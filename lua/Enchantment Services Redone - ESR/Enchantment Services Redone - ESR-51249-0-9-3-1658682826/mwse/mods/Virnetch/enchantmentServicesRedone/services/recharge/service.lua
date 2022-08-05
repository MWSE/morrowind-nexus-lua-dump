
local common = require("Virnetch.enchantmentServicesRedone.common")
local recharge = require("Virnetch.enchantmentServicesRedone.services.recharge.recharge")


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

	recharge.showRechargeMenu()
end

return {
	id = "recharge",
	name = common.i18n("service.recharge.name"),
	description = common.i18n("service.recharge.description"),
	config = common.config.recharge,
	insertAfter = common.GUI_ID.MenuDialog_Service_Enchanting,
	requirements = common.offersRecharge,
	callback = onServiceClick
}