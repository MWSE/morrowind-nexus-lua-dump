local config = require("OtherSkills.config")
local util = require("OtherSkills.util")

local LINKS_LIST = {
    {
        text = "История версий",
        url =  config.metadata.package.repository .. "/releases"
    },
    {
        text = "Информация",
        url = config.metadata.package.repository .. "/wiki"
    },
    {
        text = "Страница мода на Nexusmods",
        url = config.metadata.package.homepage
    },
    {
        text = "Поддержать автора",
        url = "https://ko-fi.com/merlord"
    },
}
local CREDITS_LIST = {
    {
        text = "Сделано Merlord",
        url = "https://www.nexusmods.com/users/3040468?tab=user+files",
    },
}

local SIDE_BAR_DEFAULT = [[Базовая платформа для добавления пользовательских навыков.]]

local function addSideBar(component)
    local versionText = string.format("Модуль навыков Версия %s", config.metadata.package.version)
    component.sidebar:createCategory(versionText)
    component.sidebar:createInfo{ text = SIDE_BAR_DEFAULT}

    local linksCategory = component.sidebar:createCategory("Ссылки")
    for _, link in ipairs(LINKS_LIST) do
        linksCategory:createHyperLink{ text = link.text, url = link.url }
    end
    local creditsCategory = component.sidebar:createCategory("Авторы")
    for _, credit in ipairs(CREDITS_LIST) do
        creditsCategory:createHyperLink{ text = credit.text, url = credit.url }
    end
end

local function registerModConfig()
    local template = mwse.mcm.createTemplate{ name = "Модуль навыков"}
    template.onClose = function()
        config.save()
    end
    template:register()
    local page = template:createSideBarPage{label = "Настройки"}
    addSideBar(page)

    page:createSlider{
        label = "Множитель роста навыков",
        description = "Множитель количества прогресса, необходимого для повышения уровня навыка; по умолчанию 1,25 (такой же, как у всех навыков в оригинальной игре).",
        decimalPlaces = 2,
        min = 0.0,
        max = 2.0,
        step = 0.1,
        jump = 0.2,
        variable = mwse.mcm.createTableVariable{ id = "fOtherSkillBonus", table = config.mcm}
    }

    page:createDropdown{
        label = "Уровень журнала",
        description = "Выберите уровень ведения журнала событий mwse.log. Оставьте INFO, если не проводите отладку",
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