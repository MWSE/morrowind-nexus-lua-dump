local data = require("RationalNames.data")

local defaultConfig = {
    enable = true,
    prefixAttackAR = true,
    shortPrefixAttackAR = false,
    armorBySlotFirst = false,
    altSpoiledNames = false,
    keyWeightValue = true,
    goldAtEnd = true,
    logging = false,
    componentEnable = {},
    baseNameEnable = {},
    baseNameBlacklist = {
        ["key_shashev"] = true,
    },
    overallBlacklist = {
        ["bm_bearheart_unique"] = true,
        ["bm_seeds_unique"] = true,
    },
}

for _, objectType in ipairs(data.components) do
    defaultConfig.componentEnable[tostring(objectType)] = true
end

for _, objectType in ipairs(data.baseNameDisableOptions) do
    defaultConfig.baseNameEnable[tostring(objectType)] = true
end

return mwse.loadConfig("RationalNames", defaultConfig)