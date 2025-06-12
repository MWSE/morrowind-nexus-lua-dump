local common = require('mer.chargenScenarios.common')
local logger = common.createLogger("mcm")
local ChargenMenu = require("mer.chargenScenarios.component.ChargenMenu")
local config = common.config
local modName = config.modName

local function registerModConfig()
    local template = mwse.mcm.createTemplate{ name = modName }
    template:saveOnClose(config.metadata.package.name, config.mcm)
    template:register()

    local settings = template:createSideBarPage("Настройки")
    settings.description = config.modDescription


    settings:createYesNoButton{
        label = string.format("Включить %s", modName),
        description = "Выключите, чтобы вернуться к стандартной процедуре создания персонажей.",
        variable = mwse.mcm.createTableVariable{
            id = 'enabled',
            table = config.mcm
        },
        restartRequired = true,
        restartRequiredMessage = "Для корректной работы необходимо перезапустить игру."
    }

    settings:createSlider{
        label = "Количество наборов предметов",
        description = "Максимальное количество наборов предметов, которые можно выбрать. По умолчанию: 3.",
        min = 1,
        max = 20,
        variable = mwse.mcm.createTableVariable{
            id = 'itemPackageLimit',
            table = config.mcm
        },
    }

    settings:createDropdown{
        label = "Уровень журнала",
        description = "Установите уровень ведения журнала событий mwse.log.",
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

    --A page for enabling/disabling each registered menu
    local menuSettings = template:createSideBarPage("Настройки меню")
    menuSettings.description = "Включите или выключите необходимые меню. Если отключить меню, оно не будет отображаться в процессе настройки, но его по-прежнему можно будет вызвать в итоговом окне."

    for _, menu in ipairs(ChargenMenu.orderedMenus) do
        menuSettings:createYesNoButton{
            label = menu.name,
            description = string.format("Включить меню %s.", menu.buttonLabel),
            variable = mwse.mcm.createTableVariable{
                id = menu:getMcmId(),
                table = config.mcm,
            }
        }
    end

end
event.register("initialized", registerModConfig, { priority = -500})