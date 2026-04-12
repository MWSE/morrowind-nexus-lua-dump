local mc = require("sb_htn.Utils.middleclass")
local IContext = require("sb_htn.Contexts.IContext")
local Queue = require("sb_htn.Utils.Queue")
local EEffectType = require("sb_htn.Effects.EEffectType")
local Stack = require("sb_htn.Utils.Stack")

---@class BaseContext : IContext
local BaseContext = mc.class("BaseContext", IContext)

---@class BaseContextParams
---@field IsDirty boolean?
---@field ContextState EContextState?
---@field CurrentDecompositionDepth integer?
---@field PlannerState IPlannerState?
---@field MethodTraversalRecord integer[]?
---@field MTRDebug integer[]?
---@field LastMTRDebug integer[]?
---@field PartialPlanQueue Queue<PartialPlanEntry>?
---@field HasPausedPartialPlan boolean?
---@field WorldStateChangeStack Stack<table<EEffectType, number>>[]

---@param params BaseContextParams?
function BaseContext:initialize(params)
    self.IsInitialized = false
    self.IsDirty = params and params.IsDirty or nil
    self.ContextState = params and params.ContextState or IContext.EContextState.Executing
    self.CurrentDecompositionDepth = params and params.CurrentDecompositionDepth or 0
    self.Factory = nil
    self.PlannerState = params and params.PlannerState or nil
    self.MethodTraversalRecord = params and params.MethodTraversalRecord or {}
    self.LastMTR = {}
    self.MTRDebug = params and params.MTRDebug or nil
    self.LastMTRDebug = params and params.LastMTRDebug or nil
    self.DebugMTR = false
    self.LogDecomposition = false
    self.PartialPlanQueue = params and params.PartialPlanQueue or Queue:new()
    self.HasPausedPartialPlan = params and params.HasPausedPartialPlan ~= nil and params.HasPausedPartialPlan or false

    self.WorldState = nil

    self.WorldStateChangeStack = params and params.WorldStateChangeStack or nil
end

function BaseContext:Init()
    if (self.WorldStateChangeStack == nil) then
        self.WorldStateChangeStack = {}
        for i = 1, table.size(self.WorldState) do
            self.WorldStateChangeStack[i] = Stack:new()
        end
    end

    if (self.DebugMTR) then
        if (self.MTRDebug == nil) then self.MTRDebug = {} end
        if (self.LastMTRDebug == nil) then self.LastMTRDebug = {} end
    end

    self.IsInitialized = true
end

---@param state any
---@param value integer
---@return boolean
function BaseContext:HasState(state, value)
    return self:GetState(state) == value
end

---@param state any
---@return integer
function BaseContext:GetState(state)
    if (self.ContextState == IContext.EContextState.Executing) then return self.WorldState[state] end

    if (table.size(self.WorldStateChangeStack[state].list) == 0) then return self.WorldState[state] end

    return self.WorldStateChangeStack[state]:peek()[2]
end

---@param state any
---@param value integer
---@param setAsDirty boolean
---@param e EEffectType?
function BaseContext:SetState(state, value, setAsDirty, e)
    if (self.ContextState == IContext.EContextState.Executing) then
        -- Prevent setting the world state dirty if we're not changing anything.
        if (self.WorldState[state] == value) then
            return
        end

        self.WorldState[state] = value
        if (setAsDirty) then
            self.IsDirty = true -- When a state change during execution, we need to mark the context dirty for replanning!
        end
    else
        self.WorldStateChangeStack[state]:push{e or EEffectType.Permanent, value}
    end
end

---@param factory IFactory
---@return any[]
function BaseContext:GetWorldStateChangeDepth(factory)
    local stackDepth = factory:CreateArray(Stack, table.size(self.WorldStateChangeStack))
    for i = 1, table.size(self.WorldStateChangeStack) do
        stackDepth[i] = table.size(self.WorldStateChangeStack[i].list) or 1
    end

    return stackDepth
end

function BaseContext:TrimForExecution()
    assert(self.ContextState ~= IContext.EContextState.Executing, "Can not trim a context when in execution mode")

    for _, stack in ipairs(self.WorldStateChangeStack) do
        while (table.size(stack.list) ~= 0 and stack:peek()[1] ~= EEffectType.Permanent) do
            stack:pop()
        end
    end
end

---@param stackDepth integer
function BaseContext:TrimToStackDepth(stackDepth)
    assert(self.ContextState ~= IContext.EContextState.Executing, "Can not trim a context when in execution mode")

    for i = 1, table.size(stackDepth) do
        local stack = self.WorldStateChangeStack[i]
        while (table.size(stack.list) > stackDepth[i]) do stack:pop() end
    end
end

function BaseContext:Reset()
    self.MethodTraversalRecord = self.MethodTraversalRecord and {} or nil
    self.LastMTR = self.LastMTR and {} or nil

    if (self.DebugMTR) then
        self.MTRDebug = self.MTRDebug and {} or nil
        self.LastMTRDebug = self.LastMTRDebug and {} or nil
    end

    self.IsInitialized = false
end

return BaseContext