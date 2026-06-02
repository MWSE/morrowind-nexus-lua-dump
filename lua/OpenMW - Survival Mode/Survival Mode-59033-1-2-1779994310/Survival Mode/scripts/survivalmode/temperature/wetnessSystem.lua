local self = require('openmw.self')
local types = require('openmw.types')
local armorWarmthBonuses = require('scripts.survivalmode.temperature.armorWarmthBonuses')

local WETNESS_MIN = 0
local WETNESS_MAX = 100
local DRYING_STEP = 1
local BASE_DRYING_MINUTES_TO_FULL_DRY = 60
local DRYING_TICK_SECONDS = (BASE_DRYING_MINUTES_TO_FULL_DRY * 60) / (WETNESS_MAX / DRYING_STEP)
local WEATHER_STEP = 1
local WEATHER_STEPS_TO_FULL = WETNESS_MAX / WEATHER_STEP
local WEATHER_REDUCTION_PER_HEAVY_PIECE = 5
local WEATHER_REDUCTION_PER_COLD_BONUS_PIECE = 7.5
local WEATHER_REDUCTION_ROBE = 60
local WATER_TEMPERATURE_MULTIPLIER_MULTIPLIER = 20.0

local WEATHER_TICK_SECONDS_BY_KEY = {
    rain = (15 * 60) / WEATHER_STEPS_TO_FULL,
    thunder = (15 * 60) / WEATHER_STEPS_TO_FULL,
    snow = (60 * 60) / WEATHER_STEPS_TO_FULL,
    blizzard = (30 * 60) / WEATHER_STEPS_TO_FULL,
}

local BASE_COLD_POINTS_PER_PERCENT = 0.5
local DEFAULT_COLD_WATER_MULTIPLIER = 1.0
local LEGACY_AMPLIFIED_COLD_WATER_MULTIPLIER = 2.0
local COLD_WATER_MULTIPLIER_BY_REGION = {
    chilly = 1.5,
    cold = 2.5,
    very_cold = 5.0,
}

local WET_WEATHER_KEYS = {
    rain = true,
    thunder = true,
    snow = true,
    blizzard = true,
}

local DEFAULT_ARMOR_WEIGHT_CLASS_BY_SLOT = {
    boots = { lightMax = 12.0, heavyMinExclusive = 18.0 },
    cuirass = { lightMax = 18.0, heavyMinExclusive = 27.0 },
    greaves = { lightMax = 9.0, heavyMinExclusive = 13.5 },
    helmet = { lightMax = 3.0, heavyMinExclusive = 4.5 },
    gauntlet = { lightMax = 3.0, heavyMinExclusive = 4.5 },
    pauldron = { lightMax = 6.0, heavyMinExclusive = 9.0 },
}

local ARMOR_WEIGHT_CLASS_BY_SLOT = DEFAULT_ARMOR_WEIGHT_CLASS_BY_SLOT

do
    local ok, temperature = pcall(require, 'scripts.survivalmode.temperature.temperature_bootstrap')
    if ok
        and type(temperature) == 'table'
        and type(temperature.config) == 'table'
        and type(temperature.config.getArmorWeightClassBySlot) == 'function' then
        local configOk, value = pcall(temperature.config.getArmorWeightClassBySlot)
        if configOk and type(value) == 'table' then
            ARMOR_WEIGHT_CLASS_BY_SLOT = value
        end
    end
end

local state = {
    wetness = 0,
    timeRemainder = 0,
    source = 'none',
    activeWeatherKey = nil,
    coldWaterMultiplier = DEFAULT_COLD_WATER_MULTIPLIER,
    ambientDryingMultiplier = 1.0,
    dryingHeatMultiplier = 1.0,
    dryingHeatSourceType = 'none',
    wasInWater = false,
    wasSwimming = false,
    pendingImmediateTemperatureTicks = 0,
}

local function trim(value)
    if type(value) ~= 'string' then
        return ''
    end
    return value:match('^%s*(.-)%s*$')
end

local function normalizeKey(value)
    return string.lower(trim(tostring(value or '')))
end

local function clamp(value, minValue, maxValue)
    if value < minValue then
        return minValue
    end
    if value > maxValue then
        return maxValue
    end
    return value
end

local function getColdWaterMultiplierForRegion(regionCategory)
    local category = normalizeKey(regionCategory)
    return tonumber(COLD_WATER_MULTIPLIER_BY_REGION[category]) or DEFAULT_COLD_WATER_MULTIPLIER
