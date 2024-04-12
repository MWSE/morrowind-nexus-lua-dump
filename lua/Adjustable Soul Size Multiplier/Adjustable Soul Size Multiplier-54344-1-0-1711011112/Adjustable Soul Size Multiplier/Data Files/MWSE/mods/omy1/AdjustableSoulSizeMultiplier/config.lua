local defaultConfig = {
    modEnabled = true,
    soulSizeMultiplier = 2.0, -- Default multiplier to double the soul size
}

local config = mwse.loadConfig("AdjustableSoulSizeMultiplier", defaultConfig)

-- Add the debug output line here
mwse.log("AdjustableSoulSizeMultiplier Config loaded: %s", json.encode(config))

return config