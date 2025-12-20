
local common = require("mer.RightClickMenuExit.common")
local config = common.config
local messages = common.messages

local LINKS_LIST = {
    {
        text = messages.ReleaseHistory(),
        url = "https://github.com/jhaakma/shop-around/releases"
    },
    {
        text = "Nexus",
        url = "https://www.nexusmods.com/morrowind/mods/55144"
    },
    {
        text = messages.BuyMeACoffee(),
        url = "https://ko-fi.com/merlord"
    },
}
local CREDITS_LIST = {
    {
        text = messages.MadeBy(),
        url = "https://www.nexusmods.com/users/3040468?tab=user+files",
    },
}

local function addSideBar(component)
    component.sidebar:createCategory(messages.ModName())
    component.sidebar:createInfo{ text = messages.ModDescription()}

    local linksCategory = component.sidebar:createCategory(messages.Links())
    for _, link in ipairs(LINKS_LIST) do
        linksCategory:createHyperLink{ text = link.text, url = link.url }
    end
    local creditsCategory = component.sidebar:createCategory(messages.Credits())
    for _, credit in ipairs(CREDITS_LIST) do
        if credit.url then
            creditsCategory:createHyperLink{ text = credit.text, url = credit.url }
        else
            creditsCategory:createInfo{ text = credit.text }
        end
    end
end

local function registerMCM()
    local template = mwse.mcm.createTemplate{ name = messages.ModName() }
    template.onClose =function()
        config.save()
    end
    template:register()

    local page = template:createSideBarPage{ label = messages.Settings()}
    addSideBar(page)

    page:createYesNoButton{
        label = messages.EnableRightClickExit(),
        description = messages.EnableRightClickExitDescription(),
        variable = mwse.mcm.createTableVariable{
            id = "enableRightClickExit",
            table = config.mcm
        }
    }

    page:createYesNoButton{
        label = messages.PlayMenuSound(),
        description = messages.PlayMenuSoundDescription(),
        variable = mwse.mcm.createTableVariable{
            id = "enableClickSound",
            table = config.mcm
        }
    }

    page:createYesNoButton{
        label = messages.ReopenInventory(),
        description = messages.ReopenInventoryDescription(),
        variable = mwse.mcm.createTableVariable{
            id = "reopenInventory",
            table = config.mcm
        }
    }

    page:createDropdown{
        label = messages.LogLevel(),
        description = messages.LogLevelDescription(),
        options = {
            { label = "TRACE", value = "TRACE"},
            { label = "DEBUG", value = "DEBUG"},
            { label = "INFO", value = "INFO"},
            { label = "ERROR", value = "ERROR"},
            { label = "NONE", value = "NONE"},
        },
        variable =  mwse.mcm.createTableVariable{ id = "logLevel", table = config.mcm},
        callback = function(self)
            for _, logger in pairs(common.loggers) do
                logger:setLevel(self.variable.value)
            end
        end
    }


end
registerMCM()