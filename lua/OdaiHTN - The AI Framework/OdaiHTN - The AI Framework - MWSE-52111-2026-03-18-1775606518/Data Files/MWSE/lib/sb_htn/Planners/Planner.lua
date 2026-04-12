local mc = require("sb_htn.Utils.middleclass")
local EDecompositionStatus = require("sb_htn.Tasks.CompoundTasks.EDecompositionStatus")
local ETaskStatus = require("sb_htn.Tasks.ETaskStatus")
local EEffectType = require("sb_htn.Effects.EEffectType")
local IContext = require("sb_htn.Contexts.IContext")
local IPrimitiveTask = require("sb_htn.Tasks.PrimitiveTasks.IPrimitiveTask")

--- A planner is a responsible for handling the management of finding plans in a domain, replan when the state of the
--- running plan demands it, or look for a new potential plan if the world state gets dirty.
---@class Planner
local Planner = mc.class("Planner")

---@param T IContext
function Planner:initialize(T)
    self.T = T
end

--- Check whether state has changed or the current plan has finished running.
--- And if so, try to find a new plan.
---@param ctx IContext
---@return boolean
local function ShouldFindNewPlan(ctx)
    return ctx.IsDirty or (ctx.PlannerState.CurrentTask == nil and table.size(ctx.PlannerState.Plan.list) == 0)
end

--- If current task is null, we need to verify that the plan has more tasks queued.
---@param ctx IContext
---@return boolean
local function CanSelectNextTaskInPlan(ctx)
    return ctx.PlannerState.CurrentTask == nil and table.size(ctx.PlannerState.Plan.list) > 0
end

--- Prepare the planner state and context for a clean replan.
---@param ctx IContext
local function ClearPlanForReplan(ctx)
    ctx.PlannerState.CurrentTask = nil
    ctx.PlannerState.Plan:clear()

    ctx.LastMTR = {}

    if (ctx.DebugMTR) then
        ctx.LastMTRDebug = {}
    end

    ctx.HasPausedPartialPlan = false
    ctx.PartialPlanQueue:clear()
    ctx.IsDirty = false
end

--- When a task is aborted (due to failed condition checks),
--- we prepare the context for a replan next tick.
---@param ctx IContext
---@param task IPrimitiveTask
local function AbortTask(ctx, task)
    if (task.Abort) then
        task:Abort(ctx)
    end
    ClearPlanForReplan(ctx)
end

--- Ensure executing conditions are valid during plan execution.
---@param self Planner
---@param domain Domain
---@param ctx IContext
---@param task IPrimitiveTask
---@param allowImmediateReplanAndExecute boolean
local function IsExecutingConditionsValid(self, domain, ctx, task, allowImmediateReplanAndExecute)
    ---@param condition ICondition
    for _, condition in ipairs(task.ExecutingConditions) do
        -- If a condition failed, then the plan failed to progress! A replan is required.
        if (condition:IsValid(ctx) == false) then
            if (ctx.PlannerState.OnCurrentTaskExecutingConditionFailed) then
                ctx.PlannerState:OnCurrentTaskExecutingConditionFailed(task, condition)
            end
            AbortTask(ctx, task)

            if (allowImmediateReplanAndExecute) then
                self:Tick(domain, ctx, false)
            end

            return false
        end
    end

    return true
end

--- If the operation finished successfully, we set task to null so that we dequeue the next task in the plan the following tick.
---@param self Planner
---@param domain Domain
---@param ctx IContext
---@param task IPrimitiveTask
---@param allowImmediateReplanAndExecute boolean
local function OnOperatorFinishedSuccessfully(self, domain, ctx, task, allowImmediateReplanAndExecute)
    if (ctx.PlannerState.OnCurrentTaskCompletedSuccessfully) then
        ctx.PlannerState:OnCurrentTaskCompletedSuccessfully(task)
    end

    --- All effects that is a result of running this task should be applied when the task is a success.
    ---@param effect IEffect
    for _, effect in ipairs(task.Effects) do
        if (effect.Type == EEffectType.PlanAndExecute) then
            if (ctx.PlannerState.OnApplyEffect) then
                ctx.PlannerState:OnApplyEffect(effect)
            end
            effect:Apply(ctx)
        end
    end

    ctx.PlannerState.CurrentTask = nil
    if (table.size(ctx.PlannerState.Plan.list) == 0) then
        ctx.LastMTR = {}

        if (ctx.DebugMTR) then
            ctx.LastMTRDebug = {}
        end

        ctx.IsDirty = false

        if (allowImmediateReplanAndExecute) then
            self:Tick(domain, ctx, false)
        end
    end
end

