local defaultConfig = {
    Name = "[Mechanics Remastered]",
    CombatEnabled = true,
    SpellcastEnabled = true,
    HealthRegenEnabled = true,
    HealthRegenSpeed = 1.0,
    MagickaRegenEnabled = true,
    MagickaRegenSpeed = 1.0,
    LevelupUncappedBonus = true,
    LevelupPersistSkills = true,
    HealthIncreaseEnabled = true,
    FastTravelEnabled = true,
    FastTravelTimescale = 1.0
}

return mwse.loadConfig("MechanicsRemastered", defaultConfig)