local transcriptionMenu = {}

local common = require("Virnetch.enchantmentServicesRedone.common")
local commonTranscription = require("Virnetch.enchantmentServicesRedone.services.transcription.commonTranscription")

--- Creates the transcription menu
--- @param isService boolean True if this is a service offered by an NPC, false if player-transcription
--- @param firstSoul {item:tes3misc, itemData:tes3itemData}? Optional. Will be automatically selected in the soul gem slot
function transcriptionMenu.createMenu(isService, firstSoul)
	-- Return if menu is already created
	if tes3ui.findMenu(common.GUI_ID.TranscriptionMenu) then return end

	-- Create the menu
	local menu = tes3ui.createMenu({ id = common.GUI_ID.TranscriptionMenu, fixedFrame = true })
	-- menu.alpha = 1.0

	-- Store if this is a service for easier access later
	menu:setPropertyBool("vir_esr_isService", isService)

	-- Create the elements of the menu
	if common.config.transcription.requireScroll and common.config.transcription.customName then
		local nameBlock = dofile("Virnetch.enchantmentServicesRedone.services.transcription.transcriptionMenu.nameBlock")
	end
	local itemSelectors = dofile("Virnetch.enchantmentServicesRedone.services.transcription.transcriptionMenu.itemsBlock")
	local midBlock = dofile("Virnetch.enchantmentServicesRedone.services.transcription.transcriptionMenu.midBlock")
	local bottomBlock = dofile("Virnetch.enchantmentServicesRedone.services.transcription.transcriptionMenu.bottomBlock")

	-- Automatically select the equipped soul gem
	if itemSelectors.soulSelector and firstSoul and firstSoul.item then
		itemSelectors.soulSelector:setItem(firstSoul)
		itemSelectors.soulSelector.params.onUpdate()
	end

	menu:updateLayout()
	commonTranscription.updateMenu()

	return menu
end

return transcriptionMenu