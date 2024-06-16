local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")

tes3.claimSpellEffectId("iceBarrage", 324)

local function onIceBarrageCollision(e)
    if e.collision then
        -- Verify effect conditions are met.
        local caster = e.sourceInstance.caster
        if (caster.cell.isInterior == true) then
            if (caster == tes3.mobilePlayer) then
                tes3.messageBox("Заклинание срабатывает, но эффекта в помещении нет.")
            end
            return
        end

        if (tes3.worldController.weatherController.currentWeather.index ~= tes3.weather.blizzard) then
            if (caster == tes3.mobilePlayer) then
                tes3.messageBox("Заклинание срабатывает, но не дает никакого эффекта, если нет метели.")
            end
            return
        end

        ---@type tes3magicEffect
        local effectDuration = 2
        local distanceLimit = 250
        local position = e.collision.point:copy()

        local reference = tes3.createReference({
            object = "OJ_ME_IceBarrageObject",
            position = position,
            cell = caster.cell
        })

        -- Add a mechanic to the Ice Barrage mesh.
        local actors = framework.functions.getActorsNearTargetPosition(caster.cell, position, distanceLimit)
        local spell = tes3.getObject("OJ_ME_IceBarrageEffect")

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

local function addIceBarrageEffect()
	framework.effects.destruction.createBasicEffect({
		-- Base information.
		id = tes3.effect.iceBarrage,
		name = "Ледяной шквал",
		description = "Бросок льдом. Требуется находиться на улице и в метель. Ледяной шквал наносит урон и замораживает пораженные цели.",

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
		onCollision = onIceBarrageCollision,
	})
end

event.register("magicEffectsResolved", addIceBarrageEffect)