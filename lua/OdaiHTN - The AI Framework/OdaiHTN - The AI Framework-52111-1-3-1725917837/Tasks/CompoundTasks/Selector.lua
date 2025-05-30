local mc = require("sb_htn.Utils.middleclass")
local CompoundTask = require("sb_htn.Tasks.CompoundTasks.CompoundTask")
local Queue = require("sb_htn.Utils.Queue")
local EDecompositionStatus = require("sb_htn.Tasks.CompoundTasks.EDecompositionStatus")
local ICompoundTask = require("sb_htn.Tasks.CompoundTasks.ICompoundTask")
local IPrimitiveTask = require("sb_htn.Tasks.PrimitiveTasks.IPrimitiveTask")
local Slot = require("sb_htn.Tasks.OtherTasks.Slot")
local GetKey = require("sb_htn.Utils.GetKey")

---@class Selector : CompoundTask
local Selector = mc.class("Selector", CompoundTask)

function Selector:initialize()
  CompoundTask.initialize(self)

  ---@type Queue<ITask>
  self.Plan = Queue:new()
end

---@param ctx IContext
---@return boolean
function Selector:IsValid(ctx)
  -- Check that our preconditions are valid first.
  if (CompoundTask.IsValid(self, ctx) == false) then
    if (ctx.LogDecomposition) then
      log("%i - Selector.IsValid:Failed:Preconditions not met!", ctx.CurrentDecompositionDepth)
    end
    return false
  end

  -- Selector requires there to be at least one sub-task to successfully select from.
  if (table.size(self.Subtasks) == 0) then
    if (ctx.LogDecomposition) then
      log("%i - Selector.IsValid:Failed:No sub-tasks!", ctx.CurrentDecompositionDepth)
    end
    return false
  end

  if (ctx.LogDecomposition) then log("%i - Selector.IsValid:Success!", ctx.CurrentDecompositionDepth) end
  return true
end

---@param ctx IContext
---@param taskIndex integer
---@param currentDecompositionIndex integer
---@return boolean
function Selector.BeatsLastMTR(ctx, taskIndex, currentDecompositionIndex)
  -- If the last plan's traversal record for this decomposition layer
  -- has a smaller index than the current task index we're about to
  -- decompose, then the new decomposition can't possibly beat the
  -- running plan, so we cancel finding a new plan.
  if (ctx.LastMTR[currentDecompositionIndex] < taskIndex) then
    -- But, if any of the earlier records beat the record in LastMTR, we're still good, as we're on a higher priority branch.
    -- This ensures that [0,0,1] can beat [0,1,0]
    for i = 1, table.size(ctx.MethodTraversalRecord) do
      local diff = ctx.MethodTraversalRecord[i] - ctx.LastMTR[i]
      if (diff < 0) then
        return true
      end
      if (diff > 0) then
        -- We should never really be able to get here, but just in case.
        return false
      end
    end

    return false
  end

  return true
end

--- In a Selector decomposition, just a single sub-task must be valid and successfully decompose for the Selector to be
--- successfully decomposed.
---@param ctx IContext
---@param startIndex integer
---@param result Queue<ITask>
---@return EDecompositionStatus
function Selector:OnDecompose(ctx, startIndex, result)
  self.Plan:clear()

  for taskIndex = startIndex, table.size(self.Subtasks) do
    if (ctx.LogDecomposition) then
      log("%i - Selector.OnDecompose:Task index: %i: %s", ctx.CurrentDecompositionDepth, taskIndex, self.Subtasks[taskIndex].Name)
    end
    -- If the last plan is still running, we need to check whether the
    -- new decomposition can possibly beat it.
    if (ctx.LastMTR and table.size(ctx.LastMTR) > 0) then
      if (table.size(ctx.MethodTraversalRecord) < table.size(ctx.LastMTR)) then
        local currentDecompositionIndex = table.size(ctx.MethodTraversalRecord) + 1
        if (self.BeatsLastMTR(ctx, taskIndex, currentDecompositionIndex) == false) then
          table.insert(ctx.MethodTraversalRecord, 0)
          if (ctx.DebugMTR) then
            table.insert(ctx.MTRDebug,
              string.format("REPLAN FAIL %s", self.Subtasks[taskIndex].Name))
          end

          if (ctx.LogDecomposition) then
            log("%i - Selector.OnDecompose:Rejected:Index %i is beat by last method traversal record!", ctx.CurrentDecompositionDepth, currentDecompositionIndex)
          end
          result:clear()
          return EDecompositionStatus.Rejected
        end
      end
    end

    local task = self.Subtasks[taskIndex]

    local status = self:OnDecomposeTask(ctx, task, taskIndex, nil, result)
    if (
          status == EDecompositionStatus.Rejected or status == EDecompositionStatus.Succeeded or
          status == EDecompositionStatus.Partial) then
      return status
    end
  end

  result:copy(self.Plan)
  return table.size(result.list) == 0 and EDecompositionStatus.Failed or EDecompositionStatus.Succeeded
