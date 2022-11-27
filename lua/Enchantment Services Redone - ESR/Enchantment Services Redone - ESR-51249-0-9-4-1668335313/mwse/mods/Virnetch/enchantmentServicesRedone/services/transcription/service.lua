
local common = require("Virnetch.enchantmentServicesRedone.common")
local transcription = require("Virnetch.enchantmentServicesRedone.services.transcription.transcription")


--- Called when the player clicks on the service button
--- @param params {reference:tes3reference, topicsList:tes3uiElement}
local function onServiceClick(params)
	-- Check for Service Refusal
	local offersService = tes3.checkMerchantOffersService(params.reference.mobile, tes3.merchantService.enchanting)
	if not offersService then
		-- Show Service Refusal message by clicking on the Enchanting service button
		local enchanting = params.topicsList:findChild(common.GUI_ID.MenuDialog_Service_Enchanting)
		enchanting:triggerEvent(tes3.uiEvent.mouseClick)
		return
	end

	transcription.showTranscriptionMenu(true)
end

return {
	id = "transcription",
	name = common.i18n("service.transcription.name"),
	description = common.i18n("service.transcription.description"),
	config = common.config.transcription,
	insertAfter = common.GUI_ID.MenuDialog_Service_Enchanting,
	requirements = common.offersTranscription,
	callback = onServiceClick
}