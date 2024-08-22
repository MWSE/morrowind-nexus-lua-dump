local config = require("CraftingFramework.carryableContainers.config")
local util = require("CraftingFramework.util.Util")
local logger = util.createLogger("ItemFilter")

---@class CarryableContainers.ItemFilter.new.data
---@field id string The id of this filter
---@field name string The name shown in the UI
---@field description? string The description shown in the UI
---@field objectTypes? table<tes3.objectType, boolean> object types that are allowed through this filter
---@field isValidItem? fun(item: tes3item, itemData: tes3itemData?): boolean A function that returns true if the item is allowed through this filter
---@field getInvalidMessage? fun(self: CarryableContainers.ItemFilter, item: tes3item, itemData: tes3itemData?): string A function that returns a message to display if the item is not allowed through this filter

---@class CarryableContainers.ItemFilter : CarryableContainers.ItemFilter.new.data
---Defines a filter for which items are allowed in a container.
---
--- - If objectTypes is defined, then only items of those types are allowed.
---
--- - Otherwise, isValidItem is called to determine if the item is allowed.
local ItemFilter = {
    defaultInvalidMessage = "Выбранный предмет нельзя положить в этот контейнер.",
}

---Get an Item Filter by ID
---@param id string
---@return CarryableContainers.ItemFilter
function ItemFilter.getFilter(id)
    return config.registeredItemFilters[id]
end

---Register a new ItemFilter
---@param data CarryableContainers.ItemFilter.new.data
function ItemFilter.register(data)
    logger:debug("Registering new ItemFilter %s", data.id)
    local itemFilter = ItemFilter:new(data)
    --Register
    if config.registeredItemFilters[data.id] then
        logger:warn("ItemFilter %s already exists, overwriting", data.id)
    end
    config.registeredItemFilters[data.id] = itemFilter
end

---Creates and registers a new ItemFilter
---@param data CarryableContainers.ItemFilter.new.data
---@return CarryableContainers.ItemFilter
function ItemFilter:new(data)
    logger:assert(type(data) == "table", "data must be a table")
    logger:assert(type(data.name) == "string", "name must be a string")
    --must have either an objectTypes or isValidItem, check type of both
    logger:assert( type(data.objectTypes) == "table"
        or type(data.isValidItem) == "function",
        "must have either objectTypes or isValidItem")
    local itemFilter = {
        id = data.id,
        name = data.name,
        description = data.description or "",
        objectTypes = data.objectTypes,
        isValidItem = data.isValidItem,
        getInvalidMessage = data.getInvalidMessage or ItemFilter.getInvalidMessage
    }
    setmetatable(itemFilter, self)
    self.__index = self
    return itemFilter
end

--Checks if an item is allowed through this filter
---@param item tes3item
---@param itemData tes3itemData?
---@return boolean
function ItemFilter:isValid(item, itemData)
    logger:trace("Checking if item %s is valid", item.id)
    if self.objectTypes then
        logger:trace("- Checking object type %s", table.find(tes3.objectType, item.objectType))
        return self.objectTypes[item.objectType]
    elseif self.isValidItem then
        logger:trace("- Checking isValidItem callback")
        return self.isValidItem(item, itemData)
    end
    logger:trace("- No checks defined, returning true")
    return true
end


---@param item tes3item
---@param itemData? tes3itemData
---@return string
function ItemFilter:getInvalidMessage(item, itemData)
    return string.format("В этом контейнере можно хранить только %s.", self.name)
end

return ItemFilter

