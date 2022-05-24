
local common = require("Virnetch.enchantmentServicesRedone.common")
local commonTranscription = require("Virnetch.enchantmentServicesRedone.services.transcription.commonTranscription")

local InventorySelectMenu = require("Virnetch.enchantmentServicesRedone.ui.InventorySelectMenu")
local itemSelector = require("Virnetch.enchantmentServicesRedone.ui.itemSelector")

local menu = tes3ui.findMenu(common.GUI_ID.TranscriptionMenu)
local isService = menu:getPropertyBool("vir_esr_isService")

-- Create the itemsBlock
local itemsBlock = menu:createBlock({ id = common.GUI_ID.TranscriptionMenu_itemsBlock })
itemsBlock.autoHeight = true
itemsBlock.autoWidth = true
itemsBlock.minWidth = 350
itemsBlock.borderAllSides = 6

-- Add itemSelectors
local function sourceFilter(e)
	if e.item.enchantment and e.item.objectType == tes3.objectType.book then
		if not (common.config.transcription.preventScripted and e.item.script) then
			return true
		end
	end
	return false
end

local function targetFilter(e)
	if (
		not e.item.enchantment
		and e.item.objectType == tes3.objectType.book
		and e.item.type == tes3.bookType.scroll
		and commonTranscription.getEnchantCapacity(e.item) > 0
		and ( not e.item.text or e.item.text == "" )
	) then
		if not (common.config.transcription.preventScripted and e.item.script) then
			return true
		end
	end
	return false
end

local function onSourceSelectMenuUpdated(e)
	local disabledColor = common.palette.disabledColor

	InventorySelectMenu.addToInventorySelectMenuTiles({
		--- @param section esrInventorySelectMenu.addToTilesParams.section
		addBelow = not isService and function(section)
			-- Show chance if not a service
			local chanceLabel = section.element:createLabel()
			local chance = commonTranscription.calculateTranscriptionChance(tes3.mobilePlayer, section.item) or 0
			chance = math.round(chance)
			chanceLabel.text = string.format("%s: %i", tes3.findGMST(tes3.gmst.sEnchantmentMenu6).value, chance)
			chanceLabel.consumeMouseEvents = false
		end,
		--- @param section esrInventorySelectMenu.addToTilesParams.section
		addRight = isService and function(section)
			-- Show cost for transcribing, if a service
			local costLabel = section.element:createLabel()
			local _, cost = commonTranscription.calculateTranscriptionCost(section.item)
			costLabel.text = string.format("%i%s", cost, tes3.findGMST(tes3.gmst.sgp).value)
			costLabel.consumeMouseEvents = false

			-- Prevent selecting source scroll's that the NPC doesn't have the skills to transcribe
			if not commonTranscription.canTranscribeItem(tes3ui.getServiceActor(), section.item) then
				costLabel.color = disabledColor
				section.element.parent:findChild(common.GUI_ID.MenuInventorySelect_nameLabel).color = disabledColor
				section.element.parent:register(tes3.uiEvent.mouseClick, function()
					tes3.messageBox(common.i18n("service.transcription.mainMenu.cantTranscribe"))
				end)
			end
		end
	})
end

local function onScrollSelectMenuUpdated(e)
	local disabledColor = common.palette.disabledColor

	-- Add enchant capacities to the item tiles
	InventorySelectMenu.addToInventorySelectMenuTiles({
		--- @param section esrInventorySelectMenu.addToTilesParams.section
		addBelow = function(section)
			-- Show the Enchant Capacity of the scroll
			local enchantCapacity = commonTranscription.getEnchantCapacity(section.item)
			local enchantCapacityLabel = section.element:createLabel()
			enchantCapacityLabel.text = common.i18n("service.transcription.enchantCapacity", { enchantCapacity = enchantCapacity/10 })
			enchantCapacityLabel.consumeMouseEvents = false

			local powerMult = commonTranscription.getPowerMult(section.item)
			if powerMult and powerMult < 1 then
				enchantCapacityLabel.color = disabledColor
				section.element.parent:findChild(common.GUI_ID.MenuInventorySelect_nameLabel).color = disabledColor
			end
		end
	})
end

