local config = require("DynamicDisposition.config")
local template = mwse.mcm.createTemplate("Динамические отношения")

template:saveOnClose("DynamicDispositionConfig", config)
template:register()

local page = template:createSideBarPage{
    label = "Настройки",
    description = "Расположение персонажей по отношению к вам динамически корректируется в зависимости от вашей расы, характеристик и отношений с фракциями.",
}

page:createOnOffButton{
    label = "Включить отладку",
    description = "Выводить отладочную информацию в журнал MWSE и консоль.",
    variable = mwse.mcm.createTableVariable{
        id = "enableDebug",
        table = config,
    },
}

page:createSlider{
    label = "Максимальный штраф за характеристики",
    description =
        "Насколько сильно низкий уровень красноречия и привлекательности влияет на отношение к вам персонажей.",
    min = 1,
    max = 50,
    step = 1,
    jump = 2,
    variable = mwse.mcm.createTableVariable{
        id = "maxPenalty",
        table = config,
    },
}

page:createDecimalSlider{
    label = "Влияние красноречия",
    description =
        "Множитель для навыка Красноречие. Более высокое значение увеличивает эффективность вашего навыка Красноречие. "
        .. "Множитель",
    min = 0.0,
    max = 2.0,
    decimalPlaces = 1,
    variable = mwse.mcm.createTableVariable{
        id = "speechcraftScale",
        table = config,
    },
}

page:createDecimalSlider{
    label = "Влияние привлекательности",
    description =
        "Множитель для атрибута Привлекательность. Более высокое значение увеличивает эффективность вашего атрибута Привлекательность. "
        .. "Множитель",
    min = 0.0,
    max = 2.0,
    decimalPlaces = 1,
    variable = mwse.mcm.createTableVariable{
        id = "personalityScale",
        table = config,
    },
}

page:createDecimalSlider{
    label = "Влияние расы",
    description =
        "Множитель для расы. Более высокое значение увеличивает концентрацию расовых предрассудков в мире. "
        .. "Множитель",
    min = 0.0,
    max = 2.0,
    decimalPlaces = 1,
    variable = mwse.mcm.createTableVariable{
        id = "raceScale",
        table = config,
    },
}

page:createDecimalSlider{
    label = "Влияние членства во фракциях",
    description =
        "Множитель для членства во фракциях. Более высокое значение увеличивает влияние членства игрока во фракциях. "
        .. "Фракционные союзы и споры учитываются при расчете множителя.",
    min = 0.0,
    max = 2.0,
    decimalPlaces = 1,
    variable = mwse.mcm.createTableVariable{
        id = "factionScale",
        table = config,
    },
}

page:createDecimalSlider{
    label = "Влияние репутации",
    description = "Определяет насколько сильно ваша репутация влияет на отношение к вам персонажей.",
    min = 0.0,
    max = 1.0,
    decimalPlaces = 1,
    variable = mwse.mcm.createTableVariable{
        id = "fameScale",
        table = config,
    },
}
