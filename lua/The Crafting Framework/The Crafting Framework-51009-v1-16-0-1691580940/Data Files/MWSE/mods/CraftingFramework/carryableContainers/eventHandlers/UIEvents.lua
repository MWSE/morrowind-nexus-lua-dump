local util = require("CraftingFramework.util.Util")
local logger = util.createLogger("UIEvents")
local CarryableContainer = require("CraftingFramework.carryableContainers.components.CarryableContainer")
local Container = require("CraftingFramework.carryableContainers.components.Container")

---@param e uiActivatedEventData
local function onUiActivated(e)
    logger:debug("uiActivated")
    local miscId = Container.getOpenContainerMiscId(e.element)
    if not miscId then return end
    local miscObject = tes3.getObject(miscId) --[[@as tes3misc]]
    if not miscObject then return end
    local menu = e.element
    local carryable = CarryableContainer:new{
        item = miscObject
    }
    if not carryable then return end
    logger:debug("We are in a carryable container inventory, miscRef ID: %s", miscId)
    if e.newlyCreated then
        Container.addButtons(menu, carryable)
    end
end
event.register(tes3.event.uiActivated, onUiActivated)


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

    --Display Weight Modifier
    local weightModifier = carryable:getWeightModifier()
    if weightModifier then
        local weightModifierLabel = e.tooltip:createLabel{
            text = string.format("Weight Modifier: %.1f", weightModifier)
        }
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