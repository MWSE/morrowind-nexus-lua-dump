local EasyMCM = require("easyMCM.EasyMCM");
local config  = require("timeConsumer.config")

local modName = 'Time Consumer';
local template = EasyMCM.createTemplate(modName)
template:saveOnClose(modName, config)
template:register()



local page = template:createSideBarPage({
    label = "Settings",
    description = "This mod passes time when the player enchants, repairs, performs alchemy, barters, or makes/buys a spell. Each feature can be enabled or disabled. Can be used alone for immersion or with other mods that introduce time-sensitive mechanics. All sliders are in tenths of an hour (A value of 10 = 1 hour, 55 = 5.5 hours, 3 = 0.3 hours). \n\n By Kleidium."
})


local settings = page:createCategory("Enchant Settings")

settings:createOnOffButton{
    label = "Enable Consumed Time on Enchant Success",
    description = "Turn on or off time consumption when the player successfully enchants an item.",
    variable = mwse.mcm.createTableVariable{ id = "advanceTimeEnchantSuccess", table = config }
}

settings:createOnOffButton{
    label = "Enable Consumed Time on Enchant Failure",
    description = "Turn on or off time consumption when the player fails to enchant an item.",
    variable = mwse.mcm.createTableVariable{ id = "advanceTimeEnchantFail", table = config }
}

settings:createOnOffButton{
    label = "Enable Consumed Time on NPC Enchanting",
    description = "Turn on or off time consumption when the player employs the services of an enchanter.",
    variable = mwse.mcm.createTableVariable{ id = "advanceTimeNPCenchant", table = config }
}

settings:createOnOffButton{
    label = "Enable Consumed Time on Enchant Recharge",
    description = "Turn on or off time consumption when the player uses a soul gem to recharge an item.",
    variable = mwse.mcm.createTableVariable{ id = "advanceTimeRecharge", table = config }
}


local enchantTime = settings:createCategory("Enchanting Base Time")

enchantTime:createSlider{
    label = "Base Enchant time for a successful enchant",
    description = "Set how much base time successful Enchants take before considering skill. Once skill is considered, the time consumed can be roughly anywhere between +40% to -60% of base time, in hours. (Based on 0-100 Skill Range, beyond 100 will still count) \n\nDefault: 5 hour(s) before skill consideration.",
    max = 120,
    min = 1,
    variable = EasyMCM:createTableVariable{
        id = "enchantSuccess_Modifier",
        table = config
    }
}

enchantTime:createSlider{
    label = "Base Enchant time for a failed enchant",
    description = "Set how much base time failed Enchants take before considering skill. Once skill is considered, the time consumed can be roughly anywhere between +40% to -60% of base time, in hours. (Based on 0-100 Skill Range, beyond 100 will still count) \n\nDefault: 2.5 hour(s) before skill consideration.",
    max = 120,
    min = 1,
    variable = EasyMCM:createTableVariable{
        id = "enchantFail_Modifier",
        table = config
    }
}

enchantTime:createSlider{
    label = "Enchant time when employing an enchanter",
    description = "Set how much time enchanting takes when the player employs the services of an enchanter. \n\nDefault: 4 hour(s).",
    max = 120,
    min = 1,
    variable = EasyMCM:createTableVariable{
        id = "enchantNPC_Modifier",
        table = config
    }
}

enchantTime:createSlider{
    label = "Base Enchant time when using a soul gem to recharge enchanted items",
    description = "Set how much base time recharge takes before considering skill. Once skill is considered, the time consumed can be roughly the same as base or as low as 10% of base time, in hours. (Based on 0-100 Skill Range, beyond 100 will still count) \n\nDefault: 0.5 hour(s).",
    max = 120,
    min = 1,
    variable = EasyMCM:createTableVariable{
        id = "recharge_Modifier",
        table = config
    }
}


local repairTime = settings:createCategory("Repair Settings")

repairTime:createOnOffButton{
    label = "Enable Consumed Time on player Repair Attempt",
    description = "Turn on or off time consumption when the player attempts to repair an item.",
    variable = mwse.mcm.createTableVariable{ id = "advanceTimeRepairAttempt", table = config }
}

repairTime:createOnOffButton{
    label = "Enable Consumed Time on NPC Repair",
    description = "Turn on or off time consumption when the player employs the services of a smith.",
    variable = mwse.mcm.createTableVariable{ id = "advanceTimeNPCrepair", table = config }
}

