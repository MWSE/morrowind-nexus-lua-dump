local mod = "Class-Conscious Character Progression"
local version = "2.0.6"
local summary = "CCCP is a radical overhaul of Morrowind's leveling system, using MWSE-lua to implement most features of Galsiah's Character Development."
local onlyChargen = "This value is used only during the mod's initial calculations upon completing chargen. Changing this value after chargen is complete will have no effect."

local config = require("CCCP.config")
local data = require("CCCP.data")

local function createMainPage(template)
    local pageMain = template:createSideBarPage{
        label = "General Settings",
        description =
            mod .. "\n" ..
            "Version " .. version .. "\n" ..
            "\n" ..
            summary .. "\n" ..
            "\n" ..
            "This page contains settings related to attribute and level gains, and miscellaneous settings. Hover over each setting to learn more about it.",
    }

    local categoryAttributes = pageMain:createCategory("Attribute Settings")

    categoryAttributes:createSlider{
        label = "Attribute increase rate",
        description =
            "A universal multiplier applied to the rate of increase of all attributes. The higher this setting, the more total attribute gains you'll receive.\n" ..
            "\n" ..
            "This is a percentage of the \"normal\" rate of increase. So, for example, a value of 50 would see attributes increase at half the normal rate, while a value of 200 would see attributes increase at twice the normal rate.\n" ..
            "\n" ..
            "Technically this is applied to the inverse of the \"increase thresholds\" for the attributes, so a higher value means the threshold for attribute increases will be lower.\n" ..
            "\n" ..
            "At the default value, a perfectly average attribute would have a threshold of 125. (This does not mean that 125 skill increases would be required; the amount of progress made per skillup is modified by the relevant skill factor, and by the skill's \"increase factor.\")\n" ..
            "\n" ..
            onlyChargen .. "\n" ..
            "\n" ..
            "Default: 100",
        variable = mwse.mcm.createTableVariable{
            id = "attributeIncreaseRate",
            table = config,
        },
        min = 1,
        max = 200,
        jump = 10,
        defaultSetting = 100,
    }

    categoryAttributes:createSlider{
        label = "Attribute spread",
        description =
            "Determines how spread out attributes will become.\n" ..
            "\n" ..
            "The higher this value, the more different your starting attributes will be (i.e. the greater the difference between your highest and lowest attribute).\n" ..
            "\n" ..
            "This also affects the rate of increase of attributes. The higher the attribute spread, the greater the difference in attribute increase thresholds, and the more your attributes will tend to spread out over time, with your strong attributes increasing faster than your weaker attributes.\n" ..
            "\n" ..
            onlyChargen .. "\n" ..
            "\n" ..
            "Default: 34",
        variable = mwse.mcm.createTableVariable{
            id = "attributeSpread",
            table = config,
        },
        max = 100,
        defaultSetting = 34,
    }

    categoryAttributes:createSlider{
        label = "Initial skill offset",
        description =
            "Contributes to determining the \"increase factor\" for each skill, which is a multiplier applied to attribute progress on each skill increase and is also influenced by the starting value of each skill.\n" ..
            "\n" ..
            "The higher the offset, the smaller the difference between skills' increase factors, which means the skills' relative influence on attribute gains will be more similar.\n" ..
            "\n" ..
            "This does not affect the actual skill factors, so each skill will still have varying degrees of influence on each attribute depending on the skill's factors. The offset only influences skills' levels of influence relative to each other.\n" ..
            "\n" ..
            onlyChargen .. "\n" ..
            "\n" ..
            "Default: 20",
        variable = mwse.mcm.createTableVariable{
            id = "initialSkillOffset",
            table = config,
        },
        min = -5,
        max = 100,
        defaultSetting = 20,
    }

    categoryAttributes:createSlider{
        label = "Influence of race on starting attributes",
        description =
            "Determines to what extent your starting attributes are determined by your \"racial\" attributes, as opposed to your class, as a percentage.\n" ..
            "\n" ..
            "Racial attributes are vanilla Morrowind's normal starting attributes, determined by race and favored attributes (and any birthsign bonus). Class-based attributes are determined by your initial skills.\n" ..
            "\n" ..
            "At the default value of 50%, starting attributes will be a simple average of racial and class-based attributes.\n" ..
            "\n" ..
            onlyChargen .. "\n" ..
            "\n" ..
            "Default: 50",
        variable = mwse.mcm.createTableVariable{
            id = "racialAttributeStart",
            table = config,
        },
        max = 100,
        defaultSetting = 50,
    }

    categoryAttributes:createSlider{
        label = "Influence of race on attribute gains",
        description =
            "Your race and class both influence how quickly your attributes increase. The higher this setting, the greater influence your race will have on growth rates (technically, attribute increase thresholds) as opposed to your class.\n" ..
            "\n" ..
            "The increase threshold calculation includes a ratio of the racial attribute and your average racial attribute, and this setting acts as a multiplier on that ratio.\n" ..
            "\n" ..
            "This is not a true percentage like the above setting, as class (initial skills) will influence your attribute increase thresholds regardless. But if this is set to 0, racial attributes will have no influence on increase thresholds at all. The higher this is set to, the greater influence the difference in racial attributes will have.\n" ..
            "\n" ..
            onlyChargen .. "\n" ..
            "\n" ..
            "Default: 30",
        variable = mwse.mcm.createTableVariable{
            id = "racialAttributeProgress",
            table = config,
        },
        max = 100,
        defaultSetting = 30,
    }

    categoryAttributes:createSlider{
        label = "Luck increase rate",
        description =
            "Determines the rate of increase of luck as a percentage of the increase rate of other attributes. At the default value, luck will increase 70% as fast as the other attributes, on average.\n" ..
            "\n" ..
            "This setting also modifies any *difference* from 40 in your starting luck. If you choose luck as a favored attribute, which would increase it from 40 to 50, that increase will be modified by this percentage and your actual starting luck will be 47, with the default setting.\n" ..
            "\n" ..
            "This eliminates what would otherwise be an incentive to always pick luck at the beginning, because either way it will only have a percentage of the increase of other attributes.\n" ..
            "\n" ..
            "Default: 70",
        variable = mwse.mcm.createTableVariable{
            id = "luckIncreaseRate",
            table = config,
        },
        max = 200,
        jump = 10,
        defaultSetting = 70,
    }

    local categoryLevel = pageMain:createCategory("Level Settings")

    categoryLevel:createSlider{
        label = "Attribute gains required to gain a level",
        description =
            "With this mod, progress toward levelup is earned by attribute gains, not by skill gains. This setting determines how many attribute gains (not including luck) are required to gain a level.\n" ..
            "\n" ..
            "Default: 6",
        variable = mwse.mcm.createTableVariable{
            id = "attributesToLevel",
            table = config,
        },
        min = 1,
        max = 10,
        jump = 2,
        defaultSetting = 6,
    }

    categoryLevel:createOnOffButton{
        label = "Levelup messages",
        description =
            "If enabled, levelup messages will be displayed when you gain a level, similar to vanilla.\n" ..
            "\n" ..
            "The vanilla messages are included up through level 20, with additional messages (from the mod Level Up Messages) up through level 75.\n" ..
            "\n" ..
            "Default: on",
        variable = mwse.mcm.createTableVariable{
            id = "displayLevelMessages",
            table = config,
        },
        defaultSetting = true,
    }

    local categoryMisc = pageMain:createCategory("Miscellaneous Settings")

    categoryMisc:createOnOffButton{
        label = "Debug mode",
        description =
            "This option enables extensive logging to MWSE.log.\n" ..
            "\n" ..
            "Default: off",
        variable = mwse.mcm.createTableVariable{
            id = "debugMode",
            table = config,
        },
        defaultSetting = false,
    }

    categoryMisc:createButton{
        label = "Reset skill factors to defaults",
        description =
            "Press this button to reset all skill and health factors (on the Skill Factors and Health Factors pages) to their default values.\n" ..
            "\n" ..
            "This will require restarting Morrowind.",
        buttonText = "Reset",
        restartRequired = true,
        callback = function()
            local defaultTable = data.defaultFactors
            config.skillFactors = defaultTable
        end,
    }

    return pageMain
