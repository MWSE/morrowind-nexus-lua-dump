local config = require("animationBlending.config")
config.version = 2.1

local template = mwse.mcm.createTemplate({ name = "Сглаженная анимация" })
template:saveOnClose("animationBlending", config)
template:register()

local page = template:createSideBarPage({})

page.sidebar:createInfo({
    text = (
        "Сглаженная анимация в%.1f\n"
        .. "Разработчики - Greatness7 и Hrnchamd\n\n"
        .. "Мод обеспечивает плавные переходы между разными анимациями.\n\n"
    ):format(config.version),
})

-- Features

local features = page:createCategory({ label = "Настройки" })

features:createOnOffButton({
    label = "Включить перемещение по диагонали (В виде от третьего лица)?",
    description = (
        "Включить перемещение по диагонали для игрока в виде от третьего лица.\n\n"
        .. "По умолчанию: Вкл"
    ),
    variable = mwse.mcm.createTableVariable({
        id = "diagonalMovement",
        table = config,
    }),
})

features:createOnOffButton({
    label = "Включить перемещение по диагонали (В виде от первого лица)?",
    description = (
        "Включить перемещение по диагонали для игрока в виде от первого лица.\n\n"
        .. "По умолчанию: Вкл"
    ),
    variable = mwse.mcm.createTableVariable({
        id = "diagonalMovement1stPerson",
        table = config,
    }),
})

-- Performance Settings

local settings = page:createCategory({ label = "Настройки производительности" })

settings:createOnOffButton({
    label = "Включить только для игрока?",
    description = (
        "Добавляет плавные переходы между анимациями только для игрока.\n\n"
        .. "Может улучшить производительность в зонах с большим количеством NPC.\n\n"
        .. "По умолчанию: Выкл"
    ),
    variable = mwse.mcm.createTableVariable({
        id = "playerOnly",
        table = config,
    }),
})

settings:createSlider({
    label = "Максимальная дистанция: %s",
    description = (
        "Максимальное расстояние от камеры, на котором быдет срабатывать плавный переход между анимациями.\n\n"
        .. "Более низкое значение может улучшить производительность.\n\n"
        .. "По умолчанию: 4096"
    ),
    min = 0,
    max = 8192,
    step = 512,
    jump = 2048,
    variable = mwse.mcm.createTableVariable({
        id = "maxDistance",
        table = config,
    }),
})

-- Developer Settings

local developer = page:createCategory({ label = "Настройки разработчика" })

developer:createOnOffButton({
    label = "Включить мод?",
    description = "Включить или выключить все аспекты мода.\n\nПо умолчанию: Вкл",
    variable = mwse.mcm.createTableVariable({
        id = "enabled",
        table = config,
    }),
})

developer:createDropdown({
    label = "Уровень записи логов",
    description = "Установить уровень записи логов. Предназначено только для отладки..\n\nПо умолчанию: INFO",
    options = {
        { label = "TRACE", value = "TRACE" },
        { label = "DEBUG", value = "DEBUG" },
        { label = "INFO",  value = "INFO" },
        { label = "WARN",  value = "WARN" },
        { label = "ERROR", value = "ERROR" },
        { label = "NONE",  value = "NONE" },
    },
    variable = mwse.mcm.createTableVariable({
        id = "logLevel",
        table = config,
    }),
    callback = function(self)
        local log = require("animationBlending.log")
        log:setLogLevel(self.variable.value)
    end,
})
