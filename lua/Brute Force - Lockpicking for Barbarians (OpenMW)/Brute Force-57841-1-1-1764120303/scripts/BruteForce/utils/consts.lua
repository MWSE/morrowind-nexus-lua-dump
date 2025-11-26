local types = require("openmw.types")
local I = require("openmw.interfaces")

Dependencies = {
    ["Impact Effects.omwscripts"] = I.impactEffects == nil,
}

JammedLocks = {}

local wTypes = types.Weapon.TYPE
local pSkills = types.Player.stats.skills
WeaponTypeToSkill = {
    [wTypes.AxeOneHand] = pSkills.axe,
    [wTypes.AxeTwoHand] = pSkills.axe,
    [wTypes.BluntOneHand] = pSkills.blunt,
    [wTypes.BluntTwoClose] = pSkills.blunt,
    [wTypes.BluntTwoWide] = pSkills.blunt,
    [wTypes.LongBladeOneHand] = pSkills.longblade,
    [wTypes.LongBladeTwoHand] = pSkills.longblade,
    [wTypes.ShortBladeOneHand] = pSkills.shortblade,
    [wTypes.SpearTwoWide] = pSkills.spear,
}
WeaponTypeToSkillId = {
    [wTypes.AxeOneHand] = "axe",
    [wTypes.AxeTwoHand] = "axe",
    [wTypes.BluntOneHand] = "blunt",
    [wTypes.BluntTwoClose] = "blunt",
    [wTypes.BluntTwoWide] = "blunt",
    [wTypes.LongBladeOneHand] = "longblade",
    [wTypes.LongBladeTwoHand] = "longblade",
    [wTypes.ShortBladeOneHand] = "shortblade",
    [wTypes.SpearTwoWide] = "spear",
}

DamageableItemTypes = {
    [types.Weapon] = true,
    [types.Armor] = true,
}
NonDamageableWeaponTypes = {
    [wTypes.Arrow] = true,
    [wTypes.Bolt] = true,
    [wTypes.MarksmanThrown] = true,
}
