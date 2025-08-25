local T = require("openmw.types")

local mCfg = require("scripts.fresh-loot.config.configuration")
local mTypes = require("scripts.fresh-loot.config.types")
local mStore = require("scripts.fresh-loot.settings.store")
local mHelpers = require("scripts.fresh-loot.util.helpers")

local module = {}

local function addToNpcsWealth(state, recordId, wealth, isNewNpc)
    state.npcsWealth[recordId] = state.npcsWealth[recordId] or mTypes.new.wealthStat()
    state.npcsWealth[recordId].total = state.npcsWealth[recordId].total + wealth
    if isNewNpc then
        state.npcsWealth[recordId].npcCount = state.npcsWealth[recordId].npcCount + 1
    end
    return state.npcsWealth[recordId].total
end
module.addToNpcsWealth = addToNpcsWealth

local function trackFactionRankBasedLevel(state, actor)
    if actor.type ~= T.NPC then return end
    local level = math.max(1, T.Actor.stats.level(actor).current)
    local stat = state.factionRanksLevel
    for _, factionId in ipairs(T.NPC.getFactions(actor)) do
        if not stat[factionId] then
            stat[factionId] = mTypes.new.averageStat()
        end
        local rank = T.NPC.getFactionRank(actor, factionId) or 0
        -- 2 ^ rank, because the higher the rank, the less the members, but they should have a real impact on the stat
        stat[factionId].count = stat[factionId].count + 2 ^ rank
        stat[factionId].sum = stat[factionId].sum + (2 ^ rank) * level / (rank + 1)
    end
end
module.trackFactionRankBasedLevel = trackFactionRankBasedLevel

local function getLockableLevelBoosts(lockable)
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
    return mTypes.new.lockableBoosts(lock, trap, waterDepth), lock + trap + waterDepth > 0
end
module.getLockableLevelBoosts = getLockableLevelBoosts

local function mergeBoosts(boosts)
    if #boosts == 1 then return boosts[1] end
    local merged = mTypes.new.lockableBoosts(0, 0, 0)
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
module.mergeBoosts = mergeBoosts

local function getActorScaledLevel(state, level, isCreature)
    if isCreature then
        level = level * math.min(1, (level / state.settings[mStore.cfg.endGameLootLevel.key]) ^ 0.5)
    end
    return level
end
module.getActorScaledLevel = getActorScaledLevel

local function getKeeperLevel(state, stats, levelOverride, levelOverrideRatio)
    local scaledLevel = getActorScaledLevel(state, stats.actorLevel, stats.isCreature)
    if levelOverride then
        scaledLevel = (1 - levelOverrideRatio) * scaledLevel + levelOverrideRatio * levelOverride
    end
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

local function getLootLevel(state, loot)
    local levelStats = state.containers[loot.id].levelStats
    local statsOverride = state.containers[loot.id].levelStatsOverride

    local reasons = {}

    local levelOverride
    local levelOverrideRatio = 1
    if statsOverride then
        if statsOverride.ownerRecordId then
            levelOverride = state.npcLevels[statsOverride.ownerRecordId]
            if not levelOverride then
                return 0, 0, { "level 0 (unidentified owner)" }
            end
            levelOverrideRatio = 0.5
            table.insert(reasons, string.format("overridden by owner \"%s\" (lvl %d)", statsOverride.ownerRecordId, levelOverride))
        elseif statsOverride.factionId then
            local rankStats = state.factionRanksLevel[statsOverride.factionId]
            if not rankStats then
                return 0, 0, { "level 0 (no faction stats)" }
            end
            levelOverride = (statsOverride.factionRank + 1) * rankStats.sum / rankStats.count
            table.insert(reasons, string.format("overridden by faction \"%s\" (rank %d)", statsOverride.factionId, statsOverride.factionRank))
        else
            return 0, 0, { "Unknown level stats override: " .. mHelpers.tableToString(statsOverride) }
        end
    end

    if #levelStats == 0 then
        return 0, 0, { "level 0 (no keepers around)" }
    end

    local scaledLevels = {}
    local levelFactors = {}
    local stats = {}
    local maxScaledLevel = 0
    for _, levelStat in ipairs(levelStats) do
        local baseLevel, levelFactor, reason = getKeeperLevel(state, levelStat, levelOverride, levelOverrideRatio)
        if baseLevel == 0 then
            return 0, 0, reason
        end
        table.insert(scaledLevels, baseLevel)
        table.insert(levelFactors, levelFactor)
        table.insert(stats, levelStat)
        table.insert(reasons, reason)
        if baseLevel > maxScaledLevel then
            maxScaledLevel = baseLevel
        end
    end
    local lootLevel = 0
    local crowdFactor = 0
    -- loot level is (lvl1 ^ 4 + lvl2 ^ 4 ...) ^ (1/4)
    -- in order to slightly boost the level when keepers are numerous
    for i, scaledLevel in ipairs(scaledLevels) do
        -- reduce the level factor based on the max level of actors around, but as unity is strength, don't penalize low levels too much
        local levelFactor = levelFactors[i] * (scaledLevel / maxScaledLevel) ^ 0.5
        lootLevel = lootLevel + (maxScaledLevel * levelFactor) ^ 4
        if not stats[i].isPassive then
            crowdFactor = crowdFactor + levelFactor
        end
    end
    lootLevel = lootLevel ^ 0.25

    -- crowd factor only applies with enough hostile keepers
    local crowdChanceBoost = math.max(0, crowdFactor - 1)

    -- Don't cap the loot level to the base level with hostile keepers
    local maxLevel = statsOverride and levelOverride or math.huge

    return math.min(maxLevel, math.max(lootLevel, 1)), crowdChanceBoost, reasons
end
module.getLootLevel = getLootLevel

local function setContainersStats(state, containersStats)
    for _, stats in ipairs(containersStats) do
        local data = state.containers[stats.container.id]
        if stats.levelStatsOverride then
            data.levelStatsOverride = stats.levelStatsOverride
        end
        mHelpers.addMapToArray(data.levelStats, stats.levelStats)
        if stats.doorsBoosts then
            data.doorsBoosts = {}
            mHelpers.addMapToArray(data.doorsBoosts, stats.doorsBoosts)
        end
    end
end
module.setContainersStats = setContainersStats

return module