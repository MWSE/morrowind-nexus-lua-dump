local MOD_NAME = require('scripts.inventoryManager.settings_stuff').MOD_NAME
local MOD_ID = require('scripts.inventoryManager.settings_stuff').MOD_ID
local o = require('scripts.inventoryManager.settings_stuff').o
local sectionKey = require('scripts.inventoryManager.settings_stuff').sectionKey
local I = require('openmw.interfaces')
local input = require('openmw.input')
local ui = require('openmw.ui')
local util = require('openmw.util')

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


I.Settings.registerPage {
        key = MOD_ID,
        l10n = MOD_ID,
        name = MOD_NAME,
        -- description = "Inventory Manager"
}


local function getSettingsFor(obj)
        local args = {}
        for i, v in pairs(obj.argument) do
                args[i] = v
        end
        return {
                key = obj.key,
                name = obj.name,
                default = obj.default,
                value = obj.value,
                description = obj.description,
                renderer = obj.renderer,
                argument = args,
        }
end

input.registerTrigger {
        key = o.showWindowKey.argument.key,
        l10n = MOD_ID,
}

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
        key = sectionKey,
        l10n = MOD_ID,
        name = MOD_NAME,
        page = MOD_ID,
        permanentStorage = true,

        settings = {
                makeSeparator('General Settings'),
                getSettingsFor(o.showWindowKey),

                makeSeparator('List Settings'),
                getSettingsFor(o.labelsSize),
                getSettingsFor(o.listItemTextSize),
                getSettingsFor(o.listScrollAmount),
                getSettingsFor(o.scrollDirection),
                getSettingsFor(o.listAlignNumbers),

                makeSeparator('Tooltip Settings'),
                getSettingsFor(o.toolTipTextSize),
                getSettingsFor(o.toolTipDelay),
                getSettingsFor(o.bookPreviewLength),
                getSettingsFor(o.bookPreviewWordsPerLine),
        }

}
