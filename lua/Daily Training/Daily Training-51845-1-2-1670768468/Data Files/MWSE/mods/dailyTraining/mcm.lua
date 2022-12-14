local EasyMCM = require("easyMCM.EasyMCM");
local config  = require("dailyTraining.config")
local logger  = require("logging.logger")
local log     = logger.getLogger("Daily Training")

local modName = 'Daily Training';
local template = EasyMCM.createTemplate { name = modName }
template:saveOnClose(modName, config)
template:register()



local function createPage(label)
    local page = template:createSideBarPage {
        label = label,
        noScroll = false,
    }
    page.sidebar:createInfo {
        text = "                          Daily Training \n\nAllows the player to spend time training instead of wasting time waiting. Training awards a small amount of skill experience per hour trained. Skills cannot be trained beyond 75 by default.\n\nBy default, training has a 24 hour cooldown. Also, the amount of hours the player can train is limited by Endurance for non-magical skills and Willpower for skills that require the use of magic (configurable).\n\nBy default, Magical skills require magicka per hour, armor skills require health per hour, and all other skills require stamina per hour. Training Fatigue can reduce Endurance or Willpower temporarily. There is an optional chance of training being interrupted in dangerous areas.\n\nSkills can be more or less efficient to train based on certain factors. Default Settings: Racial Skill + 15%, Specialization Skill + 25%, Novice Skill(skills below 15) + 50%, Misc Skill - 15%, Endurance/Willpower effects: Up to + 50% or down to - 50%. "
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

local settings = createPage("Settings")


----Global Settings-------------------------------------------------------------------------------------------------------------------------
local cdSettings = settings:createCategory("Cooldown Settings")

cdSettings:createOnOffButton {
    label = "Training Cooldown",
    description = "Turn on or off training cooldown.",
    variable = mwse.mcm.createTableVariable { id = "trainCD", table = config }
}

cdSettings:createOnOffButton {
    label = "Cooldown Reminder Messages",
    description = "Turn on or off training cooldown messages. These messages will notify you when your training cooldown ends.",
    variable = mwse.mcm.createTableVariable { id = "cdMessages", table = config }
}

cdSettings:createSlider {
    label = "Cooldown Time",
    description = "The amount of in-game hours you must wait before training again. 168 hours is equal to one week. Default: 24",
    max = 168,
    min = 1,
    variable = EasyMCM:createTableVariable {
        id = "trainCDtime",
        table = config
    }
}

local streakSettings = settings:createCategory("Streak Settings")

streakSettings:createOnOffButton {
    label = "Training Streak Bonus",
    description = "Turn on or off skill training streak bonus. If this is enabled, you receive an experience bonus equal to one extra hour of training if you train the same skill 3 days in a row each time you train afterward, until the streak is lost. This increases by one extra hour as the streak continues until you reach one year.\n\nStreak will only be active on the first skill trained or the first skill trained after streak is lost.\n\nTier 1 (Three Days): +1 exp per session.\nTier 2 (One week): +2 exp per session.\nTier 3 (One Month): +3 exp per session.\nTier 4 (Six Months): +4 exp per session.\nTier 5 (One Year): +5 exp per session!",
    variable = mwse.mcm.createTableVariable { id = "streakBonus", table = config }
}

streakSettings:createSlider {
    label = "Streak Grace Period",
    description = "The amount of in-game hours that must pass to lose your current training streak. 168 hours is equal to one week. Default: 48",
    max = 336,
    min = 24,
    variable = EasyMCM:createTableVariable {
        id = "gracePeriod",
        table = config
    }
}

local limitSettings = settings:createCategory("Training Limit Settings")

limitSettings:createOnOffButton {
    label = "Skill Training Limit",
    description = "Turn on or off the skill training limit.",
    variable = mwse.mcm.createTableVariable { id = "skillLimit", table = config }
}

limitSettings:createSlider {
    label = "Skill Limit",
    description = "Once a skill reaches this limit, you can no longer train it by practicing this way. Default: 75",
    max = 200,
    min = 1,
    variable = EasyMCM:createTableVariable {
        id = "skillMax",
        table = config
    }
}

limitSettings:createOnOffButton {
    label = "Train in Town",
    description = "If this is turned on, you are allowed to train in areas where resting is illegal. Otherwise, you cannot.",
    variable = mwse.mcm.createTableVariable { id = "townTrain", table = config }
}

limitSettings:createOnOffButton {
    label = "Town Skills",
    description = "Allows town-friendly skills to be trained in town regardless of the 'Train in Town' setting. Town Skills: Acrobatics, Alchemy, Armorer, Athletics, Security, Sneak, Speechcraft, Mercantile.",
    variable = mwse.mcm.createTableVariable { id = "townSkills", table = config }
}

limitSettings:createOnOffButton {
    label = "Training Interruption",
    description = "If this is turned on, you can be interrupted while training in the wilderness and in interiors with hostiles. If a dungeon is cleared of hostiles, it is considered safe.",
    variable = mwse.mcm.createTableVariable { id = "ambush", table = config }
}

limitSettings:createSlider {
    label = "Interruption Chance",
    description = "The chance of being ambushed while training each hour you train.",
    max = 100,
    min = 1,
    variable = EasyMCM:createTableVariable {
        id = "ambushChance",
        table = config
    }
}

limitSettings:createOnOffButton {
    label = "Training Fatigue",
    description = "If this is turned on, Endurance or Willpower will be temporarily drained due to training fatigue. Longer training sessions lead to longer recovery times.",
    variable = mwse.mcm.createTableVariable { id = "skillBurn", table = config }
}

limitSettings:createOnOffButton {
    label = "Session Limits",
    description = "If this is turned on, the amount of hours you are able to train per session is limited by Endurance for non-magical skills and Willpower for magical skills.",
    variable = mwse.mcm.createTableVariable { id = "sessionLimit", table = config }
}

limitSettings:createSlider {
    label = "Endurance Limit",
    description = "Every 10 points of Endurance increases the amount of hours you are able to train in one session by 1/10th of this amount, rounded. Applies to non-magical skills. Default: 5 (5 = 5 hours per session maximum at Endurance 100)",
    max = 10,
    min = 1,
    variable = EasyMCM:createTableVariable {
        id = "endMod",
        table = config
    }
}

limitSettings:createSlider {
    label = "Willpower Limit",
    description = "Every 10 points of Willpower increases the amount of hours you are able to train in one session by 1/10th of this amount, rounded. Applies to magical skills. Default: 5 (5 = 5 hours per session maximum at Willpower 100)",
    max = 10,
    min = 1,
    variable = EasyMCM:createTableVariable {
        id = "wilMod",
        table = config
    }
}

local expSettings = settings:createCategory("Experience Settings")

expSettings:createSlider {
    label = "Experience Ratio",
    description = "This affects the amount of experience gained per hour trained. 1 is very low and 50 is rather high. Default: 6",
    max = 50,
    min = 1,
    variable = EasyMCM:createTableVariable {
        id = "expMod",
        table = config
    }
}

expSettings:createOnOffButton {
    label = "Skill Specialization Bonus",
    description = "If this is turned on, training a skill related to your class specialization rewards +25% experience per hour. Does not stack with streak bonuses.",
    variable = mwse.mcm.createTableVariable { id = "specSkills", table = config }
}

expSettings:createOnOffButton {
    label = "Racial Skill Bonus",
    description = "If this is turned on, training a skill related to your racial skill bonuses rewards +15% experience per hour. Does not stack with streak bonuses.",
    variable = mwse.mcm.createTableVariable { id = "raceBonus", table = config }
}

expSettings:createSlider {
    label = "Novice Skill Bonus",
    description = "Skills below this skill level gain +50% extra experience per hour. Does not stack with streak bonuses. Set to 0 if you don't want novice skill experience bonuses. Default: 15",
    max = 100,
    min = 0,
    variable = EasyMCM:createTableVariable {
        id = "weakSkill",
        table = config
    }
}

expSettings:createOnOffButton {
    label = "Miscellaneous Skill Penalty",
    description = "If this is turned on, training a skill unrelated to your Major or Minor skills incurs a -15% experience per hour penalty. Does not affect streak bonuses.",
    variable = mwse.mcm.createTableVariable { id = "miscPenalty", table = config }
}

expSettings:createOnOffButton {
    label = "Attribute Bonus/Penalty",
    description = "If this is turned on, current Endurance or Willpower will affect experience gain positively if fortified above base or negatively if damaged below base. Increase/Decrease capped at 50%. Does not stack with streak bonuses.",
    variable = mwse.mcm.createTableVariable { id = "attModifier", table = config }
}

local costSettings = settings:createCategory("Cost Settings")

costSettings:createOnOffButton {
    label = "Training Resource Cost",
    description = "If this is turned on, training armor skills requires health, training magical skills requires magicka, and training all other skills requires stamina.",
    variable = mwse.mcm.createTableVariable { id = "trainCost", table = config }
}

costSettings:createSlider {
    label = "Health Multiplier",
    description = "The amount of health per hour required to train armor skills is multiplied by this amount. High level skills cost more health. 1 is very low, 10 is very high. Default: 2",
    max = 10,
    min = 1,
    variable = EasyMCM:createTableVariable {
        id = "costMultH",
        table = config
    }
}

costSettings:createSlider {
    label = "Magicka Multiplier",
    description = "The amount of magicka per hour required to train magical skills is multiplied by this amount. High level skills cost more magicka. 1 is very low, 10 is very high. Default: 3",
    max = 10,
    min = 1,
    variable = EasyMCM:createTableVariable {
        id = "costMultM",
        table = config
    }
}

costSettings:createSlider {
    label = "Stamina Multiplier",
    description = "The amount of stamina per hour required to train non-magical, non-armor skills is multiplied by this amount. High level skills cost more stamina. 1 is very low, 10 is very high. Default: 5",
    max = 10,
    min = 1,
    variable = EasyMCM:createTableVariable {
        id = "costMultF",
        table = config
    }
}


local miscSettings = settings:createCategory("Misc Settings")

miscSettings:createOnOffButton {
    label = "Disable Training Menu Colors",
    description = "If this is turned on, the training menu skill list reverts to default text/selection colors.",
    variable = mwse.mcm.createTableVariable { id = "noColor", table = config }
}

miscSettings:createOnOffButton {
    label = "Enable Sounds",
    description = "Turn off to disable training sound effects.",
    variable = mwse.mcm.createTableVariable { id = "playSound", table = config }
}

miscSettings:createDropdown {
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
