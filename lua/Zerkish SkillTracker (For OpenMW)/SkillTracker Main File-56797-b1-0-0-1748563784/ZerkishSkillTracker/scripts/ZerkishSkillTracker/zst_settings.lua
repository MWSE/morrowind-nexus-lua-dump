local async = require('openmw.async')
local I     = require('openmw.interfaces')
local util  = require('openmw.util')
local input = require('openmw.input')
local ui = require('openmw.ui')

local constants = require('scripts.omw.mwui.constants')

I.Settings.registerRenderer('ZST_input', function(value, set, arg)

    local wrapper = {
        template = I.MWUI.templates.box,
        props = {},
        content = ui.content({
            {
                template = I.MWUI.templates.textEditLine,
                --type = ui.TYPE.TextEdit,
                props = {
                    size = util.vector2(85, 18),
                    text = value and input.getKeyName(value) or 'None',
                    textColor = constants.normalColor,
                    textSize = 16,
                    textAlignV = ui.ALIGNMENT.Center,
                    textAlignH = ui.ALIGNMENT.Start,
                },
                events = {
                    keyPress = async:callback(function(evt)
                        if evt.code == input.KEY.Escape then return end
                        set(evt.code)
                    end)
                }
            }
        })
    }

    return wrapper
end)

local MAX_SKILLS = 10

I.Settings.registerPage {
    key = 'ZSTPage',
    name = 'Zerkish SkillTracker',
    description = 'Zerkish SkillTracker for OpenMW',
    l10n = 'ZST_l10n',
}

I.Settings.registerGroup {
    key = 'SettingsZSTAAMain',
    name = 'Main',
    description = 'Main Settings',
    page = 'ZSTPage',
    l10n = 'ZST_l10n',
    permanentStorage = true,

    settings = {
        {
            key = 'enable_tracker',
            renderer = 'checkbox',
            name = 'Enable SkillTracker HUD',
            default = true,
            description = nil,
        },
        {
            key = 'toggle_config_key',
            renderer = 'ZST_input',
            name = 'Config Window Key',
            default = input.KEY.K,
        },
        {
            name = 'Window Position X',
            key = 'window_position_x',
            renderer = 'number',
            default = 0.0,
            description = 'Move by dragging the window.',
            argument = {
                integer = false,
            }
        },
        {
            name = 'Window Position Y',
            key = 'window_position_y',
            renderer = 'number',
            default = 0.0,
            description = 'Move by dragging the window.',
            argument = {
                integer = false,
            }
        },
        {
            name = 'Update Interval',
            key = 'update_interval',
            renderer = 'number',
            default = 0.2,
            description = 'How often the HUD Updates in seconds.',
            argument = {
                integer = false,
                min = 0.0,
            }
        },
        {
            key = 'enable_compat_mode',
            renderer = 'checkbox',
            name = 'Enable Compatibility Mode',
            default = false,
            description = 'Enable if you have issues with UI Overhaul Mods. Reload After.',
        },
    },
}

I.Settings.registerGroup {
    key = 'SettingsZSTZAAppearance',
    name = 'Main',
    description = 'Appearance',
    page = 'ZSTPage',
    l10n = 'ZST_l10n',
    permanentStorage = true,

    settings = {
        {
            name = 'Window Alpha',
            key = 'alpha',
            renderer = 'number',
            default = 1.0,
            description = nil,
            argument = {
                integer = false,
                min = 0.0,
                max = 1.0,
            }
        },
        {
            name = 'Background Alpha',
            key = 'bg_alpha',
            renderer = 'number',
            default = 0.65,
            description = nil,
            argument = {
                integer = false,
                min = 0.0,
                max = 1.0,
            }
        },
        {
            name = 'Window Border',
            key = 'window_border',
            renderer = 'checkbox',
            default = true,
            description = nil,
        },
        {
            name = 'Skillgain Flash Time',
            key = 'flash_time',
            renderer = 'number',
            default = 2.0,
            description = nil,
            argument = {
                integer = false,
                min = 0.0,
                max = 10.0,
            }
        },

    },
}

-- local function addSkill(t, num)
--     table.insert(t, {
--         key = 'skill_' .. tostring(num),
--         renderer = 'select',
--         name = 'Skill ' .. tostring(num),
--         default = SKILL_NAMES[1],
--         argument = {
--             disabled = false,
--             items = SKILL_NAMES,
--             l10n = 'ZST_l10n',
--         },
--     })
-- end

-- local skillGroupSettings = {}

-- for i=1, MAX_SKILLS do
--     addSkill(skillGroupSettings, i)
-- end

-- I.Settings.registerGroup {
--     key = 'SettingsZSTAZSkills',
--     name = 'Tracked Skills',
--     description = nil,
--     page = 'ZSTPage',
--     l10n = 'ZST_l10n',
--     permanentStorage = true,

--     settings = skillGroupSettings
-- }

-- return {
--     SKILL_NAMES = SKILL_NAMES,
--     MAX_SKILLS = MAX_SKILLS,
-- }