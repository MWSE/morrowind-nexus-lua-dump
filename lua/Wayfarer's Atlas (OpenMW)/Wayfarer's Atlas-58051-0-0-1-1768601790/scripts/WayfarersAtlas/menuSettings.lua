local I = require("openmw.interfaces")
local Input = require("openmw.input")
local Core = require("openmw.core")
local UI = require("openmw.ui")
local OMWUtil = require("openmw.util")

local defaultConfig = require("scripts/WayfarersAtlas/defaultConfig")
local fsGetMaps = require("scripts/WayfarersAtlas/fsGetMaps")
local SettingsUtils = require("scripts/WayfarersAtlas/SettingsUtils")
local Utils = require("scripts/WayfarersAtlas/Utils")
local Immutable = require("scripts/WayfarersAtlas/Immutable")
local Array = Immutable.Array

local l10n = Core.l10n("WayfarersAtlas")
local Settings = I.Settings

Settings.registerRenderer("WAY.error", function(_value, set, arg)
	return {
		type = UI.TYPE.Text,
		props = {
			wordWrap = true,
			multiline = true,
			autoSize = true,
			textSize = 16,
			textColor = OMWUtil.color.rgb(1, 0, 0),
			text = Utils.wordWrap(arg, 30),
		},
	}
end)

Input.registerTrigger({
	key = "WAY_ToggleLargeView",
	l10n = "WayfarersAtlas",
})

Settings.registerPage({
	key = "WayfarersAtlas",
	l10n = "WayfarersAtlas",
	name = "ConfigTitle",
	description = "ConfigSummary",
})

Settings.registerGroup({
	key = "Settings/WayfarersAtlas",
	page = "WayfarersAtlas",
	l10n = "WayfarersAtlas",
	name = "ConfigCategorySettings",
	permanentStorage = true,
	settings = {
		{
			key = "b_DisableBuiltinMap",
			renderer = "checkbox",
			name = "DisableBuiltinMap",
			description = "DisableBuiltinMapDesc",
			default = defaultConfig.b_DisableBuiltinMap,
		},
		{
			key = "b_ShowInInventory",
			renderer = "checkbox",
			name = "ShowInInterface",
			description = "ShowInInterfaceDesc",
			default = defaultConfig.b_ShowInInventory,
		},
		{
			key = "b_ShowAreaOnMap",
			renderer = "checkbox",
			name = "ShowAreaOnMap",
			description = "ShowAreaOnMapDesc",
			default = defaultConfig.b_ShowAreaOnMap,
		},
		{
			key = "k_ToggleLargeView",
			renderer = "inputBinding",
			name = "KeybindToggleLarge",
			description = "KeybindToggleLargeDesc",
			default = defaultConfig.k_ToggleLargeView,
			argument = {
				key = "WAY_ToggleLargeView",
				type = "trigger",
			},
		},
	},
})

local errors, mapPacks = fsGetMaps()

for _, mapPack in ipairs(mapPacks) do
	local packScope = SettingsUtils.scopeMapPack(mapPack)
	local packGroupKey = SettingsUtils.groupKey(packScope)
	local packPageKey = SettingsUtils.join("WayfarersAtlas", packScope)
	local packErrMsg = errors[mapPack.path]

	Settings.registerPage({
		key = packPageKey,
		l10n = "WayfarersAtlas",
		name = l10n("CustomMapPack", { name = mapPack.name }),
		description = l10n("CustomMapPackDesc", { path = mapPack.path }),
	})

	Settings.registerGroup({
		key = packGroupKey,
		page = packPageKey,
		l10n = "WayfarersAtlas",
		name = l10n("MapPackSettings") .. (packErrMsg and " (errored)" or ""),
		permanentStorage = true,
		settings = Array.concat({
			packErrMsg and {
				{
					key = SettingsUtils.join(packGroupKey, "error"),
					renderer = "WAY.error",
					name = "Error",
					argument = packErrMsg,
				},
			} or {},
			{
				{
					key = SettingsUtils.join(packGroupKey, "enabled"),
					renderer = "checkbox",
					name = "Enabled",
					default = true,
				},
			},
		}),
	})

	for key, mapDefinition in pairs(mapPack.mapDefinitions) do
		local defGroupKey = SettingsUtils.groupKey(SettingsUtils.scopeMapDefinition(mapPack, mapDefinition))
		local defErrMsg = errors[mapDefinition.id]

		Settings.registerGroup({
			key = defGroupKey,
			page = packPageKey,
			l10n = "WayfarersAtlas",
			name = key .. (defErrMsg and " (errored)" or ""),
			permanentStorage = true,
			settings = Array.concat({
				defErrMsg and {
					{
						key = SettingsUtils.join(defGroupKey, "error"),
						renderer = "WAY.error",
						name = "Error",
						argument = defErrMsg,
					},
				} or {},
				{
					{
						key = SettingsUtils.join(defGroupKey, "enabled"),
						renderer = "checkbox",
						name = "Enabled",
						default = true,
					},
					{
						key = SettingsUtils.join(defGroupKey, "customName"),
						renderer = "textLine",
						name = "CustomName",
						default = mapDefinition.name,
					},
				},
			}),
		})
	end
end
