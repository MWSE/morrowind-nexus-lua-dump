local core = require('openmw.core')
local self = require('openmw.self')
local T = require('openmw.types')

local log = require('scripts.skill-evolution.util.log')
local mDef = require('scripts.skill-evolution.config.definition')
local mH = require('scripts.skill-evolution.util.helpers')

local Skills = core.stats.Skill.records
local L = core.l10n(mDef.MOD_NAME)

local skillOrder = {}
for i, skill in ipairs(Skills) do
    skillOrder[skill.id] = i
end

local module = {
    originalTrainingSkills = {}
}

local function getTrainingSkillIds(npc)
    local skills = {}
    for skillId in mH.spairs(T.NPC.stats.skills,
            function(t, a, b)
                return t[a](npc).base == t[b](npc).base
                        and skillOrder[a] < skillOrder[b]
                        or t[a](npc).base > t[b](npc).base
            end) do
        table.insert(skills, skillId)
        if #skills == 3 then
            return skills
        end
    end
end

local function getClassSkillInfo(state)
    local skills = {}
    local class = T.NPC.classes.record(self.type.record(self).class)
    skills.major = {}
    skills.minMajor = math.huge
    for _, skillId in ipairs(class.majorSkills) do
        skills.major[skillId] = true
        skills.minMajor = math.min(state.skills.base[skillId], skills.minMajor)
    end
    skills.minor = {}
    skills.minMinor = math.huge
    for _, skillId in ipairs(class.minorSkills) do
        skills.minor[skillId] = true
        skills.minMinor = math.min(state.skills.base[skillId], skills.minMinor)
    end
    return skills
end

module.capTrainedSkills = function(state, npc)
    local skills = getClassSkillInfo(state)
    local skillIds = getTrainingSkillIds(npc)
    local messages = {}
    module.originalTrainingSkills = {}
    for _, skillId in ipairs(skillIds) do
        local skill = T.NPC.stats.skills[skillId]
        if skill(self).base < skill(npc).base then
            local msgKey
            if skills.minor[skillId] then
                if state.skills.base[skillId] >= skills.minMajor then
                    msgKey = "skillTrainingCapMinor"
                end
            elseif not skills.major[skillId] and state.skills.base[skillId] >= skills.minMinor then
                msgKey = "skillTrainingCapMisc"
            end
            if msgKey then
                module.originalTrainingSkills[skillId] = skill(self).base
                log(string.format("Training cap: Player's \"%s\" buffed %d -> %d", skillId, skill(self).base, skill(npc).base))
                skill(self).base = skill(npc).base
                table.insert(messages, L(msgKey, { skill = Skills[skillId].name }))
            end
        end
    end
    if #messages > 0 and (not state.lastTrainer or state.lastTrainer.id ~= npc.id) then
        state.lastTrainer = npc
        self:sendEvent(mDef.events.showMessage, table.concat(messages, "\n"))
    end
end

module.uncapTrainedSkills = function()
    for skillId, value in pairs(module.originalTrainingSkills) do
        log(string.format("Training cap: Player's \"%s\" restored %d -> %d", skillId, T.NPC.stats.skills[skillId](self).base, value))
        T.NPC.stats.skills[skillId](self).base = value
    end
    module.originalTrainingSkills = {}
end

return module