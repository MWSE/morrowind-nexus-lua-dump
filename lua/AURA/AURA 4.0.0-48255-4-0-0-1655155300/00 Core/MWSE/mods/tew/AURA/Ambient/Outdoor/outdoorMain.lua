local climates = require("tew.AURA.Ambient.Outdoor.outdoorClimates")
local config = require("tew.AURA.config")
local common=require("tew.AURA.common")
local tewLib = require("tew.tewLib.tewLib")
local sounds = require("tew.AURA.sounds")

local isOpenPlaza=tewLib.isOpenPlaza

local moduleAmbientOutdoor=config.moduleAmbientOutdoor
local moduleInteriorWeather=config.moduleInteriorWeather
local playSplash=config.playSplash
local quietChance=config.quietChance/100
local OAvol = config.OAvol/200
local splashVol = config.splashVol/200
local playWindy=config.playWindy
local playInteriorAmbient=config.playInteriorAmbient

local moduleName = "outdoor"

local climateLast, weatherLast, timeLast, cellLast
local climateNow, weatherNow, timeNow

local windoors, interiorTimer

local debugLog = common.debugLog

local function weatherParser(options)

	local volume, pitch, ref, immediate

	if not options then
		volume = OAvol
		pitch = 1
		immediate = false
		ref = tes3.mobilePlayer.reference
	else
		volume = options.volume or OAvol
		pitch = options.pitch or 1
		immediate = options.immediate or false
		ref = options.reference or tes3.mobilePlayer.reference
	end

	if weatherNow >= 0 and weatherNow <4 then
		if quietChance<math.random() then
			debugLog("Playing regular weather track.")
			if immediate then
				sounds.playImmediate{module = moduleName, climate = climateNow, time = timeNow, volume = volume, pitch = pitch, reference = ref}
			else
				sounds.play{module = moduleName, climate = climateNow, time = timeNow, volume = volume, pitch = pitch, reference = ref}
			end
		else
			debugLog("Playing quiet weather track.")
			if immediate then
				sounds.playImmediate{module = moduleName, volume = volume, type = "quiet", pitch = pitch, reference = ref}
			else
				sounds.play{module = moduleName, volume = volume, type = "quiet", pitch = pitch, reference = ref}
			end
		end
	elseif (weatherNow >= 4 and weatherNow < 6) or (weatherNow == 8) then
		if playWindy then
			debugLog("Bad weather detected and windy option on.")
			if weatherNow == 3 or weatherNow == 4 then
				debugLog("Found warm weather, using warm wind loops.")
				if immediate then
					sounds.playImmediate{module = moduleName, volume = volume, type = "warm", pitch = pitch, reference = ref}
				else
					sounds.play{module = "outdoor", volume = volume, type = "warm", pitch = pitch, reference = ref}
				end
			elseif weatherNow == 8 or weatherNow == 5 then
				debugLog("Found cold weather, using cold wind loops.")
				if immediate then
					sounds.playImmediate{module = moduleName, volume = volume, type = "cold", pitch = pitch, reference = ref}
				else
					sounds.play{module = "outdoor", volume = volume, type = "cold", pitch = pitch, reference = ref}
				end
			end
		else
			debugLog("Bad weather detected and no windy option on. Returning.")
			return
		end
	elseif weatherNow == 6 or weatherNow == 7 or weatherNow == 9 then
		debugLog("Extreme weather detected.")
		sounds.remove{module = moduleName, reference = ref, volume = OAvol}
		return
	end
end

local function playInteriorBig(windoor, playOld)
	if windoor==nil then debugLog("Dodging an empty ref.") return end
	if playOld then
		debugLog("Playing interior ambient sounds for big interiors using old track.")
		sounds.playImmediate{module = moduleName, last = true, reference = windoor, volume = 0.35*OAvol, pitch=0.9}
	else
		debugLog("Playing interior ambient sounds for big interiors using new track.")
		weatherParser{reference = windoor, volume = 0.35*OAvol, pitch = 0.9, immediate = true}
	end
