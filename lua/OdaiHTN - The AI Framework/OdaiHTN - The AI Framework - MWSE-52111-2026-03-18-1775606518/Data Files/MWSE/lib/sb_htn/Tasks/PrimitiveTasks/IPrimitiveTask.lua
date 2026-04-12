local mc = require("sb_htn.Utils.middleclass")
local ITask = require("sb_htn.Tasks.ITask")

---@class IPrimitiveTask : ITask
--- Executing conditions are validated before every call to Operator.Update(...)
---@field ExecutingConditions ICondition[]
---@field Operator IOperator
---@field Effects IEffect[]
--- Add a new executing condition to the primitive task. This will be checked before
--- every call to Operator.Update(...)
---@field AddExecutingCondition fun(self: IPrimitiveTask, condition: ICondition): IPrimitiveTask
---@field SetOperator fun(self: IPrimitiveTask, action: IOperator)
---@field AddEffect fun(self: IPrimitiveTask, effect: IEffect): IPrimitiveTask
---@field ApplyEffects fun(self: IPrimitiveTask, ctx: IContext)
--- Graceful end of task execution.
---@field Stop fun(self: IPrimitiveTask, ctx: IContext)
--- Forced termination of task execution.
---@field Abort fun(self: IPrimitiveTask, ctx: IContext)
local IPrimitiveTask = mc.class("IPrimitiveTask", ITask)

return IPrimitiveTask