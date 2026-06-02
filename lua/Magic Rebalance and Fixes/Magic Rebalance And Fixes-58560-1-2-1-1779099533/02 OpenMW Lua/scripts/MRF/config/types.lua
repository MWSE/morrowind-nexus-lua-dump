local core = require('openmw.core')

local module = {}

local Effects = core.magic.EFFECT_TYPE

module.resistedEffects = {
    [Effects.AbsorbFatigue] = Effects.ResistMagicka,
    [Effects.AbsorbHealth] = Effects.ResistMagicka,
    [Effects.AbsorbMagicka] = Effects.ResistMagicka,
    [Effects.AbsorbAttribute] = Effects.ResistMagicka,
    [Effects.AbsorbSkill] = Effects.ResistMagicka,
    [Effects.DamageFatigue] = Effects.ResistMagicka,
    [Effects.DamageHealth] = Effects.ResistMagicka,
    [Effects.DamageMagicka] = Effects.ResistMagicka,
    [Effects.DamageAttribute] = Effects.ResistMagicka,
    [Effects.DamageSkill] = Effects.ResistMagicka,
    [Effects.DrainFatigue] = Effects.ResistMagicka,
    [Effects.DrainHealth] = Effects.ResistMagicka,
    [Effects.DrainMagicka] = Effects.ResistMagicka,
    [Effects.DrainAttribute] = Effects.ResistMagicka,
    [Effects.DrainSkill] = Effects.ResistMagicka,
    [Effects.Blind] = Effects.ResistMagicka,
    [Effects.Burden] = Effects.ResistMagicka,
    [Effects.Sound] = Effects.ResistMagicka,
    [Effects.Silence] = Effects.ResistMagicka,
    [Effects.WeaknessToBlightDisease] = Effects.ResistMagicka,
    [Effects.WeaknessToCommonDisease] = Effects.ResistMagicka,
    [Effects.WeaknessToCorprusDisease] = Effects.ResistMagicka,
    [Effects.WeaknessToMagicka] = Effects.ResistMagicka,
    [Effects.WeaknessToNormalWeapons] = Effects.ResistMagicka,
    [Effects.WeaknessToFire] = Effects.ResistFire,
    [Effects.WeaknessToFrost] = Effects.ResistFrost,
    [Effects.WeaknessToShock] = Effects.ResistShock,
    [Effects.WeaknessToPoison] = Effects.ResistPoison,
}

return module