-- mcm.lua
-- Loaded via dofile from main.lua's modConfigReady handler.

local config = require("Magicka of the Third Era.config")

local template = mwse.mcm.createTemplate({
	name               = config.confPath,
	config             = config,
	defaultConfig      = config.default,
	showDefaultSetting = true,
})
template:saveOnClose(config.confPath, config)

-- Pages --

local main_page = template:createSideBarPage({
	label = "Main Settings",
	showReset = true,
	description = [[
    Magicka of the Third Era settings menu. Default settings are the recommended ones, but you can tweak them to further tailor the game's balance.

    Hover over each setting to get a description.
    ]]
})

local cost_page = template:createSideBarPage({
	label = "Spell Costs",
	showReset = true,
	description = [[
    Cost-related variables. These affect only the Magicka costs and do not touch the cast chances.
    ]]
})

local leveling_page = template:createSideBarPage({
	label = "Leveling",
	showReset = true,
	description = [[
    Leveling variables. Magicka of the Third Era overhauls the leveling of the spellcasting skills. This feature can be disabled or tweaked.
    ]]
})

local economy_page = template:createSideBarPage({
	label = "Economy",
	showReset = true,
	description = [[
    Economy-related variables. Depending on your economy mods, you might want to tweak these.
    ]]
})

local ui_page = template:createSideBarPage({
	label = "UI",
	showReset = true,
	description = [[
    UI settings.
    ]]
})

-- Categories --

local main_settings          = main_page:createCategory("Main")
local category_main_chances  = main_page:createCategory("Spell Chances")
local hybrid_parameters      = main_page:createCategory("Hybrid Mode Parameters")

local category_cost_general  = cost_page:createCategory("General")
local category_cost_armor    = cost_page:createCategory("Armor")
local category_cost_overflow = cost_page:createCategory("Overflowing Magicka")

local category_leveling_general = leveling_page:createCategory("General")

local category_economy_general = economy_page:createCategory("General")

local category_ui_spell_merchant = ui_page:createCategory("Spell Merchants")

-- Main --

main_settings:createLogLevelOptions({
	configKey      = "log_level",
	defaultSetting = "INFO",
})

main_settings:createOnOffButton{
	label = "Enable NPC Assist",
	description = [[
      Enable assistance for spells cast by NPCs. By default, NPCs will have their minimal cast chance set to 61%, which is a guarantee under determinist mode. Also gives a small assist to bandaid the AI, which treats spells as if they have the old costs.

      Leave this on unless you are 100% sure what you are doing. NPCs can't react to their failures properly and will be significantly weaker without it.
    ]],
	configKey = "npc_assist",
}

main_settings:createOnOffButton{
	label = "Skip Birthsign Spells",
	description = [[
      When enabled, spells granted by the player's birthsign are exempt from the mod's cost and cast chance recalculations. Their vanilla values are preserved.

      Leave this on unless you specifically want birthsign spells to be rebalanced by the mod.
    ]],
	configKey = "skip_birthsign_spells",
}

main_settings:createOnOffButton{
	label = "Distribute Magicka Expanded Spells",
	description = [[
      Distribute spells from Magicka Expanded to spell merchants. Only distributes packs you have enabled; Cortex spells are not yet supported. Does nothing if Magicka Expanded is not installed.

      Spells are distributed to both Vanilla and TR merchants. The distribution is not random.
    ]],
	configKey = "distribute_magicka_expanded_spells",
}

main_settings:createButton{
	buttonText = "Reset Spell Storage",
	description = [[
      Resets the spell storage, forcing the mod to recalculate all spells from scratch.

      Useful if spell base cost formulas were changed mid-game (none can be changed via MCM). Also performed automatically when updating from an older version.

      Normally, you don't need to use this.
    ]],
	callback = function()
		if tes3.player ~= nil then
			tes3.player.data.motte_spell_storage = {}
			tes3.messageBox("[Magicka of the Third Era] Spell storage has been reset.")
		end
	end,
	inGameOnly = true,
}

-- Spell Chances --

category_main_chances:createDropdown{
	label = "Spell Chances Handling",
	options = {
		{ label = "0. Vanilla",             value = 0 },
		{ label = "1. Partial Determinism", value = 1 },
		{ label = "2. Full Determinism",    value = 2 },
		{ label = "3. Hybrid",              value = 3 },
	},
	configKey = "determinism_mode",
	description = [[
      How spell chances behave in game.
      0 = Vanilla: dice rolls for all spells.
      1 = Semi-deterministic: no dice rolls for effects where randomness is abusable, like Open.
      2 = Full determinism: 61% or above always succeeds, below always fails.
      3 = Hybrid: full determinism outside the configured range, probabilistic within it to soften the hard cutoff while preserving mod balance.

      Mod is balanced around 2. For dice-roll cast chances, try 1 (retains randomness for most spells) or 3 (softer transition around the threshold).
    ]]
}

category_main_chances:createSlider{
	label = "Flat Chance Increase",
	description = [[
      Only relevant in modes 0 and 1. Adds a flat bonus to cast chances. The mod is balanced around 61% being reliably castable, so you may want a higher base chance in these modes.
    ]],
	configKey = "flat_chance_bonus",
	min = 0, max = 40, step = 1, jump = 5,
}

