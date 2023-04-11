--[[
Represents an individual object and it's associated data,
regardless of whether it exists as a reference or an object
inside an inventory.
]]
---@class ItemInstance
---@field item tes3item
---@field dataHolder tes3itemData|table
---@field reference tes3reference?
---@field data table
---@field logger mwseLogger
---@field _dataKey string
local ItemInstance = {}

---@class ItemInstance.new.params
---@field dataKey string The key where custom data is stored on reference.data
---@field reference tes3reference?
---@field item tes3item|tes3object?
---@field itemData tes3itemData?
---@field owner tes3reference?
---@field logger mwseLogger?

---@param e ItemInstance.new.params?
---@return ItemInstance
function ItemInstance:new(e)
    local itemInstance = {}
    setmetatable(itemInstance, self)
    self.__index = self
    if not e then return itemInstance end

    itemInstance.reference = e.reference
    itemInstance.item = e.item or e.reference.baseObject --[[@as tes3item]]
    itemInstance.dataHolder = e.itemData or e.reference --[[@as table]]
    itemInstance.id = itemInstance.item.id:lower()
    itemInstance.logger = e.logger or require("logging.logger").new{
        name = "ItemInstance",
        level = "debug",
    }
    -- reference data
    itemInstance._dataKey = e.dataKey
    itemInstance.logger:assert(type(itemInstance._dataKey) == "string", "dataKey string must be present")
    itemInstance.data = setmetatable({}, {
        __index = function(_, k)
            return itemInstance.dataHolder
                and itemInstance.dataHolder.data
                and itemInstance.dataHolder.data[itemInstance._dataKey]
                and itemInstance.dataHolder.data[itemInstance._dataKey][k]
        end,
        __newindex = function(_, k, v)
            if itemInstance.dataHolder == nil then
                itemInstance.logger:debug("Setting value %s and dataHolder doesn't exist yet", k)
                if not itemInstance.reference then
                    itemInstance.logger:debug("itemInstance.item: %s", itemInstance.item)
                    --create itemData
                    itemInstance.dataHolder = tes3.addItemData{
                        to = tes3.player,
                        item = itemInstance.item.id,
                    }
                    if itemInstance.dataHolder == nil then
                        itemInstance.logger:error("Failed to create itemData")
                        return
                    end
                end
            end
            if not ( itemInstance.dataHolder.data and itemInstance.dataHolder.data[itemInstance._dataKey]) then
                itemInstance.dataHolder.data[itemInstance._dataKey] = {}
            end
            itemInstance.dataHolder.data[itemInstance._dataKey][k] = v
        end
    })
    return itemInstance
end

---Makes a safe reference so that this instance can be retreived later
--- if the reference still exists
function ItemInstance:setSafeInstance()
    if self.reference then
        self.safeRef = tes3.makeSafeObjectHandle(self.reference)
    end
end

---Gets a previously saved safe version of this instance
function ItemInstance:getSafeInstance()
    if self.safeRef and self.safeRef:valid() then
        self.reference = self.safeRef:getObject()
        self.safeRef = nil
        return self
    end
end

return ItemInstance