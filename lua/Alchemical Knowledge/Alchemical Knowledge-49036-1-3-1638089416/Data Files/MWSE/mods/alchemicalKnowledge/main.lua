local common = require("alchemicalKnowledge.common")
local strings = require("alchemicalKnowledge.strings")

event.register("modConfigReady", function()
    require("alchemicalKnowledge.mcm")
	common.config  = require("alchemicalKnowledge.config")
end)

local GUI_ID = {}
local magicSchoolName = {}

local function registerGUI()
	GUI_ID.effectFilter = tes3ui.registerID("MenuEffectFilter")
	GUI_ID.scrollPane = tes3ui.registerID("MenuEffectFilter_ScrollPane")
	GUI_ID.effectLabel = tes3ui.registerID("MenuEffectFilter_EffectLabel")
	GUI_ID.createdPotion = tes3ui.registerID("MenuAlchemy_CreatedPotion")
	GUI_ID.parent = tes3ui.registerID("AK_Tooltip_Parent")
    GUI_ID[1] = tes3ui.registerID("AK_Tooltip_Effect1")
    GUI_ID[2] = tes3ui.registerID("AK_Tooltip_Effect2")
    GUI_ID[3] = tes3ui.registerID("AK_Tooltip_Effect3")
    GUI_ID[4] = tes3ui.registerID("AK_Tooltip_Effect4")
end

local function showPotionTooltip(potion)
	local tooltip = tes3ui.createTooltipMenu()
	tooltip.minWidth = 50
	tooltip.maxWidth = 1920
	tooltip.autoHeight = true
	tooltip.autoWidth = true
	tooltip.flowDirection = "top_to_bottom"
	local name = tooltip:createLabel{id=tes3ui.registerID("HelpMenu_name"), text=potion.name}
	name.color = tes3ui.getPalette("header_color")
	tooltip:createLabel{id=tes3ui.registerID("HelpMenu_weight"), text="Weight: "..string.format("%.2f", potion.weight)}
	tooltip:createLabel{id=tes3ui.registerID("HelpMenu_value"), text="Value: "..tostring(potion.value)}
	for i = 1, #potion.effects do
		if potion.effects[i].id >= 0 then
			local block = tooltip:createBlock{ id = tes3ui.registerID("HelpMenu_effectBlock") }
			block.minWidth = 1
			block.maxWidth = 640
			block.autoWidth = true
			block.autoHeight = true
			block.widthProportional = 1.0
			block:createImage{ path = string.format("icons\\%s", potion.effects[i].object.icon), id = tes3ui.registerID("HelpMenu_effectIcon") }
			local label = block:createLabel{ text = string.format("%s", potion.effects[i]), id = tes3ui.registerID("HelpMenu_effectLabel") }
			label.borderLeft = 4
			label.wrapText = false
		end
	end
	tooltip:updateLayout()
	event.trigger("uiObjectTooltip", {tooltip=tooltip, object=potion, count=1})
end

local function showEffectTooltip(effect)
	local tooltip = tes3ui.createTooltipMenu()
	tooltip.minWidth = 50
	tooltip.maxWidth = 1920
	tooltip.autoHeight = true
	tooltip.autoWidth = true
	tooltip.flowDirection = "top_to_bottom"
	local headerBlock = tooltip:createBlock({})
	headerBlock.flowDirection = "left_to_right"
	headerBlock.autoWidth = true
	headerBlock.autoHeight = true
	headerBlock.borderLeft = 8
	headerBlock.borderTop = 8
	local path = "icons\\" .. effect.icon
	local path = string.gsub(path, "([%w_]+%.)", "B_%1")
	local image = headerBlock:createImage{ path = path }
	image.borderTop = 2
	local textBlock = headerBlock:createBlock({})
	textBlock.flowDirection = "top_to_bottom"
	textBlock.autoWidth = true
	textBlock.autoHeight = true
	textBlock.borderLeft = 8
	local name = textBlock:createLabel{text = effect.name}
	name.color = tes3ui.getPalette("header_color")
	local school = textBlock:createLabel{text =  string.format("School: %s", magicSchoolName[effect.school])}
	--[[local descriptionBlock = tooltip:createBlock({})
	descriptionBlock.flowDirection = "top_to_bottom"
	descriptionBlock.autoWidth = true
	descriptionBlock.autoHeight = true
	descriptionBlock.borderLeft = 8
	descriptionBlock.borderTop = 6
	descriptionBlock.borderBottom = 8
	local label = descriptionBlock:createLabel{text = effect.description or description[effect.id]}
	label.wrapText = true]]
	tooltip:updateLayout()
end

