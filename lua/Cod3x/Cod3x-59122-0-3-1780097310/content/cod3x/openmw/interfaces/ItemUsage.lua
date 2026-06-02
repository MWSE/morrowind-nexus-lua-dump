---@meta

-- Dedicated LuaLS stub for require("openmw.interfaces").ItemUsage.
-- Source: files/data/scripts/omw/usehandlers.lua
-- Runtime availability depends on script context, OpenMW version, and active content files.

-- OpenMW script contexts: global

---Allows to extend or override built-in item usage mechanics.
---Note: at the moment it can override item usage in inventory
---(dragging an item on the character's model), but
---* can't intercept actions performed by mwscripts;
---* can't intercept actions performed by the AI (i.e. drinking a potion in combat);
---* can't intercept actions performed via quick keys menu.
----- Override Use action (global script).
----- Forbid equipping armor with weight > 5
---I.ItemUsage.addHandlerForType(types.Armor, function(armor, actor)
---end)
----- Call Use action (any script).
---core.sendGlobalEvent('UseItem', {object = armor, actor = player})
---@class openmw.interfaces.ItemUsage
---@field version number
local ItemUsage = {}

---Interface version
---@type number
ItemUsage.version = nil

---Add new use action handler for a specific object.
---If `handler(object, actor, options)` returns false, other handlers for
---the same object (including type handlers) will be skipped.
---@param obj openmw.GObject The object.
---@param handler fun(object: openmw.GObject, actor: openmw.GObject, options: table): any The handler.
function ItemUsage.addHandlerForObject(obj, handler) end

---Add new use action handler for a type of object.
---If `handler(object, actor, options)` returns false, other handlers for
---the same object (including type handlers) will be skipped.
---@param type any A type from the `openmw.types` package.
---@param handler fun(object: openmw.GObject, actor: openmw.GObject, options: table): any The handler.
function ItemUsage.addHandlerForType(type, handler) end

return ItemUsage
