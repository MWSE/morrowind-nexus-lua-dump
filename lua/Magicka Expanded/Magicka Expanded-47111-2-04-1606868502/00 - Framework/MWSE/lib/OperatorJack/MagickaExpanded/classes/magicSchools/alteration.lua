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
		school = tes3.magicSchool.alteration,

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
		icon = params.icon or "RFD\\RFD_ms_alteration.tga",
		particleTexture = params.particleTexture or "vfx_alt_glow.tga",
		castSound = params.castSound or "alteration cast",
		castVFX = params.castVFX or "VFX_AlterationCast",
		boltSound = params.boltSound or "alteration bolt",
		boltVFX = params.boltVFX or "VFX_AlterationBolt",
		hitSound = params.hitSound or "alteration hit",
		hitVFX = params.hitVFX or "VFX_AlterationHit",
		areaSound = params.areaSound or "alteration area",
		areaVFX = params.areaVFX or "VFX_AlterationArea",
		lighting = params.lighting,
		size = params.size or 1,
		sizeCap = params.sizeCap or 50,

		-- Required callbacks.
        onTick = params.onTick or nil,
        onCollision = params.onCollision or nil
	})

	return effect
end

this.createBasicWeatherEffect = function(params)
	local effect = this.createBasicEffect({
		-- Base information.
		id = params.id,
		name = params.name,
		description = params.description,

		-- Basic dials.
		baseCost = params.baseCost,
		speed = .25,

		-- Various flags.
		appliesOnce = true,
		canCastSelf = true,
		hasNoDuration = true,
		hasNoMagnitude = true,
		nonRecastable = true,

		-- Graphics/sounds.
		icon = params.icon or "RFD\\RFD_ms_alteration.tga",
		lighting = { 0.99, 0.95, 0.67 },

		-- Required callbacks.
		onTick = function(e)	
			-- Trigger into the spell system.
			if (not e:trigger()) then
				return
			end
			
			local caster = e.sourceInstance.caster
			if (caster.cell.isInterior == true) then
				if (caster == tes3.player) then
					tes3.messageBox("The spell succeeds, but there is no effect indoors.")
				end
				e.effectInstance.state = tes3.spellState.retired
				return
			end

			if (tes3.worldController.weatherController.currentWeather.index == tes3.weather.blight) then
				if (caster == tes3.player) then
					tes3.messageBox("The spell completes, but it is unable to dispel the current Blight.")
				end
				e.effectInstance.state = tes3.spellState.retired
				return
			end

			tes3.worldController.weatherController:switchImmediate(params.weather)
			tes3.worldController.weatherController:updateVisuals()

			e.effectInstance.state = tes3.spellState.retired
		end,
	}) 

	return effect
end

return this