end

local function createHealthPage(template)
    local pageHealth = template:createSideBarPage{
        label = "Health Settings",
        description =
            mod .. "\n" ..
            "Version " .. version .. "\n" ..
            "\n" ..
            summary .. "\n" ..
            "\n" ..
            "This page contains settings related to the mod's health system. (See the Health Factors page for the individual background and in use factors for each skill.) Hover over each setting to learn more about it.",
    }

    pageHealth:createOnOffButton{
        label = "Manage health",
        description =
            "READ THIS FIRST before disabling this setting!\n" ..
            "\n" ..
            "If this setting is disabled, CCCP will not touch max health. Since in vanilla Morrowind max health only changes as part of the vanilla levelup mechanic, and since CCCP bypasses that mechanic, this means that if this setting is disabled, max health will NEVER increase, unless you're using another mod (like MWSE State-Based Health) that manages health without relying on the vanilla levelup mechanic.\n" ..
            "\n" ..
            "DO NOT DISABLE THIS SETTING unless you're using such a mod!\n" ..
            "\n" ..
            "Default: on",
        variable = mwse.mcm.createTableVariable{
            id = "manageHealth",
            table = config,
        },
        defaultSetting = true,
    }

    pageHealth:createSlider{
        label = "Health base",
        description =
            "This is the approximate base (starting) health of an average character.\n" ..
            "\n" ..
            "The health formula ensures that, generally speaking, new characters will have a starting health close to this value, on average. Combat-oriented characters will generally have more, and magic-oriented characters will generally have less.\n" ..
            "\n" ..
            onlyChargen .. "\n" ..
            "\n" ..
            "Default: 50",
        variable = mwse.mcm.createTableVariable{
            id = "healthBase",
            table = config,
        },
        min = 20,
        max = 100,
        defaultSetting = 50,
    }

    pageHealth:createSlider{
        label = "Health bonus",
        description =
            "This setting is a flat bonus applied to the health of all characters, regardless of their race, skills, health factors and endurance.\n" ..
            "\n" ..
            "Note that the health formula takes this value into account in ensuring that an average character will start out with health close to \"Health base.\"\n" ..
            "\n" ..
            "Default: 12",
        variable = mwse.mcm.createTableVariable{
            id = "healthBonus",
            table = config,
        },
        max = 20,
        defaultSetting = 12,
    }

    pageHealth:createSlider{
        label = "Health background multiplier",
        description =
            "A percentage multiplier applied to the health background factor of each skill when that skill increases, which helps determine how much health you gain on skill increase.\n" ..
            "\n" ..
            "Default: 100",
        variable = mwse.mcm.createTableVariable{
            id = "healthBackgroundMult",
            table = config,
        },
        max = 200,
        jump = 10,
        defaultSetting = 100,
    }

    pageHealth:createSlider{
        label = "Health in use multiplier",
        description =
            "A percentage multiplier applied to the health in use factor of each skill when that skill increases (further modified by the starting value of that skill compared to the average), which helps determine how much health you gain on skill increase.\n" ..
            "\n" ..
            "Default: 100",
        variable = mwse.mcm.createTableVariable{
            id = "healthInUseMult",
            table = config,
        },
        max = 200,
        jump = 10,
        defaultSetting = 100,
    }

    pageHealth:createSlider{
        label = "Health in use offset",
        description =
            "Contributes to determining how the in use factors of each skill influence health gains on skill increase.\n" ..
            "\n" ..
            "In addition to the actual in use factors, each skill's starting value will influence how much health increasing that skill will give you, with skills that start higher contributing more to health gains than skills that start lower.\n" ..
            "\n" ..
            "The higher the offset, the less difference there will be between skills regarding how much their initial values influence health gains. The lower the offset, the more important your relative starting skill values become in determining health increases.\n" ..
            "\n" ..
            onlyChargen .. "\n" ..
            "\n" ..
            "Default: 0",
        variable = mwse.mcm.createTableVariable{
            id = "healthInUseOffset",
            table = config,
        },
        min = -5,
        max = 100,
        defaultSetting = 0,
    }

    return pageHealth
