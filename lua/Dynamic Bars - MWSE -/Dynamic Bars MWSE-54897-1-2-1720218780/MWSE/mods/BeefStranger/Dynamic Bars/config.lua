local configPath = "DynamicBars"
local ch = require("BeefStranger.Dynamic Bars.configHelper")
local bs = require("BeefStranger.Dynamic Bars.common")
local info = bs.info

---@class bsDynamicBars<K, V>: { [K]: V }
local defaults = {
    barPadding  = 50,   --Extra Padding to lengthen the bars
    enabled     = true, --If Mod is Enabled
    showFatigue = true, --Enable Players Fatigue Value on Bar
    showHealth  = true, --Enable Players Health Value on Bar
    showMagicka = true, --Enable Players Magicka Value on Bar
    textPos     = 3,    --Tuned for 1440p 1.5x UI Scale
    updateRate  = 5,    --Debug
    widthCap    = 300,  --Stat Value at which The Bars Stop Growing
    hcAutoMove  = false
}

local function update()
    event.trigger(bs.barUpdate)
    local menu = tes3ui.findMenu("MenuMulti")
    if menu then
        menu:updateLayout()
    end
end

---@class bsDynamicBars
local config = mwse.loadConfig(configPath, defaults)

local function registerModConfig()
    local template = mwse.mcm.createTemplate({name = configPath})
        template:saveOnClose(configPath, config)

    local settings = template:createSideBarPage({label = "Settings"})

    ch.YN(settings, "Enable Mod", "enabled", config, "Enable", bs.restoreDefaults)
    ch.YN(settings, info.showHealth.label, "showHealth", config, info.showHealth.desc, update)
    ch.YN(settings, info.showMagicka.label, "showMagicka", config, info.showMagicka.desc, update)
    ch.YN(settings, info.showFatigue.label, "showFatigue", config, info.showFatigue.desc, update)
    ch.YN(settings, info.hcAutoMove.label, "hcAutoMove", config, info.hcAutoMove.desc, function () event.trigger(bs.manualMove) end)

    local widthCap

    local textPos = settings:createSlider({
        label = info.textPos.label,
        min = 1, max = 10, step = 1, jump = 1,
        variable = ch.tVar{ id ="textPos", table = config},
        description = info.textPos.desc..defaults.textPos,
        callback = update
    })

    local barPadding = settings:createSlider({
        label = info.barPadding.label,
        min = 0, max = 250, step = 1, jump = 10,
        variable = ch.tVar{ id ="barPadding", table = config},
        description = info.barPadding.desc..defaults.barPadding,
        callback = update
    })

    widthCap = settings:createSlider({
        label = info.widthCap.label,
        min = 50, max = 1000, step = 1, jump = 10,
        variable = ch.tVar{id = "widthCap", table = config},
        description = info.widthCap.desc..defaults.widthCap,
        callback = update
    })

    template:register()
end
event.register(tes3.event.modConfigReady, registerModConfig)

return config