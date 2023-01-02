local mc = require("sb_htn.Utils.middleclass")

---@class IEffect
local IEffect = mc.class("IEffect")

function IEffect:initialize()
    ---@type string
    self.Name = ""
    ---@type EEffectType
    self.Type = 1
end

---@param ctx IContext
function IEffect:Apply(ctx) end

return IEffect
