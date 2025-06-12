
local Actor = require('openmw.types').Actor
local core = require('openmw.core')
local types = require('openmw.types')


local function getActorSkill(player, skillName)
    local skill = types.NPC.stats.skills[skillName]
    if not skill then return 0.0 end

    return skill(player).modified
end

local function getActorSkillProgress(player, skillName)
    local skill = types.NPC.stats.skills[skillName]
    if not skill then return 0.0 end

    return skill(player).progress
end

local function getActorAttribute(actor, statName)
    local attrib = types.Actor.stats.attributes[statName]
    if not attrib then return nil end

    local a = attrib(actor)
    if not a then return nil end

    return a.modified

    --return types.Actor.stats.attributes[statName](actor).modified
end

local function getActorDynamicStat(actor, name)
    if (not actor) or (not name) then return nil end

    local dynamic = types.Actor.stats.dynamic[name]
    if not dynamic then 
        return nil
    end

    local current = dynamic(actor).current
    local base = dynamic(actor).base
    local modifier = dynamic(actor).modifier

    return {
        base = base,
        modified = math.max(0.0, base + modifier),
        current = current,
    }
end

local function getFatigueTerm(actor)
    local fatigue = getActorDynamicStat(actor, 'fatigue')
    if not fatigue then return nil end

    local fFatigueBase = core.getGMST('fFatigueBase')
    local fFatigueMult = core.getGMST('fFatigueMult')

    if (not fFatigueBase) or (not fFatigueMult) then return nil end

    local current = fatigue.current
    local max = fatigue.modified

    local normalized = math.floor(max) == 0.0 and 1.0 or math.max(0.0, current / max)

    return fFatigueBase - fFatigueMult * (1.0 - normalized)
end

local lib = {
    ------------------------------
    -- Health/Fatigue/Magicka
    ------------------------------
    
    -- Calculates the fatigueTerm used in many calculations
    getFatigueTerm = getFatigueTerm,

    -- Helper to retrieve dynamic stats easier.
    -- returns table with { base, modified and current }
    getActorDynamicStat = getActorDynamicStat,


    ------------------------------
    -- Attributes
    ------------------------------
    -- return the modified attribute.
    getActorAttribute = getActorAttribute,

    ------------------------------
    -- Skills
    ------------------------------
    -- Returns the modified skill 
    getActorSkill = getActorSkill,

    getActorSkillProgress = getActorSkillProgress,
}

return lib