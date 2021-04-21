
local EasyMCM = require("easyMCM.EasyMCM");
local config  = require("talkingMatters.config")

local modName = 'Talking Matters';
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

--[[
local page = template:createSideBarPage({
    label = strings.settings,
  })

  local page = template:createSideBarPage{
    label = "Settings",
    description = "This mod is meant to make the speaking aspect of Morrowind more inmersive. You can set up your preferences here"
}


////////////////// template para generar blacklist /////////////////

https://github.com/MWSE/morrowind-nexus-lua-dump/blob/63b3d0a6004a1088762b46fbbc12b7d11fa61fb7/nexus/Illegal%20Summoning/Illegal%20Summoning-47105-1-1-1566655388/Illegal%20Summoning/MWSE/mods/OperatorJack/IllegalSummoning/mcm.lua


local function createNpcWhitelist(template)
    -- Whitelist Page
    template:createExclusionsPage{
        label = "Blacklist NPCs",
        description = "Blacklisted NPCs won't trigger any of the changes made by this mod, they'll act just as vanilla. It would make the most sense to add companions here, if you don't want them getting irritated by talking too much or things like that.",
        leftListLabel = "Blacklist NPCs",
        rightListLabel = "NPCs",
        variable = mwse.mcm.createTableVariable{
            id = "blacklist",
            table = config,
        },
        filters = {
            {callback = getNPCs},
        },
    }
end

isNpcWhitelisted(e.caster.object.name) -> para buscar cosas en la lista
  config.npcWhitelist[name:lower()]
  ]]

local page = template:createSideBarPage({
    label = "Settings",
    description = "This mod is meant to make the speaking aspect of Morrowind more inmersive. You can set up your preferences here"
})
local settings = page:createCategory("Talking Matters - Settings")

--local enableCategory = settings:createCategory("Toggle mod functions")

settings:createOnOffButton{
    label = "Enable Mod",
    description = "Turn this mod on or off.",
    variable = mwse.mcm.createTableVariable{ id = "modEnabled", table = config }
}

local talkingTime = settings:createCategory("Talking Takes Time")

talkingTime:createOnOffButton{
    label = "Enable passing time in conversation",
    description = "If this feature is enabled, time will advance the amount of minutes you choose per topic in each conversation. The time passed will be advanced when you close the Dialog Menu, and fatigue will be restored at a rate slightly smaller than plain waiting.", --each topic is counted only once
    variable = mwse.mcm.createTableVariable{ id = "advanceTime", table = config }
}

talkingTime:createSlider{
    label = "Amount of minutes x topic",
    description = "Set how much each topic takes, in minutes. \n\nDefault: 3.",
    max = 10,
    min = 1,
    variable = EasyMCM:createTableVariable{
        id = "advanceTime_minutesxtopic",
        table = config
    }
}

talkingTime:createSlider{
    label = "Max conversation time",
    description = "Set the maximum time you can spend in conversation, in hours. \n\nDefault: 2.",
    max = 10,
    min = 1,
    step = 0.5,
    variable = EasyMCM:createTableVariable{
        id = "advanceTime_maxtime",
        table = config
    }
}

local otherFeatures = settings:createCategory("Other Features")

otherFeatures:createOnOffButton{
    label = "Disposition Increase",
    description = "If this feature is enabled there's a chance for a 1pt disposition raise for every topic chosen in a conversation. Player Speechcraft and Luck raise the chances.",
    variable = mwse.mcm.createTableVariable{ id = "dispositionIncrease", table = config }
}

otherFeatures:createOnOffButton{
    label = "Limited Topics",
    description = "If this feature is enabled, NPCs will only be willing to talk to you for a certain amount of time (topics) each day, based on their class, disposition, speechcraft skill, your own skill, your fatigue (nothing personal, but sweaty adventurers aren't nice to talk to). If you reach their limit, they will stop talking to you and you'll lose some disposition, but they'll show signs of it before it happens. ",
    variable = mwse.mcm.createTableVariable{ id = "limitedTopics", table = config }
}

otherFeatures:createSlider{
    label = "Minimum topics",
    description = "This slider defines the minimum amount of daily topics you'll get when you talk to any NPC. Default: 2.",
    max = 10,
    min = 0,
    variable = EasyMCM:createTableVariable{
        id = "minimumTopics",
        table = config
    }
}

otherFeatures:createOnOffButton{
    label = "Persuasion limit - Offense",
    description = "If this feature is enabled, NPCs will only tolerate 3 persuasion failures on a single day, and then they will get offended, making them impossible to talk to for the rest of the day. Failures are counted even if you leave the dialogue menu and come back later. ",
    variable = EasyMCM:createTableVariable{
        id = "persuasionLimit",
        table = config
    }
}

local repetition = settings:createCategory("Have we talked about this, already?")

repetition:createOnOffButton{
    label = "Repetition checking",
    description = [[If this feature is enabled, topics that have already been talked about won't be counted for the daily limit, nor will they train speechcraft or have a chance to increase disposition if those options are on. They will still take up time if that feature is enabled, though.
    
A topic will be considered "new" if the content changes, so things like latest rumors may be considered not repeated if you get e new one.
    
This is counted separately for each NPC, so it doesn't matter if you've already heard a certain piece of info before from someone different, it will be considered "new" if it hasn't been talked with the same person.]],
    variable = mwse.mcm.createTableVariable{ id = "repetition", table = config }
}

repetition:createDropdown({
    label = "Repetition reset",
    description = [[How often does the talked about topics list get refreshed. If you only want "new info" to be valuable to train or increase disposition, you can set it to "never". 
    
Be mindful that the repeated topics list starts counting when you activated the mod.]],
    options = {
        {label = "End of conversation", value = 1},
        {label = "Daily", value = 2},
        {label = "Monthly", value = 3},
        {label = "Never", value = false},
    },

    defaultSetting = 1,
    variable = mwse.mcm.createTableVariable{ id = "repetitionReset", table = config }
})

local learningFeatures = settings:createCategory("Learn by talking")

learningFeatures:createOnOffButton{
    label = "Speechcraft Leveling",
    description = "If this feature is enabled your speechcraft will be trained a little bit for every single topic you speak about (how much exactly depends on the Speechcraft level of the NPC you're talking to and your own intelligence).",
    variable = mwse.mcm.createTableVariable{ id = "speechcraftLeveling", table = config }
}

learningFeatures:createOnOffButton{
    label = "Random Class Related Leveling",
    description = [[If this feature is enabled and your character has a high intelligence (60 or more), speaking about class specific topics with an NPC has a chance of getting you trained a little bit on any of that class major skills.
    
This feature is disabled by default, because it might be inmersion breaking (for example, you have the same chance training your blunt weapon skill as of training your mysticism skill by talking to a priest about the gods) and because it might mess with people who are very careful about their leveling. ]],
    variable = mwse.mcm.createTableVariable{ id = "classLearning", table = config }
}

template:createExclusionsPage{
    label = "Blacklist NPCs",
    description = "Blacklisted NPCs won't trigger any of the changes made by this mod, they'll act just as vanilla. It would make the most sense to add companions here, if you don't want them getting irritated by talking too much or things like that.",
    leftListLabel = "Blacklist NPCs",
    rightListLabel = "NPCs",
    variable = mwse.mcm.createTableVariable{
        id = "blackList",
        table = config,
    },
    filters = {
        {callback = getNPCs},
    },
}