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
            and not mTypes.isEquipped(state.actors[actor.id]) then
        mConvert.onContainerOpen(state, actor, true)
    end
end

local function analyseNpc(state, npc)
    local isAnalyzed = mTypes.isAnalyzed(state.actors[npc.id])
    if not isAnalyzed then
        mTypes.setAnalyzed(state.actors, npc, mTypes.new.actorData, true)
        mStats.trackFactionRankBasedLevel(state, npc)
    end
    state.npcLevels[npc.recordId] = mObj.getActorLevel(npc)
    checkEquipment(state, npc)
    return not isAnalyzed
end

local function analyseCreature(state, creature)
    local isAnalyzed = mTypes.isAnalyzed(state.actors[creature.id])
    if not isAnalyzed then
        mTypes.setAnalyzed(state.actors, creature, mTypes.new.actorData, true)
    end
    checkEquipment(state, creature)
    return not isAnalyzed
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
    mTypes.setAnalyzed(state.containers, container, mTypes.new.containerData, true)

    local boosts, hasBoosts = mStats.getLockableLevelBoosts(container)
    if hasBoosts then
        state.containers[container.id].boosts = boosts
    end

    local levelStatsOverride
    if container.owner.factionId then
        levelStatsOverride = mTypes.new.lootKeeperStatsOverride(
                nil,
                false,
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
    -- merchant's containers don't need updates
    if mTypes.hasWares(state.containers[container.id]) then
        return nil
    end

    local levelStatsOverride
    local ownerId = container.owner.recordId

    if not mTypes.isAnalyzed(mObj.getLootData(state, container)) then
        levelStatsOverride = initContainer(state, container, ownerId)
    end

    local watchers = {}
    local factionsIds = { container.owner.factionId }

    if ownerId then
        levelStatsOverride = mTypes.new.lootKeeperStatsOverride(ownerId, false)
        local owner = actors.npcs[ownerId]
        if owner and mObj.getRecord(owner).servicesOffered["Barter"] then
            levelStatsOverride.hasWares = true
            state.containers[container.id].hasWares = true
            state.containers[container.id].levelStatsOverride = levelStatsOverride
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
        if mTypes.isAccessed(state.containers[container.id]) or not mObj.isValidContainer(state, mObj.getRecord(container)) or not mObj.hasValidInventory(container) then
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