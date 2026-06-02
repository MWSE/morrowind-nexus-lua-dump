-- Spell Effect Description
-- Brief magic effect descriptions loaded by main.lua.
-- Edit description strings here. Leave description empty for unknown/mod-added effects.

local effectDescriptionsById = {
	[0] = {
		name = "Water Breathing",
		school = "Alteration",
		description = "Allows breathing underwater.",
	},

	[1] = {
		name = "Swift Swim",
		school = "Alteration",
		description = "Increases swimming speed.",
	},

	[2] = {
		name = "Water Walking",
		school = "Alteration",
		description = "Allows walking on water.",
	},

	[3] = {
		name = "Shield",
		school = "Alteration",
		description = "Increases Armor Rating with a magical shield.",
	},

	[4] = {
		name = "Fire Shield",
		school = "Alteration",
		description = "Protects against fire and burns nearby attackers.",
	},

	[5] = {
		name = "Lightning Shield",
		school = "Alteration",
		description = "Protects against shock and shocks nearby attackers.",
	},

	[6] = {
		name = "Frost Shield",
		school = "Alteration",
		description = "Protects against frost and freezes nearby attackers.",
	},

	[7] = {
		name = "Burden",
		school = "Alteration",
		description = "Increases the subject's carried weight.",
	},

	[8] = {
		name = "Feather",
		school = "Alteration",
		description = "Reduces the subject's encumbrance.",
	},

	[9] = {
		name = "Jump",
		school = "Alteration",
		description = "Increases jump height and distance.",
	},

	[10] = {
		name = "Levitate",
		school = "Alteration",
		description = "Allows the subject to fly.",
	},

	[11] = {
		name = "SlowFall",
		school = "Alteration",
		description = "Slows falling and reduces fall damage.",
	},

	[12] = {
		name = "Lock",
		school = "Alteration",
		description = "Locks a door or container.",
	},

	[13] = {
		name = "Open",
		school = "Alteration",
		description = "Opens a locked door or container.",
	},

	[14] = {
		name = "Fire Damage",
		school = "Destruction",
		description = "Deals fire damage.",
	},

	[15] = {
		name = "Shock Damage",
		school = "Destruction",
		description = "Deals shock damage.",
	},

	[16] = {
		name = "Frost Damage",
		school = "Destruction",
		description = "Deals frost damage.",
	},

	[17] = {
		name = "Drain Attribute",
		school = "Destruction",
		description = "Temporarily lowers the subject's attribute of this type.",
	},

	[18] = {
		name = "Drain Health",
		school = "Destruction",
		description = "Temporarily lowers the subject's health.",
	},

	[19] = {
		name = "Drain Magicka",
		school = "Destruction",
		description = "Temporarily lowers the subject's magicka.",
	},

	[20] = {
		name = "Drain Fatigue",
		school = "Destruction",
		description = "Temporarily lowers the subject's fatigue.",
	},

	[21] = {
		name = "Drain Skill",
		school = "Destruction",
		description = "Temporarily lowers the subject's skill of this type.",
	},

	[22] = {
		name = "Damage Attribute",
		school = "Destruction",
		description = "Damages the subject's attribute of this type.",
	},

	[23] = {
		name = "Damage Health",
		school = "Destruction",
		description = "Damages the subject's health.",
	},

	[24] = {
		name = "Damage Magicka",
		school = "Destruction",
		description = "Damages the subject's magicka.",
	},

	[25] = {
		name = "Damage Fatigue",
		school = "Destruction",
		description = "Damages the subject's fatigue.",
	},

	[26] = {
		name = "Damage Skill",
		school = "Destruction",
		description = "Damages the subject's skill of this type.",
	},

	[27] = {
		name = "Poison",
		school = "Destruction",
		description = "Poisons the subject, damaging Health over time.",
	},

	[28] = {
		name = "Weakness to Fire",
		school = "Destruction",
		description = "Makes the subject more vulnerable to Fire.",
	},

	[29] = {
		name = "Weakness to Frost",
		school = "Destruction",
		description = "Makes the subject more vulnerable to Frost.",
	},

	[30] = {
		name = "Weakness to Shock",
		school = "Destruction",
		description = "Makes the subject more vulnerable to Shock.",
	},

	[31] = {
		name = "Weakness to Magicka",
		school = "Destruction",
		description = "Makes the subject more vulnerable to Magicka.",
	},

	[32] = {
		name = "Weakness to Common Disease",
		school = "Destruction",
		description = "Makes the subject more vulnerable to Common Disease.",
	},

	[33] = {
		name = "Weakness to Blight Disease",
		school = "Destruction",
		description = "Makes the subject more vulnerable to Blight Disease.",
	},

	[34] = {
		name = "Weakness to Corprus Disease",
		school = "Destruction",
		description = "Makes the subject more vulnerable to Corprus Disease.",
	},

	[35] = {
		name = "Weakness to Poison",
		school = "Destruction",
		description = "Makes the subject more vulnerable to Poison.",
	},

	[36] = {
		name = "Weakness to Normal Weapons",
		school = "Destruction",
		description = "Makes the subject more vulnerable to Normal Weapons.",
	},

	[37] = {
		name = "Disintegrate Weapon",
		school = "Destruction",
		description = "Damages the subject's equipped weapon.",
	},

	[38] = {
		name = "Disintegrate Armor",
		school = "Destruction",
		description = "Damages the subject's equipped armor.",
	},

	[39] = {
		name = "Invisibility",
		school = "Illusion",
		description = "Makes the subject invisible until they attack, cast, speak, or activate something.",
	},

	[40] = {
		name = "Chameleon",
		school = "Illusion",
		description = "Makes the subject harder to see without breaking on action.",
	},

	[41] = {
		name = "Light",
		school = "Illusion",
		description = "Creates light around the target.",
	},

	[42] = {
		name = "Sanctuary",
		school = "Illusion",
		description = "Makes the subject harder to hit.",
	},

	[43] = {
		name = "Night Eye",
		school = "Illusion",
		description = "Improves vision in darkness.",
	},

	[44] = {
		name = "Charm",
		school = "Illusion",
		description = "Temporarily raises the target's disposition.",
	},

	[45] = {
		name = "Paralyze",
		school = "Illusion",
		description = "Prevents the subject from moving.",
	},

	[46] = {
		name = "Silence",
		school = "Illusion",
		description = "Prevents the subject from casting spells.",
	},

	[47] = {
		name = "Blind",
		school = "Illusion",
		description = "Reduces the subject's chance to hit.",
	},

	[48] = {
		name = "Sound",
		school = "Illusion",
		description = "Reduces the subject's chance to cast spells successfully.",
	},

	[49] = {
		name = "Calm Humanoid",
		school = "Illusion",
		description = "Makes a humanoid less likely to attack.",
	},

	[50] = {
		name = "Calm Creature",
		school = "Illusion",
		description = "Makes a creature less likely to attack.",
	},

	[51] = {
		name = "Frenzy Humanoid",
		school = "Illusion",
		description = "Makes a humanoid more likely to attack.",
	},

	[52] = {
		name = "Frenzy Creature",
		school = "Illusion",
		description = "Makes a creature more likely to attack.",
	},

	[53] = {
		name = "Demoralize Humanoid",
		school = "Mysticism",
		description = "Makes a humanoid more likely to flee.",
	},

	[54] = {
		name = "Demoralize Creature",
		school = "Illusion",
		description = "Makes a creature more likely to flee.",
	},

	[55] = {
		name = "Rally Humanoid",
		school = "Illusion",
		description = "Makes a humanoid less likely to flee.",
	},

	[56] = {
		name = "Rally Creature",
		school = "Illusion",
		description = "Makes a creature less likely to flee.",
	},

	[57] = {
		name = "Dispel",
		school = "Mysticism",
		description = "Removes active magical effects from the subject.",
	},

	[58] = {
		name = "Soultrap",
		school = "Mysticism",
		description = "Traps the target's soul in a suitable empty soul gem if it dies.",
	},

	[59] = {
		name = "Telekinesis",
		school = "Mysticism",
		description = "Allows activating and picking up objects from a distance.",
	},

	[60] = {
		name = "Mark",
		school = "Mysticism",
		description = "Sets the destination for Recall.",
	},

	[61] = {
		name = "Recall",
		school = "Mysticism",
		description = "Returns the subject to the marked location.",
	},

	[62] = {
		name = "Divine Intervention",
		school = "Mysticism",
		description = "Teleports the subject to the nearest Imperial Cult shrine.",
	},

	[63] = {
		name = "Almsivi Intervention",
		school = "Mysticism",
		description = "Teleports the subject to the nearest Tribunal Temple shrine.",
	},

	[64] = {
		name = "Detect Animal",
		school = "Mysticism",
		description = "Reveals nearby creatures on the map.",
	},

	[65] = {
		name = "Detect Enchantment",
		school = "Mysticism",
		description = "Reveals nearby enchanted items on the map.",
	},

	[66] = {
		name = "Detect Key",
		school = "Mysticism",
		description = "Reveals nearby keys on the map.",
	},

	[67] = {
		name = "Spell Absorption",
		school = "Mysticism",
		description = "Can absorb incoming spells as Magicka.",
	},

	[68] = {
		name = "Reflect",
		school = "Mysticism",
		description = "Can reflect incoming spells back at the caster.",
	},

	[69] = {
		name = "Cure Common Disease",
		school = "Restoration",
		description = "Cures common diseases.",
	},

	[70] = {
		name = "Cure Blight Disease",
		school = "Restoration",
		description = "Cures blight diseases.",
	},

	[71] = {
		name = "Cure Corprus Disease",
		school = "Restoration",
		description = "Cures Corprus.",
	},

	[72] = {
		name = "Cure Poison",
		school = "Restoration",
		description = "Removes poison from the subject.",
	},

	[73] = {
		name = "Cure Paralyzation",
		school = "Restoration",
		description = "Removes paralysis from the subject.",
	},

	[74] = {
		name = "Restore Attribute",
		school = "Restoration",
		description = "Restores the subject's attribute.",
	},

	[75] = {
		name = "Restore Health",
		school = "Restoration",
		description = "Restores the subject's health.",
	},

	[76] = {
		name = "Restore Magicka",
		school = "Restoration",
		description = "Restores the subject's magicka.",
	},

	[77] = {
		name = "Restore Fatigue",
		school = "Restoration",
		description = "Restores the subject's fatigue.",
	},

	[78] = {
		name = "Restore Skill",
		school = "Restoration",
		description = "Restores the subject's skill.",
	},

	[79] = {
		name = "Fortify Attribute",
		school = "Restoration",
		description = "Temporarily increases the subject's attribute.",
	},

	[80] = {
		name = "Fortify Health",
		school = "Restoration",
		description = "Temporarily increases the subject's health.",
	},

	[81] = {
		name = "Fortify Magicka",
		school = "Restoration",
		description = "Temporarily increases the subject's magicka.",
	},

	[82] = {
		name = "Fortify Fatigue",
		school = "Restoration",
		description = "Temporarily increases the subject's fatigue.",
	},

	[83] = {
		name = "Fortify Skill",
		school = "Restoration",
		description = "Temporarily increases the subject's skill.",
	},

	[84] = {
		name = "Fortify Maximum Magicka",
		school = "Restoration",
		description = "Increases maximum Magicka based on Intelligence.",
	},

	[85] = {
		name = "Absorb Attribute",
		school = "Mysticism",
		description = "Transfers attribute from the target to the caster.",
	},

	[86] = {
		name = "Absorb Health",
		school = "Mysticism",
		description = "Transfers health from the target to the caster.",
	},

	[87] = {
		name = "Absorb Magicka",
		school = "Mysticism",
		description = "Transfers magicka from the target to the caster.",
	},

	[88] = {
		name = "Absorb Fatigue",
		school = "Mysticism",
		description = "Transfers fatigue from the target to the caster.",
	},

	[89] = {
		name = "Absorb Skill",
		school = "Mysticism",
		description = "Transfers skill from the target to the caster.",
	},

	[90] = {
		name = "Resist Fire",
		school = "Restoration",
		description = "Increases resistance to Fire.",
	},

	[91] = {
		name = "Resist Frost",
		school = "Restoration",
		description = "Increases resistance to Frost.",
	},

	[92] = {
		name = "Resist Shock",
		school = "Restoration",
		description = "Increases resistance to Shock.",
	},

	[93] = {
		name = "Resist Magicka",
		school = "Restoration",
		description = "Increases resistance to Magicka.",
	},

	[94] = {
		name = "Resist Common Disease",
		school = "Restoration",
		description = "Increases resistance to Common Disease.",
	},

	[95] = {
		name = "Resist Blight Disease",
		school = "Restoration",
		description = "Increases resistance to Blight Disease.",
	},

	[96] = {
		name = "Resist Corprus Disease",
		school = "Restoration",
		description = "Increases resistance to Corprus Disease.",
	},

	[97] = {
		name = "Resist Poison",
		school = "Restoration",
		description = "Increases resistance to Poison.",
	},

	[98] = {
		name = "Resist Normal Weapons",
		school = "Restoration",
		description = "Reduces damage from normal weapons.",
	},

	[99] = {
		name = "Resist Paralysis",
		school = "Restoration",
		description = "Increases resistance to Paralysis.",
	},

	[100] = {
		name = "Remove Curse",
		school = "Restoration",
		description = "Removes curses. Unused in normal gameplay.",
	},

	[101] = {
		name = "Turn Undead",
		school = "Conjuration",
		description = "Makes undead more likely to flee.",
	},

	[102] = {
		name = "Summon Scamp",
		school = "Conjuration",
		description = "Summons a Scamp to fight for the caster.",
	},

	[103] = {
		name = "Summon Clannfear",
		school = "Conjuration",
		description = "Summons a Clannfear to fight for the caster.",
	},

	[104] = {
		name = "Summon Daedroth",
		school = "Conjuration",
		description = "Summons a Daedroth to fight for the caster.",
	},

	[105] = {
		name = "Summon Dremora",
		school = "Conjuration",
		description = "Summons a Dremora to fight for the caster.",
	},

	[106] = {
		name = "Summon Ancestral Ghost",
		school = "Conjuration",
		description = "Summons a Ancestral Ghost to fight for the caster.",
	},

	[107] = {
		name = "Summon Skeletal Minion",
		school = "Conjuration",
		description = "Summons a Skeletal Minion to fight for the caster.",
	},

	[108] = {
		name = "Summon Bonewalker",
		school = "Conjuration",
		description = "Summons a Bonewalker to fight for the caster.",
	},

	[109] = {
		name = "Summon Greater Bonewalker",
		school = "Conjuration",
		description = "Summons a Greater Bonewalker to fight for the caster.",
	},

	[110] = {
		name = "Summon Bonelord",
		school = "Conjuration",
		description = "Summons a Bonelord to fight for the caster.",
	},

	[111] = {
		name = "Summon Winged Twilight",
		school = "Conjuration",
		description = "Summons a Winged Twilight to fight for the caster.",
	},

	[112] = {
		name = "Summon Hunger",
		school = "Conjuration",
		description = "Summons a Hunger to fight for the caster.",
	},

	[113] = {
		name = "Summon Golden Saint",
		school = "Conjuration",
		description = "Summons a Golden Saint to fight for the caster.",
	},

	[114] = {
		name = "Summon Flame Atronach",
		school = "Conjuration",
		description = "Summons a Flame Atronach to fight for the caster.",
	},

	[115] = {
		name = "Summon Frost Atronach",
		school = "Conjuration",
		description = "Summons a Frost Atronach to fight for the caster.",
	},

	[116] = {
		name = "Summon Storm Atronach",
		school = "Conjuration",
		description = "Summons a Storm Atronach to fight for the caster.",
	},

	[117] = {
		name = "Fortify Attack",
		school = "Restoration",
		description = "Raises the subject's chance to hit.",
	},

	[118] = {
		name = "Command Creature",
		school = "Conjuration",
		description = "Makes a creature fight for the caster.",
	},

	[119] = {
		name = "Command Humanoid",
		school = "Conjuration",
		description = "Makes a humanoid fight for the caster.",
	},

	[120] = {
		name = "Bound Dagger",
		school = "Conjuration",
		description = "Summons and equips a bound Daedric dagger.",
	},

	[121] = {
		name = "Bound Longsword",
		school = "Conjuration",
		description = "Summons and equips a bound Daedric longsword.",
	},

	[122] = {
		name = "Bound Mace",
		school = "Conjuration",
		description = "Summons and equips a bound Daedric mace.",
	},

	[123] = {
		name = "Bound Battle Axe",
		school = "Conjuration",
		description = "Summons and equips a bound Daedric battle axe.",
	},

	[124] = {
		name = "Bound Spear",
		school = "Conjuration",
		description = "Summons and equips a bound Daedric spear.",
	},

	[125] = {
		name = "Bound Longbow",
		school = "Conjuration",
		description = "Summons and equips a bound Daedric longbow.",
	},

	[126] = {
		name = "EXTRA SPELL",
		school = "Conjuration",
		description = "",
	},

	[127] = {
		name = "Bound Cuirass",
		school = "Conjuration",
		description = "Summons and equips a bound Daedric cuirass.",
	},

	[128] = {
		name = "Bound Helm",
		school = "Conjuration",
		description = "Summons and equips a bound Daedric helm.",
	},

	[129] = {
		name = "Bound Boots",
		school = "Conjuration",
		description = "Summons and equips a bound Daedric boots.",
	},

	[130] = {
		name = "Bound Shield",
		school = "Conjuration",
		description = "Summons and equips a bound Daedric shield.",
	},

	[131] = {
		name = "Bound Gloves",
		school = "Conjuration",
		description = "Summons and equips a bound Daedric gloves.",
	},

	[132] = {
		name = "Corprus",
		school = "Destruction",
		description = "Infects the subject with Corprus.",
	},

	[133] = {
		name = "Vampirism",
		school = "Destruction",
		description = "Gives the subject vampiric powers and weaknesses.",
	},

	[134] = {
		name = "Summon Centurion Sphere",
		school = "Conjuration",
		description = "Summons a Centurion Sphere to fight for the caster.",
	},

	[135] = {
		name = "Sun Damage",
		school = "Destruction",
		description = "Damages the subject in sunlight.",
	},

	[136] = {
		name = "Stunted Magicka",
		school = "Destruction",
		description = "Prevents Magicka regeneration while resting.",
	},

	[137] = {
		name = "Summon Fabricant",
		school = "Conjuration",
		description = "Summons a Fabricant to fight for the caster.",
	},

	[138] = {
		name = "sEffectSummonCreature01",
		school = "Conjuration",
		description = "",
	},

	[139] = {
		name = "sEffectSummonCreature02",
		school = "Conjuration",
		description = "",
	},

	[140] = {
		name = "sEffectSummonCreature03",
		school = "Alteration",
		description = "",
	},

	[141] = {
		name = "sEffectSummonCreature04",
		school = "Alteration",
		description = "",
	},

	[142] = {
		name = "sEffectSummonCreature05",
		school = "Alteration",
		description = "",
	},

}

return effectDescriptionsById