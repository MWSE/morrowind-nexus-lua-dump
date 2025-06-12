local core = require('openmw.core')
local T = require('openmw.types')
local self = require('openmw.self')

local mDef = require('scripts.HBFS.config.definition')
local mTools = require('scripts.HBFS.util.tools')
local log = require('scripts.HBFS.util.log')

local actorId = mTools.actorId(self)
local actorRecord = self.type.record(self)

local function newStats()
    return { attributes = {}, dynamicStats = {} }
end

local state = {
    version = mDef.gameSaveVersion,
    baseStats = nil,
    updatedStats = nil,
    areDefaultSettings = true,
    -- is the actor already dead?
    isCorpse = T.Actor.isDead(self),
    -- save it before any fight start
    baseFightValue = T.Actor.stats.ai.fight(self).base,
}

local function statsToString(stats)
    local items = {}
    for id, value in pairs(stats.attributes) do
        table.insert(items, string.format("%s=%d", id, value))
    end
    for id, value in pairs(stats.dynamicStats) do
        table.insert(items, string.format("%s=%d", id, value))
    end
    return table.concat(items, ", ")
end

local function detectStatsDiffs()
    for attributeId, getter in pairs(T.Actor.stats.attributes) do
        local diff = getter(self).base - state.updatedStats.attributes[attributeId]
        if math.floor(diff + .5) ~= 0 then
            state.baseStats.attributes[attributeId] = getter(self).base
            log(string.format("%s's %s has been changed by %d since last check (%d -> %d)",
                    actorId, attributeId, diff, getter(self).base - diff, getter(self).base))
        end
    end

    for statId, getter in pairs(T.Actor.stats.dynamic) do
        local diff = getter(self).base - state.updatedStats.dynamicStats[statId]
        if math.floor(diff + .5) ~= 0 then
            state.baseStats.dynamicStats[statId] = getter(self).base
            log(string.format("%s's %s has been changed by %d since last check (%d -> %d)",
                    actorId, statId, diff, getter(self).base - diff, getter(self).base))
        end
    end
end

local function getDynamicStatRatio(getter)
    return getter(self).base == 0 and 0 or getter(self).current / getter(self).base
end

local function restoreStats()
    for attributeId, getter in pairs(T.Actor.stats.attributes) do
        getter(self).base = state.baseStats.attributes[attributeId]
    end

    for statId, getter in pairs(T.Actor.stats.dynamic) do
        local ratio = getDynamicStatRatio(getter)
        getter(self).base = state.baseStats.dynamicStats[statId]
        getter(self).current = getter(self).base * ratio
    end

    log(string.format("%s stats have been restored: %s", actorId, statsToString(state.baseStats)))
end

local function applyNewStats(settings)
    state.updatedStats = newStats()

    for attributeId, getter in pairs(T.Actor.stats.attributes) do
        getter(self).base = state.baseStats.attributes[attributeId] * settings.attributes[attributeId] / 100
        state.updatedStats.attributes[attributeId] = getter(self).base
    end

    for statId, getter in pairs(T.Actor.stats.dynamic) do
        local ratio = getDynamicStatRatio(getter)
        getter(self).base = state.baseStats.dynamicStats[statId] * settings.dynamicStats[statId] / 100
        getter(self).current = getter(self).base * ratio
        state.updatedStats.dynamicStats[statId] = getter(self).base
    end

    log(string.format("%s stats have been updated: %s", actorId, statsToString(state.updatedStats)))
end

local function saveBaseStats()
    state.baseStats = newStats()

    for attributeId, getter in pairs(T.Actor.stats.attributes) do
        state.baseStats.attributes[attributeId] = getter(self).base
    end
    for statId, getter in pairs(T.Actor.stats.dynamic) do
        state.baseStats.dynamicStats[statId] = getter(self).base
    end
end

local function setStats(settings)
    if not settings.areActorsDefault then
        saveBaseStats()
        applyNewStats(settings)
    end
end

-- actor's stats shall be vanilla here
local function onActive(settings, eventType)
    if state.baseStats then
        log(string.format("%s's stats are already set", actorId))
    else
        setStats(settings)
    end
    self:sendEvent(mDef.events.onActorReady, { settings = settings, type = eventType })
    state.areDefaultSettings = settings.areActorsDefault
end

-- stats update while the actor is active
local function updateStats(settings, eventType)
    if not state.updatedStats or state.areDefaultSettings then
        if not state.updatedStats then
            log(string.format("%s has no stats to update", actorId))
        end
        setStats(settings)
    else
        detectStatsDiffs()
        if settings.areActorsDefault then
            restoreStats()
        else
            applyNewStats(settings)
        end
    end
    self:sendEvent(mDef.events.onActorReady, { settings = settings, type = eventType })
    state.areDefaultSettings = settings.areActorsDefault
end

local function onDied()
    if actorRecord.class == "guard" then
        core.sendGlobalEvent(mDef.events.forwardToPlayers, { data = self, event = mDef.events.setGuardOwnedItems })
    end
    core.sendGlobalEvent(mDef.events.onActorDied, { actor = self, state = state })
end

local function onInactive()
    if not state.baseStats then
        log(string.format("%s has no stats to restore", actorId))
        return
    end
    if not state.areDefaultSettings then
        detectStatsDiffs()
        restoreStats()
    end
    state.baseStats = nil
    state.updatedStats = nil
end

local function onInit()
    if state.isCorpse then
        onDied()
    end
end

local function onSave()
    return {
        state = state,
        version = mDef.gameSaveVersion,
    }
end

local function onLoad(data)
    if not data then
        onInit()
        return
    end
    local version = data.version or 1.0
    if version < 2.1 then
        local newData = {
            version = 2.1,
            state = data,
        }
        data = newData
        data.state.isCorpse = state.isCorpse
        data.state.baseFightValue = state.baseFightValue
    end

    state = data.state

    if version < 2.1 then
        onInit()
    end
end

return {
    interfaceName = mDef.MOD_NAME,
    interface = {
        version = mDef.interfaceVersion,
        getState = function() return state end,
    },
    engineHandlers = {
        onInit = onInit,
        onInactive = onInactive,
        onSave = onSave,
        onLoad = onLoad,
    },
    eventHandlers = {
        [mDef.events.onActorActive] = function(data) onActive(data.settings, data.type) end,
        [mDef.events.updateActorStats] = function(data) updateStats(data.settings, data.type) end,
        Died = onDied,
    },
}
