local config = require("CraftingFramework.carryableContainers.config")
local util = require("CraftingFramework.util.Util")
local logger = util.createLogger("Container")
local Positioner = require("CraftingFramework.components.Positioner")

---@class CarryableContainers.Container
local Container = {}

function Container.getMiscIdfromReference(reference)
    if not reference then
        logger:trace("No container ref")
        return nil
    end
    local miscId = config.persistent.containerToMiscCopyMapping[reference.baseObject.id:lower()]
    if not miscId then
        logger:trace("No misc id")
        return nil
    end
    logger:trace("Found misc id: %s", miscId)
    return miscId
end

---@return string? # Flase if not open, otherwise returns the associated misc item id
function Container.getOpenContainerMiscId(contentsMenu)
    logger:trace("Checking if we are in a carryable container inventory")
    local contentsMenu = contentsMenu or tes3ui.findMenu(tes3ui.registerID("MenuContents"))
    local menuInvalid = contentsMenu == nil
        or contentsMenu.name ~= "MenuContents"
        or contentsMenu.visible == false
    if menuInvalid then
        logger:trace("Menu is invalid")
        return nil
    end
    local containerRef = contentsMenu:getPropertyObject("MenuContents_ObjectRefr")
    return Container.getMiscIdfromReference(containerRef)
end

local function replaceTakeAllButton(menu, carryable)
    local takeAllButton = menu:findChild("MenuContents_takeallbutton")
    takeAllButton.visible = false
    local takeAllButtonParent = takeAllButton.parent

    local newTakeAllButton = takeAllButtonParent:createButton{
        id = "merCarryableContainers_takeAllButton",
        text = "Take All"
    }
    newTakeAllButton:register("mouseClick", function()
        logger:debug("Clicked take all button")
        carryable:takeAll()
        menu:updateLayout()
    end)
    newTakeAllButton.borderAllSides = 4
    newTakeAllButton.paddingLeft = 8
    newTakeAllButton.paddingRight = 8
    newTakeAllButton.paddingBottom = 3
    takeAllButton.parent:reorderChildren(takeAllButton, newTakeAllButton, 1)
    return newTakeAllButton
end

local function createFilterLabel_deprecated(filterButtonParent, filter)
    logger:debug("Creating filter label")
    local label = filterButtonParent:createLabel{
        id = "merCarryableContainers_filterLabel",
        text = string.format(" [ Filter: %s ] ", filter.name)
    }
    label.borderRight = 10
    label.borderBottom = 3
    label.color = tes3ui.getPalette("header_color")
    return label
end

local function createFilterButton(transferButtonParent, menu, carryable)
    local filter = carryable:getFilter()
    local tranferText = string.format("Transfer %s", filter.name)
    local transferButton = transferButtonParent:createButton{
        id = "merCarryableContainers_transferButton",
        text = tranferText
    }
    transferButton:register("mouseClick", function()
        logger:debug("Clicked transfer button")
        carryable:transferFiltered()
        menu:updateLayout()
    end)
    transferButton.borderAllSides = 4
    transferButton.paddingLeft = 8
    transferButton.paddingRight = 8
    transferButton.paddingBottom = 3
    return transferButton
end

---@param parent tes3uiElement
---@param carryable CarryableContainer
local function addRenameButton(parent, carryable)
    local renameButton = parent:createButton{
        id = "merCarryableContainers_renameButton",
        text = "Rename"
    }
    renameButton:register("mouseClick", function()
        logger:debug("Clicked rename button")
        carryable:openRenameMenu{
            callback = function()
                logger:debug("Reopening container after rename")
                timer.delayOneFrame(function()
                    tes3.player:activate(carryable:getCreateContainerRef())
                end)
            end
        }
    end)
    return renameButton
end

---@param parent tes3uiElement
---@param carryable CarryableContainer
local function addPickupButton(parent, carryable, menu)
    local pickupButton = parent:createButton{
        id = "merCarryableContainers_pickupButton",
        text = "Pick Up"
    }
    pickupButton:register("mouseClick", function()
        logger:debug("Clicked pickup button")
        menu:destroy()
        tes3ui.leaveMenuMode()
        carryable:setSafeInstance()
        timer.delayOneFrame(function()
            carryable:getSafeInstance()
            carryable:pickup{ doPlaySound = true}
        end)
    end)
    return pickupButton
