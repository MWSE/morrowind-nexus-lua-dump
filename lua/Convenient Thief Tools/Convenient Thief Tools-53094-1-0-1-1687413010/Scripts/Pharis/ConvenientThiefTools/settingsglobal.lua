--[[

Mod: Convenient Thief Tools
Author: Pharis

--]]

local I = require("openmw.interfaces")

-- Mod info
local modInfo = require("Scripts.Pharis.ConvenientThiefTools.modinfo")
local modName = modInfo.modName
local modVersion = modInfo.modVersion

-- General settings description(s)
local modEnableDescription = "To mod or not to mod."

-- Gameplay settings description(s)
local autoEquipLockpickDescription = "Automatically equip lockpick when locked object is activated."
local autoEquipProbeDescription = "Automatically equip probe when trapped object is activated. Activating after probe is equipped will just trigger the trap as normal."
local autoWeaponStanceDescription = "Automatically set stance to weapon when tool is equipped."
local qualitySortDirectionDescription = "Determines which tool will be equipped first and in what order they will cycle through."

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
	order = 3,
	l10n = modName,
	name = "Gameplay",
	permanentStorage = false,
	settings = {
		setting("autoEquipLockpick", "checkbox", {}, "Auto Equip Lockpick", autoEquipLockpickDescription, true),
		setting("autoEquipProbe", "checkbox", {}, "Auto Equip Probe", autoEquipProbeDescription, true),
		setting("autoWeaponStance", "checkbox", {}, "Auto Weapon Stance On Equip", autoWeaponStanceDescription, true),
		setting("qualitySortDirection", "select", {l10n = modName, items = {"ascending", "descending"}}, "Quality Sort Direction", qualitySortDirectionDescription, "ascending"),
	}
}
