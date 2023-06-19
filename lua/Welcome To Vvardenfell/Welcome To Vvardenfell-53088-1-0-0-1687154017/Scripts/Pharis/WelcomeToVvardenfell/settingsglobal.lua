--[[

Mod: Welcome To Vvardenfell
Author: Pharis

--]]

local I = require("openmw.interfaces")

-- Mod info
local modInfo = require("Scripts.Pharis.WelcomeToVvardenfell.modinfo")
local modName = modInfo.modName
local modVersion = modInfo.modVersion

-- General settings description(s)
local modEnableDescription = "To mod or not to mod."

-- Gameplay settings description(s)
local spawnsPerDeathDescription = "Number of new creatures spawned for every one that dies."
local randomizeSpawnPositionDescription = "Randomly offset position of new spawns relative to original creature."
local randomizeSpawnRotationDescription = "Give new spawns random rotation."

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
	key = "SettingsPlayer" .. modName,
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
	key = "SettingsPlayer" .. modName .. "Gameplay",
	page = modName,
	order = 1,
	l10n = modName,
	name = "Gameplay",
	permanentStorage = false,
	settings = {
		setting("spawnsPerDeath", "number", {min = 2}, "Spawns Per Death", spawnsPerDeathDescription, 2),
		setting("randomizeSpawnPosition", "checkbox", {}, "Randomize Spawn Position", randomizeSpawnPositionDescription, false),
		setting("randomizeSpawnRotation", "checkbox", {}, "Randomize Spawn Rotation", randomizeSpawnRotationDescription, false),
		setting("maxHorizontalOffset", "number", {min = 0}, "Max Horizontal Offset", "", 1024),
		setting("minVerticalOffset", "number", {min = 0}, "Min Vertical Offset", "", 32),
		setting("maxVerticalOffset", "number", {min = 0}, "Max Vertical Offset", "", 2048),
	}
}
