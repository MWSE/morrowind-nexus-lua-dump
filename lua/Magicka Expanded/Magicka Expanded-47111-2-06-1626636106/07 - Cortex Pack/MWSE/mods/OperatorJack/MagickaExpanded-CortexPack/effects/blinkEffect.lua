local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")

tes3.claimSpellEffectId("blink", 325)

local blinkEffect

local function onBlinkCollision(e)
	if e.collision then
		local canTeleport = not tes3.worldController.flagTeleportingDisabled
		if canTeleport then
			local caster = e.sourceInstance.caster
			tes3.positionCell({ reference = caster, position = e.collision.point, cell = caster.cell })

			-- Play a fancy VFX.
			e.sourceInstance:playVisualEffect({
				reference = caster,
				position = caster.position,
				visual = blinkEffect.hitVisualEffect,
				effectIndex = e.sourceInstance.source:getFirstIndexOfEffect(tes3.effect.blink),
			})
		else
			tes3.messageBox("You are not able to cast that spell here.")
		end
	end
end

local function addBlinkMagicEffect()
	blinkEffect = framework.effects.mysticism.createBasicEffect({
		-- Base information.
		id = tes3.effect.blink,
		name = "Blink",
		description = "Teleports the caster towards the location they cast at.",

		-- Basic dials.
		baseCost = 100.0,
		speed = 2.0,

		-- Flags
		allowEnchanting = true,
		appliesOnce = true,
		canCastTarget = true,
		hasNoDuration = true,
		hasNoMagnitude = true,

		-- Graphics / sounds.
		icon = "RFD\\RFD_tp_blink.dds",
		particleTexture = "vfx_particle064.tga",
		lighting = { 206 / 255, 237 / 255, 255 / 255 },

		-- Callbacks
		onCollision = onBlinkCollision
	})
end

event.register("magicEffectsResolved", addBlinkMagicEffect)