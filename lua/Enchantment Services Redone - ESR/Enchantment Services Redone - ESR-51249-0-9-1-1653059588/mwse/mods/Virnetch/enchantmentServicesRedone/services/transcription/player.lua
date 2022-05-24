
local common = require("Virnetch.enchantmentServicesRedone.common")
local transcription = require("Virnetch.enchantmentServicesRedone.services.transcription.transcription")


--- Stores the item and itemData of the soul gem player last
--- equipped, for one frame after the equip event
--- @type {item:tes3misc, itemData:tes3itemData}
local lastSoulGem = {}

--- Add a button to open the transcription menu to the messagebox
--- that appears when the player equips a filled soulgem.
--- @param e uiActivatedEventData
local function onMenuMessage(e)
	-- Return if the button has already been added
	local buttonLayout = e.element:findChild(common.GUI_ID.MenuMessage_button_layout)
	if buttonLayout:findChild(common.GUI_ID.MenuMessage_transcribeButton) then
		common.log:trace("Buttons already added, returning")
		return
	end

	-- Get the message of the MenuMessage
	local message = e.element:findChild(common.GUI_ID.MenuMessage_message)
	if not message or not message.text then
		common.log:trace("Message missing text, returning")
		return
	end

	-- Check that there are at least two buttons in the messagebox
	if not buttonLayout or #buttonLayout.children < 2 then
		common.log:trace("Message buttonLayout.children < 2, returning")
		return
	end

	-- Check if the message is correct
	if message.text ~= tes3.findGMST(tes3.gmst.sDoYouWantTo).value then
		common.log:trace("Message text ~= soul gem message, returning")
		return
	end

	-- Check that the first two buttons are correct
	local firstButtonText = buttonLayout.children[1]:findChild(common.GUI_ID.PartButton_text_ptr)
	if not firstButtonText or firstButtonText.text ~= tes3.findGMST(tes3.gmst.sRechargeEnchantment).value then
		common.log:trace("First button text ~= sRechargeEnchantment, returning")
		return
	end

	local secondButtonText = buttonLayout.children[2]:findChild(common.GUI_ID.PartButton_text_ptr)
	if not secondButtonText or secondButtonText.text ~= tes3.findGMST(tes3.gmst.sMake).value then
		common.log:trace("Second button text ~= sMake, returning")
		return
	end

	common.log:debug("Adding buttons to MenuMessage")

	-- Store the gem player equipped while the menu is still open
	local soulGem = lastSoulGem

	-- Add the transcription button
	local transcribeButton = buttonLayout:createButton({ id = common.GUI_ID.MenuMessage_transcribeButton })
	transcribeButton.text = common.i18n("service.transcription.equippedSoulGemButton")
	transcribeButton:register(tes3.uiEvent.mouseClick, function()
		e.element:destroy()
		common.log:debug("Player clicked on transcribeButton, showing TranscriptionMenu")
		transcription.showTranscriptionMenu(false, soulGem)
	end)

	-- Also add a cancel button since it's stupid not to have one
	local cancelButton = buttonLayout:createButton({ id = common.GUI_ID.MenuMessage_cancelButton })
	cancelButton.text = tes3.findGMST(tes3.gmst.sCancel).value
	cancelButton:register(tes3.uiEvent.mouseClick, function()
		e.element:destroy()
		common.leaveMenuModeIfNotInMenu()
	end)

	e.element:updateLayout()
end
event.register(tes3.event.uiActivated, onMenuMessage, { filter = "MenuMessage" })

--- Whenever the player equips a filled soul gem, store it for one frame so that
--- it can be automatically selected in the transcription menu.
--- @param e equipEventData
local function onEquip(e)
	if e.reference ~= tes3.player then return end
	if e.item and e.item.isSoulGem then
		if e.itemData and e.itemData.soul then
			common.log:trace("pc equipped filled soulgem %s with soul of %s", e.item.id, e.itemData.soul.id)
			lastSoulGem = {
				item = e.item,
				itemData = e.itemData
			}

			-- Only store for one frame
			timer.delayOneFrame(function()
				common.log:trace("pc nolonger equipping %s with soul of %s", e.item.id, e.itemData.soul.id)
				lastSoulGem = {}
			end, timer.real)
		end
	end
end
event.register(tes3.event.equip, onEquip, { priority = -1000 })