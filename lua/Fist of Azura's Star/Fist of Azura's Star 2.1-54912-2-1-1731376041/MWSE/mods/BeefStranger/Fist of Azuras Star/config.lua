local configPath = "Fist of Azuras Star"
---@class bsFistOfAzuraCfg<K, V>: { [K]: V }
local defaults = {
    h2hMin = 1,      ---Min amount attackSpeed can be
    h2hMax = 1.75,   ---The max amount that gets added to attackSpeed when H2h is 100
    h2hCap = 100,    ---H2H stops adding to attackSpeed at this value
    speedMax = 0.25, ---The max amount that gets added to attackSpeed when Speed is 100
    speedCap = 200,  ---Speed stops adding to attackSpeed at this value
    base = true,     ---Only use Base and not Current Speed in Calculations
    useSpeed = true, ---Include Speed in attackSpeed calculations
    perkLevel = 25,  ---Recieve 1 perk per this many levels
    perkMax = 4,     ---The max amount of perk points
    showPerk = true
}


---@class bsFistOfAzuraCfg
local config = mwse.loadConfig(configPath, defaults)

local function registerModConfig()
    local template = mwse.mcm.createTemplate({ name = configPath, defaultConfig = defaults, config = config })
        template:saveOnClose(configPath, config)

    local settings = template:createPage({ label = "Settings" })
    settings.showReset = true

    settings:createYesNoButton{label = "Show Perks under Hand-to-Hand Skill", configKey = "showPerk"}

    settings:createSlider({
        label = "Levels Per Perk",
        configKey = "perkLevel",
        min = 15, max = 100, jump = 10,
    })

    settings:createSlider({
        label = "Max Amount of Perks",
        configKey = "perkMax",
        min = 1, max = 8, jump = 1,
    })
    template:register()
end
event.register(tes3.event.modConfigReady, registerModConfig)

return config