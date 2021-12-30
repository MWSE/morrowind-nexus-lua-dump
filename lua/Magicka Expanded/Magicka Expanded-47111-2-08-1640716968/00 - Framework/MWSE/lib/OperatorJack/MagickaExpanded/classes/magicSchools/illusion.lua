local common = require("OperatorJack.MagickaExpanded.common")
local this = {}

--[[
	Description: Wrapper for tes3.addMagicEffect that has default values
		that are common for spells of this school. Uses the same parameter
		table as tes3.addMagicEffect(). 
]]
this.createBasicEffect = function(params)
	if (common.checkParams(params) == false) then return end
	local effect = tes3.addMagicEffect({
		-- Base information.
		id = params.id,
		name = params.name,
		description = params.description,
		school = tes3.magicSchool.illusion,

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
		hasContinuousVFX =  params.hasContinuousVFX or false,
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
		icon = params.icon or "RFD\\RFD_ms_illusion.tga",
		particleTexture = params.particleTexture or "vfx_grnflare.tga",
		castSound = params.castSound or "illusion cast",
		castVFX = params.castVFX or "VFX_IllusionCast",
		boltSound = params.boltSound or "illusion bolt",
		boltVFX = params.boltVFX or "VFX_IllusionBolt",
		hitSound = params.hitSound or "illusion hit",
		hitVFX = params.hitVFX or "VFX_IllusionHit",
		areaSound = params.areaSound or "illusion area",
		areaVFX = params.areaVFX or "VFX_IllusionArea",
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