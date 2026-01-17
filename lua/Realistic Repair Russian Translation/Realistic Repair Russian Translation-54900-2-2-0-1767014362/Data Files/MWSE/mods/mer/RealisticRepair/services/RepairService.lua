---@class RealisticRepair.RepairService
--- Orchestrates repair and enhancement mechanics.
--- Coordinates between ItemConditionService, RepairCalculationService, and StationService.
local RepairService = {}

local config = require("mer.RealisticRepair.config")
local RepairCost = require("mer.RealisticRepair.services.repairCost")
local ItemConditionService = require("mer.RealisticRepair.services.ItemConditionService")
local RepairCalculationService = require("mer.RealisticRepair.services.RepairCalculationService")
local StationService = require("mer.RealisticRepair.services.StationService")

local logger = mwse.Logger.new{
    logLevel = config.mcm.logLevel,
}
---Check if degradation system is enabled
---@return boolean
local function isDegradationEnabled()
    return config.mcm.enableRealisticRepair and config.mcm.enableDegradation
end

---Check if enhancement system is enabled
---@return boolean
local function isEnhancementEnabled()
    return config.mcm.enableRealisticRepair
        and config.mcm.enableEnhancement
        and config.mcm.enableStations
end

---Handle a repair attempt event
---@param e repairEventData
function RepairService.handleRepairAttempt(e)
    if not isDegradationEnabled() then
        return
    end

    logger:debug("Handling repair attempt for %s", e.item.name)
    local isAtStation = StationService.isRepairMenuAtStation()

    -- Apply station chance modifier if at a station
    if isAtStation then
        e.chance = math.min(100, e.chance + config.mcm.stationChanceModifier)
        logger:debug("Station bonus applied, new chance: %d", e.chance)
    end

    -- Determine if repair succeeded (roll must be LESS than chance to succeed)
    local repairSucceeded = e.roll < e.chance

    logger:debug("Repair roll: %d vs chance: %d, success: %s", e.roll, e.chance, tostring(repairSucceeded))

    -- Use automatic repair handler
    local newItemData, message = RepairService.handleAutomaticRepair(
        e.item,
        e.itemData,
        repairSucceeded,
        isAtStation,
        e.repairAmount
    )

    -- Update itemData reference
    e.itemData = newItemData

    -- Calculate and cap the repair amount based on new state
    local currentCondition = e.itemData and e.itemData.condition or e.item.maxCondition
    local maxRepairCondition = ItemConditionService.getMaxRepairCondition(e.item, e.itemData)
    local maxRepairAmount = maxRepairCondition - currentCondition
    local actualRepairAmount = math.min(e.repairAmount, maxRepairAmount)
    actualRepairAmount = math.max(0, actualRepairAmount)

    -- Update the repair amount
    e.repairAmount = actualRepairAmount

    RepairCost.handleTimeCost()
    RepairCost.handleFatigueCost()
    RepairService.checkFatigueAfterAttempt()
    logger:debug("Repair result: %s (actualRepair=%d)", message, actualRepairAmount)
end

---Reduce a repair tool condition
---@param repairTool tes3repairTool
---@param repairToolData tes3itemData?
---@return number newCondition The new condition of the repair tool
function RepairService.reduceRepairToolCondition(repairTool, repairToolData)
    ---add item data if missing
    repairToolData = ItemConditionService.ensureItemData(repairTool, repairToolData)
    repairToolData.condition = math.max(0, repairToolData.condition - 1)

    logger:debug("Reduced repair tool condition by %d. New condition: %d",
        1, repairToolData.condition)

    local newCondition = repairToolData.condition
    if newCondition <= 0 then
        tes3.removeItem{
            reference = tes3.player,
            item = repairTool,
            itemData = repairToolData,
            count = 1
        }
    end
    return newCondition
end

--Get the repairItem object and itemData from the repair menu
---@return tes3repairTool|nil, tes3itemData|nil
function RepairService.getRepairMenuItemAndData()
    local repairMenu = tes3ui.findMenu("MenuRepair")
    if not repairMenu then
        logger:warn("Repair menu not found when getting repair tool")
        return nil, nil
    end

    local item = repairMenu:getPropertyObject("MenuRepair_Object")
    local itemData = repairMenu:getPropertyObject("MenuRepair_extra", "tes3itemData")

    return item, itemData