--- If the operation failed to finish, we need to fail the entire plan, so that we will replan the next tick.
---@param self Planner
---@param domain Domain
---@param ctx IContext
---@param task IPrimitiveTask
---@param allowImmediateReplanAndExecute boolean
local function FailEntirePlan(self, domain, ctx, task, allowImmediateReplanAndExecute)
    if (ctx.PlannerState.OnCurrentTaskFailed) then
        ctx.PlannerState:OnCurrentTaskFailed(task)
    end

    task:Abort(ctx)
    ClearPlanForReplan(ctx)

    if (allowImmediateReplanAndExecute) then
        self:Tick(domain, ctx, false)
    end
end

--- While we have a valid primitive task running, we should tick it each tick of the plan execution.
---@param self Planner
---@param domain Domain
---@param ctx IContext
---@param task IPrimitiveTask
---@param allowImmediateReplanAndExecute boolean
---@return boolean
local function TryTickPrimitiveTaskOperator(self, domain, ctx, task, allowImmediateReplanAndExecute)
    if (task.Operator) then
        if (IsExecutingConditionsValid(self, domain, ctx, task, allowImmediateReplanAndExecute) == false) then
            return false
        end

        ctx.PlannerState.LastStatus = task.Operator:Update(ctx)

        -- If the operation finished successfully, we set task to null so that we dequeue the next task in the plan the following tick.
        if (ctx.PlannerState.LastStatus == ETaskStatus.Success) then
            OnOperatorFinishedSuccessfully(self, domain, ctx, task, allowImmediateReplanAndExecute)
            return true
        end

        -- If the operation failed to finish, we need to fail the entire plan, so that we will replan the next tick.
        if (ctx.PlannerState.LastStatus == ETaskStatus.Failure) then
            FailEntirePlan(self, domain, ctx, task, allowImmediateReplanAndExecute)
            return true
        end

        -- Otherwise the operation isn't done yet and need to continue.
        if (ctx.PlannerState.OnCurrentTaskContinues) then
            ctx.PlannerState:OnCurrentTaskContinues(task)
        end
        return true
    end

    -- This should not really happen if a domain is set up properly.
    task:Abort(ctx)
    ctx.PlannerState.CurrentTask = nil
    ctx.PlannerState.LastStatus = ETaskStatus.Failure
    return true
end

---@param ctx IContext
---@return Queue<PartialPlanEntry>?
local function CacheLastPartialPlan(ctx)
    if (ctx.HasPausedPartialPlan == false) then
        return nil
    end

    ctx.HasPausedPartialPlan = false
    local lastPartialPlanQueue = ctx.Factory:CreateQueue(IContext.PartialPlanEntry)

    while (table.size(ctx.PartialPlanQueue.list) > 0) do
        lastPartialPlanQueue:push(ctx.PartialPlanQueue:pop())
    end

    return lastPartialPlanQueue
end

--- Copy the MTR into our LastMTR to represent the current plan's decomposition record
--- that must be beat to replace the plan.
---@param ctx IContext
local function CopyMtrToLastMtr(ctx)
    if (ctx.MethodTraversalRecord) then
        ctx.LastMTR = {}
        for _, record in ipairs(ctx.MethodTraversalRecord) do
            table.insert(ctx.LastMTR, record)
        end

        if (ctx.DebugMTR) then
            ctx.LastMTRDebug = {}
            for _, record in ipairs(ctx.MTRDebug) do
                table.insert(ctx.LastMTRDebug, record)
            end
        end
    end
end

--- If we're simply re-evaluating whether to replace the current plan because
--- some world state got dirty, then we do not intend to continue a partial plan
--- right now, but rather see whether the world state changed to a degree where
--- we should pursue a better plan.
---@param ctx IContext
---@return Queue?
local function PrepareDirtyWorldStateForReplan(ctx)
    if (ctx.IsDirty == false) then
        return nil
    end

    ctx.IsDirty = false

    local lastPartialPlan = CacheLastPartialPlan(ctx)
    if (lastPartialPlan == nil) then
        return nil
    end

    -- We also need to ensure that the last mtr is up to date with the on-going MTR of the partial plan,
    -- so that any new potential plan that is decomposing from the domain root has to beat the currently
    -- running partial plan.
    CopyMtrToLastMtr(ctx)

    return lastPartialPlan
end

---@param decompositionStatus EDecompositionStatus
---@return boolean
local function HasFoundNewPlan(decompositionStatus)
    return decompositionStatus == EDecompositionStatus.Succeeded or
        decompositionStatus == EDecompositionStatus.Partial
end