end

local function createMagickaPage(template)
    local pageMagicka = template:createSideBarPage{
        label = "Magicka Settings",
        description =
            mod .. "\n" ..
            "Version " .. version .. "\n" ..
            "\n" ..
            summary .. "\n" ..
            "\n" ..
            "This page contains settings related to the mod's magicka system. Hover over each setting to learn more about it.",
    }

    local categoryMax = pageMagicka:createCategory("Max Magicka Settings")

    categoryMax:createOnOffButton{
        label = "Max magicka handling",
        description =
            "This setting can be used to disable the mod's max magicka handling. If turned off, the mod will not change maximum magicka.\n" ..
            "\n" ..
            "It is recommended to restart Morrowind when changing this setting.\n" ..
            "\n" ..
            "Default: on",
        variable = mwse.mcm.createTableVariable{
            id = "maxMagickaHandling",
            table = config,
        },
        defaultSetting = true,
    }

    categoryMax:createSlider{
        label = "Max magicka multiplier",
        description =
            "Acts as a straight percentage multiplier to maximum magicka, after (almost) all of the mod's other magicka calculations.\n" ..
            "\n" ..
            "The default value of 100% will result in an average character having a starting max magicka roughly similar to vanilla, though for magic-focused characters max magicka will rise significantly beyond vanilla values over time.\n" ..
            "\n" ..
            "Note that this is distinct from the vanilla \"magicka multiplier,\" which is affected by the Fortify Maximum Magicka effect and a certain GMST. That vanilla multiplier will (basically) work like normal.\n" ..
            "\n" ..
            "Default: 100",
        variable = mwse.mcm.createTableVariable{
            id = "magMaxMultiplier",
            table = config,
        },
        max = 200,
        jump = 10,
        defaultSetting = 100,
    }

    categoryMax:createSlider{
        label = "Initial magic skill offset for max magicka",
        description =
            "One of the things that contributes to determining your maximum magicka is your starting values in the magic-related skills (those for the six schools of magicka, plus Alchemy and Enchant). The higher these eight skills start out, the higher your max magicka will be.\n" ..
            "\n" ..
            "This setting determines how much influence the starting value of the magic skills will have. The higher the offset, the less difference there will be in terms of max magicka between high and low initial magic skill values.\n" ..
            "\n" ..
            onlyChargen .. "\n" ..
            "\n" ..
            "Default: 0",
        variable = mwse.mcm.createTableVariable{
            id = "magMaxStartOffset",
            table = config,
        },
        min = -40,
        max = 100,
        jump = 10,
        defaultSetting = 0,
    }

    categoryMax:createSlider{
        label = "Max magicka progression",
        description =
            "As you increase your magic-related skills, your maximum magicka will increase. This setting determines the rate of progression of max magicka due to magic skill increases.\n" ..
            "\n" ..
            "Changing this setting will have a retroactive effect the next time your max magicka changes.\n" ..
            "\n" ..
            "Default: 50",
        variable = mwse.mcm.createTableVariable{
            id = "magMaxProgress",
            table = config,
        },
        max = 100,
        defaultSetting = 50,
    }

    categoryMax:createSlider{
        label = "Unaffected magicka",
        description =
            "The portion of a character's starting magicka pool that will not be affected by most of the mod's max magicka calculations. This setting also serves as a minimum max magicka value for even the least magically-inclined characters, subject to the \"max magicka multiplier\" setting.\n" ..
            "\n" ..
            "This portion of the pool will only be affected by intelligence, Fortify Maximum Magicka and the \"max magicka multiplier\" setting. The remainder of the starting magicka pool will be affected by the mod's full calculations.\n" ..
            "\n" ..
            onlyChargen .. "\n" ..
            "\n" ..
            "Default: 20",
        variable = mwse.mcm.createTableVariable{
            id = "magMaxUnaffected",
            table = config,
        },
        max = 25,
        defaultSetting = 20,
    }

    local categoryRegen = pageMagicka:createCategory("Magicka Regen Settings")

    categoryRegen:createOnOffButton{
        label = "Magicka regen",
        description =
            "This setting can be used to disable magicka regen. If turned off, magicka will not regenerate.\n" ..
            "\n" ..
            "Default: on",
        variable = mwse.mcm.createTableVariable{
            id = "magickaRegen",
            table = config,
        },
        defaultSetting = true,
    }

    categoryRegen:createSlider{
        label = "Base magicka regen rate",
        description =
            "A simple modifier to the base rate of magicka regen, as a percentage of the normal rate. The higher this setting, the faster magicka will regenerate.\n" ..
            "\n" ..
            onlyChargen .. "\n" ..
            "\n" ..
            "Default: 100",
        variable = mwse.mcm.createTableVariable{
            id = "magRegenBaseRate",
            table = config,
        },
        max = 200,
        jump = 10,
        defaultSetting = 100,
    }

    categoryRegen:createSlider{
        label = "Initial magic skill offset for magicka regen",
        description =
            "One of the things that contributes to determining how fast your magicka regenerates is your starting values in the magic-related skills. The higher these eight skills start out, the faster your magicka will regenerate.\n" ..
            "\n" ..
            "This setting determines how much influence the starting value of the magic skills will have. The higher the offset, the less difference there will be in terms of magicka regen rate between high and low initial magic skill values.\n" ..
            "\n" ..
            onlyChargen .. "\n" ..
            "\n" ..
            "Default: 0",
        variable = mwse.mcm.createTableVariable{
            id = "magRegenStartOffset",
            table = config,
        },
        min = -40,
        max = 100,
        jump = 10,
        defaultSetting = 0,
    }

    categoryRegen:createSlider{
        label = "Magicka regen progression",
        description =
            "As you increase your magic-related skills, the rate your magicka regenerates will increase. This setting determines the rate of progression of magicka regen rate due to magic skill increases.\n" ..
            "\n" ..
            "Changing this setting will have an immediate effect on regen rate.\n" ..
            "\n" ..
            "Default: 70",
        variable = mwse.mcm.createTableVariable{
            id = "magRegenProgress",
            table = config,
        },
        max = 100,
        defaultSetting = 70,
    }

    categoryRegen:createSlider{
        label = "Neutral willpower value",
        description =
            "Your rate of magicka regeneration is also influenced by your current willpower attribute.\n" ..
            "\n" ..
            "This setting is the willpower value that will result in a \"normal\" magicka regen rate. Magicka will regen faster when your willpower is higher than this value, and slower when your willpower is lower.\n" ..
            "\n" ..
            "Default: 60",
        variable = mwse.mcm.createTableVariable{
            id = "magRegenWilValue",
            table = config,
        },
        max = 100,
        defaultSetting = 60,
    }

    categoryRegen:createSlider{
        label = "Willpower influence on regen rate",
        description =
            "Determines the extent to which willpower influences magicka regen rate.\n" ..
            "\n" ..
            "If this setting were set to 0, willpower would have no influence on regen rate. If set to 100, regen rate would be directly proportional to willpower.\n" ..
            "\n" ..
            "Default: 60",
        variable = mwse.mcm.createTableVariable{
            id = "magRegenWilInfluence",
            table = config,
        },
        max = 100,
        defaultSetting = 60,
    }

    categoryRegen:createSlider{
        label = "Neutral fatigue ratio",
        description =
            "Your fatigue ratio (ratio of current to max fatigue) also affects magicka regen rate.\n" ..
            "\n" ..
            "This setting is the fatigue ratio, as a percentage, that will result in a \"normal\" magicka regen rate. Magicka will regen faster when your fatigue ratio is higher than this value, and slower when your fatigue ratio is lower.\n" ..
            "\n" ..
            "Setting this very low can have pretty crazy results, especially if \"fatigue influence on regen rate\" is set very high.\n" ..
            "\n" ..
            "Default: 80",
        variable = mwse.mcm.createTableVariable{
            id = "magRegenFatValue",
            table = config,
        },
        max = 100,
        defaultSetting = 80,
    }

    categoryRegen:createSlider{
        label = "Fatigue influence on regen rate",
        description =
            "Determines the extent to which fatigue ratio influences magicka regen rate.\n" ..
            "\n" ..
            "If this setting were set to 0, fatigue would have no influence on regen rate. If set to 100, regen rate would be directly proportional to fatigue ratio.\n" ..
            "\n" ..
            "Default: 80",
        variable = mwse.mcm.createTableVariable{
            id = "magRegenFatInfluence",
            table = config,
        },
        max = 100,
        defaultSetting = 80,
    }

    return pageMagicka
