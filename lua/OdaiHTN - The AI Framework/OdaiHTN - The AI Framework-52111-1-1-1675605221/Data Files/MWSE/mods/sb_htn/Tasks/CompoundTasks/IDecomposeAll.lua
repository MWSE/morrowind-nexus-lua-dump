local mc = require("sb_htn.Utils.middleclass")
local ICompoundTask = require("sb_htn.Tasks.CompoundTasks.ICompoundTask")

---@class IDecomposeAll : ICompoundTask
local IDecomposeAll = mc.class("IDecomposeAll", ICompoundTask)

return IDecomposeAll
