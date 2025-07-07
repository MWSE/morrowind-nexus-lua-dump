local postprocessing = require('openmw.postprocessing')

local ShaderWrapper = {}
ShaderWrapper.__index = ShaderWrapper

local shaderInstances = {}

function ShaderWrapper:new(name, uniforms, shouldBeEnabled)
    if not uniforms then uniforms = {} end
    local shader = postprocessing.load(name)
    local instance = {
        name = name,
        shader = shader,
        enabled = false,
        shouldBeEnabled = shouldBeEnabled,
        u = {},
        _u = {}
    }
    
    local uMt = {
        __index = function (t,k)
            return instance._u[k]   -- access the original table
        end,
        
        __newindex = function (t,k,v)
            if instance._u[k] ~= v then
                instance._u[k] = v
                if type(v) =="number" then
                    instance.shader:setFloat(k,v)
                end
                if type(v) == "table" then
                    -- Also check if first element is a vector3
                    instance.shader:setVector3Array(k,v)
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



function ShaderWrapper:enable()
    if not self.enabled then
        self.shader:enable()
        self.enabled = true
    end
end

function ShaderWrapper:disable()
    if self.enabled then
        self.shader:disable()
        self.enabled = false
    end
end

return {
    instances = shaderInstances,
    ShaderWrapper = ShaderWrapper
}