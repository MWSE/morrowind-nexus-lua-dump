local config = require("CraftingFramework.config")
local Util = require("CraftingFramework.util.Util")
local mcmConfig = mwse.loadConfig(config.configPath, config.mcmDefault)

local LINKS_LIST = {
    {
        text = "Release history",
        url = "https://github.com/jhaakma/crafting-framework/releases"
    },
    {
        text = "Wiki",
        url = "https://github.com/jhaakma/crafting-framework/wiki"
    },
    {
        text = "Nexus",
        url = "https://www.nexusmods.com/morrowind/mods/51009"
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
    {
        text = "Sound Effects by SpratlyNation",
        url = "https://www.facebook.com/VideoGame360Pano",
    },
    {
        text = "Help with type definitions from C3pa",
        url = "https://www.nexusmods.com/morrowind/users/37172285"
    }
}
local SIDE_BAR_DEFAULT =
[[Crafting Framework is used by mods to implement crafting mechanics. There are a few default settings you can change here but most of them will be mod-specific and handled by the mods themselves.]]

local function addSideBar(component)
    local versionText = string.format("Crafting Framework")
    component.sidebar:createCategory(versionText)
    component.sidebar:createInfo{ text = SIDE_BAR_DEFAULT}

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
    local template = mwse.mcm.createTemplate{ name = config.static.modName }
    template.onClose = function()
        config.save(mcmConfig)
    end
    template:register()

    local page = template:createSideBarPage{ label = "Settings"}
    addSideBar(page)
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
            for _, logger in pairs(Util.loggers) do
                logger:setLogLevel(self.variable.value)
            end
        end
    }

    page:createSlider{
        label = "Material Recovery: %s%%",
        description = "Set the percentage of material recovered when a crafted object is destroyed. This may be overriden by mod or recipe-specific settings. Default: 75%",
        min = 0,
        max = 100,
        step = 1,
        variable = mwse.mcm.createTableVariable{ id = "defaultMaterialRecovery", table = mcmConfig },
    }
end
event.register("modConfigReady", registerMCM)