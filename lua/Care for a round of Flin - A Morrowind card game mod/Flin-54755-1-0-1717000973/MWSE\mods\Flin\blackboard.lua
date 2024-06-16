---@class Blackboard
---@field private data table<string, any>
local Blackboard = {}

--- constructor
function Blackboard:new()
    local newObj = {
        data = {}
    }
    self.__index = self
    setmetatable(newObj, self)
    return newObj
end

--- set data
---@param key string
---@param value any
function Blackboard:setData(key, value)
    self.data[key] = value
end

--- get data
---@param key string
---@return any?
function Blackboard:getData(key)
    return self.data[key]
end

--- remove data
---@param key string
function Blackboard:removeData(key)
    self.data[key] = nil
end

-- clean
function Blackboard:clean()
    self.data = {}
end

-- singleton instance
--- @type Blackboard?
local instance = nil
--- @return Blackboard
function Blackboard.getInstance()
    if instance == nil then
        instance = Blackboard:new()
    end
    return instance
end

return Blackboard
