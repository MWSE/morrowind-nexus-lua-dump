--[[

Mod: Pharis' Magicka Regeneration
Author: Pharis

--]]

local I = require("openmw.interfaces")

local modInfo = require("Scripts.Pharis.PharisMagickaRegeneration.modinfo")

-- Magicka regeneration settings description(s)
local modEnableDescription = "To mod or not to mod."
local enableLowMagickaRegenerationBoostDescription = "Increases magicka regeneration at lower magicka ratios. Note that disabling this will effectively lower regeneration so you may want to raise the multiplier as well."
local baseMultiplierDescription = "Base regeneration multiplier. Gets real unbalanced real fast.\n[0.01,100.0]"

local function setting(key, renderer, argument, name, description, default)
	return {
		key = key,
		renderer = renderer,
		argument = argument,
		name = name,
		description = description,
		default = default,
	}
end

I.Settings.registerGroup {
	key = "SettingsGlobal" .. modInfo.name,
	page = modInfo.name,
	order = 0,
	l10n = modInfo.name,
	name = "General",
	permanentStorage = false,
	settings = {
		setting("modEnable", "checkbox", {}, "Enable Mod", modEnableDescription, true),
	}
}

I.Settings.registerGroup {
	key = "SettingsGlobal" .. modInfo.name .. "Gameplay",
	page = modInfo.name,
	order = 1,
	l10n = modInfo.name,
	name = "Gameplay",
	description = "",
	permanentStorage = false,
	settings = {
		setting("enablePlayerRegeneration", "checkbox", {}, "Enable Player Regeneration", "", true),
		setting("enableNPCRegeneration", "checkbox", {}, "Enable NPC Regeneration", "", true),
		setting("enableCreatureRegeneration", "checkbox", {}, "Enable Creature Regeneration", "", true),
		setting("enableLowMagickaRegenerationBoost", "checkbox", {}, "Enable Low Magicka Regeneration Boost", enableLowMagickaRegenerationBoostDescription, true),
		setting("baseMultiplier", "number", {min = 0.01, max = 100.0}, "Base Multiplier", baseMultiplierDescription, 1.0),
	},
}

print("[" .. modInfo.name .. "] Initialized v" .. modInfo.version)
