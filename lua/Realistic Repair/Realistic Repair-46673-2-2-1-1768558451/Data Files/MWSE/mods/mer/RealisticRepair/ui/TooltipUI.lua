---@class RealisticRepair.TooltipUI
--- Handles tooltip modifications for items with degradation or enhancement.
local TooltipUI = {}

local config = require("mer.RealisticRepair.config")
local RepairService = require("mer.RealisticRepair.services.RepairService")
local ItemConditionService = require("mer.RealisticRepair.services.ItemConditionService")
local ConditionBarRenderer = require("mer.RealisticRepair.ui.ConditionBarRenderer")

local logger = mwse.Logger.new{
    logLevel = config.mcm.logLevel,
}

---Check if degradation/enhancement display is enabled
---@return boolean
local function isEnabled()
    return config.mcm.enableRealisticRepair
        and config.mcm.enableDegradation
end

---Check if object is gear (weapon or armor)
---@param object tes3object
---@return boolean
local function isGear(object)
    return object.objectType == tes3.objectType.weapon
        or object.objectType == tes3.objectType.armor
end

---Add condition bars to tooltip
---@param tooltip tes3uiElement
---@param item tes3weapon|tes3armor
---@param itemData tes3itemData
local function addConditionBars(tooltip, item, itemData)
    local degradationFraction, enhancementFraction = RepairService.getConditionBarFractions(item, itemData)

    -- Only add bars if there's something to show
    if degradationFraction <= 0 and enhancementFraction <= 0 then
        return
    end

    local conditionBlock = tooltip:findChild("HelpMenu_qualityCondition")
    if not conditionBlock then
        logger:debug("Could not find condition block in tooltip")
        return
    end

    local conditionBar = conditionBlock.children[1]
    if not conditionBar then
        logger:debug("Could not find condition bar in tooltip for %s", item.name)
        return
    end

    ConditionBarRenderer.createOrUpdateConditionBars(
        conditionBar,
        degradationFraction,
        enhancementFraction,
        false  -- isRepairMenu = false (tooltip)
    )
end

---Add degradation text to tooltip
---@param tooltip tes3uiElement
---@param item tes3weapon|tes3armor
---@param itemData tes3itemData
---@param conditionBlock tes3uiElement
local function addDegradationText(tooltip, item, itemData, conditionBlock)
    local degradationLevel = ItemConditionService.getDegradationLevel(itemData)
    if degradationLevel <= 0 then
        return
    end

    local degradationText = string.format("Degradation: %d", degradationLevel)
    local label = tooltip:createLabel({ text = degradationText })
    label:reorder{ before = conditionBlock }
end

---Add enhancement text to tooltip
---@param tooltip tes3uiElement
---@param item tes3weapon|tes3armor
---@param itemData tes3itemData
---@param conditionBlock tes3uiElement
local function addEnhancementText(tooltip, item, itemData, conditionBlock)
    local enhancementLevel = ItemConditionService.getEnhancementLevel(item, itemData)
    if enhancementLevel <= 0 then
        return
    end

    local enhancementText = string.format("Enhancement: +%d", enhancementLevel)
    local label = tooltip:createLabel({ text = enhancementText })
    label.color = {0.8, 0.6, 0.2}  -- Amber color
    label:reorder{ before = conditionBlock }
end

---@param weapon tes3weapon
local function getWeaponEnhanceSuffix(weapon)
    local default = "Sharpened"
    local typeMapping = {
        [tes3.weaponType.bluntOneHand] = "Tempered",
        [tes3.weaponType.bluntTwoClose] = "Tempered",
        [tes3.weaponType.bluntTwoWide] = "Tempered",
        [tes3.weaponType.marksmanBow] = "Hardened",
        [tes3.weaponType.marksmanCrossbow] = "Hardened",
    }
    return typeMapping[weapon.type] or default
end

---@param armor tes3armor
local function getArmorEnhanceSuffix(armor)
    return "Reinforced"
end

local function getModifiedDamageColor(multiplier)
    if multiplier >= 1.0 then
        return tes3ui.getPalette("positive_color")
    else
        return tes3ui.getPalette("negative_color")
    end
end

