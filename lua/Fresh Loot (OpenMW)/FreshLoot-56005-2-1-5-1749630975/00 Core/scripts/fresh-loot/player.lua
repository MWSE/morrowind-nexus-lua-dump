local T = require("openmw.types")
local I = require("openmw.interfaces")
local core = require("openmw.core")
local self = require("openmw.self")
local ui = require("openmw.ui")
local util = require("openmw.util")

local log = require("scripts.fresh-loot.util.log")
local mDef = require("scripts.fresh-loot.config.definition")
local mCfg = require("scripts.fresh-loot.config.configuration")
local mTypes = require("scripts.fresh-loot.config.types")
local mObj = require("scripts.fresh-loot.util.objects")
local mHelpers = require("scripts.fresh-loot.util.helpers")
local mLocal = require("scripts.fresh-loot.util.local")
local mUi = require("scripts.fresh-loot.util.ui")

local l10n = core.l10n(mDef.MOD_NAME);

I.Settings.registerPage {
    key = mDef.MOD_NAME,
    l10n = mDef.MOD_NAME,
    name = "name",
    description = "description",
}

local state = {
    updateTime = 0,
    prevCellId = nil,
}

local requests = {
    produced = {},
    forwarded = {},
    sizes = {},
    id = 0,
}

local function requestActorsStats(actors, containersLocalStats)
    requests.id = requests.id + 1
    requests.produced[requests.id] = {}
    requests.forwarded[requests.id] = containersLocalStats
    local count = 0
    for _, actor in pairs(actors) do
        count = count + 1
        actor:sendEvent(mDef.events.getActorStats, mTypes.new.requestEvent(mDef.events.returnActorStats, self, nil, requests.id))
    end
    requests.sizes[requests.id] = count
end

local function gatherActorsStats(stats, requestId)
    table.insert(requests.produced[requestId], stats)
    if #requests.produced[requestId] < requests.sizes[requestId] then
        return
    end

    local containersLocalStats = requests.forwarded[requestId]
    local actorsStats = mHelpers.arraysToMap(requests.produced[requestId], function(stat) return stat.actor.id end)
    requests.produced[requestId] = nil
    requests.forwarded[requestId] = nil
    requests.sizes[requestId] = nil

    for _, containerLocalStats in ipairs(containersLocalStats) do
        for actorId, levelStats in pairs(containerLocalStats.levelStats) do
            local actorStats = actorsStats[actorId]
            if actorStats then
                levelStats.still = actorStats.packageType == "Wander"
                        and actorStats.wanderDistance == 0
                levelStats.movesAround = actorStats.packageType == "Wander"
                        and actorStats.wanderDistance + (containerLocalStats.container.position - actorStats.actor.position):length()
                        < mCfg.lootLevel.maxKeepersProtectLootDistance
            else
                log(string.format("No actor stats computed for actor \"%s\"", actorStats.actor.recordId))
            end
        end
    end
    core.sendGlobalEvent(mDef.events.setContainersStats, containersLocalStats)
end

local function getLootKeeperStats(actor, container)
    local path = mLocal.getPath(actor, container, mCfg.lootLevel.maxKeepersReachLootDistance)
    if not path then
        log(string.format("Actor %s cannot reach container %s", mObj.objectId(actor), mObj.objectId(container)), mTypes.logLevels.Debug)
        return
    end
    local distance, time = mLocal.getTravelStats(actor, path)
    local seeLoot = mLocal.trySeeDestination(actor, path[#path])
    if distance > mCfg.lootLevel.maxKeepersTravelDistance
            and time > mCfg.lootLevel.maxKeepersTravelTime then return end
    return mTypes.new.lootKeeperStats(
            mObj.getActorLevel(actor),
            actor.recordId,
            actor.type == T.Creature,
            not mObj.isActorHostile(actor),
            distance,
            time,
            seeLoot)
end

local function getCellLootLocalStats(containersCellStats)
    local containersLocalStats = {}
    local actorsStatsToGet = {}
    local allDoorsBoosts = {}
    for _, containerCellStats in ipairs(containersCellStats) do
        local hasStats = false
        local container = containerCellStats.container

        local doorsBoosts
        if containerCellStats.checkDoors then
            doorsBoosts = mLocal.getDoorsBoosts(self, container, allDoorsBoosts)
            if next(doorsBoosts) then
                hasStats = true
                mHelpers.addAllToMap(allDoorsBoosts, doorsBoosts)
                log(string.format("Container \"%s\" is blocked by doors: %s", containerCellStats.container, mHelpers.tableToString(doorsBoosts, 2)), mTypes.logLevels.Debug)
            end
        end

        local levelStats = {}
        for _, actor in ipairs(containerCellStats.actors) do
            local stats = getLootKeeperStats(actor, container)
            if stats then
                hasStats = true
                actorsStatsToGet[actor.id] = actor
                levelStats[actor.id] = stats
            end
        end
        if hasStats then
            table.insert(containersLocalStats, mTypes.new.containerLocalStats(
                    containerCellStats.container,
                    levelStats,
                    containerCellStats.levelStatsOverride,
                    doorsBoosts))
        end
    end
    if next(actorsStatsToGet) then
        requestActorsStats(actorsStatsToGet, containersLocalStats)
    else
        core.sendGlobalEvent(mDef.events.setContainersStats, containersLocalStats)
    end
end

local function onUpdate(deltaTime)
    state.updateTime = state.updateTime + deltaTime
    if state.updateTime > 0.5 then
        state.updateTime = 0
        if state.prevCellId ~= self.cell.id then
            state.prevCellId = self.cell.id
            core.sendGlobalEvent(mDef.events.onCellChanged, self)
        end
    end
end

local function showMessage(message)
    if not message.quiet then
        ui.showMessage(string.format("%s: %s", l10n("name"), message.text))
    end
    log(message.text)
end

local function onSave()
    return {
        state = state,
        version = mDef.saveVersion,
    }
end

local function onLoad(data)
    if data then
        if data.version == mDef.saveVersion then
            state = data.state
        else
            -- update data
        end
    end
end

return {
    engineHandlers = {
        onKeyPress = mUi.onKeyPress,
        onUpdate = onUpdate,
        onSave = onSave,
        onLoad = onLoad,
    },
    eventHandlers = mHelpers.addAllMapsToMap({
        [mDef.events.getCellLootLocalStats] = getCellLootLocalStats,
        [mDef.events.showMessage] = showMessage,
        [mDef.events.printToConsole] = function(msg) ui.printToConsole(msg, util.color.rgb(1, 1, 1)) end,
        [mDef.events.returnActorStats] = function(event) gatherActorsStats(event.data, event.requestId) end,
    }, { mUi.callbackEvents })
}