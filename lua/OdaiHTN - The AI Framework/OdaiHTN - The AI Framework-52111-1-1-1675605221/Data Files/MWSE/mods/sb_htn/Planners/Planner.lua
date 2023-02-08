local mc = require("sb_htn.Utils.middleclass")
local EDecompositionStatus = require("sb_htn.Tasks.CompoundTasks.EDecompositionStatus")
local ETaskStatus = require("sb_htn.Tasks.ETaskStatus")
local EEffectType = require("sb_htn.Effects.EEffectType")
local Queue = require("sb_htn.Utils.Queue")
local IPrimitiveTask = require("sb_htn.Tasks.PrimitiveTasks.IPrimitiveTask")
require("sb_htn.Utils.TableExt")

--- A planner is a responsible for handling the management of finding plans in a domain, replan when the state of the
--- running plan
--- demands it, or look for a new potential plan if the world state gets dirty.
---@class Planner
local Planner = mc.class("Planner")

---@param T IContext
function Planner:initialize(T)
    ---@type ITask
    self._currentTask = nil
    ---@type Queue ITask
    self._plan = Queue:new()

    ---@type ETaskStatus
    self.LastStatus = 1

    --- OnNewPlan(newPlan) is called when we found a new plan, and there is no
    --- old plan to replace.
    ---
    ---@type function Queue<ITask>
    self.OnNewPlan = function() end

    --- OnReplacePlan(oldPlan, currentTask, newPlan) is called when we're about to replace the
    --- current plan with a new plan.
    ---
    ---@type function Queue<ITask>, ITask, Queue<ITask>
    self.OnReplacePlan = function() end

    --- OnNewTask(task) is called after we popped a new task off the current plan.
    ---
    ---@type function ITask
    self.OnNewTask = function() end

    --- OnNewTaskConditionFailed(task, failedCondition) is called when we failed to
    --- validate a condition on a new task.
    ---
    ---@type function ITask, ICondition
    self.OnNewTaskConditionFailed = function() end

    --- OnStopCurrentTask(task) is called when the currently running task was stopped
    --- forcefully.
    ---
    ---@type function IPrimitiveTask
    self.OnStopCurrentTask = function() end

    --- OnCurrentTaskCompletedSuccessfully(task) is called when the currently running task
    --- completes successfully, and before its effects are applied.
    ---
    ---@type function IPrimitiveTask
    self.OnCurrentTaskCompletedSuccessfully = function() end

    --- OnApplyEffect(effect) is called for each effect of the type PlanAndExecute on a
    --- completed task.
    ---
    ---@type function IEffect
    self.OnApplyEffect = function() end

    --- OnCurrentTaskFailed(task) is called when the currently running task fails to complete.
    ---
    ---@type function IPrimitiveTask
    self.OnCurrentTaskFailed = function() end

    --- OnCurrentTaskContinues(task) is called every tick that a currently running task
    --- needs to continue.
    ---
    ---@type function IPrimitiveTask
    self.OnCurrentTaskContinues = function() end

    --- OnCurrentTaskExecutingConditionFailed(task, condition) is called if an Executing Condition
    --- fails. The Executing Conditions are checked before every call to task.Operator.Update(...).
    ---
    ---@type function IPrimitiveTask, ICondition
    self.OnCurrentTaskExecutingConditionFailed = function() end

    self.T = T
end

