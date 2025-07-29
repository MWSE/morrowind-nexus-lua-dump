local common = require("OperatorJack.MagickaExpanded.common")

---@class MagickaExpanded.Effects.Mysticisim
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
        school = tes3.magicSchool.mysticism,

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
        icon = params.icon or "RFD\\RFD_ms_mysticism.tga",
        particleTexture = params.particleTexture or "vfx_myst_flare01.tga",
        castSound = params.castSound or "mysticism cast",
        castVFX = params.castVFX or "VFX_MysticismCast",
        boltSound = params.boltSound or "mysticism bolt",
        boltVFX = params.boltVFX or "VFX_MysticismBolt",
        hitSound = params.hitSound or "mysticism hit",
        hitVFX = params.hitVFX or "VFX_MysticismHit",
        areaSound = params.areaSound or "mysticism area",
        areaVFX = params.areaVFX or "VFX_MysticismArea",
        lighting = params.lighting,
        size = params.size or 1,
        sizeCap = params.sizeCap or 50,

        -- Required callbacks.
        onTick = params.onTick or nil,
        onCollision = params.onCollision or nil
    })

    return effect
end

---@class MagickaExpanded.Effects.Mysticisim.PositionCellParams.VectorParams
---@field x number
---@field y number
---@field z number

---@class MagickaExpanded.Effects.Mysticisim.PositionCellParams
---@field cell tes3cell|string
--[[
    Orientation in degrees. Degrees are automatically converted to radians.
]]
---@field orientation MagickaExpanded.Effects.Mysticisim.PositionCellParams.VectorParams | tes3vector3
--[[
    Position in numbers.
]]
---@field position MagickaExpanded.Effects.Mysticisim.PositionCellParams.VectorParams | tes3vector3

---@class MagickaExpanded.Effects.Mysticisim.TeleportationEffectParams: MagickaExpanded.Effects.BasicEffectParams
---@field positionCell MagickaExpanded.Effects.Mysticisim.PositionCellParams

--[[
	Wrapper for this.createBasicMagicEffect that presets parameters
		common for teleportation effects.

	@params: A table of parameters. Must be formatted as:
		example = {
			id = tes3.effect.exampleTeleport,
			name = "Teleport To Example",
			description = "Teleports the caster to Example.",
			baseCost = 150,
			positionCell = {
				position = tes3vector3.new( 106925, 117169, 264),
				orientation = tes3vector3.new( 0, 0, 34),
				cell = "Example"
			}
		}

		Other parameters will be automatically set by the function.
]]
---@param params MagickaExpanded.Effects.Mysticisim.TeleportationEffectParams
---@return tes3magicEffect | nil
this.createBasicTeleportationEffect = function(params)
    local effect = this.createBasicEffect({
        -- Base information.
        id = params.id,
        name = params.name,
        description = params.description,

        -- Basic dials.
        baseCost = params.baseCost,

        -- Various flags.
        appliesOnce = true,
        canCastSelf = true,
        hasNoDuration = true,
        hasNoMagnitude = true,
        nonRecastable = true,

        -- Graphics/sounds.
        icon = params.icon or "RFD\\RFD_teleport.dds",
        lighting = {0.99, 0.95, 0.67},

        -- Required callbacks.
        onTick = function(e)
            -- Trigger into the spell system.
            if (not e:trigger()) then return end

            local position = tes3vector3.new(params.positionCell.position.x,
                                             params.positionCell.position.y,
                                             params.positionCell.position.z)

            local orientation = tes3vector3.new(math.rad(params.positionCell.orientation.x),
                                                math.rad(params.positionCell.orientation.y),
                                                math.rad(params.positionCell.orientation.z))

            -- Teleport the caster.
            local teleportParams = {
                reference = e.sourceInstance.caster,
                position = position,
                orientation = orientation,
                cell = params.positionCell.cell
            }
            tes3.positionCell(teleportParams)

            e.effectInstance.state = tes3.spellState.retired
        end
    })

    return effect
end

return this
