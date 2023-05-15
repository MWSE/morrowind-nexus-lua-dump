--[[

Mod: Pharis' Magicka Regeneration
Author: Pharis

--]]

local I = require("openmw.interfaces")

-- Mod info
local modInfo = require("Scripts.Pharis.PharisMagickaRegeneration.modInfo")
local modName = modInfo.modName
local modVersion = modInfo.modVersion

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
	key = "SettingsGlobal" .. modName,
	page = modName,
	order = 0,
	l10n = modName,
	name = "General",
	permanentStorage = false,
	settings = {
		setting("modEnable", "checkbox", {}, "Enable Mod", modEnableDescription, true),
	}
}

I.Settings.registerGroup {
	key = "SettingsGlobal" .. modName .. "Gameplay",
	page = modName,
	order = 1,
	l10n = modName,
	name = "Gameplay",
	description = "",
	permanentStorage = false,
	settings = {
		setting("enablePlayerRegeneration", "checkbox", {}, "Enable Player Regeneration", "", true),
		setting("enableNonPlayerRegeneration", "checkbox", {}, "Enable NPC and Creature Regeneration", "", true),
		setting("enableLowMagickaRegenerationBoost", "checkbox", {}, "Enable Low Magicka Regeneration Boost", enableLowMagickaRegenerationBoostDescription, true),
		setting("baseMultiplier", "number", {min = 0.01, max = 100.0}, "Base Multiplier", baseMultiplierDescription, 1.0),
	},
}

print("[" .. modName .. "] Initialized v" .. modVersion)
