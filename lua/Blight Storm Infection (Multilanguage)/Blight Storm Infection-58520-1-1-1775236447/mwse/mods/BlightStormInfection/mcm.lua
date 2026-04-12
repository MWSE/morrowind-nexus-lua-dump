local config = require("BlightStormInfection.config")
local i18n = config.i18n
-- Включаем модуль оповещения о погоде, если он есть
local isWeatherModuleAvailable, weatherModule = pcall(require, "BlightStormInfection.weather")

local function registerModConfig()
    local template = mwse.mcm.createTemplate("Blight Storm Infection")

	-- При закрытии сохраняем файл JSON и кидаем сигнал чтобы timer.lua обновил таймер
    template.onClose = function()
		mwse.saveConfig("BlightStormInfection", config)
        event.trigger("BlightStormInfection:UpdateTimer")
    end

    -- 1. Базовые настройки
    local basePage = template:createSideBarPage({ label = i18n("base_page_label") })
    local baseCategory = basePage:createCategory(i18n("base_category_label"))

    -- 1.1 Базовый шанс
    baseCategory:createSlider({
        label = i18n("base_chance_label"),
		description = i18n("base_chance_description"),
        min = 0,
        max = 100,
        step = 1,
        jump = 5,
        variable = mwse.mcm.createTableVariable{ id = "baseChance", table = config.base }
    })

    -- 1.2 Множитель шлема
    baseCategory:createSlider({
        label = i18n("closed_helmet_multiplier_label"),
        description = i18n("closed_helmet_multiplier_description"),
		min = 0,
        max = 1,
        step = 0.01,
        jump = 0.05, -- Кнопки будут менять значение на 0.05 при зажатом Shift или по клику
        decimalPlaces = 2,
        variable = mwse.mcm.createTableVariable{ id = "helmetMultiplier", table = config.base }
    })

	-- 1.3 Интервал проверки
    baseCategory:createSlider({
        label = i18n("check_interval_label"),
        description = i18n("check_interval_description"),
        min = 1,
        max = 120,
        step = 1,
        jump = 5,
        variable = mwse.mcm.createTableVariable{ id = "duration", table = config.base }
    })

	-- 1.4 Включение/выключение попыток заражения
    baseCategory:createOnOffButton({
        label = i18n("display_infection_attempts_label"),
        description = i18n("display_infection_attempts_description"),
        variable = mwse.mcm.createTableVariable{ id = "displayInfectionAttempts", table = config.base }
    })

	-- 1.5. Кнопка сброса настроек
	baseCategory:createButton({
        label = i18n("reset_base_button_label"),
        buttonText = i18n("reset_base_button_text"),
		description = i18n("reset_button_description"),
        callback = function()
            for key, value in pairs(config.defaultConfig.base) do
                config.base[key] = value
            end
            tes3.messageBox(i18n("reset_base_button_messageBox"))
        end
    })

    -- 2. Оповещения о смене погоды
    local weatherPage = template:createSideBarPage({ label = i18n("weather_page_label") })
    local weatherCategory = weatherPage:createCategory(i18n("weather_category_label"))

    if not isWeatherModuleAvailable then
        weatherCategory:createInfo{
            label = i18n("weather_module_not_found_label"),
            description = i18n("weather_module_not_found_description")
        }
    else
        -- 2.1 Включение/выключение оповещений
        weatherCategory:createYesNoButton({
            label = i18n("toggle_blight_notifications_label"),
            description = i18n("toggle_blight_notifications_description"),
            variable = mwse.mcm.createTableVariable{ id = "showWeatherNotifications", table = config.weather },
            callback = function()
                if config.weather.showWeatherNotifications then
                    weatherModule.enable()
                else
                    weatherModule.disable()
                end
            end
        })

        -- 2.2 Текст оповещения о начале моровой бури
        weatherCategory:createTextField({
            label = i18n("blight_start_label"),
            description = i18n("blight_start_description"),
            variable = mwse.mcm.createTableVariable{
                id = "blightStormStartNotificationText",
                table = config.weather
            }
        })

	    -- 2.3 Текст оповещения об окончании моровой бури
	    weatherCategory:createTextField({
            label = i18n("blight_end_label"),
		    description = i18n("blight_end_description"),
            variable = mwse.mcm.createTableVariable{ id = "blightStormEndNotificationText", table = config.weather }
        })

        -- 2.4 Кнопка сброса настроек
	    weatherCategory:createButton({
        label = i18n("reset_weather_button_label"),
        buttonText = i18n("reset_weather_button_text"),
		description = i18n("reset_weather_button_description"),
        callback = function()
            for key, value in pairs(config.defaultConfig.weather) do
                config.weather[key] = value
            end
            tes3.messageBox(i18n("reset_weather_button_messageBox"))
        end
    })
    end

    mwse.mcm.register(template)
end

event.register("modConfigReady", registerModConfig)