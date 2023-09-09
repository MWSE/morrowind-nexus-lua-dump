local mc = require("sb_htn.Utils.middleclass")

---@class IContext
local IContext = mc.class("IContext")

--- The state our context can be in. This is essentially planning or execution state.
---@enum EContextState
IContext.EContextState =
{
    Planning = 1,
    Executing = 2
}

---@class PartialPlanEntry
IContext.PartialPlanEntry = mc.class("PartialPlanEntry")

function IContext.PartialPlanEntry:initialize()
    ---@type ICompoundTask
    self.Task = nil
    ---@type integer
    self.TaskIndex = nil
end

function IContext:initialize()
    ---@type boolean
    self.IsInitialized = nil
    ---@type boolean
    self.IsDirty = nil
    ---@type EContextState
    self.ContextState = nil
    ---@type integer
    self.CurrentDecompositionDepth = nil

    ---@type IFactory
    self.Factory = nil

    --- The Method Traversal Record is used while decomposing a domain and
    --- records the valid decomposition indices as we go through our
    --- decomposition process.
    ---
    --- It "should" be enough to only record decomposition traversal in Selectors.
    ---
    --- This can be used to compare LastMTR with the MTR, and reject
    --- a new plan early if it is of lower priority than the last plan.
    ---
    --- It is the user's responsibility to set the instance of the MTR, so that
    --- the user is free to use pooled instances, or whatever optimization they
    --- see fit.
    ---@type table<integer>
    self.MethodTraversalRecord = nil

    ---@type table<string>
    self.MTRDebug = nil

    --- The Method Traversal Record that was recorded for the currently
    --- running plan.
    ---
    --- If a plan completes successfully, this should be cleared.
    ---
    --- It is the user's responsibility to set the instance of the MTR, so that
    --- the user is free to use pooled instances, or whatever optimization they
    --- see fit.
    ---@type table<integer>
    self.LastMTR = nil

    ---@type table<string>
    self.LastMTRDebug = nil

    --- Whether the planning system should collect debug information about our Method Traversal Record.
    ---@type boolean
    self.DebugMTR = nil

    --- Whether our planning system should log our decomposition. Specially condition success vs failure.
    ---@type boolean
    self.LogDecomposition = nil

    ---@type Queue PartialPlanEntry
    self.PartialPlanQueue = nil

    ---@type boolean
    self.HasPausedPartialPlan = nil

    ---@type number[]
    self.WorldState = nil

    --- A stack of changes applied to each world state entry during planning.
    ---
    --- This is necessary if one wants to support planner-only and plan&execute effects.
    ---
    ---@type Stack[] table<EEffectType, number>
    self.WorldStateChangeStack = nil
end

--- Reset the context state to default values.
function IContext:Reset() end

function IContext:TrimForExecution() end

---@param stackDepth integer[]
function IContext:TrimToStackDepth(stackDepth) end

---@param state integer
---@param value number
---@return boolean
function IContext:HasState(state, value) return false end

---@param state integer
---@return number
function IContext:GetState(state) return 0 end

---@param state integer
---@param value number
---@param setAsDirty boolean
---@param e EEffectType
function IContext:SetState(state, value, setAsDirty, e) end

---@param factory IFactory
---@return integer[]
function IContext:GetWorldStateChangeDepth(factory) return {} end

return IContext
