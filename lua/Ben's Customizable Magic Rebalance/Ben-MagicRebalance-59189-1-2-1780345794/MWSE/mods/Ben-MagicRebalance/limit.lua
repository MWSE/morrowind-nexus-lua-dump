local config = require("Ben-MagicRebalance.config")
local common = require("Ben-MagicRebalance.common")
local util = require("Ben-MagicRebalance.util")
local gameConfig = config.getGameConfig()

local magicEffectNameIds = {} -- magicEffect.name = magicEffect.id
local currentLimits = nil -- [min|max]Duration, [min|max]Magnitude

local function getFullName(uiElement)

    local fullName = uiElement.name
    local ancestor = uiElement.parent

    while ancestor ~= nil and ancestor.name ~= nil do
        fullName = ancestor.name .. "-" .. fullName
        ancestor = ancestor.parent
    end

    return fullName

end

local function logUiStructure(uiElement)

    common.log(getFullName(uiElement))
    common.log(uiElement.type)

    if uiElement.type == "scrollBar"
    and uiElement.widget ~= nil then

        common.log(uiElement.widget.current)
        common.log(uiElement.widget.max)
        common.log(uiElement.widget.step)
        common.log(uiElement.widget.jump)

    elseif uiElement.type == "text" then
        common.log(uiElement.text)
    end

    for _, child in pairs(uiElement.children) do
        logUiStructure(child)
    end

end

local function getEffectId(menuSetValues)

    local nameLayout = menuSetValues:findChild(tes3ui.registerID("MenuSetValues_NameLayout"))
    local magicEffectName = nil

    for _, child in pairs(nameLayout.children) do
        if child.type == "text" then
            magicEffectName = child.text
            break
        end
    end

    if magicEffectName == nil then
        common.log("Could not find magic effect name in MenuSetValues.")
        return nil
    end

    local effectId = magicEffectNameIds[magicEffectName]

    if effectId == nil then
        common.log("Could not find magic effect with name: %s", magicEffectName)
        return nil
    end

    return effectId

end

local function cacheCurrentLimits(menuSetValues)

    currentLimits = nil -- clear old cache
    local effectId = getEffectId(menuSetValues)

    if effectId == nil then return end
    if gameConfig.shared.excludedEffectIds[effectId] then return end

    --------------------------------------------------

    local effectConfig = common.getEffectConfig(effectId)

    currentLimits = {
        minDuration = effectConfig.minDuration,
        maxDuration = effectConfig.maxDuration,
        minMagnitude = effectConfig.minMagnitude,
        maxMagnitude = effectConfig.maxMagnitude,
    }

    if gameConfig.limit.oneSecondMinDuration then
        currentLimits.minDuration = currentLimits.minDuration or 1
    end

end

local function enforceLimits(menuSetValues)

    if currentLimits == nil then return end

    --------------------------------------------------

    local magLowSlider = menuSetValues:findChild(tes3ui.registerID("MenuSetValues_MagLowSlider"))
    local magHighSlider = menuSetValues:findChild(tes3ui.registerID("MenuSetValues_MagHighSlider"))
    local durationSlider = menuSetValues:findChild(tes3ui.registerID("MenuSetValues_DurationSlider"))

    --------------------------------------------------

    if magLowSlider ~= nil then

        local magLowClamped = util.clamp(
            magLowSlider.widget.current,
            currentLimits.minMagnitude,
            currentLimits.maxMagnitude)

        if magLowSlider.widget.current ~= magLowClamped then
            magLowSlider.widget.current = magLowClamped
            magLowSlider:triggerEvent("PartScrollBar_changed")
        end

    end

    --------------------------------------------------

    if magHighSlider ~= nil then

        local magHighClamped = util.clamp(
            magHighSlider.widget.current,
            currentLimits.minMagnitude,
            currentLimits.maxMagnitude)

        if magHighSlider.widget.current ~= magHighClamped then
            magHighSlider.widget.current = magHighClamped
            magHighSlider:triggerEvent("PartScrollBar_changed")
        end

    end

    --------------------------------------------------

    if durationSlider ~= nil then

        local durationClamped = util.clamp(
            durationSlider.widget.current,
            currentLimits.minDuration,
            currentLimits.maxDuration)

        if durationSlider.widget.current ~= durationClamped then
            durationSlider.widget.current = durationClamped
            durationSlider:triggerEvent("PartScrollBar_changed")
        end

    end

end

local this = {}

this.onUiEvent = function(e)

    -- event is filtered to:
    -- MenuSetValues_MagLowSlider
    -- MenuSetValues_MagHighSlider
    -- MenuSetValues_DurationSlider

    -- https://mwse.github.io/MWSE/events/uiEvent/

    local menuSetValues = e.source:getTopLevelMenu()
    enforceLimits(menuSetValues)

end

this.onUiActivated = function(e)

    -- event is filtered to: MenuSetValues

    -- https://mwse.github.io/MWSE/events/uiActivated/
    -- https://mwse.github.io/MWSE/types/tes3uiElement/
    -- https://mwse.github.io/MWSE/types/tes3uiWidget/

    if not gameConfig.limit.limitsEnabled then return end

    --logUiStructure(e.element)
    cacheCurrentLimits(e.element)
    enforceLimits(e.element)

end

this.onLoaded = function(e)

    magicEffectNameIds = {}

    for _, magicEffect in pairs(tes3.dataHandler.nonDynamicData.magicEffects) do
        magicEffectNameIds[magicEffect.name] = magicEffect.id
    end

    -- https://mwse.github.io/MWSE/apis/tes3/#tes3claimspelleffectid
    -- https://mwse.github.io/MWSE/apis/tes3/#tes3addmagiceffect
    -- https://mwse.github.io/MWSE/types/tes3nonDynamicData/

    -- tes3.claimSpellEffectId() updates tes3.effect
    -- tes3.addMagicEffect() updates tes3.dataHandler.nonDynamicData.magicEffects
    -- tes3.dataHandler.nonDynamicData.magicEffects = magicEffect guaranteed to exist
    -- tes3.getMagicEffect(tes3.effect.exampleId) = magicEffect might not exist

end

return this
