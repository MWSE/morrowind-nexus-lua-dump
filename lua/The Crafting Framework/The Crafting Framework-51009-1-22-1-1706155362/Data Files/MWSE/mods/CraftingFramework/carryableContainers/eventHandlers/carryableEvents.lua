local config = require("CraftingFramework.carryableContainers.config")
local util = require("CraftingFramework.util.Util")
local logger = util.createLogger("CarryableEvents")
local CarryableContainer = require("CraftingFramework.carryableContainers.components.CarryableContainer")
local Container = require("CraftingFramework.carryableContainers.components.Container")

--[[
    When the player equips a carrayble container, we need to open it
]]
---@param e equipEventData
local function onEquipContainer(e)
    logger:debug("equip")
    local carryableMisc = CarryableContainer:new{
        item = e.item,
        itemData = e.itemData,
    }
    if carryableMisc then
        logger:debug("Opening container %s", carryableMisc.item.id)
        timer.frame.delayOneFrame(function()
            carryableMisc:open()
        end)
        return true
    end
end
event.register("equip", onEquipContainer)

--[[
    When the player activates a carrayble container, we need to open it
]]
---@param e activateEventData
local function onActivateContainer(e)

    logger:debug("activate")
    if tes3ui.menuMode() then
        logger:debug("Menu mode, skip")
        return
    end

    --If actiuvating a container, pick up if shift down, otherwise do nothing
    --If activating a misc item, pick up if shift down, otherwise open
    local miscCarryable = CarryableContainer:new{ reference = e.target }
    if miscCarryable then
        logger:debug("Activating misc item")
        if not util.isQuickModifierDown() then
            logger:debug("Opening misc item")
            miscCarryable:open()
            return true
        end
        return --else pick up misc ref
    end

    local containerCarryable = CarryableContainer:new{ containerRef = e.target }
    if containerCarryable then
        logger:debug("Activating container")
        if util.isQuickModifierDown() then
            logger:debug("Quick modifier is down, picking up")
            containerCarryable:pickup{ doPlaySound = true }
            return true
        end
        return --else activate container
    end
end
event.register("activate", onActivateContainer)

--[[
    Many tiles are updated in a single frame, but we only want to do updates once
    When a tile is updated, set the flag to true and then check it in the enterFrame event
]]
local tileUpdatedThisFrame = false
local function updateOnTransfer()
    if not tileUpdatedThisFrame then return end

    local miscId = Container.getOpenContainerMiscId()
    if miscId then
        logger:debug("We are in a carryable container inventory, miscRef ID: %s", miscId)

        local miscObject = tes3.getObject(miscId)--[[@as tes3misc]]
        logger:debug("miscObject: %s", miscObject)
        if miscObject then
            logger:debug("Found the misc item object")
            local carryableMisc = CarryableContainer:new{
                item = miscObject,
            }
            if carryableMisc then
                logger:debug("Updating weight and checking block transfer")
                carryableMisc:checkAndBlockTransfer()
                carryableMisc:updateStats()
            end
        end
    end

    tileUpdatedThisFrame = false
end
event.register("enterFrame", updateOnTransfer)


event.register("itemTileUpdated", function(e)
    if tileUpdatedThisFrame then return end
    --Check container is open
    local contentsMenu = tes3ui.findMenu(tes3ui.registerID("MenuContents"))
    if contentsMenu == nil or contentsMenu.visible == false then
        return
    end
    tileUpdatedThisFrame = true
end)


---@param e itemDroppedEventData
event.register("itemDropped", function(e)
    if not e.reference then return end
    local carryableMisc = CarryableContainer:new{
        reference = e.reference
    }
    if carryableMisc then
        logger:debug("Replacing dropped reference")
        carryableMisc:replaceInWorld()
        return true
    end
end, { priority = -200})


event.register("itemTileUpdated", function(itemTileEventData)
    itemTileEventData.element:registerBefore("mouseClick", function(e)
        -- Fire off an event when the tile is clicked for other modules to hook into.
        local tileData = e.source:getPropertyObject("MenuInventory_Thing", "tes3inventoryTile") --- @type tes3inventoryTile
        tileData = tileData or e.source:getPropertyObject("MenuContents_Thing", "tes3inventoryTile")
        if not tileData then return end

        logger:debug("Clicked on container")
        local container = CarryableContainer:new{ item = tileData.item, itemData = tileData.itemData }
        if not container then
            logger:debug("not a carryable container")
            return
        end
        if util.isQuickModifierDown() then
            local isEquipped = tes3.player.object:hasItemEquipped(tileData.item)
            --menu click sound
            tes3.worldController.menuClickSound:play()
            container:openFromInventory()


            if isEquipped then
                logger:debug("Container is equipped, triggering equip again in case it was replaced")
                tes3.mobilePlayer:equip{ item = container.item }
            end

            return false
        end
        container:setSafeInstance()
        timer.frame.delayOneFrame(function()
            if container:valid() then
                container:updateStats()
            end
        end)
    end)
end)

event.register("loaded", function()
    CarryableContainer.recalculateEncumbrance()
    for originalId, copiedId in pairs(config.persistent.containerCopies) do
        logger:info("Registering copied carryable container. Original: %s, New: %s",
        originalId, copiedId)
        local containerConfig = CarryableContainer.getContainerConfigById(originalId)
        if containerConfig then
            ---@type CarryableContainer.containerConfig
            local newConfig = table.copy(containerConfig)
            newConfig.itemId = copiedId
            CarryableContainer.register(newConfig)
        end
    end
end)

