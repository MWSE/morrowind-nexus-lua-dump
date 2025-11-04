local config = require("TamrielRebuilt.config")

----------------------
-- MCM Template --
----------------------

local function registerModConfig()

    local template = mwse.mcm.createTemplate{name="Tamriel Rebuilt"}
    template:saveOnClose("TamrielRebuilt", config)

    -- Preferences Page
    local preferences = template:createSideBarPage{label="Настройки"}

    -- Feature Toggles
    local toggles = preferences:createCategory{label = "Настройки"}
    toggles:createOnOffButton{
        label = "Предупреждение о несовместимости с Фортом Огненной Бабочки",
        description = "Эта опция отображает предупреждение при запуске игры с Tamriel Rebuilt и несовместимым модом \"Осада Форта Огненной Бабочки\" (Siege at Firemoth) без патча, распознаваемого этим MWSE модом.",
        variable = mwse.mcm.createTableVariable{
            id = "firemothWarning",
            table = config,
        },
    }

    template:register()
end

event.register(tes3.event.modConfigReady, registerModConfig)