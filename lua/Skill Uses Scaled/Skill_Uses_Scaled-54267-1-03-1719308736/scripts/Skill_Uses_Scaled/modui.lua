-- In a player script
local storage  = require('openmw.storage')
local settings = require('openmw.interfaces').Settings
local async    = require('openmw.async')
local ui       = require('openmw.ui')
local Dt       = require('scripts.Skill_Uses_Scaled.data')

local function num_range(min, max, step) -- " Why have I done this "
	if math.abs(step) < 0.0001 then
		print('SUS: step must not be between -0.0001 and 0.0001')
		return nil
	end
	local result = {}
	local digits = { tostring(step):find('%.(%d*)') }
	if not digits[3] then digits[3] = '' end
	local newdigits = '%.' .. #tostring(digits[3]) .. 'f'
	for i = min, max, step do table.insert(result, 0 + string.format(newdigits, tostring(i))) end
	return result
end

local function array_concat(array, ...)
	for _, t in ipairs({ ... }) do
		for _, v in ipairs(t) do table.insert(array, v) end
	end
	return array
end

local function makeKeyEnum(keys)
	local result = {}
	for _, key in ipairs(keys) do result[key] = true end
	return result
end

local function edit_args(base, changes)
	for k, v in pairs(changes) do base[k] = v end
	return base
end

local function get(svar) -- s in svar means serializable | Recursions WILL stack overflow :D
	if type(svar) ~= 'table' then
		return svar
	else
		local deepcopy = {}
		for _key, _value in pairs(svar) do deepcopy[_key] = get(_value) end
		return deepcopy
	end
end

local Mui = {}

Mui.presets = {
	custom = {},
	default = {
		Base_Action_Value          = 0.3,
		Global_Multiplier          = 1,
		Scaling_Multiplier         = 1,
		Magicka_to_XP              = 12,
		MP_Refund_Skill_Offset     = 15,
		MP_Refund_Armor_mult       = 0.5,
		MP_Refund_Max_Percent      = 50,
		toggle_refund              = false,
		toggle_magic               = true,
		alteration                 = true,
		conjuration                = true,
		destruction                = true,
		illusion                   = true,
		mysticism                  = true,
		restoration                = true,
		Physical_Damage_to_XP      = 20,
		toggle_h2h_str             = true,
		HandToHand_Strength        = 40,
		toggle_physical            = true,
		axe                        = true,
		bluntweapon                = true,
		longblade                  = true,
		shortblade                 = true,
		spear                      = true,
		marksman                   = true,
		handtohand                 = true,
		Armor_Damage_To_XP         = 9,
		Block_Damage_To_XP         = 9,
		toggle_armor               = true,
		heavyarmor                 = true,
		mediumarmor                = true,
		lightarmor                 = true,
		block                      = true,
		Unarmored_Armor_Mult       = 0.5,
		Unarmored_Start            = 3,
		Unarmored_Min              = 0,
		Unarmored_Decay_Time       = 30,
		--Unarmored_Beast_Races      = 6     ,
		unarmored                  = true,
		Acrobatics_Start           = 1.75,
		Acrobatics_Decay_Time      = 6,
		Acrobatics_Encumbrance_Max = 0.5,
		Acrobatics_Encumbrance_Min = 1.5,
		acrobatics                 = true,
		Athletics_Start            = 0.5,
		Athletics_Marathon         = 2,
		Athletics_Decay_Time       = 180,
		Athletics_No_Move_Penalty  = 0.01,
		Athletics_Encumbrance_Max  = 1.5,
		Athletics_Encumbrance_Min  = 0.5,
		athletics                  = true,
		Security_Lock_Points_To_XP = 20,
		Security_Trap_Points_To_XP = 20,
		security                   = true,
		SUS_DEBUG                  = false,
		SUS_VERBOSE                = true,
	}
}

Mui.SKILLS_MAP = makeKeyEnum(Dt.SKILLS)
Mui.toggles = {
	toggle_physical = { 'axe', 'bluntweapon', 'longblade', 'shortblade', 'spear', 'marksman', 'handtohand' }, --1~7
	toggle_magic    = { 'alteration', 'conjuration', 'destruction', 'illusion', 'mysticism', 'restoration' }, --8~13
	toggle_armor    = { 'heavyarmor', 'lightarmor', 'mediumarmor', 'block' },                                --14~17
	--toggle_refund     = {'MP_Refund_Skill_Offset', 'MP_Refund_Armor_mult', 'MP_Refund_Max_Percent'}
}

