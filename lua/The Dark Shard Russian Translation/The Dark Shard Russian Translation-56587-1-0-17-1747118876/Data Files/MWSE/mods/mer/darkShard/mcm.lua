local common = require("mer.darkShard.common")
local config = common.config
local metadata = config.metadata

local LINKS_LIST = {
    {
        text = "История версий",
        url = "https://github.com/jhaakma/mmm2024/releases"
    },
    {
        text = "Страница мода на Nexusmods",
        url = "https://www.nexusmods.com/morrowind/mods/55448"
    },
}

local CREDITS_LIST = {
    {
        text = "Модели и текстуры: Vegetto",
        url = "https://next.nexusmods.com/profile/Vegetto88"
    },
    {
        text = "Landscaping and Lore Research by MassiveJuice",
        url = "https://next.nexusmods.com/profile/MassiveJuice"
    },
    {
        text = "Квесты и интерьеры: Danae",
        url = "https://next.nexusmods.com/profile/Danae123"
    },
    {
        text = "Программирование: Merlord",
        url = "https://next.nexusmods.com/profile/Merlord",
    },
    {
        text = "Clutter, Proofreading and Crimefighting by Lucevar",
        url = "https://next.nexusmods.com/profile/Lucevar"
    },
}


local function addSideBar(component)
    component.sidebar:createCategory("Темный осколок")
    component.sidebar:createInfo{ text = "После неудачной телепортации проводником гильдии, поиск секретов Темного осколка приведет вас за пределы Нирна." }

    local linksCategory = component.sidebar:createCategory("Ссылки")
    for _, link in ipairs(LINKS_LIST) do
        linksCategory:createHyperLink{ text = link.text, url = link.url }
    end
    local creditsCategory = component.sidebar:createCategory("Авторы")
    for _, credit in ipairs(CREDITS_LIST) do
        if credit.url then
            creditsCategory:createHyperLink{ text = credit.text, url = credit.url }
        else
            creditsCategory:createInfo{ text = credit.text }
        end
    end
end

local function registerMCM()
    local template = mwse.mcm.createTemplate{ name = "Темный осколок" }
    template:saveOnClose(metadata.package.name, config.mcm)
    template:register()

    local page = template:createSideBarPage{ label = "Настройки"}
    addSideBar(page)

    page:createDropdown{
        label = "Уровень журнала",
        description = "Установите уровень ведения журнала событий mwse.log. Оставьте INFO, если вы не занимаетесь отладкой.",
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
        label = "Использовать кнопки Page Up/Down для масштабирования телескопа",
        description = "Включите эту функцию, чтобы вместо колеса прокрутки использовать клавиши Page Up и Page Down для масштабирования изображения телескопа.",
        variable = mwse.mcm.createTableVariable{ id = "zoomUsingPageKeys", table = config.mcm }
    }
end
event.register("modConfigReady", registerMCM)
