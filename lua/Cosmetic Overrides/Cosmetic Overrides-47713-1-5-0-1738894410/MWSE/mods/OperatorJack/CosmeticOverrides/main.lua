local config = require("OperatorJack.CosmeticOverrides.config")
local log = require("OperatorJack.CosmeticOverrides.logger")
local data = require("OperatorJack.CosmeticOverrides.data")
local mcm = require("OperatorJack.CosmeticOverrides.mcm")



--- Initializes the mod-data stored in the player.data object so that it can be safely accessed.
local function initializePlayerData()
    tes3.player.data.OJ_CosmeticOverrides = tes3.player.data.OJ_CosmeticOverrides or
        { Active = {}, Possible = {} }
end

--- Initializes the MCM dropdown options based on the currently unlocked cosmetic overrides.
local function initializePlayerDataOptions()
    for objectType, objectTypeTbl in pairs(tes3.player.data.OJ_CosmeticOverrides.Possible) do
        for slotName in pairs(objectTypeTbl) do
            mcm.updateOptions(objectType, slotName)
        end
    end
end

local function getSlotNameFromObject(obj)
    log:debug("Getting slot name from object type %s", obj.objectType)
    local slotName
    if (obj.objectType == tes3.objectType.armor) then
        slotName = table.find(tes3.armorSlot, obj.slot)
    else
        slotName = table.find(tes3.clothingSlot, obj.slot)
    end

    log:debug("Got slot name %s", slotName)
    if (slotName) then
        return slotName:lower()
    else
        return nil
    end
end

local function getOverrideItemId(objectType, objectTypeName)
    log:debug("Getting override item id for object type %s and slot %s", objectType, objectTypeName)
    if (tes3.player.data.OJ_CosmeticOverrides.Active[objectType]) then
        return tes3.player.data.OJ_CosmeticOverrides.Active[objectType][objectTypeName]
    end
    return nil
end

---@type {[string] : tes3armor | tes3clothing}
local cachedObjects = {}

local function getOverrideObject(objectType, objectTypeName)
    local overrideItemId = getOverrideItemId(objectType, objectTypeName)
    log:debug("Got override item id %s", overrideItemId)
    if (overrideItemId) then
        if (cachedObjects[overrideItemId] == nil) then
            log:debug("No cached override object, loading object")
            local obj = tes3.getObject(overrideItemId) --- @cast obj tes3armor | tes3clothing
            cachedObjects[overrideItemId] = obj
        end

        return cachedObjects[overrideItemId]
    end
    return nil
end

---@param e updateBodyPartsForItemEventData
local function onUpdateBodyPartsForItem(e)
    if (e.reference ~= tes3.player) then return end

    -- We initialize the player data to make our data access safe.
    initializePlayerData()

    local objectTypeString = mwse.longToString(e.item.objectType)
    local slotName = getSlotNameFromObject(e.item)

    log:info("Searching for override for item %s for slot %s", e.item.mesh, slotName)

    -- Check if we have an override set for this slot.
    local overrideItem = getOverrideObject(objectTypeString, slotName)
    if (overrideItem) then
        log:info("Found override item %s for slot %s", overrideItem.mesh, slotName)

        -- Override the equipped item with our override.
        e.item = overrideItem
    end
end
event.register(tes3.event.updateBodyPartsForItem, onUpdateBodyPartsForItem)


---@param e equippedEventData
local function onEquipped(e)
    local item = e.item

    if (item.objectType == tes3.objectType.armor or item.objectType == tes3.objectType.clothing) then
        local slotName = getSlotNameFromObject(item)
        if (slotName == nil or data.categories[e.item.objectType].blockedSlots[slotName] == true) then
            return
        end

        log:debug("Equipped possible item. Attempting Unlock %s", item.name)

        local objectTypeString = mwse.longToString(e.item.objectType)
        tes3.player.data.OJ_CosmeticOverrides.Possible[objectTypeString] =
            tes3.player.data.OJ_CosmeticOverrides.Possible[objectTypeString] or
            {}
        tes3.player.data.OJ_CosmeticOverrides.Possible[objectTypeString][slotName] =
            tes3.player.data.OJ_CosmeticOverrides.Possible[objectTypeString][slotName] or
            {}

        if (not tes3.player.data.OJ_CosmeticOverrides.Possible[objectTypeString][slotName][item.id] and
                config.showMessages) then
            log:debug("Unlocked %s", item.name)
            tes3.messageBox("Unlocked '%s' Cosmetic", item.name)
        end

        tes3.player.data.OJ_CosmeticOverrides.Possible[objectTypeString][slotName][item.id] = item.name

        mcm.updateOptions(objectTypeString, slotName)
    end
end
event.register(tes3.event.equipped, onEquipped)

---@param e loadedEventData
local function onLoaded(e)
    initializePlayerData()
    initializePlayerDataOptions()

    log:info("Initialized for current save game.")
end
event.register(tes3.event.loaded, onLoaded)


local function triggerBodyPartsUpdate()
    tes3.player:updateEquipment()
    tes3.player1stPerson:updateEquipment()
end

event.register(tes3.event.menuExit, function() triggerBodyPartsUpdate() end)