Mui.settingsGroups = {}
function addSettingsGroup(name)
	local groupid = "Settings_SUS_" .. name
	Mui[groupid] = {}
	storage.playerSection(groupid):reset()
	table.insert(Mui.settingsGroups, groupid)
end

settings.registerPage {
	key         = 'susconfig',
	l10n        = 'Skill_Uses_Scaled',
	name        = 'Skill Uses Scaled',
	description = 'Configure and toggle XP scaling based on the gameplay value of each skill use.\n' ..
			' All skills are configurable and can be toggled individually.\n' ..
			' Skills with similar behaviour are grouped together, for clarity and convenience.',
}

addSettingsGroup('global')
settings.registerGroup {
	key              = 'Settings_SUS_global',
	name             = 'Global Modifiers',
	description      = 'These settings change all SUS scalers by the same amount, use them to change how close to (or far from) vanilla your XP gains will be.',
	page             = 'susconfig',
	order            = 1,
	l10n             = 'Skill_Uses_Scaled',
	permanentStorage = false,
	settings         = {
		{
			key         = 'Global_Multiplier',
			name        = 'Global XP Rate',
			description = 'ALL XP gains are multiplied by this number. Use this to make leveling slower overall and stretch the early-game.. or do the opposite if you want to quickly level into late-game.',
			renderer    = 'select',
			argument    = { l10n = 'Skill_Uses_Scaled', items = array_concat(num_range(0, 1, .1), num_range(1.2, 3, .2)) },
			default     = Mui.presets.default.Global_Multiplier,
		}, {
		key         = 'Base_Action_Value',
		name        = 'Base Action Value',
		description = 'How many flat skill uses worth of XP are added to the scaled values. 1 means one Vanilla skill use.\n' ..
				' This lets you gain a baseline amount of XP regardless of how inneffective your action was, to represent the value of repetition alone.',
		renderer    = 'select',
		argument    = { l10n = 'Skill_Uses_Scaled', items = array_concat(num_range(0, 1, .1), num_range(1.2, 3, .2)) },
		default     = Mui.presets.default.Base_Action_Value,
	}, {
		key         = 'Scaling_Multiplier',
		name        = 'Scaling Multiplier',
		description = 'Use this if you like how scaling works and would prefer to tone it down a little, but don\'t want to change each scaler independently.\n' ..
				' This does not affect the XP gained from the previous setting, use them together to determine how close your experience is to Vanilla.',
		renderer    = 'select',
		argument    = { l10n = 'Skill_Uses_Scaled', items = array_concat(num_range(0, 1, .1), num_range(1.2, 3, .2)) },
		default     = Mui.presets.default.Scaling_Multiplier,
	}
	}
}
addSettingsGroup('magic')
Mui.Settings_SUS_magic.args = {
	MP_Refund_Skill_Offset = { l10n = 'Skill_Uses_Scaled', items = array_concat(num_range(1, 25, 1), num_range(30, 100, 5)), disabled = true },
	MP_Refund_Armor_mult   = { l10n = 'Skill_Uses_Scaled', items = array_concat(num_range(.1, .9, .1), num_range(1, 3, 0.1)), disabled = true },
	MP_Refund_Max_Percent  = { l10n = 'Skill_Uses_Scaled', items = array_concat(num_range(1, 25, 1), num_range(30, 100, 5)), disabled = true },
}
settings.registerGroup {
	key              = 'Settings_SUS_magic',
	name             = 'Magic Schools',
	description      = 'Successful spell casts will give XP proportional to the spell\'s cost.\n' ..
			' Optional, but recommended, are the provided refund/penalty mechanics.',
	page             = 'susconfig',
	order            = 2,
	l10n             = 'Skill_Uses_Scaled',
	permanentStorage = false,
	settings         = {
		{
			key         = 'Magicka_to_XP',
			name        = 'Magicka to XP',
			description = 'How much spell cost is equivalent to one vanilla skill use.',
			renderer    = 'select',
			argument    = { l10n = 'Skill_Uses_Scaled', items = array_concat(num_range(1, 25, 1), num_range(30, 100, 5)) },
			default     = Mui.presets.default.Magicka_to_XP,
		}, {
		key         = 'toggle_refund',
		name        = 'Dynamic Spell Cost',
		description = 'Toggling this on will make your spell\'s cost change depending on your gear and skill level, akin to spellcasting in Oblivion and Skyrim. High skill and no armor will result in a refund, while heavy armor and low skill will incur a penalty. Only applies on successful spellcasts.',
		renderer    = 'checkbox',
		default     = Mui.presets.default.toggle_refund,
	}, {
		key         = 'MP_Refund_Skill_Offset',
		name        = 'Skill Offset',
		description = 'Magic skill is reduced by [This] for the calculation of Dynamic Spell Cost',
		renderer    = 'select',
		argument    = { l10n = 'Skill_Uses_Scaled', items = array_concat(num_range(1, 25, 1), num_range(30, 100, 5)), disabled = true },
		default     = Mui.presets.default.MP_Refund_Skill_Offset,
	}, {
		key         = 'MP_Refund_Armor_mult',
		name        = 'Armor Penalty Offset',
		description = 'Magic skill is further reduced by [This]x[Equipped Armor Weight].\n' ..
				' If after all offsets your skill is still positive, you\'ll get a portion of the spell refunded, reducing spell cost. If the resulting number is negative, the "refund" will take extra magicka away instead, increasing spell cost.',
		renderer    = 'select',
		argument    = { l10n = 'Skill_Uses_Scaled', items = array_concat(num_range(.1, .9, .1), num_range(1, 3, 0.1)), disabled = true },
		default     = Mui.presets.default.MP_Refund_Armor_mult,
	}, {
		key         = 'MP_Refund_Max_Percent',
		name        = 'Maximum Refund Percentage',
		description = 'Refund will never surpass [This]% of original spell cost. This also affects cost increases from skill offset and armor weight, when applicable.',
		renderer    = 'select',
		argument    = { l10n = 'Skill_Uses_Scaled', items = array_concat(num_range(1, 25, 1), num_range(30, 100, 5)), disabled = true },
		default     = Mui.presets.default.MP_Refund_Max_Percent,
	},
		{ key = 'toggle_magic', name = 'Enable XP Scaling for this Skill Group:', renderer = 'checkbox', default = Mui.presets.default.toggle_magic },
		{ key = 'alteration',   name = 'Alteration',                              renderer = 'checkbox', default = Mui.presets.default.alteration },
		{ key = 'conjuration',  name = 'Conjuration',                             renderer = 'checkbox', default = Mui.presets.default.conjuration },
		{ key = 'destruction',  name = 'Destruction',                             renderer = 'checkbox', default = Mui.presets.default.destruction },
		{ key = 'illusion',     name = 'Illusion',                                renderer = 'checkbox', default = Mui.presets.default.illusion },
		{ key = 'mysticism',    name = 'Mysticism',                               renderer = 'checkbox', default = Mui.presets.default.mysticism },
		{ key = 'restoration',  name = 'Restoration',                             renderer = 'checkbox', default = Mui.presets.default.restoration },
	},
}

