local I = require('openmw.interfaces')
local storage = require("openmw.storage")


local function initSettingsPlayer()
    I.Settings.registerGroup({
		key = 'Settings_01_Is_Enabled_Player',
		page = 'TotalRegenerationControlPlayer',
		l10n = 'TotalRegenerationControl',
		name = "Is_Enabled",
		permanentStorage = true,
		settings = {
			{
				key = 'override_settings_enabled',
				name = 'override_settings_enabled_name',
                description = 'override_settings_enabled_description',
				default = false,
				renderer = 'checkbox',
			},
		}
	})


	I.Settings.registerGroup({
		key = 'Settings_02_Magicka_Player',
		page = 'TotalRegenerationControlPlayer',
		l10n = 'TotalRegenerationControl',
		name = "Magicka",
		description = 'Magicka_description',
		permanentStorage = true,
		settings = {
			{
				key = 'willpower',
				name = 'willpower_name',
				default = 1, -- %
				renderer = 'number',
			},
			{
				key = 'intelligence',
				name = 'intelligence_name',
				default = 0, -- %
				renderer = 'number',
			},
			{
				key = 'endurance',
				name = 'endurance_name',
				default = 0, -- %
				renderer = 'number',
			},
			{
				key = 'strength',
				name = 'strength_name',
				default = 0, -- %
				renderer = 'number',
			},
			{
				key = 'agility',
				name = 'agility_name',
				default = 0, -- %
				renderer = 'number',
			},
			{
				key = 'speed',
				name = 'speed_name',
				default = 0, -- %
				renderer = 'number',
			},
			{
				key = 'personality',
				name = 'personality_name',
				default = 0, -- %
				renderer = 'number',
			},
			{
				key = 'luck',
				name = 'luck_name',
				default = 0, -- %
				renderer = 'number',
			},
			{
				key = 'delay_resource',
				name = 'delay_resource_name',
				description = 'delay_resource_description',
				default = 5,
				renderer = 'number',
				argument = {
					min = 0,
				},
			},
			{
				key = 'delay_hp_for_magicka',
				name = 'delay_hp_for_magicka_name',
				description = 'delay_hp_for_magicka_description',
				default = 10,
				renderer = 'number',
				argument = {
					min = 0,
				},
			},
			{
				key = 'delay_strength',
				name = 'delay_strength_name',
				description = 'delay_strength_description',
				default = 70,
				renderer = 'number',
			},
			{
				key = 'base_regen',
				name = 'base_regen_name',
				default = 0,
				renderer = 'number',
			},
			{
				key = 'regen_by_level',
				name = 'regen_by_level_name',
				description = 'regen_by_level_description',
				default = 0,
				renderer = 'number',
			},
			{
				key = 'regen_max_level',
				name = 'regen_max_level_name',
				description = 'regen_max_level_description',
				default = 10000,
				renderer = 'number',
				argument = {
					min = 0,
				},
			},
			{
				key = 'regen_cap',
				name = 'regen_cap_name',
				description = 'regen_cap_description',
				default = 10000,
				renderer = 'number',
				argument = {
					min = 0,
				},
			},
		},
	})

	I.Settings.registerGroup({
		key = 'Settings_03_Magicka_Threshold_Player',
		page = 'TotalRegenerationControlPlayer',
		l10n = 'TotalRegenerationControl',
		name = "Magicka_Threshold",
		description = 'Magicka_Threshold_description',
		permanentStorage = true,
		settings = {
			{
				key = 'willpower',
				name = 'willpower_name',
				default = 0, -- %
				renderer = 'number',
			},
			{
				key = 'intelligence',
				name = 'intelligence_name',
				default = 10, -- %
				renderer = 'number',
			},
			{
				key = 'endurance',
				name = 'endurance_name',
				default = 0, -- %
				renderer = 'number',
			},
			{
				key = 'strength',
				name = 'strength_name',
				default = 0, -- %
				renderer = 'number',
			},
			{
				key = 'agility',
				name = 'agility_name',
				default = 0, -- %
				renderer = 'number',
			},
			{
				key = 'speed',
				name = 'speed_name',
				default = 0, -- %
				renderer = 'number',
			},
			{
				key = 'personality',
				name = 'personality_name',
				default = 0, -- %
				renderer = 'number',
			},
			{
				key = 'luck',
				name = 'luck_name',
				default = 2, -- %
				renderer = 'number',
			},
			{
				key = 'threshold',
				name = 'threshold_name',
				default = 0,
				renderer = 'number',
			},
			{
				key = 'threshold_by_lvl',
				name = 'threshold_by_lvl_name',
				description = 'threshold_by_lvl_description',
				default = 0,
				renderer = 'number',
			},
			{
				key = 'threshold_max_lvl',
				name = 'threshold_max_lvl_name',
				description = 'threshold_max_lvl_description',
				default = 10000,
				renderer = 'number',
				argument = {
					min = 0,
				},
			},
			{
				key = 'threshold_cap',
				name = 'threshold_cap_name',
				description = 'threshold_cap_description',
				default = 10000,
				renderer = 'number',
				argument = {
					min = 0,
				},
			},
		},
	})

	I.Settings.registerGroup({
		key = 'Settings_04_Health_Player',
		page = 'TotalRegenerationControlPlayer',
		l10n = 'TotalRegenerationControl',
		name = "Health",
		description = 'Health_description',
		permanentStorage = true,
		settings = {
			{
				key = 'willpower',
				name = 'willpower_name',
				default = 0, -- %
				renderer = 'number',
			},
			{
				key = 'intelligence',
				name = 'intelligence_name',
				default = 0, -- %
				renderer = 'number',
			},
			{
				key = 'endurance',
				name = 'endurance_name',
				default = 0.25, -- %
				renderer = 'number',
			},
			{
				key = 'strength',
				name = 'strength_name',
				default = 0, -- %
				renderer = 'number',
			},
			{
				key = 'agility',
				name = 'agility_name',
				default = 0, -- %
				renderer = 'number',
			},
			{
				key = 'speed',
				name = 'speed_name',
				default = 0, -- %
				renderer = 'number',
			},
			{
				key = 'personality',
				name = 'personality_name',
				default = 0, -- %
				renderer = 'number',
			},
			{
				key = 'luck',
				name = 'luck_name',
				default = 0, -- %
				renderer = 'number',
			},
			{
				key = 'delay_resource',
				name = 'delay_resource_name',
				description = 'delay_resource_description',
				default = 10,
				renderer = 'number',
				argument = {
					min = 0,
				},
			},
			{
				key = 'delay_strength',
				name = 'delay_strength_name',
				description = 'delay_strength_description',
				default = 90,
				renderer = 'number',
			},
			{
				key = 'base_regen',
				name = 'base_regen_name',
				default = 0,
				renderer = 'number',
			},
			{
				key = 'regen_by_level',
				name = 'regen_by_level_name',
				description = 'regen_by_level_description',
				default = 0,
				renderer = 'number',
			},
			{
				key = 'regen_max_level',
				name = 'regen_max_level_name',
				description = 'regen_max_level_description',
				default = 10000,
				renderer = 'number',
				argument = {
					min = 0,
				},
			},
			{
				key = 'regen_cap',
				name = 'regen_cap_name',
				description = 'regen_cap_description',
				default = 10000,
				renderer = 'number',
				argument = {
					min = 0,
				},
			},
		},
	})

	I.Settings.registerGroup({
		key = 'Settings_05_Health_Threshold_Player',
		page = 'TotalRegenerationControlPlayer',
		l10n = 'TotalRegenerationControl',
		name = "Health_Threshold",
		description = 'Health_Threshold_description',
		permanentStorage = true,
		settings = {
			{
				key = 'willpower',
				name = 'willpower_name',
				default = 0, -- %
				renderer = 'number',
			},
			{
				key = 'intelligence',
				name = 'intelligence_name',
				default = 0, -- %
				renderer = 'number',
			},
			{
				key = 'endurance',
				name = 'endurance_name',
				default = 0, -- %
				renderer = 'number',
			},
			{
				key = 'strength',
				name = 'strength_name',
				default = 10, -- %
				renderer = 'number',
			},
			{
				key = 'agility',
				name = 'agility_name',
				default = 0, -- %
				renderer = 'number',
			},
			{
				key = 'speed',
				name = 'speed_name',
				default = 0, -- %
				renderer = 'number',
			},
			{
				key = 'personality',
				name = 'personality_name',
				default = 0, -- %
				renderer = 'number',
			},
			{
				key = 'luck',
				name = 'luck_name',
				default = 0, -- %
				renderer = 'number',
			},
			{
				key = 'threshold',
				name = 'threshold_name',
				default = 0,
				renderer = 'number',
			},
			{
				key = 'threshold_by_lvl',
				name = 'threshold_by_lvl_name',
				description = 'threshold_by_lvl_description',
				default = 0,
				renderer = 'number',
			},
			{
				key = 'threshold_max_lvl',
				name = 'threshold_max_lvl_name',
				description = 'threshold_max_lvl_description',
				default = 10000,
				renderer = 'number',
				argument = {
					min = 0,
				},
			},
			{
				key = 'threshold_cap',
				name = 'threshold_cap_name',
				description = 'threshold_cap_description',
				default = 10000,
				renderer = 'number',
				argument = {
					min = 0,
				},
			},
		},
	})

	I.Settings.registerGroup({
		key = 'Settings_06_Fatigue_Player',
		page = 'TotalRegenerationControlPlayer',
		l10n = 'TotalRegenerationControl',
		name = "Fatigue",
		description = 'Fatigue_description',
		permanentStorage = true,
		settings = {
			{
				key = 'willpower',
				name = 'willpower_name',
				default = 1, -- %
				renderer = 'number',
			},
			{
				key = 'intelligence',
				name = 'intelligence_name',
				default = 0, -- %
				renderer = 'number',
			},
			{
				key = 'endurance',
				name = 'endurance_name',
				default = 5, -- %
				renderer = 'number',
			},
			{
				key = 'strength',
				name = 'strength_name',
				default = -1, -- %
				renderer = 'number',
			},
			{
				key = 'agility',
				name = 'agility_name',
				default = 2, -- %
				renderer = 'number',
			},
			{
				key = 'speed',
				name = 'speed_name',
				default = 1, -- %
				renderer = 'number',
			},
			{
				key = 'personality',
				name = 'personality_name',
				default = 0, -- %
				renderer = 'number',
			},
			{
				key = 'luck',
				name = 'luck_name',
				default = 0, -- %
				renderer = 'number',
			},
			{
				key = 'delay_resource',
				name = 'delay_resource_name',
				description = 'delay_resource_description',
				default = 0.1,
				renderer = 'number',
				argument = {
					min = 0,
				},
			},
			{
				key = 'delay_hp_for_fatigue',
				name = 'delay_hp_for_fatigue_name',
				description = 'delay_hp_for_fatigue_description',
				default = 2,
				renderer = 'number',
				argument = {
					min = 0,
				},
			},
			{
				key = 'delay_strength',
				name = 'delay_strength_name',
				description = 'delay_strength_description',
				default = 50,
				renderer = 'number',
			},
			{
				key = 'base_regen',
				name = 'base_regen_name',
				default = 0,
				renderer = 'number',
			},
			{
				key = 'regen_by_level',
				name = 'regen_by_level_name',
				description = 'regen_by_level_description',
				default = 0,
				renderer = 'number',
			},
			{
				key = 'regen_max_level',
				name = 'regen_max_level_name',
				description = 'regen_max_level_description',
				default = 10000,
				renderer = 'number',
				argument = {
					min = 0,
				},
			},
			{
				key = 'regen_cap',
				name = 'regen_cap_name',
				description = 'regen_cap_description',
				default = 10000,
				renderer = 'number',
				argument = {
					min = 0,
				},
			},
		},
	})

	I.Settings.registerGroup({
		key = 'Settings_07_Fatigue_Threshold_Player',
		page = 'TotalRegenerationControlPlayer',
		l10n = 'TotalRegenerationControl',
		name = "Fatigue_Threshold",
		description = 'Fatigue_Threshold_description',
		permanentStorage = true,
		settings = {
			{
				key = 'willpower',
				name = 'willpower_name',
				default = 0, -- %
				renderer = 'number',
			},
			{
				key = 'intelligence',
				name = 'intelligence_name',
				default = 0, -- %
				renderer = 'number',
			},
			{
				key = 'endurance',
				name = 'endurance_name',
				default = 0, -- %
				renderer = 'number',
			},
			{
				key = 'strength',
				name = 'strength_name',
				default = 0, -- %
				renderer = 'number',
			},
			{
				key = 'agility',
				name = 'agility_name',
				default = 5, -- %
				renderer = 'number',
			},
			{
				key = 'speed',
				name = 'speed_name',
				default = 0, -- %
				renderer = 'number',
			},
			{
				key = 'personality',
				name = 'personality_name',
				default = 0, -- %
				renderer = 'number',
			},
			{
				key = 'luck',
				name = 'luck_name',
				default = 0, -- %
				renderer = 'number',
			},
			{
				key = 'threshold',
				name = 'threshold_name',
				default = 0,
				renderer = 'number',
			},
			{
				key = 'threshold_by_lvl',
				name = 'threshold_by_lvl_name',
				description = 'threshold_by_lvl_description',
				default = 0,
				renderer = 'number',
			},
			{
				key = 'threshold_max_lvl',
				name = 'threshold_max_lvl_name',
				description = 'threshold_max_lvl_description',
				default = 10000,
				renderer = 'number',
				argument = {
					min = 0,
				},
			},
			{
				key = 'threshold_cap',
				name = 'threshold_cap_name',
				description = 'threshold_cap_description',
				default = 10000,
				renderer = 'number',
				argument = {
					min = 0,
				},
			},
		},
	})
end

local is_Enabled_Settings = storage.globalSection('Settings_01_Is_Enabled_Player')
local magicka_Settings = storage.globalSection('Settings_02_Magicka_Player')
local magicka_Threshold_Settings = storage.globalSection('Settings_03_Magicka_Threshold_Player')
local health_Settings = storage.globalSection('Settings_04_Health_Player')
local health_Threshold_Settings = storage.globalSection('Settings_05_Health_Threshold_Player')
local fatigue_Settings = storage.globalSection('Settings_06_Fatigue_Player')
local fatigue_Threshold_Settings = storage.globalSection('Settings_07_Fatigue_Threshold_Player')


return {
	initSettingsPlayer = initSettingsPlayer,
	isEnabledSettings = is_Enabled_Settings,
	magickaSettings = magicka_Settings,
	magickaTresholdSettings = magicka_Threshold_Settings,
	healthSettings = health_Settings,
	healthTresholdSettings = health_Threshold_Settings,
	fatigueSettings = fatigue_Settings,
	fatigueTresholdSettings = fatigue_Threshold_Settings,
}