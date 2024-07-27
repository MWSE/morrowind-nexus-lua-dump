local ch = require("BeefStranger.Brighter Lights.configHelper")
local configPath = "Brighter Lights"

---@class bsBrighterLights<K, V>: { [K]: V }
local defaults = {
    multi = 2,
    enableLK = true,
    lightKey = { --Keycode to trigger menu
        keyCode = tes3.scanCode.v,
        isShiftDown = false,
        isAltDown = false,
        isControlDown = false,
    },
}

---@class bsBrighterLights
local config = mwse.loadConfig(configPath, defaults)

local function registerModConfig()
    local template = mwse.mcm.createTemplate({ name = configPath })
        template:saveOnClose(configPath, config)

    local settings = template:createPage({ label = "Settings" })

    settings:createSlider({
        label = "Light Multiplier",
        min = 0.1, max = 10, step = 0.10, jump = 1, decimalPlaces = 2,
        variable = ch.var("multi", config),
        callback = function (self)
            if tes3.player then
                if tes3.player.light then
                    local light = tes3.getEquippedItem({ actor = tes3.player, objectType = tes3.objectType.light }).object
                    local radius = light.radius
                    local updated = radius * self.variable.value
                    -- debug.log(light)
                    -- debug.log(light.radius)
                    tes3.player.light:setRadius(updated)
                end
            end
        end
    })

    ch.YN(settings, "Enable Light Hotkey", "enableLK", config, "")

    settings:createKeyBinder({
        label = "Keybind for Light Hotkey",
        variable = ch.var("lightKey", config),
        allowCombinations = false
    })

    template:register()
end
event.register(tes3.event.modConfigReady, registerModConfig)

return config