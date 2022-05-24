
local common = require("Virnetch.enchantmentServicesRedone.common")
local deciphering = require("Virnetch.enchantmentServicesRedone.services.deciphering.deciphering")


--- Called when the player clicks on the service button
--- @param params {reference:tes3reference, topicsList:tes3uiElement}
local function onServiceClick(params)
	-- Check for Service Refusal
	local offersService = tes3.checkMerchantOffersService(params.reference.mobile, tes3.merchantService.spellmaking)
	if not offersService then
		-- Show Service Refusal message by clicking on the Spellmaking service button
		local spellmaking = params.topicsList:findChild(common.GUI_ID.MenuDialog_Service_Spellmaking)
		spellmaking:triggerEvent(tes3.uiEvent.mouseClick)
		return
	end

	deciphering.showDecipheringMenu()
end

return {
	id = "deciphering",
	name = common.i18n("service.deciphering.name"),
	description = common.i18n("service.deciphering.description"),
	config = common.config.deciphering,
	insertAfter = common.GUI_ID.MenuDialog_Service_Spellmaking,
	requirements = common.offersDeciphering,
	callback = onServiceClick
}