end

---@param repairTool tes3repairTool
function RepairService.calculateEnhancementSuccessChance(repairTool)
    local armorerSkill = tes3.mobilePlayer:getSkillValue(tes3.skill.armorer)
    local minChance = config.mcm.minEnhancementChance
    local maxChance = config.mcm.maxEnhancementChance

    local chance = math.remap(armorerSkill, 0, 100, minChance, maxChance) * repairTool.quality
    chance = math.clamp(math.floor(chance), minChance, maxChance)

    logger:debug("Enhancement success chance based on Armorer skill %d: %d%%",
        armorerSkill, chance)
    return chance
end

function RepairService.isPristine(item, itemData)
    -- Fully repaired
    if not ItemConditionService.isFullyRepaired(item, itemData) then
        return false
    end

    -- No degradation
    if ItemConditionService.hasDegradation(itemData) then
        return false
    end

    return true
end

---Check if an item can be enhanced
---Requirements: fully repaired, at station, no existing degradation
---@param item tes3weapon|tes3armor
---@param itemData tes3itemData?
---@return boolean canEnhance
---@return string? reason Why enhancement is blocked (if false)
function RepairService.canBeEnhanced(item, itemData)
    if not RepairService.isPristine(item, itemData) then
        return false, "Предмет должен быть полностью отремонтирован и не иметь деградации"
    end

    --Enhance cap reached
    local currentEnhancement = ItemConditionService.getEnhancementLevel(item, itemData)
    local enhancementCap = RepairCalculationService.getEnhancementCap(item)
    if currentEnhancement >= enhancementCap then
        return false, "Достигнут предел усиления"
    end

    return true
end

function RepairService.updateRepairUsesText(conditionAmount)
    local repairMenu = tes3ui.findMenu("MenuRepair")
    if not repairMenu then
        logger:warn("Repair menu not found when updating repair uses text")
        return
    end

    --Label should say "Uses 10"
    local usesLabel = repairMenu:findChild("MenuRepair_uses")
    if not usesLabel then
        logger:warn("Uses label not found in repair menu")
        return
    end

    --Replace the number with conditionAmount
    --Don't replace "Uses" for i8n compatibility
    usesLabel.text = string.format("Зарядов %d", conditionAmount)
    logger:debug("Updated repair uses text to: %s", usesLabel.text)
end

