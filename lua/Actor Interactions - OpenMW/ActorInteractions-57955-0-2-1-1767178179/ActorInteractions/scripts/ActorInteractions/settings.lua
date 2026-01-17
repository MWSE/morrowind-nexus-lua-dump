local MOD_NAME       = require('scripts.ActorInteractions.settingsData').MOD_NAME
local MOD_ID         = require('scripts.ActorInteractions.settingsData').MOD_ID
local o              = require('scripts.ActorInteractions.settingsData').o
local SECTION_KEY    = require('scripts.ActorInteractions.settingsData').SECTION_KEY
local I              = require('openmw.interfaces')
local ui             = require('openmw.ui')
local util           = require('openmw.util')
local async          = require('openmw.async')
local input          = require('openmw.input')
local storage        = require('openmw.storage')
local myConstants    = require('scripts.ActorInteractions.myLib.myConstants')
local gui            = require('scripts.ActorInteractions.myLib.myGUI')
local bindingSection = storage.playerSection('OMWInputBindings')

local mySection      = storage.playerSection(SECTION_KEY)

local customRenderer = {
        resetButton = 'resetButton' .. MOD_ID,
        separator = 'separator' .. MOD_ID
}


I.Settings.registerRenderer(customRenderer.separator, function(value, set, arg)
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
                                                        text = arg.text,
                                                        textSize = 20,
                                                }
                                        }
                                }
                        }
                }

        }
end)



I.Settings.registerRenderer(customRenderer.resetButton, function(value, set, arg)
        local el
        el = ui.create {
                type = ui.TYPE.Flex,
                props = {
                        horizontal = true,
                },
                content = ui.content {
                        {
                                template = I.MWUI.templates.textNormal,
                                props = {
                                        text = 'Remove',
                                        textColor = myConstants.colors.normal,
                                },
                                events = {
                                        mouseClick = async:callback(function()
                                                for _, key in pairs(arg.all) do
                                                        local settingsObj = o[key]
                                                        local myDefault = mySection:get(settingsObj.key)
                                                        if settingsObj.renderer == 'inputBinding' then
                                                                for i, v in pairs(bindingSection:asTable()) do
                                                                        if v.key == settingsObj.argument.key then
                                                                                bindingSection:set(i, nil)
                                                                        end
                                                                end

                                                                -- bindingSection:set(myDefault, nil)
                                                                mySection:set(settingsObj.key, myDefault)
                                                        end
                                                end
                                        end),
                                        focusGain = async:callback(function(_, l)
                                                l.props.textColor = myConstants.colors.hover
                                                el:update()
                                        end),
                                        focusLoss = async:callback(function(_, l)
                                                l.props.textColor = myConstants.colors.normal
                                                el:update()
                                        end),
                                }
                        },
                        gui.makeInt(50, 0),
                        {
                                template = I.MWUI.templates.textNormal,
                                props = {
                                        text = 'Reset',
                                        textColor = myConstants.colors.normal,
                                },
                                events = {
                                        mouseClick = async:callback(function()
                                                for _, key in pairs(arg.all) do
                                                        local settingsObj = o[key]
                                                        local myDefault = mySection:get(settingsObj.key)
                                                        if settingsObj.renderer == 'inputBinding' then
                                                                for i, v in pairs(bindingSection:asTable()) do
                                                                        if v.key == settingsObj.argument.key then
                                                                                bindingSection:set(i, nil)
                                                                        end
                                                                end

                                                                bindingSection:set(myDefault, settingsObj.resetBind)
                                                                mySection:set(settingsObj.key, myDefault)
                                                        end
                                                end
                                        end),
                                        focusGain = async:callback(function(_, l)
                                                l.props.textColor = myConstants.colors.hover
                                                el:update()
                                        end),
                                        focusLoss = async:callback(function(_, l)
                                                l.props.textColor = myConstants.colors.normal
                                                el:update()
                                        end),
                                }
                        }
                }



        }
        return el
end)

input.registerTrigger {
        key = o.openGivawayWindow.argument.key,
        l10n = MOD_ID,
}

input.registerTrigger {
        key = o.GP_openGivawayWindow.argument.key,
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

---@param text string
---@return table
local function makeSeparator(text)
        sepKey = sepKey + 1
        local sepKeyStr = string.format('GIVEAWAYsep-%s', sepKey)
        return {
                key = sepKeyStr,
                name = '',
                default = sepKeyStr,
                renderer = customRenderer.separator,
                argument = {
                        text = text
                }
        }
end

---@param keys string[]
---@return table
local function makeReset(keys)
        sepKey = sepKey + 1
        local sepKeyStr = string.format('GIVEAWAYreset-%s', sepKey)

        return {
                key = sepKeyStr,
                name = '',
                default = sepKeyStr,
                renderer = customRenderer.resetButton,
                argument = {
                        all = keys,
                }
        }
end

I.Settings.registerGroup {
        key = SECTION_KEY,
        l10n = MOD_ID,
        name = MOD_NAME,
        page = MOD_ID,
        permanentStorage = true,

        settings = {
                makeSeparator('General'),
                getSettingsFor(o.selectWindowView),
                getSettingsFor(o.requirementMult),

                makeSeparator('Keyboard Keybinds'),
                makeReset({ o.openGivawayWindow.key }),
                getSettingsFor(o.openGivawayWindow),

                makeSeparator('Controller Keybinds'),
                makeReset({ o.GP_openGivawayWindow.key }),
                getSettingsFor(o.GP_openGivawayWindow),

        }

}
