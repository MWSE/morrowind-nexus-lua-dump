local util = require("mer.autoAttack.util")
local config = util.config
local mcmConfig = mwse.loadConfig(config.configPath, config.mcmDefault)

local LINKS_LIST = {
    {
        text = "Release history",
        url = "https://github.com/jhaakma/auto-attack/releases"
    },
    -- {
    --     text = "Wiki",
    --     url = "https://github.com/jhaakma/auto-attack/wiki"
    -- },
    {
        text = "Nexus Page",
        url = "https://www.nexusmods.com/morrowind/mods/51348"
    },
    {
        text = "Buy me a coffee",
        url = "https://ko-fi.com/merlord"
    },
}
local CREDITS_LIST = {
    {
        text = "Made by Merlord",
        url = "https://www.nexusmods.com/users/3040468?tab=user+files",
    },
}

local function addSideBar(component)
    local versionText = string.format(config.static.modName)
    component.sidebar:createCategory(versionText)
    component.sidebar:createInfo{ text = config.static.modDescription}

    local linksCategory = component.sidebar:createCategory("Links")
    for _, link in ipairs(LINKS_LIST) do
        linksCategory:createHyperLink{ text = link.text, url = link.url }
    end
    local creditsCategory = component.sidebar:createCategory("Credits")
    for _, credit in ipairs(CREDITS_LIST) do
        creditsCategory:createHyperLink{ text = credit.text, url = credit.url }
    end
end

local function registerMCM()
    local template = mwse.mcm.createTemplate{ name = config.static.modName,}
    template.onClose = function()
        config.save(mcmConfig)
    end
    template:register()

    local page = template:createSideBarPage{ label = "Settings"}
    addSideBar(page)

    page:createYesNoButton{
        label = "Enable Mod",
        description = "Turn this mod on or off",
        variable = mwse.mcm.createTableVariable{ id = "enabled", table = mcmConfig }
    }

    page:createOnOffButton{
        label = "Display Messages",
        description = "Displays a message box whenever auto-attack is toggled on or off.",
        variable = mwse.mcm.createTableVariable{ id = "displayMessages", table = mcmConfig }
    }

    page:createKeyBinder{
        label = "Toggle Auto Attack Hot key",
        description = "The key combo to toggle auto attacking on or off.",
        variable = mwse.mcm.createTableVariable{ id = "hotKey", table = mcmConfig },
        allowCombinations = true
    }

    page:createSlider{
        label = "Max Swing: %s%%",
        description = "Determines how far back to pull the weapon before releasing while auto-attacking.",
        variable = mwse.mcm.createTableVariable{ id = "maxSwing", table = mcmConfig },
        min = 0,
        max = 100,
        jump = 10,
        step = 1
    }

    page:createDropdown{
        label = "Log Level",
        description = "Set the logging level for mwse.log. Keep on INFO unless you are debugging.",
        options = {
            { label = "TRACE", value = "TRACE"},
            { label = "DEBUG", value = "DEBUG"},
            { label = "INFO", value = "INFO"},
            { label = "ERROR", value = "ERROR"},
            { label = "NONE", value = "NONE"},
        },
        variable =  mwse.mcm.createTableVariable{ id = "logLevel", table = mcmConfig },
        callback = function(self)
            for _, logger in pairs(util.loggers) do
                logger:setLogLevel(self.variable.value)
            end
        end
    }
end
event.register("modConfigReady", registerMCM)