function RepairService.swapToNextRepairTool(currentTool)
    if not currentTool then
        logger:warn("No current repair tool found when swapping to next tool")
        return false
    end

    logger:debug("Swapping to next repair tool after %s is depleted", currentTool.name)

    -- Find next repair tool in inventory
    local nextToolStack = nil
    for _, stack in pairs(tes3.player.object.inventory) do
        if stack.object == currentTool then
            -- Check if there are any with itemData that have condition > 0
            if stack.variables then
                for _, itemData in pairs(stack.variables) do
                    if itemData.condition > 0 then
                        nextToolStack = { object = stack.object, itemData = itemData }
                        break
                    end
                end
            end

            -- If no itemData instances, check if there are non-itemData instances
            if not nextToolStack then
                local nonStackCount = stack.count - (stack.variables and #stack.variables or 0)
                if nonStackCount > 0 then
                    -- Create itemData for a pristine instance
                    local newItemData = tes3.addItemData{
                        to = tes3.player,
                        item = currentTool
                    }
                    nextToolStack = { object = stack.object, itemData = newItemData }
                end
            end
            break
        end
    end

    if not nextToolStack then
        logger:debug("No more repair tools of type %s available", currentTool.name)
        return false
    end

    -- Update the repair menu's repair tool
    local repairMenu = tes3ui.findMenu("MenuRepair")
    if not repairMenu then
        logger:warn("Repair menu not found when swapping repair tool")
        return false
    end

    repairMenu:setPropertyObject("MenuRepair_Object", nextToolStack.object)
    repairMenu:setPropertyObject("MenuRepair_extra", nextToolStack.itemData)

    -- Update the uses text
    RepairService.updateRepairUsesText(nextToolStack.itemData.condition)

    logger:debug("Swapped to next repair tool with condition %d", nextToolStack.itemData.condition)
    return true
end

function RepairService.hideTitle(repairMenu)
    if not repairMenu then
        logger:warn("Repair menu not found when hiding title")
        return
    end

    local titleLayout = repairMenu:findChild("title layout")
    if titleLayout then
        titleLayout.visible = false
        logger:debug("Hid repair menu title layout")
    else
        logger:warn("Could not find title layout to hide")
    end
end

---@param repairMenu tes3uiElement
function RepairService.blockRepairButtons(repairMenu, message)
    local repairList = repairMenu:findChild("MenuRepair_ServiceList")
    local contentPane = repairList and repairList:getContentElement()
    if not contentPane then
        logger:warn("Could not find repair service list content pane to block buttons")
        return
    end
    logger:debug("Blocking repair buttons in repair menu")
    for _, block in ipairs(contentPane.children) do
        local icon = block:findChild("MenuRepair_EntryIcon")
        if not icon then
            logger:warn("Could not find repair button icon to block")
            return
        end
        logger:debug("Blocking repair button: %s", icon.text)
        icon:register("mouseClick", function()
            if message then
                tes3.messageBox(message)
            end
            logger:debug("Repair button blocked due to no available repair tools")
            return false
        end)
    end
end

---Handle an enhancement attempt
---@param item tes3weapon|tes3armor
---@param itemData tes3itemData?
---@return boolean applied Whether enhancement was applied
---@return string? message Optional message to display
function RepairService.handleEnhancementAttempt(item, itemData)
    if not isEnhancementEnabled() then
        return false, "Усиление отключено"
    end

    if not StationService.isRepairMenuAtStation() then
        return false, "Для усиления необходимо использовать ремонтную станцию"
    end

    local repairTool, repairToolData = RepairService.getRepairMenuItemAndData()
    if not repairTool then
        logger:debug("Cannot enhance item %s: no repair tool equipped", item.name)
        return false, "Отсутствует ремонтный инструмент"
    end

    if repairToolData and repairToolData.condition <= 0 then
        logger:debug("Cannot enhance item %s: repair tool %s is depleted",
            item.name, repairTool.name)
        return false, "Ремонтный инструмент израсходован"
    end

    -- Check if item can be enhanced
    local canEnhance, reason = RepairService.canBeEnhanced(item, itemData)
    if not canEnhance then
        return false, reason
    end

    -- Calculate success chance and roll
    local repairTool, repairToolData = RepairService.getRepairMenuItemAndData()
    if not repairTool then
        logger:warn("No repair tool found when calculating enhancement chance")
        return false, "Отсутствует ремонтный инструмент"
    end
    local successChance = RepairService.calculateEnhancementSuccessChance(repairTool)
    local roll = math.random(1, 100)
    local attemptSucceeded = roll <= successChance

    -- Use automatic repair handler (which handles both success and failure)
    local newItemData, message = RepairService.handleAutomaticRepair(
        item,
        itemData,
        attemptSucceeded,
        true, -- always at station for enhancement
        0 -- enhancement doesn't use repair amount
    )

    logger:debug("Enhancement attempt: roll=%d, chance=%d, success=%s, result=%s",
    roll, successChance, tostring(attemptSucceeded), message)

    local newCondition = RepairService.reduceRepairToolCondition(repairTool, repairToolData)
    RepairService.updateRepairUsesText(newCondition)
    if newCondition <= 0 then
        local currentTool, currentToolData = RepairService.getRepairMenuItemAndData()

        -- Try to swap to next repair tool
        local swapped = RepairService.swapToNextRepairTool(currentTool)

        if not swapped then
            -- No more repair tools available
            local message = string.format(tes3.findGMST(tes3.gmst.sNotifyMessage51).value, repairTool.name)
            tes3.messageBox{ message = message }
            local menu = tes3ui.findMenu("MenuRepair")
            RepairService.hideTitle(menu)
            RepairService.blockRepairButtons(menu)
        end
    end


    tes3.playSound{ reference = tes3.player, sound = attemptSucceeded and "repair" or "repair fail" }
    RepairCost.handleTimeCost()
    RepairCost.handleFatigueCost()
    RepairService.checkFatigueAfterAttempt()

    return attemptSucceeded, message
end

---After any repair or enhancement attempt, check fatigue and block repair buttons if needed
function RepairService.checkFatigueAfterAttempt()
    if not config.mcm.enableFatigueCost then
        return
    end

    local currentFatigue = tes3.mobilePlayer.fatigue.current
    if currentFatigue <= 0 then
        logger:debug("Player has no fatigue after repair/enhancement attempt, blocking repair buttons")
        local repairMenu = tes3ui.findMenu("MenuRepair")
        if repairMenu then
            RepairService.blockRepairButtons(repairMenu, "Вы слишком устали, чтобы ремонтировать предметы.")
        end
    end
end

---Get message for repair menu label (now shows both repair and enhancement info)
---@return string message
function RepairService.getRepairMenuMessage()
    local messages = {}
    local isAtStation = StationService.isRepairMenuAtStation()

    -- Degradation/restoration info
    if isDegradationEnabled() then
        local baseDegradation = RepairCalculationService.calculateDegradationAmount()

        if isAtStation then
            -- At station: restoration on success = 1/2 repair amount, failure degradation unchanged
            table.insert(messages, string.format("Деградация: %d при неудачной попытке | 1/2 восстановления при успешном завершении", baseDegradation))
        else
            -- Show only failure degradation (full amount)
            table.insert(messages, string.format("Деградация при неудачной попытке: %d", baseDegradation))
        end
    end

    -- Enhancement info (only at stations)
    if isEnhancementEnabled() and isAtStation then
        local enhancementAmount = RepairCalculationService.calculateEnhancementAmount(true)
        table.insert(messages, string.format("Усиление: %d пунктов", enhancementAmount))
    end

    return table.concat(messages, " | ")
end

---Clear degradation from an item (used by service repair)
---@param item tes3weapon|tes3armor
---@param itemData tes3itemData?
function RepairService.clearDegradationForServiceRepair(item, itemData)
    if not isDegradationEnabled() then
        return
    end

    if not itemData then
        return
    end

    logger:debug("Clearing degradation for service repair: %s", item.name)
    ItemConditionService.clearDegradation(item, itemData)
end

---Check if item can be enhanced
---@param item tes3weapon|tes3armor
---@param itemData tes3itemData?
---@return boolean canEnhance
---@return string? reason
function RepairService.canEnhanceItem(item, itemData)

    if not isEnhancementEnabled() then
        return false, "Усиление отключено"
    end

    if not StationService.isRepairMenuAtStation() then
        return false, "Для усиления необходимо использовать ремонтную станцию"
    end

    return RepairService.canBeEnhanced(item, itemData)
end

function RepairService.isRepairableObject(object)
    return object.objectType == tes3.objectType.weapon
        or object.objectType == tes3.objectType.armor
end

function RepairService.isEnhanceableObject(object)
    local validObject = object.objectType == tes3.objectType.weapon
        or object.objectType == tes3.objectType.armor
    local isThrowingWeapon = object.objectType == tes3.objectType.weapon
        and (object.type == tes3.weaponType.arrow
        or object.type == tes3.weaponType.bolt
        or object.type == tes3.weaponType.marksmanThrown)

    return validObject and not isThrowingWeapon
end

---Check if item needs normal repair (condition is below max)
---@param currentCondition number
---@param maxRepairCondition number
---@return boolean
local function needsRepair(currentCondition, maxRepairCondition)
    return currentCondition < maxRepairCondition
end


---Handle successful repair when item needs repair
---@param itemData tes3itemData
---@return tes3itemData itemData
---@return string message
local function handleSuccessfulNormalRepair(itemData)
    logger:debug("SUCCESS: Normal repair (vanilla handles condition restoration)")
    return itemData, "Ремонт прошел успешно"
end

---Handle successful repair at station when item is fully repaired but has degradation
---@param item tes3weapon|tes3armor
---@param itemData tes3itemData
---@param currentDegradation number
---@param repairAmount number
---@return tes3itemData itemData
---@return string message
local function handleSuccessfulDegradationRestoration(item, itemData, currentDegradation, repairAmount)
    local restorationAmount = RepairCalculationService.calculateRestorationAmount(repairAmount)
    itemData = ItemConditionService.adjustDegradation(item, itemData, -restorationAmount)
    local newDegradation = ItemConditionService.getDegradationLevel(itemData)
    local actualRestoration = currentDegradation - newDegradation
    logger:debug("SUCCESS: Restored degradation by %d points", actualRestoration)
    return itemData, string.format("Восстановлено %d пунктов деградации", actualRestoration)
end

---Handle successful enhancement at station when item is pristine
---@param item tes3weapon|tes3armor
---@param itemData tes3itemData
---@param currentEnhancement number
---@return tes3itemData itemData
---@return string message
local function handleSuccessfulEnhancement(item, itemData, currentEnhancement)
    local enhancementAmount = RepairCalculationService.calculateEnhancementAmount(true)
    local remainingCapacity = RepairCalculationService.getRemainingEnhancementCapacity(item, currentEnhancement)

    if remainingCapacity <= 0 then
        logger:debug("SUCCESS: At enhancement cap, no action taken")
        return itemData, "Достигнут предел усиления"
    end

    local appliedAmount = math.min(enhancementAmount, remainingCapacity)
    itemData = ItemConditionService.adjustEnhancement(item, itemData, appliedAmount)

    logger:debug("SUCCESS: Enhanced by %d points", appliedAmount)
    return itemData, string.format("Усилено на %d пунктов", appliedAmount)
end

---Calculate appropriate degradation amount for a failed repair
---Stations do not affect failure degradation (only success restoration)
---@param isAtStation boolean
---@param repairAmount number
---@return number degradationAmount
local function calculateFailureDegradation(isAtStation, repairAmount)
    local baseDegradation = RepairCalculationService.calculateDegradationAmount()
    logger:debug("FAILURE: applying degradation %d (station status has no effect on failure)", baseDegradation)
    return baseDegradation
end

---Apply degradation damage to an item (degradation acts as buffer before enhancement)
---@param item tes3weapon|tes3armor
---@param itemData tes3itemData
---@param degradationAmount number
---@param currentEnhancement number
---@param currentDegradation number
---@return tes3itemData itemData
---@return string message
local function applyDegradationDamage(item, itemData, degradationAmount, currentEnhancement, currentDegradation)
    if degradationAmount <= 0 then
        return itemData, "Деградация не применена"
    end

    local currentCondition = itemData and itemData.condition or item.maxCondition

    -- Enhancement acts as a buffer - degrade enhancement first
    if currentEnhancement > 0 then
        local enhancementLoss = math.min(degradationAmount, currentEnhancement)
        itemData = ItemConditionService.adjustEnhancement(item, itemData, -enhancementLoss)

        local remainingDegradation = degradationAmount - enhancementLoss
        if remainingDegradation > 0 and currentDegradation > 0 then
            -- Enhancement buffer exhausted AND item already had degradation
            -- Only then apply remaining as actual degradation
            itemData = ItemConditionService.adjustDegradation(item, itemData, remainingDegradation)
            logger:debug("FAILURE: Lost %d enhancement, degraded by %d", enhancementLoss, remainingDegradation)
            return itemData, string.format("Потеряно %d пунктов усиления, деградация %d", enhancementLoss, remainingDegradation)
        else
            logger:debug("FAILURE: Lost %d enhancement (no degradation applied)", enhancementLoss)
            return itemData, string.format("Потеряно %d пунктов усиления", enhancementLoss)
        end
    else
        -- No enhancement buffer
        -- If no existing degradation, this is a failed enhancement attempt - don't add degradation
        local isPristine = currentCondition >= item.maxCondition and currentDegradation == 0
        if isPristine then
            logger:debug("FAILURE: Enhancement attempt on pristine item failed (no degradation applied)")
            return itemData, "Не удалось выполнить усиление"
        end

        -- Item has existing degradation - apply degradation normally
        itemData = ItemConditionService.adjustDegradation(item, itemData, degradationAmount)
        local newDegradation = ItemConditionService.getDegradationLevel(itemData)
        local actualDegradation = newDegradation - currentDegradation
        logger:debug("FAILURE: Degraded by %d points", actualDegradation)
        return itemData, string.format("Деградация %d пунктов", actualDegradation)
    end
end

---Automatically handle repair attempt based on item state
---Determines whether to degrade, restore degradation, enhance, or apply degradation to enhancement
---Note: Does NOT handle vanilla repair (condition restoration) - that's handled by the repair event
---Only handles side effects: degradation changes and enhancement
---@param item tes3weapon|tes3armor The item being repaired
---@param itemData tes3itemData? The item's data
---@param success boolean Whether the repair attempt was successful
---@param isAtStation boolean? Whether the repair is being done at a station (defaults to false)
---@param repairAmount number? The amount being repaired (defaults to 0)
---@return tes3itemData itemData The modified itemData
---@return string message Description of what happened
function RepairService.handleAutomaticRepair(item, itemData, success, isAtStation, repairAmount)
    isAtStation = isAtStation or false
    repairAmount = repairAmount or 0
    itemData = ItemConditionService.ensureItemData(item, itemData)

    local currentCondition = itemData.condition
    local currentDegradation = ItemConditionService.getDegradationLevel(itemData)
    local currentEnhancement = ItemConditionService.getEnhancementLevel(item, itemData)
    local maxRepairCondition = ItemConditionService.getMaxRepairCondition(item, itemData)

    logger:debug("Auto-repair: %s (success=%s, atStation=%s, cond=%d/%d, deg=%d, enh=%d)",
        item.name, tostring(success), tostring(isAtStation),
        currentCondition, maxRepairCondition, currentDegradation, currentEnhancement)

    -- SUCCESSFUL REPAIR
    if success then
        -- Item needs repair: vanilla handles the actual repair
        if needsRepair(currentCondition, maxRepairCondition) then
            return handleSuccessfulNormalRepair(itemData)
        end

        -- Item fully repaired: check for station bonuses
        if isAtStation then
            -- Restore degradation if present
            if currentDegradation > 0 then
                return handleSuccessfulDegradationRestoration(item, itemData, currentDegradation, repairAmount)
            end

            -- No degradation: try to enhance
            if currentDegradation == 0 then
                return handleSuccessfulEnhancement(item, itemData, currentEnhancement)
            end
        end

        logger:debug("SUCCESS: Already at maximum, no action")
        return itemData, "Уже достигнуто максимальное состояние"
    end

    -- FAILED REPAIR
    if not success then
        local degradationAmount = calculateFailureDegradation(isAtStation, repairAmount)
        return applyDegradationDamage(item, itemData, degradationAmount, currentEnhancement, currentDegradation)
    end

    return itemData, "Действие не выполнено"
end---Get the current enhancement cap for an item
---@param item tes3weapon|tes3armor
---@return number enhancementCap
function RepairService.getEnhancementCap(item)
    return RepairCalculationService.getEnhancementCap(item)
end

---Get bar fractions for UI display
---@param item tes3weapon|tes3armor
---@param itemData tes3itemData?
---@return number degradationFraction
---@return number enhancementFraction
function RepairService.getConditionBarFractions(item, itemData)
    local degradationLevel = ItemConditionService.getDegradationLevel(itemData)
    local enhancementLevel = ItemConditionService.getEnhancementLevel(item, itemData)

    local degradationFraction = RepairCalculationService.getDegradationFraction(item, degradationLevel)
    local enhancementFraction = RepairCalculationService.getEnhancementFraction(item, enhancementLevel)

    return degradationFraction, enhancementFraction
end



return RepairService
