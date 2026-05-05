---@diagnostic disable: missing-fields
local ui = require('openmw.ui')
local auxUi = require("openmw_aux.ui")
local util = require('openmw.util')
local v2 = util.vector2
local I = require("openmw.interfaces")
local self = require("openmw.self")
local core = require("openmw.core")

local buttonTemplate = require("scripts.WretchedAndWeird.utils.button")

local textSize = 16

local topPadding = 6
local bottomPadding = 8
local centerPadding = 8
local sidePadding = 4
local windowWidth = 500

local rewardWindow = {}

local function padding(x, y)
    return {
        props = {
            size = util.vector2(x, y)
        }
    }
end

-- local function borderPadding(content, size)
--     return {
--         name = "wrapper",
--         template = I.MWUI.templates.borders,
--         props = {
--             size = size
--         },
--         content = ui.content {
--             {
--                 name = "padding",
--                 template = I.MWUI.templates.padding,
--                 content = ui.content { content }
--             }
--         }
--     }
-- end

rewardWindow.show = function()
    local root

    local header = {
        name = "header",
        template = I.MWUI.templates.textParagraph,
        props = {
            size = v2(windowWidth, 0),
            text = "You have turned your life around.\n\n" ..
                "You are no longer a worthless wretch, and you feel a burgeoning sense of pride and achievement. " ..
                "The gods smile on your accomplishment, and wish to bestow a blessing upon you:\n\n" ..
                "5x Fortify Maximum Magicka\n30pt Fortify Attack\n100pt Fortify Unarmored\n\n" ..
                "Do you accept?",
            textSize = textSize,
            textAlignH = ui.ALIGNMENT.Center,
        }
    }

    local content = {
        name = "content",
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
        },
        content = ui.content {
            padding(sidePadding, 0),
            buttonTemplate.button(
                "I have earned this!",
                textSize,
                function()
                    self.type.spells(self):add("lack_ww_WretchBlessing")
                    auxUi.deepDestroy(root)
                    I.UI.setMode()
                    core.sendGlobalEvent('Unpause', 'ui')
                end
            ),
            padding(centerPadding, 0),
            buttonTemplate.button(
                "I am not worthy",
                textSize,
                function()
                    I.UI.showInteractiveMessage(
                        "You have gotten this far on your own. " ..
                        "You will continue to improve yourself without the help of the gods."
                    )
                    auxUi.deepDestroy(root)
                end
            ),
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

return rewardWindow
