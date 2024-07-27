local gutils = require("scripts/MaxYari/BirdsYoink/gutils")


local core = require("openmw.core")
local util = require("openmw.util")
local world = require('openmw.world')

local function isABird(actor)
    return string.find(actor.recordId, "ab01bird")
end

print("°°°Bird yoinker is ready to yoink some birds!°°°")

local slowYoinkers = {}

local function isValid(birb)
    return birb and birb:isValid() and birb.count > 0
end

local function onUpdate(dt)
    for birb, data in pairs(slowYoinkers) do
        if not isValid(birb) or math.abs(birb.position.z - data.elevation) <= 100 then
            slowYoinkers[birb] = nil
            goto continue
        end

        local newZ = gutils.lerp(birb.position.z, data.elevation, dt / 5)
        local newPos = util.vector3(birb.position.x, birb.position.y, newZ)
        birb:teleport(birb.cell, newPos)

        ::continue::
    end
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
    },
    eventHandlers = {
        instaYoink = function(data)
            -- print("Yoinking the" .. data.actorObject.recordId .. " bird")
            data.actorObject:teleport(data.actorObject.cell,
                data.actorObject.position + util.vector3(0, 0, data.elevationGain))
        end,
        slowYoink = function(data)
            if slowYoinkers[data.actorObject] then return end

            slowYoinkers[data.actorObject] = {
                elevation = data.actorObject.position.z + data.elevationGain
            }
        end
    },
}
