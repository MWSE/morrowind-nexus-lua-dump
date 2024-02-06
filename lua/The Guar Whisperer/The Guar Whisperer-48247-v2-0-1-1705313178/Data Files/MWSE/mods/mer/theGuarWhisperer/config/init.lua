
---@class GuarWhisperer.config
local config = {}
config.configPath = "guar_whisperer"
config.metadata = toml.loadMetadata("TheGuarWhisperer")
config.properties = require("mer.theGuarWhisperer.config.Properties")

---Global flag to reset fading on save/load
config.isFading = false

---@class GuarWhisperer.config.MCM
local defaultConfig = {
    enabled = true,
    commandToggleKey = { keyCode = tes3.scanCode.q},
    logLevel = "INFO",
    teleportDistance = 1500,
    merchants = {
        ["arrille"] = true,
        ["ra'virr"] = true,
        ["mebestian ence"] = true,
        ["alveno andules"] = true,
        ["dralasa nithryon"] = true,
        ["galtis guvron"] = true,
        ["goldyn belaram"] = true,
        ["irgola"] = true,
        ["clagius clanler"] = true,
        ["fadase selvayn"] = true,
        ["tiras sadus"] = true,
        ["heifnir"] = true,
        ["ancola"] = true,
    },
    exclusions = {
        guar = true,
        guar_feral = true
    }
}

---@type GuarWhisperer.config.MCM
config.mcm = mwse.loadConfig(config.configPath, defaultConfig)
config.save = function()
    mwse.saveConfig(config.configPath, config.mcm)
end

---@class GuarWhisperer.config.TempData
---@field isFading boolean
config.tempData = setmetatable({}, {
    __index = function(_, key)
        if not tes3.player then return end
        if not tes3.player.tempData then return end
        if not tes3.player.tempData[config.configPath] then return end
        return tes3.player.tempData[config.configPath][key]
    end,
    __newindex = function(_, key, value)
        if not tes3.player then return end
        if not tes3.player.tempData then return end
        if not tes3.player.tempData[config.configPath] then
            tes3.player.tempData[config.configPath] = {}
        end
        tes3.player.tempData[config.configPath][key] = value
    end
})

---@class GuarWhisperer.config.Data
---@field createdGuars table<string, boolean>
local persistentDefault = {
    createdGuars = {}
}

---@type GuarWhisperer.config.Data
config.persistentData = setmetatable({}, {
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