---@omw-context player
---@diagnostic disable: missing-fields
---@diagnostic disable: assign-type-mismatch
local ui = require('openmw.ui')
local auxUi = require("openmw_aux.ui")
local util = require('openmw.util')
local v2 = util.vector2
local I = require("openmw.interfaces")
local self = require("openmw.self")
local core = require("openmw.core")

local buttonTemplate = require("scripts.BoonsAndBurdens.utils.button")

local textSize = 16

local topPadding = 6
local bottomPadding = 8
local centerPadding = 8
local sidePadding = 10
local windowWidth = 600

local vampireWindow = {}

local function padding(x, y)
    return {
        props = {
            size = util.vector2(x, y)
        }
    }
end

vampireWindow.show = function()
    local root

    local header = {
        name = "header_flex",
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
        },
        content = ui.content {
            padding(sidePadding, 0),
            {
                name = "header",
                template = I.MWUI.templates.textParagraph,
                props = {
                    size = v2(windowWidth, 0),
                    text = "In your head you hear many voices, but three of them stand out the most.\n" ..
                        "\n" ..
                        "===================\n" ..
                        "\n" ..
                        "As a Quarra, you are gifted above all. Your strength and fighting skills are unmatched by any. " ..
                        "Throw away your armor and weapons, for so great is our skill, that they are unneeded.\n" ..
                        "\n" ..
                        "As an Aundae, you will find your mind even more powerful than vampires of other clans, and your spellcasting unparalleled. " ..
                        "We have achieved perfection of the mind and the body. We are sublime.\n" ..
                        "\n" ..
                        "The Berne vampire travels as the shadows do. Silent, unnoticed. " ..
                        "We are more agile than the other clans, and even on crowded streets, we pass unnoticed. " ..
                        "Our victims never suspect our presence... until their blood is on our lips.\n" ..
                        "\n" ..
                        "===================\n" ..
                        "\n" ..
                        "You have 3 days to prepare. Use this time wisely.",
                    textSize = textSize,
                    textAlignH = ui.ALIGNMENT.Center,
                }
            },
            padding(sidePadding, 0),
        }
    }

    local content = {
        name = "content",
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
        },
        content = ui.content {
            buttonTemplate.button(
                "Quarra",
                textSize,
                function()
                    self.type.spells(self):add("vampire blood quarra")
                    auxUi.deepDestroy(root)
                    I.UI.setMode()
                    core.sendGlobalEvent('Unpause', 'ui')
                end
            ),
            padding(centerPadding, 0),
            buttonTemplate.button(
                "Aundae",
                textSize,
                function()
                    self.type.spells(self):add("vampire blood aundae")
                    auxUi.deepDestroy(root)
                    I.UI.setMode()
                    core.sendGlobalEvent('Unpause', 'ui')
                end
            ),
            padding(centerPadding, 0),
            buttonTemplate.button(
                "Berne",
                textSize,
                function()
                    self.type.spells(self):add("vampire blood berne")
                    auxUi.deepDestroy(root)
                    I.UI.setMode()
                    core.sendGlobalEvent('Unpause', 'ui')
                end
            ),
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

return vampireWindow
