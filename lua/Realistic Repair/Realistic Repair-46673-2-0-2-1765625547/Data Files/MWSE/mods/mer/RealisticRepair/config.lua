
---@class RealisticRepair.Config
local config = {}

config.configPath = "realistic_repair"

---Registered repair stations
---@type table<string, RealisticRepair.RegisteredStation>
config.stations = {}

---@class RealisticRepair.Config.MCM
local mcmDefault = {
    logLevel = mwse.logLevel.info,
    --Enable Realistic Repair mod
    enableRealisticRepair = true,
    --Enable repair stations
    enableStations = true,
    --Enable loot damage
    enableLootDamage = true,
    --min condition percentage of gear found on dead NPCs.
    minCondition = 10,
    --max condition percentage of gear found on dead NPCs.
    maxCondition = 75,
    --enable Degradation
    enableDegradation = true,
    --Degradation amount at max armorer skill (direct repair).
    minDegradation = 0,
    --Degradation amount at 0 armorer skill (direct repair).
    maxDegradation = 6,
    --How much degreadation is reduced when using a station. Can go negative to restore condition.
    stationDegradeReduction = 4,
}

---@type RealisticRepair.Config.MCM
config.mcm = mwse.loadConfig(config.configPath, mcmDefault)

---Save config to file
config.save = function()
    mwse.saveConfig(config.configPath, config.mcm)
end

return config