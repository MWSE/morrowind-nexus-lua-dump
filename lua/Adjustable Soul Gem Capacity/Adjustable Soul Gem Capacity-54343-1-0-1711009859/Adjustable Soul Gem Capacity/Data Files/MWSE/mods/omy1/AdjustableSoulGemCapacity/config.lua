-- Define the default configuration
local defaultConfig = {
    modEnabled = true,
    fSoulGemMult = 10
}

-- Load the configuration from a file, or use the default configuration if the file doesn't exist
local config = mwse.loadConfig("AdjustableSoulGemCapacity", defaultConfig)

-- Log the loaded configuration
mwse.log("[AdjustableSoulGemCapacity] Config loaded: %s", json.encode(config))

-- Return the configuration so it can be used by other scripts
return config