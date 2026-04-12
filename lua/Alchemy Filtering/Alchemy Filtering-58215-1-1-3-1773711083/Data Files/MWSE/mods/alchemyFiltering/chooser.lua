local log = mwse.Logger.new()
log.level = "DEBUG"
local i18n = require("alchemyFiltering.i18n")
local config = require("alchemyFiltering.config")
local common = require("alchemyFiltering.common")

local FullEffect = common.FullEffect
local IconText = common.IconText

local GUI_ID = {}
local chooser = {
    data = {},
}

local function registerGUI()
    if GUI_ID.loaded then return end

    -- Standard MenuAlchemy registered names
    -- GUI_ID.potion_name = tes3ui.registerID("MenuAlchemy_potion_name")
    -- GUI_ID.mortar_slot = tes3ui.registerID("MenuAlchemy_mortar_slot")
    -- GUI_ID.alembic_slot = tes3ui.registerID("MenuAlchemy_alembic_slot")
    -- GUI_ID.calcinator_slot = tes3ui.registerID("MenuAlchemy_calcinator_slot")
    -- GUI_ID.retort_slot = tes3ui.registerID("MenuAlchemy_retort_slot")
    GUI_ID.ingredient = {
        tes3ui.registerID("MenuAlchemy_ingredient_one"),
        tes3ui.registerID("MenuAlchemy_ingredient_two"),
        tes3ui.registerID("MenuAlchemy_ingredient_three"),
        tes3ui.registerID("MenuAlchemy_ingredient_four"),
    }
    GUI_ID.effectarea = tes3ui.registerID("MenuAlchemy_effectarea")
    GUI_ID.create_button = tes3ui.registerID("MenuAlchemy_create_button")
    -- GUI_ID.cancel_button = tes3ui.registerID("MenuAlchemy_cancel_button")

    -- Mod MenuAlchemy registered names
    GUI_ID.choose_effects_button = tes3ui.registerID("AF:MenuAlchemy_choose_effects_button")
    GUI_ID.choose_effects_block = tes3ui.registerID("AF:MenuAlchemy_choose_effects_block")
    GUI_ID.choose_effects_left = tes3ui.registerID("AF:MenuAlchemy_choose_effects_left")
    GUI_ID.choose_effects_right = tes3ui.registerID("AF:MenuAlchemy_choose_effects_right")
    GUI_ID.chosen_label = tes3ui.registerID("AF:MenuAlchemy_chosen_label")
    GUI_ID.chosen_effect_block = tes3ui.registerID("AF:MenuAlchemy_chosen_effect_block")

    -- Test related UI elements
    GUI_ID.test_button = tes3ui.registerID("AF:MenuAlchemy_test_button")

    GUI_ID.loaded = true
end

function chooser:updateChosenEffectUi()
    if self.chosenEffect then
        self.chosenEffectElement:setPath(self.chosenEffect.magicEffect.icon)
        self.chosenEffectElement:setText(self.chosenEffect.name)
        self.chosenLabel.visible = true
        self.chosenEffectElement.block.visible = true
    else
        self.chosenLabel.visible = false
        self.chosenEffectElement.block.visible = false
    end
    self.menu:updateLayout()
end

function chooser:setChosenEffect(effect)
    self.chosenEffect = effect
    self:updateChosenEffectUi()
end

--- Gets all the effects availabled from the 4 possible ingredient slots
function chooser:getSelectedEffects()
    local selected = false
    local effects = {}
    if self.menu then
        for _, ingredientId in ipairs(GUI_ID.ingredient) do
            local ingredient = self.menu:findChild(ingredientId):getPropertyObject("MenuAlchemy_object") -- tes3ingredient
            for _, effect in FullEffect:visibleEffects(ingredient) do
                effects[effect.id] = effect
                selected = true
            end
        end
    end

    if selected then
        self.selectedEffects = effects
    else
        self.selectedEffects = nil
    end
end

local function onTestClick(e)
    log:debug("onTestClick")
    local menu = tes3ui.findMenu("MenuAlchemy")
    common:logTree(menu)
