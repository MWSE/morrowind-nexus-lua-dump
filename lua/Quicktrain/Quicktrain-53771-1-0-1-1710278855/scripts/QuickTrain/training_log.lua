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
local function addActorData(actor, skills)
    savedTrainerData[actor.id] = {
        name = types.NPC.record(actor).name,
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

    -- Get the positions of skills in the 'skillOrder' table
    local positionA = tableFind(skillOrder, a.id)
    local positionB = tableFind(skillOrder, b.id)

    -- If either skill is not found in 'skillOrder' table, use alphabetical order
    if not positionA then
        positionA = string.lower(skillA)
    end

    if not positionB then
        positionB = string.lower(skillB)
    end

    -- If base values are the same, sort by ID
    if a.base == b.base then
        return positionA < positionB
    end

    return a.base > b.base
end

local function getTrainerData(trainer)
    local maxSkills = 3
    local skills = {}
    local skillRecords = {}
    skillOrder = {}
    for index, skill in pairs(core.stats.Skill.records) do
        table.insert(skillRecords,skill.id)
        table.insert(skillOrder,skill.id)
    end
    table.sort(skillRecords)
    for index, skill in pairs(skillRecords) do
        local record = core.stats.Skill.record(skill)
        local value = types.NPC.stats.skills[skill](trainer).base

        if #skills < maxSkills then
            table.insert(skills, { id = skill,name = record.name, base = value })
            table.sort(skills, customSort)
        else
            local lowest = skills[maxSkills]
            if lowest.base < value then
                skills[maxSkills].id = skill
                skills[maxSkills].base = value
                skills[maxSkills].name = record.name
                table.sort(skills, customSort)
            end
        end
    end
    return skills
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

    interfaceName = "TrainingLog",
    interface = {

        getSkillData = getSkillData,
        getTrainerData = getTrainerData
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
