local defaultConfig = {
    Name = "[Mechanics Remastered]",

    -- Combat Settings
    CombatEnabled = true,
    CombatAlwaysHit = true,
    CombatDamageScaling = true,
    CombatStunScaling = true,
    CombatAttackXPScaling = true,
    CombatDefenseXPScaling = true,
    CombatEnchantScaling = true,

    -- Spellcast Settings
    SpellcastEnabled = true,
    SpellcastAlwaysCast = true,
    SpellcastCostScaling = true,
    SpellcastSpeedScaling = true,

    -- Health Regen Settings
    HealthRegenEnabled = true,
    HealthRegenSpeed = 1.0,
    HealthRegenNPC = true,
    HealthRegenOutOfCombatOnly = true,
    HealthRegenWhileWaiting = true,

    -- Magicka Regen Settings
    MagickaRegenEnabled = true,
    MagickaRegenSpeed = 1.0,
    MagickaRegenNPC = true,
    MagickaRegenWhileWaiting = true,

    -- Level Up Settings
    LevelupUncappedBonus = true,
    LevelupPersistSkills = true,

    -- Health Increase Settings
    HealthIncreaseEnabled = true,

    -- Fast Travel Settings
    FastTravelEnabled = true,
    FastTravelTimescale = 1.0,
    FastTravelAdvanceTime = true,
    FastTravelRegen = true,
    FastTravelAllowInCombat = false,
    FastTravelAllowOverencumbered = false,
    FastTravelAllowFromInterior = false,
    FastTravelRequireVisited = true
}

return mwse.loadConfig("MechanicsRemastered", defaultConfig)
