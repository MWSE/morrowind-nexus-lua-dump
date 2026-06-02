---@class priorityRule : conversationValidationRule
local this = {}

---@public
---@param configuration conversationConfiguration
---@return boolean, reason|nil
function this.isMet(configuration)
    if not configuration.priority then
        return true, nil
    end

    local valid, reason = this.validateValue(configuration.priority.value)
    if not valid then
        return false, reason
    end

    return this.validateWeight(configuration.priority.weight)
end

---@private
---@param value number
---@return boolean, reason|nil
function this.validateValue(value)
    if not value then
        return false, "priority value is missing"
    end

    if not type(value) == "number" then
        return false, "priority value must be a number"
    end

    return true, nil
end

---@private
---@param weight number|nil
---@return boolean, reason|nil
function this.validateWeight(weight)
    if not weight then
        return true, nil
    end

    if not type(weight) == "number" then
        return false, "priority weight must be a number"
    end

    if weight < 0 or weight > 1 then
        return false, "priority weight must be between 0 and 1"
    end

    return true, nil
end

return this
