local function registerModConfig()
    local template = mwse.mcm.createTemplate { name = "Stray Cat",
        headerImagePath = "Textures\\sb_stray\\logo.tga" }

    mwse.mcm.register(template)
end

local mcm = {}

function mcm.init()
    event.register("modConfigReady", registerModConfig)
end

return mcm
