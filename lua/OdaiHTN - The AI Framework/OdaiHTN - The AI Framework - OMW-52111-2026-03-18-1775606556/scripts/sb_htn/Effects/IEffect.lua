local mc = require("sb_htn.Utils.middleclass")

---@class IEffect
---@field Name string
---@field Type EEffectType
---@field Apply fun(self: IEffect, ctx: IContext)
local IEffect = mc.class("IEffect")

return IEffect