end

local function getArmorSlotRole(slotId)
    local equipmentSlots = (types.Actor ~= nil and types.Actor.EQUIPMENT_SLOT) or {}
    local slotNumeric = tonumber(slotId)
    local slotText = tostring(slotId)

    local function matchesSlotConstant(constant)
        if constant == nil then
            return false
        end
        local constantNumeric = tonumber(constant)
        if slotNumeric ~= nil and constantNumeric ~= nil and slotNumeric == constantNumeric then
            return true
        end
        return slotText == tostring(constant)
    end

    if matchesSlotConstant(equipmentSlots.Cuirass) then
        return 'cuirass'
    end
    if matchesSlotConstant(equipmentSlots.Helmet) then
        return 'helmet'
    end
    if matchesSlotConstant(equipmentSlots.Greaves) then
        return 'greaves'
    end
    if matchesSlotConstant(equipmentSlots.Boots) then
        return 'boots'
    end
    if matchesSlotConstant(equipmentSlots.LeftPauldron) or matchesSlotConstant(equipmentSlots.RightPauldron) then
        return 'pauldron'
    end

    return nil
end

local function getArmorRecordForItem(equippedItem)
    if equippedItem == nil or types.Armor == nil then
        return nil
    end

    if type(types.Armor.record) ~= 'function' then
        return nil
    end

    local directOk, directRecord = pcall(types.Armor.record, equippedItem)
    if directOk and directRecord ~= nil then
        return directRecord
    end

    local recordId = nil
    local directRecordIdOk, directRecordId = pcall(function()
        return equippedItem.recordId
    end)
    if directRecordIdOk then
        recordId = directRecordId
    end
    if recordId == nil then
        local directIdOk, directId = pcall(function()
            return equippedItem.id
        end)
        if directIdOk then
            recordId = directId
        end
    end
    if recordId ~= nil then
        local idOk, idRecord = pcall(types.Armor.record, recordId)
        if idOk and idRecord ~= nil then
            return idRecord
        end
    end

    return equippedItem
end

local function getArmorWeightClassInfo(armorRecord)
    if armorRecord == nil then
        return nil, nil
    end

    local weightClass = nil
    local weightClassOk, weightClassValue = pcall(function()
        return armorRecord.weightClass
    end)
    if weightClassOk then
        weightClass = weightClassValue
    end
    if weightClass == nil then
        local armorClassOk, armorClassValue = pcall(function()
            return armorRecord.armorClass
        end)
        if armorClassOk then
            weightClass = armorClassValue
        end
    end

    local skillId = nil
    local skillIdOk, skillIdValue = pcall(function()
        return armorRecord.skillId
    end)
    if skillIdOk then
        skillId = skillIdValue
    end
    if skillId == nil then
        local skillOk, skillValue = pcall(function()
            return armorRecord.skill
        end)
        if skillOk then
            skillId = skillValue
        end
    end

    return weightClass, skillId
end

local function getArmorWeightValue(armorRecord)
    if armorRecord == nil then
        return nil
    end

    local weight = nil
    local weightOk, weightValue = pcall(function()
        return armorRecord.weight
    end)
    if weightOk then
        weight = tonumber(weightValue)
    end
    if weight == nil then
        local dataOk, dataValue = pcall(function()
            return armorRecord.Weight
        end)
        if dataOk then
            weight = tonumber(dataValue)
        end
    end

    return weight
end

local function isHeavyByWeight(slotRole, armorRecord)
    if slotRole == nil then
        return false
    end

    local weight = getArmorWeightValue(armorRecord)
    if weight == nil then
        return false
    end

    local slotConfig = ARMOR_WEIGHT_CLASS_BY_SLOT[slotRole]
    local threshold = slotConfig ~= nil and tonumber(slotConfig.heavyMinExclusive) or nil
    if threshold == nil then
        return false
    end

    return weight > threshold
end

