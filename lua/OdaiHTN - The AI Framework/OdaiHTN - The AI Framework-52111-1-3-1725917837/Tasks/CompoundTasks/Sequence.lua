local mc = require("sb_htn.Utils.middleclass")
local CompoundTask = require("sb_htn.Tasks.CompoundTasks.CompoundTask")
local Queue = require("sb_htn.Utils.Queue")
local IDecomposeAll = require("sb_htn.Tasks.CompoundTasks.IDecomposeAll")
local EDecompositionStatus = require("sb_htn.Tasks.CompoundTasks.EDecompositionStatus")
local ICompoundTask = require("sb_htn.Tasks.CompoundTasks.ICompoundTask")
local IPrimitiveTask = require("sb_htn.Tasks.PrimitiveTasks.IPrimitiveTask")
local PausePlanTask = require("sb_htn.Tasks.CompoundTasks.PausePlanTask")
local Slot = require("sb_htn.Tasks.OtherTasks.Slot")
local IContext = require("sb_htn.Contexts.IContext")
local GetKey = require("sb_htn.Utils.GetKey")

---@class Sequence : CompoundTask, IDecomposeAll
local Sequence = mc.class("Sequence", CompoundTask)

function Sequence:initialize()
    CompoundTask.initialize(self)
    self.IDecomposeAll = IDecomposeAll:new()

    ---@type Queue<ITask>
    self.Plan = Queue:new()
end

---@param ctx IContext
---@return boolean
function Sequence:IsValid(ctx)
    -- Check that our preconditions are valid first.
    if (CompoundTask.IsValid(self, ctx) == false) then
        if (ctx.LogDecomposition) then
            log("%i - Sequence.IsValid:Failed:Preconditions not met!", ctx.CurrentDecompositionDepth)
        end
        return false
    end

    -- Selector requires there to be subtasks to successfully select from.
    if (table.size(self.Subtasks) == 0) then
        if (ctx.LogDecomposition) then
            log("%i - Sequence.IsValid:Failed:No sub-tasks!", ctx.CurrentDecompositionDepth)
        end
        return false
    end

    if (ctx.LogDecomposition) then
        log("%i - Sequence.IsValid:Success!", ctx.CurrentDecompositionDepth)
    end
    return true
end

--- In a Sequence decomposition, all sub-tasks must be valid and successfully decomposed in order for the Sequence to
--- be successfully decomposed.
---@param ctx IContext
---@param startIndex integer
---@param result Queue<ITask>
---@return EDecompositionStatus
function Sequence:OnDecompose(ctx, startIndex, result)
    self.Plan:clear()

    local oldStackDepth = ctx:GetWorldStateChangeDepth(ctx.Factory)

    for taskIndex = startIndex, table.size(self.Subtasks) do
        local task = self.Subtasks[taskIndex]
        if (ctx.LogDecomposition) then
            log("%i - Sequence.OnDecompose:Task index: %i: %s", ctx.CurrentDecompositionDepth, taskIndex, task.Name)
        end

        local status = self:OnDecomposeTask(ctx, task, taskIndex, oldStackDepth, result)
        if (status == EDecompositionStatus.Rejected or status == EDecompositionStatus.Failed or status == EDecompositionStatus.Partial) then
            ctx.Factory:FreeArray(nil, oldStackDepth)
            return status
        end
    end

    ctx.Factory:FreeArray(nil, oldStackDepth)

    result:copy(self.Plan)
    return table.size(result.list) == 0 and EDecompositionStatus.Failed or EDecompositionStatus.Succeeded
end

---@param ctx IContext
---@param task ITask
---@param taskIndex integer
---@param oldStackDepth integer[]
---@param result Queue<ITask>
---@return EDecompositionStatus
function Sequence:OnDecomposeTask(ctx, task, taskIndex, oldStackDepth, result)
    if (task:IsValid(ctx) == false) then
        if (ctx.LogDecomposition) then
            log("%i - Sequence.OnDecomposeTask:Failed:Task %s.IsValid returned false!", ctx.CurrentDecompositionDepth, task.Name)
        end
        self.Plan:clear()
        ctx:TrimToStackDepth(oldStackDepth)
        result:copy(self.Plan)
        return task:OnIsValidFailed(ctx)
    end

    if (task:isInstanceOf(ICompoundTask)) then
        return self:OnDecomposeCompoundTask(ctx, task, taskIndex, oldStackDepth, result)
    elseif (task:isInstanceOf(IPrimitiveTask)) then
        self:OnDecomposePrimitiveTask(ctx, task, taskIndex, oldStackDepth, result)
    elseif (task:isInstanceOf(PausePlanTask)) then
        if (ctx.LogDecomposition) then
            log("%i - Sequence.OnDecomposeTask:Return partial plan at index %i!", ctx.CurrentDecompositionDepth, taskIndex)
        end
        ctx.HasPausedPartialPlan = true
        ctx.PartialPlanQueue:push((function()
            local p = IContext.PartialPlanEntry:new()
            p.Task = self
            p.TaskIndex = taskIndex + 1
            return p
        end)())

        result:copy(self.Plan)
        return EDecompositionStatus.Partial
    elseif (task:isInstanceOf(Slot)) then
        return self:OnDecomposeSlot(ctx, task, taskIndex, oldStackDepth, result)
    end

    result:copy(self.Plan)
    local s = table.size(result.list) == 0 and EDecompositionStatus.Failed or EDecompositionStatus.Succeeded
    if (ctx.LogDecomposition) then
        log("%i - Sequence.OnDecomposeTask:%s!", ctx.CurrentDecompositionDepth, GetKey(s, EDecompositionStatus))
    end
    return s
end

