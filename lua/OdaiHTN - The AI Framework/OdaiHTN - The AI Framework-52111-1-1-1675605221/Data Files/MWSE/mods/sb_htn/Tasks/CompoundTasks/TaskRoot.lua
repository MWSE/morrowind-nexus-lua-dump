local mc = require("sb_htn.Utils.middleclass")
local Selector = require("sb_htn.Tasks.CompoundTasks.Selector")

---@class TaskRoot : Selector
local TaskRoot = mc.class("TaskRoot", Selector)

return TaskRoot