local function getArmorClassFromRecord(armorRecord, slotRole)
    local weightClass, skillId = getArmorWeightClassInfo(armorRecord)

    if weightClass ~= nil and types.Armor ~= nil and type(types.Armor.WEIGHT_CLASS) == 'table' then
        local weightClassNumber = tonumber(weightClass)
        local weightClassText = normalizeKey(weightClass)

        for enumKey, enumValue in pairs(types.Armor.WEIGHT_CLASS) do
            local enumKeyText = normalizeKey(enumKey)
            local enumValueNumber = tonumber(enumValue)
            local enumValueText = normalizeKey(enumValue)
            local matchesEnum = weightClass == enumValue

            if not matchesEnum and weightClassNumber ~= nil and enumValueNumber ~= nil then
                matchesEnum = weightClassNumber == enumValueNumber
            end
            if not matchesEnum and weightClassText ~= '' and enumValueText ~= '' then
                matchesEnum = weightClassText == enumValueText
            end

            if matchesEnum then
                if enumKeyText == 'heavy' or enumKeyText == 'heavyarmor' then
                    return 'heavy'
                end
                if enumKeyText == 'medium' or enumKeyText == 'mediumarmor' then
                    return 'medium'
                end
                if enumKeyText == 'light' or enumKeyText == 'lightarmor' then
                    return 'light'
                end
            end
        end
    end

    local weightClassText = normalizeKey(weightClass)
    if weightClassText == 'heavy' or weightClassText == 'heavyarmor' then
        return 'heavy'
    end
    if weightClassText == 'medium' or weightClassText == 'mediumarmor' then
        return 'medium'
    end
    if weightClassText == 'light' or weightClassText == 'lightarmor' then
        return 'light'
    end

    local skillText = normalizeKey(skillId)
    if skillText == 'heavyarmor' then
        return 'heavy'
    end
    if skillText == 'mediumarmor' then
        return 'medium'
    end
    if skillText == 'lightarmor' then
        return 'light'
    end

    if isHeavyByWeight(slotRole, armorRecord) then
        return 'heavy'
    end

    return nil
end

local function getEquippedArmorWeatherProtection()
    if types.Actor == nil
        or type(types.Actor.objectIsInstance) ~= 'function'
        or type(types.Actor.getEquipment) ~= 'function'
        or not types.Actor.objectIsInstance(self) then
        return 0
    end

    local ok, equipmentTable = pcall(types.Actor.getEquipment, self)
    if not ok or type(equipmentTable) ~= 'table' then
        return 0
    end

    local armorTypeAvailable = types.Armor ~= nil and type(types.Armor.objectIsInstance) == 'function'
    local totalProtection = 0

    for slotId, equippedItem in pairs(equipmentTable) do
        if equippedItem ~= nil then
            local role = getArmorSlotRole(slotId)
            if role ~= nil then
                local countThisItem = true
                if armorTypeAvailable then
                    local typeOk, isArmor = pcall(types.Armor.objectIsInstance, equippedItem)
                    if typeOk and isArmor ~= true then
                        countThisItem = false
                    end
                end

                if countThisItem then
                    local hasColdBonus = type(armorWarmthBonuses.hasWarmthBonusKeywordMatchForEquippedArmorItem)
                        == 'function'
                        and armorWarmthBonuses.hasWarmthBonusKeywordMatchForEquippedArmorItem(equippedItem) == true
                    if hasColdBonus then
                        totalProtection = totalProtection + WEATHER_REDUCTION_PER_COLD_BONUS_PIECE
                    else
                        local armorRecord = getArmorRecordForItem(equippedItem)
                        local armorClass = getArmorClassFromRecord(armorRecord, role)
                        if armorClass == 'heavy' then
                            totalProtection = totalProtection + WEATHER_REDUCTION_PER_HEAVY_PIECE
                        end
                    end
                end
            end
        end
    end

    return totalProtection
end

local function isRobeEquipped()
    if types.Actor == nil
        or type(types.Actor.objectIsInstance) ~= 'function'
        or type(types.Actor.getEquipment) ~= 'function'
        or not types.Actor.objectIsInstance(self)
        or types.Clothing == nil
        or type(types.Clothing.objectIsInstance) ~= 'function' then
        return false
    end

    local ok, equipmentTable = pcall(types.Actor.getEquipment, self)
    if not ok or type(equipmentTable) ~= 'table' then
        return false
    end

    local equipmentSlots = (types.Actor ~= nil and types.Actor.EQUIPMENT_SLOT) or {}
    local clothingTypes = (types.Clothing ~= nil and types.Clothing.TYPE) or {}
    local robeType = clothingTypes.Robe
    for slotId, equippedItem in pairs(equipmentTable) do
        if equippedItem ~= nil and types.Clothing.objectIsInstance(equippedItem) then
            if tonumber(slotId) == tonumber(equipmentSlots.Robe) then
                return true
            end
            if type(types.Clothing.record) == 'function' then
                local recordOk, recordValue = pcall(types.Clothing.record, equippedItem)
                if recordOk
                    and recordValue ~= nil
                    and robeType ~= nil
                    and recordValue.type == robeType then
                    return true
                end
            end
        end
    end

    return false
