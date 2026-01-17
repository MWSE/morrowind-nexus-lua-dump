
---@class RealisticRepair.Config
local config = {}

config.configPath = "realistic_repair"

---Registered repair stations
---@type table<string, RealisticRepair.RegisteredStation>
config.stations = {}

---@class RealisticRepair.Config.MCM
config.mcmDefault = {

    --GENERAL

    --Enable Realistic Repair mod
    enableRealisticRepair = true,
    --Enable dynamic tooltips
    enableDynamicTooltips = true,
    --Enable repair stations
    enableStations = true,
    --Logging level
    logLevel = mwse.logLevel.info,

    --REPAIR COST

    --Enable time cost to repair
    enableTimeCost = true,
    --Time to repair at low skill
    repairTimeMin = 0.5, --in hours per point repaired
    --Time to repair at high skill
    repairTimeMax = 0.1, --in hours per point repaired

    --Enable fatigue cost to repair
    enableFatigueCost = true,
    --Fatigue cost at low skill
    repairFatigueMin = 10, --fatigue points per point repaired
    --Fatigue cost at high skill
    repairFatigueMax = 1, --fatigue points per point repaired


    --LOOT DAMAGE

    --Enable loot damage
    enableLootDamage = true,
    --min condition percentage of gear found on dead NPCs.
    minCondition = 10,
    --max condition percentage of gear found on dead NPCs.
    maxCondition = 75,

    --DEGRADATION

    --enable Degradation
    enableDegradation = true,
    --Degradation amount at max armorer skill.
    minDegradation = 3,
    --Degradation amount at 0 armorer skill.
    maxDegradation = 10,
    --Station success chance modifier (added to repair chance percentage)
    stationChanceModifier = 10,

    --ENHANCEMENT

    --Enable Enhancement
    enableEnhancement = true,
    --Enhancement amount per success at min armorer skill
    minEnhancement = 5,
    --Enhancement amount per success at max armorer skill
    maxEnhancement = 50,
    --Enhancement percentage cap at min armorer skill
    minEnhancementCap = 10,
    --Enhancement percentage cap at max armorer skill
    maxEnhancementCap = 100,
    --Chance to enhance at min armorer skill
    minEnhancementChance = 25,
    --Chance to enhance at max armorer skill
    maxEnhancementChance = 99,
}

---@type RealisticRepair.Config.MCM
config.mcm = mwse.loadConfig(config.configPath, config.mcmDefault)

---Save config to file
config.save = function()
    mwse.saveConfig(config.configPath, config.mcm)
end

return config
