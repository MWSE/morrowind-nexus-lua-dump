local core = require('openmw.core')
local interfaces = require('openmw.interfaces')
local self = require('openmw.self')
local types = require('openmw.types')
local ui = require('openmw.ui')

local settings = require('scripts.LinearLeveling.settings')

local state = {
    skillIncreasesForAttribute = {
        strength = 0,
        intelligence = 0,
        willpower = 0,
        agility = 0,
        speed = 0,
        endurance = 0,
        personality = 0,
        luck = 0,
    }
}

--- Returns the ID of the governing attribute for the skill.
--- @param skillId string
--- @return string
local function getAttributeId(skillId)
    return core.stats.Skill.record(skillId).attribute
end

--- Returns the player's current attributes.
--- @return table
local function getAttributes()
    return {
        strength = types.Actor.stats.attributes.strength(self).base,
        intelligence = types.Actor.stats.attributes.intelligence(self).base,
        willpower = types.Actor.stats.attributes.willpower(self).base,
        agility = types.Actor.stats.attributes.agility(self).base,
        speed = types.Actor.stats.attributes.speed(self).base,
        endurance = types.Actor.stats.attributes.endurance(self).base,
        personality = types.Actor.stats.attributes.personality(self).base,
        luck = types.Actor.stats.attributes.luck(self).base,
    }
end

--- Returns the attributes which have increased and the amounts they've increased by.
--- @param oldAttributes table
--- @param newAttributes table
--- @return table
local function getIncreasedAttributes(oldAttributes, newAttributes)
    local increases = {}
    for attributeId, oldValue in pairs(oldAttributes) do
        local newValue = newAttributes[attributeId]
        local increase = newValue - oldValue
        if (increase > 0) then
            increases[attributeId] = increase
        end
    end
    return increases
end

--- Returns the multiplier (from 1 to 5) for the attribute based on the current state of the player.
--- @param attributeId string
--- @return integer
local function getMultiplier(attributeId)
    local skillIncreases = state.skillIncreasesForAttribute[attributeId]
    local skillIncreasesPerMultiplier = settings.getSkillIncreasesPerMultiplier()
    local multiplier = math.floor(1 + skillIncreases / skillIncreasesPerMultiplier)
    return math.min(multiplier, 5)
end

--- Returns the player's major and minor skills.
--- @return table
local function getPlayerSkills()
    if not state.skills then
        local player = types.Player.record(self)
        local class = types.Player.classes.record(player.class)
        local skills = { major = {}, minor = {} }

        for _, skillId in ipairs(class.majorSkills) do
            skills.major[skillId] = true
        end

        for _, skillId in ipairs(class.minorSkills) do
            skills.minor[skillId] = true
        end

        state.skills = skills
    end

    return state.skills
end

--- Gets the skill increase value for the skill.
--- @param skillId string
--- @return unknown
local function getSkillIncreaseValue(skillId)
    local skills = getPlayerSkills()

    if skills.major[skillId] then
        return settings.getMajorSkillValue()
    elseif skills.minor[skillId] then
        return settings.getMinorSkillValue()
    else
        return settings.getMiscSkillValue()
    end
end

--- Gets the vanilla skillIncreasesForAttribute table.
--- @return table
local function getVanillaSkillIncreasesForAttribute()
    return types.Actor.stats.level(self).skillIncreasesForAttribute
end

--- Gets the number of skill increases required by vanilla to achieve the multiplier.
--- @param multiplier integer
--- @return integer
local function getVanillaSkillIncreasesRequiredForMultiplier(multiplier)
    if multiplier == 5 then
        return 10
    elseif multiplier == 4 then
        return 8
    elseif multiplier == 3 then
        return 5
    elseif multiplier == 2 then
        return 1
    else
        return 0
    end
end

--- Updates the multiplier for the attribute based on the current state of the player by changing the vanilla
--- skillIncreasesForAttribute table.
--- @param attributeId string
local function updateAttributeMultiplier(attributeId)
    local multiplier = getMultiplier(attributeId)
    local vanillaSkillIncreasesForAttribute = getVanillaSkillIncreasesForAttribute()
    vanillaSkillIncreasesForAttribute[attributeId] = getVanillaSkillIncreasesRequiredForMultiplier(multiplier)
end

--- Updates the multiplier for all attributes based on the current state of the player.
local function updateAttributeMultipliers()
    for _, attribute in ipairs(core.stats.Attribute.records) do
        updateAttributeMultiplier(attribute.id)
    end
end

--- Adds to the number of skill increases for the attribute.
--- @param skillId string
--- @param attributeId string
local function addSkillIncrease(skillId, attributeId)
    local skillIncreaseValue = getSkillIncreaseValue(skillId)
    state.skillIncreasesForAttribute[attributeId] = state.skillIncreasesForAttribute[attributeId] + skillIncreaseValue
end

--- Removes from the number of skill increases for each attribute which increased.
--- @param attributeIncreases table
local function removeSkillIncreases(attributeIncreases)
    local skillIncreasesPerMultiplier = settings.getSkillIncreasesPerMultiplier()
    for attributeId, increase in pairs(attributeIncreases) do
        local skillDecreaseValue = skillIncreasesPerMultiplier * (increase - 1)
        state.skillIncreasesForAttribute[attributeId] = state.skillIncreasesForAttribute[attributeId] -
            skillDecreaseValue
    end
end

--- Every time a skill levels up, add to the number of increases and update the multiplier.
--- levelUpAttributeIncreaseValue is set to 0 in the options to suppress vanilla behaviour.
--- @param skillId string
--- @param _ any
--- @param options table
local function onSkillLevelUp(skillId, _, options)
    local attributeId = getAttributeId(skillId)
    addSkillIncrease(skillId, attributeId)
    updateAttributeMultiplier(attributeId)
    options["levelUpAttributeIncreaseValue"] = 0
end

--- Every time the player levels up, get the attributes which increased and remove the spent skill increases.
--- Then, update the multipliers for all attributes, as vanilla clears them after a level up.
--- @param data table
local function onUiModeChanged(data)
    if data.newMode == "LevelUp" then
        state.oldAttributes = getAttributes()
    elseif data.oldMode == "LevelUp" then
        local newAttributes = getAttributes()
        local increasedAttributes = getIncreasedAttributes(state.oldAttributes, newAttributes)
        removeSkillIncreases(increasedAttributes)
        updateAttributeMultipliers()
    end
end

local function onLoad(data)
    if data then
        state = data
    end
end

local function onSave()
    return state
end

interfaces.Settings.registerPage(settings.page)

for _, group in ipairs(settings.groups) do
    interfaces.Settings.registerGroup(group)
end

interfaces.SkillProgression.addSkillLevelUpHandler(onSkillLevelUp)

return {
    engineHandlers = {
        onSave = onSave,
        onLoad = onLoad,
    },
    eventHandlers = {
        UiModeChanged = onUiModeChanged
    },
}
