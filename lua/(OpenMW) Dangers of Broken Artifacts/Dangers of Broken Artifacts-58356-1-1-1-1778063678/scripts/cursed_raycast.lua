local nearby = require('openmw.nearby')
local util   = require('openmw.util')

local SPAWN_DIST = 150
local NAV_SEARCH_RADIUS = 100
local MAX_HEIGHT_DIFF = 120

local NUM_DIRS = 12
local ANGLE_STEP = math.rad(360 / NUM_DIRS)

local RC = {}

local function yawForward(actor)
    local yaw = actor.rotation:getYaw()
    return util.vector3(math.sin(yaw), math.cos(yaw), 0)
end

function RC.findSafeSpawnPos(actor)
    local forward = yawForward(actor)
    local startPos = actor.position

    for i = 0, NUM_DIRS - 1 do
        local k = math.ceil(i / 2)
        local sign = (i % 2 == 0) and 1 or -1
        local angle = k * ANGLE_STEP * sign
        
        local cosT, sinT = math.cos(angle), math.sin(angle)
        local dir = util.vector3(
            forward.x * cosT - forward.y * sinT,
            forward.x * sinT + forward.y * cosT,
            0
        )

        local candidate = startPos + dir * SPAWN_DIST

        -- much cheaper than manual raycasting
        local navPos = nearby.findNearestNavMeshPosition(candidate, {
            maxDistance = NAV_SEARCH_RADIUS
        })

        if navPos then
            -- verify the height is reasonable
            local heightDiff = math.abs(navPos.z - startPos.z)
            if heightDiff < MAX_HEIGHT_DIFF then
                -- return the NavMesh position slightly offset upwards
                return navPos + util.vector3(0, 0, 5)
            end
        end
    end

    -- Fallback to just above the player if no NavMesh found nearby
    return startPos + util.vector3(0, 0, 80)
end

return RC