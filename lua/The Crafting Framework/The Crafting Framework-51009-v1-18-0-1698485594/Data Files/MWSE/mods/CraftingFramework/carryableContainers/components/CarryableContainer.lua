local config = require("CraftingFramework.carryableContainers.config")
local util = require("CraftingFramework.util.Util")
local logger = util.createLogger("CarryableContainer")
local ItemInstance = require("CraftingFramework.carryableContainers.components.ItemInstance")
local ItemFilter = require("CraftingFramework.carryableContainers.components.ItemFilter")
local Container = require("CraftingFramework.carryableContainers.components.Container")
local RefStack = require("CraftingFramework.util.RefStack")
local MAX_CAPACITY = 65535
---@class CarryableContainer.containerConfig
---@field itemId string The id of the item to use for the container
---@field filter CarryableContainers.DefaultItemFilter? The id of the filter to use for the container
---@field capacity number The capacity of the container
---@field hasCollision boolean? If set to true, the in-world reference will be an actual container, rather than the placed misc item. This will give it collision, but also means it can't be as easily moved
---@field weightModifier number? The weight of the contents of this container will be multiplied by this value.
---@field scale number? The scale of the placed container

---@class CarryableContainer.new.params : ItemInstance.new.params
---@field containerRef tes3reference? If provided, the item will be created from the container reference

---A carrayable container is a misc item that, when activated
--- or equipped, will open its associated container reference
---@class CarryableContainer : ItemInstance
---@field item tes3misc
---@field containerConfig CarryableContainer.containerConfig
---@field data table
---@field filter CarryableContainers.ItemFilter|nil
local CarryableContainer = ItemInstance:new()

---Get a container by its base itemId

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
end

---@param item tes3item|tes3misc|tes3object
---@return CarryableContainer.containerConfig|nil
function CarryableContainer.getContainerConfig(item)
    local id = item.id:lower()
    if config.persistent.miscCopyToBaseMapping[id] then
        --if this is a copy of a container, get the base container config
        id = config.persistent.miscCopyToBaseMapping[id]
    end
    local containerConfig = config.registeredContainers[id]
    if containerConfig then
        return containerConfig
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
    logger:debug("openFromInventory()")
    self:replaceInInventory()
    logger:debug("Opening container from inventory %s", self:getContainerId())
    local containerRef = self:getCreateContainerRef()
    tes3.player:activate(containerRef)
    timer.delayOneFrame(function()
        self:updateStats()
    end)
end

function CarryableContainer:openFromWorld()
    logger:debug("openFromWorld()")
    self:replaceInWorld()
    logger:debug("Opening container from world %s", self:getContainerId())
    local containerRef = self:getCreateContainerRef()
    tes3.player:activate(containerRef)
end

function CarryableContainer:open()
    --if ref, open from world, otherwise open from inventory
    if self.reference then
        self:openFromWorld()
    else
        self:openFromInventory()
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

function CarryableContainer:calculateWeight()
    local container = self:getCreateContainerRef()
    return container.object.inventory:calculateWeight()
        * (self:getWeightModifier() or 1.0)
end

function CarryableContainer:updateStats()
    logger:debug("Updating weight of %s", self.item.id)
    local weightModifier = self:getWeightModifier() or 1.0
    logger:debug("Weight modifier is %s", weightModifier)
    --add up the weight off all items in the container ref and set it to this item's base weight plus the total
    local totalWeight = self:getBaseWeight()
    local totalValue = self:getBaseValue()
    local containerRef = self:getCreateContainerRef()
    ---@param stack tes3itemStack
    for _, stack in pairs(containerRef.object.inventory) do
        totalWeight = totalWeight + (stack.object.weight * stack.count * weightModifier)
        local value = stack.object.value
        local count = stack.count or 1
        logger:debug("Item %s has value %s", stack.object.id, value)
        logger:debug("Item %s has count %s", stack.object.id, count)
        --if has variables, iterate through and multiply value by condition
        if stack.variables then
            ---@param itemData tes3itemData
            for _, itemData in pairs(stack.variables) do
                totalValue = totalValue + tes3.getValue{ item = stack.object, itemData = itemData}
                count = count - 1
            end
        end
        totalValue = totalValue + (value * count)
        logger:debug("Total value of %s is %s", self.item.id, totalValue)
    end
    logger:debug("Total weight of %s is %s", self.item.id, totalWeight)
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
    logger:debug("Created copy %s", copy.id)
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

