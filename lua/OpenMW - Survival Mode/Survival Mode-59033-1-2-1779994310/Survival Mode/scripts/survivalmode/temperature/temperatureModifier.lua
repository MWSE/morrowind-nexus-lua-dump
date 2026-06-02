local M = {}

function M.create(deps)
    local core = assert(deps.core)
    local self = assert(deps.self)
    local types = assert(deps.types)
    local temperature = assert(deps.temperature)
    local temperatureBalanceConfig = assert(deps.temperatureBalanceConfig)
    local temperatureDebug = assert(deps.temperatureDebug)
    local state = assert(deps.state)
    local wetnessSystem = assert(deps.wetnessSystem)
    local isTemperatureSystemEnabled = assert(deps.isTemperatureSystemEnabled)
    local isSeasonalTemperatureVariationsEnabled = assert(deps.isSeasonalTemperatureVariationsEnabled)
    local getActiveWellHydratedStage = assert(deps.getActiveWellHydratedStage)
    local clamp = assert(deps.clamp)
    local trim = assert(deps.trim)
    local normalizeKey = assert(deps.normalizeKey)
    local normalizeWeatherKey = assert(deps.normalizeWeatherKey)
    local tryGetEnumValue = assert(deps.tryGetEnumValue)

    function temperatureDebug.getRegionTransitionDelayRealSeconds()
        local configured = tonumber(temperatureBalanceConfig.regionTransition.delayTransitionTime)
        assert(
            configured ~= nil,
            '[SurvivalMode] temperatureBalanceConfig.regionTransition.delayTransitionTime must be a number.'
        )
        return math.max(0, configured)
    end

    function temperatureDebug.getRegionTransitionRateLimitPerSecond()
        return 2.0
    end

    function temperatureDebug.toRealSeconds(elapsedSeconds)
        local seconds = tonumber(elapsedSeconds) or 0
        if seconds <= 0 then
            return 0
        end

        local gameTimeScale = 1
        if type(core.getGameTimeScale) == 'function' then
            gameTimeScale = tonumber(core.getGameTimeScale()) or 1
        end

        local simulationTimeScale = 1
        if type(core.getSimulationTimeScale) == 'function' then
            simulationTimeScale = tonumber(core.getSimulationTimeScale()) or 1
        end

        local combinedScale = gameTimeScale * simulationTimeScale
        if combinedScale <= 0 then
            combinedScale = 1
        end

        return seconds / combinedScale
    end

    function temperatureDebug.buildExteriorRegionTransitionKey(regionModifierRaw)
        if type(regionModifierRaw) ~= 'table' or regionModifierRaw.isExteriorCell ~= true then
            return ''
        end

        local matchedRegionName = normalizeKey(regionModifierRaw.matchedRegionName)
        if matchedRegionName ~= '' then
            return 'region:' .. matchedRegionName
        end

        local category = normalizeKey(regionModifierRaw.category)
        if category ~= '' then
            return 'category:' .. category
        end

        return ''
    end

    local function addWeatherAlias(aliasMap, aliasValue, canonicalKey)
        local aliasToken = normalizeWeatherKey(aliasValue)
        if aliasToken == '' then
            return
        end

        aliasMap[aliasToken] = canonicalKey
    end

    local WEATHER_ALIASES = {
        rain = { 'rain' },
        thunder = { 'thunder', 'thunderstorm' },
        snow = { 'snow' },
        blizzard = { 'blizzard' },
        ash_storm = { 'ash storm', 'ashstorm' },
        blight = { 'blight' },
    }

    local function buildWeatherAliasMap()
        local aliasMap = {}
        local configuredModifiers = type(temperatureDebug.weatherModifiers) == 'table' and temperatureDebug.weatherModifiers or {}
        for weatherKey, _ in pairs(configuredModifiers) do
            local canonicalKey = normalizeKey(tostring(weatherKey or ''))
            if canonicalKey ~= '' then
                addWeatherAlias(aliasMap, canonicalKey, canonicalKey)
                addWeatherAlias(aliasMap, canonicalKey:gsub('_', ' '), canonicalKey)
            end
        end

        local configuredAliases = WEATHER_ALIASES

        for weatherKey, aliasList in pairs(configuredAliases) do
            local canonicalKey = normalizeKey(tostring(weatherKey or ''))
            if canonicalKey ~= '' then
                addWeatherAlias(aliasMap, canonicalKey, canonicalKey)
                addWeatherAlias(aliasMap, canonicalKey:gsub('_', ' '), canonicalKey)
                if type(aliasList) == 'table' then
                    for _, aliasValue in ipairs(aliasList) do
                        addWeatherAlias(aliasMap, aliasValue, canonicalKey)
                    end
                end
            end
        end

        return aliasMap
    end

    local WEATHER_ALIAS_MAP = buildWeatherAliasMap()

    function temperatureDebug.createModifierEntry(modifierId, warmValue, coldValue)
        local normalizedId = normalizeKey(tostring(modifierId or ''))
        if normalizedId == '' then
            normalizedId = 'unknown'
        end

        return {
            id = normalizedId,
            label = temperatureDebug.modifierLabels[normalizedId] or normalizedId,
            warmModifier = tonumber(warmValue) or 0,
            coldModifier = tonumber(coldValue) or 0,
        }
    end

    function temperatureDebug.getRobeWarmthForRegion(regionCategory)
        local category = normalizeKey(regionCategory)
        local configured = tonumber(temperatureDebug.robeWarmthByRegion[category])
        if configured ~= nil then
            return configured
        end
        if category == 'very_hot' then
            configured = tonumber(temperatureDebug.robeWarmthByRegion.hot)
                or tonumber(temperatureDebug.robeWarmthByRegion.warm)
            if configured ~= nil then
                return configured
            end
        elseif category == 'warm' then
            configured = tonumber(temperatureDebug.robeWarmthByRegion.hot)
                or tonumber(temperatureDebug.robeWarmthByRegion.neutral)
            if configured ~= nil then
                return configured
            end
        elseif category == 'chilly' then
            configured = tonumber(temperatureDebug.robeWarmthByRegion.cold)
                or tonumber(temperatureDebug.robeWarmthByRegion.neutral)
            if configured ~= nil then
                return configured
            end
        elseif category == 'very_cold' then
            configured = tonumber(temperatureDebug.robeWarmthByRegion.cold)
                or tonumber(temperatureDebug.robeWarmthByRegion.chilly)
            if configured ~= nil then
                return configured
            end
        end
        configured = tonumber(temperatureDebug.robeWarmthByRegion.neutral)
        if configured ~= nil then
            return configured
        end
        local robeWarmth = tonumber(temperatureDebug.clothingWarmth.robe)
        assert(robeWarmth ~= nil, '[SurvivalMode] temperatureBalanceConfig.clothingWarmth.robe must be a number.')
        return robeWarmth
    end

    function temperatureDebug.resolveArmorWarmthProfileByRegion(profileByRegion, regionCategory)
        if type(profileByRegion) ~= 'table' then
            return nil
        end

        local category = normalizeKey(regionCategory)
        if category ~= '' and type(profileByRegion[category]) == 'table' then
            return profileByRegion[category]
        end

        if category == 'very_hot' then
            if type(profileByRegion.hot) == 'table' then
                return profileByRegion.hot
            end
            if type(profileByRegion.warm) == 'table' then
                return profileByRegion.warm
            end
        end
        if category == 'warm' then
            if type(profileByRegion.hot) == 'table' then
                return profileByRegion.hot
            end
            if type(profileByRegion.neutral) == 'table' then
                return profileByRegion.neutral
            end
        end
        if category == 'chilly' then
            if type(profileByRegion.cold) == 'table' then
                return profileByRegion.cold
            end
            if type(profileByRegion.neutral) == 'table' then
                return profileByRegion.neutral
            end
        end
        if category == 'very_cold' then
            if type(profileByRegion.cold) == 'table' then
                return profileByRegion.cold
            end
            if type(profileByRegion.chilly) == 'table' then
                return profileByRegion.chilly
            end
        end

        if type(profileByRegion.neutral) == 'table' then
            return profileByRegion.neutral
        end

        if type(profileByRegion.hot) == 'table' then
            return profileByRegion.hot
        end

        if type(profileByRegion.cold) == 'table' then
            return profileByRegion.cold
        end

        for _, value in pairs(profileByRegion) do
            if type(value) == 'table' then
                return value
            end
        end

        return nil
    end

    function temperatureDebug.getClothingWarmthForEquippedItem(slotId, clothingRecord, regionCategory, isExteriorCell)
        local equipmentSlots = (types.Actor ~= nil and types.Actor.EQUIPMENT_SLOT) or {}
        local clothingTypes = (types.Clothing ~= nil and types.Clothing.TYPE) or {}

        local function matchesClothingType(enumName)
            if type(clothingRecord) ~= 'table' then
                return false
            end

            local expectedType = tryGetEnumValue(clothingTypes, enumName)
            if expectedType == nil then
                return false
            end

            return clothingRecord.type == expectedType
        end

        local numericSlotId = tonumber(slotId)
        if numericSlotId ~= nil then
            if numericSlotId == equipmentSlots.Boots
                or numericSlotId == equipmentSlots.LeftGauntlet
                or numericSlotId == equipmentSlots.RightGauntlet then
                return temperatureDebug.clothingWarmth.glovesOrShoes
            end

            if numericSlotId == equipmentSlots.Robe then
                if isExteriorCell ~= true then
                    return 0
                end
                return temperatureDebug.getRobeWarmthForRegion(regionCategory)
            end

            if numericSlotId == equipmentSlots.Shirt or numericSlotId == equipmentSlots.Pants then
                return temperatureDebug.clothingWarmth.default
            end
        end

        if matchesClothingType('Robe') then
            if isExteriorCell ~= true then
                return 0
            end
            return temperatureDebug.getRobeWarmthForRegion(regionCategory)
        end

        if matchesClothingType('Shoes') or matchesClothingType('Glove') or matchesClothingType('Gloves') then
            return temperatureDebug.clothingWarmth.glovesOrShoes
        end

        if matchesClothingType('Shirt') or matchesClothingType('Pants') then
            return temperatureDebug.clothingWarmth.default
        end

        return 0
    end

    function temperatureDebug.isRobeEquipped()
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
                local numericSlotId = tonumber(slotId)
                if numericSlotId ~= nil and numericSlotId == equipmentSlots.Robe then
                    return true
                end

                if type(types.Clothing.record) == 'function' then
                    local recordOk, recordValue = pcall(types.Clothing.record, equippedItem)
                    if recordOk and type(recordValue) == 'table' and robeType ~= nil and recordValue.type == robeType then
                        return true
                    end
                end
            end
        end

        return false
    end

    function temperatureDebug.getClothingModifierEntry(regionCategory, usesInteriorBase)
        if types.Actor == nil
            or type(types.Actor.objectIsInstance) ~= 'function'
            or type(types.Actor.getEquipment) ~= 'function'
            or not types.Actor.objectIsInstance(self)
            or types.Clothing == nil
            or type(types.Clothing.objectIsInstance) ~= 'function' then
            return temperatureDebug.createModifierEntry('clothing', 0, 0)
        end

        local ok, equipmentTable = pcall(types.Actor.getEquipment, self)
        if not ok or type(equipmentTable) ~= 'table' then
            return temperatureDebug.createModifierEntry('clothing', 0, 0)
        end

        local totalWarm = 0
        local isExteriorCell = usesInteriorBase ~= true
        for slotId, equippedItem in pairs(equipmentTable) do
            if equippedItem ~= nil and types.Clothing.objectIsInstance(equippedItem) then
                local clothingRecord = nil
                if type(types.Clothing.record) == 'function' then
                    local recordOk, recordValue = pcall(types.Clothing.record, equippedItem)
                    if recordOk and type(recordValue) == 'table' then
                        clothingRecord = recordValue
                    end
                end

                totalWarm = totalWarm + temperatureDebug.getClothingWarmthForEquippedItem(
                    slotId,
                    clothingRecord,
                    regionCategory,
                    isExteriorCell
                )
            end
        end

        return temperatureDebug.createModifierEntry('clothing', totalWarm, 0)
    end

    function temperatureDebug.getHeavyArmorWarmthProfile(regionCategory)
        return temperatureDebug.resolveArmorWarmthProfileByRegion(
            temperatureDebug.heavyArmorWarmthByRegion,
            regionCategory
        )
    end

    function temperatureDebug.getLightArmorWarmthProfile(regionCategory)
        return temperatureDebug.resolveArmorWarmthProfileByRegion(
            temperatureDebug.lightArmorWarmthByRegion,
            regionCategory
        )
    end

    function temperatureDebug.getArmorWarmthProfile(regionCategory, armorClass)
        if armorClass == 'heavy' then
            return temperatureDebug.getHeavyArmorWarmthProfile(regionCategory)
        end
        if armorClass == 'medium' then
            return temperatureDebug.resolveArmorWarmthProfileByRegion(
                temperatureDebug.mediumArmorWarmthByRegion,
                regionCategory
            )
        end
        if armorClass == 'light' then
            return temperatureDebug.getLightArmorWarmthProfile(regionCategory)
        end
        return nil
    end

    function temperatureDebug.getArmorSlotRole(slotId)
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
        if matchesSlotConstant(equipmentSlots.LeftGauntlet) or matchesSlotConstant(equipmentSlots.RightGauntlet) then
            return 'gauntlet'
        end
        if matchesSlotConstant(equipmentSlots.LeftPauldron) or matchesSlotConstant(equipmentSlots.RightPauldron) then
            return 'pauldron'
        end

        return nil
    end

    function temperatureDebug.getArmorRecordForItem(equippedItem)
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

    function temperatureDebug.getArmorWeightClassInfo(armorRecord)
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

    function temperatureDebug.getArmorWeightValue(armorRecord)
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

    function temperatureDebug.isHeavyByWeight(slotRole, armorRecord)
        if slotRole == nil then
            return false
        end

        local weight = temperatureDebug.getArmorWeightValue(armorRecord)
        if weight == nil then
            return false
        end

        local slotConfig = temperatureDebug.armorWeightClassBySlot[slotRole]
        local threshold = slotConfig ~= nil and tonumber(slotConfig.heavyMinExclusive) or nil
        if threshold == nil then
            return false
        end

        return weight > threshold
    end

    function temperatureDebug.isLightByWeight(slotRole, armorRecord)
        if slotRole == nil then
            return false
        end

        local weight = temperatureDebug.getArmorWeightValue(armorRecord)
        if weight == nil then
            return false
        end

        local slotConfig = temperatureDebug.armorWeightClassBySlot[slotRole]
        local maxWeight = slotConfig ~= nil and tonumber(slotConfig.lightMax) or nil
        if maxWeight == nil then
            return false
        end

        return weight <= maxWeight
    end

    function temperatureDebug.isMediumByWeight(slotRole, armorRecord)
        if slotRole == nil then
            return false
        end

        local weight = temperatureDebug.getArmorWeightValue(armorRecord)
        if weight == nil then
            return false
        end

        local slotConfig = temperatureDebug.armorWeightClassBySlot[slotRole]
        local lightMax = slotConfig ~= nil and tonumber(slotConfig.lightMax) or nil
        local heavyThreshold = slotConfig ~= nil and tonumber(slotConfig.heavyMinExclusive) or nil
        if lightMax == nil or heavyThreshold == nil then
            return false
        end

        return weight > lightMax and weight <= heavyThreshold
    end

    function temperatureDebug.getArmorClassFromRecord(armorRecord, slotRole)
        local weightClass, skillId = temperatureDebug.getArmorWeightClassInfo(armorRecord)

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

        if temperatureDebug.isHeavyByWeight(slotRole, armorRecord) then
            return 'heavy'
        end
        if temperatureDebug.isMediumByWeight(slotRole, armorRecord) then
            return 'medium'
        end
        if temperatureDebug.isLightByWeight(slotRole, armorRecord) then
            return 'light'
        end

        return nil
    end

    function temperatureDebug.getWeatherApi()
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

    function temperatureDebug.callWeatherApi(weatherApi, methodName, cell)
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

    function temperatureDebug.getCurrentWeatherRecord()
        local weatherApi = temperatureDebug.getWeatherApi()
        if weatherApi == nil then
            return nil
        end

        local currentCell = self.cell
        if currentCell == nil then
            return nil
        end

        return temperatureDebug.callWeatherApi(weatherApi, 'getCurrent', currentCell)
    end

    function temperatureDebug.getCanonicalWeatherKeyFromKnownRecords(weatherRecord)
        if weatherRecord == nil then
            return nil
        end

        local weatherApi = temperatureDebug.getWeatherApi()
        if weatherApi == nil then
            return nil
        end

        local records = weatherApi.records
        local recordsType = type(records)
        if recordsType ~= 'table' and recordsType ~= 'userdata' then
            return nil
        end

        local function eachWeatherNameForKey(canonicalKey, callback)
            if type(canonicalKey) ~= 'string' or canonicalKey == '' then
                return
            end

            local variants = {
                canonicalKey,
                canonicalKey:gsub('_', ' '),
                canonicalKey:gsub('_', ''),
            }

            local aliasList = WEATHER_ALIASES[canonicalKey]
            if type(aliasList) == 'table' then
                for _, aliasValue in ipairs(aliasList) do
                    if type(aliasValue) == 'string' and aliasValue ~= '' then
                        variants[#variants + 1] = aliasValue
                    end
                end
            end

            local seen = {}
            for _, rawVariant in ipairs(variants) do
                if type(rawVariant) == 'string' and rawVariant ~= '' then
                    local compact = rawVariant
                    local withSpaces = rawVariant:gsub('_', ' ')
                    local titleCase = withSpaces:gsub('(%a)([%w_]*)', function(first, rest)
                        return string.upper(first) .. string.lower(rest)
                    end)

                    local emit = {
                        rawVariant,
                        compact,
                        withSpaces,
                        titleCase,
                        string.lower(compact),
                        string.lower(withSpaces),
                        string.upper(compact),
                        string.upper(withSpaces),
                    }

                    for _, candidate in ipairs(emit) do
                        if type(candidate) == 'string' and candidate ~= '' and seen[candidate] ~= true then
                            seen[candidate] = true
                            callback(candidate)
                        end
                    end
                end
            end
        end

        for canonicalKey, _ in pairs(temperatureDebug.weatherModifiers) do
            local matched = false
            eachWeatherNameForKey(canonicalKey, function(candidateName)
                if matched then
                    return
                end
                local candidateRecord = records[candidateName]
                if candidateRecord ~= nil and candidateRecord == weatherRecord then
                    matched = true
                end
            end)
            if matched then
                return canonicalKey
            end
        end

        return nil
    end

    function temperatureDebug.getCanonicalWeatherKey(weatherRecord)
        if weatherRecord == nil then
            return nil
        end
        local directKnownMatch = temperatureDebug.getCanonicalWeatherKeyFromKnownRecords(weatherRecord)
        if directKnownMatch ~= nil and directKnownMatch ~= '' then
            return directKnownMatch
        end

        if type(weatherRecord) ~= 'string' and type(weatherRecord) ~= 'number' then
            local isStorm = false
            local stormOk, stormValue = pcall(function()
                return weatherRecord.isStorm
            end)
            if stormOk and stormValue == true then
                isStorm = true
            end

            local rainEffect = ''
            local rainOk, rainValue = pcall(function()
                return weatherRecord.rainEffect
            end)
            if rainOk and type(rainValue) == 'string' then
                rainEffect = normalizeWeatherKey(rainValue)
            end

            local particleEffect = ''
            local particleOk, particleValue = pcall(function()
                return weatherRecord.particleEffect
            end)
            if particleOk and type(particleValue) == 'string' then
                particleEffect = normalizeWeatherKey(particleValue)
            end

            if particleEffect:find('blight', 1, true) ~= nil then
                return 'blight'
            end
            if particleEffect:find('ash', 1, true) ~= nil then
                return 'ash_storm'
            end
            if rainEffect:find('snow', 1, true) ~= nil then
                if isStorm then
                    return 'blizzard'
                end
                return 'snow'
            end
            if rainEffect:find('rain', 1, true) ~= nil then
                if isStorm then
                    return 'thunder'
                end
                return 'rain'
            end
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

        local token = normalizeWeatherKey(weatherText)
        if token == '' then
            return nil
        end

        local isStorm = false
        local stormOk, stormValue = pcall(function()
            return weatherRecord.isStorm
        end)
        if stormOk and stormValue == true then
            isStorm = true
        end

        if token:find('blight', 1, true) ~= nil then
            return 'blight'
        end
        if token:find('ashstorm', 1, true) ~= nil or token:find('ash', 1, true) ~= nil then
            return 'ash_storm'
        end
        if token:find('blizzard', 1, true) ~= nil then
            return 'blizzard'
        end
        if token:find('snow', 1, true) ~= nil then
            if isStorm then
                return 'blizzard'
            end
            return 'snow'
        end
        if token:find('thunder', 1, true) ~= nil then
            return 'thunder'
        end
        if token:find('rain', 1, true) ~= nil then
            if isStorm then
                return 'thunder'
            end
            return 'rain'
        end

        local direct = WEATHER_ALIAS_MAP[token]
        if direct ~= nil and direct ~= '' then
            return direct
        end

        return nil
    end

    function temperatureDebug.getWeatherWarmthDelta(weatherKey)
        if weatherKey == nil then
            return 0
        end

        local configuredValue = tonumber(temperatureDebug.weatherModifiers[weatherKey])
        if configuredValue == nil then
            return 0
        end

        return configuredValue
    end

    function temperatureDebug.shouldStartWeathermultiplier(weatherKey, projectedTickAmount)
        local normalizedWeatherKey = normalizeKey(weatherKey)
        if normalizedWeatherKey == '' then
            return false
        end

        local tickAmount = tonumber(projectedTickAmount) or 0
        if temperatureDebug.weathermultiplierRequiresDecreasing[normalizedWeatherKey] == true then
            return tickAmount < 0
        end
        if temperatureDebug.weathermultiplierRequiresIncreasing[normalizedWeatherKey] == true then
            return tickAmount > 0
        end

        return true
    end

    function temperatureDebug.getTemperatureTickDirection(projectedTickAmount)
        local tickAmount = tonumber(projectedTickAmount) or 0
        if tickAmount > 0 then
            return 1
        end
        if tickAmount < 0 then
            return -1
        end
        return 0
    end

    function temperatureDebug.hasReachedTemperaturemultiplierTarget(multiplierState)
        if type(multiplierState) ~= 'table' or multiplierState.active ~= true then
            return true
        end

        local targetTemperature = tonumber(multiplierState.targetTemperature)
        if targetTemperature == nil then
            return true
        end

        local direction = tonumber(multiplierState.direction) or 0
        local currentTemperature = tonumber(state.temperature) or 0
        if direction > 0 then
            return currentTemperature >= targetTemperature
        end
        if direction < 0 then
            return currentTemperature <= targetTemperature
        end
        return true
    end

    function temperatureDebug.clearTemperaturemultiplier(sourceKey)
        if type(state.temperaturemultiplier) ~= 'table' then
            state.temperaturemultiplier = temperatureDebug.createTemperaturemultiplier()
        end

        if sourceKey ~= nil and sourceKey ~= '' then
            local multiplierSource = normalizeKey(state.temperaturemultiplier.source)
            local requestedSource = normalizeKey(sourceKey)
            if multiplierSource ~= '' and multiplierSource ~= requestedSource then
                return
            end
        end

        state.temperaturemultiplier.active = false
        state.temperaturemultiplier.source = ''
        state.temperaturemultiplier.targetTemperature = nil
        state.temperaturemultiplier.direction = 0
        state.temperaturemultiplier.multiplier = 1.0
    end

    function temperatureDebug.beginTemperaturemultiplier(
        sourceKey,
        projectedTickAmount,
        targetTemperature,
        multiplier,
        replaceExisting
    )
        if type(state.temperaturemultiplier) ~= 'table' then
            state.temperaturemultiplier = temperatureDebug.createTemperaturemultiplier()
        end

        local normalizedSource = normalizeKey(sourceKey)
        if normalizedSource == '' then
            normalizedSource = 'generic'
        end

        if state.temperaturemultiplier.active == true then
            if replaceExisting ~= true then
                return false
            end
            temperatureDebug.clearTemperaturemultiplier()
        end

        local direction = temperatureDebug.getTemperatureTickDirection(projectedTickAmount)
        local target = tonumber(targetTemperature)
        local resolvedMultiplier = tonumber(multiplier) or 1.0
        if resolvedMultiplier < 1.0 then
            resolvedMultiplier = 1.0
        end
        if direction == 0 or target == nil or resolvedMultiplier <= 1.0 then
            return false
        end

        state.temperaturemultiplier.active = true
        state.temperaturemultiplier.source = normalizedSource
        state.temperaturemultiplier.targetTemperature = target
        state.temperaturemultiplier.direction = direction
        state.temperaturemultiplier.multiplier = resolvedMultiplier

        if temperatureDebug.hasReachedTemperaturemultiplierTarget(state.temperaturemultiplier) then
            temperatureDebug.clearTemperaturemultiplier()
            return false
        end

        return true
    end

    function temperatureDebug.getActiveTemperaturemultiplierMultiplier()
        if type(state.temperaturemultiplier) ~= 'table' then
            state.temperaturemultiplier = temperatureDebug.createTemperaturemultiplier()
        end

        if state.temperaturemultiplier.active ~= true then
            return 1.0
        end

        local currentDirection = temperatureDebug.getTemperatureTickDirection(state.temperatureCurrentTickAmount)
        local multiplierDirection = tonumber(state.temperaturemultiplier.direction) or 0
        if currentDirection == 0 or multiplierDirection ~= currentDirection
            or temperatureDebug.hasReachedTemperaturemultiplierTarget(state.temperaturemultiplier) then
            temperatureDebug.clearTemperaturemultiplier()
            return 1.0
        end

        return math.max(1.0, tonumber(state.temperaturemultiplier.multiplier) or 1.0)
    end

    function temperatureDebug.getInteriorRegionmultiplierMultiplier(projectedTickAmount)
        if state.temperatureUsesInteriorBase ~= true then
            return 1.0
        end

        local multiplier = tonumber(temperatureDebug.interiorRegionmultiplier.multiplier) or 10.0
        if multiplier < 1.0 then
            multiplier = 1.0
        end

        local tickAmount = tonumber(projectedTickAmount) or 0
        local regionCategory = normalizeKey(state.temperatureRegionCategory)
        if (regionCategory == 'chilly' or regionCategory == 'cold' or regionCategory == 'very_cold') and tickAmount > 0 then
            return multiplier
        end
        if (regionCategory == 'warm' or regionCategory == 'hot' or regionCategory == 'very_hot') and tickAmount < 0 then
            return multiplier
        end

        return 1.0
    end

    function temperatureDebug.beginWeathermultiplier(projectedTickAmount, targetTemperature)
        local multiplier = tonumber(temperatureDebug.weathermultiplier.multiplier) or 1.0
        temperatureDebug.beginTemperaturemultiplier('weather', projectedTickAmount, targetTemperature, multiplier, true)
    end

    function temperatureDebug.getCurrentTemperatureTickMultiplier(elapsed)
        local _ = elapsed

        local wetnessTickMultiplier = 1.0
        local isTemperatureDecreasing = (tonumber(state.temperatureCurrentTickAmount) or 0) < 0
        if type(wetnessSystem.getTemperatureTickMultiplier) == 'function' then
            wetnessTickMultiplier = tonumber(wetnessSystem.getTemperatureTickMultiplier(isTemperatureDecreasing)) or 1.0
            if wetnessTickMultiplier < 1.0 then
                wetnessTickMultiplier = 1.0
            end
        end

        local heatSourceTickMultiplier = 1.0
        local campfireConfig = type(temperatureBalanceConfig.campfire) == 'table' and temperatureBalanceConfig.campfire or nil
        local configuredHeatSourceTickMultiplier = campfireConfig ~= nil
                and tonumber(campfireConfig.temperatureTickMultiplierWhenNearSource)
            or nil
        if configuredHeatSourceTickMultiplier ~= nil and configuredHeatSourceTickMultiplier > 1.0 then
            local isTemperatureIncreasing = (tonumber(state.temperatureCurrentTickAmount) or 0) > 0
            if isTemperatureIncreasing and type(state.temperatureModifierEntries) == 'table' then
                local hasActiveHeatSource = false
                for _, entry in pairs(state.temperatureModifierEntries) do
                    if type(entry) == 'table'
                        and normalizeKey(entry.id) == 'campfire'
                        and (tonumber(entry.warmModifier) or 0) > 0 then
                        hasActiveHeatSource = true
                        break
                    end
                end
                if hasActiveHeatSource then
                    heatSourceTickMultiplier = configuredHeatSourceTickMultiplier
                end
            end
        end

        local interiorTickMultiplier = temperatureDebug.getInteriorRegionmultiplierMultiplier(state.temperatureCurrentTickAmount)
        local multiplierTargetTemperature = tonumber(state.temperatureCappedModifier) or tonumber(state.temperatureTotalModifier) or 0
        local ambientmultiplierMultiplier = math.max(interiorTickMultiplier, wetnessTickMultiplier, heatSourceTickMultiplier)
        local ambientmultiplierSource = nil
        if interiorTickMultiplier >= wetnessTickMultiplier
            and interiorTickMultiplier >= heatSourceTickMultiplier
            and interiorTickMultiplier > 1.0 then
            ambientmultiplierSource = 'interior'
        elseif wetnessTickMultiplier >= interiorTickMultiplier
            and wetnessTickMultiplier >= heatSourceTickMultiplier
            and wetnessTickMultiplier > 1.0 then
            ambientmultiplierSource = 'wetness'
        elseif heatSourceTickMultiplier > 1.0 then
            ambientmultiplierSource = 'heat_source'
        end
        if ambientmultiplierMultiplier > 1.0 and ambientmultiplierSource ~= nil then
            temperatureDebug.beginTemperaturemultiplier(
                ambientmultiplierSource,
                state.temperatureCurrentTickAmount,
                multiplierTargetTemperature,
                ambientmultiplierMultiplier,
                false
            )
        end

        local tickMultiplier = temperatureDebug.getActiveTemperaturemultiplierMultiplier()
        state.temperatureCurrentTickMultiplier = tickMultiplier
        return tickMultiplier
    end

    function temperatureDebug.getWeatherModifierEntry()
        local currentWeatherKey = nil
        local weatherLabel = temperatureDebug.modifierLabels.weather or 'Weather Modifier'
        local weatherApi = temperatureDebug.getWeatherApi()
        local currentCell = self.cell
        local weatherRecord = temperatureDebug.getCurrentWeatherRecord()

        if weatherApi == nil then
            weatherLabel = 'Weather API Unavailable'
        elseif currentCell == nil then
            weatherLabel = 'Weather Cell Nil'
        elseif weatherRecord == nil then
            weatherLabel = 'Current Weather Nil'
        end

        if weatherRecord ~= nil then
            currentWeatherKey = temperatureDebug.getCanonicalWeatherKey(weatherRecord)
            if currentWeatherKey ~= nil and currentWeatherKey ~= '' then
                weatherLabel = (currentWeatherKey:gsub('_', ' '):gsub('(%a)([%w_]*)', function(first, rest)
                    return string.upper(first) .. string.lower(rest)
                end))
            elseif type(weatherRecord) == 'string' or type(weatherRecord) == 'number' then
                weatherLabel = tostring(weatherRecord)
            else
                local weatherNameOk, weatherNameValue = pcall(function()
                    return weatherRecord.name
                end)
                if weatherNameOk and type(weatherNameValue) == 'string' and weatherNameValue ~= '' then
                    weatherLabel = weatherNameValue
                else
                    weatherLabel = tostring(weatherRecord)
                end
            end
        end

        local previousWeatherKey = state.temperatureActiveWeatherKey
        local weatherChanged = currentWeatherKey ~= previousWeatherKey
        if currentWeatherKey ~= previousWeatherKey then
            if currentWeatherKey == nil then
                temperatureDebug.clearTemperaturemultiplier('weather')
                state.temperatureCurrentTickMultiplier = 1.0
            end
            state.temperatureActiveWeatherKey = currentWeatherKey
        end

        local weatherWarmthDelta = temperatureDebug.getWeatherWarmthDelta(currentWeatherKey)
        local warmModifier = weatherWarmthDelta > 0 and weatherWarmthDelta or 0
        local coldModifier = weatherWarmthDelta < 0 and weatherWarmthDelta or 0

        local entry = temperatureDebug.createModifierEntry('weather', warmModifier, coldModifier)
        entry.label = weatherLabel
        entry.weatherKey = currentWeatherKey
        entry.weatherChanged = weatherChanged
        return entry
    end

    function temperatureDebug.resolveRegionTransitionModifiers(regionModifierRaw, regionWarm, regionCold, elapsedSeconds)
        local targetWarm = tonumber(regionWarm) or 0
        local targetCold = tonumber(regionCold) or 0
        local targetSigned = targetWarm + targetCold
        local appliedSigned = (tonumber(state.regionTransitionAppliedWarmModifier) or 0)
            + (tonumber(state.regionTransitionAppliedColdModifier) or 0)
        local delaySeconds = temperatureDebug.getRegionTransitionDelayRealSeconds()
        local realElapsedSeconds = temperatureDebug.toRealSeconds(elapsedSeconds)
        local isExteriorCell = type(regionModifierRaw) == 'table' and regionModifierRaw.isExteriorCell == true

        if delaySeconds <= 0 then
            state.regionTransitionElapsedRealSeconds = nil
            appliedSigned = targetSigned
            local appliedWarm = appliedSigned > 0 and appliedSigned or 0
            local appliedCold = appliedSigned < 0 and appliedSigned or 0
            state.regionTransitionAppliedWarmModifier = appliedWarm
            state.regionTransitionAppliedColdModifier = appliedCold
            return appliedWarm, appliedCold
        end

        if not isExteriorCell then
            state.regionTransitionElapsedRealSeconds = nil
            appliedSigned = targetSigned
            local appliedWarm = appliedSigned > 0 and appliedSigned or 0
            local appliedCold = appliedSigned < 0 and appliedSigned or 0
            state.regionTransitionAppliedWarmModifier = appliedWarm
            state.regionTransitionAppliedColdModifier = appliedCold
            return appliedWarm, appliedCold
        end

        local currentKey = temperatureDebug.buildExteriorRegionTransitionKey(regionModifierRaw)
        if currentKey == '' then
            appliedSigned = targetSigned
            local appliedWarm = appliedSigned > 0 and appliedSigned or 0
            local appliedCold = appliedSigned < 0 and appliedSigned or 0
            state.regionTransitionAppliedWarmModifier = appliedWarm
            state.regionTransitionAppliedColdModifier = appliedCold
            return appliedWarm, appliedCold
        end

        local lastKey = normalizeKey(state.lastExteriorRegionTransitionKey)
        if state.skipNextRegionTransitionDelay == true and lastKey ~= '' and currentKey == lastKey then
            state.skipNextRegionTransitionDelay = false
        end
        if lastKey == '' then
            state.lastExteriorRegionTransitionKey = currentKey
            state.regionTransitionElapsedRealSeconds = nil
            state.skipNextRegionTransitionDelay = false
        elseif currentKey ~= lastKey then
            local bypassDelay = state.skipNextRegionTransitionDelay == true
            if bypassDelay then
                state.regionTransitionElapsedRealSeconds = nil
                state.skipNextRegionTransitionDelay = false
                appliedSigned = targetSigned
            else
                state.regionTransitionElapsedRealSeconds = 0
            end
            state.lastExteriorRegionTransitionKey = currentKey
        end

        local transitionElapsed = tonumber(state.regionTransitionElapsedRealSeconds)
        if transitionElapsed ~= nil then
            if transitionElapsed < delaySeconds then
                transitionElapsed = transitionElapsed + math.max(0, realElapsedSeconds)
                if transitionElapsed >= delaySeconds then
                    state.regionTransitionElapsedRealSeconds = nil
                    appliedSigned = targetSigned
                else
                    state.regionTransitionElapsedRealSeconds = transitionElapsed
                end
            else
                state.regionTransitionElapsedRealSeconds = nil
                appliedSigned = targetSigned
            end
        else
            appliedSigned = targetSigned
        end

        local appliedWarm = appliedSigned > 0 and appliedSigned or 0
        local appliedCold = appliedSigned < 0 and appliedSigned or 0
        state.regionTransitionAppliedWarmModifier = appliedWarm
        state.regionTransitionAppliedColdModifier = appliedCold
        return appliedWarm, appliedCold
    end

    function temperatureDebug.buildModifierState(elapsedSeconds)
        local perModifier = {}

        local regionModifierRaw = temperature.config.getModifiersForCell(self.cell, {
            seasonalVariationsEnabled = isSeasonalTemperatureVariationsEnabled(),
        })
        local regionWarm = 0
        local regionCold = 0
        local interiorBaseWarm = 0
        local interiorBaseCold = 0
        local cellWarm = 0
        local cellCold = 0
        local usesInteriorBase = false
        if type(regionModifierRaw) == 'table' then
            usesInteriorBase = regionModifierRaw.usesInteriorBase == true
            interiorBaseWarm = tonumber(regionModifierRaw.interiorBaseWarmModifier) or 0
            interiorBaseCold = tonumber(regionModifierRaw.interiorBaseColdModifier) or 0
            cellWarm = tonumber(regionModifierRaw.cellTypeWarmModifier) or 0
            cellCold = tonumber(regionModifierRaw.cellTypeColdModifier) or 0
            if regionModifierRaw.regionWarmModifier ~= nil or regionModifierRaw.regionColdModifier ~= nil then
                regionWarm = tonumber(regionModifierRaw.regionWarmModifier) or 0
                regionCold = tonumber(regionModifierRaw.regionColdModifier) or 0
            else
                regionWarm = (tonumber(regionModifierRaw.warmModifier) or 0) - cellWarm - interiorBaseWarm
                regionCold = (tonumber(regionModifierRaw.coldModifier) or 0) - cellCold - interiorBaseCold
            end
        end
        regionWarm, regionCold = temperatureDebug.resolveRegionTransitionModifiers(
            regionModifierRaw,
            regionWarm,
            regionCold,
            elapsedSeconds
        )
        local regionEntry = temperatureDebug.createModifierEntry('region', regionWarm, regionCold)
        if type(regionModifierRaw) == 'table' then
            regionEntry.regionCategory = regionModifierRaw.category
            regionEntry.season = regionModifierRaw.season
            regionEntry.seasonalOffset = tonumber(regionModifierRaw.seasonalOffset) or 0
            regionEntry.timeOfDay = regionModifierRaw.timeOfDay
            regionEntry.timeOfDaySeasonalOffset = tonumber(regionModifierRaw.timeOfDaySeasonalOffset) or 0
        end
        if usesInteriorBase ~= true
            or math.abs(tonumber(regionEntry.warmModifier) or 0) > 0
            or math.abs(tonumber(regionEntry.coldModifier) or 0) > 0 then
            perModifier.region = regionEntry
        end
        if usesInteriorBase
            or math.abs(interiorBaseWarm) > 0
            or math.abs(interiorBaseCold) > 0 then
            local interiorBaseEntry = temperatureDebug.createModifierEntry('interior_base', interiorBaseWarm, interiorBaseCold)
            if type(regionModifierRaw) == 'table' then
                interiorBaseEntry.regionCategory = regionModifierRaw.category
                interiorBaseEntry.season = regionModifierRaw.season
                interiorBaseEntry.seasonalOffset = tonumber(regionModifierRaw.seasonalOffset) or 0
                interiorBaseEntry.timeOfDay = regionModifierRaw.timeOfDay
                interiorBaseEntry.timeOfDaySeasonalOffset = tonumber(regionModifierRaw.timeOfDaySeasonalOffset) or 0
            end
            perModifier.interior_base = interiorBaseEntry
        end
        local cellEntry = temperatureDebug.createModifierEntry('cell', cellWarm, cellCold)
        if type(regionModifierRaw) == 'table' then
            local cellTypeLabel = trim(tostring(regionModifierRaw.cellTypeLabel or ''))
            if cellTypeLabel ~= '' then
                cellEntry.label = string.format('%s (%s)', temperatureDebug.modifierLabels.cell or 'Cell Modifier', cellTypeLabel)
            end
            cellEntry.cellType = normalizeKey(regionModifierRaw.cellType)
            cellEntry.cellTypeLabel = cellTypeLabel
            cellEntry.scannedStaticCount = math.max(0, tonumber(regionModifierRaw.cellTypeScannedStaticCount) or 0)
            cellEntry.topScoreType = normalizeKey(regionModifierRaw.cellTypeTopScoreType)
            cellEntry.topScoreValue = tonumber(regionModifierRaw.cellTypeTopScoreValue) or 0
        end
        perModifier.cell = cellEntry
        if type(regionModifierRaw) == 'table' then
            local campfireWarm = math.max(0, tonumber(regionModifierRaw.campfireWarmModifier) or 0)
            local campfireSources = math.max(0, tonumber(regionModifierRaw.campfireSourceCount) or 0)
            local campfireActiveSources = math.max(0, tonumber(regionModifierRaw.campfireActiveSourceCount) or 0)
            local campfireScanTotal = math.max(0, tonumber(regionModifierRaw.campfireScanActivatorScanned) or 0)
                + math.max(0, tonumber(regionModifierRaw.campfireScanLightScanned) or 0)
                + math.max(0, tonumber(regionModifierRaw.campfireScanStaticScanned) or 0)
            local campfireScanFailureCount = math.max(0, tonumber(regionModifierRaw.campfireScanFailureCount) or 0)
            if campfireWarm > 0 or campfireSources > 0 or campfireScanTotal > 0 or campfireScanFailureCount > 0 then
                local campfireEntry = temperatureDebug.createModifierEntry('campfire', campfireWarm, 0)
                campfireEntry.sourceCount = campfireSources
                campfireEntry.activeSourceCount = campfireActiveSources
                campfireEntry.nearestDistance = tonumber(regionModifierRaw.campfireNearestDistance)
                campfireEntry.baseWarmModifier = tonumber(regionModifierRaw.campfireBaseWarmModifier) or 0
                campfireEntry.interiorMultiplier = tonumber(regionModifierRaw.campfireInteriorMultiplier) or 1.0
                campfireEntry.nearestRecordId = normalizeKey(regionModifierRaw.campfireNearestRecordId)
                campfireEntry.dominantSourceType = normalizeKey(regionModifierRaw.campfireDominantSourceType)
                campfireEntry.scanActivatorScanned = math.max(0, tonumber(regionModifierRaw.campfireScanActivatorScanned) or 0)
                campfireEntry.scanActivatorMatched = math.max(0, tonumber(regionModifierRaw.campfireScanActivatorMatched) or 0)
                campfireEntry.scanLightScanned = math.max(0, tonumber(regionModifierRaw.campfireScanLightScanned) or 0)
                campfireEntry.scanLightMatched = math.max(0, tonumber(regionModifierRaw.campfireScanLightMatched) or 0)
                campfireEntry.scanStaticScanned = math.max(0, tonumber(regionModifierRaw.campfireScanStaticScanned) or 0)
                campfireEntry.scanStaticMatched = math.max(0, tonumber(regionModifierRaw.campfireScanStaticMatched) or 0)
                if type(regionModifierRaw.campfireScanFailures) == 'table' then
                    campfireEntry.scanFailures = regionModifierRaw.campfireScanFailures
                else
                    campfireEntry.scanFailures = {}
                end
                perModifier.campfire = campfireEntry
            end
        end
        perModifier.weather = temperatureDebug.getWeatherModifierEntry()
        local regionCategory = regionModifierRaw ~= nil and regionModifierRaw.category or nil
        local wetnessWeatherKey = state.temperatureActiveWeatherKey
        if type(temperatureDebug.getWeatherApi) == 'function'
            and type(temperatureDebug.callWeatherApi) == 'function'
            and type(temperatureDebug.getCanonicalWeatherKey) == 'function'
            and type(wetnessSystem.isWetWeatherKey) == 'function' then
            local weatherApi = temperatureDebug.getWeatherApi()
            local currentCell = self.cell
            if weatherApi ~= nil and currentCell ~= nil then
                local transitionValue = tonumber(temperatureDebug.callWeatherApi(weatherApi, 'getTransition', currentCell))
                local nextWeatherRecord = temperatureDebug.callWeatherApi(weatherApi, 'getNext', currentCell)
                if transitionValue ~= nil
                    and transitionValue >= 0
                    and transitionValue < 0.5
                    and nextWeatherRecord ~= nil then
                    local nextWeatherKey = temperatureDebug.getCanonicalWeatherKey(nextWeatherRecord)
                    if wetnessSystem.isWetWeatherKey(wetnessWeatherKey) ~= true
                        and wetnessSystem.isWetWeatherKey(nextWeatherKey) == true then
                        wetnessWeatherKey = nextWeatherKey
                    end
                end
            end
        end
        wetnessSystem.updateWetnessByEnvironment(elapsedSeconds, {
            weatherKey = wetnessWeatherKey,
            regionCategory = regionCategory,
            isExteriorCell = regionModifierRaw ~= nil and regionModifierRaw.isExteriorCell or nil,
            heatSourceDryingMultiplier = regionModifierRaw ~= nil and regionModifierRaw.campfireDryingMultiplier or 1.0,
            heatSourceDryingSourceType = regionModifierRaw ~= nil and regionModifierRaw.campfireDryingSourceType or 'none',
        })
        perModifier.wetness = wetnessSystem.buildModifierEntry()
        require('scripts.survivalmode.temperature.wetnessHud').setWetnessValue(perModifier.wetness.wetness)
        local warmthAbility = require('scripts.survivalmode.temperature.warmthAbility')
        local warmthTotals = warmthAbility.getModifierWarmthTotals(regionCategory, usesInteriorBase == true, {
            weatherKey = normalizeKey(state.temperatureModifierTrackedWeatherKey),
            equipmentSignature = normalizeKey(state.temperatureModifierTrackedEquipmentSignature),
        })
        local armorWarmth = tonumber(warmthTotals.armorWarmth) or 0
        local clothingWarmth = tonumber(warmthTotals.clothingWarmth) or 0
        local regionTransitionPending = type(regionModifierRaw) == 'table'
            and regionModifierRaw.isExteriorCell == true
            and tonumber(state.regionTransitionElapsedRealSeconds) ~= nil
        if regionTransitionPending then
            local delayedArmorWarmth = tonumber(state.regionTransitionAppliedArmorWarmModifier)
            if delayedArmorWarmth ~= nil then
                armorWarmth = delayedArmorWarmth
            end
            local delayedClothingWarmth = tonumber(state.regionTransitionAppliedClothingWarmModifier)
            if delayedClothingWarmth ~= nil then
                clothingWarmth = delayedClothingWarmth
            end
        else
            state.regionTransitionAppliedArmorWarmModifier = armorWarmth
            state.regionTransitionAppliedClothingWarmModifier = clothingWarmth
        end
        perModifier.armor = temperatureDebug.createModifierEntry('armor', armorWarmth, 0)
        perModifier.clothing = temperatureDebug.createModifierEntry('clothing', clothingWarmth, 0)
        local targetTemperatureBeforeArmorBonus = 0
        for _, entry in pairs(perModifier) do
            if type(entry) == 'table' then
                targetTemperatureBeforeArmorBonus = targetTemperatureBeforeArmorBonus
                    + (tonumber(entry.warmModifier) or 0)
                    + (tonumber(entry.coldModifier) or 0)
            end
        end
        local armorBonusEntry = require('scripts.survivalmode.temperature.armorWarmthBonuses').buildModifierEntry(
            targetTemperatureBeforeArmorBonus
        )
        if type(armorBonusEntry) == 'table' then
            perModifier.armor_bonus = armorBonusEntry
        end

        local orderedEntries = {}
        local consumedModifierIds = {}
        local totalWarm = 0
        local totalCold = 0

        for _, modifierId in ipairs(temperatureDebug.modifierOrder) do
            local entry = perModifier[modifierId]
            if type(entry) == 'table' then
                orderedEntries[#orderedEntries + 1] = entry
                consumedModifierIds[modifierId] = true
                totalWarm = totalWarm + (tonumber(entry.warmModifier) or 0)
                totalCold = totalCold + (tonumber(entry.coldModifier) or 0)
            end
        end

        for modifierId, entry in pairs(perModifier) do
            if consumedModifierIds[modifierId] ~= true and type(entry) == 'table' then
                orderedEntries[#orderedEntries + 1] = entry
                totalWarm = totalWarm + (tonumber(entry.warmModifier) or 0)
                totalCold = totalCold + (tonumber(entry.coldModifier) or 0)
            end
        end

        local totalModifier = totalWarm + totalCold
        if totalModifier > 0 and getActiveWellHydratedStage() ~= nil then
            local positiveHeatTargetMultiplier =
                tonumber(temperatureBalanceConfig.wellHydrated.positiveHeatTargetMultiplier)
            if positiveHeatTargetMultiplier > 0
                and positiveHeatTargetMultiplier < 1.0 then
                orderedEntries[#orderedEntries + 1] = temperatureDebug.createModifierEntry(
                    'well_hydrated',
                    0,
                    -(totalModifier * (1.0 - positiveHeatTargetMultiplier))
                )
                totalCold = totalCold
                    - (totalModifier * (1.0 - positiveHeatTargetMultiplier))
                totalModifier = totalWarm + totalCold
            end
        end
        local capMin = tonumber(temperature.system.TEMPERATURE_MIN) or -400
        local capMax = tonumber(temperature.system.TEMPERATURE_MAX) or 400
        local cappedModifier = clamp(totalModifier, capMin, capMax)
        local tickAmount = 0
        if type(temperature.system.getTickAmountForCurrentTemperature) == 'function' then
            tickAmount = tonumber(temperature.system.getTickAmountForCurrentTemperature(
                state.temperature,
                totalWarm,
                totalCold
            )) or 0
        end

        local weatherEntry = perModifier.weather
        if type(weatherEntry) == 'table' and weatherEntry.weatherChanged == true then
            local weatherKey = weatherEntry.weatherKey
            if weatherKey ~= nil and weatherKey ~= '' then
                if temperatureDebug.shouldStartWeathermultiplier(weatherKey, tickAmount) then
                    temperatureDebug.beginWeathermultiplier(tickAmount, cappedModifier)
                else
                    temperatureDebug.clearTemperaturemultiplier('weather')
                    state.temperatureCurrentTickMultiplier = 1.0
                end
            else
                temperatureDebug.clearTemperaturemultiplier('weather')
            end
        end

        return {
            entries = orderedEntries,
            warm = totalWarm,
            cold = totalCold,
            total = totalModifier,
            cappedTotal = cappedModifier,
            targetTemperatureBeforeArmorBonus = targetTemperatureBeforeArmorBonus,
            currentTickAmount = tickAmount,
            usesInteriorBase = usesInteriorBase,
            regionCategory = normalizeKey(regionCategory),
            campfireWarmModifier = type(perModifier.campfire) == 'table' and (tonumber(perModifier.campfire.warmModifier) or 0) or 0,
            campfireDominantSourceType = type(perModifier.campfire) == 'table'
                and normalizeKey(perModifier.campfire.dominantSourceType)
                or '',
            weatherKey = normalizeKey(state.temperatureModifierTrackedWeatherKey),
            equipmentSignature = normalizeKey(state.temperatureModifierTrackedEquipmentSignature),
            capMin = capMin,
            capMax = capMax,
        }
    end

    function temperatureDebug.isCurrentSleepWellRestedBonusEligible()
        if isTemperatureSystemEnabled()
            and temperature ~= nil
            and type(temperature.system) == 'table'
            and type(temperature.system.getStageByValue) == 'function' then
            local temperatureStage = temperature.system.getStageByValue(state.temperature)
            local temperatureStageId = normalizeKey(temperatureStage ~= nil and temperatureStage.id or '')
            if temperatureStageId == 'hot'
                or temperatureStageId == 'very_hot'
                or temperatureStageId == 'cold'
                or temperatureStageId == 'very_cold' then
                return false
            end
        end

        if types.Actor == nil
            or type(types.Actor.objectIsInstance) ~= 'function'
            or type(types.Actor.getEquipment) ~= 'function'
            or not types.Actor.objectIsInstance(self) then
            return true
        end

        local armorTypeAvailable = types.Armor ~= nil and type(types.Armor.objectIsInstance) == 'function'
        if not armorTypeAvailable then
            return true
        end

        local equipmentOk, equipmentTable = pcall(types.Actor.getEquipment, self)
        if not equipmentOk or type(equipmentTable) ~= 'table' then
            return true
        end

        local regionCategory = normalizeKey(state.temperatureRegionCategory)
        local isColdBiasedRegion = regionCategory == 'chilly' or regionCategory == 'cold' or regionCategory == 'very_cold'
        local armorWarmthBonuses = nil
        if isColdBiasedRegion then
            local moduleOk, moduleValue = pcall(require, 'scripts.survivalmode.temperature.armorWarmthBonuses')
            if moduleOk and type(moduleValue) == 'table'
                and type(moduleValue.getWarmthBonusForEquippedArmorItem) == 'function' then
                armorWarmthBonuses = moduleValue
            end
        end
        local targetTemperatureBeforeBonus = tonumber(state.temperatureCappedModifier) or tonumber(state.temperature) or 0
        local wearingArmor = false
        local wearingWarmBonusArmor = false

        for slotId, equippedItem in pairs(equipmentTable) do
            if equippedItem ~= nil and temperatureDebug.getArmorSlotRole(slotId) ~= nil then
                local typeOk, isArmor = pcall(types.Armor.objectIsInstance, equippedItem)
                if typeOk and isArmor == true then
                    wearingArmor = true
                    if isColdBiasedRegion
                        and armorWarmthBonuses ~= nil
                        and (tonumber(armorWarmthBonuses.getWarmthBonusForEquippedArmorItem(
                            slotId,
                            equippedItem,
                            targetTemperatureBeforeBonus
                        )) or 0) > 0 then
                        wearingWarmBonusArmor = true
                    end
                end
            end
        end

        if not wearingArmor then
            return true
        end

        return wearingWarmBonusArmor
    end

    return temperatureDebug
end

return M
