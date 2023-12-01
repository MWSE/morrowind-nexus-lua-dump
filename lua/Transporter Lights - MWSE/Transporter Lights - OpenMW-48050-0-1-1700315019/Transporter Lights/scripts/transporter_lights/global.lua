local world = require "openmw.world"
local types = require "openmw.types"
local storage = require "openmw.storage"
local core = require("openmw.core")
local option = storage.globalSection("Settings_Transporter_Lights_Options_Key_KINDI")

local constants = require("scripts.transporter_lights.constants")
local lights = constants.lights
local alternateLights = constants.alternateLights

local transporters = {}

-- probably could use some error checking here..
local function selectLight(actor, index)
    local lightItemID
    if option:get("Alternate Lights") then
        -- NOTE: randomized or by index
        lightItemID = index and alternateLights[index] or alternateLights[math.random(#alternateLights)] -- JIC
    else
        lightItemID = lights[types.NPC.record(actor).class]
    end
    return lightItemID
end

local function equipLights(actor, index)
    if not option:get("Mod Status") then
        return
    end
    local success, lightObject = pcall(world.createObject, selectLight(actor, index), 1)
    if success then
        -- NOTE: moveInto is not instantaneous
        lightObject:moveInto(types.Actor.inventory(actor))
        core.sendGlobalEvent("UseItem", { object = lightObject, actor = actor, force = true })

        local lastLightObject = transporters[actor.id]
        if lastLightObject then
            lastLightObject:remove()
            transporters[actor.id] = nil
        end
        transporters[actor.id] = lightObject
    else
        -- invalid lightId?
    end
end

return {
    engineHandlers = {
        onActorActive = function(actor)
            if actor.type == types.NPC and lights[types.NPC.record(actor).class] and types.Actor.stats.dynamic.health(actor).current >= 1 then
                actor:addScript("scripts/transporter_lights/transporters.lua")
            end
        end,
        onLoad = function(data)
            transporters = data and data.transporters or {}
        end,
        onSave = function()
            return {
                transporters = transporters
            }
        end
    },
    eventHandlers = {
        TRANSPORTER_LIGHTS_EQUIP_LIGHT_EQNX = function(data)
            equipLights(table.unpack(data))
        end,
    }
}
