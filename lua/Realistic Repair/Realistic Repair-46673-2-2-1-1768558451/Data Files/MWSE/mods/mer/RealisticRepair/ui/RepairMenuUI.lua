---@class RealisticRepair.RepairMenuUI
--- Handles all repair menu UI modifications.
--- Manages unified repair list with damaged items (from vanilla) and fully-repaired items (for enhancement).
local RepairMenuUI = {}

local config = require("mer.RealisticRepair.config")
local RepairService = require("mer.RealisticRepair.services.RepairService")
local StationService = require("mer.RealisticRepair.services.StationService")
local ConditionBarRenderer = require("mer.RealisticRepair.ui.ConditionBarRenderer")
local logger = mwse.Logger.new{
    logLevel = config.mcm.logLevel,
}

---Find the MenuRepair_Object property in a button element
---@param parentElement tes3uiElement
---@return tes3uiElement? button
---@return tes3itemStack? stack
local function findMenuRepairObject(parentElement)
    local obj = parentElement:getPropertyObject("MenuRepair_Object", "tes3itemStack")
    if obj then
        return parentElement, obj
    end

    for child in table.traverse{parentElement} do
        child = child --[[@as tes3uiElement]]
        obj = child:getPropertyObject("MenuRepair_Object", "tes3itemStack")
        if obj then
            return child, obj
        end
    end
end

---Add condition bars to a repair menu button
---@param buttonParent tes3uiElement
---@param item tes3weapon|tes3armor
---@param itemData tes3itemData
local function addConditionBars(buttonParent, item, itemData)
    local degradationFraction, enhancementFraction = RepairService.getConditionBarFractions(item, itemData)

    local fillbar = buttonParent:findChild("PartFillbar_colorbar_ptr")
    if fillbar and fillbar.parent then
        ConditionBarRenderer.createOrUpdateConditionBars(
            fillbar.parent,
            degradationFraction,
            enhancementFraction,
            true  -- isRepairMenu
        )
    end
end

