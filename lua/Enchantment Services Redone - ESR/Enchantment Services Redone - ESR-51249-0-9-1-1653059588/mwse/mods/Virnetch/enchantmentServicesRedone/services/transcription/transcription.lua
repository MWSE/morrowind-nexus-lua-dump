local transcription = {}

local common = require("Virnetch.enchantmentServicesRedone.common")
local objectCreator = require("Virnetch.enchantmentServicesRedone.objects.objectCreator")

local commonTranscription = require("Virnetch.enchantmentServicesRedone.services.transcription.commonTranscription")
local transcriptionMenu = require("Virnetch.enchantmentServicesRedone.services.transcription.transcriptionMenu")


--[[
	Creates a new enchantment with reduced effect magnitudes, radiuses and
	durations. All effects with a duration and magnitude of one or less are
	removed. Returns nil if all effects were removed. If an effect already has a
	magnitude of one, then duration will be reduced twice. Likewise if the
	original effect has no duration, the min and max magnitude of the effect are
	reduced twice.
]]
--- @param originalEnchantment tes3enchantment
--- @param powerMult number
--- @return tes3enchantment|nil
function transcription.createWeakenedEnchantment(originalEnchantment, powerMult)
	common.log:debug("Reducing enchantment effects due to low enchantCapacity (%.2f/1)", powerMult)

	local function getNew(old)
		local mult = (0.01 * math.random(70, 100)) * powerMult
		local new = mult * old
		new = math.floor(new)
		common.log:debug("  %.2f * %i = %i", mult, old, new)
		return new
	end

	-- Go through each effect in the enchantment and reduce min, max, radius and duration to getNew()
	local newEffects = {}
	for _, effect in ipairs(originalEnchantment.effects) do
		if effect.object then
			local missingProperties = 1
			if effect.duration <= 1 then missingProperties = missingProperties + 1 end
			if effect.max <= 1 then missingProperties = missingProperties + 1 end
			if effect.radius <= 0 then missingProperties = missingProperties + 1 end

			-- Effects with a duration, magnitude and radius of 1 in the original enchantment will always get discarded
			if missingProperties == 4 then
				common.log:debug(" Removing %s effect from enchantment. No duration or magnitude.", effect.object.name)
			else
				local newMin, newMax, newDuration, newRadius
				if effect.max > 1 then
					common.log:debug(" Calculating new max magnitude on effect %s", effect.object.name)
					if effect.duration > 1 then
						newMax = getNew(effect.max)
					else
						newMax = effect.max / math.sqrt(missingProperties)
						common.log:debug("  %i / %.2f = %i", effect.max, math.sqrt(missingProperties), newMax)
						newMax = getNew(newMax)
					end
					newMax = math.max(newMax, 1)
				end

				if effect.min > 1 then
					common.log:debug(" Calculating new min magnitude on effect %s", effect.object.name)
					if effect.duration > 1 then
						newMin = getNew(effect.min)
					else
						newMin = effect.min / math.sqrt(missingProperties)
						common.log:debug("  %i / %.2f = %i", effect.min, math.sqrt(missingProperties), newMin)
						newMin = getNew(newMin)
					end
					newMin = math.min(newMin, newMax)
				end

				if effect.duration > 1 then
					common.log:debug(" Calculating new duration on effect %s", effect.object.name)
					if effect.max > 1 then
						newDuration = getNew(effect.duration)
					else
						newDuration = effect.duration / math.sqrt(missingProperties)
						common.log:debug("  %i / %.2f = %i", effect.duration, math.sqrt(missingProperties), newDuration)
						newDuration = getNew(newDuration)
					end
					newDuration = math.max(newDuration, 1)
				end

				if effect.radius > 0 then
					common.log:debug(" Calculating new radius on effect %s", effect.object.name)
					newRadius = effect.radius / math.sqrt(missingProperties)
					common.log:debug("  %i / %.2f = %i", effect.radius, math.sqrt(missingProperties), newRadius)
					newRadius = getNew(newRadius)
				end

				newMin = newMin or effect.min
				newMax = newMax or effect.max
				newDuration = newDuration or effect.duration
				newRadius = newRadius or effect.radius

				common.log:debug(" Adding effect to new enchantment: %s %i-%i pt at %i ft. for %i sec", effect.object.name, newMin, newMax, newRadius, newDuration)
				newEffects[#newEffects+1] = {
					id = effect.id,
					rangeType = effect.rangeType,
					attribute = effect.attribute,
					skill = effect.skill,

					min = newMin,
					max = newMax,
					duration = newDuration,
					radius = newRadius
				}
			end
		end
	end

	-- Create a new enchantment with the adjusted effects
	if #newEffects > 0 then
		common.log:debug("Creating new enchantment with %i effects.", #newEffects)

		local newEnchantment = objectCreator.createTemporaryObject({
			objectType = tes3.objectType.enchantment,
			id = common.getRandomId("vir_esr_en"),
			castType = tes3.enchantmentType.castOnce,
			chargeCost = originalEnchantment.chargeCost,
			maxCharge = originalEnchantment.maxCharge,
			effects = newEffects
		})

		common.log:debug(" Created new enchantment with id %s", newEnchantment.id)
		return newEnchantment
	end
end

--- Creates a new transcription, returning a scroll similar to targetScroll, but with
---	the enchantment of sourceScroll, with effects modified according to powerMult.
--- @param sourceScroll tes3book
--- @param targetScroll tes3book
--- @param name string The name the created scroll will have
--- @param powerMult number
--- @return tes3book
function transcription.createTranscription(sourceScroll, targetScroll, name, powerMult)
	-- Check if item requirements for the scroll is disabled. If so, just add a copy of the original scroll.
	if not targetScroll then
		return sourceScroll
	end

	-- Use already existing item if possible
	if (
		powerMult >= 1
		and sourceScroll.name == name
		and sourceScroll.mesh:lower() == targetScroll.mesh:lower()
		and sourceScroll.icon:lower() == targetScroll.icon:lower()
	) then
		return sourceScroll
	end

	-- Create a new enchantment if targetScroll has lower enchantCapacity than sourceScroll.
	-- Otherwise use the sourceScroll's enchantment
	local enchantment
	if powerMult < 1 then
		enchantment = transcription.createWeakenedEnchantment(sourceScroll.enchantment, powerMult)
	else
		enchantment = sourceScroll.enchantment
	end

	common.log:debug("Creating new transcription from %s to %s.", sourceScroll.id, targetScroll.id)

	-- Calculate value for the scroll based on how much weaker the enchantment is
	local value = sourceScroll.value
	if powerMult < 1 then
		local sourceMagickaCost = common.calculateMagickaCost(sourceScroll.enchantment)
		local newMagickaCost = common.calculateMagickaCost(enchantment)
		value = (newMagickaCost / sourceMagickaCost) * sourceScroll.value
		value = math.floor(value)
	end

	local originalSource = common.savedData.transcriptions[sourceScroll.id:lower()] or sourceScroll.id:lower()

	-- First check if there already is a transcription that would be suitable
	for previouslyCreatedId, previouslyCreatedOriginalSource in pairs(common.savedData.transcriptions) do
		local previouslyCreated = tes3.getObject(previouslyCreatedId)
		if previouslyCreated then
			if (
				previouslyCreatedOriginalSource == originalSource
				and previouslyCreated.enchantment == enchantment
				and previouslyCreated.name == name
				and previouslyCreated.mesh == targetScroll.mesh
				and previouslyCreated.icon == targetScroll.icon
				and previouslyCreated.enchantCapacity == targetScroll.enchantCapacity
				and previouslyCreated.weight == targetScroll.weight
				and previouslyCreated.value == value
			) then
				common.log:debug("Found previous transcription %s that would be identical with the new transcription. Returning that one instead.", previouslyCreated)
				return previouslyCreated
			end
		end
	end

	local newScroll = objectCreator.createTemporaryObject({
		objectType = tes3.objectType.book,
		type = tes3.bookType.scroll,
		id = common.getRandomId("vir_esr_sc"),
		name = name,
		mesh = targetScroll.mesh,
		icon = targetScroll.icon,
		enchantment = enchantment,
		enchantCapacity = targetScroll.enchantCapacity,
		weight = targetScroll.weight,
		value = value
	})

	-- Store the source of the transcription to later get the original text
	common.savedData.transcriptions[newScroll.id:lower()] = originalSource

	common.log:debug(" Created transcription with id %s", newScroll.id)
	return newScroll
end

local function onTranscribeClick(isService)
	local menu = tes3ui.findMenu(common.GUI_ID.TranscriptionMenu)
	if not menu then return	end

	local cost = isService and menu:getPropertyInt("vir_esr_cost")
	local sourceScroll, targetScroll, soulGem

	-- Check source scroll
	sourceScroll = commonTranscription.getStoredPropertyObject("vir_esr_item", common.GUI_ID.TranscriptionMenu_sourceBlock)
	if not sourceScroll then
		tes3.messageBox(common.i18n("service.transcription.mainMenu.noSource"))
		return
	end

	-- Check target scroll, if enabled
	if menu:findChild(common.GUI_ID.TranscriptionMenu_scrollBlock) then
		targetScroll = commonTranscription.getStoredPropertyObject("vir_esr_item", common.GUI_ID.TranscriptionMenu_scrollBlock)
		if not targetScroll then
			tes3.messageBox(common.i18n("service.transcription.mainMenu.noTargetScroll"))
			return
		end
	end

	-- Check soul gem, if enabled
	if menu:findChild(common.GUI_ID.TranscriptionMenu_soulBlock) then
		soulGem = commonTranscription.getStoredPropertyObject("vir_esr_item", common.GUI_ID.TranscriptionMenu_soulBlock)
		if not soulGem then
			tes3.messageBox(common.i18n("service.transcription.mainMenu.noSoulGem"))
			return
		end

		-- Make sure that soul is enough
		local soulInGem = menu:getPropertyInt("vir_esr_soulInGem")
		local soulRequired = menu:getPropertyInt("vir_esr_soulRequired")
		if soulInGem < soulRequired then
			tes3.messageBox(common.i18n("service.transcription.mainMenu.lowSoul"))
			return
		end
	end

	-- Prevent creation of scrolls with no effects.
	-- If powerMult < 1, then all effects with a duration and magnitude of 1 are removed.
	local powerMult = commonTranscription.getPowerMult(targetScroll)
	if powerMult and powerMult < 1 then
		local willHaveEffects = false
		for _, effect in ipairs(sourceScroll.enchantment.effects) do
			if effect.object and (effect.duration > 1 or effect.max > 1 or effect.radius > 0) then
				willHaveEffects = true
				break
			end
		end
		if not willHaveEffects then
			tes3.messageBox(common.i18n("service.transcription.mainMenu.noEffectsOnResult"))
			return
		end
	end

	local success = true
	if isService then
		-- Check if npc is skilled enough
		local merchant = tes3ui.getServiceActor()
		if not commonTranscription.canTranscribeItem(merchant, sourceScroll) then
			tes3.messageBox(common.i18n("service.transcription.mainMenu.cantTranscribe"))
			return
		end

		-- Check if player can afford
		if tes3.getPlayerGold() < cost then
			tes3.messageBox(tes3.findGMST(tes3.gmst.sBarterDialog1).value)
			return
		end

		-- Move gold
		tes3.transferItem({
			from = tes3.player,
			to = merchant,
			item = "Gold_001",
			count = cost
		})
	else
		-- Calculate chance of successfully transcribing
		local chance = menu:getPropertyInt("vir_esr_chance")
		local roll = math.random()
		common.log:debug("Chance: %i, Roll: %.1f", chance, roll*100)
		if roll > chance/100 then
			tes3.playSound({ sound = "enchant fail" })
			tes3.messageBox(common.i18n("service.transcription.mainMenu.transcriptionFailed"))

			success = false
		end
	end

	-- Remove gem
	if soulGem then
		tes3.removeItem({
			reference = tes3.player,
			item = soulGem,
			itemData = commonTranscription.getStoredPropertyObject("vir_esr_itemData", common.GUI_ID.TranscriptionMenu_soulBlock, "tes3itemData"),
			playSound = false
		})
	end

	if success then
		-- Get the name of transcription
		local nameInput = menu:findChild(common.GUI_ID.TranscriptionMenu_nameInput)
		local name = (nameInput and nameInput.text and string.len(nameInput.text) > 0)
			and nameInput.text or sourceScroll.name

		-- Get the number of transcriptions to create
		local count = menu:getPropertyInt("vir_esr_count")

		-- Create the transcription
		local scroll = transcription.createTranscription(sourceScroll, targetScroll, name, powerMult)

		-- Add the scrolls, remove the blank ones
		tes3.messageBox(common.i18n("service.transcription.mainMenu.transcriptionSucceeded"))
		tes3.playSound({ sound = "enchant success" })
		if targetScroll then
			tes3.removeItem({
				reference = tes3.player,
				item = targetScroll,
				count = count,
				playSound = false
			})
		end
		tes3.addItem({
			reference = tes3.player,
			item = scroll,
			count = count
		})

		if not isService then
			-- Exercise Enchant skill on successful transcription
			local createEnchantmentExperience = tes3.getSkill(tes3.skill.enchant).actions[3]
			local progress = common.config.transcription.experienceMult/100 * math.sqrt(count) * createEnchantmentExperience
			tes3.mobilePlayer:exerciseSkill(tes3.skill.enchant, progress)
			common.log:debug("exerciseSkill enchant by %.2f", progress)
		end
	end

	tes3ui.updateInventorySelectTiles()
	tes3.updateMagicGUI({ reference = tes3.player })

	commonTranscription.updateMenu()
end

--- Shows the transcription menu
--- @param isService boolean True if this is a service offered by an NPC, false if player-transcription
--- @param firstSoul {item:tes3misc, itemData:tes3itemData}? Optional. Will be automatically selected in the soul gem slot
function transcription.showTranscriptionMenu(isService, firstSoul)
	local menu = transcriptionMenu.createMenu(isService, firstSoul)
	if menu then
		local buyButton = menu:findChild(common.GUI_ID.TranscriptionMenu_buyButton)
		if buyButton then
			buyButton:register(tes3.uiEvent.mouseClick, function()
				onTranscribeClick(true)
			end)
		end

		local transcribeButton = menu:findChild(common.GUI_ID.TranscriptionMenu_transcribeButton)
		if transcribeButton then
			transcribeButton:register(tes3.uiEvent.mouseClick, function()
				onTranscribeClick(false)
			end)
		end
	end
end

-- Enchanted scrolls usually have the enchantCapacity value set to 0.
-- To get the enchantCapacity for sourceScroll, we use the value of an
-- unenchanted scroll with the same mesh.
do
	common.log:debug("Storing enchantCapacities by mesh for transcription...")
	common.enchantCapacitiesByMesh = {}
	local scrollForMesh = {}
	for book in tes3.iterateObjects(tes3.objectType.book) do
		if (
			book.type == tes3.bookType.scroll
			and book.enchantCapacity > 0
		) then
			-- Prioritization for enchant capacity:
			-- 1. Unenchanted, empty scroll
			-- 2. Unenchated scroll
			-- 3. Any other scroll with enchantCapacity
			local mesh = book.mesh:lower()
			if not book.enchantment then
				if (not book.text or book.text == "") then
					scrollForMesh[mesh] = book
				elseif not scrollForMesh[mesh] or scrollForMesh[mesh].enchantment then
					scrollForMesh[mesh] = book
				end
			elseif not scrollForMesh[mesh] then
				scrollForMesh[mesh] = book
			end
		end
	end
	for mesh, scroll in pairs(scrollForMesh) do
		common.enchantCapacitiesByMesh[mesh] = scroll.enchantCapacity
		common.log:debug("	%s: %s from %s", scroll.enchantCapacity, mesh, scroll.id)
	end
	common.log:debug("Done storing enchantCapacities.")
end

if common.config.transcription.showOriginalText then
	--- @param e bookGetTextEventData
	local function onBookGetText(e)
		if not e.book then return end

		local bookId = e.book.id:lower()
		if common.savedData.transcriptions[bookId] then
			local sourceScroll = tes3.getObject(common.savedData.transcriptions[bookId])
			if sourceScroll then
				common.log:debug("Replaced transcription %s's text with original from %s", e.book.id, sourceScroll.id)
				e.text = sourceScroll.text
			end
		end
	end
	event.register(tes3.event.bookGetText, onBookGetText, { priority = 1000 })
end

return transcription