local config = require("RationalNames.config")
local data = require("RationalNames.data")
local common = require("RationalNames.common")

local savedData
local this = {}

-- Returns the num parameter as a string, with leading zeros as needed to ensure it will display as the required number
-- of digits in the prefix.
local function extendNum(id, num, log, length)
    local numPrefix = tostring(math.floor(num))
    local tooShort = length - #numPrefix

    if tooShort > 0 then
        local zeros = string.rep("0", tooShort)
        numPrefix = string.format("%s%s", zeros, numPrefix)
        common.logMsg(string.format("%s: %s does not take up enough digits. Adding leading 0s so it will use %u digits.", id, log, length))
    end

    return numPrefix
end

local function capitalizeFirstChar(text)
    if string.find(text, "%l") == 1 then
        text = string.gsub(text, "%l", string.upper, 1)
    end

    return text
end

-- Unfortunately, Morrowind treats lowercase and capital letters differently for invenory sorting purposes. Sorting
-- order is A-Z, then a-z. This means, for example, that "Belt of the Armor of God" will sort after "Belt of Wisdom" in
-- the inventory. To fix this, we capitalize certain words in object names, and lowercase them in display names.
local function substituteLetter(text, pattern, letter, offset)
    while true do
        local index = string.find(text, pattern)

        if not index then
            break
        end

        text = string.format("%s%s%s", string.sub(text, 1, index + offset), letter, string.sub(text, index + 2 + offset, #text))
    end

    return text
end

local function checkPrefixEnabled(object, id, objectType, componentName, isKey)
    if not config.addPrefixes then
        common.logMsg(string.format("%s: Prefixes disabled. Skipping prefix.", id))
        return false
    end

    local prefixEnabledForType = config.componentEnable.prefix[tostring(objectType)]

    -- Should only be nil for ingredients.
    if prefixEnabledForType == nil then
        common.logMsg(string.format("%s: There are no prefixes for %s. Skipping prefix.", id, componentName))
        return false
    elseif prefixEnabledForType == false then
        common.logMsg(string.format("%s: Prefixes for %s are disabled. Skipping prefix.", id, componentName))
        return false
    end

    if isKey and not config.miscPrefixes.keys then
        common.logMsg(string.format("%s: Object is a key and prefixes for keys are disabled. Skipping prefix.", id))
        return false
    elseif object.isSoulGem and not config.miscPrefixes.soulgems then
        common.logMsg(string.format("%s: Object is a soulgem and prefixes for soulgems are disabled. Skipping prefix.", id))
        return false
    elseif data.propylonList[id] and not config.miscPrefixes["propylon indexes"] then
        common.logMsg(string.format("%s: Object is a propylon index and prefixes for propylon indexes are disabled. Skipping prefix.", id))
        return false
    end

    if config.blacklists.prefix[id] then
        common.logMsg(string.format("%s: On prefix blacklist. Skipping prefix.", id))
        return false
    end

    return true
end

local function checkBaseNameEnabled(id, objectType, componentName, isKey, logText)
    if not config.changeBaseNames then
        common.logMsg(string.format("%s: Base name changes disabled. Skipping %s.", id, logText))
        return false
    end

    if not config.componentEnable.baseName[tostring(objectType)] then
        common.logMsg(string.format("%s: Base name changes for %s are disabled. Skipping %s.", id, componentName, logText))
        return false
    end

    if config.blacklists.baseName[id] then
        common.logMsg(string.format("%s: On base name blacklist. Skipping %s.", id, logText))
        return false
    end

    if objectType == tes3.objectType.miscItem
    and isKey
    and not config.keyBaseNames then
        common.logMsg(string.format("%s: Object is a key, and the mod is configured to not change key base names. Skipping %s.", id, logText))
        return false
    end

    return true
end

-- Lowercases certain words in display names, for consistency and correctness. For example, "Of" becomes "of".
local function getSubstituteName(id, name, objectType, componentName, isKey)
    local substituteName = name

    if checkBaseNameEnabled(id, objectType, componentName, isKey, "display name lowercasing check") then
        for _, word in ipairs(data.wordsReplace) do
            local capitalizedWord = string.gsub(word, "%l", string.upper, 1)
            local firstLetter = string.sub(word, 1, 1)
            -- We don't want to lowercase a word when it's preceded by ":" (e.g. the subtitle of a book) or ")" (the
            -- first word of the actual name after a prefix).
            local pattern = string.format("%s%s%s", "[^:%)] ", capitalizedWord, " ")
            substituteName = substituteLetter(substituteName, pattern, firstLetter, 1)
        end

        if substituteName ~= name then
            common.logMsg(string.format("%s: Lowercasing words in display name as needed. New display name: %s." , id, substituteName))
        end
    end

    return substituteName
end

local function getNewObjectName(id, name, prefix, objectType, componentName, isKey)
    local objectName = name

    -- Capitalizes certain words in object names (but not display names) for consistent sorting. For example, "of"
    -- becomes "Of".
    if checkBaseNameEnabled(id, objectType, componentName, isKey, "object name capitalization check") then
        for _, word in ipairs(data.wordsReplace) do
            local firstLetter = string.sub(word, 1, 1)
            local firstLetterCap = string.gsub(firstLetter, "%l", string.upper)
            local pattern = string.format("%s%s%s", " ", word, " ")
            objectName = substituteLetter(objectName, pattern, firstLetterCap, 0)
        end

        if objectName ~= name then
            common.logMsg(string.format("%s: Capitalizing words in object name as needed. New object name: %s." , id, objectName))
        end
    end

    if objectType == tes3.objectType.book
    and config.removeArticlesFromBooks then
        local objectNameWithoutPrefix = string.sub(objectName, #prefix + 1, #objectName)
        local nameLower = objectNameWithoutPrefix:lower()

        if string.find(nameLower, "the ") == 1
        or string.find(nameLower, "a ") == 1
        or string.find(nameLower, "an ") == 1 then
            local startIndex = string.find(objectNameWithoutPrefix, " ") + 1
            local numNameWithoutPrefix = #objectNameWithoutPrefix

            if numNameWithoutPrefix >= startIndex then
                objectNameWithoutPrefix = string.sub(objectNameWithoutPrefix, startIndex, numNameWithoutPrefix)
                objectNameWithoutPrefix = capitalizeFirstChar(objectNameWithoutPrefix)
                objectName = string.format("%s%s", prefix, objectNameWithoutPrefix)
                common.logMsg(string.format("%s: Object is a book starting with an article, and the related setting is enabled. Removing article from object name. New object name: %s.", id, objectName))
            end
        end
    end

    -- The game will mess itself if we try to assign an object name greater than 31 characters. So we set the actual
    -- object name to only the first 31 characters of the full name.
    if #objectName > 31 then
        objectName = string.sub(objectName, 1, 31)
        common.logMsg(string.format("%s: New name is > 31 characters. Shortening object name to: %s. (Full name will display in the UI.)", id, objectName))
    end

    return objectName
end

local function getPrefix(object, id, objectType, componentName, isKey)
    local prefix = ""

    if not checkPrefixEnabled(object, id, objectType, componentName, isKey) then
        return prefix
    end

    if objectType == tes3.objectType.alchemy then
        if data.drinksList[id] then
            prefix = "~"
            common.logMsg(string.format("%s: Object is a potion and on the drinks list. Prefix: \"%s\".", id, prefix))
        elseif data.specialPotionsList[id] then
            prefix = "."
            common.logMsg(string.format("%s: Object is a potion and on the special potions list. Prefix: \"%s\".", id, prefix))
        else
            common.logMsg(string.format("%s: Object is a potion but not on the drinks list. No prefix.", id))
        end
    elseif objectType == tes3.objectType.book then
        if object.enchantment then
            prefix = "~"
            common.logMsg(string.format("%s: Object is a magic scroll. Prefix: \"%s\".", id, prefix))
        elseif object.type == tes3.bookType.scroll then
            prefix = "."
            common.logMsg(string.format("%s: Object is a non-magic scroll. Prefix: \"%s\".", id, prefix))
        else
            common.logMsg(string.format("%s: Object is a book but not a scroll. No prefix.", id))
        end
    elseif objectType == tes3.objectType.miscItem then
        if object.isSoulGem then
            local capacityPrefix = extendNum(id, object.soulGemCapacity, "Soulgem capacity", 5)
            prefix = string.format("(S-%s) ", capacityPrefix)
            common.logMsg(string.format("%s: Object is a soulgem. Prefix: \"%s\".", id, prefix))
        elseif data.propylonList[id] then
            prefix = "(P) "
            common.logMsg(string.format("%s: Object is a propylon index. Prefix: \"%s\".", id, prefix))
        elseif data.goldList[id] and config.goldAtEnd then
            prefix = "~"
            common.logMsg(string.format("%s: Object is gold, and gold prefix is enabled. Prefix: \"%s\".", id, prefix))
        elseif isKey then
            prefix = "(K) "
            common.logMsg(string.format("%s: Object is a key. Prefix: \"%s\".", id, prefix))
        else
            common.logMsg(string.format("%s: Object is a misc item but not a soulgem, key, propylon index or gold (or is gold but gold prefix is disabled). No prefix.", id))
        end
    elseif objectType == tes3.objectType.apparatus then
        local typePrefix = data.apparatusTypes[object.type] or "O"
        -- An object with quality >= 10 would sort out of order, but that's very unlikely to happen.
        prefix = string.format("(%s-%.2f) ", typePrefix, object.quality)
        common.logMsg(string.format("%s: Object is an alchemy apparatus. Prefix: \"%s\".", id, prefix))
    elseif objectType == tes3.objectType.lockpick
    or objectType == tes3.objectType.probe
    or objectType == tes3.objectType.repairItem then
        prefix = string.format("(%.2f) ", object.quality)
        common.logMsg(string.format("%s: Object is a lockpick, probe, or repair item. Prefix: \"%s\".", id, prefix))
    elseif objectType == tes3.objectType.light then
        local radius = math.min(object.radius, 999)
        local radiusDisplay = (config.lightsInReverseOrder and (999 - radius)) or radius
        local radiusPrefix = extendNum(id, radiusDisplay, "Light radius", 3)

        local time = math.min(object.time, 99999)
        local timeDisplay = (config.lightsInReverseOrder and (99999 - time)) or time
        local timePrefix = extendNum(id, timeDisplay, "Light time", 5)

        prefix = string.format("(%s-%s) ", radiusPrefix, timePrefix)
        common.logMsg(string.format("%s: Object is a light. Prefix: \"%s\".", id, prefix))
    elseif objectType == tes3.objectType.weapon
    or objectType == tes3.objectType.ammunition then
        local objTypePrefix = (config.objectTypePrefixes and "W-") or ""
        local typePrefix = data.weaponTypes[object.type] or "Ot"
        local basePrefix = string.format("%s%s", objTypePrefix, typePrefix)
        common.logMsg(string.format("%s: Object is a weapon or ammunition. Type: \"%s\".", id, typePrefix))

        if config.prefixAttackAR then
            local maxAttack

            if object.isMelee then
                maxAttack = math.max(object.chopMax, object.slashMax, object.thrustMax)
                common.logMsg(string.format("%s: Max attack for melee weapon being added to prefix. Max attack: %u.", id, maxAttack))
            else
                maxAttack = object.chopMax
                common.logMsg(string.format("%s: Max attack for non-melee weapon being added to prefix. Max attack: %u.", id, maxAttack))
            end

            local maxAttackPrefix = extendNum(id, maxAttack, "Attack", 3)
            basePrefix = string.format("%s-%s", basePrefix, maxAttackPrefix)
        end

        prefix = string.format("(%s) ", basePrefix)
        common.logMsg(string.format("%s: Prefix: \"%s\".", id, prefix))
    elseif objectType == tes3.objectType.armor then
        local objTypePrefix = (config.objectTypePrefixes and "A-") or ""
        local weightPrefix

        if config.armorAltWeight then
            weightPrefix = data.armorAltWeightClasses[object.weightClass] or "O"
        else
            weightPrefix = data.armorWeightClasses[object.weightClass] or "O"
        end

        local slotPrefix = data.armorSlots[object.slot] or "Ot"
        local basePrefix
        common.logMsg(string.format("%s: Object is armor. Weight class: \"%s\". Slot: \"%s\".", id, weightPrefix, slotPrefix))

        if config.armorBySlotFirst then
            basePrefix = string.format("%s%s-%s", objTypePrefix, slotPrefix, weightPrefix)
            common.logMsg(string.format("%s: Sorting by armor slot first. Base prefix: \"%s\".", id, basePrefix))
        else
            basePrefix = string.format("%s%s-%s", objTypePrefix, weightPrefix, slotPrefix)
            common.logMsg(string.format("%s: Sorting by weight class first. Base prefix: \"%s\".", id, basePrefix))
        end

        if config.prefixAttackAR then
            local armorRating = object.armorRating
            common.logMsg(string.format("%s: Armor rating being added to prefix. AR: %u.", id, armorRating))

            local armorRatingPrefix = extendNum(id, armorRating, "AR", 3)
            basePrefix = string.format("%s-%s", basePrefix, armorRatingPrefix)
        end

        prefix = string.format("(%s) ", basePrefix)
        common.logMsg(string.format("%s: Prefix: \"%s\".", id, prefix))
    elseif objectType == tes3.objectType.clothing then
        local objTypePrefix = (config.objectTypePrefixes and "C-") or ""
        local slotPrefix = data.clothingSlots[object.slot] or "Ot"
        prefix = string.format("(%s%s) ", objTypePrefix, slotPrefix)
        common.logMsg(string.format("%s: Object is clothing. Prefix: \"%s\".", id, prefix))
    end

    return prefix
end

local function getBaseName(object, id, oldName, objectType, componentName, isKey, ench)
    if not checkBaseNameEnabled(id, objectType, componentName, isKey, "base name change") then
        if ench then
            return savedData.enchItemBaseNames[id]
        else
            return oldName
        end
    end

    local baseNamesList = data.baseNames[objectType]
    local newBaseName

    -- ench is true if this function is being called on loaded, in which case only sourceless objects (.sourceMod is
    -- nil) are being processed. This is principally player-created enchanted items. Base names for such items are
    -- stored in persistent player data when they're created.
    if ench then
        newBaseName = savedData.enchItemBaseNames[id]
    else
        newBaseName = ( baseNamesList and baseNamesList[id] ) or nil
    end

    if newBaseName then
        common.logMsg(string.format("%s: Base name in data tables: %s.", id, newBaseName))
    else
        common.logMsg(string.format("%s: No base name specified in data tables.", id))
    end

    if objectType == tes3.objectType.alchemy then
        if config.altSpoiledNames then
            local altSpoiledName = data.spoiledPotionsAltNames[id]

            if altSpoiledName then
                common.logMsg(string.format("%s: Object is a spoiled potion, and alt spoiled potion names are enabled. Using alt name: %s.", id, altSpoiledName))
                newBaseName = altSpoiledName
            end
        end

        if config.potionRomanNumerals then
            local currentName = newBaseName or oldName
            local currentNameLength = #currentName

            for oldSuffix, newSuffix in pairs(data.potionSuffixReplace) do
                local oldSuffixLength = #oldSuffix

                if string.endswith(currentName, oldSuffix)
                and currentNameLength > oldSuffixLength then
                    local effectBase = string.sub(currentName, 1, currentNameLength - oldSuffixLength)
                    newBaseName = string.format("%s%s", effectBase, newSuffix)
                    common.logMsg(string.format("%s: Object is a regular potion, and Roman numeral suffixes are enabled. Using alt suffix. New base name: %s.", id, newBaseName))

                    break
                end
            end
        end
    end

    if objectType == tes3.objectType.book then
        if object.enchantment and config.removeScrollOf then
            local currentName = newBaseName or oldName
            local currentNameLength = #currentName

            if string.find(currentName:lower(), "scroll of ") == 1
            and currentNameLength > 10 then
                newBaseName = string.sub(currentName, 11, currentNameLength)
                newBaseName = capitalizeFirstChar(newBaseName)
                common.logMsg(string.format("%s: Object is a magic scroll starting with \"Scroll of\", and the related setting is enabled. Removing \"Scroll of\". New base name: %s.", id, newBaseName))
            end
        end
    end

    if objectType == tes3.objectType.miscItem then
        if isKey then
            -- Removes "Key" from the beginning or end of the name, for keys detected dynamically.
            if not newBaseName then
                local dynamicName = oldName

                if string.find(dynamicName:lower(), "key ") == 1
                and #dynamicName >= 5 then
                    dynamicName = string.sub(dynamicName, 5, #dynamicName)
                    dynamicName = capitalizeFirstChar(dynamicName)

                    if string.find(dynamicName:lower(), "to ") == 1
                    and #dynamicName >= 4 then
                        dynamicName = string.sub(dynamicName, 4, #dynamicName)
                        dynamicName = capitalizeFirstChar(dynamicName)
                    end
                end

                if string.endswith(dynamicName:lower(), " key")
                and #dynamicName >= 5 then
                    dynamicName = string.sub(dynamicName, 1, #dynamicName - 4)
                end

                if dynamicName ~= oldName then
                    newBaseName = dynamicName
                    common.logMsg(string.format("%s: Object is a key and not on base name list. Changing name dynamically. New name: %s.", id, newBaseName))
                end
            end

            if config.addKeyAtBeginning then
                local currentName = newBaseName or oldName

                if not string.find(currentName:lower(), " key ") then
                    newBaseName = string.format("Key, %s", currentName)
                    common.logMsg(string.format("%s: Object is a key and mod is configured to add \"Key, \" to name. New name: %s.", id, newBaseName))
                end
            end
        end
    end

    -- Makes certain replaces in item names, depending on how the mod is configured. For example, "Dwarven" can be
    -- replaced with "Dwemer".
    for tweakOption, changeTo in pairs(data.nameTweaksOptions) do
        if config.nameTweaks[tweakOption] then
            local currentName = newBaseName or oldName

            if string.find(currentName, tweakOption) then
                newBaseName = string.gsub(currentName, tweakOption, changeTo)
                common.logMsg(string.format("%s: Per config setting, replacing %s with %s in base name.", id, tweakOption, changeTo))
            end
        end
    end

    if not newBaseName then
        common.logMsg(string.format("%s: No new base name. Skipping base name change.", id))
        return oldName
    end

    common.logMsg(string.format("%s: Final base name: %s.", id, newBaseName))
    return newBaseName
end

local function checkKey(object, id, name, objectType)
    if objectType ~= tes3.objectType.miscItem then
        return false
    end

    -- If something is both a soulgem and a key (for example), treat it as a soulgem.
    if object.isSoulGem
    or data.propylonList[id]
    or data.goldList[id] then
        return false
    end

    if object.isKey or data.keyList[id] then
        return true
    end

    local nameLower = name:lower()

    if string.find(nameLower, "key ") == 1
    or string.endswith(nameLower, " key")
    or string.find(nameLower, " key ") then
        common.logMsg(string.format("%s: Object has been dynamically determined to be a key.", id))
        return true
    end

    return false
end

-- ench will be true when this is a player-created enchanted object, or otherwise does not exist in the esm/esp files.
local function renameObject(object, objectType, ench)
    local id = object.id:lower()

    if not common.checkValidObject(object) then
        common.logMsg(string.format("%s: No or invalid name. Skipping object.", id))
        return
    end

    if config.blacklists.overall[id] then
        common.logMsg(string.format("%s: On overall blacklist. Skipping object.", id))
        return
    end

    local oldName = object.name
    common.logMsg(string.format("%s: Old name: %s.", id, oldName))

    if ench then
        -- This should generally only happen with player-created enchanted items or player-brewed potions that were
        -- created before this mod was installed (or updated to 2.0).
        if not savedData.enchItemBaseNames[id] then
            local newEnchName = common.getInitialNameForEnch(oldName)
            savedData.enchItemBaseNames[id] = newEnchName
            common.logMsg(string.format("%s: Object is sourceless but was not previously saved in player data. Saving object with new base name: %s.", id, newEnchName))
            common.logMsg(string.format("savedData: %s", json.encode(savedData, { indent = true })))
        end
    end

    local componentName = data.componentNames[objectType]
    local isKey = checkKey(object, id, oldName, objectType)
    local newName = getBaseName(object, id, oldName, objectType, componentName, isKey, ench)

    local prefix = getPrefix(object, id, objectType, componentName, isKey)
    newName = string.format("%s%s", prefix, newName)
    common.logMsg(string.format("%s: New name after prefix applied: %s.", id, newName))

    local newObjectName = getNewObjectName(id, newName, prefix, objectType, componentName, isKey)

    if newObjectName ~= oldName then
        object.name = newObjectName
        common.logMsg(string.format("%s: Object name set to: %s.", id, object.name))
    else
        common.logMsg(string.format("%s: Final object name (%s) is identical to original name. Not changing object name.", id, newObjectName))
    end

    newName = getSubstituteName(id, newName, objectType, componentName, isKey)
    local newNameNoPrefix = string.sub(newName, #prefix + 1, #newName)

    -- Save the display names (with and without prefixes), when they differ from the object name, to tables so the
    -- functions in ui.lua can force the UI to display the correct name.
    if newName ~= newObjectName then
        if ench then
            data.enchDisplayNames[id] = newName
        else
            data.displayNames[id] = newName
        end

        common.logMsg(string.format("%s: Final display name (%s) differs from object name (%s). Saving in data table for UI display. (ench: %s)", id, newName, newObjectName, ench))
    end

    if newNameNoPrefix ~= newObjectName then
        if ench then
            data.enchDisplayNamesNoPrefix[id] = newNameNoPrefix
        else
            data.displayNamesNoPrefix[id] = newNameNoPrefix
        end

        common.logMsg(string.format("%s: Final display name without prefix (%s) differs from object name (%s). Saving in data table for UI display. (ench: %s)", id, newNameNoPrefix, newObjectName, ench))
    end

    -- If this object will ever display a name other than its object name, add it to a reverse lookup table so we can
    -- get the ID from the object name. This is needed to deal with magic effect tooltips and dialogue notification
    -- messages.
    if data.displayNames[id] or data.displayNamesNoPrefix[id]
    or data.enchDisplayNames[id] or data.enchDisplayNamesNoPrefix[id] then
        if ench then
            data.enchObjectNameToID[newObjectName] = id
        else
            data.objectNameToID[newObjectName] = id
        end

        common.logMsg(string.format("%s: Saving object name in reverse lookup table. (ench: %s)", id, ench))
    end

    if isKey then
        if config.keyWeightValue then
            object.value = 0
            object.weight = 0
            common.logMsg(string.format("%s: Object is a key. Per config option, setting value and weight to 0.", id))
        end

        if config.keyIsKey then
            object.isKey = true
            common.logMsg(string.format("%s: Object is a key. Per config option, setting isKey flag to true.", id))
        end
    end
end

local function renameAllOfType(objectType, ench)
    for object in tes3.iterateObjects(objectType) do
        -- When this function is called on initialized (ench is false), we process every object. When called on loaded
        -- (ench is true), we only care about sourceless objects (really just player-created enchanted items).
        if (not ench) or object.sourceMod == nil then
            renameObject(object, objectType, ench)
        end
    end
end

local function renameAllObjects(ench)
    for _, objectType in ipairs(data.components) do
        local componentName = data.componentNames[objectType]

        if config.componentEnable.overall[tostring(objectType)] then
            common.logMsg(string.format("Renaming %s.", componentName))
            renameAllOfType(objectType, ench)
        else
            common.logMsg(string.format("The %s component is disabled. Skipping %s.", componentName, componentName))
        end
    end
end

this.onEnchantedItemCreated = function(e)
    local object = e.object
    local id = object.id:lower()
    local name = object.name

    -- Removes any prefix from the object name, if somehow it got in there.
    local initEnchName = common.getInitialNameForEnch(name)
    savedData.enchItemBaseNames[id] = initEnchName
    common.logMsg(string.format("Enchanted item created. id: %s. Original name: %s. Name saved in player data: %s.", id, name, initEnchName))
    common.logMsg(string.format("savedData: %s", json.encode(savedData, { indent = true })))

    renameObject(object, object.objectType, true)
end

this.onLoaded = function()
    -- We save base names of player-created enchanted items in persistent player data; we need to rename them and add
    -- prefixes on every game load.
    tes3.player.data.rationalNames = tes3.player.data.rationalNames or {}
    savedData = tes3.player.data.rationalNames
    savedData.enchItemBaseNames = savedData.enchItemBaseNames or {}
    common.logMsg(string.format("savedData: %s", json.encode(savedData, { indent = true })))

    -- We use separate tables for sourceless items so we can clear them on game load (player could be loading an earlier
    -- save, or a save for a different character, so we have to repopulate these tables on each load).
    data.enchDisplayNames = {}
    data.enchDisplayNamesNoPrefix = {}
    data.enchObjectNameToID = {}

    common.logMsg("Renaming all objects without a sourceMod on loaded.")
    renameAllObjects(true)

    common.logTable(data.enchDisplayNames, "enchDisplayNames")
    common.logTable(data.enchDisplayNamesNoPrefix, "enchDisplayNamesNoPrefix")
    common.logTable(data.enchObjectNameToID, "enchObjectNameToID")
end

this.onInitialized = function()
    common.logMsg("Renaming all objects on initialized.")
    renameAllObjects(false)
end

return this