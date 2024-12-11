local common = require("mer.darkShard.common")
local config = common.config
local metadata = config.metadata

local LINKS_LIST = {
    {
        text = "Release History",
        url = "https://github.com/jhaakma/mmm2024/releases"
    },
    {
        text = "Nexus",
        url = "https://www.nexusmods.com/morrowind/mods/55448"
    },
}

local CREDITS_LIST = {
    {
        text = "Models and Textures by Vegetto",
        url = "https://next.nexusmods.com/profile/Vegetto88"
    },
    {
        text = "Landscaping and Lore Research by MassiveJuice",
        url = "https://next.nexusmods.com/profile/MassiveJuice"
    },
    {
        text = "Quests and Interiors by Danae",
        url = "https://next.nexusmods.com/profile/Danae123"
    },
    {
        text = "Scripted Mechanics by Merlord",
        url = "https://next.nexusmods.com/profile/Merlord",
    },
    {
        text = "Clutter, Proofreading and Crimefighting by Lucevar",
        url = "https://next.nexusmods.com/profile/Lucevar"
    },
}


local function addSideBar(component)
    component.sidebar:createCategory(metadata.package.name)
    component.sidebar:createInfo{ text = metadata.package.description }

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
    template:saveOnClose(metadata.package.name, config.mcm)
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
        variable =  mwse.mcm.createTableVariable{ id = "logLevel", table = config.mcm },
        callback = function(self)
            for _, logger in pairs(common.loggers) do
                logger:setLogLevel(self.variable.value)
            end
        end
    }
    page:createYesNoButton{
        label = "Use Page Up/Down keys for Telescope Zoom",
        description = "When enabled, you can use Page Up and Page Down keys to zoom in and out with the telescope instead of the scroll wheel.",
        variable = mwse.mcm.createTableVariable{ id = "zoomUsingPageKeys", table = config.mcm }
    }
end
event.register("modConfigReady", registerMCM)
