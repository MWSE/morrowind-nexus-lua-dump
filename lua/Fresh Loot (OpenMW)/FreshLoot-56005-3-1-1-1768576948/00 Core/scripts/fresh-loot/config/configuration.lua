return {
    containerSearch = {
        frequencySec = 3,
        navigationMeshGenDelay = 1,
    },
    checkNewContainersFrequency = 3,
    lootLevel = {
        endGameLootLevel = 50,
        minHostileFightValue = 70,
        minProtectorAlarmValue = 70,
        passiveActorsLevelRatio = 75,
        actorDontSeeLootDoesntMoveAroundRatio = 0.25,
        actorDontSeeLootMovesAroundRatio = 0.50,
        actorSeeLootIsMovingRatio = 0.75,
        maxKeepersSearchDistance = 5000,
        maxKeepersTravelDistance = 3000,
        maxKeepersReachLootDistance = 300,
        maxKeepersProtectLootDistance = 2000,
        maxKeepersTravelTime = 5,
        maxLockBoost = 10,
        maxTrapBoost = 5,
        maxWaterDepthBoost = 5,
    },
    modifierChance = {
        props = 20,
        equippedWeaponSecondChanceLootLevelRatio = 50,
    },
    waterLevelHalfBonus = 500,
    modifierLevel = {
        playerLevelScaling = 0,
        maxLevel = 5,
        pickAlpha = 4,
    },
    itemConversion = {
        projectileStackReduction = 50,
        projectileValueReduction = 25,
        propsLevelMult = {
            enchantCost = { 1, 2, 3, 4, 5 },
            enchantCharge = { 1, 2, 3, 4, 5 },
            priceForAbsoluteMod = { 1, 2, 3, 4, 5 },
            priceForRelativeMod = { 1.05, 1.1, 1.15, 1.2, 1.25 },
        },
    },
    itemWindow = {
        maxRowsPerPage = 15,
    }
}