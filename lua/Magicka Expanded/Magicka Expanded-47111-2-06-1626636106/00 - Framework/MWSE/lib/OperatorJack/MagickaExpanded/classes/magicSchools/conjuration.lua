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
		school = tes3.magicSchool.conjuration,

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
		icon = params.icon or "RFD\\RFD_ms_conjuration.tga",
		particleTexture = params.particleTexture or "vfx_conj_flare02.tga",
		castSound = params.castSound or "conjuration cast",
		castVFX = params.castVFX or "VFX_ConjureCast",
		boltSound = params.boltSound or "conjuration bolt",
		boltVFX = params.boltVFX or "VFX_DefaultBolt",
		hitSound = params.hitSound or "conjuration hit",
		hitVFX = params.hitVFX or "VFX_DefaultHit",
		areaSound = params.areaSound or "conjuration area",
		areaVFX = params.areaVFX or "VFX_DefaultArea",
		lighting = params.lighting,
		size = params.size or 1,
		sizeCap = params.sizeCap or 50,

		-- Required callbacks.
        onTick = params.onTick or nil,
        onCollision = params.onCollision or nil
	})

	return effect
end


--[[
	Description: Wrapper for this.createBasicMagicEffect that presets parameters
		common for bound armor effects.

	@params: A table of parameters. Must be formatted as:
		example = {
			id = tes3.effect.exampleArmor,
			name = "Bound Example Armor",
			description = "Gives the caster bound example armor.",
			baseCost = 2,
			armorId = "BoundExampleArmorConstructionSetId",
			icon = "Example\\PathToMyIcon.dds" | nil
		}

		Other parameters will be automatically set by the function.
]]
this.createBasicBoundArmorEffect = function(params)
	local armor = {}
	if (params.armorId) then table.insert(armor, params.armorId) end
	if (params.armorId2) then table.insert(armor, params.armorId2) end
	if (#armor > 0) then common.addBoundArmorToBoundArmorsList(params.id, armor) end

	local effect = this.createBasicEffect({
        -- Use Basic effect function.  Use default for other fields.
        --------------------
		-- Base information.
		id = params.id,
		name = params.name,
		description = params.description,

		-- Basic dials.
        baseCost = params.baseCost,

        -- Various flags.
        allowEnchanting = true,
        allowSpellmaking = true,
        appliesOnce = true,
        canCastSelf = true,
        hasNoMagnitude = true,
		nonRecastable = true,
		casterLinked = true,

		-- Graphics/sounds.
		icon = params.icon or "RFD\\RFD_ms_conjuration.tga",
		particleTexture = params.particleTexture or "vfx_conj_flare02.tga",
        lighting = { 0.99, 0.95, 0.67 },

		-- Required callbacks.
		onTick = function(e)
			e:triggerBoundArmor(params.armorId, params.armorId2)
		end,
	})

	return effect
end

--[[
	Description: Wrapper for this.createBasicMagicEffect that presets parameters
		common for bound weapon effects.

	@params: A table of parameters. Must be formatted as:
		example = {
			id = tes3.effect.exampleWeapon,
			name = "Bound Example Weapon",
			description = "Gives the caster bound example Weapon.",
			baseCost = 2,
			weaponId = "BoundExampleWeaponConstructionSetId",
			icon = "Example\\PathToMyIcon.dds" | nil
		}

		Other parameters will be automatically set by the function.
]]
this.createBasicBoundWeaponEffect = function(params)
	if (params.weaponId) then common.addBoundWeaponToBoundWeaponsList(params.id, { params.weaponId }) end

	local effect = this.createBasicEffect({
        -- Use Basic effect function.  Use default for other fields.
        --------------------
		-- Base information.
		id = params.id,
		name = params.name,
		description = params.description,

		-- Basic dials.
        baseCost = params.baseCost,

        -- Various flags.
        allowEnchanting = true,
        allowSpellmaking = true,
        appliesOnce = true,
        canCastSelf = true,
		hasNoMagnitude = true,
		nonRecastable = true,
		casterLinked = true,

		-- Graphics/sounds.
		icon = params.icon or "RFD\\RFD_ms_conjuration.tga",
		particleTexture = params.particleTexture or "vfx_conj_flare02.tga",
        lighting = { 0.99, 0.95, 0.67 },

		-- Required callbacks.
		onTick = function(e)
			e:triggerBoundWeapon(params.weaponId)
		end,
	})

	return effect
end

--[[
	Description: Wrapper for this.createBasicMagicEffect that presets parameters
		common for summoning effects.

	@params: A table of parameters. Must be formatted as:
		example = {
			id = tes3.effect.exampleSummon,
			name = "Summon Example",
			description = "Summons an example creature infront of the caster.",
			baseCost = 2,
			creatureId = "CreatureConstructionSetId",
			icon = "Example\\PathToMyIcon.dds" | nil
		}

		Other parameters will be automatically set by the function.
]]
this.createBasicSummoningEffect = function(params)
	local effect = this.createBasicEffect({
        -- Use Basic effect function.  Use default for other fields.
        --------------------
		-- Base information.
		id = params.id,
		name = params.name,
		description = params.description,

		-- Basic dials.
        baseCost = params.baseCost,

        -- Various flags.
        allowEnchanting = true,
        allowSpellmaking = true,
        appliesOnce = true,
        canCastSelf = true,
        hasNoMagnitude = true,
		casterLinked = true,

		-- Graphics/sounds.
		icon = params.icon or "RFD\\RFD_ms_conjuration.tga",
		particleTexture = params.particleTexture or "vfx_conj_flare02.tga",
        lighting = { 0.99, 0.95, 0.67 },

		-- Required callbacks.
		onTick = function(e)
            e:triggerSummon(params.creatureId)

			if e.effectInstance.createdData then
				local summon = e.effectInstance.createdData.object
				if summon then
					tes3.setAIFollow{ reference = summon, target = tes3.player }
				end
			end
        end,
	})

	return effect
end

return this