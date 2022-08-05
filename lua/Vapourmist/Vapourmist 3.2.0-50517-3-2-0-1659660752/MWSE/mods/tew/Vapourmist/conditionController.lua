-- Condition controller

-->>>---------------------------------------------------------------------------------------------<<<--

local fogService = require("tew\\Vapourmist\\fogService")
local debugLog = fogService.debugLog
local config = require("tew\\Vapourmist\\config")
local data = require("tew\\Vapourmist\\data")

local toFogColour, toWeather, toRegion, fromFogColour, fromWeather, fromRegion, recolourRegistered

local WtC

-- Check for interior cells --
local function interiorCheck(cell)
	debugLog("Starting interior check.")

	-- Only proceed if the cell is eligible for interior fog and is not already fogged --
	if data.interiorFog.isAvailable(cell) and not fogService.isCellFogged(cell, data.interiorFog.name) then

		local options = {
			height = data.interiorFog.height,
			cell = cell,
		}

		fogService.addInteriorFog(options)
	end
end

-- Controls conditions and fog spawning/removing --
local function conditionCheck()
	-- Gets messy otherwise --
	local mp = tes3.mobilePlayer
	if (not mp) or (mp and (mp.waiting or mp.traveling)) then
		local gameHour = tes3.worldController.hour.value
		toWeather = WtC.nextWeather or WtC.currentWeather
		-- Nuke fog after waiting/travelling if conditions changed --
		for _, fogType in pairs(data.fogTypes) do
			if not (fogType.isAvailable(gameHour, toWeather)) then
				debugLog("Player waiting or travelling and fog: " .. fogType.name .. " not available.")
				fogService.removeFogImmediate(fogType.name)
			end
		end
		return
	end

	debugLog("Running check.")

	-- Clear appculled fog and fade out distant fog --
	fogService.cleanInactiveFog()

	local cell = tes3.getPlayerCell()
	-- Sanity check --
	if not cell then debugLog("No cell. Returning.") return end

	-- If we're in interior then clean up exterior fog --
	if not (cell.isOrBehavesAsExterior) then
		fogService.removeAllExterior()
		if config.interiorFog then
			interiorCheck(cell)
		end
		return
	end

	-- Get game hour and time type --
	local gameHour = tes3.worldController.hour.value
	toFogColour = WtC.currentFogColor:copy()
	fromFogColour = fromFogColour or toFogColour:copy()

	-- Check weather --
	toWeather = WtC.nextWeather or WtC.currentWeather
	fromWeather = fromWeather or WtC.currentWeather

	-- Check region --
	toRegion = cell.region
	fromRegion = fromRegion or toRegion

	-- Print values so we're sure we're not insane --
	debugLog("Weather: " .. fromWeather.name .. " -> " .. toWeather.name)
	debugLog("Game hour: " .. gameHour)
	debugLog("Fog colour: " .. tostring(fromFogColour) .. " -> " .. tostring(toFogColour))
	debugLog("Region: " .. fromRegion.id .. " -> " .. toRegion.id)

	-- Iterate through fog types --
	for _, fogType in pairs(data.fogTypes) do

		-- Log fog type --
		debugLog("Fog type: " .. fogType.name)

		-- Get type of fog and its pre-set height for later calcs --
		local options = {
			type = fogType.name,
			height = fogType.height,
		}

		-- Check whether we can add the fog at this time, remove and skip to another fog type if not --
		if not (fogType.isAvailable(gameHour, toWeather)) then
			debugLog("Fog: " .. fogType.name .. " not available.")
			fogService.removeFog(fogType.name)
			goto continue
		end

		debugLog("Checks passed. Resetting and adding fog.")

		-- If we're inside weather transition, offset the spawning a bit --
		if WtC.nextWeather and WtC.transitionScalar < 0.6 then
			debugLog("Weather transition in progress. Adding fog in a bit.")
			timer.start {
				type = timer.game,
				iterations = 1,
				duration = 0.2,
				callback = function() fogService.addFog(options) end
			}
		else
			-- If transition scalar is high enough or we're not transitioning at all --
			fogService.addFog(options)
		end

		::continue::
	end

	-- Write off values for later comparison --
	fromWeather = toWeather
	fromFogColour = toFogColour
	fromRegion = toRegion
end

-- Check if we can add post-rain fog --
local function onWeatherChanged(e)
	if data.fogTypes["mist"].wetWeathers[e.from.name] then

		debugLog("Adding post-rain mist.")

		local options = {
			type = data.fogTypes["mist"].name,
			height = data.fogTypes["mist"].height,
		}

		-- Slight offset so we get all data needed --
		timer.start {
			type = timer.game,
			iterations = 1,
			duration = 0.3,
			callback = function() fogService.addFog(options) end
		}
	end
end

-- Register events, timers and reset values --
local function onLoaded()
	-- To ensure we don't end up reregistering the event --
	if not recolourRegistered then
		event.register("enterFrame", fogService.reColour)
		recolourRegistered = true
	end
	timer.start({ duration = data.baseTimerDuration, callback = function() debugLog("================== timer ==================") conditionCheck() end, iterations = -1, type = timer.game })
	debugLog("Timer started. Duration: " .. data.baseTimerDuration)
	fromWeather = nil
	fromFogColour = nil
	fromRegion = nil
	fogService.removeAll()
end

-- The check to be run after waiting/travelling --
local function waitCheck(e)
	local element = e.element
	element:registerAfter("destroy", function() -- registerAfter ensure we can register across projects --
		timer.start {
			type = timer.game,
			duration = 0.01,
			callback = conditionCheck
		}
	end)
end

-- Register events
local function init()
	WtC = tes3.worldController.weatherController

	-- Just load meshes to memory once --
	for _, fogType in pairs(data.fogTypes) do
		fogService.meshes[fogType.name] = tes3.loadMesh(fogType.mesh)
	end
	fogService.meshes[data.interiorFog.name] = tes3.loadMesh(data.interiorFog.mesh)

	event.register("loaded", function() debugLog("================== loaded ==================") onLoaded() end)
	event.register("cellChanged", function() debugLog("================== cellChanged ==================") conditionCheck() end, { priority = 500 })
	event.register("weatherChangedImmediate", function() debugLog("================== weatherChangedImmediate ==================") conditionCheck() end, { priority = 500 })
	event.register("weatherTransitionImmediate", function() debugLog("================== weatherTransitionImmediate ==================") conditionCheck() end, { priority = 500 })
	event.register("weatherTransitionStarted", function() debugLog("================== weatherTransitionStarted ==================") conditionCheck() end, { priority = 500 })
	event.register("weatherTransitionStarted", function(e) debugLog("================== weatherTransitionStarted ==================") onWeatherChanged(e) end, { priority = 500 })
	event.register("weatherTransitionFinished", function() debugLog("================== weatherTransitionFinished ==================") conditionCheck() end, { priority = 500 })
	event.register("uiActivated", waitCheck, { filter = "MenuTimePass", priority = -5 })
end

init()
