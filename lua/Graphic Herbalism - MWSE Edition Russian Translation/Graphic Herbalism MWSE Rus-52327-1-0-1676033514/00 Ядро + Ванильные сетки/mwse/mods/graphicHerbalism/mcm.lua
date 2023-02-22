local EasyMCM = include("easyMCM.EasyMCM")

-- Create a placeholder page if EasyMCM is not installed.
if (EasyMCM == nil) or (EasyMCM.version < 1.4) then
    local function placeholderMCM(element)
        element:createLabel{text="Для этого мода рекомендуется EasyMCM версии 1.4 или выше."}
        local link = element:createTextSelect{text="Перейти на страницу EasyMCM в Nexus"}
        link.color = tes3ui.getPalette("link_color")
        link.widget.idle = tes3ui.getPalette("link_color")
        link.widget.over = tes3ui.getPalette("link_over_color")
        link.widget.pressed = tes3ui.getPalette("link_pressed_color")
        link:register("mouseClick", function()
            os.execute("start https://www.nexusmods.com/morrowind/mods/46427?tab=files")
        end)
    end
    mwse.registerModConfig("Graphic Herbalism", {onCreate=placeholderMCM})
    return
end


-------------------
-- Utility Funcs --
-------------------
local config = require("graphicHerbalism.config")

local function getHerbalismObjects()
    local list = {}
    for obj in tes3.iterateObjects(tes3.objectType.container) do
        if obj.organic then
            list[#list+1] = (obj.baseObject or obj).id:lower()
        end
    end
    table.sort(list)
    return list
end

local function getVolumeAsInteger(self)
    return math.round(config.volume * 100)
end

local function setVolumeAsDecimal(self, value)
    config.volume = math.round(value / 100, 2)
end


----------------------
-- EasyMCM Template --
----------------------
local template = EasyMCM.createTemplate{name="Graphic Herbalism"}
template:saveOnClose("graphicHerbalism", config)
template:register()

-- Preferences Page
local preferences = template:createSideBarPage{label="Опции"}
preferences.sidebar:createInfo{text="MWSE Graphic Herbalism Версия 1.03"}

-- Sidebar Credits
local credits = preferences.sidebar:createCategory{label="Кредиты:"}
credits:createHyperlink{
    text = "Greatness7 - Скриптинг",
    exec = "start https://www.nexusmods.com/morrowind/users/64030?tab=user+files",
}
credits:createHyperlink{
    text = "Merlord - Поддержка MCM",
    exec = "start https://www.nexusmods.com/morrowind/users/3040468?tab=user+files",
}
credits:createHyperlink{
    text = "NullCascade - Поддержка MWSE",
    exec = "start https://www.nexusmods.com/morrowind/users/26153919?tab=user+files",
}
credits:createHyperlink{
    text = "Petethegoat - Помощь со скриптами и обратная связь",
    exec = "start https://www.nexusmods.com/morrowind/users/25319994?tab=user+files",
}
credits:createHyperlink{
    text = "Remiros - Сетки MOP",
    exec = "start https://www.nexusmods.com/morrowind/users/899234?tab=user+files",
}
credits:createHyperlink{
    text = "Stuporstar - Преобразование сеток и сглаживание",
    exec = "start http://stuporstar.sarahdimento.com/",
}
credits:createHyperlink{
    text = "Sveng - Тестинг и обратная связь",
    exec = "start https://www.nexusmods.com/morrowind/users/1121630?tab=user+files",
}
credits:createHyperlink{
    text = "Gruntella - универсальные текстуры Graphic Herbalism",
    exec = "start https://www.nexusmods.com/morrowind/users/2356095?tab=user+files",
}
credits:createHyperlink{
    text = "Skrawafunda и Manauser - оригинальные текстуры Graphic Herbalism",
    exec = "start https://www.nexusmods.com/morrowind/users/13100210?tab=user+files",
}
credits:createHyperlink{
    text = "Moranar - Сглаженные сетки",
    exec = "start https://www.nexusmods.com/morrowind/users/6676263?tab=user+files",
}
credits:createHyperlink{
    text = "Tyddy - Сглаженные сетки",
    exec = "start https://www.nexusmods.com/morrowind/users/3281858?tab=user+files",
}
credits:createHyperlink{
    text = "Articus - Помощь с сетками и обратная связь",
    exec = "start https://www.nexusmods.com/morrowind/users/51799631?tab=user+files",
}
credits:createHyperlink{
    text = "DassiD - Апскейлинг текстур",
    exec = "start https://www.nexusmods.com/morrowind/users/6344059?tab=user+files",
}
credits:createHyperlink{
    text = "Nich и CJW-Craigor - Правильное отображение руды",
    exec = "start http://mw.modhistory.com/download-1-13484",
}

-- Feature Toggles
local toggles = preferences:createCategory{label="Настройки"}
toggles:createOnOffButton{
    label = "Показывать всплывающие подсказки",
    description = "Показывать всплывающие подсказки\n\n Этот параметр определяет, будут ли отображаться всплывающие подсказки по ингредиентам при наведении курсора на растение.\n\nПо умолчанию: Вкл\n\n",
    variable = EasyMCM:createTableVariable{
        id = "showTooltips",
        table = config,
    },
}
toggles:createOnOffButton{
    label = "Показать сообщение о сборе",
    description = "Показывать сообщение о сборе\n\n Этот параметр определяет, будет ли отображаться сообщение после сбора растний.\n\nПо умолчанию: Вкл\n\n",
    variable = EasyMCM:createTableVariable{
        id = "showPickedMessage",
        table = config,
    },
}

-- Feature Controls
local controls = preferences:createCategory{label="Управление"}
controls:createSlider{
    label = "Громкость: %s%%",
    description = "Настройте громкость сбора",
    variable = EasyMCM:createVariable{
        get = getVolumeAsInteger,
        set = setVolumeAsDecimal,
    },
}

-- Blacklist Page
template:createExclusionsPage{
    label = "Черный список",
    description = "Все органические контейнеры обрабатываются как растения. Сундуки гильдии по умолчанию занесены в черный список, как и несколько контейнеров TR. Другие могут быть добавлены вручную в этом меню.",
    leftListLabel = "Черный список",
    rightListLabel = "Объекты",
    variable = EasyMCM:createTableVariable{
        id = "blacklist",
        table = config,
    },
    filters = {
        {callback = getHerbalismObjects},
    },
}

-- Whitelist Page
template:createExclusionsPage{
    label = "Белый список",
    description = "Контейнеры, созданные скриптами, автоматически пропускаются, но могут быть включены в этом меню. Контейнеры, измененные с помощью расширенных звуков от Piratelord, по умолчанию занесены в белый список. Будьте осторожны с внесением контейнеров в белый список, использующих OnActivate, так как это может привести к поломке их скриптов.",
    leftListLabel = "Белый список",
    rightListLabel = "Объекты",
    variable = EasyMCM:createTableVariable{
        id = "whitelist",
        table = config,
    },
    filters = {
        {callback = getHerbalismObjects},
    },
}
