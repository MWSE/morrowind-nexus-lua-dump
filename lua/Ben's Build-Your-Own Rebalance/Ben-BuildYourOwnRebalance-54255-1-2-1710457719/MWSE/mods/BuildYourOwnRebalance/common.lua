local config = require("BuildYourOwnRebalance.config")
local util = require("BuildYourOwnRebalance.util")
local gameConfig = config.getGameConfig()

this = {}

--------------------------------------------------
-- LOGGING HELPERS
--------------------------------------------------

local modNameAndVersion = "BYO Rebalance v1.0"

local function getLoggingEnabled()
    return gameConfig.shared.loggingEnabled
end

this.log = function(...)
    
    if not getLoggingEnabled() then return end
    
    local message = ""
    local arg1, arg2 = ...
    
    if arg1 == nil
    or arg2 == nil
    then message = tostring(arg1)
    else message = string.format(...) end
    
    mwse.log("[%s] %s", modNameAndVersion, message)
    
end

this.toast = function(...)
    
    if not getLoggingEnabled() then return end
    
    local message = ""
    local arg1, arg2 = ...
    
    if arg1 == nil
    or arg2 == nil
    then message = tostring(arg1)
    else message = string.format(...) end
    
    tes3.messageBox("[%s]\n%s", modNameAndVersion, message)
    
end

this.logEnchant = function(object, newValue)
    
    if object.enchantment then
        this.log("  Enchant: Enchanted")
    elseif newValue == nil then 
        this.log("  Enchant: %.1f", object.enchantCapacity * 0.1)
    else -- not enchanted and was rebalanced
        this.log("  Enchant: %.1f -> %.1f", object.enchantCapacity * 0.1, newValue * 0.1)
    end
    
end

--------------------------------------------------
-- OBJECT HELPERS
--------------------------------------------------

this.sortedIterateObjects = function(filter)
    
    if not getLoggingEnabled() then
        return tes3.iterateObjects(filter)
    end
    
    local objects = {}
    local sortedTable = {}
    
    for object in tes3.iterateObjects(filter) do
        
        objects[object.id] = object
        table.insert(sortedTable, object.id)
        
    end
    
    table.sort(sortedTable, util.sortFunction_ByStringKey)
    
    local i = 0 -- iterator variable
    local iteratorFunction = function ()
        
        i = i + 1
        if sortedTable[i] == nil then return nil
        else return objects[sortedTable[i]] end
        
    end
    
    return iteratorFunction
    
end

this.shouldCacheObject = function(object)
    
    if object.name == "" then return false end
    if object.name == "FOR SPELL CASTING" then return false end
    if object.sourceMod == nil then return false end
    return true
    
end

--------------------------------------------------
-- SEARCH HELPERS
--------------------------------------------------

local function logSearchTable(searchTable, valueIsNumber)
    
    if not getLoggingEnabled() then return end
    
    local message = "  %s %s"
    if valueIsNumber then message = "  %d %s" end
    
    for searchTerm, value in util.sortedPairs(searchTable, util.getSortFunction_ByKeyLengthDescThenKeyThenValue(searchTable)) do
        this.log(message, value, searchTerm)
    end
    
end

local function getSearchPattern(searchTerm)
    
    local firstCharacter = string.sub(searchTerm, 1, 1)
    
    if firstCharacter == "*"
    then searchPattern = string.sub(searchTerm, 2)
    else searchPattern = util.getCaseInsensitivePattern(searchTerm) end
    
    if string.len(searchPattern) == 0 then return nil end
    return searchPattern
    
end

local function parseSearchTerms_MultiLine(searchTermsString, setOfValidValues, valueLabel, valueIsNumber, transformValueFunction)
    
    local searchTermsTable = {}
    
    for line in string.gmatch(searchTermsString, "[^\n]+") do
        
        local startIndex, endIndex = string.find(line, ":")
        
        if startIndex ~= nil then
            
            local value = string.sub(line, 1, startIndex - 1)
            local searchTerm = string.sub(line, endIndex + 1)
            
            if string.len(searchTerm) > 0 then
                
                if valueIsNumber then
                    value = tonumber(value)
                end
                
                if transformValueFunction ~= nil then
                    value = transformValueFunction(value)
                end
                
                if setOfValidValues[value] ~= nil then
                    searchTermsTable[searchTerm] = value
                end
                
            end
            
        end
        
    end
    
    this.log("%s Search Terms:", valueLabel)
    logSearchTable(searchTermsTable, valueIsNumber)
    return searchTermsTable
    
