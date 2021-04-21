local this = {}
local common = require('ngc.common')

local function createBlockCategory(page)
    local category = page:createCategory{
        label = "Block Settings"
    }

    -- Create option to capture hotkey.
    category:createKeyBinder{
        label = "Assign key for Active Blocking Hotkey",
        description = "Use this option to set the hotkey for Active Blocking. Click on the option and follow the prompt.",
        allowCombinations = true,
        variable = mwse.mcm.createTableVariable{
            id = "activeBlockKey",
            table = common.config,
            defaultSetting = {
                keyCode = common.config.activeBlockKey.keyCode,
                isShiftDown = common.config.activeBlockKey.isShiftDown,
                isAltDown = common.config.activeBlockKey.isAltDown,
                isControlDown = common.config.activeBlockKey.isControlDown,
            },
            restartRequired = true
        }
    }

    category:createOnOffButton{
        label = "Use Right Mouse button",
        description = "Allows right mouse button to activate blocking. Note: assigned key above will still work too.",
        variable = mwse.mcm.createTableVariable{
            id = "toggleActiveBlockingMouse2",
            table = common.config
        },
        restartRequired = true
    }

    category:createTextField{
        label = "Minimum fatigue threshold",
        description = "This is the minimum percentage of fatigue you can have before active blocking will not active/turn off. Default: 0.25 or 25%",
        variable = mwse.mcm.createTableVariable{
            id = "activeBlockingFatigueMin",
            table = common.config,
            numbersOnly = true
        },
    }

    category:createTextField{
        label = "Base fatigue drain",
        description = "Base fatigue percentage drain while active blocking. Default: 0.25 or 25%",
        variable = mwse.mcm.createTableVariable{
            id = "activeBlockingFatiguePercentBase",
            table = common.config,
            numbersOnly = true
        },
    }

    -- Create option to capture hotkey.
    category:createKeyBinder{
        label = "Assign key for Non Standard Attack Key",
        description = "If you do not use the standard attack key (Left Mouse click) then you have to set this or some events wont work. Click on the option and follow the prompt.",
        allowCombinations = true,
        variable = mwse.mcm.createTableVariable{
            id = "nonStandardAttackKey",
            table = common.config,
            restartRequired = true
        }
    }
end

local function createFeatureCategory(page)
    local category = page:createCategory{
        label = "Feature Settings"
    }

    -- Toggles
    category:createOnOffButton{
        label = "Toggle Weapon Perks",
        description = "Use this to turn on/off all weapon perks.",
        variable = mwse.mcm.createTableVariable{
            id = "toggleWeaponPerks",
            table = common.config
        }
    }

    category:createOnOffButton{
        label = "Toggle Always Hit",
        description = "Use this to turn on/off always hit feature. This reverts Blind, Sanctuary and Attack Bonus to vanilla functionality.",
        variable = mwse.mcm.createTableVariable{
            id = "toggleAlwaysHit",
            table = common.config
        }
    }

    category:createOnOffButton{
        label = "Toggle Active Blocking",
        description = "Use this to turn on/off the active blocking feature.",
        variable = mwse.mcm.createTableVariable{
            id = "toggleActiveBlocking",
            table = common.config,
            restartRequired = true
        }
    }

    category:createOnOffButton{
        label = "Toggle Hand to Hand Feature",
        description = "Use this to turn on/off the hand to hand feature. This reverts hand to hand to vanilla functionality with no additional perks.",
        variable = mwse.mcm.createTableVariable{
            id = "toggleHandToHandPerks",
            table = common.config,
            restartRequired = true
        }
    }

    category:createOnOffButton{
        label = "Toggle Skill Gain Feature",
        description = "Use this to turn on/off skill experience gain feature. Turn this off if other mods do this.",
        variable = mwse.mcm.createTableVariable{
            id = "toggleSkillGain",
            table = common.config,
            restartRequired = true
        }
    }

    category:createOnOffButton{
        label = "Toggle GMST Balance Feature",
        description = "Use this to turn on/off the balance GMSTs. This allows other mods to control these GMSTs.",
        variable = mwse.mcm.createTableVariable{
            id = "toggleBalanceGMSTs",
            table = common.config,
            restartRequired = true
        }
    }

