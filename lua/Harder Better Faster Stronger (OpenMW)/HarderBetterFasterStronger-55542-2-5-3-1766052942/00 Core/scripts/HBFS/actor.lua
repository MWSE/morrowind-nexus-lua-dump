local core = require('openmw.core')
local I = require("openmw.interfaces")
local T = require('openmw.types')
local self = require('openmw.self')

local mDef = require('scripts.HBFS.config.definition')
if not mDef.isOpenMW49OrAbove then return end
local mTools = require('scripts.HBFS.util.tools')
local log = require('scripts.HBFS.util.log')

local actorId = mTools.actorId(self)
local actorRecord = self.type.record(self)
local lastUpdateTime = 0

local function newStats()
    return { attributes = {}, dynamicStats = {} }
end

local state = {
    version = mDef.gameSaveVersion,
    baseStats = nil,
    updatedStats = nil,
    -- is the actor already dead?
    isCorpse = T.Actor.isDead(self),
    -- save it before any fight start
    baseFightValue = T.Actor.stats.ai.fight(self).base,
    follower = nil,
    excludeNPCFollowers = false,
    excludeCreatureFollowers = false,
    noBackRunning = false,
    isExcluded = false,
}

local function isExcluded()
    if not state.excludeNPCFollowers and not state.excludeCreatureFollowers then
        return false
    end
    local followings = I.AI.getTargets("Follow")
    for _, following in ipairs(followings) do
        if following.type == T.Player and
                (state.excludeNPCFollowers and self.type == T.NPC or state.excludeCreatureFollowers and self.type == T.Creature) then
            log(string.format("%s is excluded", actorId))
            return true
        end
    end
    return false
end

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
    if not state.updatedStats then return end
    local stats = state.isExcluded and state.baseStats or state.updatedStats

    for attributeId, getter in pairs(T.Actor.stats.attributes) do
        local diff = getter(self).base - stats.attributes[attributeId]
        if math.floor(diff + .5) ~= 0 then
            state.baseStats.attributes[attributeId] = getter(self).base
            log(string.format("%s's %s has been changed by %d since last check (%d -> %d)",
                    actorId, attributeId, diff, getter(self).base - diff, getter(self).base))
        end
    end

    for statId, getter in pairs(T.Actor.stats.dynamic) do
        local diff = getter(self).base - stats.dynamicStats[statId]
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

local function saveBaseStats()
    if state.baseStats then return end
    state.baseStats = newStats()

    for attributeId, getter in pairs(T.Actor.stats.attributes) do
        state.baseStats.attributes[attributeId] = getter(self).base
    end
    for statId, getter in pairs(T.Actor.stats.dynamic) do
        state.baseStats.dynamicStats[statId] = getter(self).base
    end
end

local function computeNewStats(settings)
    state.updatedStats = newStats()

    for attributeId in pairs(T.Actor.stats.attributes) do
        state.updatedStats.attributes[attributeId] = state.baseStats.attributes[attributeId] * settings.attributes[attributeId] / 100
    end

    for statId in pairs(T.Actor.stats.dynamic) do
        state.updatedStats.dynamicStats[statId] = state.baseStats.dynamicStats[statId] * settings.dynamicStats[statId] / 100
    end

    log(string.format("%s stats have been computed: %s", actorId, statsToString(state.updatedStats)))
end

local function applyNewStats()
    local stats = state.isExcluded and state.baseStats or state.updatedStats

    for attributeId, getter in pairs(T.Actor.stats.attributes) do
        getter(self).base = stats.attributes[attributeId]
    end

    for statId, getter in pairs(T.Actor.stats.dynamic) do
        local ratio = getDynamicStatRatio(getter)
        getter(self).base = stats.dynamicStats[statId]
        getter(self).current = getter(self).base * ratio
    end

    log(string.format("%s stats have been updated", actorId))
end

local function setStats(settings)
    if settings.areActorsDefault then return end
    saveBaseStats()
    computeNewStats(settings)
    applyNewStats()
end

-- actor's stats shall be vanilla here
local function onActive(settings, eventType)
    state.excludeNPCFollowers = settings.excludeNPCFollowers
    state.excludeCreatureFollowers = settings.excludeCreatureFollowers
    state.noBackRunning = settings.noBackRunningActors
    state.isExcluded = isExcluded()

    if state.baseStats then
        log(string.format("%s's stats are already set", actorId))
    else
        setStats(settings)
    end
    self:sendEvent(mDef.events.onActorReady, { settings = settings, type = eventType })
end

-- stats update while the actor is active
local function updateStats(settings, eventType)
    state.excludeNPCFollowers = settings.excludeNPCFollowers
    state.excludeCreatureFollowers = settings.excludeCreatureFollowers
    state.noBackRunning = settings.noBackRunningActors
    local excluded = isExcluded()

    if not state.updatedStats then
        state.isExcluded = excluded
        log(string.format("%s has no stats to update (unlikely)", actorId))
        setStats(settings)
    else
        detectStatsDiffs()
        computeNewStats(settings)
        state.isExcluded = excluded
        applyNewStats()
    end
    self:sendEvent(mDef.events.onActorReady, { settings = settings, type = eventType })
end

local function onUpdate(deltaTime)
    if deltaTime == 0 then return end
    -- check the stance because it's faster than checking controls
    if state.noBackRunning and T.Actor.getStance(self) ~= T.Actor.STANCE.Nothing and self.controls.run == true and self.controls.movement < 0 then
        self.controls.run = false
    end
    if not state.isExcluded and not state.excludeNPCFollowers and not state.excludeCreatureFollowers then
        return
    end
    lastUpdateTime = lastUpdateTime + deltaTime
    if lastUpdateTime < 2 then return end
    lastUpdateTime = 0
    local follower = I.AI.getActiveTarget("Follow")
    if mTools.areObjectEquals(follower, state.follower) then
        return
    end
    if isExcluded() then
        if not state.isExcluded then
            restoreStats()
        end
        state.isExcluded = true
    elseif state.isExcluded then
        state.isExcluded = false
        applyNewStats()
    end
    state.follower = follower
end

local function onInactive()
    if not state.baseStats then
        log(string.format("%s has no stats to restore", actorId))
        return
    end
    detectStatsDiffs()
    restoreStats()
    state.baseStats = nil
    state.updatedStats = nil
end

local function onDied()
    if actorRecord.class == "guard" then
        core.sendGlobalEvent(mDef.events.forwardToPlayers, { data = self, event = mDef.events.setGuardOwnedItems })
    end
    core.sendGlobalEvent(mDef.events.onActorDied, { actor = self, state = state })
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
        onUpdate = onUpdate,
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
