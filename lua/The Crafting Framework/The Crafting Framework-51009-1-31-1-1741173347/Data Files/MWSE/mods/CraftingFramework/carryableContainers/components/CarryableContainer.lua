--[[
CarryableContainer.lua

This class represents a carryable container, which is a misc item that, when activated,
will open its associated container reference.

Usage:
Call CarryableContainer.register() to register a new carryable container.
See the CarryableContainer.containerConfig annotation for details on the config options.
]]

local config = require("CraftingFramework.carryableContainers.config")
local util = require("CraftingFramework.util.Util")
local logger = util.createLogger("CarryableContainer")
local ItemInstance = require("CraftingFramework.carryableContainers.components.ItemInstance")
local ItemFilter = require("CraftingFramework.carryableContainers.components.ItemFilter")
local Container = require("CraftingFramework.carryableContainers.components.Container")
local RefStack = require("CraftingFramework.util.RefStack")
local CopiedObjects = require("CraftingFramework.copiedObjects")

local MAX_CAPACITY = 65535

---Overrride function when activating from inventory
---@alias CarryableContainer.openFromInventory fun(self:CarryableContainer)
---Callback function when a copy of this container is created
---@alias CarryableContainer.onCopyCreatedData { copy: tes3misc, original: tes3misc }
---Container Config
---@class CarryableContainer.containerConfig
---@field itemId string The id of the item to use for the container
---@field filter CarryableContainers.DefaultItemFilter|string|nil The id of the filter to use for the container
---@field capacity number The capacity of the container
---@field hasCollision boolean? If set to true, the in-world reference will be an actual container, rather than the placed misc item. This will give it collision, but also means it can't be as easily moved
---@field weightModifier number? The weight of the contents of this container will be multiplied by this value.
---@field scale number? The scale of the placed container
---@field openFromInventory? fun(self:CarryableContainer)
---@field onCopyCreated? fun(self:CarryableContainer, data:CarryableContainer.onCopyCreatedData)
---@field getWeightModifier? fun(self:CarryableContainer):number Override function to get the weight modifier for this container
---@field getWeightModifierText? fun(self:CarryableContainer):string Override function to get the weight modifier text for this container
---@field getTooltip? fun(self:CarryableContainer):string An optional callback to add an additional tooltip to the container
---@field blockWorldActivate? boolean If set, the container will not be opened when activated in the world.
---@field allowUnfiltered? boolean If set, the filter button will be shown, but otherwise any item can be added to the container

---@class CarryableContainer.new.params : ItemInstance.new.params
---@field containerRef? tes3reference? If provided, the item will be created from the container reference

---A carrayable container is a misc item that, when activated
--- or equipped, will open its associated container reference
---@class CarryableContainer : ItemInstance
---@field reference tes3reference The reference of the carryable item
---@field item tes3misc
---@field containerConfig CarryableContainer.containerConfig
---@field data table
---@field filter CarryableContainers.ItemFilter|nil
local CarryableContainer = ItemInstance:new()


---Register a carryable container
---@param data CarryableContainer.containerConfig
function CarryableContainer.register(data)
    assert(data.itemId, "No itemId provided for carryable container")
    data.capacity = data.capacity or MAX_CAPACITY
    logger:debug("Registering new CarryableContainer %s", data.itemId)
    local id = data.itemId:lower()
    --Register
    if config.registeredContainers[id] then
        logger:warn("CarryableContainer %s already exists, overwriting", id)
    end
    config.registeredContainers[id] = data
    CopiedObjects.register{
        id = id,
        onCopied = CarryableContainer.onCopied,
        onLoad = CarryableContainer.onLoad,
    }
end

---@type CopiedObjects.onCopiedCallback
function CarryableContainer.onCopied(original, copy)
    local containerConfig = original and CarryableContainer.getContainerConfig(original)
    if containerConfig then
        logger:info("Registering copied carryable container. Original: %s, New: %s",
            original, copy)
        ---@type CarryableContainer.containerConfig
        local newConfig = table.copy(containerConfig)
        newConfig.itemId = copy.id
        CarryableContainer.register(newConfig)
        --Remap the misc copy to the new container
        local containerId = config.persistent.miscCopyToContainerMapping[original.id:lower()]
        if containerId then

            local containerObject = tes3.getObject(containerId)
            if containerObject then
                containerObject.name = copy.name
            end
            local newItemId = copy.id:lower()
            CarryableContainer.mapItemToContainer(newItemId, containerId)
        end
        if containerConfig.onCopyCreated then
            containerConfig.onCopyCreated(CarryableContainer, {copy = copy, original = original})
        end
    end
end

function CarryableContainer.onLoad(original, copy)
    logger:info("Registering copied carryable container. Original: %s, New: %s",
    original, copy)
    local containerConfig = CarryableContainer.getContainerConfig(original)
    if containerConfig then
        ---@type CarryableContainer.containerConfig
        local newConfig = table.copy(containerConfig)
        newConfig.itemId = copy.id
        CarryableContainer.register(newConfig)
    end
end

---@param item tes3item|tes3misc|tes3object The carryable object to get the container config for
---@return CarryableContainer.containerConfig|nil
function CarryableContainer.getContainerConfig(item)
    return CarryableContainer.getContainerConfigById(item.id)
end


