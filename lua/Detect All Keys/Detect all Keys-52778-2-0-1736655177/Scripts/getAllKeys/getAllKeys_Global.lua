local util = require("openmw.util")
local world = require("openmw.world")
local core = require("openmw.core")
local types = require("openmw.types")
local async = require('openmw.async')

local acti = require("openmw.interfaces").Activation
local checkPlaced = false
if (core.API_REVISION < 69) then

   return {}
end
local keyMap = {}
local function checkIsKey(record)
    if record.isKey == true then
        return false -- it is a key, but already tracked so we don't need to add a new itemcheck
    end

    local icon = record.icon:lower()
    local model = record.model:lower()
    local name = record.name:lower()
    local id = record.id:lower()

    if string.find(icon, "key") or string.find(model, "key") or
        string.find(name, "key") or string.find(id, "key") then
        return true -- record contains the word "key"
    end

    return false -- record does not contain the word "key"
end

local function findAllKeys()
    local miscitems = types.Miscellaneous.records
    for i, record in ipairs(miscitems) do
        if (checkIsKey(record)) then print(record.id) end
    end

end
local function addKeyToInventory(inv)
    local keyItem = world.createObject("ZHAC_PlaceholderKey")
    keyItem:moveInto(inv)
    -- print("Added to " .. inv.recordId)

end
local function addKeyToWorld(object)
    local keyItem = world.createObject("ZHAC_PlaceholderKey")
    keyItem:teleport(object.cell, object.position)
    keyMap[object.id ] = keyItem.id
    -- print("Placed Key")
end
local function removeKeyFromInventory(data)

    local object = data.cont
    local inv = types.Container.content(object)
    local itemcheck = inv:find("ZHAC_PlaceholderKey")
    if (itemcheck ~= nil) then
        itemcheck:remove()
    end
end
local function onItemActive(item)

    if (item.type == types.Miscellaneous) then
        if (checkIsKey(types.Miscellaneous.record(item))) then
            addKeyToWorld(item)
        end
    end

end

local function MiscActivate(object, actor)
   if keyMap[object.id] then
      for i,x in ipairs(object.cell:getAll(types.Miscellaneous)) do
         if x.id == keyMap[object.id]  then
            x:remove()
         end
      end
    end
end
local function ContainerActivate(object, actor)

   removeKeyFromInventory({cont = object, player = actor})
end
acti.addHandlerForType(types.NPC, ContainerActivate)
acti.addHandlerForType(types.Container, ContainerActivate)
acti.addHandlerForType(types.Miscellaneous, MiscActivate)
local function contentFileCheck()


    world.mwscript.getGlobalVariables(world.players[1])
    .ZHAC_CheckForScriptsFile = 1
    if not core.contentFiles.has("detectallkeys.omwaddon") then
        world.players[1]:sendEvent("ZHAC_ShowMessage",
                         "You do not have the DetectAllKeys OMWAddon loaded! The mod will not work.")
    end

    return false
end
local function onActivate(object, actor)
    for i, item in ipairs(actor.cell:getAll(types.Miscellaneous)) do
        if (item.recordId == "zhac_placeholderkey" and item.position ==
            object.position) then
            item:remove()
            -- print("Removed found item")
        end
    end
end
return {
    eventHandlers = {
        addKeyToInventory = addKeyToInventory,
        removeKeyFromInventory = removeKeyFromInventory,
        findAllKeys = findAllKeys,
    },
    engineHandlers = {
        onActivate = onActivate,
        onItemActive = onItemActive,
        onInit = contentFileCheck,
        onPlayerAdded = contentFileCheck,
        onSave = function ()
         return {
            keyMap = keyMap
         }
        end,
        onLoad = function (data)
         if data then
            keyMap = data.keyMap or {}
         end
        end
    }
}
