local self = require('openmw.self')
local types = require('openmw.types')
local config = require('scripts.survivalmode.temperature.armorWarmthBonusesConfig')

local SLOT_KEYS = {
    'cuirass',
    'helmet',
    'greaves',
    'boots',
    'gauntlet',
    'pauldron',
}

local cacheByRecordKey = {}
local configuredProfiles = nil

local function getWarmthBonusTemperatureMultiplier(targetTemperatureBeforeBonus)
    if (tonumber(targetTemperatureBeforeBonus) or 0) >= 0 then
        return 0.5
    end
    return 1.0
end

local function trim(value)
    if type(value) ~= 'string' then
        return ''
    end
    return value:match('^%s*(.-)%s*$')
end

local function normalizeKey(value)
    return string.lower(trim(tostring(value or '')))
end

local function addCandidate(target, seen, value)
    if type(target) ~= 'table' or type(seen) ~= 'table' then
        return
    end
    if value == nil then
        return
    end

    local normalized = normalizeKey(value)
    if normalized == '' or seen[normalized] == true then
        return
    end

    seen[normalized] = true
    target[#target + 1] = normalized
end

local function addProfileKeyword(target, value)
    if type(target) ~= 'table' then
        return
    end

    local normalized = normalizeKey(value)
    if normalized == '' then
        return
    end

    target[#target + 1] = normalized
end

local function getFallbackKeywords(profileId)
    local fallback = normalizeKey(profileId)
    fallback = fallback:gsub('bonus$', '')
    if fallback == '' then
        return {}
    end
    return { fallback }
end

local function cloneSlotBonuses(slotBonuses)
    local clone = {}
    for _, slotKey in ipairs(SLOT_KEYS) do
        clone[slotKey] = tonumber(slotBonuses[slotKey]) or 0
    end
    return clone
end

local function appendConfiguredProfile(target, profileId, profile)
    if type(target) ~= 'table' or type(profile) ~= 'table' then
        return
    end

    local keywords = {}
    if type(profile.keywords) == 'table' then
        for _, keyword in ipairs(profile.keywords) do
            addProfileKeyword(keywords, keyword)
        end
    elseif type(profile.keyword) == 'string' then
        addProfileKeyword(keywords, profile.keyword)
    end
    if #keywords == 0 then
        keywords = getFallbackKeywords(profileId)
    end

    local slotBonuses = {}
    for _, slotKey in ipairs(SLOT_KEYS) do
        slotBonuses[slotKey] = tonumber(profile[slotKey]) or 0
    end

    target[#target + 1] = {
        id = tostring(profileId),
        keywords = keywords,
        slotBonuses = slotBonuses,
    }
end

local function getConfiguredProfiles()
    if configuredProfiles ~= nil then
        return configuredProfiles
    end

    configuredProfiles = {}
    if type(config) ~= 'table' then
        return configuredProfiles
    end

    local consumedProfileIds = {}
    if type(config.keywordOrder) == 'table' then
        for _, profileId in ipairs(config.keywordOrder) do
            local normalizedProfileId = normalizeKey(profileId)
            if normalizedProfileId ~= '' and consumedProfileIds[normalizedProfileId] ~= true then
                appendConfiguredProfile(configuredProfiles, normalizedProfileId, config[profileId] or config[normalizedProfileId])
                consumedProfileIds[normalizedProfileId] = true
            end
        end
    end

    for profileId, profile in pairs(config) do
        local normalizedProfileId = normalizeKey(profileId)
        if normalizedProfileId ~= 'keywordorder' and consumedProfileIds[normalizedProfileId] ~= true then
            appendConfiguredProfile(configuredProfiles, profileId, profile)
        end
    end

    return configuredProfiles
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

local function getArmorRecordKey(equippedItem, armorRecord)
    local candidates = {}
    local seen = {}

    pcall(function()
        addCandidate(candidates, seen, equippedItem.recordId)
    end)
    pcall(function()
        addCandidate(candidates, seen, equippedItem.id)
    end)
    pcall(function()
        addCandidate(candidates, seen, armorRecord.id)
    end)
    pcall(function()
        addCandidate(candidates, seen, armorRecord.recordId)
    end)

    return candidates[1] or ''
end

local function collectArmorTextCandidates(equippedItem, armorRecord)
    local candidates = {}
    local seen = {}

    pcall(function()
        addCandidate(candidates, seen, equippedItem.recordId)
    end)
    pcall(function()
        addCandidate(candidates, seen, equippedItem.id)
    end)
    pcall(function()
        addCandidate(candidates, seen, equippedItem.name)
    end)
    pcall(function()
        addCandidate(candidates, seen, armorRecord.name)
    end)
    pcall(function()
        addCandidate(candidates, seen, armorRecord.id)
    end)
    pcall(function()
        addCandidate(candidates, seen, armorRecord.recordId)
    end)

    return candidates
end

local function profileMatchesCandidates(profile, candidates)
    if type(profile) ~= 'table' or type(candidates) ~= 'table' then
        return false
    end

    for _, keyword in ipairs(profile.keywords or {}) do
        if keyword ~= '' then
            for _, candidate in ipairs(candidates) do
                if candidate:find(keyword, 1, true) ~= nil then
                    return true
                end
            end
        end
    end

    return false
end

local function resolveSlotBonusesForArmor(equippedItem, armorRecord)
    local cacheKey = getArmorRecordKey(equippedItem, armorRecord)
    if cacheKey ~= '' and type(cacheByRecordKey[cacheKey]) == 'table' then
        return cacheByRecordKey[cacheKey]
    end

    local resolved = {}
    for _, slotKey in ipairs(SLOT_KEYS) do
        resolved[slotKey] = 0
    end

    local candidates = collectArmorTextCandidates(equippedItem, armorRecord)
    for _, profile in ipairs(getConfiguredProfiles()) do
        if profileMatchesCandidates(profile, candidates) then
            resolved = cloneSlotBonuses(profile.slotBonuses)
            break
        end
    end

    if cacheKey ~= '' then
        cacheByRecordKey[cacheKey] = resolved
    end

    return resolved
end

local function getWarmthBonusForEquippedArmorItem(slotId, equippedItem, targetTemperatureBeforeBonus)
    local slotRole = getArmorSlotRole(slotId)
    if slotRole == nil or equippedItem == nil then
        return 0
    end

    local armorTypeAvailable = types.Armor ~= nil and type(types.Armor.objectIsInstance) == 'function'
    if armorTypeAvailable then
        local typeOk, isArmor = pcall(types.Armor.objectIsInstance, equippedItem)
        if typeOk and isArmor ~= true then
            return 0
        end
    end

    local armorRecord = getArmorRecordForItem(equippedItem)
    if armorRecord == nil then
        return 0
    end

    local slotBonuses = resolveSlotBonusesForArmor(equippedItem, armorRecord)
    local multiplier = getWarmthBonusTemperatureMultiplier(targetTemperatureBeforeBonus)
    return (tonumber(slotBonuses[slotRole]) or 0) * multiplier
end

local function hasWarmthBonusKeywordMatchForEquippedArmorItem(equippedItem)
    if equippedItem == nil then
        return false
    end

    local armorTypeAvailable = types.Armor ~= nil and type(types.Armor.objectIsInstance) == 'function'
    if armorTypeAvailable then
        local typeOk, isArmor = pcall(types.Armor.objectIsInstance, equippedItem)
        if typeOk and isArmor ~= true then
            return false
        end
    end

    local armorRecord = getArmorRecordForItem(equippedItem)
    if armorRecord == nil then
        return false
    end

    local candidates = collectArmorTextCandidates(equippedItem, armorRecord)
    for _, profile in ipairs(getConfiguredProfiles()) do
        if profileMatchesCandidates(profile, candidates) then
            return true
        end
    end

    return false
end

local function buildModifierEntry(targetTemperatureBeforeBonus)
    if types.Actor == nil
        or type(types.Actor.objectIsInstance) ~= 'function'
        or type(types.Actor.getEquipment) ~= 'function'
        or not types.Actor.objectIsInstance(self) then
        return nil
    end

    local equipmentOk, equipmentTable = pcall(types.Actor.getEquipment, self)
    if not equipmentOk or type(equipmentTable) ~= 'table' then
        return nil
    end

    local totalWarm = 0
    for slotId, equippedItem in pairs(equipmentTable) do
        if equippedItem ~= nil then
            totalWarm = totalWarm + getWarmthBonusForEquippedArmorItem(slotId, equippedItem, targetTemperatureBeforeBonus)
        end
    end

    if totalWarm <= 0 then
        return nil
    end

    return {
        id = 'armor_bonus',
        label = 'Armor Material Bonus',
        warmModifier = totalWarm,
        coldModifier = 0,
    }
end

return {
    buildModifierEntry = buildModifierEntry,
    getWarmthBonusForEquippedArmorItem = getWarmthBonusForEquippedArmorItem,
    hasWarmthBonusKeywordMatchForEquippedArmorItem = hasWarmthBonusKeywordMatchForEquippedArmorItem,
}
