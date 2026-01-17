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
local MOD_NAME     = require("scripts.LivelyMap.ns")
local interfaces   = require('openmw.interfaces')
local ui           = require('openmw.ui')
local util         = require('openmw.util')
local pself        = require("openmw.self")
local aux_util     = require('openmw_aux.util')
local imageAtlas   = require('scripts.LivelyMap.h3.imageAtlas')
local iutil        = require("scripts.LivelyMap.icons.iutil")
local async        = require("openmw.async")
local settings     = require("scripts.LivelyMap.settings")
local core         = require('openmw.core')
local types        = require('openmw.types')

local settingCache = {
    palleteColor1 = settings.main.palleteColor1,
}

local compassAtlas = imageAtlas.constructAtlas({
    totalTiles = 360,
    tilesPerRow = 18,
    atlasPath = "textures/LivelyMap/arrow_atlas.dds",
    tileSize = util.vector2(128, 128),
    create = true,
})
compassAtlas:spawn({
    anchor = util.vector2(0.5, 0.5),
    color = settingCache.palleteColor1,
    events = {},
    relativeSize = iutil.iconSize(),
})

settings.main.subscribe(async:callback(function(_, key)
    settingCache[key] = settings.main[key]
    if key == "palleteColor1" then
        compassAtlas:getElement().layout.props.color = settingCache.palleteColor1
        compassAtlas:getElement():update()
    end
end))

local function adjustedYaw(deg)
    local yaw = math.deg(deg)

    if yaw < 0 then yaw = util.remap(yaw, -180, 0, 181, 360) end

    return util.clamp(util.round(yaw), 1, 360)
end

--- TODO: add an off-screen indicator for where you are
local compassIcon = {
    element = compassAtlas:getElement(),
    cached = {},
    pos = function()
        return interfaces.LivelyMapPlayer.getExteriorPositionAndFacing().pos
    end,
    facing = function()
        return interfaces.LivelyMapPlayer.getExteriorPositionAndFacing().facing
    end,
    ---@param posData ViewportData
    onDraw = function(_, posData, parentAspectRatio)
        compassAtlas:getElement().layout.props.visible = true
        compassAtlas:getElement().layout.props.relativePosition = posData.viewportPos.pos

        if not posData.viewportPos.onScreen then
            compassAtlas:getElement().layout.props.visible = false
            compassAtlas:getElement():update()
            return
        end

        compassAtlas:getElement().layout.props.relativeSize = iutil.iconSize(posData, parentAspectRatio)

        if posData.viewportFacing then
            local angle = math.atan2(posData.viewportFacing.x, -1 * posData.viewportFacing.y)

            -- Convert to degrees, where 0° = East, 90° = North.
            local deg = adjustedYaw(angle)
            --print(deg .. " - " .. tostring(posData.viewportFacing))

            compassAtlas:setTile(deg)
        end
        --compassAtlas:getElement():update()
        --print("compass onDraw done: " .. aux_util.deepToString(compassAtlas:getElement().layout.props))
    end,
    onHide = function()
        compassAtlas:getElement().layout.props.visible = false
        --compassAtlas:getElement():update()
    end,
    priority = 100,
}


interfaces.LivelyMapDraw.registerIcon(compassIcon)
