local seph = require("seph")
local blackSoulGem = require("seph.npcSoulTrapping.blackSoulGem")
local npcSoulMode = require("seph.npcSoulTrapping.npcSoulMode")
local interop = require("seph.npcSoulTrapping.interop")

local npcSoulTrap = seph.Module:new()

npcSoulTrap.magicEffectName = "npcSoulTrap"
npcSoulTrap.magicEffectId = 10000
npcSoulTrap.sMagicTargetResisted = ""

---@param reference tes3reference
function npcSoulTrap.isValidTarget(reference)
	return reference and reference.baseObject.objectType == tes3.objectType.npc
end

---@param reference tes3reference
function npcSoulTrap.isNpcException(reference)
	local config = npcSoulTrap.mod.config.current
	local id = reference.baseObject.id:lower()
	return (config.npcExceptions[id] or interop.npcExceptions[id]) ~= nil
end

---@param reference tes3reference
function npcSoulTrap.requiresBlackSoulGem(reference)
	local config = npcSoulTrap.mod.config.current
	return config.blackSoulGem.required and not npcSoulTrap.isNpcException(reference)
end

---@param reference tes3reference
function npcSoulTrap.getSmallestFittingSoulGem(reference)
	local config = npcSoulTrap.mod.config.current
	local soulValue = reference.baseObject.soul
	if soulValue then
		local smallestSoulGem = nil
		local soulGems = {}
		for _, itemStack in pairs(tes3.player.object.inventory) do
			if itemStack.object.isSoulGem then
				local isValidSoulGem = false
				local isBlackSoulGem = blackSoulGem.isBlackSoulGem(itemStack.object)

				if npcSoulTrap.isNpcException(reference) then
					isValidSoulGem = config.blackSoulGem.canSoulTrapCreatures or not isBlackSoulGem
				else
					isValidSoulGem = not npcSoulTrap.requiresBlackSoulGem(reference) or isBlackSoulGem
				end

				if isValidSoulGem then
					local emptyCount = itemStack.count - (itemStack.variables and #itemStack.variables or 0)
					if emptyCount > 0 then
						table.insert(soulGems, itemStack.object)
					end
				end
			end
		end
		for _, soulGem in pairs(soulGems) do
			if soulGem.soulGemCapacity >= soulValue and (not smallestSoulGem or smallestSoulGem.soulGemCapacity > soulGem.soulGemCapacity) then
				smallestSoulGem = soulGem
			end
		end
		return smallestSoulGem
	end
	return nil
end

---@param position tes3vector3
function npcSoulTrap.playSoulTrapVisualEffect(position)
	tes3.createVisualEffect{
		effect = "VFX_Soul_Trap",
		position = position,
		repeatCount = 1
	}
end

---@param reference tes3reference
function npcSoulTrap.trapSoul(reference)
	local soulGem = npcSoulTrap.getSmallestFittingSoulGem(reference)
	if soulGem then
		local response = event.trigger(
			"seph.npcSoulTrap:soulTrap",
			{
				reference = reference,
				soulGem = soulGem
			}
		)

		if response.block then
			npcSoulTrap.logger:debug(string.format("Soul trapping for '%s' inside '%s' has been blocked.", reference.baseObject.id, soulGem.id))
			return
		end

		reference = response.reference
		soulGem = response.soulGem

		tes3.removeItem{reference = tes3.player, item = soulGem, playSound = false}
		tes3.addItem{reference = tes3.player, item = soulGem, soul = tes3.getObject(reference.baseObject.id), playSound = false}
		tes3.playSound{reference = reference, sound = "conjuration hit"}
		npcSoulTrap.playSoulTrapVisualEffect(reference.position)
		tes3.messageBox(tes3.findGMST(tes3.gmst.sSoultrapSuccess).value)
		npcSoulTrap.logger:debug(string.format("Trapped soul '%s' inside '%s'", reference.baseObject.id, soulGem.id))
		
		event.trigger(
			"seph.npcSoulTrap:soulTrapped",
			{
				reference = reference,
				soulGem = soulGem
			}
		)
	end
end

---@param name string
---@param duration number
function npcSoulTrap.createDummySoulTrapSpell(name, duration)
	local spell = tes3.createObject{objectType = tes3.objectType.spell, getIfExists = false}
	spell.name = name
	spell.alwaysSucceeds = true
	spell.castType = tes3.spellType.spell
	spell.magickaCost = 0
	local effect = spell.effects[1]
	effect.id = tes3.effect.npcSoulTrap
	effect.min = 0
	effect.max = 0
	effect.radius = 0
	effect.rangeType = tes3.effectRange.touch
	effect.duration = duration
	effect.attribute = -1
	effect.skill = -1
	tes3.setSourceless(spell)
	return spell
end

---@param eventData magicEffectsResolvedEventData
function npcSoulTrap.onMagicEffectsResolved(eventData)
	local soulTrap = tes3.getMagicEffect(tes3.effect.soultrap)
	tes3.addMagicEffect{
		id = npcSoulTrap.magicEffectId,
		name = npcSoulTrap.magicEffectName,
		description = "",
		school = tes3.magicSchool.mysticism,
		baseCost = 0,
		speed = soulTrap.speed,
		allowEnchanting = false,
		allowSpellmaking = false,
		appliesOnce = soulTrap.appliesOnce,
		canCastSelf = true,
		canCastTarget = true,
		canCastTouch = true,
		casterLinked = soulTrap.casterLinked,
		hasContinuousVFX = soulTrap.hasContinuousVFX,
		hasNoDuration = soulTrap.hasNoDuration,
		hasNoMagnitude = soulTrap.hasNoMagnitude,
		illegalDaedra = soulTrap.illegalDaedra,
		isHarmful = soulTrap.isHarmful,
		nonRecastable = soulTrap.nonRecastable,
		targetsAttributes = soulTrap.targetsAttributes,
		targetsSkills = soulTrap.targetsSkills,
		unreflectable = soulTrap.unreflectable,
		usesNegativeLighting = soulTrap.usesNegativeLighting,
		icon = soulTrap.icon,
		particleTexture = soulTrap.particleTexture,
		castSound = soulTrap.castSoundEffect.id,
		castVFX = soulTrap.castVisualEffect.id,
		boltSound = soulTrap.boltSoundEffect.id,
		boltVFX = soulTrap.boltVisualEffect.id,
		hitSound = soulTrap.hitSoundEffect.id,
		hitVFX = soulTrap.hitVisualEffect.id,
		areaSound = soulTrap.areaSoundEffect.id,
		areaVFX = soulTrap.areaVisualEffect.id,
		lighting = {x = soulTrap.lightingRed, y = soulTrap.lightingGreen, z = soulTrap.lightingBlue},
		size = soulTrap.size,
		sizeCap = soulTrap.sizeCap,
		onTick = nil,
		onCollision = nil
	}
end

---@param eventData spellResistEventData
function npcSoulTrap.onSpellResist(eventData)
	local isSoulTrap = eventData.effect.id == tes3.effect.soultrap
	if isSoulTrap and npcSoulTrap.isValidTarget(eventData.target) then
		-- Soul trap does not work on NPCs, therefore we make it completely ignore the spell existed in the first place by resisting it.
		-- Making NPCs not resist this effect will lead to the VFX of the effect being visible on them forever.
		eventData.resistedPercent = 100

		-- Apply our own npcSoulTrap magic effect instead.
		tes3.applyMagicSource{
			reference = eventData.target,
			source = npcSoulTrap.createDummySoulTrapSpell(eventData.source.name, eventData.effect.duration),
			castChance = 100,
			bypassResistances = false
		}

		-- This is a hack to hide the message box that tells the player that the target has resisted magic.
		-- Just hiding the MenuNotify will not work since it will create gaps inbetween messages.
		-- The logic for placing MenuNotify does not allow hiding of individual message boxes.
		-- This also means that if you cast another effect that the target might resist in the same frame it won't be shown to the player.
		tes3.findGMST(tes3.gmst.sMagicTargetResisted).value = ""
		timer.delayOneFrame(
			function()
				tes3.findGMST(tes3.gmst.sMagicTargetResisted).value = npcSoulTrap.sMagicTargetResisted
			end
		)

		npcSoulTrap.logger:debug(string.format("Replaced soul trap effect on '%s'", eventData.target))
		return false
	end
end

---@param eventData damagedEventData
function npcSoulTrap.onDamaged(eventData)
	if eventData.killingBlow and npcSoulTrap.isValidTarget(eventData.reference) then
		for _, activeMagicEffect in pairs(eventData.mobile.activeMagicEffectList) do
			if activeMagicEffect.effectId == tes3.effect.npcSoulTrap then
				npcSoulTrap.trapSoul(eventData.reference)
				break
			end
		end
	end
end

---@param eventData calcSoulValueEventData
function npcSoulTrap.onCalcSoulValue(eventData)
	if eventData.actor.objectType == tes3.objectType.npc then
		if interop.npcSouls[eventData.actor.id:lower()] then
			eventData.value = interop.npcSouls[eventData.actor.id:lower()]
		else
			eventData.value = 0
			local npcSoulConfig = npcSoulTrap.mod.config.current.npcSoul

			if npcSoulConfig.mode == npcSoulMode.level or npcSoulConfig.mode == npcSoulMode.fixedLevel then
				eventData.value = eventData.actor.level * npcSoulConfig.levelMultiplier
			elseif npcSoulConfig.mode == npcSoulMode.attributes or npcSoulConfig.mode == npcSoulMode.fixedAttributes then
				for _, attribute in pairs(eventData.actor.attributes) do
					eventData.value = eventData.value + attribute
				end
			elseif npcSoulConfig.mode == npcSoulMode.health or npcSoulConfig.mode == npcSoulMode.fixedHealth then
				eventData.value = eventData.actor.health
			end

			if npcSoulConfig.mode == npcSoulMode.fixed or
				npcSoulConfig.mode == npcSoulMode.fixedAttributes or
				npcSoulConfig.mode == npcSoulMode.fixedHealth or
				npcSoulConfig.mode == npcSoulMode.fixedLevel then
				eventData.value = eventData.value + npcSoulConfig.fixedValue
			end

			if npcSoulConfig.multiplier then
				eventData.value = eventData.value * npcSoulConfig.multiplier
			end
		end
	end
end

function npcSoulTrap:onEnabled()
	event.register(tes3.event.calcSoulValue, self.onCalcSoulValue)
	event.register(tes3.event.spellResist, self.onSpellResist)
	event.register(tes3.event.damaged, self.onDamaged)
end

function npcSoulTrap:onDisabled()
	event.unregister(tes3.event.calcSoulValue, self.onCalcSoulValue)
	event.unregister(tes3.event.spellResist, self.onSpellResist)
	event.unregister(tes3.event.damaged, self.onDamaged)
end

function npcSoulTrap:onMorrowindInitialized(eventData)
	self.sMagicTargetResisted = tes3.findGMST(tes3.gmst.sMagicTargetResisted).value
end

function npcSoulTrap:onRun()
	tes3.claimSpellEffectId(self.magicEffectName, self.magicEffectId)
	event.register(tes3.event.magicEffectsResolved, self.onMagicEffectsResolved)
end

return npcSoulTrap