local T = require("openmw.types")

local mCfg = require("scripts.fresh-loot.config.configuration")
local mT = require("scripts.fresh-loot.config.types")
local mStore = require("scripts.fresh-loot.settings.store")
local mHelpers = require("scripts.fresh-loot.util.helpers")

local module = {}

module.addToNpcsWealth = function(state, recordId, wealth, isNewNpc)
    state.npcsWealth[recordId] = state.npcsWealth[recordId] or mT.new.wealthStat()
    state.npcsWealth[recordId].total = state.npcsWealth[recordId].total + wealth
    if isNewNpc then
        state.npcsWealth[recordId].npcCount = state.npcsWealth[recordId].npcCount + 1
    end
    return state.npcsWealth[recordId].total
end

module.trackFactionRankBasedLevel = function(state, actor)
    if actor.type ~= T.NPC then return end
    local level = math.max(1, T.Actor.stats.level(actor).current)
    local stat = state.factionRanksLevel
    for _, factionId in ipairs(T.NPC.getFactions(actor)) do
        if not stat[factionId] then
            stat[factionId] = mT.new.averageStat()
        end
        local rank = T.NPC.getFactionRank(actor, factionId) or 0
        -- 2 ^ rank, because the higher the rank, the less the members, but they should have a real impact on the stat
        stat[factionId].count = stat[factionId].count + 2 ^ rank
        stat[factionId].sum = stat[factionId].sum + (2 ^ rank) * level / (rank + 1)
    end
end

module.getLockableLevelBoosts = function(lockable)
    local lock = 0
    local lockLevel = T.Lockable.getLockLevel(lockable)
    if lockLevel > 0 then
        lock = math.min(100, lockLevel) / 100
    end
    local trap = 0
    local trapSpell = T.Lockable.getTrapSpell(lockable)
    if trapSpell then
        trap = (math.max(1, math.min(100, trapSpell.cost)) / 100) ^ 0.5
    end
    local waterDepth = 0
    local waterLevel = lockable.cell.waterLevel
    if waterLevel and waterLevel > lockable.position.z then
        waterDepth = 1 - 1 / (1 + ((waterLevel - lockable.position.z) / mCfg.waterLevelHalfBonus) ^ 2)
    end
    return mT.new.lockableBoosts(lock, trap, waterDepth), lock + trap + waterDepth > 0
end

module.mergeBoosts = function(boosts)
    if #boosts == 1 then return boosts[1] end
    local merged = mT.new.lockableBoosts(0, 0, 0)
    for _, boost in ipairs(boosts) do
        for key, value in pairs(boost) do
            merged[key] = merged[key] + value ^ 4
        end
    end
    for key, value in pairs(merged) do
        merged[key] = value ^ 0.25
    end
    return merged
end

module.getActorScaledLevel = function(state, level, isCreature)
    if isCreature then
        level = level * math.min(1, (level / state.settings[mStore.cfg.endGameLootLevel.key]) ^ 0.5)
    end
    return level
end

local function getKeeperLevel(state, stats, levelOverride, levelOverrideRatio)
    local scaledLevel = module.getActorScaledLevel(state, stats.actorLevel, stats.isCreature)
    if levelOverride then
        scaledLevel = (1 - levelOverrideRatio) * scaledLevel + levelOverrideRatio * levelOverride
    end
    scaledLevel = math.max(1, scaledLevel)
    local distanceFactor = stats.distance / mCfg.lootLevel.maxKeepersTravelDistance
    local timeFactor = stats.time / mCfg.lootLevel.maxKeepersTravelTime
    local proximityFactor, proximityReason
    if distanceFactor < timeFactor then
        proximityFactor = distanceFactor
        proximityReason = string.format("dist:%d", stats.distance)
    else
        proximityFactor = timeFactor
        proximityReason = string.format("time:%ds", stats.time)
    end

    local levelFactor = 1
    if stats.isPassive then
        levelFactor = levelFactor * state.settings[mStore.cfg.passiveActorsLevelRatio.key] / 100
    end

    levelFactor = levelFactor / (proximityFactor ^ 4 + 1)
    if stats.seeLoot then
        if not stats.still then
            levelFactor = levelFactor * mCfg.lootLevel.actorSeeLootIsMovingRatio
        end
    else
        if stats.movesAround then
            levelFactor = levelFactor * mCfg.lootLevel.actorDontSeeLootMovesAroundRatio
        else
            levelFactor = levelFactor * mCfg.lootLevel.actorDontSeeLootDoesntMoveAroundRatio
        end
    end

    local reason = string.format("actor \"%s\" (lvl %d->%.2f*%.2f=%.2f) (passive:%s seeLoot:%s still:%s movesAround:%s %s (%.2f))",
            stats.actorRecordId, stats.actorLevel, scaledLevel, levelFactor, scaledLevel * levelFactor,
            stats.isPassive, stats.seeLoot, stats.still, stats.movesAround, proximityReason, proximityFactor)
    return scaledLevel, levelFactor, reason
