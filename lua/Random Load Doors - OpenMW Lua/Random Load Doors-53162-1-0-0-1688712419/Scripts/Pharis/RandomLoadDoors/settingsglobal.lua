--[[

Mod: Random Load Doors
Author: Pharis

--]]

local I = require("openmw.interfaces")

local modInfo = require("Scripts.Pharis.RandomLoadDoors.modinfo")

-- General settings description(s)
local modEnableDescription = "To mod or not to mod."

-- Gameplay settings description(s)
local randomizeChanceDescription = "Chance that any individual load door will be randomized."

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
	key = "SettingsPlayer" .. modInfo.name,
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
	key = "SettingsPlayer" .. modInfo.name .. "Gameplay",
	page = modInfo.name,
	order = 1,
	l10n = modInfo.name,
	name = "Gameplay",
	permanentStorage = false,
	settings = {
		setting("randomizeChance", "number", {min = 0, max = 1}, "Randomize Chance", randomizeChanceDescription, 0.5),
	}
}