local function updateEffectFilter(parent, effectList)
	local effectFilter = parent:findChild(GUI_ID.scrollPane)
	if effectFilter then
		effectFilter:destroy()
	end
	effectFilter = parent:createVerticalScrollPane{ id = GUI_ID.scrollPane}
	effectFilter.borderTop = 4
	for _, effect in ipairs(effectList) do
        effect = tes3.getMagicEffect(effect)
		local state = (effect == common.filteredEffect) and 4 or 1
        local labelText = effect.name
        local textSelect = effectFilter:createTextSelect({ id = GUI_ID.effectLabel, text = effect.name, state = state })
		if state == 4 then
			textSelect:triggerEvent("mouseLeave")
		end
		textSelect:register("help", function()
			showEffectTooltip(effect)
		end)
		textSelect:register("mouseClick", function()
			if textSelect.widget.state == 4 then
				common.filteredEffect = nil
				textSelect.widget.state = 1
			else
				for __, ts in ipairs(textSelect.parent.children) do
					if ts.widget.state == 4 then
						ts.widget.state = 1
						ts:triggerEvent("mouseLeave")
					end
				end
				common.filteredEffect = effect
				textSelect.widget.state = 4
			end
		end)
	end
end

local function onMenuAlchemy(e)
	common.filteredEffect = nil
	e.element:findChild().visible = false
	local rightBlock = e.element:findChild(tes3ui.registerID("MenuAlchemy_effectarea")).parent
	rightBlock.height = 228
	rightBlock.borderRight = 4
	rightBlock.borderTop = 0
	rightBlock.borderBottom = 0
	rightBlock.borderAllSides = 0
	rightBlock.borderLeft = 10
	for _, child in pairs(rightBlock.children) do
		child.visible = false
	end
	
	rightBlock:createLabel{text = "Effect Filter"}
	local effectList = common.getIngredEffectList(tes3.player.object.inventory)
	updateEffectFilter(rightBlock, effectList)
	
	local leftBlock = e.element:findChild(tes3ui.registerID("MenuAlchemy_mortar_slot")).parent
	leftBlock.borderBottom = 5
	
	local ancestor = e.element:findChild(-1111)
	for i, gp in ipairs(ancestor.children) do
		for j, p in ipairs(gp.children) do
			for k, child in ipairs(p.children) do
				if child.text == tes3.findGMST(tes3.gmst.sApparatus).value then
					child.borderTop = 0
					leftBlock = child.parent
					break
				end
			end
		end
	end
	
	local label = leftBlock:createLabel{text = strings.createdPotion}
	label.borderBottom = 3
	createdPotion = leftBlock:createThinBorder{id = GUI_ID.createdPotion}
	createdPotion.minHeight = 50
	createdPotion.maxHeight = 50
	createdPotion.minWidth = 50
	createdPotion.maxWidth = 50
	createdPotion.borderLeft = 5
	createdPotion.borderBottom = 5
	createdPotion.paddingAllSides = 8
	createdPotion.autoHeight = true
	createdPotion.autoWidth = true
	
	border = leftBlock:createThinBorder({id = tes3ui.registerID("BORDER")})
	border.height = 30
	border.width = 166
	border.widthProportional = 1.0
	border.absolutePosAlignX = 1
	border.absolutePosAlignY = 0.55
	border.paddingAllSides = 8
	border.childAlignY = 0.5
	border.consumeMouseEvents = true
	
	local nameFormat = border:createTextInput{id = tes3ui.registerID("MenuAlchemy_potion_nameFormat")}
	nameFormat.widget.lengthLimit = 31
	border:register("mouseClick", function()
		tes3ui.acquireTextInput(nameFormat)
	end)
	timer.start{
		duration = 0.05,
		type = timer.real,
		callback = function()
			tes3ui.acquireTextInput(nameFormat)
			nameFormat.text = strings.defaultPotionName
		end
	}
	
	leftBlock:reorderChildren(3, -3, 3)
	
	local createButton = e.element:findChild(tes3ui.registerID("MenuAlchemy_create_button"))
	createButton:registerBefore("mouseClick", function()
		local name = e.element:findChild(tes3ui.registerID("MenuAlchemy_potion_name"))
		if nameFormat.text == "" then
			nameFormat.text = strings.defaultPotionName
		end
		local oldText = name.text
		name.text = string.gsub(nameFormat.text, "%%E", name.text)
		if name.text == "" then
			name.text = "Potion"
		end
		local potionBlock = e.element:findChild(GUI_ID.createdPotion)
		potionBlock:destroyChildren()
		e.element:updateLayout()
		timer.start{
			duration = 0.1,
			type = timer.real,
			callback = function()
				name.text = oldText
				local newEffectList = common.getIngredEffectList(tes3.player.object.inventory)
				updateEffectFilter(rightBlock, newEffectList)
				e.element:updateLayout()
			end
		}
	end)
	
	e.element:updateLayout()
end

local function onFilterInventorySelect(e)
	if e.type ~= "ingredient" then return end
	if e.item.objectType ~= tes3.objectType.ingredient then
		e.filter = false
		return false
	end
	if common.isSelected(e.item) then 
		e.filter = false
		return false
	end
	if common.filteredEffect then 
		local count = common.getVisibleEffectsCount()
		local filter = false	
		for i, effect in ipairs(e.item.effects) do
			if count >= i or (tes3.player.data.alchemyKnowledge[e.item.id] and tes3.player.data.alchemyKnowledge[e.item.id][i]) then
				if effect == common.filteredEffect.id then
					filter = true	
					break 
				end 
			end
		end		
		e.filter = filter
	end 