---@param id string
---@return CarryableContainer.containerConfig|nil
function CarryableContainer.getContainerConfigById(id)
    local id = id:lower()
    if config.persistent.miscCopyToBaseMapping[id] then
        --if this is a copy of a container, get the base container config
        id = config.persistent.miscCopyToBaseMapping[id]
    end
    local containerConfig = config.registeredContainers[id]
    if containerConfig then
        return containerConfig
    end
end

---@return CarryableContainer|nil
function CarryableContainer.getCarryableFromReference(reference)
    if reference.baseObject.objectType == tes3.objectType.container then
        return CarryableContainer:new{
            containerRef = reference
        }
    else
        return CarryableContainer:new{
            item = reference.baseObject
        }
    end
end

---@param reference? tes3reference
---@return CarryableContainer[]
function CarryableContainer.getCarryableContainersInInventory(reference)
    local carriedContainers = {}
    reference = reference or tes3.player
    for _, stack in pairs(reference.object.inventory) do
        local carryable = CarryableContainer:new{ item = stack.object }
        if carryable then
            table.insert(carriedContainers, carryable)
            --Get containers inside this container
            if carryable:getContainerRef() then
                local innerCarryables = CarryableContainer.getCarryableContainersInInventory(carryable:getContainerRef())
                for _, innerCarryable in pairs(innerCarryables) do
                    table.insert(carriedContainers, innerCarryable)
                end
            end
        end
    end
    return carriedContainers
end

---@class CarryableContainer.getItemCount.params : tes3.getItemCount.params
---@field itemData? tes3itemData
---@field reference tes3reference? Default: tes3.player


---Gets the full list of items in the reference's inventory, including items in containers
---@param reference? tes3reference Default: tes3.player
---@return tes3itemStack[] #The list of items
---@deprecated Use getInventory to get the ownerRef of each stack
function CarryableContainer.getFullInventory(reference, checkedContainers)
    ---Cache each container we've already checked to prevent infinite recursion
    checkedContainers = checkedContainers or {}
    --- all items in inventory and in containers
    ---@type tes3itemStack[]
    local inventory = {}
    local containers = {}
    reference = reference or tes3.player
    for _, stack in pairs(reference.object.inventory) do
        table.insert(inventory, stack)
        local carryable = CarryableContainer:new{ item = stack.object }
        if carryable then
            table.insert(containers, carryable)
        end
    end
    for _, carryable in pairs(containers) do
        local containerRef = carryable:getContainerRef()
        if containerRef and not checkedContainers[containerRef] then
            checkedContainers[containerRef] = true
            ---@diagnostic disable-next-line: deprecated
            local containerInventory = CarryableContainer.getFullInventory(containerRef, checkedContainers)
            for _, stack in pairs(containerInventory) do
                table.insert(inventory, stack)
            end
        end
    end
    return inventory
end

---@class CarryableContainer.getInventory.result
---@field stack tes3itemStack
---@field ownerRef tes3reference

---Gets the full list of item stacks in the reference's inventory, including items in containers
---Returns a list of stacks along with the ownerRef of each stack
---@param reference? tes3reference Default: tes3.player
---@return CarryableContainer.getInventory.result[] #The list of items
function CarryableContainer.getInventory(reference, checkedContainers)
    ---Cache each container we've already checked to prevent infinite recursion
    checkedContainers = checkedContainers or {}
    --- all items in inventory and in containers
    ---@type CarryableContainer.getInventory.result[]
    local inventory = {}
    local containers = {}
    reference = reference or tes3.player
    for _, stack in pairs(reference.object.inventory) do
        table.insert(inventory, { stack = stack, ownerRef = reference })
        local carryable = CarryableContainer:new{ item = stack.object }
        if carryable then
            table.insert(containers, carryable)
        end
    end
    for _, carryable in pairs(containers) do
        local containerRef = carryable:getContainerRef()
        if containerRef and not checkedContainers[containerRef] then
            checkedContainers[containerRef] = true
            local containerInventory = CarryableContainer.getInventory(containerRef, checkedContainers)
            for _, stack in pairs(containerInventory) do
                table.insert(inventory, { stack = stack.stack, ownerRef = containerRef })
            end
        end
    end
    return inventory
end

---Gets the number of items in the reference's inventory,
--- recursing through any containers
---@param e CarryableContainer.getItemCount.params
---@return number The number of items in the reference's inventory
function CarryableContainer.getItemCount(e)
    e.reference = e.reference or tes3.player
    ---@type tes3item
    local item
    if type(e.item) == "string" then
        item = tes3.getObject(e.item--[[@as string]])
    else
        item = e.item
    end
    if not item then
        --getObject failed
        return 0
    end
    local count = 0
    for _, result in pairs(CarryableContainer.getInventory(e.reference)) do
        if result.stack.object == item then
            count = count + result.stack.count
        end
    end
    return count
end


---Find and return an item stack in the reference's inventory,
---@param e { item: string|tes3item, itemData?: tes3itemData, reference: tes3reference? }
---@return tes3itemStack|nil stack, tes3reference|nil ownerRef
function CarryableContainer.findItemStack(e)
    e.reference = e.reference or tes3.player
    ---@type tes3item
    local item
    if type(e.item) == "string" then
        item = tes3.getObject(e.item--[[@as string]])
    else
        item = e.item
    end
    if not item then
        --getObject failed
        return
    end
    for _, result in pairs(CarryableContainer.getInventory(e.reference)) do
        local stack = result.stack
        local ownerRef = result.ownerRef
        if stack.object == item then
            if not e.itemData then
                return stack, ownerRef
            end
            if not stack.variables then return end
            for _, itemData in pairs(stack.variables) do
                if itemData == e.itemData then
                    return stack, ownerRef
                end
            end
        end
    end
