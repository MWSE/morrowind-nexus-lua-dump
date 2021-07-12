local config = require("RationalNames.config")
local data = require("RationalNames.data")
local common = require("RationalNames.common")

local this = {}

-- num is the max attack of a weapon or the base AR of an armor piece. Returns the same number as a string, with leading
-- zeros as needed to ensure it will display as two or three digits in the prefix.
local function extendNum(id, num, log)
    local numPrefix = tostring(math.floor(num))
    local targetLength = ( config.shortPrefixAttackAR and 2 ) or 3
    local tooShort = targetLength - #numPrefix

    if tooShort > 0 then
        local zeros = string.rep("0", tooShort)
        numPrefix = string.format("%s%s", zeros, numPrefix)
        common.logMsg(string.format("%s: %s does not take up enough digits. Adding leading 0s so it will use %u digits.", id, log, targetLength))
    end

    return numPrefix
end

this.renameObjects = function(objectType)
    for object in tes3.iterateObjects(objectType) do
        local id = object.id:lower()
        local oldName, newName, baseNameEnabled, componentName, newBaseName, prefix
        local isKey = false

        if config.overallBlacklist[id] then
            common.logMsg(string.format("%s: On overall blacklist. Skipping object.", id))
            goto skipObject
        end

        oldName = object.name

        if ( not oldName )
        or oldName == ""
        or oldName == "FOR SPELL CASTING" then
            common.logMsg(string.format("%s: No or invalid name. Skipping object.", id))
            goto skipObject
        end

        common.logMsg(string.format("%s: Old name: %s.", id, oldName))
        newName = oldName

        baseNameEnabled = config.baseNameEnable[tostring(objectType)]
        componentName = data.componentNames[objectType]

        --[[ Some object types (specifically, those which don't have prefixes and therefore the only changes made by
        this mod are to the object base names) don't have a baseNameEnabled option in the MCM (because it's more
        efficient to just disable the corresponding component instead, which will prevent this function from being run
        for the object type at all). That's why we only care if the setting is false here. If it's nil we proceed. ]]--
        if baseNameEnabled == false then
            common.logMsg(string.format("%s: Base name changes for %s are disabled. Skipping base name change.", id, componentName))
            goto skipBaseName
        end

        if config.baseNameBlacklist[id] then
            common.logMsg(string.format("%s: On base name blacklist. Skipping base name change.", id))
            goto skipBaseName
        end

        newBaseName = data.baseNames[objectType][id]

        if not newBaseName then
            common.logMsg(string.format("%s: No new base name. Skipping base name change.", id))
            goto skipBaseName
        end

        if objectType == tes3.objectType.alchemy
        and config.altSpoiledNames then
            local altSpoiledName = data.spoiledPotionsAltNames[id]

            if altSpoiledName then
                common.logMsg(string.format("%s: Object is a spoiled potion, and alt spoiled potion names are enabled. Using alt name.", id))
                newBaseName = altSpoiledName
            end
        end

        common.logMsg(string.format("%s: New base name: %s.", id, newBaseName))
        newName = newBaseName

        ::skipBaseName::

        if objectType == tes3.objectType.alchemy then
            if data.drinksList[id] then
                prefix = "~"
                common.logMsg(string.format("%s: Object is a potion and on the drinks list. Prefix: \"%s\".", id, prefix))
            else
                common.logMsg(string.format("%s: Object is a potion but not on the drinks list. Skipping prefix.", id))
                goto skipPrefix
            end
        elseif objectType == tes3.objectType.book then
            if object.enchantment then
                prefix = "~"
                common.logMsg(string.format("%s: Object is a magic scroll. Prefix: \"%s\".", id, prefix))
            elseif object.type == tes3.bookType.scroll then
                prefix = "."
                common.logMsg(string.format("%s: Object is a non-magic scroll. Prefix: \"%s\".", id, prefix))
            else
                common.logMsg(string.format("%s: Object is a book but not a scroll. Skipping prefix.", id))
                goto skipPrefix
            end
        elseif objectType == tes3.objectType.miscItem then
            if object.isSoulGem
            or data.soulgemList[id] then
                prefix = "(S) "
                common.logMsg(string.format("%s: Object is a soulgem. Prefix: \"%s\".", id, prefix))
            elseif object.isKey
            or data.keyList[id] then
                isKey = true
                prefix = "(K) "
                common.logMsg(string.format("%s: Object is a key. Prefix: \"%s\".", id, prefix))
            elseif data.propylonList[id] then
                prefix = "(P) "
                common.logMsg(string.format("%s: Object is a propylon index. Prefix: \"%s\".", id, prefix))
            elseif data.goldList[id]
            and config.goldAtEnd then
                prefix = "~"
                common.logMsg(string.format("%s: Object is gold, and gold prefix is enabled. Prefix: \"%s\".", id, prefix))
            else
                common.logMsg(string.format("%s: Object is a misc item but not a soulgem, key, propylon index or gold (or is gold but gold prefix is disabled). Skipping prefix.", id))
                goto skipPrefix
            end
        elseif objectType == tes3.objectType.weapon
        or objectType == tes3.objectType.ammunition then
            local typePrefix = data.weaponTypes[object.type] or "Ot"
            local basePrefix = typePrefix
            common.logMsg(string.format("%s: Object is a weapon or ammunition. Type: \"%s\".", id, typePrefix))

            if config.prefixAttackAR then
                local maxAttack = math.max(object.chopMax, object.slashMax, object.thrustMax)
                common.logMsg(string.format("%s: Max attack being added to prefix. Max attack: %u.", id, maxAttack))

                local maxAttackPrefix = extendNum(id, maxAttack, "Attack")
                basePrefix = string.format("%s-%s", basePrefix, maxAttackPrefix)
            end

            prefix = string.format("(%s) ", basePrefix)
            common.logMsg(string.format("%s: Prefix: \"%s\".", id, prefix))
        elseif objectType == tes3.objectType.armor then
            local weightPrefix = data.armorWeightClasses[object.weightClass] or "O"
            local slotPrefix = data.armorSlots[object.slot] or "Ot"
            local basePrefix
            common.logMsg(string.format("%s: Object is armor. Weight class: \"%s\". Slot: \"%s\".", id, weightPrefix, slotPrefix))

            if config.armorBySlotFirst then
                basePrefix = string.format("%s-%s", slotPrefix, weightPrefix)
                common.logMsg(string.format("%s: Sorting by armor slot first. Base prefix: \"%s\".", id, basePrefix))
            else
                basePrefix = string.format("%s-%s", weightPrefix, slotPrefix)
                common.logMsg(string.format("%s: Sorting by weight class first. Base prefix: \"%s\".", id, basePrefix))
            end

            if config.prefixAttackAR then
                local armorRating = object.armorRating
                common.logMsg(string.format("%s: Armor rating being added to prefix. AR: %u.", id, armorRating))

                local armorRatingPrefix = extendNum(id, armorRating, "AR")
                basePrefix = string.format("%s-%s", basePrefix, armorRatingPrefix)
            end

            prefix = string.format("(%s) ", basePrefix)
            common.logMsg(string.format("%s: Prefix: \"%s\".", id, prefix))
        elseif objectType == tes3.objectType.clothing then
            local slotPrefix = data.clothingSlots[object.slot] or "Ot"
            prefix = string.format("(%s) ", slotPrefix)
            common.logMsg(string.format("%s: Object is clothing. Prefix: \"%s\".", id, prefix))
        else
            common.logMsg(string.format("%s: There are no prefixes for %s. Skipping prefix.", id, componentName))
            goto skipPrefix
        end

        if prefix then
            newName = string.format("%s%s", prefix, newName)
            common.logMsg(string.format("%s: New name after prefix applied: %s.", id, newName))
        else
            common.logMsg(string.format("%s: Prefix is nil, skipping. (This should never happen.)", id))
        end

        ::skipPrefix::

        --[[ The game will mess itself if we try to assign an object name greater than 31 characters. So we save the
        full (long) name to a table so the functions in ui.lua can force the UI to display the full name, then set the
        actual object name to only the first 31 characters of the full name. We also add this object to a reverse lookup
        table so we can get the ID from the short name, which is needed to deal with magic effect tooltips. ]]--
        if #newName > 31 then
            data.fullNamesList[id] = newName
            newName = string.sub(newName, 1, 31)
            data.shortNameToID[newName] = id
            common.logMsg(string.format("%s: New name is > 31 characters. Shortening name to: %s. (Full name will display in the UI.)", id, newName))
        end

        if newName ~= oldName then
            object.name = newName
            common.logMsg(string.format("%s: Final name: %s.", id, newName))
            common.logMsg(string.format("%s: Real final name: %s.", id, object.name))
        else
            common.logMsg(string.format("%s: Final name (%s) is identical to original name.", id, newName))
        end

        if isKey
        and config.keyWeightValue then
            object.value = 0
            object.weight = 0
            common.logMsg(string.format("%s: Object is a key. Per config option, setting value and weight to 0.", id))
        end

        ::skipObject::
    end
end

return this