local types = require("openmw.types")
local W     = types.Weapon.TYPE

return {
    WEAPON_SKILL = {
        [W.AxeOneHand]        = "axe",
        [W.AxeTwoHand]        = "axe",
        [W.BluntOneHand]      = "bluntweapon",
        [W.BluntTwoClose]     = "bluntweapon",
        [W.BluntTwoWide]      = "bluntweapon",
        [W.LongBladeOneHand]  = "longblade",
        [W.LongBladeTwoHand]  = "longblade",
        [W.ShortBladeOneHand] = "shortblade",
        [W.SpearTwoWide]      = "spear",
        [W.MarksmanBow]       = "marksman",
        [W.MarksmanCrossbow]  = "marksman",
        [W.MarksmanThrown]    = "marksman",
    },

    WEAPON_ATTR = {
        [W.AxeOneHand]        = "strength",
        [W.AxeTwoHand]        = "strength",
        [W.BluntOneHand]      = "strength",
        [W.BluntTwoClose]     = "strength",
        [W.BluntTwoWide]      = "strength",
        [W.LongBladeOneHand]  = "strength",
        [W.LongBladeTwoHand]  = "strength",
        [W.ShortBladeOneHand] = "speed",
        [W.SpearTwoWide]      = "endurance",
        [W.MarksmanBow]       = "agility",
        [W.MarksmanCrossbow]  = "agility",
        [W.MarksmanThrown]    = "agility",
    },

    WEAPON_DAMAGE_FORMULA = {
        [W.AxeOneHand]        = "chop",
        [W.AxeTwoHand]        = "chop",
        [W.BluntOneHand]      = "chop",
        [W.BluntTwoClose]     = "chop",
        [W.BluntTwoWide]      = "slash",
        [W.LongBladeOneHand]  = "max",
        [W.LongBladeTwoHand]  = "max",
        [W.ShortBladeOneHand] = "max",
        [W.SpearTwoWide]      = "thrust",
        [W.MarksmanBow]       = "chop",
        [W.MarksmanCrossbow]  = "chop",
        [W.MarksmanThrown]    = "chop",
    },

    WEAPON_TIER_GROUP = {
        [W.AxeOneHand]        = "axe1h",
        [W.AxeTwoHand]        = "axe2h",
        [W.BluntOneHand]      = "mace",
        [W.BluntTwoClose]     = "hammer",
        [W.BluntTwoWide]      = "staff",
        [W.LongBladeOneHand]  = "blade1h",
        [W.LongBladeTwoHand]  = "blade2h",
        [W.ShortBladeOneHand] = "shortblade",
        [W.SpearTwoWide]      = "spear",
        [W.MarksmanBow]       = "bow",
        [W.MarksmanCrossbow]  = "crossbow",
        [W.MarksmanThrown]    = "thrown",
    },

    IGNORED_TYPES = {
        [W.Bolt]  = true,
        [W.Arrow] = true,
    },
}
