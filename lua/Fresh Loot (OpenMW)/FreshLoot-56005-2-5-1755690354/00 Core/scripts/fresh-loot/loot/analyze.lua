local async = require('openmw.async')
local T = require("openmw.types")

local log = require("scripts.fresh-loot.util.log")
local mDef = require("scripts.fresh-loot.config.definition")
local mCfg = require("scripts.fresh-loot.config.configuration")
local mTypes = require("scripts.fresh-loot.config.types")
local mStore = require("scripts.fresh-loot.settings.store")
local mObj = require("scripts.fresh-loot.util.objects")
local mHelpers = require("scripts.fresh-loot.util.helpers")
local mStats = require("scripts.fresh-loot.loot.stats")
local mConvert = require("scripts.fresh-loot.loot.convert")
local mInterop = require("scripts.fresh-loot.util.interop")

local module = {}

local function checkEquipment(state, actor)
    if state.settings[mStore.cfg.doEquippedItems.key]
            and not mTypes.isEquipped(state.actors[actor.id]) then
        async:newSimulationTimer(
                0.5 + math.random() / 2,
                async:registerTimerCallback(mDef.callbacks.checkEquipment .. actor.id, function()
                    if mInterop.isActorEquipmentReady(actor) then
                        mConvert.onContainerOpen(state, actor, false)
                    end
                end)
        )
    end
end

local function analyseNpc(state, npc)
    local isAnalyzed = mTypes.isAnalyzed(state.actors[npc.id])
    if not isAnalyzed then
        mTypes.setAnalyzed(state.actors, npc, mTypes.new.actorData)
        mStats.trackFactionRankBasedLevel(state, npc)
        mStats.addToNpcsWealth(state, npc.recordId, mObj.getItemsValueSum(npc), true)
        state.npcLevels[npc.recordId] = mObj.getActorLevel(npc)
    end
    return not isAnalyzed
end

local function analyseCreature(state, creature)
    local isAnalyzed = mTypes.isAnalyzed(state.actors[creature.id])
    if not isAnalyzed then
        mTypes.setAnalyzed(state.actors, creature, mTypes.new.actorData)
    end
    return not isAnalyzed
end

module.analyseActors = function(state, actors)
    local npcCt, creatureCt = 0, 0
    for _, actor in ipairs(actors) do
        if actor.type == T.NPC then
            if analyseNpc(state, actor) then
                npcCt = npcCt + 1
            end
        else
            if analyseCreature(state, actor) then
                creatureCt = creatureCt + 1
            end
        end
        checkEquipment(state, actor)
    end
    if npcCt + creatureCt > 0 then
        log(string.format("Found %d new NPCs and %d new creatures", npcCt, creatureCt))
    end
end

local function initContainer(state, container, ownerId)
    local boosts, hasBoosts = mStats.getLockableLevelBoosts(container)
    if hasBoosts then
        state.containers[container.id].boosts = boosts
    end

    local levelStatsOverride
    if ownerId then
        levelStatsOverride = mTypes.new.lootKeeperStatsOverride(ownerId)
        local wealth = mStats.addToNpcsWealth(state, ownerId, mObj.getItemsValueSum(container), false)
        log(string.format("\"%s\" owns container \"%s\" with value %d", ownerId, container.recordId, wealth), mTypes.logLevels.Debug)
    elseif container.owner.factionId then
        levelStatsOverride = mTypes.new.lootKeeperStatsOverride(
                nil,
                container.owner.factionId,
                container.owner.factionRank or 0)
    end

    return levelStatsOverride
end

local function analyseContainer(state, container, actors)
    mTypes.setAnalyzed(state.containers, container, mTypes.new.containerData)

    local levelStatsOverride
    local ownerId = container.owner.recordId
    levelStatsOverride = initContainer(state, container, ownerId)

    local watchers = {}
    local factionsIds = { container.owner.factionId }

    if ownerId then
        local owner = actors.npcs[ownerId]
        if owner and mObj.doesActorSellItems(mObj.getRecord(owner)) then
            state.containers[container.id].hasWares = true
            return nil
        end

        if actors.membersFactionIds[ownerId] then
            -- if the owner has factions, their members (him included) can be loot keepers
            mHelpers.addArrayToArray(factionsIds, actors.membersFactionIds[ownerId])
        elseif owner then
            watchers[owner.id] = owner
        end
    end

    if ownerId or #factionsIds ~= 0 then
        mHelpers.addAllToMap(watchers, actors.protectors)
    end

    for _, factionId in ipairs(factionsIds) do
        if actors.factionsMemberIds[factionId] then
            for _, memberId in ipairs(actors.factionsMemberIds[factionId]) do
                if actors.npcs[memberId] then
                    watchers[actors.npcs[memberId].id] = actors.npcs[memberId]
                end
            end
        end
    end
    local keepers = {}
    for _, actor in pairs(mHelpers.addAllToMap(watchers, actors.enemies)) do
        if (actor.position - container.position):length() <= mCfg.lootLevel.maxKeepersSearchDistance then
            if not actor:hasScript(mDef.actorScriptPath) then
                actor:addScript(mDef.actorScriptPath, {})
            end
            table.insert(keepers, actor)
        end
    end
    return mTypes.new.containerGlobalStats(container, keepers, levelStatsOverride, not state.containers[container.id].doorsBoosts)
end

module.analyseContainers = function(state, containers, actors, player)
    local validContainers = {}
    for _, container in ipairs(containers) do
        if mTypes.isAnalyzed(state.containers[container.id])
                or not mObj.isValidContainer(state, mObj.getRecord(container))
                or not mObj.hasValidInventory(container) then
            log(string.format("Container \"%s\" is excluded", container.recordId), mTypes.logLevels.Debug)
        else
            table.insert(validContainers, container)
        end
    end
    if #validContainers == 0 then return end

    local stats = {
        factionsMemberIds = {},
        membersFactionIds = {},
        npcs = {},
        protectors = {},
        enemies = {},
    }
    for _, actor in ipairs(actors) do
        if actor.type == T.NPC then
            local record = mObj.getRecord(actor)
            local factions = T.NPC.getFactions(actor)
            stats.membersFactionIds[record.id] = #factions ~= 0 and factions or nil
            for _, factionId in ipairs(factions) do
                stats.factionsMemberIds[factionId] = stats.factionsMemberIds[factionId] or {}
                table.insert(stats.factionsMemberIds[factionId], record.id)
            end
            stats.npcs[record.id] = actor
            if mObj.isActorHostile(actor) then
                stats.enemies[actor.id] = actor
            end
            if mObj.isActorProtector(actor) then
                stats.protectors[actor.id] = actor
            end
        else
            if mObj.isActorHostile(actor) then
                stats.enemies[actor.id] = actor
            end
        end
    end
    local containersData = {}
    for _, container in ipairs(validContainers) do
        local containerStats = analyseContainer(state, container, stats)
        if containerStats then
            table.insert(containersData, containerStats)
        end
    end
    if #containersData > 0 then
        player:sendEvent(mDef.events.addLootsLocalStats, containersData)
    end
end

return module