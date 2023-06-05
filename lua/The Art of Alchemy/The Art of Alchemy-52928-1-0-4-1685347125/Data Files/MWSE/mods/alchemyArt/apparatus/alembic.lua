local ui = require("alchemyArt.ui")
local common = require("alchemyArt.common")
local apparatus = require("alchemyArt.apparatus.apparatus")
local effects = require("alchemyArt.effects")

local formulas = require("alchemyArt.formulas")

local alembic = apparatus:new()

alembic.menuName = "MenuAlembic"
alembic.rightBlockLeftBorder = 73 --6
alembic.magnitudeDurationValue = 3
alembic.contentsEffects = {}
alembic.mode = 0
alembic.notEnoughContentsMessage = common.dictionary.atLeastOnePotion

alembic.showMainTutorial = function (e)
    local tooltip = tes3ui.createTooltipMenu()
	tooltip.autoHeight = true
	tooltip.autoWidth = true
    tooltip.wrapText = true
    local label =  tooltip:createLabel{text = common.dictionary.alembicHelp}
    label.autoHeight = true
    label.autoWidth = true
    label.wrapText = true
end

alembic.showModeTutorial = function(e)
    local tooltip = tes3ui.createTooltipMenu()
	tooltip.autoHeight = true
	tooltip.autoWidth = true
    tooltip.wrapText = true
    local label
    if e.source.widget.value == 0 then
        label =  tooltip:createLabel{text = common.dictionary.alembicConcentrateHelp}
    else
        label =  tooltip:createLabel{text = common.dictionary.alembicFilterHelp}
    end
    label.autoHeight = true
    label.autoWidth = true
    label.wrapText = true
end

alembic.showPotionsTutorial = function (e)
    local tooltip = tes3ui.createTooltipMenu()
	tooltip.autoHeight = true
	tooltip.autoWidth = true
    tooltip.wrapText = true
    local label =  tooltip:createLabel{text = common.dictionary.alembicPotionsHelp}
    label.autoHeight = true
    label.autoWidth = true
    label.wrapText = true
end

-- Count modifier for potion1 -> get power without modifier
-- Count modifier for potion2 -> get power without modifier
-- Count new modifier -> power = PWOM *nm


function alembic:getEffectsArray(contents, apparatusQuality)
    local result = {}
    local sameEffectsRequired = 0
    local sameEffectsFound = 0
    local count = self:countContents()
    for _, item in pairs(contents) do
        if count > 1 then
            local effectsCount = item:getActiveEffectCount()
            effectsCount = math.floor(0.5 + effectsCount/2)
            sameEffectsRequired = math.max(sameEffectsRequired, effectsCount)
        end

        local comboModifier = effects.getModifier(item.effects)

        local i = 1 -- effect Array index
        local j = 1 -- current potion index
        while item.effects[j].id ~= -1 do
            mwse.log("%s %s", i, j)
            local effect = item.effects[j]
            if not result[i] then
                --mwse.log("adding new effect %s", effect.name)
                result[i] = {}
                result[i].id = effect.id
                local power = formulas.getEffectPower(effect)
                result[i].power = power * 100 / (100 + 10*comboModifier)
                -- result[i].magnitude, result[i].duration = formulas.getEffectMagnitudeDuration(effect.id, power, self.magnitudeDurationValue)
                result[i].attribute = effect.attribute
                result[i].skill = effect.skill
                j = j + 1
                i = 1
            elseif result[i].id == effect.id and effect.attribute == result[i].attribute then -- support skill based effects?
                -- mwse.log("found same effect %s", effect.name)
                if self.mode == 0 then
                    --mwse.log("mode 0: concentrate")
                    local power = formulas.getEffectPower(effect)
                    power = power * 100 / (100 + 10*comboModifier) + result[i].power
                    power = formulas.limitMaxPower(power, apparatusQuality)
                    result[i].power = power
                    -- result[i].magnitude, result[i].duration = formulas.getEffectMagnitudeDuration(effect.id, power, self.magnitudeDurationValue)
                    j = j + 1
                    i = 1
                    sameEffectsFound = sameEffectsFound + 1
                elseif self.mode == 1 then
                    --mwse.log("mode 1: filter")
                    local power = formulas.getEffectPower(effect)
                    power = power * 100 / (100 + 10*comboModifier) - result[i].power
                    power = formulas.limitMinPower(power, apparatusQuality)
                    result[i].power = power
                    -- result[i].magnitude, result[i].duration = formulas.getEffectMagnitudeDuration(effect.id, power, self.magnitudeDurationValue)
                    j = j + 1
                    i = 1
                    sameEffectsFound = sameEffectsFound + 1
                end
            else
                i = i + 1
            end
        end
    end
    if sameEffectsFound >= sameEffectsRequired then

        local newModifier = effects.getModifier(result)

        for i, effect in ipairs(result) do
            result[i].power = effect.power + effect.power*0.1*newModifier
            result[i].magnitude, result[i].duration = formulas.getEffectMagnitudeDuration(effect.id, result[i].power, self.magnitudeDurationValue)
        end

        return result
    else
        return {}
    end
