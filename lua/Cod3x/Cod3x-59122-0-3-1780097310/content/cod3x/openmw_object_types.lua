---@meta

-- Non-runtime LuaLS capability types for OpenMW object handles.
-- These classes describe which operations are available in each script context.

---Object owner information
---@class openmw.ObjectOwner
---@field recordId string NPC who owns the object (nil if missing). Global and self scripts can set the value.
---@field factionId string Faction who owns the object (nil if missing). Global and self scripts can set the value.
---@field factionRank number Rank required to be allowed to pick up the object (`nil` if any rank is allowed). Global and self scripts can set the value.
local ObjectOwner = {}

---Either a table with options or a openmw.util.Vector3 rotation.
---@class openmw.TeleportOptions
---@field rotation openmw.util.Transform New rotation; if missing, then the current rotation is used.
---@field onGround boolean If true, adjust destination position to the ground.
local TeleportOptions = {}

---List of OpenMW objects. Implements [iterables#List](iterables.html#List) of #Object.
---@class openmw.ObjectList<T>: table<number, T>
local ObjectList = {}

---Any object that exists in the game world and has a specific location.
---Player, actors, items, and statics are game objects.
---@class openmw.Object: userdata
---@field id string The unique id of this object (not record id), can be used as a key in a table.
---@field contentFile string Lowercase file name of the content file that defines this object; nil for dynamically created objects.
---@field position openmw.util.Vector3 Object position.
---@field scale number Object scale.
---@field rotation openmw.util.Transform Object rotation.
---@field startingCell openmw.core.Cell? The object's original cell. Returns nil if `cell` of the object is nil.
---@field startingPosition openmw.util.Vector3 The object original position
---@field startingRotation openmw.util.Transform The object original rotation
---@field owner openmw.ObjectOwner Ownership information
---@field cell openmw.core.Cell? The cell where the object currently is. During loading a game and for objects in an inventory or a container `cell` is nil.
---@field parentContainer openmw.Object Container or actor that contains (or has in inventory) this object. It is nil if the object is in a cell.
---@field type any Type of the object (one of the tables from the package openmw.types.types).
---@field count number Count (>1 means a stack of objects).
---@field recordId string Returns record ID of the object in lowercase.
---@field globalVariable string Global Variable associated with this object (read only).
local Object = {}

---A read-only object handle available from local scripts for nearby objects.
---@class openmw.LObject: openmw.Object
---@field startingCell openmw.core.LCell? The object's original cell. Returns nil if `cell` of the object is nil.
---@field cell openmw.core.LCell? The cell where the object currently is. During loading a game and for objects in an inventory or a container `cell` is nil.
local LObject = {}

---A mutable object handle available from global scripts.
---@class openmw.GObject: openmw.Object
---@field startingCell openmw.core.GCell? The object's original cell. Returns nil if `cell` of the object is nil.
---@field cell openmw.core.GCell? The cell where the object currently is. During loading a game and for objects in an inventory or a container `cell` is nil.
---@field enabled boolean Whether the object is enabled or disabled. Global scripts can set the value. Items in containers or inventories can't be disabled.
local GObject = {}

---The object handle for the object a local script is attached to.
---@class openmw.SelfObject: openmw.LObject
---@field controls openmw.self.ActorControls Movement controls (only for actors)
local SelfObject = {}

---Does the object still exist and is available.
---Returns true if the object exists and loaded, and false otherwise. If false, then every
---access to the object will raise an error.
---@return boolean
function Object:isValid() end

---Send a local event to the object.
---@param eventName string
---@param eventData any
function Object:sendEvent(eventName, eventData) end

---The axis aligned bounding box in world coordinates.
---@return openmw.util.Box
function Object:getBoundingBox() end

---Activate the object.
---object:activateBy(self)
---@param actor openmw.GObject|openmw.SelfObject The actor who activates the object
function Object:activateBy(actor) end

---Add a new local script to the object.
---Can be called only from a global script. Script should be specified in a content
---file (omwgame/omwaddon/omwscripts) with a CUSTOM flag. Scripts can not be attached to Statics.
---@param scriptPath string Path to the script in OpenMW virtual filesystem.
---@param initData? table (optional) Initialization data to be passed to onInit. If missed then Lua initialization data from content files will be used (if exists for this script).
function GObject:addScript(scriptPath, initData) end

---Whether a script with given path is attached to this object.
---Can be called only from a global script.
---@param scriptPath string Path to the script in OpenMW virtual filesystem.
---@return boolean
function GObject:hasScript(scriptPath) end

---Removes script that was attached by `addScript`
---Can be called only from a global script.
---@param scriptPath string Path to the script in OpenMW virtual filesystem.
function GObject:removeScript(scriptPath) end

---Sets the object's scale.
---Can be called only from a global script.
---@param scale number Scale desired in game.
function GObject:setScale(scale) end

---Moves the object to given cell and position.
---Can be called only from a global script.
---The effect is not immediate: the position will be updated only in the next
---frame. Can be called only from a global script. Enables object if it was disabled.
---Can be used to move objects from an inventory or a container to the world.
---If the worldspace has multiple cells (i.e. an exterior), the destination cell is calculated using `position`.
---@param cellOrName any A cell to define the destination worldspace; can be either Cell, or cell name, or an empty string (empty string means the default exterior worldspace).
---@param position openmw.util.Vector3 New position.
---@param options? openmw.TeleportOptions (optional) Either table TeleportOptions or openmw.util.Transform rotation.
function GObject:teleport(cellOrName, position, options) end

---Moves an object into a container or an inventory. Enables if was disabled.
---Can be called only from a global script.
---@param dest any Inventory or Object
function GObject:moveInto(dest) end

---Removes an object or reduces a stack of objects.
---Can be called only from a global script.
---@param count? number (optional) the number of items to remove (if not specified then the whole stack)
function GObject:remove(count) end

---Splits a stack of items. Original stack is reduced by `count`. Returns a new stack with `count` items.
---Can be called only from a global script.
---money:split(50):moveInto(types.Container.content(cont))
---@param count number The number of items to return.
---@return openmw.GObject
function GObject:split(count) end

---Returns true if the script isActive (the object it is attached to is in an active cell).
---If it is not active, then `openmw.nearby` can not be used.
---@return boolean
function SelfObject.isActive() end

---Enables or disables standard AI (enabled by default).
---@param v boolean
function SelfObject.enableAI(v) end
