local T = require("openmw.types")
local I = require("openmw.interfaces")
local core = require("openmw.core")
local input = require("openmw.input")
local async = require('openmw.async')
local self = require("openmw.self")
local nearby = require("openmw.nearby")
local ui = require("openmw.ui")
local util = require("openmw.util")

local log = require("scripts.fresh-loot.util.log")
local mDef = require("scripts.fresh-loot.config.definition")
local mCfg = require("scripts.fresh-loot.config.configuration")
local mT = require("scripts.fresh-loot.config.types")
local mObj = require("scripts.fresh-loot.util.objects")
local mHelpers = require("scripts.fresh-loot.util.helpers")
local mLocal = require("scripts.fresh-loot.util.local")
local mUi = require("scripts.fresh-loot.util.ui")

local l10n = core.l10n(mDef.MOD_NAME);

input.registerAction {
    key = mDef.actions.showItems,
    type = input.ACTION_TYPE.Boolean,
    l10n = mDef.MOD_NAME,
    defaultValue = false,
}

I.Settings.registerPage {
    key = mDef.MOD_NAME,
    l10n = mDef.MOD_NAME,
    name = "name",
    description = "description",
}

local lastCheckContainersTime = 0
local knownContainers = {}
local actorStatsCache = {}

local requests = {
    produced = {},
    forwarded = {},
    sizes = {},
    id = 0,
}

local function setLootsStats(requestId)
    local lootsStats = requests.forwarded[requestId]
    local actorsStats = mHelpers.arraysToMap(requests.produced[requestId], function(_stats) return _stats.actor.id end)
    requests.produced[requestId] = nil
    requests.forwarded[requestId] = nil
    requests.sizes[requestId] = nil

    for _, lootStats in ipairs(lootsStats) do
        for actorId, levelStats in pairs(lootStats.levelStats) do
            local actorStats = actorsStats[actorId]
            if actorStats then
                levelStats.still = actorStats.packageType == "Wander"
                        and actorStats.wanderDistance == 0
                levelStats.movesAround = actorStats.packageType == "Wander"
                        and actorStats.wanderDistance + (lootStats.container.position - actorStats.actor.position):length()
                        < mCfg.lootLevel.maxKeepersProtectLootDistance
            else
                log(string.format("No actor stats computed for actor \"%s\"", actorId))
            end
        end
    end
    core.sendGlobalEvent(mDef.events.setLootsStats, lootsStats)
end

local function requestActorsStats(actors, lootsStats)
    requests.id = requests.id + 1
    requests.produced[requests.id] = {}
    requests.forwarded[requests.id] = lootsStats
    local requestId = requests.id
    local count = 0
    local cached = 0
    for _, actor in pairs(actors) do
        count = count + 1
        if actorStatsCache[actor.id] then
            cached = cached + 1
            table.insert(requests.produced[requestId], actorStatsCache[actor.id])
        else
            core.sendGlobalEvent(mDef.events.requestActorStats, {
                actor = actor,
                responseEvent = mT.new.requestEvent(mDef.events.returnActorStats, self, nil, requestId),
            })
        end
    end
    log(string.format("Requested %d actors stats, and %d were already cached", count, cached))
    requests.sizes[requestId] = count
    if count == cached then
        setLootsStats(requestId)
    end
end

local function gatherActorsStats(stats, requestId)
    actorStatsCache[stats.actor.id] = stats
    table.insert(requests.produced[requestId], stats)
    if #requests.produced[requestId] >= requests.sizes[requestId] then
        setLootsStats(requestId)
    end
end