end

local function isWetWeatherKey(weatherKey)
    local normalizedKey = normalizeKey(weatherKey)
    return WET_WEATHER_KEYS[normalizedKey] == true
end

local function isCellExposedToWeather(cell)
    if cell == nil then
        return false
    end

    local exteriorOk, exteriorValue = pcall(function()
        return cell.isExterior
    end)
    if exteriorOk and exteriorValue == true then
        return true
    end

    if type(cell.hasTag) == 'function' then
        local quasiExteriorOk, quasiExteriorValue = pcall(function()
            return cell:hasTag('QuasiExterior')
        end)
        if quasiExteriorOk and quasiExteriorValue == true then
            return true
        end
    end

    return false
end

local function isSwimming()
    if types.Actor == nil
        or type(types.Actor.objectIsInstance) ~= 'function'
        or type(types.Actor.isSwimming) ~= 'function'
        or not types.Actor.objectIsInstance(self) then
        return false
    end

    local ok, value = pcall(types.Actor.isSwimming, self)
    return ok and value == true
end

local function getCellWaterLevel(cell)
    if cell == nil then
        return nil
    end

    local ok, value = pcall(function()
        return cell.waterLevel
    end)
    if not ok then
        return nil
    end

    return tonumber(value)
end

local function getBoundingBoxVerticalBounds()
    local ok, box = pcall(function()
        return self:getBoundingBox()
    end)
    if not ok or box == nil then
        return nil, nil
    end

    local centerZ = nil
    local halfSizeZ = nil

    local centerOk = pcall(function()
        centerZ = tonumber(box.center.z)
    end)
    local halfSizeOk = pcall(function()
        halfSizeZ = tonumber(box.halfSize.z)
    end)

    if not centerOk or not halfSizeOk or centerZ == nil or halfSizeZ == nil or halfSizeZ <= 0 then
        return nil, nil
    end

    return centerZ - halfSizeZ, centerZ + halfSizeZ
end

local function getWaterSubmersionRatio()
    local waterLevel = getCellWaterLevel(self.cell)
    if waterLevel == nil then
        return 0
    end

    local lowerZ, upperZ = getBoundingBoxVerticalBounds()
    if lowerZ == nil or upperZ == nil or upperZ <= lowerZ then
        return 0
    end

    local verticalSpan = upperZ - lowerZ
    local submergedHeight = clamp(waterLevel - lowerZ, 0, verticalSpan)
    if submergedHeight <= 0 then
        return 0
    end

    return clamp(submergedHeight / verticalSpan, 0, 1)
end

local function setSource(source)
    local normalized = normalizeKey(source)
    if normalized == '' then
        normalized = 'none'
    end
    if state.source ~= normalized then
        state.timeRemainder = 0
        state.activeWeatherKey = nil
    end
    state.source = normalized
end

local function getWeatherTickSeconds(weatherKey)
    local key = normalizeKey(weatherKey)
    local configured = tonumber(WEATHER_TICK_SECONDS_BY_KEY[key])
    if configured ~= nil and configured > 0 then
        return configured
    end
    return (15 * 60) / WEATHER_STEPS_TO_FULL
end

local function advanceTowardsMax(elapsedSeconds, maxWetness, tickSeconds, stepSize)
    local elapsed = tonumber(elapsedSeconds) or 0
    if elapsed <= 0 then
        return
    end

    if state.wetness >= maxWetness then
        state.wetness = clamp(state.wetness, WETNESS_MIN, WETNESS_MAX)
        state.timeRemainder = 0
        return
    end

    local tick = tonumber(tickSeconds) or 0
    if tick <= 0 then
        return
    end
    local step = tonumber(stepSize) or 0
    if step <= 0 then
        return
    end

    local totalElapsed = state.timeRemainder + elapsed
    local ticks = math.floor(totalElapsed / tick)
    state.timeRemainder = totalElapsed - (ticks * tick)

    if ticks <= 0 then
        return
    end

    state.wetness = math.min(maxWetness, state.wetness + (ticks * step))
    if state.wetness >= maxWetness then
        state.timeRemainder = 0
    end
