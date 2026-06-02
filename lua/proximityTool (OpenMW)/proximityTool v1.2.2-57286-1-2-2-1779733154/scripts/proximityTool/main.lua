local async = require('openmw.async')
local types = require('openmw.types')
local world = require('openmw.world')

local supportedObjectTypes = require("scripts.proximityTool.supportedObjectTypes")


local function onObjectActiveGlobal(object)
    if supportedObjectTypes[object.type] then
        if not object:hasScript("scripts/proximityTool/objectLocal.lua") then

            world.players[1]:sendEvent("proximityTool:addActiveObject", object)
            object:addScript("scripts/proximityTool/objectLocal.lua")

        end
    end
end

local function onObjectActive(object)
    world.players[1]:sendEvent("proximityTool:addActiveObject", object)
end

local function objectInactive(objectData)
    local object = objectData[1]
    world.players[1]:sendEvent("proximityTool:removeActiveObject", objectData)
    if object:isValid() and object:hasScript("scripts/proximityTool/objectLocal.lua") then
        object:removeScript("scripts/proximityTool/objectLocal.lua")
    end
end

local function checkObjectStatus(objectData)
    local object = objectData[1]
    if not object:isValid() then return end

    if not object.cell or not object.enabled then
        world.players[1]:sendEvent("proximityTool:removeActiveObject", objectData)
        if object:hasScript("scripts/proximityTool/objectLocal.lua") then
            object:removeScript("scripts/proximityTool/objectLocal.lua")
        end
    end
end


return {
    engineHandlers = {
        onObjectActive = async:callback(onObjectActiveGlobal),
        onItemActive = async:callback(onObjectActiveGlobal),
    },
    eventHandlers = {
        ["proximityTool:objectInactive"] = objectInactive,
        ["proximityTool:objectActive"] = onObjectActive,
        ["proximityTool:checkObjectStatus"] = checkObjectStatus,
    },
}