local defns = require("herbert100.more quickloot.defns")

---@class herbert.MQL.config.Container.equipped
---@field clothing_slots {[tes3.clothingSlot]: true}
---@field armor_slots {[tes3.armorSlot]: true}
---@field weapon_types {[tes3.weaponType]: true}
---@field show_unavailable boolean if blocked, should they still be shown in the menu?
---@field allowed_type_defns {[herbert.MQL.defns.equipped_type]: boolean}

---@class herbert.MQL.config.keys
local keys = {
	use_activate_btn = false,

	---@type mwseKeyMouseCombo
	custom = { keyCode = tes3.scanCode.f },
	---@type mwseKeyMouseCombo
	take_all = { keyCode = tes3.scanCode.r },
	---@type mwseKeyMouseCombo
	modifier = { keyCode = tes3.scanCode.lAlt },

	---@type mwseKeyMouseCombo
	equip_modifier = { keyCode = tes3.scanCode.backSlash },

	---@type mwseKeyMouseCombo
	undo = {
		keyCode = tes3.scanCode.z,
		isControlDown = true,
		isAltDown = false,
		isShiftDown = false,
		isSuperDown = false,
	},
}
---@class herbert.MQL.config.UI
local UI = {
	menu_x_pos = 0.8,
	menu_y_pos = 0.5,
	max_disp_items = 10,

	play_switch_sounds = "menu click", ---@type false|string

	show_msgbox = true,
	show_lucky_msg = true,
	show_failure_msg = true,
	show_tooltips = true,

	--- Should an icon for the tooltips be shown?
	---
	---@type
	---|0 Do not show an icon
	---|1 Show an icon, but show it below the tooltip (for compatibility)
	---|2 Show an icon above the tooltip.
	show_tooltips_icon = 2,
	show_controls = true,
	-- should we display extra controls?
	show_controls_m = true,

	-- only in supported menus
	enable_status_bar = true,

	-- how should items be sorted?
	sort_items = defns.sort_items.value_weight_ratio, ---@type herbert.MQL.defns.sort_items

	-- should we also sort by object type?
	sort_by_obj_type = true,

	ttip_collected_str = "(C)",

	ttip_mark_selected = true,

	-- update player inventory when quickloot menu is closed. can give performance boosts in some cases
	update_inv_on_close = false,

	---@type
	---|1 dont autosize, dont center
	---|2 dont autosize, but do center
	---|3 autosize, dont center
	columns_layout = 3,
}

---@class herbert.MQL.config.container.regular
local reg = {

	equip_modifier_take_all_enabled = false,

	mi = {
		-- single take
		defns.mi.ratio,
		-- single take (m)
		defns.mi.stack,
		-- take all
		defns.mi.stack,
		-- take all (m)
		defns.mi.ratio,
		min_ratio = 8,
		max_total_weight = 75,

	},

	sn_dist = 200,

	-- How strict should we be when searching nearby containers?
	sn_cf = defns.sn_cf.same_base_obj, ---@type herbert.MQL.defns.sn_cf

	-- Should we test line of sight when searching for nearby containers?
	sn_test_line_of_sight = true,

	-- minimum gold/weight ratio before we take all
	take_all_min_ratio = 1.0,
	-- Search nearby creatures of the same type?
	-- If false, then the same name will be used.
	sn_same_type = true,
};

---@class herbert.MQL.config.container.dead
local dead = {
	enable = true,

	-- Replace `take all` button with "Dispose" prompt when dead things are empty?
	dispose = true,

	-- Should we pool by creature type? or include all nearby dead things.
	sn_pool_by_creature_type = false,
};

---@class herbert.MQL.config.container.inanimate
local inanimate = {
	enable = true,

	show_trapped = true, -- use security skill to see inside trapped containers
	show_locked = false, -- use security skill to see inside locked containers

	show_locked_min_security = 50,
	show_trapped_min_security = 35,

	ac = {
		open = defns.misc.ac.open.on_sight, ---@type herbert.MQL.defns.misc.ac.open
		close = defns.misc.ac.close.use_ac_cfg, ---@type herbert.MQL.defns.misc.ac.close
		auto_close_if_empty = false,
	},

	-- minimum weight an item should have if we're to place it inside the container
	placing = {
		allow_books = false,
		allow_ingredients = true,
		reverse_sort = true,
		min_weight = 2,
	},
};

