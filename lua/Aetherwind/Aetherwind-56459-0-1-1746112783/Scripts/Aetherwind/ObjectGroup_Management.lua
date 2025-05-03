local I = require("openmw.interfaces")

local v2 = require("openmw.util").vector2
local util = require("openmw.util")
local core = require("openmw.core")
local types = require("openmw.types")
local storage = require("openmw.storage")
local world = require("openmw.world")
local async = require("openmw.async")
local acti = require("openmw.interfaces").Activation

local objectGroups = {}
local objectGroupId = {}
local function createObjectGroup(list,key)
    objectGroups[key] = list
    for _, x in ipairs(list) do
        objectGroupId[x.id] = key
    end

end
local function getObjectGroup(key)
    return objectGroups[key]
end
local function removeFromObjectGroup(key,object)
    if objectGroups[key] then
        for i, x in ipairs(objectGroups[key]) do
            if x == object then
                table.remove(objectGroups[key],i)
                return
            end
        end
    end
end

local function removeObjectFromAllGroups(object)
    for _, group in pairs(objectGroups) do
        for i, x in ipairs(group) do
            if x == object then
                table.remove(group, i)
                break
            end
        end
    end
    if object then
        objectGroupId[object.id] = nil
    end
end

local function addToObjectGroup(key, object)
    removeObjectFromAllGroups(object)
    objectGroupId[object.id] = key
    if objectGroups[key] then
        table.insert(objectGroups[key], object)
        return objectGroups[key][1]
    end
end

local function disableObjectGroup(key,state)
    if objectGroups[key] then
        for _, x in ipairs(objectGroups[key]) do
            x.enabled = state or false
        end
    end
end
local function standUpdate(data)
    local actor = data.actor
    local object = data.object
    local val
    removeObjectFromAllGroups(actor)
    if object and  objectGroupId[object.id] then
        val =  addToObjectGroup(objectGroupId[object.id], actor)
    elseif not object then
        removeObjectFromAllGroups(object)
    end
    if actor.type == types.Player then
        actor:sendEvent("setAirshipOb",val)
        if val then
            I.Aeth_ShipManage.setPlayerShip(val.recordId)
        else
            I.Aeth_ShipManage.setPlayerShip(nil)
        end
    end
end
return {
    interfaceName = "ObjectGroup_Management",
    interface = {
        createObjectGroup = createObjectGroup,
        getObjectGroup = getObjectGroup,
        disableObjectGroup = disableObjectGroup,
        addToObjectGroup = addToObjectGroup,
        removeFromObjectGroup = removeFromObjectGroup,
    },
    eventHandlers = {standUpdate = standUpdate},
    engineHandlers = {
        onSave = function ()
            return {objectGroups = objectGroups, objectGroupId = objectGroupId}
        end,
        onLoad = function (data)
            if data.objectGroups then
                objectGroups = data.objectGroups
                objectGroupId = data.objectGroupId or {}
            end
        end
    }
}
