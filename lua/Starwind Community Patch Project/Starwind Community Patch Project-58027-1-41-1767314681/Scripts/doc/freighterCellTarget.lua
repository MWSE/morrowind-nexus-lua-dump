---@class TeleportTarget
---@field pos util.vector3 position to teleport to
---@field rot number Z rotation in degrees to teleport to

---@class FreighterCellTarget
---@field planetActivator string RecordId of the activator which triggers travel to a given planet
---@field teleportTo TeleportTarget teleport target data

---@alias FreighterCellID string

---@type table<FreighterCellID, FreighterCellTarget>