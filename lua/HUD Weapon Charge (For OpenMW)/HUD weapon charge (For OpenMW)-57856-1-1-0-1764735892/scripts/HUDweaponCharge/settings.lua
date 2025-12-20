--[[

Mod: HUDweaponCharge
Author: Nitro

--]]

local I = require("openmw.interfaces")
local modInfo = require("Scripts.HUDweaponCharge.modInfo")
local util = require('openmw.util')
local storage = require("openmw.storage")
local async = require('openmw.async')
local ui = require("openmw.ui")
local ChargeColor   = util.color.rgba(0.50, 0.60, 0.90, 1.00)
local betterBar = false
local displayAreaY = ui.layers[1].size.y
--local yPos, xPos = displayAreaY-12, 82
-- Settings Descriptions
local pageDescription = "By Nitro\nv" .. modInfo.version .. "\n\nShows weapon charge on HUD"
local modEnableDescription = "This enables the mod or disables it."
local defaults = {xPos = 82, yPos = displayAreaY-12}

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

I.Settings.registerPage {
	key = modInfo.name,
	l10n = modInfo.name,
	name = "HUDweaponCharge",
	description = pageDescription
}

I.Settings.registerGroup {
	key = "SettingsPlayer" .. modInfo.name,
	page = modInfo.name,
	order = 0,
	l10n = modInfo.name,
	name = "General",
	permanentStorage = false,
	settings = {
		setting("modEnable", "checkbox", {}, "Enable Mod", modEnableDescription, true),
		setting("betterBarSetting", "checkbox", {}, "Better Bar Compatibility", "Enable if using BetterBars mod", betterBar),
		setting("alwaysOn", "checkbox", {}, "Bar is always shown", "Bar always displaye regardless if item has enchantment or constant effect", true),
		setting("HUD_LOCK", "checkbox", {disabled = false}, "Lock Position", nil, true),
		setting("xPos", "number", {integer = true, disabled = true}, "X Position", nil, defaults.xPos),
		setting("yPos", "number", {integer = true, disabled = true}, "Y Position", nil, defaults.yPos),
		setting("R_FLAG", "checkbox", {disabled = true}, "", nil, false),
	}
}
I.Settings.registerGroup {
	key = "SettingsPlayer" .. modInfo.name .. "Color",
	page = modInfo.name,
	order = 0,
	l10n = modInfo.name,
	name = "Color",
	permanentStorage = false,
	settings = {
		setting("colorSetting", "color2", {}, "colorPicker", "color picker widget", util.color.hex(ChargeColor:asHex())),
	}
}

-- local positionSettings = storage.playerSection("SettingsPlayer" .. modInfo.name .. "Position")
-- local userInterfaceSettings = storage.playerSection("SettingsPlayer" .. modInfo.name)
-- local flag

-- local function settingChange(section, key)
-- 	if section == "SettingsPlayer" .. modInfo.name then
-- 		if key == "betterBarSetting" then
-- 			betterBar = userInterfaceSettings:get("betterBarSetting")
-- 			if betterBar then
-- 				positionSettings:set("xPos",12)
-- 			else
-- 				positionSettings:set("xPos",82)
-- 			end
-- 		end
-- 	end

-- 	if section == "SettingsPlayer" .. modInfo.name .. "Position" then
-- 		if key == "R_FLAG" then
-- 			print("RESET TRIGGERED")
-- 			-- xPos = betterBar and 12 or 82
-- 			-- print("State of BetterBar.. / xPos ", betterBar, xPos)
-- 			-- -- betterBar = false
-- 			-- -- --userInterfaceSettings:set("betterBarSetting", betterBar)
-- 			-- -- async:newUnsavableSimulationTimer(0, function()
-- 			-- -- 	userInterfaceSettings:set("betterBarSetting", betterBar)
-- 			-- -- 		print("setting betterBarSetting to false")
-- 			-- -- 	end)
-- 		elseif key == "xPos" then
-- 			local val = positionSettings:get("xPos")
-- 			print(key," changed to.. ", val)
-- 			print(type(val))
-- 		elseif key == "yPos" then
-- 			local val = positionSettings:get("yPos")
-- 			print(key," changed to.. ", val)
-- 		end
-- 	end
-- end

-- userInterfaceSettings:subscribe(async:callback(settingChange))
-- positionSettings:subscribe(async:callback(settingChange))

print("[" .. modInfo.name .. "] Initialized v" .. modInfo.version)