end




---@class CarryableContainer.removeItem.params : tes3.removeItem.params
---@field reference tes3reference

---Removes an item from the reference's inventory,
--- recursing through any containers
---@param e CarryableContainer.removeItem.params
---@returns number #The number of items removed
function CarryableContainer.removeItem(e)
    ---@type tes3item
    local item
    if type(e.item) == "string" then
        item = tes3.getObject(e.item--[[@as string]])
    else
        item = e.item
    end
    if not item then
        --getObject failed
        return 0
    end

    local reference = e.reference or tes3.player
    local count = e.count or 1
    local removed = tes3.removeItem(e)
    local remaining = count - removed
    if remaining > 0 then
        for _, stack in pairs(reference.object.inventory) do
            local carryable = CarryableContainer:new{ item = stack.object }
            if carryable then
                local containerRef = carryable:getContainerRef()
                if containerRef then
                    ---@type CarryableContainer.removeItem.params
                    local params = table.copy(e)
                    params.reference = containerRef
                    params.count = remaining
                    local removed =  CarryableContainer.removeItem(params)
                    remaining = remaining - removed
                    if remaining <= 0 then
                        break
                    end
                end
            end
        end
    end
    return count - remaining
end

---@param e tes3.transferItem.params
function CarryableContainer.transferItem(e, skipInventoryUpdate)
    ---For each inventory, check item count to see if it's in that container, then do tes3.transferItem
    local count = e.count or 1
    local transferred = tes3.transferItem(e)
    local remaining = count - transferred
    if remaining > 0 then
        for _, stack in pairs(e.from.object.inventory) do
            local carryable = CarryableContainer:new{ item = stack.object }
            if carryable then
                local containerRef = carryable:getContainerRef()
                if containerRef then
                    ---@type tes3.transferItem.params
                    local params = table.copy(e)
                    params.from = containerRef
                    params.count = remaining
                    local transferred =  CarryableContainer.transferItem(params, true)
                    remaining = remaining - transferred
                    if remaining <= 0 then
                        break
                    end
                end
            end
        end
    end
    return transferred
end

---Checks whether a container reference is a carryable container
function CarryableContainer.isCarryableContainer(containerRef)
    return config.persistent.containerToMiscCopyMapping[containerRef.baseObject.id:lower()] ~= nil
end

---Get the carryable container instance from an item
---@param item tes3item
function CarryableContainer.getFromItem(item)
    if item then
        return CarryableContainer:new{ item = item }
    end
end

---Construct an instance of a carryable container
---@param e CarryableContainer.new.params
---@return CarryableContainer|nil
function CarryableContainer:new(e)
    --if passed a container reference, get the misc ref for it
    if e.containerRef then
        local miscId = Container.getMiscIdfromReference(e.containerRef)
        if miscId then
            logger:trace("Craryable misc from container ref")
            local item = tes3.getObject(miscId)
            if item then
                e.item = item --[[@as tes3misc]]
                e.itemData = nil
                e.reference = nil
            end
        else
            return nil
        end
    end
    assert(e.item or e.reference, "No item or reference provided to create a carryable container")

    local containerConfig = CarryableContainer.getContainerConfig(e.item or e.reference.object)
    if not containerConfig then
        return nil
    end

    local carryableMisc = ItemInstance:new{
        item = e.item,
        itemData = e.itemData,
        reference = e.reference,
        dataKey = "carryableMisc",
        logger = logger,
    }
    setmetatable(carryableMisc, self)
    ---@cast carryableMisc CarryableContainer
    carryableMisc.containerConfig = containerConfig
    self.__index = function(t, k)
        --use tes3.getReference(self.item.id) to get the container ref
        if k == "reference" then
            return tes3.getReference(t.item.id)
        end
        return CarryableContainer[k]
    end

    if containerConfig.filter then
        carryableMisc.filter = config.registeredItemFilters[containerConfig.filter]
    end

    return carryableMisc
end

---@return CarryableContainers.ItemFilter|nil
function CarryableContainer:getFilter()
    local filterId = self.containerConfig.filter
    if filterId then
        local filter = ItemFilter.getFilter(filterId)
        if not filter then
            logger:warn("%s has filter %s, but this has not been registered",
                self.item.id, filterId)
        end
        return filter
    end
end

function CarryableContainer:getContainerId()
    return config.persistent.miscCopyToContainerMapping[self.item.id:lower()]
end

function CarryableContainer:openFromInventory()
    local barterMenu = tes3ui.findMenu("MenuBarter")
    local inBarterMenu = barterMenu and barterMenu.visible
    if inBarterMenu then
        logger:warn("Can't open containers while bartering")
        return
    end

    local icon = tes3ui.findHelpLayerMenu("CursorIcon")
    local tile = icon and icon:getPropertyObject("MenuInventory_Thing", "tes3inventoryTile")
    if tile then
        logger:warn("Can't open containers when holding something")
        return
    end

    self:replaceInInventory()
    logger:debug("Opening container from inventory %s", (self:getContainerId() or tes3.player))
    local containerRef = self:getCreateContainerRef()

    local oldBlock = self.containerConfig.blockWorldActivate
    self.containerConfig.blockWorldActivate = false
    tes3.player:activate(containerRef)
    timer.delayOneFrame(function()
        logger:debug("openFromInventory - Restoring block world activate")
        self.containerConfig.blockWorldActivate = oldBlock
        self:updateStats()
    end)