repairTime:createSlider{
    label = "Base Repair time for on attempted repair",
    description = "Set how much base time attempted repairs take before considering skill. Once skill is considered, the time consumed can be roughly the same as base or as low as 10% of base time, in hours. (Based on 0-100 Skill Range, beyond 100 will still count) \n\nDefault: 0.3 hour(s).",
    max = 120,
    min = 1,
    variable = EasyMCM:createTableVariable{
        id = "repairAttempt_Modifier",
        table = config
    }
}

repairTime:createSlider{
    label = "Repair time when employing a smith",
    description = "Set how much time repairs take when the player employs the services of a smith. \n\nDefault: 0.3 hour(s)",
    min = 1,
    max = 120,
    variable = EasyMCM:createTableVariable{
        id = "repairNPC_Modifier",
        table = config
    }
}


local alchemyTime = settings:createCategory("Alchemy Settings")

alchemyTime:createOnOffButton{
    label = "Enable Consumed Time on Alchemy success",
    description = [[Turn on or off time consumption when the player succeeds creating a potion.]],
    variable = mwse.mcm.createTableVariable{ id = "advanceTimePotionSuccess", table = config }
}

alchemyTime:createOnOffButton{
    label = "Enable Consumed Time on Alchemy failure",
    description = [[Turn on or off time consumption when the player fails creating a potion.]],
    variable = mwse.mcm.createTableVariable{ id = "advanceTimePotionFail", table = config }
}

alchemyTime:createSlider{
    label = "Base Alchemy time for a potion success",
    description = "Set how much base time alchemy successes take before considering skill. Once skill is considered, the time consumed can be roughly the same as base or as low as 10% of base time, in hours. (Based on 0-100 Skill Range, beyond 100 will still count) \n\nDefault: 1 hour(s) before skill consideration.",
    max = 120,
    min = 1,
    variable = EasyMCM:createTableVariable{
        id = "potionSuccess_Modifier",
        table = config
    }
}

alchemyTime:createSlider{
    label = "Base Alchemy time for a potion failure",
    description = "Set how much base time alchemy failures take before considering skill. Once skill is considered, the time consumed can be roughly the same as base or as low as 10% of base time, in hours. (Based on 0-100 Skill Range, beyond 100 will still count) \n\nDefault: 1 hour(s) before skill consideration.",
    max = 120,
    min = 1,
    variable = EasyMCM:createTableVariable{
        id = "potionFail_Modifier",
        table = config
    }
}


local npcSpellTime = settings:createCategory("Spellmaking/learning Settings")

npcSpellTime:createOnOffButton{
    label = "Enable Consumed Time on NPC Spellmaking",
    description = [[Turn on or off time consumption when the player employs the services of a spellmaker.]],
    variable = mwse.mcm.createTableVariable{ id = "advanceTimeNPCspellmaker", table = config }
}

npcSpellTime:createOnOffButton{
    label = "Enable Consumed Time on NPC Spell Purchase",
    description = [[Turn on or off time consumption when the player buys a pre made spell.]],
    variable = mwse.mcm.createTableVariable{ id = "advanceTimeNPCspell", table = config }
}

npcSpellTime:createSlider{
    label = "Spellmaking time when employing a spellmaker",
    description = "Set how much time spellmaking takes when the player employs the services of a spellmaker before considering intelligence. Every 10 points of intelligence reduces this amount by roughly 0.2 hours. \n\nDefault: 6 hour(s) before intelligence consideration.",
    max = 120,
    min = 1,
    variable = EasyMCM:createTableVariable{
        id = "npcSpellTime_Modifier",
        table = config
    }
}

npcSpellTime:createSlider{
    label = "Spell learning time when buying pre made spells",
    description = "Set how much time learning pre made spells takes when the player employs the services of a spell trader before considering intelligence. Once intelligence is considered, the time consumed can be roughly the same as base or as low as 10% of base time, in hours. (Based on 0-100 Skill Range, beyond 100 will still count) \n\nDefault: 1 hour(s) before intelligence consideration.",
    max = 120,
    min = 1,
    variable = EasyMCM:createTableVariable{
        id = "spellNPC_Modifier",
        table = config
    }
}


local barterTime = settings:createCategory("Barter Settings")

barterTime:createOnOffButton{
    label = "Enable Consumed Time on Bartering",
    description = [[Turn on or off time consumption when the player buys and sells items.]],
    variable = mwse.mcm.createTableVariable{ id = "advanceTimeBarter", table = config }
}


local miscSettings = settings:createCategory("Misc. Settings")

miscSettings:createOnOffButton{
    label = "Enable Debug Mode",
    description = "Turn on or off debug messages in MWSE log when this mod consumes time.",
    variable = mwse.mcm.createTableVariable{ id = "debugMode", table = config }
}