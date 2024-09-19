local mc = require("sb_htn.Utils.middleclass")
local Queue = require("sb_htn.Utils.Queue")

---@class IPlannerState
local IPlannerState = mc.class("IPlannerState")

function IPlannerState:initialize()
	---@type ITask
	self.CurrentTask = nil
	---@type Queue<ITask>
	self.Plan = Queue:new()
	---@type ETaskStatus
	self.LastStatus = 1
end

--- OnNewPlan(newPlan) is called when we found a new plan, and there is no
--- old plan to replace.
---
---@type function Queue<ITask>
function IPlannerState:OnNewPlan() end

--- OnReplacePlan(oldPlan, currentTask, newPlan) is called when we're about to replace the
--- current plan with a new plan.
---
---@type function Queue<ITask>, ITask, Queue<ITask>
function IPlannerState:OnReplacePlan() end

--- OnNewTask(task) is called after we popped a new task off the current plan.
---
---@type function ITask
function IPlannerState:OnNewTask() end

--- OnNewTaskConditionFailed(task, failedCondition) is called when we failed to
--- validate a condition on a new task.
---
---@type function ITask, ICondition
function IPlannerState:OnNewTaskConditionFailed() end

--- OnStopCurrentTask(task) is called when the currently running task was stopped
--- forcefully.
---
---@type function IPrimitiveTask
function IPlannerState:OnStopCurrentTask() end

--- OnCurrentTaskCompletedSuccessfully(task) is called when the currently running task
--- completes successfully, and before its effects are applied.
---
---@type function IPrimitiveTask
function IPlannerState:OnCurrentTaskCompletedSuccessfully() end

--- OnApplyEffect(effect) is called for each effect of the type PlanAndExecute on a
--- completed task.
---
---@type function IEffect
function IPlannerState:OnApplyEffect() end

--- OnCurrentTaskFailed(task) is called when the currently running task fails to complete.
---
---@type function IPrimitiveTask
function IPlannerState:OnCurrentTaskFailed() end

--- OnCurrentTaskContinues(task) is called every tick that a currently running task
--- needs to continue.
---
---@type function IPrimitiveTask
function IPlannerState:OnCurrentTaskContinues() end

--- OnCurrentTaskExecutingConditionFailed(task, condition) is called if an Executing Condition
--- fails. The Executing Conditions are checked before every call to task.Operator.Update(...).
---
---@type function IPrimitiveTask, ICondition
function IPlannerState:OnCurrentTaskExecutingConditionFailed() end

return IPlannerState
