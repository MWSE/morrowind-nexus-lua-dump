local core = require("openmw.core")
local types = require("openmw.types")

-- Originally taken from Hit Chance UI by Safebox (https://www.nexusmods.com/morrowind/mods/53930)
local weaponTypeToWeaponSkillMap = {
    [types.Weapon.TYPE.AxeOneHand] = "axe",
    [types.Weapon.TYPE.AxeTwoHand] = "axe",
    [types.Weapon.TYPE.BluntOneHand] = "bluntweapon",
    [types.Weapon.TYPE.BluntTwoClose] = "bluntweapon",
    [types.Weapon.TYPE.BluntTwoWide] = "bluntweapon",
    [types.Weapon.TYPE.LongBladeOneHand] = "longblade",
    [types.Weapon.TYPE.LongBladeTwoHand] = "longblade",
    [types.Weapon.TYPE.MarksmanBow] = "marksman",
    [types.Weapon.TYPE.MarksmanCrossbow] = "marksman",
    [types.Weapon.TYPE.MarksmanThrown] = "marksman",
    [types.Weapon.TYPE.ShortBladeOneHand] = "shortblade",
    [types.Weapon.TYPE.SpearTwoWide] = "spear",
}

local function calculateAttackerHitChance(source, weapon)
    local weaponSkillKey = weapon and weaponTypeToWeaponSkillMap[types.Weapon.record(weapon).type] or "handtohand"
    local weaponSkill = types.NPC.stats.skills[weaponSkillKey](source).modified
    local agility = types.Actor.stats.attributes.agility(source).modified
    local luck = types.Actor.stats.attributes.luck(source).modified
    local fatigueCurrent = types.Actor.stats.dynamic.fatigue(source).current
    local fatigueBase = types.Actor.stats.dynamic.fatigue(source).base
    local fortifyAttack = types.Actor.activeEffects(source):getEffect(core.magic.EFFECT_TYPE.FortifyAttack)
    local blind = types.Actor.activeEffects(source):getEffect(core.magic.EFFECT_TYPE.Blind)
    return (weaponSkill + (agility / 5) + (luck / 10)) * (0.75 + (0.5 * (fatigueCurrent / fatigueBase)))
        + (fortifyAttack and fortifyAttack.magnitude or 0)
        + (blind and blind.magnitude or 0)
end

local function calculateTargetEvasionChance(target)
    local agility = types.Actor.stats.attributes.agility(target).modified
    local luck = types.Actor.stats.attributes.luck(target).modified
    local fatigueCurrent = types.Actor.stats.dynamic.fatigue(target).current
    local fatigueBase = types.Actor.stats.dynamic.fatigue(target).base
    local sanctuary = types.Actor.activeEffects(target):getEffect(core.magic.EFFECT_TYPE.Sanctuary)
    return ((agility / 5) + (luck / 10)) * (0.75 + (0.5 * (fatigueCurrent / fatigueBase)))
        + (sanctuary and sanctuary.magnitude or 0)
end

local function calculateHitChanceForAttack(attacker, target)
    local carriedWeapon = types.Actor.getEquipment(attacker, types.Actor.EQUIPMENT_SLOT.CarriedRight)
    return math.max(0, calculateAttackerHitChance(attacker, carriedWeapon) - calculateTargetEvasionChance(target))
end
--

return { calculate = calculateHitChanceForAttack }
