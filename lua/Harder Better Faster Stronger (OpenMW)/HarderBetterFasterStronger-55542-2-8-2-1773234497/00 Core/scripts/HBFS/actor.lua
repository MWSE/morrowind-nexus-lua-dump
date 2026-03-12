local core = require('openmw.core')
local I = require("openmw.interfaces")
local T = require('openmw.types')
local self = require('openmw.self')

local mDef = require('scripts.HBFS.config.definition')
if not mDef.isOpenMW49OrAbove then return end

local log = require('scripts.HBFS.util.log')
local mTools = require('scripts.HBFS.util.tools')

local lastUpdateTime = 0
local state

local function newState()
    return {
        baseStats = nil,
        updatedStats = nil,
        followsPlayer = false,
        followerPercent = nil,
        summonPercent = nil,
        noBackRunningActors = false,
        baseFightValue = T.Actor.stats.ai.fight(self).base,
    }
end

local function isPlayerFollower()
    for _, following in ipairs(I.AI.getTargets("Follow")) do
        if following.type == T.Player then
            return true
        end
    end
    return false
end

local function checkFollowsPlayer()
    local wasPlayerFollower = state.followsPlayer
    state.followsPlayer = isPlayerFollower()
    local changed = wasPlayerFollower ~= state.followsPlayer
    if changed then
        if wasPlayerFollower then
            log("Stops following the player")
        else
            log("Starts following the player")
        end
    end
    return changed
end

local function newStats()
    return { attributes = {}, dynamicStats = {} }
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
    log("Base stats have been saved")
end

local function detectStatsDiffs()
    if not state.updatedStats then return end

    for attributeId, getter in pairs(T.Actor.stats.attributes) do
        local diff = getter(self).base - state.updatedStats.attributes[attributeId]
        if math.floor(diff + .5) ~= 0 then
            state.baseStats.attributes[attributeId] = getter(self).base
            log(string.format("%s has been changed by %d since last check (%d -> %d)",
                    attributeId, diff, getter(self).base - diff, getter(self).base))
        end
    end

    for statId, getter in pairs(T.Actor.stats.dynamic) do
        local diff = getter(self).base - state.updatedStats.dynamicStats[statId]
        if math.floor(diff + .5) ~= 0 then
            state.baseStats.dynamicStats[statId] = getter(self).base
            log(string.format("%s has been changed by %d since last check (%d -> %d)",
                    statId, diff, getter(self).base - diff, getter(self).base))
        end
    end
end

local function getStatFactor(percent, followerFactor)
    return 1 + (percent / 100 - 1) * followerFactor
end

local function computeNewStats()
    state.updatedStats = newStats()

    local followerFactor = 1
    if state.summonPercent then
        followerFactor = state.summonPercent / 100
    elseif state.followsPlayer then
        followerFactor = state.followerPercent / 100
    end

    for attributeId in pairs(T.Actor.stats.attributes) do
        state.updatedStats.attributes[attributeId] = math.floor(0.5 + state.baseStats.attributes[attributeId] * getStatFactor(state.attributes[attributeId], followerFactor))
    end

    for statId in pairs(T.Actor.stats.dynamic) do
        state.updatedStats.dynamicStats[statId] = math.floor(0.5 + state.baseStats.dynamicStats[statId] * getStatFactor(state.dynamicStats[statId], followerFactor))
    end

    log(string.format("Stats have been computed%s: %s",
            state.followsPlayer and string.format(" (followerFactor=%.3f)", followerFactor) or "",
            mTools.statsToString(state.baseStats, state.updatedStats)))
end

local function getDynamicStatRatio(getter)
    return getter(self).base == 0 and 0 or getter(self).current / getter(self).base
end

