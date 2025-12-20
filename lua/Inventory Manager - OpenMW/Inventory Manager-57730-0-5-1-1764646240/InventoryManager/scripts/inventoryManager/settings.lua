local MOD_NAME = require('scripts.inventoryManager.settings_stuff').MOD_NAME
local MOD_ID = require('scripts.inventoryManager.settings_stuff').MOD_ID
local o = require('scripts.inventoryManager.settings_stuff').o
local sectionKey = require('scripts.inventoryManager.settings_stuff').sectionKey
local I = require('openmw.interfaces')
local input = require('openmw.input')
local ui = require('openmw.ui')
local util = require('openmw.util')
local async = require('openmw.async')
local getTemplate = require('scripts.inventoryManager.myLib.myTemplates').getTemplate

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


I.Settings.registerPage {
        key = MOD_ID,
        l10n = MOD_ID,
        name = MOD_NAME,
        description = [[The window will only show for #FF0000NON-OWNED#caa560 containers since stealing
is not implemented.

Actions:
- #FFFFFFMouse click: #caa560Move item from/to player's inventory/container (Whole stack).
- #FFFFFFMouse click + Alt: #caa560Same as Mouse click but one single item.
- #FFFFFFMouse click + Shift: #caa560Equip/Use item (must be in player's inventory).
- #FFFFFFMouse click + Ctrl: #caa560Drop item to the ground.
- #FFFFFFMouse click + Super\Win: #caa560Lock/Unlock item. (can also be toggled by clicking the checkbox)
]]
}

input.registerTrigger {
        key = o.showWindowKey.argument.key,
        l10n = MOD_ID,
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
