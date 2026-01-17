local core = require('openmw.core')
local self = require('openmw.self')
local T = require('openmw.types')

local log = require('scripts.skill-evolution.util.log')
local mDef = require('scripts.skill-evolution.config.definition')
local mS = require('scripts.skill-evolution.config.settings')
local mCore = require('scripts.skill-evolution.util.core')
local mH = require('scripts.skill-evolution.util.helpers')

local Skills = core.stats.Skill.records
local L = core.l10n(mDef.MOD_NAME)

local cappedSkills = {}
local playerGold
local playerGoldCount = 0
local skillOrder = {}
for i, skill in ipairs(Skills) do
    skillOrder[skill.id] = i
end

local module = {}

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

local function setTrainingState()
    playerGold = mCore.getPlayerGold()
    playerGoldCount = playerGold and playerGold.count or 0
end

module.restoreTrainingState = function()
    if not playerGold then return end
    local goldDiff = playerGoldCount - playerGold.count
    if goldDiff > 0 then
        core.sendGlobalEvent(mDef.events.addObject, { player = self, recordId = "gold_001", count = goldDiff })
    end
    core.sendGlobalEvent(mDef.events.skipGameHours, { player = self, hours = -2 })
    playerGold = nil
    playerGoldCount = 0
end

module.setTrainingCap = function(state, npc)
    setTrainingState()
    local capTraining = mS.skillsStorage:get("capSkillTraining")
    local skills = getClassSkillInfo(state)
    local skillIds = getTrainingSkillIds(npc)
    local messages = {}
    cappedSkills = {}
    for _, skillId in ipairs(skillIds) do
        local skill = T.NPC.stats.skills[skillId]
        if skill(self).base < skill(npc).base then
            local msgKey
            if skill(self).base >= mS.getSkillMaxValue(skillId) then
                msgKey = "skillTrainingCap"
            elseif capTraining then
                if skills.minor[skillId] then
                    if state.skills.base[skillId] >= skills.minMajor then
                        msgKey = "skillTrainingCapMinor"
                    end
                elseif not skills.major[skillId] and state.skills.base[skillId] >= skills.minMinor then
                    msgKey = "skillTrainingCapMisc"
                end
            end
            if msgKey then
                cappedSkills[skillId] = msgKey
                log(string.format("Training cap: Player's \"%s\" cap is set", skillId))
                table.insert(messages, L(msgKey, { skill = Skills[skillId].name }))
            end
        end
    end
    if #messages > 0 and (not state.lastTrainer or state.lastTrainer.id ~= npc.id) then
        state.lastTrainer = npc
        self:sendEvent(mDef.events.showMessage, table.concat(messages, "\n"))
    end
end

module.clearTrainingCap = function()
    for skillId in pairs(cappedSkills) do
        log(string.format("Training cap: Player's \"%s\" cap is cleared", skillId))
    end
    cappedSkills = {}
end

module.getSkillCappedMsg = function(skillId)
    return cappedSkills[skillId]
end

return module