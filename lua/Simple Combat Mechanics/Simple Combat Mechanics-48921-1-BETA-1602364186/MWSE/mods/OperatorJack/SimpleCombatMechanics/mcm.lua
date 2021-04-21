local config = require("OperatorJack.SimpleCombatMechanics.config")

local function createGeneralCategory(page)
    local category = page:createCategory{
        label = "General Settings"
    }

    -- Create option to capture debug mode.
    category:createOnOffButton{
        label = "Enable Debug Mode",
        description = "Use this option to enable debug mode.",
        variable = mwse.mcm.createTableVariable{
            id = "debugMode",
            table = config
        }
    }

    return category
end

local function createCombatScavengingCategory(page)
    local category = page:createCategory{
        label = "Combat Scavenging Settings"
    }

    category:createOnOffButton{
        label = "Enable Combat Scavenging",
        description = "Use this option to enable combat scavenging. This will cause NPCs to look for and equip nearby (within reach) items during combat, if they haver ownership access to those items, and if the items are better than their current equipment and skill level. For example, an NPC will not pickup a daedric axe if their axe skill is significantly lower than their skill with their current weapon, but they would pick it up if their axe skill is similar or higher than their skill with their current weapon. This applies to weapons, armor, enchanted clothing, and potions as configured using the options below.",
        variable = mwse.mcm.createTableVariable{
            id = "enableCombatScavenging",
            table = config
        }
    }

    category:createOnOffButton{
        label = "Enable Scavenging of Weapons",
        description = "Use this option to enable combat scavenging of weapons. Requires combat scavenging to be enabled.",
        variable = mwse.mcm.createTableVariable{
            id = "enableCombatScavengingWeapons",
            table = config
        }
    }

    category:createOnOffButton{
        label = "Enable Scavenging of Armor",
        description = "Use this option to enable combat scavenging of armor. Requires combat scavenging to be enabled.",
        variable = mwse.mcm.createTableVariable{
            id = "enableCombatScavengingArmor",
            table = config
        }
    }

    category:createOnOffButton{
        label = "Enable Scavenging of Clothing",
        description = "Use this option to enable combat scavenging of clothing. Requires combat scavenging to be enabled.",
        variable = mwse.mcm.createTableVariable{
            id = "enableCombatScavengingClothing",
            table = config
        }
    }

    category:createOnOffButton{
        label = "Enable Scavenging of Potions",
        description = "Use this option to enable combat scavenging of potions. Requires combat scavenging to be enabled.",
        variable = mwse.mcm.createTableVariable{
            id = "enableCombatScavengingPotions",
            table = config
        }
    }

    category:createOnOffButton{
        label = "Enable Scavenging Force Equip",
        description = "Use this option to enable force equiping scavenged items. Requires combat scavenging to be enabled. If disabled, the games AI will determine when to use scavenged items.",
        variable = mwse.mcm.createTableVariable{
            id = "combatScavengingForceEquip",
            table = config
        }
    }

    category:createSlider{
        label = "Scavenging Distance",
        description = "Use this option to configure the distance at which NPCs will scavenge from their position.",
        min = 0,
        max = 500,
        step = 1,
        jump = 10,
        variable = mwse.mcm.createTableVariable{
            id = "combatScavengingSearchDistance",
            table = config
        }
    }

    return category
end

local function createDisarmamentCategory(page)
    local category = page:createCategory{
        label = "Disarmament Settings"
    }


    category:createOnOffButton{
        label = "Enable Disarmament",
        description = "Use this option to enable disarmament. This will add a disarming mechanic which allows the PC and NPCs to disarm each other. If using hand to hand, there is a chance to steal the target's weapon. If using a weapon, there is a chance to disarm the target, causing them to drop their weapon to the ground. Chances are based on the attacker and target's skills in their respective weapon.",
        variable = mwse.mcm.createTableVariable{
            id = "enableDisarmament",
            table = config
        }
    }

    category:createSlider{
        label = "Base Chance",
        description = "Use this option to configure the base chance at which disarmament will happen.",
        min = 0,
        max = 100,
        step = 1,
        jump = 5,
        variable = mwse.mcm.createTableVariable{
            id = "disarmamentBaseChance",
            table = config
        }
    }

    category:createSlider{
        label = "Max Chance",
        description = "Use this option to configure the maximum chance at which disarmament will happen. Calcualted chance will be cut-off to this value if higher.",
        min = 0,
        max = 100,
        step = 1,
        jump = 5,
        variable = mwse.mcm.createTableVariable{
            id = "disarmamentMaxChance",
            table = config
        }
    }

    category:createSlider{
        label = "Search Distance",
        description = "Use this option to configure the distance at which a strike can trigger a disarmament.",
        min = 0,
        max = 500,
        step = 1,
        jump = 10,
        variable = mwse.mcm.createTableVariable{
            id = "disarmamentSearchDistance",
            table = config
        }
    }

    return category
