---@diagnostic disable: undefined-global

local config = require("weapons_sheath_when_equip_change.config")

local function registerModConfig()
    local currentConfig = config.get()

    local template = mwse.mcm.createTemplate({
        name = "Анимированная смена оружия",
        config = currentConfig,
        defaultConfig = config.getDefaults(),
    })

    template:saveOnClose("weapons_sheath_when_equip_change\\config", currentConfig)

    local page = template:createSideBarPage({ label = "Основные" })

    page.sidebar:createInfo({
        text = table.concat({
            "Мод принудительно вызывает визуальную анимацию при смене экипированного оружия.",
            "Обычная смена блокируется, а вместо нее воспроизводится анимация \"убрать в ножны предыдущее оружие\" + \"достать новое оружие\".",
            "Мод больше не добавляет дополнительную задержку после убирания в ножны или альтернативный сценарий.",
        }, "\n\n"),
    })

    local featureCategory = page:createCategory({ label = "Настройки" })

    featureCategory:createOnOffButton({
        label = "Включить мод",
        description = "Включает или выключает анимацию смены оружия.",
        variable = mwse.mcm.createTableVariable({
            id = "enabled",
            table = currentConfig.featureFlags,
        }),
    })

    featureCategory:createOnOffButton({
        label = "Детальное логирование",
        description = "Сохраняет подробную диагностику мода в файл MWSE.log",
        variable = mwse.mcm.createTableVariable({
            id = "debugLogging",
            table = currentConfig.featureFlags,
        }),
    })

    template:register()
end

event.register("modConfigReady", registerModConfig)