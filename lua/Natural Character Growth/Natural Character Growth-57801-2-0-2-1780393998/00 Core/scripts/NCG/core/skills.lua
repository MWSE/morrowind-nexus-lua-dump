local core = require('openmw.core')
local self = require('openmw.self')
local T = require('openmw.types')
local I = require('openmw.interfaces')

local mDef = require('scripts.NCG.config.definition')
local mCfg = require('scripts.NCG.config.configuration')
local mS = require('scripts.NCG.config.store')
local mHelpers = require('scripts.NCG.util.helpers')

local L = core.l10n(mDef.MOD_NAME)
local skillStatsCache
local customSkillCompletedDescriptions = {}

local module = {}

module.getStat = function(skillId)
    return module.getStats()[skillId]
end

module.getStats = function()
    if skillStatsCache then
        return skillStatsCache
    end
    local skills = {}
    for skillId, getter in pairs(T.NPC.stats.skills) do
        skills[skillId] = getter(self)
    end
    if I.SkillFramework then
        for skillId in pairs(I.SkillFramework.getSkillRecords()) do
            skills[skillId] = I.SkillFramework.getSkillStat(skillId)
        end
    end
    skillStatsCache = skills
    return skills
end

module.addHandlers = function()
    -- Wait the next frame to check if the skill level up actually happened (not blocked by other mods)
    I.SkillProgression.addSkillLevelUpHandler(function(skillId, _)
        self:sendEvent(mDef.events.onSkillLevelUp, { skillId = skillId, skillLevel = module.getStat(skillId).base })
    end)
    if I.SkillFramework then
        I.SkillFramework.addSkillLevelUpHandler(function(skillId, _, _)
            self:sendEvent(mDef.events.onSkillLevelUp, { skillId = skillId, skillLevel = module.getStat(skillId).base })
        end)
    end
end

module.onSkillLevelUp = function(state, skillId, skillLevel)
    if module.getStat(skillId).base == skillLevel then return end
    if state.skills.major[skillId] or state.skills.minor[skillId] then
        state.levelProgress = state.levelProgress + 1
    end
    self:sendEvent(mDef.events.updateRequest, mDef.requestTypes.refreshStats)
end

module.saveStartValues = function(state, baseSkillMods)
    for skillId, skill in pairs(module.getStats()) do
        state.skills.start[skillId] = skill.base - (baseSkillMods[skillId] or 0)
    end
end

module.setClassSkills = function(state)
    local playerClass = T.NPC.classes.record(T.NPC.record(self).class)
    state.skills.major = {}
    for _, skillId in ipairs(playerClass.majorSkills) do
        state.skills.major[skillId] = true
    end
    state.skills.minor = {}
    for _, skillId in ipairs(playerClass.minorSkills) do
        state.skills.minor[skillId] = true
    end
    state.skills.misc = {}
    for _, skill in ipairs(core.stats.Skill.records) do
        if not state.skills.major[skill.id] and not state.skills.minor[skill.id] then
            state.skills.misc[skill.id] = true
        end
    end
end

module.computeChargenValues = function(state)
    local playerRecord = T.NPC.record(self)
    local playerClass = T.NPC.classes.record(playerRecord.class)
    local playerRace = T.NPC.races.record(playerRecord.race)

    local startSkills = {}
    for _, skill in ipairs(core.stats.Skill.records) do
        startSkills[skill.id] = 5
        if skill.specialization == playerClass.specialization then
            startSkills[skill.id] = startSkills[skill.id] + 5
        end
    end
    for skillId, value in pairs(playerRace.skills) do
        startSkills[skillId] = startSkills[skillId] + value
    end
    for _, skillId in ipairs(playerClass.majorSkills) do
        startSkills[skillId] = startSkills[skillId] + 25
    end
    for _, skillId in ipairs(playerClass.minorSkills) do
        startSkills[skillId] = startSkills[skillId] + 10
    end
    if playerRecord.race == "argonian" and core.contentFiles.has("racesrespected.omwscripts") then
        if playerRecord.isMale then
            startSkills.athletics = startSkills.athletics + 5
            startSkills.unarmored = startSkills.unarmored + 5
            startSkills.spear = startSkills.spear + 5
        else
            startSkills.alchemy = startSkills.alchemy + 5
            startSkills.illusion = startSkills.illusion + 5
            startSkills.mysticism = startSkills.mysticism + 5
        end
    end
    state.skills.start = startSkills
end

local function getSkillClassGrowthSetting(state, skillId)
    if state.skills.major[skillId] then
        return mS.settings.growthFactorFromMajorSkills
    elseif state.skills.minor[skillId] then
        return mS.settings.growthFactorFromMinorSkills
    else
        if core.stats.Skill.records[skillId] then
            return mS.settings.growthFactorFromMiscSkills
        elseif I.SkillFramework and I.SkillFramework.getSkillStat(skillId) then
            return mS.settings.growthFactorFromCustomSkills
        end
    end
    print(string.format("Unknown skill \"%s\", will use Misc skill growth setting", skillId))
    return mS.settings.growthFactorFromMiscSkills
end

module.setGrowthForAttributes = function(state, skillId, skillValue, startValuesRatio, luckGrowthRate, baseSkillMods)
    local growth = skillValue - (baseSkillMods[skillId] or 0) - startValuesRatio * state.skills.start[skillId]
    state.skills.growth[skillId] = growth
            * getSkillClassGrowthSetting(state, skillId).get() / 100
            * (1 - luckGrowthRate / 4)
end

module.setAllGrowthsForAttributes = function(state, baseSkillMods)
    local startValuesRatio = mS.settings.startAttrRatio.get()
    local luckGrowthRate = mS.settings.luckGrowthRate.get()

    for skillId, skill in pairs(module.getStats()) do
        module.setGrowthForAttributes(state, skillId, skill.base, startValuesRatio, luckGrowthRate, baseSkillMods)
    end
end

module.updateCustomSkills = function(state)
    if not I.SkillFramework then return end

    -- force the skill stat cache regeneration now custom skills should be all registered
    skillStatsCache = nil

    -- handle unsupported custom skills and mid-game added custom skills
    local refreshGrowth = false
    local refreshImpacts = false
    for skillId, props in pairs(I.SkillFramework.getSkillRecords()) do
        if props.attribute and not customSkillCompletedDescriptions[skillId] then
            customSkillCompletedDescriptions[skillId] = true
            local newProps = mHelpers.copyMap(props)
            local impacts
            if mCfg.skillImpactOnAttributes[skillId] then
                impacts = L("customSkillDescExtra_" .. skillId)
            else
                impacts = L("customSkillDescExtraDefault", { attribute = core.stats.Attribute.records[props.attribute].name })
            end
            newProps.description = string.format("%s\n\n%s", newProps.description, impacts)
            print(string.format("Overriding custom skill \"%s\" to complete its description with skill impact on attributes.", props.name))
            I.SkillFramework.registerSkill(skillId, newProps)
        end

        if props.attribute and not mCfg.skillImpactOnAttributes[skillId] then
            refreshImpacts = true
            mCfg.setSkillsImpactOnAttributes(skillId, { [props.attribute] = 7 })
        end
        if not state.skills.start[skillId] then
            refreshGrowth = true
            state.skills.start[skillId] = props.startLevel
            state.skills.misc[skillId] = true
            state.skills.growth[skillId] = 0
        end
    end
    if refreshImpacts then
        mCfg.setSkillImpactSums()
    end
    if refreshImpacts or refreshGrowth then
        mCfg.setSkillImpactSums()
        self:sendEvent(mDef.events.updateRequest, mDef.requestTypes.refreshStats)
    end
end

return module