end


local function createInterativeBystandersCategory(page)
    local category = page:createCategory{
        label = "Interactive Bystanders Settings"
    }


    category:createOnOffButton{
        label = "Enable Interactive Bystanders",
        description = "Use this option to enable interactive bystanders. More powerful actors will assist guards. Actors will flee from nearby combatants if they are significantly weaker than any of the combatants.",
        variable = mwse.mcm.createTableVariable{
            id = "enableInteractiveBystanders",
            table = config
        }
    }

    category:createOnOffButton{
        label = "Enable Bystanders Flee",
        description = "Use this option to enable bystanders fleeing. If an actor is near a more powerful actor which that actor attacks, they will flee. If the more powerful actor does not attack, they will not flee. Requires interactive bystanders to be enabled.",
        variable = mwse.mcm.createTableVariable{
            id = "enableInteractiveBystandersWeaklingsFlee",
            table = config
        }
    }

    category:createOnOffButton{
        label = "Enable Bystanders Assist Guards",
        description = "Use this option to enable bystanders assisting guards. If an actor is near a guard that is in combat, they will assist the guard if the guard's target is near or less powerful than them. Requires interactive bystanders to be enabled.",
        variable = mwse.mcm.createTableVariable{
            id = "enableInteractiveBystandersAssistGuards",
            table = config
        }
    }

    category:createSlider{
        label = "Bystanders Flee Proximity Distance",
        description = "Use this option to configure the distance at which a bystander will flee from a more powerful actor.",
        min = 500,
        max = 5000,
        step = 10,
        jump = 100,
        variable = mwse.mcm.createTableVariable{
            id = "interactiveBystandersFleeSearchDistance",
            table = config
        }
    }

    category:createSlider{
        label = "Bystanders Flee Level Limit",
        description = "Use this option to configure the level difference at which bystanders will flee. If an actor is this value higher level than the bystander, the bystander will flee.",
        min = 0,
        max = 100,
        step = 1,
        jump = 10,
        variable = mwse.mcm.createTableVariable{
            id = "interactiveBystandersFleeLowerLimit",
            table = config
        }
    }

    category:createSlider{
        label = "Bystanders Assist Guards Proximity Distance",
        description = "Use this option to configure the distance at which a bystander will attempt to assist a nearby guard.",
        min = 500,
        max = 5000,
        step = 10,
        jump = 100,
        variable = mwse.mcm.createTableVariable{
            id = "interactiveBystandersAssistGuardsSearchDistance",
            table = config
        }
    }

    category:createSlider{
        label = "Bystanders Assist Guards Level Limit",
        description = "Use this option to configure the level at difference at which bystanders will attempt to help a guard. If an actor is this value, or more, higher level than the guard's target, the bystander will attempt to assist the guard.",
        min = 0,
        max = 100,
        step = 1,
        jump = 10,
        variable = mwse.mcm.createTableVariable{
            id = "interactiveBystandersAssistGuardsLowerLimit",
            table = config
        }
    }

    return category
end

-- Handle mod config menu.
local template = mwse.mcm.createTemplate("Simple Combat Mechanics")
template:saveOnClose("Simple-Combat-Mechanics", config)

local page = template:createSideBarPage{
    label = "Settings Sidebar",
    description = "Hover over a setting to learn more about it."
}

createGeneralCategory(page)
createCombatScavengingCategory(page)
createDisarmamentCategory(page)
createInterativeBystandersCategory(page)

mwse.mcm.register(template)