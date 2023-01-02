local mc = require("sb_htn.Utils.middleclass")

---@class ITask
local ITask = mc.class("ITask")

function ITask:initialize()
    --- Used for debugging and identification purposes
    ---@type string
    self.Name = ""

    --- The parent of this task in the hierarchy
    ---@type ICompoundTask
    self.Parent = nil

    --- The conditions that must be satisfied for this task to pass as valid.
    ---@type table<ICondition>
    self.Conditions = {}
end

--- Add a new condition to the task.
---@param condition ICondition
---@return ITask
function ITask:AddCondition(condition) return {} end

--- Check the task's preconditions, returns true if all preconditions are valid.
---@param ctx IContext
---@return boolean
function ITask:IsValid(ctx) return false end

---@param ctx IContext
---@return EDecompositionStatus | 0
function ITask:OnIsValidFailed(ctx) return 0 end

return ITask