end

this.getSearchPatterns_MultiLine = function(searchTermsString, setOfValidValues, valueLabel, valueIsNumber, transformValueFunction)
    
    local searchTermsTable = parseSearchTerms_MultiLine(searchTermsString, setOfValidValues, valueLabel, valueIsNumber, transformValueFunction)
    local searchPatterns = {}
    
    for searchTerm, value in pairs(searchTermsTable) do
        
        local searchPattern = getSearchPattern(searchTerm)
        
        if searchPattern ~= nil then
            searchPatterns[searchPattern] = value
        end
        
    end
    
    this.log("%s Search Patterns:", valueLabel)
    logSearchTable(searchPatterns, valueIsNumber)
    return searchPatterns
    
end

local function parseSearchTerms_SingleLine(searchTermsString, value, valueLabel, valueIsNumber)
    
    local searchTermsTable = {}
    
    for searchTerm in string.gmatch(searchTermsString, "[^/]+") do
        searchTermsTable[searchTerm] = value
    end
    
    this.log("%s Search Terms:", valueLabel)
    logSearchTable(searchTermsTable, valueIsNumber)
    return searchTermsTable
    
end

this.getSearchPatterns_SingleLine = function(searchTermsString, value, valueLabel, valueIsNumber)
    
    local searchTermsTable = parseSearchTerms_SingleLine(searchTermsString, value, valueLabel, valueIsNumber)
    local searchPatterns = {}
    
    for searchTerm, value in pairs(searchTermsTable) do
        
        local searchPattern = getSearchPattern(searchTerm)
        
        if searchPattern ~= nil then
            searchPatterns[searchPattern] = value
        end
        
    end
    
    this.log("%s Search Patterns:", valueLabel)
    logSearchTable(searchPatterns)
    return searchPatterns
    
end

this.getValueBySearchPattern = function(item, searchPatterns, valueLabel, valueFormat)
    
    local matchLabel = nil
    
    -- search for longest patterns first (e.g. search "Nordic Silver" before "Nordic" or "Silver")
    for searchPattern, value in util.sortedPairs(searchPatterns, util.getSortFunction_ByKeyLengthDescThenKeyThenValue(searchPatterns)) do
        
        if string.find(item.name, searchPattern) ~= nil then
            matchValue = item.name
            matchLabel = "Name"
            
        elseif string.find(item.mesh, searchPattern) ~= nil then
            matchValue = item.mesh
            matchLabel = "Mesh"
            
        elseif string.find(item.icon, searchPattern) ~= nil then
            matchValue = item.icon
            matchLabel = "Icon"
            
        elseif string.find(item.id, searchPattern) ~= nil then
            matchValue = item.id
            matchLabel = "ID"
        end
        
        if matchLabel ~= nil then
            
            if valueLabel ~= nil
            and valueFormat ~= nil then
                
                local message = 
                    "  %s: " .. valueFormat .. 
                    " | Detect %s by %s: %s"..
                    " | Pattern: %s"
                
                this.log(message,
                    valueLabel, value,
                    valueLabel, matchLabel, matchValue,
                    searchPattern)
                
            end
            
            return value
            
        end
        
    end
    
    return nil
    
end

this.getValueByStat = function(stat, maxStats, valueLabel, statLabel, valueFormat, statFormat, statUiMax)
    
    for value, maxStat in util.sortedPairs(maxStats, util.getSortFunction_ByValueThenKey(maxStats)) do
        
        -- if UI slider is set to max, treat maxStat as infinity
        if stat <= maxStat or maxStat >= statUiMax then
            
            if valueLabel ~= nil
            and statLabel ~= nil
            and valueFormat ~= nil
            and statFormat ~= nil then
                
                local message = 
                    "  %s: " .. valueFormat ..
                    " | Detect %s by %s: " .. statFormat ..
                    " | Max %s: " .. statFormat
                
                this.log(message,
                    valueLabel, value,
                    valueLabel, statLabel, stat,
                    statLabel, maxStat)
                
            end
            
            return value
            
        end
        
    end
    
    return nil
    
