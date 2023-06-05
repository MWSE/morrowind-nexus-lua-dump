--[[

Mod: Auto Attack
Author: Pharis

--]]

local async = require("openmw.async")
local I = require("openmw.interfaces")
local input = require("openmw.input")
local ui = require("openmw.ui")

-- Mod info
local modInfo = require("Scripts.Pharis.AutoAttack.modInfo")
local modName = modInfo.modName
local modVersion = modInfo.modVersion

-- Page description(s)
local pageDescription = "By Pharis\nv" .. modVersion .. "\n\nConfigurable automated bonking."

-- General settings description(s)
local modEnableDescription = "To mod or not to mod."

-- UI settings description(s)
local showMessagesDescription = "Show messages on screen when auto attack is toggled."

-- Controls settings description(s)
local autoAttackHotkeyDescription = "Choose which key toggles auto attack."
local attackBindingModeDescription = "Binds auto attack to the attack button assigned in the controls menu (typically left click).\n\nOverrides hotkey setting."
local stopOnReleaseDescription = "Stops auto attacking when the hotkey is released."
local increaseAttackIntervalHotkeyDescription = "Press and hold to increase auto attack interval."
local decreaseAttackIntervalHotkeyDescription = "Press and hold to decrease auto attack interval."

-- Gameplay settings description(s)
local drawOnEnableDescription = "Automatically draw weapon when auto attack is enabled."
local sheatheOnDisableDescription = "Automatically sheathe weapon when auto attack is disabled. Currently slow as it currently is not possible to detect if the player is mid-animation."
local marksmanOnlyDescription = "Limits auto attack to marksman weapons only. Implemented mostly in case it is useful for mods such as Starwind."
local useWhitelistDescription = "Allow auto attacking only for weapons on the whitelist. To add to the whitelist edit the provided \"weaponWhitelist.lua\" file.\n\nOverrides marksman only setting."

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

local function initSettings()
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
		name = "Auto Attack",
		description = pageDescription
	}

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
		key = "SettingsPlayer" .. modName .. "UI",
		page = modName,
		order = 1,
		l10n = modName,
		name = "UI",
		permanentStorage = false,
		settings = {
			setting("showMessages", "checkbox", {}, "Show Messages", showMessagesDescription, false),
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
			setting("autoAttackHotkey", "inputKeySelection", {}, "Auto Attack Hotkey", autoAttackHotkeyDescription, input.KEY.G),
			setting("attackBindingMode", "checkbox", {}, "Attack Binding Mode", attackBindingModeDescription, false),
			setting("stopOnRelease", "checkbox", {}, "Stop On Release", stopOnReleaseDescription, false),
			setting("decreaseAttackIntervalHotkey", "inputKeySelection", {}, "Decrease Attack Interval Hotkey", decreaseAttackIntervalHotkeyDescription, input.KEY.X),
			setting("increaseAttackIntervalHotkey", "inputKeySelection", {}, "Increase Attack Interval Hotkey", increaseAttackIntervalHotkeyDescription, input.KEY.C),
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
			setting("drawOnEnable", "checkbox", {}, "Automatically Draw Weapon", drawOnEnableDescription, false),
			setting("sheatheOnDisable", "checkbox", {}, "Automatically Sheathe Weapon", sheatheOnDisableDescription, false),
			setting("marksmanOnlyMode", "checkbox", {}, "Marksman Only Mode (Starwind Mode)", marksmanOnlyDescription, false),
			setting("useWhitelist", "checkbox", {}, "Use Whitelist", useWhitelistDescription, false),
		}
	}

	print("[" .. modName .. "] Initialized v" .. modVersion)
end

return {
	engineHandlers = {
		onActive = initSettings,
	}
}
