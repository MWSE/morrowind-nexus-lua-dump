local common = require("mer.chargenScenarios.common")
local logger = common.createLogger("ItemList")
local ItemPick = require("mer.chargenScenarios.component.ItemPick")
local Validator = require("mer.chargenScenarios.util.validator")

---@class ChargenScenarios.ItemListInput
---@field name string
---@field description? string A description of the Item List
---@field items ChargenScenariosItemPickInput[]
---@field active? boolean (Default: false)
---@field priority? number (Default: 0)

---@class ChargenScenarios.ItemList : ChargenScenarios.ItemListInput
---@field name string @the name of the item list
---@field active boolean @whether the item list is active
---@field defaultActive boolean @whether the item list is active by default
---@field items ChargenScenariosItemPick @the list of items to add to the player's inventory
local ItemList = {
    schema = {
        name = "ItemList",
        fields = {
            name = { type = "string", required = true },
            items = { type = "table", childType = ItemPick.schema, required = true },
        }
    },
}

--Constructor
---@param e ChargenScenarios.ItemListInput
---@return ChargenScenarios.ItemList
function ItemList:new(e)
    local itemList = table.copy(e)
    ---validate
    Validator.validate(itemList, self.schema)
    itemList.active = not not itemList.active
    itemList.defaultActive = itemList.active
    itemList.priority = itemList.priority or 0
    itemList.items = common.convertListTypes(itemList.items, ItemPick)

    setmetatable(itemList, self)
    self.__index = self
    return itemList
end

function ItemList:doItems()
    if not self.active then
        logger:debug("ItemList %s is not active", self.name)
        return false
    end
    if self.items and table.size(self.items) > 0 then
        mwse.log("Doing items")
        ---@param itemPick ChargenScenariosItemPick
        for _, itemPick in ipairs(self.items) do
            if itemPick:checkRequirements() then
                itemPick:giveToPlayer()
            end
        end
        return true
    else
        return false
    end
end

function ItemList:getDescriptionList()
    local descriptions = {}

    --Sort by description
    table.sort(self.items,
    ---@param a ChargenScenariosItemPick
    ---@param b ChargenScenariosItemPick
    function(a,b)
        return a:getDescription() < b:getDescription()
    end)

    for _, itemPick in ipairs(self.items) do
        local description = string.format("%d x %s", itemPick.count, itemPick:getDescription())
        table.insert(descriptions, description)
    end
    return descriptions
end

function ItemList:getDescription()
    local descriptions = self:getDescriptionList()
    return table.concat(descriptions, "\n")
end

return ItemList
