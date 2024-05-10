local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local metadata = config.metadata --[[@as MWSE.Metadata]]
local logger = common.createLogger("MCM")

local LINKS_LIST = {
    {
        text = "История версий",
        url = "https://github.com/jhaakma/joy-of-painting/releases"
    },
    {
        text = "Информация",
        url = "https://github.com/jhaakma/joy-of-painting/wiki"
    },
    {
         text = "Страница мода на Nexusmods",
         url = "https://www.nexusmods.com/morrowind/mods/53036"
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

local SIDE_BAR_DEFAULT =
[[Радость рисования позволяет вам рисовать собственные картины и продавать их или вешать на стену.]]

local function addSideBar(component)
    local versionText = string.format("Радость рисования, версия 1.2.3")
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
    local template = mwse.mcm.createTemplate{ name = "Радость рисования" }
    template.onClose = function()
        config.save()
        event.trigger("JoyOfPainting:McmUpdated")
    end
    template:register()

    local page = template:createSideBarPage{ label = "Настройки"}
    addSideBar(page)

    page:createYesNoButton{
        label = "Включить мод",
        description = "Включить/Выключить мод",
        variable = mwse.mcm.createTableVariable{ id = "enabled", table = config.mcm },
        callback = function(self)
            if self.variable.value == true then
                logger:info("Enabling mod")
                event.trigger("JoyOfPainting:ModEnabled")
                event.trigger("JoyOfPainting:McmUpdated")
            else
                logger:info("Disabling mod")
                event.trigger("JoyOfPainting:ModDisabled")
            end
        end
    }

    page:createSlider{
        label = "Максимум сохраненных картин",
        description = "Задайте максимальное количество изображений в полном разрешении для каждого художественного стиля, сохраненных в разделе`Data Files/Textures/jop/saved/`. Как только будет достигнуто максимальное значение, самая старая картина будет удалена, чтобы освободить место для новой.",
        min = 1,
        max = 100,
        step = 1,
        jump = 10,
        variable = mwse.mcm.createTableVariable{ id = "maxSavedPaintings", table = config.mcm },
    }

    page:createTextField{
        label = "Размер сохраненной картины",
        description = "Размер сохраненной картины. Это будет величина меньшей стороны картины.",
        variable = mwse.mcm.createTableVariable{ id = "savedPaintingSize", table = config.mcm },
        numbersOnly = true,
    }

    page:createYesNoButton{
        label = "Включить удаление гобелена",
        description = "Если этот параметр включен, вы можете активировать гобелен, чтобы убрать его и освободить место для картины.",
        variable = mwse.mcm.createTableVariable{ id = "enableTapestryRemoval", table = config.mcm },
    }

    page:createYesNoButton{
        label = "Показать подсказку к гобелену",
        description = "Если эта функция включена, при наведении курсора на гобелен будет отображаться всплывающая подсказка. Требуется перезагрузка, чтобы изменения вступили в силу.",
        variable = mwse.mcm.createTableVariable{ id = "showTapestryTooltip", table = config.mcm },
        restartRequired = true,
    }

    page:createDropdown{
        label = "Log Level",
        description = "Установите уровень ведения журнала событий.",
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

    template:createExclusionsPage{
        label = "Торговцы красками",
        description = "Выберите, какие торговцы продают краски и другие материалы для рисования",
        leftListLabel = "Торговцы красками",
        rightListLabel = "Список торговцев",
        filters = {
            {
                label = "",
                callback = function()
                    local npcs = {}
                    for obj in tes3.iterateObjects(tes3.objectType.npc) do
                        ---@cast obj tes3npc
                        if obj.class and obj.class.bartersMiscItems then
                            local id = obj.id:lower()
                            npcs[id] = true
                        end
                    end
                    local npcsList = {}
                    for npc, _ in pairs(npcs) do
                        table.insert(npcsList, npc)
                    end
                    table.sort(npcsList)
                    return npcsList
                end
            }
        },
        variable = mwse.mcm.createTableVariable{
            id = "paintSuppliesMerchants",
            table = config.mcm,
        },
    }
end
event.register("modConfigReady", registerMCM)