local log = mwse.Logger.new()
log.level = "DEBUG"
local strings = require("alchemyFiltering.strings")
local config = require("alchemyFiltering.config")

local GUI_ID = {}
local chooser = {
	data = {},
}

local function getVisibleEffectsCount()
    local skill = tes3.mobilePlayer.alchemy.current
    local gmst = tes3.findGMST(tes3.gmst.fWortChanceValue)
    return math.clamp(math.floor(skill / gmst.value), 0, 4)
end

--- Split the string in two at the first instance of the delimiter
local function splitString(str, delimiter)
    local startIndex, endIndex = string.find(str, delimiter, 1, true)

    if startIndex then
        -- Extract the part before the delimiter (from 1 to start_index - 1)
        local part1 = string.sub(str, 1, startIndex - 1)
        -- Extract the part after the delimiter (from end_index + 1 to the end)
        local part2 = string.sub(str, endIndex + 1)
        return part1, part2
    else
        -- Delimiter not found
        return str, nil
    end
end

--- Get a set of effects which also have additional IDs,
--- such as Attributes or Skills
local russianAttributes = {
	[0] = "Силу",
	[1] = "Интеллект",
	[2] = "Силу волу",
	[3] = "Ловкость",
	[4] = "Скорость",
	[5] = "Выносливость",
	[6] = "Привлекательность",
	[7] = "Удачу"
}
local russianSkills = {
	[0] = "Защиту",
	[1] = "Кузнеца",
	[2] = "Средние доспехи",
	[3] = "Тяжелые доспехи",
	[4] = "Дробящее оружие",
	[5] = "Длинные клинки",
	[6] = "Секиры",
	[7] = "Древковое оружие",
	[8] = "Атлетику",
	[9] = "Зачарование",
	[10] = "Разрушение",
	[11] = "Изменение",
	[12] = "Иллюзии",
	[13] = "Колдовство",
	[14] = "Мистицизм",
	[15] = "Восстановление",
	[16] = "Алхимию",
	[17] = "Бездоспешный бой",
	[18] = "Безопасность",
	[19] = "Скрытность",
	[20] = "Акробатику",
	[21] = "Легкие доспехи",
	[22] = "Короткие клинки",
	[23] = "Меткость",
	[24] = "Торговлю",
	[25] = "Красноречие",
	[26] = "Рукопашный бой"
}
local function getCompoundEffects(effectType)
	local effects = {}
	for name, effect in pairs(tes3.effect) do
		if string.match(name, effectType) then
			effects[effect] = true
		end
	end
	return effects
end

local attributeEffects = getCompoundEffects("Attribute")
local skillEffects = getCompoundEffects("Skill")

local FullEffect = {}
FullEffect.__index = FullEffect

function FullEffect:new(effectId, attributeId, skillId)
	local effect = {}
	setmetatable(effect, self)
	effect.effectId = effectId
	effect.attributeId = attributeId
	effect.skillId = skillId
	effect.id = effectId

	effect.magicEffect = tes3.getMagicEffect(effectId)

	effect.name1, effect.name2 = splitString(effect.magicEffect.name, " ")
	if effect.name2 then
		if attributeEffects[effectId] then
			effect.name2 = russianAttributes[attributeId]
			effect.id = effect.id + attributeId * 1000000
		elseif skillEffects[effectId] then
			effect.name2 = russianSkills[skillId]
			effect.id = effect.id + skillId * 1000000
		end
		effect.name2 = effect.name2:gsub("^%l", string.upper)
		effect.name = effect.name1 .. " " .. effect.name2
	else
		effect.name = effect.magicEffect.name
	end
	return effect
end

function FullEffect:fromIngredient(ingredient, i)
	return FullEffect:new(ingredient.effects[i], ingredient.effectAttributeIds[i], ingredient.effectSkillIds[i])
end

function FullEffect.ingredientIter(ingredient, state)
	state.i = state.i + 1
	if state.i > state.visibleCount then
		return nil
	end
	if ingredient.effects[state.i] < 0 then
		return nil
	end

	return state, FullEffect:fromIngredient(ingredient, state.i)
end

function FullEffect:visibleEffects(ingredient)
	if ingredient then
		return FullEffect.ingredientIter, ingredient, {i = 0, visibleCount = getVisibleEffectsCount()}
	else
		return function() return nil end
	end
end

IconText = {}
IconText.__index = IconText