---@class herbert.MQL.config.container.pickpocket
local pickpocket = {
	enable = true,
	mi = {
		-- single take
		defns.mi.one,
		-- single take (m)
		defns.mi.stack,
		-- take all
		defns.mi.stack,
		-- take all (m)
		defns.mi.one,
		min_chance = 0.15,
		min_ratio = 5,
		max_total_weight = 50,
	},
	---@type herbert.MQL.config.Container.equipped
	equipped = {
		-- auto generated from other settings
		---@type {[tes3.clothingSlot]: true}
		armor_slots = {},
		-- auto generated from other settings
		---@type {[tes3.clothingSlot]: true}
		weapon_types = {},
		-- auto generated from other settings
		---@type {[tes3.clothingSlot]: true}
		clothing_slots = {},
		allowed_type_defns = {
			[defns.equipped_types.accessories] = true,
			[defns.equipped_types.jewelry] = true,
			[defns.equipped_types.clothing] = false,
			[defns.equipped_types.weapons] = false,
			[defns.equipped_types.armor] = false,
		},

		show_unavailable = true,
	},

	show_chances = defns.ui_show_chances.always, ---@type herbert.MQL.defns.ui_show_chances
	show_chances_lvl = 50, ---@type integer level to show chances
	show_chances_100 = true, ---@type boolean should chances be shown if they're 100%

	determinism = false,
	determinism_cutoff = .70,
	show_detection_status = true,

	chance_mult = 1,

	min_chance = 0.05,
	max_chance = 1.00,

	detection_mult = 0.33,
	trigger_crime_undetected = true,

};
---@class herbert.MQL.config.container.organic
local organic = {
	enable = true,

	-- ---------------------------------------------------------------------
	-- VISUAL/COMPATIBILITY
	-- ---------------------------------------------------------------------
	-- should plants be changed when empty. if so, how?
	change_plants = defns.change_plants.none, ---@type herbert.MQL.defns.change_plants
	not_plants_src = defns.not_plants_src.plant_list, ---@type herbert.MQL.defns.not_plants_src
	hide_on_empty = true, -- hide on empty containers

	-- ---------------------------------------------------------------------
	-- MULTIPLE ITEMS
	-- ---------------------------------------------------------------------
	mi = {
		-- single take
		defns.mi.one,
		-- single take (m)
		defns.mi.stack,
		-- take all
		defns.mi.stack,
		-- take all (m)
		defns.mi.one,

		-- only used for the `total_chance` setting in `multiple_items`
		min_chance = 0.50,
		max_total_weight = 50,
		min_ratio = 3,
	},

	show_chances = defns.ui_show_chances.lvl, ---@type herbert.MQL.defns.ui_show_chances
	show_chances_lvl = 35, ---@type integer level to show chances
	show_chances_100 = true, ---@type boolean should chances be shown if they're 100%

	-- ---------------------------------------------------------------------
	-- XP
	-- ---------------------------------------------------------------------
	xp = { award = true, on_failure = true, max_lvl = 50 },
	-- ---------------------------------------------------------------------
	-- MISC
	-- ---------------------------------------------------------------------

	sn_dist = 300,
	sn_cf = defns.sn_cf.same_base_obj, ---@type herbert.MQL.defns.sn_cf

	chance_mult = 1,
	min_chance = 0.15,
	max_chance = 1.00,
};
---@class herbert.MQL.config.container.training
local training = { enable = true, max_lvl_is_weight = true };
---@class herbert.MQL.config.container.barter
local barter = {
	enable = true,

	-- should we start by buying, or start by selling?
	start_buying = true,
	-- switch_if_empty = true,
	---@type herbert.MQL.config.Container.equipped
	equipped = {

		armor_slots = {},
		weapon_types = {},
		clothing_slots = {},
		allowed_type_defns = {
			[defns.equipped_types.accessories] = true,
			[defns.equipped_types.jewelry] = true,
			[defns.equipped_types.clothing] = false,
			[defns.equipped_types.weapons] = false,
			[defns.equipped_types.armor] = false,
		},

		show_unavailable = true,
	},

	automate_disposition_minmaxing = false,

	-- should xp be given after successfully bartering?
	award_xp = false, -- this will be set to `true` the first time BXP is installed
	selling = {
		allow_books = true,
		allow_ingredients = true,
		reverse_sort = false,
		min_weight = 2,
	},
	show_cart_gold_value = false,
};
---@class herbert.MQL.config.container.services
local services = {
	enable = true,
	allow_skooma = true,

	default_service = 0, -- `services` to start at
};

