LevelingFramework = {}

LevelingFramework.scriptName = "LevelingFramework"

LevelingFramework.initialConfig = require("custom.LevelingFramework.initialConfig")

local vanillaData = require("custom.LevelingFramework.vanillaData")
LevelingFramework.data = DataManager.loadData(
    LevelingFramework.scriptName,
    vanillaData
)

LevelingFramework.config = DataManager.loadConfiguration(
    LevelingFramework.scriptName,
    LevelingFramework.initialConfig.values,
    LevelingFramework.initialConfig.keyOrder
)
tableHelper.fixNumericalKeys(LevelingFramework.config)

LevelingFramework.cachedClasses = {}


-- Constants
LevelingFramework.SPECIALIZATION_COMBAT = 0
LevelingFramework.SPECIALIZATION_MAGIC = 1
LevelingFramework.SPECIALIZATION_STEALTH = 2


-- Utility
function splitString(str, pattern)
    local r = {}
    for i in string.gmatch(str, pattern) do
        table.insert(r, i)
    end
    return r
end

local splitPattern = "[^%s%p]+"


-- Methods
function LevelingFramework.importESPs()
    if espParser == nil then
        return
    end

    -- Load esp files if necessary
    local loaded = espParser.isLoaded()
    if not loaded then
        espParser.loadFiles()
    end

    -- Parse skills
    LevelingFramework.data.skills = {}
    for _, record in pairs(espParser.getAllRecords("SKIL")) do
        local skill = {}
        local skillName = ""
        for _, subRecord in pairs(record.subRecords) do
            local data = subRecord.data
            if data ~= nil then
                if subRecord.name == "INDX" then
                    skillName = tes3mp.GetSkillName(espParser.getValue(data, "I", 1))
                elseif subRecord.name == "SKDT" then
                    skill.attribute = tes3mp.GetAttributeName(espParser.getValue(data, "I", 1))
                    skill.specialization = espParser.getValue(data, "I", 5)
                end
            end
        end
        LevelingFramework.data.skills[skillName] = skill
    end

    -- Parse classes
    LevelingFramework.data.classes = {}
    for _, record in pairs(espParser.getAllRecords("CLAS")) do
        local class = {}
        local className = ""
        for _, subRecord in pairs(record.subRecords) do
            local data = subRecord.data
            if subRecord.name == "NAME" then
                className = espParser.getValue(data, "s", 1):lower()
            elseif subRecord.name == "CLDT" then
                class.majorAttributes = {
                    tes3mp.GetAttributeName(espParser.getValue(data, "I", 1)),
                    tes3mp.GetAttributeName(espParser.getValue(data, "I", 5)),
                }
                class.specialization = espParser.getValue(data, "I", 9)

                class.minorSkills = {}
                for i = 13, 46, 8 do
                    table.insert(
                        class.minorSkills,
                        tes3mp.GetSkillName(
                            espParser.getValue(data, "I", i)
                        )
                    )
                end

                class.majorSkills = {}
                for i = 17, 50, 8 do
                    table.insert(
                        class.majorSkills,
                        tes3mp.GetSkillName(
                            espParser.getValue(data, "I", i)
                        )
                    )
                end
            end
        end
        LevelingFramework.data.classes[className] = class
    end
    
    -- Clean after if expected
    if not loaded then
        espParser.unloadFiles()
    end

    -- Save freshly loaded classes
    DataManager.saveData(LevelingFramework.scriptName, LevelingFramework.data)
end

function LevelingFramework.getSkill(skillName)
    return LevelingFramework.data.skills[skillName]
end

function LevelingFramework.getClass(pid)
    local accountName = Players[pid].accountName
    if LevelingFramework.cachedClasses[accountName] ~= nil then
        return LevelingFramework.cachedClasses[accountName]
    end

    local player = Players[pid]
    local className = player.data.character.class
    if className == "custom" then
        local class = player.data.customClass
        local niceClass = {}
        niceClass.majorAttributes = splitString(class.majorAttributes, splitPattern)
        niceClass.majorSkills = splitString(class.majorSkills, splitPattern)
        niceClass.minorSkills = splitString(class.minorSkills, splitPattern)
        niceClass.specialization = class.specialization
        niceClass.name = class.name
        niceClass.description = class.description
        LevelingFramework.cachedClasses[accountName] = niceClass
        return niceClass
    else
        return LevelingFramework.data.classes[className]
    end
end


function LevelingFramework.isMajorSkill(class, skillName)
    return tableHelper.containsValue(class.majorSkills, skillName)
end

function LevelingFramework.isMinorSkill(class, skillName)
    return tableHelper.containsValue(class.minorSkills, skillName)
end

function LevelingFramework.isSpecialized(class, skillName)
    return class.specialization == LevelingFramework.getSkill(skillName).specialization
end


