local ui = require('openmw.ui')
local util = require('openmw.util')
local auxUi = require('openmw_aux.ui')
local templates = require('openmw.interfaces').MWUI.templates

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


return this