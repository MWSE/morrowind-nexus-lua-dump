local core = require('openmw.core')
local self = require('openmw.self')
local types = require('openmw.types')
local temperatureBalanceConfig = require('scripts.survivalmode.temperature.temperatureBalanceConfig')
local armorWarmthBonuses = require('scripts.survivalmode.temperature.armorWarmthBonuses')
local l10n = core.l10n('SurvivalMode', 'en')

local NEEDS_DYNAMIC_SPELL_REQUEST_EVENT = 'SurvivalNeeds_RequestDynamicDebuffSpell'
local WARMTH_ABILITY_NAME = 'Warmth'
local WARMTH_DISPLAY_EFFECT_ID = 'sn_warmth_display'
local SECONDS_PER_GAME_HOUR = 60 * 60
local NIGHT_START_HOUR = 22
local NIGHT_END_HOUR = 5
local EVENING_COOL_START_HOUR = 19
local MORNING_WARM_END_HOUR = 8
local WARMTH_DISPLAY_VALUE_STEP = 0.5
local WARMTH_SYNC_MIN_REBUILD_INTERVAL_SECONDS = 5.0
local MAX_WARMTH_CACHE_ENTRIES = 64

local function localize(key, data)
    if data == nil then
        return l10n(key)
    end
    return l10n(key, data)
end

local armorWeightClassBySlot = (function()
    local ok, bootstrap = pcall(require, 'scripts.survivalmode.temperature.temperature_bootstrap')
    if ok
        and type(bootstrap) == 'table'
        and type(bootstrap.config) == 'table'
        and type(bootstrap.config.getArmorWeightClassBySlot) == 'function' then
        local valueOk, value = pcall(bootstrap.config.getArmorWeightClassBySlot)
        if valueOk and type(value) == 'table' then
            return value
        end
    end

    return {
        boots = { lightMax = 12.0, heavyMinExclusive = 18.0 },
        cuirass = { lightMax = 18.0, heavyMinExclusive = 27.0 },
        greaves = { lightMax = 9.0, heavyMinExclusive = 13.5 },
        helmet = { lightMax = 3.0, heavyMinExclusive = 4.5 },
        gauntlet = { lightMax = 3.0, heavyMinExclusive = 4.5 },
        pauldron = { lightMax = 6.0, heavyMinExclusive = 9.0 },
    }
end)()

local state = {
    requestCounter = 0,
    pendingRequest = nil,
    appliedStageId = nil,
    appliedSpellId = nil,
    trackedSpellIds = {},
    applyFailures = {},
    lastSyncSignature = nil,
    lastSyncBuildTime = -math.huge,
    warmthCacheByKey = {},
    warmthCacheEntryCount = 0,
}

local function trim(value)
    if type(value) ~= 'string' then
        return ''
    end
    return value:match('^%s*(.-)%s*$')
end

local function normalizeKey(value)
    if type(value) ~= 'string' then
        return ''
    end
    return string.lower(trim(value))
end

local function now()
    return core.getGameTime()
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

local function roundToNearestInteger(value)
    local numeric = tonumber(value) or 0
    if numeric >= 0 then
        return math.floor(numeric + 0.5)
    end
    return math.ceil(numeric - 0.5)
end

local function quantizeValue(value, step)
    local numeric = tonumber(value) or 0
    local bucketStep = tonumber(step) or 0
    if bucketStep <= 0 then
        return numeric
    end
    return roundToNearestInteger(numeric / bucketStep) * bucketStep
end

local function boolToken(value)
    return value == true and '1' or '0'
end

local function clearWarmthCache()
    state.warmthCacheByKey = {}
    state.warmthCacheEntryCount = 0
end

local function readWarmthCache(cacheKey)
    if type(cacheKey) ~= 'string' or cacheKey == '' then
        return nil
    end
    return state.warmthCacheByKey[cacheKey]
end

local function writeWarmthCache(cacheKey, value)
    if type(cacheKey) ~= 'string' or cacheKey == '' then
        return value
    end
    if state.warmthCacheByKey[cacheKey] == nil then
        state.warmthCacheEntryCount = (tonumber(state.warmthCacheEntryCount) or 0) + 1
        if state.warmthCacheEntryCount > MAX_WARMTH_CACHE_ENTRIES then
            clearWarmthCache()
        end
    end
    state.warmthCacheByKey[cacheKey] = value
    return value
end

local function smoothstep(value)
    local clamped = clamp(tonumber(value) or 0, 0, 1)
    return clamped * clamped * (3 - (2 * clamped))
end

local function getCurrentHourOfDay()
    if type(core.getGameTime) ~= 'function' then
        return nil
    end

    local gameTimeSeconds = math.max(0, tonumber(core.getGameTime()) or 0)
    local hour = (gameTimeSeconds / SECONDS_PER_GAME_HOUR) % 24
    if hour < 0 or hour >= 24 then
        return nil
    end

    return hour
end

local function getNightTemperatureFactor()
    local hour = getCurrentHourOfDay()
    if hour == nil then
        return 0
    end

    if hour >= NIGHT_START_HOUR or hour <= NIGHT_END_HOUR then
        return 1.0
    end

    if hour > NIGHT_END_HOUR and hour < MORNING_WARM_END_HOUR then
        local span = MORNING_WARM_END_HOUR - NIGHT_END_HOUR
        if span <= 0 then
            return 0
        end
        return 1.0 - smoothstep((hour - NIGHT_END_HOUR) / span)
    end

    if hour > EVENING_COOL_START_HOUR and hour < NIGHT_START_HOUR then
        local span = NIGHT_START_HOUR - EVENING_COOL_START_HOUR
        if span <= 0 then
            return 0
        end
        return smoothstep((hour - EVENING_COOL_START_HOUR) / span)
    end

    return 0
end

