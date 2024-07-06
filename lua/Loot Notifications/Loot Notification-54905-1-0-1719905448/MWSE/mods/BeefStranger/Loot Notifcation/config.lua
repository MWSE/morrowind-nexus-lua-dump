local configPath = "Loot Notification"
local ch = require("BeefStranger.Loot Notifcation.configHelper")

---@class bsLootNotif<K, V>: { [K]: V }
local defaults = {
    alpha = 0,
    maxNotify = 15,
    showDur = 5,
    xPos = 0,
    yPos = 0,
}

---@class bsLootNotif
local config = mwse.loadConfig(configPath, defaults)

local function registerModConfig()
    local template = mwse.mcm.createTemplate({ name = configPath })
        template:saveOnClose(configPath, config)

    local settings = template:createPage({ label = "Settings" })

    local alpha = settings:createSlider({
        label = "Menu Background Alpha",
        min = 0, max = 1, step = 0.01, jump = 0.10, decimalPlaces = 2,
        variable = ch.tVar{ id ="alpha", table = config},
        callback = function() event.trigger("bsLootNotif") end
    })

    local maxNotify = settings:createSlider({
        label = "Max Amount of Notifications Displayed at Once",
        min = 0, max = 25, step = 1, jump = 5,
        variable = ch.tVar{ id ="maxNotify", table = config},
        callback = function() event.trigger("bsLootNotif") end
    })

    local showDur = settings:createSlider({
        label = "Duration to Show Notifications",
        min = 0, max = 30, step = 1, jump = 5,
        variable = ch.tVar{ id ="showDur", table = config},
        callback = function() event.trigger("bsLootNotif") end
    })

    local xPos = settings:createSlider({
        label = "Menu position X",
        min = 0, max = 1, step = 0.01, jump = 0.10, decimalPlaces = 2,
        variable = ch.tVar{ id ="xPos", table = config},
        callback = function() event.trigger("bsLootNotif") end
    })

    local yPos = settings:createSlider({
        label = "Menu position Y",
        min = 0, max = 1, step = 0.01, jump = 0.10, decimalPlaces = 2,
        variable = ch.tVar{ id ="yPos", table = config},
        callback = function() event.trigger("bsLootNotif") end
    })

    template:register()
end
event.register(tes3.event.modConfigReady, registerModConfig)

return config