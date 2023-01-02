local mc = require("sb_htn.Utils.middleclass")

---@class ICondition
local ICondition = mc.class("ICondition")

function ICondition:initialize()
    ---@type string
    self.Name = ""
end

---@param ctx IContext
---@return boolean
function ICondition:IsValid(ctx) return false end

return ICondition