---@param ctx IContext
---@param newPlan Queue<ITask>
local function OnFoundNewPlan(ctx, newPlan)
    if (ctx.PlannerState.OnReplacePlan and (table.size(ctx.PlannerState.Plan.list) > 0 or ctx.PlannerState.CurrentTask)) then
        ctx.PlannerState:OnReplacePlan(ctx.PlannerState.Plan, ctx.PlannerState.CurrentTask, newPlan)
    elseif (ctx.PlannerState.OnNewPlan and table.size(ctx.PlannerState.Plan.list) == 0) then
        ctx.PlannerState:OnNewPlan(newPlan)
    end

    ctx.PlannerState.Plan:clear()
    while (table.size(newPlan.list) > 0) do
        ctx.PlannerState.Plan:push(newPlan:pop())
    end

    -- If a task was running from the previous plan, we stop it.
    if (ctx.PlannerState.CurrentTask and ctx.PlannerState.CurrentTask:isInstanceOf(IPrimitiveTask)) then
        if (ctx.PlannerState.OnStopCurrentTask) then
            ctx.PlannerState:OnStopCurrentTask(ctx.PlannerState.CurrentTask)
        end
        ctx.PlannerState.CurrentTask:Stop(ctx)
        ctx.PlannerState.CurrentTask = nil
    end

    -- Copy the MTR into our LastMTR to represent the current plan's decomposition record
    -- that must be beat to replace the plan.
    CopyMtrToLastMtr(ctx)
end

---@param self Planner
---@param ctx IContext
---@param lastPartialPlanQueue Queue<PartialPlanEntry>
local function RestoreLastPartialPlan(self, ctx, lastPartialPlanQueue)
    ctx.HasPausedPartialPlan = true
    ctx.PartialPlanQueue:clear()

    while (table.size(lastPartialPlanQueue.list) > 0) do
        ctx.PartialPlanQueue:push(lastPartialPlanQueue:pop())
    end

    ctx.Factory:FreeQueue(self.T, lastPartialPlanQueue)
end

--- Copy the Last MTR back into our MTR. This is done during rollback when a new plan
--- failed to beat the last plan.
---@param ctx IContext
local function RestoreLastMethodTraversalRecord(ctx)
    if (table.size(ctx.LastMTR) > 0) then
        ctx.MethodTraversalRecord = {}
        for _, record in ipairs(ctx.LastMTR) do
            table.insert(ctx.MethodTraversalRecord, record)
        end
        ctx.LastMTR = {}

        if (ctx.DebugMTR == false) then
            return
        end

        ctx.MTRDebug = {}
        for _, record in ipairs(ctx.LastMTRDebug) do
            table.insert(ctx.MTRDebug, record)
        end
        ctx.LastMTRDebug = {}
    end
end

---@param self Planner
---@param domain Domain
---@param ctx IContext
---@return boolean, EDecompositionStatus
local function TryFindNewPlan(self, domain, ctx)
    local lastPartialPlanQueue = PrepareDirtyWorldStateForReplan(ctx)
    local isTryingToReplacePlan = table.size(ctx.PlannerState.Plan.list) > 0

    local newPlan = ctx.Factory:CreateQueue(IContext.PartialPlanEntry)
    local decompositionStatus = domain:FindPlan(ctx, newPlan)

    if (HasFoundNewPlan(decompositionStatus)) then
        OnFoundNewPlan(ctx, newPlan)
    elseif (lastPartialPlanQueue) then
        RestoreLastPartialPlan(self, ctx, lastPartialPlanQueue)
        RestoreLastMethodTraversalRecord(ctx)
    end

    return isTryingToReplacePlan, decompositionStatus
end

--- Ensure conditions are valid when a new task is selected from the plan
---@param ctx IContext
---@return boolean
local function IsConditionsValid(ctx)
    for _, condition in ipairs(ctx.PlannerState.CurrentTask.Conditions) do
        -- If a condition failed, then the plan failed to progress! A replan is required.
        if (condition:IsValid(ctx) == false) then
            if (ctx.PlannerState.OnNewTaskConditionFailed) then
                ctx.PlannerState:OnNewTaskConditionFailed(ctx.PlannerState.CurrentTask, condition)
            end
            AbortTask(ctx, ctx.PlannerState.CurrentTask)

            return false
        end
    end

    return true
end

--- Dequeues the next task of the plan and checks its conditions. If a condition fails, we require a replan.
---@param domain Domain
---@param ctx IContext
---@return boolean
local function SelectNextTaskInPlan(domain, ctx)
    ctx.PlannerState.CurrentTask = ctx.PlannerState.Plan:pop()
    if (ctx.PlannerState.CurrentTask) then
        if (ctx.PlannerState.OnNewTask) then
            ctx.PlannerState:OnNewTask(ctx.PlannerState.CurrentTask)
        end

        return IsConditionsValid(ctx)
    end

    return true
end

