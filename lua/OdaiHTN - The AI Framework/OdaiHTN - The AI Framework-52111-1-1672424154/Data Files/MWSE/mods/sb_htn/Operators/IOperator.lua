local mc = require("sb_htn.Utils.middleclass")

---@class IOperator
local IOperator = mc.class("IOperator")

---@param ctx IContext
---@return ETaskStatus | 0
function IOperator:Update(ctx) return 0 end

---@param ctx IContext
function IOperator:Stop(ctx) end

return IOperator
