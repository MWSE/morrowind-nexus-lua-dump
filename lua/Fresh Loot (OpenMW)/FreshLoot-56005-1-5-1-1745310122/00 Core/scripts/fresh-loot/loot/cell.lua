local T = require("openmw.types")

local log = require("scripts.fresh-loot.util.log")
local mDef = require("scripts.fresh-loot.config.definition")
local mTypes = require("scripts.fresh-loot.config.types")
local mStore = require("scripts.fresh-loot.settings.store")
local mObj = require("scripts.fresh-loot.util.objects")
local mHelpers = require("scripts.fresh-loot.util.helpers")
local mStats = require("scripts.fresh-loot.loot.stats")
local mConvert = require("scripts.fresh-loot.loot.convert")

local module = {}

local function checkEquipment(state, actor)
    if state.settings[mStore.cfg.enabled.key]
            and state.settings[mStore.cfg.doEquippedItems.key]
            and not state.processed.equipments[actor.id] then
        state.processed.equipments[actor.id] = true
        mConvert.onContainerOpen(state, actor, true)
    end
end

local function analyseNpc(state, npc)
    checkEquipment(state, npc)

    if state.processed.actors[npc.id] then
        return false
    end
    state.processed.actors[npc.id] = npc
    local wealth = mStats.addToNpcsWealth(state, npc.recordId, mStats.trackInventoryValueBasedLevel(state, npc))
    log(string.format("\"%s\"'s inventory wealth is %d", npc.recordId, wealth))
    mStats.trackFactionRankBasedLevel(state, npc)
    return true
end

local function analyseCreature(state, creature)
    checkEquipment(state, creature)

    if state.processed.actors[creature.id] then
        return false
    end
    state.processed.actors[creature.id] = creature
    return true
end

local function analyseActors(state, cell)
    local npcs, creatures = {}, {}
    for _, npc in ipairs(cell:getAll(T.NPC)) do
        if analyseNpc(state, npc) then
            table.insert(npcs, npc)
        end
    end
    for _, creature in ipairs(cell:getAll(T.Creature)) do
        if analyseCreature(state, creature) then
            table.insert(creatures, creature)
        end
    end
    if #npcs + #creatures > 0 then
        log(string.format("Found %d NPCs and %d creatures in cell \"%s\"", #npcs, #creatures, cell.id))
    end
    return npcs, creatures
end

local function initContainer(state, container, ownerId)
    state.learned.containers.initialized[container.id] = true

    local boosts, hasBoosts = mStats.getLockableLevelBoosts(container)
    if hasBoosts then
        state.learned.containers.boosts[container.id] = boosts
    end

    local levelStatsOverride
    if container.owner.factionId then
        local rankStats = state.learned.factionRanksLevel[container.owner.factionId] or { count = 1, sum = 1 }
        local rank = container.owner.factionRank or 0
        levelStatsOverride = mTypes.new.lootKeeperStatsOverride(
                (rank + 1) * rankStats.sum / rankStats.count,
                mTypes.new.containerLevelSource(nil, false, container.owner.factionId, rank))
    end

    if ownerId then
        local wealth = mStats.addToNpcsWealth(state, ownerId, mObj.getItemsValueSum(container))
        log(string.format("\"%s\" owns container \"%s\" with value %d", ownerId, container.recordId, wealth))
    end

    return levelStatsOverride
end

local function analyseContainer(state, container, actors)
    -- merchant's containers don't need updates
    if state.learned.containers.soldItems[container.id] then
        return nil
    end

    local levelStatsOverride
    local ownerId = container.owner.recordId

    if not state.learned.containers.initialized[container.id] then
        levelStatsOverride = initContainer(state, container, ownerId)
    end

    local watchers = {}
    local factionsIds = { container.owner.factionId }

    local owner = actors.npcs[ownerId]
    if owner then
        local levelSource = mTypes.new.containerLevelSource(ownerId, false)
        levelStatsOverride = mTypes.new.lootKeeperStatsOverride(mObj.getActorLevel(owner), levelSource)

        if mObj.getRecord(owner).servicesOffered["Barter"] then
            levelSource.isForSale = true
            state.learned.containers.soldItems[container.id] = {}
            state.learned.containers.levelStats[container.id] = mTypes.new.containerStats(container, {}, levelStatsOverride)
            return nil
        end

        if actors.membersFactionIds[ownerId] then
            -- if the owner has factions, their members (him included) can be loot keepers
            mHelpers.addAllToArray(factionsIds, actors.membersFactionIds[ownerId])
        else
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
            table.insert(keepers, actor)
        end
    end
    return mTypes.new.containerStats(container, keepers, levelStatsOverride)
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
        if not mObj.isValidContainer(container) or not mObj.isValidInventory(container) then
            state.processed.containers[container.id] = true
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

local function analyseCell(state, cell, player)
    local npcs, creatures = analyseActors(state, cell)
    if #npcs ~= 0 or creatures ~= 0 then
        analyseContainers(state, cell, npcs, creatures, player)
    end
end
module.analyseCell = analyseCell

local function analyseActor(state, actor, player)
    if actor.type == T.NPC then
        if analyseNpc(state, actor) then
            log(string.format("Found new NPC \"%s\" in cell \"%s\"", actor.recordId, actor.cell.id))
            analyseContainers(state, actor.cell, { actor }, {}, player)
        end
    else
        if analyseCreature(state, actor) then
            log(string.format("Found new creature \"%s\" in cell \"%s\"", actor.recordId, actor.cell.id))
            analyseContainers(state, actor.cell, {}, { actor }, player)
        end
    end
end
module.analyseActor = analyseActor

return module