category_main_chances:createOnOffButton{
	label = "Override Always-to-Succeed Chances",
	description = [[
      When enabled, recalculates cast chances even for spells tagged 'always succeeds', ignoring the tag. Leave disabled to preserve the guaranteed success of those spells.
    ]],
	configKey = "override_chances_alwaystosucceed",
}

category_main_chances:createDropdown{
	label = "Chance Calculation Formula",
	options = {
		{ label = "2. Flatter",  value = 2 },
		{ label = "3. Baseline", value = 3 },
	},
	configKey = "chance_formula",
	description = [[
      Formula used to calculate spell cast chances.
      2 - Flatter: higher base chance, less reward for skill investment. Compresses the range between low and high skill builds.
      3 - Baseline: steeper skill scaling, more differentiation between builds. Recommended.
    ]]
}

category_main_chances:createSlider{
	label = "Willpower Softcap",
	description = [[
      Softcap on Willpower's contribution to spell chances. Set to 100 to make any Willpower above 100 have no further effect. Set to 0 to disable.
      For Willpower > 100: Capped = 100 + (Willpower - 100)^(1 - Softcap/100)

      Some softcap is recommended, since stacking Willpower can make a mage excessively powerful.
    ]],
	configKey = "willpower_softcap",
	min = 0, max = 100, step = 1, jump = 10,
}

-- Hybrid Mode Parameters --

hybrid_parameters:createSlider{
	label = "Cut-In Value",
	description = [[
      For Hybrid only: spell chance is always 0 below this value. Must be lower than the fulcrum.
    ]],
	configKey = "sa_cut_in_value",
	min = 0, max = 100, step = 1, jump = 10,
}

hybrid_parameters:createSlider{
	label = "Fulcrum Value",
	description = [[
      For Hybrid only: the value around which the shoulder is balanced. Must be higher than cut-in and lower than cut-off.
    ]],
	configKey = "sa_fulcrum_value",
	min = 0, max = 100, step = 1, jump = 10,
}

hybrid_parameters:createSlider{
	label = "Cut-Off Value",
	description = [[
      For Hybrid only: spell chance is always 100 above this value. Must be higher than the fulcrum.
    ]],
	configKey = "sa_cut_off_value",
	min = 0, max = 100, step = 1, jump = 10,
}

hybrid_parameters:createSlider{
	label = "Base Probability",
	description = [[
      For Hybrid only: the spell chance at the fulcrum value.
    ]],
	configKey = "sa_base_probability",
	min = 0, max = 100, step = 1, jump = 10,
}

hybrid_parameters:createSlider{
	label = "Step Chance",
	description = [[
      For Hybrid only: spell chance increment per step within the shoulder range.
    ]],
	configKey = "sa_chance_step",
	min = 0, max = 20, step = 1, jump = 5,
}

-- Spell Costs --

category_cost_general:createOnOffButton{
	label = "Override Always-to-Succeed Costs",
	description = [[
      By default the mod recalculates costs for all spells with valid effects, including always-to-succeed ones. Disable if you have a mod that adds expensive spells with this tag.
    ]],
	configKey = "override_costs_alwaystosucceed",
}

category_cost_general:createSlider{
	label = "Fatigue Cost Penalty",
	description = [[
      Increases spell costs based on missing fatigue, up to this percentage more. Does not affect cast chance. Set to 0 to disable.
    ]],
	configKey = "fatigue_penalty_mult",
	min = 0, max = 150, step = 1, jump = 5,
}

-- Armor --

category_cost_armor:createSlider{
	label = "Armor Cost Penalty",
	description = [[
      Maximum percentage increase to spell costs when wearing armor with insufficient skill. Larger armor pieces contribute more. Does not affect cast chance. Set to 0 to disable.
    ]],
	configKey = "armor_penalty_perc_max",
	min = 0, max = 300, step = 1, jump = 10,
}

category_cost_armor:createSlider{
	label = "Armor Cost Penalty - Light",
	description = [[
      Light Armor skill required to fully avoid the cost penalty. Below this value, costs scale up toward the Armor Cost Penalty maximum.
    ]],
	configKey = "armor_penalty_cap_light",
	min = 5, max = 100, step = 1, jump = 5,
}

category_cost_armor:createSlider{
	label = "Armor Cost Penalty - Medium",
	description = [[
      Medium Armor skill required to fully avoid the cost penalty. Below this value, costs scale up toward the Armor Cost Penalty maximum.
    ]],
	configKey = "armor_penalty_cap_medium",
	min = 5, max = 100, step = 1, jump = 5,
}

category_cost_armor:createSlider{
	label = "Armor Cost Penalty - Heavy",
	description = [[
      Heavy Armor skill required to fully avoid the cost penalty. Below this value, costs scale up toward the Armor Cost Penalty maximum.
    ]],
	configKey = "armor_penalty_cap_heavy",
	min = 5, max = 100, step = 1, jump = 5,
}

-- Overflowing Magicka --

