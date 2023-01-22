--[[

Mod: Light Hotkey
Author: Pharis

--]]

local async = require('openmw.async')
local core = require('openmw.core')
local I = require('openmw.interfaces')
local input = require('openmw.input')
local ui = require('openmw.ui')

-- Mod info
local modInfo = require('Scripts.Pharis.LightHotkey.modInfo')
local modName = modInfo.modName
local modVersion = modInfo.modVersion

-- Page description(s)
local pageDescription = "By Pharis\nv" .. modVersion .. "\n\nEquip light with hotkey; automatically re-equip shield when light is unequipped."

-- General settings description(s)
local modEnableDescription = "To mod or not to mod."
local logDebugDescription = "Press F10 to see logged messages in-game. Leave disabled for normal gameplay."

-- UI settings description(s)
local showMessagesDescription = "Show messages on screen when light is equipped and preferred light is set/cleared."

-- Controls settings description(s)
local lightHotkeyDescription = "Choose which key equips a light; picking 'alt' isn't recommended as preferred light is set with 'alt > hotkey'."

-- Gameplay settings description(s)
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
--[[
local function updateModDisabled()
    local disabled = not playerSettings:get('modEnable')
    I.Settings.updateRendererArgument('SettingsPlayer' .. modName, 'showDebug', {disabled = disabled})
    I.Settings.updateRendererArgument('SettingsPlayer' .. modName, 'lightHotkey', {disabled = disabled})
end

playerSettings:subscribe(async:callback(updateModDisabled))
]]
local function initSettings()
	I.Settings.registerRenderer('inputKeySelection', function(value, set)
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
		name = "Light Hotkey",
		description = pageDescription
	}

	I.Settings.registerGroup {
		key = 'SettingsPlayer' .. modName,
		page = modName,
		order = 0,
		l10n = modName,
		name = "General",
		permanentStorage = false,
		settings = {
			setting('modEnable', 'checkbox', {}, "Enable Mod", modEnableDescription, true),
			setting('showDebug', 'checkbox', {}, "Log Debug Messages", logDebugDescription, false),
		}
	}

	I.Settings.registerGroup {
		key = 'SettingsPlayer' .. modName .. 'UI',
		page = modName,
		order = 1,
		l10n = modName,
		name = "UI",
		permanentStorage = false,
		settings = {
			setting('showMessages', 'checkbox', {}, "Show Messages", showMessagesDescription, true),
		}
	}

	I.Settings.registerGroup {
		key = 'SettingsPlayer' .. modName .. 'Controls',
		page = modName,
		order = 2,
		l10n = modName,
		name = "Controls",
		permanentStorage = false,
		settings = {
			setting('lightHotkey', 'inputKeySelection', {}, "Light Hotkey", lightHotkeyDescription, input.KEY.V),
		}
	}

	I.Settings.registerGroup {
		key = 'SettingsPlayer' .. modName .. 'Gameplay',
		page = modName,
		order = 3,
		l10n = modName,
		name = "Gameplay",
		permanentStorage = false,
		settings = {
			setting('lowerTwoHandedWeapon', 'checkbox', {}, "Automatically Lower Two-Handed Weapon", lowerTwoHandedWeaponDescription, true),
		}
	}

	print("[" .. modName .. "] Initialized v" .. modVersion)
end

return {
	engineHandlers = {
		onActive = initSettings,
	}
}