end

this.getIsBoundItem = function(object)
    
    if gameConfig.shared.boundItemIds[object.id] then
        
        this.log("  Bound Item: true | In \"Bound Items\" List")
        return true
        
    elseif gameConfig.shared.detectBoundItemsByName
    and string.find(object.name, gameConfig.shared.boundItemSearchPattern) ~= nil then
        
        this.log("  Bound Item: true | Detect by Name")
        return true
        
    end
    
    this.log("  Bound Item: false")
    return false
    
end

--------------------------------------------------
-- ARMOR HELPERS
--------------------------------------------------

local armorSlot_ConfigKey = {
    [tes3.armorSlot.helmet] = "helm",
    [tes3.armorSlot.cuirass] = "cuirass",
    [tes3.armorSlot.leftPauldron] = "pauldron",
    [tes3.armorSlot.rightPauldron] = "pauldron",
    [tes3.armorSlot.greaves] = "greaves",
    [tes3.armorSlot.boots] = "boots",
    [tes3.armorSlot.leftGauntlet] = "gauntlet",
    [tes3.armorSlot.rightGauntlet] = "gauntlet",
    [tes3.armorSlot.shield] = "shield",
    [tes3.armorSlot.leftBracer] = "gauntlet",
    [tes3.armorSlot.rightBracer] = "gauntlet",
}

this.getArmorSlotConfigKey = function(armorSlot)
    return armorSlot_ConfigKey[armorSlot]
end

local armorSlotConfigKey_SortOrder = {
    helm = 1,
    pauldron = 2,
    cuirass = 3,
    gauntlet = 4,
    greaves = 5,
    boots = 6,
    shield = 7,
}

this.sortFunction_ByArmorSlotConfigKey = function(keyA, keyB)
    
    local valueA = armorSlotConfigKey_SortOrder[keyA]
    local valueB = armorSlotConfigKey_SortOrder[keyB]
    
    return valueA < valueB
    
end

local armorWeightClass_SearchValue = {
    [tes3.armorWeightClass.light] = "L",
    [tes3.armorWeightClass.medium] = "M",
    [tes3.armorWeightClass.heavy] = "H",
}

this.getArmorWeightClassSearchValue = function(armorWeightClass)
    return armorWeightClass_SearchValue[armorWeightClass]
end

local armorWeightClassSearchValue_ConfigKey = {
    L = "light",
    M = "medium",
    H = "heavy",
}

this.getArmorWeightClassSearchValueConfigKey = function(armorWeightClassSearchValue)
    return armorWeightClassSearchValue_ConfigKey[armorWeightClassSearchValue]
end

local armorWeightClassConfigKey_SortOrder = {
    light = 1,
    medium = 2,
    heavy = 3,
}

this.sortFunction_ByArmorWeightClassConfigKey = function(keyA, keyB)
    
    local valueA = armorWeightClassConfigKey_SortOrder[keyA]
    local valueB = armorWeightClassConfigKey_SortOrder[keyB]
    
    return valueA < valueB
    
end

--------------------------------------------------
-- WEAPON HELPERS
--------------------------------------------------

local weaponType_ConfigKey = {
    [tes3.weaponType.shortBladeOneHand] = "shortBladeOneHand",
    [tes3.weaponType.longBladeOneHand] = "longBladeOneHand",
    [tes3.weaponType.bluntOneHand] = "bluntOneHand",
    [tes3.weaponType.axeOneHand] = "axeOneHand",
    
    [tes3.weaponType.spearTwoWide] = "spearTwoWide",
    [tes3.weaponType.longBladeTwoClose] = "longBladeTwoClose",
    [tes3.weaponType.bluntTwoWide] = "bluntTwoWide",
    [tes3.weaponType.bluntTwoClose] = "bluntTwoClose",
    [tes3.weaponType.axeTwoHand] = "axeTwoHand",
    
    [tes3.weaponType.marksmanCrossbow] = "marksmanCrossbow",
    [tes3.weaponType.marksmanBow] = "marksmanBow",
    [tes3.weaponType.bolt] = "bolt",
    [tes3.weaponType.arrow] = "arrow",
    [tes3.weaponType.marksmanThrown] = "marksmanThrown",
}

