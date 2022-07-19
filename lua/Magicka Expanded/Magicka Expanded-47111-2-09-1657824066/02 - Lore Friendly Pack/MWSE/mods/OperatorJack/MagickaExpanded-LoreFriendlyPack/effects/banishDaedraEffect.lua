local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")

tes3.claimSpellEffectId("banishDaedra", 220)

-- Written by NullCascade.
local function onBanishDaedraTick(e)
	-- Trigger into the spell system.
	if (not e:trigger()) then
		return
	end

	-- Ignore any non-daedric opponents.
	if (e.effectInstance.target.object.type ~= tes3.creatureType.daedra) then
		e.effectInstance.state = tes3.spellState.retired
		return
	end

	local effect = framework.functions.getEffectFromEffectOnEffectEvent(e, tes3.effect.banishDaedra)
	local magnitude = framework.functions.getCalculatedMagnitudeFromEffect(effect)

	if (e.effectInstance.target.object.level <= magnitude) then
		--@type tes3reference
		e.effectInstance.target:disable()

		timer.delayOneFrame({
			callback = function()
				e.effectInstance.target.deleted = true
			end
		})

		tes3.messageBox("%s has been banished!", e.effectInstance.target.baseObject.name)
	else
		tes3.messageBox("%s was too powerful to be banished!", e.effectInstance.target.baseObject.name)
	end

	e.effectInstance.state = tes3.spellState.retired
end

-- Written by NullCascade.
local function addBanishDaedraEffect()
	framework.effects.conjuration.createBasicEffect({
		-- Base information.
		id = tes3.effect.banishDaedra,
		name = "Banish Daedra",
		description = "Banishes a daedric creature back to its originating plane. The effect's magnitude is the level of daedra that it can banish.",

		-- Basic dials.
		baseCost = 25.0,

		-- Various flags.
		allowEnchanting = true,
		allowSpellmaking = true,
		appliesOnce = true,
		canCastTarget = true,
		canCastTouch = true,
		hasNoDuration = true,
		nonRecastable = true,
		unreflectable = true,

		-- Graphics/sounds.
		icon = "RFD\\RFD_lf_banish.dds",
		particleTexture = "vfx_myst_flare01.tga",
		lighting = { 0.99, 0.95, 0.67 },

		-- Required callbacks.
		onTick = onBanishDaedraTick,
	})
end

event.register("magicEffectsResolved", addBanishDaedraEffect)