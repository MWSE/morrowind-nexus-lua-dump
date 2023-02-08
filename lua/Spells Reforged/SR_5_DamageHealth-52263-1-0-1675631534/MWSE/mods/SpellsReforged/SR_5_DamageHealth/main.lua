local spellsReforged = require("SpellsReforged.SR_0_Core")
assert(spellsReforged.version >= 1.0)

spellsReforged.registerVFX({
    id = tes3.effect.damageHealth,
    data = {
        handsVFX = {
            id = "VFX_k_DamLifeHands",
            lifespan = 1.0,
        },
        touchVFX = {
            id = "VFX_k_DamLifeTouch",
            lifespan = 1.0,
        },
    },
})