--Get the weight modifier for this container
function CarryableContainer:getWeightModifier()
    return self.containerConfig.weightModifier
end

function CarryableContainer:replaceInWorld()
    if not self.reference then
        logger:error("Trying to replace in world for item %s", self.item.id)
        return self
    end
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

            logger:debug("Moving %s to position %.f, %.f, %.f",
                containerRef.object.id,
                self.reference.position.x,
                self.reference.position.y,
                self.reference.position.z)

            tes3.positionCell{
                reference = containerRef,
                position = self.reference.position,
                orientation = self.reference.orientation,
                cell = self.reference.cell,
                forceCellChange = true
            }
            containerRef.scale = self.containerConfig.scale or 1.0
            containerRef.hasNoCollision = false
            containerRef:updateLighting()
            if containerRef.sceneNode then
                containerRef.sceneNode.appCulled = false
                containerRef.sceneNode:updateProperties()
                containerRef.sceneNode:updateEffects()
            else
                logger:error("No scene node for %s", containerRef.object.id)
            end
            tes3.dataHandler:updateCollisionGroupsForActiveCells{}


            --move miscRef elsewhere -1000 z
            local position = self.reference.position:copy()
            position.z = position.z - 1000
            tes3.positionCell{
                reference = self.reference,
                position = position,
                orientation = self.reference.orientation,
                cell = self.reference.cell,
            }


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
    local copy = self:createCopy()
    local itemData
    if not self.reference then
        itemData = self.dataHolder --[[@as tes3itemData]]
    end
    tes3.player.object.inventory:removeItem{
        item = self.item,
        itemData = itemData,
    }
    tes3.player.object.inventory:addItem{
        item = copy,
        itemData = itemData,
    }
    --update self with new item
    self.item = copy --[[@as tes3misc]]
    self.dataHolder = itemData
end

---Returns what the capacity of the container should be, based on containerConfig and current MCM setting
function CarryableContainer:calculateCapacity()
    return config.mcm.enableInfiniteStorage and MAX_CAPACITY or self.containerConfig.capacity
end

--Get the associated container reference, if it exists
function CarryableContainer:getContainerRef()
    if self:getContainerId() then
        local containerRef = tes3.getReference(self:getContainerId())
        logger:assert(containerRef ~= nil, "Has container id %s, but no reference exists", self:getContainerId())
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

        logger:debug("Created container object %s for %s", containerObject.id, self.item.id)
        containerRef = tes3.createReference{
            object = containerObject, ---@diagnostic disable-line assign-type-mismatch
            ---1000z below
            position = {
                x = tes3.player.position.x,
                y = tes3.player.position.y,
                z = tes3.player.position.z - 1000,
            },
            orientation = tes3.player.orientation,
            cell = tes3.player.cell,
            scale = self.containerConfig.scale or 1.0
        }

        --Map the container to the misc item
        logger:debug("Mapping container %s to misc %s", containerObject.id, self.item.id)
        config.persistent.miscCopyToContainerMapping[self.item.id:lower()] = containerObject.id:lower()
        config.persistent.containerToMiscCopyMapping[containerObject.id:lower()] = self.item.id:lower()

        logger:debug("Created container reference %s for %s", containerRef.id, self.item.id)
    end
    return containerRef
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
            local container = self:getContainerRef()
            if container then
                --moving container out of the way
                --container.sceneNode.appCulled = true
                container.hasNoCollision = true
                tes3.positionCell{
                    reference = container,
                    position = {
                        x = tes3.player.position.x,
                        y = tes3.player.position.y,
                        z = tes3.player.position.z - 1000,
                    },
                    orientation = tes3.player.orientation,
                    cell = tes3.player.cell,
                }
            end
        end
    end)
