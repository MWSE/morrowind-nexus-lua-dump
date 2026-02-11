local common = require('mer.chargenScenarios.common')
local config = require('mer.chargenScenarios.config')
local modName = "Сценарии - конструктор"
local mcmConfig = common.config.mcm
--MCM MENU
local this = {}

local function createSettingsPage(template)
    local settings = template:createSideBarPage("Настройки")
    template:saveOnClose("Chargen Scenarios", mcmConfig)
    settings.description = config.modDescription

    --Locations
    local registerLocationsCategory = settings:createCategory("Утилита регистрации расположения")
    registerLocationsCategory:createOnOffButton{
        label = string.format("Включить"),
        description = "Включить или выключить утилиту регистрации расположения. Когда она включена, вы можете нажать горячую клавишу, чтобы зарегистрировать свое текущее расположение в качестве начальной позиции для сценария. Вам будет предложено присвоить расположению уникальное имя, и оно будет сохранено в файле Morrowind/Data Files/MWSE/config/Chargen Scenario Utilities.json.",
        variable = mwse.mcm.createTableVariable{id = "registerLocationsEnabled", table = mcmConfig}
    }
    registerLocationsCategory:createKeyBinder{
        label = "Горячая клавиша",
        description = "Нажмите эту клавишу, чтобы зарегистрировать текущее расположение в качестве начальной позиции сценария.",
        variable = mwse.mcm.createTableVariable{ id = "registerLocationsHotKey", table = mcmConfig},
        allowCombinations = true,
    }

    --Clutter
    local registerClutterCategory = settings:createCategory("Утилита регистрации обстановки")
    registerClutterCategory:createOnOffButton{
        label = string.format("Включить"),
        description = "Включить или выключить утилиту регистрации помех. Когда она включена, вы можете нажать горячую клавишу, чтобы зарегистрировать свое текущее местоположение в качестве начальной позиции для сценария. Вам будет предложено присвоить местоположению уникальное имя, и оно будет сохранено в файле Morrowind/Data Files/MWSE/config/Chargen Scenario Utilities.json.",
        variable = mwse.mcm.createTableVariable{id = "registerClutterEnabled", table = mcmConfig}
    }
    registerClutterCategory:createKeyBinder{
        label = "Горячая клавиша",
        description = "Нажмите эту кнопку, чтобы зарегистрировать текущее местоположение в качестве начальной позиции сценария.",
        variable = mwse.mcm.createTableVariable{ id = "registerClutterHotKey", table = mcmConfig},
        allowCombinations = true,
    }
end

local function createDevOptionsPage(template)
    local devOptions = template:createSideBarPage("Настройки разработчика")
    devOptions.description = "Инструменты для отладки и т.д."

    --Testing
    devOptions:createOnOffButton{
        label = "Включить тесты модулей",
        description = "Включить или выключить тесты модулей.",
        variable = mwse.mcm.createTableVariable{id = "doTests", table = mcmConfig}
    }
end

this.registerModConfig = function()
    local template = mwse.mcm.createTemplate{ name = modName }
    template:saveOnClose(modName, mcmConfig)
    template:register()
    createSettingsPage(template)
    createDevOptionsPage(template)
end

return this