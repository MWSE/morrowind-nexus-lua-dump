local world = require('openmw.world')
local util = require('openmw.util')
local core = require('openmw.core')
local calendar = require('openmw_aux.calendar')
local time = require('openmw_aux.time')
local async = require('openmw.async')
local v2 = util.vector2
local I = require('openmw.interfaces')
local storage = require('openmw.storage')
local types = require('openmw.types')
local oresDatabase = require('scripts.timeFlies.ore_database')
local hasSimplyMining = core.contentFiles.has('SimplyMining.omwscripts')
local active = false
local hoursToPass = 0
local maxHoursToPass = 0
local previousPauseTags = {}
local previousTimeScale = nil
local waitingForMidnight = false
local lastRealTime = nil
local passTimeSpeed = 2 -- game hours per real second

local function passMinutes(minutes)
	-- print("+"..minutes)
	hoursToPass = hoursToPass + minutes/60
	maxHoursToPass = math.max(maxHoursToPass, hoursToPass)
	lastRealTime = core.getRealTime()
	active = true
end

local function onUpdate()
	if not active then return end
	local now = core.getRealTime()
	local dt = now - lastRealTime
	lastRealTime = now
	local globals = world.mwscript.getGlobalVariables()
	if waitingForMidnight then
		local gamehour = globals.gamehour
		if gamehour < 1 then
			-- restore previous state after midnight
			waitingForMidnight = false
			if previousTimeScale then
				world.setGameTimeScale(previousTimeScale)
				previousTimeScale = nil
			end
			for tag, _ in pairs(previousPauseTags) do
				world.pause(tag)
			end
			previousPauseTags = {}
		else
			return
		end
	end
	if hoursToPass <= 0 then 
		active = false 
		maxHoursToPass = 0
		return
	end
	local gamehour = globals.gamehour
	
	-- smooth log curve for duration
	-- 0.1h -> 0.12s
	-- 0.5h -> 0.18s
	--   1h -> 0.24s
	--   4h -> 0.42s
	--  10h -> 0.58s
	--  20h -> 0.71s
	--  24h -> 0.74s
	--  48h -> 0.88s
	local totalTimeForTransition = 0.1 + 0.2 * math.log(1 + maxHoursToPass)

	local speed = maxHoursToPass / totalTimeForTransition
	local step = math.min(1, dt * speed, hoursToPass, 23.999999 - gamehour)
	if step > 0.00001 then
		globals.gamehour = globals.gamehour + step
		hoursToPass = hoursToPass - step
		for _, player in pairs(world.players) do
			player:sendEvent('timeHud_refreshTime')
		end
	else
		-- at midnight boundary let the engine process the day transition
		previousPauseTags = world.getPausedTags()
		for tag, _ in pairs(previousPauseTags) do
			world.unpause(tag)
		end
		if world.getGameTimeScale() <= 1 then
			previousTimeScale = world.getGameTimeScale()
			world.setGameTimeScale(60)
		end
		waitingForMidnight = true
	end
end

-- activation handlers

local function activateContainer(object, player)
	local isOrganic = types.Container.record(object).isOrganic
	if isOrganic then
		if oresDatabase[object.recordId] then
			if not hasSimplyMining then
				player:sendEvent("TimeFlies_mineOre", object)
			end
		else
			player:sendEvent("TimeFlies_harvestPlant", object)
		end
	end
end

I.Activation.addHandlerForType(types.Container, activateContainer)

local function activateShrine(object, player)
	local recordId = object.recordId:lower()
	local shrineScript = (types.Activator.record(recordId).mwscript or '')
	if shrineScript:sub(1,6) == "shrine" then
		player:sendEvent("TimeFlies_activateShrine", object)
	end
end

I.Activation.addHandlerForType(types.Activator, activateShrine)

-- intercept sun's dusk global events
local function cookFood(data)
	local player = data[1]
	player:sendEvent("TimeFlies_cookFood")
end

local function brewTea(data)
	local player = data[1]
	player:sendEvent("TimeFlies_brewTea")
end

local function refillWell(data)
	local player = data[1]
	player:sendEvent("TimeFlies_refillWell")
end

local function purifyWater(data)
	local player = data[1]
	player:sendEvent("TimeFlies_purifyWater")
end

local function buildFire(data)
	local player = data[1]
	player:sendEvent("TimeFlies_buildFire")
end

local function destroyFlimsyTent(obj)
	for _, player in pairs(world.players) do
		player:sendEvent("TimeFlies_destroyTent")
	end
end

local function pitchTent(data)
	local player = data[1]
	player:sendEvent("TimeFlies_pitchTent")
end

local function breakCamp(data)
	local player = data[1]
	player:sendEvent("TimeFlies_destroyTent")
end

-- ownlyme's suite
local function simplyMining(data)
	for _, player in pairs(world.players) do
		player:sendEvent("TimeFlies_simplyMining")
	end
end

-- quickloot dispose body
local function takeAll(data)
    local player = data[1]
    local object = data[2]
    local disposeBody = data[3]
    if disposeBody and types.Actor.objectIsInstance(object) and types.Actor.isDead(object) then
        player:sendEvent("TimeFlies_disposeBody", object)
    end
end

return {
	eventHandlers = {
		-- core time passing
		TimeFlies_passMinutes = passMinutes,

		-- quickloot
		OwnlysQuickLoot_takeAll = takeAll,

		-- sun's dusk
		SunsDusk_createStew = cookFood,
		SunsDusk_Tea_brewTea = brewTea,
		SunsDusk_WaterBottles_refillBottlesWell = refillWell,
		SunsDusk_WaterBottles_purifyWater = purifyWater,
		SunsDusk_igniteFire = buildFire,
		SunsDusk_destroyCamp = destroyFlimsyTent,
		SunsDusk_upgradeTent = pitchTent,
		SunsDusk_damageTent = breakCamp,

		-- ownlyme
		SimplyMining_setNodeSize = simplyMining,
		
		-- ralts
	},
	engineHandlers = {
		onUpdate = onUpdate,
	}
}