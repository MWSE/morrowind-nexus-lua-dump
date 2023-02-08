local mc = require("sb_htn.Utils.middleclass")
local IContext = require("sb_htn.Contexts.IContext")
local Queue = require("sb_htn.Utils.Queue")
local EEffectType = require("sb_htn.Effects.EEffectType")
local Stack = require("sb_htn.Utils.Stack")
require("sb_htn.Utils.TableExt")

---@class BaseContext : IContext
local BaseContext = mc.class("BaseContext", IContext)

function BaseContext:initialize()
    IContext.initialize(self)

    ---@type boolean
    self.IsInitialized = false
    ---@type boolean
    self.IsDirty = nil
    ---@type EContextState
    self.ContextState = IContext.EContextState.Executing
    ---@type integer
    self.CurrentDecompositionDepth = 0
    ---@type IFactory
    self.Factory = nil
    ---@type table<integer>
    self.MethodTraversalRecord = {}
    ---@type table<integer>
    self.LastMTR = {}
    ---@type table<integer>
    self.MTRDebug = nil
    ---@type table<integer>
    self.LastMTRDebug = nil
    ---@type boolean
    self.DebugMTR = false
    ---@type Queue PartialPlanEntry
    self.PartialPlanQueue = Queue:new()
    ---@type boolean
    self.HasPausedPartialPlan = false

    ---@type number[]
    self.WorldState = nil

    ---@type Stack[] table<EEffectType, number>
    self.WorldStateChangeStack = nil
end

function BaseContext:init()
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

function BaseContext:HasState(state, value)
    return self:GetState(state) == value
end

function BaseContext:GetState(state)
    if (self.ContextState == IContext.EContextState.Executing) then return self.WorldState[state] end

    if (table.size(self.WorldStateChangeStack[state].list) == 0) then return self.WorldState[state] end

    return self.WorldStateChangeStack[state]:peek()[2]
end

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
        self.WorldStateChangeStack[state]:push({ e or EEffectType.Permanent, value })
    end
end

function BaseContext:GetWorldStateChangeDepth(factory)
    local stackDepth = factory:CreateArray(table.size(self.WorldStateChangeStack), Stack)
    for i = 1, table.size(self.WorldStateChangeStack) do stackDepth[i] = table.size(self.WorldStateChangeStack[i].list)
            or 1
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