end

local function createMessageSettings(page)
    local category = page:createCategory{
        label = "Message Settings"
    }

    -- Toggles
    category:createOnOffButton{
        label = "Show messages",
        description = "Turn on/off the standard perk messages.",
        variable = mwse.mcm.createTableVariable{
            id = "showMessages",
            table = common.config
        }
    }

    category:createOnOffButton{
        label = "Show active blocking messages",
        description = "Turn on/off messages that show you when your guard is up or down.",
        variable = mwse.mcm.createTableVariable{
            id = "showActiveBlockMessages",
            table = common.config
        }
    }

    category:createOnOffButton{
        label = "Show extra damage numbers",
        description = "Turn on/off to show the extra damage you are doing with your weapon perks.",
        variable = mwse.mcm.createTableVariable{
            id = "showDamageNumbers",
            table = common.config
        }
    }

    category:createOnOffButton{
        label = "Show debug messages",
        description = "ONLY FOR DEBUGGING. This is a very spammy option that will show all sorts of messages including all damage taken/reduced.",
        variable = mwse.mcm.createTableVariable{
            id = "showDebugMessages",
            table = common.config
        }
    }

    category:createOnOffButton{
        label = "Show skill gain debug messages",
        description = "ONLY FOR DEBUGGING. This shows the experience you gain every time you gain experience for a skill.",
        variable = mwse.mcm.createTableVariable{
            id = "showSkillGainDebugMessages",
            table = common.config
        }
    }
end

local function createGeneralSettings(page)
    local category = page:createCategory{
        label = "General Settings"
    }

    category:createTextField{
        label = "Creature bonus damage modifier",
        description = "The modifier to scale crature bonus damage by strength. Default: 0.3 or 30% at strenth 100.",
        variable = mwse.mcm.createTableVariable{
            id = "creatureBonusModifier",
            table = common.config,
            numbersOnly = true
        },
    }

    category:createTextField{
        label = "Weapon skill damage modifier",
        description = "The modifier to scale damage per weapon skill. Default: 0.2 or 20% at weapon skill 100.",
        variable = mwse.mcm.createTableVariable{
            id = "weaponSkillModifier",
            table = common.config,
            numbersOnly = true
        },
    }

    category:createTextField{
        label = "Attack bonus damage modifier",
        description = "The modifier to scale how much damage attack bonus gives. Default: 0.5 or 50% at attack bonus 100.",
        variable = mwse.mcm.createTableVariable{
            id = "attackBonusModifier",
            table = common.config,
            numbersOnly = true
        },
    }

    category:createTextField{
        label = "Sanctuary reduction modifier",
        description = "The modifier to scale how much sanctuary reduces damage. Default: 0.35 or roughly 15% damage reduction at sanctuary 30 with high Agility and Luck.",
        variable = mwse.mcm.createTableVariable{
            id = "sanctuaryModifier",
            table = common.config,
            numbersOnly = true
        },
    }

    category:createTextField{
        label = "Fatigue reduction modifier",
        description = "The modifier to scale how much low fatigue reduces damage scaling. Default: 0.2 or 20% less damage at zero fatigue.",
        variable = mwse.mcm.createTableVariable{
            id = "fatigueReductionModifier",
            table = common.config,
            numbersOnly = true
        },
    }
end

