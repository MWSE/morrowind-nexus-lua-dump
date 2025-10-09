local interfaces = require('openmw.interfaces')
local self = require('openmw.self')
local types = require('openmw.types')

local settings = require('scripts.ConfigurableLevelingSpeed.settings')

local lastAnimation = nil

local magickaSkills = {
    alteration = true,
    conjuration = true,
    destruction = true,
    illusion = true,
    mysticism = true,
    restoration = true,
}

--- Check if the player is currently casting a spell.
--- @return boolean
local function isCastingSpell()
    return lastAnimation and lastAnimation.group == "spellcast" and string.sub(lastAnimation.key, -7) == "release"
        or false
end

--- Get the player's major and minor skills.
--- @return table
local function getPlayerSkills()
    local player = types.Player.record(self)
    local class = types.Player.classes.record(player.class)
    local skills = { major = {}, minor = {} }

    for _, skillId in ipairs(class.majorSkills) do
        skills.major[skillId] = true
    end

    for _, skillId in ipairs(class.minorSkills) do
        skills.minor[skillId] = true
    end

    return skills
end

--- Get the player's skill level for the given skill.
--- @param skillId string
--- @return number
local function getSkillLevel(skillId)
    return types.NPC.stats.skills[skillId](self).base
end

--- Get the global speed scale for the given skill.
--- @param skillId string
--- @return number
local function getGlobalSpeedScale(skillId)
    local globalSpeed = settings.getGlobalSpeed()

    if globalSpeed.from == globalSpeed.to then
        return globalSpeed.from
    end

    local skillLevel = getSkillLevel(skillId)
    return globalSpeed.from * ((globalSpeed.to / globalSpeed.from) ^ (skillLevel / 100))
end

--- Get the class speed scale for the given skill.
--- @param skillId string
--- @return number
local function getClassSpeedScale(skillId)
    local skills = getPlayerSkills()

    if skills.major[skillId] then
        return settings.getClassSpeed().major
    elseif skills.minor[skillId] then
        return settings.getClassSpeed().minor
    else
        return settings.getClassSpeed().misc
    end
end

--- Get the individual speed scale for the given skill.
--- @param skillId string
--- @return number
local function getIndividualSpeedScale(skillId)
    local individualSpeed = settings.getIndividualSpeed()
    return individualSpeed[skillId] or 1
end

--- Check if magicka scaling should be applied.
--- @return boolean
local function shouldScaleByMagicka()
    local magickaScaling = settings.getMagickaScaling()
    return magickaScaling.enabled and isCastingSpell()
end

--- Handler for when a skill is used.
--- @param skillId string
--- @param options table
local function onSkillUsed(skillId, options)
    local globalSpeedScale = getGlobalSpeedScale(skillId)
    local classSpeedScale = getClassSpeedScale(skillId)
    local individualSpeedScale = getIndividualSpeedScale(skillId)
    options.skillGain = options.skillGain * globalSpeedScale * classSpeedScale * individualSpeedScale

    if magickaSkills[skillId] and shouldScaleByMagicka() then
        local spell = types.Actor.getSelectedSpell(self)
        options.skillGain = options.skillGain * spell.cost * settings.getMagickaScaling().rate
    end
end

interfaces.Settings.registerPage(settings.page)

for _, group in ipairs(settings.groups) do
    interfaces.Settings.registerGroup(group)
end

interfaces.AnimationController.addTextKeyHandler('', function(group, key)
    lastAnimation = { group = group, key = key }
end)

interfaces.SkillProgression.addSkillUsedHandler(onSkillUsed)
