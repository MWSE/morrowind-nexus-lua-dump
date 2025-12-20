local MOD_NAME = require('scripts.Loadouts.settingsData').MOD_NAME
local MOD_ID = require('scripts.Loadouts.settingsData').MOD_ID
local o = require('scripts.Loadouts.settingsData').o
local SECTION_KEY = require('scripts.Loadouts.settingsData').SECTION_KEY
local I = require('openmw.interfaces')
local ui = require('openmw.ui')
local util = require('openmw.util')
local input = require('openmw.input')
local async = require('openmw.async')
local getTemplate = require('scripts.Loadouts.myLib.myTemplates').getTemplate

---@param value string
---@param set function
---@param arg table
---@return ui.Layout
local function inputRenderer(value, set, arg)
        return {
                type = ui.TYPE.TextEdit,
                template = getTemplate('thin', { 0, 0, 0, 0 }, false),
                props = {
                        size = util.vector2(64, 32),
                        textSize = 32,
                        textColor = util.color.hex('ffffff'),
                        text = value
                },
                events = {
                        textChanged = async:callback(function(newText, l)
                                local text = newText:lower()
                                if text:len() <= 1 then
                                        set(text)
                                else
                                        set(value)
                                end
                        end),
                }
        }
end

I.Settings.registerRenderer('inputRenderer', inputRenderer)

I.Settings.registerRenderer('separator', function(value, set, arg)
        return {
                type = ui.TYPE.Flex,
                props = {
                        size = util.vector2(400, 0),
                        align = ui.ALIGNMENT.Center,
                        arrange = ui.ALIGNMENT.Center,
                },
                content = ui.content {
                        {
                                type = ui.TYPE.Flex,
                                props = {
                                        size = util.vector2(1, 80),
                                        align = ui.ALIGNMENT.Center,
                                        arrange = ui.ALIGNMENT.Center,
                                },
                                content = ui.content {
                                        {
                                                template = I.MWUI.templates.textHeader,
                                                props = {
                                                        text = value,
                                                        textSize = 20,
                                                }
                                        }
                                }
                        }
                }

        }
end)

input.registerTrigger {
        key = o.showLoadoutsWindow.argument.key,
        l10n = MOD_ID,
}
input.registerTrigger {
        key = o.equipLoadoutKey.argument.key,
        l10n = MOD_ID,
}

input.registerTrigger {
        key = o.switchToNextLoadout.argument.key,
        l10n = MOD_ID,
}
input.registerTrigger {
        key = o.switchToPrevLoadout.argument.key,
        l10n = MOD_ID,
}

I.Settings.registerPage {
        key = MOD_ID,
        l10n = MOD_ID,
        name = MOD_NAME,
}


local function getSettingsFor(obj)
        return {
                key = obj.key,
                name = obj.name,
                default = obj.default,
                value = obj.value,
                description = obj.description,
                renderer = obj.renderer,
                argument = obj.argument,
        }
end

local sepKey = 0

local function makeSeparator(text)
        sepKey = sepKey + 1
        return {
                key = string.format('sep-%s', sepKey),
                name = '',
                default = text,
                renderer = 'separator',
        }
end

I.Settings.registerGroup {
        key = SECTION_KEY,
        l10n = MOD_ID,
        name = MOD_NAME,
        page = MOD_ID,
        permanentStorage = true,

        settings = {
                -- makeSeparator('General Settings'),
                getSettingsFor(o.showLoadoutsWindow),
                getSettingsFor(o.equipLoadoutKey),

                getSettingsFor(o.switchToNextLoadout),
                getSettingsFor(o.switchToPrevLoadout),

        }

}
