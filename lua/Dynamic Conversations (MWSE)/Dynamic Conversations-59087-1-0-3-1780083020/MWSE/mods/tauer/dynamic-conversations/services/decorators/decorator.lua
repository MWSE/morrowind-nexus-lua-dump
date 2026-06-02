---@class decorator
local this = {}

--- Wraps an inner instance with decorator functionality
---@public
---@param inner any The inner instance to be decorated
---@param wrapper table?  Methods/fields for this specific decorator
---@return decoratedType
function this.wrap(inner, wrapper)
    local instance = { inner = inner }

    local metatable = {
        __index = this.__index,
        __base = this,
        __wrapper = wrapper,
    }

    return setmetatable(instance, metatable)
end

function this:__index(key)
    local metatable = getmetatable(self)

    local wrapper = rawget(metatable, "__wrapper")
    if wrapper then
        local wrapperValue = rawget(wrapper, key)
        if wrapperValue then
            return wrapperValue
        end
    end

    local baseValue = rawget(this, key)
    if baseValue then
        return baseValue
    end

    local inner = rawget(self, "inner")
    if not inner then
        return nil
    end

    local value = inner[key]
    if type(value) == "function" then
        return function(_, ...)
            return value(inner, ...)
        end
    end

    return value
end

return this
