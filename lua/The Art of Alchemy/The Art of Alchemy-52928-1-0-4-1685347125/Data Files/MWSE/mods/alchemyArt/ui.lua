local common = require("alchemyArt.common")

local ui = {}

ui.negativeEffectColor = {0.792, 0.647, 0.376}
ui.positiveEffectColor = {0.792, 0.647, 0.376}
ui.selectedEffectColor = {0.792, 0.647, 0.376}

ui.createAutoBlock = function (element, id)
    local newBlock = element:createBlock{id = id}
    newBlock.autoWidth = true
    newBlock.autoHeight = true
    return newBlock
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
	local school = textBlock:createLabel{text =  string.format("School: %s", common.magicSchoolName[effect.school])}
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

ui.createBottomBlock = function(menu, reference, onCreate)
    local bottomBlock = ui.createAutoBlock(menu, menu.name.."_bottom")
    bottomBlock.borderTop = 10
    bottomBlock.flowDirection = "left_to_right"
    local takeButton = bottomBlock:createButton{id = menu.name.."_take_button", text = common.dictionary.take}
    local createButton = bottomBlock:createButton{id = menu.name.."_create_button", text = common.dictionary.create}
    if common.config.tutorialMode then
        createButton:register("mouseOver", function()
            local tooltip = tes3ui.createTooltipMenu()
            tooltip.autoHeight = true
            tooltip.autoWidth = true
            tooltip.wrapText = true
            local label =  tooltip:createLabel{text = common.dictionary.createHelp}
            label.autoHeight = true
            label.autoWidth = true
            label.wrapText = true
        end)
    end
    local cancelButton = bottomBlock:createButton{id = menu.name.."_cancel_button", text = common.dictionary.cancel}
    createButton.borderLeft = 250
	cancelButton:register("mouseClick", function()
        -- ui.negativeEffectColor = tes3ui.getPalette(tes3.palette.normalColor)
        -- ui.positiveEffectColor = tes3ui.getPalette(tes3.palette.normalColor)
		menu:destroy()
		tes3ui.leaveMenuMode()
        common.selectedEffects = {}
	end)
    if not string.endswith(reference.id, "_static") then
        takeButton:register("mouseClick", function()
            -- ui.negativeEffectColor = tes3ui.getPalette(tes3.palette.normalColor)
            -- ui.positiveEffectColor = tes3ui.getPalette(tes3.palette.normalColor)
            menu:destroy()
            tes3ui.leaveMenuMode()
            tes3.addItem{reference = tes3.player, item = reference.object.id}
            reference:disable()
            reference:delete()
            common.selectedEffects = {}
        end)
    else
        createButton.borderLeft = 311
        --createButton.borderLeft = createButton.borderLeft + takeButton.width + 2*takeButton.borderAllSides
        takeButton.visible = false
    end
    createButton:register("mouseClick", onCreate)
end

ui.createItemSlot = function(element, id, onMouseClick)
    local slot = element:createThinBorder{id = id}
    slot.minHeight = 50
	slot.maxHeight = 50
	slot.minWidth = 50
    slot.maxWidth = 50
	slot.autoHeight = true
	slot.autoWidth = true
    slot.borderAllSides = 4
    slot.borderAllSides = 4
    slot.paddingAllSides = 8
	slot.childAlignY = 0.5
    slot:register("mouseClick", onMouseClick)
    return slot
end

ui.createEffectFilter = function (element, id, effectList)
    local effectFilter = element:createVerticalScrollPane{ id = id}
    effectFilter.autoWidth = true
    effectFilter.autoHeight = true
    effectFilter.minWidth = 200
    effectFilter.minHeight = 150
    effectFilter.maxWidth = 200
    effectFilter.borderLeft = 35
	effectFilter.borderTop = 4
	for _, effect in ipairs(effectList) do
        effect = tes3.getMagicEffect(effect)
		local state = (effect == common.filteredEffect) and 4 or 1
        local labelText = effect.name
        local textSelect = effectFilter:createTextSelect({ id = "effectFilter_label", text = effect.name, state = state })
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

