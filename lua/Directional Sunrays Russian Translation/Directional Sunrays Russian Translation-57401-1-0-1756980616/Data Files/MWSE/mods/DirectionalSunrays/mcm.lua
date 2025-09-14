local config = require("DirectionalSunrays.config")

----------------------
-- MCM Template --
----------------------

local function registerModConfig()
    local template = mwse.mcm.createTemplate{ name = "Направленные солнечные лучи"}
    template:saveOnClose("DirectionalSunrays", config)

    -- Preferences Page
    local preferences = template:createSideBarPage{
        label = "Настройки",
        noScroll = true,
    }

    preferences.sidebar:createCategory{ label = "Направленные солнечные лучи" }
    preferences.sidebar:createInfo{ text = "Скрывает или уменьшает интенсивность солнечных лучей из мода \"Свет в конах\" (Glow in the Dahrk) в зависимости от текущего положения солнца." }

    -- Feature Toggles
    local settings = preferences:createCategory{}
    settings:createOnOffButton{
        label = "Включить",
        description = "Включить или выключить мод.\nТребует перезагрузки сохранения.\n\nПо умолчанию: Вкл",
        variable = mwse.mcm.createTableVariable{
            id = "enabled",
            table = config
        },
    }

    settings:createSlider{
        label = "Внешний предел: %s градусов",
        description = "Лучи, которые находятся под углом больше этого значения от солнца, не будут светить вообще. Лучи между внутренним и внешним пределами будут светить, но менее ярко." ..
                        "\nТребует перезагрузки сохранения.\n\nПо умолчанию: 70",
        min = 45,
        max = 180,
        variable = mwse.mcm.createTableVariable{ id = "outerLimit", table = config }
    }

    settings:createSlider{
        label = "Внутренний предел: %s градусов",
        description = "Солнечные лучи в пределах этого угла от солнца будут светить с полной интенсивностью. Если это значение больше внешнего предела, то мод \"Направленные солнечные лучи\" будет считать его равным внешнему пределу." ..
                        "\nТребует перезагрузки сохранения.\n\nПо умолчанию: 35",
        min = 0,
        max = 180,
        variable = mwse.mcm.createTableVariable{ id = "innerLimit", table = config }
    }

    template:createExclusionsPage{
        label = "Нестандартные окна",
        description = "В моделях окон из мода \"Свет в окнах\" угол каждого солнечного луча указан в NIF-файлах, что позволяет моду \"Направленные солнечные лучи\" легко определять их видимость. Однако другие моды могли создать лучи в своих моделях по-другому, что приведет к сбою этого подхода." ..
                        " Выбор объекта на этой странице заставит мод \"Направленные солнечные лучи\" вместо этого анализировать каждую вершину лучей этого объекта для определения их направления. Этот подход работает в большем количестве случаев, но значительно более ресурсоемок и может привести к заметному падению производительности, если в ячейке много таких объектов.",
        leftListLabel = "Нестандартные окна",
        rightListLabel = "Статичные объекты и активаторы",
        variable = mwse.mcm.createTableVariable{ id = "nonstandardMeshes", table = config },
        filters = {
            { type = "Object", objectType = { tes3.objectType.activator, tes3.objectType.static } },
        }
    }

    template:createExclusionsPage{
        label = "Игнорируемые окна",
        description = "Если солнечные лучи окна не работают с модом \"Направленные солнечные лучи\" или не должны быть затронуты им по какой-либо причине, то объект можно добавить в список игнорируемых.",
        leftListLabel = "Игнорируемые окна",
        rightListLabel = "Статичные объекты и активаторы",
        variable = mwse.mcm.createTableVariable{ id = "ignoredMeshes", table = config },
        filters = {
            { type = "Object", objectType = { tes3.objectType.activator, tes3.objectType.static } },
        }
    }

    template:register()
end

event.register(tes3.event.modConfigReady, registerModConfig)