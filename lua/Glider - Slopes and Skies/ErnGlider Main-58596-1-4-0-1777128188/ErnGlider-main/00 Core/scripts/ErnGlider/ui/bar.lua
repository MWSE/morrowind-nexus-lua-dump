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
local util       = require('openmw.util')
local ui         = require('openmw.ui')
local interfaces = require("openmw.interfaces")

local function barLayout(ratio, color, flashColor)
    return {
        type = ui.TYPE.Widget,
        name = 'bar',
        template = interfaces.MWUI.templates.borders,
        props = {
            size = util.vector2(20, 100),
        },
        content = ui.content {
            {
                type = ui.TYPE.Image,
                name = 'barContainer',
                props = {
                    resource = ui.texture { path = 'white' },
                    relativePosition = util.vector2(0, 0),
                    relativeSize = util.vector2(1, 1),
                    alpha = 0.7,
                    color = util.color.rgb(0.1, 0.1, 0.1),
                },
                events = {},
            },
            {
                name = 'barColor',
                type = ui.TYPE.Flex,
                props = {
                    horizontal = false,
                    arrange = ui.ALIGNMENT.Center,
                    align = ui.ALIGNMENT.End,
                    anchor = util.vector2(0, 1),
                    relativePosition = util.vector2(0, 1),
                    relativeSize = util.vector2(1, 1),
                    autoSize = false,
                },
                content = ui.content {
                    {
                        type = ui.TYPE.Image,
                        name = 'barFlash',
                        props = {
                            resource = ui.texture { path = 'Textures/ErnGlider/vert_gradient.dds' },
                            anchor = util.vector2(0, 1),
                            --relativePosition = util.vector2(0, ratio),
                            relativeSize = util.vector2(1, 0),
                            alpha = 0.7,
                            color = flashColor,
                        },
                    },
                    {
                        type = ui.TYPE.Image,
                        name = 'barFill',
                        props = {
                            resource = ui.texture { path = 'Textures/ErnGlider/vert_gradient.dds' },
                            anchor = util.vector2(0, 1),
                            --relativePosition = util.vector2(0, 1),
                            relativeSize = util.vector2(1, ratio),
                            alpha = 0.7,
                            color = color,
                        },
                    },

                }
            },
        }
    }
end

local function setRatio(elem, ratio, flashRatio)
    elem.layout.content.barColor.content.barFill.props.relativeSize = util.vector2(1, ratio)
    elem.layout.content.barColor.content.barFlash.props.relativeSize = util.vector2(1, flashRatio)
    -- epsilon is there to get rid of the gap between bars
    elem.layout.content.barColor.content.barFlash.props.relativePosition = util.vector2(0, 1 - ratio)
end

local flashSpeed     = 0.1

local BarFunctions   = {}
BarFunctions.__index = BarFunctions

function NewBar(ratio, color, flashColor)
    local new = {
        ratio = ratio,
        flashRatio = 0,
        color = color,
        flashColor = flashColor,
        elem = ui.create(barLayout(ratio, color, flashColor))
    }
    setmetatable(new, BarFunctions)
    return new
end

function BarFunctions.reset(self, newRatio)
    self.ratio = newRatio or 0
    self.flashRatio = 0
    self.elem:update()
end

function BarFunctions.onUpdate(self, dt, newRatio)
    local changed = false
    if newRatio ~= self.ratio then
        if newRatio < self.ratio then
            self.flashRatio = util.clamp(self.flashRatio + self.ratio - newRatio, 0, 1 - self.ratio)
        end
        self.ratio = newRatio
        changed = true
    end
    if self.flashRatio > 0 then
        self.flashRatio = util.clamp(self.flashRatio - flashSpeed * dt, 0, 1)
        changed = true
    end
    if changed then
        setRatio(self.elem, self.ratio, self.flashRatio)
        self.elem:update()
    end
end

return {
    NewBar = NewBar,
}
