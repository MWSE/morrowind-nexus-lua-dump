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

local function setContainerLevelBoosts(state, container)
    local lock = 0
    local lockLevel = T.Lockable.getLockLevel(container)
    if lockLevel > 0 then
        lock = math.min(100, lockLevel) / 100
    end
    local trap = 0
    local trapSpell = T.Lockable.getTrapSpell(container)
    if trapSpell then
        trap = (math.max(1, math.min(100, trapSpell.cost)) / 100) ^ 0.5
    end
    local waterDepth = 0
    local waterLevel = container.cell.waterLevel
    if waterLevel and waterLevel > container.position.z then
        waterDepth = 1 - 1 / (1 + ((waterLevel - container.position.z) / mCfg.waterLevelHalfBonus) ^ 2)
    end
    state.learned.containers.boosts[container.id] = mTypes.new.lootBoosts(lock, trap, waterDepth)
end
module.setContainerLevelBoosts = setContainerLevelBoosts

local function isLootKeeperCloseEnough(actor, containerPosition)
    return (actor.position - containerPosition):length() <= mCfg.lootLevel.maxKeepersSearchDistance
end
module.isLootKeeperCloseEnough = isLootKeeperCloseEnough

local function getActorFinalLevel(state, level, isCreature)
    if isCreature then
        level = level * math.min(1, (level / state.settings[mStore.cfg.endGameLootLevel.key]) ^ 0.5)
    end
    return level
end
module.getActorFinalLevel = getActorFinalLevel

local function getKeeperLevel(state, stats, statsOverride)
    local actorBaseLevel = stats.actorLevel
    if statsOverride then
        mHelpers.addAllToMap(stats, statsOverride, function(k, v) return v ~= nil and k ~= "actorRecordId" end)
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

    local baseLevel = getActorFinalLevel(state, stats.actorLevel, stats.isCreature)
    local level = baseLevel
    if stats.isPassive then
        level = level * state.settings[mStore.cfg.passiveActorsLevelRatio.key] / 100
    end

    level = level / (proximityFactor ^ 4 + 1)
    if stats.seeLoot then
        if not stats.still then
            level = level * mCfg.lootLevel.actorSeeLootIsMovingRatio
        end
    else
        if stats.movesAround then
            level = level * mCfg.lootLevel.actorDontSeeLootMovesAroundRatio
        else
            level = level * mCfg.lootLevel.actorDontSeeLootDoesntMoveAroundRatio
        end
    end

    local reason = string.format("actor \"%s\" lvl %d (lvl:%d passive:%s seeLoot:%s still:%s movesAround:%s %s)",
            stats.actorRecordId, actorBaseLevel, stats.actorLevel, stats.isPassive, stats.seeLoot, stats.still, stats.movesAround, proximityReason)
    return baseLevel, level, reason
end

local function getLootLevel(state, containerStats)
    local statsOverride = containerStats.levelStatsOverride
    if statsOverride and statsOverride.source.isForSale then
        local reason = string.format("merchant owner \"%s\" level %d and player level %d", statsOverride.actorRecordId, statsOverride.actorLevel, state.playerLevel)
        return math.min(state.playerLevel, statsOverride.actorLevel), 0, { reason }
    end

    local keepersLevel = {}
    local maxKeeperLevel = 0
    local maxBaseKeeperLevel = 0
    local reasons = {}
    for _, levelStats in pairs(containerStats.levelStats) do
        local baseKeeperLevel, keeperLevel, reason = getKeeperLevel(state, levelStats, statsOverride)
        table.insert(keepersLevel, keeperLevel)
        table.insert(reasons, reason)
        if baseKeeperLevel > maxBaseKeeperLevel then
            maxBaseKeeperLevel = baseKeeperLevel
        end
        if keeperLevel > maxKeeperLevel then
            maxKeeperLevel = keeperLevel
        end
    end
    local maxKeeperRelativeLevel = 0
    local keeperRelativeLevels = {}
    for _, level in ipairs(keepersLevel) do
        local keeperRelativeLevel = (level / maxKeeperLevel) ^ 0.5
        table.insert(keeperRelativeLevels, keeperRelativeLevel)
        if keeperRelativeLevel > maxKeeperRelativeLevel then
            maxKeeperRelativeLevel = keeperRelativeLevel
        end
    end
    local crowdLevel = 0
    for _, level in ipairs(keeperRelativeLevels) do
        crowdLevel = crowdLevel + level
    end
    if not statsOverride then
        -- Don't cap the loot level to the base level with hostile keepers
        maxBaseKeeperLevel = math.huge
    end

    local lootLevel = crowdLevel + maxKeeperLevel - maxKeeperRelativeLevel

    -- For passive keepers, don't increase pick chance because of the crowd size
    local crowdChanceBoost = (statsOverride or crowdLevel < 1) and 0 or crowdLevel - 1

    return math.min(maxBaseKeeperLevel, math.max(lootLevel, 1)), crowdChanceBoost, reasons
end
module.getLootLevel = getLootLevel

local function setLootsLevelStats(state, containersStats)
    local levelStats = state.learned.containers.levelStats
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
    end
end
module.setLootsLevelStats = setLootsLevelStats

return module