this.getWeaponTypeConfigKey = function(weaponType)
    return weaponType_ConfigKey[weaponType]
end

local configKey_WeaponType = {
    shortBladeOneHand = tes3.weaponType.shortBladeOneHand,
    longBladeOneHand = tes3.weaponType.longBladeOneHand,
    bluntOneHand = tes3.weaponType.bluntOneHand,
    axeOneHand = tes3.weaponType.axeOneHand,
    
    spearTwoWide = tes3.weaponType.spearTwoWide,
    longBladeTwoClose = tes3.weaponType.longBladeTwoClose,
    bluntTwoWide = tes3.weaponType.bluntTwoWide,
    bluntTwoClose = tes3.weaponType.bluntTwoClose,
    axeTwoHand = tes3.weaponType.axeTwoHand,
    
    marksmanCrossbow = tes3.weaponType.marksmanCrossbow,
    marksmanBow = tes3.weaponType.marksmanBow,
    bolt = tes3.weaponType.bolt,
    arrow = tes3.weaponType.arrow,
    marksmanThrown = tes3.weaponType.marksmanThrown,
}

this.getConfigKeyWeaponType = function(weaponTypeConfigKey)
    return configKey_WeaponType[weaponTypeConfigKey]
end

local weaponTypeConfigKey_DisplayName = {
    shortBladeOneHand = "1H Short Blade",
    longBladeOneHand = "1H Long Blade",
    bluntOneHand = "1H Blunt",
    axeOneHand = "1H Axe",
    
    spearTwoWide = "2H Spear",
    longBladeTwoClose = "2H Long Blade",
    bluntTwoWide = "2H Blunt (Wide)",
    bluntTwoClose = "2H Blunt (Close)",
    axeTwoHand = "2H Axe",
    
    marksmanCrossbow = "Crossbow",
    marksmanBow = "Bow",
    bolt = "Bolt",
    arrow = "Arrow",
    marksmanThrown = "Thrown",
}

this.getWeaponTypeConfigKeyDisplayName = function(weaponTypeConfigKey)
    return weaponTypeConfigKey_DisplayName[weaponTypeConfigKey]
end

local weaponTypeConfigKey_SortOrder = {
    shortBladeOneHand = 1,
    longBladeOneHand = 2,
    bluntOneHand = 3,
    axeOneHand = 4,
    
    spearTwoWide = 11,
    bluntTwoWide = 12,
    longBladeTwoClose = 13,
    bluntTwoClose = 14,
    axeTwoHand = 15,
    
    marksmanCrossbow = 21,
    marksmanBow = 22,
    bolt = 23,
    arrow = 24,
    marksmanThrown = 25,
}

this.sortFunction_ByWeaponTypeConfigKey = function(keyA, keyB)
    
    local valueA = weaponTypeConfigKey_SortOrder[keyA]
    local valueB = weaponTypeConfigKey_SortOrder[keyB]
    
    return valueA < valueB
    
end

local weaponWeightClassSearchValue_ConfigKey = {
    L = "light",
    M = "medium",
    H = "heavy",
}

this.getWeaponWeightClassSearchValueConfigKey = function(weaponWeightClassSearchValue)
    return weaponWeightClassSearchValue_ConfigKey[weaponWeightClassSearchValue]
end

local weaponWeightClassConfigKey_SortOrder = {
    light = 1,
    medium = 2,
    heavy = 3,
}

this.sortFunction_ByWeaponWeightClassConfigKey = function(keyA, keyB)
    
    local valueA = weaponWeightClassConfigKey_SortOrder[keyA]
    local valueB = weaponWeightClassConfigKey_SortOrder[keyB]
    
    return valueA < valueB
    
end

-- this does not match the tes3weapon.isRanged flag
local weaponTypeConfigKey_IsRanged = {
    shortBladeOneHand = false,
    longBladeOneHand = false,
    bluntOneHand = false,
    axeOneHand = false,
    
    spearTwoWide = false,
    longBladeTwoClose = false,
    bluntTwoWide = false,
    bluntTwoClose = false,
    axeTwoHand = false,
    
    marksmanCrossbow = true,
    marksmanBow = true,
    bolt = true,
    arrow = true,
    marksmanThrown = true,
}