local function createBaseWeaponPerkSettings(page)
    local category = page:createCategory{
        label = "Base Weapon Perk Settings"
    }

    category:createTextField{
        label = "Execute health threshold",
        description = "The percentage health threshold that will allow execute damage (short blade). Default: 0.25 or 25%",
        variable = mwse.mcm.createTableVariable{
            id = "executeThreshold",
            table = common.config,
            numbersOnly = true
        },
    }

    category:createTextField{
        label = "Multistrike strikes required",
        description = "The number of strikes required to perform a multistrike (long blade) attack. Default: 3",
        variable = mwse.mcm.createTableVariable{
            id = "multistrikeStrikesNeeded",
            table = common.config,
            numbersOnly = true
        },
    }

    category:createTextField{
        label = "Multistrike double strike multiplier",
        description = "Damage multiplier for performing a double strike on a multistrike (long blade) attack. Default: 1 or 100%",
        variable = mwse.mcm.createTableVariable{
            id = "multistrikeBonuseDamageMultiplier",
            table = common.config,
            numbersOnly = true
        },
    }

    category:createTextField{
        label = "Bleed damage multiplier",
        description = "Damage multiplier for bleed damage per stack. Default: 0.35 or 35% of damage per stack",
        variable = mwse.mcm.createTableVariable{
            id = "bleedMultiplier",
            table = common.config,
            numbersOnly = true
        },
    }

    category:createTextField{
        label = "Full draw fatigue drain percent",
        description = "Full draw fatigue drain percent per second. Default: 0.1 or 10%",
        variable = mwse.mcm.createTableVariable{
            id = "fullDrawFatigueDrainPercent",
            table = common.config,
            numbersOnly = true
        },
    }

    category:createTextField{
        label = "Full draw fatigue drain min",
        description = "Full draw fatigue drain minimum percent. Default: 0.2 or 20%",
        variable = mwse.mcm.createTableVariable{
            id = "fullDrawFatigueMin",
            table = common.config,
            numbersOnly = true
        },
    }

    category:createTextField{
        label = "Full draw back speed",
        description = "Movement speed modifier while moving backwards in full draw. Default: 0.3 or 30%",
        variable = mwse.mcm.createTableVariable{
            id = "fullDrawBackSpeedModifier",
            table = common.config,
            numbersOnly = true
        },
    }

    category:createTextField{
        label = "Hamstring modifier",
        description = "The amount hamstring will slow someone down. Default: 0.5 or 50% of normal",
        variable = mwse.mcm.createTableVariable{
            id = "hamstringModifier",
            table = common.config,
            numbersOnly = true
        },
    }

    category:createTextField{
        label = "Bow zoom level",
        description = "Bow zoom level when sneaking and reaching full draw. Default: 2",
        variable = mwse.mcm.createTableVariable{
            id = "bowZoomLevel",
            table = common.config,
            numbersOnly = true
        },
    }

    category:createTextField{
        label = "Crossbow critical range",
        description = "Distance the enemy has to be to do critical damage with crossbow. Default: 800",
        variable = mwse.mcm.createTableVariable{
            id = "crossbowCriticalRange",
            table = common.config,
            numbersOnly = true
        },
    }

    category:createTextField{
        label = "Thrown agility modifier",
        description = "Thrown weapon damage modifier from agility. Default: 0.5 or 0.5% per point of agility",
        variable = mwse.mcm.createTableVariable{
            id = "thrownAgilityModifier",
            table = common.config,
            numbersOnly = true
        },
    }
end

local function createHandToHandPerkSettings(page)
    local category = page:createCategory{
        label = "Base Hand to Hand Perk Settings"
    }

    category:createTextField{
        label = "Base hand to hand minimum damage",
        description = "Minimum base damage for hand to hand. Default: 2",
        variable = mwse.mcm.createTableVariable{
            id = "handToHandBaseDamageMin",
            table = common.config,
            numbersOnly = true
        },
    }

    category:createTextField{
        label = "Base hand to hand maximum damage",
        description = "Maximum base damage for hand to hand. Default: 3",
        variable = mwse.mcm.createTableVariable{
            id = "handToHandBaseDamageMax",
            table = common.config,
            numbersOnly = true
        },
    }

    category:createTextField{
        label = "Minimum modifier for knockdown chance",
        description = "The minimum modifier for knockdown chance when scaled with agility. Default: 0.25 or 25% of the knockdown chance of that tier",
        variable = mwse.mcm.createTableVariable{
            id = "agilityKnockdownChanceMinMod",
            table = common.config,
            numbersOnly = true
        },
    }
