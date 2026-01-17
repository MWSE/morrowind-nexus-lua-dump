---@class (exact) ChargenScenariosItemPickInput
---@field description? string A description of the item. Required if using multiple ids
---@field id? string The id of the item
---@field ids? string[] The ids of multiple items. If this is used instead of 'id', one will be chosen at random.
---@field count? number The number of items to add. Only useful for random pick methods. Default is 1
---@field requirements? ChargenScenariosRequirementsInput The requirements for the item
---@field noDuplicates? boolean If true, the same item will not be added if it is already in the player's inventory
---@field noSlotDuplicates? boolean If true, the same item will not be added if an item of the same type is already in the player's inventory
---@field noListDuplicates? boolean If true, the same item will not be added if any items in the itemPick ids list are already in the player's inventory
---@field pickMethod? ChargenScenarios.ItemPickMethod The method for picking an item. Default is 'random'
---@field pickOneOnly? boolean If true, when using pickMethod random and count > 1, the same item will be added multiple times
---@field data? table Additional data added to the item pick. Will only add data to one item
---@field ammo? {weaponId: string, ammoId: string, count: number}[] If a given weapon is selected, this ammo will be added to the player's inventory

---@alias ChargenScenarios.ItemPickItem tes3object|tes3misc|tes3clothing|tes3armor|tes3weapon
---@alias ChargenScenarios.ItemPickMethod
---|'random' #Pick a random item from the list
---|'bestForClass' #Pick the best item for the player's class
---|'bestForGenderRandom' #Picks random pants/skirt depending on gender
---|'bestForGenderFirst' #Picks first pants/skirt depending on gender
---|'firstValid' #Pick the first valid item. If count is > 1, the same item will be added multiple times
---|'all' #Add all valid items. If count is > 1, all items will be added multiple times

local common = require("mer.chargenScenarios.common")
local logger = common.createLogger("ItemPick")
local Requirements = require("mer.chargenScenarios.component.Requirements")
local Validator = require("mer.chargenScenarios.util.validator")
local GearManager = require("mer.chargenScenarios.component.GearManager")

---@class ChargenScenariosItemPick : ChargenScenariosItemPickInput
---@field id nil
---@field ids table<number, string> the list of item ids the item pick is chosen from
---@field resolvedItems? table<ChargenScenarios.ItemPickItem, number> the resolved items and their counts
---@field count number the number of items to add to the player's inventory
---@field requirements? ChargenScenariosRequirements the requirements for the item pick
local ItemPick = {
    schema = {
        name = "ItemPick",
        fields = {
            id = { type = "string", required = false },
            ids = { type = "table", childType = "string", required = false },
            count = { type = "number", default = 1, required = false },
            requirements = { type = Requirements.schema, required = false },
            noDuplicates = { type = "boolean", required = false },
            noSlotDuplicates = { type = "boolean", required = false },
            noListDuplicates = { type = "boolean", required = false },
            pickMethod = { type = "string", required = false },
        }
    }
}

---@type table<ChargenScenarios.ItemPickMethod, fun(items: ChargenScenarios.ItemPickItem[]): ChargenScenarios.ItemPickItem[] >
ItemPick.pickMethods = {
    random = function(items)
        local choice = table.choice(items)
        return { choice }
    end,
    bestForClass = function(items)
        local choice = GearManager.getBestItemForClass(items)
        return { choice }
    end,
    bestForGenderRandom = function(items)
        local validItems = {}
        for _, item in ipairs(items) do
            local slot = tes3.player.object.female and tes3.clothingSlot.skirt or tes3.clothingSlot.pants
            if item.slot == slot then
                table.insert(validItems, item)
            end
        end
        if #validItems == 0 then
            return {}
        end
        local choice = table.choice(validItems)
        return { choice }
    end,
    bestForGenderFirst = function(items)
        local validItems = {}
        for _, item in ipairs(items) do
            local slot = tes3.player.object.female == true
                and tes3.clothingSlot.skirt
                or tes3.clothingSlot.pants
            if item.slot == slot then
                table.insert(validItems, item)
            end
        end
        if #validItems == 0 then
            return {}
        end
        local choice = validItems[1]
        return { choice }
    end,
    firstValid = function(items)
        local choice = items[1]
        return { choice }
    end,
    all = function(items)
        return items
    end
}