end

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
        logger:debug("Checking stack %s", stack.object.id)
        logger:debug("Self.id: %s", self.item.id)

        local item = stack.object --[[@as tes3item]]
        local count = stack.count

        --Check if adding container to itself
        local isItself = item.id:lower() == self.item.id
        if isItself then
            table.insert(itemsToRemove, {
                item = item,
                count = count,
            })
        end
        local filter = self:getFilter()
        if filter then
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
            }
        end
        tes3.messageBox(invalidMessage or ItemFilter.defaultInvalidMessage)
    end
end

---@class CarryableContainer.openRenameMenu.params
---@field menuModeStaysOpen boolean? If true, the menu will stay open after the button is pressed
---@field callback fun() Callback function to run after the renaming is complete

---@param e? CarryableContainer.openRenameMenu.params
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
    local t = { name = self.item.name }
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
                tes3.messageBox("Renamed to %s", self.item.name)
                menu:destroy()
                return
            end
            if t.name == self.item.name then
                logger:debug("Name is the same, keeping old name")
                tes3.messageBox("Renamed to %s", self.item.name)
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

function CarryableContainer:transferFiltered()
    --Transfer all filtered items from player inventory to the container
    --Get all the filtered items, calculate the weight, then check if there is enough space
    --If not enough space, cancel the transfer with a message saying why
    --Otherwise, use transferItem on everything

    local containerRef = self:getCreateContainerRef()
    if not containerRef then
        logger:error("Failed to get container ref")
        return
    end
    local filter = self:getFilter()
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
        #itemsToTransfer, filter.name, containerRef.id)
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

-- Transfer all items in the container to the player, if the player has enough space
function CarryableContainer:takeAll()
    local containerRef = self:getCreateContainerRef()
    if not containerRef then
        logger:error("Failed to get container ref")
        return
    end
    local containerInventory = containerRef.object.inventory
    local totalWeight = containerInventory:calculateWeight()
    local encumbrance = tes3.mobilePlayer.encumbrance
    local remainingPlayerCapacity = encumbrance.base - encumbrance.current
    if self.reference then
        if remainingPlayerCapacity < totalWeight then
            tes3.messageBox("Not enough space in inventory")
            return
        end
    end
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

function CarryableContainer:_openContainerMenu_deprecated()
    logger:debug("Opening container menu for %s", self.item.id)
    --options: open, pick up. use tes3ui.showMessageMenu
    self:setSafeInstance()

    tes3ui.showMessageMenu{
        message = self.item.name,
        buttons = {
            {
                text = "Open",
                callback = function()
                    timer.delayOneFrame(function()
                        self = self:getSafeInstance() --[[@as CarryableContainer]]
                        if self then
                            self:open()
                            self:updateStats()
                        else
                            logger:error("Failed to get safe instance when opening")
                        end
                    end)
                end
            },
            {
                text = "Rename",
                callback = function()
                    timer.delayOneFrame(function()
                        self = self:getSafeInstance() --[[@as CarryableContainer]]
                        if self then
                            self:openRenameMenu()
                        else
                            logger:error("Failed to get safe instance when renaming")
                        end
                    end)
                end
            },
            {
                text = "Pick up",
                callback = function ()
                    timer.delayOneFrame(function()
                        self = self:getSafeInstance() --[[@as CarryableContainer]]
                        if self then
                            self:pickup()
                        else
                            logger:debug("Failed to get safe instance when picking up")
                        end
                    end)
                end,
                showRequirements = function()
                    return self.reference ~= nil
                end
            }
        },
        cancels = true
    }
end

return CarryableContainer