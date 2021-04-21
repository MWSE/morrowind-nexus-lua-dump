
-- Load configuration.
return mwse.loadConfig("Combat-Mechanic-Enhancements", {
    -- Combat Scavenging Settings
    enableCombatScavenging = true,
    enableCombatScavengingWeapons = true,
    enableCombatScavengingArmor = false,
    enableCombatScavengingClothing = false,
    enableCombatScavengingPotions = false,
    combatScavengingSearchDistance = 128,
    combatScavengingForceEquip = true,

    -- Disarmament Settings
    enableDisarmament = true,
    disarmamentBaseChance = 1,
    disarmamentMaxChance = 50,
    disarmamentSearchDistance = 256,

    -- Interactive Bystanders Settings
    enableInteractiveBystanders = true,
    enableInteractiveBystandersWeaklingsFlee = true,
    enableInteractiveBystandersAssistGuards = true,
    interactiveBystandersFleeSearchDistance = 2048,
    interactiveBystandersFleeLowerLimit = 10,
    interactiveBystandersAssistGuardsSearchDistance = 2048,
    interactiveBystandersAssistGuardsLowerLimit = 10,

    -- General Settings
    debugMode = false
})