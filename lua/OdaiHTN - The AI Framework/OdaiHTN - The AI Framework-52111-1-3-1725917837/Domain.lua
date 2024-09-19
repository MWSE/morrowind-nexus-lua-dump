local mc = require("sb_htn.Utils.middleclass")
local IDomain = require("sb_htn.IDomain")
local TaskRoot = require("sb_htn.Tasks.CompoundTasks.TaskRoot")
local IContext = require("sb_htn.Contexts.IContext")
local EDecompositionStatus = require("sb_htn.Tasks.CompoundTasks.EDecompositionStatus")
local Queue = require("sb_htn.Utils.Queue")

---@class Domain<IContext> : IDomain
local Domain = mc.class("Domain", IDomain)

---@param name string
---@param T IContext
function Domain:initialize(T, name)
    IDomain.initialize(self)

    ---@type table<integer, Slot>
    self._slots = nil

    self.Root = TaskRoot:new()
    self.Root.Name = name
    self.Root.Parent = nil
    self.T = T
end

---@param parent ICompoundTask
---@param subtask ITask
function Domain:AddTask(parent, subtask)
    assert(parent ~= subtask, "Parent-task and Sub-task can't be the same instance!")

    parent:AddSubtask(subtask)
    subtask.Parent = parent
end

---@param parent ICompoundTask
---@param slot Slot
function Domain:AddSlot(parent, slot)
    if (self._slots) then
        assert(self._slots[slot.SlotId] == nil, "This slot id already exist in the domain definition!")
    end

    parent:AddSubtask(slot)
    slot.Parent = parent

    if (self._slots == nil) then
        self._slots = {}
    end

    self._slots[slot.SlotId] = slot
end

--- If decomposition status is failed or rejected, the replan failed.
---@param status EDecompositionStatus
---@return boolean
local function HasDecompositionSucceeded(status)
    return status == EDecompositionStatus.Succeeded or status == EDecompositionStatus.Partial
end

--- Pushs the sub plan's queue onto the existing plan
---@param plan Queue<ITask>
---@param subPlan Queue<ITask>
local function PushToExistingPlan(plan, subPlan)
    while (table.size(subPlan.list) > 0) do
        plan:push(subPlan:pop())
    end
end

--- If decomposition status is failed or rejected, the replan failed.
---@param status EDecompositionStatus
local function HasDecompositionFailed(status)
    return status == EDecompositionStatus.Rejected or status == EDecompositionStatus.Failed
end

--- We only erase the MTR if we start from the root task of the domain.
---@param ctx IContext
local function ClearMethodTraversalRecord(ctx)
    ctx.MethodTraversalRecord = {}

    if (ctx.DebugMTR) then
        ctx.MTRDebug = {}
    end
end

--- We first check whether we have a stored start task. This is true
--- if we had a partial plan pause somewhere in our plan, and we now
--- want to continue where we left off.
--- If this is the case, we don't erase the MTR, but continue building it.
---@param self Domain
---@param ctx IContext
---@param plan Queue<ITask>
---@param status EDecompositionStatus
local function OnPausedPartialPlan(self, ctx, plan, status)
    ctx.HasPausedPartialPlan = false
    while (table.size(ctx.PartialPlanQueue.list) > 0) do
        local kvp = ctx.PartialPlanQueue:pop()
        if (table.size(plan.list) == 0) then
            status = kvp.Task:Decompose(ctx, kvp.TaskIndex, plan)
        else
            local subPlan = Queue:new()
            status = kvp.Task:Decompose(ctx, kvp.TaskIndex, subPlan)
            if (HasDecompositionSucceeded(status)) then
                PushToExistingPlan(plan, subPlan)
            end
        end

        -- While continuing a partial plan, we might encounter
        -- a new pause.
        if (ctx.HasPausedPartialPlan) then
            break
        end
    end

    -- If we failed to continue the paused partial plan,
    -- then we have to start planning from the root.
    if (HasDecompositionFailed(status)) then
        ClearMethodTraversalRecord(ctx)
        
        status = self.Root:Decompose(ctx, 1, plan)
    end

    return status
end

--- If there is a paused partial plan, we cache it to a last partial plan queue.
--- This is useful when we want to perform a replan, but don't know yet if it will
--- win over the current plan.
---@param ctx IContext
---@return Queue | nil
local function CacheLastPartialPlan(ctx)
    if (ctx.HasPausedPartialPlan == false) then
        return nil
    end

    ctx.HasPausedPartialPlan = false
    local lastPartialPlanQueue = ctx.Factory:CreateQueue()
    
    while (table.size(ctx.PartialPlanQueue.list) > 0) do
        lastPartialPlanQueue:push(ctx.PartialPlanQueue:pop())
    end

    return lastPartialPlanQueue
end

--- If we failed to find a new plan, we have to restore the old plan,
--- if it was a partial plan.
---@param ctx IContext
---@param lastPartialPlanQueue Queue<PartialPlanEntry> | nil
---@param status EDecompositionStatus
local function RestoreLastPartialPlan(ctx, lastPartialPlanQueue, status)
    if (lastPartialPlanQueue == nil) then
        return
    end

    ctx.HasPausedPartialPlan = true
    ctx.PartialPlanQueue:clear()

    while (table.size(lastPartialPlanQueue.list) > 0) do
        ctx.PartialPlanQueue:push(lastPartialPlanQueue:pop())
    end

    ctx.Factory:FreeQueue(lastPartialPlanQueue)
end

