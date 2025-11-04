local MODNAME = "Disenchanting"
local I = require('openmw.interfaces')

settings = {
    key = 'Settings'..MODNAME,
    page = MODNAME,
    l10n = "none",
    name = "Disenchanting",
	description = "",
    permanentStorage = true,
    settings = {
		{
			key = "EXPERIENCE_EXP",
			name = "Experience Exponent",
			description = "EnchantmentPoints ^ Exponent",
			renderer = "number",
			default = 0.71,
			argument = {
				min = 0,
				max = 1000,
			},
		},
		{
			key = "EXPERIENCE_MULT2",
			name = "Experience Mult",
			description = "* Mult",
			renderer = "number",
			default = 0.4,
			argument = {
				min = 0,
				max = 1000,
			},
		},
		{
			key = "EXPERIENCE_ADD2",
			name = "Experience Add",
			description = "+ Add",
			renderer = "number",
			default = 3.5,
			argument = {
				min = 0,
				max = 1000,
			},
		},
		{
			key = "CONSUME_MULT",
			name = "Consuming Experience Mult",
			description = "Soul value gets fed into the formula above and multiplied by this\n0 disables the dialogue when you use a soulgem with shift",
			renderer = "number",
			default = 2.5,
			argument = {
				min = 0,
				max = 1000,
			},
		},
		{
			key = "RECOUPED_SOUL",
			name = "Recouped Soul Mult",
			description = "enchantment size * this mult\nset to 0 to disable",
			renderer = "number",
			default = 0.7,
			argument = {
				min = 0,
				max = 1000,
			},
		},
		{
			key = "MINIMUM_RECOUPED_SOUL",
			name = "Minimum Recouped Soul",
			description = "if the recouped soul is smaller than this value, don't create a soulgem",
			renderer = "number",
			default = 10,
			argument = {
				min = 0,
				max = 1000,
			},
		},
		{
			key = "REQUIRE_EMPTY_SOULGEM",
			name = "Require empty soul gem",
			description = "does not use azura's star",
			renderer = "checkbox",
			default = true
		},
		{
			key = "VALUE_MULT",
			name = "Disenchanted Item Value Mult",
			description = "0 = don't create a disenchanted version",
			renderer = "number",
			default = 0.5,
			argument = {
				min = 0,
				max = 1000,
			},
		},
		{
			key = "CAPACITY_MULT",
			name = "Disenchanted Item Capacity Mult",
			description = "new capacity = old capacity * this mult",
			renderer = "number",
			default = 0.90,
			argument = {
				min = 0,
				max = 1000,
			},
		},
		{
			key = "CAPACITY_FROM_ENCHANTMENT",
			name = "Capacity Increase From Old Enchantment",
			description = "new capacity = value above + (enchantment size * this mult)",
			renderer = "number",
			default = 0.43,
			argument = {
				min = 0,
				max = 1000,
			},
		},
		{
			key = "BEST_IN_SLOT_CAP",
			name = "Cap at x times best in slot value",
			description = "If the new capacity is higher than x times the best unenchanted item for this slot, reduce it to x times that item's capacity",
			renderer = "number",
			default = 999999999,
			argument = {
				min = 0,
				max = 999999999,
			},
		},
		{
			key = "CAPACITY_CAP_FOR_TRASH",
			name = "Enchant Magnitude Mult for Trash",
			description = "The enchant magnitude that the formula uses is usually capped at 2x the item's base capacity.\nFor example boots of blinding light have a magnitude of several thousand but would get held back by their base capacity of 10.\nThis multiplier lifts it back up to at least x times the enchantment magnitude.",
			renderer = "number",
			default = 0.1428,
			argument = {
				min = 0,
				max = 1000,
			},
		},
		{
			key = "ALLOW_SPELLMAKING",
			name = "Use Effects in Spellmaking",
			description = "Allow using the effects learnt from disenchanting in spellmaking",
			renderer = "checkbox",
			default = true
		},
		{
			key = "ALLOW_REENCHANTING",
			name = "Use Effects in Enchanting",
			description = "Allow using the effects learnt from disenchanting in enchanting",
			renderer = "checkbox",
			default = true
		},
		{
			key = "OWN_SPELLS_IN_LIBRARY",
			name = "Own Spells In Library",
			description = "Enable if you want every spell you have ever known to be available for enchanting (and spellmaking?)",
			renderer = "checkbox",
			default = false
		},
		{
			key = "DISENCHANTING_EXPERTISE_MULT",
			name = "Disenchanting Expertise Multiplier",
			description = "Increases your enchanting by 4 points for each unique effect you have disenchanted plus the count of all effects you have ever disenchanted (max. +5 per item)\nmultiplied by this value",
			renderer = "number",
			default = 0.05,
			argument = {
				min = 0,
				max = 1000,
			},
		},
		{
			key = "UNCAPPER",
			name = "Uncapper",
			description = "Allow leveling enchanting higher than 100 though disenchanting or consuming soulgems",
			renderer = "checkbox",
			default = true
		},
		{
			key = "ENCHANT_CAPACITY_FIX",
			name = "Enchanting Capacity Fix",
			description = "Fixes that the game changes an item's capacity when you enchant it (does not affect charges or anything)",
			renderer = "checkbox",
			default = true
		},
		{
			key = "SOUL_PRICE_REBALANCE",
			name = "Tooltip Price Is Rebalanced?",
			description = "Do you have 'rebalance soul gem values' enabled in the settings?\nI recommend using my 'worthless soul gems' mod instead\nThis is only used for showing the correct price in the consume window.",
			renderer = "checkbox",
			default = true
		},
		{
			key = "PAPER_MULT",
			name = "Enchanted Paper Multiplier",
			description = "For every enchanted paper you get x-1 extra",
			renderer = "number",
			default = 5,
			argument = {
				min = 0,
				max = 1000,
			},
		},
	}
}





I.Settings.registerGroup(settings)





return true