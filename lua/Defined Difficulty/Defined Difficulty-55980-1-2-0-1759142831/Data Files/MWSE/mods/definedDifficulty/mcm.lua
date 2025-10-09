local EasyMCM = require("easyMCM.EasyMCM");
local config  = require("definedDifficulty.config")
local logger  = require("logging.logger")
local log     = logger.getLogger("Defined Difficulty")

local modName = 'Defined Difficulty';
local template = EasyMCM.createTemplate { name = modName }
template:saveOnClose(modName, config)
template:register()

local function createPage(label)
    local page = template:createSideBarPage {
        label = label,
        noScroll = false,
    }
    page.sidebar:createInfo {
        text = "                          Defined Difficulty \n\nThis mod enables you to define a new layer of difficulty based on your difficulty slider settings. This allows the difficulty slider to affect things like NPC Health, experience gain, and damage the way you want.\n\nSettings from this mod are applied BEFORE your vanilla slider settings are applied. Default settings assume a slider value of 0 or above."
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

local function quickCalc(e)
    if tes3.mobilePlayer then
        --fix this somehow
        local type = config.playerDamage
        local label = "damage"
        local floor = nil
        local limit = nil
        if e.label == "NPC Damage Rate" then
            type = config.npcDamage
            limit = config.damageLimitNPC
            floor = config.damageFloorNPC
        elseif e.label == "Player Spell Resist Rate" then
            type = config.playerResist
            label = "Spell Resistance"
            limit = config.resistLimitPlayer
            floor = config.resistFloorPlayer
        elseif e.label == "NPC Spell Resist Rate" then
            type = config.npcResist
            label = "Spell Resistance"
            limit = config.resistLimitNPC
            floor = config.resistFloorNPC
        elseif e.label == "NPC Health Rate" then
            type = config.healthMod
            label = "health"
            limit = config.healthLimit
            floor = config.healthFloor
        elseif e.label == "NPC Strength Rate" then
            type = config.strengthMod
            label = "Strength"
            limit = config.strengthLimit
            floor = config.strengthFloor
        elseif e.label == "NPC Intelligence Rate" then
            type = config.intelligenceMod
            label = "Intelligence"
            limit = config.intelligenceLimit
            floor = config.intelligenceFloor
        elseif e.label == "NPC Willpower Rate" then
            type = config.willpowerMod
            label = "Willpower"
            limit = config.willpowerLimit
            floor = config.willpowerFloor
        elseif e.label == "NPC Agility Rate" then
            type = config.agilityMod
            label = "Agility"
            limit = config.agilityLimit
            floor = config.agilityFloor
        elseif e.label == "NPC Speed Rate" then
            type = config.speedMod
            label = "Speed"
            limit = config.speedLimit
            floor = config.speedFloor
        elseif e.label == "NPC Endurance Rate" then
            type = config.enduranceMod
            label = "Endurance"
            limit = config.enduranceLimit
            floor = config.enduranceFloor
        elseif e.label == "NPC Personality Rate" then
            type = config.personalityMod
            label = "Personality"
            limit = config.personalityLimit
            floor = config.personalityFloor
        elseif e.label == "NPC Luck Rate" then
            type = config.luckMod
            label = "Luck"
            limit = config.luckLimit
            floor = config.luckFloor
        elseif e.label == "Alchemy Rate" then
            type = config.alchemyMod
            label = "Potion Strength"
            limit = config.alchemyLimit
            floor = config.alchemyFloor
        elseif e.label == "Cast Rate" then
            type = config.castMod
            label = "Cast Chance"
            floor = config.castFloor
        elseif e.label == "Charge Rate" then
            type = config.chargeMod
            label = "Charge Cost"
            limit = config.chargeLimit
            floor = config.chargeFloor
        elseif e.label == "Reflect Rate" then
            type = config.reflectMod
            label = "Reflect Chance"
            floor = config.reflectFloor
        elseif e.label == "Experience Rate" then
            type = config.expMod
            label = "Skill Experience"
            limit = config.expLimit
            floor = config.expFloor
        elseif e.label == "Repair Rate" then
            type = config.repairMod
            label = "Repair Amount"
            limit = config.repairLimit
            floor = config.repairFloor
        elseif e.label == "Security Rate" then
            type = config.lockMod
            label = "Lockpick/Trap Disarm Chance"
            floor = config.lockFloor
        elseif e.label == "Pickpocketing Rate" then
            type = config.pocketMod
            label = "Pickpocketing Chance"
            floor = config.pocketFloor
        elseif e.label == "Training Price Rate" then
            type = config.trainingPriceMod
            label = "Training Price"
            limit = config.trainingPriceLimit
            floor = config.trainingPriceFloor
        elseif e.label == "Travel Price Rate" then
            type = config.travelPriceMod
            label = "Travel Price"
            limit = config.travelPriceLimit
            floor = config.travelPriceFloor
        elseif e.label == "Repair Price Rate" then
            type = config.repairPriceMod
            label = "Repair Price"
            limit = config.repairPriceLimit
            floor = config.repairPriceFloor
        elseif e.label == "Spellmaking Price Rate" then
            type = config.spellmakingPriceMod
            label = "Spellmaking Price"
            limit = config.spellmakingPriceLimit
            floor = config.spellmakingPriceFloor
        elseif e.label == "Enchanting Price Rate" then
            type = config.enchantingPriceMod
            label = "Enchanting Price"
            limit = config.enchantingPriceLimit
            floor = config.enchantingPriceFloor
        else
            limit = config.damageLimitPlayer
            floor = config.damageFloorPlayer
        end

        local diff = (tes3.worldController.difficulty) * 100
        local mod = type * diff

        if limit ~= nil then
            if mod > limit then
                mod = limit
            end
        end

        if floor ~= nil then
            if mod < floor then
                mod = floor
            end
        end

        if config.flatValues == true then
            tes3.messageBox({ message = "Difficulty: " .. math.round(diff, 2) .. "\n\n" .. e.label .. ": " .. math.round(mod, 2) .. " total " .. label .. "", duration = 4 })
        else
            tes3.messageBox({ message = "Difficulty: " .. math.round(diff, 2) .. "\n\n" .. e.label .. ": " .. math.round(mod, 2) .. "% total " .. label .. "", duration = 4 })
        end
    end
end

local settings = createPage("Settings")

----Settings----------------------------------------------------------------------------------------------------------

local general = settings:createCategory("General Settings")

general:createOnOffButton {
    label = "Flat Value Mode",
    description = "Turn on or off Flat Value Mode. In Flat Value Mode, the difficulty slider increases/reduces damage/health/exp etc. by a flat amount rather than a percentage. \n\nExample: -50% damage would translate to -50 damage on hit.",
    variable = mwse.mcm.createTableVariable { id = "flatValues", table = config }
}

general:createOnOffButton {
    label = "Affect Physical Damage",
    description = "Determines whether or not physical damage will be affected by this mod. Changes to physical damage are applied BEFORE the vanilla slider applies. Changing this setting requires a restart to take effect.",
    restartRequired = true,
    variable = mwse.mcm.createTableVariable { id = "affectDamage", table = config }
}

general:createOnOffButton {
    label = "Affect Hit Chance",
    description = "Determines whether or not melee hit chance will be affected by this mod. Changing this setting requires a restart to take effect.",
    restartRequired = true,
    variable = mwse.mcm.createTableVariable { id = "affectHit", table = config }
}

general:createOnOffButton {
    label = "Affect Spell Resistance",
    description = "Determines whether or not spell resistance will be affected by this mod. Spells cast on Self are NOT affected. Changing this setting requires a restart to take effect.",
    restartRequired = true,
    variable = mwse.mcm.createTableVariable { id = "affectResist", table = config }
}

general:createOnOffButton {
    label = "Cap Spell Resistance",
    description = "Turn on or off the Spell Resistance cap. With the cap, spell resistance will never rise above 100. Resistances above 100 may display strange behavior.\n\nExample: Resistances above 100 can result in damage spells providing healing instead.",
    variable = mwse.mcm.createTableVariable { id = "capResist", table = config }
}

general:createOnOffButton {
    label = "Affect Non-Hostile Spells",
    description = "Choose whether or not Non-Hostile spells will be affected by your Spell Resistance settings. When turned on, Player/NPC Spell Resistance settings affect non-hostile spells.\n\nExample: Your settings give NPCs 50% spell resistance. With this turned on, the player's non-hostile spells (healing/calming/charming etc) are 50% less effective on NPCs as well.",
    variable = mwse.mcm.createTableVariable { id = "affectPositiveSpells", table = config }
}

--Affect Calm and Charm
general:createOnOffButton {
    label = "Calm and Charm as Hostile Spells",
    description = "Determines whether or not calm and charm effects are considered hostile by this mod's spell resistance settings. If considered hostile, Calm and Charm effects are treated on par with Damage Health rather than Restore Health. Only useful if \"Affect Non-Hostile Spells\" is turned off.",
    variable = mwse.mcm.createTableVariable { id = "hostileIllusion", table = config }
}

general:createOnOffButton {
    label = "Affect Lock/Open Spells",
    description = "Choose whether or not Lock/Open spells will be affected by your Spell Resistance settings. When turned on, NPC Spell Resistance settings affect the player's Lock/Open spells.\n\nExample: Your settings give NPCs 50% spell resistance. With this turned on, doors and chests also have 50% Spell Resistance to Lock/Open spells, requiring a higher magnitude to be effective.",
    variable = mwse.mcm.createTableVariable { id = "affectLockSpells", table = config }
}

general:createDropdown {
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



local player = createPage("Player Settings")---------------------------------------------------------------------------------------

local dmg = player:createCategory("Melee Settings")

--Damage--
dmg:createSlider {
    label = "Player Damage Rate",
    description = "Controls the rate at which the player's physical damage is affected by difficulty. \n\nDefault: -0.50% damage (or -0.50 damage in Flat Value Mode) per difficulty point.",
    max = 20.00,
    min = -20.00,
    step = 0.01,
    jump = 0.10,
    decimalPlaces = 2,
    callback = quickCalc,
    variable = EasyMCM:createTableVariable {
        id = "playerDamage",
        table = config
    }
}

dmg:createSlider {
    label = "Player Damage Limit",
    description = "The maximum amount that the player's physical damage can be increased by. \n\nDefault: 2000% damage increase or +2000 damage in Flat Value Mode.",
    max = 2000,
    min = 100,
    jump = 10,
    variable = EasyMCM:createTableVariable {
        id = "damageLimitPlayer",
        table = config
    }
}

dmg:createSlider {
    label = "Player Damage Floor",
    description = "The maximum amount that the player's physical damage can be reduced by. Represented as a whole number.\n\nDefault: 75% damage reduction or -75 damage in Flat Value Mode.",
    max = 0,
    min = -100,
    variable = EasyMCM:createTableVariable {
        id = "damageFloorPlayer",
        table = config
    }
}

--Hit Chance--
dmg:createSlider {
    label = "Player Hit Rate",
    description = "Controls the rate at which the player's melee hit chance is affected by difficulty. \n\nDefault: -0.25% chance (or -0.25 chance in Flat Value Mode) per difficulty point.",
    max = 20.00,
    min = -20.00,
    step = 0.01,
    jump = 0.10,
    decimalPlaces = 2,
    callback = quickCalc,
    variable = EasyMCM:createTableVariable {
        id = "playerHit",
        table = config
    }
}

dmg:createSlider {
    label = "Player Hit Limit",
    description = "The maximum amount that the player's melee hit chance can be increased by. \n\nDefault: 1000% chance increase or +1000 chance in Flat Value Mode.",
    max = 2000,
    min = 100,
    jump = 10,
    variable = EasyMCM:createTableVariable {
        id = "hitLimitPlayer",
        table = config
    }
}

dmg:createSlider {
    label = "Player Hit Floor",
    description = "The maximum amount that the player's melee hit chance can be reduced by. Represented as a whole number.\n\nDefault: 75% hit chance reduction or -75 hit chance in Flat Value Mode.",
    max = 0,
    min = -100,
    variable = EasyMCM:createTableVariable {
        id = "hitFloorPlayer",
        table = config
    }
}


local mgk = player:createCategory("Magic Settings")

--Player Spell Resist--
mgk:createSlider {
    label = "Player Spell Resist Rate",
    description = "Controls the rate at which the player's spell resistance is affected by difficulty.\n\nDefault: -0.50% spell resistance per difficulty point.",
    max = 20.00,
    min = -20.00,
    step = 0.01,
    jump = 0.10,
    decimalPlaces = 2,
    callback = quickCalc,
    variable = EasyMCM:createTableVariable {
        id = "playerResist",
        table = config
    }
}

mgk:createSlider {
    label = "Player Spell Resist Limit",
    description = "The maximum amount that the player's spell resistance can be increased by. \n\nDefault: +75% spell resistance increase maximum.",
    max = 2000,
    min = 0,
    jump = 10,
    variable = EasyMCM:createTableVariable {
        id = "resistLimitPlayer",
        table = config
    }
}

mgk:createSlider {
    label = "Player Spell Resist Floor",
    description = "The maximum amount that the player's spell resistance can be reduced by. Represented as a whole number.\n\nDefault: -2000% spell resistance decrease maximum.",
    max = 0,
    min = -2000,
    jump = 10,
    variable = EasyMCM:createTableVariable {
        id = "resistFloorPlayer",
        table = config
    }
}

--Cast Chance--
mgk:createOnOffButton {
    label = "Affect Cast Chance",
    description = "Determines whether or not player cast chance will be affected by difficulty. This will make 100% cast chance harder to obtain on all spells. How much harder is up to your settings.\n\nNote: Keep in mind how much your difficulty is affecting your cast chance when looking through your spell list. The spell menu will NOT display your final cast chance.",
    variable = mwse.mcm.createTableVariable { id = "affectCastChance", table = config }
}

mgk:createSlider {
    label = "Cast Rate",
    description = "Controls the rate at which the player's cast chance is affected by difficulty. \n\nDefault: -0.30% cast chance (or -0.30 cast chance in Flat Value Mode) per difficulty point.",
    max = 20.00,
    min = -20.00,
    step = 0.01,
    jump = 0.10,
    decimalPlaces = 2,
    callback = quickCalc,
    variable = EasyMCM:createTableVariable {
        id = "castMod",
        table = config
    }
}

mgk:createSlider {
    label = "Cast Floor",
    description = "The maximum amount that the player's cast chance can be reduced by. Represented as a whole number.\n\nDefault: 75% cast chance reduction or -75 cast chance in Flat Value Mode.",
    max = 0,
    min = -100,
    variable = EasyMCM:createTableVariable {
        id = "castFloor",
        table = config
    }
}

--Enchantment Charge Cost
mgk:createOnOffButton {
    label = "Affect Enchantment Charge Cost",
    description = "Determines whether or not enchantment charge cost will be affected by difficulty. Changing this setting requires a restart.",
    restartRequired = true,
    variable = mwse.mcm.createTableVariable { id = "affectCharge", table = config }
}

mgk:createSlider {
    label = "Charge Rate",
    description = "Controls the rate at which the player's enchantment charge cost is affected by difficulty. \n\nDefault: +0.30% charge cost (or +0.30 charge cost in Flat Value Mode) per difficulty point.",
    max = 20.00,
    min = -20.00,
    step = 0.01,
    jump = 0.10,
    decimalPlaces = 2,
    callback = quickCalc,
    variable = EasyMCM:createTableVariable {
        id = "chargeMod",
        table = config
    }
}

mgk:createSlider {
    label = "Charge Limit",
    description = "The maximum amount that the player's enchantment charge cost can be increased by. \n\nDefault: 1000% enchantment charge cost or +1000 enchantment charge cost in Flat Value Mode.",
    max = 2000,
    min = 100,
    jump = 10,
    variable = EasyMCM:createTableVariable {
        id = "chargeLimit",
        table = config
    }
}

mgk:createSlider {
    label = "Charge Floor",
    description = "The maximum amount that the player's enchantment charge cost can be reduced by. Represented as a whole number.\n\nDefault: 75% enchantment charge cost reduction or -75 enchantment charge cost in Flat Value Mode.",
    max = 0,
    min = -100,
    variable = EasyMCM:createTableVariable {
        id = "chargeFloor",
        table = config
    }
}

--Reflect Chance--
mgk:createOnOffButton {
    label = "Affect Spell Reflect Chance",
    description = "Determines whether or not player spell reflect chance will be affected by difficulty. This can attempt to balance spell reflect by making 100% reflect chance harder or impossible to obtain. Changing this setting requires a restart to take effect.\n\nAny reduction will make 100% reflect chance impossible to obtain with a vanilla spell, though it can still be possible with mods or very close depending on your settings.",
    restartRequired = true,
    variable = mwse.mcm.createTableVariable { id = "affectReflect", table = config }
}

mgk:createSlider {
    label = "Reflect Rate",
    description = "Controls the rate at which the player's spell reflect chance is affected by difficulty. \n\nDefault: -0.50% reflect chance (or -0.50 reflect chance in Flat Value Mode) per difficulty point.",
    max = 20.00,
    min = -20.00,
    step = 0.01,
    jump = 0.10,
    decimalPlaces = 2,
    callback = quickCalc,
    variable = EasyMCM:createTableVariable {
        id = "reflectMod",
        table = config
    }
}

mgk:createSlider {
    label = "Reflect Floor",
    description = "The maximum amount that the player's reflect chance can be reduced by. Represented as a whole number.\n\nDefault: 75% reflect chance reduction or -75 reflect chance in Flat Value Mode.",
    max = 0,
    min = -100,
    variable = EasyMCM:createTableVariable {
        id = "castFloor",
        table = config
    }
}



local non = player:createCategory("Non-Combat Settings")

--Security Chance--
non:createOnOffButton {
    label = "Affect Security",
    description = "Determines whether or not player lockpick/trap disarm chance will be affected by difficulty. This will make 100% pick/disarm chance harder to obtain on all locks. How much harder is up to your settings.",
    variable = mwse.mcm.createTableVariable { id = "affectLocks", table = config }
}

non:createSlider {
    label = "Security Rate",
    description = "Controls the rate at which the player's lockpick/trap disarm chance is affected by difficulty. \n\nDefault: -0.30% pick/disarm chance (or -0.30 pick/disarm chance in Flat Value Mode) per difficulty point.",
    max = 20.00,
    min = -20.00,
    step = 0.01,
    jump = 0.10,
    decimalPlaces = 2,
    callback = quickCalc,
    variable = EasyMCM:createTableVariable {
        id = "lockMod",
        table = config
    }
}

non:createSlider {
    label = "Security Floor",
    description = "The maximum amount that the player's lockpick/trap disarm chance can be reduced by. Represented as a whole number.\n\nDefault: 75% pick/disarm chance reduction or -75 pick chance in Flat Value Mode.",
    max = 0,
    min = -100,
    variable = EasyMCM:createTableVariable {
        id = "lockFloor",
        table = config
    }
}

--Pickpocket Chance--
non:createOnOffButton {
    label = "Affect Pickpocketing",
    description = "Determines whether or not player pickpocket chance will be affected by difficulty. This will make 100% pickpocket chance harder to obtain. How much harder is up to your settings.",
    variable = mwse.mcm.createTableVariable { id = "affectPockets", table = config }
}

non:createSlider {
    label = "Pickpocketing Rate",
    description = "Controls the rate at which the player's pickpocketing chance is affected by difficulty. \n\nDefault: -0.30% pickpocket chance (or -0.30 pickpocket chance in Flat Value Mode) per difficulty point.",
    max = 20.00,
    min = -20.00,
    step = 0.01,
    jump = 0.10,
    decimalPlaces = 2,
    callback = quickCalc,
    variable = EasyMCM:createTableVariable {
        id = "pocketMod",
        table = config
    }
}

non:createSlider {
    label = "Pickpocketing Floor",
    description = "The maximum amount that the player's pickpocketing chance can be reduced by. Represented as a whole number.\n\nDefault: 75% pickpocket chance reduction or -75 pickpocket chance in Flat Value Mode.",
    max = 0,
    min = -100,
    variable = EasyMCM:createTableVariable {
        id = "pocketFloor",
        table = config
    }
}

--Potion Strength--
non:createOnOffButton {
    label = "Affect Alchemy",
    description = "Determines whether or not potion strength will be affected by difficulty.",
    variable = mwse.mcm.createTableVariable { id = "affectAlchemy", table = config }
}

non:createSlider {
    label = "Alchemy Rate",
    description = "Controls the rate at which the player's potion strength is affected by difficulty. \n\nDefault: -0.30% potion strength (or -0.30 potion strength in Flat Value Mode) per difficulty point.",
    max = 20.00,
    min = -20.00,
    step = 0.01,
    jump = 0.10,
    decimalPlaces = 2,
    callback = quickCalc,
    variable = EasyMCM:createTableVariable {
        id = "alchemyMod",
        table = config
    }
}

non:createSlider {
    label = "Alchemy Limit",
    description = "The maximum amount that the player's potion strength can be increased by. \n\nDefault: 1000% potion strength or +1000 potion strength in Flat Value Mode.",
    max = 2000,
    min = 100,
    jump = 10,
    variable = EasyMCM:createTableVariable {
        id = "alchemyLimit",
        table = config
    }
}

non:createSlider {
    label = "Alchemy Floor",
    description = "The maximum amount that the player's potion strength can be reduced by. Represented as a whole number.\n\nDefault: 75% potion strength reduction or -75 potion strength in Flat Value Mode.",
    max = 0,
    min = -100,
    variable = EasyMCM:createTableVariable {
        id = "alchemyFloor",
        table = config
    }
}

--Repair Amount--
non:createOnOffButton {
    label = "Affect Repairs",
    description = "Determines whether or not player repair amounts will be affected by difficulty.",
    variable = mwse.mcm.createTableVariable { id = "affectRepair", table = config }
}

non:createSlider {
    label = "Repair Rate",
    description = "Controls the rate at which the player's repair amount is affected by difficulty. \n\nDefault: -0.30% repair amount (or -0.30 repair amount in Flat Value Mode) per difficulty point.",
    max = 20.00,
    min = -20.00,
    step = 0.01,
    jump = 0.10,
    decimalPlaces = 2,
    callback = quickCalc,
    variable = EasyMCM:createTableVariable {
        id = "repairMod",
        table = config
    }
}

non:createSlider {
    label = "Repair Limit",
    description = "The maximum amount that the player's repair amount can be increased by. \n\nDefault: 1000% repair amount or +1000 repair amount in Flat Value Mode.",
    max = 2000,
    min = 100,
    jump = 10,
    variable = EasyMCM:createTableVariable {
        id = "repairLimit",
        table = config
    }
}

non:createSlider {
    label = "Repair Floor",
    description = "The maximum amount that the player's repair amount can be reduced by. Represented as a whole number.\n\nDefault: 75% repair amount reduction or -75 repair amount in Flat Value Mode.",
    max = 0,
    min = -100,
    variable = EasyMCM:createTableVariable {
        id = "repairFloor",
        table = config
    }
}

--Experience--
non:createOnOffButton {
    label = "Affect Experience",
    description = "Determines whether or not skill experience gain will be affected by difficulty. Changing this setting requires a restart to take effect.",
    restartRequired = true,
    variable = mwse.mcm.createTableVariable { id = "affectExperience", table = config }
}

non:createSlider {
    label = "Experience Rate",
    description = "Controls the rate at which the player's skill experience gain is affected by difficulty. \n\nDefault: -0.50% experience gain (or -0.50 experience gain (careful) in Flat Value Mode) per difficulty point.",
    max = 20.00,
    min = -20.00,
    step = 0.01,
    jump = 0.10,
    decimalPlaces = 2,
    callback = quickCalc,
    variable = EasyMCM:createTableVariable {
        id = "expMod",
        table = config
    }
}

non:createSlider {
    label = "Experience Limit",
    description = "The maximum amount that the player's skill experience gain can be increased by. \n\nDefault: 1000% experience gain or +1000 experience in Flat Value Mode.",
    max = 2000,
    min = 100,
    jump = 10,
    variable = EasyMCM:createTableVariable {
        id = "expLimit",
        table = config
    }
}

non:createSlider {
    label = "Experience Floor",
    description = "The maximum amount that the player's skill experience can be reduced by. Represented as a whole number.\n\nDefault: 75% experience reduction or -75 experience in Flat Value Mode.",
    max = 0,
    min = -100,
    variable = EasyMCM:createTableVariable {
        id = "expFloor",
        table = config
    }
}



local npc = createPage("NPC Settings")-------------------------------------------------------------------------------------------------

local dmg2 = npc:createCategory("Melee Settings")

--Damage--
dmg2:createSlider {
    label = "NPC Damage Rate",
    description = "Controls the rate at which an NPC's damage is affected by difficulty. \n\nDefault: Damage Unchanged",
    max = 20.00,
    min = -20.00,
    step = 0.01,
    jump = 0.10,
    decimalPlaces = 2,
    callback = quickCalc,
    variable = EasyMCM:createTableVariable {
        id = "npcDamage",
        table = config
    }
}

dmg2:createSlider {
    label = "NPC Damage Limit",
    description = "The maximum amount that an NPC's damage can be increased by. Represented as a whole number.\n\nDefault: 2000% damage increase or +2000 damage in Flat Value Mode.",
    max = 2000,
    min = 100,
    jump = 10,
    variable = EasyMCM:createTableVariable {
        id = "damageLimitNPC",
        table = config
    }
}

dmg2:createSlider {
    label = "NPC Damage Floor",
    description = "The maximum amount that an NPC's damage can be reduced by. \n\nDefault: 75% damage reduction or -75 damage in Flat Value Mode.",
    max = 0,
    min = -100,
    variable = EasyMCM:createTableVariable {
        id = "damageFloorNPC",
        table = config
    }
}

--Hit Chance--
dmg2:createSlider {
    label = "NPC Hit Rate",
    description = "Controls the rate at which an NPC's melee hit chance is affected by difficulty. \n\nDefault: +0.25% chance (or +0.25 chance in Flat Value Mode) per difficulty point.",
    max = 20.00,
    min = -20.00,
    step = 0.01,
    jump = 0.10,
    decimalPlaces = 2,
    callback = quickCalc,
    variable = EasyMCM:createTableVariable {
        id = "npcHit",
        table = config
    }
}

dmg2:createSlider {
    label = "NPC Hit Limit",
    description = "The maximum amount that an NPC's melee hit chance can be increased by. \n\nDefault: 1000% chance increase or +1000 chance in Flat Value Mode.",
    max = 2000,
    min = 100,
    jump = 10,
    variable = EasyMCM:createTableVariable {
        id = "hitLimitNPC",
        table = config
    }
}

dmg2:createSlider {
    label = "NPC Hit Floor",
    description = "The maximum amount that an NPC's melee hit chance can be reduced by. Represented as a whole number.\n\nDefault: 75% hit chance reduction or -75 hit chance in Flat Value Mode.",
    max = 0,
    min = -100,
    variable = EasyMCM:createTableVariable {
        id = "hitFloorNPC",
        table = config
    }
}


local mgk2 = npc:createCategory("Magic Settings")

--NPC Spell Resist--
mgk2:createSlider {
    label = "NPC Spell Resist Rate",
    description = "Controls the rate at which NPC spell resistance is affected by difficulty. \n\nDefault: +0.50% spell resistance per difficulty point.",
    max = 20.00,
    min = -20.00,
    step = 0.01,
    jump = 0.10,
    decimalPlaces = 2,
    callback = quickCalc,
    variable = EasyMCM:createTableVariable {
        id = "npcResist",
        table = config
    }
}

mgk2:createSlider {
    label = "NPC Spell Resist Limit",
    description = "The maximum amount that NPC spell resistance can be increased by. \n\nDefault: +75% maximum spell resistance increase.",
    max = 2000,
    min = 0,
    jump = 10,
    variable = EasyMCM:createTableVariable {
        id = "resistLimitNPC",
        table = config
    }
}

mgk2:createSlider {
    label = "NPC Spell Resist Floor",
    description = "The maximum amount that NPC spell resistance can be decreased by. \n\nDefault: -2000% maximum spell resistance decrease.",
    max = 0,
    min = -2000,
    variable = EasyMCM:createTableVariable {
        id = "resistFloorNPC",
        table = config
    }
}


local att = npc:createCategory("Attribute Settings")

--Static Mode--
att:createOnOffButton {
    label = "Static Mode",
    description = "Turn on or off Static Mode. In Static Mode, all NPCs/Creatures retain their initial attribute bonuses they gained when they were first met. This does not affect damage scaling.\n\nExample: Fargoth was met at difficulty 10, and given a 20% health bonus. When met again at difficulty 100, Fargoth still retains his 20% bonus rather than increasing to a 200% bonus as he would in normal mode.",
    variable = mwse.mcm.createTableVariable { id = "staticMode", table = config }
}

--Health--
att:createOnOffButton {
    label = "Affect NPC Health",
    description = "Determines whether or not NPC health will be affected by difficulty.",
    variable = mwse.mcm.createTableVariable { id = "affectHealth", table = config }
}

att:createSlider {
    label = "NPC Health Rate",
    description = "Controls the rate at which an NPC's health is affected by difficulty.\n\nIt is best to move cells after making changes. If this does not update health, save and reload.\n\nDefault: +2.5% Health (or +2.5 Health in Flat Value Mode) per difficulty point.",
    max = 20.00,
    min = -20.00,
    step = 0.01,
    jump = 0.10,
    decimalPlaces = 2,
    callback = quickCalc,
    variable = EasyMCM:createTableVariable {
        id = "healthMod",
        table = config
    }
}

att:createSlider {
    label = "NPC Health Limit",
    description = "The maximum amount that an NPC's health can be increased by. Represented as a whole number.\n\nDefault: 2000% health increase or +2000 health in Flat Value Mode.",
    max = 2000,
    min = 100,
    jump = 10,
    variable = EasyMCM:createTableVariable {
        id = "healthLimit",
        table = config
    }
}

att:createSlider {
    label = "NPC Health Floor",
    description = "The maximum amount that an NPC's health can be reduced by. \n\nDefault: 75% health reduction or -75 health in Flat Value Mode.",
    max = 0,
    min = -100,
    variable = EasyMCM:createTableVariable {
        id = "healthFloor",
        table = config
    }
}

--Strength--
att:createOnOffButton {
    label = "Affect NPC Strength",
    description = "Determines whether or not NPC Strength will be affected by difficulty.\n\nAffects NPC weapon damage, carry weight, and maximum fatigue.",
    variable = mwse.mcm.createTableVariable { id = "affectStrength", table = config }
}

att:createSlider {
    label = "NPC Strength Rate",
    description = "Controls the rate at which an NPC's Strength is affected by difficulty.\n\nIt is best to move cells after making changes. If this does not update Strength, save and reload.\n\nDefault: +0.30% Strength (or +0.30 Strength in Flat Value Mode) per difficulty point.",
    max = 20.00,
    min = -20.00,
    step = 0.01,
    jump = 0.10,
    decimalPlaces = 2,
    callback = quickCalc,
    variable = EasyMCM:createTableVariable {
        id = "strengthMod",
        table = config
    }
}

att:createSlider {
    label = "NPC Strength Limit",
    description = "The maximum amount that an NPC's Strength can be increased by. Represented as a whole number.\n\nDefault: 1000% Strength increase or +1000 Strength in Flat Value Mode.",
    max = 2000,
    min = 100,
    jump = 10,
    variable = EasyMCM:createTableVariable {
        id = "strengthLimit",
        table = config
    }
}

att:createSlider {
    label = "NPC Strength Floor",
    description = "The maximum amount that an NPC's Strength can be reduced by. \n\nDefault: 75% Strength reduction or -75 Strength in Flat Value Mode.",
    max = 0,
    min = -100,
    variable = EasyMCM:createTableVariable {
        id = "strengthFloor",
        table = config
    }
}

--Intelligence--
att:createOnOffButton {
    label = "Affect NPC Intelligence",
    description = "Determines whether or not NPC Intelligence will be affected by difficulty.\n\nAffects NPC magicka pools.",
    variable = mwse.mcm.createTableVariable { id = "affectIntelligence", table = config }
}

att:createSlider {
    label = "NPC Intelligence Rate",
    description = "Controls the rate at which an NPC's Intelligence is affected by difficulty.\n\nIt is best to move cells after making changes. If this does not update Intelligence, save and reload.\n\nDefault: +0.30% Intelligence (or +0.30 Intelligence in Flat Value Mode) per difficulty point.",
    max = 20.00,
    min = -20.00,
    step = 0.01,
    jump = 0.10,
    decimalPlaces = 2,
    callback = quickCalc,
    variable = EasyMCM:createTableVariable {
        id = "intelligenceMod",
        table = config
    }
}

att:createSlider {
    label = "NPC Intelligence Limit",
    description = "The maximum amount that an NPC's Intelligence can be increased by. Represented as a whole number.\n\nDefault: 1000% Intelligence increase or +1000 Intelligence in Flat Value Mode.",
    max = 2000,
    min = 100,
    jump = 10,
    variable = EasyMCM:createTableVariable {
        id = "intelligenceLimit",
        table = config
    }
}

att:createSlider {
    label = "NPC Intelligence Floor",
    description = "The maximum amount that an NPC's Intelligence can be reduced by. \n\nDefault: 75% Intelligence reduction or -75 Intelligence in Flat Value Mode.",
    max = 0,
    min = -100,
    variable = EasyMCM:createTableVariable {
        id = "intelligenceFloor",
        table = config
    }
}

--Willpower--
att:createOnOffButton {
    label = "Affect NPC Willpower",
    description = "Determines whether or not NPC Willpower will be affected by difficulty.\n\nAffects NPC cast chance, paralyze/silence resistance, and maximum fatigue.",
    variable = mwse.mcm.createTableVariable { id = "affectWillpower", table = config }
}

att:createSlider {
    label = "NPC Willpower Rate",
    description = "Controls the rate at which an NPC's Willpower is affected by difficulty.\n\nIt is best to move cells after making changes. If this does not update Willpower, save and reload.\n\nDefault: +0.30% Willpower (or +0.30 Willpower in Flat Value Mode) per difficulty point.",
    max = 20.00,
    min = -20.00,
    step = 0.01,
    jump = 0.10,
    decimalPlaces = 2,
    callback = quickCalc,
    variable = EasyMCM:createTableVariable {
        id = "willpowerMod",
        table = config
    }
}

att:createSlider {
    label = "NPC Willpower Limit",
    description = "The maximum amount that an NPC's Willpower can be increased by. Represented as a whole number.\n\nDefault: 1000% Willpower increase or +1000 Willpower in Flat Value Mode.",
    max = 2000,
    min = 100,
    jump = 10,
    variable = EasyMCM:createTableVariable {
        id = "willpowerLimit",
        table = config
    }
}

att:createSlider {
    label = "NPC Willpower Floor",
    description = "The maximum amount that an NPC's Willpower can be reduced by. \n\nDefault: 75% Willpower reduction or -75 Willpower in Flat Value Mode.",
    max = 0,
    min = -100,
    variable = EasyMCM:createTableVariable {
        id = "willpowerFloor",
        table = config
    }
}

--Agility--
att:createOnOffButton {
    label = "Affect NPC Agility",
    description = "Determines whether or not NPC Agility will be affected by difficulty.\n\nAffects weapon hit rate, evasion, resistance to staggering and knock down, and success rate of Sneaking and Blocking. Agility also affects maximum Fatigue.",
    variable = mwse.mcm.createTableVariable { id = "affectAgility", table = config }
}

att:createSlider {
    label = "NPC Agility Rate",
    description = "Controls the rate at which an NPC's Agility is affected by difficulty.\n\nIt is best to move cells after making changes. If this does not update Agility, save and reload.\n\nDefault: +0.30% Agility (or +0.30 Agility in Flat Value Mode) per difficulty point.",
    max = 20.00,
    min = -20.00,
    step = 0.01,
    jump = 0.10,
    decimalPlaces = 2,
    callback = quickCalc,
    variable = EasyMCM:createTableVariable {
        id = "agilityMod",
        table = config
    }
}

att:createSlider {
    label = "NPC Agility Limit",
    description = "The maximum amount that an NPC's Agility can be increased by. Represented as a whole number.\n\nDefault: 1000% Agility increase or +1000 Agility in Flat Value Mode.",
    max = 2000,
    min = 100,
    jump = 10,
    variable = EasyMCM:createTableVariable {
        id = "agilityLimit",
        table = config
    }
}

att:createSlider {
    label = "NPC Agility Floor",
    description = "The maximum amount that an NPC's Agility can be reduced by. \n\nDefault: 75% Agility reduction or -75 Agility in Flat Value Mode.",
    max = 0,
    min = -100,
    variable = EasyMCM:createTableVariable {
        id = "agilityFloor",
        table = config
    }
}

--Speed--
att:createOnOffButton {
    label = "Affect NPC Speed",
    description = "Determines whether or not NPC Speed will be affected by difficulty.\n\nAffects NPC movement speed.",
    variable = mwse.mcm.createTableVariable { id = "affectSpeed", table = config }
}

att:createSlider {
    label = "NPC Speed Rate",
    description = "Controls the rate at which an NPC's Speed is affected by difficulty.\n\nIt is best to move cells after making changes. If this does not update Speed, save and reload.\n\nDefault: +0.30% Speed (or +0.30 Speed in Flat Value Mode) per difficulty point.",
    max = 20.00,
    min = -20.00,
    step = 0.01,
    jump = 0.10,
    decimalPlaces = 2,
    callback = quickCalc,
    variable = EasyMCM:createTableVariable {
        id = "speedMod",
        table = config
    }
}

att:createSlider {
    label = "NPC Speed Limit",
    description = "The maximum amount that an NPC's Speed can be increased by. Represented as a whole number.\n\nDefault: 1000% Speed increase or +1000 Speed in Flat Value Mode.",
    max = 2000,
    min = 100,
    jump = 10,
    variable = EasyMCM:createTableVariable {
        id = "speedLimit",
        table = config
    }
}

att:createSlider {
    label = "NPC Speed Floor",
    description = "The maximum amount that an NPC's Speed can be reduced by. \n\nDefault: 75% Speed reduction or -75 Speed in Flat Value Mode.",
    max = 0,
    min = -100,
    variable = EasyMCM:createTableVariable {
        id = "speedFloor",
        table = config
    }
}

--Endurance--
att:createOnOffButton {
    label = "Affect NPC Endurance",
    description = "Determines whether or not NPC Endurance will be affected by difficulty.\n\nAffects NPC maximum fatigue and fatigue regeneration.",
    variable = mwse.mcm.createTableVariable { id = "affectEndurance", table = config }
}

att:createSlider {
    label = "NPC Endurance Rate",
    description = "Controls the rate at which an NPC's Endurance is affected by difficulty.\n\nIt is best to move cells after making changes. If this does not update Endurance, save and reload.\n\nDefault: +0.30% Endurance (or +0.30 Endurance in Flat Value Mode) per difficulty point.",
    max = 20.00,
    min = -20.00,
    step = 0.01,
    jump = 0.10,
    decimalPlaces = 2,
    callback = quickCalc,
    variable = EasyMCM:createTableVariable {
        id = "enduranceMod",
        table = config
    }
}

att:createSlider {
    label = "NPC Endurance Limit",
    description = "The maximum amount that an NPC's Endurance can be increased by. Represented as a whole number.\n\nDefault: 1000% Endurance increase or +1000 Endurance in Flat Value Mode.",
    max = 2000,
    min = 100,
    jump = 10,
    variable = EasyMCM:createTableVariable {
        id = "enduranceLimit",
        table = config
    }
}

att:createSlider {
    label = "NPC Endurance Floor",
    description = "The maximum amount that an NPC's Endurance can be reduced by. \n\nDefault: 75% Endurance reduction or -75 Endurance in Flat Value Mode.",
    max = 0,
    min = -100,
    variable = EasyMCM:createTableVariable {
        id = "enduranceFloor",
        table = config
    }
}

--Personality--
att:createOnOffButton {
    label = "Affect NPC Personality",
    description = "Determines whether or not NPC Personality will be affected by difficulty.\n\nProbably doesn't affect anything on its own, but included all the same for mods that use NPC personality in calculations.",
    variable = mwse.mcm.createTableVariable { id = "affectPersonality", table = config }
}

att:createSlider {
    label = "NPC Personality Rate",
    description = "Controls the rate at which an NPC's Personality is affected by difficulty.\n\nIt is best to move cells after making changes. If this does not update Personality, save and reload.\n\nDefault: +0.30% Personality (or +0.30 Personality in Flat Value Mode) per difficulty point.",
    max = 20.00,
    min = -20.00,
    step = 0.01,
    jump = 0.10,
    decimalPlaces = 2,
    callback = quickCalc,
    variable = EasyMCM:createTableVariable {
        id = "personalityMod",
        table = config
    }
}

att:createSlider {
    label = "NPC Personality Limit",
    description = "The maximum amount that an NPC's Personality can be increased by. Represented as a whole number.\n\nDefault: 1000% Personality increase or +1000 Personality in Flat Value Mode.",
    max = 2000,
    min = 100,
    jump = 10,
    variable = EasyMCM:createTableVariable {
        id = "personalityLimit",
        table = config
    }
}

att:createSlider {
    label = "NPC Personality Floor",
    description = "The maximum amount that an NPC's Personality can be reduced by. \n\nDefault: 75% Personality reduction or -75 Personality in Flat Value Mode.",
    max = 0,
    min = -100,
    variable = EasyMCM:createTableVariable {
        id = "personalityFloor",
        table = config
    }
}

--Luck--
att:createOnOffButton {
    label = "Affect NPC Luck",
    description = "Determines whether or not NPC Luck will be affected by difficulty.\n\nAffects many things an NPC does in a small way, such as their hit/cast chance.",
    variable = mwse.mcm.createTableVariable { id = "affectLuck", table = config }
}

att:createSlider {
    label = "NPC Luck Rate",
    description = "Controls the rate at which an NPC's Luck is affected by difficulty.\n\nIt is best to move cells after making changes. If this does not update Luck, save and reload.\n\nDefault: +0.30% Luck (or +0.30 Luck in Flat Value Mode) per difficulty point.",
    max = 20.00,
    min = -20.00,
    step = 0.01,
    jump = 0.10,
    decimalPlaces = 2,
    callback = quickCalc,
    variable = EasyMCM:createTableVariable {
        id = "luckMod",
        table = config
    }
}

att:createSlider {
    label = "NPC Luck Limit",
    description = "The maximum amount that an NPC's Luck can be increased by. Represented as a whole number.\n\nDefault: 1000% Luck increase or +1000 Luck in Flat Value Mode.",
    max = 2000,
    min = 100,
    jump = 10,
    variable = EasyMCM:createTableVariable {
        id = "luckLimit",
        table = config
    }
}

att:createSlider {
    label = "NPC Luck Floor",
    description = "The maximum amount that an NPC's Luck can be reduced by. \n\nDefault: 75% Luck reduction or -75 Luck in Flat Value Mode.",
    max = 0,
    min = -100,
    variable = EasyMCM:createTableVariable {
        id = "luckFloor",
        table = config
    }
}


local eco = createPage("Economy Settings")----------------------------------------------------------------------------------------------------------------------------

local tra = eco:createCategory("Training Prices")

--Training Price--
tra:createOnOffButton {
    label = "Affect Training Prices",
    description = "Determines whether or not training prices will be affected by difficulty.",
    variable = mwse.mcm.createTableVariable { id = "affectTrainingPrice", table = config }
}

tra:createSlider {
    label = "Training Price Rate",
    description = "Controls the rate at which training prices are affected by difficulty. \n\nDefault: +1.00% training price increase (or +1.00 price increase in Flat Value Mode) per difficulty point.",
    max = 20.00,
    min = -20.00,
    step = 0.01,
    jump = 0.10,
    decimalPlaces = 2,
    callback = quickCalc,
    variable = EasyMCM:createTableVariable {
        id = "trainingPriceMod",
        table = config
    }
}

tra:createSlider {
    label = "Training Price Limit",
    description = "The maximum amount that training prices can be increased by. \n\nDefault: 1000% price gain or +1000 flat price in Flat Value Mode.",
    max = 2000,
    min = 100,
    jump = 10,
    variable = EasyMCM:createTableVariable {
        id = "trainingPriceLimit",
        table = config
    }
}

tra:createSlider {
    label = "Training Price Floor",
    description = "The maximum amount that training prices can be reduced by. Represented as a whole number.\n\nDefault: 75% price reduction or -75 flat price in Flat Value Mode.",
    max = 0,
    min = -100,
    variable = EasyMCM:createTableVariable {
        id = "trainingPriceFloor",
        table = config
    }
}

local trv = eco:createCategory("Travel Prices")

--Travel Price--
trv:createOnOffButton {
    label = "Affect Travel Prices",
    description = "Determines whether or not travel prices will be affected by difficulty.",
    variable = mwse.mcm.createTableVariable { id = "affectTravelPrice", table = config }
}

trv:createSlider {
    label = "Travel Price Rate",
    description = "Controls the rate at which travel prices are affected by difficulty. \n\nDefault: +1.00% travel price increase (or +1.00 price increase in Flat Value Mode) per difficulty point.",
    max = 20.00,
    min = -20.00,
    step = 0.01,
    jump = 0.10,
    decimalPlaces = 2,
    callback = quickCalc,
    variable = EasyMCM:createTableVariable {
        id = "travelPriceMod",
        table = config
    }
}

trv:createSlider {
    label = "Travel Price Limit",
    description = "The maximum amount that travel prices can be increased by. \n\nDefault: 1000% price gain or +1000 flat price in Flat Value Mode.",
    max = 2000,
    min = 100,
    jump = 10,
    variable = EasyMCM:createTableVariable {
        id = "travelPriceLimit",
        table = config
    }
}

trv:createSlider {
    label = "Travel Price Floor",
    description = "The maximum amount that travel prices can be reduced by. Represented as a whole number.\n\nDefault: 75% price reduction or -75 flat price in Flat Value Mode.",
    max = 0,
    min = -100,
    variable = EasyMCM:createTableVariable {
        id = "travelPriceFloor",
        table = config
    }
}

local rep = eco:createCategory("Repair Prices")

--Repair Price--
rep:createOnOffButton {
    label = "Affect Repair Prices",
    description = "Determines whether or not repair prices will be affected by difficulty.",
    variable = mwse.mcm.createTableVariable { id = "affectRepairPrice", table = config }
}

rep:createSlider {
    label = "Repair Price Rate",
    description = "Controls the rate at which repair prices are affected by difficulty. \n\nDefault: +0.75% repair price increase (or +0.75 price increase in Flat Value Mode) per difficulty point.",
    max = 20.00,
    min = -20.00,
    step = 0.01,
    jump = 0.10,
    decimalPlaces = 2,
    callback = quickCalc,
    variable = EasyMCM:createTableVariable {
        id = "repairPriceMod",
        table = config
    }
}

rep:createSlider {
    label = "Repair Price Limit",
    description = "The maximum amount that repair prices can be increased by. \n\nDefault: 1000% price gain or +1000 flat price in Flat Value Mode.",
    max = 2000,
    min = 100,
    jump = 10,
    variable = EasyMCM:createTableVariable {
        id = "repairPriceLimit",
        table = config
    }
}

rep:createSlider {
    label = "Repair Price Floor",
    description = "The maximum amount that repair prices can be reduced by. Represented as a whole number.\n\nDefault: 75% price reduction or -75 flat price in Flat Value Mode.",
    max = 0,
    min = -100,
    variable = EasyMCM:createTableVariable {
        id = "repairPriceFloor",
        table = config
    }
}

local spe = eco:createCategory("Spellmaking Prices")

--Spellmaking Price--
spe:createOnOffButton {
    label = "Affect Spellmaking Prices",
    description = "Determines whether or not spellmaking prices will be affected by difficulty.",
    variable = mwse.mcm.createTableVariable { id = "affectSpellmakingPrice", table = config }
}

spe:createSlider {
    label = "Spellmaking Price Rate",
    description = "Controls the rate at which spellmaking prices are affected by difficulty. \n\nDefault: +1.00% spellmaking price increase (or +1.00 price increase in Flat Value Mode) per difficulty point.",
    max = 20.00,
    min = -20.00,
    step = 0.01,
    jump = 0.10,
    decimalPlaces = 2,
    callback = quickCalc,
    variable = EasyMCM:createTableVariable {
        id = "spellmakingPriceMod",
        table = config
    }
}

spe:createSlider {
    label = "Spellmaking Price Limit",
    description = "The maximum amount that spellmaking prices can be increased by. \n\nDefault: 1000% price gain or +1000 flat price in Flat Value Mode.",
    max = 2000,
    min = 100,
    jump = 10,
    variable = EasyMCM:createTableVariable {
        id = "spellmakingPriceLimit",
        table = config
    }
}

spe:createSlider {
    label = "Spellmaking Price Floor",
    description = "The maximum amount that spellmaking prices can be reduced by. Represented as a whole number.\n\nDefault: 75% price reduction or -75 flat price in Flat Value Mode.",
    max = 0,
    min = -100,
    variable = EasyMCM:createTableVariable {
        id = "spellmakingPriceFloor",
        table = config
    }
}

local enc = eco:createCategory("Enchanting Prices")

--Enchanting Price--
enc:createOnOffButton {
    label = "Affect Enchanting Prices",
    description = "Determines whether or not Enchanting prices will be affected by difficulty.",
    variable = mwse.mcm.createTableVariable { id = "affectEnchantingPrice", table = config }
}

enc:createSlider {
    label = "Enchanting Price Rate",
    description = "Controls the rate at which Enchanting prices are affected by difficulty. \n\nDefault: +1.00% Enchanting price increase (or +1.00 price increase in Flat Value Mode) per difficulty point.",
    max = 20.00,
    min = -20.00,
    step = 0.01,
    jump = 0.10,
    decimalPlaces = 2,
    callback = quickCalc,
    variable = EasyMCM:createTableVariable {
        id = "enchantingPriceMod",
        table = config
    }
}

enc:createSlider {
    label = "Enchanting Price Limit",
    description = "The maximum amount that Enchanting prices can be increased by. \n\nDefault: 1000% price gain or +1000 flat price in Flat Value Mode.",
    max = 2000,
    min = 100,
    jump = 10,
    variable = EasyMCM:createTableVariable {
        id = "enchantingPriceLimit",
        table = config
    }
}

enc:createSlider {
    label = "Enchanting Price Floor",
    description = "The maximum amount that Enchanting prices can be reduced by. Represented as a whole number.\n\nDefault: 75% price reduction or -75 flat price in Flat Value Mode.",
    max = 0,
    min = -100,
    variable = EasyMCM:createTableVariable {
        id = "enchantingPriceFloor",
        table = config
    }
}



--Blacklists-------------------------------------------------------------------------------------------------
local function getObjects(objType)
    local temp = {}
    for obj in tes3.iterateObjects(objType) do
        temp[obj.id:lower()] = true
    end
    
    local list = {}
    for id in pairs(temp) do
        list[#list+1] = id
    end
    
    table.sort(list)
    return list
end

template:createExclusionsPage({
    label = "Blacklist: NPCs",
    description = "Blacklisted NPCs won't be affected by attribute changes.",
    leftListLabel = "NPC Blacklist",
    rightListLabel = "NPC Whitelist",
    variable = mwse.mcm.createTableVariable{
        id = "blacklistNPC",
        table = config,
    },
    filters = {
        {
            label = "NPCs",
            callback = function() return getObjects(tes3.objectType.npc) end
        },
    },
})

template:createExclusionsPage({
    label = "Blacklist: Creatures",
    description = "Blacklisted creatures won't be affected by attribute changes.",
    leftListLabel = "Creature Blacklist",
    rightListLabel = "Creature Whitelist",
    variable = mwse.mcm.createTableVariable{
        id = "blacklistCreature",
        table = config,
    },
    filters = {
        {
            label = "Creatures",
            callback = function()
                    local baseCreatures = {}
                    for obj in tes3.iterateObjects(tes3.objectType.creature) do
                        if not (obj.baseObject and obj.baseObject.id ~= obj.id ) then
                            baseCreatures[#baseCreatures+1] = (obj.baseObject or obj).id:lower()
                        end
                    end
                    table.sort(baseCreatures)
                    return baseCreatures
                end
        },
    },
})