end

function CarryableContainer:openFromWorld()
    self:replaceInWorld()
    logger:debug("Opening container from world %s", self:getContainerId())
    local containerRef = self:getCreateContainerRef()

    local oldBlock = self.containerConfig.blockWorldActivate
    self.containerConfig.blockWorldActivate = false
    tes3.player:activate(containerRef)
    timer.delayOneFrame(function()
        logger:debug("openFromWorld - Restoring block world activate")
        self.containerConfig.blockWorldActivate = oldBlock
    end)
end

---Open the container
function CarryableContainer:open()
    self.logger:debug("open")

    --if ref, open from world, otherwise open from inventory
    if self.reference then
        logger:debug("Has reference, opening from world")
        self:openFromWorld()
    else
        if self.containerConfig.openFromInventory then
            logger:debug("No ref, Opening from inventory with custom function")
            self.containerConfig.openFromInventory(self)
        else
            logger:debug("No ref, Opening from inventory")
            self:openFromInventory()
        end
    end
end

function CarryableContainer.recalculateEncumbrance()
    local burden = tes3.getEffectMagnitude{reference = tes3.mobilePlayer, effect = tes3.effect.burden}
    local feather = tes3.getEffectMagnitude{reference = tes3.mobilePlayer, effect = tes3.effect.feather}
    local weight = tes3.player.object.inventory:calculateWeight() + burden - feather
    local oldWeight = tes3.mobilePlayer.encumbrance.currentRaw

    if (math.abs(oldWeight - weight) > 0.01) then
        logger:debug(string.format("Recalculating current encumbrance %.2f => %.2f", oldWeight, weight))
        tes3.setStatistic{reference = tes3.mobilePlayer, name = "encumbrance", current = weight}
    end
end

---@param e { includeWeightModifier: boolean? }?
function CarryableContainer:calculateWeight(e)
    e = e or { includeWeightModifier = false}
    e.includeWeightModifier = e.includeWeightModifier or false
    local container = self:getCreateContainerRef()
    local weightModifier = e.includeWeightModifier and self:getWeightModifier() or 1.0
    return container.object.inventory:calculateWeight()
        * weightModifier
end

function CarryableContainer:updateStats()
    local containerRef = self:getCreateContainerRef()
    logger:debug("Updating weight of %s", self.item.id)
    local weightModifier = self:getWeightModifier() or 1.0
    logger:debug(" - Weight modifier is %s", weightModifier)
    --add up the weight off all items in the container ref and set it to this item's base weight plus the total
    local totalWeight = self:getBaseWeight()
    local totalValue = self:getBaseValue()
    ---@param stack tes3itemStack
    for _, stack in pairs(containerRef.object.inventory) do
        totalWeight = totalWeight + (stack.object.weight * stack.count * weightModifier)
        local value = stack.object.value
        local count = stack.count or 1
        logger:trace(" - Item %s has value %s", stack.object.id, value)
        logger:trace(" - Item %s has count %s", stack.object.id, count)
        --if has variables, iterate through and multiply value by condition
        if stack.variables then
            ---@param itemData tes3itemData
            for _, itemData in pairs(stack.variables) do
                totalValue = totalValue + tes3.getValue{ item = stack.object, itemData = itemData}
                count = count - 1
            end
        end
        totalValue = totalValue + (value * count)
        logger:trace(" - Total value of %s is %s", self.item.id, totalValue)
    end
    logger:debug(" - Total weight of %s is %s", self.item.id, totalWeight)
    self.item.weight = totalWeight
    self.item.value = math.floor(totalValue)

    CarryableContainer.recalculateEncumbrance()
end

function CarryableContainer:isCopy()
    return config.persistent.miscCopyToBaseMapping[self.item.id:lower()] ~= nil
end

---@return tes3misc
function CarryableContainer:createCopy()
    logger:debug("Creating copy of %s", self.item.id)
    local copy = self.item:createCopy{}
    logger:trace("Created copy %s", copy.id)
    config.persistent.miscCopyToBaseMapping[copy.id:lower()] = self.item.id:lower()
    event.trigger("CraftingFramework:CarryableContainer_CopyCreated", {copy = copy, original = self.item})
    return copy
end

function CarryableContainer:getBaseId()
    return config.persistent.miscCopyToBaseMapping[self.item.id:lower()]
        or self.item.id
end

function CarryableContainer:getBaseObject()
    return tes3.getObject(self:getBaseId())
end

function CarryableContainer:getBaseWeight()
    local baseObject = self:getBaseObject()
    if not baseObject then
        logger:error("Could not find base object for %s", self.item.id)
        return 0
    end
    return baseObject.weight
end

function CarryableContainer:getBaseValue()
    local baseObject = self:getBaseObject()
    if not baseObject then
        logger:error("Could not find base object for %s", self.item.id)
        return 0
    end
    return baseObject.value
end

function CarryableContainer:getName()
    return self.item.name
end

