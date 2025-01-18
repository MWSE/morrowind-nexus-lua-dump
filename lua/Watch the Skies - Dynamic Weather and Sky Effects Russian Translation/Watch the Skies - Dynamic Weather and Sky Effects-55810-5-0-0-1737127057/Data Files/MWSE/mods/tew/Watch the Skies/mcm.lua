local metadata = toml.loadMetadata("Watch the Skies")
local configPath = metadata.package.name
local config = require("tew.Watch the Skies.config")


local template = mwse.mcm.createTemplate {
    name = "Взгляд в Небо",
    headerImagePath = "\\Textures\\tew\\Watch the Skies\\WtS_logo.tga",
}

local page = template:createPage { label = "Настройки" }
page:createCategory {
    label = "\"Взгляд в Небо - динамичные погодные эффекты\" версия " .. metadata.package.version .. " от tewlwolow.\nMWSE мод для динамичного изменения неба и погоды в Морровинде.\n\nНастройки:",
}

local function createYesNoButton(label, id, restartRequired)
    restartRequired = restartRequired or true

    page:createYesNoButton {
        label = label,
        variable = mwse.mcm.createTableVariable {
            id = id,
            table = config,
        },
        restartRequired = restartRequired,
    }
end

createYesNoButton("Включить режим отладки?", "debugLogOn")
createYesNoButton("Включить случайный выбор текстуры облаков?", "skyTexture")
createYesNoButton(
"Использовать оригинальные текстуры неба? Обратите внимание, что они должны находиться в папке Data Files/Textures, текстуры из BSA архивов работать не будут.",
    "useVanillaSkyTextures")
createYesNoButton("Включить случайные интервалы между сменой погоды?", "dynamicWeatherChanges")
createYesNoButton("Включить изменение погодных условий в интерьерах?", "interiorTransitions")
createYesNoButton("Включить сезонные погодные условия?", "seasonalWeather")
createYesNoButton("Включить сезонную продолжительность дня?", "seasonalDaytime")
createYesNoButton("Включить случайный выбор максимального количества частиц?", "particleAmount")
createYesNoButton("Включить случайный выбор скорости движения облаков?", "cloudSpeed")
createYesNoButton("Включить случайный выбор моделей частиц дождя и снега?", "particleMesh")

page:createDropdown {
    label = "Режим скорости движения облаков:",
    options = {
        { label = "Морровинд",   value = 100 },
        { label = "Skies .iv", value = 500 },
    },
    variable = mwse.mcm.createTableVariable {
        id = "cloudSpeedMode",
        table = config,
    },
    restartRequired = true,
}

template:saveOnClose(configPath, config)
mwse.mcm.register(template)
