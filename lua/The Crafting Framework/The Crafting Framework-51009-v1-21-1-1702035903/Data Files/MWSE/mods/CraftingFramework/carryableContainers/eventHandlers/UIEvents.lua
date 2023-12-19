local util = require("CraftingFramework.util.Util")
local logger = util.createLogger("UIEvents")
local CarryableContainer = require("CraftingFramework.carryableContainers.components.CarryableContainer")
local Container = require("CraftingFramework.carryableContainers.components.Container")
local Craftable = require("CraftingFramework.components.Craftable")

local function getCarryableFromMenu(menu)
    local miscId = Container.getOpenContainerMiscId(menu)
    if not miscId then return nil end
    local miscObject = tes3.getObject(miscId) --[[@as tes3misc]]
    if not miscObject then return nil end
    local carryable = CarryableContainer:new{
        item = miscObject
    }
    return carryable
end


--Add buttons to the container menu.
-- This can happen for carryable containers or
-- for containers that are crafted
---@param e uiActivatedEventData
local function onContentsMenuActivated(e)
    local reference = Container.getMenuReference(e.element)
    if not reference then return end
    if not e.element.name == "MenuContents" then return end

    --Carryable Containers
    local carryable = getCarryableFromMenu(e.element)
    if carryable then
        logger:debug("We are in a carryable container inventory")
        Container.addCarryableButtonsToMenu{ menu = e.element, carryable = carryable}
        return
    end

    --Crafted Containers
    local isContainer = reference.object.objectType == tes3.objectType.container
    local craftable = Craftable.getCraftable(reference.baseObject.id)
    if craftable and isContainer then
        logger:debug("We are in a crafted container inventory")
        Container.addCraftableButtonsToMenu{
            menu = e.element,
            craftable = craftable,
            reference = reference
        }
        return
    end
end
event.register(tes3.event.uiActivated, onContentsMenuActivated)


---@param e uiObjectTooltipEventData
local function onTooltip(e)
    logger:trace("onTooltip()")

    local carryable
    if e.reference then
        carryable = CarryableContainer:new{
            containerRef = e.reference,
        }
    end
    if not carryable then
        carryable = CarryableContainer:new{
            item = e.object,
            itemData = e.itemData,
            reference = e.reference,
        }
    end
    if not carryable then return end

    --Display filter
    local filterText = "Container"
    local filter = carryable:getFilter()
    if filter then
        filterText = filter.name .. " Container"
    end
    local filterLabel = e.tooltip:createLabel{
        text = filterText
    }
    filterLabel.borderLeft = 10
    filterLabel.borderRight = 10
    filterLabel.borderBottom = 10



    --Display optional tooltip
    if carryable.containerConfig.getTooltip then
        local tooltipText = carryable.containerConfig.getTooltip(carryable)
        local tooltipLabel = e.tooltip:createLabel{
            text = tooltipText
        }
        tooltipLabel.borderLeft = 10
        tooltipLabel.borderRight = 10
        tooltipLabel.borderBottom = 10
    end

    if tes3ui.menuMode() then
        --Display "Shift + click to open" tooltip
        local key = util.getQuickModifierKeyText()
        local tooltipText = string.format("%s + click to open", key)
        local tooltipLabel = e.tooltip:createLabel{
            text = tooltipText
        }
        tooltipLabel.borderLeft = 10
        tooltipLabel.borderRight = 10
        tooltipLabel.borderBottom = 10
    end

    --Display Weight Modifier
    local weightModifier = carryable:getWeightModifier()
    if weightModifier then
        local weightModifierText
        if carryable.containerConfig.getWeightModifierText then
            weightModifierText = carryable.containerConfig.getWeightModifierText(carryable)
        else
            weightModifierText = string.format("Weight Modifier: %.1fx", weightModifier)
        end
        local weightModifierLabel = e.tooltip:createLabel{ text = weightModifierText }
        weightModifierLabel.borderLeft = 10
        weightModifierLabel.borderRight = 10
        weightModifierLabel.borderBottom = 10
    end

    --Display current/max weight
    local containerRef = carryable:getContainerRef()
    local currentWeight
    local maxWeight
    if containerRef then
        currentWeight = carryable:calculateWeight()
        maxWeight = containerRef.object.capacity
    else
        currentWeight = 0
        maxWeight = carryable:calculateCapacity()
    end
    if maxWeight < 9998 then
        local fillbar = e.tooltip:createFillBar{
            current = currentWeight,
            max = maxWeight
        }
        fillbar.borderBottom = 10
        fillbar.borderLeft = 10
        fillbar.borderRight = 10
    end
end
event.register(tes3.event.uiObjectTooltip, onTooltip)