end


function alembic:getFilterEffectList(inventory)
    return common.getPotionEffectList(inventory)
end


-- function alembic:selectItem(e)
--     local source = e.source
--     self:createSelectionMenu()
--     event.clear("alchemyArt_itemSelected")
--     event.register("alchemyArt_itemSelected", function(params)
--         self:onItemSelected()
--         local selectedObject = params.item
--         ui.createItemImage(source, selectedObject)
--         local menu = tes3ui.findMenu(self.menuName)
--         source:register("mouseClick", function (removeParams)
--             self:removeSelected(removeParams)
--         end)
--         event.clear("alchemyArt_itemSelected")
--         self.contents[source.name] = selectedObject
--         menu:updateLayout()
--         -- self:updateSameEffects()
--     end)
-- end

local function onSliderChanged(e)
    alembic.magnitudeDurationValue = e.source.widget.current + 1
end

local function onModeButtonValueChange(e)
    if e.source.widget.value == 0 then
        alembic.mode  = 0
        ui.selectedEffectColor = tes3ui.getPalette("header_color")
    elseif e.source.widget.value == 1 then
        alembic.mode  = 1
        ui.selectedEffectColor = tes3ui.getPalette("negative_color")
    end
end

function alembic:createLeftBlock(element)
    self.magnitudeDurationValue = 3
    self.mode = 0
    mwse.log("selected color is header")
    local leftBlock = ui.createAutoBlock(element, self.menuName.."_left")
    leftBlock.flowDirection = "top_to_bottom"
    -- leftBlock.borderBottom = 10
    leftBlock.borderTop = 31
    -- local sliderLabelsBlock = ui.createAutoBlock(leftBlock, self.menuName.."_sliderLabels")
    -- sliderLabelsBlock.flowDirection = "left_to_right"
    -- local magnitudeLabel = sliderLabelsBlock:createLabel{id = self.menuName.."_magnitude_label", text = common.dictionary.magn}
    -- magnitudeLabel.borderLeft = 4
    -- local durationLabel =sliderLabelsBlock:createLabel{id = self.menuName.."_duration_label", text = common.dictionary.dur}
    -- durationLabel.borderLeft = 54
    -- local slider = leftBlock:createSlider{id = self.menuName.."_durationMagnitudeSlider", min = 0, current = 2, max = 4}
    -- slider.autoHeight = true
    -- slider.autoWidth = true
    -- slider.borderLeft = 4
    -- slider.borderBottom = 30
    -- slider.minWidth = 200
    -- slider:register("PartScrollBar_changed", onSliderChanged)
    local modeButton = leftBlock:createCycleButton{
        id = self.menuName.."_modeButton",
        options = {{text="Concentrate", value = 0}}
    }
    modeButton.minWidth = 130
    modeButton.minHeight = 30
    modeButton.borderBottom = 15
    modeButton.widget:addOption{text="Filter", value = 1}
    local modeButtonText = modeButton:findChild("PartButton_text_ptr")
    modeButtonText.wrapText = true
    modeButtonText.justifyText = tes3.justifyText.center
    modeButton:register("valueChanged", onModeButtonValueChange)
    if common.config.tutorialMode then
        modeButton:register("mouseOver", self.showModeTutorial)
    end
    local potionsLabel = leftBlock:createLabel{id = self.menuName.."_potions_label", text = common.dictionary.potions}
    if common.config.tutorialMode then
        potionsLabel:register("mouseOver", self.showPotionsTutorial)
    end
    local potionsBlock = ui.createAutoBlock(leftBlock, self.menuName.."_potions")
    local potion1 = ui.createItemSlot(potionsBlock, self.menuName.."_potion1", function (e)
        self:selectItem(e)
    end)
    local potion2 = ui.createItemSlot(potionsBlock, self.menuName.."_potion2", function (e)
        self:selectItem(e)
    end)
end

return alembic