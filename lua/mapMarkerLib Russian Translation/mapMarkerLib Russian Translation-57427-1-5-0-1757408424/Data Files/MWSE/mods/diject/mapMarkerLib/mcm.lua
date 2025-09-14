local markerLib = include("diject.mapMarkerLib.marker")
local logLib = include("diject.mapMarkerLib.utils.log")

local configFileName = "mapMarkerLib_settings"

local this = {}

local default = {
    enabled = markerLib.enabled,
    logging = logLib.enabled,
    minDelayBetweenUpdates = math.round(markerLib.minDelayBetweenUpdates * 1000),
    updateInterval = math.round(markerLib.updateInterval * 1000),
}

this.config = mwse.loadConfig(configFileName, default)

local mcm = mwse.mcm

local function onSearch(searchText)
    local text = searchText:lower()
    if text:find("map") or text:find("marker") or text:find("lib") then
        return true
    end
    return false
end

local function onClose()
    mwse.saveConfig(configFileName, this.config)
end

local function callback(self)
    markerLib.enabled = this.config.enabled
    logLib.enabled = this.config.logging
    markerLib.minDelayBetweenUpdates = this.config.minDelayBetweenUpdates / 1000
    markerLib.updateInterval = this.config.updateInterval / 1000
end

callback()

function this.registerModConfig()
    local template = mcm.createTemplate{name = "mapMarkerLib", config = this.config, onSearch = onSearch, onClose = onClose}

    local page = template:createPage{label = "Основные"}

    page:createOnOffButton{configKey = "enabled", restartRequired = true, label = "Включить маркеры карты."}
    page:createOnOffButton{configKey = "logging", label = "Включить журнал ошибок."}

    page:createSlider{min = 10, max = 1000, configKey = "updateInterval",
        label = "%s - Минимальный интервал обновления меню карты (в миллисекундах). Обычно меню карты обновляется автоматически, но иногда, например когда вы стоите на месте, это не происходит - эта опция для таких случаев.",
        callback = callback,
    }
    page:createSlider{min = 0, max = 100, configKey = "minDelayBetweenUpdates", callback = callback,
        label = "%s - Интервал между обновлениями мини-карты. Мини-карта обновляется каждый кадр. Если после последнего обновления прошло меньше миллисекунд чем указано в этой опции, мини-карта не будет обновлена. Это опция для снижения ненужной нагрузки.",
    }
    page:createButton{inGameOnly = true, buttonText = "Очистить все данные", label = "Удаляет все данные из хранилища мода. Требует сохранения и загрузки.",
        callback = function (self)
            markerLib.flush()
        end,
    }

    template:register()
end

return this