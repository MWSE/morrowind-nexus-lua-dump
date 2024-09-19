--[[
CopiedObjects.lua

This class manages the tracking of copied objects.
Examples of copied objects are:
- Objects that have been enchanted
- CarryableContainers
- Dripified objects from the mod DRIP
- Any other object that has :createCopy() called on it by a mod

This class allows you to register a callback for when a copy of an object is created,
and when a copy of an object is loaded. The purpose of this class is for maintaining
links between the original object and their copies. For example, to ensure copied versions
of objects are registered with the same interops as their base version.

Usage:
Call CopiedObjects.register() to register an object ID to track copies of.
Optionally, provide a callback function to be called when a copy of the object is created,
and/or when a copy of the object is loaded.
]]

local util = require("CraftingFramework.util.Util")

---Represents any kind of tes3 object
---@alias _tes3objectAny tes3object|tes3item|tes3misc|tes3container|tes3activator|tes3door|tes3light|tes3weapon|tes3armor|tes3clothing|tes3ingredient|tes3book|tes3lockpick|tes3probe|tes3alchemy|tes3creature|tes3npc

---This callback will only be called once, when the object is copied. Use for adding the new object to persistent tables.
---@alias CopiedObjects.onCopiedCallback fun(original: _tes3objectAny, copy: _tes3objectAny)

---This callback will be called once for each copy of the object when the game is loaded. Use for adding the new object with non-persistent tables
---@alias CopiedObjects.onLoadCallback fun(original: _tes3objectAny, copy: _tes3objectAny)

---@class CopiedObjects.trackedObjectData
---@field id string The ID of the object to track copies of
---@field onCopied? CopiedObjects.onCopiedCallback This function is called when a copy of the object is created
---@field onLoad? CopiedObjects.onLoadCallback This function is called when a copy of the object is loaded

---@class CraftingFramework.CopiedObjects
local CopiedObjects = {
    trackedObjects = {},
    logger = util.createLogger("CopiedObjects")
}

---Register an object Id to track copies of
---@param e CopiedObjects.trackedObjectData
function CopiedObjects.register(e)
    CopiedObjects.trackedObjects[e.id:lower()] = e
end

---Returns the original ID of a copied object, or the original ID if it is not a copy
---@param id string The ID of the object to resolve
---@return string id The original ID of the object
---@return boolean isCopy Whether the object is a copy
function CopiedObjects.resolveId(id)
    local copies = CopiedObjects.getPersistedCopies()
    for originalId, copyIds in pairs(copies) do
        if copyIds[id:lower()] then
            return originalId, true
        end
    end
    return id, false
end

---Returns the original object of a copied object, or the object if it is not a copy
---@param object tes3object|tes3item|tes3misc
---@return tes3object|tes3item|tes3misc object The original object
---@return boolean isCopy Whether the object is a copy
function CopiedObjects.resolveObject(object)
    local id, isCopy = CopiedObjects.resolveId(object.id)
    if isCopy then
        return tes3.getObject(id), true
    end
    return object, false
end

---Returns the tracked object data for an object ID
---@param id string The ID of the object to get data for
---@return CopiedObjects.trackedObjectData
function CopiedObjects.getTrackedObjectData(id)
    return CopiedObjects.trackedObjects[id:lower()]
end

---Returns a table of copied objects, keyed by the original object's ID
---@return table<string, table<string, boolean>> A table of copied objects, keyed by the original object's ID
function CopiedObjects.getPersistedCopies()
    tes3.player.data.CraftingFramework_CopiedObjects = tes3.player.data.CraftingFramework_CopiedObjects or {}
    local data = tes3.player.data.CraftingFramework_CopiedObjects
    return data
end

---Add a copied object ID to the persisted list of copies for an original object
---@param originalId string
---@param copyId string
function CopiedObjects.persistCopy(originalId, copyId)
    local copies = CopiedObjects.getPersistedCopies()
    copies[originalId:lower()] = copies[originalId:lower()] or {}
    copies[originalId:lower()][copyId:lower()] = true
end

return CopiedObjects
