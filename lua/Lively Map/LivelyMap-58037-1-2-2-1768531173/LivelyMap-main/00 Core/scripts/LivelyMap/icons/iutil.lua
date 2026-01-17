--[[
LivelyMap for OpenMW.
Copyright (C) Erin Pentecost 2025

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
local util         = require('openmw.util')
local pself        = require("openmw.self")
local mutil        = require("scripts.LivelyMap.mutil")
local nearby       = require('openmw.nearby')
local settings     = require("scripts.LivelyMap.settings")
local async        = require("openmw.async")
local camera       = require("openmw.camera")
local myui         = require('scripts.LivelyMap.pcp.myui')
local interfaces   = require('openmw.interfaces')
local ui           = require('openmw.ui')
local async        = require("openmw.async")

local settingCache = {
    iconScale = settings.main.iconScale,
}

settings.automatic.subscribe(async:callback(function(_, key)
    settingCache[key] = settings.main[key]
end))

local baseIconSize = util.vector2(0.05, 0.05)
local function iconSize(posData, parentAspectRatio)
    if not parentAspectRatio then
        parentAspectRatio = util.vector2(1, 1)
    end
    if posData then
        local dist = (camera.getPosition() - posData.mapWorldPos):length()
        dist = util.clamp(dist, 100, 500)
        return (baseIconSize * util.remap(dist, 100, 500, 1, 0.5) * settingCache.iconScale):ediv(parentAspectRatio)
    else
        return baseIconSize:ediv(parentAspectRatio)
    end
end

local function hoverTextLayout(text, color, path)
    return {
        name = 'mainV',
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
        },
        content = ui.content {
            {
                type = ui.TYPE.Image,
                props = {
                    relativePosition = util.vector2(0, 0.5),
                    anchor = util.vector2(0.5, 0.5),
                    size = util.vector2(20, 20),
                    resource = ui.texture {
                        path = path,
                    },
                    color = color,
                }
            },
            text ~= "" and myui.padWidget(10, 0) or nil,
            text ~= "" and {
                template = interfaces.MWUI.templates.textHeader,
                type = ui.TYPE.Text,
                alignment = ui.ALIGNMENT.End,
                props = {
                    textAlignV = ui.ALIGNMENT.Center,
                    relativePosition = util.vector2(0, 0.5),
                    text = text,
                    textSize = 20,
                    textColor = color or myui.interactiveTextColors.normal.default,
                }
            } or nil,
        }
    }
end

return {
    iconSize = iconSize,
    hoverTextLayout = hoverTextLayout,
}
