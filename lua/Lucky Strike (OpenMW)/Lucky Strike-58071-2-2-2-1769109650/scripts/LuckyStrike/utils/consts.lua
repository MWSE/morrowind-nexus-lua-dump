local types = require("openmw.types")

WeaponTypes = {
    unarmed                               = function(npc) return npc.type.stats.skills.handtohand(npc) end,
    [types.Weapon.TYPE.Arrow]             = function(npc) return npc.type.stats.skills.marksman(npc) end,
    [types.Weapon.TYPE.AxeOneHand]        = function(npc) return npc.type.stats.skills.axe(npc) end,
    [types.Weapon.TYPE.AxeTwoHand]        = function(npc) return npc.type.stats.skills.axe(npc) end,
    [types.Weapon.TYPE.BluntOneHand]      = function(npc) return npc.type.stats.skills.bluntweapon(npc) end,
    [types.Weapon.TYPE.BluntTwoClose]     = function(npc) return npc.type.stats.skills.bluntweapon(npc) end,
    [types.Weapon.TYPE.BluntTwoWide]      = function(npc) return npc.type.stats.skills.bluntweapon(npc) end,
    [types.Weapon.TYPE.Bolt]              = function(npc) return npc.type.stats.skills.marksman(npc) end,
    [types.Weapon.TYPE.LongBladeOneHand]  = function(npc) return npc.type.stats.skills.longblade(npc) end,
    [types.Weapon.TYPE.LongBladeTwoHand]  = function(npc) return npc.type.stats.skills.longblade(npc) end,
    [types.Weapon.TYPE.MarksmanBow]       = function(npc) return npc.type.stats.skills.marksman(npc) end,
    [types.Weapon.TYPE.MarksmanCrossbow]  = function(npc) return npc.type.stats.skills.marksman(npc) end,
    [types.Weapon.TYPE.MarksmanThrown]    = function(npc) return npc.type.stats.skills.marksman(npc) end,
    [types.Weapon.TYPE.ShortBladeOneHand] = function(npc) return npc.type.stats.skills.shortblade(npc) end,
    [types.Weapon.TYPE.SpearTwoWide]      = function(npc) return npc.type.stats.skills.spear(npc) end,
}
