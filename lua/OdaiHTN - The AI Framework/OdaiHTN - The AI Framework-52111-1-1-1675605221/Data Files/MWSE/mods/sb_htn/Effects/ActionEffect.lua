local mc = require("sb_htn.Utils.middleclass")
local IEffect = require("sb_htn.Effects.IEffect")
local EEffectType = require("sb_htn.Effects.EEffectType")
local GetKey = require("sb_htn.Utils.GetKey")

---@class ActionEffect<IContext> : IEffect
local ActionEffect = mc.class("ActionEffect", IEffect)

---@param name string
---@param type EEffectType
---@param func function<IContext>
---@param T IContext
function ActionEffect:initialize(name, type, func, T)
    IEffect.initialize(self)

    self.Name = name
    self.Type = type
    ---@type function<IContext, EEffectType>
    self.Func = func
    self.T = T
end

function ActionEffect:Apply(ctx)
    assert(ctx:isInstanceOf(self.T), "Unexpected context type!")
    if (ctx.LogDecomposition) then
        print(string.format("ActionEffect.Apply:%s\n\t- %i", GetKey(self.Type, EEffectType)), ctx.CurrentDecompositionDepth)
    end
    if (self.Func) then self.Func(ctx, self.Type) end
end

return ActionEffect
