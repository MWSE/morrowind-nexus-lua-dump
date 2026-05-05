local types = require("openmw.types")
local dataa = require("scripts.wdisarm_data")
local WEAPON_SKILL = dataa.WEAPON_SKILL

local function getSkill(actor, skillId)
    return types.NPC.stats.skills[skillId](actor).modified
end

local function conditionRatio(weapon)
    local rec = types.Weapon.record(weapon)
    if not rec.health or rec.health <= 0 then return 1 end
    local data = types.Item.itemData(weapon)
    local cond = (data and data.condition) or rec.health
    return cond / rec.health
end

local function bestAvgDamage(rec)
    local chop  = (rec.chopMinDamage  + rec.chopMaxDamage)  / 2
    local slash = (rec.slashMinDamage + rec.slashMaxDamage) / 2
    local thrust = (rec.thrustMinDamage + rec.thrustMaxDamage) / 2
    return math.max(chop, slash, thrust)
end

local function effectiveDamage(weapon)
    local base = bestAvgDamage(types.Weapon.record(weapon))
    local ratio = conditionRatio(weapon)
    return base * ratio
end

local M = {}

function M.shouldPickup(npc, dropped, pickupChance, damageThreshold, skillThreshold)
    if not types.NPC.objectIsInstance(npc) then return false end

    -- dropped weapon
    local droppedRec = types.Weapon.record(dropped)
    local droppedSkillId = WEAPON_SKILL[droppedRec.type]
    if not droppedSkillId then return false end
    local droppedData = types.Item.itemData(dropped)
    local droppedCond = (droppedData and droppedData.condition) or droppedRec.health
    local droppedMax  = droppedRec.health or 0
    local droppedBase = bestAvgDamage(droppedRec)
    local droppedEff  = effectiveDamage(dropped)
    -- print(string.format("[Disarm em All] dropped '%s': base=%.1f  cond=%d/%d  eff=%.2f", droppedRec.id, droppedBase, droppedCond, droppedMax, droppedEff))

    local eqTable = types.Actor.getEquipment(npc)
    local currentWeapon = eqTable and eqTable[types.Actor.EQUIPMENT_SLOT.CarriedRight]

    if not currentWeapon or not currentWeapon:isValid() or not types.Weapon.objectIsInstance(currentWeapon) then
        return math.random() <= pickupChance
    end

    -- current weapon
    local currentRec  = types.Weapon.record(currentWeapon)
    local currentSkillId = WEAPON_SKILL[currentRec.type]
    local currentData = types.Item.itemData(currentWeapon)
    local currentCond = (currentData and currentData.condition) or currentRec.health
    local currentMax  = currentRec.health or 0
    local currentBase = bestAvgDamage(currentRec)
    local currentEff  = effectiveDamage(currentWeapon)
    -- print(string.format("[Disarm em All] current '%s': base=%.1f  cond=%d/%d  eff=%.2f", currentRec.id, currentBase, currentCond, currentMax, currentEff))

     -- check if a new weapon is better
    if droppedEff - currentEff < damageThreshold then return false end

    -- check if an npc's skill isn't much worse
    local droppedSkill = getSkill(npc, droppedSkillId)
    local currentSkill = currentSkillId and getSkill(npc, currentSkillId) or 0
    if currentSkill - droppedSkill > skillThreshold then return false end

    return true
end

return M