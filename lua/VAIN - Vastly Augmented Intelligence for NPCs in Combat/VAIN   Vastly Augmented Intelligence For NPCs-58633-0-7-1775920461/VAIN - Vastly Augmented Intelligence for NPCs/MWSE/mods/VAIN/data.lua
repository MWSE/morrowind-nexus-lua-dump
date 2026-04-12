-- =============================================================================
-- VAIN.data
-- Static lookup tables (monster -> spell list, spell definitions) and the
-- runtime registry of created tes3 objects (stone weapon, projectile alchemy).
--
-- The static tables are populated at require-time. The runtime registry is
-- populated by main.lua during the `initialized` event, after which other
-- modules read from `data.spells` and `data.stone`.
-- =============================================================================
local M = {}

-- -----------------------------------------------------------------------------
-- Maps creature/NPC base IDs to their list of available projectile spell names
-- -----------------------------------------------------------------------------
M.monsterSpells = {
	-- Daedra
	["atronach_flame"] = { "Fire_ball", "Fire_bolt" },
	["atronach_flame_summon"] = { "Fire_ball", "Fire_bolt" },
	["atronach_frost"] = { "Frost_ball", "Frost_bolt" },
	["atronach_frost_summon"] = { "Frost_ball", "Frost_bolt" },
	["atronach_frost_BM"] = { "Frost_ball", "Frost_bolt" },
	["atronach_storm"] = { "Shock_ball", "Shock_bolt" },
	["atronach_storm_summon"] = { "Shock_ball", "Shock_bolt" },

	["dremora"] = { "Fire_arrow", "Fire_ball" },
	["dremora_summon"] = { "Fire_arrow", "Fire_ball" },
	["dremora_lord"] = { "Fire_ball", "Fire_bolt" },

	["golden saint"] = { "Fire_bolt", "Frost_bolt", "Shock_bolt" },
	["golden saint_summon"] = { "Fire_bolt", "Frost_bolt", "Shock_bolt" },

	["4nm_mazken"] = { "Chaos_bolt", "Frost_bolt", "Shock_bolt" },
	["4nm_mazken_s"] = { "Chaos_bolt", "Frost_bolt", "Shock_bolt" },

	["hunger"] = { "Chaos_arrow", "Chaos_ball" },
	["hunger_summon"] = { "Chaos_arrow", "Chaos_ball" },

	["scamp"] = { "Fire_arrow" },
	["scamp_summon"] = { "Fire_arrow" },

	["daedroth"] = { "Poison_arrow", "Poison_ball" },
	["daedroth_summon"] = { "Poison_arrow", "Poison_ball" },

	["winged twilight"] = { "Frost_arrow", "Frost_ball", "Shock_arrow", "Shock_ball" },
	["winged twilight_summon"] = { "Frost_arrow", "Frost_ball", "Shock_arrow", "Shock_ball" },

	["4nm_dremora_mage"] = { "Fire_ball", "Frost_ball", "Shock_ball", "Fire_bolt", "Frost_bolt", "Shock_bolt" },
	["4nm_dremora_mage_s"] = { "Fire_ball", "Frost_ball", "Shock_ball", "Fire_bolt", "Frost_bolt", "Shock_bolt" },

	["4nm_daedraspider"] = { "Poison_ball", "Poison_bolt", "Chaos_ball", "Chaos_bolt" },
	["4nm_daedraspider_s"] = { "Poison_ball", "Poison_bolt", "Chaos_ball", "Chaos_bolt" },

	["4nm_xivilai"] = { "Fire_ball", "Chaos_ball" },
	["4nm_xivilai_s"] = { "Fire_ball", "Chaos_ball" },

	["4nm_xivkyn"] = { "Fire_ball", "Fire_bolt", "Shock_ball", "Shock_bolt" },
	["4nm_xivkyn_s"] = { "Fire_ball", "Fire_bolt", "Shock_ball", "Shock_bolt" },

	-- Undead
	["ancestor_ghost"] = { "Chaos_arrow", "Frost_arrow" },
	["ancestor_ghost_summon"] = { "Chaos_arrow", "Frost_arrow" },
	["ancestor_ghost_greater"] = { "Chaos_arrow", "Chaos_ball", "Frost_arrow", "Frost_ball" },

	["Bonewalker_Greater"] = { "Chaos_arrow" },
	["Bonewalker_Greater_summ"] = { "Chaos_arrow" },

	["bonelord"] = { "Chaos_ball", "Chaos_bolt", "Frost_ball", "Frost_bolt" },
	["bonelord_summon"] = { "Chaos_ball", "Chaos_bolt", "Frost_ball", "Frost_bolt" },

	["4nm_skeleton_mage"] = {
		"Fire_arrow",
		"Frost_arrow",
		"Shock_arrow",
		"Chaos_arrow",
		"Fire_ball",
		"Frost_ball",
		"Shock_ball",
		"Chaos_ball",
	},
	["4nm_skeleton_mage_s"] = {
		"Fire_arrow",
		"Frost_arrow",
		"Shock_arrow",
		"Chaos_arrow",
		"Fire_ball",
		"Frost_ball",
		"Shock_ball",
		"Chaos_ball",
	},

	["lich"] = { "Frost_ball", "Poison_ball", "Chaos_ball", "Frost_bolt", "Poison_bolt", "Chaos_bolt" },
	["4nm_lich_elder"] = { "Frost_bolt", "Shock_bolt", "Poison_bolt", "Chaos_bolt" },
	["4nm_lich_elder_s"] = { "Frost_bolt", "Shock_bolt", "Poison_bolt", "Chaos_bolt" },

	-- Ash creatures & others
	["ash_slave"] = { "Fire_arrow", "Frost_arrow", "Shock_arrow" },
	["ash_ghoul"] = { "Chaos_ball", "Chaos_bolt" },
	["ascended_sleeper"] = { "Fire_bolt", "Frost_bolt", "Shock_bolt", "Poison_bolt", "Chaos_bolt" },

	["kwama warrior"] = { "Poison_arrow", "Poison_ball" },
	["kwama warrior blighted"] = { "Poison_arrow", "Poison_ball" },

	["netch_bull"] = { "Poison_arrow", "Poison_ball" },
	["netch_betty"] = { "Shock_arrow", "Shock_ball" },

	["goblin_handler"] = { "Fire_arrow" },
	["goblin_officer"] = { "Fire_arrow", "Fire_ball" },

	["BM_spriggan"] = { "Frost_ball", "Poison_ball" },
	["BM_ice_troll"] = { "Frost_arrow", "Frost_ball" },
}

