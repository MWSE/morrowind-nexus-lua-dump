local types = require("openmw.types")

return {
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
    BLUNT_TYPES = {
        [types.Weapon.TYPE.BluntOneHand]  = true,
        [types.Weapon.TYPE.BluntTwoClose] = true,
        [types.Weapon.TYPE.BluntTwoWide]  = true,
    },
}