local function getModifiedDamageText(text, multiplier)
    local min = math.ceil(multiplier * text:match("%d+"))
    local max = math.ceil(multiplier * text:match("%d+$"))
    return text:gsub("%d+", "%%d"):format(min, max)
end

local function getModifiedArmorRatingText(text, multiplier)
    local rating = math.ceil(multiplier * text:match("%d+"))
    return text:gsub("%d+", "%%d"):format(rating)
end


local function getMultiplier(item, itemData)
    return itemData.condition / item.maxCondition
end


---Update weapon damage stats in tooltip based on condition
---@param tooltip tes3uiElement
---@param item tes3weapon
---@param itemData tes3itemData
function TooltipUI.updateWeaponStats(tooltip, item, itemData)

    local multiplier = getMultiplier(item, itemData)
    if multiplier == 1.0 then
        return
    end

    local name = tooltip:findChild(tes3ui.registerID("HelpMenu_name"))
    if name and (multiplier > 1.0) then
        name.text = name.text .. " (" .. getWeaponEnhanceSuffix(item) .. ")"
    end

    local chop = tooltip:findChild(tes3ui.registerID("HelpMenu_chop"))
    if chop then
        chop.text = getModifiedDamageText(chop.text, multiplier)
        chop.color = getModifiedDamageColor(multiplier)
    end

    local slash = tooltip:findChild(tes3ui.registerID("HelpMenu_slash"))
    if slash then
        slash.text = getModifiedDamageText(slash.text, multiplier)
        slash.color = getModifiedDamageColor(multiplier)
    end

    local thrust = tooltip:findChild(tes3ui.registerID("HelpMenu_thrust"))
    if thrust then
        thrust.text = getModifiedDamageText(thrust.text, multiplier)
        thrust.color = getModifiedDamageColor(multiplier)
    end
end

---Update armor rating stats in tooltip based on condition
---@param tooltip tes3uiElement
---@param item tes3armor
---@param itemData tes3itemData
function TooltipUI.updateArmorStats(tooltip, item, itemData)
    local multiplier = getMultiplier(item, itemData)
    if multiplier == 1.0 then
        return
    end

    local name = tooltip:findChild(tes3ui.registerID("HelpMenu_name"))
    if name and (multiplier > 1.0) then
        name.text = name.text .. " (" .. getArmorEnhanceSuffix(item) .. ")"
    end

    --HelpMenu_armorRating
    local armorRating = tooltip:findChild(tes3ui.registerID("HelpMenu_armorRating"))

    if armorRating then
        armorRating.text = getModifiedArmorRatingText(armorRating.text, multiplier)
        armorRating.color = getModifiedDamageColor(multiplier)
    end
end

---Update item tooltip with degradation and enhancement information
---@param e uiObjectTooltipEventData
function TooltipUI.updateTooltip(e)
    if not isEnabled() then
        return
    end

    local item = e.object --[[@as tes3weapon|tes3armor]]
    local itemData = e.itemData

    if not e.itemData then
        return
    end

    if not isGear(e.object) then
        return
    end

    if config.mcm.enableDynamicTooltips then
        if item.objectType == tes3.objectType.weapon then
            TooltipUI.updateWeaponStats(e.tooltip, item, itemData)
        end
        if item.objectType == tes3.objectType.armor then
            TooltipUI.updateArmorStats(e.tooltip, item, itemData)
        end
    end


    -- Check if there's anything to display
    local hasDegradation = ItemConditionService.hasDegradation(itemData)
    local hasEnhancement = ItemConditionService.hasEnhancement(item, itemData)

    if not hasDegradation and not hasEnhancement then
        return
    end

    logger:debug("Updating tooltip for %s (degradation: %s, enhancement: %s)",
        item.name, tostring(hasDegradation), tostring(hasEnhancement))

    local conditionBlock = e.tooltip:findChild("HelpMenu_qualityCondition")
    if not conditionBlock then
        logger:debug("No condition block found in tooltip")
        return
    end

    -- Add condition bars
    addConditionBars(e.tooltip, item, itemData)

    -- Add text labels
    if hasDegradation then
        addDegradationText(e.tooltip, item, itemData, conditionBlock)
    end

    if hasEnhancement then
        addEnhancementText(e.tooltip, item, itemData, conditionBlock)
    end


end

return TooltipUI
