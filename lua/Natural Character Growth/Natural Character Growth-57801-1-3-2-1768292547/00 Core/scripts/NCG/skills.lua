local self = require('openmw.self')
local I = require('openmw.interfaces')
local T = require('openmw.types')

local mDef = require('scripts.NCG.config.definition')
local mS = require('scripts.NCG.config.settings')
local mC = require('scripts.NCG.common')

local module = {}

module.setSkillGrowths = function(state, skillId, skillValue, startValuesRatio, luckGrowthRate, baseSkillMods)
    local baseValue = skillValue - (baseSkillMods[skillId] or 0)
    state.skills.growth.level[skillId] = state.skills.misc[skillId] and 0 or baseValue - state.skills.start[skillId]

    local attrGrowth = baseValue - startValuesRatio * state.skills.start[skillId]
    local settingKey = state.skills.major[skillId] and "Major" or (state.skills.minor[skillId] and "Minor" or "Misc")
    state.skills.growth.attributes[skillId] = attrGrowth
            * mS.attributesStorage:get("growthFactorFrom" .. settingKey .. "Skills") / 100
            * (1 - luckGrowthRate / 4)
end

module.updateSkills = function(state)
    local startValuesRatio = mS.getAttributeStartValuesRatio()
    local luckGrowthRate = mS.getLuckGrowthRate()
    local baseSkillMods = mC.getBaseStatMods().skill

    for skillId, getter in pairs(T.NPC.stats.skills) do
        module.setSkillGrowths(state, skillId, getter(self).base, startValuesRatio, luckGrowthRate, baseSkillMods)
    end
end

local function getSkillLevelUpHandler()
    return function(skillId, _)
        -- Wait the next frame to check if the skill level up actually happened (not blocked by other mods)
        self:sendEvent(mDef.events.onSkillLevelUp, { skillId = skillId, skillLevel = T.NPC.stats.skills[skillId](self).base })
    end
end

module.onSkillLevelUp = function(skillId, skillLevel)
    if T.NPC.stats.skills[skillId](self).base == skillLevel then return end
    self:sendEvent(mDef.events.updateRequest, mDef.requestTypes.refreshStats)
end

module.addHandlers = function()
    I.SkillProgression.addSkillLevelUpHandler(getSkillLevelUpHandler())
end

return module