end

function Container.updateCapacityFillbar(carryable)
    local menu = tes3ui.findMenu("MenuContents")
    if (menu == nil) then return end
    local maxCapacity = menu:getPropertyFloat("MenuContents_containerweight")
    local bar = menu:findChild("CarryableContainers:MenuContents_capacity")
    bar.widget.max = maxCapacity
    bar.widget.current = carryable:calculateWeight()
    logger:debug("Updating capacity fillbar: %s / %s", bar.widget.current, bar.widget.max)
    if (maxCapacity <= 0) then
        bar.visible = false
    end
end

function Container.addCapacityFillbar(menu, carryable)
	-- Create capacity fillbar for containers.
    local buttonBlock = menu:findChild("Buttons").children[2]
    local capacityBar = buttonBlock:createFillBar{
        id = "CarryableContainers:MenuContents_capacity"
    }
    capacityBar.width = 128
    capacityBar.height = 21
    capacityBar.borderAllSides = 4
    buttonBlock:reorderChildren(0, -1, 1)

    menu:registerBefore("update", function()
        Container.updateCapacityFillbar(carryable)
    end)
    -- Necessary as otherwise the fillbar is hidden for some reason.
    menu:triggerEvent("update")
end

---@param parent tes3uiElement
---@param carryable CarryableContainer
local function addPositionButton(parent, carryable, menu)
    --Determine which ref to position. hasCollision means the container is the ref
    local reference = carryable.reference
    if carryable.containerConfig.hasCollision then
        reference = menu:getPropertyObject("MenuContents_ObjectRefr")
    end

    local positionButton = parent:createButton{
        id = "merCarryableContainers_positionButton",
        text = "Position"
    }
    positionButton:register("mouseClick", function()
        logger:debug("Clicked position button")
        --end menu, open Positioner.startPositioning
        tes3ui.leaveMenuMode()
        local safeRef = tes3.makeSafeObjectHandle(reference)
        timer.delayOneFrame(function()
            logger:debug("Positioning after frame")
            -- Put those hands away.
            if (tes3.mobilePlayer.weaponReady) then
                tes3.mobilePlayer.weaponReady = false
            elseif (tes3.mobilePlayer.castReady) then
                tes3.mobilePlayer.castReady = false
            end
            if safeRef and safeRef:valid() then
                logger:debug("Ref is safe, start positioning %s", reference)
                Positioner.startPositioning{
                    target = reference,
                    nonCrafted = true,
                }
            end
        end)
    end)
    return positionButton
end

---@param menu tes3uiElement
---@param carryable CarryableContainer
function Container.addButtons(menu, carryable)

    -- disable UI Expansions filter and capacity elements
    local uiExpFilterBlock = menu:findChild("UIEXP:ContentsMenu:FilterBlock")
    if uiExpFilterBlock then
        tes3ui.acquireTextInput(nil)
        uiExpFilterBlock.visible = false
    end
    local uiExpCapacity = menu:findChild("UIEXP_MenuContents_capacity")
    if uiExpCapacity then
        uiExpCapacity.visible = false
    end

    --Replace the take all button with our one
    local takeAllButton = menu:findChild("MenuContents_takeallbutton")
    local buttonBlock = takeAllButton.parent
    local newTakeAllButton = replaceTakeAllButton(menu, carryable)

    --Add pickup/position button for in-world containers
    if carryable.reference then
        local pickupButton = addPickupButton(buttonBlock, carryable, menu)
        local closeButton = menu:findChild("MenuContents_closebutton")
        pickupButton.parent:reorderChildren(closeButton, pickupButton, 1)

        local positionButton = addPositionButton(buttonBlock, carryable, menu)
        buttonBlock:reorderChildren(-2, positionButton, 1)
    end

    --Add filter button
    if carryable:getFilter() then
        local transferButton = createFilterButton(buttonBlock, menu, carryable)
        buttonBlock:reorderChildren(newTakeAllButton, transferButton, 1)
    end

    --Add rename button
    local renameButton = addRenameButton(buttonBlock, carryable)
    buttonBlock:reorderChildren(-2, renameButton, 1)

    --Add capacity fillbar
    Container.addCapacityFillbar(menu, carryable)

    menu:updateLayout()
end

return Container