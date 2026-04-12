local mc = require("sb_htn.Utils.middleclass")

---@class ITask
--- Used for debugging and identification purposes
---@field Name string
--- The parent of this task in the hierarchy
---@field Parent ICompoundTask
--- The conditions that must be satisfied for this task to pass as valid.
---@field Conditions ICondition[]
--- Add a new condition to the task.
---@field AddCondition fun(self: ITask, condition: ICondition): ITask
--- Check the task's preconditions, returns true if all preconditions are valid.
---@field IsValid fun(self: ITask, ctx: IContext): boolean
---@field OnIsValidFailed fun(self: ITask, ctx: IContext): EDecompositionStatus
local ITask = mc.class("ITask")

return ITask