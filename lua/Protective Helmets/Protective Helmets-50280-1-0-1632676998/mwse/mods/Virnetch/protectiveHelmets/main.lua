
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

local function isWhitelisted(equipmentStack)
	local helmet = equipmentStack.object
	local itemData = equipmentStack.itemData
	-- Check also for the original item if Consistent Enchanting is installed
	local enchantedFromObject = itemData and itemData.data and itemData.data.ncceEnchantedFrom and tes3.getObject(itemData.data.ncceEnchantedFrom)

	return (
	  config.whitelist[helmet.id:lower()]
	  or helmet.sourceMod and config.whitelist[helmet.sourceMod:lower()]
	  or enchantedFromObject and (
		config.whitelist[enchantedFromObject.id:lower()]
		or enchantedFromObject.sourceMod and config.whitelist[enchantedFromObject.sourceMod:lower()]
	  )
	)
end

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
		npcsToUpdate[e.reference.id] = e.reference
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
	if not ( helmet and helmet.parts )
	  or config.blacklist[helmet.id:lower()]
	  or helmet.sourceMod and config.blacklist[helmet.sourceMod:lower()] then
		removeEffect(e.reference.mobile)
		return
	end

	if isWhitelisted(equippedHelmet) then
		addEffect(e.reference.mobile, equippedHelmet)
		return
	end

	for _, part in pairs(helmet.parts) do
		if part.type == tes3.activeBodyPart.head then
			-- The helmet covers entire head, add effect if actor doesn't already have it
			addEffect(e.reference.mobile, equippedHelmet)
			return
		end
	end

	-- No head parts found, remove effect
	removeEffect(e.reference.mobile)
end

local function menuExit()
	for _, ref in pairs(npcsToUpdate) do
		updateResistance({ reference = ref })
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

	event.register("cellChanged", cellChanged)
	event.register("equipped", updateResistance)
	event.register("unequipped", updateResistance)
	event.register("menuExit", menuExit)

	mwse.log("[Protective Helmets] Initialized.")
end
event.register("initialized", initialized)

event.register("modConfigReady", function()
	require("Virnetch.protectiveHelmets.mcm")
end)