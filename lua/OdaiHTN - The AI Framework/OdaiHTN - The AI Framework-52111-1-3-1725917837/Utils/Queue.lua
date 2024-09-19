local mc = require("sb_htn.Utils.middleclass")

---@class Queue<any>
local Queue = mc.class("Queue")

function Queue:initialize()
    self.list = {}
    self.first = 1
    self.last = 0
end

function Queue:push(item)
    self.last = self.last + 1
    self.list[self.last] = item
end

function Queue:pop()
    if self.first <= self.last then
        local value = self.list[self.first]
        self.list[self.first] = nil
        self.first = self.first + 1
        return value
    end
end

function Queue:peek()
    return self.list[self.first]
end

function Queue:clear()
    self.list = {}
    self.first = 1
    self.last = 0
end

function Queue:copy(q)
    self.list = q.list
    self.first = q.first
    self.last = q.last
end

return Queue
