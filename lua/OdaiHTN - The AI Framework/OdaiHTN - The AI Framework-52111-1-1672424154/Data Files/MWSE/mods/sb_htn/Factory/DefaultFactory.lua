local mc = require("sb_htn.Utils.middleclass")
local IFactory = require("sb_htn.Factory.IFactory")
local Queue = require("sb_htn.Utils.Queue")

---@class DefaultFactory : IFactory
local DefaultFactory = mc.class("DefaultFactory", IFactory)

function DefaultFactory:CreateArray(length, T)
    local array = table.new(length, length)
    for i = 1, length do
        array[i] = T:new()
    end
    return array
end

function DefaultFactory:CreateList(T)
    return {}
end

function DefaultFactory:CreateQueue(T)
    return Queue:new()
end

function DefaultFactory:FreeArray(array, T)
    for _, value in ipairs(array) do
        table.removevalue(array, value)
    end
    return table.size(array) == 0
end

function DefaultFactory:FreeList(list, T)
    for _, value in ipairs(list) do
        table.removevalue(list, value)
    end
    return table.size(list) == 0
end

function DefaultFactory:FreeQueue(queue, T)
    queue:clear()
    return queue:isInstanceOf(Queue)
end

function DefaultFactory:Free(obj, T)
    obj = nil
    return obj == nil
end

return DefaultFactory
