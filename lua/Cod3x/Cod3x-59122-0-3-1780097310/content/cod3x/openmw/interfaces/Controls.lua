---@meta

-- Dedicated LuaLS stub for require("openmw.interfaces").Controls.
-- Source: files/data/scripts/omw/input/playercontrols.lua
-- Runtime availability depends on script context, OpenMW version, and active content files.

-- OpenMW script contexts: player

---@class openmw.interfaces.Controls
---@field version number
local Controls = {}

---Interface version
---@type number
Controls.version = nil

---When set to true then the movement controls including jump and sneak are not processed and can be handled by another script.
---If movement should be disallowed completely, consider to use `types.Player.setControlSwitch` instead.
---@param value boolean
function Controls.overrideMovementControls(value) end

---When set to true then the controls "attack", "toggle spell", "toggle weapon" are not processed and can be handled by another script.
---If combat should be disallowed completely, consider to use `types.Player.setControlSwitch` instead.
---@param value boolean
function Controls.overrideCombatControls(value) end

---When set to true then the controls "open inventory", "open journal" and so on are not processed and can be handled by another script.
---@param value boolean
function Controls.overrideUiControls(value) end

return Controls
