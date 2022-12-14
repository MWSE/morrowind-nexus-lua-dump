--[[

Mod: Light Hotkey - OpenMW Lua
Author: Pharis

--]]

local core = require('openmw.core')
local interfaces = require('openmw.interfaces')
local storage = require('openmw.storage')
local input = require('openmw.input')
local ui = require('openmw.ui')
local async = require('openmw.async')

local modName = "LightHotkey"
local modVersion = 1.2
local modEnableConfDesc = "To mod or not to mod."
local logDebugConfDesc = "Press F10 to see logged messages in-game."
local modHotkeyConfDesc = "Choose which key equips a light; picking \'Alt\' isn't recommended for obvious reasons."

interfaces.Settings.registerRenderer('inputKeySelection', function(value, set)
	local name = 'No Key Set'
	if value then
		name = input.getKeyName(value)
	end
	return {
		template = interfaces.MWUI.templates.box,
		content = ui.content {
			{
				template = interfaces.MWUI.templates.padding,
				content = ui.content {
					{
						template = interfaces.MWUI.templates.textEditLine,
						props = {
							text = name,
						},
						events = {
							keyPress = async:callback(function(e)

								set(e.code)
							end),
						},
					},
				},
			},
		},

	}
end)

local function settingTemplate(key, renderer, argument, name, description, default)
	return {
		key = key,
		renderer = renderer,
		argument = argument,
		name = name,
		description = description,
		default = default,
	}
end

interfaces.Settings.registerPage {
	key = modName,
	l10n = modName,
	name = "Light Hotkey",
	description = "By Pharis\n\nEquip light with hotkey; automatically re-equip shield when light is unequipped."
}

interfaces.Settings.registerGroup {
	key = 'SettingsPlayer' .. modName,
	page = modName,
	l10n = modName,
	name = "General Settings",
	permanentStorage = false,
	settings = {
		settingTemplate('modEnableConf', 'checkbox', {}, "Enable Mod", modEnableConfDesc, true),
		settingTemplate('modHotkeyConf', 'inputKeySelection', {}, "Choose Light Hotkey", modHotkeyConfDesc, input.KEY.C),
		settingTemplate('showDebugConf', 'checkbox', {}, "Log Debug Messages", logDebugConfDesc, false),
	}
}

local settings = {
	modName = modName,
	modVersion = modVersion,
	playerSettings = storage.playerSection('SettingsPlayer' .. modName),
}

return settings