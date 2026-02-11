local I = require("openmw.interfaces")
local ambient = require('openmw.ambient')
local async = require("openmw.async")
local core = require("openmw.core")
local self = require("openmw.self")
local ui = require("openmw.ui")
local util = require("openmw.util")
local types = require("openmw.types")
local savedTrainerData = {}
local logId

local skillNums = {}

for i, x in ipairs(core.stats.Skill.records) do
    skillNums[x.id] = i
end
local function addActorData(actor, skills)
    savedTrainerData[actor.id] = {
        name = types.NPC.records[actor.recordId].name,
        cell = actor.cell.name,
        skills = skills
    }
end
local function getSkillData(skillName)
    local skillLines = {}
    for index, data in pairs(savedTrainerData) do
        for skillId, skillValue in pairs(data.skills) do
            local skillId = skillValue.name
            if skillId == skillName then
                table.insert(skillLines,
                    {
                        value = skillValue.base,
                        line = data.name ..
                            " in " .. data.cell .. " up to " .. tostring(skillValue.base)
                    })
            else
            end
        end
    end
    table.sort(skillLines, function(a, b) return a.value > b.value end)
    return skillLines
end
local function getSkillBase(skillID, actor)
    return types.NPC.stats.skills[skillID:lower()](actor).base
end

local function sortByValue(lhs, rhs)
    return lhs[2] > rhs[2]
end
local function getSkillForTraining(actor, skill)
    return getSkillBase(skill, actor)
end
local skillOrder
local function tableFind(tbl, value)
    for i, v in ipairs(tbl) do
        if v == value then
            return i
        end
    end
    return nil
end
local function customSort(a, b)
    -- Extract the skill names after the "::" and convert to lowercase
    -- Extract the positions of skills in the 'skillOrder' table
    local positionA = skillNums[a.id]
    local positionB = skillNums[b.id]

    -- If base values are the same, sort by ID (lowest ID wins)
    if a.base == b.base then
        return positionA < positionB
    end

    -- Otherwise, sort by base value (highest base first)
    return a.base > b.base
end

local function getTrainerData(trainer)
    local maxSkills = 3
    local skills = {}

    -- Collect all skills and their values
    for _, skill in pairs(core.stats.Skill.records) do
        local record = core.stats.Skill.record(skill.id)
        local value = types.NPC.stats.skills[skill.id](trainer).base
        table.insert(skills, { id = skill.id, name = record.name, base = value })
    end

    -- Sort all skills based on custom logic
    table.sort(skills, customSort)

    -- Return the top N skills
    local selectedSkills = {}
    for i = 1, maxSkills do
        if skills[i] then
            table.insert(selectedSkills, skills[i])
        end
    end

    return selectedSkills
end
local function addTrainerData(trainer)
    local skills = getTrainerData(trainer)
    addActorData(trainer, skills)
end
local function UiModeChanged(data)
    local newMode = data.newMode
    local target = data.arg
    if newMode == "Training" and target then
        if not savedTrainerData[target.id] then
            addTrainerData(target)
        end
    elseif newMode == "Scroll" and target and target.recordId == logId then
        I.TrainingLogWindow.openTrainingLog()
    end
end
return {
    --I.TrainingLog.getTrainerData(selected)
    interfaceName = "TrainingLog",
    interface = {
        getSkillData = getSkillData,
        getTrainerData = getTrainerData,
        isTrainingData = function (actor)
            return savedTrainerData[actor.id] ~= nil
        end
    },
    eventHandlers = {
        UiModeChanged = UiModeChanged,
        setLogId = function(log)
            logId = log
        end,
    },
    engineHandlers = {
        onSave = function() return { savedTrainerData = savedTrainerData, logId = logId } end,
        onLoad = function(data)
            if not data then return end
            savedTrainerData = data.savedTrainerData
            logId = data.logId
        end,
    }
}
