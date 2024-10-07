-- The main logic and functions of this mod
local core = require('openmw.core')

local info = require('scripts.PotentialCharacterProgression.info')
local L = core.l10n(info.name)

if core.API_REVISION < info.minApiVersion then
    print(L('UpdateOpenMW'))
    return
end

local ambient = require('openmw.ambient')
local async = require('openmw.async')
local I = require('openmw.interfaces')
local input = require('openmw.input')
local self = require('openmw.self')
local storage = require('openmw.storage')
local types = require('openmw.types')
local ui = require('openmw.ui')
local util = require('openmw.util')

local Player = types.Player

local classData = require('scripts.' .. info.name .. '.classdata')
local PLui = require('scripts.' .. info.name .. '.ui')
local settings = require('scripts.' .. info.name .. '.settings')

local function contains(t, element)
  for _, value in pairs(t) do
    if value == element then
      return true
    end
  end
  return false
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Mod settings

local modSettings = {
    basic = storage.playerSection('SettingsPlayer' .. info.name),
    health = storage.playerSection('SettingsPlayer' .. info.name .. 'Health'),
    balance = storage.playerSection('SettingsPlayer' .. info.name .. 'Balance')
}

local healthSettings = {
    isRetroactive = nil,
    isStartRetroactive = nil,
    isCustom = nil,
    customCoefficients = nil,
    customGainMult = nil
}

-- Game settings

local skillUpsPerLevel = core.getGMST('iLevelupTotal')
local levelHealthMult = core.getGMST('fLevelUpHealthEndMult')

-- Player data

local playerStats = Player.stats
local playerAttributes = playerStats.attributes
local playerSkills = playerStats.skills

local function getPlayerRecords()
    local playerRecord = Player.record(self)
    return {
        class = Player.classes.record(playerRecord.class),
        race = Player.races.record(playerRecord.race),
        sex = (playerRecord.isMale and 'male') or 'female'
    }
end

-- Saved variables

-- Level-ups gained while this mod is active, important to track for health gain
local levelUps = 0
-- Total max health increase from this mod, important to track for external health/endurance gain
local totalHealthGained = 0
local experience = 0

local attributeData = {}

local skillData = {}

local function setAttributesValue(var, value)
    for attributeid, attribute in pairs(playerAttributes) do
        attributeData[attributeid][var] = value
    end
end

local function setSkillsValue(var, value)
    for skillid, skill in pairs(playerSkills) do
        skillData[skillid][var] = value
    end
end

for attributeid, attribute in pairs(playerAttributes) do
    attributeData[attributeid] = {}
end

for skillid, skill in pairs(playerSkills) do
    skillData[skillid] = {}
end

setAttributesValue('ups', 0)
setAttributesValue('potential', 0)

setSkillsValue('ups', 0)
setSkillsValue('upsCurLevel', 0)
setSkillsValue('upsLastLevels', 0)
setSkillsValue('peak', 0)

local totalSkillUpsCurLevel = 0

-- Runtime Variables

local isCharGenFinished = false
local startAttributes
local isLevelUp = true
local levelUpData







-- Debug stuff -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

local function infoDump()
    for attributeid, attribute in pairs(attributeData) do
        print(attributeid .. ' increases: ' .. attribute.ups)
        print(attributeid .. ' potential: ' .. attribute.potential)
    end
    for skillid, skill in pairs(skillData) do
        print(skillid .. ' increases: ' .. skill.ups)
        print(skillid .. ' increases this level: ' .. skill.upsCurLevel)
        print(skillid .. ' increases last level: ' .. skill.upsLastLevels)
        print(skillid .. ' highest value: ' .. skill.peak)
    end
    print('total skill increases this level: ' .. totalSkillUpsCurLevel)
    print('level-ups: ' .. levelUps)
    print('experience: ' .. experience)
end







-- Health functions  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Update health settings
local function updateHealthSettings()
    healthSettings.isRetroactive = modSettings.health:get('RetroactiveHealth')
    healthSettings.isStartRetroactive = healthSettings.isRetroactive and modSettings.health:get('RetroactiveStartHealth')
    healthSettings.isCustom = modSettings.health:get('CustomHealth')
    healthSettings.customCoefficients = modSettings.health:get('CustomHealthCoefficients')
    healthSettings.customGainMult = modSettings.health:get('CustomGainMultiplier')
