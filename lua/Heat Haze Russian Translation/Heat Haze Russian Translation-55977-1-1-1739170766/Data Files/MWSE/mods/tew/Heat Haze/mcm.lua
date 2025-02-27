local configPath = "Heat Haze"
local config = require("tew.Heat Haze.config")
mwse.loadConfig("Heat Haze")
local modversion = require("tew\\Heat Haze\\version")
local version = modversion.version

local function registerVariable(id)
    return mwse.mcm.createTableVariable{
        id = id,
        table = config
    }
end

local template = mwse.mcm.createTemplate{
    name="Тепловая дымка",
    headerImagePath="\\Textures\\tew\\Heat Haze\\heathaze_logo.tga"}

    local page = template:createPage{label="Основные настройки", noScroll=true}
    page:createCategory{
        label = "\"Тепловая дымка\" Версия "..version.." от vtastek and tewlwolow.\nСкрипт шейдера тепловой дымки.\n\nНастройки:",
    }

    page:createYesNoButton{
        label = "Включить режим отладки?",
        variable = registerVariable("debugLogOn"),
        restartRequired=true
    }

    page:createYesNoButton{
        label = "Изменить время начала и окончания? Не рекомендуется, если вы используете моды, изменяющие время восхода и захода солнца.",
        variable = registerVariable("overrideHours"),
    }

    page:createSlider{
        label = "Изменяет время начала работы теплового шейдера.\nПо умолчанию = 6. Часов",
        min = 0,
        max = 23,
        step = 1,
        jump = 1,
        variable=registerVariable("hazeStartHour")

    }

    page:createSlider{
        label = "Изменяет время окончания работы теплового шейдера.\nПо умолчанию = 21. Часов",
        min = 0,
        max = 23,
        step = 1,
        jump = 1,
        variable=registerVariable("hazeEndHour")

    }

    template:createExclusionsPage{
        label = "Регионы",
        description = "Выберите, в каких регионах будет работать шейдер. Чтобы включить, переместите нужные регионы в левую таблицу.",
        toggleText = "Включить найденные",
        leftListLabel = "Тепловые зоны",
        rightListLabel = "Все регионы",
        showAllBlocked = false,
        variable = mwse.mcm.createTableVariable{
            id = "heatRegions",
            table = config,
        },

        filters = {

            {
                label = "Регионы",
                callback = (
                    function()
                        local regionNames = {}
                        for region in tes3.iterate(tes3.dataHandler.nonDynamicData.regions) do
                            table.insert(regionNames, region.id)
                        end
                        return regionNames
                    end
                )
            },

        }
    }

    template:createExclusionsPage{
        label = "Погодные условия",
        description = "Выберите, при каких погодных условиях должен работать шейдер. Чтобы включить, переместите нужные погодные условия в левую таблицу",
        toggleText = "Включить найденные",
        leftListLabel = "Теплая погода",
        rightListLabel = "Вся погода",
        showAllBlocked = false,
        variable = mwse.mcm.createTableVariable{
            id = "heatWeathers",
            table = config,
        },

        filters = {

            {
                label = "Погода",
                callback = (
                    function()
                        local weatherNames = {}
                        for weather, _ in pairs(tes3.weather) do
                            table.insert(weatherNames, weather:sub(1,1):upper()..weather:sub(2))
                        end
                        return weatherNames
                    end
                )
            },

        }
    }



template:saveOnClose(configPath, config)
mwse.mcm.register(template)