end

local function createSkillGainSettings(page)
    local category = page:createCategory{
        label = "Skill Experience Gain Settings"
    }

    category:createTextField{
        label = "Base weapon skill gain modifier",
        description = "The base modifier for all weapon skill gain. Default: 0.6 or 60% of vanilla gain so 40% less than vanilla",
        variable = mwse.mcm.createTableVariable{
            id = "weaponSkillGainBaseModifier",
            table = common.config,
            numbersOnly = true
        },
    }

    category:createTextField{
        label = "Base armor skill gain modifier",
        description = "The base modifier for all armor skill gain. Default: 0.8 or 80% of vanilla gain so 20% less than vanilla",
        variable = mwse.mcm.createTableVariable{
            id = "armorSkillGainBaseModifier",
            table = common.config,
            numbersOnly = true
        },
    }
end

local function createGMSTSettings(page)
    local category = page:createCategory{
        label = "GMST Settings"
    }

    category:createTextField{
        label = "Knockdown chance damage multiplier (iKnockdownMult)",
        description = "The damage multiplier for the vanilla knockdown chance. Default: 0.8",
        variable = mwse.mcm.createTableVariable{
            id = "knockdownMult",
            table = common.config.gmst,
            numbersOnly = true
        },
    }

    category:createTextField{
        label = "Knockdown odds multiplier (iKnockdownOddsMult)",
        description = "The odds of getting a vanilla knockdown on damage. Default: 70",
        variable = mwse.mcm.createTableVariable{
            id = "knockdownOddsMult",
            table = common.config.gmst,
            numbersOnly = true
        },
    }

    category:createTextField{
        label = "Fatigue attack encumberence multiplier (fFatigueAttackMult)",
        description = "GMST for fatigue cost on attack multiplier of encumberence. Default: 0.2. Vanilla: 0",
        variable = mwse.mcm.createTableVariable{
            id = "fatigueAttackMult",
            table = common.config.gmst,
            numbersOnly = true
        },
    }

    category:createTextField{
        label = "Fatigue attack base (fFatigueAttackBase)",
        description = "GMST for fatigue base cost for attacks. Default: 3. Vanilla: 2",
        variable = mwse.mcm.createTableVariable{
            id = "fatigueAttackBase",
            table = common.config.gmst,
            numbersOnly = true
        },
    }

    category:createTextField{
        label = "Weapon fatigue multiplier (fWeaponFatigueMult)",
        description = "GMST for fatigue cost on attack multiplier of weapon weight and attack. Default: 0.5. Vanilla: 0.25",
        variable = mwse.mcm.createTableVariable{
            id = "weaponFatigueMult",
            table = common.config.gmst,
            numbersOnly = true
        },
    }

    category:createTextField{
        label = "Projectile min speed (fProjectileMinSpeed)",
        description = "GMST for min speed of projectiles (arrow/bolt). Default: 560. Vanilla: 400",
        variable = mwse.mcm.createTableVariable{
            id = "projectileMinSpeed",
            table = common.config.gmst,
            numbersOnly = true
        },
    }

    category:createTextField{
        label = "Projectile max speed (fProjectileMaxSpeed)",
        description = "GMST for max speed of projectiles (arrow/bolt). Default: 4000. Vanilla: 3000",
        variable = mwse.mcm.createTableVariable{
            id = "projectileMaxSpeed",
            table = common.config.gmst,
            numbersOnly = true
        },
    }

    category:createTextField{
        label = "Thrown min speed (fThrownWeaponMinSpeed)",
        description = "GMST for min speed of thrown weapons. Default: 360. Vanilla: 300",
        variable = mwse.mcm.createTableVariable{
            id = "thrownWeaponMinSpeed",
            table = common.config.gmst,
            numbersOnly = true
        },
    }

    category:createTextField{
        label = "Thrown max speed (fThrownWeaponMaxSpeed)",
        description = "GMST for max speed of thrown weapons. Default: 1200. Vanilla: 1000",
        variable = mwse.mcm.createTableVariable{
            id = "thrownWeaponMaxSpeed",
            table = common.config.gmst,
            numbersOnly = true
        },
    }