end

local function createSlowdownPage(template)
    local pageSlowdown = template:createSideBarPage{
        label = "Slowdown Settings",
        description =
            mod .. "\n" ..
            "Version " .. version .. "\n" ..
            "\n" ..
            summary .. "\n" ..
            "\n" ..
            "This page contains settings related to the mod's skill slowdown system. Hover over each setting to learn more about it.",
    }

    pageSlowdown:createSlider{
        label = "Slowdown start point",
        description =
            "The point at which skill progression can potentially begin to slow down.\n" ..
            "\n" ..
            "This is the base slowdown point used by the mod. A certain amount (which will vary by skill) will be added to this value to determine the actual slowdown point for each skill.\n" ..
            "\n" ..
            "The \"skill uncap\" feature of Morrowind Code Patch is recommended. If that feature is not enabled, skills will not progress beyond 100 regardless of any of this mod's slowdown settings.\n" ..
            "\n" ..
            onlyChargen .. "\n" ..
            "\n" ..
            "Default: 60",
        variable = mwse.mcm.createTableVariable{
            id = "slowdownStart",
            table = config,
        },
        max = 100,
        defaultSetting = 60,
    }

    pageSlowdown:createSlider{
        label = "Slowdown spread",
        description =
            "The actual slowdown point in-game will vary by skill. This setting is the percentage of the initial value of each skill that will be added to the base start point to determine the slowdown point for each skill.\n" ..
            "\n" ..
            "With the default settings, the slowdown point for each skill will be 60 plus 80 percent of the starting value of that skill. With these settings, a skill that starts at 5 will have a slowdown point of 64, while a skill that starts at 45 will have a slowdown point of 96.\n" ..
            "\n" ..
            onlyChargen .. "\n" ..
            "\n" ..
            "Default: 80",
        variable = mwse.mcm.createTableVariable{
            id = "slowdownSpread",
            table = config,
        },
        max = 200,
        jump = 10,
        defaultSetting = 80,
    }

    pageSlowdown:createSlider{
        label = "Slowdown rate",
        description =
            "This setting determines the rate at which skill progression will slow down once a skill reaches its slowdown point.\n" ..
            "\n" ..
            "When a skill reaches its slowdown point, it will start to progress at 1/2 its normal rate. After some additional skill increases, the rate of progression will slow to 1/3 normal, then 1/4, then 1/5, and so on.\n" ..
            "\n" ..
            "The rate at which the divisor (2, 3, 4, 5...) increases is exponential, with the base of the formula (the number being taken to an exponent) derived from this setting. Eventually, progression in the affected skill will become so slow that further increases will be prohibitively time-consuming, and the higher this setting, the earlier that happens.\n" ..
            "\n" ..
            "This setting also affects paid training, with the cost required to train a skill affected by the same multiplier as skill progression. For example, if the progression rate for a skill is 1/3 normal due to skill slowdown, the cost to train that skill will be three times normal.\n" ..
            "\n" ..
            "Setting this value to 100 will result in a very rapid skill slowdown, while setting it to 0 will disable the skill slowdown system. Changing this setting will have an immediate effect on skill progression rates for affected skills.\n" ..
            "\n" ..
            "Default: 35",
        variable = mwse.mcm.createTableVariable{
            id = "slowdownRate",
            table = config,
        },
        max = 100,
        defaultSetting = 35,
    }

    return pageSlowdown
