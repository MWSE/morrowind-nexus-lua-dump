---@class jai.storage.cell
---@field name string|nil
---@field x integer|nil
---@field y integer|nil

---@class jai.storage.position
---@field x number
---@field y number
---@field z number
---@field cell jai.storage.cell

---@class jai.storage.rotation
---@field x number
---@field y number
---@field z number

---@class jai.storage.itemData
---@field id string
---@field count integer
---@field condition number|nil
---@field charge number|nil
---@field isEquipped boolean|nil

---@class jai.storage.stats
---@field health number
---@field magicka number
---@field fatigue number

---@class jai.storage.race
---@field isBeast boolean
---@field male table<string, string> id is a tes3raceBodyParts field
---@field female table<string, string> id is a tes3raceBodyParts field

---@class jai.storage.playerData
---@field objects table<string, table>
---@field count integer

---@class rotf.storage.deathMapRecord
---@field recordId integer
---@field playerId string
---@field position jai.storage.position
---@field rotation jai.storage.rotation
---@field name string
---@field race string
---@field raceData jai.storage.race
---@field isBeast boolean
---@field isFemale boolean
---@field head string
---@field hair string
---@field deathCount integer
---@field customObjects table
---@field inventory table<integer, jai.storage.itemData>
---@field equipment table<integer, integer> position of the item in the inventory table
---@field skills table<integer, integer>
---@field attributes table<integer, integer>
---@field spells table<integer, string>
---@field stats jai.storage.stats