local effectMaker = {}

-- local logger = require("logging.logger")
local log = require("logging.logger").new { name = "bsEffects", logLevel = "INFO", logToConsole = true, }

local schools = {
    [0] = { -- Alteration
        autoIcon = "s\\Tx_s_burden.dds",
        areaSound = "alteration area",
        areaVFX = "VFX_AlterationArea",
        boltSound = "alteration bolt",
        boltVFX = "VFX_AlterationBolt",
        castSound = "alteration cast",
        castVFX = "VFX_AlterationCast",
        hitSound = "alteration hit",
        hitVFX = "VFX_AlterationHit",
        particleTexture = "vfx_alt_glow.tga"
    },
    [1] = { -- Conjuration
        autoIcon = "s\\tx_s_turn_undead.dds",
        areaSound = "conjuration area",
        areaVFX = "VFX_DefaultArea",
        boltSound = "conjuration bolt",
        boltVFX = "VFX_DefaultBolt",
        castSound = "conjuration cast",
        castVFX = "VFX_ConjureCast",
        hitSound = "conjuration hit",
        hitVFX = "VFX_DefaultHit",
        particleTexture = "vfx_conj_flare02.tga"
    },
    [2] = { -- Destruction
        autoIcon = "s\\Tx_s_dmg_fati.tga",
        areaSound = "destruction area",
        areaVFX = "VFX_DestructArea",
        boltSound = "destruction bolt",
        boltVFX = "VFX_DestructBolt",
        castSound = "destruction cast",
        castVFX = "VFX_DestructCast",
        hitSound = "destruction hit",
        hitVFX = "VFX_DestructHit",
        particleTexture = "vfx_alpha_bolt01.tga"
    },
    [3] = { -- Illusion
        autoIcon = "s\\tx_s_cm_crture.dds",
        areaSound = "illusion area",
        areaVFX = "VFX_IllusionArea",
        boltSound = "illusion bolt",
        boltVFX = "VFX_IllusionBolt",
        castSound = "illusion cast",
        castVFX = "VFX_IllusionCast",
        hitSound = "illusion hit",
        hitVFX = "VFX_IllusionHit",
        particleTexture = "vfx_grnflare.tga"
    },
    [4] = { -- Mysticism
        autoIcon = "s\\tx_s_alm_intervt.dds",
        areaSound = "mysticism area",
        areaVFX = "VFX_MysticismArea",
        boltSound = "mysticism bolt",
        boltVFX = "VFX_MysticismBolt",
        castSound = "mysticism cast",
        castVFX = "VFX_MysticismCast",
        hitSound = "mysticism hit",
        hitVFX = "VFX_MysticismHit",
        particleTexture = "vfx_bluecloud.tga"
    },
    [5] = { -- Restoration
        autoIcon = "s\\Tx_S_ftfy_skill.tga",
        areaSound = "restoration area",
        areaVFX = "VFX_RestorationArea",
        boltSound = "restoration bolt",
        boltVFX = "VFX_RestoreBolt",
        castSound = "restoration cast",
        castVFX = "VFX_RestorationCast",
        hitSound = "restoration hit",
        hitVFX = "VFX_RestorationHit",
        particleTexture = "vfx_myst_flare01.tga"
    }
}

