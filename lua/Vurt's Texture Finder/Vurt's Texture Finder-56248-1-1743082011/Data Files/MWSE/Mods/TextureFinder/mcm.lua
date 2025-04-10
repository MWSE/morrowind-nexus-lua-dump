local configPath = "TextureFinder"
local config = mwse.loadConfig(configPath, { enabled = true, showFullPaths = true }) -- Load or create config with defaults

local function registerModConfig()
    local template = mwse.mcm.createTemplate({ name = "Texture Finder" })
    template:saveOnClose(configPath, config)

    local page = template:createSideBarPage({ label = "Settings" })
    page.sidebar:createInfo({ text = "Texture Finder Mod - Shows texture names on attack." })

    local category = page:createCategory({ label = "Toggle Mod" })
    category:createYesNoButton({
        label = "Enable Texture Finder",
        description = "Turn the texture detection mod on or off.",
        variable = mwse.mcm.createTableVariable({ id = "enabled", table = config }),
    })

    category:createYesNoButton({
        label = "Show Full Texture Paths",
        description = "If Yes, shows full paths (e.g., textures\\rock\\tx_rock_01.dds). If No, shows only filenames (e.g., tx_rock_01.dds).",
        variable = mwse.mcm.createTableVariable({ id = "showFullPaths", table = config }),
    })

    mwse.mcm.register(template)
end

event.register("modConfigReady", registerModConfig)
return config