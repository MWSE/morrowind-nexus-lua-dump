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
local interfaces = require('openmw.interfaces')
local ui         = require('openmw.ui')
local util       = require('openmw.util')
local pself      = require("openmw.self")
local mutil      = require("scripts.LivelyMap.mutil")
local nearby     = require('openmw.nearby')
local settings   = require("scripts.LivelyMap.settings")
local async      = require("openmw.async")
local iutil      = require("scripts.LivelyMap.icons.iutil")


local debugEnabled = settings.main.debug
settings.main.subscribe(async:callback(function(_, key)
    if key == "debug" then
        debugEnabled = settings.main.debug
    end
end))

local psoUnlocked = settings.pso.psoUnlock
settings.main.subscribe(async:callback(function(_, key)
    if key == "psoUnlock" then
        psoUnlocked = settings.pso.psoUnlock
    end
end))

local debugIcons = {}

local function makeDebugPips()
    for x = -2, 2, 1 do
        for y = -2, 2, 1 do
            if not (x == 0 and y == 0) then
                local offset = util.vector3(
                    x * mutil.CELL_SIZE / 2,
                    y * mutil.CELL_SIZE / 2,
                    100 * mutil.CELL_SIZE
                )

                local element = ui.create {
                    name = "debug_" .. tostring(x) .. "_" .. tostring(y),
                    type = ui.TYPE.Image,
                    props = {
                        visible = false,
                        relativePosition = util.vector2(0.2, 0.2),
                        anchor = util.vector2(0.5, 0.5),
                        relativeSize = iutil.iconSize(),
                        resource = ui.texture {
                            path = "textures/LivelyMap/debug.png"
                        }
                    }
                }
                local worldPos = function()
                    if not (debugEnabled or psoUnlocked) then
                        return nil
                    end
                    local origin = pself.position + offset
                    local castResult = nearby.castRay(origin,
                        util.vector3(origin.x, origin.y, -100 * mutil.CELL_SIZE), {
                            collisionType = nearby.COLLISION_TYPE.HeightMap + nearby.COLLISION_TYPE.Water
                        })
                    if not castResult.hit then
                        return nil
                    end
                    return castResult.hitPos
                end
                table.insert(debugIcons, {
                    element = element,
                    pos = worldPos,
                    ---@param posData ViewportData
                    onDraw = function(_, posData, parentAspectRatio)
                        if not (debugEnabled or psoUnlocked) then
                            element.layout.props.visible = false
                            return
                        end
                        element.layout.props.relativeSize = iutil.iconSize(posData, parentAspectRatio)
                        element.layout.props.visible = true
                        element.layout.props.relativePosition = posData.viewportPos.pos
                        --element:update()
                    end,
                    onHide = function()
                        element.layout.props.visible = false
                        --element:update()
                    end,
                    priority = -1000,
                })
            end
        end
    end
end

makeDebugPips()
for _, icon in ipairs(debugIcons) do
    interfaces.LivelyMapDraw.registerIcon(icon)
end
