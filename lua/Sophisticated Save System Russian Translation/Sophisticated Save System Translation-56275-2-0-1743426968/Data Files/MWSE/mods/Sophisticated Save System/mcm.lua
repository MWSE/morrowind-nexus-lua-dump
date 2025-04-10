local this = {}

local config = require("Sophisticated Save System.config")
local interop = require("Sophisticated Save System.interop")

local template = mwse.mcm.createTemplate("Улучшенная система сохранений")
template:saveOnClose("Sophisticated Save System", config)

--local page = template:createPage()
local page = template:createSideBarPage{
        label = "Настройки",
        description = "Улучшенная система сохранений\n\n"
    }

page:createYesNoButton({
    label = "Использовать любое последнее сохранение для быстрой загрузки?",
    description = "Обычно функция \"Быстрая загрузка\" загружает только последнее сохранение, сделанное через \"Быстрое сохранение\". Данная опция позволяет загружать вместо этого любое последнее сохранение.",
    variable = mwse.mcm.createTableVariable({
        id = "loadLatestSave",
        table = config,
    }),
})

page:createTextField({
    label = "Максимальное количество автосохранений:",
    description = "Максимальное количество автосохранений. Старые автосохранения будут замещаться новыми.",
    variable = mwse.mcm.createTableVariable({
        id = "maxSaveCount",
        table = config,
        numbersOnly = true,
    }),
})

page:createTextField({
    label = "Минимальное время между автосохранениями:",
    description = "После выполнения условия для создания автосохранения оно не будет создано до истечения указанного времени (в минутах) с момента последнего автосохранения.",
    variable = mwse.mcm.createTableVariable({
        id = "minimumTimeBetweenAutoSaves",
        table = config,
        numbersOnly = true,
    }),
})

page:createYesNoButton({
    label = "Включить периодическое автосохранение?",
    description = "Автосохранение создается при выполнении определенных условий.\n\nПри включении данной опции автосохранения будут создаваться через указанный промежуток времени.",
    variable = mwse.mcm.createTableVariable({
        id = "saveOnTimer",
        table = config,
    }),
})

page:createTextField({
    label = "Время между автосохранениями:",
    description = "Промежуток времени, через который создается периодическое автосохранение.",
    variable = mwse.mcm.createTableVariable({
        id = "timeBetweenAutoSaves",
        table = config,
        numbersOnly = true,
    }),
})

page:createYesNoButton({
    label = "Создавать автосохранения при начале боя?",
    description = "Автосохранение создается при выполнении определенных условий.\n\nПри включении данной опции автосохранение будет создаваться при начале боя.",
    variable = mwse.mcm.createTableVariable({
        id = "saveOnCombatStart",
        table = config,
    }),
})

page:createYesNoButton({
    label = "Создавать автосохранения по окончании боя?",
    description = "Автосохранение создается при выполнении определенных условий.\n\nПри включении данной опции автосохранение будет создаваться после завершения боя.",
    variable = mwse.mcm.createTableVariable({
        id = "saveOnCombatEnd",
        table = config,
    }),
})

page:createYesNoButton({
    label = "Создавать автосохранения при смене локаций?",
    description = "Автосохранение создается при выполнении определенных условий.\n\nПри включении данной опции автосохранение будет создаваться при смене локаций.",
    variable = mwse.mcm.createTableVariable({
        id = "saveOnCellChange",
        table = config,
    }),
})

mwse.mcm.register(template)