--- Create a new block holing Icon and Text elements
---
--- The argument is a table holding various settings
--- * parent -  (required) the block in which the IconText will created
--- * textId - (optional) the registerd ID of the text element
--- * isLabel - (optional) if true, the text element is a Label, otherwise a TextSelect
--- * path - (optional) the path to the Icon
--- * text - (optional) the text of the text element
function IconText:create(args)
	local element = {}
	setmetatable(element, self)
	element.block = args.parent:createBlock()
	element.block.autoHeight = true
	element.block.autoWidth = true
	element.block.flowDirection = tes3.flowDirection.leftToRight
	element.icon = element.block:createImage()
	if args.isLabel then
		element.text = element.block:createLabel{id = args.textId}
	else
		element.text = element.block:createTextSelect{id = args.textId}
	end

	element:setPath(args.path)
	element:setText(args.text)
	return element
end

--- Sets the path to the Icon
---
--- If path is nil, then the Icon is hidden. The border will be updated
--- appropriately to maintain text alignment
function IconText:setPath(path)
	if path then
		self.icon.contentPath = "Icons\\" .. path
		self.icon.visible = true
		self.text.borderLeft = 10
	else
		self.icon.visible = false
		self.text.borderLeft = 10 + 16
	end
end

--- Sets the text to be displayed
---
--- Also sets the text of the block, which is not visible, but allows
--- for the block itself to be sorted based on the text value.
function IconText:setText(text)
	self.block.text = text
	self.text.text = text
end

local function registerGUI()
	-- Standard registered names
	GUI_ID.MenuAlchemy = tes3ui.registerID("MenuAlchemy")
	GUI_ID.potion_name = tes3ui.registerID("MenuAlchemy_potion_name")
	GUI_ID.mortar_slot = tes3ui.registerID("MenuAlchemy_mortar_slot")
	GUI_ID.alembic_slot = tes3ui.registerID("MenuAlchemy_alembic_slot")
	GUI_ID.calcinator_slot = tes3ui.registerID("MenuAlchemy_calcinator_slot")
	GUI_ID.retort_slot = tes3ui.registerID("MenuAlchemy_retort_slot")
	GUI_ID.ingredient = {
		tes3ui.registerID("MenuAlchemy_ingredient_one"),
		tes3ui.registerID("MenuAlchemy_ingredient_two"),
		tes3ui.registerID("MenuAlchemy_ingredient_three"),
		tes3ui.registerID("MenuAlchemy_ingredient_four"),
	}
	GUI_ID.effectarea = tes3ui.registerID("MenuAlchemy_effectarea")
	GUI_ID.create_button = tes3ui.registerID("MenuAlchemy_create_button")
	GUI_ID.cancel_button = tes3ui.registerID("MenuAlchemy_cancel_button")

	GUI_ID.PartScrollPane_pane = tes3ui.registerID("PartScrollPane_pane")

	-- Mod registered names
	GUI_ID.MenuAlchemyChooseEffect = tes3ui.registerID("AF:MenuAlchemyChooseEffect")
	GUI_ID.choose_effects_button = tes3ui.registerID("AF:MenuAlchemy_choose_effects_button")
	GUI_ID.choose_effects_block = tes3ui.registerID("AF:MenuAlchemy_choose_effects_block")
	GUI_ID.choose_effects_left = tes3ui.registerID("AF:MenuAlchemy_choose_effects_left")
	GUI_ID.choose_effects_right = tes3ui.registerID("AF:MenuAlchemy_choose_effects_right")
	GUI_ID.filter_label = tes3ui.registerID("AF:MenuAlchemy_filter_label")
	GUI_ID.filter_effect_label = tes3ui.registerID("AF:MenuAlchemy_filter_effect_label")

	-- Test related UI elements
	GUI_ID.test_button = tes3ui.registerID("AF:MenuAlchemy_test_button")
end

--- Print out all the children recursively to examine the arrangement of UI elements
local function logTree(parent, indent)
	indent = indent or ""
	for _, c in ipairs(parent.children) do
		local t = c.text or "_"
		local p = c.contentPath or "_"
		local ty = c.type
		log:debug("" .. indent .. ty .. " " .. c.name .. " " .. c.id .. " " .. t .. " " .. p)

		for _, k in pairs({"name", "absolutePosAlignX", "absolutePosAlignY", "autoHeight", "autoWidth",
						    "height", "width", "flowDirection", "minHeight", "minWidth", "maxHeight", "maxWidth",
							"ignoreLayoutX", "ignoreLayoutY", "heightProportional", "widthProportional",
						    "childAlignX", "childAlignY", "childOffsetX", "childOffsetY", "paddingAllSides",
							"paddingBottom", "paddingLeft", "paddingRight", "paddingTop",
							"borderAllSides", "borderBottom", "borderLeft", "borderRight", "borderTop"}) do
			if c[k] then
				log:debug("  " .. indent .. "child[" .. k .. "] = " .. tostring(c[k]))
			end
		end

		logTree(c, indent .. "  ")
	end
