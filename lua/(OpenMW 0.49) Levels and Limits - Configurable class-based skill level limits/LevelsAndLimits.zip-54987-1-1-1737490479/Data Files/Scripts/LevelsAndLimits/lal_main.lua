local self = require('openmw.self')
local types = require('openmw.types')
local core = require('openmw.core')
local I = require('openmw.interfaces')

local repeatedFailedSkillUpSkillId = '' -- save the skill name on skill level up, to reduce unnecessary skill level up checks.

local majorSkills = {}
local minorSkills = {}

local playerClass = types.NPC.classes.records[types.NPC.record(self).class]

for _, skill in ipairs(playerClass.majorSkills) do 
    majorSkills[skill] = true
end

for _, skill in ipairs(playerClass.minorSkills) do 
    minorSkills[skill] = true
end

local function skillLevelUpHandler(skillid, options)

    local skillLevelUpFailed = false

    if I.lalUtil.getLevelProgressLimitToggle() then
        if (types.Actor.stats.level(self).progress >= I.lalUtil.getLevelProgressLimit()) then
            skillLevelUpFailed = true
        else
            repeatedFailedSkillUpSkillId = ''
        end
    end
    
    if repeatedFailedSkillUpSkillId == skillid then
        skillLevelUpFailed = true
    end

    if skillLevelUpFailed == false then

        local skillStat = types.NPC.stats.skills[skillid](self)
        local skillLevel = skillStat.base
    
        if majorSkills[skillid] and skillLevel >= I.lalUtil.getModifiedSkillMaximum(skillid, I.lalUtil.getSettingMajorSkillLimit()) then
            skillLevelUpFailed = true
        elseif minorSkills[skillid] and skillLevel >= I.lalUtil.getModifiedSkillMaximum(skillid, I.lalUtil.getSettingMinorSkillLimit()) then
            skillLevelUpFailed = true
        elseif not majorSkills[skillid] and not minorSkills[skillid] and skillLevel >= I.lalUtil.getModifiedSkillMaximum(skillid, I.lalUtil.getSettingMiscSkillLimit()) then
            skillLevelUpFailed = true
        end
    end
    
    if skillLevelUpFailed then
        I.lalUtil.resetSkillExperience(skillid)
        I.lalUtil.showFailedSkillLevelUpMessage(options)
        repeatedFailedSkillUpSkillId = skillid
        return false
    end

end

if I.lalUtil.getLaLToggle() then
    I.SkillProgression.addSkillLevelUpHandler(skillLevelUpHandler)
end