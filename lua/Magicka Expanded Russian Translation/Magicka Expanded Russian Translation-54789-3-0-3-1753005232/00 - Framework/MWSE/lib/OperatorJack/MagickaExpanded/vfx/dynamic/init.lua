---@class MagickaExpanded.Vfx.Dynamic
local this = {}

---@type MagickaExpanded.Vfx.Dynamic.Lightning?
this.lightning = nil

event.register(tes3.event.initialized, function()
    this.lightning = require("OperatorJack.MagickaExpanded.vfx.dynamic.lightning")
end, {priority = 10000})

return this
