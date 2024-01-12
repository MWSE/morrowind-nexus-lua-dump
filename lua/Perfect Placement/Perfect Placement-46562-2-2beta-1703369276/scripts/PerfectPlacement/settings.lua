--[[
    Mod: Perfect Placement OpenMW
    Author: Hrnchamd
    Version: 2.2beta
]]--

local async = require('openmw.async')
local core = require('openmw.core')
local input = require('openmw.input')
local I = require('openmw.interfaces')
local storage = require('openmw.storage')
local ui = require('openmw.ui')
local util = require('openmw.util')

local l10n = core.l10n('PerfectPlacement')
local versionString = "2.2beta"

-- inputKeySelection by Pharis
I.Settings.registerRenderer('inputKeySelection', function(value, set)
	local name = 'No Key Set'
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

-- Settings page
I.Settings.registerPage {
    key = 'PerfectPlacement',
    l10n = 'PerfectPlacement',
    name = 'ConfigTitle',
    description = l10n('ConfigSummary'):gsub('%%{version}', versionString),
}
I.Settings.registerGroup {
    key = 'Settings/PerfectPlacement/Options',
    page = 'PerfectPlacement',
    l10n = 'PerfectPlacement',
    name = 'ConfigCategoryOptions',
    permanentStorage = true,
    settings = {
        {
            key = 'showGuide',
            renderer = 'checkbox',
            name = 'ConfigDisplayGuide',
            default = true,
        },
        {
            key = 'initialGroundAlign',
            renderer = 'checkbox',
            name = 'ConfigOrientToGround',
            default = true,
        },
        {
            key = 'initialWallAlign',
            renderer = 'checkbox',
            name = 'ConfigOrientToWalls',
            default = true,
        },
        {
            key = 'sensitivity',
            renderer = 'number',
            name = 'ConfigRotateSensitivity',
			integer = true,
			min = 5,
			max = 50,
            default = 15,
        },
        {
            key = 'snapN',
            renderer = 'select',
            name = 'ConfigSnapRotationTo',
			argument = {
				l10n = 'PerfectPlacement',
				items = { 'Snap15', 'Snap30', 'Snap45', 'Snap90' },
			},
            default = 'Snap90',
        },
    },
}
I.Settings.registerGroup {
    key = 'Settings/PerfectPlacement/Keybinds',
    page = 'PerfectPlacement',
    l10n = 'PerfectPlacement',
    name = 'ConfigCategoryKeybinds',
    permanentStorage = true,
    settings = {
        {
            key = 'keybind',
            renderer = 'inputKeySelection',
            name = 'GrabDropItem',
            default = input.KEY.G,
        },
        {
            key = 'keybindRotate',
            renderer = 'inputKeySelection',
            name = 'RotateItem',
            default = input.KEY.LeftShift,
        },
        {
            key = 'keybindVertical',
            renderer = 'inputKeySelection',
            name = 'VerticalMode',
            default = input.KEY.LeftAlt,
        },
        {
            key = 'keybindWallAlign',
            renderer = 'inputKeySelection',
            name = 'OrientToSurface',
            default = input.KEY.Slash,
        },
        {
            key = 'keybindSnap',
            renderer = 'inputKeySelection',
            name = 'SnapRotation',
            default = input.KEY.RightShift,
        },
    },
}

local options = storage.playerSection('Settings/PerfectPlacement/Options')
local keybinds = storage.playerSection('Settings/PerfectPlacement/Keybinds')
local config = {}

local function updateConfig()
	config.options = options:asTable()
	config.options.snapN = 90 / tonumber(config.options.snapN:sub(5))
	config.keybinds = keybinds:asTable()
end
updateConfig()
options:subscribe(async:callback(updateConfig))
keybinds:subscribe(async:callback(updateConfig))

return config