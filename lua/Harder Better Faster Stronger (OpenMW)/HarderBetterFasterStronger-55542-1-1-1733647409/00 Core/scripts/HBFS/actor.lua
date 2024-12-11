local T = require('openmw.types')
local self = require('openmw.self')

local mTools = require('scripts.HBFS.tools')

local actorId = mTools.actorId(self)

local function newState()
    return {
        baseStats = { attributes = {}, dynamicStats = {} },
        updatedStats = { attributes = {}, dynamicStats = {} },
    }
end

local state

local function getHealthRatio(getter)
    return (getter(self).base == 0) and 0 or getter(self).current / getter(self).base
end

local function restoreStats()
    if not state then return end

    for attributeId, getter in pairs(T.Actor.stats.attributes) do
        local diff = getter(self).base - state.updatedStats.attributes[attributeId]
        getter(self).base = state.baseStats.attributes[attributeId] + diff
    end

    for statId, getter in pairs(T.Actor.stats.dynamic) do
        local ratio = getHealthRatio(getter)
        local diff = getter(self).base - state.updatedStats.dynamicStats[statId]
        getter(self).base = state.baseStats.dynamicStats[statId] + diff
        getter(self).current = getter(self).base * ratio
    end
    state = nil
    mTools.debugPrint(string.format("%s changed stats have been restored", actorId))
end

local function updateStats(settings)
    if state then
        restoreStats()
        if settings.areDefault then return end
    end
    state = newState()
    for attributeId, getter in pairs(T.Actor.stats.attributes) do
        state.baseStats.attributes[attributeId] = getter(self).base
        getter(self).base = getter(self).base * settings.attributes[attributeId] / 100
        state.updatedStats.attributes[attributeId] = getter(self).base
    end

    for statId, getter in pairs(T.Actor.stats.dynamic) do
        state.baseStats.dynamicStats[statId] = getter(self).base
        local ratio = getHealthRatio(getter)
        getter(self).base = getter(self).base * settings.dynamicStats[statId] / 100
        getter(self).current = getter(self).base * ratio
        state.updatedStats.dynamicStats[statId] = getter(self).base
    end
    mTools.debugPrint(string.format("%s stats have been updated", actorId))
end

local function onInactive()
    restoreStats()
end

local function onSave()
    return state
end

local function onLoad(data)
    state = data
end

return {
    engineHandlers = {
        onInactive = onInactive,
        onSave = onSave,
        onLoad = onLoad,
    },
    eventHandlers = {
        hbfs_updateStats = updateStats,
    },
}
