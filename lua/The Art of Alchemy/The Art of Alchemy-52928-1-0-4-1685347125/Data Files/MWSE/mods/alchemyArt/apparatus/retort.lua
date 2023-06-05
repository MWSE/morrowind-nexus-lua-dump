local ui = require("alchemyArt.ui")
local common = require("alchemyArt.common")
local formulas = require("alchemyArt.formulas")
local specialEffects = require("alchemyArt.specialEffects")
local apparatus = require("alchemyArt.apparatus.apparatus")
local ingredType = require("alchemyArt.ingredients.ingredType")
local effects = require("alchemyArt.effects")

local retort = apparatus:new()

retort.menuName = "MenuRetort"
retort.notEnoughContentsMessage = common.dictionary.retortIngredientNotSelected
retort.count = 1
retort.rightBlockLeftBorder = 16
retort.filterBy = tes3.objectType.ingredient

retort.showMainTutorial = function(e)
    local tooltip = tes3ui.createTooltipMenu()
	tooltip.autoHeight = true
	tooltip.autoWidth = true
    tooltip.wrapText = true
    local label =  tooltip:createLabel{text = common.dictionary.retortHelp}
    label.autoHeight = true
    label.autoWidth = true
    label.wrapText = true
end

retort.showIngredTutorial = function(e)
    local tooltip = tes3ui.createTooltipMenu()
	tooltip.autoHeight = true
	tooltip.autoWidth = true
    tooltip.wrapText = true
    local label =  tooltip:createLabel{text = common.dictionary.retortIngredHelp}
    label.autoHeight = true
    label.autoWidth = true
    label.wrapText = true
end


function retort:onItemSelected()
    local menu = tes3ui.findMenu(self.menuName)
    for slot, item in pairs(self.contents) do
        if item then
            slot = menu:findChild(slot)
            local countLabel = slot:findChild("Ingredient_count")
            if countLabel and countLabel.text then
                countLabel:destroy()
            end
        end
    end
    self.count = 1
end

local function spoil(effects, harmful, n)
    for effect, attrCount in pairs(effects) do
        for attribute, count in pairs(attrCount) do
            if count == 1 then
                local magicEffect = tes3.getMagicEffect(effect)
                if harmful ~= magicEffect.isHarmful then
                    local chance = 1/n
                    if math.random() < chance then
                        effects[effect][attribute] = 2
                        return effects
                    end
                    n = n-1
                end
            end
        end
    end
end

function retort:getEffectsArray(contents, apparatusQuality)

    local effectsAll = {}
    local effectsForThisIngred
    local moreThanOne = 0
    local harmful
    local numPositives = 0
    local numNegatives = 0
    for _, ingred in pairs(contents) do
        effectsForThisIngred = {}
        for i, effect in ipairs(ingred.effects) do

            if i == 2 and ingredType.poorlySoluble[ingred.id] then
                break
            end

            if effect == -1 then
                break
            end

            local magicEffect = tes3.getMagicEffect(effect)
            local attribute = -1

            if magicEffect.targetsAttributes then
                attribute = ingred.effectAttributeIds[i]
            elseif magicEffect.targetsSkills then 
                attribute = ingred.effectSkillIds[i]
            end

            if not effectsForThisIngred[attribute] or not effectsForThisIngred[attribute][effect] then
                effectsAll[effect] = effectsAll[effect] or {}
                effectsAll[effect][attribute] = effectsAll[effect][attribute] and effectsAll[effect][attribute] + 1 or 1
                if effectsAll[effect][attribute] > 1 then
                    moreThanOne = moreThanOne + 1
                    harmful = tes3.getMagicEffect(effect).isHarmful
                else
                    if tes3.getMagicEffect(effect).isHarmful then
                        numNegatives = numNegatives + 1
                    else
                        numPositives = numPositives + 1
                    end
                end
                effectsForThisIngred[attribute] = effectsForThisIngred[attribute] or {}
                effectsForThisIngred[attribute][effect] = true
            end
        end
    end

    if not formulas.getSuccess() then
        if moreThanOne == 1 then
            local n = harmful and numPositives or numNegatives
            effectsAll = spoil(effectsAll, harmful, n)
        end
    end

    local power = formulas.getPower(apparatusQuality)
    local result = {}
    local i = 1

    --resultSet = {}


    for effect, attrCount in pairs(effectsAll) do
        for attribute, count in pairs(attrCount) do
            power = count > 2 and power * 1.5 or power
            if count >= 2 then
                local magnitude
                local duration
                -- magnitude, duration = formulas.getEffectMagnitudeDuration(effect, power)
                -- resultSet[effect] = resultSet[effect] or {}
                -- resultSet[effect][attribute] = {
                --     magnitude = magnitude,
                --     duration = duration
                --     power = power
                -- }
                result[i] = {}
                result[i].id = effect
                result[i].magnitude, result[i].duration = formulas.getEffectMagnitudeDuration(effect, power)
                result[i].attribute = attribute
                result[i].skill = attribute
                result[i].power = power
                i = i + 1
            end
        end
    end

    local comboModifier = effects.getModifier(result)
    for j, effect in ipairs(result) do
        result[j].power = effect.power + effect.power*0.1*comboModifier
        result[j].magnitude, result[j].duration = formulas.getEffectMagnitudeDuration(effect.id, result[j].power) --, self.magnitudeDurationValue
    end

    local function sortFunction(a,b)
        if a.id == b.id then
            return a.attribute < b.attribute
        else
            return a.id < b.id
        end
    end

    table.sort(result, sortFunction)

    return result
end

function retort:pickResultEnd(reference)
    specialEffects.removeRetortFire(reference)
end

function retort:addVisualEffect(reference)
    specialEffects.addRetortFire(reference)
end

function retort:createLeftBlock(element)
    local leftBlock = ui.createAutoBlock(element, "MenuRetort_left")
    leftBlock.flowDirection = "top_to_bottom"
    leftBlock.borderTop = 78
    local ingredLabel = leftBlock:createLabel{id = "MenuRetort_ingredients_label", text = common.dictionary.ingredients}
    if common.config.tutorialMode then
        ingredLabel:register("mouseOver", self.showIngredTutorial)
    end
    local ingredientsBlock = ui.createAutoBlock(leftBlock, "MenuRetort_ingredientBlock")
    local ingredient1 = ui.createItemSlot(ingredientsBlock, "MenuRetort_ingredient1", function (e)
        self:selectItem(e)
    end)
    local ingredient2 = ui.createItemSlot(ingredientsBlock, "MenuRetort_ingredient2", function (e)
        self:selectItem(e)
    end)
    local ingredient3 = ui.createItemSlot(ingredientsBlock, "MenuRetort_ingredient3", function (e)
        self:selectItem(e)
    end)
    local scrollpane = ingredientsBlock:createVerticalScrollPane{id = "counter"}
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

return retort