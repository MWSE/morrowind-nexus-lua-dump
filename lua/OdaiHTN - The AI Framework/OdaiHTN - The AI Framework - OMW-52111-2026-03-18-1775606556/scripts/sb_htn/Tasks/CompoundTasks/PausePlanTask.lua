local mc = require("sb_htn.Utils.middleclass")
local ITask = require("sb_htn.Tasks.ITask")
local EDecompositionStatus = require("sb_htn.Tasks.CompoundTasks.EDecompositionStatus")

---@class PausePlanTask : ITask
---@field Effects IEffect[]
local PausePlanTask = mc.class("PausePlanTask", ITask)

---@class PausePlanTaskParams
---@field public Name string?
---@field public Parent ICompoundTask?

---@param params PausePlanTaskParams?
function PausePlanTask:initialize(params)
    self.Name = params and params.Name or "Pause Plan"
    self.Parent = params and params.Parent or nil
    self.Conditions = {}
    self.Effects = {}
end

---@param ctx IContext
---@return EDecompositionStatus
function PausePlanTask:OnIsValidFailed(ctx)
    return EDecompositionStatus.Failed
end

---@param condition ICondition
function PausePlanTask:AddCondition(condition)
    assert(condition == nil, "Pause Plan tasks does not support conditions.")
end

---@param effect IEffect
function PausePlanTask:AddEffect(effect)
    assert(effect == nil, "Pause Plan tasks does not support effects.")
end

---@param ctx IContext
function PausePlanTask:ApplyEffects(ctx) end

---@param ctx IContext
---@return boolean
function PausePlanTask:IsValid(ctx)
    if (ctx.LogDecomposition) then
        log("%i - PausePlanTask.IsValid:Success!", ctx.CurrentDecompositionDepth)
    end
    return true
end

return PausePlanTask