local T = require("openmw.types")

local mCfg = require("scripts.fresh-loot.config.configuration")
local mTypes = require("scripts.fresh-loot.config.types")
local mStore = require("scripts.fresh-loot.settings.store")
local mHelpers = require("scripts.fresh-loot.util.helpers")
local mObj = require("scripts.fresh-loot.util.objects")

local module = {}

local function addToNpcsWealth(state, recordId, wealth)
    state.learned.npcsWealth[recordId] = state.learned.npcsWealth[recordId] or mTypes.new.wealthStat()
    state.learned.npcsWealth[recordId].total = state.learned.npcsWealth[recordId].total + wealth
    return wealth
end
module.addToNpcsWealth = addToNpcsWealth

local function trackInventoryValueBasedLevel(state, actor)
    if actor.type ~= T.NPC then return end
    local level = math.max(1, T.Actor.stats.level(actor).current)
    local stat = state.learned.inventoryWealthLevel
    local wealth = math.max(1, mObj.getItemsValueSum(actor))
    stat.count = stat.count + 1
    stat.sum = stat.sum + wealth / level
    return wealth
end
module.trackInventoryValueBasedLevel = trackInventoryValueBasedLevel

local function trackFactionRankBasedLevel(state, actor)
    if actor.type ~= T.NPC then return end
    local level = math.max(1, T.Actor.stats.level(actor).current)
    local stat = state.learned.factionRanksLevel
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

local function isLootKeeperCloseEnough(actor, containerPosition)
    return (actor.position - containerPosition):length() <= mCfg.lootLevel.maxKeepersSearchDistance
end
module.isLootKeeperCloseEnough = isLootKeeperCloseEnough

local function getActorScaledLevel(state, level, isCreature)
    if isCreature then
        level = level * math.min(1, (level / state.settings[mStore.cfg.endGameLootLevel.key]) ^ 0.5)
    end
    return level
end
module.getActorScaledLevel = getActorScaledLevel

local function getKeeperLevel(state, stats, statsOverride)
    local level = stats.actorLevel
    local scaledLevel = getActorScaledLevel(state, stats.actorLevel, stats.isCreature)
    if statsOverride then
        if statsOverride.source.ownerRecordId then
            scaledLevel = (scaledLevel + statsOverride.actorLevel) / 2
        else
            scaledLevel = statsOverride.actorLevel
        end
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

    local reason = string.format("actor \"%s\" lvl %d (%d->%.2f*%.2f=%.2f) (passive:%s seeLoot:%s still:%s movesAround:%s %s (%.2f))",
            stats.actorRecordId, level, stats.actorLevel, scaledLevel, levelFactor, scaledLevel * levelFactor,
            stats.isPassive, stats.seeLoot, stats.still, stats.movesAround, proximityReason, proximityFactor)
    return scaledLevel, levelFactor, reason
end

local function getLootLevel(state, containerStats)
    local statsOverride = containerStats.levelStatsOverride
    if statsOverride and statsOverride.source.isForSale then
        local reason = string.format("merchant owner \"%s\" level %d and player level %d", statsOverride.source.ownerRecordId, statsOverride.actorLevel, state.playerLevel)
        return math.min(state.playerLevel, statsOverride.actorLevel), 0, { reason }
    end

    local scaledLevels = {}
    local levelFactors = {}
    local stats = {}
    local maxScaledLevel = 0
    local reasons = {}
    for _, levelStats in pairs(containerStats.levelStats) do
        local baseLevel, levelFactor, reason = getKeeperLevel(state, levelStats, statsOverride)
        --local level = baseLevel * levelFactor
        table.insert(scaledLevels, baseLevel)
        table.insert(levelFactors, levelFactor)
        table.insert(stats, levelStats)
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
        if not stats.isPassive then
            crowdFactor = crowdFactor + levelFactor
        end
    end
    lootLevel = lootLevel ^ 0.25

    if not statsOverride then
        -- Don't cap the loot level to the base level with hostile keepers
        maxScaledLevel = math.huge
    end

    -- crowd factor only applies with enough hostile keepers
    local crowdChanceBoost = math.max(0, crowdFactor - 1)

    return math.min(maxScaledLevel, math.max(lootLevel, 1)), crowdChanceBoost, reasons
end
module.getLootLevel = getLootLevel

local function setCellLootLocalStats(state, containersStats)
    local levelStats = state.learned.containers.levelStats
    local accessDoors = state.learned.containers.accessDoors
    for _, containerStats in ipairs(containersStats) do
        local id = containerStats.container.id
        containerStats.container = nil
        containerStats.actors = nil
        levelStats[id] = levelStats[id] or {}
        if containerStats.levelStatsOverride then
            levelStats[id].levelStatsOverride = containerStats.levelStatsOverride
        end
        if levelStats[id].levelStats then
            mHelpers.addAllToMap(levelStats[id].levelStats, containerStats.levelStats)
        else
            levelStats[id].levelStats = containerStats.levelStats
        end
        accessDoors[id] = accessDoors[id] or {}
        mHelpers.addAllToMap(accessDoors[id], containerStats.accessDoors)
    end
end
module.setCellLootLocalStats = setCellLootLocalStats

return module