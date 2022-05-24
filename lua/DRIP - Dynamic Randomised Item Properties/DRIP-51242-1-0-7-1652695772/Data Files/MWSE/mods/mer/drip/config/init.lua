local config = {}
local cache
config.materials = {}
config.modifiers = {
    prefixes = {},
    suffixes = {},
}
config.weapons = {}
config.clothing = {}
config.armor = {}

--Static Configs
config.modName = "Drip"
config.modDescription = [[
Drip adds Diablo 2 style loot to Morrowind. Unique weapons, armor, clothing and accesories are dynamically generated, with over a hundred unique modifiers and more than a million possible combinations.
]]
config.configPath = "drip"
config.modifierIcon = "Icons/drip/modifier.dds"
config.selfRepairPercentPerHour = 1

--MCM Configs (Stored in Json, cached in memory)
config.mcmDefault = {
    logLevel = "INFO",
    enabled = true,
    modifierChance = 4,--percent
    secondaryModifierChance = 20,
    wildChance = 6,
}
config.save = function(newConfig)
    cache = newConfig
    mwse.saveConfig(config.configPath, cache)
end
config.mcm = setmetatable({}, {
    __index = function(_, key)
        cache = cache or mwse.loadConfig(config.configPath, config.mcmDefault)
        return cache[key]
    end,
    __newindex = function(_, key, value)
        cache = cache or mwse.loadConfig(config.configPath, config.mcmDefault)
        cache[key] = value
        mwse.saveConfig(config.configPath, cache)
    end
})

--Persistent Configs (Stored on tes3.player.data, save specific)
config.persistentDefault = {
    generatedLoot = {}
}
config.persistent = setmetatable({}, {
    __index = function(_, key)
        if not tes3.player then return end
        tes3.player.data[config.configPath] = tes3.player.data[config.configPath] or config.persistentDefault
        return tes3.player.data[config.configPath][key]
    end,
    __newindex = function(_, key, value)
        if not tes3.player then return end
        tes3.player.data[config.configPath] = tes3.player.data[config.configPath] or config.persistentDefault
        tes3.player.data[config.configPath][key] = value
    end
})

return config