addSettingsGroup('physical')
Mui.Settings_SUS_physical.args = {
	HandToHand_Strength = { l10n = 'Skill_Uses_Scaled', items = array_concat(num_range(10, 100, 5)), disabled = false },
}
settings.registerGroup {
	key              = 'Settings_SUS_physical',
	name             = 'Weapons and Hand To Hand',
	description      = 'Successful attacks will give XP proportional to their damage.\n' ..
			'Damaging enchantments on weapons are NOT counted, only the weapon\'s own damage (modified by Strength and Condition).',
	page             = 'susconfig',
	order            = 3,
	l10n             = 'Skill_Uses_Scaled',
	permanentStorage = false,
	settings         = {
		{
			key         = 'Physical_Damage_to_XP',
			name        = 'Damage to XP',
			description = 'How much outgoing damage is equivalent to one vanilla skill use.\n' ..
					' Not affected by enemy Armor Rating or by game difficulty.',
			renderer    = 'select',
			argument    = { l10n = 'Skill_Uses_Scaled', items = array_concat(num_range(1, 25, 1), num_range(30, 100, 5)) },
			default     = Mui.presets.default.Physical_Damage_to_XP,
		}, {
		key      = 'toggle_h2h_str',
		name     = 'Factor Strength into Hand to Hand',
		renderer = 'checkbox',
		default  = Mui.presets.default.toggle_h2h_str,
	}, {
		key         = 'HandToHand_Strength',
		name        = 'H2H Strength Ratio',
		description = 'H2H damage is multiplied by [STR]/[This] when calculating XP.\n' ..
				' Default is same as OpenMW\'s.\n' ..
				' Does not affect Werewolves, since (due to how Vanilla Morrowind works) you don\'t get XP from attacking while in Werewolf form.',
		renderer    = 'select',
		argument    = { l10n = 'Skill_Uses_Scaled', items = array_concat(num_range(10, 100, 5)) },
		default     = Mui.presets.default.HandToHand_Strength,
	},
		{ key = 'toggle_physical', name = 'Enable XP Scaling for this Skill Group:', renderer = 'checkbox', default = Mui.presets.default.toggle_physical },
		{ key = 'axe',             name = 'Axe',                                     renderer = 'checkbox', default = Mui.presets.default.axe },
		{ key = 'bluntweapon',     name = 'Blunt Weapon',                            renderer = 'checkbox', default = Mui.presets.default.bluntweapon },
		{ key = 'longblade',       name = 'Long Blade',                              renderer = 'checkbox', default = Mui.presets.default.longblade },
		{ key = 'shortblade',      name = 'Short Blade',                             renderer = 'checkbox', default = Mui.presets.default.shortblade },
		{ key = 'spear',           name = 'Spear',                                   renderer = 'checkbox', default = Mui.presets.default.spear },
		{ key = 'marksman',        name = 'Marksman',                                renderer = 'checkbox', default = Mui.presets.default.marksman },
		{ key = 'handtohand',      name = 'Hand To Hand',                            renderer = 'checkbox', default = Mui.presets.default.handtohand },
	},
}

