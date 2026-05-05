local config = require("Rain Sheltering.config")
local state = require("Rain Sheltering.state")
local weather = require("Rain Sheltering.weather")
local shelterLogic = require("Rain Sheltering.shelter_logic")

config.excludedClasses["Guard"] = config.is_guard_patrolling_in_rain

local function onSimulate(e)
	state.timer = state.timer + e.delta
    -- Не чаще чем раз в checkInterval секунд:
	if state.timer < config.checkInterval then return end
	state.timer = 0.0

    -- Обновляем текущее состояние дождя в state.isRaining
	local rainingNow = weather.getWeatherIsRaining()
	if rainingNow ~= state.isRaining then
		state.isRaining = rainingNow
	end

    -- Если дождь идет - распределяем NPC по укрытиям
	if state.isRaining then
		shelterLogic.processSheltering()
	else -- Если дождя нет - возвращаем NPC из укрытий
		shelterLogic.releaseAllShelters()
	end
end
event.register(tes3.event.simulate, onSimulate)

-- При загрузке - инициализация
local function onLoaded()
	state.timer = 0.0
	state.isRaining = weather.getWeatherIsRaining()
	shelterLogic.resetActiveCells()
	shelterLogic.restoreAllNpcsData()
end
event.register(tes3.event.loaded, onLoaded)