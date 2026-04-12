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
local MOD_NAME       = require("scripts.ErnGlider.ns")
local core           = require("openmw.core")
local pself          = require("openmw.self")
local camera         = require('openmw.camera')
local util           = require('openmw.util')
local async          = require("openmw.async")
local types          = require('openmw.types')
local input          = require('openmw.input')
local controls       = require('openmw.interfaces').Controls
local nearby         = require('openmw.nearby')
local animation      = require('openmw.animation')
local ui             = require('openmw.ui')
local aux_util       = require('openmw_aux.util')
local interfaces     = require("openmw.interfaces")
local settings       = require("scripts.ErnGlider.settings")
local bar            = require("scripts.ErnGlider.ui.bar")
local toastcontainer = require("scripts.ErnGlider.ui.toastcontainer")
local localization   = core.l10n(MOD_NAME)
local uiInterface    = require("openmw.interfaces").UI

-- from PCP-OpenMW
-- Get a usable color value from a fallback in openmw.cfg
local function configColor(setting)
    local v = core.getGMST('FontColor_color_' .. setting)
    local values = {}
    for i in v:gmatch('([^,]+)') do table.insert(values, tonumber(i)) end
    local color = util.color.rgb(values[1] / 255, values[2] / 255, values[3] / 255)
    return color
end

return {
    configColor = configColor
}
