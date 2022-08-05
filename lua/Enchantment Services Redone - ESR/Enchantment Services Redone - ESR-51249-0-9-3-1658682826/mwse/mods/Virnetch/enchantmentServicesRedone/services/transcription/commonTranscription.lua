local commonTranscription = {}

local common = require("Virnetch.enchantmentServicesRedone.common")


--- Returns the propertyObject stored on a uiElement in the transcription menu
--- @param propName string The property name.
--- @param elementOrId tes3uiElement|string|number The element or its id
--- @param expectedUsertype string? Optional. A Lua usertype name, if expecting a non-standard object type.
function commonTranscription.getStoredPropertyObject(propName, elementOrId, expectedUsertype)
	local menu = tes3ui.findMenu(common.GUI_ID.TranscriptionMenu)
	if not menu then return end

	--- @type tes3uiElement
	local element = type(elementOrId) == "userdata" and elementOrId or menu:findChild(elementOrId)
	if not element then return end

	local property = element:getPropertyObject(propName, expectedUsertype)
	if property and type(property) == "userdata" then
		return property
	end
end

function commonTranscription.updateMenu()
	local menu = tes3ui.findMenu(common.GUI_ID.TranscriptionMenu)
	if not menu then return end

	-- Update layout first to update the itemSelectors
	menu:updateLayout()

	-- Get if this is a service or player menu
	local isService = menu:getPropertyBool("vir_esr_isService")

	local scrollBlock = menu:findChild(common.GUI_ID.TranscriptionMenu_scrollBlock)
	local countBlock = menu:findChild(common.GUI_ID.TranscriptionMenu_countBlock)

	local newCount = menu:getPropertyInt("vir_esr_count")
	local maxCount = 1

	-- Reduce count to the amount of empty scrolls player has
	local sourceScroll = commonTranscription.getStoredPropertyObject("vir_esr_item", common.GUI_ID.TranscriptionMenu_sourceBlock)
	if sourceScroll then
		maxCount = scrollBlock and ( scrollBlock:getPropertyInt("vir_esr_itemCount") or 1 ) or math.huge
	end

--		-- Limit by gold amount
--		if isService then
--			local costForOne = calculateTranscriptionCost(sourceScroll)
--			local affordAmount = math.floor( tes3.getPlayerGold() / costForOne )
--			maxCount = math.min(maxCount, affordAmount)
--		end
--	end

	-- Get the amount of soul in the selected gem
	local itemData = commonTranscription.getStoredPropertyObject("vir_esr_itemData", common.GUI_ID.TranscriptionMenu_soulBlock, "tes3itemData")
	local soulInGem = itemData and itemData.soul.soul or 0

	-- Required amount of soul is equal to the enchantCapacity of the scroll, multiplied by count
	-- If item requirements for the scroll are disabled, the enchantCapacity of the sourceScroll is used instead.
	local scroll = commonTranscription.getStoredPropertyObject("vir_esr_item",
		(scrollBlock or common.GUI_ID.TranscriptionMenu_sourceBlock)
	)

	-- Reduce count to current soul
	local soulRequiredForOneTranscription = 0
	if scroll then
		local enchantCapacity = commonTranscription.getEnchantCapacity(scroll)
		soulRequiredForOneTranscription = enchantCapacity / 10

		-- Reduce count if it's too high for the soul
		if soulInGem > 0 then
			local maxCountForSoul = math.max(1, math.floor(soulInGem / soulRequiredForOneTranscription))
			maxCount = math.min(maxCount, maxCountForSoul)
		end
	end

	if maxCount == math.huge then
		-- Currently no limits, disable count changing
		maxCount = 1
	elseif newCount == -1 then
		-- Player clicked the max count button
		newCount = maxCount
	end

	maxCount = math.max(maxCount, 1)
	newCount = math.clamp(newCount, 1, maxCount)
	menu:setPropertyInt("vir_esr_count", newCount)

	-- Multiply required soul amount by count
	local soulRequired = newCount * soulRequiredForOneTranscription

	menu:setPropertyInt("vir_esr_soulInGem", soulInGem)
	menu:setPropertyInt("vir_esr_soulRequired", soulRequired)


	-- Update the labels
	local countLabel = countBlock:findChild(common.GUI_ID.TranscriptionMenu_countLabel)
	countLabel.text = newCount

	local soulAmountLabel = menu:findChild(common.GUI_ID.TranscriptionMenu_soulAmountLabel)
	if soulAmountLabel then
		soulAmountLabel.text = string.format("%i/%i", soulRequired, soulInGem)
	end

	if isService then
		-- Update the cost of the service
		local cost = 0
		if sourceScroll then
			_, cost = commonTranscription.calculateTranscriptionCost(sourceScroll, newCount)
		end

		menu:setPropertyInt("vir_esr_cost", cost)

		-- Update the label
		local costLabel = menu:findChild(common.GUI_ID.TranscriptionMenu_costLabel)
		costLabel.text = string.format("%i", cost)
	else
		-- Update the chance of successfully transcribing
		local chance = 0
		if sourceScroll then
			chance = commonTranscription.calculateTranscriptionChance(tes3.mobilePlayer, sourceScroll, newCount)
		end

		menu:setPropertyInt("vir_esr_chance", chance)

		-- Update the label
		local chanceLabel = menu:findChild(common.GUI_ID.TranscriptionMenu_chanceLabel)
		chanceLabel.text = string.format("%i", menu:getPropertyInt("vir_esr_chance"))
	end

	if scrollBlock then
		-- Update the Scroll-label's color
		local label = scrollBlock:findChild(common.GUI_ID.itemSelect_label)
		local powerMult = commonTranscription.getPowerMult()
		if powerMult and powerMult < 1 then
			label.color = {0.85, 0.25, 0.15}
		else
			label.color = common.palette.headerColor
		end
	end
