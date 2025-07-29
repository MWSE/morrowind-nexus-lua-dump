local framework = require("OperatorJack.MagickaExpanded")
local tick = require("OperatorJack.MagickaExpanded.utils.onTickHandlers")

tes3.claimSpellEffectId("conjurePalmFlame", 440)

--[[
    TODO:
    - Add custom icon
    - Add custom bolt VFX
]]
framework.effects.conjuration.createBasicEffect({
    -- Base information.
    id = tes3.effect.conjurePalmFlame,
    name = "Ручное пламя",
    description = "Обратитесь к духам природы, чтобы наколдовать шар пламени в своих руках.",

    -- Basic dials.
    baseCost = 5.0,

    -- Various flags.
    allowEnchanting = false,
    allowSpellmaking = false,
    hasNoMagnitude = false,
    hasNoDuration = false,
    canCastTarget = false,
    canCastTouch = false,
    canCastSelf = true,
    casterLinked = true,
    appliesOnce = true,
    isHarmful = true,
    nonRecastable = true,

    -- Graphics/sounds.
    hitVFX = framework.data.ids.objects.static.vfxEmpty,
    areaVFX = framework.data.ids.objects.static.vfxEmpty,
    boltVFX = framework.data.ids.objects.static.vfxEmpty,
    castVFX = "VFX_DestructCast",
    particleTexture = "vfx_firealpha00A.tga",

    -- Required callbacks.
    onTick = function(e)
        tick.onPalmEffectTick({
            effect = tes3.effect.conjurePalmFlame,
            resistAttribute = tes3.effectAttribute.resistFire,
            tickEventData = e,
            vfxRootNodeName = "oj_me_palm_flame",
            vfxPath = "OJ\\ME\\cp\\vfx_palm_flame.nif",
            vfxHitObjectId = "VFX_DestructHit"
        })
    end
})