--- Call this with a domain and context instance to have the planner manage plan and task handling for the domain at
--- runtime.
---
--- If the plan completes or fails, the planner will find a new plan, or if the context is marked dirty, the planner
--- will attempt
--- a replan to see whether we can find a better plan now that the state of the world has changed.
---
--- This planner can also be used as a blueprint for writing a custom planner.
---@param domain Domain
---@param ctx IContext
---@param allowImmediateReplan boolean | nil
function Planner:Tick(domain, ctx, allowImmediateReplan)
    assert(ctx.IsInitialized == true, "Context was not initialized!")

    local decompositionStatus = EDecompositionStatus.Failed
    local isTryingToReplacePlan = false
    -- Check whether state has changed or the current plan has finished running.
    -- and if so, try to find a new plan.
    if (self._currentTask == nil and (table.size(self._plan.list) == 0) or ctx.IsDirty) then
        local lastPartialPlanQueue = nil

        local worldStateDirtyReplan = ctx.IsDirty
        ctx.IsDirty = false

        if (worldStateDirtyReplan) then
            -- If we're simply re-evaluating whether to replace the current plan because
            -- some world state got dirt, then we do not intend to continue a partial plan
            -- right now, but rather see whether the world state changed to a degree where
            -- we should pursue a better plan. Thus, if this replan fails to find a better
            -- plan, we have to add back the partial plan temps cached above.
            if (ctx.HasPausedPartialPlan) then
                ctx.HasPausedPartialPlan = false
                lastPartialPlanQueue = ctx.Factory:CreateQueue()
                while (table.size(ctx.PartialPlanQueue.list) > 0) do
                    lastPartialPlanQueue:push(ctx.PartialPlanQueue:pop())
                end

                -- We also need to ensure that the last mtr is up to date with the on-going MTR of the partial plan,
                -- so that any new potential plan that is decomposing from the domain root has to beat the currently
                -- running partial plan.
                ctx.LastMTR = {}
                for _, record in ipairs(ctx.MethodTraversalRecord) do table.insert(ctx.LastMTR, record) end

                if (ctx.DebugMTR) then
                    ctx.LastMTRDebug = {}
                    for _, record in ipairs(ctx.MTRDebug) do table.insert(ctx.LastMTRDebug, record) end
                end
            end
        end

        local newPlan = Queue:new()
        decompositionStatus = domain:FindPlan(ctx, newPlan)
        isTryingToReplacePlan = table.size(self._plan.list) > 0
        if (decompositionStatus == EDecompositionStatus.Succeeded or decompositionStatus == EDecompositionStatus.Partial
            ) then
            if (self.OnReplacePlan and (table.size(self._plan.list) > 0 or self._currentTask ~= nil)) then
                self.OnReplacePlan(self._plan, self._currentTask, newPlan)
            elseif (self.OnNewPlan and table.size(self._plan.list) == 0) then
                self.OnNewPlan(newPlan)
            end

            self._plan:clear()
            while (table.size(newPlan.list) > 0) do self._plan:push(newPlan:pop()) end

            if (self._currentTask ~= nil and self._currentTask:isInstanceOf(IPrimitiveTask)) then
                self.OnStopCurrentTask(self._currentTask)
                self._currentTask:Stop(ctx)
                self._currentTask = nil
            end

            -- Copy the MTR into our LastMTR to represent the current plan's decomposition record
            -- that must be beat to replace the plan.
            if (table.size(ctx.MethodTraversalRecord) > 0) then
                ctx.LastMTR = {}
                for _, record in ipairs(ctx.MethodTraversalRecord) do table.insert(ctx.LastMTR, record) end

                if (ctx.DebugMTR) then
                    ctx.LastMTRDebug = {}
                    for _, record in ipairs(ctx.MTRDebug) do table.insert(ctx.LastMTRDebug, record) end
                end
            end
        elseif (lastPartialPlanQueue ~= nil) then
            ctx.HasPausedPartialPlan = true
            ctx.PartialPlanQueue:clear()
            while (table.size(lastPartialPlanQueue.list) > 0) do
                ctx.PartialPlanQueue:push(lastPartialPlanQueue:pop())
            end
            ctx.Factory:FreeQueue(lastPartialPlanQueue)

            if (table.size(ctx.LastMTR) > 0) then
                ctx.MethodTraversalRecord = {}
                for _, record in ipairs(ctx.LastMTR) do table.insert(ctx.MethodTraversalRecord, record) end
                ctx.LastMTR = {}

                if (ctx.DebugMTR) then
                    ctx.MTRDebug = {}
                    for _, record in ipairs(ctx.LastMTRDebug) do table.insert(ctx.MTRDebug, record) end
                    ctx.LastMTRDebug = {}
                end
            end
        end
    end

    if (self._currentTask == nil and table.size(self._plan.list) > 0) then
        self._currentTask = self._plan:pop()
        if (self._currentTask ~= nil) then
            self.OnNewTask(self._currentTask)
            for _, condition in ipairs(self._currentTask.Conditions) do
                -- If a condition failed, then the plan failed to progress! A replan is required.
                if (condition:IsValid(ctx) == false) then
                    self.OnNewTaskConditionFailed(self._currentTask, condition)

                    self._currentTask = nil
                    self._plan:clear()

                    ctx.LastMTR = {}
                    if (ctx.DebugMTR) then ctx.LastMTRDebug = {} end

                    ctx.HasPausedPartialPlan = false
                    ctx.PartialPlanQueue:clear()
                    ctx.IsDirty = false

                    return
                end
            end
        end
    end

    if (self._currentTask ~= nil) then
        if (self._currentTask:isInstanceOf(IPrimitiveTask)) then
            if (self._currentTask.Operator) then
                for _, condition in ipairs(self._currentTask.ExecutingConditions) do
                    -- If a condition failed, then the plan failed to progress! A replan is required.
                    if (condition:IsValid(ctx) == false) then
                        self.OnCurrentTaskExecutingConditionFailed(self._currentTask, condition)

                        self._currentTask = nil
                        self._plan:clear()

                        ctx.LastMTR = {}
                        if (ctx.DebugMTR) then ctx.LastMTRDebug = {} end

                        ctx.HasPausedPartialPlan = false
                        ctx.PartialPlanQueue:clear()
                        ctx.IsDirty = false

                        if (allowImmediateReplan == nil and true or allowImmediateReplan) then
                            self:Tick(domain, ctx, allowImmediateReplan or false)
                        end
                        return
                    end
                end

                self.LastStatus = self._currentTask.Operator:Update(ctx)

                -- If the operation finished successfully, we set task to {} so that we dequeue the next task in the plan the following tick.
                if (self.LastStatus == ETaskStatus.Success) then
                    self.OnCurrentTaskCompletedSuccessfully(self._currentTask)

                    -- All effects that is a result of running this task should be applied when the task is a success.
                    for _, effect in ipairs(self._currentTask.Effects) do
                        if (effect.Type == EEffectType.PlanAndExecute) then
                            self.OnApplyEffect(effect)
                            effect:Apply(ctx)
                        end
                    end

                    self._currentTask = nil
                    if (table.size(self._plan.list) == 0) then
                        ctx.LastMTR = {}
                        if (ctx.DebugMTR) then ctx.LastMTRDebug = {} end

                        ctx.IsDirty = false

                        if (allowImmediateReplan == nil and true or allowImmediateReplan) then
                            self:Tick(domain, ctx, allowImmediateReplan or false)
                        end
                    end

                    -- If the operation failed to finish, we need to fail the entire plan, so that we will replan the next tick.
                elseif (self.LastStatus == ETaskStatus.Failure) then
                    self.OnCurrentTaskFailed(self._currentTask)

                    self._currentTask = nil
                    self._plan:clear()

                    ctx.LastMTR = {}
                    if (ctx.DebugMTR) then ctx.LastMTRDebug = {} end

                    ctx.HasPausedPartialPlan = false
                    ctx.PartialPlanQueue:clear()
                    ctx.IsDirty = false

                    -- Otherwise the operation isn't done yet and need to continue.
                else
                    self.OnCurrentTaskContinues(self._currentTask)
                end
            else
                -- This should not really happen if a domain is set up properly.
                self._currentTask = nil
                self.LastStatus = ETaskStatus.Failure
            end
        end
    end

    if (
        self._currentTask == nil and table.size(self._plan.list) == 0 and isTryingToReplacePlan == false and
            (decompositionStatus == EDecompositionStatus.Failed or decompositionStatus == EDecompositionStatus.Rejected)
        ) then
        self.LastStatus = ETaskStatus.Failure
    end
end

---@param ctx IContext
function Planner:Reset(ctx)
    self._plan:clear()

    if (self._currentTask ~= nil and self._currentTask:isInstanceOf(IPrimitiveTask)) then
        self._currentTask:Stop(ctx)
    end
    self._currentTask = nil
end

--- Get the current plan. This is not a copy of the running plan, so treat it as read-only.
---@return Queue<ITask>
function Planner:GetPlan()
    return self._plan
end

--- Get the current task.
---@return ITask
function Planner:GetCurrentTask()
    return self._currentTask
end

return Planner
