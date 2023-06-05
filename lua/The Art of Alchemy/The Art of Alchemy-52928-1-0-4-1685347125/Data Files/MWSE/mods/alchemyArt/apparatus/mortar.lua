local ui = require("alchemyArt.ui")
local common = require("alchemyArt.common")
local apparatus = require("alchemyArt.apparatus.apparatus")
local formulas = require("alchemyArt.formulas")
local specialEffects = require("alchemyArt.specialEffects")
local ingredients = require("alchemyArt.ingredients.ingredients")
local ingredType = require("alchemyArt.ingredients.ingredType")

local mortar = apparatus:new()

mortar.menuName = "MenuMortar"
mortar.notEnoughContentsMessage = common.dictionary.atLeastOnePotion
mortar.filterBy = tes3.objectType.ingredient
mortar.maxItems = nil
mortar.rightBlockLeftBorder = 131
mortar.timer = nil
mortar.maxItems = false

mortar.showMainTutorial = function (e)
    local tooltip = tes3ui.createTooltipMenu()
	tooltip.autoHeight = true
	tooltip.autoWidth = true
    tooltip.wrapText = true
    local label =  tooltip:createLabel{text = common.dictionary.mortarHelp}
    label.autoHeight = true
    label.autoWidth = true
    label.wrapText = true
end

function mortar:alchemyEnd(reference)
    self.timer:cancel()
    specialEffects.mortarAnimationEnd(reference)
    self:cleanUp(reference)
end

function mortar:startTimer(reference)
    -- tes3.messageBox("Starting Mortar Timer")
    specialEffects.mortarAnimationBegin(reference)
    local numTries = math.floor(2 * reference.object.quality * reference.data.alchemyArt.count)
    local iterations = numTries - reference.data.alchemyArt.progress
    local alchemyTime = common.config.alchemyTime/12
    local ingred = reference.data.alchemyArt.contents[1]
    local grinded = ingredType.wholeToGrinded[ingred]
    local maxSuccess = reference.data.alchemyArt.count
    if ingredType.insoluble[ingred] then
        maxSuccess = 3 * maxSuccess
    end
    
    grinded = tes3.getObject(grinded)

    self.timer = timer.start{
        duration = alchemyTime/(2 * reference.object.quality),
        iterations = iterations,
        type = timer.game,
        callback = function ()
            reference.data.alchemyArt.progress = reference.data.alchemyArt.progress + 1
            if formulas.getSuccess() then
                tes3.messageBox(common.dictionary.itemCreated, grinded.name)
                tes3.addItem{reference = tes3.player, item = grinded}
                common.practiceAlchemy(0.5)
                reference.data.alchemyArt.success = reference.data.alchemyArt.success + 1
                if reference.data.alchemyArt.success >= maxSuccess then
                    self:alchemyEnd(reference)
                end
            end
            if reference.data.alchemyArt.progress >= numTries then
                tes3.messageBox(common.dictionary.itemDestroyed, tes3.getObject(ingred).name)
                self:alchemyEnd(reference)
            end
        end
    }
end

function mortar:alchemyBegin(reference)

    reference.data.alchemyArt = reference.data.alchemyArt or {}
    reference.data.alchemyArt.contents =  self:removeContentsFromPlayer()
    -- tes3.messageBox("Current count: %s", self.count)
    reference.data.alchemyArt.count = self.count
    reference.data.alchemyArt.progress = 0
    reference.data.alchemyArt.success = 0
    self:startTimer(reference)


    -- self:removeContentsFromPlayer()
    -- specialEffects.mortarAnimationBegin(reference)
    -- local ingred = self.contents[self.menuName.."_ingredient"]
    -- local grinded = ingredType.wholeToGrinded[ingred.id]
    -- grinded = tes3.getObject(grinded)
    -- local numTries = 2 * reference.object.quality
    -- local countTries = 0
    -- local countSuccess = 0
    -- local maxSuccess = 3
    -- mortarIterations = timer.start{
    --     duration = 3,
    --     iterations = numTries,
    --     callback = function ()
    --         if formulas.getSuccess() then
    --             tes3.messageBox(common.dictionary.itemCreated, grinded.name)
    --             tes3.addItem{reference = tes3.player, item = grinded}
    --             countSuccess = countSuccess + 1
    --             if countSuccess >= maxSuccess then
    --                 mortar:alchemyEnd(reference)
    --             end
    --         end
    --         countTries = countTries + 1
    --         if countTries >= numTries then
    --             mortar:alchemyEnd(reference)
    --         end
    --     end
    -- }
end

function mortar:ingredientPassesFilter(item)

    local grinded = ingredType.wholeToGrinded[item.id]

    if not grinded then
        return false
    end

    if common.filteredEffect then
        for i, effect in ipairs(item.effects) do
            if effect == common.filteredEffect.id then
                return true
            end
        end
    else
        return true
    end
    return false
end

function mortar:getFilterEffectList(inventory)
    return ingredients.getGrindableEffectList(inventory)
end

function mortar:createLeftBlock(element)
    local leftBlock = ui.createAutoBlock(element, self.menuName.."_left")
    leftBlock.flowDirection = "top_to_bottom"
    leftBlock.borderTop = 78
    leftBlock:createLabel{id = self.menuName.."_ingredient_label", text = common.dictionary.ingredient}
    --local ingredientsBlock = ui.createAutoBlock(leftBlock, self.menuName.."potion")
    local ingredientBlock = ui.createAutoBlock(leftBlock, "MenuMortar_ingredientBlock")
    local ingredientSlot = ui.createItemSlot(ingredientBlock, self.menuName.."_ingredient", function (e)
        self:selectItem(e)
    end)
    local scrollpane = ingredientBlock:createVerticalScrollPane{id = "counter"}
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

return mortar