end

---@param ctx IContext
---@param task ITask
---@param taskIndex integer
---@param oldStackDepth integer[]
---@param result Queue<ITask>
---@return EDecompositionStatus
function Selector:OnDecomposeTask(ctx, task, taskIndex, oldStackDepth, result)
  if (task:IsValid(ctx) == false) then
    if (ctx.LogDecomposition) then
      log("%i - Selector.OnDecomposeTask:Failed:Task %s.IsValid returned false!", ctx.CurrentDecompositionDepth, task.Name)
    end
    result:copy(self.Plan)
    return task:OnIsValidFailed(ctx)
  end

  if (task:isInstanceOf(ICompoundTask)) then
    return self:OnDecomposeCompoundTask(ctx, task, taskIndex, nil, result)
  end

  if (task:isInstanceOf(IPrimitiveTask)) then
    self:OnDecomposePrimitiveTask(ctx, task, taskIndex, nil, result)
  end

  if (task:isInstanceOf(Slot)) then
    return self:OnDecomposeSlot(ctx, task, taskIndex, nil, result)
  end

  result:copy(self.Plan)
  local status = table.size(result.list) == 0 and EDecompositionStatus.Failed or EDecompositionStatus.Succeeded

  if (ctx.LogDecomposition) then
    log("%i - Selector.OnDecomposeTask:%s!", ctx.CurrentDecompositionDepth, GetKey(status, EDecompositionStatus))
  end
  return status
end

---@param ctx IContext
---@param task IPrimitiveTask
---@param taskIndex integer
---@param oldStackDepth integer[]
---@param result Queue<ITask>
function Selector:OnDecomposePrimitiveTask(ctx, task, taskIndex, oldStackDepth, result)
  -- We need to record the task index before we decompose the task,
  -- so that the traversal record is set up in the right order.
  table.insert(ctx.MethodTraversalRecord, taskIndex)
  if (ctx.DebugMTR) then table.insert(ctx.MTRDebug, task.Name) end

  if (ctx.LogDecomposition) then
    log("%i - Selector.OnDecomposeTask:Pushed %s to plan!", ctx.CurrentDecompositionDepth, task.Name)
  end
  task:ApplyEffects(ctx)
  self.Plan:push(task)
  result:copy(self.Plan)
end