-- Get all enhanceable items from player inventory
---@return table enhanceable List of {object, itemData} pairs that can be enhanced
---@return table nonEnhanceable List of {object, itemData} pairs at cap
local function getEnhanceableItems()
    local enhancable = {}
    local nonEnhancable = {}

    for _, stack in pairs(tes3.player.object.inventory) do
        local isRepairableObject = RepairService.isEnhanceableObject(stack.object)
        if isRepairableObject then
            -- Non-itemData instances (pristine items)
            local nonStackCount = stack.count - (stack.variables and #stack.variables or 0)
            if nonStackCount > 0 then
                local canEnhance = RepairService.canBeEnhanced(stack.object, nil)
                if canEnhance then
                    table.insert(enhancable, { object = stack.object, itemData = nil })
                else
                    table.insert(nonEnhancable, { object = stack.object, itemData = nil })
                end
            end
            -- ItemData instances
            if stack.variables then
                for _, itemData in pairs(stack.variables) do
                    if RepairService.isPristine(stack.object, itemData) then
                        local canEnhance = RepairService.canBeEnhanced(stack.object, itemData)
                        if canEnhance then
                            table.insert(enhancable, { object = stack.object, itemData = itemData })
                        else
                            table.insert(nonEnhancable, { object = stack.object, itemData = itemData })
                        end
                    end
                end
            end
        end
    end

    return enhancable, nonEnhancable
end

-- Populate enhancement list with all enhanceable items
---@param enhancementList tes3uiElement
local function populateEnhancementList(enhancementList)
    local contentPane = enhancementList:getContentElement()

    -- Clear existing rows
    for _, child in ipairs(contentPane.children) do
        child:destroy()
    end

    local enhancable, nonEnhancable = getEnhanceableItems()

    -- Add enhancable first, then non-enhancable at bottom
    for _, entry in ipairs(enhancable) do
        RepairMenuUI.createEnhancementRow(enhancementList, entry.object, entry.itemData)
    end
    for _, entry in ipairs(nonEnhancable) do
        RepairMenuUI.createEnhancementRow(enhancementList, entry.object, entry.itemData)
    end
end

-- Toggle between repair and enhancement lists
---@param menu tes3uiElement
local function toggleRepairEnhancementLists(menu)
    local repairList = menu:findChild("MenuRepair_ServiceList")
    local enhancementList = menu:findChild("MenuRepair_EnhancementList")
    local toggleButton = menu:findChild("MenuRepair_ToggleButton")
    local modeLabel = menu:findChild("MenuRepair_ModeLabel")

    if not repairList or not enhancementList or not toggleButton then
        return
    end

    -- Toggle visibility
    repairList.visible = not repairList.visible
    enhancementList.visible = not enhancementList.visible

    -- Save state for menu reopening
    tes3.player.tempData.repairMenuShowingEnhancements = enhancementList.visible

    -- Update button text
    if repairList.visible then
        toggleButton.text = "Switch to Enhance"
        if modeLabel then
            modeLabel.text = "Repair"
        end
    else
        toggleButton.text = "Switch to Repair"
        if modeLabel then
            modeLabel.text = "Enhance"
        end
    end

    menu:updateLayout()
end

-- Update/ensure condition bars on vanilla repair list buttons
---@param contentPane tes3uiElement
local function updateConditionBarsOnList(contentPane)
    for _, buttonParent in ipairs(contentPane.children) do
        local _, stack = findMenuRepairObject(buttonParent)
        if stack then
            -- Use the same logic as addConditionBars so it handles both itemData and non-itemData cases
            addConditionBars(buttonParent, stack.object, stack.variables and stack.variables[1])
        end
    end
end

---Setup repair menu UI with separate repair and enhancement lists
---@param menu tes3uiElement
function RepairMenuUI.setupUnifiedMenu(menu)
    logger:debug("Setting up repair menu UI with separate lists")

    local repairList = menu:findChild("MenuRepair_ServiceList")
    if not repairList then
        logger:warn("MenuRepair_ServiceList not found")
        return
    end

    -- Setup vanilla repair buttons with condition bars
    local buttonList = repairList:getContentElement()
    updateConditionBarsOnList(buttonList)

    -- Create enhancement list if at station and enhancement is enabled
    if StationService.isRepairMenuAtStation() and config.mcm.enableEnhancement then
        -- Check if we should restore enhancement view
        local showEnhancements = tes3.player.tempData.repairMenuShowingEnhancements or false

        -- Create label showing current mode above the lists
        local titleLayout = menu:findChild("title layout")
        if titleLayout then
            local labelBlock = menu:createBlock()
            labelBlock.widthProportional = 1.0
            labelBlock.autoHeight = true
            labelBlock.childAlignX = 0.5
            labelBlock.borderBottom = 4
            labelBlock:reorder{ before = titleLayout }

            local modeLabel = labelBlock:createLabel{
                id = "MenuRepair_ModeLabel",
                text = showEnhancements and "Enhance" or "Repair"
            }
            modeLabel.color = tes3ui.getPalette("header_color")
        end

        -- Create toggle button at the bottom, before OK button
        local okButton = menu:findChild("MenuRepair_Okbutton")
        if okButton and okButton.parent then
            local toggleButton = okButton.parent:createButton{
                id = "MenuRepair_ToggleButton",
                text = showEnhancements and "Switch to Repair" or "Switch to Enhance"
            }
            toggleButton:reorder{ before = okButton }
            toggleButton:register("mouseClick", function()
                toggleRepairEnhancementLists(menu)
            end)
        end

        -- Create enhancement list (copy structure from repair list)
        local enhancementList = menu:createVerticalScrollPane{
            id = "MenuRepair_EnhancementList"
        }
        enhancementList.widthProportional = 1.0
        enhancementList.heightProportional = 1.0
        enhancementList.visible = showEnhancements  -- Restore previous state

        -- Set repair list visibility based on enhancement list
        repairList.visible = not showEnhancements

        -- Populate enhancement list
        populateEnhancementList(enhancementList)
        -- Position it after repair list in layout
        enhancementList:reorder{
            before = repairList
        }
    end

    menu:updateLayout()
end

--[[
    Enhancement row structure (in MenuRepair_EnhancementList):
    outerBlock (flow: top_to_bottom)
        -> label (item name)
        -> innerBlock (flow: left_to_right)
            -> 32x32 icon with callback to enhance, and objectTooltip
            -> fillbar with condition (which will always be 100%), and enhancement overlay
---]]
---@param enhancementList tes3uiElement The MenuRepair_EnhancementList to append to
---@param item tes3weapon|tes3armor
---@param itemData tes3itemData|nil
function RepairMenuUI.createEnhancementRow(enhancementList, item, itemData)
    local contentPane = enhancementList:getContentElement()

    local row = contentPane:createBlock{}
    row.widthProportional = 1.0
    row.autoHeight = true
    row.paddingAllSides = 4
    row.borderBottom = 4
    row.flowDirection = "top_to_bottom"

    -- Item name label
    row:createLabel{ text = item.name }

    -- Inner block for icon and fillbar
    local innerBlock = row:createBlock{}
    innerBlock.widthProportional = 1.0
    innerBlock.autoHeight = true
    innerBlock.flowDirection = "left_to_right"

    -- Icon
    local icon = innerBlock:createImage{ id = "Icon_" .. item.id, path = "icons/" .. item.icon }
    icon.width = 32
    icon.height = 32
    icon.borderRight = 20
    icon:register("mouseClick", function()
        local repairTool, repairToolData = RepairService.getRepairMenuItemAndData()
        if repairToolData == nil or repairToolData.condition <= 0 then
            logger:debug("Cannot enhance item %s: repair tool %s is depleted",
                item.name, repairTool and repairTool.name or "unknown")
            return
        end

        --if fatigue cost active, check if player has any fatigue
        local currentFatigue = tes3.mobilePlayer.fatigue.current
        if config.mcm.enableFatigueCost and currentFatigue <= 0 then
            logger:debug("Cannot enhance item %s: player has no fatigue", item.name)
            tes3.messageBox("You are too fatigued to enhance items.")
            return
        end


        logger:debug("Enhancement attempt for %s", item.name)
        local success, message = RepairService.handleEnhancementAttempt(item, itemData)
        if success then
            tes3.messageBox("Enhancement Successful: %s", message)
        else
            tes3.messageBox("Enhancement Failed: %s", message)
        end



        -- Refresh UI
        local repairMenu = tes3ui.findMenu("MenuRepair")
        if repairMenu then
            RepairMenuUI.refreshMenu(repairMenu)
        end
    end)

    icon:register("help", function()
        tes3ui.createTooltipMenu{
            object = item,
            itemData = itemData,
        }
    end)

    -- Fillbar
    local currentCondition = itemData and itemData.condition or item.maxCondition
    local fillbar = innerBlock:createFillBar{
        id = "RealisticRepair_EnhancementFillbar",
        current = currentCondition,
        max = item.maxCondition,
    }
    fillbar.widthProportional = 1.0
    fillbar.height = 20
    fillbar.borderTop = 6

    addConditionBars(innerBlock, item, itemData)
end

---Initialize repair menu UI
---@param menu tes3uiElement
function RepairMenuUI.initializeMenu(menu)
    logger:debug("Initializing repair menu UI")

    -- Setup unified menu (damaged items + fully-repaired items)
    RepairMenuUI.setupUnifiedMenu(menu)
end

---Refresh the repair menu after a repair/enhancement attempt
---@param menu tes3uiElement
function RepairMenuUI.refreshMenu(menu)
    logger:debug("Refreshing repair menu UI")

    local repairList = menu:findChild("MenuRepair_ServiceList")
    if not repairList then
        return
    end

    -- Update condition bars on vanilla repair buttons
    local contentPane = repairList:getContentElement()
    updateConditionBarsOnList(contentPane)

    -- Refresh enhancement list if it exists
    local enhancementList = menu:findChild("MenuRepair_EnhancementList")
    if enhancementList then
        populateEnhancementList(enhancementList)
    end

    menu:updateLayout()
end



return RepairMenuUI
