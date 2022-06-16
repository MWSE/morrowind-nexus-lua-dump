---@meta

---@class dripLootData
---@field modifiers table<DripModifierData>
---@field baseObject tes3weapon|tes3armor|tes3clothing
---@field ownerReference tes3reference The ref holding this item. Required for adding itemData to the new object

---@class dripLoot
---@field modifiers table<DripModifier>
---@field baseObject tes3weapon|tes3armor|tes3clothing #The object that this loot is cloned from
---@field object tes3weapon|tes3armor|tes3clothing #The cloned object that this loot is constructed from.
---@field ownerReference tes3reference The ref holding this item. Required for adding itemData to the new object
---@field wild boolean True when the speical "Wild" prefix has been added
Loot = {}

---@param lootData dripLootData
---@return dripLoot
function Loot:new(lootData) end

---@param modifier DripModifier
function Loot:addModifier(modifier) end

function Loot:createLootObject() end

function Loot:createLootName() end