---@param ctx IContext
---@param task ICompoundTask
---@param taskIndex integer
---@param oldStackDepth integer[]
---@param result Queue<ITask>
---@return EDecompositionStatus
function Selector:OnDecomposeCompoundTask(ctx, task, taskIndex, oldStackDepth, result)
  -- We need to record the task index before we decompose the task,
  -- so that the traversal record is set up in the right order.
  table.insert(ctx.MethodTraversalRecord, taskIndex)
  if (ctx.DebugMTR) then table.insert(ctx.MTRDebug, task.Name) end

  local subPlan = Queue:new()
  local status = task:Decompose(ctx, 1, subPlan)

  -- If status is rejected, that means the entire planning procedure should cancel.
  if (status == EDecompositionStatus.Rejected) then
    if (ctx.LogDecomposition) then
      log("%i - Selector.OnDecomposeCompoundTask:%s: Decomposing %s was rejected.", ctx.CurrentDecompositionDepth,
        GetKey(status, EDecompositionStatus), task.Name)
    end
    result:clear()
    return EDecompositionStatus.Rejected
  end

  -- If the decomposition failed
  if (status == EDecompositionStatus.Failed) then
    -- Remove the taskIndex if it failed to decompose.
    ctx.MethodTraversalRecord[table.size(ctx.MethodTraversalRecord)] = nil
    if (ctx.DebugMTR) then ctx.MTRDebug[table.size(ctx.MTRDebug)] = nil end

    if (ctx.LogDecomposition) then
      log("%i - Selector.OnDecomposeCompoundTask:%s: Decomposing %s failed.", ctx.CurrentDecompositionDepth,
        GetKey(status, EDecompositionStatus), task.Name)
    end
    result:copy(self.Plan)
    return EDecompositionStatus.Failed
  end

  while (table.size(subPlan.list) > 0) do
    local p = subPlan:pop()
    if (ctx.LogDecomposition) then
      log("%i - Selector.OnDecomposeCompoundTask:Decomposing %s:Pushed %s to plan!", ctx.CurrentDecompositionDepth,
        task.Name, p.Name)
    end
    self.Plan:push(p)
  end

  if (ctx.HasPausedPartialPlan) then
    if (ctx.LogDecomposition) then
      log("%i - Selector.OnDecomposeCompoundTask:Return partial plan at index %i!", ctx.CurrentDecompositionDepth, taskIndex)
    end
    result:copy(self.Plan)
    return EDecompositionStatus.Partial
  end

  result:copy(self.Plan)
  local s = table.size(result.list) == 0 and EDecompositionStatus.Failed or EDecompositionStatus.Succeeded
  if (ctx.LogDecomposition) then
    log("%i - Selector.OnDecomposeCompoundTask:%s!", ctx.CurrentDecompositionDepth, GetKey(s, EDecompositionStatus))
  end
  return s
end

---@param ctx IContext
---@param task Slot
---@param taskIndex integer
---@param oldStackDepth integer[]
---@param result Queue<ITask>
---@return EDecompositionStatus
function Selector:OnDecomposeSlot(ctx, task, taskIndex, oldStackDepth, result)
  -- We need to record the task index before we decompose the task,
  -- so that the traversal record is set up in the right order.
  table.insert(ctx.MethodTraversalRecord, taskIndex)
  if (ctx.DebugMTR) then table.insert(ctx.MTRDebug, task.Name) end

  local subPlan = Queue:new()
  local status = task:Decompose(ctx, 1, subPlan)

  -- If status is rejected, that means the entire planning procedure should cancel.
  if (status == EDecompositionStatus.Rejected) then
    if (ctx.LogDecomposition) then
      log("%i - Selector.OnDecomposeSlot:%s: Decomposing %s was rejected.", ctx.CurrentDecompositionDepth,
        GetKey(status, EDecompositionStatus), task.Name)
    end
    result:clear()
    return EDecompositionStatus.Rejected
  end

  -- If the decomposition failed
  if (status == EDecompositionStatus.Failed) then
    -- Remove the taskIndex if it failed to decompose.
    ctx.MethodTraversalRecord[table.size(ctx.MethodTraversalRecord)] = nil
    if (ctx.DebugMTR) then ctx.MTRDebug[table.size(ctx.MTRDebug)] = nil end

    if (ctx.LogDecomposition) then
      log("%i - Selector.OnDecomposeSlot:%s: Decomposing %s failed.", ctx.CurrentDecompositionDepth,
        GetKey(status, EDecompositionStatus), task.Name)
    end
    result:copy(self.Plan)
    return EDecompositionStatus.Failed
  end

  while (table.size(subPlan.list) > 0) do
    local p = subPlan:pop()
    if (ctx.LogDecomposition) then
      log("%i - Selector.OnDecomposeSlot:Decomposing %s:Pushed %s to plan!", ctx.CurrentDecompositionDepth,
       task.Name, p.Name)
    end
    self.Plan:push(p)
  end

  if (ctx.HasPausedPartialPlan) then
    if (ctx.LogDecomposition) then
      log("%i - Selector.OnDecomposeSlot:Return partial plan!", ctx.CurrentDecompositionDepth)
    end
    result:copy(self.Plan)
    return EDecompositionStatus.Partial
  end

  result:copy(self.Plan)
  local s = table.size(result.list) == 0 and EDecompositionStatus.Failed or EDecompositionStatus.Succeeded
  if (ctx.LogDecomposition) then
    log("%i - Selector.OnDecomposeSlot:%s!", ctx.CurrentDecompositionDepth, s)
  end
  return s
end

return Selector