addSettingsGroup('armor')
settings.registerGroup {
	key              = 'Settings_SUS_armor',
	name             = 'Armor',
	description      = 'Hits taken will provide XP proportional to incoming damage.\n' ..
			' Like vanilla, this is NOT triggered by spells or magic effects, nor is it affected by any magic-related damage.',
	page             = 'susconfig',
	order            = 4,
	l10n             = 'Skill_Uses_Scaled',
	permanentStorage = false,
	settings         = {
		{
			key         = 'Armor_Damage_To_XP',
			name        = 'Damage to XP',
			description = 'How much incoming damage is equivalent to one vanilla skill use.\n' ..
					' Not affected by your Armor Rating or by game difficulty.',
			renderer    = 'select',
			argument    = { l10n = 'Skill_Uses_Scaled', items = array_concat(num_range(1, 25, 1), num_range(30, 100, 5)) },
			default     = Mui.presets.default.Armor_Damage_To_XP,
		}, {
		key         = 'Block_Damage_To_XP',
		name        = 'Block - Damage to XP',
		description = 'How much blocked damage is equivalent to one vanilla skill use.\n' ..
				' Remember that blocked hits are prevented completely.',
		renderer    = 'select',
		argument    = { l10n = 'Skill_Uses_Scaled', items = array_concat(num_range(1, 25, 1), num_range(30, 100, 5)) },
		default     = Mui.presets.default.Block_Damage_To_XP,
	},
		{ key = 'toggle_armor', name = 'Enable Scaling for this Skill Group:', renderer = 'checkbox', default = Mui.presets.default.toggle_armor },
		{ key = 'heavyarmor',   name = 'Heavy Armor',                          renderer = 'checkbox', default = Mui.presets.default.heavyarmor },
		{ key = 'mediumarmor',  name = 'Medium Armor',                         renderer = 'checkbox', default = Mui.presets.default.mediumarmor },
		{ key = 'lightarmor',   name = 'Light Armor',                          renderer = 'checkbox', default = Mui.presets.default.lightarmor },
		{ key = 'block',        name = 'Block',                                renderer = 'checkbox', default = Mui.presets.default.block },
	},
}

