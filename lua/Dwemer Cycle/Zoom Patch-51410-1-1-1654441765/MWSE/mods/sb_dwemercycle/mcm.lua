local confPath = "sb_dwemercycle"
local config = mwse.loadConfig(confPath)
if not config then
    config = { units = 0, keyBind = {keyCode = tes3.scanCode.y} }
end

local function registerModConfig()
    local template = mwse.mcm.createTemplate { name = "Dwemer Cycle", headerImagePath = "Textures\\sb_dwemercycle\\Logo.tga" }
    template:saveOnClose(confPath, config)

    local page = template:createPage { label = "Config", noScroll = true }
    local elementGroup = page:createSideBySideBlock()

    elementGroup:createInfo { text = "Unit System" }
    elementGroup:createDropdown {
        options  = {
            { label = "Metric", value = 0 },
            { label = "Imperial", value = 1 }
        },
        variable = mwse.mcm:createTableVariable {
            id    = "units",
            table = config
        }
    }

    elementGroup = page:createSideBySideBlock()

    elementGroup:createInfo { text = "Summon Key" }
    elementGroup:createKeyBinder {
        variable = mwse.mcm:createTableVariable {
            id    = "keyBind",
            table = config
        }
    }

    elementGroup = page:createSideBySideBlock()

    local stats = elementGroup:createCategory { label = "Stats" }
    stats:createInfo { text = "Weight\nGears\nFuel Tank\nAcceleration\nTop Speed" }

    local imperial = elementGroup:createCategory { label = "" }
    imperial:createInfo { text = "300 lb\nlow - medium - high\n10 mi/gal\n9 ft/s - 18 ft/s - 32 ft/s\n10 mph - 30 mph - 60 mph" }

    local metric = elementGroup:createCategory { label = "" }
    metric:createInfo { text = "136 kg\nlow - medium - high\n16 km/L\n3 m/s - 5 m/s - 10 m/s\n16 kph - 48 kph - 96 kph" }

    mwse.mcm.register(template)
end

local mcm = { config = config }

function mcm.init()
    event.register("modConfigReady", registerModConfig)
end

return mcm