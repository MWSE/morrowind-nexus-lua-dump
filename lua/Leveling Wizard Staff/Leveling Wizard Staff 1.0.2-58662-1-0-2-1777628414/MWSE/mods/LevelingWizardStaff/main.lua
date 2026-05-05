require("LevelingWizardStaff.lws")
require("LevelingWizardStaff.config")
require("LevelingWizardStaff.mcm")
require("LevelingWizardStaff.levelup_menu")

local log = mwse.Logger.new()

local modName = "Leveling Wizard Staff"
local modVersion = "1.0.2"

---@return lwsModData
local function ensureModData()
	local modData = lws.GetModData()

	if not modData then
		--- @type lwsModData
		---@diagnostic disable-next-line: missing-fields
		tes3.player.data.levelingWizardStaff = {} -- fields on serialized data need to be assigned one by one
		modData = tes3.player.data.levelingWizardStaff
	end

	if modData.baseStaffId == nil then
		modData.baseStaffId = "ebony staff"
	end
	if modData.progression == nil then
		modData.progression = lws.progression.initial
	end
	if modData.staffEquipped == nil then
		modData.staffEquipped = false
	end
	if modData.staffMagickaAccumulated == nil then
		modData.staffMagickaAccumulated = 0
	end
	if modData.staffLevel == nil then
		modData.staffLevel = -1
	end
	if modData.staffMaxLevelReached == nil then
		modData.staffMaxLevelReached = false
	end
	if modData.staffLevelUpPending == nil then
		modData.staffLevelUpPending = false
	end
	if modData.staffEffectLevels == nil then
		modData.staffEffectLevels = {}
	end
	-- fix for morrowind sometimes changing the type of the keys from int to string when loading or saving
	for key, value in pairs(modData.staffEffectLevels) do
		local stringKey = tostring(key)
		local intKey = tonumber(stringKey)
		if intKey then
			modData.staffEffectLevels[stringKey] = nil
			modData.staffEffectLevels[intKey] = value
		end
	end
	if modData.staffFilledEnchantmentSlots == nil then
		modData.staffFilledEnchantmentSlots = 0
	end

	return modData
end

--- @return tes3weapon
local function createWizardStaff()
	local modData = lws.GetModData()

	---@type tes3weapon
	local baseStaff = tes3.getObject(modData.baseStaffId)

	---@type tes3enchantment
	local wizardStaffEnchantment = tes3.createObject({
		-- ###
		id = lws.wizardStaffEnchantmentId,
		objectType = tes3.objectType.enchantment,
		getIfExists = false,
		castType = tes3.enchantmentType.constant,
		effects = {},
		modified = true,
	})

	---@type tes3weapon
	local wizardStaff = baseStaff:createCopy({ id = lws.wizardStaffId })
	wizardStaff.weight = 1
	wizardStaff.value = 0
	wizardStaff.name = "My Wizard Staff"
	wizardStaff.enchantment = wizardStaffEnchantment
	wizardStaff.modified = true

	return wizardStaff
end

--- @return tes3weapon
local function getOrCreateWizardStaff()
	local wizardStaff = tes3.getObject(lws.wizardStaffId)
	if not wizardStaff then
		wizardStaff = createWizardStaff()
	end
	return wizardStaff
end

local function loadedCallback()
	local modData = ensureModData()

	log:debug("Mod loaded with data %s", modData)

	if modData.staffLevelUpPending then
		tes3.messageBox("Your Wizard Staff is ready to grow in power.")
	end
end

---@param e itemDroppedEventData
local function itemDroppedCallback(e)
	local droppedItemReference = e.reference

	if droppedItemReference.id == lws.wizardStaffId then
		local _, _, newitemData = tes3.addItem({ reference = tes3.player, item = tes3.getObject(lws.wizardStaffId) })

		local droppedItemData = droppedItemReference.itemData;
		if droppedItemData then
			newitemData.condition = droppedItemData.condition
		end

		droppedItemReference:delete()

		tes3.messageBox("Your dropped Wizard Staff vanishes and reappears in your bag.")
	end
end

---@param e containerClosedEventData
local function containerClosedCallback(e)
	local containerReference = e.reference
	--- @type tes3container|tes3containerInstance
	local container = containerReference.object
	if container then
		for _, itemStack in ipairs(container.inventory.items) do
			if itemStack.object.id == lws.wizardStaffId then
				local _, _, newitemData = tes3.addItem({ reference = tes3.player, item = tes3.getObject(lws.wizardStaffId) })

				--- @type tes3itemData
				local oldItemData = itemStack.variables
				if oldItemData then
					newitemData.condition = oldItemData.condition
				end

				tes3.removeItem({ reference = containerReference, item = lws.wizardStaffId })

				tes3.messageBox("Your Wizard Staff vanishes from where you put it and reappears in your bag.")
				break
			end
		end
	end