end

function chooser:updateFilteringEffect()
	if self.chosenEffect then
		self.filterLabel.text = strings.filteringEffect
		self.filterEffectElement:setPath(self.chosenEffect.magicEffect.icon)
		self.filterEffectElement:setText(self.chosenEffect.name)
		self.filterEffectElement.block.visible = true
		self.filterEffects = {self.chosenEffect}
	else
		self.filterLabel.text = strings.filterMatchingEffects
		self.filterEffectElement.block.visible = false
		self.filterEffects = self.selectedEffects
	end
	self.menu:updateLayout()
end

function chooser:setChosenEffect(effect)
	self.chosenEffect = effect
	self:updateFilteringEffect()
end

--- Gets all the effects availabled from the 4 possible ingredient slots
function chooser:getSelectedEffects()
	local selected = false
	local effects = {}
	for _, ingredientId in ipairs(GUI_ID.ingredient) do
		local ingredient = self.menu:findChild(ingredientId):getPropertyObject("MenuAlchemy_object") -- tes3ingredient
		for _, effect in FullEffect:visibleEffects(ingredient) do
			effects[effect.id] = effect
			selected = true
		end
	end

	if selected then
		self.selectedEffects = effects
	else
		self.selectedEffects = nil
	end
	self:updateFilteringEffect()
end

local function onTestClick(e)
	log:debug("onTestClick")
	local menu = tes3ui.findMenu(GUI_ID.MenuAlchemy)
	logTree(menu)
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

local function getScrollPaneInner(pane)
	return pane:findChild(GUI_ID.PartScrollPane_pane)
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
		getScrollPaneInner(self.chooseEffectsRight):destroyChildren()
		if #effectList == 1 then
			self.chooseEffectsRight.visible = false
		end
		if self.chooseEffectsRight.visible then
			-- Populate right pane
			for _, effectRight in ipairs(effectList) do
				local effectElement = IconText:create{parent = self.chooseEffectsRight,
													  path = effectRight.magicEffect.icon,
													  text = effectRight.name}
				effectElement.text:setPropertyInt("AF:paneId", self.chooseEffectsRight.id)
				effectElement.text:setLuaData("AF:effectList", {effectRight})
				effectElement.text:register("mouseClick", onChooserTextClick)
				if self.chosenEffect and effectRight.id == self.chosenEffect.id then
					self:onChooserTextClick(effectElement.text)
					effect = effectRight
				end
			end
			getScrollPaneInner(self.chooseEffectsRight):sortChildren(uiTextCompare)
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
		getScrollPaneInner(self.chooseEffectsLeft):destroyChildren()
		getScrollPaneInner(self.chooseEffectsRight):destroyChildren()
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
		self:updateFilteringEffect()
	end
	for nameLeft, effectsListRight in pairs(getInventorySplitEffects(effects)) do
		local effectElement = IconText:create{parent = self.chooseEffectsLeft,
											  text = nameLeft}
		effectElement.text:setPropertyInt("AF:paneId", self.chooseEffectsLeft.id)
		effectElement.text:setLuaData("AF:effectList", effectsListRight)
		effectElement.text:register("mouseClick", onChooserTextClick)
		if #effectsListRight == 1 then
			effectElement:setPath(effectsListRight[1].magicEffect.icon)
			effectElement:setText(effectsListRight[1].name)
		end
		if self.chosenEffect and nameLeft == self.chosenEffect.name1 then
			self:onChooserTextClick(effectElement.text)
		end
	end
	getScrollPaneInner(self.chooseEffectsLeft):sortChildren(uiTextCompare)
	self.menu:updateLayout()
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
		self.filterLabel = nil
		self.filterEffectElement = nil
	end
	self.chooseEffectsLeft = nil
	self.chooseEffectsRight = nil
	self.activeTexts = {}

	-- Clean up filter state
	self.selectedEffects = nil
	if topLevelMenu then
		self.chosenEffect = nil
	else
		-- setChosenEffect() tries to update UI elements
		self:setChosenEffect(nil)
	end
	self.filterEffects = nil

