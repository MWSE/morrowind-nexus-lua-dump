local types = require('openmw.types')
local core = require('openmw.core')
local util = require('openmw.util')
local self = require('openmw.self')
local I = require('openmw.interfaces')
local nearby = require('openmw.nearby')
local o = require('scripts.knockback.settingsObject').o

local storage = require('openmw.storage')
local globalSection = storage.globalSection('KNOCKBACK_GLOBAL_SETTINGS')
local trans = util.transform


---@param v [number, number, number]
---@param normal Vector3
---@param bias number -- 0 = bounce, 1 = to normal
---@return number
---@return number
---@return number
local function bounceVector_REDUCED(v, normal, bias)
        local bounce = globalSection:get(o.bounceAmount.key) + 0.5
        -- local bounce = 1
        local dot_product = v[1] * normal.x + v[2] * normal.y + v[3] * normal.z
        -- bounce
        local bounce_x = v[1] - (1 + bounce) * dot_product * normal.x
        local bounce_y = v[2] - (1 + bounce) * dot_product * normal.y
        local bounce_z = v[3] - (1 + bounce) * dot_product * normal.z
        -- based to normal
        return
            bounce_x * (1 - bias) + normal.x * bias,
            bounce_y * (1 - bias) + normal.y * bias,
            bounce_z * (1 - bias) + normal.z * bias
end

---@param v [number, number, number]
---@param normal Vector3
---@return number
---@return number
---@return number
local function bounceVector(v, normal)
        local bounce = globalSection:get(o.bounceAmount.key)
        local dot_product = v[1] * normal.x + v[2] * normal.y + v[3] * normal.z
        return
            v[1] - (1 + bounce) * dot_product * normal.x,
            v[2] - (1 + bounce) * dot_product * normal.y,
            v[3] - (1 + bounce) * dot_product * normal.z
end

local tx
local ty
local tz
local rotv

local isKnockedBack = false
local isWaiting = false
local nearbyActors
local box

local totalBounces

local FRICTION = 0.5
local GRAVITY = 2
-- local GRAVITY = 1.8
-- local GRAVITY = 2.8
-- local MAX_GRAVITY = 35
local MAX_GRAVITY = 120


-- local MAX_VEL = 25

local radius

local collTypes = util.bitOr(
        nearby.COLLISION_TYPE.World,
        nearby.COLLISION_TYPE.HeightMap,
        nearby.COLLISION_TYPE.Door
-- nearby.COLLISION_TYPE.Camera,
-- nearby.COLLISION_TYPE.Projectile,
-- nearby.COLLISION_TYPE.VisualOnly
)

local originalPosition
---@param attackInfo AttackInfo
local function handler(attackInfo)
        if not attackInfo.successful then return end
        if types.Actor.stats.dynamic.health(self).current <= 0 then return end
        if not attackInfo.attacker or not types.Player.objectIsInstance(attackInfo.attacker) then return end

        -- attacker = attackInfo.attacker
        -- originalPosition = self.position
        -- print('')
        -- print('')
        -- print('KNOCKBACK STARTED')


        local attacker = attackInfo.attacker
        local angle = attacker.rotation:getYaw()
        local pitch = attacker.rotation:getPitch()

        local magnitude

        if globalSection:get(o.adjustByAttackPower.key) then
                magnitude = attackInfo.strength * globalSection:get(o.knockbackMagnitude.key)
        else
                magnitude = globalSection:get(o.knockbackMagnitude.key)
        end

        tx = math.cos(angle) * math.cos(pitch) * magnitude
        ty = math.sin(angle) * math.cos(pitch) * magnitude
        tz = math.sin(-pitch) * globalSection:get(o.verticalKnockFactor.key) * magnitude

        if math.random() > 0.5 then
                rotv = 0.4 + math.random() * 0.3
        else
                rotv = -0.4 - math.random() * 0.3
        end

        nearbyActors = {}
        for _, v in pairs(nearby.actors) do
                if v ~= self then
                        table.insert(nearbyActors, v)
                end
        end

        if tz < 0 then
                tz = -1 * tz
        end

        isKnockedBack = true
        isWaiting = false
        totalBounces = 0


        -- radius = math.min(self:getBoundingBox().halfSize.z, self:getBoundingBox().halfSize.x)
        -- radius = math.max(self:getBoundingBox().halfSize.z, 50)
        -- radius = math.max(self:getBoundingBox().halfSize.z, 60)
        radius = 45
        -- print('radius = ', radius)