end

local function onPotionBrewed(e)	
	local potion = e.object
	local count = common.getVisibleEffectsCount()
	local effectLearned = nil
	for _, ingredient in ipairs(e.ingredients) do
		for i, ingredEffect in ipairs(ingredient.effects) do
			for j, potionEffect in ipairs(potion.effects) do
				if ingredEffect == potionEffect.id then
					tes3.player.data.alchemyKnowledge[ingredient.id] = tes3.player.data.alchemyKnowledge[ingredient.id] or {}
					if not tes3.player.data.alchemyKnowledge[ingredient.id][i] then
						tes3.player.data.alchemyKnowledge[ingredient.id][i] = true
						if count < i then
							effectLearned = true
							tes3.mobilePlayer:exerciseSkill(tes3.skill.alchemy, 0.5)
						end
					end
				end
			end
		end
	end
	
	if effectLearned then
		tes3.messageBox(strings.effectLearned)
	end
	
	local menu = tes3ui.findMenu(tes3ui.registerID("MenuAlchemy"))
	if menu then
		local potionBlock = menu:findChild(GUI_ID.createdPotion)
		local image = potionBlock:createImage{path=("icons\\" .. potion.icon)}
		image.absolutePosAlignX = 0.5
		image.absolutePosAlignY = 0.5
		image:register("help", function()
			showPotionTooltip(potion)
		end)
	end
end

local function onIngredTooltip(e)
	if e.object.objectType ~= tes3.objectType.ingredient then return end
	local count = common.getVisibleEffectsCount()
	if count > 3 then return end
	local ingred = e.object
	if not tes3.player.data.alchemyKnowledge[ingred.id] then return end
	
	local parent = e.tooltip:findChild(tes3ui.registerID("PartHelpMenu_main"))
	
	for _, child in ipairs(parent.children) do
		local i = 0
		if child.id == tes3ui.registerID("HelpMenu_effectBlock") then
			child.visible = false
		end
	end
	
	local parent = e.tooltip:createBlock{id=GUI_ID.parent}
	parent.flowDirection = "top_to_bottom"
	parent.childAlignX = 0.5
	parent.autoHeight = true
	parent.autoWidth = true
	for i = 1, 4 do
		local effect = tes3.getMagicEffect(ingred.effects[i])
		local target = math.max(ingred.effectAttributeIds[i], ingred.effectSkillIds[i])

		local block = parent:createBlock{id=GUI_ID[i]}
		block.autoHeight = true
		block.autoWidth = true

		if effect == nil then
			-- pass
		elseif i > count and not tes3.player.data.alchemyKnowledge[ingred.id][i] then
			local label = block:createLabel{text="?"}
			label.wrapText = true
		else
			local image = block:createImage{path=("icons\\" .. effect.icon)}
			image.wrapText = false
			image.borderLeft = 4

			local label = block:createLabel{text=common.getEffectName(effect, target)}
			label.wrapText = false
			label.borderLeft = 4
		end
	end
end

local function onIngredConsumed(e)
	if e.item.objectType ~= tes3.objectType.ingredient then
		return
	end
	if common.config.nonEdible[e.item.id] then return false end
	tes3.player.data.alchemyKnowledge[e.item.id] = tes3.player.data.alchemyKnowledge[e.item.id] or {}
	if common.getVisibleEffectsCount() == 0 and not tes3.player.data.alchemyKnowledge[e.item.id][1]  then
		tes3.messageBox(strings.effectLearned)
		tes3.mobilePlayer:exerciseSkill(tes3.skill.alchemy, 0.5)
	end
	tes3.player.data.alchemyKnowledge[e.item.id][1] = true
end

local function onLoaded(e)
	tes3.player.data.alchemyKnowledge = tes3.player.data.alchemyKnowledge or {}
	tes3.findGMST(tes3.gmst.fWortChanceValue).value = common.config.gmstValue
end


local function onInitialized(e)
	if common.config.modEnabled then
		mwse.log("[Alchemical Knowledge]: enabled")
		event.register("loaded", onLoaded)
		event.register("uiActivated", onMenuAlchemy, {filter = "MenuAlchemy"})	
		event.register("filterInventorySelect", onFilterInventorySelect)
		event.register("potionBrewed", onPotionBrewed)
		event.register("uiObjectTooltip", onIngredTooltip, {priority=200})
		event.register("equip", onIngredConsumed)
		registerGUI()
		magicSchoolName = {
			[0] = tes3.findGMST(tes3.gmst.sSchoolAlteration).value,
			[1] = tes3.findGMST(tes3.gmst.sSchoolConjuration).value,
			[2] = tes3.findGMST(tes3.gmst.sSchoolDestruction).value,
			[3] = tes3.findGMST(tes3.gmst.sSchoolIllusion).value,
			[4] = tes3.findGMST(tes3.gmst.sSchoolMysticism).value,
			[5] = tes3.findGMST(tes3.gmst.sSchoolRestoration).value,
		}
	else
		mwse.log("[Alchemical Knowledge]: disabled")
	end
end

event.register("initialized", onInitialized)