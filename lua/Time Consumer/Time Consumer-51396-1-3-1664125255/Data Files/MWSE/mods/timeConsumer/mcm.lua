local EasyMCM = require("easyMCM.EasyMCM");
local config  = require("timeConsumer.config")
local logger  = require("logging.logger")
local log     = logger.getLogger("Time Consumer")

local modName = 'Time Consumer';
local template = EasyMCM.createTemplate(modName)
template:saveOnClose(modName, config)
template:register()




local function createPage(label)
    local page = template:createSideBarPage {
        label = label,
        noScroll = false,
    }
    page.sidebar:createInfo {
        text = "                         -Time Consumer- \n\nThis mod passes time when the player enchants, repairs, performs alchemy, barters, chats, makes/buys a spell, or searches a container. Each feature can be enabled or disabled. Can be used alone for immersion or with other mods that introduce time-sensitive mechanics. \n\nAll sliders (except for talking time) are in tenths of an hour (A value of 10 = 1 hour, 55 = 5.5 hours, 3 = 0.3 hours)."
    }
    page.sidebar:createHyperLink {
        text = "Made by Kleidium",
        exec = "start https://www.nexusmods.com/users/5374229?tab=user+files",
        postCreate = function(self)
            self.elements.outerContainer.borderAllSides = self.indent
            self.elements.outerContainer.alignY = 1.0
            self.elements.info.layoutOriginFractionX = 0.5
        end,
    }
    return page
end

local settings = createPage("Global Settings")
local npcSettings = createPage("Service Settings")
local playerSettings = createPage("Player Settings")

----Global Settings----------------------------------------------------------------------------------------------------------

--Misc
local miscSettings = settings:createCategory("Misc. Settings")

miscSettings:createOnOffButton {
    label = "Enable Consumed Time when Looting",
    description = "Turn on or off time consumption when looting non-empty containers, including corpses. Searching a container consumes 1 minute.",
    variable = mwse.mcm.createTableVariable { id = "lootTime", table = config }
}

miscSettings:createOnOffButton {
    label = "Enable Fatigue Recovery",
    description = "Turn on or off fatigue recovery when consuming time while engaging in NPC service activities. \n\n(Talking, Bartering, NPC Spell Purchase, NPC Spellmaking, NPC Enchanting, NPC Repair are all considered service activities.)",
    variable = mwse.mcm.createTableVariable { id = "restMode", table = config }
}

miscSettings:createOnOffButton {
    label = "Enable Observer Bonus",
    description = "Turn on or off the chance of gaining a small amount of skill experience when consuming time observing NPCs perform services for you. If the relevant skill is 25 or above, no skill experience is gained. \n\n(NPC Repair: 10% chance to gain 1 armorer exp point, NPC Enchanting: 40% chance to gain 1 enchant exp point, NPC Spellmaking: 40% chance to gain 1 exp point in created spell's school)",
    variable = mwse.mcm.createTableVariable { id = "trainSkill", table = config }
}


settings:createDropdown {
    label = "Debug Logging Level",
    description = "Set the log level.",
    options = {
        { label = "TRACE", value = "TRACE" },
        { label = "DEBUG", value = "DEBUG" },
        { label = "INFO", value = "INFO" },
        { label = "ERROR", value = "ERROR" },
        { label = "NONE", value = "NONE" },
    },
    variable = mwse.mcm.createTableVariable { id = "logLevel", table = config },
    callback = function(self)
        log:setLogLevel(self.variable.value)
    end
}

----Player Settings----------------------------------------------------------------------------------------------------------

--Enchantment
local enchSettings = playerSettings:createCategory("Player Enchanting Settings")

enchSettings:createOnOffButton {
    label = "Enable Consumed Time on Enchantment Success",
    description = "Turn on or off time consumption when the player successfully enchants an item.",
    variable = mwse.mcm.createTableVariable { id = "advanceTimeEnchantSuccess", table = config }
}

enchSettings:createSlider {
    label = "Base Enchant time for a successful enchantment",
    description = "Set how much base time successful Enchants take before considering skill. \n\nOnce skill is considered, the time consumed can be roughly the same as base or as low as 60% of base time, in hours. (Based on 0-100 Skill Range, beyond 100 will still count) \n\nDefault: 5 hour(s) before skill consideration.",
    max = 120,
    min = 1,
    variable = EasyMCM:createTableVariable {
        id = "enchantSuccess_Modifier",
        table = config
    }
}

