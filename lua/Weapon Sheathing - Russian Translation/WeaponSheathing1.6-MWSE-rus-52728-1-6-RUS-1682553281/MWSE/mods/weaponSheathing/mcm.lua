local config = require("weaponSheathing.config")

local template = mwse.mcm.createTemplate{name="Weapon Sheathing"}
template:saveOnClose("weaponSheathing", config)
template:register()

-- Preferences Page
local preferences = template:createSideBarPage{label="Настройки"}
preferences.sidebar:createInfo{
    text = "Weapon Sheathing, Версия 1.6\n\nДобро пожаловать в меню конфигурации! Здесь вы можете настроить, какие функции мода будут включены или выключены.\n\nНаведите курсор на отдельные опции для получения дополнительной информации. Чтобы изменения, сделанные здесь, вступили в силу, может потребоваться перезагрузка сохраненной игры.\n\nЭтот мод стал возможен только благодаря вкладу наших талантливых членов сообщества. Вы можете использовать ссылки ниже, чтобы найти больше их контента.\n"
}

-- Sidebar Credits
local credits = preferences.sidebar:createCategory{label="Авторы:"}
credits:createHyperlink{
    text = "akortunov",
    exec = "https://www.nexusmods.com/morrowind/users/39882615?tab=user+files",
}
credits:createHyperlink{
    text = "Greatness7",
    exec = "start https://www.nexusmods.com/morrowind/users/64030?tab=user+files",
}
credits:createHyperlink{
    text = "Heinrich",
    exec = "start https://www.nexusmods.com/morrowind/users/49330348?tab=user+files",
}
credits:createHyperlink{
    text = "Hrnchamd",
    exec = "start https://www.nexusmods.com/morrowind/users/843673?tab=user+files",
}
credits:createHyperlink{
    text = "London Rook",
    exec = "start https://www.nexusmods.com/users/9114769?tab=user+files",
}
credits:createHyperlink{
    text = "Lord Berandas",
    exec = "start https://www.nexusmods.com/morrowind/users/1858915?tab=user+files",
}
credits:createHyperlink{
    text = "Melchior Dahrk",
    exec = "start https://www.nexusmods.com/morrowind/users/962116?tab=user+files",
}
credits:createHyperlink{
    text = "MementoMoritius",
    exec = "start https://www.nexusmods.com/morrowind/users/20765944?tab=user+files",
}
credits:createHyperlink{
    text = "NullCascade",
    exec = "start https://www.nexusmods.com/morrowind/users/26153919?tab=user+files",
}
credits:createHyperlink{
    text = "Petethegoat",
    exec = "start https://www.nexusmods.com/morrowind/users/25319994?tab=user+files",
}
credits:createHyperlink{
    text = "PikachunoTM",
    exec = "start https://www.nexusmods.com/morrowind/users/16269634?tab=user+files",
}
credits:createHyperlink{
    text = "Remiros",
    exec = "start https://www.nexusmods.com/morrowind/users/899234?tab=user+files",
}

-- Feature Buttons
local buttons = preferences:createCategory{}
buttons:createOnOffButton{
    label = "Показать неподготовленное оружие",
    description = "Показать неподготовленное оружие\n\nЭтот параметр определяет, будет ли экипированное оружие видно, когда оно не готово к бою. Объекты, заблокированные списками исключений, не учитывают эту настройку, и их видимость всегда будет отключена.\n\nПо-умолчанию: Вкл",
    variable = mwse.mcm:createTableVariable{
        id = "showWeapon",
        table = config,
    },
}
buttons:createOnOffButton{
    label = "Показывать неподготовленные щиты на спине",
    description = "Показывать неподготовленные щиты на спине\n\nЭтот параметр определяет, будут ли щиты видны на спине в неподготовленном состоянии. Объекты, заблокированные списками исключений, не учитывают эту настройку, и их видимость всегда будет отключена.\n\nПо-умолчанию: Выкл",
    variable = mwse.mcm:createTableVariable{
        id = "showShield",
        table = config,
    },
}
buttons:createOnOffButton{
    label = "Показать модифицированные ножны и колчаны",
    description = "Показать модифицированные ножны и колчаны\n\nЭтот параметр определяет, будут ли пользовательские ассеты использоваться в сочетании с другими возможностями мода. Объекты, заблокированные списками исключений, не учитывают эту настройку, и их видимость всегда будет отключена.\n\nПо-умолчанию: Вкл",
    variable = mwse.mcm:createTableVariable{
        id = "showCustom",
        table = config,
    },
}

-- Exclusions Page
template:createExclusionsPage{
    label = "Исключения",
    description = "Weapon Sheathing по-умолчанию будет поддерживать всех персонажей и снаряжение в вашей игре. В некоторых случаях это не идеально, и вы можете предпочесть исключить определенные объекты из обработки. Эта страница предоставляет интерфейс для выполнения этой задачи. Используя приведенные ниже списки, вы можете легко просмотреть или отредактировать, какие объекты должны быть заблокированы, а какие разрешены.",
    variable = mwse.mcm:createTableVariable{
        id = "blocked",
        table = config,
    },
    filters = {
        {
            label = "Плагины",
            type = "Plugin",
        },
        {
            label = "Персонажи",
            type = "Object",
            objectType = tes3.objectType.npc,
        },
        {
            label = "Существа",
            type = "Object",
            objectType = tes3.objectType.creature,
        },
        {
            label = "Щиты",
            type = "Object",
            objectType = tes3.objectType.armor,
            objectFilters = {
                slot = tes3.armorSlot.shield
            },
        },
        {
            label = "Оружие",
            type = "Object",
            objectType = tes3.objectType.weapon,
        },
    },
}
