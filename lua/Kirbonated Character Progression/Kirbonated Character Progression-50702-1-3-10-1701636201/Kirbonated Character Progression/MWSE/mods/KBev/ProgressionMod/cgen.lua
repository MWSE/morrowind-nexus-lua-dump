local common = require("KBev.ProgressionMod.common")
local mcm = require("KBev.ProgressionMod.mcm")

--container for attributes
local budget = mcm.cgenBudget

local function generateAttributeText(id)
	local baseAttributes = tes3.player.object.attributes
	local currentAttributes= tes3.mobilePlayer.attributes
	
	if currentAttributes[id + 1].base == baseAttributes[id + 1] then
		return tostring(baseAttributes[id + 1])
	else return (currentAttributes[id + 1].base .. "(" .. baseAttributes[id + 1] .. ")")
	end
end

local function asButtonScript(params)
	local baseAttributes = tes3.player.object.attributes
	if params.type == "add" then
		if (budget > 0) and (baseAttributes[params.tbl.id + 1] < params.tbl.cap) then
			tes3.modStatistic{attribute = params.tbl.id, reference = tes3.player, value = 1}
			baseAttributes[params.tbl.id + 1] = baseAttributes[params.tbl.id + 1] + 1
			budget = budget - 1 
		end
	end
	if params.type == "sub" then
		if (baseAttributes[params.tbl.id + 1] > params.tbl.base) then
			budget = budget + 1
			tes3.modStatistic{attribute = params.tbl.id, reference = tes3.player, value = -1}
			baseAttributes[params.tbl.id + 1] = baseAttributes[params.tbl.id + 1] - 1
		end
	end
	params.tbl.score_label.text = generateAttributeText(params.tbl.id)
	tes3.setStatistic({reference = tes3.mobilePlayer, name = "health", value = (tes3.mobilePlayer.strength.base + (tes3.mobilePlayer.endurance.base * tes3.player.object.level)) / 2})
end

local function createAtrTooltip()
	local tooltip = tes3ui.createTooltipMenu()
	local outerBlock = tooltip:createBlock()
		outerBlock.autoWidth = true
		outerBlock.autoHeight = true
		outerBlock.visible = true
		
		local header = outerBlock:createLabel{
			text = "Class Favored Attribute"
		}
			header.absolutePosAlignX = 0.5
			header.color = tes3ui.getPalette("header_color")
		
	tooltip:updateLayout()
end



local function onStatReview(e)
	if not mcm.cgenEnabled then return end
	e.element.autoHeight = true
	e.element:findChild(tes3ui.registerID("MenuStatReview_left_main")).autoHeight = true
	e.element:findChild(tes3ui.registerID("MenuStatReview_left_main")).parent.autoHeight = true
	local playerNPC = tes3.player.object
	local baseAttributes = playerNPC.attributes
	
	classAtr = {}
	
	for _, id in ipairs(playerNPC.class.attributes) do
		classAtr[id + 1] = true
	end
	
	local atrLayoutBlock = e.element:findChild(tes3ui.registerID("MenuStatReview_left_main")).children[3]
		atrLayoutBlock.autoHeight = true
	local atrRemBlock = atrLayoutBlock:createBlock{id = tes3ui.registerID("KCP:MenuStatReview_pointsRem_layout")}
		atrRemBlock.autoHeight = true
		atrRemBlock.autoWidth = true
		atrRemBlock.widthProportional = 1.0
		atrRemBlock.childAlignX = -1
		atrRemBlock.visible = true
		local atrRemText = atrRemBlock:createLabel{text = "Attribute Points: "}
			atrRemText.autoWidth = true
			atrRemText.color = tes3ui.getPalette("white_color")
		local atrRemNum = atrRemBlock:createLabel{text = tostring(budget)}
			atrRemNum.autoWidth = true
			atrRemNum.color = tes3ui.getPalette("white_color")
	atr = {}
	
	local function updateASButtons()
		for i, data in ipairs(atr) do
			if (budget > 0) and (baseAttributes[data.id + 1] < data.cap) then
				data.button_plus.widget.state = tes3.uiState.active
			else data.button_plus.widget.state = tes3.uiState.disabled end
			if (baseAttributes[data.id + 1] > data.base) then data.button_minus.widget.state = tes3.uiState.active
			else data.button_minus.widget.state = tes3.uiState.disabled end
		end
		atrRemNum.text = tostring(budget)
		atrLayoutBlock:updateLayout()
	end
	
	for i=1, 8, 1 do
		local block = atrLayoutBlock.children[i]
		--Create UI
		block.children[2].visible = false
		atr[i] = {
			id = i - 1,
			playerStat = tes3.mobilePlayer[tes3.attributeName[i - 1]],
			asBlock = block:createBlock(),
			base = ((classAtr[i] and mcm.cgenBase + 10) or mcm.cgenBase),
			cap = ((classAtr[i] and mcm.cgenMax + 10) or mcm.cgenMax),
		}
		local dif = atr[i].playerStat.base - baseAttributes[i]
		baseAttributes[i] = atr[i].base
		tes3.setStatistic{attribute = atr[i].id, reference = tes3.player, value = baseAttributes[i] + dif}
		atr[i].asBlock.visible = true
		atr[i].asBlock.autoHeight = true
		atr[i].asBlock.autoWidth = true
		
			atr[i].button_minus = atr[i].asBlock:createTextSelect{text = "-"}
			atr[i].button_minus.widget.pressed = tes3ui.getPalette("normal_pressed_color")
			atr[i].button_minus.widget.idleDisabled = tes3ui.getPalette("disabled_color")
			atr[i].button_minus.widget.pressedDisabled = tes3ui.getPalette("disabled_pressed_color")
			atr[i].button_minus.visible = true
			
			atr[i].button_minus:register("mouseClick", function ()
				asButtonScript({type = "sub", tbl = atr[i]})
				updateASButtons()
			end)
			
			atr[i].score_label = atr[i].asBlock:createLabel{text = generateAttributeText(atr[i].id)}
		if classAtr[i] then
			atr[i].score_label.color = tes3ui.getPalette("white_color")
		end
			
			atr[i].button_plus = atr[i].asBlock:createTextSelect{text = "+"}
			atr[i].button_plus.widget.pressed = tes3ui.getPalette("normal_pressed_color")
			atr[i].button_plus.widget.idleDisabled = tes3ui.getPalette("disabled_color")
			atr[i].button_plus.widget.pressedDisabled = tes3ui.getPalette("disabled_pressed_color")
			atr[i].button_plus.visible = true
			
			atr[i].button_plus:register("mouseClick", function()
				asButtonScript({type = "add", tbl = atr[i]})
				updateASButtons()
			end)
	end
	atrLayoutBlock:reorderChildren(0, atrRemBlock, -1) --move the Points Remaining text to the top of the block
	updateASButtons()
	e.element:updateLayout()
end
event.register("uiActivated", onStatReview, {filter = "MenuStatReview"})