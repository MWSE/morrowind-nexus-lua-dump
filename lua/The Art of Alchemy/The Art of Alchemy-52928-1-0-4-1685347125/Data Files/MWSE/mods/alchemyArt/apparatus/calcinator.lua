local ui = require("alchemyArt.ui")
local common = require("alchemyArt.common")
local apparatus = require("alchemyArt.apparatus.apparatus")
local specialEffects = require("alchemyArt.specialEffects")
local effects = require("alchemyArt.effects")
local formulas = require("alchemyArt.formulas")

local calcinator = apparatus:new()

calcinator.menuName = "MenuCalcinator"
calcinator.notEnoughContentsMessage = common.dictionary.atLeastOnePotion
calcinator.rightBlockLeftBorder = 74
calcinator.mode = 0
calcinator.count = 1
calcinator.maxItems = 3

calcinator.showMainTutorial = function (e)
    local tooltip = tes3ui.createTooltipMenu()
	tooltip.autoHeight = true
	tooltip.autoWidth = true
    tooltip.wrapText = true
    local label =  tooltip:createLabel{text = common.dictionary.calcinatorHelp}
    label.autoHeight = true
    label.autoWidth = true
    label.wrapText = true
end

calcinator.showModeTutorial = function(e)
    local tooltip = tes3ui.createTooltipMenu()
	tooltip.autoHeight = true
	tooltip.autoWidth = true
    tooltip.wrapText = true
    local label
    -- if e.source.widget.value == 0 then
    label =  tooltip:createLabel{text = common.dictionary.calcinatorModeHelp}
    -- else
    --     label =  tooltip:createLabel{text = common.dictionary.alembicFilterHelp}
    -- end
    label.autoHeight = true
    label.autoWidth = true
    label.wrapText = true
end

function calcinator:getEffectsArray(contents, apparatusQuality, effectsToClear)
    local potionToClear = contents["MenuCalcinator_potion"]
    local count = 0
    for i, effect in ipairs(potionToClear.effects) do
        if effect.id == -1 then break end
        if effectsToClear[i] then
            count = count + 1
        end
    end

    local oldModifier = effects.getModifier(potionToClear.effects)

    local power

    if count > 0 then
        power = math.floor(formulas.getPower(apparatusQuality)/count + 0.5)
    else
        power = 0
    end

    local result = {}
    local rI = 1
    for i, effect in ipairs(potionToClear.effects) do

        if effect.id == -1 then break end

        if effectsToClear[i] then
            local effectPower = effect.duration * (effect.min + effect.max)/2
            effectPower = effectPower - power
            if effectPower > 0 then
                result[rI] = {}
                result[rI].magnitude, result[i].duration = formulas.getMagnitudeDuration(effectPower)
                result[rI].id = effect.id
                result[rI].power = effectPower
                result[rI].attribute = effect.attribute
                result[rI].skill = effect.skill
                rI = rI + 1
            end
        else
            result[rI] = {}
            result[rI].magnitude = (effect.min + effect.max)/2
            result[rI].duration = effect.duration
            result[rI].id = effect.id
            result[rI].power = formulas.getEffectPower(effect)
            result[rI].attribute = effect.attribute
            result[rI].skill = effect.skill
            rI = rI + 1
        end
    end

    local newModifier = effects.getModifier(result)

    if newModifier ~= oldModifier then
        for j, effect in ipairs(result) do
            result[j].power = power * (100 +10*newModifier) / (100 + 10*oldModifier)
            result[j].magnitude, result[j].duration = formulas.getEffectMagnitudeDuration(effect.id, result[j].power) --, self.magnitudeDurationValue
        end
    end

    return result
end

function calcinator:getFilterEffectList(inventory)
    return common.getPotionEffectList(inventory)
end

local function onModeButtonValueChange(e)
    if e.source.widget.value == 0 then
        ui.negativeEffectColor = tes3ui.getPalette(tes3.palette.negativeColor)
        ui.positiveEffectColor = tes3ui.getPalette(tes3.palette.normalColor)
        calcinator.effectsToClear = {}
        calcinator.mode  = 0
    elseif e.source.widget.value == 1 then
        ui.negativeEffectColor = tes3ui.getPalette(tes3.palette.normalColor)
        ui.positiveEffectColor = tes3ui.getPalette(tes3.palette.negativeColor)
        calcinator.effectsToClear = {}
        calcinator.mode  = 1
    end
end

