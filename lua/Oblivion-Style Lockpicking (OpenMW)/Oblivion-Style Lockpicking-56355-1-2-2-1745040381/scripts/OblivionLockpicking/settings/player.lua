local async = require('openmw.async')
local core = require('openmw.core')
local input = require('openmw.input')
local I = require('openmw.interfaces')
local ui = require('openmw.ui')
local util = require('openmw.util')

local l10n = core.l10n('OblivionLockpicking')
local versionString = "1.2.2"

-- inputKeySelection by Pharis
I.Settings.registerRenderer('OblivionLockpicking/inputKeySelection', function(value, set)
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
    key = 'OblivionLockpicking',
    l10n = 'OblivionLockpicking',
    name = 'ConfigTitle',
    description = l10n('ConfigSummary'):gsub('%%{version}', versionString),
}
I.Settings.registerGroup {
    key = 'Settings/OblivionLockpicking/1_Keybinds',
    page = 'OblivionLockpicking',
    l10n = 'OblivionLockpicking',
    name = 'ConfigCategoryKeybinds',
    permanentStorage = true,
    settings = {
        {
            key = 'keybindPreviousPin',
            renderer = 'OblivionLockpicking/inputKeySelection',
            name = 'KeybindPreviousPin',
            description = 'KeybindPreviousPinDesc',
            default = input.KEY.A
        },
        {
            key = 'keybindNextPin',
            renderer = 'OblivionLockpicking/inputKeySelection',
            name = 'KeybindNextPin',
            description = 'KeybindNextPinDesc',
            default = input.KEY.D
        },
        {
            key = 'keybindPickPin',
            renderer = 'OblivionLockpicking/inputKeySelection',
            name = 'KeybindPickPin',
            description = 'KeybindPickPinDesc',
            default = input.KEY.W
        },
        {
            key = 'keybindAutoAttempt',
            renderer = 'OblivionLockpicking/inputKeySelection',
            name = 'KeybindAutoAttempt',
            description = 'KeybindAutoAttemptDesc',
            default = input.KEY.F
        },
        {
            key = 'keybindCancel',
            renderer = 'OblivionLockpicking/inputKeySelection',
            name = 'KeybindCancel',
            description = 'KeybindCancelDesc',
            default = input.KEY.V
        }
    },
}
I.Settings.registerGroup {
    key = 'Settings/OblivionLockpicking/2_ClientOptions',
    page = 'OblivionLockpicking',
    l10n = 'OblivionLockpicking',
    name = 'ConfigCategoryClientOptions',
    permanentStorage = true,
    settings = {
        {
            key = 'b_AutoEquip',
            renderer = 'checkbox',
            name = 'AutoEquip',
            description = 'AutoEquipDesc',
            default = true,
        },
        {
            key = 's_AutoEquipPrefTier',
            renderer = 'select',
            name = 'AutoEquipPrefTier',
            argument = {
                l10n = 'OblivionLockpicking',
                items = {
                    'AutoEquipPrefTierLower',
                    'AutoEquipPrefTierHigher'
                }
            },
            default = 'AutoEquipPrefTierHigher',
        },
        {
            key = 's_AutoEquipPrefCond',
            renderer = 'select',
            name = 'AutoEquipPrefCond',
            argument = {
                l10n = 'OblivionLockpicking',
                items = {
                    'AutoEquipPrefCondLower',
                    'AutoEquipPrefCondHigher'
                }
            },
            default = 'AutoEquipPrefCondLower',
        },
        {
            key = 'b_StopIfCaught',
            renderer = 'checkbox',
            name = 'StopIfCaught',
            description = 'StopIfCaughtDesc',
            default = true,
        },
        {
            key = 'b_ShowInfoWindow',
            renderer = 'checkbox',
            name = 'ShowInfoWindow',
            description = 'ShowInfoWindowDesc',
            default = true,
        },
        {
            key = 's_ShowInfoWindowProbability',
            renderer = 'select',
            name = 'ShowInfoWindowProbability',
            argument = {
                l10n = 'OblivionLockpicking',
                items = {
                    'ShowInfoWindowProbabilityBoth',
                    'ShowInfoWindowProbabilityDifficulty',
                    'ShowInfoWindowProbabilityNone',
                }
            },
            default = 'ShowInfoWindowProbabilityBoth',
        },
        {
            key = 'b_ShowInfoWindowPick',
            renderer = 'checkbox',
            name = 'ShowInfoWindowPick',
            default = true,
        },
        {
            key = 'b_ShowInfoWindowKeybinds',
            renderer = 'checkbox',
            name = 'ShowInfoWindowKeybinds',
            default = true,
        },
        {
            key = 'n_InfoWindowOffsetXRelative',
            renderer = 'number',
            name = 'InfoWindowOffsetXRelative',
            argument = {
                min = 0.0,
                max = 1.0,
            },
            default = 0.5,
        },
        {
            key = 'n_InfoWindowOffsetYRelative',
            renderer = 'number',
            name = 'InfoWindowOffsetYRelative',
            argument = {
                min = 0.0,
                max = 1.0,
            },
            default = 0.5,
        },
        {
            key = 'n_InfoWindowOffsetXAbsolute',
            renderer = 'number',
            name = 'InfoWindowOffsetXAbsolute',
            default = 170,
        },
        {
            key = 'n_InfoWindowOffsetYAbsolute',
            renderer = 'number',
            name = 'InfoWindowOffsetYAbsolute',
            default = -202,
        },
        {
            key = 'n_InfoWindowUpdateInterval',
            renderer = 'number',
            name = 'InfoWindowUpdateInterval',
            default = 10,
            argument = {
                integer = true,
                min = 1,
                max = 60,
            },
        },
        {
            key = 'b_ShowFailureReason',
            renderer = 'checkbox',
            name = 'ShowFailureReason',
            description = 'ShowFailureReasonDesc',
            default = true,
        },
        {
            key = 'b_ShowFailureReasonPercentage',
            renderer = 'checkbox',
            name = 'ShowFailureReasonPercentage',
            description = 'ShowFailureReasonPercentageDesc',
            default = true,
        },
        {
            key = 'b_PlayRandomSounds',
            renderer = 'checkbox',
            name = 'PlayRandomSounds',
            description = 'PlayRandomSoundsDesc',
            default = true,
        },
        {
            key = 'b_PlayLockpickAnimation',
            renderer = 'checkbox',
            name = 'PlayLockpickAnimation',
            description = 'PlayLockpickAnimationDesc',
            default = true,
        }
    },
}