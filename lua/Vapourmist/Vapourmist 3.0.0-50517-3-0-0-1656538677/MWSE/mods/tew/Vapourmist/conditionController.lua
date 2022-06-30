-- Condition controller

-->>>---------------------------------------------------------------------------------------------<<<--

local fogService = require("tew\\Vapourmist\\fogService")
local debugLog = fogService.debugLog
local config = require("tew\\Vapourmist\\config")
local data = require("tew\\Vapourmist\\data")

local toTime, toWeather, toRegion, fromTime, fromWeather, fromRegion, blockTimer

local WtC

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

	-- Get all data needed
	local cell = tes3.getPlayerCell()
	-- Sanity check
	if not cell then debugLog("No cell. Returning.") return end

	if (cell.isInterior) and not (cell.behavesAsExterior) then
		fogService.removeAll()
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

	debugLog("Weather: "..fromWeather.name.." -> "..toWeather.name)
	debugLog("Time: "..fromTime.." -> "..toTime)
	debugLog("Game hour: "..gameHour)
	debugLog("Region: "..fromRegion.id.." -> "..toRegion.id)

	-- Gets messy otherwise
	local mp = tes3.mobilePlayer
	if (not mp) or (mp and (mp.waiting or mp.traveling)) then
		debugLog("Player waiting or travelling.")
		if not (blockTimer) or (blockTimer.state == timer.expired) then
			blockTimer = timer.start
			{
				callback = conditionCheck,
				type = timer.game,
				duration = 0.05
			}
			fromWeather = toWeather
			fromTime = toTime
			fromRegion = toRegion
			fromTime = toTime
			return
		end

		if not (
		fromWeather.name == toWeather.name
		and fromTime == toTime
		and fromRegion.id == toRegion.id) then
			debugLog("Conditions changed. Removing fog.")
			fogService.removeAll()
		end
		return
	end

		timer.start{
			type = timer.real,
			duration = 0.5,
			iterations = 1,
			callback = function()
				
			-- Iterate through fog types
			for _, fogType in pairs(data.fogTypes) do

				-- Log fog type
				debugLog("Fog type: "..fogType.name)

				if fromWeather.name == toWeather.name
				and fromTime == toTime
				and fromRegion.id == toRegion.id
				and (fogService.isCellFogged(cell, fogType.name)) then
					debugLog("Conditions are the same. Returning.")
					return
				end
				
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

				if (fogService.isCellFogged(cell, fogType.name)) then
					debugLog("Cell already fogged. Recolouring.")
					fogService.reColour(options)
				end

				debugLog("Checks passed. Resetting and adding fog.")

				if WtC.nextWeather and WtC.transitionScalar < 0.6 then
					debugLog("Weather transition in progress. Adding fog in a bit.")
					timer.start {
						type = timer.game,
						iterations = 1,
						duration = 0.2,
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
			fromTime = toTime

		end
	}
end

-- On travelling, waiting etc.
local function onImmediateChange()
	debugLog("Weather changed immediate. Removing fog.")
	fogService.removeAll()
	conditionCheck()
end


local function onWeatherChanged(e)
	if data.fogTypes["mist"].wetWeathers[e.from.name] then

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
	fromWeather = nil
	fromTime = nil
	fromRegion = nil
	fogService.removeAll()
end

-- Register events
local function init()
	WtC = tes3.worldController.weatherController
	event.register("loaded", function() debugLog("================== loaded ==================") onLoaded() end)
	event.register("cellChanged", function() debugLog("================== cellChanged ==================") conditionCheck() end, {priority = 500})
	event.register("weatherChangedImmediate", function() debugLog("================== weatherChangedImmediate ==================") onImmediateChange() end, {priority = 500})
	event.register("weatherTransitionImmediate", function() debugLog("================== weatherTransitionImmediate ==================") onImmediateChange() end, {priority = 500})
	event.register("weatherTransitionStarted", function() debugLog("================== weatherTransitionStarted ==================") conditionCheck() end, {priority = 500})
	event.register("weatherTransitionStarted", function(e) debugLog("================== weatherTransitionStarted ==================") onWeatherChanged(e) end, {priority = 500})
	event.register("weatherTransitionFinished", function() debugLog("================== weatherTransitionFinished ==================") conditionCheck() end, {priority = 500})

end

-- Cuz SOLID, encapsulation blah blah blah
init()