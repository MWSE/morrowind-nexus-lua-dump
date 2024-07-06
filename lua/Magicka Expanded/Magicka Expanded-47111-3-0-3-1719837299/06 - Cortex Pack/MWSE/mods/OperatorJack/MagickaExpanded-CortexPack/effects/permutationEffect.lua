local framework = require("OperatorJack.MagickaExpanded")

tes3.claimSpellEffectId("permutation", 335)

local permutationList = {
    [0] = "mudcrab",
    [10] = "mudcrab",
    [20] = "nix-hound",
    [30] = "kagouti",
    [40] = "atronach_flame",
    [50] = "atronach_frost",
    [60] = "dremora",
    [70] = "atronach_storm",
    [80] = "winged twilight",
    [90] = "golden saint",
    [100] = "fabricant_hulking"
}

local function onPermutationTick(e)
    local caster = e.sourceInstance.caster
    local value = (caster.mobile.willpower.current * .4) + (caster.mobile.conjuration.current * .6)

    local rounded = math.round(value, -1)
    if (rounded > 100) then rounded = 100 end

    local id = permutationList[rounded]
    e:triggerSummon(id)
end

framework.effects.conjuration.createBasicEffect({
    -- Base information.
    id = tes3.effect.permutation,
    name = "Permutation",
    description = "Summons a creature from Oblivion that is increasingly more powerful depending on the caster's conjuration and willpower.",

    -- Basic dials.
    baseCost = 50.0,

    -- Various flags.
    allowEnchanting = true,
    allowSpellmaking = true,
    canCastSelf = true,
    hasNoMagnitude = true,
    casterLinked = true,
    appliesOnce = true,

    -- Graphics/sounds.
    icon = "RFD\\RFD_crt_permutation.dds",
    lighting = {0, 0, 0},

    -- Required callbacks.
    onTick = onPermutationTick
})
