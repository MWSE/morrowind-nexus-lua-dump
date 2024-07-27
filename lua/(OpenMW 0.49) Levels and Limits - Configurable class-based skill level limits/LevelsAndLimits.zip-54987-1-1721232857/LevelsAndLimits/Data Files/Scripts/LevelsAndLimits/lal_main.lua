local self = require('openmw.self')
local types = require('openmw.types')
local I = require('openmw.interfaces')
local lalFunc = require('scripts.levelsandlimits.lal_func')

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

    -- Check if the mod is enabled
    if not getLaLToggle() then
        return  -- If disabled, allow normal skill progression
    end

    local skillStat = types.NPC.stats.skills[skillid](self)
    local skillLevel = skillStat.base
    local skillLevelUpFailed = false

    if majorSkills[skillid] and skillLevel >= getModifiedSkillMaximum(skillid, getSettingMajorSkillLimit()) then
        skillLevelUpFailed = true
    elseif minorSkills[skillid] and skillLevel >= getModifiedSkillMaximum(skillid, getSettingMinorSkillLimit()) then
        skillLevelUpFailed = true
    elseif not majorSkills[skillid] and not minorSkills[skillid] and skillLevel >= getModifiedSkillMaximum(skillid, getSettingMiscSkillLimit()) then
        skillLevelUpFailed = true
    end
    
    if skillLevelUpFailed then
        resetSkillExperience(skillid)
        showFailedSkillLevelUpMessage(options)
        return false
    end
end

I.SkillProgression.addSkillLevelUpHandler(skillLevelUpHandler)
