local ui = require('openmw.ui')
local core = require('openmw.core')
local self = require('openmw.self')
local types = require('openmw.types')
local storage = require('openmw.storage')
local settings = storage.playerSection("SettingsLevelsAndLimits")
local settingsXP = storage.playerSection("SettingsLevelsAndLimitsXP")
local settingsY = storage.playerSection("SettingsLevelsAndLimitsY")
local Actor = types.Actor

local L = core.l10n("LevelsAndLimits")

local favoredAttributes = types.NPC.classes.records[types.NPC.record(self).class].attributes

local racialSkills = {}
local playerRace = types.NPC.races.records[types.NPC.record(self).race]

local playerClass = types.NPC.classes.records[types.NPC.record(self).class]
local playerSkills = playerClass.skills

local majorSkills = {}
local minorSkills = {}

for _, skill in ipairs(playerClass.majorSkills) do 
    majorSkills[skill] = true
end

for _, skill in ipairs(playerClass.minorSkills) do 
    minorSkills[skill] = true
end

for skill in pairs(playerRace.skills) do
    racialSkills[skill] = true
end

local function getLaLToggle()
    return settings:get("lalToggle")
end

local function getSettingMajorSkillLimit()
    return settings:get("lalLimitMajor")
end

local function getSettingMinorSkillLimit()
    return settings:get("lalLimitMinor")
end

local function getSettingMiscSkillLimit()
    return settings:get("lalLimitMisc")
end

local function getSpecializationToggle()
    return settings:get("lalSpecializationToggle")
end

local function getSpecializationMalus()
    return settings:get("lalSpecializationMalus")
end

local function getFavoredAttributesToggle()
    return settings:get("lalFavoredAttributesToggle")
end

local function getFavoredAttributesMalus()
    return settings:get("lalFavoredAttributesMalus")
end

local function getRacialSkillToggle()
    return settings:get("lalRacialSkillToggle")
end

local function getRacialSkillMalus()
    return settings:get("lalRacialSkillMalus")
end

local function getDisableTrainingToggle()
    return settings:get("lalDisableTrainingToggle")
end

local function getDisableBooksToggle()
    return settings:get("lalDisableBooksToggle")
end

--

local function getXPToggle()
    return settingsXP:get("lalXPToggle")
end

local function getXPGlobalMultiplier()
    return settingsXP:get("lalXPGlobalMultiplier")
end

local function getXPDiminishingToggle()
    return settingsXP:get("lalXPDiminishingToggle")
end

local function getXPDiminishingMultiplier()
    return settingsXP:get("lalXPDiminishingMultiplier")
end

local function getXPDisableToggle()
    return settingsXP:get("lalXPDisableToggle")
end

--

local function getLevelProgressLimitToggle()
    return settingsY:get("lalLevelProgressLimitToggle")
end

local function getLevelProgressLimit()
    return settingsY:get("lalLevelProgressLimit")
end

local function getDebugInfoToggle()
    return settingsY:get("lalShowDebugInfo")
end

--

local function resetSkillExperience(skillid)
    local skillStat = types.NPC.stats.skills[skillid](self)
    if skillStat.progress > 1 then
        skillStat.progress = 1
    end
end

local function showFailedSkillLevelUpMessage(method)
    if method == 'trainer' then
        ui.showMessage(string.format(L("levelUpFailTrainer")))
    elseif method == 'book' then
        ui.showMessage(string.format(L("levelUpFailBook")))
    end
end

local function isLevelUpProgressLimitReached(progress)
    return progress >= getLevelProgressLimit()
end

local function getSkillMaximum(skillid)

    if majorSkills[skillid] then
        return getSettingMajorSkillLimit()
    end
    
    if minorSkills[skillid] then
        return getSettingMinorSkillLimit()
    end
    
    return getSettingMiscSkillLimit()

end

local function getModifiedSkillMaximum(skillid, skillMaximum)

    local classSpecialization = types.NPC.classes.records[types.NPC.record(self).class].specialization
    local skillSpecialization = core.stats.Skill.records[skillid].specialization
    
    -- check Specialization
    if getSpecializationToggle() then
        if getSpecializationToggle() and classSpecialization ~= skillSpecialization then
            --print("nope, not a specialization skill")
            skillMaximum = skillMaximum - getSpecializationMalus()
        end
    end
    
    -- check Favored Attributes
    if getFavoredAttributesToggle() then
    -- print('FavoredAttributesToggle true')
    
        local skillAttribute = core.stats.Skill.records[skillid].attribute
        local isFavoredAttribute = false
        
        for _, attr in pairs(favoredAttributes) do
            if attr == skillAttribute then
                isFavoredAttribute = true
                break
            end
        end
        
        if not isFavoredAttribute then
            --print("nop, not favored either!")
            skillMaximum = skillMaximum - getFavoredAttributesMalus()
        end
    end
    
    -- check Racial Skills
    if getRacialSkillToggle() then
        if not racialSkills[skillid] then
            --print("eh, thats not a racial skill.")
            skillMaximum = skillMaximum - getRacialSkillMalus()
        end
    end

    --print("skill maximum: " .. skillMaximum)

    return skillMaximum
    
