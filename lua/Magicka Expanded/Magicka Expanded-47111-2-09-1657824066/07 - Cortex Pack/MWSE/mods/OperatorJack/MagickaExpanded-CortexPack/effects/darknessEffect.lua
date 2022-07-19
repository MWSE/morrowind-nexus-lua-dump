local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")

tes3.claimSpellEffectId("darkness", 263)

local function onDarknessCollision(e)
    if e.collision then
        ---@type tes3magicEffect
        local effect = framework.functions.getEffectFromEffectOnEffectEvent(e, tes3.effect.darkness)

        local caster = e.sourceInstance.caster
        local effectDuration = effect.duration
        local distanceLimit = 250
        local mistPosition = e.collision.point:copy()

        local mistReference = tes3.createReference({
            object = "OJ_ME_DarknessMist",
            position = mistPosition,
            cell = caster.cell
        })

        -- Add a mechanic to the darkness mesh.
        timer.start({ 
            duration = 1,
            callback = function()
                local actors = framework.functions.getActorsNearTargetPosition(caster.cell, mistPosition, distanceLimit)
        
                -- For any actors near the darkness, remove the light effect if it exists.
                for _, actor in pairs(actors) do
                    tes3.removeEffects({
                        reference = actor,
                        effect = tes3.effect.light
                    })
                end
            end, 
            iterations = (effectDuration - 1) 
        })

        timer.start(
        {
            duration = effectDuration,
            callback = function()
                --@type tes3reference
                mistReference:disable()

                timer.delayOneFrame({
                    callback = function()
                        mistReference.deleted = true
                    end
                })
            end
        })
	end
end

-- Written by NullCascade.
local function addDarknessEffect()
	framework.effects.illusion.createBasicEffect({
		-- Base information.
		id = tes3.effect.darkness,
		name = "Darkness",
		description = "Create a sphere of darkness around the target, negating any light effects within.",

		-- Basic dials.
		baseCost = 3.0,

		-- Various flags.
		allowEnchanting = true,
        allowSpellmaking = true,
        hasNoMagnitude = true,
		canCastTarget = true,
        canCastTouch = true,
        unreflectable = true,
        usesNegativeLighting = true,

		-- Graphics/sounds.
		icon = "RFD\\RFD_lf_darkness.dds",
		lighting = { 0, 0, 0 },

		-- Required callbacks.
		onCollision = onDarknessCollision,
	})
end

event.register("magicEffectsResolved", addDarknessEffect)