local function getEffectsToClear()
    local effectsToClear = {}
    local potionToClear = calcinator.contents["MenuCalcinator_potion"]
    if calcinator.mode == 0 then
        for i, effect in ipairs(potionToClear.effects) do
            if effect.object then
                if effect.object.isHarmful then
                    effectsToClear[i] = true
                end
            else
                break
            end
        end
    else
        for i, effect in ipairs(potionToClear.effects) do
            if effect.object then
                if not effect.object.isHarmful then
                    effectsToClear[i] = true
                end
            else
                break
            end
        end
    end
    return effectsToClear
end

function calcinator:pickResultEnd(reference)
    specialEffects.removeCalcinatorFire(reference)
end

function calcinator:addVisualEffect(reference)
    specialEffects.addCalcinatorFire(reference)
end

function calcinator:alchemyBegin(reference)
    reference.data.alchemyArt = reference.data.alchemyArt or {}
    reference.data.alchemyArt.contents =  self:removeContentsFromPlayer()
    local effectsToClear = getEffectsToClear()
    local effectsArray
    if not formulas.getSuccess() then
        effectsArray = {}
    else
        effectsArray = self:getEffectsArray(calcinator.contents, reference.object.quality, effectsToClear)
        -- mwse.log(inspect(effectsArray))
    end
    reference.data.alchemyArt.effectsArray = effectsArray
    -- tes3.messageBox("Current count: %s", self.count)
    reference.data.alchemyArt.count = self.count
    reference.data.alchemyArt.progress = 0
    reference.data.alchemyArt.makeStandard = tes3.worldController.inputController:isControlDown()
    self:addVisualEffect(reference)
    --specialEffects.addRetortFire(reference)
    self:startTimer(reference)
end

-- function calcinator:alchemyBegin(reference)
--     reference.data.alchemyArt = reference.data.alchemyArt or {}
--     reference.data.alchemyArt.contents =  self:removeContentsFromPlayer()
--     local effectsToClear = getEffectsToClear()
--     local effectsArray = {}
--     if not formulas.getSuccess() then
--         effectsArray = {}
--     else
--         effectsArray = self:getEffectsArray(calcinator.contents, reference.object.quality, effectsToClear)
--     end
--     reference.data.alchemyArt.effectsArray = effectsArray
--     reference.data.alchemyArt.progress = 0
--     self:addVisualEffect(reference)
--     self:startTimer(reference)
-- end


function calcinator:createLeftBlock(element)
    local leftBlock = ui.createAutoBlock(element, self.menuName.."_left")
    leftBlock.flowDirection = "top_to_bottom"
    leftBlock.borderTop = 29
    local modeButton = leftBlock:createCycleButton{
        id = self.menuName.."_modeButton",
        options = {{text="Clear Negative", value = 0}}
    }
    modeButton.minWidth = 130
    modeButton.minHeight = 30
    modeButton.borderBottom = 15
    modeButton.widget:addOption{text="Clear Positive", value = 1}
    local modeButtonText = modeButton:findChild("PartButton_text_ptr")
    modeButtonText.wrapText = true
    modeButtonText.justifyText = tes3.justifyText.center
    ui.negativeEffectColor = tes3ui.getPalette(tes3.palette.negativeColor)
    ui.positiveEffectColor = tes3ui.getPalette(tes3.palette.normalColor)
    timer.delayOneFrame(function ()
        timer.delayOneFrame(function ()
            ui.negativeEffectColor = tes3ui.getPalette(tes3.palette.normalColor)
            ui.positiveEffectColor = tes3ui.getPalette(tes3.palette.normalColor)
        end)
    end)
    self.mode  = 0
    modeButton:register("valueChanged", onModeButtonValueChange)
    modeButton:register("mouseOver", self.showModeTutorial)
    leftBlock:createLabel{id = self.menuName.."_potion_label", text = common.dictionary.potion}
    local potionBlock = ui.createAutoBlock(leftBlock, self.menuName.."potionBlock")
    local potionSlot = ui.createItemSlot(potionBlock, self.menuName.."_potion", function (e)
        self:selectItem(e)
    end)
    local scrollpane = potionBlock:createVerticalScrollPane{id = "counter"}
    scrollpane.maxHeight = 40
    scrollpane.minHeight = 40
    scrollpane.maxWidth = 22
    scrollpane.minWidth = 22
    scrollpane.borderTop = 8
    scrollpane:findChild("PartScrollBar_bar_back").visible = false
    local arrowUp = scrollpane:findChild("PartScrollBar_left_arrow")
    local arrowDown = scrollpane:findChild("PartScrollBar_right_arrow")
    arrowUp.borderBottom = 5
    arrowUp:register("mouseClick", function ()
        self:countUp()
    end)
    arrowDown:register("mouseClick", function ()
        self:countDown()
    end)
end

return calcinator