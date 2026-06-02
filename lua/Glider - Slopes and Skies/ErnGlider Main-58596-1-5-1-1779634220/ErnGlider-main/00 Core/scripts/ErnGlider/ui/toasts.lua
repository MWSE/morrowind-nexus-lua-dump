--[[
ErnGlider for OpenMW.
Copyright (C) 2026 Erin Pentecost

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]
local MOD_NAME     = require("scripts.ErnGlider.ns")
local core         = require("openmw.core")
local pself        = require("openmw.self")
local camera       = require('openmw.camera')
local util         = require('openmw.util')
local async        = require("openmw.async")
local types        = require('openmw.types')
local input        = require('openmw.input')
local controls     = require('openmw.interfaces').Controls
local nearby       = require('openmw.nearby')
local animation    = require('openmw.animation')
local ui           = require('openmw.ui')
local aux_util     = require('openmw_aux.util')
local interfaces   = require("openmw.interfaces")
local settings     = require("scripts.ErnGlider.settings")
local common       = require("scripts.ErnGlider.ui.common")
local localization = core.l10n(MOD_NAME)
local uiInterface  = require("openmw.interfaces").UI

local function newTextToast(text, colorID)
    colorID = colorID or "normal"
    return ui.create {
        type = ui.TYPE.Text,
        props = {
            text = text,
            textColor = common.configColor(colorID),
            textShadow = true,
            textShadowColor = util.color.rgba(0, 0, 0, 0.9),
            textAlignV = ui.ALIGNMENT.Center,
            textAlignH = ui.ALIGNMENT.Center,
            textSize = 18,
            --relativePosition = util.vector2(0.5, 0.5),
            anchor = util.vector2(0.5, 0.5),
        }
    }
end

return {
    newTextToast = newTextToast,
}
