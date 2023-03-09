
local config = require("Virnetch.protectiveHelmets.config")

local resistanceEnchantment

local function isAffectedByActiveResistance(mobile)
	if not tes3.isAffectedBy({ reference = mobile, object = resistanceEnchantment }) then
		return false
	end
	for _, activeMagicEffect in pairs(mobile.activeMagicEffectList) do
		if activeMagicEffect.instance and activeMagicEffect.instance.source then
			if activeMagicEffect.instance.source == resistanceEnchantment then
				local state = activeMagicEffect.instance.state
				return (
					state == tes3.spellState.working
					or state == tes3.spellState.beginning
					or state == tes3.spellState.cast
					or state == tes3.spellState.preCast
				)
			end
		end
	end
end

local function addEffect(mobile, fromStack)
	if not mobile then return end

	if not isAffectedByActiveResistance(mobile) then
		tes3.applyMagicSource({
			reference = mobile,
			source = resistanceEnchantment,
			fromStack = fromStack,
			castChance = 100,
			target = mobile,
			bypassResistances = true
		})
	end
end

local function removeEffect(mobile)
	if not mobile then return end
	if tes3.isAffectedBy({ reference = mobile, object = resistanceEnchantment }) then
		for _, activeMagicEffect in pairs(mobile.activeMagicEffectList) do
			if activeMagicEffect.instance and activeMagicEffect.instance.source then
				if activeMagicEffect.instance.source == resistanceEnchantment then
					activeMagicEffect.instance.state = tes3.spellState.ending
				end
			end
		end
	end
end

local function isObjectBlacklisted(object)
	return (
		config.blacklist[object.id:lower()]
		or object.sourceMod and config.blacklist[object.sourceMod:lower()]
	)
end

local function isObjectWhitelisted(object)
	return (
		config.whitelist[object.id:lower()]
		or object.sourceMod and config.whitelist[object.sourceMod:lower()]
	)
end

local function isEquipmentStackWhitelisted(equipmentStack)
	local helmet = equipmentStack.object
	local itemData = equipmentStack.itemData

	-- Check also for the original item if Consistent Enchanting is installed
	local enchantedFromObjectId = itemData and itemData.data and itemData.data.ncceEnchantedFrom
	local enchantedFromObject = enchantedFromObjectId and tes3.getObject(enchantedFromObjectId)

	return isObjectWhitelisted(helmet) or ( enchantedFromObject and isObjectWhitelisted(enchantedFromObject) )
end

--- @type table<string, mwseSafeObjectHandle>
local npcsToUpdate = {}
local function updateResistance(e)
	if e.eventType and e.eventType == "unequipped" then
		-- Remove immediately, so that effect is reapplied if player equips something else
		-- Otherwise the effects fromStack source would remain as the previous helmet.
		if e.item and e.item.slot and e.item.slot == tes3.armorSlot.helmet then
			removeEffect(e.reference.mobile)
			return
		end
	end

	if tes3ui.menuMode() then
		-- Adding effects in menuMode will only add the effect after exiting menuMode,
		-- resulting in possibly multiple effects being added if player equips and
		-- unequips helmet multiple times.
		npcsToUpdate[e.reference.id] = tes3.makeSafeObjectHandle(e.reference)
		return
	end

	-- Get the current equipped helmet by the actor
	local equippedHelmet = tes3.getEquippedItem({
		actor = e.reference,
		objectType = tes3.objectType.armor,
		slot = tes3.armorSlot.helmet
	})
	local helmet = equippedHelmet and equippedHelmet.object

	-- Remove effect if actor is not wearing a helmet, or if helmet is in blacklist
	if not ( helmet and helmet.parts ) or isObjectBlacklisted(helmet) then
		removeEffect(e.reference.mobile)
		return
	end

	-- Add effect if actor's helmet is whitelisted
	if isEquipmentStackWhitelisted(equippedHelmet) then
		addEffect(e.reference.mobile, equippedHelmet)
		return
	end

	-- Add effect if actor's helmet covers the entire head
	for _, part in pairs(helmet.parts) do
		if part.type == tes3.activeBodyPart.head then
			-- The helmet covers entire head, add effect if actor doesn't already have it
			addEffect(e.reference.mobile, equippedHelmet)
			return
		end
	end

	-- Remove effect if actor's helmet doesn't cover the entire head
	removeEffect(e.reference.mobile)
end

local function menuExit()
	for _, refHandle in pairs(npcsToUpdate) do
		if refHandle:valid() then
			updateResistance({ reference = refHandle:getObject() })
		end
	end
	npcsToUpdate = {}
end

local function cellChanged()
	timer.delayOneFrame(function()
		-- Need to delay a frame or the effect won't get applied...
		local cell = tes3.getPlayerCell()
		if cell then
			for reference in cell:iterateReferences(tes3.objectType.npc) do
				updateResistance({ reference = reference })
			end
		end
	end)
end

--- @param e vfxCreatedEventData
local function blockHelmetResistanceVFX(e)
	if not e.vfx.sourceInstance.source then return end
	if e.vfx.sourceInstance.source ~= resistanceEnchantment then return end

	e.vfx.expired = true

	-- Claim the effect in case another mod were to implement a custom vfx etc.
	e.claim = true
end

local function initialized()

	-- Create the enchantment
	resistanceEnchantment = tes3.createObject({
		objectType = tes3.objectType.enchantment,
		id = "vir_pm_resistances",
		name = "Helmet Resistances",
		castType = tes3.enchantmentType.constant,
		chargeCost = 1,
		maxCharge = 1,
		effects = {
			( config.enableBlight and ( config.blightMag > 0 ) and {
				id = tes3.effect.resistBlightDisease,
				min = config.blightMag,
				max = config.blightMag
			}),
			( config.enableDisease and ( config.diseaseMag > 0 ) and {
				id = tes3.effect.resistCommonDisease,
				min = config.diseaseMag,
				max = config.diseaseMag
			}),
			( config.enablePoison and ( config.poisonMag > 0 ) and {
				id = tes3.effect.resistPoison,
				min = config.poisonMag,
				max = config.poisonMag
			})
		}
	})

	event.register(tes3.event.cellChanged, cellChanged)
	event.register(tes3.event.equipped, updateResistance)
	event.register(tes3.event.unequipped, updateResistance)
	event.register(tes3.event.menuExit, menuExit)
	event.register(tes3.event.vfxCreated, blockHelmetResistanceVFX, { priority = 10 })

	mwse.log("[Protective Helmets] Initialized.")
end
event.register(tes3.event.initialized, initialized)

event.register(tes3.event.modConfigReady, function()
	require("Virnetch.protectiveHelmets.mcm")
end)