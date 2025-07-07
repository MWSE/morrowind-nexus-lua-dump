local common = require("classImages.common")
local config = require("classImages.config")
local metadata = config.metadata
local LINKS_LIST = {
    {
        text = "История изменений",
        url = "https://github.com/jhaakma/dynamic-class-images/releases"
    },
    -- {
    --     text = "Wiki",
    --     url = "https://github.com/jhaakma/classImages/wiki"
    -- },
    -- {
    --     text = "Nexus",
    --     url = "https://www.nexusmods.com/morrowind/mods/52962"
    -- },
    {
        text = "Купить кофе для Merlord",
        url = "https://ko-fi.com/merlord"
    },
}

local CREDITS_LIST = {
    {
        text = "Написание кода: Merlord",
        url = "https://www.nexusmods.com/users/3040468?tab=user+files",
    },
    {
        text = "Создание изображений и логика их внедрения: Melchior Dahrk",
        url = "https://www.nexusmods.com/morrowind/users/962116?tab=user+files",
    }
}

local function addSideBar(component)
    component.sidebar:createCategory(config.modName)
    component.sidebar:createInfo{ text = "Заменяет изображение вашего класса динамически генерируемыми аналогами на основе специализации, характеристик и навыков."}

    local linksCategory = component.sidebar:createCategory("Ссылки")
    for _, link in ipairs(LINKS_LIST) do
        linksCategory:createHyperLink{ text = link.text, url = link.url }
    end
    local creditsCategory = component.sidebar:createCategory("Благодарности")
    for _, credit in ipairs(CREDITS_LIST) do
        if credit.url then
            creditsCategory:createHyperLink{ text = credit.text, url = credit.url }
        else
            creditsCategory:createInfo{ text = credit.text }
        end
    end
end

local function registerMCM()
    local template = mwse.mcm.createTemplate{ name = config.modName }
    template.onClose = function()
        config.save()
        event.trigger("KeyScroll:McmUpdated")
    end
    template:register()

    local page = template:createSideBarPage{ label = "Настройки"}
    addSideBar(page)

    page:createOnOffButton{
        label = string.format("Включение мода %s", config.modName),
        description = "Включение или выключение мода.",
        variable = mwse.mcm.createTableVariable{
            id = "enabled",
            table = config.mcm,
        },
    }

    page:createDropdown{
        label = "Уровень ведения логов",
        description = "Устанавливает уровень ведения логов для записи в MWSE.",
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
                logger:setLogLevel(self.variable.value)
            end
        end
    }
end
event.register("modConfigReady", registerMCM)