--- We first check whether we have a stored start task. This is true
--- if we had a partial plan pause somewhere in our plan, and we now
--- want to continue where we left off.
--- If this is the case, we don't erase the MTR, but continue building it.
--- However, if we have a partial plan, but LastMTR is not 0, that means
--- that the partial plan is still running, but something triggered a replan.
--- When this happens, we have to plan from the domain root (we're not
--- continuing the current plan), so that we're open for other plans to replace
--- the running partial plan.
---@param self Domain
---@param ctx IContext
---@param plan Queue<ITask>
---@param status EDecompositionStatus
---@return EDecompositionStatus
local function OnReplanDuringPartialPlanning(self, ctx, plan, status)
    local lastPartialPlanQueue = CacheLastPartialPlan(ctx)

    ClearMethodTraversalRecord(ctx)

    -- Replan through decomposition of the hierarchy
    status = self.Root:Decompose(ctx, 1, plan)

    if (HasDecompositionFailed(status)) then
        RestoreLastPartialPlan(ctx, lastPartialPlanQueue, status)
    end

    return status
end

--- If this MTR equals the last MTR, then we need to double-check whether we ended up
--- just finding the exact same plan. During decomposition each compound task can't check
--- for equality, only for less than, so this case needs to be treated after the fact.
---@param ctx IContext
---@return boolean
local function HasFoundSamePlan(ctx)
    local isMTRsEqual = table.size(ctx.MethodTraversalRecord) == table.size(ctx.LastMTR)
    if (isMTRsEqual) then
        for i = 1, table.size(ctx.MethodTraversalRecord) do
            if (ctx.MethodTraversalRecord[i] < ctx.LastMTR[i]) then
                isMTRsEqual = false
                break
            end
        end

        return isMTRsEqual
    end

    return false
end

--- Apply permanent world state changes to the actual world state used during plan execution.
---@param ctx IContext
local function ApplyPermanentWorldStateStackChanges(ctx)
    -- Trim away any plan-only or plan&execute effects from the world state change stack, that only
    -- permanent effects on the world state remains now that the planning is done.
    ctx:TrimForExecution()

    -- Apply permanent world state changes to the actual world state used during plan execution.
    for i = 1, table.size(ctx.WorldStateChangeStack) do
        local stack = ctx.WorldStateChangeStack[i]
        if (stack and table.size(stack.list) > 0) then
            ctx.WorldState[i] = stack:peek()[2]
            stack:clear()
        end
    end
end

-- Clear away any changes that might have been applied to the stack
---@param ctx IContext
local function ClearWorldStateStackChanges(ctx)
    for _, stack in ipairs(ctx.WorldStateChangeStack) do
        if (stack and table.size(stack.list) > 0) then
            stack:clear()
        end
    end
end

---@param ctx IContext
---@param plan Queue<ITask>
---@return EDecompositionStatus
function Domain:FindPlan(ctx, plan)
    assert(ctx.IsInitialized, "Context was not initialized!")

    assert(ctx.MethodTraversalRecord, "We require the Method Traversal Record to have a valid instance.")

    ctx.ContextState = IContext.EContextState.Planning

    plan:clear()
    local status = EDecompositionStatus.Rejected

    -- We first check whether we have a stored start task. This is true
    -- if we had a partial plan pause somewhere in our plan, and we now
    -- want to continue where we left off.
    -- If this is the case, we don't erase the MTR, but continue building it.
    -- However, if we have a partial plan, but LastMTR is not 0, that means
    -- that the partial plan is still running, but something triggered a replan.
    -- When this happens, we have to plan from the domain root (we're not
    -- continuing the current plan), so that we're open for other plans to replace
    -- the running partial plan.
    if (ctx.HasPausedPartialPlan and table.size(ctx.LastMTR) == 0) then
        status = OnPausedPartialPlan(self, ctx, plan, status)
    else
        status = OnReplanDuringPartialPlanning(self, ctx, plan, status)
    end

    -- If this MTR equals the last MTR, then we need to double-check whether we ended up
    -- just finding the exact same plan. During decomposition each compound task can't check
    -- for equality, only for less than, so this case needs to be treated after the fact.
    if (HasFoundSamePlan(ctx)) then
        plan:clear()
        status = EDecompositionStatus.Rejected
    end

    if (HasDecompositionSucceeded(status)) then
        -- Apply permanent world state changes to the actual world state used during plan execution.
        ApplyPermanentWorldStateStackChanges(ctx)
    else
        -- Clear away any changes that might have been applied to the stack
        -- No changes should be made or tracked further when the plan failed.
        ClearWorldStateStackChanges(ctx)
    end

    ctx.ContextState = IContext.EContextState.Executing
    return status
end

--- At runtime, set a sub-domain to the slot with the given id.
---
--- This can be used with Smart Objects, to extend the behavior
--- of an agent at runtime.
---@param slotId integer
---@param subDomain Domain<IContext>
---@return boolean
function Domain:TrySetSlotDomain(slotId, subDomain)
    if (table.size(self._slots) > 0 and self._slots[slotId]) then
        return self._slots[slotId]:Set(subDomain.Root)
    end

    return false
end

--- At runtime, clear the sub-domain from the slot with the given id.
---
--- This can be used with Smart Objects, to extend the behavior
--- of an agent at runtime.
---@param slotId integer
function Domain:ClearSlot(slotId)
    if (table.size(self._slots) > 0 and self._slots[slotId]) then
        self._slots[slotId]:Clear()
    end
end

return Domain
