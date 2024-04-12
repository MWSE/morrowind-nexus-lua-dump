local config = require("CraftingFramework.carryableContainers.config")
local util = require("CraftingFramework.util.Util")
local logger = util.createLogger("Container")
local Positioner = require("CraftingFramework.components.Positioner")
local mwseCommon = require("mwse.common")

---@class CarryableContainers.Container
local Container = {}

---@param e tes3.positionCell.params
function Container.positionCell(e)
    tes3.positionCell(e)
    e.reference.position = e.position:copy()
    e.reference.orientation = e.orientation:copy()
end

---@param reference tes3reference
function Container.hide(reference)
    logger:debug("Hiding container %s", reference)
    reference:disable()
    reference.hasNoCollision = true
end

function Container.unhide(reference)
    logger:debug("Unhiding container %s", reference)
    reference:enable()
    reference.hasNoCollision = false
end

function Container.getMiscIdfromReference(containerRef)
    if not containerRef then
        logger:trace("No container ref")
        return nil
    end
    local miscId = config.persistent.containerToMiscCopyMapping[containerRef.baseObject.id:lower()]
    if not miscId then
        logger:trace("No misc id")
        return nil
    end
    logger:trace("Found misc id: %s", miscId)
    return miscId
end


function Container.getMenuReference(contentsMenu)
    local contentsMenu = contentsMenu or tes3ui.findMenu(tes3ui.registerID("MenuContents"))
    local menuInvalid = contentsMenu == nil
        or contentsMenu.name ~= "MenuContents"
        or contentsMenu.visible == false
    if menuInvalid then
        logger:trace("Menu is invalid")
        return nil
    end
    local containerRef = contentsMenu:getPropertyObject("MenuContents_ObjectRefr")
    return containerRef
end

---@return string? # Flase if not open, otherwise returns the associated misc item id
function Container.getOpenContainerMiscId(contentsMenu)
    logger:trace("Checking if we are in a carryable container inventory")
    local containerRef = Container.getMenuReference(contentsMenu)
    return Container.getMiscIdfromReference(containerRef)
end

local function replaceTakeAllButton(menu, carryable)
    local takeAllButton = menu:findChild("MenuContents_takeallbutton")
    takeAllButton.visible = false
    local takeAllButtonParent = takeAllButton.parent

    --Destroy existing
    local existingButton = takeAllButtonParent:findChild("merCarryableContainers_takeAllButton")
    if existingButton then
        existingButton:destroy()
    end

    local newTakeAllButton = takeAllButtonParent:createButton{
        id = "merCarryableContainers_takeAllButton",
        text = "Взять все"
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


local function createFilterButton(transferButtonParent, menu, carryable)

    --Destroy existing
    local existingButton = transferButtonParent:findChild("merCarryableContainers_filterButton")
    if existingButton then
        existingButton:destroy()
    end

    local filter = carryable:getFilter()
    local transferText = string.format("Переместить %s", filter.name)
    local transferButton = transferButtonParent:createButton{
        id = "merCarryableContainers_filterButton",
        text = transferText
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
    --Destroy existing
    local existingButton = parent:findChild("merCarryableContainers_renameButton")
    if existingButton then
        existingButton:destroy()
    end

    local renameButton = parent:createButton{
        id = "merCarryableContainers_renameButton",
        text = "Переименовать"
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
    --Destroy existing
    local existingButton = parent:findChild("merCarryableContainers_pickupButton")
    if existingButton then
        existingButton:destroy()
    end


    local pickupButton = parent:createButton{
        id = "merCarryableContainers_pickupButton",
        text = "Убрать"
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

---@param carryable CarryableContainer
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

local function addCapacityFillbar(menu, carryable)
    --destroy existing
    local existingBar = menu:findChild("CarryableContainers:MenuContents_capacity")
    if existingBar then
        existingBar:destroy()
    end

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
    --Destroy existing
    local existingButton = parent:findChild("merCarryableContainers_positionButton")
    if existingButton then
        existingButton:destroy()
    end

    --Determine which ref to position. hasCollision means the container is the ref
    local reference = carryable.reference
    if carryable.containerConfig.hasCollision then
        reference = menu:getPropertyObject("MenuContents_ObjectRefr")
    end

    local positionButton = parent:createButton{
        id = "merCarryableContainers_positionButton",
        text = "Переместить"
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

---@class CraftingFramework.Container.addButtons.params
---@field menu tes3uiElement
---@field carryable CarryableContainer?

---@param e CraftingFramework.Container.addButtons.params
function Container.addCarryableButtonsToMenu(e)
    local menu = e.menu
    local carryable = e.carryable

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

    --Add filter button
    if carryable and carryable:getFilter() then
        local transferButton = createFilterButton(buttonBlock, menu, carryable)
        buttonBlock:reorderChildren(newTakeAllButton, transferButton, 1)
    end

    --Add rename button
    local renameButton = addRenameButton(buttonBlock, carryable)
    buttonBlock:reorderChildren(newTakeAllButton, renameButton, 1)


    --Add pickup/position button for in-world containers
    if carryable and carryable.reference then
        local positionButton = addPositionButton(buttonBlock, carryable, menu)
        buttonBlock:reorderChildren(newTakeAllButton, positionButton, 1)

        local pickupButton = addPickupButton(buttonBlock, carryable, menu)
        pickupButton.parent:reorderChildren(newTakeAllButton, pickupButton, 1)
    end

    --Add capacity fillbar
    addCapacityFillbar(menu, carryable)

    menu:updateLayout()
end

---@class CraftingFramework.Container.addButton.params
---@field reference tes3reference
---@field buttonData craftingFrameworkMenuButtonData
---@field parent tes3uiElement
---@field menu tes3uiElement

---@param e CraftingFramework.Container.addButton.params
---@return tes3uiElement|nil button
local function addButton(e)
    local doShow = e.buttonData.showRequirements == nil
        or e.buttonData.showRequirements{ reference = e.reference}
    if not doShow then return end
    local button = e.parent:createButton{
        id = "CraftingFramework_CraftedContainerButton",
        text = mwseCommon.resolveDynamicText(e.buttonData.text),
    }
    local doEnable = e.buttonData.enableRequirements == nil
        or e.buttonData.enableRequirements{ reference = e.reference}
    if not doEnable then
        mwseCommon.ui.disable(button)
    end
    button:register("mouseClick", function()
        e.menu:destroy()
        tes3ui.leaveMenuMode()
        e.buttonData.callback{ reference = e.reference}
    end)
    return button
end

---@class CraftingFramework.Container.addCraftableButtonsToMenu.params
---@field craftable CraftingFramework.Craftable
---@field reference tes3reference
---@field menu tes3uiElement

---@param e CraftingFramework.Container.addCraftableButtonsToMenu.params
function Container.addCraftableButtonsToMenu(e)
    local menuButtons = e.craftable:getMenuButtons(e.reference)
    local menu = e.menu
    local takeAllButton = menu:findChild("MenuContents_takeallbutton")
    local buttonBlock = takeAllButton and takeAllButton.parent
    if not buttonBlock then return end
    local filterBlock = menu:findChild("UIEXP:ContentsMenu:FilterBlock")
    for _, buttonData in ipairs(menuButtons) do
        local button = addButton{
            menu = menu,
            reference = e.reference,
            buttonData = buttonData,
            parent = buttonBlock,
        }
        if button then
            buttonBlock:reorderChildren(takeAllButton, button, 1)
        end
    end
    menu:updateLayout()
end

return Container