-- -----------------------------------------------------------------------------
-- Projectile spell definitions used to build tes3alchemy objects on init.
-- Each entry: { n = name, { rangeType, effectId, minDmg, maxDmg, radius, duration } }
-- rangeType 2 = target. effectId: 14=fire, 15=shock, 16=frost, 23=chaos, 27=poison.
-- -----------------------------------------------------------------------------
M.spellDefs = {
	{ n = "Fire_arrow", { 2, 14, 5, 10, 1, 1 } },
	{ n = "Fire_ball", { 2, 14, 10, 20, 5, 1 } },
	{ n = "Fire_bolt", { 2, 14, 20, 30, 10, 1 } },
	{ n = "Frost_arrow", { 2, 16, 5, 10, 1, 1 } },
	{ n = "Frost_ball", { 2, 16, 10, 20, 5, 1 } },
	{ n = "Frost_bolt", { 2, 16, 20, 30, 10, 1 } },
	{ n = "Shock_arrow", { 2, 15, 5, 10, 1, 1 } },
	{ n = "Shock_ball", { 2, 15, 10, 20, 5, 1 } },
	{ n = "Shock_bolt", { 2, 15, 20, 30, 10, 1 } },
	{ n = "Poison_arrow", { 2, 27, 1, 2, 1, 5 } },
	{ n = "Poison_ball", { 2, 27, 2, 4, 5, 5 } },
	{ n = "Poison_bolt", { 2, 27, 4, 6, 10, 5 } },
	{ n = "Chaos_arrow", { 2, 23, 5, 10, 1, 1 } },
	{ n = "Chaos_ball", { 2, 23, 10, 20, 5, 1 } },
	{ n = "Chaos_bolt", { 2, 23, 20, 30, 10, 1 } },
}

-- -----------------------------------------------------------------------------
-- Effects that are useless (or harmful to AI quality) when used offensively.
-- A spell whose harmful effects are ALL in this set will be excluded from the
-- offensive spell list at combat start.
--
-- Soul Trap:           NPCs gain nothing from soul-trapping the player.
-- Demoralize Creature: Has no effect on the player character.
-- Demoralize Humanoid: Has no effect on the player character.
-- -----------------------------------------------------------------------------
M.forbiddenOffensiveEffects = {
	[tes3.effect.soultrap] = true,
	[tes3.effect.demoralizeCreature] = true,
	[tes3.effect.demoralizeHumanoid] = true,
}

-- -----------------------------------------------------------------------------
-- Runtime registry, populated by main.lua's `initialized` event handler.
-- -----------------------------------------------------------------------------
M.spells = {} -- spell name -> tes3alchemy
M.stone = nil ---@type tes3weapon

return M
