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
        return
    end
    local carryableMisc = CarryableContainer:new{
        reference = e.target,
    }
    if not carryableMisc then return end

    logger:debug("Activating container")
    carryableMisc:open()
    return true
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

---@param e itemTileUpdatedEventData
local function onItemTileUpdated(e)
    if tileUpdatedThisFrame then return end
    --Check container is open
    local contentsMenu = tes3ui.findMenu(tes3ui.registerID("MenuContents"))
    if contentsMenu == nil or contentsMenu.visible == false then
        return
    end
    tileUpdatedThisFrame = true
end
event.register("itemTileUpdated", onItemTileUpdated)


---@param e itemDroppedEventData
local function onDrop(e)
    if not e.reference then return end
    local carryableMisc = CarryableContainer:new{
        reference = e.reference
    }
    if carryableMisc then
        logger:debug("Replacing dropped reference")
        carryableMisc:replaceInWorld()
        return true
    end
end
event.register("itemDropped", onDrop, { priority = -200})

--recalibrate encumbrance on load
event.register("loaded", function()
    CarryableContainer.recalculateEncumbrance()
end)