end

function chooser:updateUi()
	if self.data.active then
		self:createUi()
	else
		self:destroyUi()
	end
end

local function onChooseEffects(e)
	chooser.data.active = not chooser.data.active
	chooser:updateUi()
end

local function onFilterInventorySelect(e)
	if not config.modEnabled then return end
	if e.type ~= "ingredient" then return end
	if e.item.objectType ~= tes3.objectType.ingredient then
		e.filter = false
		return false
	end

	if chooser.filterEffects then
		local filter = false
		for _, filterEffect in pairs(chooser.filterEffects) do
			for _, itemEffect in FullEffect:visibleEffects(e.item) do
				log:trace("  " .. itemEffect.name .. " " .. filterEffect.id .. " " .. itemEffect.id)
				if filterEffect.id == itemEffect.id then
					filter = true
					break
				end
			end
			if filter == true then
				break
			end
		end
		e.filter = filter
	end
end

local function onIngredientClick(e)
	chooser:getSelectedEffects()
end

local function onCreateClick()
	chooser.visibleEffectsCount = getVisibleEffectsCount()
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
	local newVisibleEffectsCount = getVisibleEffectsCount()
	if newVisibleEffectsCount ~= chooser.visibleEffectsCount then
		chooser.visibleEffectsCount = newVisibleEffectsCount
		chooser:updateUi()
		return
	end
end

-- This isn't actually needed for the mod to work, but it is useful for
-- debugging when your character gains alchemy skill causing more effects
-- to be visible, thus repopulating the chooser panes
local function onAlchemyRaised()
	if not config.modEnabled then return end
	log:debug("Alchemy raised")

	-- log:debug("Bump to skill 61")
	-- tes3.mobilePlayer.alchemy.current = 61
end

function chooser:mergeWithMenuAlchemy(menu)
	self.menu = menu
	self.visibleEffectsCount = getVisibleEffectsCount()
	self.menu:register("destroy", function() self:uiDestroyed(true) end)
	self.createButton = self.menu:findChild(GUI_ID.create_button)
	self.createButton:registerBefore("mouseClick", onCreateClick)
	local buttonBlock = self.createButton.parent

	local effectarea = self.menu:findChild(GUI_ID.effectarea)
	self.filterLabel = effectarea.parent:createLabel{id = GUI_ID.filter_label}

	self.filterEffectElement = IconText:create{parent = effectarea.parent,
											   isLabel = true,
											   textId = GUI_ID.filter_effect_label}

	self.chooseButton = buttonBlock:createButton{id = GUI_ID.choose_effects_button, text = strings.chooseEffects}
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

	chooser:updateUi()
	chooser:updateFilteringEffect()
end

function chooser:detachFromMenuAlchemy()
	if self.filterLabel then self.filterLabel:destroy() end
	if self.filterEffectElement then self.filterEffectElement.block:destroy() end
	if self.chooseButton then self.chooseButton:destroy() end
	if self.chooseBlock then self.chooseBlock:destroy() end
	if self.testButton then self.testButton:destroy() end

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

local function onLoaded(e)
	tes3.player.data.alchemyFiltering = tes3.player.data.alchemyFiltering or {}
	chooser.data = tes3.player.data.alchemyFiltering
end

local function onModConfigEntryClosed()
	if config.modEnabled then
		if not chooser.menu then
			local menu = tes3ui.findMenu(GUI_ID.MenuAlchemy)
			if menu then
				chooser:mergeWithMenuAlchemy(menu)
			end
		end
	else
		chooser.data.active = false
		chooser:detachFromMenuAlchemy()
	end
end

local function onInitialized(e)
	if config.modEnabled then
		log:debug("enabled")
	else
		log:debug("disabled")
		chooser.data.active = false
	end
	event.register("loaded", onLoaded)
	event.register("modConfigEntryClosed", onModConfigEntryClosed, {filter = strings.mcm.modName})
	event.register("uiActivated", onMenuAlchemy, {filter = "MenuAlchemy"})
	event.register("filterInventorySelect", onFilterInventorySelect)
	event.register("potionBrewed", onPotionAttempted)
	event.register("potionBrewFailed", onPotionAttempted)
	-- event.register("skillRaised", onAlchemyRaised, {filter = tes3.skill.alchemy})
	registerGUI()
end

event.register("initialized", onInitialized)
