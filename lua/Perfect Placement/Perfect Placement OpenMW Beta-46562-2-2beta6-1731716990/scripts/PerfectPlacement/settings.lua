--[[
    Mod: Perfect Placement OpenMW
    Author: Hrnchamd
    Version: 2.2beta
]]--

local async = require('openmw.async')
local core = require('openmw.core')
local input = require('openmw.input')
local I = require('openmw.interfaces')
local ui = require('openmw.ui')

local l10n = core.l10n('PerfectPlacement')
local versionString = "2.2beta"

-- inputKeySelection by Pharis
I.Settings.registerRenderer('PerfectPlacement/inputKeySelection', function(value, set)
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
            key = 'keybindPlace',
            renderer = 'PerfectPlacement/inputKeySelection',
            name = 'GrabDropItem',
            default = input.KEY.G,
        },
        {
            key = 'keybindRotate',
            renderer = 'PerfectPlacement/inputKeySelection',
            name = 'RotateItem',
            default = input.KEY.LeftShift,
        },
        {
            key = 'keybindVertical',
            renderer = 'PerfectPlacement/inputKeySelection',
            name = 'VerticalMode',
            default = input.KEY.LeftAlt,
        },
        {
            key = 'keybindSurfaceAlign',
            renderer = 'PerfectPlacement/inputKeySelection',
            name = 'OrientToSurface',
            default = input.KEY.Slash,
        },
        {
            key = 'keybindSnap',
            renderer = 'PerfectPlacement/inputKeySelection',
            name = 'SnapRotation',
            default = input.KEY.RightShift,
        },
    },
}
