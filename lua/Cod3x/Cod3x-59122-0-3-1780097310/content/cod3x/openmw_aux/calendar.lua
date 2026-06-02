---@meta

-- LuaLS stubs for OpenMW's Lua auxiliary calendar helpers.
-- Runtime behavior is provided by OpenMW resources/vfs/openmw_aux/calendar.lua.
-- OpenMW script contexts: global|menu|local|player

---Utility functions for formatting game time.
---@class openmw_aux.calendar
---@field monthCount number The number of months in a year.
---@field daysInYear number The number of days in a year.
---@field daysInWeek number The number of days in a week.
local calendar = {}

---Table accepted by `gameTime` and returned by `formatGameTime('*t', ...)`.
---@class openmw_aux.calendar.GameTimeTable
---@field year? integer
---@field month? integer
---@field day? integer
---@field hour? integer
---@field min? integer
---@field sec? integer
---@field yday? integer
---@field wday? integer

calendar.monthCount = 12
calendar.daysInYear = 365
calendar.daysInWeek = 7

---An equivalent of `os.time` for game time.
---@param table? openmw_aux.calendar.GameTimeTable Date table. If omitted, returns current game time.
---@return number timestamp
function calendar.gameTime(table) end

---An equivalent of `os.date` for game time.
---This is a slow function; avoid using it every frame.
---@overload fun(format: "*t", time?: number): openmw_aux.calendar.GameTimeTable
---@param format? string Date format; defaults to `%c`.
---@param time? number Time to format; defaults to current game time.
---@return string formattedTime
function calendar.formatGameTime(format, time) end

---The number of days in a month.
---@param monthIndex integer
---@return number
function calendar.daysInMonth(monthIndex) end

---The name of a month.
---@param monthIndex integer
---@return string
function calendar.monthName(monthIndex) end

---The name of a month in genitive form.
---@param monthIndex integer
---@return string
function calendar.monthNameInGenitive(monthIndex) end

---The name of a weekday.
---@param dayIndex integer
---@return string
function calendar.weekdayName(dayIndex) end

return calendar