addSettingsGroup('unarmored')
settings.registerGroup {
	key              = 'Settings_SUS_unarmored',
	name             = 'Unarmored',
	description      = 'Unarmored XP uses hit count instead of incoming damage, frontloading most of your progress into the first few hits of every encounter.\n' ..
			' It was made this way for technical reasons, but the result is a good and viable defensive option for characters that can\'t take enough hits to justify an Armor skill, but would still like to enjoy a modicum of protection from weaker enemies.',
	page             = 'susconfig',
	order            = 5,
	l10n             = 'Skill_Uses_Scaled',
	permanentStorage = false,
	settings         = {
		{
			key         = 'Unarmored_Start',
			name        = 'Starting Multiplier',
			description = 'The first hit you take is equivalent to [This] many vanilla skill uses.\n' ..
					' This multiplier is drastically reduced on each consecutive hit.',
			renderer    = 'select',
			argument    = { l10n = 'Skill_Uses_Scaled', items = array_concat(num_range(.5, 5, .25), num_range(6, 15, 1)) },
			default     = Mui.presets.default.Unarmored_Start,
		}, {
		key         = 'Unarmored_Decay_Time',
		name        = 'Penalty Timer',
		description = 'The Starting Multiplier is restored in [This] many seconds.\n' ..
				' The higher this is, the harder it is to keep XP rates high in long battles',
		renderer    = 'select',
		argument    = { l10n = 'Skill_Uses_Scaled', items = array_concat(num_range(1, 25, 1), num_range(30, 100, 5), num_range(120, 600, 20)) },
		default     = Mui.presets.default.Unarmored_Decay_Time,
	}, {
		key         = 'Unarmored_Min',
		name        = 'Minimum Multiplier',
		description = 'The more you get hit, the closer the XP multiplier gets to [This] many vanilla skill uses.',
		renderer    = 'select',
		argument    = { l10n = 'Skill_Uses_Scaled', items = array_concat(num_range(-1, 1, .1), num_range(1.25, 5, .25)) },
		default     = Mui.presets.default.Unarmored_Min,
	}, {
		key         = 'Unarmored_Armor_Mult',
		name        = 'Armor Weight Penalty Multiplier',
		description = 'Weight of equipped armor will slow down unarmored XP gain. Weight is multiplied by [This] before being added to the XP formula.\n' ..
				' This mechanic further encourages using Unarmored either by itself or along light armor.',
		renderer    = 'select',
		argument    = { l10n = 'Skill_Uses_Scaled', items = array_concat(num_range(-1, 1, .1), num_range(1.25, 5, .25)) },
		default     = Mui.presets.default.Unarmored_Armor_Mult,
		--  },{
		--    key         = 'Unarmored_Beast_Races',
		--    name        = 'Armored Beast Bonus',
		--    description = 'When playing an Argonian or Khajiit, XP from hits to Head and Feet (if they are unarmored) will be multiplied by [This].\n'..
		--				' This bonus is meant to mitigate the Armor Rating penalty for beast characters that run full armor sets, and has no effect on beast characters that don\'t use armor.',
		--    renderer    = 'select',
		--    argument    = {l10n  = 'Skill_Uses_Scaled', items = array_concat(num_range(-1,1,.1), num_range(1.25,5,.25))},
		--    default     = 6,
	},
		{ key = 'unarmored', name = 'Enable scaling for Unarmored XP:', renderer = 'checkbox', default = Mui.presets.default.unarmored },
	},
}

addSettingsGroup('acrobatics')
settings.registerGroup {
	key              = 'Settings_SUS_acrobatics',
	name             = 'Acrobatics',
	description      = 'Gain more XP for making larger, slower jumps, and progress faster while carrying little weight.\n' ..
			' Jumping up slopes will still result in significant (albeit reduced) skill progress, while fall damage and calculated jumps will no longer lag massively behind.',
	page             = 'susconfig',
	order            = 6,
	l10n             = 'Skill_Uses_Scaled',
	permanentStorage = false,
	settings         = {
		{
			key         = 'Acrobatics_Start',
			name        = 'Starting Multiplier',
			description = 'The first jump you make is equivalent to [This] many vanilla skill uses.\n' ..
					' This multiplier is reduced on each consecutive jump.',
			renderer    = 'select',
			argument    = { l10n = 'Skill_Uses_Scaled', items = array_concat(num_range(.25, 5, .25), num_range(6, 15, 1)) },
			default     = Mui.presets.default.Acrobatics_Start,
		}, {
		key         = 'Acrobatics_Decay_Time',
		name        = 'Penalty Timer',
		description = 'The Starting Multiplier is restored in [This] many seconds. Increasing this number makes spam jumping even less valuable.',
		renderer    = 'select',
		argument    = { l10n = 'Skill_Uses_Scaled', items = array_concat(num_range(1, 25, 1), num_range(30, 100, 5), num_range(120, 600, 20)) },
		default     = Mui.presets.default.Acrobatics_Decay_Time,
	}, {
		key         = 'Acrobatics_Encumbrance_Min',
		name        = 'Low Encumbrance Bonus',
		description = 'At 0% carry weight, your skill progress will be multiplied by [this].',
		renderer    = 'select',
		argument    = { l10n = 'Skill_Uses_Scaled', items = array_concat(num_range(.25, 5, .25), num_range(6, 15, 1)) },
		default     = Mui.presets.default.Acrobatics_Encumbrance_Min,
	}, {
		key         = 'Acrobatics_Encumbrance_Max',
		name        = 'High Encumbrance Penalty',
		description = 'At 100% carry weight, your skill progress will be multiplied by [this].',
		renderer    = 'select',
		argument    = { l10n = 'Skill_Uses_Scaled', items = array_concat(num_range(.25, 5, .25), num_range(6, 15, 1)) },
		default     = Mui.presets.default.Acrobatics_Encumbrance_Max,
	},
		{ key = 'acrobatics', name = 'Enable scaling for Acrobatics XP:', renderer = 'checkbox', default = Mui.presets.default.acrobatics },
	},
}