end

---@return boolean
local function checkModQuestStartRequirements()
	if lws.Config.modStartRequiredPlayerLevel > 0 then
		if tes3.player.object.level < lws.Config.modStartRequiredPlayerLevel then
			return false
		end
	end

	if lws.Config.modStartRequiresWizardRank then
		local magesGuildFaction = tes3.getFaction("Mages Guild")
		local wizardRankInMagesGuild = magesGuildFaction and magesGuildFaction.playerJoined and magesGuildFaction.playerRank >= 7
		if not wizardRankInMagesGuild then
			return false
		end
	end

	return true
end

---@param itemStack tes3itemStack
local function isValidBaseStaff(itemStack)
	return lws.validStaffIds[itemStack.object.id] ~= nil and itemStack.object.enchantment == nil
end

---@param itemStack tes3itemStack
local function isLargeSoulGem(itemStack)
	if not itemStack.object.isSoulGem then
		return false
	end

	---@type tes3itemData[]|nil
	local variables = itemStack.variables
	if variables ~= nil then
		for _, itemData in ipairs(variables) do
			if itemData.soul and itemData.soul.soul >= 400 then
				return true
			end
		end
	end

	return false
end

---@return tes3itemStack|nil
local function checkGrandSoulInInventory()
	for _, itemStack in ipairs(tes3.player.mobile.inventory) do
		if isLargeSoulGem(itemStack) then
			return itemStack
		end
	end

	return nil
end

local function checkStaffIngredientsInInventory()
	local baseStaffItemStack = nil
	local soulGemItemStack = nil

	for _, itemStack in ipairs(tes3.player.mobile.inventory) do
		if baseStaffItemStack == nil and isValidBaseStaff(itemStack) then
			baseStaffItemStack = itemStack
		elseif soulGemItemStack == nil and isLargeSoulGem(itemStack) then
			soulGemItemStack = itemStack
		end
	end

	return unpack({ baseStaffItemStack, soulGemItemStack })
end

---@param dreamMessage string
---@return tes3uiElement
local function showDreamMessage(dreamMessage)
	local messageMenu = tes3ui.showMessageMenu({
		-- ###
		id = "lws_MessageMenu_IntroDream",
		message = dreamMessage,
		buttons = { { text = tes3.findGMST(tes3.gmst.sOK).value } },
	})
	messageMenu.alpha = 1
	messageMenu.width = 300
	messageMenu.autoHeight = true

	tes3ui.enterMenuMode(messageMenu.id)

	return messageMenu
end

---@param soulGemId string
local function consumeSoul(soulGemId)
	local removedCount = tes3.removeItem({ reference = tes3.player, item = soulGemId, playSound = false })
	if removedCount > 0 and soulGemId == "Misc_SoulGem_Azura" then
		-- re-adding empty Azura's Star
		tes3.addItem({ reference = tes3.player, item = soulGemId, playSound = false, count = removedCount })
	end
end

---@param baseStaffItemStack tes3itemStack
---@param soulGemItemStack tes3itemStack
local function triggerStaffGrantingDream(baseStaffItemStack, soulGemItemStack)
	local modData = lws.GetModData()
	-- TODO: Offer option to select what staff and soulgem to use?
	log:trace("Staff ingredients found: %s and %s", baseStaffItemStack.object.name, soulGemItemStack.object.name)
	modData.baseStaffId = baseStaffItemStack.object.id

	tes3.removeItem({ reference = tes3.player, item = baseStaffItemStack.object.id, playSound = false })
	consumeSoul(soulGemItemStack.object.id)

	local messageMenu = showDreamMessage("You find yourself in the dream void again and hear the expected deep voice speaking to you in an excited tone.\n\n\"Good, you have returned with the right materials. It was not too difficult I hope? Lets get right too it.\"\n\nYou feel a strange tug on your soul as if someone is gripping a part of it and twisting it into a knot. You try to call out but your voice fails you. After a time that feels both very short and very long, the voice speaks again.\n\n\"Your new Wizard Staff is now ready for you. All thats left to do is plant the seed of magic that shall soon bloom into a vast forest. Choose now the first enchantment for your staff! After that just keep it in your hand as you cast your spells and it will soon grow as more and more Magicka flows through it.\n\nNow go, my chosen Wizard and use your new Wizard Staff to bring more magic into the world! We shall soon hear from each other again.\"")
	messageMenu:registerAfter(tes3.uiEvent.destroy, function()
		local wizardStaff = getOrCreateWizardStaff()
		log:trace("Adding Wizard-Staff to inventory")
		tes3.addItem({ reference = tes3.player, item = wizardStaff })
		LevelUpMenu:CreateWindow()
	end)