end

--- @param scroll tes3book
--- @return number
function commonTranscription.getEnchantCapacity(scroll)
	if not scroll then return end

	if not scroll.enchantment and scroll.enchantCapacity > 0 then
		return scroll.enchantCapacity
	end

	local mesh = scroll.mesh and scroll.mesh:lower()
	return mesh and common.enchantCapacitiesByMesh[mesh] or scroll.enchantCapacity or 0
end

--- Calculates the cost of transcribing an item through a service.
--- @param item tes3book The sourceScroll
--- @param count integer? Optional. Default: 1
--- @param merchant tes3mobileActor? Optional. Default is the current serviceActor
--- @return number baseCost The base cost for creating the transcriptions
--- @return number totalPrice Total cost modified by the merchant
function commonTranscription.calculateTranscriptionCost(item, count, merchant)
	count = count or 1

	-- Calculate base cost: value of scroll + half of its charge cost
	local chargeCost = common.calculateMagickaCost(item.enchantment)
	local baseTranscriptionCost = count * math.floor(item.value + chargeCost / 2)

	-- Modify for current merchant
	merchant = merchant or tes3ui.getServiceActor()
	local totalPrice = tes3.calculatePrice({
		object = item,
		basePrice = baseTranscriptionCost,
		merchant = merchant,
		bartering = true,	-- To trigger Buying Game calculations, otherwise it would be more expensive to buy scrolls the NPC already has
		count = count
	})

	-- Modify the final price with config
	totalPrice = math.floor(totalPrice * (common.config.transcription.costMult/100))

	return baseTranscriptionCost, totalPrice
end

--- Calculates the chance of succesfully transcribing a scroll.
--- @param merchant tes3mobileActor
--- @param item tes3book The sourceScroll
--- @param count integer? Optional. Default: 1
--- @return number
function commonTranscription.calculateTranscriptionChance(merchant, item, count)
	count = count or 1

	--[[
		https://en.uesp.net/wiki/Morrowind:Enchant - Enchanting success rate

		The percent chance to successfully self-enchant an item is %Success
			= (8×Enchant + 2×Intelligence + Luck - 20×chargeCost×(1 + "Effect is constant"))/8
		The formula in OpenMW is a bit different : %Success
			= (0.75 + %Fatigue) × (1-0.4318×"Effect is constant") × (10×Enchant + 2×Intelligence + Luck - 30×chargeCost)/10

		https://gitlab.com/OpenMW/openmw/-/wikis/development/research#self-enchanting

		z = enchantSkill - y * fEnchantmentChanceMult
		x = (z + 0.2 * pcIntelligence + 0.1 * pcLuck) * fatigueTerm
		if enchantment is constant effect:
			x *= fEnchantmentConstantChanceMult
		x = int(x)
	]]

	local baseChance = common.calculateBaseEnchantChanceForActor(merchant)
	local baseTranscriptionCost = commonTranscription.calculateTranscriptionCost(item, 1, merchant)
	local chance = baseChance - baseTranscriptionCost^(2/3)

	common.log:debug(" Chance to transcribe %s: %.2f - %.2f = %.2f",
		item.id, baseChance, (baseChance - chance), chance
	)

	-- Chance decreases if trying to create multiple scrolls at once
	chance = chance / count^(1/3)

	if merchant == tes3.mobilePlayer then
		chance = chance / (common.config.transcription.playerChanceMult/100)
	end

	return math.max(0, chance)
end

--- Determines if a merchant can transcribe an item
--- @param merchant tes3mobileNPC
--- @param item tes3book
--- @return boolean
function commonTranscription.canTranscribeItem(merchant, item)
	if not common.config.transcription.enableChance then return true end

	-- Get the chance for NPC
	local chance = commonTranscription.calculateTranscriptionChance(merchant, item)

	-- Get the required chance
	local chanceRequired = common.config.transcription.chanceRequired

	-- Modify required chance by disposition
	local disposition = merchant.object.disposition
	if disposition then
		local dispFactor = common.config.dispositionFactor
		chanceRequired = chanceRequired + math.remap(math.clamp(disposition, 0, 100), 0, 100, dispFactor, -dispFactor)
	end

	common.log:debug("  chance: %i, required: %i for transcribing %s", chance, chanceRequired, item.id)

	return ( chance >= chanceRequired )
end

function commonTranscription.getPowerMult(scroll)
	local sourceScroll = commonTranscription.getStoredPropertyObject("vir_esr_item", common.GUI_ID.TranscriptionMenu_sourceBlock)
	scroll = scroll or commonTranscription.getStoredPropertyObject("vir_esr_item", common.GUI_ID.TranscriptionMenu_scrollBlock)

	if sourceScroll and scroll then
		local sourceScrollEnchantCapacity = commonTranscription.getEnchantCapacity(sourceScroll)
		sourceScrollEnchantCapacity = math.max(sourceScrollEnchantCapacity, 1)

		return math.min((scroll.enchantCapacity/sourceScrollEnchantCapacity), 1)
	end
end

return commonTranscription