local sourceSelector = itemSelector.create({
	parent = itemsBlock,
	id = common.GUI_ID.TranscriptionMenu_sourceBlock,
	label = common.i18n("service.transcription.mainMenu.sourceLabel"),
	tooltip = common.i18n("service.transcription.mainMenu.sourceTooltip"),
	inventorySelectParams = {
		filter = sourceFilter,
		title = common.i18n("service.transcription.select.source.title"),
		noResultsText = common.i18n("service.transcription.select.source.noResultsText")
	},
	onUpdate = function()
		-- Default the nameInput's text to sourceScroll's name, clear it when removing the selected scroll
		local nameInput = menu:findChild(common.GUI_ID.TranscriptionMenu_nameInput)
		if nameInput then
			local sourceScroll = commonTranscription.getStoredPropertyObject("vir_esr_item", common.GUI_ID.TranscriptionMenu_sourceBlock)
			nameInput.text = sourceScroll and sourceScroll.name or ""
			tes3ui.acquireTextInput(nameInput)
		end

		commonTranscription.updateMenu()
	end,
	onMenuInventorySelectMenuActivated = function(e)
		if isService then
			InventorySelectMenu.addPlayerGold(e.element)
		end
		e.element:registerAfter(tes3.uiEvent.preUpdate, onSourceSelectMenuUpdated)
	end
})
sourceSelector.element.borderRight = 50

-- Item requirements
local requirementsBlock = itemsBlock:createBlock()
requirementsBlock.widthProportional = 1.0
requirementsBlock.autoHeight = true
requirementsBlock.autoWidth = true
requirementsBlock.childAlignX = 1.0

local scrollSelector, soulSelector
if common.config.transcription.requireScroll then
	scrollSelector = itemSelector.create({
		parent = requirementsBlock,
		id = common.GUI_ID.TranscriptionMenu_scrollBlock,
		label = common.i18n("service.transcription.mainMenu.scrollLabel"),
	--	tooltip = common.i18n("service.transcription.mainMenu.scrollTooltip"),
		inventorySelectParams = {
			filter = targetFilter,
			title = common.i18n("service.transcription.select.scroll.title"),
			noResultsText = common.i18n("service.transcription.select.scroll.noResultsText")
		},
		onUpdate = commonTranscription.updateMenu,
		onMenuInventorySelectMenuActivated = function(e)
			-- Show the sourceScroll's enchantCapacity at the bottom of the menu
			local sourceScroll = commonTranscription.getStoredPropertyObject("vir_esr_item", common.GUI_ID.TranscriptionMenu_sourceBlock)
			local enchantCapacity = commonTranscription.getEnchantCapacity(sourceScroll)
			if enchantCapacity then
				local bottomLabel = InventorySelectMenu.addBottomLabel(e.element, common.GUI_ID.MenuInventorySelect_transcriptionSourceEnchantCapacityLabel)
				bottomLabel.text = common.i18n("service.transcription.select.scroll.transcriptionSourceEnchantCapacity", { enchantCapacity = enchantCapacity/10 })
			end

			e.element:registerAfter(tes3.uiEvent.preUpdate, onScrollSelectMenuUpdated)
		end
	})
	scrollSelector.element.borderRight = 10
	scrollSelector.element:findChild(common.GUI_ID.itemSelect_label):register(tes3.uiEvent.help, function()
		local powerMult = commonTranscription.getPowerMult()

		local tooltipText
		if powerMult and powerMult < 1 then
			tooltipText = common.i18n("service.transcription.mainMenu.scrollTooltipLowPower")
		else
			tooltipText = common.i18n("service.transcription.mainMenu.scrollTooltip")
		end
		common.tooltip(tooltipText, true)
	end)
end
if common.config.transcription.requireSoulGem then
	soulSelector = itemSelector.create({
		parent = requirementsBlock,
		id = common.GUI_ID.TranscriptionMenu_soulBlock,
		label = tes3.findGMST(tes3.gmst.sSoulGem).value,
		tooltip = common.i18n("service.transcription.mainMenu.soulGemTooltip"),
		inventorySelectParams = {
			filter = "soulgemFilled",
			title = tes3.findGMST(tes3.gmst.sSoulGemsWithSouls).value,
			noResultsText = tes3.findGMST(tes3.gmst.sInventorySelectNoSoul).value
		},
		onUpdate = commonTranscription.updateMenu
	})
end

return {
	sourceSelector = sourceSelector,
	scrollSelector = scrollSelector,
	soulSelector = soulSelector
}