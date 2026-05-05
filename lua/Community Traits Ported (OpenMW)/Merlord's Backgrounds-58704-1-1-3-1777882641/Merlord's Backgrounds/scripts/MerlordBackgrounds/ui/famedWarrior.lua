---@diagnostic disable: missing-fields
local ui = require('openmw.ui')
local auxUi = require("openmw_aux.ui")
local util = require('openmw.util')
local v2 = util.vector2
local I = require("openmw.interfaces")
local core = require("openmw.core")
local async = require("openmw.async")
local self = require("openmw.self")

local buttonTemplate = require("scripts.MerlordBackgrounds.utils.button")

local textSize = 16

local topPadding = 6
local bottomPadding = 8
local centerPadding = 4
local sidePadding = 4
local inputWidth = 250

local swordWindow = {}

local function padding(x, y)
    return {
        props = {
            size = util.vector2(x, y)
        }
    }
end

local function borderPadding(content, size)
    return {
        name = "wrapper",
        template = I.MWUI.templates.borders,
        props = {
            size = size
        },
        content = ui.content {
            {
                name = "padding",
                template = I.MWUI.templates.padding,
                content = ui.content { content }
            }
        }
    }
end

swordWindow.show = function ()
    local root
    local name = ""

    local header = {
        name = "header",
        type = ui.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props = {
            size = v2(inputWidth, textSize),
            text = "Name your sword",
            textSize = textSize,
        }
    }

    local textInput = ui.create {
        name = "textInput",
        type = ui.TYPE.TextEdit,
        template = I.MWUI.templates.textEditLine,
        props = {
            size = v2(inputWidth - 6, 0),
            textSize = textSize,
        },
        events = {
            textChanged = async:callback(function(text)
                name = text
            end),
        },
    }

    local inputWrapper = borderPadding(textInput, v2(inputWidth, textSize + 8))

    local confirm = buttonTemplate.button(
        "Confirm",
        textSize,
        function()
            if name == "" then return end
            core.sendGlobalEvent(
                "MerlordsTraits_generateFamedSword",
                { swordName = name, player = self }
            )
            auxUi.deepDestroy(root)
        end
    )

    local content = {
        name = "content",
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
        },
        content = ui.content {
            padding(sidePadding, 0),
            inputWrapper,
            padding(centerPadding, 0),
            confirm,
            padding(sidePadding, 0),
        }
    }

    root = ui.create {
        name = "root",
        layer = "Windows",
        template = I.MWUI.templates.boxTransparentThick,
        props = {
            relativePosition = v2(0.5, 0.5),
            anchor = v2(0.5, 0.5),
        },
        content = ui.content { {
            name = "rootPadding",
            template = I.MWUI.templates.padding,
            content = ui.content { {
                name = "flex_V1",
                type = ui.TYPE.Flex,
                props = {
                    horizontal = false,
                    arrange = ui.ALIGNMENT.Center,
                },
                content = ui.content {
                    padding(0, topPadding),
                    header,
                    padding(0, centerPadding),
                    content,
                    padding(0, bottomPadding),
                }
            } }
        } }
    }

    root:update()
end

return swordWindow