enchSettings:createOnOffButton {
    label = "Enable Consumed Time on Enchantment Failure",
    description = "Turn on or off time consumption when the player fails to enchant an item.",
    variable = mwse.mcm.createTableVariable { id = "advanceTimeEnchantFail", table = config }
}

enchSettings:createSlider {
    label = "Base Enchant time for a failed enchantment",
    description = "Set how much base time failed Enchants take before considering skill. \n\nOnce skill is considered, the time consumed can be roughly the same as base or as low as 60% of base time, in hours. (Based on 0-100 Skill Range, beyond 100 will still count) \n\nDefault: 2.5 hour(s) before skill consideration.",
    max = 120,
    min = 1,
    variable = EasyMCM:createTableVariable {
        id = "enchantFail_Modifier",
        table = config
    }
}

enchSettings:createOnOffButton {
    label = "Enable Consumed Time on Enchantment Recharge",
    description = "Turn on or off time consumption when the player uses a soul gem to recharge an item.",
    variable = mwse.mcm.createTableVariable { id = "advanceTimeRecharge", table = config }
}

enchSettings:createSlider {
    label = "Base Enchantment recharge time",
    description = "Set how much base time recharge takes before considering skill. \n\nOnce skill is considered, the time consumed can be roughly the same as base or as low as 33% of base time, in hours. (Based on 0-100 Skill Range, beyond 100 will still count) \n\nDefault: 0.5 hour(s).",
    max = 120,
    min = 1,
    variable = EasyMCM:createTableVariable {
        id = "recharge_Modifier",
        table = config
    }
}

--Repair
local repairTime = playerSettings:createCategory("Player Repair Settings")

repairTime:createOnOffButton {
    label = "Enable Consumed Time on player Repair Attempt",
    description = "Turn on or off time consumption when the player attempts to repair an item.",
    variable = mwse.mcm.createTableVariable { id = "advanceTimeRepairAttempt", table = config }
}

repairTime:createSlider {
    label = "Base Repair time for on attempted repair",
    description = "Set how much base time attempted repairs take before considering skill. \n\nOnce skill is considered, the time consumed can be roughly the same as base or as low as 20% of base time, in hours. (Based on 0-100 Skill Range, beyond 100 will still count) \n\nDefault: 0.3 hour(s).",
    max = 120,
    min = 1,
    variable = EasyMCM:createTableVariable {
        id = "repairAttempt_Modifier",
        table = config
    }
}

--Alchemy
local alchemyTime = playerSettings:createCategory("Player Alchemy Settings")

alchemyTime:createOnOffButton {
    label = "Enable Consumed Time on Alchemy success",
    description = [[Turn on or off time consumption when the player succeeds creating a potion.]],
    variable = mwse.mcm.createTableVariable { id = "advanceTimePotionSuccess", table = config }
}

alchemyTime:createSlider {
    label = "Base Alchemy time for a potion success",
    description = "Set how much base time alchemy successes take before considering skill. \n\nOnce skill is considered, the time consumed can be roughly the same as base or as low as 33% of base time, in hours. (Based on 0-100 Skill Range, beyond 100 will still count) \n\nDefault: 1 hour(s) before skill consideration.",
    max = 120,
    min = 1,
    variable = EasyMCM:createTableVariable {
        id = "potionSuccess_Modifier",
        table = config
    }
}

alchemyTime:createOnOffButton {
    label = "Enable Consumed Time on Alchemy failure",
    description = [[Turn on or off time consumption when the player fails creating a potion.]],
    variable = mwse.mcm.createTableVariable { id = "advanceTimePotionFail", table = config }
}

alchemyTime:createSlider {
    label = "Base Alchemy time for a potion failure",
    description = "Set how much base time alchemy failures take before considering skill. \n\nOnce skill is considered, the time consumed can be roughly the same as base or as low as 33% of base time, in hours. (Based on 0-100 Skill Range, beyond 100 will still count) \n\nDefault: 1 hour(s) before skill consideration.",
    max = 120,
    min = 1,
    variable = EasyMCM:createTableVariable {
        id = "potionFail_Modifier",
        table = config
    }
}


----NPC Settings-------------------------------------------------------------------------------------------------

--Enchantment
local enchSettings2 = npcSettings:createCategory("NPC Enchanting Settings")

enchSettings2:createOnOffButton {
    label = "Enable Consumed Time on NPC Enchanting",
    description = "Turn on or off time consumption when the player employs the services of an enchanter.",
    variable = mwse.mcm.createTableVariable { id = "advanceTimeNPCenchant", table = config }
}