end

local function getMenuAlchemySlotIngredients()
    local ingredients = {}
    if chooser.menu then
        for _, ingredientId in ipairs(GUI_ID.ingredient) do
            local ingredient = chooser.menu:findChild(ingredientId):getPropertyObject("MenuAlchemy_object") -- tes3ingredient
            if ingredient then
                ingredients[ingredient.id] = ingredient
            end
        end
    end
    return ingredients
end

local function getInventoryIngredients()
    local ingredients = {}

    -- Iterating over ingredients in the inventory
    for _, stack in pairs(tes3.player.object.inventory) do
        if stack.object.objectType == tes3.objectType.ingredient then
            ingredients[stack.object.id] = stack.object
        end
    end

    -- Iterating over ingredients selected by MenuAlchemy slots
    for _, ingredient in pairs(getMenuAlchemySlotIngredients()) do
        ingredients[ingredient.id] = ingredient
    end
    return ingredients
end

--- Gets all the effects which have at least 2 ingredients from the inventory
local function getInventoryEffects()
    local effects = {}
    for _, ingredient in pairs(getInventoryIngredients()) do
        for _, effect in FullEffect:visibleEffects(ingredient) do
            effects[effect.id] = effects[effect.id] or {count = 0}
            effects[effect.id].count = effects[effect.id].count + 1
            effects[effect.id].effect = effect
        end
    end

    for id, info in pairs(effects) do
        if info.count >= 2 then
            effects[id] = info.effect
        else
            effects[id] = nil
        end
    end

    return effects
end

local function getInventorySplitEffects(effects)
    local splitEffects = {}
    for _, effect in pairs(effects) do
        splitEffects[effect.name1] = splitEffects[effect.name1] or {}
        table.insert(splitEffects[effect.name1], effect)
    end
    return splitEffects
end

local function uiTextCompare(a, b)
    return a.text < b.text
end

--- Updates the active item in the given pane<br>
--- If item is nil, then deactivates any ative item<br>
--- If item is valid, then toggles that active state, deactivating other active items
--- @return boolean activeState true when item is active else false
function chooser:updateActivatedColor(paneId, item)
    if self.activeTexts[paneId] then
        self.activeTexts[paneId].widget.state = tes3.uiState.normal
        if self.activeTexts[paneId] == item then
            self.activeTexts[paneId] = nil
            return false
        end
    end
    self.activeTexts[paneId] = item
    if item then
        item.widget.state = tes3.uiState.active
        return true
    end
    return false
end

local function onChooserTextClick(e)
    chooser:onChooserTextClick(e.source)
end

function chooser:onChooserTextClick(effectText)
    local paneId = effectText:getPropertyInt("AF:paneId")
    local effectList = effectText:getLuaData("AF:effectList")
    local effect = nil
    if #effectList == 1 then
        effect = effectList[1]
    end
    local isActivated = self:updateActivatedColor(paneId, effectText)
    self.chooseEffectsRight.visible = true
    if paneId == self.chooseEffectsLeft.id then
        self.chooseEffectsRight.visible = isActivated
        self:updateActivatedColor(self.chooseEffectsRight.id, nil)
        self.chooseEffectsRight:getContentElement():destroyChildren()
        if #effectList == 1 then
            self.chooseEffectsRight.visible = false
        end
        if self.chooseEffectsRight.visible then
            -- Populate right pane
            for _, effectRight in ipairs(effectList) do
                local effectElement = IconText:create{parent = self.chooseEffectsRight,
                path = effectRight.magicEffect.icon,
                text = effectRight.name}
                effectElement.block:setPropertyInt("AF:paneId", self.chooseEffectsRight.id)
                effectElement.block:setLuaData("AF:effectList", {effectRight})
                effectElement:register("mouseClick", onChooserTextClick)
                if self.chosenEffect and effectRight.id == self.chosenEffect.id then
                    self:onChooserTextClick(effectElement.block)
                    effect = effectRight
                end
            end
            self.chooseEffectsRight:getContentElement():sortChildren(uiTextCompare)
        end
    end
    if isActivated then
        self:setChosenEffect(effect)
    else
        self:setChosenEffect(nil)
    end
