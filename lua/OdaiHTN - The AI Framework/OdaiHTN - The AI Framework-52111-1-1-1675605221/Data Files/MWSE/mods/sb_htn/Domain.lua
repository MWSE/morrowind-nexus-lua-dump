local mc = require("sb_htn.Utils.middleclass")
local IDomain = require("sb_htn.IDomain")
local TaskRoot = require("sb_htn.Tasks.CompoundTasks.TaskRoot")
local IContext = require("sb_htn.Contexts.IContext")
local EDecompositionStatus = require("sb_htn.Tasks.CompoundTasks.EDecompositionStatus")
local Queue = require("sb_htn.Utils.Queue")
require("sb_htn.Utils.TableExt")

---@class Domain<IContext> : IDomain
local Domain = mc.class("Domain", IDomain)

---@param name string
---@param T IContext
function Domain:initialize(name, T)
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
function Domain.AddTask(parent, subtask)
    assert(parent ~= subtask, "Parent-task and Sub-task can't be the same instance!")

    parent:AddSubtask(subtask)
    subtask.Parent = parent
end

---@param parent ICompoundTask
---@param slot Slot
function Domain:AddSlot(parent, slot)
    assert(parent ~= slot, "Parent-task and Sub-task can't be the same instance!")

    if (self._slots ~= nil) then
        assert(self._slots[slot.SlotId] == nil, "This slot id already exist in the domain definition!")
    end

    parent:AddSubtask(slot)
    slot.Parent = parent

    if (self._slots == nil) then
        self._slots = {};
    end

    self._slots[slot.SlotId] = slot
end

---@param ctx IContext
---@param plan Queue ITask
---@return EDecompositionStatus | 0
function Domain:FindPlan(ctx, plan)
    assert(ctx.IsInitialized, "Context was not initialized!")

    assert(ctx.MethodTraversalRecord ~= nil, "We require the Method Traversal Record to have a valid instance.")

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
        ctx.HasPausedPartialPlan = false
        while (table.size(ctx.PartialPlanQueue.list) > 0) do
            local kvp = ctx.PartialPlanQueue:pop()
            if (table.size(plan.list) == 0) then
                status = kvp.Task:Decompose(ctx, kvp.TaskIndex, plan)
            else
                local p = Queue:new()
                status = kvp.Task:Decompose(ctx, kvp.TaskIndex, p)
                if (status == EDecompositionStatus.Succeeded or status == EDecompositionStatus.Partial) then
                    while (table.size(p.list) > 0) do
                        plan:push(p:pop())
                    end
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
        if (status == EDecompositionStatus.Rejected or status == EDecompositionStatus.Failed) then
            ctx.MethodTraversalRecord = {}
            if (ctx.DebugMTR) then ctx.MTRDebug = {} end

            status = self.Root:Decompose(ctx, 1, plan)
        end
    else
        local lastPartialPlanQueue = nil
        if (ctx.HasPausedPartialPlan) then
            ctx.HasPausedPartialPlan = false
            lastPartialPlanQueue = ctx.Factory:CreateQueue()
            while (table.size(ctx.PartialPlanQueue.list) > 0) do
                lastPartialPlanQueue:push(ctx.PartialPlanQueue:pop())
            end
        end

        -- We only erase the MTR if we start from the root task of the domain.
        ctx.MethodTraversalRecord = {}
        if (ctx.DebugMTR) then ctx.MTRDebug = {} end

        status = self.Root:Decompose(ctx, 1, plan)

        -- If we failed to find a new plan, we have to restore the old plan,
        -- if it was a partial plan.
        if (lastPartialPlanQueue ~= nil) then
            if (status == EDecompositionStatus.Rejected or status == EDecompositionStatus.Failed) then
                ctx.HasPausedPartialPlan = true
                ctx.PartialPlanQueue:clear()
                while (table.size(lastPartialPlanQueue.list) > 0) do
                    ctx.PartialPlanQueue:push(lastPartialPlanQueue:pop())
                end
                ctx.Factory:FreeQueue(lastPartialPlanQueue)
            end
        end
    end

    -- If this MTR equals the last MTR, then we need to double check whether we ended up
    -- just finding the exact same plan. During decomposition each compound task can't check
    -- for equality, only for less than, so this case needs to be treated after the fact.
    local isMTRsEqual = table.size(ctx.MethodTraversalRecord) == table.size(ctx.LastMTR)
    if (isMTRsEqual) then
        for i = 1, table.size(ctx.MethodTraversalRecord) do
            if (ctx.MethodTraversalRecord[i] < ctx.LastMTR[i]) then
                isMTRsEqual = false
                break
            end
        end

        if (isMTRsEqual) then
            plan:clear()
            status = EDecompositionStatus.Rejected
        end
    end

    if (status == EDecompositionStatus.Succeeded or status == EDecompositionStatus.Partial) then
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
    else
        -- Clear away any changes that might have been applied to the stack
        -- No changes should be made or tracked further when the plan failed.
        for i = 1, table.size(ctx.WorldStateChangeStack) do
            local stack = ctx.WorldStateChangeStack[i]
            if (stack and table.size(stack.list) > 0) then stack:clear() end
        end
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
