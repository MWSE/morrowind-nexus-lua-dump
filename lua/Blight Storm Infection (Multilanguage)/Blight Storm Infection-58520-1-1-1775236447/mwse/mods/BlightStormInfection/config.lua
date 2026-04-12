local i18n = mwse.loadTranslations("BlightStormInfection")

local defaultConfig = {
	base = {
		baseChance = 10, -- базовый шанс заражения
		helmetMultiplier = 0.5, -- уменьшение базового шанса заражения от ношения закрытого шлема
		duration = 10, -- интервал в секундах между проверками
		displayInfectionAttempts = false, -- отображать попытки заражения
	},
	weather = {
		showWeatherNotifications = true, -- оповещение о моровых бурях
		blightStormStartNotificationText = i18n("blight_start_notification_text"),
		blightStormEndNotificationText = i18n("blight_end_notification_text")
	}
}

-- Загрузка существующего конфига JSON, или использование стандартного
local configPath = "BlightStormInfection"
local config = mwse.loadConfig(configPath, defaultConfig)

-- Метатаблица - прямой доступ (напр config.i18n), но MWSE не будет засорять этим свой JSON-файл
local metadata = {
	-- Ссылка на данные текущей локализации
    i18n = i18n,
	-- Ссылка на стандартные настройки (из этого файла) в объекте конфига, чтобы к ним был доступ в MCM
    defaultConfig = defaultConfig
}
setmetatable(config, { __index = metadata })

return config