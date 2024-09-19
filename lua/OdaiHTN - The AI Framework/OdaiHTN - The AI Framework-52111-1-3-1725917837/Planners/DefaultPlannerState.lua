local mc = require("sb_htn.Utils.middleclass")
local Queue = require("sb_htn.Utils.Queue")
local IPlannerState = require("sb_htn.Planners.IPlannerState")

---@class DefaultPlannerState : IPlannerState
local DefaultPlannerState = mc.class("DefaultPlannerState", IPlannerState)

function DefaultPlannerState:initialize()
	self.CurrentTask = nil
	self.Plan = Queue:new()
	self.LastStatus = 1
end

function DefaultPlannerState:OnNewPlan() end
function DefaultPlannerState:OnReplacePlan() end
function DefaultPlannerState:OnNewTask() end
function DefaultPlannerState:OnNewTaskConditionFailed() end
function DefaultPlannerState:OnStopCurrentTask() end
function DefaultPlannerState:OnCurrentTaskCompletedSuccessfully() end
function DefaultPlannerState:OnApplyEffect() end
function DefaultPlannerState:OnCurrentTaskFailed() end
function DefaultPlannerState:OnCurrentTaskContinues() end
function DefaultPlannerState:OnCurrentTaskExecutingConditionFailed() end

return DefaultPlannerState
