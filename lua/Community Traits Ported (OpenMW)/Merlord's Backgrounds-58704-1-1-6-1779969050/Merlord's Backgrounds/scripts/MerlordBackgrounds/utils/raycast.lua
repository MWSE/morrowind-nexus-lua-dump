--  Taken from Dangers of Broken Artifacts by Foxunder
-- https://www.nexusmods.com/morrowind/mods/58227
local util = require("openmw.util")
local nearby = require("openmw.nearby")

local SPAWN_Z_OFFSET = 50
local GROUND_CHECK_Z = 200

local raycast = {}

raycast.findSafeSpawnPos = function(actor, distance)
    local backward = actor.rotation:apply(util.vector3(0, -1, 0))
    local right   = actor.rotation:apply(util.vector3(1, 0, 0))

    local candidateDirs = {
        backward,
        backward + right * 0.4,
        backward - right * 0.4,
        backward + right * 0.8,
        backward - right * 0.8,
    }

    for _, dir in ipairs(candidateDirs) do
        local candidate = actor.position + dir:normalize() * distance

        local wallCheck = nearby.castRay(
            actor.position + util.vector3(0, 0, 60),
            candidate      + util.vector3(0, 0, 60),
            {
                collisionType = nearby.COLLISION_TYPE.World,
                ignore = { actor }
            }
        )

        if not wallCheck.hit then
            local groundCheck = nearby.castRay(
                candidate + util.vector3(0, 0, SPAWN_Z_OFFSET),
                candidate - util.vector3(0, 0, GROUND_CHECK_Z),
                { collisionType = nearby.COLLISION_TYPE.World }
            )

            if groundCheck.hit then
                local heightDiff = math.abs(groundCheck.hitPos.z - actor.position.z)
                if heightDiff < 120 then
                    return groundCheck.hitPos + util.vector3(0, 0, 10)
                end
            end
        end
    end

    return actor.position + util.vector3(0, 0, 80)
end

return raycast
