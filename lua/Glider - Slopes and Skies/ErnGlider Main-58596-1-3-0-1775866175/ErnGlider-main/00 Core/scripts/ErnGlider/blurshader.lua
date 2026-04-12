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
local util                  = require("openmw.util")
local postprocessing        = require('openmw.postprocessing')
local settings              = require("scripts.ErnGlider.settings")

local BlurShaderFunctions   = {}
BlurShaderFunctions.__index = BlurShaderFunctions

---@class BlurShader
---@field update fun(dt: number)
---@field setEnabled fun(status: boolean)

---@return BlurShader
function NewBlurShader()
    local new = {
        ---@type boolean
        enabled = false,
        strength = 0,
        shader = postprocessing.load("gliderblur"),
        elapsedTime = 0,
    }
    setmetatable(new, BlurShaderFunctions)
    return new
end

---@param status boolean
function BlurShaderFunctions.setEnabled(self, status)
    status = settings.main.shaders and status
    if self.enabled == status then
        return
    end
    self.enabled = status
    if status then
        print("enabling blur shader")
        self.shader:setFloat("uStrength", self.strength)
        self.shader:enable()
    else
        print("disabling blur shader")
        self.shader:disable()
    end
end

function BlurShaderFunctions.update(self, strength)
    self.strength = util.clamp(strength, 0, 1)
    self.shader:setFloat("uStrength", self.strength)
end

return {
    ---@type fun() BlurShader
    NewBlurShader = NewBlurShader,
}
