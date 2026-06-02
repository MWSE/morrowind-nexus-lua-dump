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
local util                     = require("openmw.util")
local postprocessing           = require('openmw.postprocessing')
local settings                 = require("scripts.ErnGlider.settings")

local UpdraftShaderFunctions   = {}
UpdraftShaderFunctions.__index = UpdraftShaderFunctions

---@class UpdraftShader
---@field update fun(dt: number)
---@field setEnabled fun(status: boolean)

---@return UpdraftShader
function NewUpdraftShader()
    local new = {
        ---@type boolean
        enabled = false,
        strength = 0,
        shader = postprocessing.load("gliderupdraft"),
        elapsedTime = 0,
        rand = 0,
    }
    setmetatable(new, UpdraftShaderFunctions)
    return new
end

---@param status boolean
function UpdraftShaderFunctions.setEnabled(self, status)
    status = settings.main.shaders and status
    if self.enabled == status then
        return
    end
    self.enabled = status
    if status then
        print("enabling updraft shader")
        self.shader:setFloat("uStrength", self.strength)
        self.shader:setFloat("uRand", math.random())
        self.shader:enable()
    else
        print("disabling updraft shader")
        self.shader:disable()
    end
end

function UpdraftShaderFunctions.update(self, strength, dt)
    self.elapsedTime = self.elapsedTime + dt
    self.shader:setFloat("uStrength", self.strength)
    self.strength = util.clamp(strength, 0, 1)
    self.shader:setFloat("uTime", self.elapsedTime)
end

return {
    ---@type fun() UpdraftShader
    NewUpdraftShader = NewUpdraftShader,
}