ui.createEffectBlock = function(element, effects)
    for i, effect in ipairs(effects) do
        local magicEffect = tes3.getMagicEffect(effect.id)
        if not magicEffect then
            break
        end
        local block = ui.createAutoBlock(element, "Effectblock")
        block.flowDirection = "left_to_right"
        local image = block:createImage{path=("icons\\" .. magicEffect.icon)}
        image.wrapText = false
        image.borderLeft = 4
        local text = common.getEffectText(effect)
        local label = block:createLabel{text=text}
        label.wrapText = false
        label.borderLeft = 4
    end
end


ui.showTooltip = function(source, slot)
	local tooltip = tes3ui.createTooltipMenu()
	tooltip.minWidth = 50
	tooltip.maxWidth = 1920
	tooltip.autoHeight = true
	tooltip.autoWidth = true
	local name = tooltip:createLabel{text=source.name}
	name.color = tes3ui.getPalette("header_color")
	tooltip.flowDirection = "top_to_bottom"
	local effects = source.effects
    if source.objectType == tes3.objectType.ingredient then

        local count = common.getVisibleEffectsCount()

        for i, effect in ipairs(effects) do
            local magicEffect = tes3.getMagicEffect(effect)
            if not magicEffect then 
                break 
            end
            local target = math.max(source.effectAttributeIds[i], source.effectSkillIds[i])
            local block = tooltip:createBlock{id="HelpMenu_effectBlock"}
            block.autoHeight = true
            block.autoWidth = true
            block.flowDirection = "left_to_right"
            if i > count and not (tes3.player.data.alchemyKnowledge[source.id] and tes3.player.data.alchemyKnowledge[source.id][i]) then
                local label = block:createLabel{text="?"}
                label.wrapText = true
            else
                local image = block:createImage{path=("icons\\" .. magicEffect.icon)}
                image.wrapText = false
                image.borderLeft = 4
    
                local label = block:createLabel{text = common.getEffectName(magicEffect, target)}
                label.wrapText = false
                label.borderLeft = 4
            end
        end
    else
        for i, effect in ipairs(effects) do
            local magicEffect = tes3.getMagicEffect(effect.id)
            if not magicEffect then
                break
            end
            local block = ui.createAutoBlock(tooltip, "HelpMenu_effectBlock")
            block.flowDirection = "left_to_right"
            local image = block:createImage{path=("icons\\" .. magicEffect.icon)}
            image.wrapText = false
            image.borderLeft = 4
            local text = common.getEffectText(effect)
            local label = block:createLabel{text=text}
            -- if magicEffect.isHarmful then
            --     mwse.log("Applying Negative Color")
            --     mwse.log(inspect(ui.negativeEffectColor))
            --     label.color = ui.negativeEffectColor
            -- else
            --     label.color = ui.positiveEffectColor
            -- end
            label.wrapText = false
            label.borderLeft = 4
        end
    end
	tooltip:updateLayout()
    event.trigger("uiObjectTooltip", {tooltip = tooltip, object = source, menuSlot = slot})
end

ui.createItemBlock = function(menu, scrollpane, stack)
    local item = stack.object
    local block = ui.createAutoBlock(scrollpane, "PartHelpMenu_brick")
    local image = block:createImage{id = "MenuInventorySelect_icon_brick", path = "icons\\" ..item.icon}
    image.borderAllSides = 8
    local countLabel = image:createLabel{id = "Ingredient_count", text = tostring(stack.count)}
    countLabel.color = {0.875,0.788,0.624}
    countLabel.absolutePosAlignX = 1
    countLabel.absolutePosAlignY = 1
    local label = block:createLabel{id = "MenuInventorySelect_item_brick",  text = item.name}
    label.borderAllSides = 14
    block.consumeMouseEvents = true
    block:register("help", function()
        ui.showTooltip(item)
    end)
    block:register("mouseClick", function() 
        menu:destroy()
        event.trigger("alchemyArt_itemSelected", {item = item})
        tes3ui.leaveMenuMode()
    end)
end

ui.createItemImage = function (element, item)
    local image = element:createImage{id = "Item_Image", path = "icons\\"..item.icon}
    image.absolutePosAlignX = 0.5
    image.absolutePosAlignY = 0.5
    image.autoWidth = true
    image.autoHeight = true
    image:register("help", function()
        ui.showTooltip(item, element.name)
    end)
end

return ui