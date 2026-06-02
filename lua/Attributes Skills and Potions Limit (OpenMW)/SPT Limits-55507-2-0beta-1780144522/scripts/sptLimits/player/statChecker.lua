local self = require("openmw.self")
local types = require("openmw.types")

local config = require("scripts.sptLimits.shared.config")

local excludedAttributeSpells = {}
for attr, spells in pairs(config.attributes or {}) do
    excludedAttributeSpells[attr] = {}
    for _, id in ipairs(spells) do
        excludedAttributeSpells[attr][id] = true
    end
end

local excludedSkillSpells = {}
for skill, spells in pairs(config.skills or {}) do
    excludedSkillSpells[skill] = {}
    for _, id in ipairs(spells) do
        excludedSkillSpells[skill][id] = true
    end
end

local skippedAttributes = {}
local skippedSkills = {}

local attributeNames = {
    "strength",
    "intelligence",
    "willpower",
    "agility",
    "speed",
    "endurance",
    "personality",
    "luck",
}

local skillNames = {
    "alchemy",
    "longblade",
    "acrobatics",
    "bluntweapon",
    "enchant",
    "security",
    "axe",
    "conjuration",
    "sneak",
    "armorer",
    "alteration",
    "lightarmor",
    "mediumarmor",
    "destruction",
    "marksman",
    "heavyarmor",
    "mysticism",
    "shortblade",
    "spear",
    "restoration",
    "handtohand",
    "block",
    "illusion",
    "mercantile",
    "athletics",
    "unarmored",
    "speechcraft",
}

local function hasExcludedSpellActive(spellSet)
    if not spellSet or not next(spellSet) then
        return false
    end
    local activeSpells = types.Actor.activeSpells(self)
    for id, _ in pairs(spellSet) do
        if activeSpells:isSpellActive(id) == true then
            return true
        end
    end
    return false
end

local function shouldSkipAttribute(name)
    return skippedAttributes[name] or hasExcludedSpellActive(excludedAttributeSpells[name])
end

local function shouldSkipSkill(name)
    return skippedSkills[name] or hasExcludedSpellActive(excludedSkillSpells[name])
end

local function checkAttributes(cap)
    local attrs = types.Actor.stats.attributes
    for _, name in ipairs(attributeNames) do
        if not shouldSkipAttribute(name) and attrs[name](self).modified > cap then
            return true
        end
    end
    return false
end

local function checkSkills(cap)
    local skills = types.NPC.stats.skills
    for _, name in ipairs(skillNames) do
        if not shouldSkipSkill(name) and skills[name](self).modified > cap then
            return true
        end
    end
    return false
end

return {
    checkAttributes = checkAttributes,
    checkSkills = checkSkills,
    skippedAttributes = skippedAttributes,
    skippedSkills = skippedSkills,
}
