local spellsReforged = require("SpellsReforged.SR_0_Core")
assert(spellsReforged.version >= 1.0)

spellsReforged.registerVFX({
    id = tes3.effect.damageMagicka,
    data = {
        handsVFX = {
            id = "VFX_k_DamMagiHands",
            lifespan = 1.0,
        },
        touchVFX = {
            id = "VFX_k_DamMagiTouch",
            lifespan = 1.0,
        },
    },
})