---@class Drip.Config
local config = {
    modName = "Drip",
    configPath = "drip",
    modifierIcon = "Icons/drip/modifier.dds",
    modDescription = [[
Мод Drip добавляет в Морровинд систему добычи в стиле Diablo II. Уникальное оружие, броня, одежда и аксессуары генерируются динамически, с более чем сотней уникальных модификаторов и миллионами возможных комбинаций.
]],
    multiplierFieldDecimals= {
        speed = 2,
    },
    minEnchantCapacity = 10,
    maxEnchantCapacty = 500,
    maxEnchantEffect = 5,
    --registered configs
    materialPrefixes = {},
    materialSuffixes = {},

    modifiers = {
        ---@type table <string, Drip.Modifier[]>
        prefixes = {},
        ---@type table <string, Drip.Modifier[]>
        suffixes = {},
    },
    weapons = {},
    clothing = {},
    armor = {},
}

---@type MWSE.Metadata
config.metadata = toml.loadFile("Data Files\\DRIP-metadata.toml")

local cache
--Static Configs

--MCM Configs (Stored in Json, cached in memory)
config.mcmDefault = {
    logLevel = "INFO",
    enabled = true,
    modifierChance = 5,--percent
    secondaryModifierChance = 25,
    wildChance = 10,
    wildMultiplier = 1.5,
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


---@alias Drip.GeneratedLoot.Modifier Drip.Modifier.Data|string
---@alias Drip.GeneratedLoot { modifiers:table<number, Drip.GeneratedLoot.Modifier> }
---@class Drip.Config.Persistent
---@field generatedLoot table<string, Drip.GeneratedLoot>
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