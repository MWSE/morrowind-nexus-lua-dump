local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")

tes3.claimSpellEffectId("disarmTarget", 25000)

local function onDisarmCollision(e)
    -- When the spell collides
    if e.collision then
        local target = tes3.getPlayerTarget()
        
        if not target then  -- Check if there's a target
            tes3.playSound({sound = "Disarm Trap Fail"})
            return
        end

        local targetObject = target.object
        local targetType = targetObject.objectType

        -- Ensure the target is a container or a door
        if targetType == tes3.objectType.container or targetType == tes3.objectType.door then
            local lockNode = target.lockNode

            -- Check if the target has a trap
            if lockNode and lockNode.trap then
                -- Disarm the trap
                lockNode.trap = nil

                tes3.playSound({sound = "Disarm Trap"})
                tes3.messageBox("Trap disarmed.")
            else
                tes3.messageBox("This item isn't trapped.")
                tes3.playSound({sound = "Disarm Trap Fail"})
            end
        else
            tes3.messageBox("This can't be disarmed.")
            tes3.playSound({sound = "Disarm Trap Fail"})
        end
    end
end

-- Register the collision event
event.register("spellCollision", onDisarmCollision)

local function addDisarmEffect()
	disarmTarget = framework.effects.alteration.createBasicEffect({
		-- Base information.
		id = tes3.effect.disarmTarget,
		name = "Disarm Target",
		description = "Disarms trapped doors and container",

		-- Basic dials.
		baseCost = 5.0,
		speed = 3.0,

		-- Flags
        allowSpellmaking = true,
		appliesOnce = true,
		canCastTarget = true,
		hasNoDuration = true,
		canCastSelf = false,
        canCastTouch = true,

		-- Graphics / sounds.
		icon = "disarm\\DisarmIcon.dds",
		particleTexture = "vfx_ill_glow.tga",
		lighting = { 106 / 255, 63 / 255, 120 / 255 },

		-- Callbacks
		onCollision = onDisarmCollision
	})
end

event.register("magicEffectsResolved", addDisarmEffect)