local mc = require("sb_htn.Utils.middleclass")

---@class IOperator
---@field Start fun(self: IOperator, ctx: IContext): ETaskStatus
---@field Update fun(self: IOperator, ctx: IContext): ETaskStatus
--- Graceful end of task execution.
---@field Stop fun(self: IOperator, ctx: IContext)
--- Forced termination of task execution.
---@field Abort fun(self: IOperator, ctx: IContext)
local IOperator = mc.class("IOperator")

return IOperator