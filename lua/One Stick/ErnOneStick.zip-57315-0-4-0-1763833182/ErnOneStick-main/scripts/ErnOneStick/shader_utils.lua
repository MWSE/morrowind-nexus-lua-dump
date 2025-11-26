--[[
ErnOneStick for OpenMW.
Copyright (C) 2025 Max Yari, modified by Erin Pentecost

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

local ShaderWrapper = {}
ShaderWrapper.__index = ShaderWrapper

local shaderInstances = {}

function NewShaderWrapper(name, uniforms)
    if not uniforms then uniforms = {} end
    local shader = postprocessing.load(name)
    local instance = {
        name = name,
        shader = shader,
        enabled = false,
        u = {},
        _u = {}
    }

    local uMt = {
        __index = function(t, k)
            return instance._u[k] -- access the original table
        end,

        __newindex = function(t, k, v)
            if instance._u[k] ~= v then
                instance._u[k] = v
                if type(v) == "number" then
                    instance.shader:setFloat(k, v)
                end
                if type(v) == "table" then
                    -- Also check if first element is a vector3
                    instance.shader:setVector3Array(k, v)
                end
            end
        end
    }
    setmetatable(instance, ShaderWrapper)
    setmetatable(instance.u, uMt)

    for key, value in pairs(uniforms) do
        instance.u[key] = value
    end

    shaderInstances[name] = instance
    return instance
end

function HandleShaders(dt)
    for _, shader in pairs(shaderInstances) do
        if shader.tweener then shader.tweener:tick(dt) end
        if shader.enabled then
            shader.shader:enable()
        else
            shader.shader:disable()
        end
    end
end

return {
    NewShaderWrapper = NewShaderWrapper,
    HandleShaders = HandleShaders,
}
