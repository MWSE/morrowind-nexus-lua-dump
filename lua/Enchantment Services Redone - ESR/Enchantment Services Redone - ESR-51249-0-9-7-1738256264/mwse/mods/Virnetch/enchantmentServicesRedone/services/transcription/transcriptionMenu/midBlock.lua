
local common = require("Virnetch.enchantmentServicesRedone.common")
local commonTranscription = require("Virnetch.enchantmentServicesRedone.services.transcription.commonTranscription")

local menu = tes3ui.findMenu(common.GUI_ID.TranscriptionMenu)
local isService = menu:getPropertyBool("vir_esr_isService")

local midBlock = menu:createBlock({ id = common.GUI_ID.TranscriptionMenu_midBlock })
midBlock.autoHeight = true
midBlock.widthProportional = 1.0
midBlock.childAlignX = -1
midBlock.childAlignY = 1.0
midBlock.borderAllSides = 3

local countBlock = midBlock:createBlock({ id = common.GUI_ID.TranscriptionMenu_countBlock })
countBlock.autoHeight = true
countBlock.autoWidth = true
countBlock.childAlignY = 0.5

	local countChangeBlock = countBlock:createBlock({ id = common.GUI_ID.TranscriptionMenu_countChangeBlock })
	countChangeBlock.flowDirection = "top_to_bottom"
	countChangeBlock.autoHeight = true
	countChangeBlock.autoWidth = true

		local function increaseCount()
			menu:setPropertyInt("vir_esr_count", (menu:getPropertyInt("vir_esr_count") + 1))
			commonTranscription.updateMenu()
		end
		local function decreaseCount()
			menu:setPropertyInt("vir_esr_count", (menu:getPropertyInt("vir_esr_count") - 1))
			commonTranscription.updateMenu()
		end

		local countIncreaseButton = countChangeBlock:createButton({ id = common.GUI_ID.TranscriptionMenu_countIncreaseButton })
		countIncreaseButton.text = "+"
		countIncreaseButton.autoWidth = false
		countIncreaseButton.width = 30
		countIncreaseButton.borderAllSides = 1

		local countDecreaseButton = countChangeBlock:createButton({ id = common.GUI_ID.TranscriptionMenu_countDecreaseButton })
		countDecreaseButton.text = "-"
		countDecreaseButton.autoWidth = false
		countDecreaseButton.width = 30
		countDecreaseButton.borderAllSides = 1

		countIncreaseButton:register(tes3.uiEvent.mouseClick, increaseCount)
		countDecreaseButton:register(tes3.uiEvent.mouseClick, decreaseCount)

		-- Allow changing count with mouse wheel
		countBlock:register(tes3.uiEvent.mouseScrollUp, increaseCount)
		countBlock:register(tes3.uiEvent.mouseScrollDown, decreaseCount)

	local countTitle = countBlock:createLabel({ text = string.format("%s:", common.i18n("service.transcription.mainMenu.countLabel")) })
	countTitle.color = common.palette.headerColor
	countTitle.borderLeft = 6
	countTitle:register(tes3.uiEvent.help, function()
		if common.config.transcription.requireScroll
		  and common.config.transcription.requireSoulGem then
			common.tooltip(common.i18n("service.transcription.mainMenu.countTooltipScrollAndSoul"), true)
		elseif common.config.transcription.requireScroll then
			common.tooltip(common.i18n("service.transcription.mainMenu.countTooltipScroll"), true)
		elseif common.config.transcription.requireSoulGem then
			common.tooltip(common.i18n("service.transcription.mainMenu.countTooltipSoul"), true)
		else
			common.tooltip(common.i18n("service.transcription.mainMenu.countTooltip"), true)
		end
	end)
	local countLabel = countBlock:createLabel({ id = common.GUI_ID.TranscriptionMenu_countLabel })
	countLabel.text = 1
	countLabel.borderLeft = 4

local infoBlock = midBlock:createBlock({ id = common.GUI_ID.TranscriptionMenu_infoBlock })
infoBlock.autoHeight = true
infoBlock.autoWidth = true
infoBlock.borderAllSides = 5
menu:setPropertyInt("vir_esr_count", 1)
menu:setPropertyInt("vir_esr_cost", 0)

	local leftBlock = infoBlock:createBlock()
	leftBlock.flowDirection = "top_to_bottom"
	leftBlock.autoWidth = true
	leftBlock.autoHeight = true
	leftBlock.childAlignX = 1.0
	leftBlock.borderRight = 10
	local rightBlock = infoBlock:createBlock()
	rightBlock.flowDirection = "top_to_bottom"
	rightBlock.autoWidth = true
	rightBlock.autoHeight = true
	rightBlock.childAlignX = 1.0
	rightBlock.minWidth = 60

		if common.config.transcription.requireSoulGem then
			local soulAmountTitle = leftBlock:createLabel({ text = string.format("%s:", common.i18n("service.transcription.mainMenu.soulAmountLabel")) })
			soulAmountTitle.borderBottom = 4
			soulAmountTitle.color = common.palette.headerColor
			soulAmountTitle:register(tes3.uiEvent.help, function()
				common.tooltip(common.i18n("service.transcription.mainMenu.soulAmountTooltip"), true)
			end)
			local soulAmountLabel = rightBlock:createLabel({ id = common.GUI_ID.TranscriptionMenu_soulAmountLabel })
			soulAmountLabel.borderBottom = 4
			soulAmountLabel.text = "0/0"
		end

		if isService then
			local costTitle = leftBlock:createLabel({ text = string.format("%s:", tes3.findGMST(tes3.gmst.sBarterDialog7).value) })
			costTitle.color = common.palette.headerColor
			costTitle:register(tes3.uiEvent.help, function()
				common.tooltip(common.i18n("service.transcription.mainMenu.costTooltip"), true)
			end)
			local costLabel = rightBlock:createLabel({ id = common.GUI_ID.TranscriptionMenu_costLabel })
			costLabel.text = 0

			local goldTitle = leftBlock:createLabel({ text = string.format("%s:", tes3.findGMST(tes3.gmst.sGold).value) })
			goldTitle.color = common.palette.headerColor
			goldTitle:register(tes3.uiEvent.help, function()
				common.tooltip(common.i18n("service.transcription.mainMenu.goldTooltip"), true)
			end)
			local goldLabel = rightBlock:createLabel({ id = common.GUI_ID.TranscriptionMenu_goldLabel })
			goldLabel.text = tes3.getPlayerGold()
		else
			local chanceTitle = leftBlock:createLabel({ text = string.format("%s:", tes3.findGMST(tes3.gmst.sEnchantmentMenu6).value) })
			chanceTitle.color = common.palette.headerColor
			chanceTitle:register(tes3.uiEvent.help, function()
				common.tooltip(common.i18n("service.transcription.mainMenu.chanceTooltip"), true)
			end)
			local chanceLabel = rightBlock:createLabel({ id = common.GUI_ID.TranscriptionMenu_chanceLabel })
			chanceLabel.text = 0
		end

return midBlock