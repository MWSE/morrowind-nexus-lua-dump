local Util = require("mer.itemBrowser.util")
local config = require("mer.itemBrowser.config")
local mcmConfig = mwse.loadConfig(config.configPath, config.mcmDefault)

local LINKS_LIST = {
    {
        text = "История версий",
        url = "https://github.com/jhaakma/item-browser/releases"
    },
    -- {
    --     text = "Wiki",
    --     url = "https://github.com/jhaakma/crafting-framework/wiki"
    -- },
    {
        text = "Страница мода на Nexusmods",
        url = "https://www.nexusmods.com/morrowind/mods/51366"
    },
    {
        text = "Поддержать автора",
        url = "https://ko-fi.com/merlord"
    },
}
local CREDITS_LIST = {
    {
        text = "Автор: Merlord",
        url = "https://www.nexusmods.com/users/3040468?tab=user+files",
    },
}

local function addSideBar(component)
    local versionText = string.format("Каталог предметов")
    component.sidebar:createCategory(versionText)
    component.sidebar:createInfo{ text = config.static.modDescription }

    local linksCategory = component.sidebar:createCategory("Ссылки:")
    for _, link in ipairs(LINKS_LIST) do
        linksCategory:createHyperLink{ text = link.text, url = link.url }
    end
    local creditsCategory = component.sidebar:createCategory("Создатели:")
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

    local page = template:createSideBarPage{ label = "Настройки"}
    addSideBar(page)

    page:createYesNoButton{
        label = "Включить мод",
        description = "Включить или выключить мод. При первом включении в игровой сессии возможны задержки, так как регистрация всех предметов займет некоторое время.",
        variable = mwse.mcm.createTableVariable{ id = "enabled", table = mcmConfig },
        callback = function(self)
            if self.variable.value == true then
                event.trigger("ItemBrowser:RegisterMenus")
            end
        end
    }

    page:createKeyBinder{
        label = "Горячая клавиша",
        description = "Комбинация клавиш для вызова меню каталога предеметов.",
        variable = mwse.mcm.createTableVariable{ id = "hotKey", table = mcmConfig },
        allowCombinations = true
    }

    page:createDropdown{
        label = "Log Level",
        description = "Выберите уровень ведения журнала событий mwse.log. Оставьте INFO, если не проводите отладку.",
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