local function getWeatherApi()
    if core == nil then
        return nil
    end

    local weatherApi = core.weather
    if weatherApi == nil then
        weatherApi = core.Weather
    end
    if weatherApi == nil then
        return nil
    end

    local apiType = type(weatherApi)
    if apiType ~= 'table' and apiType ~= 'userdata' then
        return nil
    end

    if type(weatherApi.getCurrent) ~= 'function' then
        return nil
    end

    return weatherApi
end

local function callWeatherApi(weatherApi, methodName, cell)
    if weatherApi == nil or type(weatherApi[methodName]) ~= 'function' then
        return nil
    end

    local callAttempts = {
        function()
            return weatherApi[methodName](cell)
        end,
        function()
            return weatherApi[methodName](weatherApi, cell)
        end,
        function()
            return weatherApi[methodName]()
        end,
        function()
            return weatherApi[methodName](weatherApi)
        end,
    }

    for _, callAttempt in ipairs(callAttempts) do
        local ok, value = pcall(callAttempt)
        if ok and value ~= nil then
            return value
        end
    end

    return nil
end

local function getCurrentWeatherRecord()
    local weatherApi = getWeatherApi()
    if weatherApi == nil then
        return nil
    end

    local currentCell = self.cell
    if currentCell == nil then
        return nil
    end

    return callWeatherApi(weatherApi, 'getCurrent', currentCell)
end

local function isClearOrCloudyWeather()
    local weatherRecord = getCurrentWeatherRecord()
    if weatherRecord == nil then
        return false
    end

    local weatherText = ''
    if type(weatherRecord) == 'string' or type(weatherRecord) == 'number' then
        weatherText = tostring(weatherRecord)
    else
        local candidateFields = { 'recordId', 'scriptId', 'id', 'name', 'cloudTexture', 'rainEffect', 'particleEffect' }
        for _, fieldName in ipairs(candidateFields) do
            local ok, value = pcall(function()
                return weatherRecord[fieldName]
            end)
            if ok and type(value) == 'string' and value ~= '' then
                weatherText = weatherText .. ' ' .. value
            end
        end
        weatherText = weatherText .. ' ' .. tostring(weatherRecord)
    end

    local token = normalizeKey(weatherText)
    if token == '' then
        return false
    end

    if token:find('rain', 1, true) ~= nil
        or token:find('thunder', 1, true) ~= nil
        or token:find('snow', 1, true) ~= nil
        or token:find('blizzard', 1, true) ~= nil
        or token:find('ash', 1, true) ~= nil
        or token:find('blight', 1, true) ~= nil
        or token:find('storm', 1, true) ~= nil then
        return false
    end

    if token:find('clear', 1, true) ~= nil then
        return true
    end
    if token:find('cloudy', 1, true) ~= nil then
        return true
    end

    return false
end

local function isClearOrCloudyWeatherKey(weatherKey)
    local key = normalizeKey(weatherKey)
    if key == '' then
        return false
    end
    if key == 'clear' or key == 'cloudy' then
        return true
    end
    if key:find('rain', 1, true) ~= nil
        or key:find('thunder', 1, true) ~= nil
        or key:find('snow', 1, true) ~= nil
        or key:find('blizzard', 1, true) ~= nil
        or key:find('ash', 1, true) ~= nil
        or key:find('blight', 1, true) ~= nil
        or key:find('storm', 1, true) ~= nil then
        return false
    end
    return key:find('clear', 1, true) ~= nil
        or key:find('cloudy', 1, true) ~= nil
end

local function resolveClearOrCloudyWeatherValue(options)
    local details = type(options) == 'table' and options or {}
    if details.clearOrCloudyWeather ~= nil then
        return details.clearOrCloudyWeather == true
    end
    if details.weatherKey ~= nil then
        local weatherKey = normalizeKey(details.weatherKey)
        return isClearOrCloudyWeatherKey(weatherKey)
    end
    return isClearOrCloudyWeather()
end

local function getBalanceTable(fieldName)
    local value = temperatureBalanceConfig[fieldName]
    assert(type(value) == 'table', string.format(
        '[SurvivalMode] temperatureBalanceConfig.%s must be a table.',
        tostring(fieldName)
    ))
    return value
end

local function requireNumericConfigField(container, fieldName, configPath)
    local value = tonumber(container[fieldName])
    assert(value ~= nil, string.format(
        '[SurvivalMode] %s.%s must be a number.',
        tostring(configPath),
        tostring(fieldName)
    ))
    return value
end

local function formatWarmthPoints(value)
    local roundedTenths = math.floor(((tonumber(value) or 0) * 10) + 0.5) / 10
    local roundedWhole = math.floor(roundedTenths + 0.5)
    if math.abs(roundedTenths - roundedWhole) < 0.001 then
        return localize('warmth_points_format', { value = tostring(roundedWhole) })
    end

    return localize('warmth_points_format', { value = string.format('%.1f', roundedTenths) })
end

local function quantizeWarmthValue(value)
    local numeric = tonumber(value) or 0
    local step = tonumber(WARMTH_DISPLAY_VALUE_STEP) or 0
    if step <= 0 then
        return numeric
    end
    return math.floor((numeric / step) + 0.5) * step
end