end

function chooser:createUi()
    if not self.menu then
        return
    end
    if self.chooseButton then
        self.chooseButton.widget.state = tes3.uiState.active
    end

    self.chooseBlock.visible = true
    if self.chooseEffectsLeft then
        -- Already created, so just update the contents
        self.chooseEffectsLeft:getContentElement():destroyChildren()
        self.chooseEffectsRight:getContentElement():destroyChildren()
    else
        -- Need to create the left and right panes
        self.chooseEffectsLeft = self.chooseBlock:createVerticalScrollPane{id = GUI_ID.choose_effects_left}
        self.chooseEffectsLeft.autoHeight = true
        self.chooseEffectsLeft.autoWidth = true
        self.chooseEffectsRight = self.chooseBlock:createVerticalScrollPane{id = GUI_ID.choose_effects_right}
        self.chooseEffectsRight.autoHeight = true
        self.chooseEffectsRight.autoWidth = true
    end
    self.chooseEffectsRight.visible = false

    self.activeTexts = {}

    -- Populate left pane
    local effects = getInventoryEffects()
    if self.chosenEffect and not effects[self.chosenEffect.id] then
        self.chosenEffect = nil
    end
    for nameLeft, effectsListRight in pairs(getInventorySplitEffects(effects)) do
        local effectElement = IconText:create{parent = self.chooseEffectsLeft,
        text = nameLeft}
        effectElement.block:setPropertyInt("AF:paneId", self.chooseEffectsLeft.id)
        effectElement.block:setLuaData("AF:effectList", effectsListRight)
        effectElement:register("mouseClick", onChooserTextClick)
        if #effectsListRight == 1 then
            effectElement:setPath(effectsListRight[1].magicEffect.icon)
            effectElement:setText(effectsListRight[1].name)
        end
        if self.chosenEffect and nameLeft == self.chosenEffect.name1 then
            self:onChooserTextClick(effectElement.block)
        end
    end
    self.chooseEffectsLeft:getContentElement():sortChildren(uiTextCompare)
end

function chooser:destroyUi()
    self.chooseBlock:destroyChildren()
    self.chooseBlock.visible = false
    if self.chooseButton then
        self.chooseButton.widget.state = tes3.uiState.normal
    end
    self:uiDestroyed(false)
    self.menu:updateLayout()
end

function chooser:uiDestroyed(topLevelMenu)
    -- Clean up UI elements
    if topLevelMenu then
        self.menu = nil
        self.createButton = nil
        self.testButton = nil
        self.chooseBlock = nil
        self.chooseButton = nil
        self.chosenLabel = nil
        self.chosenEffectElement = nil
    end
    self.chooseEffectsLeft = nil
    self.chooseEffectsRight = nil
    self.activeTexts = {}

    -- Clean up chosen and selected effects
    self.selectedEffects = nil
    if topLevelMenu then
        if not config.chosenEffectSticky then
            self.chosenEffect = nil
        end
    else
        -- setChosenEffect() tries to update UI elements
        self:setChosenEffect(nil)
    end

end

function chooser:updateUi()
    if self.data.active then
        self:createUi()
        self:updateChosenEffectUi()
    else
        self:destroyUi()
    end
end

local function onChooseEffects(e)
    chooser.data.active = not chooser.data.active
    chooser:updateUi()
end

local function onIngredientClick(e)
    chooser:getSelectedEffects()
end

local function onCreateClick()
    chooser.visibleEffectsCount = common:getVisibleEffectsCount()
    chooser.slotIngredients = getMenuAlchemySlotIngredients()
end

local function onPotionAttempted()
    if not config.modEnabled then return end

    -- Check if any of the slot ingredients are used up
    local newInventoryIngredients = getInventoryIngredients()
    for id, _ in pairs(chooser.slotIngredients) do
        if not newInventoryIngredients[id] then
            chooser:updateUi()
            return
        end
    end
    -- Check if we can see more effects
    local newVisibleEffectsCount = common:getVisibleEffectsCount()
    if newVisibleEffectsCount ~= chooser.visibleEffectsCount then
        chooser.visibleEffectsCount = newVisibleEffectsCount
        chooser:updateUi()
        return
    end
