local mc = require("sb_htn.Utils.middleclass")

---@class IFactory
local IFactory = mc.class("IFactory")

---@param length integer
---@param T any
---@return any[]
function IFactory:CreateArray(T, length) return {} end

---@param array any[]
---@param T any
---@return boolean
function IFactory:FreeArray(T, array) return false end

---@param T any
---@return Queue<any>
function IFactory:CreateQueue(T) return {} end

---@param queue Queue<any>
---@param T any
---@return boolean
function IFactory:FreeQueue(T, queue) return false end

---@param T any
---@return table<any>
function IFactory:CreateList(T) return {} end

---@param list table<any>
---@param T any
---@return table<any>
function IFactory:FreeList(T, list) return {} end

---@param obj any
---@param T any
---@return boolean
function IFactory:Free(T, obj) return false end

return IFactory
