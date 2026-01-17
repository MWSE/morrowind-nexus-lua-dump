---@class tes3travelDestinationNode
---@field cell tes3cell?
---@field cellData tes3cellData
---@field marker {position : tes3vector3, rotation : tes3vector3}

---@class tes3cell
---@field name string
---@field displayName string?
---@field region string
---@field id string
---@field gridX integer
---@field gridY integer
---@field isExterior boolean
---@field getAll function
---@field hasTag function

---@class tes3cellData
---@field id string?
---@field name string?
---@field gridX integer?
---@field gridY integer?
---@field isExterior boolean

---@alias tes3reference any