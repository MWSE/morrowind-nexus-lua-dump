
local config = require("Wonders of Water.config")
local interop = require("Wonders of Water.interop")

local weatherRusName = {
    Clear = "Ясно",
    Cloudy = "Облачно",
    Foggy = "Туманно",
    Overcast = "Пасмурно",
    Rain = "Дождь",
    Thunderstorm = "Гроза",
    Ashstorm = "Пепельная буря",
    Blight = "Моровая буря",
    Snow = "Снег",
    Blizzard = "Метель"
}

local function getSortedWeatherList()
	local weathers = {} --- @type tes3weather[]
	for _, weather in ipairs(tes3.worldController.weatherController.weathers) do
		table.insert(weathers, weather)
	end

	--table.sort(weathers, function(a, b)
		--return a.name:lower() < b.name:lower()
	--end)

	return weathers
end

local function registerModConfig()
	local template = mwse.mcm.createTemplate({ name = "Чудеса воды" })

	-- Save config options when the mod config menu is closed
	template:saveOnClose("Wonders of Water", config)

	-- Create a simple container Page under Template
	do
		local settings = template:createSideBarPage({ label = "Настройки" })

		-- Create a button under Page that toggles a variable between true and false
		settings:createYesNoButton({
			label = "Включить мод",
			variable = mwse.mcm:createTableVariable({ id = "enabled", table = config }),
			callback = interop.resetValues
		})

		local features = settings:createCategory({ label = "Функции" })
		do
			features:createYesNoButton({
				label = "Уменьшить воздействие солнечных лучей на глубине?",
				variable = mwse.mcm:createTableVariable({ id = "sunDamage", table = config.features }),
			})

			features:createYesNoButton({
				label = "Изменять эффект бликов под водой в зависимости от погоды?",
				variable = mwse.mcm:createTableVariable({ id = "waterCaustics", table = config.features }),
			})

			features:createYesNoButton({
				label = "Изменять высоту волн в зависимости от погоды?",
				variable = mwse.mcm:createTableVariable({ id = "waterWaves", table = config.features }),
			})

			features:createYesNoButton({
				label = "Изменять прозрачность воды в зависимости от глубины?",
				variable = mwse.mcm:createTableVariable({ id = "waterClarity", table = config.features }),
			})
		end
	end

	-- Create a simple container Page under Template
	do
		local weathers = template:createSideBarPage({ label = "Погодные условия" })

		local allWeathers = getSortedWeatherList()
		for _, weather in ipairs(allWeathers) do
			local category = weathers:createCategory({ label = weatherRusName[weather.name] or weather.name})
			local weatherConfig = interop.getConfigForWeather(weather)
			category:createTextField({
				label = "Множитель световых бликов",
				description = "Множитель, усиливающий или ослабляющий световые блики под водой при этой погоде.",
				variable = mwse.mcm.createTableVariable({ id = "caustics", converter = tonumber, table = weatherConfig }),
				numbersOnly = true,
			})
			category:createTextField({
				label = "Множитель высоты волн",
				description = "Множитель, определяющий высоту волн при этой погоде.",
				variable = mwse.mcm.createTableVariable({ id = "waveHeight", converter = tonumber, table = weatherConfig }),
				numbersOnly = true,
			})
			category:createTextField({
				label = "Множитель видимости",
				description = "Множитель, определяющий дальность обзора под водой при этой погоде.",
				variable = mwse.mcm.createTableVariable({ id = "clarity", converter = tonumber, table = weatherConfig }),
				numbersOnly = true,
			})
		end
	end

	-- Finish up.
	template:register()
end
event.register(tes3.event.modConfigReady, registerModConfig)
