local async = require('openmw.async')
local T = require("openmw.types")

local log = require("scripts.fresh-loot.util.log")
local mDef = require("scripts.fresh-loot.config.definition")
local mTypes = require("scripts.fresh-loot.config.types")
local mStore = require("scripts.fresh-loot.settings.store")
local mObj = require("scripts.fresh-loot.util.objects")
local mHelpers = require("scripts.fresh-loot.util.helpers")
local mStats = require("scripts.fresh-loot.loot.stats")
local mConvert = require("scripts.fresh-loot.loot.convert")
local mInterop = require("scripts.fresh-loot.util.interop")

local module = {}

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

local function analyseActors(state, cell)
    local npcs, creatures, allActors = {}, {}, {}
    for _, npc in ipairs(cell:getAll(T.NPC)) do
        table.insert(allActors, npc)
        if analyseNpc(state, npc) then
            table.insert(npcs, npc)
        end
    end
    for _, creature in ipairs(cell:getAll(T.Creature)) do
        table.insert(allActors, creature)
        if analyseCreature(state, creature) then
            table.insert(creatures, creature)
        end
    end
    if #npcs + #creatures > 0 then
        log(string.format("Found %d NPCs and %d creatures not analysed in cell \"%s\"", #npcs, #creatures, cell.id))
    end
    return npcs, creatures, allActors
end

local function initContainer(state, container, ownerId)
    local boosts, hasBoosts = mStats.getLockableLevelBoosts(container)
    if hasBoosts then
        state.containers[container.id].boosts = boosts
    end

    local levelStatsOverride
    if container.owner.factionId then
        levelStatsOverride = mTypes.new.lootKeeperStatsOverride(
                nil,
                container.owner.factionId,
                container.owner.factionRank or 0)
    end

    if ownerId then
        local wealth = mStats.addToNpcsWealth(state, ownerId, mObj.getItemsValueSum(container), false)
        log(string.format("\"%s\" owns container \"%s\" with value %d", ownerId, container.recordId, wealth), mTypes.logLevels.Debug)
    end

    return levelStatsOverride
end

local function analyseContainer(state, container, actors)
    local levelStatsOverride
    local ownerId = container.owner.recordId

    if not mTypes.isAnalyzed(state.containers[container.id]) then
        mTypes.setAnalyzed(state.containers, container, mTypes.new.containerData)
        levelStatsOverride = initContainer(state, container, ownerId)
    end

    local watchers = {}
    local factionsIds = { container.owner.factionId }

    if ownerId then
        local owner = actors.npcs[ownerId]
        if owner and mObj.doesActorSellItems(mObj.getRecord(owner)) then
            state.containers[container.id].hasWares = true
            return nil
        end

        levelStatsOverride = mTypes.new.lootKeeperStatsOverride(ownerId)
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
        if mStats.isLootKeeperCloseEnough(actor, container.position) then
            if not actor:hasScript(mDef.actorScriptPath) then
                actor:addScript(mDef.actorScriptPath, {})
            end
            table.insert(keepers, actor)
        end
    end
    return mTypes.new.containerCellStats(container, keepers, levelStatsOverride, not state.containers[container.id].doorsBoosts)
end

local function analyseContainers(state, cell, npcs, creatures, player)
    local actors = {
        factionsMemberIds = {},
        membersFactionIds = {},
        npcs = {},
        protectors = {},
        enemies = {},
    }
    for _, npc in ipairs(npcs) do
        local record = mObj.getRecord(npc)
        local factions = T.NPC.getFactions(npc)
        actors.membersFactionIds[record.id] = #factions ~= 0 and factions or nil
        for _, factionId in ipairs(factions) do
            actors.factionsMemberIds[factionId] = actors.factionsMemberIds[factionId] or {}
            table.insert(actors.factionsMemberIds[factionId], record.id)
        end
        actors.npcs[record.id] = npc
        if mObj.isActorHostile(npc) then
            actors.enemies[npc.id] = npc
        end
        if mObj.isActorProtector(npc) then
            actors.protectors[npc.id] = npc
        end
    end
    for _, creature in ipairs(creatures) do
        if mObj.isActorHostile(creature) then
            actors.enemies[creature.id] = creature
        end
    end
    local containersData = {}
    for _, container in ipairs(cell:getAll(T.Container)) do
        if mTypes.isAccessed(state.containers[container.id])
                or mTypes.hasWares(state.containers[container.id])
                or not mObj.isValidContainer(state, mObj.getRecord(container))
                or not mObj.hasValidInventory(container) then
            log(string.format("Container \"%s\" is excluded", container.recordId), mTypes.logLevels.Debug)
        else
            local containerStats = analyseContainer(state, container, actors)
            if containerStats then
                table.insert(containersData, containerStats)
            end
        end
    end
    if #containersData ~= 0 then
        player:sendEvent(mDef.events.getCellLootLocalStats, containersData)
    end
end

local function checkEquipment(state, actor)
    async:newSimulationTimer(
            0.5 + math.random() / 2,
            async:registerTimerCallback(mDef.callbacks.checkEquipment .. actor.id, function()
                if state.settings[mStore.cfg.doEquippedItems.key]
                        and mInterop.isActorEquipmentReady(actor)
                        and not mTypes.isEquipped(state.actors[actor.id]) then
                    mConvert.onContainerOpen(state, actor, false)
                end
            end)
    )
end

module.analyseCell = function(state, cell, player)
    log(string.format("Analyzing cell \"%s\"...", cell.id))
    local npcs, creatures, allActors = analyseActors(state, cell)
    if #npcs ~= 0 or creatures ~= 0 then
        analyseContainers(state, cell, npcs, creatures, player)
    end
    for _, actor in ipairs(allActors) do
        checkEquipment(state, actor)
    end
end

module.analyseActor = function(state, actor, player)
    if actor.type == T.NPC then
        if analyseNpc(state, actor) then
            log(string.format("Analyzed new NPC \"%s\" in cell \"%s\"", actor.recordId, actor.cell.id))
            analyseContainers(state, actor.cell, { actor }, {}, player)
        end
    else
        if analyseCreature(state, actor) then
            log(string.format("Analyzed new creature \"%s\" in cell \"%s\"", actor.recordId, actor.cell.id))
            analyseContainers(state, actor.cell, {}, { actor }, player)
        end
    end
    checkEquipment(state, actor)
end

return module