local world = require("openmw.world")
local types = require("openmw.types")

local DAMAGE_SCRIPT = "scripts/tamer_damage.lua"

-- damageMult[creatureId] = current damage multiplier (>1) for that creature
local damageMult = {}

-- broadcast the current table to every actor running the damage script
local function syncAll()
    for _, actor in ipairs(world.activeActors) do
        if actor:hasScript(DAMAGE_SCRIPT) then
            actor:sendEvent("Tamer_DamageMultSync", { mult = damageMult })
        end
    end
end

-- ENGINE HANDLERS

local function onActorActive(actor)
    if not actor:isValid() then return end
    -- attach the lightweight damage script to every alive actor
    if not types.Actor.isDead(actor) and not actor:hasScript(DAMAGE_SCRIPT) then
        actor:addScript(DAMAGE_SCRIPT)
    end
    if actor:hasScript(DAMAGE_SCRIPT) then
        actor:sendEvent("Tamer_DamageMultSync", { mult = damageMult })
    end
end

local function onSave()
    return { damageMult = damageMult }
end

local function onLoad(d)
    damageMult = (d and d.damageMult) or {}
end

-- EVENT HANDLERS

-- a tamed creature reports its current damage multiplier
local function onSetDamageMult(d)
    if not d or not d.creature then return end
    local id = d.creature.id
    if d.mult and d.mult > 1 then
        damageMult[id] = d.mult
    else
        damageMult[id] = nil
    end
    syncAll()
end

-- a creature is no longer tamed (lost or died): drop its multiplier
local function onClearDamageMult(d)
    if not d or not d.creatureId then return end
    if damageMult[d.creatureId] ~= nil then
        damageMult[d.creatureId] = nil
        syncAll()
    end
end

-- a freshly-activated actor's damage script asks for the current table
local function onRequestDamageMult(d)
    if not d or not d.actor or not d.actor:isValid() then return end
    if d.actor:hasScript(DAMAGE_SCRIPT) then
        d.actor:sendEvent("Tamer_DamageMultSync", { mult = damageMult })
    end
end

-- an actor's damage script went inactive
local function onDamageScriptCleanup(d)
    if not d or not d.actor or not d.actor:isValid() then return end
    if d.actor:hasScript(DAMAGE_SCRIPT) then
        d.actor:removeScript(DAMAGE_SCRIPT)
    end
end

-- a tameable creature was knocked out
local function onSuppressBroadcast(d)
    if not d or not d.victim or not d.duration then return end
    local victimId = d.victim.id
    for _, actor in ipairs(world.activeActors) do
        if actor.id ~= victimId
           and actor:isValid()
           and not types.Actor.isDead(actor)
           and actor:hasScript(DAMAGE_SCRIPT) then
            actor:sendEvent("Tamer_SuppressToward", {
                victim   = d.victim,
                duration = d.duration,
            })
        end
    end
end

return {
    engineHandlers = {
        onActorActive = onActorActive,
        onSave        = onSave,
        onLoad        = onLoad,
    },
    eventHandlers = {
        Tamer_SetDamageMult       = onSetDamageMult,
        Tamer_ClearDamageMult     = onClearDamageMult,
        Tamer_RequestDamageMult   = onRequestDamageMult,
        Tamer_DamageScriptCleanup = onDamageScriptCleanup,
        Tamer_SuppressBroadcast   = onSuppressBroadcast,
    },
}