end

module.getLootLevelStats = function(state, loot)
    local levelStats = state.containers[loot.id].levelStats
    local statsOverride = state.containers[loot.id].levelStatsOverride

    local reasons = {}

    local levelOverride
    local levelOverrideRatio = 1
    if statsOverride then
        if statsOverride.ownerRecordId then
            levelOverride = state.npcLevels[statsOverride.ownerRecordId]
            if not levelOverride then
                table.insert(reasons, string.format("unidentified owner \"%s\"", statsOverride.ownerRecordId))
                statsOverride = nil
            else
                levelOverrideRatio = 0.5
                table.insert(reasons, string.format("overridden by owner \"%s\" (lvl %d)", statsOverride.ownerRecordId, levelOverride))
            end
        elseif statsOverride.factionId then
            local rankStats = state.factionRanksLevel[statsOverride.factionId]
            if not rankStats then
                table.insert(reasons, string.format("no stats for faction \"%s\"", statsOverride.factionId))
                statsOverride = nil
            else
                levelOverride = (statsOverride.factionRank + 1) * rankStats.sum / rankStats.count
                table.insert(reasons, string.format("overridden by faction \"%s\" (rank %d)", statsOverride.factionId, statsOverride.factionRank))
            end
        else
            return mT.new.lootLevelStats(0, 0, { "Unknown level stats override: " .. mHelpers.tableToString(statsOverride) })
        end
    end

    if #levelStats == 0 then
        return mT.new.lootLevelStats(0, 0, { "level 0 (no keepers around)" })
    end

    local scaledLevels = {}
    local levelFactors = {}
    local stats = {}
    local maxScaledLevel = 0
    for _, levelStat in ipairs(levelStats) do
        local scaledLevel, levelFactor, reason = getKeeperLevel(state, levelStat, levelOverride, levelOverrideRatio)
        table.insert(scaledLevels, scaledLevel)
        table.insert(levelFactors, levelFactor)
        table.insert(stats, levelStat)
        table.insert(reasons, reason)
        if scaledLevel > maxScaledLevel then
            maxScaledLevel = scaledLevel
        end
    end
    local lootLevel = 0
    local chanceBonus = 0
    local endGameLevel = state.settings[mStore.cfg.endGameLootLevel.key]
    -- loot level is (lvl1 ^ 4 + lvl2 ^ 4 ...) ^ (1/4)
    -- in order to slightly boost the level when keepers are numerous
    for i, scaledLevel in ipairs(scaledLevels) do
        -- reduce the level factor based on the max level of actors around, but as unity is strength, don't penalize low levels too much
        local levelFactor = maxScaledLevel * levelFactors[i] * (scaledLevel / maxScaledLevel) ^ 0.5
        lootLevel = lootLevel + levelFactor ^ 4
        -- chance bonus is based on the keeper's level, and the number of loots he watches weighted by the level factor (distance from the loot...)
        chanceBonus = chanceBonus + math.min(1, scaledLevel / endGameLevel) ^ 2 * levelFactors[i] / (stats[i].watchedLoots ^ (0.5 - 0.5 * levelFactors[i]))
    end
    lootLevel = lootLevel ^ 0.25

    -- Don't cap the loot level to the base level with hostile keepers
    local maxLevel = statsOverride and levelOverride or math.huge

    return mT.new.lootLevelStats(math.min(maxLevel, math.max(lootLevel, 1)), chanceBonus, reasons)
end

module.setContainersStats = function(state, lootsLocalStats)
    for _, lootStats in ipairs(lootsLocalStats) do
        local data = state.containers[lootStats.container.id]
        if lootStats.levelStatsOverride then
            data.levelStatsOverride = lootStats.levelStatsOverride
        end
        mHelpers.addMapToArray(data.levelStats, lootStats.levelStats)
        if lootStats.doorsBoosts then
            data.doorsBoosts = {}
            mHelpers.addMapToArray(data.doorsBoosts, lootStats.doorsBoosts)
        end
    end
end

return module