enchSettings2:createSlider {
    label = "Enchant time when employing an enchanter",
    description = "Set how much time enchanting takes when the player employs the services of an enchanter before considering the enchanter's skill. \n\nOnce skill is considered, the time consumed can be roughly the same as base or as low as 60% of base time, in hours. (Based on 0-100 Skill Range, beyond 100 will still count)  \n\nDefault: 4 hour(s) before skill consideration.",
    max = 120,
    min = 1,
    variable = EasyMCM:createTableVariable {
        id = "enchantNPC_Modifier",
        table = config
    }
}

--Repair
local repairSettings2 = npcSettings:createCategory("NPC Repair Settings")

repairSettings2:createOnOffButton {
    label = "Enable Consumed Time on NPC Repair",
    description = "Turn on or off time consumption when the player employs the services of a smith.",
    variable = mwse.mcm.createTableVariable { id = "advanceTimeNPCrepair", table = config }
}

repairSettings2:createSlider {
    label = "Repair time when employing a smith",
    description = "Set how much time repairs take when the player employs the services of a smith before the smith's Armorer skill is considered. \n\nOnce skill is considered, the time consumed can be roughly the same as base or as low as 20% of base time, in hours. (Based on 0-100 Skill Range, beyond 100 will still count)  \n\nDefault: 0.5 hour(s) before skill consideration.",
    min = 1,
    max = 120,
    variable = EasyMCM:createTableVariable {
        id = "repairNPC_Modifier",
        table = config
    }
}

--Spellmaking/learning
local npcSpellTime = npcSettings:createCategory("Spellmaking/learning Settings")

npcSpellTime:createOnOffButton {
    label = "Enable Consumed Time on NPC Spellmaking",
    description = [[Turn on or off time consumption when the player employs the services of a spellmaker.]],
    variable = mwse.mcm.createTableVariable { id = "advanceTimeNPCspellmaker", table = config }
}

npcSpellTime:createSlider {
    label = "Spellmaking time when employing a spellmaker",
    description = "Set how much time spellmaking takes when the player employs the services of a spellmaker before considering intelligence of both the spellmaker and the player. \n\nOnce intelligence is considered, the time consumed can be roughly the same as base or as low as 60% of base time, hours. (Based on 0-100 Attribute Range, beyond 100 will still count) \n\nDefault: 6 hour(s) before intelligence consideration.",
    max = 120,
    min = 1,
    variable = EasyMCM:createTableVariable {
        id = "npcSpellTime_Modifier",
        table = config
    }
}

npcSpellTime:createOnOffButton {
    label = "Enable Consumed Time on NPC Spell Purchase",
    description = [[Turn on or off time consumption when the player buys a pre made spell.]],
    variable = mwse.mcm.createTableVariable { id = "advanceTimeNPCspell", table = config }
}

npcSpellTime:createSlider {
    label = "Spell learning time when buying pre made spells",
    description = "Set how much time learning pre made spells takes when the player employs the services of a spell trader before considering intelligence of both the spell trader and the player. \n\nOnce intelligence is considered, the time consumed can be roughly the same as base or as low as 30% of base time, in hours. (Based on 0-100 Attribute Range, beyond 100 will still count) \n\nDefault: 1 hour(s) before intelligence consideration.",
    max = 120,
    min = 1,
    variable = EasyMCM:createTableVariable {
        id = "spellNPC_Modifier",
        table = config
    }
}

--Social
local barterTime = npcSettings:createCategory("Social Settings")

barterTime:createOnOffButton {
    label = "Enable Consumed Time when Bartering",
    description = [[Turn on or off time consumption when the player buys and sells items. Each instance of selecting an item to buy or sell as well as making an offer consumes 1 minute.]],
    variable = mwse.mcm.createTableVariable { id = "advanceTimeBarter", table = config }
}

barterTime:createOnOffButton {
    label = "Enable Consumed Time when Talking",
    description = [[Turn on or off time consumption when the player asks about a topic, gives a response, attempts persuasion, or is refused service. Each instance of speaking takes 1-3 minutes by default, configurable below.]],
    variable = mwse.mcm.createTableVariable { id = "advanceTimeChat", table = config }
}

barterTime:createSlider {
    label = "Minimum talk time",
    description = "The minimum amount of time (in minutes) speaking will consume per instance.",
    max = 20,
    min = 1,
    variable = EasyMCM:createTableVariable {
        id = "chatMin",
        table = config
    }
}

barterTime:createSlider {
    label = "Maximum talk time",
    description = "The maximum amount of time (in minutes) speaking will consume per instance.",
    max = 20,
    min = 1,
    variable = EasyMCM:createTableVariable {
        id = "chatMax",
        table = config
    }
}
