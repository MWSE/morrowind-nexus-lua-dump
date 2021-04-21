local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")
local common = require("TeamVoluptuousVelks.DeeperDagothUr.common")

tes3.claimSpellEffectId("dispelLevitate", 400)
tes3.claimSpellEffectId("dispelLevitateJavelin", 401)

-- Dispel Levitation - Javelin Effect --
local function getEquipmentWithEnchantmentEffect(effectId)
	local equippedItems = {}
	for _, stack in pairs(tes3.player.object.equipment) do
		mwse.log(stack.object)
		mwse.log(stack.object.enchantment)
		if (stack.object.enchantment ~= nil) then
			common.debug("Dispel Levitation: Found an enchanted item.")
			for _, effect in pairs(stack.object.enchantment.effects) do
				if (effect.id == effectId) then
					common.debug("Dispel Levitation: Found an enchanted item of effect ID.")
					table.insert(equippedItems, stack)
				end
			end
		end
	end
	return equippedItems
end


local function onDispelLevitateJavelinTick(e)
	-- Trigger into the spell system.
	if (not e:trigger()) then
		return
	end

	-- Check if player has levitation active.
    local mobilePlayer = tes3.mobilePlayer
	local isLevitationActive = tes3.isAffectedBy({
		reference = mobilePlayer,
		effect = tes3.effect.levitate
	})

	if (isLevitationActive == true) then
		local equippedItems = getEquipmentWithEnchantmentEffect(tes3.effect.levitate)
		if (equippedItems ~= nil) then
			common.debug("Dispel Levitation: Iterating enchanted items.")
			for _, equippedItem in pairs(equippedItems) do
				if (equippedItem.object.enchantment.castType == tes3.enchantmentType.constant) then
					common.debug("Dispel Levitation: Constant Effect.")
					if (common.shouldPerformRandomEvent(40) == true ) then
						equippedItem.object.enchantment = nil
						tes3.messageBox("As the projectile strikes you, your levitation enchantment gives out.")
					else
						tes3.messageBox("As the projectile strikes you, your levitation enchantment falters.")
					end
				else
					common.debug("Dispel Levitation: Non Constant Effect.")
					equippedItem.variables.charge = 0
					tes3.messageBox("As the projectile strikes you, your levitation enchantment is drained.")
				end
			end
		end

		-- Remove any levitation effects.
		tes3.removeEffects({
			reference = e.effectInstance.target,
			effect = tes3.effect.levitate
		})
	end

    e.effectInstance.state = tes3.spellState.retired
end

local function addDispelLevitateJavelinEffect()
	framework.effects.mysticism.createBasicEffect({
		-- Base information.
		id = tes3.effect.dispelLevitateJavelin,
		name = "Dispel Levitate - Javelin",
		description = "Removes any active levitation effects from the target.",

		-- Basic dials.
		baseCost = 3.0,

		-- Various flags.
		allowEnchanting = false,
        allowSpellmaking = false,
        hasNoMagnitude = true,
        hasNoDuration = true,
		canCastTarget = true,
        canCastTouch = false,
        canCastSelf = false,
        nonRecastable = false,

		-- Graphics/sounds.
        lighting = { 0, 0, 0 },
        boltVFX = "DDU_VFX_javelinBolt",

		-- Required callbacks.
		onTick = onDispelLevitateJavelinTick,
	})
end

-- Dispel Levitation Effect --
local function onDispelLevitateTick(e)
	-- Trigger into the spell system.
	if (not e:trigger()) then
		return
	end

	-- Remove any levitation effects.
	tes3.removeEffects({
        reference = e.effectInstance.target,
        effect = tes3.effect.levitate
    })

    e.effectInstance.state = tes3.spellState.retired
end

local function addDispelLevitateEffect()
	framework.effects.mysticism.createBasicEffect({
		-- Base information.
		id = tes3.effect.dispelLevitate,
		name = "Dispel Levitate",
		description = "Removes any active levitation effects from the target.",

		-- Basic dials.
		baseCost = 3.0,

		-- Various flags.
		allowEnchanting = true,
        allowSpellmaking = true,
        hasNoMagnitude = true,
        hasNoDuration = true,
		canCastTarget = true,
        canCastTouch = true,
        canCastSelf = true,
        nonRecastable = false,

		-- Graphics/sounds.
        lighting = { 0, 0, 0 },

		-- Required callbacks.
		onTick = onDispelLevitateTick,
	})
end
-------------------------------------------------
event.register("magicEffectsResolved", addDispelLevitateEffect)
event.register("magicEffectsResolved", addDispelLevitateJavelinEffect)