local bs = require("BeefStranger.Fist of Azuras Star.common")

local deflect = {}

---Simplified Vanilla Block Chance Calcs
---@param e damageEventData|damageHandToHandEventData
local function blockChance(e)
    local iBlockMinChance = bs.GMST(tes3.gmst.iBlockMinChance)
    local iBlockMaxChance = bs.GMST(tes3.gmst.iBlockMaxChance)
    local pc = e.mobile
    local blockTerm = pc.block.current + 0.2 * pc.agility.current + 0.1 * pc.luck.current
    local playerTerm = math.floor(blockTerm * pc:getFatigueTerm())
    playerTerm = playerTerm * bs.DEFLECT.BLOCK_MULT
    local npc = e.attacker
    local npcSkill

    if npc.actorType == tes3.actorType.creature then
        npcSkill = npc.combat.current
    else
        npcSkill = (npc.readiedWeapon and npc:getSkillStatistic(npc.readiedWeapon.object.skillId).current) or
        npc.handToHand.current
    end

    local npcTerm = npcSkill + 0.2 * npc.agility.current + 0.1 * npc.luck.current
    npcTerm = npcTerm * npc:getFatigueTerm()

    local x = math.floor(playerTerm - npcTerm)
    x = math.clamp(x, iBlockMinChance, iBlockMaxChance)
    -- debug.log(x)

    return x
end


function deflect.playerDmg(e, dmg)
    if bs.roll() <= blockChance(e) then
        tes3.playSound{sound = "Body Fall Medium"}
        tes3.mobilePlayer.actionData.blockingState = 2
        tes3.modStatistic({reference = e.attacker, current = -(dmg * bs.DEFLECT.DMG_REFLECT_FATIGUE_MULT), name = "fatigue"})
        e.attacker:applyDamage{applyArmor = true, damage = dmg * bs.DEFLECT.DMG_REFLECT_MULT, playerAttack = true}
        e.attacker:hitStun({knockDown = true})
        tes3.mobilePlayer:exerciseSkill(tes3.skill.block, dmg * bs.DEFLECT.BLOCK_XP_MULT)
        -- debug.log(dmg)
        return 0
    else
        tes3.mobilePlayer:exerciseSkill(tes3.skill.block, dmg * bs.DEFLECT.BLOCK_FAIL_XP_MULT)
        return dmg
    end
end

---@param speed number Current speed
---@return number speed
function deflect.moveSpeed(speed)
    return speed * bs.DEFLECT.MOVE_MULT
end

return deflect