end

---@param e tes3uiEventData
local function restStartedCallback(e)
	log:trace("restStartedCallback(%s)", e)

	local modData = lws.GetModData()

	if modData.progression == lws.progression.initial then
		if checkModQuestStartRequirements() then
			showDreamMessage("In your dream you drift through an endless void. You can see stars and swirling magic all around you and a deep voice speaks to you, like from the inside of your mind.\n\n\"So you have been granted a Staff and can now call yourself Wizard in the eyes of your colleagues at the Mages Guild. Congratulations, I suppose. Though I suspect someone with your... special destiny might feel an ordinary Wizard Staff somewhat beneath them, am I right? Have you already stored it away in a box somehwere? Too heavy perhaps? Well, I have quite an offer for you!\"\n\nYou can hear from their voice that the speaker is grinning, though you still can not make out where they are.\n\n\"I can offer you a REAL Wizards Staff, beyond anything your colleagues could even dream off. A living enchantment that gets stronger with you as you feed it more Magicka. And light as an egg too. All you have to do is get yourself a nice unenchanted staff you like and a soul gem with a grand soul inside. Take them with you the next time you go to bed, and I will grant you your staff and consider our pact sealed.\"\n\nAs you wake you feel like you hear a deep voice laughing in the distance, then fading away.")
			modData.progression = lws.progression.staffIntroDreamReceived
		end
	elseif modData.progression == lws.progression.staffIntroDreamReceived then
		--- @type tes3itemStack|nil
		local baseStaffItemStack, soulGemItemStack = checkStaffIngredientsInInventory()
		if baseStaffItemStack ~= nil and soulGemItemStack ~= nil then
			triggerStaffGrantingDream(baseStaffItemStack, soulGemItemStack)
			modData.progression = lws.progression.staffReceived
		end
	elseif modData.progression == lws.progression.staffReceived then
		-- we have the staff don't know how to level it up yet
		if modData.staffLevelUpPending then
			showDreamMessage("Once again you find yourself in the familiar dream void, only this time your new Wizard Staff is in your hand. You can feel it pulsing with excitement and drinking up the Magicka drifting through this space. The deep voice speaks to you, now seemingly emanating from the staff in your hand.\n\n\"Good job! You have channeled many spells through your staff and it shows. It is ready to grow and strengthen its enchantment. But it needs a catalyst. I believe you know already what is required. Get another soul gem with a grand soul and take it with you when you sleep. Then we shall strengthen your Wizard Staff together!\"\n\nYou are more familiar with this dream world and the voice now and ask the speaker who he is, and what he gains from your bargain. There is a brief silence before the voice can be heard again.\n\n\"Who I am need not concern you. Take confort in the promise that I require no extraordinary deeds or unexpected costs from you. Just carry your staff through the world an feed it with Magicka whenever possible. That is all I demand and require. I would consider that quite a generous offer with all the benefits your Wizard Staff will soon grant you.\n\nNow go! Get a soul gem. We shall go far together!\"\n\nYou wake covered in sweat. And your staff is pulsing expectantly in your hand.")
			modData.progression = lws.progression.levelUpIntroDreamReceived
		end
	else
		if (modData.staffFilledEnchantmentSlots >= 4) and (modData.progression < lws.progression.halfSlotsFilledDreamReceived) then
			showDreamMessage("You have a regular dream where you attend a party in the mansion of your rich friend. But as you listen to the conversations around you, the deep voice from the dream world suddenly whispers in your ear where you were leaning onto your Wizard Staff.\n\n\"You are making good progress. The enchantments on your staff have grown quite a bit, certainly to the envy of your colleagues at the Mages Guild. Do you even visit them anymore? Never mind that. I just came to warn you: Even with my vast knowledge, there are limits to how much magic a Wizard Staff can hold. Try to place more than maybe 8 enchantments on one and everything becomes unstable. Not a pretty sight! Lets just say you certainly don't want that. You are halfway there already, so I suggest thinking really carefully about what remaining effects to add to your staff.\n\nSome of the more powerful effects will only become available later when your staff has gotten even stronger. And it would be a shame to have no more room left for them when then time comes, wouldn't you say? Maybe focus on strengthening your existing enchantments for a bit and see what new wonders will soon become available.\"\n\nYou look up and all the other guests have already left the party and you find yourself standing alone in the dark courtyard of your friends manison, before you awake from your dream feeling a bit tense.")
			modData.progression = lws.progression.halfSlotsFilledDreamReceived
		elseif modData.staffLevelUpPending then
			local soulGemItemStack = checkGrandSoulInInventory()
			if soulGemItemStack ~= nil then
				consumeSoul(soulGemItemStack.object.id)
				LevelUpMenu:CreateWindow()
			else
				tes3.messageBox("Your Wizard Staff was ready to grow in power,\nbut you did not have a large enough soul with you.")
			end
		end
		-- TODO: final dream
	end
