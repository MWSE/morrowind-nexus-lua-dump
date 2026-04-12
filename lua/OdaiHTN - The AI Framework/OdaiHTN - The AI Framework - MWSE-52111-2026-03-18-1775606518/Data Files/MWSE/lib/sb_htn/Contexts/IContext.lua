local mc = require("sb_htn.Utils.middleclass")

---@class IContext
---@field IsInitialized boolean
---@field IsDirty boolean
---@field ContextState EContextState
---@field CurrentDecompositionDepth integer
---@field Factory IFactory
---@field PlannerState IPlannerState
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
---@field MethodTraversalRecord integer[]
--- The Method Traversal Record that was recorded for the currently
--- running plan.
---
--- If a plan completes successfully, this should be cleared.
---
--- It is the user's responsibility to set the instance of the MTR, so that
--- the user is free to use pooled instances, or whatever optimization they
--- see fit.
---@field LastMTR integer[]
---@field MTRDebug integer[]
---@field LastMTRDebug integer[]
--- Whether the planning system should collect debug information about our Method Traversal Record.
---@field DebugMTR boolean
--- Whether our planning system should log our decomposition. Specially condition success vs failure.
---@field LogDecomposition boolean
---@field PartialPlanQueue Queue<PartialPlanEntry>
---@field HasPausedPartialPlan boolean
---@field WorldState number[]
--- A stack of changes applied to each world state entry during planning.
---
--- This is necessary if one wants to support planner-only and plan&execute effects.
---@field WorldStateChangeStack Stack<EEffectType, number[]>
--- Reset the context state to default values.
---@field Reset fun(self: IContext)
---@field TrimForExecution fun(self: IContext)
---@field TrimToStackDepth fun(self: IContext, stackDepth: integer[])
---@field HasState fun(self: IContext, state: integer, value: number): boolean
---@field GetState fun(self: IContext, state: integer): number
---@field SetState fun(self: IContext, state: integer, value: number, setAsDirty: boolean, e: EEffectType)
---@field GetWorldStateChangeDepth fun(self: IContext, factory: IFactory): integer[]
local IContext = mc.class("IContext")

--- The state our context can be in. This is essentially planning or execution state.
---@enum EContextState
IContext.EContextState =
{
    Planning = 1,
    Executing = 2
}

---@class PartialPlanEntry
---@field Task ICompoundTask
---@field TaskIndex integer
IContext.PartialPlanEntry = mc.class("PartialPlanEntry")

return IContext