end

local function createWeaponPerkSettings(page, weaponTier)
    local category = page:createCategory{
        label = "General Weapon Tier Settings"
    }
    category:createTextField{
        label = "Weapon skill (min)",
        description = "Weapon skill level that this tier starts at. It is not recommended to modify this but it can be useful if you have an uncapped game and would rather things scale up to level 200 weapon skill for example.",
        variable = mwse.mcm.createTableVariable{
            id = "weaponSkillMin",
            table = common.config[weaponTier],
            numbersOnly = true
        },
    }

    local shortBlade = page:createCategory{
        label = "Short Blade"
    }

    shortBlade:createTextField{
        label = "Critical Strike Chance",
        description = "Chance to perform a critical strike.",
        variable = mwse.mcm.createTableVariable{
            id = "criticalStrikeChance",
            table = common.config[weaponTier],
            numbersOnly = true
        },
    }

    if weaponTier ~= "weaponTier1" then
        shortBlade:createTextField{
            label = "Execute damage multiplier",
            description = "The multiplier for execute damage when enemy is below health threshold.",
            variable = mwse.mcm.createTableVariable{
                id = "executeDamageMultiplier",
                table = common.config[weaponTier],
                numbersOnly = true
            },
        }
    end

    local longBlade = page:createCategory{
        label = "Long Blade"
    }

    longBlade:createTextField{
        label = "Multistrike damage multiplier",
        description = "Damage multiplier for a multistrike.",
        variable = mwse.mcm.createTableVariable{
            id = "multistrikeDamageMultiplier",
            table = common.config[weaponTier],
            numbersOnly = true
        },
    }

    if weaponTier ~= "weaponTier1" then
        longBlade:createTextField{
            label = "Multistrike double strike chance",
            description = "Chance to perform a double damage strike on a multistrike.",
            variable = mwse.mcm.createTableVariable{
                id = "multistrikeBonusChance",
                table = common.config[weaponTier],
                numbersOnly = true
            },
        }
    end

    local axe = page:createCategory{
        label = "Axe"
    }

    axe:createTextField{
        label = "Bleed chance",
        description = "Chance to perform a bleed",
        variable = mwse.mcm.createTableVariable{
            id = "bleedChance",
            table = common.config[weaponTier],
            numbersOnly = true
        },
    }

    if weaponTier ~= "weaponTier1" then
        axe:createTextField{
            label = "Max bleed stacks",
            description = "Maximum number of bleed stacks",
            variable = mwse.mcm.createTableVariable{
                id = "maxBleedStack",
                table = common.config[weaponTier],
                numbersOnly = true
            },
        }
    end

    local bluntWeapon = page:createCategory{
        label = "Blunt Weapon (maces/staves)"
    }

    bluntWeapon:createTextField{
        label = "Stun chance",
        description = "Chance to stun for 1 second",
        variable = mwse.mcm.createTableVariable{
            id = "stunChance",
            table = common.config[weaponTier],
            numbersOnly = true
        },
    }

    if weaponTier ~= "weaponTier1" then
        bluntWeapon:createTextField{
            label = "Armor damage multiplier (mace only)",
            description = "The multiplier for each pointer of armor rating the enemy has",
            variable = mwse.mcm.createTableVariable{
                id = "bonusArmorDamageMultiplier",
                table = common.config[weaponTier],
                numbersOnly = true
            },
        }
    end

    local spear = page:createCategory{
        label = "Spear"
    }

    spear:createTextField{
        label = "Bonus damage for fatigue (momentum)",
        description = "This is the bonus damage if you have momentum (have higher fatigue percentange than your enemy.",
        variable = mwse.mcm.createTableVariable{
            id = "bonusDamageForFatigueMultiplier",
            table = common.config[weaponTier],
            numbersOnly = true
        },
    }

    if weaponTier ~= "weaponTier1" then
        spear:createTextField{
            label = "Adrenaline Rush chance",
            description = "Chance on each hit to gain Adrenaline Rush (fatigue restore).",
            variable = mwse.mcm.createTableVariable{
                id = "adrenalineRushChance",
                table = common.config[weaponTier],
                numbersOnly = true
            },
        }
    end

    local handToHand = page:createCategory{
        label = "Hand to Hand"
    }

    handToHand:createTextField{
        label = "Hand to hand minimum damage",
        description = "Minimum damage roll for hand to hand in this tier",
        variable = mwse.mcm.createTableVariable{
            id = "handToHandBaseDamageMin",
            table = common.config[weaponTier],
            numbersOnly = true
        },
    }

    handToHand:createTextField{
        label = "Hand to hand maximum damage",
        description = "Maximum damage roll for hand to hand in this tier",
        variable = mwse.mcm.createTableVariable{
            id = "handToHandBaseDamageMax",
            table = common.config[weaponTier],
            numbersOnly = true
        },
    }

    handToHand:createTextField{
        label = "Hand to hand knockdown chance",
        description = "Chance to perform a knockdown on hit",
        variable = mwse.mcm.createTableVariable{
            id = "handToHandKnockdownChance",
            table = common.config[weaponTier],
            numbersOnly = true
        },
    }

    handToHand:createTextField{
        label = "Hand to hand knockdown damage multiplier",
        description = "Damage multiplier for any damage when enemy is knockedown",
        variable = mwse.mcm.createTableVariable{
            id = "handToHandKnockdownDamageMultiplier",
            table = common.config[weaponTier],
            numbersOnly = true
        },
    }

    local bow = page:createCategory{
        label = "Bow"
    }

    bow:createTextField{
        label = "Full draw multiplier",
        description = "Damage multiplier for when you full draw a weapon (player only)",
        variable = mwse.mcm.createTableVariable{
            id = "bowFullDrawMultiplier",
            table = common.config[weaponTier],
            numbersOnly = true
        },
    }

    bow:createTextField{
        label = "NPC draw multiplier",
        description = "Damage multiplier for NPC full draw (this is applied on every NPC hit basically so just make it about 1/3 of player full draw)",
        variable = mwse.mcm.createTableVariable{
            id = "bowNPCDrawMultiplier",
            table = common.config[weaponTier],
            numbersOnly = true
        },
    }

    if weaponTier ~= "weaponTier1" then
        bow:createTextField{
            label = "Hamstring chance",
            description = "Chance to cause hamstring on hit.",
            variable = mwse.mcm.createTableVariable{
                id = "hamstringChance",
                table = common.config[weaponTier],
                numbersOnly = true
            },
        }
    end

    local crossbow = page:createCategory{
        label = "Crossbow"
    }

    crossbow:createTextField{
        label = "Critical damage multiplier",
        description = "Damage multiplier for when you are in critical range (see general perk settings).",
        variable = mwse.mcm.createTableVariable{
            id = "crossbowCriticalDamageMultiplier",
            table = common.config[weaponTier],
            numbersOnly = true
        },
    }

    if weaponTier ~= "weaponTier1" then
        crossbow:createTextField{
            label = "Repeater chance",
            description = "Chance on fire to get an instant reload on next shot.",
            variable = mwse.mcm.createTableVariable{
                id = "repeaterChance",
                table = common.config[weaponTier],
                numbersOnly = true
            },
        }
    end

    local thrown = page:createCategory{
        label = "Thrown Weapon"
    }

    thrown:createTextField{
        label = "Critical strike chance (thrown)",
        description = "Critical strike chance for thrown weapons.",
        variable = mwse.mcm.createTableVariable{
            id = "thrownCriticalStrikeChance",
            table = common.config[weaponTier],
            numbersOnly = true
        },
    }

    if weaponTier ~= "weaponTier1" then
        thrown:createTextField{
            label = "Chance to recover (thrown)",
            description = "Chance to recover projectile on hit for thrown eapons.",
            variable = mwse.mcm.createTableVariable{
                id = "thrownChanceToRecover",
                table = common.config[weaponTier],
                numbersOnly = true
            },
        }
    end

    local block = page:createCategory{
        label = "Block"
    }

    block:createTextField{
        label = "Block fatigue drain",
        description = "Fatigue percentage drain while active blocking",
        variable = mwse.mcm.createTableVariable{
            id = "activeBlockingFatiguePercent",
            table = common.config[weaponTier],
            numbersOnly = true
        },
    }

    local skillGain = page:createCategory{
        label = "Skill Gain"
    }

    skillGain:createTextField{
        label = "Weapon skill gain modifier",
        description = "Modifier for weapon skill experience gain per tier",
        variable = mwse.mcm.createTableVariable{
            id = "weaponSkillGainModifier",
            table = common.config[weaponTier],
            numbersOnly = true
        },
    }
