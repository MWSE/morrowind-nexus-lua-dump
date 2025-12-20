local config = require("mer.RealisticRepair.config")
local maxConditionEffect = require("mer.RealisticRepair.maxConditionEffect")
local logger = mwse.Logger.new()

local function getEnabled()
    return config.mcm.enableRealisticRepair
        and config.mcm.enableDegradation
end

local function repairButtonOverride(stack)
    local doDisable = maxConditionEffect.doBlockRepair(stack)
    local degradationAmount = maxConditionEffect.calculateDegradationAmount()
    -- Allow repair if degradation can be reduced (negative degradation at high skill)
    if doDisable and degradationAmount >= 0 then
        tes3.messageBox("This item cannot be repaired further.")
        --menu click
        tes3.playSound{ reference = tes3.player, sound = "Menu Click" }
        return false
    end
end

--Override repair buttons to block if max condition reached
event.register("uiActivated", function(e)
    if not getEnabled() then return end

    logger:debug("MenuRepair entered, checking for disabled items.")

    --Disable buttons if condition is maxed
    local buttonList = e.element:findChild("MenuRepair_ServiceList"):getContentElement()
    for _, buttonParent in ipairs(buttonList.children) do
        local button, stack = maxConditionEffect.findMenuRepairObject(buttonParent)
        if button and stack then
            button:registerBefore("mouseClick", function()
                return repairButtonOverride(stack)
            end)
            local fillbar = buttonParent:findChild("PartFillbar_colorbar_ptr").parent
            local degradationFraction = maxConditionEffect.getDegradationFraction(stack.object, stack.variables[1])
            maxConditionEffect.createRepairMenuDegradationBar(fillbar, degradationFraction)
            e.element:updateLayout()
        end
    end

    maxConditionEffect.addDegradePerFailureLabel(e.element)

end, { filter = "MenuRepair", priority = -100})

---@param stack tes3itemStack
local function serviceRepairButtonOverride(stack)
    logger:debug("Service repair button clicked for item: %s", stack.object.name)
    if #stack.variables >= 1 then
        logger:debug("Removing degradation level after service repair.")
        stack.variables[1].data.degradationLevel = nil
    else
        logger:debug("No item variables found on stack after service repair.")
    end
end

--Override service repair button, to remove degradation after repairing
event.register("uiActivated", function(e)
    if not getEnabled() then return end
    logger:debug("MenuServiceRepair entered, overriding service repair buttons.")

    local buttonList = e.element:findChild("MenuServiceRepair_ServiceList"):getContentElement()
    for _, button in ipairs(buttonList.children) do
        logger:debug("Overriding service repair button: %s", button.text)
        local stack = button:getPropertyObject("MenuServiceRepair_Object", "tes3itemStack")
        if stack then
            logger:debug("Found stack for service repair button: %s", stack.object.name)
            button:registerBefore("mouseClick", function()
                return serviceRepairButtonOverride(stack)
            end)
        else
            logger:debug("Could not find stack for service repair button.")
        end
    end

    maxConditionEffect.addDegradePerFailureLabel(e.element)

end, { filter = "MenuServiceRepair", priority = -100})


--When failing a repair attempt, degrade the item (direct repair)
--When using a station, apply degradation/restoration based on success
event.register("repair", function(e)
    if not getEnabled() then return end
    logger:debug("Repair event detected for item: %s", e.item.name)

    local isAtStation = tes3.player.tempData.realisticRepairAtStation or false
    local degradationAmount = maxConditionEffect.calculateDegradationAmount()

    local currentCondition = e.itemData and e.itemData.condition or e.item.maxCondition
    local maxRepairCondition = maxConditionEffect.getMaxRepairCondition(e.item, e.itemData)
    if degradationAmount < 0 then
        maxRepairCondition = maxRepairCondition - degradationAmount
    end
    local maxRepairAmount = maxRepairCondition - currentCondition
    local initialRepairAmount = e.repairAmount
    local actualRepairAmount = math.min(initialRepairAmount, maxRepairAmount)

    e.repairAmount = actualRepairAmount

    local failed = e.roll >= e.chance
    local shouldApplyDegradation = false

    -- At stations: apply degradation on failure, restoration on success
    if failed and degradationAmount > 0 then
        shouldApplyDegradation = true
    elseif not failed and degradationAmount < 0 then
        shouldApplyDegradation = true
    end

    if shouldApplyDegradation then
        maxConditionEffect.degradeItem(e.item, e.itemData, degradationAmount)
        -- refresh the repair menu UI
        local repairMenu = tes3ui.findMenu("MenuRepair")
        if repairMenu then
            local buttonList = repairMenu:findChild("MenuRepair_ServiceList"):getContentElement()
            for _, buttonParent in pairs(buttonList.children) do
                local _, stack = maxConditionEffect.findMenuRepairObject(buttonParent)
                if stack and stack.variables and #stack.variables > 0 then
                    local conditionBar = buttonParent:findChild("PartFillbar_colorbar_ptr").parent
                    local degradationFraction = maxConditionEffect.getDegradationFraction(stack.object, stack.variables[1])
                    maxConditionEffect.updateDegradationBar(conditionBar, degradationFraction)
                end
            end
        end
    end
end)

--Update the itemtooltip to show degradation level as a grey bar covering condition bar
event.register("uiObjectTooltip", function(e)
    if not getEnabled() then return end
    if not e.itemData then return end
    local isGear = e.object.objectType == tes3.objectType.weapon
        or e.object.objectType == tes3.objectType.armor
    if not isGear then
        return
    end
    local degradationLevel = e.itemData.data and e.itemData.data.degradationLevel or 0
    if degradationLevel <= 0 then return end

    local degradationFraction = maxConditionEffect.getDegradationFraction(e.object, e.itemData)
    local conditionBlock = e.tooltip:findChild("HelpMenu_qualityCondition") --[[@as tes3uiElement]]
    local conditionBar = conditionBlock.children[1]
    if conditionBar then
        maxConditionEffect.createTooltipDegradationBar(conditionBar, degradationFraction)
    else
        logger:debug("Could not find condition bar in tooltip for %s", e.object.name)
    end

    --Add degradation amount to tooltip text
    local degradationText = string.format("Degradation: %d", degradationLevel)
    local label = e.tooltip:createLabel({ text = degradationText })
    label:reorder{ before = conditionBlock }

end, { priority = -100 })