end

local function advanceTowardsDry(elapsedSeconds, dryingMultiplier)
    local elapsed = tonumber(elapsedSeconds) or 0
    if elapsed <= 0 then
        return
    end

    if state.wetness <= WETNESS_MIN then
        state.wetness = WETNESS_MIN
        state.timeRemainder = 0
        return
    end

    local effectiveDryingMultiplier = math.max(1.0, tonumber(dryingMultiplier) or 1.0)
    local totalElapsed = state.timeRemainder + (elapsed * effectiveDryingMultiplier)
    local ticks = math.floor(totalElapsed / DRYING_TICK_SECONDS)
    state.timeRemainder = totalElapsed - (ticks * DRYING_TICK_SECONDS)

    if ticks <= 0 then
        return
    end

    state.wetness = math.max(WETNESS_MIN, state.wetness - (ticks * DRYING_STEP))
    if state.wetness <= WETNESS_MIN then
        state.wetness = WETNESS_MIN
        state.timeRemainder = 0
        state.activeWeatherKey = nil
        state.coldWaterMultiplier = DEFAULT_COLD_WATER_MULTIPLIER
    end
end

local function updateWetnessByEnvironment(elapsedSeconds, context)
    local elapsed = tonumber(elapsedSeconds) or 0
    if elapsed < 0 then
        elapsed = 0
    end

    local details = type(context) == 'table' and context or {}
    local regionCategory = normalizeKey(details.regionCategory)
    local coldWaterMultiplier = getColdWaterMultiplierForRegion(regionCategory)
    local ambientDryingMultiplier = 1.0
    local dryingHeatMultiplier = math.max(1.0, tonumber(details.heatSourceDryingMultiplier) or 1.0)
    local dryingHeatSourceType = normalizeKey(details.heatSourceDryingSourceType)
    if dryingHeatMultiplier <= 1.0 then
        dryingHeatMultiplier = 1.0
        dryingHeatSourceType = 'none'
    elseif dryingHeatSourceType == '' then
        dryingHeatSourceType = 'none'
    end
    state.ambientDryingMultiplier = ambientDryingMultiplier
    state.dryingHeatMultiplier = dryingHeatMultiplier
    state.dryingHeatSourceType = dryingHeatSourceType
    local totalDryingMultiplier = ambientDryingMultiplier * dryingHeatMultiplier
    local currentlySwimming = isSwimming()
    local waterSubmersionRatio = getWaterSubmersionRatio()
    local currentlyInWater = currentlySwimming or waterSubmersionRatio > 0

    if currentlyInWater then
        if not state.wasInWater then
            state.coldWaterMultiplier = coldWaterMultiplier
            state.pendingImmediateTemperatureTicks = state.pendingImmediateTemperatureTicks + 1
        end
        state.wasInWater = true
        state.wasSwimming = currentlySwimming
        setSource('water')
        state.wetness = math.max(
            state.wetness,
            currentlySwimming and WETNESS_MAX or math.floor((waterSubmersionRatio * WETNESS_MAX) + 0.5)
        )
        state.timeRemainder = 0
        state.activeWeatherKey = nil
        return
    end

    state.wasInWater = false
    state.wasSwimming = false

    local weatherKey = normalizeKey(details.weatherKey)
    local weatherIsWet = isWetWeatherKey(weatherKey)
    local exposedToWeather = weatherIsWet and isCellExposedToWeather(self.cell)

    if state.source == 'water' and state.wetness > WETNESS_MIN then
        -- Water wetness source remains authoritative until fully dry.
        if exposedToWeather then
            return
        end

        advanceTowardsDry(elapsed, totalDryingMultiplier)
        state.wetness = clamp(state.wetness, WETNESS_MIN, WETNESS_MAX)
        if state.wetness <= WETNESS_MIN then
            state.source = 'none'
        else
            state.source = 'water'
        end
        return
    end

    if exposedToWeather then
        local weatherProtection = 0
        if isRobeEquipped() then
            weatherProtection = WEATHER_REDUCTION_ROBE
        else
            weatherProtection = getEquippedArmorWeatherProtection()
        end
        local weatherCap = clamp(
            WETNESS_MAX - weatherProtection,
            WETNESS_MIN,
            WETNESS_MAX
        )

        if weatherCap > WETNESS_MIN then
            local enteringWetWeather = state.source ~= 'weather'
            setSource('weather')
            if state.activeWeatherKey ~= weatherKey then
                state.timeRemainder = 0
                state.activeWeatherKey = weatherKey
            end
            if enteringWetWeather and state.wetness < weatherCap then
                state.wetness = math.min(weatherCap, state.wetness + WEATHER_STEP)
            end
            advanceTowardsMax(elapsed, weatherCap, getWeatherTickSeconds(weatherKey), WEATHER_STEP)
            state.wetness = clamp(state.wetness, WETNESS_MIN, WETNESS_MAX)
            return
        end
    end

    if state.wetness > WETNESS_MIN then
        setSource('drying')
        advanceTowardsDry(elapsed, totalDryingMultiplier)
        state.wetness = clamp(state.wetness, WETNESS_MIN, WETNESS_MAX)
        if state.wetness <= WETNESS_MIN then
            state.source = 'none'
        end
        return
    end

    state.wetness = WETNESS_MIN
    state.timeRemainder = 0
    state.source = 'none'
    state.activeWeatherKey = nil
    state.coldWaterMultiplier = DEFAULT_COLD_WATER_MULTIPLIER
