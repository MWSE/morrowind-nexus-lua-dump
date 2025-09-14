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

local function objectInactive(object)
    world.players[1]:sendEvent("proximityTool:removeActiveObject", object)
    if object:hasScript("scripts/proximityTool/objectLocal.lua") then
        object:removeScript("scripts/proximityTool/objectLocal.lua")
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
    },
}