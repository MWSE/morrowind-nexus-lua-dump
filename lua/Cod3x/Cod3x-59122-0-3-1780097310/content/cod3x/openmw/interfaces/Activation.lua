---@meta

-- Dedicated LuaLS stub for require("openmw.interfaces").Activation.
-- Source: files/data/scripts/omw/activationhandlers.lua
-- Runtime availability depends on script context, OpenMW version, and active content files.

-- OpenMW script contexts: global

---@class openmw.interfaces.Activation
---@field version number
local Activation = {}

---Interface version
---@type number
Activation.version = nil

---Add a new activation handler for a specific object.
---If `handler(object, actor)` returns false, other handlers for
---the same object (including type handlers) will be skipped.
---@param obj openmw.GObject The object.
---@param handler fun(object: openmw.GObject, actor: openmw.GObject): any The handler.
function Activation.addHandlerForObject(obj, handler) end

---Add a new activation handler for a type of object.
---If `handler(object, actor)` returns false, other handlers for
---the same object (including type handlers) will be skipped.
---@param type any A type from the `openmw.types` package.
---@param handler fun(object: openmw.GObject, actor: openmw.GObject): any The handler.
function Activation.addHandlerForType(type, handler) end

return Activation