end

local function createFactorPage(template)
    local pageFactor = template:createSideBarPage{
        label = "Skill Factors",
        description =
            mod .. "\n" ..
            "Version " .. version .. "\n" ..
            "\n" ..
            summary .. "\n" ..
            "\n" ..
            "This page allows you to modify skill factors (one per skill for each of the seven main attributes). These factors contribute to determining three things in this mod.\n" ..
            "\n" ..
            "First, and most obviously, they strongly influence how much progress is made toward an increase in each attribute on skillup. For example, the default acrobatics factor for strength is 10, which means that a base 10 points (before being modified by other things) are applied to strength progress each time acrobatics increases. Likewise, 4 points (again modified by other things) are applied to endurance progress, while no progress is made toward intelligence or willpower.\n" ..
            "\n" ..
            "These values also contribute to calculating your starting attributes (or the portion of starting attributes determined by class) and the increase thresholds for the attributes (or how quickly each attribute increases), in combination with initial skill values.\n" ..
            "\n" ..
            "Making radical changes to these values (and especially making significant changes to the total of all factors, or the total for each skill or each attribute) can have unforeseen and likely undesired effects, so tread carefully unless you know what you're doing.",
    }

    for _, configSkill in ipairs(config.skillFactors) do
        local configSkillId = configSkill.skill
        local configSkillFactors = configSkill.factors
        local configSkillName = tes3.skillName[configSkillId]
        local categoryName = string.format("%s Factors", configSkillName)

        local category = pageFactor:createCategory(categoryName)

        for _, currentFactor in ipairs(configSkillFactors) do
            local currentAttributeId = currentFactor.attribute
            local currentAttributeNameLower = tes3.attributeName[currentAttributeId]
            local currentAttributeName = string.gsub(currentAttributeNameLower, "%l", string.upper, 1)
            local sliderLabel = string.format("%s factor", currentAttributeName)

            category:createSlider{
                label = sliderLabel,
                description = string.format("%s factor for %s.", configSkillName, currentAttributeNameLower),
                variable = mwse.mcm.createTableVariable{
                    id = "factor",
                    table = currentFactor,
                },
                max = 30,
            }
        end
    end

    return pageFactor
