-- Данный модуль отслеживает изменения погоды, касающихся моровых бурь, и вызывает уведомления из config
local config = require("BlightStormInfection.config")

local function onBlightStart()
	tes3.messageBox(config.weather.blightStormStartNotificationText)
end

local function onBlightFinish()
	tes3.messageBox(config.weather.blightStormEndNotificationText)
end

local function checkIsBlight()
	if not tes3.getCurrentWeather() then -- например при старте новой игры после уже загруженной
		return false
	end
	return tes3.getCurrentWeather().index == tes3.weather.blight
end

local wasBlight = false -- Хранит текущее состояние бури после обработки события

-- Функция для проверки состояния и вывода сообщения
local function blightNotification(event)
	--weatherTransitionStarted only
	if (event.eventType == "weatherTransitionStarted") then
		local nextBlight = (event.to.index == tes3.weather.blight)

		if not wasBlight and nextBlight then -- Погода меняется на бурю
			onBlightStart()
			return
		end
	end

	local isBlight = checkIsBlight()

	if wasBlight and not isBlight then -- Погода сменилась с бури на что-то другое
		onBlightFinish()
		wasBlight = false
		return
	end

	--weatherTransitionFinished only
	if (event.eventType == "weatherTransitionFinished") then
		if not wasBlight and isBlight then -- Погода сменилась на бурю
			wasBlight = true
			return
		end
	end

	--cellChanged only
	if (event.eventType == "cellChanged") then
		if not wasBlight and isBlight then -- В новой ячейке появилась буря
			-- если загрузились в интерьере, а снаружи буря - уведомление не нужно
			if tes3.getPlayerCell().isInterior then return end

			onBlightStart()
			wasBlight = true
			return
		end
	end
end

-- Функции управления включением/отключением модуля. Управляются галочкой в mcm.lua. Инициализируются здесь.
local isRegistered = false -- защита от повторной регистрации
local weather = {}

function weather.enable()
	if isRegistered then return end
	if not config.weather.showWeatherNotifications then return end

	isRegistered = true --сразу на случай частичной регистрации

	wasBlight = checkIsBlight()

	-- 1. При смене погоды
	event.register(tes3.event.weatherTransitionStarted, blightNotification)
	event.register(tes3.event.weatherTransitionFinished, blightNotification)
	-- 2. При смене ячейки: загрузка сохранения, телепортация, переход между локациями
	event.register(tes3.event.cellChanged, blightNotification)

	-- 3. При каждой загрузке сохранения - обнуляем состояние прошлой бури
	local function onLoad()
		wasBlight = false
	end
	event.register(tes3.event.load, onLoad)
end

function weather.disable()
	if not isRegistered then return end

	event.unregister(tes3.event.weatherTransitionStarted, blightNotification)
	event.unregister(tes3.event.weatherTransitionFinished, blightNotification)
	event.unregister(tes3.event.cellChanged, blightNotification)

	isRegistered = false --unregister несуществующего обработчика не вызывает ошибку
end

event.register(tes3.event.initialized, weather.enable) -- инициализируем при загрузке (запуске) игры

return weather