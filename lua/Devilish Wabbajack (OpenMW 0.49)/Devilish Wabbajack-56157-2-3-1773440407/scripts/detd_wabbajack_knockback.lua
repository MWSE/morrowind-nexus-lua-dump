-- detd_wabbajack_knockback.lua
-- Path: scripts/detd_wabbajack_knockback.lua

local core = require('openmw.core')
local util = require('openmw.util')
local self = require('openmw.self')
local I = require('openmw.interfaces')
local nearby = require('openmw.nearby')
local types = require('openmw.types')
local anim = require('openmw.animation')

local M = {}

local tx = 0
local ty = 0
local tz = 0

local isKnockedBack = false
local isWaiting = false
local totalBounces = 0

local lastHitYaw = nil
local lastHitPitch = nil
local lastHitValid = false

-- airborne tracking
local launchStartZ = nil
local highestZ = nil
local airborneThreshold = 80

local FRICTION = 0.5
local GRAVITY = 2
local MAX_GRAVITY = 120

local collTypes = util.bitOr(
    nearby.COLLISION_TYPE.World,
    nearby.COLLISION_TYPE.HeightMap,
    nearby.COLLISION_TYPE.Door
)

---@param v [number, number, number]
---@param normal Vector3
---@param bounceAmount number
local function bounceVector(v, normal, bounceAmount)
    local dot = v[1] * normal.x + v[2] * normal.y + v[3] * normal.z

    return
        v[1] - (1 + bounceAmount) * dot * normal.x,
        v[2] - (1 + bounceAmount) * dot * normal.y,
        v[3] - (1 + bounceAmount) * dot * normal.z
end

local function isInterior()
    return self.cell and not self.cell.isExterior
end

---------------------------------------------------
-- animation safety (fix rare attack type crash)
---------------------------------------------------

local function cancelCombatAnimations()
    local torso = anim.getActiveGroup(self, anim.BONE_GROUP.Torso)
    local left = anim.getActiveGroup(self, anim.BONE_GROUP.LeftArm)
    local right = anim.getActiveGroup(self, anim.BONE_GROUP.RightArm)

    if torso then anim.cancel(self, torso) end
    if left then anim.cancel(self, left) end
    if right then anim.cancel(self, right) end
end

---------------------------------------------------
-- landing detection
---------------------------------------------------

local function finishKnockback()
    local rise = 0

    if launchStartZ and highestZ then
        rise = highestZ - launchStartZ
    end

    isKnockedBack = false
    isWaiting = false
    totalBounces = 0

    tx = 0
    ty = 0
    tz = 0

    launchStartZ = nil
    highestZ = nil

    if rise >= airborneThreshold then
        self:sendEvent("detd_KnockbackLanded", { riseAmount = rise })
    end
end

---------------------------------------------------
-- main init
---------------------------------------------------

function M.init(config)
    config = config or {}

    local magnitude = config.magnitude or 30
    local verticalFactor = config.verticalFactor or 0.20
    local bounceAmount = config.bounceAmount or 0.25
    local maxBounces = config.maxBounces
    local adjustByAttackPower = config.adjustByAttackPower

    local outdoorRadius = config.radius or config.outdoorRadius or 45
    local indoorRadius = config.indoorRadius or 14

    local outdoorRayMultiplier = config.outdoorRayMultiplier or 3.0
    local indoorRayMultiplier = config.indoorRayMultiplier or 1.15

    local indoorMagnitudeMultiplier = config.indoorMagnitudeMultiplier or 0.35
    local indoorVerticalMultiplier = config.indoorVerticalMultiplier or 0.35

    airborneThreshold = config.airborneThreshold or 80

    if maxBounces == nil then
        maxBounces = 2
    end

    if adjustByAttackPower == nil then
        adjustByAttackPower = true
    end

    local function getEffectiveRadius()
        if isInterior() then
            return indoorRadius
        end
        return outdoorRadius
    end

    local function getEffectiveRayMultiplier()
        if isInterior() then
            return indoorRayMultiplier
        end
        return outdoorRayMultiplier
    end

