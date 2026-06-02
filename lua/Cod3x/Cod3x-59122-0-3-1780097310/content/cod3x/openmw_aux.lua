---@meta

-- Convenience index for OpenMW auxiliary LuaLS stubs. Runtime code should require modules directly.
---@class openmw_aux
local openmw_aux = {}

---@type openmw_aux.calendar
openmw_aux.calendar = require("openmw_aux.calendar")
---@type openmw_aux.calendarconfig
openmw_aux.calendarconfig = require("openmw_aux.calendarconfig")
---@type openmw_aux.time
openmw_aux.time = require("openmw_aux.time")
---@type openmw_aux.ui
openmw_aux.ui = require("openmw_aux.ui")
---@type openmw_aux.util
openmw_aux.util = require("openmw_aux.util")

return openmw_aux
