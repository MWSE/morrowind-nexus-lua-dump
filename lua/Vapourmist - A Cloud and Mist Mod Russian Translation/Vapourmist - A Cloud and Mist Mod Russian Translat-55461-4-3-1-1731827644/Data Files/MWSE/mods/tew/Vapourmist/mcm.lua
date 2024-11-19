local configPath = "Vapourmist"
local config = require("tew.Vapourmist.config")
local metadata = toml.loadMetadata("Vapourmist")

local function registerVariable(id)
    return mwse.mcm.createTableVariable {
        id = id,
        table = config
    }
end

local template = mwse.mcm.createTemplate {
    name = "Стихия Мглы",
    headerImagePath = "\\Textures\\tew\\Vapourmist\\logo.dds" }

local mainPage = template:createPage { label = "Главные настройки", noScroll = true }
mainPage:createCategory {
    label = "Стихия Мглы" .. " " .. metadata.package.version .. " От tewlwolow.\n" .. "Добавление и настройка эффектов тумана, дымки и объемных облаков" .."\n\nНастройки:"
}

mainPage:createOnOffButton{
    label = "Включить Стихию Мглы?",
    description = "Enable Vapourmist?\n\nDefault: On\n\n",
    variable = registerVariable("modEnabled")
}

mainPage:createYesNoButton {
    label = "Включить отладку мода?",
    variable = registerVariable("debugLogOn"),
    restartRequired = true
}
mainPage:createYesNoButton {
    label = "Включить облака?",
    variable = registerVariable("clouds"),
}
mainPage:createYesNoButton {
    label = "Включить шейдерный туман?",
    variable = registerVariable("mistShader"),
}
mainPage:createYesNoButton {
    label = "Включить NIF туман?",
    variable = registerVariable("mistNIF"),
}
mainPage:createYesNoButton {
    label = "Включить шейдерный туман в интерьерах?",
    variable = registerVariable("interiorShader"),
}
mainPage:createYesNoButton {
    label = "Включить NIF туман в интерьерах?",
    variable = registerVariable("interiorNIF"),
}

mainPage:createSlider {
    label = "Настройка скорости движения облаков по небу.\nСтандарт - 45.\nМножитель скорости",
    min = 0,
    max = 100,
    step = 1,
    jump = 10,
    variable = registerVariable("speedCoefficient")
}

local weathersPage = template:createPage { label = "Разрешенные погодные условия", noScroll = true }
weathersPage:createCategory {
    label = "Настройки типов погодных условий, при которых могут появляться облака и туман.\n",
}

weathersPage:createExclusionsPage {
    label = "Облачная погода",
    description = "Погода при которой появляются облака:",
    toggleText = "Переключить",
    leftListLabel = "Облачная погода",
    rightListLabel = "Вся погода",
    showAllBlocked = false,
    variable = mwse.mcm.createTableVariable {
        id = "cloudyWeathers",
        table = config,
    },

    filters = {

        {
            label = "Погода",
            callback = (
                function()
                    local weatherNames = {}
                    for weather, _ in pairs(tes3.weather) do
                        if weather == "thunder" then
                            table.insert(weatherNames, "Thunderstorm")
                        else
                            table.insert(weatherNames, weather:sub(1, 1):upper() .. weather:sub(2))
                        end
                    end
                    table.sort(weatherNames)
                    return weatherNames
                end
            )
        },

    }
}

weathersPage:createExclusionsPage {
    label = "Туманная погода",
    description = "Настройки типов погодных условий, при которых может появляться туман (с учетом рассвета/заката и тумана после дождя):",
    toggleText = "Переключить",
    leftListLabel = "Туманная погода",
    rightListLabel = "Вся погода",
    showAllBlocked = false,
    variable = mwse.mcm.createTableVariable {
        id = "mistyWeathers",
        table = config,
    },

    filters = {

        {
            label = "Погода",
            callback = (
                function()
                    local weatherNames = {}
                    for weather, _ in pairs(tes3.weather) do
                        if weather == "thunder" then
                            table.insert(weatherNames, "Thunderstorm")
                        else
                            table.insert(weatherNames, weather:sub(1, 1):upper() .. weather:sub(2))
                        end
                    end
                    table.sort(weatherNames)
                    return weatherNames
                end
                )
        },

    }
}

local blockedPage = template:createPage { label = "Запрещенные погодные условия", noScroll = true }
blockedPage:createCategory {
    label = "Настройки типов погодных условий, при которых туман никогда не появляется (игнорируя другие настройки).\n",
}

blockedPage:createExclusionsPage {
    label = "Облачная погода",
    description = "Погода блокирующая появление облаков:",
    toggleText = "Переключить",
    leftListLabel = "Облачная погода",
    rightListLabel = "Вся погода",
    showAllBlocked = false,
    variable = mwse.mcm.createTableVariable {
        id = "blockedCloud",
        table = config,
    },

    filters = {

        {
            label = "Погода",
            callback = (
                function()
                    local weatherNames = {}
                    for weather, _ in pairs(tes3.weather) do
                        if weather == "thunder" then
                            table.insert(weatherNames, "Thunderstorm")
                        else
                            table.insert(weatherNames, weather:sub(1, 1):upper() .. weather:sub(2))
                        end
                    end
                    table.sort(weatherNames)
                    return weatherNames
                end
            )
        },

    }
}

blockedPage:createExclusionsPage {
    label = "Туманная погода",
    description = "Погода блокирующая появление тумана:",
    toggleText = "Переключить",
    leftListLabel = "Туманная погода",
    rightListLabel = "Вся погода",
    showAllBlocked = false,
    variable = mwse.mcm.createTableVariable {
        id = "blockedMist",
        table = config,
    },

    filters = {

        {
            label = "Погода",
            callback = (
                function()
                    local weatherNames = {}
                    for weather, _ in pairs(tes3.weather) do
                        if weather == "thunder" then
                            table.insert(weatherNames, "Thunderstorm")
                        else
                            table.insert(weatherNames, weather:sub(1, 1):upper() .. weather:sub(2))
                        end
                    end
                    table.sort(weatherNames)
                    return weatherNames
                end
            )
        },

    }
}

local blacklistPage = template:createPage { label = "Черный список интерьеров", noScroll = true }
blacklistPage:createCategory {
    label = "Настройки черного списка интерьерных ячеек.\n",
}

blacklistPage:createExclusionsPage {
    label = "Интерьер",
    description = "Черный список:",
    toggleText = "Переключить",
    leftListLabel = "Черный список интерьеров",
    rightListLabel = "Все интерьеры",
    showAllBlocked = false,
    variable = mwse.mcm.createTableVariable {
        id = "blockedInteriors",
        table = config,
    },

    filters = {

        {
            label = "Интерьер",
            callback = (
                function()
                    local interiors = {}
                    for cell in tes3.iterate(tes3.dataHandler.nonDynamicData.cells) do
						if not cell.isOrBehavesAsExterior then
                            table.insert(interiors, cell.name)
                        end
                    end

                    table.sort(interiors)
                    return interiors
                end
            )
        },

    }
}


template.onClose = function()
    mwse.saveConfig(configPath, config)
    dofile("Data Files\\MWSE\\mods\\tew\\Vapourmist\\components\\events.lua")
end
mwse.mcm.register(template)
