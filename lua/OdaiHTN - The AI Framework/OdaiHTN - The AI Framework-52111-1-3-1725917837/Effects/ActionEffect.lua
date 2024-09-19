local mc = require("sb_htn.Utils.middleclass")
local IEffect = require("sb_htn.Effects.IEffect")
local EEffectType = require("sb_htn.Effects.EEffectType")
local GetKey = require("sb_htn.Utils.GetKey")

---@class ActionEffect<IContext> : IEffect
local ActionEffect = mc.class("ActionEffect", IEffect)

---@param name string
---@param effectType EEffectType
---@param func function<IContext>
---@param T IContext
function ActionEffect:initialize(T, name, effectType, func)
    IEffect.initialize(self)

    self.Name = name
    self.Type = effectType
    ---@type function<IContext, EEffectType>
    self.Func = func
    self.T = T
end

---@param ctx IContext
function ActionEffect:Apply(ctx)
    assert(ctx:isInstanceOf(self.T), "Unexpected context type!")
    if (ctx.LogDecomposition) then
        log("%i - ActionEffect.Apply:%s", ctx.CurrentDecompositionDepth, GetKey(self.Type, EEffectType))
    end
    if (self.Func) then self.Func(ctx, self.Type) end
end

return ActionEffect
