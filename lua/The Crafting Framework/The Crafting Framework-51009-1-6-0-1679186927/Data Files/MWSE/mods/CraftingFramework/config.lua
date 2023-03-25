local inMemConfig

local this = {}

--Static Config (stored right here)
this.static = {
    modName = "Crafting Framework",
    modDescription = [[
The Crafting Framework is a powerful, flexible and easy to use framework for creating crafting mods.
]]
}

--MCM Config (stored as JSON)
this.configPath = "craftingFramework"

---@class CraftingFramework.config
this.mcmDefault = {
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
    defaultMaterialRecovery = 75
}
this.save = function(newConfig)
    inMemConfig = newConfig
    mwse.saveConfig(this.configPath, inMemConfig)
end

---@type CraftingFramework.config
this.mcm = setmetatable({}, {
    __index = function(_, key)
        inMemConfig = inMemConfig or mwse.loadConfig(this.configPath, this.mcmDefault)
        return inMemConfig[key]
    end,
    __newindex = function(_, key, value)
        inMemConfig = inMemConfig or mwse.loadConfig(this.configPath, this.mcmDefault)
        inMemConfig[key] = value
        mwse.saveConfig(this.configPath, inMemConfig)
    end
})


local persistentDefault = {
    knownRecipes = {},
    placementSetting = 'ground',
}

this.persistent = setmetatable({}, {
    __index = function(_, key)
        if not tes3.player then return end
        tes3.player.data[this.configPath] = tes3.player.data[this.configPath] or persistentDefault
        return tes3.player.data[this.configPath][key]
    end,
    __newindex = function(_, key, value)
        if not tes3.player then return end
        tes3.player.data[this.configPath] = tes3.player.data[this.configPath] or persistentDefault
        tes3.player.data[this.configPath][key] = value
    end
})

return this