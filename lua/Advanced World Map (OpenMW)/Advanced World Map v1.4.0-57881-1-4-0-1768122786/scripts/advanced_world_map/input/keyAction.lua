local storage = require("openmw.storage")
local async = require("openmw.async")

local commonData = require("scripts.advanced_world_map.common")

local keyBinding = require("scripts.advanced_world_map.input.keyBinding")
local keyCodes = require("scripts.advanced_world_map.input.keyCodes")


local bindingSection = storage.playerSection("AdvWMap:InputBindings")


local this = {}


---@type table<string, {func : function, actions : table<string, boolean>}> by key combination, by id
this.actionBindingByKey = {}
---@type table<string, string>
this.actionBindingById = {}
---@type table<string, table<fun(keyCombination : string, actionId : string), boolean>> by id
this.registeredHandlers = {}


--- Registers an action handler. When the action is triggered, the handler function will be called.
--- If the handler function returns true or nil, the action is considered handled and no further handlers for the pressed key combination will be called.
--- For example, if Ctrl + M is pressed and there is an action "1" for it, and an action "2" for "M":
--- If the handler for action "1" returns true or nil, the handler for action "2" will not be called.
---@param action string
---@param func fun(keyCombination : string, actionId : string)
function this.registerAction(action, func)
    if not action or not func then return end
    this.registeredHandlers[action] = this.registeredHandlers[action] or {}
    this.registeredHandlers[action][func] = true
end

function this.unregisterAction(action, func)
    if not action or not func then return end
    this.registeredHandlers[action] = this.registeredHandlers[action] or {}
    this.registeredHandlers[action][func] = nil
end


local function bindingCallback(keyCombination)
    local handler = this.actionBindingByKey[keyCombination]
    local triggered = false
    if not handler then return end

    for actionId, _ in pairs(handler.actions) do
        for func, _ in pairs(this.registeredHandlers[actionId] or {}) do
            local res = func(keyCombination, actionId)
            if res ~= nil then
                triggered = res or triggered
            else
                triggered = true
            end
        end
    end
    return triggered
end


local function register(id, binding)
    local oldBind = this.actionBindingById[id]
    if oldBind and this.actionBindingByKey[oldBind] then
        local bindData = this.actionBindingByKey[oldBind]
        bindData.actions[id] = nil
        if not next(bindData.actions) then
            keyBinding.unregister(oldBind, bindData.func)
            this.actionBindingByKey[oldBind] = nil
        end
    end

    if binding then
        if not this.actionBindingByKey[binding] then
            this.actionBindingByKey[binding] = {
                actions = {},
                func = bindingCallback,
            }
        end
        this.actionBindingByKey[binding].actions[id] = true
        keyBinding.register(binding, bindingCallback)
    end

    this.actionBindingById[id] = binding
end


---@param action string
---@param binding string
function this.register(action, binding)
    register(action, binding)
    bindingSection:set(action, binding)
end


bindingSection:subscribe(async:callback(function(_, id)
    if not id then return end

    local binding = bindingSection:get(id)

    register(id, binding)

    return id
end))


for id, bind in pairs(bindingSection:asTable()) do
    register(id, bind)
end



return this