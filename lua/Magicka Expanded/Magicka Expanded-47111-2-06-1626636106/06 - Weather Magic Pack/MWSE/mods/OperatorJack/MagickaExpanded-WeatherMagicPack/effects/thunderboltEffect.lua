local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")

tes3.claimSpellEffectId("thunderbolt", 323)

local function onThunderboltCollision(e)
    if e.collision then
        -- Verify effect conditions are met.
        local caster = e.sourceInstance.caster
        if (caster.cell.isInterior == true) then
            if (caster == tes3.player) then
                tes3.messageBox("The spell succeeds, but there is no effect indoors.")
            end
            return
        end

        if (tes3.worldController.weatherController.currentWeather.index ~= tes3.weather.thunder) then
            if (caster == tes3.player) then
                tes3.messageBox("The spell succeeds, but there is no effect when not in a thunderstorm.")
            end
            return
        end

        ---@type tes3magicEffect
        local effectDuration = 2
        local distanceLimit = 250
        local position = e.collision.point:copy()

        local reference = tes3.createReference({
            object = "OJ_ME_ThunderboltObject",
            position = position,
            cell = caster.cell
        })

        -- Add a mechanic to the thunderbolt mesh.
        local actors = framework.functions.getActorsNearTargetPosition(caster.cell, position, distanceLimit)
        local spell = tes3.getObject("OJ_ME_ThunderBoltEffect")

        mwscript.explodeSpell({
            reference = reference,
            spell = spell
        })

        for _, actor in pairs(actors) do
            local isCasterNewlyHostile = false
            if (actor.hostileActors == nil) then
                isCasterNewlyHostile = true
            else
                -- !!!! Not finished. Should not report true.
                local isCasterInHostileActors = false
                for _, hostileActor in pairs(actor.hostileActors) do
                    if (caster == hostileActor) then
                        isCasterInHostileActors = true
                    end
                end

                if (isCasterInHostileActors == true) then
                    isCasterNewlyHostile = false
                else
                    isCasterNewlyHostile = true
                end
            end

            if (isCasterNewlyHostile == true) then
                if(caster == tes3.player) then
                    tes3.triggerCrime({
                        criminal = caster,
                        type = tes3.crimeType.attack,
                        victim = actor
                    })
                end

                mwscript.startCombat({
                    reference = actor,
                    target = caster
                })
            end
        end

        timer.start(
        {
            duration = effectDuration,
            callback = function()
                --@type tes3reference
                reference:disable()

                timer.delayOneFrame({
                    callback = function()
                        reference.deleted = true
                    end
                })
            end
        })
	end
end

local function addThunderboltEffect()
	framework.effects.destruction.createBasicEffect({
		-- Base information.
		id = tes3.effect.thunderbolt,
		name = "Thunderbolt",
		description = "Cast a thunderbolt down from above. Requires being outside and being in a thunderstorm. Thunderbolts will damage and stun affected targets.",

		-- Basic dials.
		baseCost = 25.0,

		-- Various flags.
		allowEnchanting = true,
        allowSpellmaking = true,
        hasNoMagnitude = true,
        hasNoDuration = true,
		canCastTarget = true,

        -- Graphics/sounds.

		-- Required callbacks.
		onCollision = onThunderboltCollision,
	})
end

event.register("magicEffectsResolved", addThunderboltEffect)