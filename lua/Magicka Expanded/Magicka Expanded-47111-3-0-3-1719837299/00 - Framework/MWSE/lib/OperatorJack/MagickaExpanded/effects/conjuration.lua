local common = require("OperatorJack.MagickaExpanded.common")

---@class MagickaExpanded.Effects.Conjuration
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

---@class MagickaExpanded.Effects.Conjuration.BoundArmorEffectParams: MagickaExpanded.Effects.BasicEffectParams
---@field armorId string
---@field armorId2 string?

--[[
	Wrapper for this.createBasicMagicEffect that presets parameters
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
---@param params MagickaExpanded.Effects.Conjuration.BoundArmorEffectParams
---@return tes3magicEffect | nil
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
        lighting = {0.99, 0.95, 0.67},

        -- Required callbacks.
        onTick = function(e) e:triggerBoundArmor(params.armorId, params.armorId2) end
    })

    return effect
end

---@class MagickaExpanded.Effects.Conjuration.BoundWeaponEffectParams: MagickaExpanded.Effects.BasicEffectParams
---@field weaponId string

--[[
	Wrapper for this.createBasicMagicEffect that presets parameters
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
---@param params MagickaExpanded.Effects.Conjuration.BoundWeaponEffectParams
---@return tes3magicEffect | nil
this.createBasicBoundWeaponEffect = function(params)
    if (params.weaponId) then
        common.addBoundWeaponToBoundWeaponsList(params.id, {params.weaponId})
    end

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
        lighting = {0.99, 0.95, 0.67},

        -- Required callbacks.
        onTick = function(e) e:triggerBoundWeapon(params.weaponId) end
    })

    return effect
end

---@class MagickaExpanded.Effects.Conjuration.SummoningEffectParams: MagickaExpanded.Effects.BasicEffectParams
---@field creatureId string

--[[
	Wrapper for this.createBasicMagicEffect that presets parameters
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
---@param params MagickaExpanded.Effects.Conjuration.SummoningEffectParams
---@return tes3magicEffect | nil
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
        lighting = {0.99, 0.95, 0.67},

        -- Required callbacks.
        onTick = function(e) e:triggerSummon(params.creatureId) end
    })

    return effect
end

---@class MagickaExpanded.Effects.Conjuration.WeatherEffectParams: MagickaExpanded.Effects.BasicEffectParams
---@field weather tes3.weather

---@param params MagickaExpanded.Effects.Conjuration.WeatherEffectParams
---@return tes3magicEffect | nil
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
        icon = params.icon or "RFD\\RFD_ms_conjuration.tga",
        lighting = {0.99, 0.95, 0.67},

        -- Required callbacks.
        onTick = function(e)
            -- Trigger into the spell system.
            if (not e:trigger()) then return end

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
                    tes3.messageBox(
                        "The spell completes, but it is unable to dispel the current Blight.")
                end
                e.effectInstance.state = tes3.spellState.retired
                return
            end

            tes3.worldController.weatherController:switchImmediate(params.weather)
            tes3.worldController.weatherController:updateVisuals()

            e.effectInstance.state = tes3.spellState.retired
        end
    })

    return effect
end

return this