--Get the weight modifier for this container
function CarryableContainer:getWeightModifier()
    if self.containerConfig.getWeightModifier then
        return self.containerConfig.getWeightModifier(self)
    else
        return self.containerConfig.weightModifier
    end
end

function CarryableContainer:replaceInWorld()
    logger:assert(self.reference ~= nil, "Trying to replace in world for item %s", self.item.id)
    logger:debug("Replacing container in world %s", self.item.id)

    local refStack = RefStack:new{
        reference = self.reference,
        logger = util.createLogger("CarryableContainer.RefStack")
    }
    if refStack then
        logger:debug("Returning excess items")
        refStack:returnExcess()
    end

    if not self:isCopy() then
        --Creating new misc copy
        local copy = self:createCopy()
        local newMisc = tes3.createReference{
            object = copy,
            position = self.reference.position,
            orientation = self.reference.orientation,
            cell = self.reference.cell,
            scale = self.containerConfig.scale or 1.0
        }
        logger:debug("Created new misc %s", newMisc.object.id)
        --copy data
        for k, v in pairs(self.data) do
            newMisc.data.carryableMisc[k] = v
        end
        --remove old reference
        self.reference:delete()
        --update self with new reference
        self.item = newMisc.object --[[@as tes3misc]]
        self.reference = newMisc
        self.dataHolder = newMisc
    else
        logger:debug("Item %s is already a copy", self.item.id)

    end

    if self.containerConfig.hasCollision then
        logger:debug("Large item, moving container to misc position")
        --place container where misc ref is
        self:setSafeInstance()
        timer.frame.delayOneFrame(function()
            self = self:getSafeInstance() --[[@as CarryableContainer]]
            if not self then
                logger:error("Could not get safe instance for %s", self.item.id)
                return
            end

            local containerRef = self:getCreateContainerRef()

            logger:debug("Moving containerRef %s to position %.f, %.f, %.f",
                containerRef.object.id,
                self.reference.position.x,
                self.reference.position.y,
                self.reference.position.z)

            local newPosition = self.reference.position:copy()
            Container.positionCell{
                reference = containerRef,
                position = newPosition,
                orientation = self.reference.orientation:copy(),
                cell = self.reference.cell,
                forceCellChange = true
            }
            Container.unhide(containerRef)
            containerRef:updateLighting()
            if containerRef.sceneNode then
                containerRef.sceneNode.appCulled = false
                containerRef.sceneNode:updateProperties()
                containerRef.sceneNode:updateEffects()
            else
                logger:error("No scene node for %s", containerRef.object.id)
            end

            Container.hide(self.reference)
            tes3.dataHandler:updateCollisionGroupsForActiveCells{}
        end)
    else
        self.reference.scale = self.containerConfig.scale or self.reference.scale
        self:setSafeInstance()
        timer.frame.delayOneFrame(function()
            self = self:getSafeInstance() --[[@as CarryableContainer]]
            if not self then
                logger:error("Could not get safe instance for %s", self.item.id)
                return
            end
            --move container to misc position
            local containerRef = self:getCreateContainerRef()
            if containerRef then
                logger:debug("Moving container %s to misc position", containerRef.object.name)
                Container.positionCell{
                    reference = containerRef,
                    position = self.reference.position,
                    orientation = self.reference.orientation,
                    cell = self.reference.cell,
                    forceCellChange = true
                }
                Container.hide(containerRef)
            end
        end)
    end

    return self
end

function CarryableContainer:replaceInInventory()
    if self:isCopy() then
        logger:debug("This is a copy, not replacing")
        return self
    end
    if self.reference then
        logger:error("Trying to replace in inventory for reference %s", self.reference.id)
        return
    end
    logger:debug("Replacing container in inventory %s", self.item.id)
    local reference = tes3.player
    --get contents Menu
    local contentsMenu = tes3ui.findMenu(tes3ui.registerID("MenuContents"))
    if contentsMenu and contentsMenu.visible then
        local contentsMenuOwnerRef = contentsMenu:getPropertyObject("MenuContents_ObjectRefr")
        local containerInContents = contentsMenuOwnerRef
            and contentsMenuOwnerRef.object.inventory:contains(self.item)
        if containerInContents then
            reference = contentsMenuOwnerRef
        end
    end
    logger:debug("replacing container %s in inventory of %s", self:getName(), reference.id)

    local copy = self:createCopy()
    local itemData
    if not self.reference then
        itemData = self.dataHolder --[[@as tes3itemData]]
    end
    -- local isEquipped = tes3.player.object:hasItemEquipped(self.item)
    tes3.removeItem{
        reference = reference,
        item = self.item,
        itemData = itemData,
        playSound = false,
    }
    tes3.addItem{
        reference = reference,
        item = copy,
        itemData = itemData,
        playSound = false,
    }
    -- if isEquipped then
    --     reference.mobile:equip{ item = copy }
    -- end
    --update self with new item
    self.item = copy --[[@as tes3misc]]
    self.dataHolder = itemData
end

function CarryableContainer:replace()
    if self.reference then
        self:replaceInWorld()
    else
        self:replaceInInventory()
    end
end

---Returns what the capacity of the container should be, based on containerConfig and current MCM setting
function CarryableContainer:calculateCapacity()
    if config.mcm.enableInfiniteStorage then return MAX_CAPACITY end
    local capacity = self.containerConfig.capacity
    return capacity
end

