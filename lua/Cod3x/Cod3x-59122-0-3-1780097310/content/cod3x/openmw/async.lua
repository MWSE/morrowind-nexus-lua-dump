---@meta

-- This file was mechanically drafted from files/lua_api/openmw/async.lua.
-- It uses LuaLS/LLS annotations and stub bodies only; runtime behavior is provided by OpenMW.
-- OpenMW script contexts: global|menu|local|player|load

---Contains timers and coroutine utilities. All functions require
---the package itself as a first argument.
---@class openmw.async
local async = {}

---@class openmw.async.Callback
local Callback = {}

---@class openmw.async.TimerCallback
local TimerCallback = {}

---Register a function as a timer callback.
---@param self any
---@param name string
---@param func fun(...): any
---@return openmw.async.TimerCallback
function async.registerTimerCallback(self, name, func) end

---Calls callback(arg) in `delay` simulation seconds.
---The callback must be registered in advance.
---@param self any
---@param delay number
---@param callback openmw.async.TimerCallback A callback returned by `registerTimerCallback`
---@param arg any An argument for `callback`; can be `nil`.
function async.newSimulationTimer(self, delay, callback, arg) end

---Calls callback(arg) in `delay` game seconds.
---The callback must be registered in advance.
---@param self any
---@param delay number
---@param callback openmw.async.TimerCallback A callback returned by `registerTimerCallback`
---@param arg any An argument for `callback`; can be `nil`.
function async.newGameTimer(self, delay, callback, arg) end

---Calls `func()` in `delay` simulation seconds.
---The timer will be lost if the game is saved and loaded.
---@param self any
---@param delay number
---@param func fun(...): any
function async.newUnsavableSimulationTimer(self, delay, func) end

---Calls `func()` in `delay` game seconds.
---The timer will be lost if the game is saved and loaded.
---@param self any
---@param delay number
---@param func fun(...): any
function async.newUnsavableGameTimer(self, delay, func) end

---Wraps a Lua function with a `Callback` object that can be used in async API calls.
---@param self any
---@param func fun(...): any
---@return openmw.async.Callback
function async.callback(self, func) end

return async
