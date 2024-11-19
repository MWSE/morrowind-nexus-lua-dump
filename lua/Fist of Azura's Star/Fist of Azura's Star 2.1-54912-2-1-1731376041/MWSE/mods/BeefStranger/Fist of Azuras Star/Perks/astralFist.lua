local bs = require("BeefStranger.Fist of Azuras Star.common")

---@class bs_Azura_Astral
local astral = {}
---@param e damageEventData|damageHandToHandEventData
function astral.onDmg(e)
    local dmg = e.damage or e.fatigueDamage
    local dist = e.mobile.playerDistance / 22.1
    local distMod = 1

    if dist > 15 then
        distMod = math.max(1 - (dist - bs.ASTRAL.DMG_DIST_FULL) * bs.ASTRAL.DMG_REDUCTION_RATE, bs.ASTRAL.DMG_DEAL_MIN_MULT)
        -- tes3.playSound{sound = bs.sound.Hand_to_Hand_Hit_2}
    end

    dmg = e.damage and (dmg * distMod) or (dmg * distMod) * bs.ASTRAL.DMG_DEAL_FATIGUE_MULT
    -- debug.log(dmg)
    return dmg
end

---Modify attackSpeed
---@return number attackSpeed
function astral.attackSpeed(h2hMod)
    return h2hMod * bs.ASTRAL.ATTACKSPEED_MULT
end

-- Function to calculate angle based on distance
local function calcAngle(dist)
    if dist > bs.ASTRAL.ANGLE_DIST_MAX then return bs.ASTRAL.ANGLE_MIN end

    -- Linear interpolation of the angle based on distance ||| CHATGPT Not Me. I cant math
    local angle = bs.ASTRAL.ANGLE_MAX - ((dist / bs.ASTRAL.ANGLE_DIST_MAX) * (bs.ASTRAL.ANGLE_MAX - bs.ASTRAL.ANGLE_MIN))
    return math.max(bs.ASTRAL.ANGLE_MIN, angle)
end

--- @param e calcHitDetectionConeEventData
function astral.reach(e)
    return math.min(e.reach + (bs.h2h:base() / 15) + (bs.will:base() / 25) * bs.ASTRAL.REACH_MULT, bs.ASTRAL.REACH_CAP)
end

--- @param e calcHitDetectionConeEventData
function astral.hitConeAngle(e)
    local xy = 15
    local z = 10

    if tes3.mobilePlayer.actionData.target then
        local dist = tes3.mobilePlayer.actionData.target.playerDistance
        -- debug.log(calcAngle(dist))
        xy = calcAngle(dist) * bs.ASTRAL.ANGLE_XY_MULT
        z = calcAngle(dist) * bs.ASTRAL.ANGLE_Z_MULT
    end
    return xy, z
end

--- @param e damagedEventData
function astral.postDmg(e)
    if bs.roll() < 25 then
        bs.blockStun(e)
    end
end


return astral