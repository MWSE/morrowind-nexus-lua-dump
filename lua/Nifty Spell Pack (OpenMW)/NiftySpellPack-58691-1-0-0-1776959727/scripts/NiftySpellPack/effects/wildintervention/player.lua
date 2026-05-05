local util = require('openmw.util')
local nearby = require('openmw.nearby')
local self = require('openmw.self')
local core = require('openmw.core')
local debug = require('openmw.debug')

local COLLISION_MASK = nearby.COLLISION_TYPE.Default - nearby.COLLISION_TYPE.Actor
local SKYCAST_DENSITY = 9
local SKYCAST_GRID_SIZE = 1000
local SKYCAST_START_OFFSET_Z = 50000
local SKYCAST_DISTANCE = 100000

local function castSkyRay(x, y, baseZ)
    local origin = util.vector3(x, y, baseZ + SKYCAST_START_OFFSET_Z)
    local target = util.vector3(x, y, baseZ + SKYCAST_START_OFFSET_Z - SKYCAST_DISTANCE)
    local hit = nearby.castRay(origin, target, {
        radius = 0,
        collisionType = COLLISION_MASK,
    })
    return hit and hit.hitPos or nil
end

local function findSkycastDestination(centerPos, waterLevel)
    local half = SKYCAST_GRID_SIZE * 0.5
    local step = SKYCAST_DENSITY > 1 and (SKYCAST_GRID_SIZE / (SKYCAST_DENSITY - 1)) or 0
    local lowestDryHit
    local lowestAnyHit

    for ix = 0, SKYCAST_DENSITY - 1 do
        for iy = 0, SKYCAST_DENSITY - 1 do
            local x = centerPos.x - half + (ix * step)
            local y = centerPos.y - half + (iy * step)
            local hitPos = castSkyRay(x, y, centerPos.z)
            if hitPos then
                if not lowestAnyHit or hitPos.z < lowestAnyHit.z then
                    lowestAnyHit = hitPos
                end

                local isAboveWater = (not waterLevel) or (hitPos.z >= waterLevel)
                if isAboveWater and (not lowestDryHit or hitPos.z < lowestDryHit.z) then
                    lowestDryHit = hitPos
                end
            end
        end
    end

    return lowestDryHit or lowestAnyHit
end

return {
    onMagnitudeChange = function()
        self.type.activeEffects(self):remove('nsp_wildintervention')
    end,
    onTeleport = function()
        if not debug.isGodMode() then
            self.type.stats.dynamic.fatigue(self).current = math.random(-15, 5)
        end
        if not self.cell.isExterior then return end

        local waterLevel = self.cell and self.cell.waterLevel or nil
        local destination = findSkycastDestination(self.position, waterLevel)
        if destination ~= nil then
            if math.random() < 0.05 then
                destination = destination + util.vector3(0, 0, 250 + math.random() * 750)
            end

            core.sendGlobalEvent('NSP_Teleport', {
                target = self,
                position = destination,
            })
        end
    end
}