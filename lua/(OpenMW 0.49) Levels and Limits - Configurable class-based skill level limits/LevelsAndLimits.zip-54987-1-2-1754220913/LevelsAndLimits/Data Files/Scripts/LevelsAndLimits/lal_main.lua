local self = require('openmw.self')
local types = require('openmw.types')
local core = require('openmw.core')
local I = require('openmw.interfaces')

local function skillLevelUpHandler(skillid, options)

    if I.lalUtil.getLaLToggle() then
    
        -- print(I.lalUtil.isSkillLevelUpPossible(skillid, options))
        local skillLevelUpPossible = I.lalUtil.isSkillLevelUpPossible(skillid, options)
        
        if skillLevelUpPossible == false then
            I.lalUtil.resetSkillExperience(skillid)
            I.lalUtil.showFailedSkillLevelUpMessage(options)
        end
    
        return skillLevelUpPossible
        
    end

end

local function skillUsedHandler(skillid, params)

    if I.lalUtil.getXPToggle() then

        if I.lalUtil.isSkillGainPossible() then
            params.skillGain = I.lalUtil.getModifiedSkillGain(skillid, params.skillGain)
            -- print(params.skillGain)
        else
            return false
        end
        
    end
    
end

if I.lalUtil.getDebugInfoToggle() then

    I.lalUtil.printDebugInfo()

end

I.SkillProgression.addSkillLevelUpHandler(skillLevelUpHandler)
I.SkillProgression.addSkillUsedHandler(skillUsedHandler)