end

local function getActualSkillBaseValue(skillid)

    local skillStat = types.NPC.stats.skills[skillid](self)
    local skillBaseLevel = skillStat.base
    local skillModiLevel = skillStat.modified
    local skillCalcLevel = skillBaseLevel
    
    --print('skill: ' .. skillid .. ' base: ' .. skillBaseLevel .. ' modified: ' .. skillModiLevel)
    
    for id, params in pairs(Actor.activeSpells(self)) do        
        for _, effect in pairs(params.effects) do
        
            if (effect.affectedSkill == skillid and skillStat.base == skillStat.modified) then
                
                -- print('affected, ability bonus!! .....................................................')            
                
                skillCalcLevel = skillCalcLevel - effect.magnitudeThisFrame
                
            end
        
        end
    end
    
    return skillCalcLevel

end

local function isSkillLevelUpPossible(skillid, source, options)

    if getDisableTrainingToggle() and source == 'trainer' then
        print('training disabled, trainer used!')
        return false
    end
    
    if getDisableBooksToggle() and source == 'book' then
        print('books disabled, book used!')
        return false
    end

    if getLevelProgressLimitToggle() then
        if ( isLevelUpProgressLimitReached(types.Actor.stats.level(self).progress) ) then
            print('Progress Limit reached, no further skill ups possible until rested!')
            return false
        end
    end
    
    if getActualSkillBaseValue(skillid) >= getModifiedSkillMaximum(skillid, getSkillMaximum(skillid)) then
        -- print ('skill up not possible!')
        return false
    end

    return true
end


local function getSkillGainMultiplier(skillid)
    local globalMultiplier = getXPGlobalMultiplier()
    local finalMultiplier = globalMultiplier
    
    if getXPDiminishingToggle() then
        local skillLevel = getActualSkillBaseValue(skillid)
        
        for id, params in pairs(Actor.activeSpells(self)) do        
            for _, effect in pairs(params.effects) do
            
                if (effect.affectedSkill == skillid) then
                    -- print('affected...........................................!')
                    skillLevel = skillLevel - effect.magnitudeThisFrame
                end
            
            end
        end
        
        -- print('so: ' .. skillid .. ' ' .. types.NPC.stats.skills[skillid](self).base)
        local diminishMultiplier = 1 / math.max(1, (skillLevel / 10) * getXPDiminishingMultiplier()) 
        finalMultiplier = globalMultiplier * diminishMultiplier
    end

    return finalMultiplier
end

local function getModifiedSkillGain(skillid, skillGain)
    
    if getDebugInfoToggle() then
        print('-----------------------------------------')
        print(skillid .. ': Initital Skillgain: ' .. skillGain )
    end
    
    skillGain = skillGain * getSkillGainMultiplier(skillid)
    
    if getDebugInfoToggle() then
        print('Calculated Skillgain:' .. skillGain .. ' skillgain multiplier: ' .. getSkillGainMultiplier(skillid))
        print('-----------------------------------------')
        print('')
    end

    return skillGain
end

local function isSkillGainPossible()

    if getXPDisableToggle() then
        -- print('skillgain was disabled')
        return false
    end
    
    if getLevelProgressLimitToggle() then
        if (types.Actor.stats.level(self).progress >= getLevelProgressLimit()) then
            -- print('skillgain is not possible, rest first!')
            return false
        end
    end
    
    -- print('skillgain is possible!')
    
    return true

end

local function printDebugInfo()

 
    local printout = '\n--- LEVELS AND LIMITS DEBUG INFO---'
    
    if isSkillGainPossible() then
        print('skillgain is possible!')
    end

    --if isSkillLevelUpPossible(skillid, 'trainer') then
    --    print('skill up is possible ')
    --end

    for i, skill in ipairs(core.stats.Skill.records) do
    
        local multiplier = tonumber(string.format("%.3f", getSkillGainMultiplier(skill.id)))
        
        printout = printout .. '\n ' .. skill.id
          .. ', base: '
          .. types.NPC.stats.skills[skill.id](self).base
          .. ', actual base: '
          .. getActualSkillBaseValue(skill.id)
          .. ', max skill level: ' 
          .. getModifiedSkillMaximum(skill.id, getSkillMaximum(skill.id) ) 
          .. ', xp gain multiplier: ' 
          .. multiplier .. 'x'
        
    end
    
    printout = printout .. '\n--- LEVELS AND LIMITS DEBUG END ---'
    
    print(printout);

end

return {
    interfaceName = "lalUtil",
    interface = {
        getLaLToggle = getLaLToggle,
        resetSkillExperience = resetSkillExperience,
        showFailedSkillLevelUpMessage = showFailedSkillLevelUpMessage,
        getXPToggle = getXPToggle,
        getModifiedSkillGain = getModifiedSkillGain,
        isSkillLevelUpPossible = isSkillLevelUpPossible,
        isSkillGainPossible = isSkillGainPossible,
        getDebugInfoToggle = getDebugInfoToggle,
        printDebugInfo = printDebugInfo
        
    }
}