--Get the associated container reference, if it exists
function CarryableContainer:getContainerRef()
    local containerId = self:getContainerId()
    if containerId then
        local containerRef = tes3.getReference(containerId)
        logger:assert(containerRef ~= nil, "Has container id %s, but no reference exists", containerId)
        return containerRef
    end
end

--Get the associated container reference, and create one if it doesn't exist already
---@return tes3reference
function CarryableContainer:getCreateContainerRef()
    local containerRef = self:getContainerRef()
    if not containerRef then
        local containerObject = tes3.createObject{
            objectType = tes3.objectType.container,
            name = self.item.name,
            capacity = self:calculateCapacity(),
            mesh = self.containerConfig.hasCollision
                and self.item.mesh or self.item.mesh,
        }
        containerObject.modified = true

        logger:debug("Created container object %s for %s", containerObject.id, self.item.id)
        containerRef = tes3.createReference{
            object = containerObject, ---@diagnostic disable-line assign-type-mismatch
            ---1000z below
            position = {
                x = tes3.player.position.x,
                y = tes3.player.position.y,
                z = tes3.player.position.z,
            },
            orientation = tes3.player.orientation,
            cell = tes3.player.cell,
            scale = self.containerConfig.scale or 1.0
        }

        Container.hide(containerRef)

        --Map the container to the misc item
        CarryableContainer.mapItemToContainer(self.item.id, containerObject.id)

        logger:debug("Created container reference %s for %s", containerRef.id, self.item.id)
    end
    containerRef.persistent = true
    return containerRef
end

function CarryableContainer.mapItemToContainer(itemId, containerId)
    logger:debug("Mapping container %s to misc %s", containerId, itemId)

    itemId = itemId:lower()
    containerId = containerId:lower()

    --Remove existing mappings
    local previousMiscId = config.persistent.containerToMiscCopyMapping[containerId]
    if previousMiscId then
        config.persistent.miscCopyToContainerMapping[previousMiscId] = nil
    end
    local previousContainerId = config.persistent.miscCopyToContainerMapping[itemId]
    if previousContainerId then
        config.persistent.containerToMiscCopyMapping[previousContainerId] = nil
    end

    config.persistent.miscCopyToContainerMapping[itemId] = containerId
    config.persistent.containerToMiscCopyMapping[containerId] = itemId
end


---@class CarryableContainer.pickup.params
---@field doPlaySound? boolean `default: false` Whether to play the sound when picking up the item

---@param e? CarryableContainer.pickup.params
function CarryableContainer:pickup(e)
    e = e or {}
    logger:debug("Picking up %s", self.item.id)

    if not self.reference then
        logger:error("Trying to pickup item %s, but no reference exists", self.item.id)
        return
    end

    local function stealActivateEvent(e2)
        event.unregister("activate", stealActivateEvent)
        e2.claim = true
    end

    local function blockSound()
        event.unregister("addSound", blockSound)
        return false
    end

    local safeRef = tes3.makeSafeObjectHandle(self.reference)
    timer.frame.delayOneFrame(function()
        if safeRef and safeRef:valid() then
            event.register("activate", stealActivateEvent, { priority = 1000000})
            if not e.doPlaySound then
                event.register("addSound", blockSound, { priority = 1000000})
            end
            local ref = safeRef:getObject()
            logger:debug("- Activating %s", ref.id)
            tes3.player:activate(ref)
            local containerRef = self:getContainerRef()
            if containerRef then
                Container.hide(containerRef)
            end
        end
    end)
end

---Check if the container has been placed inside itself,
--- or in a container that is inside itself, etc.
--- If so, send it back to the player inventory with a message
function CarryableContainer:checkAndRemoveFromSelf()
    local containerRef = self:getContainerRef()
    if containerRef then
        ---Look for this container anywhere inside the container
        for _, result in ipairs(CarryableContainer.getInventory(containerRef)) do
            local stack = result.stack
            if stack.object then
                logger:debug("checkAndRemoveFromSelf - Checking stack %s", stack.object.id)
                logger:debug("Self.id: %s", self.item.id)

                --Check if adding container to itself
                local isItself = stack.object.id:lower() == self.item.id
                if isItself then
                    logger:debug("Removing %s from %s", self.item.id, containerRef.id)
                    self.transferItem{
                        from = containerRef,
                        to = tes3.player,
                        item = stack.object,
                        count = stack.count,
                        playSound = false
                    }
                    tes3.messageBox("You cannot place this container inside itself")
                    return
                end
            end
        end
    end
end

