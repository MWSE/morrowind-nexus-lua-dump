
local common = require("Virnetch.enchantmentServicesRedone.common")
local commonTranscription = require("Virnetch.enchantmentServicesRedone.services.transcription.commonTranscription")

local menu = tes3ui.findMenu(common.GUI_ID.TranscriptionMenu)
local isService = menu:getPropertyBool("vir_esr_isService")

local bottomBlock = menu:createBlock({ id = common.GUI_ID.TranscriptionMenu_bottomBlock })
bottomBlock.autoHeight = true
bottomBlock.widthProportional = 1.0

	local maxCount = bottomBlock:createButton({ text = common.i18n("service.transcription.mainMenu.maxCount") })
	maxCount:register(tes3.uiEvent.mouseClick, function()
		menu:setPropertyInt("vir_esr_count", -1)
		commonTranscription.updateMenu()
	end)

local bottomRightBlock = bottomBlock:createBlock()
bottomRightBlock.autoHeight = true
bottomRightBlock.widthProportional = 1.0
bottomRightBlock.childAlignX = 1.0

	if isService then
		local buyButton = bottomRightBlock:createButton({ id = common.GUI_ID.TranscriptionMenu_buyButton, text = tes3.findGMST(tes3.gmst.sBuy).value })
		buyButton:registerBefore(tes3.uiEvent.mouseClick, function()
			-- Make sure that the value shown is correct
			local cost = menu:getPropertyInt("vir_esr_cost")
			commonTranscription.updateMenu()

			if cost ~= menu:getPropertyInt("vir_esr_cost") then
				common.log:info("Transcription cost shown in menu different from actual cost, blocking buy button")
				return false
			end
		end)

		buyButton:registerAfter(tes3.uiEvent.mouseClick, function()
			-- Update the goldLabel
			local goldLabel = menu:findChild(common.GUI_ID.TranscriptionMenu_goldLabel)
			if goldLabel then
				goldLabel.text = tes3.getPlayerGold()
			end
		end)
	else
		local transcribeButton = bottomRightBlock:createButton({ id = common.GUI_ID.TranscriptionMenu_transcribeButton, text = common.i18n("service.transcription.verb") })
	end

	local cancelButton = bottomRightBlock:createButton({ id = common.GUI_ID.TranscriptionMenu_cancelButton, text = tes3.findGMST(tes3.gmst.sCancel).value })
	cancelButton:register(tes3.uiEvent.mouseClick, function()
		menu:destroy()
		common.leaveMenuModeIfNotInMenu()
	end)

return bottomBlock