end

local function isTable(t)
    return type(t) == "table"
end

local function isString(t)
    return type(t) == "string"
end

local function cleanUpConfig()
    for k, v in pairs(common.config) do
        if not isTable(v) then
            if isString(v) then
                common.config[k] = tonumber(v)
            end
        else
            for nestedK, nestedV in pairs(common.config[k]) do
                if isString(nestedV) then
                    common.config[k][nestedK] = tonumber(nestedV)
                end
            end
        end
    end
end

-- Handle mod config menu.
function this.registerModConfig()
    mwse.log("Registering MCM")
    local template = mwse.mcm.createTemplate("Next Generation Combat")
    template.onClose = function()
        cleanUpConfig()
        mwse.saveConfig("ngc", common.config)
    end

    --[[
        General settings
    ]]--
    local page = template:createSideBarPage{
        label = "Settings",
        description = "Toggle and configure features."
    }

    createFeatureCategory(page)
    createBlockCategory(page)
    createMessageSettings(page)
    createGeneralSettings(page)
    createBaseWeaponPerkSettings(page)
    createHandToHandPerkSettings(page)
    createSkillGainSettings(page)
    createGMSTSettings(page)

    --[[
        Weapon tier settings
    ]]--
    local weaponTier1Page = template:createSideBarPage{
        label = "Perks (Apprentice)",
        description = "Perk settings for Apprentice weapon tier (>25 skill)."
    }
    createWeaponPerkSettings(weaponTier1Page, "weaponTier1")

    local weaponTier2Page = template:createSideBarPage{
        label = "Perks (Journeyman)",
        description = "Perk settings for Journeyman weapon tier (>50 skill)."
    }
    createWeaponPerkSettings(weaponTier2Page, "weaponTier2")

    local weaponTier3Page = template:createSideBarPage{
        label = "Perks (Expert)",
        description = "Perk settings for Expert weapon tier (>75 skill)."
    }
    createWeaponPerkSettings(weaponTier3Page, "weaponTier3")

    local weaponTier4Page = template:createSideBarPage{
        label = "Perks (Master)",
        description = "Perk settings for Master weapon tier (>100 skill)."
    }
    createWeaponPerkSettings(weaponTier4Page, "weaponTier4")

    mwse.mcm.register(template)
end

return this