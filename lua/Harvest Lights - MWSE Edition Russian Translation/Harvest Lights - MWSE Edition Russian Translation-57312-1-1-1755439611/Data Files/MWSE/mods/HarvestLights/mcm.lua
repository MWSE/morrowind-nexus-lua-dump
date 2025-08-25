

local configLua = require("HarvestLights.config")
local config = configLua.settings
local configDefault = configLua.defaultConfig

----------------------
-- MCM Template --
----------------------

local function registerModConfig()
    local template = mwse.mcm.createTemplate{ name = "Подсветка собранных растений"}
    template:saveOnClose("HarvestLights", config)

    -- Preferences Page
    local preferences = template:createSideBarPage{
        label = "Настройки",
        noScroll = true,
    }
    preferences.sidebar:createCategory{ label = "Подсветка собранных растений" }
    preferences.sidebar:createInfo{ text = "Отключает ближайшие источники света при сборе растений из контейнеров и включает их снова, когда растения вырастут. Наборы растений и связанных с ними источников света можно редактировать на соответствующей странице." }

    -- Feature Toggles
    local settings = preferences:createCategory{}
    settings:createOnOffButton{
        label = "Включить",
        description = "Включить или выключить мод. Отключение мода также приведет к невозможности повторного включения отключенных источников света.\nТребуется перезагрузка.\n\nПо умолчанию: Включено",
        variable = mwse.mcm.createTableVariable{
            id = "enabled",
            table = config,
            restartRequired = true
        },
    }

    settings:createSlider{
        label = "Расстояние до источника света",
        description = "Максимальное расстояние от растения на котором может находиться источник света, что бы быть отключенным при сборе растения. Источник света также должен находиться как минимум на таком же расстоянии от других подходящих растений." ..
                        " Увеличение значения предотвратит игнорирование удалённых источников света, но потребует сбора урожая с более отдалённых контейнеров для их отключения." ..
                        "\nТребуется перезагрузка.\n\nПо умолчанию: 160",
        min = 96,
        max = 256,
        variable = mwse.mcm.createTableVariable{ id = "singleDistance", table = config }
    }

    local containerLightPage = template:createPage{
        label= "Растения и источники света",
        noScroll = true
    }

    containerLightPage:createInfo({ text = "Поле ниже содержит наборы растений и связанных с ними источников света, которые отключаются при сборе растения. Наборы можно добавлять, изменять или удалять." .. 
                                            " Два типа наборов разделены точкой с запятой в каждой строке: слева - ID контейнеров (или их части), справа - ID источников света." ..
                                            " Каждый ID должен быть заключён в двойные кавычки и разделён запятыми. Каждый ID должен встречаться только один раз во всём поле. Не забудьте нажать Enter для сохранения изменений." ..
                                            "\nУбедитесь, что в файле mwse.log нет записей \"[Harvest Lights] Error\" после загрузки игры с изменёнными настройками.\nТребуется перезагрузка.", })

    containerLightPage:createButton{
        label = "Сбросить настройки",
        callback = function()
            tes3.messageBox({ message = "Вы уверены, что хотите вернуть настройки растений и источников света по умолчанию?",
            buttons = { "Да", "Нет" },
            callback = function(e)
                if e.button == 0 then
	                config.containerLights = configDefault.containerLights
                    tes3.messageBox({ message = "Изменения в поле не отобразятся до повторного открытия этой страницы." })
                end
            end })
        end
    }

    containerLightPage:createParagraphField{
        sNewValue = "Растения и источники света сохранены",
        variable = mwse.mcm.createTableVariable{ id = "containerLights", table = config },
        height = 500,
        postCreate = function(component)
            component.elements.inputField.widget.lengthLimit = 99999
        end
    }

    local debugPage = template:createSideBarPage{
        label= "Отладка",
        noScroll = true
    }
    preferences.sidebar:createInfo{"Подсветка собранных растений v1.1"}

    debugPage:createOnOffButton{
        label = "Режим отладки",
        description = "Выводит в mwse.log информацию о наборах растений и источников света, а также об отключаемых/включаемых источниках.\n\nПо умолчанию: Выключено",
        variable = mwse.mcm.createTableVariable{
            id = "debug",
            table = config,
        },
    }

    debugPage:createButton{
        buttonText = "Найти ближайший источник света",
        description = "Выводит в mwse.log ID ближайшего включённого источника света для удобства создания или расширения наборов.",
        inGameOnly = true,
        callback = function()
            local closestLight
            local closestLightPosition = math.huge
            for _,cell in pairs(tes3.getActiveCells()) do
                for light in cell:iterateReferences(tes3.objectType.light) do
                    if not light.disabled then
                        if not closestLight or light.position:distance(tes3.player.position) < closestLightPosition then
                            closestLight = light
                        end
                    end
                end
            end

            if closestLight then mwse.log(closestLight.baseObject.id) end
        end
    }

    debugPage:createButton{
        buttonText = "Включить все источники света",
        description = "Включает все источники света, отключённые этим модом. Полезно при удалении наборов или деинсталляции мода.",
        inGameOnly = true,
        callback = function()
            for _,cell in pairs(tes3.dataHandler.nonDynamicData.cells) do
                for light in cell:iterateReferences(tes3.objectType.light) do
                    if light.data.harvestDisabled then
                        light:enable()
                        light.data.harvestDisabled = nil
                    end
                end
            end
        end
    }

    template:register()
end

event.register(tes3.event.modConfigReady, registerModConfig)