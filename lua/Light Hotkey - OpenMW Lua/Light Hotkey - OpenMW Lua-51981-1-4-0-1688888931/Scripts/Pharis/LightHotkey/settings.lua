--[[

Mod: Light Hotkey
Author: Pharis

--]]

local async = require("openmw.async")
local core = require("openmw.core")
local I = require("openmw.interfaces")
local input = require("openmw.input")
local ui = require("openmw.ui")

local modInfo = require("Scripts.Pharis.LightHotkey.modInfo")

local pageDescription = "By Pharis\nv" .. modInfo.version .. "\n\nEquip light with hotkey; automatically re-equip shield when light is unequipped."
local modEnableDescription = "To mod or not to mod."
local showMessagesDescription = "Show messages on screen when light is equipped and preferred light is set/cleared."
local lightHotkeyDescription = "Choose which key equips a light; picking alt isn't recommended as preferred light is set with alt > hotkey."
local lowerTwoHandedWeaponDescription = "Lowers two-handed weapon when light is equipped."

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

I.Settings.registerRenderer(
	"inputKeySelection",
	function(value, set)
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
	end
)

I.Settings.registerPage {
	key = modInfo.name,
	l10n = modInfo.name,
	name = "Light Hotkey",
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
		setting("lightHotkey", "inputKeySelection", {}, "Light Hotkey", lightHotkeyDescription, input.KEY.V),
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
		settings = {
			setting("lowerTwoHandedWeapon", "checkbox", {}, "Automatically Lower Two-Handed Weapon", lowerTwoHandedWeaponDescription, true),
		}
	}
end

print("[" .. modInfo.name .. "] Initialized v" .. modInfo.version)