---@param ctx IContext
---@param task IPrimitiveTask
---@param taskIndex integer
---@param oldStackDepth integer[]
---@param result Queue<ITask>
function Sequence:OnDecomposePrimitiveTask(ctx, task, taskIndex, oldStackDepth, result)
    -- We don't add MTR tracking on sequences for primary sub-tasks, since they will always be included, so they're irrelevant to MTR tracking.

    if (ctx.LogDecomposition) then
        log("%i - Sequence.OnDecomposeTask:Pushed %s to plan!", ctx.CurrentDecompositionDepth, task.Name)
    end
    task:ApplyEffects(ctx)
    self.Plan:push(task)
end

---@param ctx IContext
---@param task ICompoundTask
---@param taskIndex integer
---@param oldStackDepth integer[]
---@param result Queue<ITask>
---@return EDecompositionStatus
function Sequence:OnDecomposeCompoundTask(ctx, task, taskIndex, oldStackDepth, result)
    local subPlan = Queue:new()
    local status = task:Decompose(ctx, 1, subPlan)

    -- If result is null, that means the entire planning procedure should cancel.
    if (status == EDecompositionStatus.Rejected) then
        if (ctx.LogDecomposition) then
            log("%i - Sequence.OnDecomposeCompoundTask:%s: Decomposing %s was rejected.", ctx.CurrentDecompositionDepth,
             GetKey(status, EDecompositionStatus), task.Name)
        end

        self.Plan:clear()
        ctx:TrimToStackDepth(oldStackDepth)

        result:clear()
        return EDecompositionStatus.Rejected
    end

    -- If the decomposition failed
    if (status == EDecompositionStatus.Failed) then
        if (ctx.LogDecomposition) then
            log("%i - Sequence.OnDecomposeCompoundTask:%s: Decomposing %s failed.", ctx.CurrentDecompositionDepth,
             GetKey(status, EDecompositionStatus), task.Name)
        end

        self.Plan:clear()
        ctx:TrimToStackDepth(oldStackDepth)
        result:copy(self.Plan)
        return EDecompositionStatus.Failed
    end

    while (table.size(subPlan.list) > 0) do
        local p = subPlan:pop()
        if (ctx.LogDecomposition) then
            log("%i - Sequence.OnDecomposeCompoundTask:Decomposing %s:Pushed %s to plan!", ctx.CurrentDecompositionDepth,
             task.Name, p.Name)
        end
        self.Plan:push(p)
    end

    if (ctx.HasPausedPartialPlan) then
        if (ctx.LogDecomposition) then
            log("%i - Sequence.OnDecomposeCompoundTask:Return partial plan at index %i!", ctx.CurrentDecompositionDepth, taskIndex)
        end
        if (taskIndex < table.size(self.Subtasks)) then
            ctx.PartialPlanQueue:push((function()
                local p = IContext.PartialPlanEntry:new()
                p.Task = self
                p.TaskIndex = taskIndex + 1
                return p
            end)())
        end

        result:copy(self.Plan)
        return EDecompositionStatus.Partial
    end

    result:copy(self.Plan)
    if (ctx.LogDecomposition) then
        log("%i - Sequence.OnDecomposeCompoundTask:Succeeded!", ctx.CurrentDecompositionDepth)
    end
    return EDecompositionStatus.Succeeded
end

---@param ctx IContext
---@param task Slot
---@param taskIndex integer
---@param oldStackDepth integer[]
---@param result Queue<ITask>
---@return EDecompositionStatus
function Sequence:OnDecomposeSlot(ctx, task, taskIndex, oldStackDepth, result)
    local subPlan = Queue:new()
    local status = task:Decompose(ctx, 1, subPlan)

    -- If result is null, that means the entire planning procedure should cancel.
    if (status == EDecompositionStatus.Rejected) then
        if (ctx.LogDecomposition) then
            log("%i - Sequence.OnDecomposeSlot:%s: Decomposing %s was rejected.", ctx.CurrentDecompositionDepth,
             GetKey(status, EDecompositionStatus), task.Name)
        end

        self.Plan:clear()
        ctx:TrimToStackDepth(oldStackDepth)

        result:clear()
        return EDecompositionStatus.Rejected
    end

    -- If the decomposition failed
    if (status == EDecompositionStatus.Failed) then
        if (ctx.LogDecomposition) then
            log("%i - Sequence.OnDecomposeSlot:%s: Decomposing %s failed.", ctx.CurrentDecompositionDepth,
             GetKey(status, EDecompositionStatus), task.Name)
        end

        self.Plan:clear()
        ctx:TrimToStackDepth(oldStackDepth)
        result:copy(self.Plan)
        return EDecompositionStatus.Failed
    end

    while (table.size(subPlan.list) > 0) do
        local p = subPlan:pop()
        if (ctx.LogDecomposition) then
            log("%i - Sequence.OnDecomposeSlot:Decomposing %s:Pushed %s to plan!", ctx.CurrentDecompositionDepth,
             task.Name, p.Name)
        end
        self.Plan:push(p)
    end

    if (ctx.HasPausedPartialPlan) then
        if (ctx.LogDecomposition) then
            log("%i - Sequence.OnDecomposeSlot:Return partial plan at index %i!", ctx.CurrentDecompositionDepth, taskIndex)
        end
        if (taskIndex < table.size(self.Subtasks)) then
            ctx.PartialPlanQueue:push((function()
                local p = IContext.PartialPlanEntry:new()
                p.Task = self
                p.TaskIndex = taskIndex + 1
                return p
            end)())
        end

        result:copy(self.Plan)
        return EDecompositionStatus.Partial
    end

    result:copy(self.Plan)
    if (ctx.LogDecomposition) then
        log("%i - Sequence.OnDecomposeSlot:Succeeded!", ctx.CurrentDecompositionDepth)
    end
    return EDecompositionStatus.Succeeded
end

return Sequence
