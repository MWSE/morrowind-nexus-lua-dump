local nearby = require('openmw.nearby')
local util   = require('openmw.util')

local SPAWN_DIST     = 150
local SPAWN_Z_OFFSET = 50
local GROUND_CHECK_Z = 200

local RC = {}

function RC.findSafeSpawnPos(actor)
    local forward = actor.rotation:apply(util.vector3(0, 1, 0))
    local right   = actor.rotation:apply(util.vector3(1, 0, 0))

    local candidateDirs = {
        forward,
        forward + right * 0.4,
        forward - right * 0.4,
        forward + right * 0.8,
        forward - right * 0.8,
    }

    for _, dir in ipairs(candidateDirs) do
        local candidate = actor.position + dir:normalize() * SPAWN_DIST

        local wallCheck = nearby.castRay(
            actor.position + util.vector3(0, 0, 60),
            candidate      + util.vector3(0, 0, 60),
            { collisionType = nearby.COLLISION_TYPE.World, ignore = { actor } }
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

return RC