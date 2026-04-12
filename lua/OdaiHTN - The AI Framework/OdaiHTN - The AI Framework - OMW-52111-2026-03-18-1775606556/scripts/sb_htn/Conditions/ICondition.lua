local mc = require("sb_htn.Utils.middleclass")

---@class ICondition
---@field Name string
---@field IsValid fun(ctx: IContext): boolean
local ICondition = mc.class("ICondition")

return ICondition