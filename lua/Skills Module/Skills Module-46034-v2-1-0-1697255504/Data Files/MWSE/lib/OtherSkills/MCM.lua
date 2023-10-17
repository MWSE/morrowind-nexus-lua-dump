local config = require("OtherSkills.config")
local util = require("OtherSkills.util")

local LINKS_LIST = {
    {
        text = "Release history",
        url =  config.metadata.package.repository .. "/releases"
    },
    {
        text = "Wiki",
        url = config.metadata.package.repository .. "/wiki"
    },
    {
        text = "Nexus",
        url = config.metadata.package.homepage
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

local SIDE_BAR_DEFAULT = config.metadata.package.description

local function addSideBar(component)
    local versionText = string.format("%s Version %s", config.metadata.package.name, config.metadata.package.version)
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

local function registerModConfig()
    local template = mwse.mcm.createTemplate{ name = config.metadata.package.name}
    template.onClose = function()
        config.save()
    end
    template:register()
    local page = template:createSideBarPage{label = "Settings"}
    addSideBar(page)

    page:createDropdown{
        label = "Log Level",
        description = "Set the logging level for all Loggers.",
        options = {
            { label = "TRACE", value = "TRACE"},
            { label = "DEBUG", value = "DEBUG"},
            { label = "INFO", value = "INFO"},
            { label = "ERROR", value = "ERROR"},
            { label = "NONE", value = "NONE"},
        },
        variable =  mwse.mcm.createTableVariable{ id = "logLevel", table = config.mcm},
        callback = function(self)
            for _, logger in pairs(util.loggers) do
                logger:setLogLevel(self.variable.value)
            end
        end
    }
end
event.register("modConfigReady", registerModConfig)