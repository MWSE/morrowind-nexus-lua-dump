--[[
    widgets.lua
    Higher-level reusable widget templates: text edits, selects, checkboxes,
    buttons, scroll bars, scrollables, and modals.
]]

local ui = require('openmw.ui')
local util = require('openmw.util')
local async = require('openmw.async')
local core = require('openmw.core')
local I = require('openmw.interfaces')

local C = require('scripts.niftyspellpack.ui.constants')
local Primitives = require('scripts.niftyspellpack.ui.primitives')

local l10n = core.l10n('NiftySpellPack')
local colors = C.uiColors
local createPaddingTemplate = Primitives.createPaddingTemplate
local playClickFx = Primitives.playClickFx
local buttonBordersTemplate = Primitives.buttonBordersTemplate

local state = require('scripts.niftyspellpack.ui.state')

local Widgets = {}

function Widgets.button(text, size, callback, active, color)
    local button = ui.create {
        template = buttonBordersTemplate,
        props = {
            size = size or util.vector2(0, 0),
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                props = {
                    autoSize = false,
                    relativeSize = util.vector2(1, 1),
                    arrange = ui.ALIGNMENT.Center,
                    align = ui.ALIGNMENT.Center,
                },
                content = ui.content {
                    {
                        template = I.MWUI.templates.textNormal,
                        props = {
                            text = text,
                            textColor = active and colors.ACTIVE or (color or colors.DEFAULT),
                        },
                    },
                },
            },
        },
        events = {},
        userData = {
            focused = false,
        }
    }

    button.layout.events.focusGain = async:callback(function(_, layout)
        if I.UI.getMode() == nil then return false end
        layout.userData.focused = true
        layout.content[1].content[1].props.textColor = active and colors.ACTIVE_LIGHT or colors.DEFAULT_LIGHT
        pcall(button.update, button)
        return true
    end)

    button.layout.events.focusLoss = async:callback(function(_, layout)
        if I.UI.getMode() == nil then return false end
        layout.userData.focused = false
        layout.content[1].content[1].props.textColor = active and colors.ACTIVE or (color or colors.DEFAULT)
        pcall(button.update, button)
        return true
    end)

    button.layout.events.mousePress = async:callback(function(_, layout)
        if I.UI.getMode() == nil then return false end
        playClickFx()
        layout.content[1].content[1].props.textColor = active and colors.ACTIVE_PRESSED or colors.DEFAULT_PRESSED
        button:update()
    end)

    button.layout.events.mouseRelease = async:callback(function(_, layout)
        if I.UI.getMode() == nil then return false end
        layout.content[1].content[1].props.textColor = layout.userData.focused and (active and colors.ACTIVE_LIGHT or colors.DEFAULT_LIGHT) or (active and colors.ACTIVE or (color or colors.DEFAULT))
        button:update()
        if callback then callback() end
    end)

    return button
end

function Widgets.modal(content)
    return {
        layer = "Modal",
        props = {
            relativeSize = util.vector2(1, 1),
        },
        content = ui.content {
            {
                type = ui.TYPE.Image,
                props = {
                    resource = ui.texture { path = 'black' },
                    size = util.vector2(0, 0),
                    relativeSize = util.vector2(1, 1),
                    alpha = 0.5,
                }
            },
            {
                template = I.MWUI.templates.boxSolidThick,
                props = {
                    anchor = util.vector2(0.5, 0.5),
                    relativePosition = util.vector2(0.5, 0.5),
                },
                content = ui.content { content },
            },
        }
    }
end

function Widgets.confirmModal(onConfirm, onCancel, text)
    return Widgets.modal(Primitives.paddedLayout({
        type = ui.TYPE.Flex,
        props = {
            arrange = ui.ALIGNMENT.Center,
        },
        content = ui.content {
            text and {
                template = I.MWUI.templates.textParagraph,
                props = {
                    text = text,
                    size = util.vector2(0, 0),
                    relativeSize = util.vector2(1, 0),
                    textAlignH = ui.ALIGNMENT.Center,
                },
            } or {},
            text and createPaddingTemplate(16) or {},
            {
                type = ui.TYPE.Flex,
                props = {
                    horizontal = true,
                    align = ui.ALIGNMENT.Center,
                },
                content = ui.content {
                    Widgets.button(l10n('UI_Yes'), util.vector2(128, 32), function()
                        if onConfirm then
                            onConfirm()
                        end
                    end),
                    I.MWUI.templates.interval,
                    Widgets.button(l10n('UI_No'), util.vector2(128, 32), function()
                        if onCancel then
                            onCancel()
                        end
                    end),
                },
            },
        },
    }, 16))
end

function Widgets.choiceModal(title, choices)
    local buttons = {}
    for i, choice in ipairs(choices) do
        table.insert(buttons, Widgets.button(choice.text, util.vector2(400, 32), function()
            if choice.callback then
                choice.callback()
            end
        end))
        if i < #choices then
            table.insert(buttons, I.MWUI.templates.interval)
        end
    end

    return Widgets.modal(
        Primitives.paddedLayout({
            type = ui.TYPE.Flex,
            props = {
                arrange = ui.ALIGNMENT.Center,
            },
            content = ui.content {
                title and {
                    template = I.MWUI.templates.textParagraph,
                    props = {
                        text = title,
                        textAlignH = ui.ALIGNMENT.Center,
                        size = util.vector2(0, 0),
                        relativeSize = util.vector2(1, 0),
                    },
                } or {},
                title and createPaddingTemplate(16) or {},
                {
                    type = ui.TYPE.Flex,
                    props = {
                        horizontal = false,
                        align = ui.ALIGNMENT.Center,
                    },
                    content = ui.content(buttons),
                },
            },
        }, 16)
    )
end

return Widgets
