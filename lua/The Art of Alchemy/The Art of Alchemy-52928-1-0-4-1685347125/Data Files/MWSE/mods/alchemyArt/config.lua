local defaultConfig = {
    modEnabled = true,
    rebalanceApparatus = true,
    rebalancePotions = true,
    fixApparatusModels = true,
    overhaulIngredients = true,
    hideUngrindedEffects = false,
    tutorialMode = true,
    alchemyTime = 6,
    experienceGain = 4,
}

local mwseConfig = mwse.loadConfig("alchemyArt", defaultConfig)

return mwseConfig