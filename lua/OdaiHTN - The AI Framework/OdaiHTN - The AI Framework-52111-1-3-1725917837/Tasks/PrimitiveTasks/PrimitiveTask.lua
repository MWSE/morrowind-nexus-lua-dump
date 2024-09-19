local mc = require("sb_htn.Utils.middleclass")
local IPrimitiveTask = require("sb_htn.Tasks.PrimitiveTasks.IPrimitiveTask")
local IContext = require("sb_htn.Contexts.IContext")
local EDecompositionStatus = require("sb_htn.Tasks.CompoundTasks.EDecompositionStatus")
require("sb_htn.Utils.TableExt")

---@class PrimitiveTask : IPrimitiveTask
local PrimitiveTask = mc.class("PrimitiveTask", IPrimitiveTask)

function PrimitiveTask:initialize()
    IPrimitiveTask.initialize(self)

    ---@type string
    self.Name = ""
    ---@type ICompoundTask
    self.Parent = nil
    ---@type table<ICondition>
    self.Conditions = {}
    ---@type table<ICondition>
    self.ExecutingConditions = {}
    ---@type IOperator
    self.Operator = nil
    ---@type table<IEffect>
    self.Effects = {}
end

---@param ctx IContext
---@return EDecompositionStatus
function PrimitiveTask:OnIsValidFailed(ctx)
    return EDecompositionStatus.Failed
end

---@param condition ICondition
---@return IPrimitiveTask
function PrimitiveTask:AddCondition(condition)
    table.insert(self.Conditions, condition)
    return self
end

---@param condition ICondition
---@return IPrimitiveTask
function PrimitiveTask:AddExecutingCondition(condition)
    table.insert(self.ExecutingConditions, condition)
    return self
end

---@param effect IEffect
---@return IPrimitiveTask
function PrimitiveTask:AddEffect(effect)
    table.insert(self.Effects, effect)
    return self
end

---@param action IOperator
function PrimitiveTask:SetOperator(action)
    assert(self.Operator == nil, "A Primitive Task can only contain a single Operator!")

    self.Operator = action
end

---@param ctx IContext
function PrimitiveTask:ApplyEffects(ctx)
    if (ctx.LogDecomposition) then
        ctx.CurrentDecompositionDepth = ctx.CurrentDecompositionDepth + 1
        if (ctx.ContextState == IContext.EContextState.Planning) then
            log("%i - PrimitiveTask.ApplyEffects", ctx.CurrentDecompositionDepth)
        end
    end
    for _, effect in ipairs(self.Effects) do
        effect:Apply(ctx)
    end
    if (ctx.LogDecomposition) then ctx.CurrentDecompositionDepth = ctx.CurrentDecompositionDepth - 1 end
end

---@param ctx IContext
function PrimitiveTask:Stop(ctx)
    if (self.Operator) then self.Operator:Stop(ctx) end
end

---@param ctx IContext
function PrimitiveTask:Aborted(ctx)
    if (self.Operator) then self.Operator:Aborted(ctx) end
end

---@param ctx IContext
---@return boolean
function PrimitiveTask:IsValid(ctx)
    if (ctx.LogDecomposition) then
        log(table.size(self.Conditions) > 0 and "%i - PrimitiveTask.IsValid check" or "%i - PrimitiveTask.IsValid check", ctx.CurrentDecompositionDepth + 1)
    end
    for _, condition in ipairs(self.Conditions) do
        if (ctx.LogDecomposition) then
            ctx.CurrentDecompositionDepth = ctx.CurrentDecompositionDepth + 1
            log("\t- %i", ctx.CurrentDecompositionDepth)
        end
        local result = condition:IsValid(ctx)
        if (ctx.LogDecomposition) then
            log("%i - PrimitiveTask.IsValid:%s:%s is%s valid!", ctx.CurrentDecompositionDepth, result and "Success" or "Failed", condition.Name, result and "" or " not")
            ctx.CurrentDecompositionDepth = ctx.CurrentDecompositionDepth - 1
        end
        if (result == false) then
            if (ctx.LogDecomposition) then
                log("%i - PrimitiveTask.IsValid:Failed:Preconditions not met!", ctx.CurrentDecompositionDepth + 1)
            end
            return false
        end
    end

    if (ctx.LogDecomposition) then
        log("%i - PrimitiveTask.IsValid:Success!", ctx.CurrentDecompositionDepth + 1)
    end
    return true
end

return PrimitiveTask