end

-- Increase max health, apply increase to current health as well
local function increaseHealth(healthIncrease)
    totalHealthGained = totalHealthGained + healthIncrease
    playerStats.dynamic.health(self).base = playerStats.dynamic.health(self).base + healthIncrease
    playerStats.dynamic.health(self).current = math.min(math.max(playerStats.dynamic.health(self).current + healthIncrease, 1), playerStats.dynamic.health(self).base)
end

-- Calculate starting attribute values, not factoring in birthsigns
local function getStartingAttributes()
    if not startAttributes then
        local playerRecords = getPlayerRecords()
        startAttributes = {}
        for attributeid, _ in pairs(attributeData) do
            startAttributes[attributeid] = playerRecords.race.attributes[attributeid][playerRecords.sex]
        end
        for _, attributeid in pairs(playerRecords.class.attributes) do
            startAttributes[attributeid] = startAttributes[attributeid] + 10
        end
    end
    return startAttributes
end

-- Get current base attribute values
local function getBaseAttributes()
    local baseAttributes = {}
    for attributeid, _ in pairs(attributeData) do
        baseAttributes[attributeid] = playerAttributes[attributeid](self).base
    end
    return baseAttributes
end

-- Calculate weighted average for the custom health setting
local function calculateWeightedAverage(attributes)
    local average = 0
    local coefficientsSum = 0
    for attributeid, attribute in pairs(attributes) do
        average = average + attribute * healthSettings.customCoefficients[attributeid]
        coefficientsSum = coefficientsSum + math.max(healthSettings.customCoefficients[attributeid], 0)
    end
    if coefficientsSum == 0 then
        return 0
    else
        return average / coefficientsSum
    end
end

-- Calculate starting health under specified conditions
local function calculateStartHealth(isRetroactive, isCustom)
    local attributes
    if isRetroactive then
        attributes = getBaseAttributes()
    else
        attributes = getStartingAttributes()
    end
    if isCustom then
        return calculateWeightedAverage(attributes)
    else
        return (attributes.endurance + attributes.strength) * 0.5
    end
end

-- Given attribute values, calculate health gained from one level up
local function calculateLevelHealth(attributes)
    if healthSettings.isCustom then
        return calculateWeightedAverage(attributes) * healthSettings.customGainMult
    else
        return attributes.endurance * levelHealthMult
    end
end

-- Given attribute values, calculate health gain and optionally starting health
local function calculateHealthIncrease(attributes, isRetroactive, isStartRetroactive, gainLevels)
    if not attributes then
        attributes = getBaseAttributes()
    end

    local levelHealth = calculateLevelHealth(attributes) * gainLevels
    local startHealth
    local base

    if isRetroactive then
        startHealth = calculateStartHealth(isStartRetroactive, healthSettings.isCustom)
        base = calculateStartHealth(false, false) + totalHealthGained
    else
        startHealth = 0
        base = 0
    end

    increaseHealth(startHealth + levelHealth - base)
end







-- Menu functions -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Use skill increases to determine level-up art
local function getLevelUpClass()
    local highestScore = 0
    local highestClass = 'acrobat'
    
    for class, data in pairs(classData) do
        local score = 0
        for skillid, modifier in pairs(data) do
            score = score + skillData[skillid].upsLastLevels * modifier
        end
        if score > highestScore then
            highestScore = score
            highestClass = class
        end
    end
        
    return highestClass
end

