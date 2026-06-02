local core = require('openmw.core')
local self = require('openmw.self')
local nearby = require('openmw.nearby')
local types = require('openmw.types')
local util = require('openmw.util')

local common = require('scripts.wispspell.common')

local state = {
    caster = nil,
    payloadSpellId = nil,
    payloadSpellIds = nil,
    sourceSpellName = 'Soul Wisp',
    duration = common.defaultDuration,
    fadeOutTime = common.fadeOutTime,
    interval = 2,
    cooldown = 0,
    magnitude = common.defaultMagnitude,
    projectileSpeed = common.baseProjectileSpeed,
    targetRadius = common.defaultRadius,
    target = nil,
    hostileActors = {},
    playerAllies = {},
    nextHostilityRequest = 0,
    removing = false,
}

local function valid(object)
    return common.isValid(object)
end

local function sameObject(a, b)
    return valid(a) and valid(b) and a.id == b.id
end

local function isActor(object)
    return valid(object) and types.Actor.objectIsInstance(object)
end

local function isDead(actor)
    return not isActor(actor) or types.Actor.isDead(actor)
end

local function distance2(object)
    local d = object.position - self.position
    return d:length2()
end

local function stance(actor)
    local ok, value = pcall(types.Actor.getStance, actor)
    return ok and value or nil
end

local function fight(actor)
    local ok, value = pcall(function()
        return types.Actor.stats.ai.fight(actor).modified
    end)
    return ok and tonumber(value) or nil
end

local function disposition(actor)
    if not valid(state.caster) or not types.NPC.objectIsInstance(actor) then return nil end
    local ok, value = pcall(types.NPC.getDisposition, actor, state.caster)
    return ok and tonumber(value) or nil
end

local function isCreature(actor)
    return types.Creature and types.Creature.objectIsInstance(actor)
end

local function isCombatReady(actor)
    local s = stance(actor)
    return s ~= nil and s ~= types.Actor.STANCE.Nothing
end

local function hasLineOfSight(target)
    local from = self.position + util.vector3(0, 0, 40)
    local to = target.position + util.vector3(0, 0, common.objectHeightOffset(target, 80))
    local ok, hit = pcall(nearby.castRay, from, to, { ignore = self })
    if not ok or not hit or not hit.hit then return true end
    return hit.hitObject == nil or sameObject(hit.hitObject, target)
end

local function pruneHostileActorCache()
    state.hostileActors = state.hostileActors or {}
    state.playerAllies = state.playerAllies or {}
    local now = core.getSimulationTime()

    for id, expires in pairs(state.hostileActors) do
        if (tonumber(expires) or 0) <= now then
            state.hostileActors[id] = nil
        end
    end

    for id, expires in pairs(state.playerAllies) do
        if (tonumber(expires) or 0) <= now then
            state.playerAllies[id] = nil
        end
    end
end

local function isKnownPlayerAlly(actor)
    if not valid(actor) then return false end
    pruneHostileActorCache()

    local expires = state.playerAllies and state.playerAllies[actor.id]
    return expires ~= nil and expires > core.getSimulationTime()
end

local function isKnownHostileToPlayerSide(actor)
    if not valid(actor) then return false end
    pruneHostileActorCache()

    local expires = state.hostileActors and state.hostileActors[actor.id]
    return expires ~= nil and expires > core.getSimulationTime()
end

local function likelyHostileFallback(actor)
    -- Fallback path for engines/modded actors where no active Combat target is
    -- visible through the AI interface.  This is intentionally weaker than the
    -- old Fight-based rule for NPCs: friendly high-disposition NPCs are ignored,
    -- so followers do not become targets merely because their Fight value is high.
    if not isCombatReady(actor) then return false end

    if types.NPC.objectIsInstance(actor) then
        local d = disposition(actor)
        if d ~= nil then
            if d >= common.friendlyNpcDispositionCutoff then return false end
            if d < common.hostileNpcDispositionCutoff then return true end
        end

        local f = fight(actor)
        return f ~= nil and f >= common.npcFightFallbackCutoff
    end

    if isCreature(actor) then
        local f = fight(actor)
        return f == nil or f >= common.creatureFightFallbackCutoff
    end

    local f = fight(actor)
    return f ~= nil and f >= common.npcFightFallbackCutoff
end

local function isHostileToPlayer(actor)
    if not valid(actor) then return false end
    if isKnownPlayerAlly(actor) then return false end
    if isKnownHostileToPlayerSide(actor) then return true end
    return likelyHostileFallback(actor)
end

local function hostilityCandidates()
    local actors = {}

    for _, actor in ipairs(nearby.actors) do
        if isActor(actor)
            and not isDead(actor)
            and not sameObject(actor, self.object)
            and not sameObject(actor, state.caster)
            and not types.Player.objectIsInstance(actor)
            and distance2(actor) <= state.targetRadius * state.targetRadius
            and hasLineOfSight(actor)
        then
            table.insert(actors, actor)
        end
    end

    return actors
end

local function requestHostilityState(force)
    local now = core.getSimulationTime()
    if not force and now < (state.nextHostilityRequest or 0) then return end

    state.nextHostilityRequest = now + common.hostilityRequestInterval
    core.sendGlobalEvent('RT_QuerySoulWispHostility', {
        wisp = self.object,
        actors = hostilityCandidates(),
    })