end

local function updateInteriorBig()
	debugLog("Updating interior doors and windows.")
	local playerPos=tes3.player.position
	for _, windoor in ipairs(windoors) do
		if common.getDistance(playerPos, windoor.position) > 2048
		and windoor~=nil then
			playInteriorBig(windoor, true)
		end
	end
end

local function playInteriorSmall()
	if cellLast and not cellLast.isInterior then
		debugLog("Playing interior ambient sounds for small interiors using old track.")
		sounds.playImmediate{module = moduleName, last = true, volume = 0.3*OAvol, pitch=0.9}
	else
		debugLog("Playing interior ambient sounds for small interiors using new track.")
		weatherParser{volume = 0.3*OAvol, pitch = 0.9, immediate = true}
	end
end

local function cellCheck()

	-- Gets messy otherwise
	local mp = tes3.mobilePlayer
	if (not mp) or (mp and (mp.waiting or mp.traveling)) then
		debugLog("Player waiting or travelling. Returning.")
		timer.start{
			duration = 1,
			callback = cellCheck,
		}
		return
	end

	local region

	OAvol = config.OAvol/200	
	
	debugLog("Cell changed or time check triggered. Running cell check.")
	
	-- Getting rid of timers on cell check --
	if not interiorTimer then
		interiorTimer = timer.start({duration=1, iterations=-1, callback=updateInteriorBig, type=timer.real})
		interiorTimer:pause()
	else
		interiorTimer:pause()
	end
	
	local cell = tes3.getPlayerCell()
	if (not cell) then debugLog("No cell detected. Returning.") return end
	
	if cell.isInterior then
		region = tes3.getRegion({useDoors=true}).name
	else
		region = tes3.getRegion().name
	end
	
	if region == nil then debugLog("No region detected. Returning.") return end
	
	-- Checking climate --
	for kRegion, vClimate in pairs(climates.regions) do
		if kRegion==region then
			climateNow=vClimate
		end
	end
	if not climateNow then debugLog ("Blacklisted region - no climate detected. Returning.") return end
	debugLog("Climate: "..climateNow)
	
	-- Checking time --
	local gameHour=tes3.worldController.hour.value
	if (gameHour >= WtC.sunriseHour - 1.5) and (gameHour < WtC.sunriseHour + 1.5) then
		timeNow = "sr"
	elseif (gameHour >= WtC.sunriseHour + 1.5) and (gameHour < WtC.sunsetHour - 1.5) then
		timeNow = "d"
	elseif (gameHour >= WtC.sunsetHour - 1.5) and (gameHour < WtC.sunsetHour + 1.5) then
		timeNow = "ss"
	elseif (gameHour >= WtC.sunsetHour + 1.5) or (gameHour < WtC.sunriseHour - 1.5) then
		timeNow = "n"
	end
	debugLog("Time: "..timeNow)
	
	-- Checking current weather --
	weatherNow = tes3.getRegion({useDoors=true}).weather.index
	debugLog("Weather: "..weatherNow)
	
	-- Transition filter chunk --
	if
		timeNow==timeLast
		and climateNow==climateLast
		and weatherNow==weatherLast
		and (common.checkCellDiff(cell, cellLast) == false
			or cell == cellLast) then
		debugLog("Same conditions. Returning.")
		return
	elseif
		timeNow~=timeLast
		and weatherNow==weatherLast
		and (common.checkCellDiff(cell, cellLast) == false)
		and ((weatherNow >= 4 and weatherNow < 6) or (weatherNow == 8)) then
			debugLog("Time changed but weather didn't. Returning.")
			return
	end
		
	debugLog("Different conditions. Resetting sounds.")
	
	if moduleInteriorWeather == false and windoors[1]~=nil and weatherNow<4 or weatherNow==8 then
		for _, windoor in ipairs(windoors) do
			sounds.removeImmediate{module=moduleName, reference=windoor}
		end
		debugLog("Clearing windoors.")
	end
	
	if not cell.isInterior
	or (cell.isInterior) and (cell.behavesAsExterior
	and not isOpenPlaza(cell)) then
		if cellLast and common.checkCellDiff(cell, cellLast)==true and timeNow==timeLast
		and weatherNow==weatherLast and climateNow==climateLast
		and not ((weatherNow >= 4 and weatherNow <= 6) or (weatherNow == 8)) then
		-- Using the same track when entering int/ext in same area; time/weather change will randomise it again --
			debugLog("Found same cell. Immediately playing last sound.")
			sounds.removeImmediate{module = moduleName}
			sounds.playImmediate{module = moduleName, last = true, volume = OAvol}
		else
			debugLog("Found exterior cell.")
			sounds.remove{module = moduleName, volume=OAvol}
			weatherParser{volume=OAvol}
		end
	elseif cell.isInterior then
		if (not playInteriorAmbient) or (playInteriorAmbient and isOpenPlaza(cell) and weatherNow==3) then
			debugLog("Found interior cell. Removing sounds.")
			sounds.removeImmediate{module = moduleName}
		else
			if weatherNow > 3 and not weatherNow == 8 then return end
			if common.getCellType(cell, common.cellTypesSmall)==true
			or common.getCellType(cell, common.cellTypesTent)==true then
				debugLog("Found small interior cell. Playing interior loops.")
				sounds.removeImmediate{module = moduleName}
				playInteriorSmall()
			else
				debugLog("Found big interior cell. Playing interior loops.")
				sounds.removeImmediate{module = moduleName}
				windoors=nil
				windoors=common.getWindoors(cell)
				if windoors ~= nil then
					for _, windoor in ipairs(windoors) do
						playInteriorBig(windoor)
					end
					interiorTimer:resume()
				end
			end
		end
	end
		
	-- Setting last values --
	timeLast=timeNow
	climateLast=climateNow
	weatherLast=weatherNow
	cellLast=cell
	debugLog("Cell check complete.")
