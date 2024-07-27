local gutils = require("scripts/MaxYari/BirdsYoink/gutils")

local core = require("openmw.core")
local omwself = require("openmw.self")
local nearby = require("openmw.nearby")
local util = require("openmw.util")


local function isABird(actor)
    return string.find(actor.recordId, "ab01bird")
end

if not isABird(omwself) then return end


--print("Bird yoinker found a bird! ", omwself.recordId)

local beenYoinkedAtStart = false
local desiredElevation = 3000
local dangerZone = math.random(300, 600)

local function onUpdate(dt)
    local now = core.getRealTime()
    local raycast = nearby.castRay(omwself.position,
        omwself.position - util.vector3(0, 0, desiredElevation), { ignore = omwself })

    if raycast.hitPos and (not raycast.hitObject or not isABird(raycast.hitObject)) then
        local elevation = (omwself.position - raycast.hitPos).z
        local elevationGain = desiredElevation - elevation

        if elevation < desiredElevation and not beenYoinkedAtStart then
            --print("START: Birb" .. omwself.recordId .. " was too low, yoinking to ", desiredElevation)
            core.sendGlobalEvent("instaYoink", { actorObject = omwself, elevationGain = elevationGain })
        elseif elevation < dangerZone then
            --print("DANGER ZONE: Birb" .. omwself.recordId .. " was too low, yoinking to ", desiredElevation)
            core.sendGlobalEvent("slowYoink", { actorObject = omwself, elevationGain = elevationGain })
        end
    end

    beenYoinkedAtStart = true
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
    }
}
