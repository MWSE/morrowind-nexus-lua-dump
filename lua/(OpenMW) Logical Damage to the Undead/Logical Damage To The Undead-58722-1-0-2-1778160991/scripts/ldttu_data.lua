local types = require("openmw.types")

return {
    WEAPON_MAP = {
        [types.Weapon.TYPE.ShortBladeOneHand] = "blade",
        [types.Weapon.TYPE.LongBladeOneHand]  = "blade",
        [types.Weapon.TYPE.LongBladeTwoHand]  = "blade",
        
        [types.Weapon.TYPE.BluntOneHand]      = "blunt",
        [types.Weapon.TYPE.BluntTwoClose]     = "blunt",
        [types.Weapon.TYPE.BluntTwoWide]      = "blunt",
        [types.Weapon.TYPE.AxeOneHand]        = "axe",
        [types.Weapon.TYPE.AxeTwoHand]        = "axe",
        
        [types.Weapon.TYPE.SpearTwoWide]      = "spear",
        
        [types.Weapon.TYPE.MarksmanBow]       = "marksman",
        [types.Weapon.TYPE.MarksmanCrossbow]  = "marksman",
        [types.Weapon.TYPE.MarksmanThrown]    = "marksman",
        [types.Weapon.TYPE.Arrow]             = "marksman",
        [types.Weapon.TYPE.Bolt]              = "marksman",
    }
}