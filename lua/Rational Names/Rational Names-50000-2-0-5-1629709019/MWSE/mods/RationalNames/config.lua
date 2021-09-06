local data = require("RationalNames.data")

local defaultConfig = {
    enable = true,
    addPrefixes = true,
    displayPrefixes = false,
    changeBaseNames = true,
    prefixAttackAR = true,
    armorBySlotFirst = false,
    armorAltWeight = true,
    lightsInReverseOrder = true,
    objectTypePrefixes = true,
    potionRomanNumerals = false,
    altSpoiledNames = false,
    removeScrollOf = true,
    removeArticlesFromBooks = true,
    keyBaseNames = true,
    addKeyAtBeginning = false,
    keyWeightValue = true,
    keyIsKey = true,
    goldAtEnd = true,
    changeKeyMessage = true,
    logging = false,
    nameTweaks = {},
    miscPrefixes = {},
    componentEnable = {
        overall = {},
        prefix = {},
        baseName = {},
    },
    blacklists = {
        overall = {
            ["bm_bearheart_unique"] = true,
            ["bm_seeds_unique"] = true,
        },
        prefix = {},
        baseName = {},
    },
}

for _, tweakOption in ipairs(table.keys(data.nameTweaksOptions, true)) do
    defaultConfig.nameTweaks[tweakOption] = true
end

for _, miscOption in ipairs(data.miscPrefixOptions) do
    defaultConfig.miscPrefixes[miscOption] = true
end

for _, objectType in ipairs(data.components) do
    for _, listType in ipairs(data.mcmListTypes) do
        if listType ~= "prefix"
        or objectType ~= tes3.objectType.ingredient then
            defaultConfig.componentEnable[listType][tostring(objectType)] = true
        end
    end
end

return mwse.loadConfig("RationalNames", defaultConfig)