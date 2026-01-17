---@class RealisticRepair.ConditionBarRenderer
--- Renders multi-segment condition bars showing degradation, normal condition, and enhancement.
--- Provides unified rendering for both repair menu and tooltips.
local ConditionBarRenderer = {}
local config = require("mer.RealisticRepair.config")
local logger = mwse.Logger.new{
    logLevel = config.mcm.logLevel,
}

---Color definitions for bar segments
local COLORS = {
    degradation = {0.2, 0.2, 0.2, 1.0},  -- Dark grey for degradation
    enhancement = {0.8, 0.6, 0.2, 0.2},  -- Amber/gold for enhancement
}

---Bar element IDs
local IDS = {
    degradation = "RealisticRepair_degradeBar",
    enhancement = "RealisticRepair_enhanceBar",
}

---Get the fillbar element from a condition bar
---@param conditionBar tes3uiElement
---@return tes3uiElement? fillBar
local function getFillBar(conditionBar)
    return conditionBar:findChild("PartFillbar_colorbar_ptr")
end

---Calculate the actual bar width (excluding borders)
---@param conditionBar tes3uiElement
---@param fillBar tes3uiElement
---@return number barWidth
local function getBarWidth(conditionBar, fillBar)
    return math.ceil(conditionBar.width - (fillBar.borderAllSides * 2))
end

---Create a bar overlay element
---@param parent tes3uiElement
---@param id string
---@param color number[] RGBA color array
---@param width number
---@param height number
---@param alignX number
---@return tes3uiElement bar
local function createBarOverlay(parent, id, color, width, height, alignX)
    local bar = parent:createRect{
        id = id,
        color = color,
    }
    bar.width = width
    bar.height = height
    bar.absolutePosAlignX = alignX
    bar.absolutePosAlignY = 0.5
    bar.borderAllSides = 2
    bar.alpha = color[4] or 1.0
    return bar
end

---Create or update degradation bar (right-aligned, dark grey)
---@param conditionBar tes3uiElement
---@param degradationFraction number 0.0 to 1.0
---@param isRepairMenu boolean Whether this is for repair menu (different sizing)
local function _createOrUpdateDegradationBar(conditionBar, degradationFraction, isRepairMenu)

    logger:debug("Creating/updating degradation bar with fraction %.3f", degradationFraction)


    local fillBar = getFillBar(conditionBar)
    if not fillBar then
        logger:warn("Could not find fill bar in condition bar")
        return
    end

    if degradationFraction <= 0 then
        return
    end


    local barWidth = getBarWidth(conditionBar, fillBar)
    local degradeBarWidth

    if isRepairMenu then
        -- Repair menu uses fixed width (backward compatibility)
        degradeBarWidth = math.ceil(294 * degradationFraction)
    else
        -- Tooltip uses calculated width
        degradeBarWidth = math.ceil(barWidth * degradationFraction)
    end

    logger:debug("Degradation bar width: %d (total bar width: %d)", degradeBarWidth, barWidth)

    -- Check if bar already exists
    local degradeBar = conditionBar.parent:findChild(IDS.degradation)
    if degradeBar then
        -- Update existing bar
        degradeBar.width = degradeBarWidth
    else
        -- Create new bar
        degradeBar = createBarOverlay(
            conditionBar.parent,
            IDS.degradation,
            COLORS.degradation,
            degradeBarWidth,
            fillBar.height,
            1.0  -- Right-aligned
        )

        -- Reorder to appear behind condition bar
        local parent = conditionBar.parent
        parent:reorderChildren(parent.children[1], degradeBar, 1)

        -- Weird thing to trigger proper ordering
        conditionBar.imageScaleX = 0.0
    end
end

---Create or update enhancement bar (left-aligned, amber)
---@param conditionBar tes3uiFillBar|tes3uiElement
---@param enhancementFraction number 0.0 to 1.0
---@param isRepairMenu boolean Whether this is for repair menu (different sizing)
local function _createOrUpdateEnhancementBar(conditionBar, enhancementFraction, isRepairMenu)
    if enhancementFraction <= 0 then
        return
    end

    logger:debug("Creating/updating enhancement bar with fraction %.3f", enhancementFraction)

    local fillBar = getFillBar(conditionBar)
    if not fillBar then
        logger:warn("Could not find fill bar in condition bar")
        return
    end

    -- Ensure condition bar is properly sized
    if isRepairMenu then
        conditionBar.widthProportional = 1.0
        conditionBar:updateLayout()
    end

    local barWidth = getBarWidth(conditionBar, fillBar)
    local enhanceBarWidth

    if isRepairMenu then
        -- Repair menu uses fixed width (backward compatibility)
        enhanceBarWidth = math.ceil(294 * enhancementFraction)
    else
        -- Tooltip uses calculated width
        enhanceBarWidth = math.ceil(barWidth * enhancementFraction)
    end

    logger:debug("Enhancement bar width: %d (total bar width: %d)", enhanceBarWidth, barWidth)



    -- Check if bar already exists
    local enhanceBar = conditionBar:findChild(IDS.enhancement)
    if enhanceBar then
        -- Update existing bar
        enhanceBar.width = enhanceBarWidth
    else
        -- Create new bar
        enhanceBar = createBarOverlay(
            conditionBar,
            IDS.enhancement,
            COLORS.enhancement,
            enhanceBarWidth,
            fillBar.height,
            0.0  -- Left-aligned
        )

        -- Reorder to appear behind condition bar
        conditionBar:reorderChildren(conditionBar.children[2], enhanceBar, 1)

        -- Hide condition bar scaling artifacts
        conditionBar.imageScaleX = 0.0
    end
end

---Remove existing overlay bars
---@param conditionBar tes3uiElement
local function _removeExistingBars(conditionBar)
    local parent = conditionBar.parent

    local degradeBar = parent:findChild(IDS.degradation)
    if degradeBar then
        degradeBar:destroy()
    end

    local enhanceBar = conditionBar:findChild(IDS.enhancement)
    if enhanceBar then
        enhanceBar:destroy()
    end
end

---Create or update both degradation and enhancement bars
---@param conditionBar tes3uiElement
---@param degradationFraction number 0.0 to 1.0
---@param enhancementFraction number 0.0 to 1.0
---@param isRepairMenu boolean Whether this is for repair menu (different sizing)
function ConditionBarRenderer.createOrUpdateConditionBars(conditionBar, degradationFraction, enhancementFraction, isRepairMenu)
    -- Ensure condition bar is properly sized
    if isRepairMenu then
        conditionBar.widthProportional = 1.0
    end

    -- Remove bars if both fractions are zero
    if degradationFraction <= 0 and enhancementFraction <= 0 then
        _removeExistingBars(conditionBar)
        return
    end

    -- Create or update enhancement bar first
    if enhancementFraction > 0 then
        _createOrUpdateEnhancementBar(conditionBar, enhancementFraction, isRepairMenu)
    else
        -- Remove enhancement bar if it exists but fraction is zero
        local enhanceBar = conditionBar:findChild(IDS.enhancement)
        if enhanceBar then
            enhanceBar:destroy()
        end
    end

    -- Create or update degradation bar
    if degradationFraction > 0 then
        _createOrUpdateDegradationBar(conditionBar, degradationFraction, isRepairMenu)
    else
        -- Remove degradation bar if it exists but fraction is zero
        local degradeBar = conditionBar.parent:findChild(IDS.degradation)
        if degradeBar then
            degradeBar:destroy()
        end
    end
end

return ConditionBarRenderer