function LevelingFramework.progressLevel(pid, skillName, value)
    local class = LevelingFramework.getClass(pid)
    local progressLevel = value
    local progressAttribute = value
    if LevelingFramework.isMajorSkill(class, skillName) then
        progressLevel = progressLevel * LevelingFramework.config.iLevelUpMajorMult
        progressAttribute = progressAttribute * LevelingFramework.config.iLevelUpMajorMultAttribute
    elseif LevelingFramework.isMinorSkill(class, skillName) then
        progressLevel = progressLevel * LevelingFramework.config.iLevelUpMinorMult
        progressAttribute = progressAttribute * LevelingFramework.config.iLevelUpMinorMultAttribute
    else
        progressLevel = 0
        progressAttribute = progressAttribute * LevelingFramework.config.iLevelupMiscMultAttriubte
    end
    progressLevel = math.floor(progressLevel)
    progressAttribute = math.floor(progressAttribute)

    local player = Players[pid]
    local skill = LevelingFramework.getSkill(skillName)
    local attribute = player.data.attributes[skill.attribute]
    attribute.skillIncrease = attribute.skillIncrease + progressAttribute
    player.data.stats.levelProgress = player.data.stats.levelProgress + progressLevel
end

function LevelingFramework.skillProgressRequirement(pid, skillName)
    local class = LevelingFramework.getClass(pid)
    local skillLevel = Players[pid].data.skills[skillName].base
    local requirement = 1 + skillLevel

    if LevelingFramework.isMajorSkill(class, skillName) then
        requirement = requirement * LevelingFramework.config.fMajorSkillBonus
    elseif LevelingFramework.isMinorSkill(class, skillName) then
        requirement = requirement * LevelingFramework.config.fMinorSkillBonus
    else
        requirement = requirement * LevelingFramework.config.fMiscSkillBonus
    end

    if LevelingFramework.isSpecialized(class, skillName) then
        requirement = requirement * LevelingFramework.config.fSpecialSkillBonus
    end

    return math.floor(requirement)
end

function LevelingFramework.increaseSkill(pid, skillName, value, keepProgress)
    local arguments = {
        skillName = skillName,
        value = value,
        keepProgress = keepProgress
    }
    local eventStatus = customEventHooks.triggerValidators(
        "LevelingFramework_OnSkillIncrease",
        {pid, arguments}
    )
    if eventStatus.validDefaultHandler then
        local oldReq, newReq
        local skill = Players[pid].data.skills[arguments.skillName]
        if arguments.keepProgress then
            oldReq = LevelingFramework.skillProgressRequirement(pid, arguments.skillName)
        end

        skill.base = skill.base + arguments.value

        if arguments.keepProgress then
            newReq = LevelingFramework.skillProgressRequirement(pid, arguments.skillName)
            skill.progress = skill.progress * newReq / oldReq
        else
            skill.progress = 0
        end

        LevelingFramework.progressLevel(pid, arguments.skillName, arguments.value)
    end
    customEventHooks.triggerHandlers(
        "LevelingFramework_OnSkillIncrease",
        eventStatus,
        {pid, arguments}
    )
end

function LevelingFramework.progressSkill(pid, skillName, progress, count)
    count = count or 1
    local skill = Players[pid].data.skills[skillName]
    local progressCurrent = skill.progress
    local skillIncrease = 0
    while count > 0 do
        local progressRequirement = LevelingFramework.skillProgressRequirement(pid, skillName)
        local countToLevel = math.ceil( (progressRequirement - progressCurrent) / progress )
        if countToLevel > count then
            skill.progress = progressCurrent + progress * count
            count = 0
        else
            skillIncrease = skillIncrease + 1
            progressCurrent = 0
            count = count - countToLevel
        end
    end
    if skillIncrease > 0 then
        LevelingFramework.increaseSkill(pid, skillName, skillIncrease)
    end
end

-- Hooks

customEventHooks.registerHandler("OnServerPostInit", function()
    if LevelingFramework.config.importESPs then
        LevelingFramework.importESPs()
    end
end)

customEventHooks.registerValidator("LevelingFramework_OnSkillIncrease", function(eventStatus, pid, arguments)
    local skill = Players[pid].data.skills[arguments.skillName]
    if skill.base + arguments.value > LevelingFramework.config.skillCap then
        arguments.value = LevelingFramework.config.skillCap - skill.base
    end
end)
customEventHooks.registerHandler("LevelingFramework_OnSkillIncrease", function(eventStatus, pid, arguments)
    local skill = Players[pid].data.skills[arguments.skillName]
    if skill.base == LevelingFramework.config.skillCap then
        skill.progress = 0
    end
    if arguments.value > 0 and LevelingFramework.config.message.enabled then
        tes3mp.MessageBox(
            pid,
            LevelingFramework.config.message.id,
            string.format(
                LevelingFramework.config.message.text,
                LevelingFramework.config.skillNames[arguments.skillName],
                skill.base
            )
        )
        tes3mp.PlaySpeech(pid, LevelingFramework.config.message.sound)
    end
end)

customCommandHooks.registerCommand("lfimportesps", function(pid, cmd)
    LevelingFramework.importESPs()
    tes3mp.SendMessage(pid, "Imported ESPs!")
end)

return LevelingFramework
