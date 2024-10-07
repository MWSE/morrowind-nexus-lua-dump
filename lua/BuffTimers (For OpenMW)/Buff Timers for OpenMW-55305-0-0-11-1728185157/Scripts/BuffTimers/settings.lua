--[[

Mod: BuffTimers
Author: Nitro

--]]

-- Add user Setting for radial swipe direction and perhaps color

local async = require("openmw.async")
local core = require("openmw.core")
local I = require("openmw.interfaces")
local input = require("openmw.input")
local ui = require("openmw.ui")
local util = require('openmw.util')

--local color = util.color

local modInfo = require("Scripts.BuffTimers.modInfo")

local pageDescription = "By Nitro\nv" .. modInfo.version .. "\n\nBuff Timers\n\nThis mod shows all buffs or debuffs with timers and optional dynamic visual effects."
.."\n\nYou can click and drag both buff or debuff windows to any location on the HUD.\n\nFor Buff/Debuff HUD Positions:\n    Press '=' key to Save\n    Press '-' key to Reset"
local modEnableDescription = "This enables the mod or disables it."
local showMessagesDescription = "Enables UI messages to be shown for any cases which require it. (Currently none)"
local iconOptions = "Select which options you want for the icons the following options are available: \n 1. All (contains all below)\n 2. Icon Pulse on low time\n 3. Radial Swipe"

local menuParams = {
	const = {

	},
}

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
	name = "Buff Timers",
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
	}
}

I.Settings.registerGroup {
	key = "SettingsPlayer" .. modInfo.name .. "UI",
	page = modInfo.name,
	order = 1,
	l10n = modInfo.name,
	name = "UI",
	permanentStorage = false,
	settings = {
		setting("showMessages", "checkbox", {}, "Show Messages", showMessagesDescription, true),
		setting("iconScaling", "inputText", {defaultValue = 35}, "Icon and Text Size", "Set the icon size in pixels. Default is 35, min/max is: 1/100", 35),
		setting("showBox","checkbox",{}, "Show Buff Borders", "Show the area box where buff icons will be rendered. Useful for positioning the buffs display area",true),
		setting("buffAlign","checkbox",{}, "Align Buffs Left", "Buffs fill in each row from the left. If turned off buffs will align on the right hand side",true),
		setting("debuffAlign","checkbox",{}, "Align deBuffs Left", "deBuffs fill in each row from the left. If turned off buffs will align on the right hand side",true),
		setting("splitBuffsDebuffs","checkbox",{}, "Split Buffs and Debuffs\n-NOT IMPLEMENTED YET-", "This will set buff and debuffs into two distinct containers that you can place anywhere on the HUD", true),
		setting("iconOptions", "select", {l10n = modInfo.name, items = {"1", "2", "3"}}, "Icon Effect Selection\n-NOT IMPLEMENTED YET-", iconOptions, "1"),
		setting("timerColor","color",{}, "Timer Text Color", "Text color for time countdown text", util.color.rgb(255, 255, 255)),
		setting("detailTextColor","color",{}, "Buff Details Text Color", "Text color of skill, attribute and magnitude for buffs and debuffs ",util.color.hex('DFC99F')),
		setting("iconPadding","checkbox",{}, "Pad Icons", "Put Padding around the buff Icons", true),
		setting("rowLimit","inputText",{defaultValue = 15}, "Max number of debuffs or buffs per row", "Set the limit on how many buffs or debuffs to show per row. Default is 15, min/max is: 1/100", 15),
		setting("buffLimit","inputText",{defaultValue = 100}, "Max number of debuffs or buffs to display", "Set the limit on how many buffs or debuffs can be shown. Default is 100, min/max is: 1/100", 100),
		setting("radialSwipe","myToggle",{}, "Radial Swipe Options", "Radial swipe effect as time decreases: Shade / Unshade\nRequires Reload to take effect.", "Unshade"),
	}
}

I.Settings.registerGroup {
	key = "SettingsPlayer" .. modInfo.name .. "Controls",
	page = modInfo.name,
	order = 2,
	l10n = modInfo.name,
	name = "Controls",
	permanentStorage = false,
	settings = {
		--Add settings here
	}
}

-- No need to even show this setting in 0.48
if (core.API_REVISION >= 31) then
	I.Settings.registerGroup {
		key = "SettingsPlayer" .. modInfo.name .. "Gameplay",
		page = modInfo.name,
		order = 3,
		l10n = modInfo.name,
		name = "Gameplay",
		permanentStorage = false,
		description = "Settings that modify how the icons interact with gameplay",
		settings = {
			--setting("iconScaling", "inputText", {}, "TextInputRenderer", "Test_of_icon_ScalingRenderer", 24),
		}
	}
end

--[[ for _, actionInfo in ipairs(actions) do
	--print(actionInfo)
	input.registerAction(actionInfo)
end ]]

print("[" .. modInfo.name .. "] Initialized v" .. modInfo.version)
