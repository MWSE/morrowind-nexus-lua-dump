--[[
    Evasion! — Global Script
    - Attaches the evasion actor script to active non-player actors.
    - Forwards perk events to the target actor's local script.
]]

local types = require('openmw.types')

local config = require('scripts.Evasion.config')

local ACTOR_SCRIPT = "scripts/Evasion/actor.lua"

local core = require('openmw.core')

local BLIND_EFFECT_ID = core.magic.EFFECT_TYPE.Blind
local blindRecordCache = nil

local function findBlindRecord(desiredMagnitude, desiredDuration)
    if blindRecordCache ~= nil then
        return blindRecordCache or nil
    end

    local bestMatch = nil
    local bestScore = math.huge

    local function scoreRecord(recordId, recordName, effect, index, sourcePenalty)
        local magMin = tonumber(effect.magnitudeMin) or 0
        local magMax = tonumber(effect.magnitudeMax) or magMin
        local duration = tonumber(effect.duration) or 0
        local avgMag = (magMin + magMax) * 0.5
        local score = (sourcePenalty or 0)
            + math.abs(duration - desiredDuration) * 10
            + math.abs(avgMag - desiredMagnitude) * 4
        if bestMatch == nil or score < bestScore then
            bestMatch = {
                id = recordId,
                name = recordName or recordId,
                effectIndex = index - 1,
                magnitudeMin = magMin,
                magnitudeMax = magMax,
                duration = duration,
            }
            bestScore = score
        end
    end

    for recordId, record in pairs(core.magic.spells.records) do
        local effects = record.effects or {}
        for index, effect in ipairs(effects) do
            if effect.id == BLIND_EFFECT_ID then
                scoreRecord(recordId, record.name, effect, index, 0)
            end
        end
    end

    for recordId, record in pairs(types.Potion.records) do
        local effects = record.effects or {}
        for index, effect in ipairs(effects) do
            if effect.id == BLIND_EFFECT_ID then
                scoreRecord(recordId, record.name, effect, index, 20)
            end
        end
    end

    blindRecordCache = bestMatch or false
    return bestMatch
end

local function addTemporaryBlind(target, attacker, magnitude, duration, displayName)
    local match = findBlindRecord(magnitude, duration)
    if not match then return false end
    types.Actor.activeSpells(target):add({
        id = match.id,
        effects = { match.effectIndex },
        name = displayName or match.name or 'Pocket Ash',
        caster = attacker,
        stackable = true,
        ignoreReflect = true,
        ignoreSpellAbsorption = true,
    })
    return true
end

local function onActorActive(actor)
    if types.Player.objectIsInstance(actor) then return end
    if (types.NPC.objectIsInstance(actor) or types.Creature.objectIsInstance(actor)) and not actor:hasScript(ACTOR_SCRIPT) then
        actor:addScript(ACTOR_SCRIPT)
    end
end

local function applyRiposte(data)
    if not data or not data.target then return end
    if not (types.NPC.objectIsInstance(data.target) or types.Creature.objectIsInstance(data.target)) then return end
    if types.Actor.isDead(data.target) then return end
    data.target:sendEvent('Evasion_ApplyRiposte', {
        amount = tonumber(data.healthDamage) or 0,
        sound = data.sound,
    })
end

local function applyAshSand(data)
    if not data or not data.target then return end
    if not (types.NPC.objectIsInstance(data.target) or types.Creature.objectIsInstance(data.target)) then return end
    if types.Actor.isDead(data.target) then return end

    local ok, applied = pcall(function()
        return addTemporaryBlind(
            data.target,
            data.attacker,
            config.perks.ashSand.blindMagnitude,
            config.perks.ashSand.blindDuration,
            'Pocket Ash'
        )
    end)

    if not ok or not applied then
        data.target:sendEvent('Evasion_ApplyAshSand', {
            magnitude = config.perks.ashSand.blindMagnitude,
            duration = config.perks.ashSand.blindDuration,
            sound = data.sound,
        })
    end
end

local function applyVanish(data)
    if not data or not data.target then return end
    if not (types.NPC.objectIsInstance(data.target) or types.Creature.objectIsInstance(data.target)) then return end
    if types.Actor.isDead(data.target) then return end
    data.target:sendEvent('Evasion_ApplyVanishCalm', {
        magnitude = config.perks.vanish.calmMagnitude,
        duration = config.perks.vanish.calmDuration,
        sound = data.sound,
    })
end

return {
    engineHandlers = {
        onActorActive = onActorActive,
    },
    eventHandlers = {
        Evasion_Riposte = applyRiposte,
        Evasion_AshSand = applyAshSand,
        Evasion_Vanish = applyVanish,
    },
}
