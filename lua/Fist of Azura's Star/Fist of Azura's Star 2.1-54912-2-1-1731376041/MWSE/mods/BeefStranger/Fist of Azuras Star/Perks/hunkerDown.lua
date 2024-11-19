local bs = require("BeefStranger.Fist of Azuras Star.common")

---@class bsAzuraHunker
local hunker = {}

function hunker.attackSpeed(h2hMod)
    if bs.combatSneak() then
        return h2hMod * bs.HUNKER.ATTACK_SPEED_MULT
    else
        return h2hMod
    end
end

---@return integer 0
function hunker.moveSpeed(speed)
    if bs.combatSneak() then
        return 0
    else
        return speed
    end
end

--- @param e calcHitChanceEventData
function hunker.hitChance(e)
    if bs.combatSneak() then
        return e.hitChance * bs.HUNKER.ENEMY_HITCHANCE_MULT
    else
        return e.hitChance
    end
end

function hunker.onDmg(dmg)
    if bs.combatSneak() then
        return dmg * bs.HUNKER.DMG_DEAL_MULT
    else
        return dmg
    end
end

function hunker.playerDmg(e, dmg)
    if bs.combatSneak() then
        if e.fatigueDamage then return dmg * bs.HUNKER.DMG_TAKE_FATIGUE_MULT end
        if e.damage then return dmg * bs.HUNKER.DMG_TAKE_MULT end
    else
        return dmg
    end
end
--- @param e damagedHandToHandEventData|damagedEventData
function hunker.postPlayerDamage(e)
    if bs.combatSneak() and bs.roll() <= bs.HUNKER.BLOCK_STUN_CHANCE then
        bs.blockStun(e)
    end
end

--- @param e damagedHandToHandEventData|damagedEventData
function hunker.postPlayerAttack(e)
    if bs.combatSneak() and bs.roll() <= bs.HUNKER.BLOCK_STUN_ENEMY_CHANCE then
        bs.blockStun(e)
    end
end

return hunker
