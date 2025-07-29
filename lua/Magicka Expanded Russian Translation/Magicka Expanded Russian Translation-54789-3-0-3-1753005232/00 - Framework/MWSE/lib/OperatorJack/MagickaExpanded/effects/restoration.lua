local common = require("OperatorJack.MagickaExpanded.common")

---@class MagickaExpanded.Effects.Restoration
local this = {}

--[[
	Wrapper for tes3.addMagicEffect that has default values
		that are common for spells of this school. Uses the same parameter
		table as tes3.addMagicEffect(). 
]]
---@param params MagickaExpanded.Effects.BasicEffectParams
---@return tes3magicEffect | nil
this.createBasicEffect = function(params)
    if (common.checkParams(params) == false) then return end
    local effect = tes3.addMagicEffect({
        -- Base information.
        id = params.id,
        name = params.name,
        description = params.description,
        school = tes3.magicSchool.restoration,

        -- Basic dials.
        baseCost = params.baseCost,
        speed = params.speed or 1,

        -- Various flags.
        allowEnchanting = params.allowEnchanting or false,
        allowSpellmaking = params.allowSpellmaking or false,
        appliesOnce = params.appliesOnce or false,
        canCastSelf = params.canCastSelf or false,
        canCastTarget = params.canCastTarget or false,
        canCastTouch = params.canCastTouch or false,
        casterLinked = params.casterLinked or false,
        hasContinuousVFX = params.hasContinuousVFX or false,
        hasNoDuration = params.hasNoDuration or false,
        hasNoMagnitude = params.hasNoMagnitude or false,
        illegalDaedra = params.illegalDaedra or false,
        isHarmful = params.isHarmful or false,
        nonRecastable = params.nonRecastable or false,
        targetsAttributes = params.targetsAttributes or false,
        targetsSkills = params.targetsSkills or false,
        unreflectable = params.unreflectable or false,
        usesNegativeLighting = params.usesNegativeLighting or false,

        -- Graphics/sounds.
        icon = params.icon or "RFD\\RFD_ms_restoration.tga",
        particleTexture = params.particleTexture or "vfx_bluecloud.tga",
        castSound = params.castSound or "restoration cast",
        castVFX = params.castVFX or "VFX_RestorationCast",
        boltSound = params.boltSound or "restoration bolt",
        boltVFX = params.boltVFX or "VFX_RestoreBolt",
        hitSound = params.hitSound or "restoration hit",
        hitVFX = params.hitVFX or "VFX_RestorationHit",
        areaSound = params.areaSound or "restoration area",
        areaVFX = params.areaVFX or "VFX_RestorationArea",
        lighting = params.lighting,
        size = params.size or 1,
        sizeCap = params.sizeCap or 50,

        -- Required callbacks.
        onTick = params.onTick or nil,
        onCollision = params.onCollision or nil
    })

    return effect
end

return this
