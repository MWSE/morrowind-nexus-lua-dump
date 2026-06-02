local ui = require('openmw.ui')
local util = require('openmw.util')
local auxUi = require('openmw_aux.ui')
local templates = require('openmw.interfaces').MWUI.templates

local borders = require("scripts.quest_guider_lite.ui.borders")
local uiUtils = require("scripts.quest_guider_lite.ui.utils")

local config = require("scripts.quest_guider_lite.config")

local this = {}

this.boxSolidThick = auxUi.deepLayoutCopy(templates.boxSolidThick)
this.boxSolid = auxUi.deepLayoutCopy(templates.boxSolid)
this.box = auxUi.deepLayoutCopy(templates.box)

pcall(function ()
    this.boxSolidThick.content[1].template.props.color = config.data.ui.backgroundColor
    this.boxSolid.content[1].template.props.color = config.data.ui.backgroundColor
    this.box.type = ui.TYPE.Widget
end)


this.btnBoxSolidThick = {
    type = ui.TYPE.Container,
    content = ui.content{
        {
            type = ui.TYPE.Image,
            props = {
                resource = uiUtils.whiteTexture,
                color = config.data.ui.backgroundColor,
            },
        },
        {
            type = ui.TYPE.Image,
            props = {
                resource = borders.textures[11],
                tileH = true,
                tileV = false,
                size = util.vector2(1, 4),
                relativeSize = util.vector2(1, 0),
                position = util.vector2(4, 4),
                relativePosition = util.vector2(0, 1),
            },
        }
    },
}

this.btnBoxSolidThick.content:add {
    external = { slot = true },
    props = {
        position = util.vector2(4, 4),
        relativeSize = util.vector2(1, 1),
    }
}

this.underlineBoxThin = {
    type = ui.TYPE.Container,
    content = ui.content{
        {
            type = ui.TYPE.Image,
            props = {
                resource = borders.textures[3],
                tileH = true,
                tileV = false,
                size = util.vector2(0, 2),
                relativeSize = util.vector2(1, 0),
                position = util.vector2(2, 2),
                relativePosition = util.vector2(0, 1),
            },
        }
    },
}

this.underlineBoxThin.content:add {
    external = { slot = true },
    props = {
        position = util.vector2(2, 2),
        relativeSize = util.vector2(1, 1),
    }
}

return this