addSettingsGroup('athletics')
settings.registerGroup {
	key              = 'Settings_SUS_athletics',
	name             = 'Athletics',
	description      = 'Gain more XP for running long periods of time, and progress faster while carrying heavy weights.\n' ..
			' Additionally, bad vanilla behaviour was fixed and you no longer gain athletics XP while jumping or falling (but you do gain XP while levitating).\n' ..
			' Bunnyhopping long distances is still a good training method, just not for raising Athletics.\n' ..
			' TLDR: If your legs are moving you\'re training athletics, otherwise you aren\'t.',
	page             = 'susconfig',
	order            = 7,
	l10n             = 'Skill_Uses_Scaled',
	permanentStorage = false,
	settings         = {
		{
			key         = 'Athletics_Start',
			name        = 'Starting Multiplier',
			description = 'Athletics XP is multiplied by a [Marathon Bonus]. This is the lowest it can get. \n' ..
					' Note that by default this is 0.5, meaning it cuts your XP in half when moving short distances and making long stops.',
			renderer    = 'select',
			argument    = { l10n = 'Skill_Uses_Scaled', items = array_concat(num_range(.25, 5, .25), num_range(6, 15, 1)) },
			default     = Mui.presets.default.Athletics_Start,
		}, {
		key         = 'Athletics_Decay_Time',
		name        = 'Marathon Timer',
		description = 'It takes [This] many seconds of continuous running or swimming to reach the Maximum Multiplier.\n' ..
				' It\'s increase and decrease are gradual, so you can stop for a few seconds and you won\'t lose your entire progress.',
		renderer    = 'select',
		argument    = { l10n = 'Skill_Uses_Scaled', items = array_concat(num_range(30, 100, 5), num_range(120, 600, 20), num_range(660, 1200, 60)) },
		default     = Mui.presets.default.Athletics_Decay_Time,
	}, {
		key         = 'Athletics_Marathon',
		name        = 'Maximum Multiplier',
		description = 'Athletics XP is multiplied by a [Marathon Bonus]. This is the highest it can get.',
		renderer    = 'select',
		argument    = { l10n = 'Skill_Uses_Scaled', items = array_concat(num_range(.25, 5, .25), num_range(6, 15, 1)) },
		default     = Mui.presets.default.Athletics_Marathon,
	}, {
		key         = 'Athletics_No_Move_Penalty',
		name        = 'No Movement Penalty',
		description = 'While not significantly moving (i.e, running or swimming into a wall), XP will be multiplied by [This].\n' ..
				' By default, it\'s low enough to make maxing the skill this way take very long, but still allows \'training\' AFK.',
		renderer    = 'select',
		argument    = { l10n = 'Skill_Uses_Scaled', items = array_concat(num_range(-1, -0.1, 0.1), num_range(-0.09, 0.09, 0.01), num_range(0.1, 1, 0.1)) },
		default     = Mui.presets.default.Athletics_No_Move_Penalty,
	}, {
		key         = 'Athletics_Encumbrance_Max',
		name        = 'High Encumbrance Bonus',
		description = 'At 100% carry weight, your skill progress will be multiplied by [this].',
		renderer    = 'select',
		argument    = { l10n = 'Skill_Uses_Scaled', items = array_concat(num_range(.25, 5, .25), num_range(6, 15, 1)) },
		default     = Mui.presets.default.Athletics_Encumbrance_Max,
	}, {
		key         = 'Athletics_Encumbrance_Min',
		name        = 'Low Encumbrance Penalty',
		description = 'At 0% carry weight, your skill progress will be multiplied by [this].',
		renderer    = 'select',
		argument    = { l10n = 'Skill_Uses_Scaled', items = array_concat(num_range(.25, 5, .25), num_range(6, 15, 1)) },
		default     = Mui.presets.default.Athletics_Encumbrance_Min,
	},
		{ key = 'athletics', name = 'Enable scaling for Athletics XP:', renderer = 'checkbox', default = Mui.presets.default.athletics },
	},
}

