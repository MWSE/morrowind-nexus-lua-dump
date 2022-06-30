
    local defaultConfig = {
        isModActive = true,
        showUnlockChance = true,
        showDisarmChance = true,
        showKeyName = true,
        showTrapName = true,
        toolsIsNeededToSee = true,
        showTrapEnchantmentEffect = "Always",
        lockLevelDisplay = "Normal",
        trapDisplay = "Normal",
        trapEffectsDisplay = "Simple",
        tooltipRefreshFrequency = 0.25,
		fpicklockmult = -1,
		ftrapcostmult = 0

    }




local ssConfig = mwse.loadConfig("security_success", defaultConfig )

return ssConfig