local function applyNewStats()
    for attributeId, getter in pairs(T.Actor.stats.attributes) do
        getter(self).base = state.updatedStats.attributes[attributeId]
    end

    for statId, getter in pairs(T.Actor.stats.dynamic) do
        local ratio = getDynamicStatRatio(getter)
        getter(self).base = state.updatedStats.dynamicStats[statId]
        getter(self).current = getter(self).base * ratio
    end

    log("New stats have been applied")
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

    log(string.format("Stats have been restored: %s", mTools.statsToString(state.updatedStats, state.baseStats)))
end

local function setStats(settings, eventType)
    if not state then
        log("Is inactive: Don't update his stats")
        return
    end
    mTools.copyMap(settings, state)
    checkFollowsPlayer()
    saveBaseStats()
    detectStatsDiffs()
    computeNewStats()
    applyNewStats()
    -- for other mods
    self:sendEvent(mDef.events.onActorReady, { settings = settings, type = eventType })
end

-- only save base fight value (in global script) when it first changes
local function checkBaseFightValue()
    if state.baseFightValue and state.baseFightValue ~= T.Actor.stats.ai.fight(self).base then
        core.sendGlobalEvent(mDef.events.initActorData, { actor = self, data = { baseFightValue = state.baseFightValue } })
    end
end

local function onInit()
    local data = {}
    if T.Actor.isDead(self) then
        data.isCorpse = true
    end
    if self.type == T.Creature and isPlayerFollower() then
        data.playerSummon = true
    end
    if next(data) then
        core.sendGlobalEvent(mDef.events.initActorData, { actor = self, data = data })
    end
end

local function onActive()
    state = state or newState()
end

local function onUpdate(deltaTime)
    if deltaTime == 0 or not state then return end

    -- check the stance because it's faster than checking controls
    if state.noBackRunningActors
            and T.Actor.getStance(self) ~= T.Actor.STANCE.Nothing
            and self.controls.run == true
            and self.controls.movement < 0 then
        self.controls.run = false
    end

    lastUpdateTime = lastUpdateTime + deltaTime
    if lastUpdateTime < 2 then return end
    lastUpdateTime = 0

    if checkFollowsPlayer() then
        detectStatsDiffs()
        computeNewStats()
        applyNewStats()
    end
end

local function onInactive()
    if not state then
        log("Is already inactive: No stats to restore")
        return
    end
    if state.baseStats then
        if state.updatedStats then
            detectStatsDiffs()
        end
        restoreStats()
    else
        log("Has no stats to restore")
    end
    checkBaseFightValue()
    state = nil
end

local function onDied()
    checkBaseFightValue()
    if self.type.record(self).class == "guard" then
        core.sendGlobalEvent(mDef.events.forwardToPlayers, { data = self, event = mDef.events.setGuardOwnedItems })
    end
    core.sendGlobalEvent(mDef.events.onActorDied, self)
end

local function onSave()
    if not state then return end
    checkBaseFightValue()
    return {
        state = state,
        version = mDef.saveVersion,
    }
end

local function onLoad(data)
    if not data then return end

    local version = data.version or 1.0

    if version < 2.6 and version >= 2.1 then
        local update = {}
        if data.state.isCorpse then
            update.isCorpse = true
        end
        data.state.isCorpse = nil
        if data.state.baseFightValue ~= T.Actor.stats.ai.fight(self).base then
            update.baseFightValue = data.state.baseFightValue
        end
        if next(update) then
            core.sendGlobalEvent(mDef.events.initActorData, { actor = self, data = update })
        end
    end

    if version == 2.61 then
        data.state.baseFightValue = T.Actor.stats.ai.fight(self).base
    end

    state = data.state
end

return {
    interfaceName = mDef.MOD_NAME,
    interface = {
        version = mDef.interfaceVersion,
        getState = function() return state end,
    },
    engineHandlers = {
        onInit = onInit,
        onActive = onActive,
        onUpdate = onUpdate,
        onInactive = onInactive,
        onSave = onSave,
        onLoad = onLoad,
    },
    eventHandlers = {
        [mDef.events.setActorStats] = function(data) setStats(data.settings, data.type) end,
        Died = onDied,
    },
}
