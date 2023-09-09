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
---@return EDecompositionStatus | 0
function PrimitiveTask:OnIsValidFailed(ctx)
    return EDecompositionStatus.Failed
end

---@param condition ICondition
---@return ITask
function PrimitiveTask:AddCondition(condition)
    table.insert(self.Conditions, condition)
    return self
end

function PrimitiveTask:AddExecutingCondition(condition)
    table.insert(self.ExecutingConditions, condition)
    return self
end

function PrimitiveTask:AddEffect(effect)
    table.insert(self.Effects, effect)
    return self
end

function PrimitiveTask:SetOperator(action)
    assert(self.Operator == nil, "A Primitive Task can only contain a single Operator!")

    self.Operator = action
end

function PrimitiveTask:ApplyEffects(ctx)
    if (ctx.LogDecomposition) then
        ctx.CurrentDecompositionDepth = ctx.CurrentDecompositionDepth + 1
        if (ctx.ContextState == IContext.EContextState.Planning) then print(string.format("PrimitiveTask.ApplyEffects\n\t- %i",
                ctx.CurrentDecompositionDepth))
        end
    end
    for _, effect in ipairs(self.Effects) do
        effect:Apply(ctx)
    end
    if (ctx.LogDecomposition) then ctx.CurrentDecompositionDepth = ctx.CurrentDecompositionDepth - 1 end
end

function PrimitiveTask:Stop(ctx)
    self.Operator:Stop(ctx)
end

---@param ctx IContext
---@return boolean
function PrimitiveTask:IsValid(ctx)
    if (ctx.LogDecomposition) then print(string.format(table.size(self.Conditions) > 0 and "PrimitiveTask.IsValid check" or
            "PrimitiveTask.IsValid check\n\t- %i", ctx.CurrentDecompositionDepth + 1))
    end
    for _, condition in ipairs(self.Conditions) do
        if (ctx.LogDecomposition) then
            ctx.CurrentDecompositionDepth = ctx.CurrentDecompositionDepth + 1
            print(string.format("\t- %i", ctx.CurrentDecompositionDepth))
        end
        local result = condition:IsValid(ctx)
        if (ctx.LogDecomposition) then
            print(string.format("PrimitiveTask.IsValid:%s:%s is%s valid!\n\t- %i", result and "Success" or "Failed", condition.Name
                , result and "" or " not", ctx.CurrentDecompositionDepth))
            ctx.CurrentDecompositionDepth = ctx.CurrentDecompositionDepth - 1
        end
        if (result == false) then
            if (ctx.LogDecomposition) then print(string.format("PrimitiveTask.IsValid:Failed:Preconditions not met!\n\t- %i",
                    ctx.CurrentDecompositionDepth + 1))
            end
            return false
        end
    end

    if (ctx.LogDecomposition) then print(string.format("PrimitiveTask.IsValid:Success!\n\t- %i", ctx.CurrentDecompositionDepth + 1)) end
    return true
end

return PrimitiveTask
