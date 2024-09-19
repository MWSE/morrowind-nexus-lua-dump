local mc = require("sb_htn.Utils.middleclass")
local IFactory = require("sb_htn.Factory.IFactory")
local Queue = require("sb_htn.Utils.Queue")

---@class DefaultFactory : IFactory
local DefaultFactory = mc.class("DefaultFactory", IFactory)

---@param T type
---@param length integer
---@return table<any>
function DefaultFactory:CreateArray(T, length)
    local array = table.new(length, length)
    for i = 1, length do
        array[i] = T:new()
    end
    return array
end

---@param T type
---@return table<any>
function DefaultFactory:CreateList(T)
    return {}
end

---@param T type
---@return Queue
function DefaultFactory:CreateQueue(T)
    return Queue:new()
end

---@param T type
---@param array table<any>
---@return boolean
function DefaultFactory:FreeArray(T, array)
    for _, value in ipairs(array) do
        table.removevalue(array, value)
    end
    return table.size(array) == 0
end

---@param T type
---@param list table<any>
---@return boolean
function DefaultFactory:FreeList(T, list)
    for _, value in ipairs(list) do
        table.removevalue(list, value)
    end
    return table.size(list) == 0
end

---@param T type
---@param queue Queue
---@return boolean
function DefaultFactory:FreeQueue(T, queue)
    queue:clear()
    return queue:isInstanceOf(Queue)
end

---@param T type
---@param obj any
---@return boolean
function DefaultFactory:Free(T, obj)
    obj = nil
    return obj == nil
end

return DefaultFactory
