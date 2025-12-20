local I = require('openmw.interfaces')
local async = require('openmw.async')
local input = require('openmw.input')
local ui = require('openmw.ui')
local core = require('openmw.core')

local version = '1.1'

I.Settings.registerRenderer('ControlledJumps/inputKeySelection', function(value, set)
    local name = 'No Key Set'
    if value then
        name = input.getKeyName(value)
    end
    return {
        template = I.MWUI.templates.box,
        content = ui.content {{
            template = I.MWUI.templates.padding,
            content = ui.content {{
                template = I.MWUI.templates.textEditLine,
                props = {
                    text = name
                },
                events = {
                    keyPress = async:callback(function(e)
                        if e.code == input.KEY.Escape then
                            return
                        end
                        set(e.code)
                    end)
                }
            }}
        }}
    }
end)

I.Settings.registerPage {
    key = 'ControlledJumps',
    l10n = 'ControlledJumps',
    name = 'ControlledJumps',
    description = "settings_description"
}

I.Settings.registerGroup {
    key = 'SettingsPlayerControlledJumps',
    page = 'ControlledJumps',
    l10n = 'ControlledJumps',
    name = 'cjSettings',
    description = 'cjSettingsDesc',
    permanentStorage = true,
    settings = {{
        key = 'cjEnable',
        name = 'cjEnableName',
        default = true,
        renderer = 'checkbox'
    }, {
        key = 'cjKey',
        name = 'cjKeyName',
        default = input.KEY.Space,
        renderer = 'ControlledJumps/inputKeySelection'
    }, {
        key = 'cjBonusSound',
        name = 'cjBonusSoundName',
        default = true,
        renderer = 'checkbox'

    }, {
        key = 'cjBonus',
        name = 'cjBonusName',
        default = true,
        renderer = 'checkbox'
    }, {
        key = 'cjBoost',
        name = 'cjBoostName',
        default = 15,
        argument = {
            max = 25,
            min = 0
        },
        renderer = 'number'
    }, {
	key = 'cjDontEatFatigue',
        name = 'cjDontEatFatigueName',
        default = false,
        renderer = 'checkbox'
    }, {
        key = 'cjEnableExpBoost',
        name = 'cjEnableExpBoostName',
        default = false,
        renderer = 'checkbox'
    }, {
	key = 'cjEnableUncontrolledJump',
        name = 'cjEnableUncontrolledJumpName',
        default = false,
        renderer = 'checkbox'
    }}

}

I.Settings.registerGroup {
    key = 'SettingsPlayerControlledJumps2',
    page = 'ControlledJumps',
    l10n = 'ControlledJumps',
    name = 'cjShortJump',
    description = 'cjShortJumpDesc',
    permanentStorage = true,
    settings = {{
        key = 'cjEnableShort',
        name = 'cjEnableShortName',
        default = true,
        renderer = 'checkbox'
    }, {
        key = 'cjKeyShort',
        name = 'cjKeyShortName',
        default = "Shift",

        argument = {
            l10n = 'ControlledJumps',
            items = {"Shift", "Ctrl", "Alt"}
        },
        renderer = 'select'
    }, {
        key = 'cjPercent',
        name = 'cjPercentName',
        default = 40,
        argument = {
            max = 99,
            min = 0
        },
        renderer = 'number'
    }}
}

I.Settings.registerGroup {
    key = 'SettingsPlayerControlledJumps3',
    page = 'ControlledJumps',
    l10n = 'ControlledJumps',
    name = 'cjViewJump',
    description = 'cjViewJumpDesc',
    permanentStorage = true,
    settings = {{
        key = 'cjEnableViewJump',
        name = 'cjEnableViewJumpName',
        default = false,
        renderer = 'checkbox'
    }, {
        key = 'cjViewJumpFromGround',
        name = 'cjViewJumpFromGroundName',
        default = false,
        renderer = 'checkbox'
    }}

}
