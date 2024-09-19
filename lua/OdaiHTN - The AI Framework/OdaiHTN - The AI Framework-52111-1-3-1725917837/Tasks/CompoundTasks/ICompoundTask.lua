local mc = require("sb_htn.Utils.middleclass")
local ITask = require("sb_htn.Tasks.ITask")

---@class ICompoundTask : ITask
local ICompoundTask = mc.class("ICompoundTask", ITask)

function ICompoundTask:initialize()
    ITask.initialize(self)

    ---@type table<ITask>
    self.Subtasks = nil
end

---@param subtask ITask
---@return ICompoundTask
function ICompoundTask:AddSubtask(subtask) return {} end

--- Decompose the task onto the tasks to process queue, mind it's depth first
---@param ctx IContext
---@param startIndex integer
---@param result Queue<ITask> - out
---@return EDecompositionStatus
function ICompoundTask:Decompose(ctx, startIndex, result) return 0 end

return ICompoundTask
