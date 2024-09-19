local mc = require("sb_htn.Utils.middleclass")
local Domain = require("sb_htn.Domain")
local ICompoundTask = require("sb_htn.Tasks.CompoundTasks.ICompoundTask")
local Sequence = require("sb_htn.Tasks.CompoundTasks.Sequence")
local Selector = require("sb_htn.Tasks.CompoundTasks.Selector")
local PrimitiveTask = require("sb_htn.Tasks.PrimitiveTasks.PrimitiveTask")
local IPrimitiveTask = require("sb_htn.Tasks.PrimitiveTasks.IPrimitiveTask")
local PausePlanTask = require("sb_htn.Tasks.CompoundTasks.PausePlanTask")
local FuncCondition = require("sb_htn.Conditions.FuncCondition")
local FuncOperator = require("sb_htn.Operators.FuncOperator")
local ActionEffect = require("sb_htn.Effects.ActionEffect")
local Slot = require("sb_htn.Tasks.OtherTasks.Slot")

---@class BaseDomainBuilder<BaseDomainBuilder, IContext>
local BaseDomainBuilder = mc.class("BaseDomainBuilder")

---@param domainName string
---@param factory IFactory
---@param DB BaseDomainBuilder
---@param T IContext
function BaseDomainBuilder:initialize(T, domainName, factory, DB)
    ---@type IFactory
    self._factory = factory
    ---@type Domain
    self._domain = Domain:new(T, domainName)
    ---@type table<ITask>
    self._pointers = self._factory:CreateList()
    table.insert(self._pointers, self._domain.Root)
    self.DB = DB
    self.T = T
end

---@return ITask | nil
function BaseDomainBuilder:Pointer()
    if (table.size(self._pointers) == 0) then return nil end
    return self._pointers[table.size(self._pointers)]
end

--- Compound tasks are where HTN get their “hierarchical” nature. You can think of a compound task as
--- a high level task that has multiple ways of being accomplished. There are primarily two types of
--- compound tasks. Selectors and Sequencers. A Selector must be able to decompose a single sub-task,
--- while a Sequence must be able to decompose all its sub-tasks successfully for itself to have decomposed
--- successfully. There is nothing stopping you from extending this toolset with RandomSelect, UtilitySelect,
--- etc. These tasks are decomposed until we're left with only Primitive Tasks, which represent a final plan.
---
--- Compound tasks are comprised of a set of subtasks and a set of conditions.
---
--- http:--www.gameaipro.com/GameAIPro/GameAIPro_Chapter12_Exploring_HTN_Planners_through_Example.pdf
---@param name string
---@param P ICompoundTask
---@return BaseDomainBuilder
function BaseDomainBuilder:Compound(name, P)
    local parent = P:new()
    return self:CompoundTask(name, parent)
end

--- Compound tasks are where HTN get their “hierarchical” nature. You can think of a compound task as
--- a high level task that has multiple ways of being accomplished. There are primarily two types of
--- compound tasks. Selectors and Sequencers. A Selector must be able to decompose a single sub-task,
--- while a Sequence must be able to decompose all its sub-tasks successfully for itself to have decomposed
--- successfully. There is nothing stopping you from extending this toolset with RandomSelect, UtilitySelect,
--- etc. These tasks are decomposed until we're left with only Primitive Tasks, which represent a final plan.
---
--- Compound tasks are comprised of a set of subtasks and a set of conditions.
---
--- http:--www.gameaipro.com/GameAIPro/GameAIPro_Chapter12_Exploring_HTN_Planners_through_Example.pdf
---@param name string
---@param task ICompoundTask
---@return BaseDomainBuilder
function BaseDomainBuilder:CompoundTask(name, task)
    assert(task, "task")
    assert(self:Pointer():isInstanceOf(ICompoundTask),
        "Pointer is not a compound task type. Did you forget an End() after a Primitive Task Action was defined?")
    task.Name = name
    self._domain:AddTask(self:Pointer(), task)
    table.insert(self._pointers, task)
    return self
end

--- Primitive tasks represent a single step that can be performed by our AI. A set of primitive tasks is
--- the plan that we are ultimately getting out of the HTN. Primitive tasks are comprised of an operator,
--- a set of effects, a set of conditions and a set of executing conditions.
---
--- http:--www.gameaipro.com/GameAIPro/GameAIPro_Chapter12_Exploring_HTN_Planners_through_Example.pdf
---@param name string
---@param P IPrimitiveTask
---@return BaseDomainBuilder
function BaseDomainBuilder:PrimitiveTask(name, P)
    assert(self:Pointer():isInstanceOf(ICompoundTask),
        "Pointer is not a compound task type. Did you forget an End() after a Primitive Task Action was defined?")
    local parent = P:new()
    parent.Name = name
    self._domain:AddTask(self:Pointer(), parent)
    table.insert(self._pointers, parent)

    return self
end

--- Partial planning is one of the most powerful features of HTN. In simplest terms, it allows
--- the planner the ability to not fully decompose a complete plan. HTN is able to do this because
--- it uses forward decomposition or forward search to find plans. That is, the planner starts with
--- the current world state and plans forward in time from that. This allows the planner to only
--- plan ahead a few steps.
---
--- http:--www.gameaipro.com/GameAIPro/GameAIPro_Chapter12_Exploring_HTN_Planners_through_Example.pdf
---@return BaseDomainBuilder
function BaseDomainBuilder:PausePlanTask()
    assert(self:Pointer().IDecomposeAll,
        "Pointer is not a decompose-all compound task type, like a Sequence. Maybe you tried to Pause Plan a Selector, or forget an End() after a Primitive Task Action was defined?")
    local parent = PausePlanTask:new()
    parent.Name = "Pause Plan"
    self._domain:AddTask(self:Pointer(), parent)

    return self
