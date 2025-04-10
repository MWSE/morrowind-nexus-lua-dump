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

local function filterLootKeepers(containersStats)
    local keptContainersStats = {}
    local actorsStatsToGet = {}
    for _, containerStats in ipairs(containersStats) do
        local container = containerStats.container
        for _, actor in ipairs(containerStats.actors) do
            local path = mLocal.getPath(actor, container)
            if path then
                local distance, time = mLocal.getTravelStats(actor, path)
                local seeLoot, hitPos = mLocal.trySeeObject(actor, container)
                if not seeLoot and hitPos then
                    seeLoot = (hitPos - container.position):length() < mCfg.lootLevel.maxKeepersClosestDistance
                end
                if distance < mCfg.lootLevel.maxKeepersTravelDistance or time < mCfg.lootLevel.maxKeepersTravelTime then
                    actorsStatsToGet[actor.id] = actor
                    containerStats.levelStats[actor.id] = mTypes.new.lootKeeperStats(
                            mObj.getActorLevel(actor),
                            nil,
                            actor.recordId,
                            actor.type == T.Creature,
                            not mObj.isActorHostile(actor),
                            distance,
                            time,
                            seeLoot
                    )
                end
            else
                log(string.format("Actor %s cannot reach container %s", mObj.objectId(actor), mObj.objectId(container)), mTypes.logLevels.Debug)
            end
        end
        if next(containerStats.levelStats) then
            table.insert(keptContainersStats, containerStats)
        end
    end
    if #keptContainersStats ~= 0 then
        mLocal.requestActorsStats(actorsStatsToGet, mTypes.new.requestEvent(mDef.events.returnActorsStats, self, keptContainersStats))
    end
end

local function returnActorsStats(actorsStats, containersStats)
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
    core.sendGlobalEvent(mDef.events.setLootsLevel, containersStats)
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
        [mDef.events.filterLootKeepers] = filterLootKeepers,
        [mDef.events.showMessage] = showMessage,
        [mDef.events.printToConsole] = function(msg) ui.printToConsole(msg, util.color.rgb(1, 1, 1)) end,
        [mDef.events.returnActorsStats] = function(data) returnActorsStats(data.actorsStats, data.eventData) end,
    }, { mUi.callbackEvents, mLocal.callbackEvents })
}