---------------------------------------------------
-- remember hit direction
---------------------------------------------------

    local function rememberPlayerHitDirection(attackInfo)
        if not attackInfo or not attackInfo.successful then
            return
        end

        if types.Actor.stats.dynamic.health(self).current <= 0 then
            return
        end

        if not attackInfo.attacker or not types.Player.objectIsInstance(attackInfo.attacker) then
            return
        end

        if not self.cell then
            return
        end

        if not types.Actor.activeSpells(self):isSpellActive('detd_wabbajack_staff') then
            return
        end

        lastHitYaw = attackInfo.attacker.rotation:getYaw()
        lastHitPitch = attackInfo.attacker.rotation:getPitch()
        lastHitValid = true
    end

    I.Combat.addOnHitHandler(rememberPlayerHitDirection)

---------------------------------------------------
-- start knockback
---------------------------------------------------

    local function startKnockback()
        if not self.cell then
            return false
        end

        if not lastHitValid or not lastHitYaw then
            return false
        end

        cancelCombatAnimations()

        local angle = lastHitYaw
        local pitch = lastHitPitch or 0

        local finalMagnitude = magnitude
        local finalVerticalFactor = verticalFactor

        if adjustByAttackPower then
            finalMagnitude = finalMagnitude * 1
        end

        if isInterior() then
            finalMagnitude = finalMagnitude * indoorMagnitudeMultiplier
            finalVerticalFactor = finalVerticalFactor * indoorVerticalMultiplier
        end

        tx = math.cos(angle) * math.cos(pitch) * finalMagnitude
        ty = math.sin(angle) * math.cos(pitch) * finalMagnitude
        tz = math.sin(-pitch) * finalVerticalFactor * finalMagnitude

        if tz < 0 then
            tz = -tz
        end

        isKnockedBack = true
        isWaiting = false
        totalBounces = 0
        lastHitValid = false

        launchStartZ = self.position.z
        highestZ = self.position.z

        return true
    end

---------------------------------------------------
-- update loop
---------------------------------------------------

    return {
        start = startKnockback,

        engineHandlers = {
            onUpdate = function()
                if core.isWorldPaused() then
                    return
                end

                if not isKnockedBack then
                    return
                end

                if isWaiting then
                    return
                end

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

                tz = tz - GRAVITY

                if tz < -MAX_GRAVITY then
                    tz = -MAX_GRAVITY
                end

                local currentRadius = getEffectiveRadius()
                local rayMultiplier = getEffectiveRayMultiplier()

                local box = self:getBoundingBox()

                if util.vector3(ty, tx, tz):length() < 5 then
                    local down = box.center + util.vector3(0, 0, -500)

                    local downRay = nearby.castRay(
                        box.center,
                        down,
                        { collisionType = collTypes, radius = currentRadius }
                    )

                    if downRay.hit then
                        local toGround = math.abs(downRay.hitPos.z - self.position.z)

                        if toGround < currentRadius * 2 then
                            finishKnockback()
                            return
                        end
                    end
                end

                local rayStart = box.center
                local rayEnd = rayStart + util.vector3(ty, tx, tz) * rayMultiplier

                local res = nearby.castRay(
                    rayStart,
                    rayEnd,
                    { collisionType = collTypes, radius = currentRadius }
                )

                if res.hit and res.hitNormal then
                    totalBounces = totalBounces + 1

                    ty, tx, tz = bounceVector({ ty, tx, tz }, res.hitNormal, bounceAmount)

                    if isInterior() then
                        tx = tx * 0.55
                        ty = ty * 0.55
                        tz = math.max(0, tz * 0.35)
                    end

                    if totalBounces > maxBounces then
                        finishKnockback()
                        return
                    end
                end

                local nextPos = self.position + util.vector3(ty, tx, tz)

                if nextPos.z > highestZ then
                    highestZ = nextPos.z
                end

     core.sendGlobalEvent(
    'detd_EnemyKnockback',
    {
        actor = self,
        nextPos = nextPos,
        rotation = self.rotation,
        ground = false,
    }
)

                isWaiting = true
            end,
        },

        eventHandlers = {
            detd_TELE_DONE = function()
                isWaiting = false
            end,
        },
    }
end

return M
