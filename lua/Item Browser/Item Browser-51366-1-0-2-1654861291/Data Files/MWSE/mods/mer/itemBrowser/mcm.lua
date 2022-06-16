local Util = require("mer.itemBrowser.util")
local config = require("mer.itemBrowser.config")
local mcmConfig = mwse.loadConfig(config.configPath, config.mcmDefault)

local LINKS_LIST = {
    {
        text = "Release history",
        url = "https://github.com/jhaakma/item-browser/releases"
    },
    -- {
    --     text = "Wiki",
    --     url = "https://github.com/jhaakma/crafting-framework/wiki"
    -- },
    {
        text = "Nexus",
        url = "https://www.nexusmods.com/morrowind/mods/51366"
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
    local versionText = string.format("Item Browser")
    component.sidebar:createCategory(versionText)
    component.sidebar:createInfo{ text = config.static.modDescription }

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

    page:createYesNoButton{
        label = "Enable Mod",
        description = "Turn this mod on or off. Expect a delay if enabling for the first time this game session, as it will take a moment to register all of the recipes.",
        variable = mwse.mcm.createTableVariable{ id = "enabled", table = mcmConfig },
        callback = function(self)
            if self.variable.value == true then
                event.trigger("ItemBrowser:RegisterMenus")
            end
        end
    }

    page:createKeyBinder{
        label = "Hot key",
        description = "The key combo to activate the item browser menu.",
        variable = mwse.mcm.createTableVariable{ id = "hotKey", table = mcmConfig },
        allowCombinations = true
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
        variable =  mwse.mcm.createTableVariable{ id = "logLevel", table = mcmConfig, default = config.mcmDefault.logLevel},
        callback = function(self)
            for _, logger in pairs(Util.loggers) do
                logger:setLogLevel(self.variable.value)
            end
        end
    }
end
event.register("modConfigReady", registerMCM)