local function getEquipmentSignature()
    if types.Actor == nil
        or type(types.Actor.objectIsInstance) ~= 'function'
        or type(types.Actor.getEquipment) ~= 'function'
        or not types.Actor.objectIsInstance(self) then
        return ''
    end

    local equipmentOk, equipmentTable = pcall(types.Actor.getEquipment, self)
    if not equipmentOk or type(equipmentTable) ~= 'table' then
        return ''
    end

    local parts = {}
    for slotId, equippedItem in pairs(equipmentTable) do
        local recordId = ''
        if equippedItem ~= nil then
            local recordIdOk, recordIdValue = pcall(function()
                return equippedItem.recordId
            end)
            if recordIdOk and recordIdValue ~= nil then
                recordId = normalizeKey(tostring(recordIdValue))
            end
            if recordId == '' then
                local idOk, idValue = pcall(function()
                    return equippedItem.id
                end)
                if idOk and idValue ~= nil then
                    recordId = normalizeKey(tostring(idValue))
                end
            end
        end
        parts[#parts + 1] = string.format('%s=%s', tostring(slotId), recordId)
    end

    table.sort(parts)
    return table.concat(parts, '|')
end

local function resolveEquipmentSignature(options)
    local details = type(options) == 'table' and options or {}
    if details.equipmentSignature ~= nil then
        return normalizeKey(details.equipmentSignature)
    end
    return getEquipmentSignature()
end

local function buildSyncSignature(context)
    local details = type(context) == 'table' and context or {}
    local regionCategory = normalizeKey(details.regionCategory)
    local usesInteriorBase = details.usesInteriorBase == true and '1' or '0'
    local targetTemperatureBeforeArmorBonus = roundToNearestInteger(details.targetTemperatureBeforeArmorBonus)
    local campfireWarmModifier = roundToNearestInteger(details.campfireWarmModifier)
    local campfireDominantSourceType = normalizeKey(details.campfireDominantSourceType)
    local clearOrCloudyWeather = boolToken(resolveClearOrCloudyWeatherValue(details))
    local equipmentSignature = resolveEquipmentSignature(details)

    return table.concat({
        regionCategory,
        usesInteriorBase,
        tostring(targetTemperatureBeforeArmorBonus),
        tostring(campfireWarmModifier),
        campfireDominantSourceType,
        tostring(clearOrCloudyWeather),
        equipmentSignature,
    }, '|')
end

local function getEquipmentDisplayName(equippedItem, record)
    local candidates = {
        function() return record ~= nil and record.name or nil end,
        function() return equippedItem ~= nil and equippedItem.name or nil end,
        function() return record ~= nil and record.id or nil end,
        function() return equippedItem ~= nil and equippedItem.recordId or nil end,
        function() return equippedItem ~= nil and equippedItem.id or nil end,
    }

    for _, getCandidate in ipairs(candidates) do
        local ok, value = pcall(getCandidate)
        if ok and type(value) == 'string' then
            local text = trim(value)
            if text ~= '' then
                return text
            end
        end
    end

    return localize('warmth_unknown_item_name')
end

local function getEquipmentSlotSortOrder(slotId)
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

    if matchesSlotConstant(equipmentSlots.Helmet) then return 10 end
    if matchesSlotConstant(equipmentSlots.Cuirass) then return 20 end
    if matchesSlotConstant(equipmentSlots.Shirt) then return 30 end
    if matchesSlotConstant(equipmentSlots.LeftPauldron) then return 40 end
    if matchesSlotConstant(equipmentSlots.RightPauldron) then return 41 end
    if matchesSlotConstant(equipmentSlots.LeftGauntlet) then return 50 end
    if matchesSlotConstant(equipmentSlots.RightGauntlet) then return 51 end
    if matchesSlotConstant(equipmentSlots.Greaves) then return 60 end
    if matchesSlotConstant(equipmentSlots.Pants) then return 70 end
    if matchesSlotConstant(equipmentSlots.Boots) then return 80 end
    if matchesSlotConstant(equipmentSlots.Robe) then return 90 end
    return 999
end

local function resolveRegionValue(valuesByRegion, regionCategory, configPath)
    if type(valuesByRegion) ~= 'table' then
        error(string.format('[SurvivalMode] %s must be a table.', tostring(configPath)))
    end

    local category = normalizeKey(regionCategory)
    local value = tonumber(valuesByRegion[category])
    if value ~= nil then
        return value
    end
    if category == 'very_hot' then
        value = tonumber(valuesByRegion.hot) or tonumber(valuesByRegion.warm)
    elseif category == 'warm' then
        value = tonumber(valuesByRegion.hot) or tonumber(valuesByRegion.neutral)
    elseif category == 'chilly' then
        value = tonumber(valuesByRegion.cold) or tonumber(valuesByRegion.neutral)
    elseif category == 'very_cold' then
        value = tonumber(valuesByRegion.cold) or tonumber(valuesByRegion.chilly)
    end
    if value ~= nil then
        return value
    end
    value = tonumber(valuesByRegion.neutral)
    assert(value ~= nil, string.format(
        '[SurvivalMode] %s.neutral must be a number.',
        tostring(configPath)
    ))
    return value
end

local function resolveArmorWarmthProfileByRegion(profileByRegion, regionCategory)
    if type(profileByRegion) ~= 'table' then
        return nil
    end

    local category = normalizeKey(regionCategory)
    if type(profileByRegion[category]) == 'table' then
        return profileByRegion[category]
    end
    if category == 'very_hot' and type(profileByRegion.hot) == 'table' then
        return profileByRegion.hot
    end
    if category == 'warm' and type(profileByRegion.hot) == 'table' then
        return profileByRegion.hot
    end
    if category == 'chilly' and type(profileByRegion.cold) == 'table' then
        return profileByRegion.cold
    end
    if category == 'very_cold' and type(profileByRegion.cold) == 'table' then
        return profileByRegion.cold
    end
    if type(profileByRegion.neutral) == 'table' then
        return profileByRegion.neutral
    end

    for _, value in pairs(profileByRegion) do
        if type(value) == 'table' then
            return value
        end
    end
    return nil
end

local function isRecordObject(value)
    local valueType = type(value)
    return valueType == 'table' or valueType == 'userdata'
end

local function tryGetEnumValue(enumTable, enumName)
    if enumTable == nil or enumName == nil then
        return nil
    end
    local ok, value = pcall(function()
        return enumTable[enumName]
    end)
    if not ok then
        return nil
    end
    return value
end

local function getClothingWarmthForEquippedItem(slotId, clothingRecord, regionCategory, isExteriorCell)
    local equipmentSlots = (types.Actor ~= nil and types.Actor.EQUIPMENT_SLOT) or {}
    local clothingTypes = (types.Clothing ~= nil and types.Clothing.TYPE) or {}
    local configuredClothingWarmth = getBalanceTable('clothingWarmth')
    local configuredRobeWarmthByRegion = getBalanceTable('robeWarmthByRegion')
    local glovesOrShoesWarmth = requireNumericConfigField(
        configuredClothingWarmth,
        'glovesOrShoes',
        'temperatureBalanceConfig.clothingWarmth'
    )
    requireNumericConfigField(
        configuredClothingWarmth,
        'robe',
        'temperatureBalanceConfig.clothingWarmth'
    )
    local defaultWarmth = requireNumericConfigField(
        configuredClothingWarmth,
        'default',
        'temperatureBalanceConfig.clothingWarmth'
    )

    local function matchesClothingType(enumName)
        if not isRecordObject(clothingRecord) then
            return false
        end
        local expectedType = tryGetEnumValue(clothingTypes, enumName)
        return expectedType ~= nil and clothingRecord.type == expectedType
    end

    local numericSlotId = tonumber(slotId)
    if numericSlotId ~= nil then
        if numericSlotId == equipmentSlots.Boots
            or numericSlotId == equipmentSlots.LeftGauntlet
            or numericSlotId == equipmentSlots.RightGauntlet then
            return glovesOrShoesWarmth
        end
        if numericSlotId == equipmentSlots.Robe then
            if isExteriorCell ~= true then
                return 0
            end
            return resolveRegionValue(
                configuredRobeWarmthByRegion,
                regionCategory,
                'temperatureBalanceConfig.robeWarmthByRegion'
            )
        end
        if numericSlotId == equipmentSlots.Shirt or numericSlotId == equipmentSlots.Pants then
            return defaultWarmth
        end
    end

    if matchesClothingType('Robe') then
        if isExteriorCell ~= true then
            return 0
        end
        return resolveRegionValue(
            configuredRobeWarmthByRegion,
            regionCategory,
            'temperatureBalanceConfig.robeWarmthByRegion'
        )
    end
    if matchesClothingType('Shoes') or matchesClothingType('Glove') or matchesClothingType('Gloves') then
        return glovesOrShoesWarmth
    end
    if matchesClothingType('Shirt') or matchesClothingType('Pants') then
        return defaultWarmth
    end

    return 0
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
    local robeType = tryGetEnumValue(clothingTypes, 'Robe')
    for slotId, equippedItem in pairs(equipmentTable) do
        if equippedItem ~= nil and types.Clothing.objectIsInstance(equippedItem) then
            if tonumber(slotId) == tonumber(equipmentSlots.Robe) then
                return true
            end
            if type(types.Clothing.record) == 'function' then
                local recordOk, recordValue = pcall(types.Clothing.record, equippedItem)
                if recordOk and isRecordObject(recordValue) and robeType ~= nil and recordValue.type == robeType then
                    return true
                end
            end
        end
    end

    return false
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

    if matchesSlotConstant(equipmentSlots.Cuirass) then return 'cuirass' end
    if matchesSlotConstant(equipmentSlots.Helmet) then return 'helmet' end
    if matchesSlotConstant(equipmentSlots.Greaves) then return 'greaves' end
    if matchesSlotConstant(equipmentSlots.Boots) then return 'boots' end
    if matchesSlotConstant(equipmentSlots.LeftGauntlet) or matchesSlotConstant(equipmentSlots.RightGauntlet) then
        return 'gauntlet'
    end
    if matchesSlotConstant(equipmentSlots.LeftPauldron) or matchesSlotConstant(equipmentSlots.RightPauldron) then
        return 'pauldron'
    end

    return nil
end

local function getArmorRecordForItem(equippedItem)
    if equippedItem == nil or types.Armor == nil or type(types.Armor.record) ~= 'function' then
        return nil
    end

    local directOk, directRecord = pcall(types.Armor.record, equippedItem)
    if directOk and directRecord ~= nil then
        return directRecord
    end

    local recordId = nil
    local recordIdOk, recordIdValue = pcall(function() return equippedItem.recordId end)
    if recordIdOk then
        recordId = recordIdValue
    end
    if recordId == nil then
        local idOk, idValue = pcall(function() return equippedItem.id end)
        if idOk then
            recordId = idValue
        end
    end
    if recordId ~= nil then
        local byIdOk, byIdRecord = pcall(types.Armor.record, recordId)
        if byIdOk and byIdRecord ~= nil then
            return byIdRecord
        end
    end

    return equippedItem
end

local function getArmorWeightClassInfo(armorRecord)
    if armorRecord == nil then
        return nil, nil
    end

    local weightClass = nil
    local weightClassOk, weightClassValue = pcall(function() return armorRecord.weightClass end)
    if weightClassOk then
        weightClass = weightClassValue
    end
    if weightClass == nil then
        local armorClassOk, armorClassValue = pcall(function() return armorRecord.armorClass end)
        if armorClassOk then
            weightClass = armorClassValue
        end
    end

    local skillId = nil
    local skillIdOk, skillIdValue = pcall(function() return armorRecord.skillId end)
    if skillIdOk then
        skillId = skillIdValue
    end
    if skillId == nil then
        local skillOk, skillValue = pcall(function() return armorRecord.skill end)
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
    local weightOk, weightValue = pcall(function() return armorRecord.weight end)
    if weightOk then
        weight = tonumber(weightValue)
    end
    if weight == nil then
        local dataOk, dataValue = pcall(function() return armorRecord.Weight end)
        if dataOk then
            weight = tonumber(dataValue)
        end
    end

    return weight
end

local function isHeavyByWeight(slotRole, armorRecord)
    local weight = getArmorWeightValue(armorRecord)
    local slotConfig = armorWeightClassBySlot[slotRole]
    local threshold = slotConfig ~= nil and tonumber(slotConfig.heavyMinExclusive) or nil
    return weight ~= nil and threshold ~= nil and weight > threshold
end

local function isLightByWeight(slotRole, armorRecord)
    local weight = getArmorWeightValue(armorRecord)
    local slotConfig = armorWeightClassBySlot[slotRole]
    local maxWeight = slotConfig ~= nil and tonumber(slotConfig.lightMax) or nil
    return weight ~= nil and maxWeight ~= nil and weight <= maxWeight
end

local function isMediumByWeight(slotRole, armorRecord)
    local weight = getArmorWeightValue(armorRecord)
    local slotConfig = armorWeightClassBySlot[slotRole]
    local lightMax = slotConfig ~= nil and tonumber(slotConfig.lightMax) or nil
    local heavyThreshold = slotConfig ~= nil and tonumber(slotConfig.heavyMinExclusive) or nil
    return weight ~= nil
        and lightMax ~= nil
        and heavyThreshold ~= nil
        and weight > lightMax
        and weight <= heavyThreshold
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
                if enumKeyText == 'heavy' or enumKeyText == 'heavyarmor' then return 'heavy' end
                if enumKeyText == 'medium' or enumKeyText == 'mediumarmor' then return 'medium' end
                if enumKeyText == 'light' or enumKeyText == 'lightarmor' then return 'light' end
            end
        end
    end

    local weightClassText = normalizeKey(weightClass)
    local skillText = normalizeKey(skillId)
    if weightClassText == 'heavy' or weightClassText == 'heavyarmor' or skillText == 'heavyarmor' then
        return 'heavy'
    end
    if weightClassText == 'medium' or weightClassText == 'mediumarmor' or skillText == 'mediumarmor' then
        return 'medium'
    end
    if weightClassText == 'light' or weightClassText == 'lightarmor' or skillText == 'lightarmor' then
        return 'light'
    end
    if isHeavyByWeight(slotRole, armorRecord) then return 'heavy' end
    if isMediumByWeight(slotRole, armorRecord) then return 'medium' end
    if isLightByWeight(slotRole, armorRecord) then return 'light' end
    return nil
end

local function getArmorWarmthProfile(regionCategory, armorClass)
    local configuredArmorWarmthByRegion = getBalanceTable('armorWarmthByRegion')
    if armorClass == 'heavy' then
        return resolveArmorWarmthProfileByRegion(configuredArmorWarmthByRegion.heavy, regionCategory)
    end
    if armorClass == 'medium' then
        return resolveArmorWarmthProfileByRegion(configuredArmorWarmthByRegion.medium, regionCategory)
    end
    if armorClass == 'light' then
        return resolveArmorWarmthProfileByRegion(configuredArmorWarmthByRegion.light, regionCategory)
    end
    return nil
end

local function getSurcoatArmorWarmthMultiplier(regionCategory, armorClass)
    if armorClass == 'heavy' then
        return resolveRegionValue(
            getBalanceTable('robeArmorWarmthMultiplierByRegion'),
            regionCategory,
            'temperatureBalanceConfig.robeArmorWarmthMultiplierByRegion'
        )
    end
    if armorClass == 'medium' then
        return resolveRegionValue(
            getBalanceTable('robeMediumArmorWarmthMultiplierByRegion'),
            regionCategory,
            'temperatureBalanceConfig.robeMediumArmorWarmthMultiplierByRegion'
        )
    end
    return 1.0
end

local function buildWarmthEntries(
    regionCategory,
    usesInteriorBase,
    targetTemperatureBeforeArmorBonus,
    options
)
    if types.Actor == nil
        or type(types.Actor.objectIsInstance) ~= 'function'
        or type(types.Actor.getEquipment) ~= 'function'
        or not types.Actor.objectIsInstance(self) then
        return {}
    end

    local equipmentOk, equipmentTable = pcall(types.Actor.getEquipment, self)
    if not equipmentOk or type(equipmentTable) ~= 'table' then
        return {}
    end

    local settings = type(options) == 'table' and options or {}
    local includeArmorBonuses = settings.includeArmorBonuses ~= false
    local entries = {}
    local isExteriorCell = usesInteriorBase ~= true
    local robeEquipped = isExteriorCell and isRobeEquipped() or false
    local nightTemperatureFactor = 0
    if isExteriorCell then
        if settings.nightTemperatureFactor ~= nil then
            nightTemperatureFactor = clamp(tonumber(settings.nightTemperatureFactor) or 0, 0, 1)
        else
            nightTemperatureFactor = getNightTemperatureFactor()
        end
    end
    local clearOrCloudyWeather = isExteriorCell and resolveClearOrCloudyWeatherValue(settings) or false
    local interiorArmorMultiplier = usesInteriorBase == true
        and resolveRegionValue(
            getBalanceTable('interiorArmorWarmthMultiplierByRegion'),
            regionCategory,
            'temperatureBalanceConfig.interiorArmorWarmthMultiplierByRegion'
        )
        or 1.0
    local armorTypeAvailable = types.Armor ~= nil and type(types.Armor.objectIsInstance) == 'function'
    local clothingTypeAvailable = types.Clothing ~= nil and type(types.Clothing.objectIsInstance) == 'function'

    for slotId, equippedItem in pairs(equipmentTable) do
        if equippedItem ~= nil then
            local totalWarmth = 0
            local displayRecord = nil
            local entrySource = nil
            local baseWarmth = 0
            local armorBonusWarmth = 0

            if clothingTypeAvailable then
                local clothingOk, isClothing = pcall(types.Clothing.objectIsInstance, equippedItem)
                if clothingOk and isClothing == true then
                    local clothingRecord = nil
                    if type(types.Clothing.record) == 'function' then
                        local recordOk, recordValue = pcall(types.Clothing.record, equippedItem)
                        if recordOk and isRecordObject(recordValue) then
                            clothingRecord = recordValue
                        end
                    end
                    totalWarmth = getClothingWarmthForEquippedItem(
                        slotId,
                        clothingRecord,
                        regionCategory,
                        isExteriorCell
                    )
                    displayRecord = clothingRecord
                    if totalWarmth > 0 then
                        entrySource = 'clothing'
                        baseWarmth = totalWarmth
                    end
                end
            end

            if totalWarmth <= 0 then
                local slotRole = getArmorSlotRole(slotId)
                if slotRole ~= nil then
                    local countThisItem = true
                    if armorTypeAvailable then
                        local typeOk, isArmor = pcall(types.Armor.objectIsInstance, equippedItem)
                        if typeOk and isArmor ~= true then
                            countThisItem = false
                        end
                    end
                    if countThisItem then
                        local armorRecord = getArmorRecordForItem(equippedItem)
                        if armorRecord ~= nil then
                            local armorClass = getArmorClassFromRecord(armorRecord, slotRole)
                            local profile = getArmorWarmthProfile(regionCategory, armorClass)
                            if profile ~= nil then
                                local slotBaseWarmth = tonumber(profile[slotRole])
                                assert(slotBaseWarmth ~= nil, string.format(
                                    '[SurvivalMode] Missing armor warmth value for "%s" in category "%s".',
                                    tostring(slotRole),
                                    tostring(regionCategory)
                                ))
                                totalWarmth = slotBaseWarmth * interiorArmorMultiplier
                                local shouldApplySurcoatMultiplier = (armorClass == 'heavy' or armorClass == 'medium')
                                    and (nightTemperatureFactor > 0 or not clearOrCloudyWeather or robeEquipped)
                                if shouldApplySurcoatMultiplier then
                                    local blockedByKeyword = type(
                                        armorWarmthBonuses.hasWarmthBonusKeywordMatchForEquippedArmorItem
                                    ) == 'function'
                                        and armorWarmthBonuses.hasWarmthBonusKeywordMatchForEquippedArmorItem(
                                            equippedItem
                                        ) == true
                                    if not blockedByKeyword then
                                        local surcoatMultiplier =
                                            getSurcoatArmorWarmthMultiplier(regionCategory, armorClass)
                                        if nightTemperatureFactor > 0 and clearOrCloudyWeather and not robeEquipped then
                                            surcoatMultiplier = 1.0
                                                + ((surcoatMultiplier - 1.0) * nightTemperatureFactor)
                                        end
                                        totalWarmth = totalWarmth
                                            * surcoatMultiplier
                                    end
                                end
                            end
                            baseWarmth = totalWarmth
                            if includeArmorBonuses then
                                armorBonusWarmth = tonumber(armorWarmthBonuses.getWarmthBonusForEquippedArmorItem(
                                    slotId,
                                    equippedItem,
                                    targetTemperatureBeforeArmorBonus
                                )) or 0
                            end
                            totalWarmth = baseWarmth + armorBonusWarmth
                            if totalWarmth > 0 then
                                entrySource = 'armor'
                            end
                            displayRecord = armorRecord
                        end
                    end
                end
            end

            if totalWarmth > 0 then
                entries[#entries + 1] = {
                    name = getEquipmentDisplayName(equippedItem, displayRecord),
                    warmth = totalWarmth,
                    source = entrySource,
                    baseWarmth = baseWarmth,
                    armorBonusWarmth = armorBonusWarmth,
                    sortOrder = getEquipmentSlotSortOrder(slotId),
                }
            end
        end
    end

    table.sort(entries, function(left, right)
        local leftOrder = tonumber(left.sortOrder) or 999
        local rightOrder = tonumber(right.sortOrder) or 999
        if leftOrder ~= rightOrder then
            return leftOrder < rightOrder
        end
        local leftName = tostring(left.name or '')
        local rightName = tostring(right.name or '')
        if leftName ~= rightName then
            return leftName < rightName
        end
        return (tonumber(left.warmth) or 0) > (tonumber(right.warmth) or 0)
    end)

    return entries
end

local function resolveWarmthComputationContext(
    regionCategory,
    usesInteriorBase,
    targetTemperatureBeforeArmorBonus,
    options
)
    local details = type(options) == 'table' and options or {}
    local normalizedRegionCategory = normalizeKey(regionCategory)
    local targetTemperature = tonumber(targetTemperatureBeforeArmorBonus) or 0
    local normalizedWeatherKey = normalizeKey(details.weatherKey)
    local clearOrCloudyWeather = resolveClearOrCloudyWeatherValue(details)
    local equipmentSignature = resolveEquipmentSignature(details)
    local exteriorCell = usesInteriorBase ~= true
    local nightTemperatureFactor = 0
    if exteriorCell then
        if details.nightTemperatureFactor ~= nil then
            nightTemperatureFactor = clamp(tonumber(details.nightTemperatureFactor) or 0, 0, 1)
        else
            nightTemperatureFactor = getNightTemperatureFactor()
        end
    end

    return {
        regionCategory = normalizedRegionCategory,
        usesInteriorBase = usesInteriorBase == true,
        targetTemperatureBeforeArmorBonus = targetTemperature,
        weatherKey = normalizedWeatherKey,
        clearOrCloudyWeather = clearOrCloudyWeather == true,
        equipmentSignature = equipmentSignature,
        nightTemperatureFactor = nightTemperatureFactor,
    }
end

local function buildModifierWarmthCacheKey(context)
    return table.concat({
        'modifier',
        context.regionCategory,
        boolToken(context.usesInteriorBase),
        context.equipmentSignature,
        context.weatherKey,
        boolToken(context.clearOrCloudyWeather),
        tostring(quantizeValue(context.nightTemperatureFactor, 0.05)),
    }, '|')
end

local function buildSpellWarmthCacheKey(context, campfireDominantSourceType, campfireWarmModifier)
    return table.concat({
        'spell',
        context.regionCategory,
        boolToken(context.usesInteriorBase),
        context.equipmentSignature,
        context.weatherKey,
        boolToken(context.clearOrCloudyWeather),
        tostring(quantizeValue(context.nightTemperatureFactor, 0.05)),
        tostring(roundToNearestInteger(context.targetTemperatureBeforeArmorBonus)),
        normalizeKey(campfireDominantSourceType),
        tostring(quantizeValue(campfireWarmModifier, WARMTH_DISPLAY_VALUE_STEP)),
    }, '|')
end

local function getModifierWarmthTotals(regionCategory, usesInteriorBase, options)
    local context = resolveWarmthComputationContext(regionCategory, usesInteriorBase, 0, options)
    local cacheKey = buildModifierWarmthCacheKey(context)
    local cached = readWarmthCache(cacheKey)
    if type(cached) == 'table' then
        return cached
    end

    local entries = buildWarmthEntries(
        context.regionCategory,
        context.usesInteriorBase,
        0,
        {
            includeArmorBonuses = false,
            clearOrCloudyWeather = context.clearOrCloudyWeather,
            weatherKey = context.weatherKey,
            equipmentSignature = context.equipmentSignature,
            nightTemperatureFactor = context.nightTemperatureFactor,
        }
    )

    local armorWarmth = 0
    local clothingWarmth = 0
    for _, entry in ipairs(entries) do
        local warmth = tonumber(entry.warmth) or 0
        if entry.source == 'clothing' then
            clothingWarmth = clothingWarmth + warmth
        elseif entry.source == 'armor' then
            armorWarmth = armorWarmth + warmth
        end
    end

    return writeWarmthCache(cacheKey, {
        armorWarmth = armorWarmth,
        clothingWarmth = clothingWarmth,
        totalWarmth = armorWarmth + clothingWarmth,
    })
end

local function buildWarmthSpell(
    regionCategory,
    usesInteriorBase,
    targetTemperatureBeforeArmorBonus,
    options
)
    local settings = type(options) == 'table' and options or {}
    local context = resolveWarmthComputationContext(
        regionCategory,
        usesInteriorBase,
        targetTemperatureBeforeArmorBonus,
        settings
    )
    local campfireDominantSourceType = normalizeKey(settings.campfireDominantSourceType)
    local campfireWarmModifier = math.max(0, tonumber(settings.campfireWarmModifier) or 0)
    local cacheKey = buildSpellWarmthCacheKey(context, campfireDominantSourceType, campfireWarmModifier)
    local cached = readWarmthCache(cacheKey)
    if cached ~= nil then
        if cached == false then
            return nil
        end
        return cached
    end

    local entries = buildWarmthEntries(
        context.regionCategory,
        context.usesInteriorBase,
        context.targetTemperatureBeforeArmorBonus,
        {
            includeArmorBonuses = true,
            clearOrCloudyWeather = context.clearOrCloudyWeather,
            weatherKey = context.weatherKey,
            equipmentSignature = context.equipmentSignature,
            nightTemperatureFactor = context.nightTemperatureFactor,
        }
    )

    local spellNameLines = {}
    local signatureParts = {}
    for _, entry in ipairs(entries) do
        local displayWarmth = quantizeWarmthValue(entry.warmth)
        local line = localize('warmth_item_line', {
            item = tostring(entry.name or localize('warmth_unknown_item_name')),
            warmth = formatWarmthPoints(displayWarmth),
        })
        spellNameLines[#spellNameLines + 1] = line
        signatureParts[#signatureParts + 1] = line
    end

    if campfireDominantSourceType == 'torch' and campfireWarmModifier > 0 then
        local torchDisplayWarmth = quantizeWarmthValue(campfireWarmModifier)
        local torchLine = localize('warmth_item_line', {
            item = localize('warmth_torch_label'),
            warmth = formatWarmthPoints(torchDisplayWarmth),
        })
        spellNameLines[#spellNameLines + 1] = torchLine
        signatureParts[#signatureParts + 1] = torchLine
    end

    if #spellNameLines == 0 then
        writeWarmthCache(cacheKey, false)
        return nil
    end

    return writeWarmthCache(cacheKey, {
        stageId = table.concat(signatureParts, '|'),
        spellName = table.concat(spellNameLines, '\n'),
    })
end

local function isLikelyWarmthSpellRecord(spell)
    if type(spell) ~= 'table' then
        return false
    end
    if spell.type ~= nil and spell.type ~= core.magic.SPELL_TYPE.Ability then
        return false
    end

    local spellId = normalizeKey(spell.id)
    if type(spell.effects) == 'table' then
        for _, effect in ipairs(spell.effects) do
            if type(effect) == 'table' and normalizeKey(effect.id) == WARMTH_DISPLAY_EFFECT_ID then
                return true
            end
        end
    end
    local spellName = normalizeKey(spell.name)
    return spellId ~= ''
        and string.sub(spellId, 1, 9) == 'sn_needs_'
        and spellName ~= ''
        and string.sub(spellName, 1, #normalizeKey(WARMTH_ABILITY_NAME)) == normalizeKey(WARMTH_ABILITY_NAME)
end

local function removeAppliedSpell(knownSpellIds)
    if types.Actor.objectIsInstance(self) then
        local actorSpells = types.Actor.spells(self)
        local removeSpellIds = {}
        if type(state.appliedSpellId) == 'string' and state.appliedSpellId ~= '' then
            removeSpellIds[state.appliedSpellId] = true
        end
        for spellId, enabled in pairs(state.trackedSpellIds) do
            if enabled == true and type(spellId) == 'string' and spellId ~= '' then
                removeSpellIds[spellId] = true
            end
        end
        for _, spell in pairs(actorSpells) do
            if isLikelyWarmthSpellRecord(spell) and type(spell.id) == 'string' and spell.id ~= '' then
                removeSpellIds[spell.id] = true
            end
        end
        for spellId, _ in pairs(removeSpellIds) do
            pcall(function() actorSpells:remove(spellId) end)
            if type(knownSpellIds) == 'table' then
                knownSpellIds[spellId] = nil
            end
        end
    end
    state.trackedSpellIds = {}
    state.appliedSpellId = nil
end

local function sync(context)
    local currentTime = now()
    local syncSignature = buildSyncSignature(context)
    local hasAppliedSpell = type(state.appliedSpellId) == 'string' and trim(state.appliedSpellId) ~= ''
    local hasPendingRequest = type(state.pendingRequest) == 'table'
    local elapsedSinceLastBuild = currentTime - (tonumber(state.lastSyncBuildTime) or -math.huge)
    local withinRebuildInterval = elapsedSinceLastBuild >= 0
        and elapsedSinceLastBuild < WARMTH_SYNC_MIN_REBUILD_INTERVAL_SECONDS
    if state.lastSyncSignature == syncSignature
        and (hasAppliedSpell or hasPendingRequest)
        and withinRebuildInterval then
        return
    end

    state.lastSyncSignature = syncSignature
    state.lastSyncBuildTime = currentTime

    local spell = buildWarmthSpell(
        context ~= nil and context.regionCategory or nil,
        context ~= nil and context.usesInteriorBase == true,
        context ~= nil and context.targetTemperatureBeforeArmorBonus or 0,
        {
            campfireWarmModifier = context ~= nil and context.campfireWarmModifier or 0,
            campfireDominantSourceType = context ~= nil and context.campfireDominantSourceType or '',
        }
    )
    local knownSpellIds = context ~= nil and context.knownSpellIds or nil
    if spell == nil then
        state.pendingRequest = nil
        state.appliedStageId = nil
        removeAppliedSpell(knownSpellIds)
        return
    end

    if state.appliedStageId == spell.stageId then
        if type(state.appliedSpellId) == 'string' and state.appliedSpellId ~= '' then
            return
        end
        if type(state.pendingRequest) == 'table' and currentTime - (tonumber(state.pendingRequest.sentAt) or 0) < 1.0 then
            return
        end
    else
        state.appliedStageId = spell.stageId
    end

    if type(state.pendingRequest) == 'table' then
        if state.pendingRequest.stageId == spell.stageId then
            if currentTime - (tonumber(state.pendingRequest.sentAt) or 0) < 1.0 then
                return
            end
        elseif currentTime - (tonumber(state.pendingRequest.sentAt) or 0) < 1.0 then
            return
        end
    end

    state.requestCounter = (tonumber(state.requestCounter) or 0) + 1
    local requestId = state.requestCounter
    state.pendingRequest = {
        requestId = requestId,
        stageId = spell.stageId,
        sentAt = currentTime,
    }

    local playerObject = self.object or self
    local ok, err = pcall(function()
        core.sendGlobalEvent(NEEDS_DYNAMIC_SPELL_REQUEST_EVENT, {
            player = playerObject,
            category = 'warmth',
            stageId = spell.stageId,
            spellName = spell.spellName,
            requestId = requestId,
            effects = {
                {
                    id = WARMTH_DISPLAY_EFFECT_ID,
                    magnitudeMin = 0,
                    magnitudeMax = 0,
                    duration = 0,
                    range = 'self',
                },
            },
        })
    end)
    if not ok then
        state.pendingRequest = nil
        print(string.format('[SurvivalMode] Failed to request dynamic warmth spell: %s', tostring(err)))
    end
end

local function onDynamicSpellReady(data, knownSpellIds)
    if type(data) ~= 'table' or normalizeKey(data.category) ~= 'warmth' or not types.Actor.objectIsInstance(self) then
        return false
    end
    if type(state.pendingRequest) ~= 'table' or tonumber(data.requestId) ~= state.pendingRequest.requestId then
        return true
    end
    local pending = state.pendingRequest
    state.pendingRequest = nil
    if state.appliedStageId ~= pending.stageId then
        return true
    end

    local spellId = type(data.spellId) == 'string' and trim(data.spellId) or trim(tostring(data.spellId or ''))
    if spellId == '' then
        return true
    end

    local actorSpells = types.Actor.spells(self)
    local previousSpellId = type(state.appliedSpellId) == 'string' and trim(state.appliedSpellId) or ''
    local appliedSpellId = nil
    local function tryAddById(idValue)
        local idString = type(idValue) == 'string' and trim(idValue) or ''
        if idString == '' then
            return false, 'empty id'
        end
        local ok, err = pcall(function() actorSpells:add(idString) end)
        return ok, ok and idString or err
    end

    local ok, valueOrError = tryAddById(spellId)
    if ok then
        appliedSpellId = valueOrError
    else
        local record = core.magic.spells.records[spellId] or core.magic.spells.records[string.lower(spellId)]
        if record ~= nil then
            local okRecord = pcall(function() actorSpells:add(record) end)
            if okRecord then
                appliedSpellId = tostring(record.id or spellId)
            end
        end
    end

    if appliedSpellId ~= nil and appliedSpellId ~= '' then
        state.appliedSpellId = appliedSpellId
        state.applyFailures[spellId] = nil
        state.trackedSpellIds[appliedSpellId] = true
        if type(knownSpellIds) == 'table' then
            knownSpellIds[appliedSpellId] = true
        end
        if previousSpellId ~= '' and previousSpellId ~= appliedSpellId then
            pcall(function() actorSpells:remove(previousSpellId) end)
            state.trackedSpellIds[previousSpellId] = nil
            if type(knownSpellIds) == 'table' then
                knownSpellIds[previousSpellId] = nil
            end
        end
    elseif state.applyFailures[spellId] ~= true then
        state.applyFailures[spellId] = true
        print(string.format('[SurvivalMode] Failed to apply dynamic warmth spell "%s": %s', spellId, tostring(valueOrError)))
    end

    return true
end

local function reset(knownSpellIds)
    state.requestCounter = 0
    state.pendingRequest = nil
    state.appliedStageId = nil
    state.applyFailures = {}
    state.lastSyncSignature = nil
    state.lastSyncBuildTime = -math.huge
    clearWarmthCache()
    removeAppliedSpell(knownSpellIds)
end

return {
    sync = sync,
    reset = reset,
    onDynamicSpellReady = onDynamicSpellReady,
    getModifierWarmthTotals = getModifierWarmthTotals,
}
