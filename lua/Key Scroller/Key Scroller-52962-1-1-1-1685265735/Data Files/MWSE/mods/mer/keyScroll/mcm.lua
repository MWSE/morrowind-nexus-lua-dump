local util = require("mer.keyScroll.util")
local config = require("mer.keyScroll.config")
local metadata = config.metadata

local LINKS_LIST = {
    {
        text = "Release history",
        url = "https://github.com/jhaakma/keyScroll/releases"
    },
    -- {
    --     text = "Wiki",
    --     url = "https://github.com/jhaakma/keyScroll/wiki"
    -- },
    {
        text = "Nexus",
        url = "https://www.nexusmods.com/morrowind/mods/52962"
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
    }
}

local function addSideBar(component)
    component.sidebar:createCategory(metadata.package.name)
    component.sidebar:createInfo{ text = metadata.package.description}

    local linksCategory = component.sidebar:createCategory("Links")
    for _, link in ipairs(LINKS_LIST) do
        linksCategory:createHyperLink{ text = link.text, url = link.url }
    end
    local creditsCategory = component.sidebar:createCategory("Credits")
    for _, credit in ipairs(CREDITS_LIST) do
        if credit.url then
            creditsCategory:createHyperLink{ text = credit.text, url = credit.url }
        else
            creditsCategory:createInfo{ text = credit.text }
        end
    end
end

local function registerMCM()
    local template = mwse.mcm.createTemplate{ name = metadata.package.name }
    template.onClose = function()
        config.save()
        event.trigger("KeyScroll:McmUpdated")
    end
    template:register()

    local page = template:createSideBarPage{ label = "Settings"}
    addSideBar(page)

    page:createOnOffButton{
        label = string.format("Enable %s", metadata.package.name),
        description = "Enable or disable the mod.",
        variable = mwse.mcm.createTableVariable{
            id = "enabled",
            table = config.mcm,
        },
    }

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
event.register("modConfigReady", registerMCM)