addSettingsGroup('security')
settings.registerGroup {
	key              = 'Settings_SUS_security',
	name             = 'Security',
	description      = 'Successful lockpicking will grant XP based on the difficulty of the lock opened.\n' ..
			' Successful probing will grant XP based on the difficulty of the trap disarmed.',
	page             = 'susconfig',
	order            = 8,
	l10n             = 'Skill_Uses_Scaled',
	permanentStorage = false,
	settings         = {
		{
			key         = 'Security_Lock_Points_To_XP',
			name        = 'Lock Difficulty to XP',
			description = 'How many lock points are equivalent to one vanilla skill use.\n' ..
					' Not affected by tool quality.',
			renderer    = 'select',
			argument    = { l10n = 'Skill_Uses_Scaled', items = array_concat(num_range(1, 25, 1), num_range(30, 100, 5)) },
			default     = Mui.presets.default.Security_Lock_Points_To_XP,
		}, {
		key         = 'Security_Trap_Points_To_XP',
		name        = 'Trap Difficulty to XP',
		description = 'How many trap points are equivalent to one vanilla skill use.\n' ..
				' Not affected by tool quality.\n' ..
				' Note that trap difficulty is independent from lock difficulty, and directly based on the trap spell\'s magic cost. Hard traps are generally dangerous, and easy ones mostly harmless.',
		renderer    = 'select',
		argument    = { l10n = 'Skill_Uses_Scaled', items = array_concat(num_range(1, 25, 1), num_range(30, 100, 5)) },
		default     = Mui.presets.default.Security_Trap_Points_To_XP,
	},
		{ key = 'security', name = 'Enable scaling for Security XP:', renderer = 'checkbox', default = Mui.presets.default.security },
	},
}

--addSettingsGroup('presets')
--settings.registerGroup {
--  key              = 'Settings_SUS_presets',
--  name             = 'Settings Presets',
--  description      = 'Pick from available config presets, or save your current settings as a new preset for later use.',
--  page             = 'susconfig',
--  order            = 0,
--  l10n             = 'Skill_Uses_Scaled',
--  permanentStorage = true,
--  settings         = {
--	--{
--  --  key         = 'Security_Trap_Points_To_XP',
--  --  name        = 'Trap Difficulty to XP',
--  --  description = 'How many trap points are equivalent to one vanilla skill use.\n'..
--								' Not affected by tool quality.\n'..
--								' Note that trap difficulty is independent from lock difficulty, and directly based on the trap spell\'s magic cost. Hard traps are generally dangerous, and easy ones mostly harmless.',
--  --  renderer    = 'select',
--  --  argument    = {l10n  = 'Skill_Uses_Scaled', items = array_concat(num_range(1,25,1), num_range(30, 100, 5))},
--  --  default     = Mui.presets.default.Security_Trap_Points_To_XP,
--  --},{
--  --  key         = 'Security_Trap_Points_To_XP',
--  --  name        = 'Trap Difficulty to XP',
--  --  description = 'How many trap points are equivalent to one vanilla skill use.\n'..
--								' Not affected by tool quality.\n'..
--								' Note that trap difficulty is independent from lock difficulty, and directly based on the trap spell\'s magic cost. Hard traps are generally dangerous, and easy ones mostly harmless.',
--  --  renderer    = 'select',
--  --  argument    = {l10n  = 'Skill_Uses_Scaled', items = array_concat(num_range(1,25,1), num_range(30, 100, 5))},
--  --  default     = Mui.presets.default.Security_Trap_Points_To_XP,
--  --},
--  },
--}

addSettingsGroup('DEBUG')
settings.registerGroup {
	key              = 'Settings_SUS_DEBUG',
	name             = 'Info & Debug',
	description      = '',
	page             = 'susconfig',
	order            = 9,
	l10n             = 'Skill_Uses_Scaled',
	permanentStorage = false,
	settings         = {
		{
			key         = 'SUS_DEBUG',
			name        = 'Enable Debug Messages',
			description = 'Print information on every skill use about XP gained (and about this mod\'s multipliers) to the in-game F10 console.\n' ..
					' Useful for anyone wishing to hone in their configuration, or to get a general idea of this mod\'s (and vanilla morrowind\'s) XP mechanics.',
			renderer    = 'checkbox',
			default     = Mui.presets.default.SUS_DEBUG,
		}, {
		key         = 'SUS_VERBOSE',
		name        = 'Use Verbose Messaging',
		description = 'Show fancy messageboxes directly to your screen instead of to the F10 console.\n' ..
				' Enabled by Default.\n' ..
				' Whether this is more or less intrusive than the F10 window is a matter of opinion.. disable it if you prefer the console.',
		renderer    = 'checkbox',
		default     = Mui.presets.default.SUS_VERBOSE,
	},
	},
}