end

local function getColdModifierFromWetness()
    local wetnessValue = clamp(tonumber(state.wetness) or 0, WETNESS_MIN, WETNESS_MAX)
    if wetnessValue <= WETNESS_MIN then
        return 0
    end

    local coldWaterMultiplier = math.max(
        DEFAULT_COLD_WATER_MULTIPLIER,
        tonumber(state.coldWaterMultiplier) or DEFAULT_COLD_WATER_MULTIPLIER
    )
    local pointsPerPercent = BASE_COLD_POINTS_PER_PERCENT * coldWaterMultiplier

    return -(wetnessValue * pointsPerPercent)
end

local function getSourceLabel(sourceKey)
    if sourceKey == 'water' then
        return 'Water'
    end
    if sourceKey == 'weather' then
        return 'Weather'
    end
    if sourceKey == 'drying' then
        return 'Drying'
    end
    return 'Dry'
end

local function getDryingHeatSourceLabel(sourceKey)
    if sourceKey == 'lava' then
        return 'Lava'
    end
    if sourceKey == 'fire' then
        return 'Fire'
    end
    if sourceKey == 'torch' then
        return 'Torch'
    end
    return ''
end

local function buildModifierEntry()
    local wetnessValue = clamp(tonumber(state.wetness) or 0, WETNESS_MIN, WETNESS_MAX)
    local coldModifier = getColdModifierFromWetness()
    local coldWaterMultiplier = math.max(
        DEFAULT_COLD_WATER_MULTIPLIER,
        tonumber(state.coldWaterMultiplier) or DEFAULT_COLD_WATER_MULTIPLIER
    )
    local percentText = tostring(math.floor(wetnessValue + 0.5))
    local label = 'Wetness ' .. percentText .. '% (' .. getSourceLabel(state.source) .. ')'
    if coldWaterMultiplier > DEFAULT_COLD_WATER_MULTIPLIER then
        label = string.format('%s [Cold Water x%.1f]', label, coldWaterMultiplier)
    end
    if wetnessValue > WETNESS_MIN and state.ambientDryingMultiplier > 1.0 then
        label = string.format('%s [Indoors x%.2f]', label, state.ambientDryingMultiplier)
    end
    if wetnessValue > WETNESS_MIN and state.dryingHeatMultiplier > 1.0 then
        local dryingHeatLabel = getDryingHeatSourceLabel(state.dryingHeatSourceType)
        if dryingHeatLabel ~= '' then
            label = string.format('%s [Near %s x%.1f]', label, dryingHeatLabel, state.dryingHeatMultiplier)
        end
    end

    return {
        id = 'wetness',
        label = label,
        warmModifier = 0,
        coldModifier = coldModifier,
        wetness = wetnessValue,
        source = state.source,
        coldWaterAmplified = coldWaterMultiplier > DEFAULT_COLD_WATER_MULTIPLIER,
        coldWaterMultiplier = coldWaterMultiplier,
        ambientDryingMultiplier = math.max(1.0, tonumber(state.ambientDryingMultiplier) or 1.0),
        dryingHeatMultiplier = math.max(1.0, tonumber(state.dryingHeatMultiplier) or 1.0),
        dryingHeatSourceType = normalizeKey(state.dryingHeatSourceType),
    }
