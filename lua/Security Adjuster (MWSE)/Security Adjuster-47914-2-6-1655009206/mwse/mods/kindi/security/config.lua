
    local defaultConfig = {
        showUnlockChance = true,
        showDisarmChance = true,
        showKeyName = true,
        showTrapName = true,
        showTrapEnchantmentEffect = false,
        lockLevelDisplay = "Normal",
        trapDisplay = "Normal",
        trapEffectsDisplay = "Verbose",
		fpicklockmult = -1,
		ftrapcostmult = 0

    }




local ssConfig = mwse.loadConfig("security_success", defaultConfig )

return ssConfig
