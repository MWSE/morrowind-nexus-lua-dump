---@meta

-- LuaLS stubs for OpenMW's Lua auxiliary timers.
-- Runtime behavior is provided by OpenMW resources/vfs/openmw_aux/time.lua.
-- OpenMW script contexts: global|menu|local|player

---Utility functions for timers.
---@class openmw_aux.time
---@field second number One simulation/game second.
---@field minute number One minute in seconds.
---@field hour number One hour in seconds.
---@field day number One day in seconds.
---@field GameTime string Timer type using game time.
---@field SimulationTime string Timer type using simulation time.
local time = {}

---Options for `openmw_aux.time.runRepeatedly`.
---@class openmw_aux.time.RunRepeatedlyOptions
---@field initialDelay? number Delay before the first call. Defaults to a random delay in `[0, period]`.
---@field type? string Either `time.SimulationTime` or `time.GameTime`.

time.second = 1
time.minute = 60
time.hour = 3600
time.day = 86400
time.GameTime = 'GameTime'
time.SimulationTime = 'SimulationTime'

---Alias of `async:registerTimerCallback`; register a function as a timer callback.
---@param name string
---@param fn fun(...): any
---@return openmw.async.TimerCallback
function time.registerTimerCallback(name, fn) end

---Alias of `async:newGameTimer`; call `callback(arg)` in `delay` game seconds.
---The callback must be registered in advance.
---@param delay number
---@param callback openmw.async.TimerCallback A callback returned by `registerTimerCallback`.
---@param callbackArg? any An argument for `callback`; can be nil.
function time.newGameTimer(delay, callback, callbackArg) end

---Alias of `async:newSimulationTimer`; call `callback(arg)` in `delay` simulation seconds.
---The callback must be registered in advance.
---@param delay number
---@param callback openmw.async.TimerCallback A callback returned by `registerTimerCallback`.
---@param callbackArg? any An argument for `callback`; can be nil.
function time.newSimulationTimer(delay, callback, callbackArg) end

---Run a function repeatedly until the returned stop function is called.
---Loading a save stops evaluation; call this during script initialization if it should always work.
---@param fn fun()
---@param period number Interval between calls.
---@param options? openmw_aux.time.RunRepeatedlyOptions Additional options.
---@return fun() stop A function without arguments that stops periodical evaluation.
function time.runRepeatedly(fn, period, options) end

return time
