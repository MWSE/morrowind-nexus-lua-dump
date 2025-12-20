---@class RealisticRepair.MaxConditionEffect
local MaxConditionEffect = {}
local logger = mwse.Logger.new()
local config = require("mer.RealisticRepair.config")

---Get the max condition level that can be achieved through repair
---@param item tes3weapon|tes3armor
---@param itemData tes3itemData|nil
function MaxConditionEffect.getMaxRepairCondition(item, itemData)
    local maxCondition = item.maxCondition
    if not itemData then
        return maxCondition
    end

    local degradationLevel = itemData.data and itemData.data.degradationLevel or 0
    return math.max(1, maxCondition - degradationLevel)
end

function MaxConditionEffect.calculateDegradationAmount()
    local isAtStation = tes3.player.tempData.realisticRepairAtStation or false
    local armorerSkill = tes3.mobilePlayer:getSkillStatistic(tes3.skill.armorer).current
    local min = config.mcm.minDegradation
    local max = config.mcm.maxDegradation
    local degradationAmount = math.remap(armorerSkill, 0, 100, max, min)
    degradationAmount = math.clamp(degradationAmount, min, max)
    if isAtStation then
        -- At stations: degradation reduced by stationDegradeReduction, can go negative to restore
        local stationReduction = config.mcm.stationDegradeReduction or 0
        degradationAmount = degradationAmount - stationReduction
    end
    degradationAmount = math.floor(degradationAmount)

    return degradationAmount
end


---Degrade an item, reducing its max condition for future repairs
---@param item tes3weapon|tes3armor
---@param itemData tes3itemData
---@param degradeAmount number Amount to degrade by
function MaxConditionEffect.degradeItem(item, itemData, degradeAmount)
    if not itemData then
        itemData = tes3.addItemData{
            to = tes3.player,
            item = item,
        }
    end
    itemData.data = itemData.data or {}

    local currentCondition = itemData.condition or item.maxCondition
    local maxDegradation = item.maxCondition - currentCondition
    local currentDegradation = itemData.data.degradationLevel or 0
    local newDegradation = currentDegradation + degradeAmount
    -- Clamp between 0 and maxDegradation to prevent negative degradation
    newDegradation = math.clamp(newDegradation, 0, maxDegradation)
    if newDegradation > 0 then
        itemData.data.degradationLevel = newDegradation
    else
        itemData.data.degradationLevel = nil
    end
end

---Check if an item stack should be blocked from
--- repair attempts as a result of max condition
---@param itemStack tes3itemStack
function MaxConditionEffect.doBlockRepair(itemStack)
    local item = itemStack.object
    local itemDataList = itemStack.variables
    if not itemDataList then
        return false
    end
    --if at least one item can be repaired, allow repair
    for _, itemData in pairs(itemDataList) do
        local maxRepairCondition = MaxConditionEffect.getMaxRepairCondition(item, itemData)
        if itemData.condition < maxRepairCondition then
            return false
        end
    end
    --all items at max condition, block repair
    return true
end

function MaxConditionEffect.getDegradationFraction(item, itemData)
    local maxCondition = item.maxCondition
    local maxRepairCondition = MaxConditionEffect.getMaxRepairCondition(item, itemData)
    local degradationLevel = maxCondition - maxRepairCondition
    return degradationLevel / maxCondition
end


---@return tes3uiElement?, tes3itemStack?
function MaxConditionEffect.findMenuRepairObject(parentElement)
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


---@param conditionBar tes3uiElement
---@param degradationFraction number
function MaxConditionEffect.createRepairMenuDegradationBar(conditionBar, degradationFraction)
    logger:debug("Creating degradation bar with fraction %s", degradationFraction)
    local conditionFillBar = conditionBar and conditionBar:findChild("PartFillbar_colorbar_ptr")
    if not conditionFillBar then
        logger:debug("Could not find condition fill bar in condition bar")
        return
    end

    conditionBar.widthProportional = 1.0
    conditionBar:updateLayout()

    logger:debug("conditionBar.width: %s", conditionBar.width)
    local barWidth = math.ceil(conditionBar.width - (conditionFillBar.borderAllSides * 2))
    logger:debug("barWidth: %s", barWidth)
    local degradeBarWidth = math.ceil(barWidth * degradationFraction)
    logger:debug("degradeBarWidth: %s", degradeBarWidth)
    local degradeBar = conditionBar.parent:createRect{
        id = "RealisticRepair_degradeBar",
        color = {0.2, 0.2, 0.2, 0.7},
    }
    degradeBar.width = 294 * degradationFraction
    degradeBar.height = conditionFillBar.height
    degradeBar.absolutePosAlignX = 1.0
    degradeBar.absolutePosAlignY = 0.5
    degradeBar.borderRight = 2

    local parent = conditionBar.parent
    parent:reorderChildren(parent.children[1], degradeBar, 1)
    conditionBar.imageScaleX = 0.5
    conditionBar.imageScaleX = 0.0
end


---@param conditionBar tes3uiElement
---@param degradationFraction number
function MaxConditionEffect.createTooltipDegradationBar(conditionBar, degradationFraction)
    logger:debug("Creating degradation bar with fraction %s", degradationFraction)
    local conditionFillBar = conditionBar and conditionBar:findChild("PartFillbar_colorbar_ptr")
    if not conditionFillBar then
        logger:debug("Could not find condition fill bar in condition bar")
        return
    end


    local degradeBar = conditionBar.parent:createRect{
        id = "RealisticRepair_degradeBar",
        color = {0.2, 0.2, 0.2, 0.7},
    }


    local barWidth = math.ceil(conditionBar.width - (conditionFillBar.borderAllSides * 2))
    local degradeBarWidth = math.ceil(barWidth * degradationFraction)
    degradeBar.width = degradeBarWidth
    degradeBar.height = conditionFillBar.height
    degradeBar.absolutePosAlignX = 1.0
    degradeBar.absolutePosAlignY = 0.5
    degradeBar.borderRight = 4

    local parent = conditionBar.parent
    parent:reorderChildren(parent.children[1], degradeBar, 1)
    conditionBar.imageScaleX = 0.5
    conditionBar.imageScaleX = 0.0
end




--Update the degradation bar width
function MaxConditionEffect.updateDegradationBar(conditionBar, degradationFraction)
    local degradeBar = conditionBar and conditionBar.parent:findChild("RealisticRepair_degradeBar")
    if degradeBar then
        logger:debug("Updating degradation bar with fraction %s", degradationFraction)
        local conditionFillBar = conditionBar:findChild("PartFillbar_colorbar_ptr")
        local barWidth = math.ceil(conditionBar.width - (conditionFillBar.borderAllSides * 2))
        local degradeBarWidth = math.ceil(barWidth * degradationFraction)
        degradeBar.width = degradeBarWidth
    else
        logger:debug("Could not find degradation bar to update")
    end
end

---Add a label to the repair menu showing degrade amount per failure
---@param menu tes3uiElement
function MaxConditionEffect.addDegradePerFailureLabel(menu)
    local degradeAmount = MaxConditionEffect.calculateDegradationAmount()
    local message = degradeAmount >= 0 and
        "Degradation on Failure: %d" or
        "Restoration on Success: %d"
    local label = menu:createLabel{ text = string.format(message, math.abs(degradeAmount)) }
    label.borderBottom = 6
    label.autoHeight = true
    label.widthProportional = 1.0
    label.wrapText = true
    label.justifyText = "center"
    label:reorder{ after = menu:getContentElement().children[1] }
    menu:updateLayout()
end

return MaxConditionEffect