end

I.Combat.addOnHitHandler(handler)

return {
        engineHandlers = {
                onUpdate = function(dt)
                        if core.isWorldPaused() then return end
                        if not isKnockedBack then return end
                        if isWaiting then return end

                        if tx > 0 then
                                tx = math.max(0, tx - FRICTION)
                        elseif tx < 0 then
                                tx = math.min(0, tx + FRICTION)
                        end

                        if ty > 0 then
                                ty = math.max(0, ty - FRICTION)
                        elseif ty < 0 then
                                ty = math.min(0, ty + FRICTION)
                        end

                        if rotv > 0 then
                                rotv = math.max(0, rotv - 0.01)
                        elseif rotv < 0 then
                                rotv = math.min(0, rotv + 0.01)
                        end

                        tz = tz - GRAVITY
                        if tz < -MAX_GRAVITY then
                                tz = -MAX_GRAVITY
                        end

                        box = self:getBoundingBox()

                        if util.vector3(ty, tx, tz):length() < 5 then
                                local down = box.center + util.vector3(0, 0, -500)
                                ---@type RayCastingResult
                                local downRay = nearby.castRay(box.center + util.vector3(0, 0, 0), down,
                                        {
                                                collisionType = collTypes,
                                                -- radius = box.halfSize.z / 2
                                                radius = radius
                                        })

                                if downRay.hit then
                                        local toGround = math.abs(downRay.hitPos.z - self.position.z)
                                        -- print(self.recordId, ' toGround = ', toGround)
                                        if toGround < radius * 2 then
                                                -- print('KNOCK BACK ENDED FOR ', self.recordId)
                                                isKnockedBack = false
                                                return
                                        end
                                end
                        end



                        -- local rayStart = self.position + util.vector3(0, 0, box.halfSize.z)
                        -- local rayStart = self.position + util.vector3(0, 0, radius)
                        -- local rayStart = box.center + util.vector3(0, 0, radius / 2)
                        local rayStart = box.center
                        -- local rayEnd = rayStart + util.vector3(ty, tx, tz) * 2
                        local rayEnd = rayStart + util.vector3(ty, tx, tz) * 3

                        ---@type RayCastingResult
                        local res = nearby.castRay(rayStart, rayEnd,
                                {
                                        collisionType = collTypes,
                                        -- radius = box.halfSize.z / 2
                                        radius = radius
                                })


                        if res.hit and res.hitNormal then
                                -- print(self.recordId, ' BOUNCED!!!')
                                -- print('position = ', self.position)
                                totalBounces = totalBounces + 1
                                ty, tx, tz = bounceVector({ ty, tx, tz }, res.hitNormal)
                                -- ty, tx, tz = bounceVector_REDUCED({ ty, tx, tz }, res.hitNormal, 0.85)
                                -- print(self.recordId, 'totalBounces:', totalBounces)
                                if totalBounces >= globalSection:get(o.maxBounces.key) then
                                        -- core.sendGlobalEvent('ENEMY_KNOCKBACK', {
                                        --         actor = self,
                                        --         nextPos = originalPosition,
                                        --         ground = true,
                                        -- })
                                        isKnockedBack = false
                                        return
                                end
                        end

                        local startPos = self.position
                        local nextPos
                        nextPos = startPos + util.vector3(ty, tx, tz) / 1

                        local newRot = trans.rotateZ(self.rotation:getYaw() + rotv)

                        core.sendGlobalEvent('ENEMY_KNOCKBACK', {
                                actor = self,
                                nextPos = nextPos,
                                rotation = newRot,
                        })

                        isWaiting = true
                end
        },
        eventHandlers = {
                TELE_DONE = function()
                        isWaiting = false
                end
        },
}
