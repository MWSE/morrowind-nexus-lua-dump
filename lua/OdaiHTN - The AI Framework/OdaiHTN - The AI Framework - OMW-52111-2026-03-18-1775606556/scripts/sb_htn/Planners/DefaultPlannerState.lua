local mc = require("sb_htn.Utils.middleclass")
local Queue = require("sb_htn.Utils.Queue")
local IPlannerState = require("sb_htn.Planners.IPlannerState")

---@class DefaultPlannerState : IPlannerState
local DefaultPlannerState = mc.class("DefaultPlannerState", IPlannerState)

---@class DefaultPlannerStateParams
---@field CurrentTask ITask?
---@field Plan Queue<ITask>?
---@field LastStatus integer?

---@param params DefaultPlannerStateParams?
function DefaultPlannerState:initialize(params)
	self.CurrentTask = params and params.CurrentTask or nil
	self.Plan = params and params.Plan or Queue:new()
	self.LastStatus = params and params.LastStatus or nil
end

function DefaultPlannerState:OnNewPlan() end
function DefaultPlannerState:OnReplacePlan() end
function DefaultPlannerState:OnNewTask() end
function DefaultPlannerState:OnNewTaskConditionFailed() end
function DefaultPlannerState:OnStopCurrentTask() end
function DefaultPlannerState:OnCurrentTaskCompletedSuccessfully() end
function DefaultPlannerState:OnApplyEffect() end
function DefaultPlannerState:OnCurrentTaskFailed() end
function DefaultPlannerState:OnCurrentTaskStarted() end
function DefaultPlannerState:OnCurrentTaskContinues() end
function DefaultPlannerState:OnCurrentTaskExecutingConditionFailed() end

return DefaultPlannerState