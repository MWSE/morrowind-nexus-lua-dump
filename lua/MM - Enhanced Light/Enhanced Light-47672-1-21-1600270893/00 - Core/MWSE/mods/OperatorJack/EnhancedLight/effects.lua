-- Register new Light Effect --
local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")
local functions = include("OperatorJack.EnhancedLight.functions")

tes3.claimSpellEffectId("magelight", 344)

local function onTick(e)
	-- Trigger into the spell system.
	e:trigger()

    local target = e.effectInstance.target
    local isLit = functions.isReferenceLit(target)

    if (isLit == false and e.effectInstance.state ~= tes3.spellState.retired) then
        ---@type tes3magicEffect
        local effect = framework.functions.getEffectFromEffectOnEffectEvent(e, tes3.effect.magelight)
        local magnitude = framework.functions.getCalculatedMagnitudeFromEffect(effect)
        local duration = effect.duration
        local radius = functions.getRadiusFromMagnitude(magnitude)
    
        functions.attachLightToReference(target, radius, duration)
    end

    if (e.effectInstance.state == tes3.spellState.retired) then
        functions.detachLightFromReference(target)
    end
end

local function onCollision(e)
    local target = e.sourceInstance.target
    if e.collision and target == nil then
        ---@type tes3magicEffect
        local effect = framework.functions.getEffectFromEffectOnEffectEvent(e, tes3.effect.magelight)
        local magnitude = framework.functions.getCalculatedMagnitudeFromEffect(effect)
        local duration = effect.duration
        local radius = functions.getRadiusFromMagnitude(magnitude)
        local cell = e.sourceInstance.caster.cell
        functions.attachLightToPoint(e.collision.objectPosAtCollision, cell, radius, duration)
    end
end

local function addEffect()
    local vfx = {
        area = {
            id = "VFX_OJ_EL_LightArea",
            mesh = "OJ\\EL\\LightArea.nif",
        },
        cast = {
            id = "VFX_OJ_EL_LightCast",
            mesh = "OJ\\EL\\LightCast.nif",
        },
        hit = {
            id = "VFX_OJ_EL_LightHit",
            mesh = "OJ\\EL\\LightHit.nif",
        },
    }
    for _, obj in pairs(vfx) do
        local object = tes3.getObject(obj.id)
        if (object == nil) then
            tes3.createObject({
                objectType = tes3.objectType.static,
                id = obj.id,
                mesh = obj.mesh
            })
        end
    end

	framework.effects.illusion.createBasicEffect({
		-- Base information.
		id = tes3.effect.magelight,
		name = "Magelight",
		description = "Creates an orb of light that floats are the target, providing light to the surrounding area.",

		-- Basic dials.
		baseCost = 0.2,

		-- Various flags.
		allowEnchanting = true,
        allowSpellmaking = true,
		canCastTarget = true,
        canCastTouch = true,
        canCastSelf = true,
        nonRecastable = true,

		-- Graphics/sounds.
        lighting = { 1, 1, 1 },
        castVFX = vfx.cast.id,
        hitVFX = vfx.hit.id,
        areaVFX = vfx.area.id,
        particleTexture = "OJ\\EL\\Blank.dds",
        boltVFX = "VFX_OJ_EL_LightBolt",

		castSound = "SND_OJ_EL_Cast",
		boltSound = "SND_OJ_EL_Bolt",
		hitSound = "SND_OJ_EL_Hit",
		areaSound = "SND_OJ_EL_Area",

        -- Required callbacks.
        onTick = onTick,
		onCollision = onCollision,
	})
end

event.register("magicEffectsResolved", addEffect)
-------------------------