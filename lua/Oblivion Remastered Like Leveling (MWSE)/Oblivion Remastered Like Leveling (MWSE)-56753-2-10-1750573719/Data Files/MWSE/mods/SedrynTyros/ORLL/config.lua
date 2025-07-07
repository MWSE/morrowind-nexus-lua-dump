local configPath = "Oblivion Remastered Like Leveling"
local defaultConfig = {
    attributeLvlCap = 100,
    virtuesPerLevel = 12,
    maxPointsPerAttribute = 5,
    altLevelMsgs = true,
    minHealth = 0,
    deathProtection = false,
    retroHealth = true,
    restrictLuckToOne = true,
    logLevel = "INFO"
}

local config = mwse.loadConfig(configPath, defaultConfig)

-- Sync minHealth with deathProtection
if config.deathProtection then
    config.minHealth = 1
else
    config.minHealth = 0
end

return config