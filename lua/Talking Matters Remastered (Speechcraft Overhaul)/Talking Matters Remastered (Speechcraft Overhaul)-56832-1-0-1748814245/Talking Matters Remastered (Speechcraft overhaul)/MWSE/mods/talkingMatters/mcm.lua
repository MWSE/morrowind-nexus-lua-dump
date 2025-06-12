local EasyMCM = require("easyMCM.EasyMCM");
local config  = require("talkingMatters.config").loaded
local defaultConfig = require("talkingMatters.config").default

local modName = 'Talking Matters Remastered';
local template = EasyMCM.createTemplate(modName)
template:saveOnClose(modName, config)
template:register()

local function getNPCs()
    local temp = {}
    for obj in tes3.iterateObjects(tes3.objectType.npc) do
        temp[obj.name:lower()] = true
    end
    
    local list = {}
    for name in pairs(temp) do
        list[#list+1] = name
    end
    
    table.sort(list)
    return list
end

local page = template:createSideBarPage({
    label = "Settings",
    description = "This mod is meant to make the speaking aspect of Morrowind more inmersive. You can set up your preferences here.",
    showReset = true
})

local settings = page:createCategory("Talking Matters - Settings")

settings:createOnOffButton{
    label = "Enable Mod",
    description = "Turn this mod on or off.",
    defaultSetting = defaultConfig.modEnabled,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{ 
        id = "modEnabled",
        table = config 
    }
}

local talkingTime = page:createCategory("Talking Takes Time")

talkingTime:createOnOffButton{
    label = "Enable passing time in conversation",
    description = "If this feature is enabled, talking will pass the time. The time will be advanced when you close the Dialogue Menu, and fatigue will be restored at a rate slightly smaller than plain waiting.", --each topic is counted only once
    defaultSetting = defaultConfig.advanceTime,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{ 
        id = "advanceTime",
        table = config 
    }
}

talkingTime:createSlider{
    label = "Amount of minutes x topic",
    description = "Set how much each topic takes, in minutes.",
    max = 10,
    min = 1,
    defaultSetting = defaultConfig.advanceTime_minutesxtopic,
    showDefaultSetting = true,
    variable = EasyMCM:createTableVariable{
        id = "advanceTime_minutesxtopic",
        table = config
    }
}

talkingTime:createSlider{
    label = "Max conversation time",
    description = "Set the maximum time you can spend in conversation (as in per time you opened a dialogue with someone), in hours.",
    max = 10,
    min = 1,
    step = 0.5,
    defaultSetting = defaultConfig.advanceTime_maxtime,
    showDefaultSetting = true,
    variable = EasyMCM:createTableVariable{
        id = "advanceTime_maxtime",
        table = config
    }
}

local gettingToKnowYou = page:createCategory("Asking questions is a crucial skill for a good listener")

gettingToKnowYou:createOnOffButton{
    label = "Disposition Increase Through Talking",
    description = "If this feature is enabled there's a chance for a 1pt disposition raise for every topic chosen (every question asked) in a conversation. Player Speechcraft and Luck raise the chances.",
    defaultSetting = defaultConfig.dispositionIncrease,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{ 
        id = "dispositionIncrease",
        table = config
    }
}

local limitedTopicsLabel = page:createCategory("Charisma to hold someone's attention")


limitedTopicsLabel:createOnOffButton{
    label = "Limited Topics (per day)",
    description = "If this feature is enabled, NPCs will only be willing to talk to you for a certain amount of time (amount of topics) each day, based on a variety of variables (yours and their skills, your current fatigue, how much they like you, if you are in the same faction etc.).\n\nIf you reach their limit, they will stop talking to you and you'll lose some disposition, but they'll show signs of it before it happens.\n\nThis will not interfere with dialouge choices or journal entries (if they had something so interesting to say, they will want to talk a bit more).",
    defaultSetting = defaultConfig.limitedTopics,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{ 
        id = "limitedTopics",
        table = config
    }
}

limitedTopicsLabel:createSlider{
    label = "Minimum topics per encounter",
    description = "This slider defines the minimum amount of daily topics you'll get when you talk to any NPC.",
    max = 10,
    min = 0,
    defaultSetting = defaultConfig.minimumTopics,
    showDefaultSetting = true,
    variable = EasyMCM:createTableVariable{
        id = "minimumTopics",
        table = config
    }
}

limitedTopicsLabel:createSlider{
    label = "Friends are more talkative - Disposition limit to be considered a friends",
    description = "If an NPC has this or higher disposition towards the player character, they will consider you a friend and be much more talkative.",
    max = 100,
    min = 70,
    step = 1,
    defaultSetting = defaultConfig.friendDispositionLimit,
    showDefaultSetting = true,
    variable = EasyMCM:createTableVariable{
        id = "friendDispositionLimit",
        table = config
    }
}

limitedTopicsLabel:createOnOffButton{
    label = "Persuasion limit - Offense",
    description = "If this feature is enabled, NPCs will only tolerate a set of persuasion failures on a single day, after which they will get offended, making them impossible to talk to for the rest of the day. Failures are counted even if you leave the dialogue menu and come back later.\n\nAn offended person won't allow you to use their services until the next day. To balance this out a little, succeeding with a persuasion also gives you a few more topics you can ask (the amount is tweakable below)",
    defaultSetting = defaultConfig.persuasionLimit,
    showDefaultSetting = true,
    variable = EasyMCM:createTableVariable{
        id = "persuasionLimit",
        table = config
    }
}

limitedTopicsLabel:createSlider{
    label = "Allowed persuasion failures - Amount of persuasions allowed to fail per day",
    description = "If Persuasion limit is active, this setting will say how many persuasion attempts per NPC you can make before they are offended.",
    defaultSetting = defaultConfig.allowedPersuasionFailures,
    showDefaultSetting = true,
    max = 10,
    min = 1,
    variable = EasyMCM:createTableVariable{
        id = "allowedPersuasionFailures",
        table = config
    }
}

limitedTopicsLabel:createSlider{
    label = "Amount of more topics can be asked about per suceeded persuasion",
    description = "In addition to an increase in disposition, succeeding in a persuasion also gives you more questions you can ask of someone.\n\nThis value does nothing unless both the Limited Topics and Persuasion limit modules are enabled.",
    defaultSetting = defaultConfig.topicsGainedPerPersuasionSuccess,
    showDefaultSetting = true,
    max = 10,
    min = 1,
    variable = EasyMCM:createTableVariable{
        id = "topicsGainedPerPersuasionSuccess",
        table = config
    }
}

local repetitionFeatures = page:createCategory("Have we talked about this before?")

repetitionFeatures:createOnOffButton{
    label = "Repetition checking",
    description = [[If this feature is enabled, when you click a topic, if the NPCs response have already been said by that NPC most features of this mod won't trigger for that topic. 
    
The repeated topic won't be counted for the daily topic limit until the repetition counter is reset (see option below for when to reset the repetition counter), nor will they train speechcraft or have a chance to increase disposition if those options are on. They will still take up time if that feature is enabled, though.
    
A topic will be considered "new" if the content changes, so things like latest rumors may be considered not repeated if you get e new one.
    
This is counted separately for each NPC, so it doesn't matter if you've already heard a certain piece of info before from someone different, it will be considered "new" if it hasn't been talked with the same person.]],
    defaultSetting = defaultConfig.repetition,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{ 
        id = "repetition",
        table = config
    }
}

repetitionFeatures:createDropdown({
    label = "Repetition reset interval",
    description = [[How often does the talked about topics list get refreshed. If you only want "new info" to be valuable to train or increase disposition, you can set it to "never". 
    
Be mindful that the repeated topics list starts counting when you activated the mod.]],
    options = {
        {label = "End of conversation", value = 1},
        {label = "Daily", value = 2},
        {label = "Monthly", value = 3},
        {label = "Never", value = false},
    },
    defaultSetting = defaultConfig.repetitionReset,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{ 
        id = "repetitionReset",
        table = config 
    }
})

local learningFeatures = page:createCategory("Train speechcraft by talking with others")

learningFeatures:createOnOffButton{
    label = "Speechcraft leveling",
    description = "If this feature is enabled your speechcraft will be trained a little bit for every single topic you speak about (how much exactly depends on the Speechcraft level of the NPC you're talking to and your own intelligence).",
    defaultSetting = defaultConfig.speechcraftLeveling,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{ 
        id = "speechcraftLeveling",
        table = config 
    }
}

learningFeatures:createSlider{
    label = "Speech craft training rate (percentage)",
    description = "100 means the default traning rate. At 200 you will train speechcraft twice as much per chosen topic, at 50 half the default rate etc. This value does nothing if Speechcraft Leveling is disabled.",
    min = 25,
    max = 200,
    defaultSetting = defaultConfig.speechcraftTrainingRate,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{ 
        id = "speechcraftTrainingRate",
        table = config
    }
}

local legacyFeatures = page:createCategory("LEGACY - Class based learning from talking with others")

legacyFeatures:createOnOffButton{
    label = "Random Class Related Leveling",
    description = [[Note from rhjelte: When I rewrote Talking Matters it was important that the original intent from sofiaaq (the author of the original Talking Matters) was kept intact, hence this feature is here for those who want it. I (and sofiaaq) don't recommend playing with this setting on as default, but it's there for those who want it. sofiaaq's original description below:
    
If this feature is enabled and your character has a high intelligence (60 or more), speaking about class specific topics with an NPC has a chance of getting you trained a little bit on any of that class major skills.
    
This feature is disabled by default, because it might be inmersion breaking (for example, you have the same chance training your blunt weapon skill as of training your mysticism skill by talking to a priest about the gods) and because it might mess with people who are very careful about their leveling.]],
    defaultSetting = defaultConfig.classLearning,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{ 
        id = "classLearning",
        table = config
    }
}

legacyFeatures:createOnOffButton{
    label = "Random Class Related Leveling - Learn from colleagues?",
    description = "Note from rhjelte: This is my own addition. I am not sure what was the orignial intent, but the code was written in a way where you couldn't learn skills from anyone who was the same class as you. Now here is an option to do so if you want to. With this turned off, your character will only learn from NPCs of OTHER classes than yourself. It's probably way too easy to exploit just going and talking to all character of the same class as you (especially inside the same factions), hence this is turned OFF as default. \n\nBut, should you want a more full roleplay experience, maybe this should also be turned on. The choice is yours. \n\nDefault: Off, even if Random Class Related Leveling is on.",
    defaultSetting = defaultConfig.colleagueLearning,
    variable = mwse.mcm.createTableVariable{ 
        id = "colleagueLearning",
        table = config
    }
}

local debugLabel = page:createCategory("Debug")

debugLabel:createOnOffButton{
    label = "Show Debug Info",
    description ="This toggle posts extra info in the dialogue boxes that exposes how the mod works behind the scenes. Only actual usage is for development purposes (or for the very curious). Most things posted as debug will end up in the log, with just a few things extra being visible in the actual dialogues in-game. \n\nDefault: Off",
    defaultSetting = defaultConfig.debugEnabled,
    variable = mwse.mcm.createTableVariable{ 
        id = "debugEnabled",
        table = config
    }
}

template:createExclusionsPage{
    label = "Blacklist NPCs",
    description = "Blacklisted NPCs will act exactly as vanilla, with the exception that time will pass in conversations with them if that option is turned on. It would make the most sense to add companions here, if you don't want them getting irritated by talking too much or things like that. \n\nThe default config adds all essential NPCs here. I have not tested this mod for a full playthrough and instead of worrying about how it might affect the main quest (both gameplay and immersion-wise) I chose to bypass the involved characters.\n\nIf you prefer to play with all characters acting the same, you can always just remove all the characters from the blacklist. You can easily add all essential NPCs back by pressing the Reset button here on the black list page (but do be warned that the reset will also remove any changes you have done including any custom additions to the blacklist).",
    leftListLabel = "Blacklist NPCs",
    rightListLabel = "NPCs",
    defaultSetting = defaultConfig.blackList,
    showReset = true,
    variable = mwse.mcm.createTableVariable{
        id = "blackList",
        table = config,
    },
    filters = {
        {callback = getNPCs},
    },
}