end

local function positionCheck(e)
	local cell=tes3.getPlayerCell()
	local element=e.element
	debugLog("Player underwater. Stopping AURA sounds.")
	if (not cell.isInterior) or (cell.behavesAsExterior) then
		sounds.removeImmediate{module = moduleName}
		sounds.playImmediate{module = moduleName, last = true, volume = 0.4*OAvol, pitch=0.5}
	end
	if playSplash and moduleAmbientOutdoor then
		tes3.playSound{sound="splash_lrg", volume=0.5*splashVol, pitch=0.6}
	end
	element:register("destroy", function()
		debugLog("Player above water level. Resetting AURA sounds.")
		if (not cell.isInterior) or (cell.behavesAsExterior) then
			sounds.removeImmediate{module = moduleName}
			sounds.playImmediate{module = moduleName, last = true, volume = OAvol}
		end
		timer.start({duration=1, callback=cellCheck, type=timer.real})
		if playSplash and moduleAmbientOutdoor then
			tes3.playSound{sound="splash_sml", volume=0.6*splashVol, pitch=0.7}
		end
	end)
end

local function runResetter()
	climateLast, weatherLast, timeLast = nil, nil, nil
	climateNow, weatherNow, timeNow = nil, nil, nil
	windoors = {}
end

local function runHourTimer()
	timer.start({duration=0.5, callback=cellCheck, iterations=-1, type=timer.game})
end

local function hackyCheck()
	runResetter()
	cellCheck()
end

debugLog("Outdoor Ambient Sounds module initialised.")
event.register("loaded", runHourTimer, {priority=-160})
event.register("load", runResetter, {priority=-160})
event.register("cellChanged", cellCheck, {priority=-160})
event.register("weatherTransitionFinished", cellCheck, {priority=-160})
event.register("weatherTransitionImmediate", cellCheck, {priority=-160})
event.register("weatherChangedImmediate", cellCheck, {priority=-160})
event.register("uiActivated", positionCheck, {filter="MenuSwimFillBar", priority = -5})
event.register("AURA:conditionChanged", hackyCheck)