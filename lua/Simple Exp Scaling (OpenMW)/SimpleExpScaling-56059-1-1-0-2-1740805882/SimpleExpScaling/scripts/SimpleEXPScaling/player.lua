local I = require('openmw.interfaces')
local storage = require('openmw.storage')

require('scripts.SimpleEXPScaling.settings')
local settings = storage.playerSection('SettingsSimpleExpScaling')

local function getSkillMultiplier(skill)
    return settings:get(skill.. 'multi')
end

I.SkillProgression.addSkillUsedHandler(function(skillid, params)

    if skillid == 'speechcraft' and params.useType == I.SkillProgression.SKILL_USE_TYPES.Speechcraft_Fail and settings:get('togglespeechcraftfail') then
        params.skillGain = params.skillGain + (settings:get('basespeechcraftfail') * getSkillMultiplier(skillid))
    else
        params.skillGain = params.skillGain * getSkillMultiplier(skillid)
    end
end)