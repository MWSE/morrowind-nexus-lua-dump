local core = require('openmw.core')
local self = require('openmw.self')
local T = require('openmw.types')

local mDef = require('scripts.skill-evolution.config.definition')
local mS = require('scripts.skill-evolution.config.store')
local mSettings = require('scripts.skill-evolution.config.settings')
local mCore = require('scripts.skill-evolution.util.core')
local mDecay = require('scripts.skill-evolution.skills.decay')
local mHelpers = require('scripts.skill-evolution.util.helpers')
local log = require('scripts.skill-evolution.util.log')

local L = core.l10n(mDef.MOD_NAME)

local cappedSkills = {}
local playerGold
local playerGoldCount = 0
local skillOrder = {}
local Skills = mCore.getSkillRecords()
for i = 1, #Skills do
    skillOrder[Skills[i].id] = i
end

local module = {}

local function getTrainingSkillIds(npc)
    local skills = {}
    for skillId in mHelpers.spairs(mCore.getSkillStats(npc),
            function(t, a, b)
                return t[a].base == t[b].base
                        and skillOrder[a] < skillOrder[b]
                        or t[a].base > t[b].base
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
    for i = 1, #class.majorSkills do
        local skillId = class.majorSkills[i]
        skills.major[skillId] = true
        skills.minMajor = math.min(state.skills.base[skillId], skills.minMajor)
    end
    skills.minor = {}
    skills.minMinor = math.huge
    for i = 1, #class.minorSkills do
        local skillId = class.minorSkills[i]
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
    playerGold = nil
    playerGoldCount = 0
end

module.setTrainingCap = function(state, npc)
    setTrainingState()
    local capTraining = mS.settings.capSkillTraining.get()
    local skills = getClassSkillInfo(state)
    local skillIds = getTrainingSkillIds(npc)
    local messages = {}
    cappedSkills = {}
    for i = 1, #skillIds do
        local skillId = skillIds[i]
        local skill = mCore.getSkillStat(skillId)
        if skill.base < mCore.getSkillStat(skillId, npc).base then
            local msgKey
            if skill.base >= mSettings.getSkillCappedValue(skillId) then
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
                log(string.format("Training cap: player's \"%s\" cap is set", skillId))
                table.insert(messages, L(msgKey, { skill = mCore.getSkillRecord(skillId).name }))
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
        log(string.format("Training cap: player's \"%s\" cap is cleared", skillId))
    end
    cappedSkills = {}
end

module.getSkillCappedMsg = function(skillId)
    return cappedSkills[skillId]
end

module.onSkillTrained = function(state, skillId, skillLevel)
    mDecay.setTrainedSkillId(skillId)

    local range = mS.settings.scaledTrainingDuration.get()
    if range.from == 2 and range.to == 2 then return end

    local timePassed = mDef.logRangeFunctions[mDef.logRangeTypes.scaledTrainingDuration](state.skills.base[skillId], range.from, range.to)
    log(string.format("Training skill \"%s\" took %.2f hours", skillId, timePassed))

    -- pause decay and resume it when the whole time has passed
    mDecay.setIsPaused(true)
    core.sendGlobalEvent(mDef.events.passHours, timePassed - 2)

    self:sendEvent(mDef.events.showMessage, L("trainingDuration", {
        skill = mCore.getSkillRecord(skillId).name,
        level = skillLevel + 1,
        hours = math.floor(timePassed),
        minutes = math.floor(timePassed % 1 * 60)
    }))
end

return module