---Check if the container has any items that are disallowed by the containers filter,
--- and send them back to the player's inventory
--- Also checks and removes any items that are containers inside themselves
function CarryableContainer:checkAndBlockTransfer()
    --Check container inventory for item with this container as its containerID on itemData and remove
    local containerRef = self:getCreateContainerRef()
    logger:debug("Checking if misc item %s was placed in its own container %s",
        self.item.id, containerRef.id)

    ---@class CarryableContainer.checkAndBlockTransfer.itemsToRemove
    ---@field item tes3item
    ---@field itemData tes3itemData
    ---@field count number
    local itemsToRemove = {}
    local invalidMessage

    ---@param stack tes3itemStack
    for _, stack in pairs(containerRef.object.inventory) do
        local item = stack.object --[[@as tes3item]]
        local innerCarryable = CarryableContainer:new{ item = item }
        if innerCarryable then
            logger:debug("Checking inner carryable %s", item.id)
            innerCarryable:checkAndRemoveFromSelf()
        end
    end

    ---@param stack tes3itemStack
    for _, stack in pairs(containerRef.object.inventory) do
        logger:debug("Checking stack %s", stack.object.id)
        local item = stack.object --[[@as tes3item]]
        local count = stack.count
        local filter = self:getFilter()
        if filter and not self.containerConfig.allowUnfiltered then
            logger:debug("Checking filter")
            --Check itemData
            local numVariables = stack.variables and #stack.variables or 0
            if numVariables > 0 then
                ---@param itemData tes3itemData
                for _, itemData in ipairs(stack.variables) do
                    --check filtered
                    if not filter:isValid(item, itemData) then
                        logger:debug("Item with itemData %s is invalid", item.id)
                        table.insert(itemsToRemove, {
                            item = item,
                            itemData = itemData,
                        })
                        if not invalidMessage then
                            invalidMessage = filter:getInvalidMessage(item, itemData)
                        end
                    end
                end
            end
            ---If there are any without item data, check those too
            if count > numVariables then
                if not filter:isValid(item) then
                    logger:debug("Item %s is invalid", item.id)
                    table.insert(itemsToRemove, {
                        item = item,
                        count = count - numVariables,
                    })
                    if not invalidMessage then
                        invalidMessage = filter:getInvalidMessage(item)
                    end
                end
            end
        end
    end

    --Remove the filtered items
    if #itemsToRemove > 0 then
        logger:debug("Removing %d items from container %s", #itemsToRemove, containerRef.id)
        ---@param itemToRemove CarryableContainer.checkAndBlockTransfer.itemsToRemove
        for _, itemToRemove in ipairs(itemsToRemove) do
            logger:debug("  - %s", itemToRemove.item.id)
            tes3.transferItem{
                from = containerRef,
                to = tes3.player,
                item = itemToRemove.item, ---@diagnostic disable-line assign-type-mismatch
                itemData = itemToRemove.itemData,
                count = itemToRemove.count,
                playSound = false
            }
        end
        tes3.messageBox(invalidMessage or ItemFilter.defaultInvalidMessage)
    end
end


---Opens the Rename menu for a container
---@param e? { menuModeStaysOpen: boolean?, callback: fun() }
function CarryableContainer:openRenameMenu(e)
    e = e or {}

    logger:debug("Opening rename menu")
    local menu = tes3ui.createMenu{
        id = "CarryableContainers_RenameMenu",
        fixedFrame = true
    }
    menu.minWidth = 300
    menu.absolutePosAlignX = 0.5
    menu.absolutePosAlignY = 0.5
    menu.flowDirection = "left_to_right"
    menu:createLabel{
        text = "Enter a new name:",
    }
    local t = { name = self:getName() }
    local textField = mwse.mcm.createTextField(menu, {
        buttonText = "Submit",
        variable = mwse.mcm.createTableVariable{
            id = "name",
            table = t
        },
        callback = function()
            logger:debug("New name: %s", t.name)
            if t.name == "" then
                logger:debug("Name is empty, keeping old name")
                tes3.messageBox("Renamed to %s", self:getName())
                menu:destroy()
                return
            end
            if t.name == self:getName() then
                logger:debug("Name is the same, keeping old name")
                tes3.messageBox("Renamed to %s", self:getName())
                menu:destroy()
                return
            end
            if #t.name > 31 then
                logger:debug("Name is too long")
                tes3.messageBox("Name too long")
                return
            end
            logger:debug("Renaming to %s", t.name)
            --Rename both the misc item and the container
            self.item.name = t.name
            self:getCreateContainerRef().baseObject.name = t.name
            tes3.messageBox("Renamed to %s", t.name)
            menu:destroy()
            tes3ui.leaveMenuMode()
            if e.callback then e.callback() end
        end
    })
    tes3ui.acquireTextInput(textField.elements.inputField)
    tes3ui.enterMenuMode("CarryableContainers_RenameMenu")
end

---Transfer all filtered items from player inventory to the container
---Get all the filtered items, calculate the weight, then check if there is enough space
---If not enough space, cancel the transfer with a message saying why
---Otherwise, use transferItem on everything
---
--- TODO: Check if weight modifier should be removed here
---@param filter? CarryableContainers.ItemFilter The filter to use for transferring items. If nil, uses the filter set on the container
function CarryableContainer:transferFiltered(filter)

    local containerRef = self:getCreateContainerRef()
    if not containerRef then
        logger:error("Failed to get container ref")
        return
    end
    if not filter then
        filter = self:getFilter()
    end
    if not filter then
        logger:debug("No filter, skipping transfer")
        return
    end

    local itemsToTransfer = {}
    local totalWeight = 0
    local playerInventory = tes3.player.object.inventory
    local weightModifier = self:getWeightModifier() or 1.0
    for _, stack in pairs(playerInventory) do


        local item = stack.object --[[@as tes3item]]
        local count = stack.count
        local numVariables = stack.variables and #stack.variables or 0

        if item ~= self.item then

            if numVariables > 0 then
                ---@param itemData tes3itemData
                for _, itemData in ipairs(stack.variables) do
                    --check filtered
                    if filter:isValid(item, itemData) then
                        ---@cast item tes3item|tes3weapon|tes3armor|tes3clothing
                        local isEquipped =  tes3.getEquippedItem{
                            type = item.type,
                            actor = tes3.player,
                            objectType = item.objectType,
                            slot = item.slot
                        }
                        if not isEquipped then
                            totalWeight = totalWeight + (stack.object.weight * weightModifier)
                            table.insert(itemsToTransfer, {
                                item = item,
                                itemData = itemData,
                                count = 1,
                            })
                        end
                    end
                end
            end
            ---If there are any without item data, check those too
            if count > numVariables then
                if filter:isValid(item) then
                    local remainingCount = count - numVariables
                    totalWeight = totalWeight + (stack.object.weight * weightModifier * remainingCount)
                    table.insert(itemsToTransfer, {
                        item = item,
                        count = remainingCount,
                    })
                end
            end
        end
    end
    --Only need to check weight if retrieving from world, otherwise it evens out anyway
    local maxCapacity = containerRef.object.capacity
    local currentWeight = containerRef.object.inventory:calculateWeight()
    local remainingCapacity = maxCapacity - currentWeight
    logger:debug("Current capacity: %d", currentWeight)
    logger:debug("Remaining capacity: %d", remainingCapacity)
    logger:debug("Total weight: %d", totalWeight)
    if remainingCapacity < totalWeight then
        tes3.messageBox("Not enough space in container")
        return
    end
    logger:debug("Transferring %d items filtered by '%s' to %s",
        #itemsToTransfer, filter.name or "custom", containerRef.id)
    --Transfer the items
    local hasItemsToTransfer = false
    for _, itemToTransfer in ipairs(itemsToTransfer) do
        hasItemsToTransfer = true
        tes3.transferItem{
            from = tes3.player,
            to = containerRef,
            item = itemToTransfer.item, ---@diagnostic disable-line assign-type-mismatch
            itemData = itemToTransfer.itemData,
            count = itemToTransfer.count,
            playSound = false,
            updateGUI = false,
        }
    end
    if hasItemsToTransfer then
        tes3.playSound{ sound = "Item Misc Up" }
        tes3.updateInventoryGUI({ reference = tes3.player })
        tes3.updateInventoryGUI({ reference = containerRef })
    else
        tes3.messageBox("Nothing to transfer.")
    end
end

-- Transfer all items in the container to the player
function CarryableContainer:takeAll()
    local containerRef = self:getCreateContainerRef()
    if not containerRef then
        logger:error("Failed to get container ref")
        return
    end
    local containerInventory = containerRef.object.inventory
    logger:debug("Taking all items from %s", containerRef.id)
    local hasItemsToTransfer = false
    for _, stack in pairs(containerInventory) do
        hasItemsToTransfer = true
        local item = stack.object --[[@as tes3item]]
        ---If there are any without item data, check those too
        tes3.transferItem{
            from = containerRef,
            to = tes3.player,
            item = item, ---@diagnostic disable-line assign-type-mismatch
            count = stack.count,
            playSound = false,
            updateGUI = false,
            limitCapacity = false
        }
    end
    if hasItemsToTransfer then
        tes3.playSound{ sound = "Item Misc Up" }
        tes3.updateInventoryGUI({ reference = tes3.player })
        tes3.updateInventoryGUI({ reference = containerRef })
    else
        tes3.messageBox("Nothing to transfer.")
    end
end

---Transfer a specific list of items from the player to the container
---@param e { itemIds: string[] }
function CarryableContainer:transferPlayerToContainer(e)
    --create custom filter that returns true for items in the list
    local filter = ItemFilter:new{
        id = "",
        name = "transferPlayerToContainer",
        isValidItem = function(item)
            for _, id in ipairs(e.itemIds) do
                if item.id:lower() == id:lower() then
                    return true
                end
            end
            return false
        end
    }
    self:transferFiltered(filter)
    self:updateStats()
end

---@class (exact) CarryableContainer.transferPlayerToContainerWithDetails.items
---@field item tes3item Item to transfer
---@field count number Item count
---@field itemData tes3itemData? Item data

---Transfer a specific list of items with counts and itemData from the player to the container
---@param e { items: CarryableContainer.transferPlayerToContainerWithDetails.items[] }
function CarryableContainer:transferPlayerToContainerWithDetails(e)
    local containerRef = self:getCreateContainerRef()
    if not containerRef then
        logger:error("Failed to get container ref")
        return
    end

    local itemsToTransfer = {}
    for _, itemDetail in ipairs(e.items) do
        if itemDetail.item then
            table.insert(itemsToTransfer, {
                item = itemDetail.item,
                count = itemDetail.count,
                itemData = itemDetail.itemData,
            })
        else
            logger:warn("Item with ID %s not found", itemDetail.item.id)
        end
    end

    local hasItemsToTransfer = false
    for _, itemToTransfer in ipairs(itemsToTransfer) do
        hasItemsToTransfer = true
        tes3.transferItem{
            from = tes3.player,
            to = containerRef,
            item = itemToTransfer.item,
            itemData = itemToTransfer.itemData,
            count = itemToTransfer.count,
            playSound = false,
            updateGUI = false,
        }
    end

    if hasItemsToTransfer then
        tes3.playSound{ sound = "Item Misc Up" }
        tes3.updateInventoryGUI({ reference = tes3.player })
        tes3.updateInventoryGUI({ reference = containerRef })
    else
        tes3.messageBox("Nothing to transfer.")
    end

    self:updateStats()
end

return CarryableContainer