end

--- A compound task that requires all sub-tasks to be valid.
---
--- Sub-tasks can be sequences, selectors or actions.
---@param name string
---@return BaseDomainBuilder
function BaseDomainBuilder:Sequence(name)
    return self:Compound(name, Sequence)
end

--- A compound task that requires a single sub-task to be valid.
---
--- Sub-tasks can be sequences, selectors or actions.
---@param name string
---@return BaseDomainBuilder
function BaseDomainBuilder:Select(name)
    return self:Compound(name, Selector)
end

--- A primitive task that can contain conditions, an operator and effects.
---@param name string
---@return BaseDomainBuilder
function BaseDomainBuilder:Action(name)
    return self:PrimitiveTask(name, PrimitiveTask)
end

--- A precondition is a boolean statement required for the parent task to validate.
---
--- <param name="name"></param>
---@param name string
---@param condition function<IContext>
---@return BaseDomainBuilder
function BaseDomainBuilder:Condition(name, condition)
    local cond = FuncCondition:new(self.T, name, condition)
    self:Pointer():AddCondition(cond)

    return self
end

--- An executing condition is a boolean statement validated before every call to the current.
---
--- primitive task's operator update tick. It's only supported inside primitive tasks / Actions.
---
--- Note that this condition is never validated during planning, only during execution.
---@param name string
---@param condition function<IContext>
---@return BaseDomainBuilder
function BaseDomainBuilder:ExecutingCondition(name, condition)
    assert(self:Pointer():isInstanceOf(IPrimitiveTask),
        "Tried to add an Executing Condition, but the Pointer is not a Primitive Task!")
    local cond = FuncCondition:new(self.T, name, condition)
    self:Pointer():AddExecutingCondition(cond)

    return self
end

--- The operator of an Action / primitive task.
---@param action function<IContext>
---@param forceStopAction function<IContext>
---@return BaseDomainBuilder
function BaseDomainBuilder:Do(action, forceStopAction)
    assert(self:Pointer():isInstanceOf(IPrimitiveTask),
        "Tried to add an Operator, but the Pointer is not a Primitive Task!")
    local op = FuncOperator:new(self.T, action, forceStopAction or nil)
    self:Pointer():SetOperator(op)

    return self
end

--- Effects can be added to an Action / primitive task.
---@param name string
---@param effectType EEffectType
---@param func function<IContext>
---@return BaseDomainBuilder
function BaseDomainBuilder:Effect(name, effectType, func)
    assert(self:Pointer():isInstanceOf(IPrimitiveTask),
        "Tried to add an Effect, but the Pointer is not a Primitive Task!")
    local effect = ActionEffect:new(self.T, name, effectType, func)
    self:Pointer():AddEffect(effect)

    return self
end

--- Every task encapsulation must end with a call to End(), otherwise subsequent calls will be applied wrong.
---@return BaseDomainBuilder
function BaseDomainBuilder:End()
    self._pointers[table.size(self._pointers)] = nil
    return self
end

--- We can splice multiple domains together, allowing us to define reusable sub-domains.
---@param domain Domain
---@return BaseDomainBuilder
function BaseDomainBuilder:Splice(domain)
    assert(self:Pointer():isInstanceOf(ICompoundTask), "Pointer is not a compound task type. Did you forget an End()?")
    self._domain:AddTask(self:Pointer(), domain.Root)

    return self
end

--- The identifier associated with a slot can be used to splice
--- sub-domains onto the domain, and remove them, at runtime.
---
--- Use TrySetSlotDomain and ClearSlot on the domain instance at
--- runtime to manage this feature. SlotId can typically be implemented
--- as an enum.
---@param slotId integer
---@return BaseDomainBuilder
function BaseDomainBuilder:Slot(slotId)
    assert(self:Pointer():isInstanceOf(ICompoundTask), "Pointer is not a compound task type. Did you forget an End()?")
    local slot = Slot:new()
    slot.SlotId = slotId
    slot.Name = string.format("Slot %i", slotId)
    self._domain:AddSlot(self:Pointer(), slot)

    return self
end

--- We can add a Pause Plan when in a sequence in our domain definition,
--- and this will give us partial planning.
---
--- It means that we can tell our planner to only plan up to a certain point,
--- then stop. If the partial plan completes execution successfully, the next
--- time we try to find a plan, we will continue planning where we left off.
---
--- Typical use cases is to split after we navigate toward a location, since
--- this is often time consuming, it's hard to predict the world state when
--- we have reached the destination, and thus there's little point wasting
--- milliseconds on planning further into the future at that point. We might
--- still want to plan what to do when reaching the destination, however, and
--- this is where partial plans come into play.
---@return BaseDomainBuilder
function BaseDomainBuilder:PausePlan()
    return self:PausePlanTask()
end

--- Build the designed domain and return a domain instance.
---@return Domain
function BaseDomainBuilder:Build()
    assert(self:Pointer() == self._domain.Root,
        string.format("The domain definition lacks one or more End() statements. Pointer is '%s', but expected '%s'.",
            self:Pointer().Name, self._domain.Root.Name))

    self._factory:FreeList(nil, self._pointers)
    return self._domain
end

return BaseDomainBuilder