end

local function getTemperatureTickMultiplier(isTemperatureDecreasing)
    if state.source == 'water'
        and state.wetness > WETNESS_MIN
        and isTemperatureDecreasing == true then
        return WATER_TEMPERATURE_MULTIPLIER_MULTIPLIER
    end
    return 1.0
end

local function hasPendingImmediateTemperatureTick()
    return (tonumber(state.pendingImmediateTemperatureTicks) or 0) > 0
end

local function consumeImmediateTemperatureTicks()
    local pending = math.max(0, math.floor(tonumber(state.pendingImmediateTemperatureTicks) or 0))
    state.pendingImmediateTemperatureTicks = 0
    return pending
end

local function reset()
    state.wetness = 0
    state.timeRemainder = 0
    state.source = 'none'
    state.activeWeatherKey = nil
    state.coldWaterMultiplier = DEFAULT_COLD_WATER_MULTIPLIER
    state.ambientDryingMultiplier = 1.0
    state.dryingHeatMultiplier = 1.0
    state.dryingHeatSourceType = 'none'
    state.wasInWater = false
    state.wasSwimming = false
    state.pendingImmediateTemperatureTicks = 0
end

local function onSave()
    return {
        wetness = clamp(tonumber(state.wetness) or 0, WETNESS_MIN, WETNESS_MAX),
        timeRemainder = math.max(0, tonumber(state.timeRemainder) or 0),
        source = normalizeKey(state.source),
        activeWeatherKey = normalizeKey(state.activeWeatherKey),
        coldWaterAmplified = (tonumber(state.coldWaterMultiplier) or DEFAULT_COLD_WATER_MULTIPLIER) > DEFAULT_COLD_WATER_MULTIPLIER,
        coldWaterMultiplier = math.max(
            DEFAULT_COLD_WATER_MULTIPLIER,
            tonumber(state.coldWaterMultiplier) or DEFAULT_COLD_WATER_MULTIPLIER
        ),
    }
end

local function onLoad(savedData)
    reset()

    if type(savedData) ~= 'table' then
        return
    end

    state.wetness = clamp(tonumber(savedData.wetness) or 0, WETNESS_MIN, WETNESS_MAX)
    state.timeRemainder = math.max(0, tonumber(savedData.timeRemainder) or 0)

    local savedSource = normalizeKey(savedData.source)
    if savedSource == 'water' or savedSource == 'weather' or savedSource == 'drying' then
        state.source = savedSource
    else
        state.source = (state.wetness > 0) and 'drying' or 'none'
    end
    state.activeWeatherKey = normalizeKey(savedData.activeWeatherKey)
    if state.activeWeatherKey == '' then
        state.activeWeatherKey = nil
    end

    local savedColdWaterMultiplier = tonumber(savedData.coldWaterMultiplier)
    if savedColdWaterMultiplier ~= nil then
        state.coldWaterMultiplier = math.max(DEFAULT_COLD_WATER_MULTIPLIER, savedColdWaterMultiplier)
    elseif savedData.coldWaterAmplified == true then
        state.coldWaterMultiplier = LEGACY_AMPLIFIED_COLD_WATER_MULTIPLIER
    else
        state.coldWaterMultiplier = DEFAULT_COLD_WATER_MULTIPLIER
    end
    if state.wetness <= 0 then
        state.coldWaterMultiplier = DEFAULT_COLD_WATER_MULTIPLIER
        state.source = 'none'
        state.activeWeatherKey = nil
    end
    state.ambientDryingMultiplier = 1.0
    state.dryingHeatMultiplier = 1.0
    state.dryingHeatSourceType = 'none'
end

return {
    WETNESS_MIN = WETNESS_MIN,
    WETNESS_MAX = WETNESS_MAX,
    isWetWeatherKey = isWetWeatherKey,
    updateWetnessByEnvironment = updateWetnessByEnvironment,
    buildModifierEntry = buildModifierEntry,
    getTemperatureTickMultiplier = getTemperatureTickMultiplier,
    hasPendingImmediateTemperatureTick = hasPendingImmediateTemperatureTick,
    consumeImmediateTemperatureTicks = consumeImmediateTemperatureTicks,
    onSave = onSave,
    onLoad = onLoad,
    reset = reset,
}