end

local function createHealthFactorPage(template)
    local pageHealthFactor = template:createSideBarPage{
        label = "Health Factors",
        description =
            mod .. "\n" ..
            "Version " .. version .. "\n" ..
            "\n" ..
            summary .. "\n" ..
            "\n" ..
            "This page allows you to modify health factors for each skill. These factors contribute to determining how much health you start with and how much health you gain on each skill increase.\n" ..
            "\n" ..
            "Each skill has two health factors: a \"background factor\" and an \"in use factor.\" A skill's background factor represents how useful characters will find that skill in avoiding damage in general circumstances, even when the skill is not actively being used. A skill's in use factor represents how useful that skill is in avoiding damage for a character actively using the skill.\n" ..
            "\n" ..
            "A skill's background factor is added to a running points total when the skill increases, which contributes to determining health gains. The skill's in use factor is modified by that skill's relative starting value compared to the average before contributing to the health calculation.",
    }

    for _, configSkill in ipairs(config.skillFactors) do
        local configSkillId = configSkill.skill
        local configSkillName = tes3.skillName[configSkillId]
        local categoryName = string.format("%s Health Factors", configSkillName)

        local category = pageHealthFactor:createCategory(categoryName)

        category:createSlider{
            label = "Background factor",
            description = string.format("Health background factor for %s", configSkillName),
            variable = mwse.mcm.createTableVariable{
                id = "healthBackFactor",
                table = configSkill,
            },
            max = 40,
        }

        category:createSlider{
            label = "In use factor",
            description = string.format("Health in use factor for %s", configSkillName),
            variable = mwse.mcm.createTableVariable{
                id = "healthInUseFactor",
                table = configSkill,
            },
            max = 40,
        }
    end

    return pageHealthFactor
end

local template = mwse.mcm.createTemplate("CCCP")
template:saveOnClose("CCCP", config)

createMainPage(template)
createHealthPage(template)
createMagickaPage(template)
createSlowdownPage(template)
createFactorPage(template)
createHealthFactorPage(template)

mwse.mcm.register(template)