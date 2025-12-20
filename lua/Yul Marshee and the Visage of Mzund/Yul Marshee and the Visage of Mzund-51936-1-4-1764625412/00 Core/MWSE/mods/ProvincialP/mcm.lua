local confPath = "ProvincialP"


local mcm = { config = mwse.loadConfig(confPath) or
    {
        mode = 0
    }
}

local function registerModConfig()
    local template = mwse.mcm.createTemplate { name = "Yul Marshee and the Visage of Mzund", headerImagePath ="Textures/glow/door_glow_00_g.dds" }
    template:saveOnClose(confPath, mcm.config)
    local controls = template:createPage({ label = "Controls" })
    controls:createInfo {text = "Move forward: Forward keybind\nMove backward: Backward keybind\nUp: Shift+Forward\nDown: Shift+Back \nDismount: Q\nFixMe command: Shift+x\n\n\nCustom controls will be added at a later date"}
    mwse.mcm.register(template)
end

function mcm.init()
    event.register("modConfigReady", registerModConfig)
end

return mcm