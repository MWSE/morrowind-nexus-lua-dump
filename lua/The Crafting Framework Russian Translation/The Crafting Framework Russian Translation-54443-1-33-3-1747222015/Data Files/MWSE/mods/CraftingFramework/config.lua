local inMemConfig

---@class CraftingFramework.config
local config = {}
config.initialized = false
--Static Config (stored right here)
config.static = {
    modName = "Модуль ремесла",
    modDescription = [[
Модуль ремесла это мощная, гибкая и простая в использовании среда для создания модов по изготовлению различных предметов.
]],
    ---SoundTypes registered by Crafting Framework
    defaultConstructionSounds = {
        fabric = {
            "craftingFramework\\craft\\Fabric1.wav",
            "craftingFramework\\craft\\Fabric2.wav",
            "craftingFramework\\craft\\Fabric3.wav",
            "craftingFramework\\craft\\Fabric4.wav",
        },
        wood = {
            "craftingFramework\\craft\\Wood1.wav",
            "craftingFramework\\craft\\Wood2.wav",
            "craftingFramework\\craft\\Wood3.wav",
        },
        leather = {
            "craftingFramework\\craft\\Leather1.wav",
            "craftingFramework\\craft\\Leather2.wav",
            "craftingFramework\\craft\\Leather3.wav",
        },
        rope = {
            "craftingFramework\\craft\\Rope1.wav",
            "craftingFramework\\craft\\Rope2.wav",
            "craftingFramework\\craft\\Rope3.wav",
        },
        straw = {
            "craftingFramework\\craft\\Straw1.wav",
            "craftingFramework\\craft\\Straw2.wav",
        },
        metal = {
            "craftingFramework\\craft\\Metal1.wav",
            "craftingFramework\\craft\\Metal2.wav",
            "craftingFramework\\craft\\Metal3.wav",
        },
        carve = {
            "craftingFramework\\craft\\Carve1.wav",
            "craftingFramework\\craft\\Carve2.wav",
        },
        defaultConstruction = {
            "craftingFramework\\craft\\Fabric1.wav",
            "craftingFramework\\craft\\Fabric2.wav",
            "craftingFramework\\craft\\Fabric3.wav",
            "craftingFramework\\craft\\Fabric4.wav",
        },
        deconstruction = {
            "craftingFramework\\craft\\Deconstruct1.wav",
            "craftingFramework\\craft\\Deconstruct2.wav",
            "craftingFramework\\craft\\Deconstruct3.wav",
        },
    }
}

--MCM Config (stored as JSON)
config.configPath = "craftingFramework"

---@class CraftingFramework.config
config.mcmDefault = {
    logLevel = "INFO",
    keybindRotate = {
        keyCode = tes3.scanCode.lShift
    },
    keybindModeCycle = {
        keyCode = tes3.scanCode.lAlt
    },
    quickModifierHotkey = {
        keyCode = tes3.scanCode.lShift
    },
    defaultMaterialRecovery = 75,
}
config.save = function(newConfig)
    inMemConfig = newConfig
    mwse.saveConfig(config.configPath, inMemConfig)
end

---@type CraftingFramework.config
config.mcm = setmetatable({}, {
    __index = function(_, key)
        inMemConfig = inMemConfig or mwse.loadConfig(config.configPath, config.mcmDefault)
        return inMemConfig[key]
    end,
    __newindex = function(_, key, value)
        inMemConfig = inMemConfig or mwse.loadConfig(config.configPath, config.mcmDefault)
        inMemConfig[key] = value
        mwse.saveConfig(config.configPath, inMemConfig)
    end
})


local persistentDefault = {
    knownRecipes = {},
    placementSetting = 'ground',
}

config.persistent = setmetatable({}, {
    __index = function(_, key)
        if not tes3.player then return end
        tes3.player.data[config.configPath] = tes3.player.data[config.configPath] or persistentDefault
        return tes3.player.data[config.configPath][key]
    end,
    __newindex = function(_, key, value)
        if not tes3.player then return end
        tes3.player.data[config.configPath] = tes3.player.data[config.configPath] or persistentDefault
        tes3.player.data[config.configPath][key] = value
    end
})

return config