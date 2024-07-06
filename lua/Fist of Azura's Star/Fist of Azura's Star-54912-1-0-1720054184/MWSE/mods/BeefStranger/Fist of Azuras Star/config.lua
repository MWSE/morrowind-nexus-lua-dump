local configPath = "Fist of Azuras Star"
local bs = require("BeefStranger.Fist of Azuras Star.common")
local ts = tostring

---@class bsFistOfAzura<K, V>: { [K]: V }
local defaults = {
    baseSpeedOnly = false, --Use Base value of speed instead of current buffed value
    useSpeed = true, --Use Speed in calcs
    h2hMax = 1.50, --The speed when Hand to Hand is at level 100
    speedMax = 0.25, --The speed added when Speed attribute is 100
    showSpeed = true,
}

---@class bsFistOfAzura
local config = mwse.loadConfig(configPath, defaults)

local function registerModConfig()
    local template = mwse.mcm.createTemplate({ name = configPath })
    template:saveOnClose(configPath, config)

    local settings = template:createSideBarPage { label = "Settings", }

    local h2hMax = settings:createSlider({
        variable = mwse.mcm.createTableVariable { id = "h2hMax", table = config },
        label = "What Attack Speed Will Be When Hand-to-Hand is at 100  ",
        description = "What Attack Speed Will Be when Hand-To-Hand is 100 \n\n Default : " .. defaults.h2hMax,
        min = 0.1, max = 3, step = 0.01, jump = 0.05, decimalPlaces = 2,
        -- callback = function(self) mwse.log("h2hMax " .. config.h2hMax) end
    })

    bs.yesNoB(settings, "Use Speed", "useSpeed", config, "Make Player Speed affects Attack Speed \n\n Default : "..ts(defaults.useSpeed))

    local speedMax = settings:createSlider({
        variable = mwse.mcm.createTableVariable { id = "speedMax", table = config },
        label = "How much Player Speed Adds to Attack Speed When Speed is 100  ",
        description = "How much gets added to Attack Speed when Speed is 100 \n\n Default : " .. defaults.speedMax,
        min = 0.1, max = 3, step = 0.01, jump = 0.05, decimalPlaces = 2,
        -- callback = function(self) mwse.log("speedMax " .. config.speedMax) end
    })

    bs.yesNoB(settings, "Base Speed Only", "baseSpeedOnly", config, "Only factor in Players Base Speed, without factoring in Buffs to Speed \n\n Default : "..ts(config.baseSpeedOnly))
    bs.yesNoB(settings, "Show Attack Speed", "showSpeed", config, "Show Attack Speed when Hovering Over Hand-to-Hand in the Skills Menu \n\n Default : "..ts(config.showSpeed))

    template:register()
end
event.register(tes3.event.modConfigReady, registerModConfig)

return config