Mui.custom_groups = {
	toggle_refund  = true,
	toggle_h2h_str = true,
}
Mui.custom = function(group, key)
	if key == 'toggle_refund' then
		local args   = Mui.Settings_SUS_magic.args
		local offset = 'MP_Refund_Skill_Offset'
		local mult   = 'MP_Refund_Armor_mult'
		local max    = 'MP_Refund_Max_Percent'
		if Mui[group].section:get(key) then
			settings.updateRendererArgument(group, offset, edit_args(args[offset], { disabled = false }))
			settings.updateRendererArgument(group, mult, edit_args(args[mult], { disabled = false }))
			settings.updateRendererArgument(group, max, edit_args(args[max], { disabled = false }))
		else
			settings.updateRendererArgument(group, offset, edit_args(args[offset], { disabled = true }))
			settings.updateRendererArgument(group, mult, edit_args(args[mult], { disabled = true }))
			settings.updateRendererArgument(group, max, edit_args(args[max], { disabled = true }))
		end
	elseif key == 'toggle_h2h_str' then
		local args  = Mui.Settings_SUS_physical.args
		local ratio = 'HandToHand_Strength'
		if Mui[group].section:get(key) then
			settings.updateRendererArgument(group, ratio, edit_args(args[ratio], { disabled = false }))
		else
			settings.updateRendererArgument(group, ratio, edit_args(args[ratio], { disabled = true }))
		end
	end
end

Mui.update = async:callback(function(group, key)
	if key == nil then print(group .. ': nil key') end
	if (not group) or (not key) then
		return
	elseif Mui.toggles[key] then
		local toggled = Mui[group].section:get(key)
		for _, setting in ipairs(Mui.toggles[key]) do
			settings.updateRendererArgument(group, setting, { disabled = not toggled })
			if (not toggled) and Mui.getSetting("SUS_DEBUG") then
				print(setting ..
					': ' .. tostring(Mui[group].section:get(setting)))
			end
		end
		if Mui.getSetting("SUS_DEBUG") then print(key .. ': ' .. tostring(Mui[group].section:get(key))) end
	elseif Mui.custom_groups[key] then
		Mui.custom(group, key)
	else
		if type(Mui[group].section:get(key)) == 'number' then
			if Mui.getSetting("SUS_DEBUG") then print(key .. ': ' .. string.format('%.1f', Mui[group].section:get(key))) end
		else
			if Mui.getSetting("SUS_DEBUG") then print(key .. ': ' .. tostring(Mui[group].section:get(key))) end
		end
	end
	--Mui.savePreset('current')
end)

Mui.GROUPS_MAP = {}
for _, groupid in ipairs(Mui.settingsGroups) do
	Mui[groupid].section = storage.playerSection(groupid)
	Mui[groupid].section:subscribe(Mui.update)
	for key in pairs(Mui[groupid].section:asTable()) do
		Mui.GROUPS_MAP[key] = Mui[groupid].section
	end
end

Mui.getSetting = function(settingid)
	return Mui.GROUPS_MAP[settingid]:get(settingid)
end
Mui.savePreset = function(name)
	local preset = {}
	for _, groupid in ipairs(Mui.settingsGroups) do
		for k, v in pairs(Mui[groupid].section:asTable()) do
			preset[k] = v
			if Mui.getSetting("SUS_DEBUG") then print('Saving... ' .. k .. ': ' .. tostring(v)) end
		end
	end
	storage.playerSection("SUS_Presets"):set(name, preset)
	storage.playerSection("SUS_Presets"):setLifeTime(storage.LIFE_TIME.Persistent)
end
Mui.loadPreset = function(name)
	local target_as_table = storage.playerSection("SUS_Presets"):asTable()[name]
	if target_as_table == nil then
		if Mui.getSetting("SUS_DEBUG") then
			print("[Loading defaults]")
		end
		target_as_table = Mui.presets.default
	end
	for _, groupid in ipairs(Mui.settingsGroups) do
		for k, v in pairs(Mui[groupid].section:asTable()) do
			if target_as_table[k] ~= nil then
				Mui[groupid].section:set(k, target_as_table[k])
				if Mui.getSetting("SUS_DEBUG") then
					print('SUS - Loading preset [' ..
						name .. '] | ' .. k .. ' -> ' .. tostring(target_as_table[k]))
				end
			end
		end
	end
end

--  Saving:
-- • Default "standard" preset = initCfg
-- • onLoad, Cfg = Mui.Storage[Settings_SUS_Current].section:getAll
-- • onLoad, loadMissingSettings(Cfg, initCfg)
-- • onSave, Settings_SUS_Current].section = Cfg
-- Custom presets
-- • on preset save:
return Mui
