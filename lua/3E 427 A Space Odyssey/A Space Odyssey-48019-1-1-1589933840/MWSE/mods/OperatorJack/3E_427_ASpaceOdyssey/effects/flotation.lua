local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")

tes3.claimSpellEffectId("float", 424)

local function onTick(e)
	if (e.effectInstance.state == tes3.spellState.beginning) then
		e.effectInstance.target.position = e.effectInstance.target.position + tes3vector3.new(0, 0, 64)  
	end

	-- Trigger into the spell system.
	if (e:trigger()) then
		local magnitude = e.effectInstance.magnitude
		local encumbrance = e.effectInstance.target.mobile.encumbrance.current
		local modifier = math.ceil((magnitude * 10) - (encumbrance / 5))
		e.effectInstance.target.mobile.velocity = tes3vector3.new(0, 0, modifier)
	end
end

local function addFloatEffect()
	framework.effects.alteration.createBasicEffect({
		-- Base information.
		id = tes3.effect.float,
		name = "Float",
		description = "Causes the target to float upwards in the air. The magnitude of the effect and the weight of the target determines the velocity of the flotation.",

		-- Basic dials.
		baseCost = 1.25,

		-- Various flags.
		allowEnchanting = true,
		allowSpellmaking = true,
		canCastTarget = true,
		canCastTouch = true,
		canCastSelf = true,
		hasContinuousVFX = true,
		casterLinked = true,

		-- Graphics/sounds.
		icon = "RFD\\ME_Float.dds",
		lighting = { 0.99, 0.95, 0.67 },

		-- Required callbacks.
		onTick = onTick,
	})
end

event.register("magicEffectsResolved", addFloatEffect)