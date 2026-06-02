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
local ui = require('openmw.ui')

--- This file should be overwritten by a glider animation data directory.
ui.showMessage("You didn't install the glider mod correctly!")
error("You didn't install the glider mod correctly!")

---@class GliderAnimationInfo
---@field forward string animation for forward movement
---@field right string animation for right movement
---@field left string animation for left movement
---@field bone string bone to attach mesh to
---@field model string? mesh path

---@class GliderAnimationCollection
---@field basic GliderAnimationInfo
---@field advanced GliderAnimationInfo
---@field masterwork GliderAnimationInfo
local placeholder = {
    basic = {
        forward = "jump",
        right = "jump",
        left = "jump",
        bone = "Neck",
        model = nil
    },
    advanced = {
        forward = "jump",
        right = "jump",
        left = "jump",
        bone = "Neck",
        model = nil
    },
    masterwork = {
        forward = "jump",
        right = "jump",
        left = "jump",
        bone = "Neck",
        model = nil
    },
}

return placeholder