end

--- @param e uiActivatedEventData
local function restMenuActivatedCallback(e)
	if e.newlyCreated then
		--- @type tes3uiElement
		local untilHealedButton = e.element:findChild("MenuRestWait_untilhealed_button")
		if untilHealedButton ~= nil then
			untilHealedButton:registerBefore(tes3.uiEvent.mouseClick, restStartedCallback)
		end

		--- @type tes3uiElement
		local restButton = e.element:findChild("MenuRestWait_rest_button")
		if restButton ~= nil then
			restButton:registerBefore(tes3.uiEvent.mouseClick, restStartedCallback)
		end
	end
end

--- @param e uiActivatedEventData
local function uiActivatedCallback(e)
	if e.element.name == "MenuRestWait" then
		restMenuActivatedCallback(e)
	end
end

---@param e barterOfferEventData
local function barterOfferCallback(e)
	for _, sellingTile in ipairs(e.selling) do
		if sellingTile.item.id == lws.wizardStaffId then
			e.success = false
			tes3.messageBox("You can not sell your Wizard Staff")
			break
		end
	end
end

---@param e equippedEventData
local function equippedCallback(e)
	if e.mobile == tes3.player.mobile and e.item.id == lws.wizardStaffId then
		---@type lwsModData
		local modData = lws.GetModData()
		modData.staffEquipped = true
		log:trace("Wizard Staff equipped")
	end
end

---@param e unequippedEventData
local function unequippedCallback(e)
	if e.mobile == tes3.player.mobile and e.item.id == lws.wizardStaffId then
		---@type lwsModData
		local modData = lws.GetModData()
		modData.staffEquipped = false
		log:trace("Wizard Staff unequipped")
	end
end

local function checkForStaffLevelUp()
	local modData = lws.GetModData()

	if modData.staffLevelUpPending or modData.staffMaxLevelReached then
		return
	end

	local magickaForLevelUp = lws.CalculateMagickaForLevelUp(modData.staffLevel + 1)
	log:trace("Checking for Level-Up: %s / %s", modData.staffMagickaAccumulated, magickaForLevelUp)

	if modData.staffMagickaAccumulated >= magickaForLevelUp then
		modData.staffLevelUpPending = true
		tes3.messageBox("Your Wizard Staff is ready to grow in power.")
	end
end

---@param value number positive number we want to scale diminishingly
---@param halfThreshold number positive number at which the diminishing scaling factor should be 1/2
---@return number
local function diminishingReturns(value, halfThreshold)
	return value * (1 / ((1 / halfThreshold) * value + 1))
end

---@param e spellCastedEventData
local function spellCastedCallback(e)
	local modData = lws.GetModData()
	if modData.staffMaxLevelReached then
		event.unregister(tes3.event.spellCasted, spellCastedCallback)
		return
	end

	if e.caster == tes3.player then
		local spellMagickaCost = math.max(0, e.source.magickaCost)

		local staffMagickaGained
		if lws.Config.useDiminishingReturns then
			local halfThreshold = math.max(1, lws.Config.diminishingReturnHalfThreshold)
			staffMagickaGained = math.ceil(diminishingReturns(spellMagickaCost, halfThreshold))
		else
			staffMagickaGained = spellMagickaCost
		end

		if modData.staffEquipped then
			modData.staffMagickaAccumulated = modData.staffMagickaAccumulated + staffMagickaGained
			log:trace("Sucessfully cast spell with Magicka-cost %s with staff equipped, increasing the accumulated Magicka by %s to %s.", spellMagickaCost, staffMagickaGained, modData.staffMagickaAccumulated)
		else
			log:trace("Sucessfully cast spell with Magicka-cost %s without staff equipped.", spellMagickaCost)
		end

		checkForStaffLevelUp()
	end
end

local function initialized()
	event.register(tes3.event.loaded, loadedCallback)
	event.register(tes3.event.itemDropped, itemDroppedCallback)
	event.register(tes3.event.containerClosed, containerClosedCallback)
	event.register(tes3.event.uiActivated, uiActivatedCallback)
	event.register(tes3.event.barterOffer, barterOfferCallback, { priority = -99999 })
	event.register(tes3.event.equipped, equippedCallback)
	event.register(tes3.event.unequipped, unequippedCallback)
	event.register(tes3.event.spellCasted, spellCastedCallback)

	LevelUpMenu:Initialize()

	print(string.format("[%s %s] Initialized", modName, modVersion))
end

event.register(tes3.event.initialized, initialized)