local function getLootKeeperStats(actor, container)
    local path = mLocal.getPath(actor, container, mCfg.lootLevel.maxKeepersReachLootDistance)
    if not path then
        log(string.format("Actor %s cannot reach container %s", mObj.objectId(actor), mObj.objectId(container)), mT.logLevels.Debug)
        return
    end
    local distance, time = mLocal.getTravelStats(actor, path)
    local seeLoot = mLocal.trySeeDestination(actor, path[#path])
    if distance > mCfg.lootLevel.maxKeepersTravelDistance
            and time > mCfg.lootLevel.maxKeepersTravelTime then return end
    return mT.new.lootKeeperStats(
            mObj.getActorLevel(actor),
            actor.recordId,
            actor.type == T.Creature,
            not mObj.isActorHostile(actor),
            distance,
            time,
            seeLoot)
end

local function addLootsLocalStats(lootsGlobalStats)
    local lootsStats = {}
    local actorsStatsToGet = {}
    local actorsWatchedLoots = {}
    local allDoorsBoosts = {}
    for _, lootGlobalStats in ipairs(lootsGlobalStats) do
        local hasStats = false
        local container = lootGlobalStats.container

        local doorsBoosts
        if lootGlobalStats.toBeAnalyzed then
            doorsBoosts = mLocal.getDoorsBoosts(self, container, allDoorsBoosts)
            if next(doorsBoosts) then
                hasStats = true
                mHelpers.addAllToMap(allDoorsBoosts, doorsBoosts)
                log(string.format("Container \"%s\" is blocked by doors: %s",
                        container, mHelpers.tableToString(doorsBoosts, 2)), mT.logLevels.Debug)
            end
        end

        local levelStats = {}
        for _, actor in ipairs(lootGlobalStats.actors) do
            local stats = getLootKeeperStats(actor, container)
            if stats then
                hasStats = true
                actorsStatsToGet[actor.id] = actor
                actorsWatchedLoots[actor.id] = actorsWatchedLoots[actor.id] and (actorsWatchedLoots[actor.id] + 1) or 1
                levelStats[actor.id] = stats
            end
        end
        if hasStats and lootGlobalStats.toBeAnalyzed then
            table.insert(lootsStats, mT.new.containerLocalStats(
                    container,
                    levelStats,
                    lootGlobalStats.levelStatsOverride,
                    doorsBoosts))
        end
    end
    for _, lootStats in ipairs(lootsStats) do
        for actorId, stats in pairs(lootStats.levelStats) do
            stats.watchedLoots = actorsWatchedLoots[actorId] or 0
        end
    end
    if next(actorsStatsToGet) then
        requestActorsStats(actorsStatsToGet, lootsStats)
    else
        core.sendGlobalEvent(mDef.events.setLootsStats, lootsStats)
    end
end

local function isActorCloseEnough(actor, containers)
    for _, containerData in ipairs(containers) do
        if containerData.toBeAnalyzed and (actor.position - containerData.object.position):length() < mCfg.lootLevel.maxKeepersSearchDistance then
            return true
        end
    end
    return false
end

local function checkNewContainers()
    local newContainers = 0
    local containersData = {}

    for _, container in ipairs(nearby.containers) do
        if not knownContainers[container.id] then
            local dist = (self.position - container.position):length()
            -- containers in player's reach
            if dist < mCfg.lootLevel.maxKeepersSearchDistance then
                knownContainers[container.id] = container
                newContainers = newContainers + 1
            end
            -- containers in player and actors' reach
            if dist < 2 * mCfg.lootLevel.maxKeepersSearchDistance then
                table.insert(containersData, mT.new.newContainerData(container, knownContainers[container.id] ~= nil))
            end
        end
    end
    if newContainers == 0 then return end
    local closeActors = {}
    for _, actor in ipairs(nearby.actors) do
        if actor.type ~= T.Player and isActorCloseEnough(actor, containersData) then
            table.insert(closeActors, actor)
        end
    end
    log(string.format("Found %d new containers (%d in actors' reach) around with %d actors close enough", newContainers, #containersData, #closeActors))
    core.sendGlobalEvent(mDef.events.onNewContainers, mT.new.newContainersData(containersData, closeActors, self))
end

local function onUpdate(deltaTime)
    lastCheckContainersTime = lastCheckContainersTime + deltaTime
    if lastCheckContainersTime < mCfg.containerSearch.frequencySec then return end
    lastCheckContainersTime = 0
    checkNewContainers()
end

local function checkNewContainersNow()
    lastCheckContainersTime = mCfg.containerSearch.frequencySec - mCfg.containerSearch.navigationMeshGenDelay
end

local function clearNewContainers()
    knownContainers = {}
    checkNewContainersNow()
end

local function onActive()
    checkNewContainersNow()
end

local function onTeleported()
    checkNewContainersNow()
end

local function showMessage(message)
    if not message.quiet then
        ui.showMessage(string.format("%s: %s", l10n("name"), message.text))
    end
    log(message.text)
end

local function uiModeChanged(data)
    log(string.format("UI mode changed from %s to %s, target is %s", data.oldMode, data.newMode, data.arg))
    if data.newMode == "MainMenu" then
        mUi.toggleItemWindow()
    end
end

local function onInit()
    input.registerActionHandler(mDef.actions.showItems, async:callback(function(enabled)
        if enabled then
            mUi.toggleItemWindow()
        end
    end))
end

return {
    engineHandlers = {
        onInit = onInit,
        onLoad = onInit,
        onUpdate = onUpdate,
        onActive = onActive,
        onTeleported = onTeleported,
        onKeyPress = mUi.onKeyPress,
    },
    eventHandlers = {
        UiModeChanged = uiModeChanged,
        [mDef.events.clearNewContainers] = clearNewContainers,
        [mDef.events.addLootsLocalStats] = addLootsLocalStats,
        [mDef.events.showMessage] = showMessage,
        [mDef.events.printToConsole] = function(msg) ui.printToConsole(msg, util.color.rgb(1, 1, 1)) end,
        [mDef.events.returnActorStats] = function(event) gatherActorsStats(event.data, event.requestId) end,
        [mDef.events.returnConvertedItems] = mUi.showWindow,
    }
}