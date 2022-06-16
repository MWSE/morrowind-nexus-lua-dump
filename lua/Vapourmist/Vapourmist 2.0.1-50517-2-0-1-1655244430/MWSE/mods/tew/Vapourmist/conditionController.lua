-- Condition controller

-->>>---------------------------------------------------------------------------------------------<<<--

local fogService = require("tew\\Vapourmist\\fogService")
local debugLog = fogService.debugLog
local config = require("tew\\Vapourmist\\config")
local data = require("tew\\Vapourmist\\data")

local toTime, toWeather, toRegion, fromTime, fromWeather, fromRegion

-- Check for interior cells
local function interiorCheck(cell)

	debugLog("Starting interior check.")

	if data.interiorFog.isAvailable(cell) and not fogService.isCellFogged(cell, data.interiorFog.name) then

		local options = {
			mesh = data.interiorFog.mesh,
			type = data.interiorFog.name,
			height = data.interiorFog.height,
			colours = data.interiorFog.colours,
			cell = cell,
		}

		fogService.addInteriorFog(options)

	end

end

-- Controls conditions and fog spawning/removing
local function conditionCheck(e)

	debugLog("Running check.")

	-- Gets messy otherwise
	local mp = tes3.mobilePlayer
	if (not mp) or (mp and (mp.waiting or mp.traveling)) then
		debugLog("Player waiting or travelling. Returning.")
		timer.start{
			duration = 1,
			callback = conditionCheck,
		}
		return
	end

	-- Get all data needed
	local cell = tes3.getPlayerCell()
	-- Sanity check
	if not cell then debugLog("No cell. Returning.") return end

	if (cell.isInterior) and not (cell.behavesAsExterior) then
		if config.interiorFog then
			interiorCheck(cell)
		end
		return
	end

	-- Get game hour and time type
	local gameHour = tes3.worldController.hour.value
	toTime = fogService.getTime(gameHour)
	fromTime = fromTime or toTime

	-- Check weather
	toWeather = WtC.nextWeather or WtC.currentWeather
	fromWeather = fromWeather or WtC.currentWeather

	-- Check region
	toRegion = cell.region
	fromRegion = fromRegion or toRegion

	debugLog("Weather: "..fromWeather.index.." -> "..toWeather.index)
	debugLog("Time: "..fromTime.." -> "..toTime)
	debugLog("Game hour: "..gameHour)
	debugLog("Region: "..fromRegion.id.." -> "..toRegion.id)

	-- Iterate through fog types
	for _, fogType in pairs(data.fogTypes) do

		-- Log fog type
		debugLog("Fog type: "..fogType.name)
		
		local options = {
			mesh = fogType.mesh,
			type = fogType.name,
			height = fogType.height,
			colours = fogType.colours,
			fromWeather = fromWeather,
			toWeather = toWeather,
			fromTime = fromTime,
			toTime = toTime,
		}

		-- Check whether we can add the fog at this time
		if not (fogType.isAvailable(gameHour, toWeather)) then
			debugLog("Fog: "..fogType.name.." not available.")
			fogService.removeFog(options.type)
			goto continue
		end

		if fromWeather.index == toWeather.index
		and fromTime == toTime
		and fromRegion.id == toRegion.id
		and (fogService.isCellFogged(cell, fogType.name)) then
			debugLog("Conditions are the same. Returning.")
			break
		end

		if (fogService.isCellFogged(cell, fogType.name)) and not (fogService.isFogAppculled(fogType.name)) then
			debugLog("Cell already fogged and not appculled. Recolouring.")
			fogService.reColour(options)
		end

		debugLog("Checks passed. Adding fog.")
		if WtC.nextWeather and WtC.transitionScalar < 0.6 then
			debugLog("Weather transition in progress. Adding fog in a bit.")
			timer.start {
				type = timer.game,
				iterations = 1,
				duration = 0.3,
				callback = function() fogService.addFog(options) end
			}
		else
			fogService.addFog(options)
		end

		::continue::
	end

	fromWeather = toWeather
	fromTime = toTime
	fromRegion = toRegion

end

-- On travelling, waiting etc.
local function onImmediateChange(e)

	if e then
		fromWeather = e.from or WtC.currentWeather
		toWeather = e.to or WtC.nextWeather or fromWeather
	else
		fromWeather = WtC.currentWeather
		toWeather = WtC.nextWeather or fromWeather
	end

	 -- Get game hour and time
	local gameHour = tes3.worldController.hour.value
	toTime = fogService.getTime(gameHour)

	 -- Iterate through fog types
	for _, fogType in pairs(data.fogTypes) do
		debugLog("Checking conditions for "..fogType.name..".")

		fogService.removeFogImmediate{
			fromTime = fromTime,
			toTime = toTime,
			fromWeather = fromWeather,
			toWeather = toWeather,
			colours = fogType.colours,
			type = fogType.name,
		}
	end

	conditionCheck()

end


local function onWeatherChanged(e)
	if data.fogTypes["mist"].wetWeathers[e.from.index] then

		debugLog("Adding post-rain mist.")

		local options = {
			mesh = data.fogTypes["mist"].mesh,
			type = data.fogTypes["mist"].name,
			height = data.fogTypes["mist"].height,
			colours = data.fogTypes["mist"].colours,
			toWeather = e.to,
			toTime = fogService.getTime(tes3.worldController.hour.value),
		}

		timer.start {
			type = timer.game,
			iterations = 1,
			duration = 0.3,
			callback = function() fogService.addFog(options) end
		}
		
	end
end

-- A timer needed to check for time changes
local function onLoaded()
	timer.start({duration = data.baseTimerDuration, callback = function() debugLog("================== timer ==================") conditionCheck() end, iterations = -1, type = timer.game})
	debugLog("Timer started. Duration: "..data.baseTimerDuration)
	fogService.removeAll()
end

-- Register events
local function init()
	WtC = tes3.worldController.weatherController
	event.register("loaded", function() debugLog("================== loaded ==================") onLoaded() end)
	event.register("cellChanged", function() debugLog("================== cellChanged ==================") conditionCheck() end, {priority=255})
	event.register("weatherChangedImmediate", function() debugLog("================== weatherChangedImmediate ==================") onImmediateChange() end)
	event.register("weatherTransitionImmediate", function() debugLog("================== weatherTransitionImmediate ==================") onImmediateChange() end)
	event.register("weatherTransitionStarted", function() debugLog("================== weatherTransitionStarted ==================") conditionCheck() end, {priority = 100})
	event.register("weatherTransitionStarted", function(e) debugLog("================== weatherTransitionStarted ==================") onWeatherChanged(e) end, {priority = 120})

end

-- Cuz SOLID, encapsulation blah blah blah
init()