------------------------------------------------------------------------------------------------------------------------------
--- @class EffectParams
--- @field id integer The unique identifier for the magic effect. (tes3.effect.light)
--- @field name string The name of the magic effect.
--- @field baseCost number? Default: 1 : The base cost of the magic effect.
--- @field school tes3.magicSchool The school of magic the effect belongs to.
--- @field icon string? Optional. The path to the icon representing the effect.
--- @field areaSound string? Default: Will Use placeholder fx for school : The sound played for area effects.
--- @field areaVFX string? Default: Will Use placeholder fx for school : The visual effects played for area effects.
--- @field boltSound string? Default: Will Use placeholder fx for school : The sound played when the effect is used in a bolt.
--- @field boltVFX string? Default: Will Use placeholder fx for school : The visual effects played when the effect is used in a bolt.
--- @field castSound string? Default: Will Use placeholder fx for school : The sound played when the effect is cast.
--- @field castVFX string? Default: Will Use placeholder fx for school : The visual effects played when the effect is cast.
--- @field hitSound string? Default: Will Use placeholder fx for school : The sound played when the effect hits a target.
--- @field hitVFX string? Default: Will Use placeholder fx for school : The visual effects played when the effect hits a target.
--- @field particleTexture string? Default: Will Use placeholder fx for school : The texture of the particles used in the effect.
--- @field description string? Optional. A description of the effect.
--- @field size number? Default: 1 : The size parameter of the effect.
--- @field sizeCap number? Default: 1 : The maximum size of the effect.
--- @field speed number? Default: 1 : The speed at which the effect travels.
--- @field lighting table? Optional. Example { x = 0.99, y = 0.26, z = 0.53 }. Lighting effects associated with the magic effect.
--- @field usesNegativeLighting boolean? Whether the effect uses negative lighting.
--- @field hasContinuousVFX boolean? Default: true : Whether the effect has continuous visual effects.
--- @field allowEnchanting boolean? Default: true : Whether the effect can be used in enchanting.
--- @field allowSpellmaking boolean? Default: true : Whether the effect can be used in spellmaking.
--- @field appliesOnce boolean? Default: false: Whether the effect applies once or continuously.
--- @field canCastSelf boolean? Default: true: Whether the effect can be cast on self.
--- @field canCastTarget boolean? Default: true: Whether the effect can be cast on a target.
--- @field canCastTouch boolean? Default: true : Whether the effect can be cast by touch.
--- @field casterLinked boolean? Default: true : Whether the effect is linked to the caster.
--- @field hasNoDuration boolean? Default: false : Whether the effect has no duration.
--- @field hasNoMagnitude boolean? Default: false : Whether the effect has no magnitude.
--- @field illegalDaedra boolean? Default: false : Whether the effect is illegal for Daedra.
--- @field isHarmful boolean? Default: false : Whether the effect is considered harmful.
--- @field nonRecastable boolean? Whether the effect is non-recastable.
--- @field targetsAttributes boolean? Whether the effect targets attributes.
--- @field targetsSkills boolean? Whether the effect targets skills.
--- @field unreflectable boolean? Whether the effect is unreflectable.
--- @field onTick nil|fun(e: tes3magicEffectTickEventData)
--- @field onCollision nil|(fun(e: tes3magicEffectCollisionEventData))?: Optional. The function called when the effect collides.
--- @param params EffectParams The configuration table for the new magic effect.
function effectMaker.create(params)
    --Default name if not supplied. (dont remember why i needed this, something wasnt working right)
    params.name = params.name or "Error: Unnamed Effect"
    log:info("%s effect created with ID of %s", params.name, params.id)

    -- Set school variable to either the entered school or a default if something goes wrong.
    local school = params.school or tes3.magicSchool["alteration"]

    local autoSchool = schools[school] or schools[0]

    local effect = tes3.addMagicEffect({
        id = params.id,
        name = params.name,
        baseCost = params.baseCost or 5,
        school = params.school,

        areaSound = params.areaSound or autoSchool.areaSound,
        areaVFX = params.areaVFX or autoSchool.areaVFX,
        boltSound = params.boltSound or autoSchool.boltSound,
        boltVFX = params.boltVFX or autoSchool.boltVFX,
        castSound = params.castSound or autoSchool.castSound,
        castVFX = params.castVFX or autoSchool.castVFX,
        description = params.description,
        hasContinuousVFX = params.hasContinuousVFX or false,
        hitSound = params.hitSound or autoSchool.hitSound,
        hitVFX = params.hitVFX or autoSchool.hitVFX,
        icon = params.icon or autoSchool.autoIcon or "default icon.tga",
        lighting = params.lighting,
        particleTexture = params.particleTexture or autoSchool.particleTexture,
        size = params.size or 1,
        sizeCap = params.sizeCap or 1,
        speed = params.speed or 1,
        usesNegativeLighting = params.usesNegativeLighting or false,

        allowEnchanting = (params.allowEnchanting == nil) and true or params.allowEnchanting,
        allowSpellmaking = (params.allowSpellmaking == nil) and true or params.allowSpellmaking,
        appliesOnce = params.appliesOnce or false,

        canCastSelf = (params.canCastSelf == nil) and true or params.canCastSelf,
        canCastTarget = (params.canCastTouch == nil) and true or params.canCastTouch, --REVERSED! Odd problem with addMagicEffect
        canCastTouch = (params.canCastTarget == nil) and true or params.canCastTarget, --REVERSED! Touch/Target Reversed

        casterLinked = (params.casterLinked == nil) and true or params.casterLinked,
        hasNoDuration = params.hasNoDuration or false,
        hasNoMagnitude = params.hasNoMagnitude or false,
        illegalDaedra = params.illegalDaedra or false,
        isHarmful = params.isHarmful or false,
        nonRecastable = params.nonRecastable or false,
        targetsAttributes = params.targetsAttributes or false,
        targetsSkills = params.targetsSkills or false,
        unreflectable = params.unreflectable or false,

        onTick = params.onTick,
        onCollision = params.onCollision,
    })
    return effect
end

------------------------------------------------------------------------------------------------------------------------------
---@param e tes3magicEffectCollisionEventData
---@param effect tes3.effect Get the mag of effect from a complex spell, with multiple effects
function effectMaker.getComplexMag(e, effect)
    for _, effects in ipairs(e.sourceInstance.sourceEffects) do
        if effects.id == effect then
        local complexMag = effectMaker.getMag(effects)
            return complexMag
        end
    end
    return nil
end
------------------------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------------------------
---@param effect tes3effect Calculate an effective magnitdue for the effect
function effectMaker.getMag(effect) 
    local minMag = math.floor(effect.min)
    local maxMag = math.floor(effect.max)
    local eMag = math.random(minMag, maxMag)
    return eMag
end
------------------------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------------------------
---STOLE THESE FROM OPERATORJACK: for testing need to make my own
effectMaker.getActorsNearTargetPosition = function(cell, targetPosition, distanceLimit)
    local actors = {}
    -- Iterate through the references in the cell.
    for ref in cell:iterateReferences() do
        -- Check that the reference is a creature or NPC.
        if (ref.object.objectType == tes3.objectType.npc or
                ref.object.objectType == tes3.objectType.creature) then
            if (distanceLimit ~= nil) then
                -- Check that the distance between the reference and the target point is within the distance limit. If so, save the reference.
                local distance = targetPosition:distance(ref.position)
                if (distance <= distanceLimit) then
                    table.insert(actors, ref)
                end
            else
                table.insert(actors, ref)
            end
        end
    end
    return actors
end
------------------------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------------------------
effectMaker.getEffectFromEffectOnEffectEvent = function(event, effectId)
    for i = 1, 8 do
        local effect = event.sourceInstance.source.effects[i]
        if (effect ~= nil) then
            if (effect.id == effectId) then
                return effect
            end
        end
    end
    return nil
end
------------------------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------------------------
effectMaker.getCalculatedMagnitudeFromEffect = function(effect)
    local minMagnitude = math.floor(effect.min)
    local maxMagnitude = math.floor(effect.max)
    local magnitude = math.random(minMagnitude, maxMagnitude)
    return magnitude
end
------------------------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------------------------
return effectMaker
