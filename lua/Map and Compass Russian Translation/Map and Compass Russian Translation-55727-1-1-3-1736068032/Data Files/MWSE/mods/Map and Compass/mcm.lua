local config = require("Map and Compass.config")

local template = mwse.mcm.createTemplate("Карта и компас")
template.headerImagePath = "MWSE/mods/Map and Compass/Map and Compass Logo.tga"
template:saveOnClose("Map and Compass", config)

template.onClose = function()
                        mwse.saveConfig("Map and Compass", config)
                        event.trigger("jaceyS_MaC_MCM_Closed")
                    end

local generalPage = template:createSidebarPage({
    label = "Общие настройки",
    description = "Общие настройки карты и компаса",
})

local installedMapPacks = generalPage:createCategory({
    label = "Установленные пакеты карт",
    descrption = "Пакеты карт, обнаруженные модом Карта и Компас. Инструкции по добавлению дополнительных пакетов карт см. в readme.."
})
for _, mapPack in pairs(config.mapPacks) do
    installedMapPacks:createCategory({label = mapPack})
end
local reloadMessage = "Please load a game from save (or start a new one), in order for this setting to change."
generalPage:createYesNoButton({
    label = "Карта мира",
    description = "Включить или отключить доступность карты мира из базовой игры.",
    variable = mwse.mcm.createTableVariable({id = "worldMap", table = config})
})
generalPage:createYesNoButton({
    label = "Карта местности",
    description = "Включить или отключить доступность локальной карты из базовой игры.",
    variable = mwse.mcm.createTableVariable({id = "localMap", table = config})
})
generalPage:createYesNoButton({
    label = "Скрыть заголовок карты",
    description = "Скрывает блок заголовка в верхней части меню карты.",
    variable = mwse.mcm.createTableVariable({id = "hideMapTitle", table = config})
})
generalPage:createYesNoButton({
    label = "Скрыть уведомления о местности",
    description = "Скрывает всплывающие уведомления с названием местности, отображаемые над мини-картой при смене ячеек.",
    variable = mwse.mcm.createTableVariable({id = "hideMapNotification", table = config})
})
generalPage:createYesNoButton({
    label = "Выпадающий список",
    description = "Заменяет кнопку \"Переключить\" на карте на выпадающий список для выбора.",
    variable = mwse.mcm.createTableVariable({id = "selectionDropdown", table = config}),
})
generalPage:createYesNoButton({
    label = "Скрыть переключатель",
    description = "Включение выпадающего списка автоматически скрывает кнопку \"Переключить\", но если вы не хотите использовать его, но и не хотите видеть кнопку \"Переключить\", активируйте этот параметр.",
    variable = mwse.mcm.createTableVariable({id = "hideSwitch", table = config}),
})
generalPage:createSlider({
    label = "Максимальное увеличение изображения",
    description = "Насколько сильно вы можете увеличить карту при помощи масштабирования.",
    step = 1,
    min = 1,
    max = 10,
    jump = 1,
    variable = mwse.mcm.createTableVariable({id = "maxScale", table = config})
})
generalPage:createKeyBinder({
    label = "Заметка на карте",
    description = "Клавиша, которую нужно удерживать при нажатии на пользовательскую карту, чтобы сделать заметку.",
    allowCombinations = false,
    variable = mwse.mcm.createTableVariable({id = "noteKey", table = config})
})

local compassOptions = {{label = "Мини-карта", value = false}}
for _, value in pairs(config.compasses) do
    table.insert(compassOptions, {label = value, value = value})
end
local compass = generalPage:createDropdown({
    label = "Компас",
    description = "Выберите, использовать мини-карту по умолчанию или заменить ее одним из установленных компасов.",
    options = compassOptions,
    variable = mwse.mcm.createTableVariable({id = "compass", table = config}),
})


for _, mapPack in pairs(config.mapPacks) do
    local packPage = template:createSidebarPage({
        label = mapPack,
        description = "Настройка карт из пакета ".. mapPack
    })
    local maps = require("Map and Compass."..mapPack..".maps")
    if (not maps) then
        local string = "Карта и компас, ошибка: мод ожидал найти список карт, присутствующих в пакете " .. mapPack .. ", но этого не произошло. Пожалуйста, убедитесь, что вы правильно установили свои пакеты карт."
        packPage:createCategory({label = string})
    else
        for map, value in pairs(maps) do
            local category = packPage:createCategory({label = map})
            local displayName = category:createCategory({label = "Отображаемое название по умолчанию:\n".. value.name})
            displayName:createTextField({
                description = "Используйте это поле, чтобы изменить отображаемое название, используемое для этой карты. Необходимо, если вы хотите использовать две карты с одинаковыми названиями по умолчанию.",
                variable = mwse.mcm.createTableVariable({id = "name", table = config[mapPack][map]})
            })
            displayName:createButton({buttonText = "Сброс", callback = function() config[mapPack][map].name = nil end})
            category:createYesNoButton({
                label = "Включить",
                description = "Добавляет эту карту в список доступных карт.",
                variable = mwse.mcm.createTableVariable({id = "enabled", table = config[mapPack][map]}),
            })
            category:createButton({inGameOnly = true, label = "Сделать эту карту текущей выбранной картой.", buttonText = "Выбрать", callback =
                function()
                    if(not tes3.player.data.JaceyS) then
                        tes3.player.data.JaceyS = {}
                    end
                    if(not tes3.player.data.JaceyS.MaC) then
                        tes3.player.data.JaceyS.MaC = {}
                    end
                    if (config[mapPack][map].enabled ~= true) then
                        tes3.messageBox "Вы должны включить карту, прежде чем устанавливать ее в качестве текущей карты."
                        return
                    end
                    tes3.player.data.JaceyS.MaC.currentMap = mapPack .."-".. map
                end
            })
            category:createButton({inGameOnly = true, label = "Удалить все заметки на этой карте.", buttonText = "Удалить", callback =
                function()
                    if(tes3.player and tes3.player.data.JaceyS and tes3.player.data.JaceyS.MaC and
                    tes3.player.data.JaceyS.MaC[mapPack] and tes3.player.data.JaceyS.MaC[mapPack][map] and
                    tes3.player.data.JaceyS.MaC[mapPack][map].notes) then
                        tes3.player.data.JaceyS.MaC[mapPack][map].notes = nil
                    end
                end
            })
        end
    end
end
mwse.mcm.register(template)