--Constructor
---@param data ChargenScenariosItemPickInput
---@return ChargenScenariosItemPick?
function ItemPick:new(data)
    if not data then return nil end
    ---Validate
    Validator.validate(data, self.schema)
    assert(data.id or data.ids, "ItemPick must have either an id or ids")
    local itemPick = {
        description = data.description,
        ids = data.id and {data.id} or data.ids,
        count = data.count or 1,
        requirements = data.requirements and Requirements:new(data.requirements),
        noDuplicates = data.noDuplicates,
        noSlotDuplicates = data.noSlotDuplicates,
        noListDuplicates = data.noListDuplicates,
        pickMethod = data.pickMethod or "random",
        pickOneOnly = data.pickOneOnly,
        data = data.data,
        ammo = data.ammo
    }

    --go through ids and remove any where the object doesn't exist
    for i, id in ipairs(itemPick.ids) do
        if not tes3.getObject(id) then
            table.remove(itemPick.ids, i)
        end
    end
    if #itemPick.ids == 0 then
        return nil
    end

    ---Create ItemPick
    setmetatable(itemPick, self)
    self.__index = self
    return itemPick
end

---@return string
function ItemPick:getDescription()
    local description = self.description
    if not description then
        local item = tes3.getObject(self.ids[1])
        if item then
            description = item.name
        else
            description = "Unknown item"
        end
    end
    return description
end

--Get a lit of all valid items
---@return ChargenScenarios.ItemPickItem[]
function ItemPick:getValidItems()
    local validItems = {}
    for _, id in ipairs(self.ids) do
        local item = tes3.getObject(id)
        if item then
            table.insert(validItems, item)
        end
    end
    return validItems
end

---@return ChargenScenarios.ItemPickItem[]|nil
function ItemPick:pick()
    if not self:checkRequirements() then
        return nil
    end
    --Find which items exist
    local validItems = self:getValidItems()
    if #validItems == 0 then
        logger:debug("No valid items found")
        return nil
    end
    --Pick an item
    if not self.ids then return nil end
    local pickedItems = self.pickMethods[self.pickMethod](validItems)
    return pickedItems
end



---@param item ChargenScenarios.ItemPickItem
local function isEquippableType(item)
    return item.objectType == tes3.objectType.armor
        or item.objectType == tes3.objectType.clothing
        or item.objectType == tes3.objectType.weapon
end

---Check if the player has an item of the same type and slot/weapontype
---@param item ChargenScenarios.ItemPickItem
local function playerHasSameItemType(item)
    if not isEquippableType(item) then return false end
    for _, stack in pairs(tes3.player.object.inventory) do
        if stack.object.objectType == item.objectType then
            if item.objectType == tes3.objectType.armor or item.objectType == tes3.objectType.clothing then
                if stack.object.slot == item.slot then
                    return true
                end
                --Gauntlets and bracers have same slot
                if item.objectType == tes3.objectType.armor then
                    if item.slot == tes3.armorSlot.leftGauntlet then
                        if stack.object.slot == tes3.armorSlot.leftBracer then
                            return true
                        end
                    elseif item.slot == tes3.armorSlot.leftBracer then
                        if stack.object.slot == tes3.armorSlot.leftGauntlet then
                            return true
                        end
                    elseif item.slot == tes3.armorSlot.rightGauntlet then
                        if stack.object.slot == tes3.armorSlot.rightBracer then
                            return true
                        end
                    elseif item.slot == tes3.armorSlot.rightBracer then
                        if stack.object.slot == tes3.armorSlot.rightGauntlet then
                            return true
                        end
                    end
                end
            elseif item.objectType == tes3.objectType.weapon then
                if stack.object.type == item.type then
                    return true
                end
            end
        end
    end
    return false