---@class herbert.MQL.config.blacklist
local blacklist = {
	---@type {[string]: boolean}
	containers = {
		["g7_container_keys"] = true,
		["g7_container_misc"] = true,
		["g7_container_clot"] = true,
		["g7_container_soul"] = true,
		["g7_container_lock"] = true,
		["g7_container_ingr"] = true,
		["g7_container_weap"] = true,
		["g7_container_repa"] = true,
		["g7_container_book"] = true,
		["g7_container_alch"] = true,
		["g7_container_scrl"] = true,
		["g7_container_ammo"] = true,
		["g7_container_armo"] = true,
	},
	-- this blacklist used to be called `destroy_blacklist`
	organic = {
		-- vanilla stuff
		["barrel_01_ahnassi_drink"] = true,
		["barrel_01_ahnassi_food"] = true,
		["com_chest_02_mg_supply"] = true,
		["com_chest_02_fg_supply"] = true,

		-- tamriel rebuilt
		["t_mwcom_furn_ch2fguild"] = true,
		["t_mwcom_furn_ch2mguild"] = true,
		["tr_com_sack_02_i501_mry"] = true,
		["tr_i3-295-de_p_drinks"] = true,
		["tr_i3-672_de_rm_deskalc"] = true,
		["tr_m2_com_sack_i501_bg"] = true,
		["tr_m2_com_sack_i501_sl"] = true,
		["tr_m2_com_sack_i501_ww"] = true,
		["tr_m2_q_27_fgchest"] = true,
		["tr_m2_q_29_fgchest"] = true,
		["tr_m3_i395_sack_local1"] = true,
		["tr_m3_ingchest_i3-390-i"] = true,
		["tr_m3_oe_anjzhirra_sack"] = true,
		["tr_m3_soil_i3-390-ind"] = true,

		-- unique items
		["urn_ash_lyngas00_unique"] = true,
		["bottle_unique"] = true,
		["urn_ash_brinne00_unique"] = true,
		["de_r_chest_irano_unique"] = true,
		["com_chest_tohan_unique"] = true,
		["flora_treestump_unique"] = true,
		["chest_clawfang_unique"] = true,
		["urn_ash_nan00_unique"] = true,
		["crate_02_mead_unique"] = true,
	},
};

---@class herbert.MQL.config.advanced
local advanced = {
	v_dist = 75,
	-- scroll wheel
	sw_claim = true,
	sw_priority = 400,
	-- arrow keys
	ak_claim = true,
	ak_priority = 400,

	-- other keys
	keydown_priority = 400,
	mousedown_priority = 400,

	-- other buttons
	activate_key_priority = 400,
	custom_priority = 400,
	take_all_priority = 400,

	-- other priority settings
	activate_event_priority = 9999999,
	ui_object_tooltip_priority = 9999999,
	load_priority = 1000,
	menu_entered_priority = 1000,
	cell_changed_priority = 1000,
	simulate_priority = 10,
	dialogue_filtered_priority = 10,
};

-- this records various compatibility information
---@class herbert.MQL.config.compat
local compat = {

	ac = false, -- animated containers

	-- this records whether Graphic Herbalism was ever installed.
	-- used for changing config settings whenever GH is first installed
	gh_history = defns.misc.gh.never, ---@type herbert.MQL.defns.misc.gh

	-- this records whether Graphic Herbalism is currently installed.
	-- used to properly load the GH blacklist, and make sure certain config settings aren't set improperly
	gh_current = defns.misc.gh.never, ---@type herbert.MQL.defns.misc.gh

	-- is "Just the Tooltip" installed?
	ttip = false,

	-- is "Buying Game" installed?
	bg = false,

	bxp = false,
};

---@class herbert.MQL.config
---@field log_level mwseLogger.logLevel
---@field version string?
local default = {
	livecoding = false,

	-- =========================================================================
	-- GENERAL SETTINGS
	-- =========================================================================
	take_nearby_dist = 600,
	take_nearby_allow_theft = true,
	sneak_to_steal = true,

	-- should scripted containers be shown?
	show_scripted = defns.show_scripted.prefix, ---@type herbert.MQL.defns.show_scripted

	-- key bindings
	log_level = mwse.logLevel.info,
	-- general = general,

	UI = UI,
	keys = keys,
	reg = reg,
	-- =========================================================================
	-- CONTAINER SPECIFIC SETTINGS
	-- =========================================================================
	dead = dead,
	inanimate = inanimate,
	pickpocket = pickpocket,
	organic = organic,
	training = training,
	barter = barter,
	services = services,
	blacklist = blacklist,
	advanced = advanced,
	compat = compat,
}

return default
