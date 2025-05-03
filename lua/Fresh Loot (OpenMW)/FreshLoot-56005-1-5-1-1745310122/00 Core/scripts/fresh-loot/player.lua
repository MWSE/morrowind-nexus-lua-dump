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

local function requestActorsStats(actors, containersStats)
    requests.id = requests.id + 1
    requests.produced[requests.id] = {}
    requests.forwarded[requests.id] = containersStats
    local count = 0
    for _, actor in pairs(actors) do
        count = count + 1
        actor:sendEvent(mDef.events.getActorStats, mTypes.new.requestEvent(mDef.events.returnActorStats, self, nil, requests.id))
    end
    requests.sizes[requests.id] = count
end

local function gatherActorsStats(actorStats, requestId)
    table.insert(requests.produced[requestId], actorStats)
    if #requests.produced[requestId] < requests.sizes[requestId] then
        return
    end

    local containersStats = requests.forwarded[requestId]
    local actorsStats = mHelpers.arraysToMap(requests.produced[requestId], function(stat) return stat.actor.id end)
    requests.produced[requestId] = nil
    requests.forwarded[requestId] = nil
    requests.sizes[requestId] = nil

    for _, containerStats in ipairs(containersStats) do
        for actorId, lootKeeperStats in pairs(containerStats.levelStats) do
            local stats = actorsStats[actorId]
            if stats then
                lootKeeperStats.still = stats.packageType == "Wander" and stats.wanderDistance == 0
                lootKeeperStats.movesAround = stats.packageType == "Wander"
                        and stats.wanderDistance + mCfg.lootLevel.maxKeepersClosestDistance
                        < (containerStats.container.position - stats.actor.position):length()
            end
        end
    end
    core.sendGlobalEvent(mDef.events.setCellLootLocalStats, containersStats)
end

local function getLootKeeperStats(actor, container)
    local path = mLocal.getPath(actor, container, mCfg.lootLevel.maxKeepersClosestDistance)
    if not path then
        log(string.format("Actor %s cannot reach container %s", mObj.objectId(actor), mObj.objectId(container)), mTypes.logLevels.Debug)
        return
    end
    local distance, time = mLocal.getTravelStats(actor, path)
    local seeLoot, hitPos = mLocal.trySeeObject(actor, container)
    if not seeLoot and hitPos then
        seeLoot = (hitPos - container.position):length() < mCfg.lootLevel.maxKeepersClosestDistance
    end
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

local function getCellLootLocalStats(containersStats)
    local keptContainersStats = {}
    local actorsStatsToGet = {}
    local allDoorStats = {}
    for _, containerStats in ipairs(containersStats) do
        local hasStats = false
        local container = containerStats.container
        local doorStats = mLocal.getDoorStats(self, container, allDoorStats)
        if next(doorStats) then
            hasStats = true
            mHelpers.addAllToMap(allDoorStats, doorStats)
            containerStats.accessDoors = mHelpers.mapToHashset(doorStats)
            log(string.format("Container \"%s\" is blocked by doors: %s", containerStats.container, mHelpers.tableToString(doorStats, 2)), mTypes.logLevels.Debug)
        end
        for _, actor in ipairs(containerStats.actors) do
            local stats = getLootKeeperStats(actor, container)
            if stats then
                hasStats = true
                actorsStatsToGet[actor.id] = actor
                containerStats.levelStats[actor.id] = stats
            end
        end
        if hasStats then
            table.insert(keptContainersStats, containerStats)
        end
    end
    if next(actorsStatsToGet) then
        requestActorsStats(actorsStatsToGet, keptContainersStats)
    else
        core.sendGlobalEvent(mDef.events.setCellLootLocalStats, keptContainersStats)
    end
    core.sendGlobalEvent(mDef.events.setDoorStats, allDoorStats)
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