-- Show the level-up menu
-- When called by the normal level-up mechanics, increase level and give experience to distribute
local function showMenu()
    updateHealthSettings()

    if isLevelUp and isCharGenFinished then
        local levelsGained = math.floor(playerStats.level(self).progress / skillUpsPerLevel)
        -- Without this check, the player can (harmlessly) trigger the same level up over and over with the right timing
        if levelsGained > 0 then
            playerStats.level(self).progress = playerStats.level(self).progress - (levelsGained * skillUpsPerLevel)
            local nextLevel = playerStats.level(self).current + levelsGained
            playerStats.level(self).current = nextLevel
            levelUps = levelUps + levelsGained
            experience = experience + (levelsGained * modSettings.balance:get('ExperiencePerLevel'))
            ambient.streamMusic('Music/Special/MW_Triumph.mp3')
            
            levelUpData = {
                level = nextLevel,
                ups = levelsGained,
                class = getLevelUpClass()
            }

            setSkillsValue('upsLastLevels', 0)
        end
    end

    -- Manually order attributes to match vanilla menus
    -- There is probably a better way to do this
    local attributeOrder = {
        strength = 1,
        intelligence = 2,
        willpower = 3,
        agility = 4,
        speed = 5,
        endurance = 6,
        personality = 7,
        luck = 8
    }

    local orderedAttributeData = {}
    local attributeCount = 8

    for attributeid, attribute in pairs(attributeData) do
        if attributeOrder[attributeid] then
            orderedAttributeData[attributeOrder[attributeid]] = {potential = attribute.potential, id = attributeid}
        else
            attributeCount = attributeCount + 1
            orderedAttributeData[attributeCount] = attribute
        end
    end

    PLui.createMenu(levelUpData, orderedAttributeData, experience, finishMenu)
end

local function hideMenu()
    PLui.hideMenu()
    -- If leveled up or retroactive health gain enabled, calculate health gain with base attributes
    -- Other sources of attribute increases and health should be integrated correctly
    -- Do this in the hide function so it still triggers even if the player just closes the menu
    if levelUpData or healthSettings.isRetroactive then
        local gainLevels = (healthSettings.isRetroactive and levelUps) or levelUpData.ups
        calculateHealthIncrease(nil, healthSettings.isRetroactive, healthSettings.isStartRetroactive, gainLevels)
    end
    isLevelUp = true
    levelUpData = nil
end

I.UI.registerWindow('LevelUpDialog', showMenu, hideMenu)

local function finishMenu(data)
    for attributeid, uiAttribute in pairs(data.uiAttributes) do
        if not data.debugMode then
            attributeData[attributeid].potential = math.max(math.floor(uiAttribute.potential) - uiAttribute.ups, 0) + uiAttribute.potential - math.floor(uiAttribute.potential)
        end
        attributeData[attributeid].ups = attributeData[attributeid].ups + uiAttribute.ups
        playerAttributes[attributeid](self).base = playerAttributes[attributeid](self).base + uiAttribute.ups
    end
    
    -- If menu wasn't triggered by a level-up and retroactive gain is off, calculate health gain for 1 level
    -- Calculate only with menu attribute increases, don't integrate other attribute increases
    -- Do this in the finish menu event so we don't have to pass individual increase data to the hide function
    if not (isLevelUp or healthSettings.isRetroactive) then
        local healthAttributes = {}
        for attributeid, attribute in pairs(data.uiAttributes) do
            healthAttributes[attributeid] = attribute.ups
        end
        calculateHealthIncrease(healthAttributes, false, false, 1)
    end
    
    experience = data.uiExperience
    I.UI.removeMode('LevelUp')
end







-- Handlers -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Increase level progress and attribute potential for every skill increase 
-- Also track highest value for each skill, for use with the jail exploit setting
local function handleskillUps(skillid, source, options)
    local skillIncrease = options.skillIncreaseValue
    local skillNewValue = skillIncrease + playerSkills[skillid](self).base
    if not modSettings.basic:get('JailExploit') then
        skillIncrease = util.clamp(skillNewValue - skillData[skillid].peak, 0, skillIncrease)
    end
    skillData[skillid].peak = math.max(skillNewValue, skillData[skillid].peak)
    skillData[skillid].ups = skillData[skillid].ups + skillIncrease
    skillData[skillid].upsCurLevel = skillData[skillid].upsCurLevel + skillIncrease
    totalSkillUpsCurLevel = totalSkillUpsCurLevel + skillIncrease
    options.levelUpProgress = skillIncrease

    local playerRecords = getPlayerRecords()

    local potentialMult = modSettings.balance:get('PotentialPerSkill')
    if contains(playerRecords.class.minorSkills, skillid) then
        potentialMult = modSettings.balance:get('PotentialPerMinorSkill')
    elseif contains(playerRecords.class.majorSkills, skillid) then
        potentialMult = modSettings.balance:get('PotentialPerMajorSkill')
    end
    attributeData[options.levelUpAttribute].potential = attributeData[options.levelUpAttribute].potential + skillIncrease * potentialMult
    
    -- Prepare for level-up
    if totalSkillUpsCurLevel >= skillUpsPerLevel then
        totalSkillUpsCurLevel = totalSkillUpsCurLevel % skillUpsPerLevel
        for skillid, skill in pairs(skillData) do
            skillData[skillid].upsLastLevels = skillData[skillid].upsLastLevels + skillData[skillid].upsCurLevel
        end
        setSkillsValue('upsCurLevel', 0)
        skillData[skillid].upsLastLevels = skillData[skillid].upsLastLevels - totalSkillUpsCurLevel
        skillData[skillid].upsCurLevel = totalSkillUpsCurLevel
    end
    return true
