local mc = require("sb_htn.Utils.middleclass")
local ITask = require("sb_htn.Tasks.ITask")
local EDecompositionStatus = require("sb_htn.Tasks.CompoundTasks.EDecompositionStatus")

---@class Slot : ITask
---@field SlotId integer
---@field Subtask ICompoundTask
local Slot = mc.class("Slot", ITask)

---@class SlotParams
---@field SlotId integer?
---@field Name string?
---@field Parent ICompoundTask?
---@field Subtask ICompoundTask?

---@param params SlotParams?
function Slot:initialize(params)
    self.SlotId = params and params.SlotId or nil
    self.Name = params and params.Name or nil
    self.Parent = params and params.Parent or nil
    self.Conditions = nil
    self.Subtask = nil
end

---@param ctx IContext
---@return EDecompositionStatus
function Slot:OnIsValidFailed(ctx)
    return EDecompositionStatus.Failed
end

---@param condition ICondition
function Slot:AddCondition(condition)
    assert(condition == nil, "Slot tasks does not support conditions.")
end

---@param subtask ICompoundTask
---@return boolean
function Slot:Set(subtask)
    if (self.Subtask) then
        return false
    end

    self.Subtask = subtask
    return true
end

function Slot:Clear()
    self.Subtask = nil
end

---@param ctx IContext
---@param startIndex integer
---@param result Queue<ITask> - out
---@return EDecompositionStatus
function Slot:Decompose(ctx, startIndex, result)
    if (self.Subtask) then
        return self.Subtask:Decompose(ctx, startIndex, result)
    end

    result:clear()
    return EDecompositionStatus.Failed
end

---@param ctx IContext
---@return boolean
function Slot:IsValid(ctx)
    local result = self.Subtask and true or false
    if (ctx.LogDecomposition) then
        log("%i - Slot.IsValid:%s!", ctx.CurrentDecompositionDepth, (result and "Success" or "Failed"))
    end
    return result
end

return Slot