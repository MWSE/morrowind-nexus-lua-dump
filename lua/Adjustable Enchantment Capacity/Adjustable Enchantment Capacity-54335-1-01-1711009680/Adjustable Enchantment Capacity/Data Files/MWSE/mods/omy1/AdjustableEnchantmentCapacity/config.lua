local defaultConfig = {
    modEnabled = true,
    enchCap = 1000,
    FEnchantmentMult = 1.0,
}

local config = mwse.loadConfig("AdjustableEnchantmentCapacity", defaultConfig)

-- Add the debug output line here
mwse.log("[AdjustableEnchantmentCapacity] Config loaded: %s", json.encode(config))

return config