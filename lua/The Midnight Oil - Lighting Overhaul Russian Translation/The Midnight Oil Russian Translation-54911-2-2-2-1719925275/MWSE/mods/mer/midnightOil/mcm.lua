local common = require("mer.midnightOil.common")
local conf = require("mer.midnightOil.config")
local modName = "Полуночное масло"
local config = conf.getConfig()

local function createSettingsPage(template)
    local config = conf.getConfig()

    local page = template:createSideBarPage{
        label = "Настройки",
        description = (
            "Этот мод изменяет освещение, добавляя следующие функции:\n\n" ..
            "- Огни больше не будут уничтожаться, когда у них заканчивается топливо или когда они погружаются под воду.\n\n" ..
            "- Заправляйте фонари, покупая у торговцев свечи и масло.\n\n" ..
            "- Удерживайте горячую клавишу (по умолчанию shift) при активации фонаря, чтобы включить или выключить его. Это работает как для носимых, так и для статичных фонарей.\n\n"..
            "- Фонари и факелы в городах будут автоматически выключаться днем и включаться ночью."
        )
    }

    do --generalCategory
        local generalCategory = page:createCategory("Общие настройки")

        generalCategory:createYesNoButton{
            label = "Включить мод",
            description = "Включите или выключите этот мод.",
            variable = mwse.mcm.createTableVariable{ id = "enabled", table = config }
        }

        generalCategory:createKeyBinder{
            label = "Горячая клавиша для переключения света",
            description = "Удерживайте эту клавишу нажатой, когда активируете переносной фонарь, чтобы включить или выключить его.",
            allowCombinations = true,
            variable = mwse.mcm.createTableVariable{ id = "toggleHotkey", table = config }
        }

        generalCategory:createDropdown{
            label = "Log Level",
            description = "Выберите уровень ведения журнала событий mwse.log. Оставьте INFO, если не проводите отладку",
            options = {
                { label = "TRACE", value = "TRACE"},
                { label = "DEBUG", value = "DEBUG"},
                { label = "INFO", value = "INFO"},
                { label = "ERROR", value = "ERROR"},
                { label = "NONE", value = "NONE"},
            },
            variable = mwse.mcm.createTableVariable{ id = "logLevel", table = config },
            callback = function(self)
                for _, log in pairs(common.loggers) do
                    log:setLogLevel(self.variable.value)
                end
            end
        }
    end

    do --dungeonLightsCategory
        local dungeonLightsCategory = page:createCategory("Огни подземелья")
        dungeonLightsCategory:createYesNoButton{
            label = "Выключить свет в подземелье по умолчанию",
            description = "Если эта функция включена, то в подземельях, где нет NPC, при первом входе в них будет выключен весь свет.",
            variable = mwse.mcm.createTableVariable{ id = "dungeonLightsOff", table = config }
        }
    end

    do --nightDayCategory
        local nightDayCategory = page:createCategory("Переключатель городского освещения день/ночь")

        nightDayCategory:createYesNoButton{
            label = "Переключать освещение только в населенных пунктах",
            description = "Если эта функция включена, свет будет выключаться днем только в том случае, если вы находитесь в ячейке, где отдых запрещен.",
            variable = mwse.mcm.createTableVariable{ id = "settlementsOnly", table = config }
        }
        nightDayCategory:createYesNoButton{
            label = "Переключать только статическое освещение",
            description = "Если эта функция включена, светильники будут выключаться днем только в том случае, если они статичны (их нельзя поднять). Если отключить эту функцию, переносные светильники, размещенные на улице, будут включаться и выключаться в зависимости от времени суток. Переключение света вручную отложит это до следующего дня.",
            variable = mwse.mcm.createTableVariable{ id = "staticLightsOnly", table = config }
        }

        nightDayCategory:createSlider{
            label = "Час рассвета",
            description = "В этот час в городе начнут гаснуть фонари.",
            min = 0,
            max = 12,
            step = 1,
            jump = 1,
            variable = mwse.mcm.createTableVariable{ id = "dawnHour", table = config }
        }

        nightDayCategory:createSlider{
            label = "Сумеречный час",
            description = "В этот час в городе начнут загораться фонари.",
            min = 12,
            max = 24,
            step = 1,
            jump = 1,
            variable = mwse.mcm.createTableVariable{ id = "duskHour", table = config }
        }

        nightDayCategory:createYesNoButton{
            label = "Постепенное включение",
            description = "Если включен этот параметр, фонари будут включаться/выключаться не все сразу, а в течение определенного времени.",
            variable = mwse.mcm.createTableVariable{ id = "useVariance", table = config }
        }

        nightDayCategory:createSlider{
            label = "Разница в минутах",
            description = "Интервал, через который фонари начнут включаться/выключаться.",
            min = 1,
            max = 60,
            step = 1,
            jump = 10,
            variable = mwse.mcm.createTableVariable{ id = "varianceInMinutes", table = config }
        }
    end
end

---@type string[]
local cells
local function createExclusionsPage(template)
    template:createExclusionsPage{
        label = "Черный список",
        description = "Добавьте ячейки в черный список, чтобы в них не отключался свет. Это полезно для ячеек с освещением, которое никогда не следует выключать, например, для поясов Молаг Мар.",
        leftListLabel = "Черный список ячеек",
        rightListLabel = "Белые список ячеек",
        variable = mwse.mcm.createTableVariable{ id = "cellBlacklist", table = config },
        filters = {
            {
                label = "Ячейки",
                callback = function()
                    if cells then return cells end
                    cells = {}
                    for _, cell in ipairs(tes3.dataHandler.nonDynamicData.cells) do
                        table.insert(cells, cell.editorName)
                    end
                    table.sort(cells)
                    return cells
                end
            }
        }
    }
end

local function registerMCM()
    local template = mwse.mcm.createTemplate(modName)
    template:saveOnClose(conf.configPath, config)
    template:register()
    createSettingsPage(template)
    createExclusionsPage(template)
end
event.register("modConfigReady", registerMCM)