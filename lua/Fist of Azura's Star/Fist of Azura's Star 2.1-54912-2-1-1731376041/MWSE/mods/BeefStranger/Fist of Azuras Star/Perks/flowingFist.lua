local bs = require("BeefStranger.Fist of Azuras Star.common")

local flowing = {}

---@param h2hMod number current h2hMod
---@return number h2hMod
function flowing.attackSpeed(h2hMod)
    return h2hMod * bs.FLOWING.ATTACK_SPEED_MULT
end

---@param h2hBoost number current h2hBoost
---@return number h2hBoost
function flowing.attackSwing(h2hBoost)
    return h2hBoost + bs.FLOWING.SWING_BONUS
end

---@param speed number current speed
---@return number speed
function flowing.moveSpeed(speed)
    return speed * bs.FLOWING.MOVE_MULT
end

---MAKE DRAIN AMOUNT A CONSTANT
function flowing.fatigueDrain()
    tes3.modStatistic { reference = tes3.mobilePlayer, current = -0.5, limitToBase = true, name = "fatigue" }
end

---Modify Attack Reach
--- @param e calcHitDetectionConeEventData
function flowing.reach(e)
    return e.reach * bs.FLOWING.REACH_MULT
end

---@param dmg number
---@return number dmg
function flowing.playerDmg(dmg)
    return dmg * bs.FLOWING.DMG_TAKE_MULT
end
--- @param e damagedHandToHandEventData|damagedEventData
function flowing.postPlayerAttack(e)
    if bs.roll() <= bs.FLOWING.BLOCK_STUN_ENEMY_CHANCE then
        bs.blockStun(e)
    end
end


return flowing
