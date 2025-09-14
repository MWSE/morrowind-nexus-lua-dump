--[[
ErnShaderWrangler for OpenMW.
Copyright (C) 2025 Erin Pentecost

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
local postprocessing = require('openmw.postprocessing')

local ShaderFunctions = {}
ShaderFunctions.__index = ShaderFunctions

function NewShader(name, args)
    local new = {
        name = name,
        enabled = false,
        shader = postprocessing.load(name),
        args = args
    }
    setmetatable(new, ShaderFunctions)
    return new
end

function ShaderFunctions.enable(self, enable)
    if self.enabled ~= enable then
        if enable then
            --print("Enabling " .. self.name)
            self.shader:enable()
            for k, v in pairs(self.args) do
                self.shader:setFloat(k, v)
            end
        else
            --print("Disabling " .. self.name)
            self.shader:disable()
        end
        self.enabled = enable
    end
end

return {
    NewShader = NewShader
}