end

function chooser:mergeWithMenuAlchemy(menu)
    if not menu then return end
    self.menu = menu
    self.visibleEffectsCount = common:getVisibleEffectsCount()
    self.menu:register("destroy", function() self:uiDestroyed(true) end)
    self.createButton = self.menu:findChild(GUI_ID.create_button)
    self.createButton:registerBefore("mouseClick", onCreateClick)
    local buttonBlock = self.createButton.parent

    local effectarea = self.menu:findChild(GUI_ID.effectarea)
    self.chosenLabel = effectarea.parent:createLabel{id = GUI_ID.chosen_label, text = i18n("chosenEffect")}

    self.chosenEffectElement = IconText:create{parent = effectarea.parent,
    isLabel = true,
    id = GUI_ID.chosen_effect_block}

    self.chooseButton = buttonBlock:createButton{id = GUI_ID.choose_effects_button, text = i18n("chooseEffects")}
    self.chooseButton:register("mouseClick", onChooseEffects)
    self.chooseButton:reorder{before = self.createButton}

    -- Option to create test button for debugging
    if false then
        self.testButton = buttonBlock:createButton{id = GUI_ID.test_button, text = "Test"}
        self.testButton:register("mouseClick", onTestClick)
        self.testButton:reorder{before = self.chooseButton}
    end

    self.chooseBlock = self.menu:createBlock{id = GUI_ID.choose_effects_block}
    self.chooseBlock.autoWidth = true
    self.chooseBlock.height = config.chooserHeight
    self.chooseBlock.widthProportional = 1.0
    self.chooseBlock:reorder{before = buttonBlock}

    -- Hook into ingredient clicks
    for _, ingredientId in ipairs(GUI_ID.ingredient) do
        local ingredient = self.menu:findChild(ingredientId)
        ingredient:registerBefore("mouseClick", onIngredientClick)
    end

    self:updateUi()
end

function chooser:detachFromMenuAlchemy()
    common:destroyAll{
        self.chosenLabel,
        self.chosenEffectElement,
        self.chooseButton,
        self.chooseBlock,
        self.testButton,
    }

    if self.menu then
        -- Unhook from ingredient clicks
        for _, ingredientId in ipairs(GUI_ID.ingredient) do
            local ingredient = self.menu:findChild(ingredientId)
            ingredient:unregisterBefore("mouseClick", onIngredientClick)
        end

        self.createButton:unregisterBefore("mouseClick", onCreateClick)
        self.menu:updateLayout()
    end
    self:uiDestroyed(true)
end

local function onMenuAlchemy(e)
    if not config.modEnabled then return end
    if not e.newlyCreated then return end
    chooser:mergeWithMenuAlchemy(e.element)
end

function chooser:onModConfigEntryClosed()
    if config.modEnabled then
        local menuAlchemy = tes3ui.findMenu("MenuAlchemy")
        if not menuAlchemy and not config.chosenEffectSticky then
            self.chosenEffect = nil
        end
        if self.menu then
            self.chooseBlock.height = config.chooserHeight
            self.menu:updateLayout()
        else
            self:mergeWithMenuAlchemy(menuAlchemy)
        end
    else
        self.data.active = false
        self.chosenEffect = nil
        self:detachFromMenuAlchemy()
    end
end

local function onLoaded(e)
    tes3.player.data.alchemyFiltering = tes3.player.data.alchemyFiltering or {}
    chooser.data = tes3.player.data.alchemyFiltering
end

function chooser:init()
    if not GUI_ID.loaded then
        event.register("loaded", onLoaded)
        event.register("uiActivated", onMenuAlchemy, {filter = "MenuAlchemy"})
        event.register("potionBrewed", onPotionAttempted)
        event.register("potionBrewFailed", onPotionAttempted)
    end
    registerGUI()
end

return chooser