end

local function onHostilityState(data)
    if not data or not sameObject(data.wisp, self.object) then return end

    state.hostileActors = {}
    state.playerAllies = {}
    local expires = core.getSimulationTime() + (tonumber(data.cacheDuration) or common.hostilityCacheDuration)

    for _, actor in ipairs(data.actors or {}) do
        if valid(actor) then
            state.hostileActors[actor.id] = expires
        end
    end

    for _, actor in ipairs(data.allies or {}) do
        if valid(actor) then
            state.playerAllies[actor.id] = expires
        end
    end
end

local function validTarget(actor)
    return isActor(actor)
        and not isDead(actor)
        and not sameObject(actor, self.object)
        and not sameObject(actor, state.caster)
        and not types.Player.objectIsInstance(actor)
        and distance2(actor) <= state.targetRadius * state.targetRadius
        and isHostileToPlayer(actor)
        and hasLineOfSight(actor)
end

local function findTarget()
    requestHostilityState(false)
    local best = nil
    local bestDistance = math.huge

    for _, actor in ipairs(nearby.actors) do
        if validTarget(actor) then
            local d2 = distance2(actor)
            if d2 < bestDistance then
                best = actor
                bestDistance = d2
            end
        end
    end

    return best
end

local function targetPoint(target)
    return target.position + util.vector3(0, 0, common.objectHeightOffset(target, 80))
end

local function normalisePayloadIds(value)
    if not value then return nil end
    if type(value) == 'string' then return { value } end
    if type(value) ~= 'table' then return nil end

    if value.payloadSpellIds then
        return normalisePayloadIds(value.payloadSpellIds)
    end
    if value.payloadSpellId then
        return normalisePayloadIds(value.payloadSpellId)
    end

    local ids = {}
    for _, id in ipairs(value) do
        if type(id) == 'string' then table.insert(ids, id) end
    end
    if #ids == 0 then return nil end
    return ids
end

local function clamp01(x)
    if x < 0 then return 0 end
    if x > 1 then return 1 end
    return x
end

local function smoothstep(x)
    x = clamp01(x)
    return x * x * (3 - 2 * x)
end

local function updateVisualScale()
    local fadeTime = tonumber(state.fadeOutTime) or common.fadeOutTime
    if fadeTime <= 0 then return end

    local t = clamp01(state.duration / fadeTime)
    local scale = smoothstep(t)

    core.sendGlobalEvent('RT_SetSoulWispScale', {
        wisp = self.object,
        scale = scale,
    })
end

local function pulse()
    local startPos = self.position + util.vector3(0, 0, 40)

    if not validTarget(state.target) then
        state.target = findTarget()
    end
    if not validTarget(state.target) then return end

    local direction = targetPoint(state.target) - startPos
    if direction:length2() <= 0.0001 then return end
    
    core.sendGlobalEvent('RT_SoulWispPulse', {
        caster = state.caster,
        wisp = self.object,
        target = state.target,
        payloadSpellIds = state.payloadSpellIds,
        payloadSpellId = state.payloadSpellId,
        sourceSpellName = state.sourceSpellName,
        startPos = startPos,
        direction = direction:normalize(),
        magnitude = state.magnitude,
        projectileSpeed = state.projectileSpeed,
    })
end

local function initialise(data)
    data = data or {}
    for key, value in pairs(data) do
        state[key] = value
    end
    state.payloadSpellIds = normalisePayloadIds(state.payloadSpellIds or state.payloadSpellId)
    state.payloadSpellId = state.payloadSpellIds and state.payloadSpellIds[1] or state.payloadSpellId
    state.interval = math.max(0.1, tonumber(state.interval) or 2)
    state.duration = math.max(0.1, tonumber(state.duration) or common.defaultDuration)
    state.fadeOutTime = math.max(0, tonumber(state.fadeOutTime) or common.fadeOutTime)
    state.targetRadius = math.max(1, tonumber(state.targetRadius) or common.defaultRadius)
    state.projectileSpeed = common.projectileSpeedFromMagnitude(state.magnitude)
    state.hostileActors = {}
    state.nextHostilityRequest = 0
    state.removing = false
end

local function removeSelf()
    if state.removing then return end
    state.removing = true
    core.sendGlobalEvent('RT_RemoveSoulWisp', { wisp = self.object })
end

return {
    eventHandlers = {
        RT_SoulWispHostilityState = onHostilityState,
    },
    engineHandlers = {
        onInit = initialise,
        onLoad = function(save)
            initialise(save)
        end,
        onSave = function()
            local saved = {}
            for key, value in pairs(state) do
                if key ~= 'hostileActors' and key ~= 'nextHostilityRequest' then
                    saved[key] = value
                end
            end
            return saved
        end,
        onUpdate = function(dt)
            if state.removing then return end

            state.duration = state.duration - dt
            updateVisualScale()

            if state.duration <= 0 then
                removeSelf()
                return
            end

            requestHostilityState(false)

            state.cooldown = state.cooldown - dt
            if state.cooldown > 0 then return end
            state.cooldown = state.interval
            pulse()
        end,
    },
}
