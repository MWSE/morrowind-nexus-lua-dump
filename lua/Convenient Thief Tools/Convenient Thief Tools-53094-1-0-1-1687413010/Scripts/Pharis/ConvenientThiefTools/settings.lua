--[[

Mod: Convenient Thief Tools
Author: Pharis

--]]

local async = require("openmw.async")
local I = require("openmw.interfaces")
local input = require("openmw.input")
local ui = require("openmw.ui")

-- Mod info
local modInfo = require("Scripts.Pharis.ConvenientThiefTools.modinfo")
local modName = modInfo.modName
local modVersion = modInfo.modVersion

-- Page description(s)
local pageDescription = "By Pharis\nv" .. modVersion .. "\n\nThief tools but convenient. :)"

-- UI settings description(s)
local showMessagesDescription = "Show messages on screen when equipping fails."

-- Controls settings description(s)
local lockpickHotkeyDescription = "Hotkey to equip/unequip lockpicks. Use alt>hotkey to cycle through lockpicks."
local probeHotkeyDescription = "Hotkey to equip/unequip probes. Use alt>hotkey to cycle through probes."

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

I.Settings.registerRenderer("inputKeySelection", function(value, set)
	local name = "No Key Set"
	if value then
		name = input.getKeyName(value)
	end
	return {
		template = I.MWUI.templates.box,
		content = ui.content {
			{
				template = I.MWUI.templates.padding,
				content = ui.content {
					{
						template = I.MWUI.templates.textEditLine,
						props = {
							text = name,
						},
						events = {
							keyPress = async:callback(function(e)
								if e.code == input.KEY.Escape then return end
								set(e.code)
							end),
						},
					},
				},
			},
		},
	}
end)

I.Settings.registerPage {
	key = modName,
	l10n = modName,
	name = "Convenient Thief Tools",
	description = pageDescription
}

I.Settings.registerGroup {
	key = "SettingsPlayer" .. modName .. "UI",
	page = modName,
	order = 1,
	l10n = modName,
	name = "UI",
	permanentStorage = false,
	settings = {
		setting("showMessages", "checkbox", {}, "Show Messages", showMessagesDescription, true),
	}
}

I.Settings.registerGroup {
	key = "SettingsPlayer" .. modName .. "Controls",
	page = modName,
	order = 2,
	l10n = modName,
	name = "Controls",
	permanentStorage = false,
	settings = {
		setting("lockpickHotkey", "inputKeySelection", {}, "Lockpick Hotkey", lockpickHotkeyDescription, input.KEY.L),
		setting("probeHotkey", "inputKeySelection", {}, "Probe Hotkey", probeHotkeyDescription, input.KEY.P),
	}
}

print("[" .. modName .. "] Initialized v" .. modVersion)
