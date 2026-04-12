local mc = require("sb_htn.Utils.middleclass")

---@class IPlannerState
---@field CurrentTask ITask
---@field Plan Queue<ITask>
---@field LastStatus ETaskStatus
--- OnNewPlan(newPlan) is called when we found a new plan, and there is no
--- old plan to replace.
---@field OnNewPlan fun(self: IPlannerState)
--- OnReplacePlan(oldPlan, currentTask, newPlan) is called when we're about to replace the
--- current plan with a new plan.
---@field OnReplacePlan fun(self: IPlannerState)
--- OnNewTask(task) is called after we popped a new task off the current plan.
---@field OnNewTask fun(self: IPlannerState)
--- OnNewTaskConditionFailed(task, failedCondition) is called when we failed to
--- validate a condition on a new task.
---@field OnNewTaskConditionFailed fun(self: IPlannerState)
--- OnStopCurrentTask(task) is called when the currently running task was stopped
--- forcefully.
---@field OnStopCurrentTask fun(self: IPlannerState)
--- OnCurrentTaskCompletedSuccessfully(task) is called when the currently running task
--- completes successfully, and before its effects are applied.
---@field OnCurrentTaskCompletedSuccessfully fun(self: IPlannerState)
--- OnApplyEffect(effect) is called for each effect of the type PlanAndExecute on a
--- completed task.
---@field OnApplyEffect fun(self: IPlannerState)
--- OnCurrentTaskFailed(task) is called when the currently running task fails to complete.
---@field OnCurrentTaskFailed fun(self: IPlannerState)
--- OnCurrentTaskStarted(task) is called once when a new task in the plan is selected.
---@field OnCurrentTaskStarted fun(self: IPlannerState)
--- OnCurrentTaskContinues(task) is called every tick that a currently running task
--- needs to continue.
---@field OnCurrentTaskContinues fun(self: IPlannerState)
--- OnCurrentTaskExecutingConditionFailed(task, condition) is called if an Executing Condition
--- fails. The Executing Conditions are checked before every call to task.Operator.Update(...).
---@field OnCurrentTaskExecutingConditionFailed fun(self: IPlannerState)
local IPlannerState = mc.class("IPlannerState")

return IPlannerState