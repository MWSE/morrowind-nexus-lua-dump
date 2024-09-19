local mc = require("sb_htn.Utils.middleclass")
local ICondition = require("sb_htn.Conditions.ICondition")

---@class FuncCondition<IContext> : ICondition
local FuncCondition = mc.class("FuncCondition", ICondition)

---@param name string
---@param func function<IContext>
---@param T IContext
function FuncCondition:initialize(T, name, func)
    ICondition.initialize(self)

    self.Name = name
    ---@type function<IContext>
    ---@return boolean
    self.Func = func
    self.T = T
end

---@param ctx IContext
---@return boolean
function FuncCondition:IsValid(ctx)
    assert(ctx:isInstanceOf(self.T), "Unexpected context type!")
    local result = self.Func and self.Func(ctx) or false
    if (ctx.LogDecomposition) then
        log("%i - FuncCondition.IsValid:%s", ctx.CurrentDecompositionDepth + 1, result and "True" or "False")
    end
    return result
end

return FuncCondition