end

function ItemPick:playerHasListDuplicate()
    for _, id in ipairs(self.ids) do
        if tes3.player.object.inventory:contains(id) then
            logger:debug("Player already has item from list, skipping")
            return true
        end
    end
    return false
end

---Add the item to the player's inventory if it passes the skip flag checks
---@param item ChargenScenarios.ItemPickItem
---@param count number
function ItemPick:checkAndGiveItem(item, count)
    logger:debug("Checking item: %s. Flags:%s%s%s", item,
        self.noDuplicates and " noDuplicates" or "",
        self.noSlotDuplicates and " noSlotDuplicates" or "",
        self.noListDuplicates and " noListDuplicates" or ""
    )


    if self.noDuplicates and tes3.player.object.inventory:contains(item) then
        logger:debug("Player already has item, skipping %s", item)
        return
    end

    if self.noSlotDuplicates and playerHasSameItemType(item) then
        logger:debug("Player already has item of same type, skipping %s", item)
        return
    end

    if tes3.player.object.race.isBeast and item.isUsableByBeasts == false then
        logger:debug("Beast cannot use %s, adding gold value instead", item)
        tes3.addItem{
            reference = tes3.player,
            item = "gold_001",
            count = item.value,
            playSound = false,
        }
    else
        logger:debug("Adding item to player inventory: %s", item)
        tes3.addItem{
            reference = tes3.player,
            item = item,
            count = count,
            playSound = false,
        }
        if self.data then
            local itemData = tes3.addItemData{
                to = tes3.player,
                item = item,

            }
            for k, v in pairs(self.data) do
                itemData.data[k] = v
            end
        end
        if self.ammo then
            for _, ammoData in ipairs(self.ammo) do
                if ammoData.weaponId:lower() == item.id:lower() then
                    logger:debug("Adding ammo to player inventory: %s", ammoData.ammoId)
                    tes3.addItem{
                        reference = tes3.player,
                        item = ammoData.ammoId,
                        count = ammoData.count,
                        playSound = false,
                    }
                end
            end
        end
    end
end

function ItemPick:giveToPlayer()
    self:resolveItems()
    if self.noListDuplicates then
        logger:debug("Checking for list duplicates")
        --log all ids
        logger:debug("ItemPick ids: %s", table.concat(self.ids, ", "))
        if self:playerHasListDuplicate() then
            logger:debug("Player already has item from list, skipping")
            return
        end
    end
    for item, count in pairs(self.resolvedItems) do
        self:checkAndGiveItem(item, count)
    end
end

---Reset the resolved items
function ItemPick:reset()
    self.resolvedItems = nil
end

---Resolves the ids into items. Call before using self.resolvedItems
function ItemPick:resolveItems()
    if self.resolvedItems then
        return self.resolvedItems
    end
    self.resolvedItems = {}
    local added = 0
    --If there's only one item in the list, then add them all at once
    --If there's multiple items, pick and add one at a time
    local hasMultipleItems = #self.ids > 1 and not self.pickOneOnly
    local numAddedPerLoop = hasMultipleItems and 1 or self.count
    while added < (self.count or 1) do
        local pickedItems = self:pick()
        if pickedItems == nil or #pickedItems == 0 then
            logger:debug("No valid items to pick from")
            break
        end
        for _, pickedItem in ipairs(pickedItems) do
            logger:debug("Picked item: %s", pickedItem)
            self.resolvedItems[pickedItem] = self.resolvedItems[pickedItem]
                and (self.resolvedItems[pickedItem] + numAddedPerLoop)
                or numAddedPerLoop
            added = added + numAddedPerLoop
        end
    end
end


function ItemPick:checkRequirements()
    if self.requirements and not self.requirements:check() then
        return false
    end
    return true
end

return ItemPick