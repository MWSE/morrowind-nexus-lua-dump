local config = require("CraftingFramework.config")
local Util = require("CraftingFramework.util.Util")
local mcmConfig = mwse.loadConfig(config.configPath, config.mcmDefault)

local LINKS_LIST = {
    {
        text = "История версий",
        url = "https://github.com/jhaakma/crafting-framework/releases"
    },
    {
        text = "Информация",
        url = "https://github.com/jhaakma/crafting-framework/wiki"
    },
    {
        text = "Страница мода на Nexusmods",
        url = "https://www.nexusmods.com/morrowind/mods/51009"
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
    {
        text = "Звуки: SpratlyNation",
        url = "https://www.facebook.com/VideoGame360Pano",
    },
    {
        text = "Help with type definitions from C3pa",
        url = "https://www.nexusmods.com/morrowind/users/37172285"
    }
}
local SIDE_BAR_DEFAULT =
[[Базовая платформа для реализации в модах механики изготовления различных предметов. Здесь вы можете изменить несколько настроек по умолчанию, но большинство из них будет зависеть от конкретного мода, который может иметь собственное меню настройки.]]

local function addSideBar(component)
    local versionText = string.format("Модуль ремесла")
    component.sidebar:createCategory(versionText)
    component.sidebar:createInfo{ text = SIDE_BAR_DEFAULT}

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
    local template = mwse.mcm.createTemplate{ name = "Модуль ремесла" }
    template.onClose = function()
        config.save(mcmConfig)
    end
    template:register()

    local page = template:createSideBarPage{ label = "Настройки"}
    addSideBar(page)
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
        variable =  mwse.mcm.createTableVariable{ id = "logLevel", table = mcmConfig },
        callback = function(self)
            for _, logger in pairs(Util.loggers) do
                logger:setLogLevel(self.variable.value)
                ---@diagnostic disable-next-line
                logger:info("New Log Level: %s", logger.logLevel)
            end
        end
    }

    page:createSlider{
        label = "Восстановление материалов: %s%%",
        description = "Установите процент восстановления материалов при уничтожении предмета. Это значение может быть изменено настройками конкретного мода или чертежа. По умолчанию: 75%",
        min = 0,
        max = 100,
        step = 1,
        variable = mwse.mcm.createTableVariable{ id = "defaultMaterialRecovery", table = mcmConfig },
    }

    page:createKeyBinder{
        label = "Назначить горячую клавишу быстрой активации",
        description = "Назначьте кнопку для быстрой активации контейнеров и других предметов, для котрых установленно `quickActivateCallback` в чертеже. По умолчанию: Left Shift",
        allowCombinations = false,
        variable = mwse.mcm.createTableVariable{ id = "quickModifierHotkey", table = mcmConfig },
    }

    page:createYesNoButton{
        label = "Включить бесконечное хранилище",
        description = "Включите эту опцию, чтобы можно было хранить неограниченное количество предметов в переносных контейнерах. Не влияет на ранее размещенные контейнеры.",
        variable = mwse.mcm.createTableVariable{ id = "enableInfiniteStorage", table = config.mcm },
    }
end
event.register("modConfigReady", registerMCM)