category_cost_overflow:createSlider{
	label = "Overflowing Magicka",
	description = [[
      Increases spell costs while your current Magicka exceeds 100. For every 100 points above that threshold, costs increase by this percentage. Costs return to normal once Magicka drops to 100 or below.
      The goal is to nerf large Magicka pools without penalizing players for simply having high Magicka. Set to 0 to disable.
    ]],
	configKey = "overflowing_magicka_rate",
	min = 0, max = 200, step = 1, jump = 5,
}

-- Leveling --

category_leveling_general:createOnOffButton{
	label = "Reworked Experience Gain",
	description = [[
      Alters experience gain from casting spells. Experience is based on spell cost and distributed across all involved schools proportional to effect costs.
      Disabling this disables all variables below.
    ]],
	configKey = "experience_gain",
}

category_leveling_general:createSlider{
	label = "Global Magic Leveling Rate",
	description = [[
      Global multiplier on experience gained from casting spells.
    ]],
	configKey = "leveling_rate_global",
	min = 0, max = 300, step = 1, jump = 10,
}

category_leveling_general:createSlider{
	label = "Alteration Leveling Rate",
	description = [[
      Experience gain multiplier for the Alteration school.
    ]],
	configKey = "leveling_rate_alteration",
	min = 0, max = 300, step = 1, jump = 10,
}

category_leveling_general:createSlider{
	label = "Conjuration Leveling Rate",
	description = [[
      Experience gain multiplier for the Conjuration school.
    ]],
	configKey = "leveling_rate_conjuration",
	min = 0, max = 300, step = 1, jump = 10,
}

category_leveling_general:createSlider{
	label = "Destruction Leveling Rate",
	description = [[
      Experience gain multiplier for the Destruction school.
    ]],
	configKey = "leveling_rate_destruction",
	min = 0, max = 300, step = 1, jump = 10,
}

category_leveling_general:createSlider{
	label = "Illusion Leveling Rate",
	description = [[
      Experience gain multiplier for the Illusion school.
    ]],
	configKey = "leveling_rate_illusion",
	min = 0, max = 300, step = 1, jump = 10,
}

category_leveling_general:createSlider{
	label = "Mysticism Leveling Rate",
	description = [[
      Experience gain multiplier for the Mysticism school.
    ]],
	configKey = "leveling_rate_mysticism",
	min = 0, max = 300, step = 1, jump = 10,
}

category_leveling_general:createSlider{
	label = "Restoration Leveling Rate",
	description = [[
      Experience gain multiplier for the Restoration school.
    ]],
	configKey = "leveling_rate_restoration",
	min = 0, max = 300, step = 1, jump = 10,
}

category_leveling_general:createOnOffButton{
	label = "Uncapped Leveling",
	description = [[
      Allows spellcasting skills to progress beyond 100.
    ]],
	configKey = "leveling_uncapped",
}

-- Economy --

category_economy_general:createSlider{
	label = "Spell Merchant Multiplier",
	description = [[
      Multiplier on gold costs for spells bought from merchants.
    ]],
	configKey = "economy_spellmerchant_mult",
	min = 0, max = 100, step = 1, jump = 5,
}

category_economy_general:createSlider{
	label = "Spellmaker Multiplier",
	description = [[
      Multiplier on gold costs for spells created at the spellmaker.
    ]],
	configKey = "economy_spellmaker_mult",
	min = 0, max = 100, step = 1, jump = 5,
}

category_economy_general:createSlider{
	label = "Spell Merchant Disposition Factor",
	description = [[
      Maximum percentage increase to spell merchant prices at 0 Disposition versus 100. E.g. 100 means spells cost double at 0 Disposition.
    ]],
	configKey = "economy_spellmerchant_diff",
	min = 0, max = 200, step = 1, jump = 5,
}

category_economy_general:createSlider{
	label = "Spellmaker Disposition Factor",
	description = [[
      Maximum percentage increase to spellmaker prices at 0 Disposition versus 100. E.g. 30 means the spellmaker costs 30% more at 0 Disposition.
    ]],
	configKey = "economy_spellmaker_diff",
	min = 0, max = 200, step = 1, jump = 5,
}

-- UI --

category_ui_spell_merchant:createOnOffButton{
	label = "Extended Spell Merchant UI",
	description = [[
      Use the extended look for the spell merchant UI.
    ]],
	configKey = "ui_extended_spell_merchant",
}

category_ui_spell_merchant:createDropdown{
	label = "Spell Sorting",
	options = {
		{ label = "0. None",          value = 0 },
		{ label = "1. Name",          value = 1 },
		{ label = "2. Cost",          value = 2 },
		{ label = "3. Chance",        value = 3 },
		{ label = "4. School + Name", value = 4 },
		{ label = "5. School + Cost", value = 5 },
	},
	configKey = "ui_spell_merchant_sort",
	description = [[
      Sorting algorithm for the spell merchant list.
      0 - No sorting.
      1 - Sort by name.
      2 - Sort by gold cost (almost always derived from base cost).
      3 - Sort by cast chance.
      4 - Sort by dominant school, name as tiebreaker.
      5 - Sort by dominant school, cost as tiebreaker.
    ]]
}

template:register()