---@param self Planner
---@param domain Domain
---@param ctx IContext
---@param task IPrimitiveTask
---@param allowImmediateReplanAndExecute boolean
---@return boolean
local function TryStartPrimitiveTaskOperator(self, domain, ctx, task, allowImmediateReplanAndExecute)
    if (task.Operator) then
        ctx.PlannerState.LastStatus = task.Operator:Start(ctx)

        -- If the operation finished successfully already on start, we set task to null so that we dequeue the next task in the plan the following tick.
        if (ctx.PlannerState.LastStatus == ETaskStatus.Success) then
            -- We have to first invoke that the task operator has run its start function successfully, before we report that the operator finished.
            if (ctx.PlannerState.OnCurrentTaskStarted) then
                ctx.PlannerState:OnCurrentTaskStarted(task)
            end

            OnOperatorFinishedSuccessfully(self, domain, ctx, task, allowImmediateReplanAndExecute)
            return true
        end

        -- If the operation failed to start, we need to fail the entire plan, so that we will replan the next tick.
        if (ctx.PlannerState.LastStatus == ETaskStatus.Failure) then
            FailEntirePlan(self, domain, ctx, task, allowImmediateReplanAndExecute)
            return true
        end

        -- Otherwise the operation started as expected, and we are ready to start running Update ticks on the operator.
        if (ctx.PlannerState.OnCurrentTaskStarted) then
            ctx.PlannerState:OnCurrentTaskStarted(task)
        end
        return true
    end

    -- This should not really happen if a domain is set up properly.
    task:Abort(ctx)
    ctx.PlannerState.CurrentTask = nil
    ctx.PlannerState.LastStatus = ETaskStatus.Failure
    return true
end

--- If current task is null, and plan is empty, and we're not trying to replace the current plan, and decomposition failed or was rejected, then the planner failed to find a plan.
---@param isTryingToReplacePlan boolean
---@param decompositionStatus EDecompositionStatus
---@param ctx IContext
---@return boolean
local function HasFailedToFindPlan(isTryingToReplacePlan, decompositionStatus, ctx)
    return ctx.PlannerState.CurrentTask == nil and table.size(ctx.PlannerState.Plan.list) == 0 and isTryingToReplacePlan == false and
        (decompositionStatus == EDecompositionStatus.Failed or decompositionStatus == EDecompositionStatus.Rejected)
end

--- Call this with a domain and context instance to have the planner manage plan and task handling for the domain at
--- runtime.
---
--- If the plan completes or fails, the planner will find a new plan, or if the context is marked dirty, the planner
--- will attempt a replan to see whether we can find a better plan now that the state of the world has changed.
---
--- This planner can also be used as a blueprint for writing a custom planner.
---@param domain Domain
---@param ctx IContext
---@param allowImmediateReplanAndExecute boolean?
function Planner:Tick(domain, ctx, allowImmediateReplanAndExecute)
    assert(ctx.IsInitialized == true, "Context was not initialized!")

    local decompositionStatus = EDecompositionStatus.Failed
    local isTryingToReplacePlan = false

    -- Check whether state has changed or the current plan has finished running.
    -- and if so, try to find a new plan.
    if (ShouldFindNewPlan(ctx)) then
        isTryingToReplacePlan, decompositionStatus = TryFindNewPlan(self, domain, ctx)
    end

    -- If the plan has more tasks, we try to select the next one.
    if (CanSelectNextTaskInPlan(ctx)) then
        -- Select the next task, but check whether the conditions of the next task failed to validate.
        if (SelectNextTaskInPlan(domain, ctx) == false) then
            return
        end

        if (ctx.PlannerState.CurrentTask:isInstanceOf(IPrimitiveTask)) then
            if (TryStartPrimitiveTaskOperator(self, domain, ctx, ctx.PlannerState.CurrentTask, allowImmediateReplanAndExecute == nil or allowImmediateReplanAndExecute) == false) then
                return
            end
        end
    end

    -- If the current task is a primitive task, we try to tick its operator.
    if (ctx.PlannerState.CurrentTask and ctx.PlannerState.CurrentTask:isInstanceOf(IPrimitiveTask)) then
        if (TryTickPrimitiveTaskOperator(self, domain, ctx, ctx.PlannerState.CurrentTask, allowImmediateReplanAndExecute == nil or allowImmediateReplanAndExecute) == false) then
            return
        end
    end

    -- Check whether the planner failed to find a plan
    if (HasFailedToFindPlan(isTryingToReplacePlan, decompositionStatus, ctx)) then
        ctx.PlannerState.LastStatus = ETaskStatus.Failure
    end
end

---@param ctx IContext
function Planner:Reset(ctx)
    ctx.PlannerState.Plan:clear()

    if (ctx.PlannerState.CurrentTask and ctx.PlannerState.CurrentTask:isInstanceOf(IPrimitiveTask)) then
        ctx.PlannerState.CurrentTask:Stop(ctx)
    end

    ClearPlanForReplan(ctx)
end

return Planner