end

I.SkillProgression.addSkillLevelUpHandler(handleskillUps)

-- Record skill values when finishing character creation or when first loading this script on an existing character
local function finishCharGen()
    -- Update health with relevant settings
    updateHealthSettings()
    if healthSettings.isStartRetroactive then
        calculateHealthIncrease(false, true, true, 0)
    elseif healthSettings.isCustom then
        calculateHealthIncrease(getStartingAttributes(), true, false, 0)
    end

    for skillid, skill in pairs(playerSkills) do
        skillData[skillid].peak = skill(self).base
    end
    totalSkillUpsCurLevel = playerStats.level(self).progress % skillUpsPerLevel
    local keybind = input.getKeyName(modSettings.basic:get('MenuKey'))
    local charGenCallback = async:registerTimerCallback('charGenMessage', function() ui.showMessage(L('StartUp', {keybind = keybind}), {showInDialogue = false}) end)
    async:newSimulationTimer(0.1, charGenCallback)
end

local function onUpdate()
    if not isCharGenFinished then
        if Player.isCharGenFinished(self) then
            isCharGenFinished = true
            finishCharGen()
        end
    end
end

-- Input handlers

local function levelMenuKey()
    local topMode = I.UI.modes[1]
    if isCharGenFinished then
        if contains(I.UI.modes, 'LevelUp') then
            I.UI.removeMode('LevelUp')
        elseif topMode == nil or topMode == 'Interface' then
            isLevelUp = false
            I.UI.addMode('LevelUp')
        end
    end
end

input.registerTriggerHandler('Menu' .. info.name, async:callback(levelMenuKey))

local function onKeyPress(key)
    if key.code == modSettings.basic:get('MenuKey') then
        input.activateTrigger('Menu' .. info.name)
    end
end

-- Save/load handlers

local function onLoad(data)
    if info.saveVersion > data.saveVersion then
        ui.showMessage(L('SaveVersionNew'), {showInDialogue = false})
        print(L('SaveVersionNew'))
    elseif info.saveVersion < data.saveVersion then
        ui.showMessage(L('SaveVersionOld'), {showInDialogue = false})
        print(L('SaveVersionOld'))
    else
        if info.settingsVersion > (data.settingsVersion or 1) then
            ui.showMessage(L('SettingsVersionNew'), {showInDialogue = false})
            print(L('SettingsVersionNew'))
        elseif info.settingsVersion < (data.settingsVersion or 1) then
            ui.showMessage(L('SettingsVersionNew'), {showInDialogue = false})
            print(L('SettingsVersionOld'))
        end
        skillData = data.skillData
        attributeData = data.attributeData
        levelUps = data.levelUps
        experience = data.experience
        totalHealthGained = data.totalHealthGained
        totalSkillUpsCurLevel = data.totalSkillUpsCurLevel
    end
        isCharGenFinished = true
end

local function onSave()
    return {
        saveVersion = info.saveVersion,
        settingsVersion = info.settingsVersion,
        skillData = skillData,
        attributeData = attributeData,
        levelUps = levelUps,
        experience = experience,
        totalHealthGained = totalHealthGained,
        totalSkillUpsCurLevel = totalSkillUpsCurLevel,
    }
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onKeyPress = onKeyPress,
        onLoad = onLoad,
        onSave = onSave
    },
    eventHandlers = {
        FinishMenu = finishMenu
    }
}