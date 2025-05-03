local EasyMCM = include("easyMCM.EasyMCM")

-- Create a placeholder page if EasyMCM is not installed.
if (EasyMCM == nil) or (EasyMCM.version < 1.4) then
    local function placeholderMCM(element)
        element:createLabel{text="This mod config menu requires EasyMCM v1.4 or later."}
        local link = element:createTextSelect{text="Перейти на страницу EasyMCM"}
        link.color = tes3ui.getPalette("link_color")
        link.widget.idle = tes3ui.getPalette("link_color")
        link.widget.over = tes3ui.getPalette("link_over_color")
        link.widget.pressed = tes3ui.getPalette("link_pressed_color")
        link:register("mouseClick", function()
            os.execute("start https://www.nexusmods.com/morrowind/mods/46427?tab=files")
        end)
    end
    mwse.registerModConfig("Quick Loot", {onCreate=placeholderMCM})
    return
end


-------------------
-- Utility Funcs --
-------------------
local config = require("QuickLoot.config")

local function getContainers()
    local list = {}
    for obj in tes3.iterateObjects(tes3.objectType.container) do
		list[#list+1] = (obj.baseObject or obj).id:lower()
    end
    table.sort(list)
    return list
end

----------------------
-- EasyMCM Template --
----------------------
local template = EasyMCM.createTemplate{name="Быстрый лут"}
template:saveOnClose("QuickLoot", config)
template:register()

-- Preferences Page
local preferences = template:createSideBarPage{label="Настройки"}
preferences.sidebar:createInfo{text="Быстрый лут версия 2.0"}

-- Sidebar Credits
local credits = preferences.sidebar:createCategory{label="Благодарности:"}
credits:createHyperlink{
    text = "mort - Создатель, кодер и т.д.",
    exec = "start https://www.nexusmods.com/morrowind/users/4138441?tab=user+files",
}
credits:createHyperlink{
    text = "Svengineer99 - Помощь в написании кода",
    exec = "start https://www.nexusmods.com/morrowind/users/1121630?tab=user+files",
}
credits:createHyperlink{
    text = "Greatness7 - Помощь в написании кода (В частности этого меню)",
    exec = "start https://www.nexusmods.com/users/64030?tab=user+files",
}
credits:createHyperlink{
    text = "Nullcascade - MWSE",
    exec = "start https://www.nexusmods.com/morrowind/users/26153919?tab=user+files",
}
credits:createHyperlink{
    text = "Hrnchamd - MWSE",
    exec = "start https://www.nexusmods.com/morrowind/users/843673?tab=user+files",
}
credits:createHyperlink{
    text = "PeteTheGoat - Бурное тестирование",
    exec = "start https://www.nexusmods.com/morrowind/users/25319994",
}


-- Feature Toggles
local toggles = preferences:createCategory{label="Основное"}
toggles:createOnOffButton{
    label = "Выключить 'Быстрый лут'?",
    description = "По умолчанию: Выкл\n\n",
    variable = EasyMCM:createTableVariable{
        id = "modDisabled",
        table = config,
    },
}
toggles:createOnOffButton{
    label = "Показывать сообщения при луте?",
    description = "Показывает стандартное сообщение при получении предметов.\n\nПо умолчанию: Выкл\n\n",
    variable = EasyMCM:createTableVariable{
        id = "showMessageBox",
        table = config,
    },
}
toggles:createOnOffButton{
    label = "Спрятать содержимое контейнеров с ловушками?",
    description = "Выкл - показывает предметы, ловушка срабатывает при взятии.\n\nПо умолчанию: Вкл\n\n",
    variable = EasyMCM:createTableVariable{
        id = "hideTrapped",
        table = config,
    },
}
toggles:createOnOffButton{
    label = "Спрятать статус замка?",
    description = "Выкл - показывает Закрыто при закрытом замке, при открытом - ничего.\n\nПо умолчанию: Выкл\n\n",
    variable = EasyMCM:createTableVariable{
        id = "hideLocked",
        table = config,
    },
}
toggles:createOnOffButton{
    label = "Показывать меню быстрого лута на растениях и других органических контейнерах? ",
    description = "Органический контейнер — это любой контейнер, который восстанавливается.. Черный/Белый список переопределит эту опцию.\n\nПо умолчанию: Вкл\n\n",
    variable = EasyMCM:createTableVariable{
        id = "showPlants",
        table = config,
    },
}
toggles:createOnOffButton{
    label = "Показывать для заскриптованных контейнеров?",
    description = "Некоторые контейнеры имеют на себе скрипт, который отслеживает, когда игрок взаимодействует с ними, после чего запускает код. Так что лучше данную опцию не включать.\n\nПо умолчанию: Выкл\n\n",
    variable = EasyMCM:createTableVariable{
        id = "showScripted",
        table = config,
    },
}
toggles:createOnOffButton{
    label = "Спрятать подсказки контейнеров? ",
    description = "Стандартная подсказка при наведении на контейнер, будет отображаться на ряду с новой. Некоторым людям это по душе.\n\nПо умолчанию: Вкл\n\n",
    variable = EasyMCM:createTableVariable{
        id = "hideTooltip",
        table = config,
    },
}
toggles:createOnOffButton{
    label = "Позволить брать один выделенный предмет вашей стандартной кнопкой взаимодействия? ",
    description = "С этой опцией вы будете брать один предмет не специальной кнопкой, а стандартной, в том числе с растений.\n\nПо умолчанию: Вкл\n\n",
    variable = EasyMCM:createTableVariable{
        id = "activateMode",
        table = config,
    },
}
toggles:createSlider{
    label = "Количество предметов в списке: ",
	min=4,
	max=25,
	jump=2,
    variable = EasyMCM:createTableVariable{
        id = "maxItemDisplaySize",
        table = config,
    },
}
toggles:createSlider{
    label = "Позиция меню по оси Х (больше = правее): ",
	max=10,
	jump=1,
    variable = EasyMCM:createTableVariable{
        id = "menuX",
        table = config,
    },
}
toggles:createSlider{
    label = "Позиция меню по оси У (больше = ниже): ",
	max=10,
	jump=1,
    variable = EasyMCM:createTableVariable{
        id = "menuY",
        table = config,
    },
}

local keybinds = preferences:createCategory{label="Настройка кнопок"}
keybinds:createKeyBinder{
    label = "Взять один предмет(Если ваша стандартная кнопка взаимодействия уже берет один предмет, значит эта будет открывать контейнер)",
    allowCombinations = true,
    variable = EasyMCM.createTableVariable{
        id = "takeKey",
        table = config,
        defaultSetting = {
            keyCode = tes3.scanCode['z'],
            --These default to false
            isShiftDown = false,
            isAltDown = false,
            isControlDown = false,
        }
    }
}
keybinds:createKeyBinder{
    label = "Взять все предметы",
    allowCombinations = true,
    variable = EasyMCM.createTableVariable{
        id = "takeAllKey",
        table = config,
        defaultSetting = {
            keyCode = tes3.scanCode['x'],
            --These default to false
            isShiftDown = false,
            isAltDown = false,
            isControlDown = false,
        }
    }
}
keybinds:createKeyBinder{
    label = "Назначить клавишу вкл/выкл мод 'Быстрый лут'",
    allowCombinations = true,
    variable = EasyMCM.createTableVariable{
        id = "svengKey",
        table = config,
        defaultSetting = {
            keyCode = tes3.scanCode['x'],
            --These default to false
            isShiftDown = false,
            isAltDown = false,
            isControlDown = false,
        }
    }
}

-- Blacklist Page
template:createExclusionsPage{
    label = "Черный список",
    description = "Все органические контейнеры обрабатываются как растения. Сундуки гильдий по умолчанию в черном списке, как и некоторые контейнеры TR. Остальные можно добавить вручную через это меню.",
    leftListLabel = "Черный список",
    rightListLabel = "Контейнеры",
    variable = EasyMCM:createTableVariable{
        id = "blacklist",
        table = config,
    },
    filters = {
        {callback = getContainers},
    },
}

-- Whitelist Page
template:createExclusionsPage{
    label = "Белый список",
    description = "Контейнеры со скриптами автоматически пропускаются, но их можно включить в этом меню. Будьте осторожны, добавляя в белый список контейнеры с OnActivate — это может сломать их скрипты.",
    leftListLabel = "Белый список",
    rightListLabel = "Контейнеры",
    variable = EasyMCM:createTableVariable{
        id = "whitelist",
        table = config,
    },
    filters = {
        {callback = getContainers},
    },
}
