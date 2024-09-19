local config = require("poisonCrafting.config")
config.version = 2.1

local template = mwse.mcm.createTemplate{name="Изготовление ядов"}
template:saveOnClose("poisonCrafting", config)
template:register()

local page = template:createSideBarPage{}
page.sidebar:createInfo{text=("Изготовление ядов v%.1f\n\nОт Greatness7"):format(config.version)}

page:createOnOffButton{
    label = "Добавить иконки эффектов",
    description = "Эта функция добавляет иконки магических эффектов на предметы в инвентаре.",
    variable = mwse.mcm:createTableVariable{
        id = "useEffectIcons",
        table = config,
    },
}

page:createOnOffButton{
    label = "Исправление Алхимии",
    description = "Эта функция заставляет системы алхимии использовать базовые характеристики и навыки игрока, а не их иуменьшенные или усиленные значения.",
    variable = mwse.mcm:createTableVariable{
        id = "useBaseStats",
        table = config,
    },
}

page:createOnOffButton{
    label = "Бонусный прогресс алхимии",
    description = "Эта функция добавляет дополнительный прогресс в навыке алхимии в зависимости от количества магических эффектов в созданном зелье.\n\nЗа каждый эффект сверх первого ваш прогресс будет увеличиваться еще на 10 процентов.",
    variable = mwse.mcm:createTableVariable{
        id = "useBonusProgress",
        table = config,
    },
}

page:createOnOffButton{
    label = "Подсказка применить яд",
    description = "Эта функция вызывает появление подсказки в меню при нанесении ядов на оружие, что помогает избежать возможных ошибок.",
    variable = mwse.mcm:createTableVariable{
        id = "useApplyMessage",
        table = config,
    },
}
