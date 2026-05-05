local types = require("openmw.types")

return {
    WEAPON_SKILL = {
        [types.Weapon.TYPE.ShortBladeOneHand] = "shortblade",
        [types.Weapon.TYPE.LongBladeOneHand]  = "longblade",
        [types.Weapon.TYPE.LongBladeTwoHand]  = "longblade",
        [types.Weapon.TYPE.BluntOneHand]      = "bluntweapon",
        [types.Weapon.TYPE.BluntTwoClose]     = "bluntweapon",
        [types.Weapon.TYPE.BluntTwoWide]      = "bluntweapon",
        [types.Weapon.TYPE.AxeOneHand]        = "axe",
        [types.Weapon.TYPE.AxeTwoHand]        = "axe",
        [types.Weapon.TYPE.SpearTwoWide]      = "spear",
    },
    WEAPON_SOUND = {
        [types.Weapon.TYPE.ShortBladeOneHand] = "Item Weapon Shortblade Up",
        [types.Weapon.TYPE.LongBladeOneHand]  = "Item Weapon Longblade Up",
        [types.Weapon.TYPE.LongBladeTwoHand]  = "Item Weapon Longblade Up",
        [types.Weapon.TYPE.BluntOneHand]      = "Item Weapon Blunt Up",
        [types.Weapon.TYPE.BluntTwoClose]     = "Item Weapon Blunt Up",
        [types.Weapon.TYPE.BluntTwoWide]      = "Item Weapon Blunt Up",
        [types.Weapon.TYPE.AxeOneHand]        = "Item Weapon Blunt Up",
        [types.Weapon.TYPE.AxeTwoHand]        = "Item Weapon Blunt Up",
        [types.Weapon.TYPE.SpearTwoWide]      = "Item Weapon Spear Up",
    },
}