this.getWeaponTypeConfigKeyIsRanged = function(weaponTypeConfigKey)
    return weaponTypeConfigKey_IsRanged[weaponTypeConfigKey]
end

local weaponTypeConfigKey_IsProjectile = {
    shortBladeOneHand = false,
    longBladeOneHand = false,
    bluntOneHand = false,
    axeOneHand = false,
    
    spearTwoWide = false,
    longBladeTwoClose = false,
    bluntTwoWide = false,
    bluntTwoClose = false,
    axeTwoHand = false,
    
    marksmanCrossbow = false,
    marksmanBow = false,
    bolt = true,
    arrow = true,
    marksmanThrown = true,
}

this.getWeaponTypeConfigKeyIsProjectile = function(weaponTypeConfigKey)
    return weaponTypeConfigKey_IsProjectile[weaponTypeConfigKey]
end

--------------------------------------------------
-- CLOTHING HELPERS
--------------------------------------------------

local clothingSlot_ConfigKey = {
    [tes3.clothingSlot.pants] = "pants",
    [tes3.clothingSlot.shoes] = "shoes",
    [tes3.clothingSlot.shirt] = "shirt",
    [tes3.clothingSlot.belt] = "belt",
    [tes3.clothingSlot.robe] = "robe",
    [tes3.clothingSlot.rightGlove] = "glove",
    [tes3.clothingSlot.leftGlove] = "glove",
    [tes3.clothingSlot.skirt] = "skirt",
    [tes3.clothingSlot.ring] = "ring",
    [tes3.clothingSlot.amulet] = "amulet",
}

this.getClothingSlotConfigKey = function(clothingSlot)
    return clothingSlot_ConfigKey[clothingSlot]
end

local clothingSlotConfigKey_SortOrder = {
    amulet = 1,
    ring = 2,
    shirt = 3,
    skirt = 4,
    pants = 5,
    belt = 6,
    glove = 7,
    shoes = 8,
    robe = 9,
}

this.sortFunction_ByClothingSlotConfigKey = function(keyA, keyB)
    
    local valueA = clothingSlotConfigKey_SortOrder[keyA]
    local valueB = clothingSlotConfigKey_SortOrder[keyB]
    
    return valueA < valueB
    
end

--------------------------------------------------
-- GMST HELPERS
--------------------------------------------------

local gmst_DisplayName = {
    [tes3.gmst.iBaseArmorSkill] = "iBaseArmorSkill",
    [tes3.gmst.fLightMaxMod] = "fLightMaxMod",
    [tes3.gmst.fMedMaxMod] = "fMedMaxMod",
    
    [tes3.gmst.iBootsWeight] = "iBootsWeight",
    [tes3.gmst.iCuirassWeight] = "iCuirassWeight",
    [tes3.gmst.iGauntletWeight] = "iGauntletWeight",
    [tes3.gmst.iGreavesWeight] = "iGreavesWeight",
    [tes3.gmst.iHelmWeight] = "iHelmWeight",
    [tes3.gmst.iPauldronWeight] = "iPauldronWeight",
    [tes3.gmst.iShieldWeight] = "iShieldWeight",
    
    [tes3.gmst.fUnarmoredBase1] = "fUnarmoredBase1",
    [tes3.gmst.fUnarmoredBase2] = "fUnarmoredBase2",
}

local function setGmst(gmstId, newValue)
    
    local gmst = tes3.findGMST(gmstId)
    local oldValue = gmst.value
    
    tes3.findGMST(gmstId).value = newValue
    if not getLoggingEnabled() then return end
    
    local displayName = gmst_DisplayName[gmstId]
    local valueFormat = nil
    
    if gmst.type == "i" then
        valueFormat = "%d"
    elseif gmst.type == "f" then
        valueFormat = "%.4f"
    elseif gmst.type == "s" then
        valueFormat = "%s"
    end
    
    local message = "GMST %s: " .. valueFormat .. " -> " .. valueFormat
    this.log(message, displayName, oldValue, newValue)
    
end

this.setGmsts = function(gmstTable)
    
    for gmstId, value in util.sortedPairs(gmstTable) do
        setGmst(gmstId, value)
    end
    
end

return this
