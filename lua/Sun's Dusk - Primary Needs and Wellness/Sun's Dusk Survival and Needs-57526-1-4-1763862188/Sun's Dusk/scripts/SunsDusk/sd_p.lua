--[[
╭──────────────────────────────────────────────────────────────────────╮
│  Sun's Dusk : Player Runtime					  					   │
│  orchestrate per-minute/hour jobs, UI hooks, rain/water checks	   │
╰──────────────────────────────────────────────────────────────────────╯
]]

MODNAME = "SunsDusk"
ui = require('openmw.ui')
util = require('openmw.util')
core = require('openmw.core')
calendar = require('openmw_aux.calendar')
time = require('openmw_aux.time')
async = require('openmw.async')
v2 = util.vector2
v3 = util.vector3
I = require('openmw.interfaces')
storage = require('openmw.storage')
input = require('openmw.input')
self = require('openmw.self')
types = require("openmw.types")
vfs = require('openmw.vfs')
I = require('openmw.interfaces')
camera = require('openmw.camera')
nearby = require('openmw.nearby')
ambient = require('openmw.ambient')
auxUi = require('openmw_aux.ui')
debug = require('openmw.debug')
animation = require('openmw.animation')
--Health = types.Actor.stats.dynamic.health(self)
makeBorder = require("scripts.SunsDusk.ui_makeborder") 
typesActorSpellsSelf = types.Actor.spells(self)
-- Cache once to avoid repeated checks
G_WEATHER_API_AVAILABLE = core.weather and core.weather.getCurrent
G_preventAddingAnyBuffs = false
G_forceSquareFalloff = nil
G_addSpellWhenAwake = function(spell)
	if not G_preventAddingAnyBuffs then
		typesActorSpellsSelf:add(spell)
	end
end


-- ───────────────────────────────────────────────────────────── Logger gang ─────────────────────────────────────────────────────────────
DEBUG_LEVEL = 5  --  { "Silent", "Quiet", "Chatty", "Deep", "Trace" }
local _raw_print = print 
function log(level, ...)
	if level <= DEBUG_LEVEL then
		_raw_print(...)
	end
end

require('scripts.SunsDusk.localization')
require('scripts.SunsDusk.sd_helpers')


-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Job registries : add modules here			  						│
-- ╰────────────────────────────────────────────────────────────────────╯
--- FOR MODDING THIS MOD ---
local layerId = ui.layers.indexOf("HUD")
hudLayerSize = ui.layers[layerId].size
cellInfo = {fires = {}}
perHourJobs = {}
perMinuteJobs = {}
mousewheelJobs = {}
UiModeChangedJobs = {}
onLoadJobs = {}
G_refreshWidgetJobs = {}
G_removeBuffsJobs = {}
onFrameJobs = {}

onFrameJobsSluggish = {}
local onFrameJobsSluggishIterator = nil
local sluggishSchedulerAuto = {}
local sluggishSchedulerAutoIterator = 1
sluggishScheduler = {}
local sluggishSchedulerIterator = 1
local sluggishSchedulerSize = 0

sluggishScheduler = setmetatable({}, {
    __newindex = function(t, key, value)
        sluggishSchedulerSize = 0
		for _ in pairs(t) do
			sluggishSchedulerSize = sluggishSchedulerSize + 1
		end
		if not t[key] then
			sluggishSchedulerSize = sluggishSchedulerSize + 1
		end
		--print(sluggishSchedulerSize)
        rawset(t, key, value)
    end
})

for i=1,5 do
	sluggishScheduler[i] = {}
end

local jobTimings = {} -- [jobId] = {avgTime = 0.0001, lastRun = 0}
local jobTimingsMax = {} -- [jobId] = {avgTime = 0.0001, lastRun = 0}
local otherJobsAvg = 0.1

cellChangedJobs = {}
onConsumeJobs = {}
settingsChangedJobs = {}
onConsumedWaterJobs = {}
raycastResult = nil
raycastResultType = nil
raycastChangedJobs = {}
onPlayerInfoChangedJobs = {}
onCellInfoChangedJobs = {}
equipmentChangedJobs = {}
landedHitJobs = {}
G_destroyHudJobs = {}
landedSpellHitJobs = {}
eventHandlers  = {}
heartbeatFlags = {} --[moduleName] = volume
vignetteFlags = {} --[moduleName] = alpha
vignetteColorFlags = {} --[moduleName] = colorName (hot, cold, default/nil)
flashVignette = 0

equippedItems = nil
lastRaycastHitObject = nil
isInWater = 0
uiWidgets = {}

G_rowWidgets   = {}
G_columnWidgets    = {}
G_rowsNeedUpdate = false
G_columnsNeedUpdate = false


uiWidgets2 = {}
local isHeartbeatPlaying = false
local lastHeartbeatVolume = 0
local lastHeartbeatPlayed = 0
local nextHeartbeatFlash = math.huge
HEARTBEAT_INTERVAL = 1.0
G_heartbeatFlashing = 0

-- ─────────────────────────────────────────────────────────────────────────────── Libraries ───────────────────────────────────────────────────────────────────────────────


isSleeping = false
CLOCK_OFFSET = 0
local hasActivatedBed = false


-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Texture pack discovery (Before settings)							│
-- ╰────────────────────────────────────────────────────────────────────╯
require('scripts.SunsDusk.sd_loadTexturePacks')


-- ─────────────────────────────────────────────────────────────────────────────── UI ─────────────────────────────────────────────────────────────────────────────────────
-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Global Style														│
-- ╰────────────────────────────────────────────────────────────────────╯
-- Colors
morrowindGold 	= getColorFromGameSettings("fontColor_color_normal")
morrowindLight 	= getColorFromGameSettings("fontColor_color_normal_over")
goldenMix 		= mixColors(morrowindGold, morrowindLight)
goldenMix2 		= mixColors(morrowindLight, morrowindGold, 0.3)
lightText 		= util.color.rgb(morrowindLight.r^0.5,morrowindLight.g^0.5,morrowindLight.b^0.5)
morrowindBlue 	= getColorFromGameSettings("fontColor_color_journal_link")
morrowindBlue2 	= getColorFromGameSettings("fontColor_color_journal_link_over")
morrowindBlue3 	= getColorFromGameSettings("fontColor_color_journal_link_pressed")

-- Borders (template)

BORDER_STYLE = "thick" --"none", "thin", "normal", "thick", "verythick"
background = ui.texture { path = 'black' }
borderOffset = BORDER_STYLE == "verythick" and 4 or BORDER_STYLE == "thick" and 3 or BORDER_STYLE == "normal" and 2 or (BORDER_STYLE == "thin" or BORDER_STYLE == "max performance") and 1 or 0
borderFile = "thin"
if BORDER_STYLE == "verythick" or BORDER_STYLE == "thick" then
	borderFile = "thick"
end
windowTemplate = makeBorder(borderFile, util.color.rgb(0.5,0.5,0.5), borderOffset, {
	type = ui.TYPE.Image,
	props = {
		resource = ui.texture{ path = 'black' },
		relativeSize = v2(1,1),
		alpha = 0.8,
	}
}).borders

--button helper
makeButton = require("scripts.SunsDusk.ui_makeButton")

-- HUD
require('scripts.SunsDusk.sd_ui')


-- ─────────────────────────────────────────────────────────────────────────────── Settings ───────────────────────────────────────────────────────────────────────────────
require('scripts.SunsDusk.sd_settings')
I.Settings.registerPage({
	key = MODNAME,
	l10n = "none",
	name = "Sun's Dusk: Primary Needs",
	description = "",
})



local debugLevelNames = { "Silent", "Quiet", "Chatty", "Deep", "Trace" }

local function applyHiddenDifficultySettings(diff)
	if diff == "Default" then
		WAKEVALUE_MULT = 1
		FOODVALUE_MULT = 1
		DRINKVALUE_MULT = 1
	elseif diff == "Hard" then
		WAKEVALUE_MULT = 0.75
		FOODVALUE_MULT = 0.75
		DRINKVALUE_MULT = 0.75
	elseif diff == "Hardcore" then
		WAKEVALUE_MULT = 0.5
		FOODVALUE_MULT = 0.5
		DRINKVALUE_MULT = 0.5
	end
end

function readAllSettings()
	for _, template in pairs(settingsTemplate) do
		local settingsSection = storage.globalSection(template.key)
		for i, entry in pairs(template.settings) do
			_G[entry.key] = settingsSection:get(entry.key)
			if entry.key == "DIFFICULTY_PRESET" then
				applyHiddenDifficultySettings(settingsSection:get("DIFFICULTY_PRESET"))
			end
		end
	end
	for i, name in pairs(debugLevelNames) do
		DEBUG_LEVEL = i
		if name == DEBUG_LEVEL_NAME then
			break
		end
	end
end

readAllSettings()

-- ────────────────────────────────────────────────────────────────────────── Settings Event ──────────────────────────────────────────────────────────────────────────
for _, template in pairs(settingsTemplate) do
	local sectionName = template.key
	local settingsSection = storage.globalSection(template.key)
	settingsSection:subscribe(async:callback(function (_,setting)
		-- will be in local context:
		-- local sectionName = ... 
		-- local settingsSection = ...
		
		--print(sectionName.."\\"..setting.." changed to "..tostring(settingsSection:get(setting)))
		local oldValue = _G[setting]
		_G[setting] = settingsSection:get(setting)
		
		if setting == "DEBUG_LEVEL_NAME" then
			for i, name in pairs(debugLevelNames) do
				DEBUG_LEVEL = i
				if name == DEBUG_LEVEL_NAME then
					break
				end
			end
		end
		if setting == "DIFFICULTY_PRESET" then
			applyHiddenDifficultySettings(settingsSection:get("DIFFICULTY_PRESET"))
		end
		for _, func in pairs(settingsChangedJobs) do
			func(sectionName, setting, oldValue)
		end
		
		for _, func in pairs(G_refreshWidgetJobs) do
			func(minute)
		end
		G_updateSDHUD()
		--readAllSettings()
	end))
end



-- ────────────────────────────────────────────────────────────────────────── Consumables Database ────────────────────────────────────────────────────────────────────────

require('scripts.SunsDusk.spreadsheetParser') -- dbConsumables

-- ────────────────────────────────────────────────────────────────────────── Consumables Database ────────────────────────────────────────────────────────────────────────

--require('scripts.SunsDusk.module_sleep')
--require('scripts.SunsDusk.module_hunger')
for filename in vfs.pathsWithPrefix("scripts/SunsDusk/modules/module_") do
	if filename:match("%.lua$") then
		-- Remove .lua extension
		local require_path = filename:gsub("%.lua$", "")
		-- Replace forward slashes with dots
		require_path = require_path:gsub("/", ".")
		log(5, "[SD] Loaded "..require_path)
		require(require_path)
	end
end





-- ─────────────────────────────────────────────────────────────────────────────── on Update ────────────────────────────────────────────────────────────────────────────────
function updateHeartbeat(dt)
	-- Calculate maximum intensity from all flags
	local maxIntensity = 0
	
	for moduleName, intensity in pairs(heartbeatFlags) do
		maxIntensity = math.max(maxIntensity, intensity)
	end
	
	-- Only play if intensity > 0
	if maxIntensity > 0 then
		local currentTime = core.getRealTime()
		-- Check if enough time has passed since last heartbeat
		if G_heartbeatFlashing > 0 and currentTime > nextHeartbeatFlash then
			flashVignette = G_heartbeatFlashing
			nextHeartbeatFlash = math.huge
		end
		if currentTime - lastHeartbeatPlayed >= HEARTBEAT_INTERVAL then
			ambient.playSoundFile("sound/SunsDusk/Heartbeat1_by_Latzii.ogg", {
				volume = maxIntensity,
				loop = false,
				scale = false
			})
			lastHeartbeatPlayed = currentTime
			if G_heartbeatFlashing > 0 then
				nextHeartbeatFlash = currentTime + 0.4
			end
		end
	end
end
--table.insert(onFrameJobsSluggish, updateHeartbeat)
table.insert(sluggishScheduler[5], updateHeartbeat)
onFrameJobsSluggish.updateHeartbeat = updateHeartbeat

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Weather + rain sensing												│
-- ╰────────────────────────────────────────────────────────────────────╯



-- Optional one-time log
 if not G_WEATHER_API_AVAILABLE then
	 -- why: inform users on older OpenMW that rain hydration is disabled
	log(1, "[SunsDusk] Weather API not available (OpenMW < 0.50). Some features like Argonian rain hydration disabled.")
 end

-- Use feature detection + sky guard
-- Module-level variables
local weatherInfoIndex = 1
local weatherInfoUpdaters = {
	-- Rain check (RAYCAST + getCurrent)
	weatherRainCheck = function()
		local cell = self and self.cell
		if not cell or not cell.hasSky then 
			saveData.weatherInfo.isInRain = false
			return 
		end
		local w = saveData.weatherInfo.currentWeather
		if not w then
			saveData.weatherInfo.isInRain = false
			return
		end
		if isInWater >=0.9 then
			saveData.weatherInfo.isInRain = false
			return
		end
		local playerPos = self.position + v3(0,0,saveData.playerInfo.noseLevel)
		local skyPos = self.position + v3(0,0,1800)
		local ray = nearby.castRenderingRay(playerPos, skyPos, { collisionType = nearby.COLLISION_TYPE.AnyPhysical+nearby.COLLISION_TYPE.VisualOnly, ignore = self })
		if ray.hit then
			saveData.weatherInfo.isInRain = false
		elseif w.rainEffect ~= nil or (w.rainMaxRaindrops and w.rainMaxRaindrops > 0) then 
			saveData.weatherInfo.isInRain = true
		else
			saveData.weatherInfo.isInRain = false
		end
	end,
	
	-- Current weather + Storm status (bundled: both use getCurrent + stormDirection)
	weatherCurrentAndStorm = function()
		local cell = self and self.cell
		if not cell then return end
		local w = saveData.weatherInfo.currentWeather
		--saveData.weatherInfo.currentWeather = w
		saveData.weatherInfo.weatherName = w and w.name or "Unknown"
		if not w then
			saveData.weatherInfo.isStorm = nil
			saveData.weatherInfo.stormDirection = nil
			return
		end
		
		
		local stormDir = core.weather.getCurrentStormDirection(cell)
		--print(stormDir)
		if saveData.weatherInfo.weatherName == "Blight" then
			stormDir = v3(1,0,0)
		elseif not w.isStorm and stormDir and(math.abs(stormDir.x) < 0.01 or math.abs(stormDir.y - 1) < 0.01 or math.abs(stormDir.z) < 0.01) then
			stormDir = v3(0,1,0)
		end
		
		saveData.weatherInfo.stormDirection = stormDir
		
		-- Check if stormDirection deviates from default (0,1,0)
		local isActualStorm = (w and w.isStorm) or false
		if stormDir and not isActualStorm then
			-- If direction isn't (0,1,0), probably a storm even if isStorm is false
			if math.abs(stormDir.x) > 0.01 or math.abs(stormDir.y - 1) > 0.01 or math.abs(stormDir.z) > 0.01 then
				isActualStorm = true
			end
		end
		saveData.weatherInfo.isStorm = isActualStorm
	end,
	
	-- Shadow check (RAYCAST + sunLightDirection)
	weatherShadowCheck = function()
		local cell = self and self.cell
		if not cell or not cell.hasSky then 
			saveData.weatherInfo.isInShadow = true
			return 
		end
		
		local sunDir = core.weather.getCurrentSunLightDirection(cell)
		if not sunDir then 
			saveData.weatherInfo.isInShadow = 69
			saveData.weatherInfo.shadowLength = 999999
			return 
		end

		-- Shadow length = horizontal distance / vertical distance
		-- For 1-unit tall object
		local horizontal = math.sqrt(sunDir.x^2 + sunDir.y^2)
		saveData.weatherInfo.shadowLength = horizontal / math.abs(sunDir.z)
		
		sunDir = v3(sunDir.x, sunDir.y, sunDir.z)
		local playerPos
		if self.controls.sneak then
			playerPos = self.position + v3(0,0,40)
		else
			playerPos = self.position + v3(0,0,90)
		end
		local sunPos = playerPos + (sunDir * -1500)
		local ray = nearby.castRenderingRay(playerPos, sunPos, { collisionType = nearby.COLLISION_TYPE.AnyPhysical, ignore = self })
		
		saveData.weatherInfo.isInShadow = ray.hit
	end,
	
	-- Sun exposure (bundled: sunPercentage + sunVisibility)
	weatherSunExposure = function()
		local cell = self and self.cell
		if not cell then return end
		saveData.weatherInfo.sunPercentage = core.weather.getCurrentSunPercentage(cell)
		saveData.weatherInfo.sunVisibility = core.weather.getCurrentSunVisibility(cell)
		--saveData.weatherInfo.sunStrength = saveData.weatherInfo.isInShadow and 0 or (saveData.weatherInfo.sunPercentage or 0) * (saveData.weatherInfo.sunVisibility or 0) * math.min(1, 1/saveData.weatherInfo.shadowLength)
		saveData.weatherInfo.sunStrength = (saveData.weatherInfo.sunPercentage or 0) * (saveData.weatherInfo.sunVisibility or 0) * math.min(1, 1/saveData.weatherInfo.shadowLength)
	end,
	
	-- Wind cover check (RAYCAST + stormDirection)
	weatherWindCover = function()
		local cell = self and self.cell
		if not cell or not cell.hasSky then 
			saveData.weatherInfo.hasWindCover = nil
			return 
		end
		
		local windDir = saveData.weatherInfo.stormDirection or core.weather.getCurrentStormDirection(cell)
		if not windDir then 
			saveData.weatherInfo.hasWindCover = nil
			return 
		end
		
		-- Check if there's actual wind (direction deviates from default 0,1,0)
		local hasWind = saveData.weatherInfo.weatherName:lower():find("storm") or saveData.weatherInfo.isStorm or (math.abs(windDir.x) > 0.01 or math.abs(windDir.y - 1) > 0.01 or math.abs(windDir.z) > 0.01)
		
		-- If no wind, no need to check for cover
		if not hasWind then
			saveData.weatherInfo.hasWindCover = nil
			return
		end
		
		local playerPos
		local windSourcePos
		if self.controls.sneak then
			playerPos= self.position + v3(0,0,30)
			windSourcePos = playerPos + (windDir * -400) + v3(0,0,120)
		else
			playerPos= self.position + v3(0,0,80)
			windSourcePos = playerPos + (windDir * -400) + v3(0,0,180)
		end
		-- Raycast in direction wind is coming FROM (check for blocking wall/structure)
		local ray = nearby.castRay(playerPos, windSourcePos, { collisionType = nearby.COLLISION_TYPE.AnyPhysical, ignore = self })
		
		saveData.weatherInfo.hasWindCover = ray.hit
	end,
	
	-- Wind speed + Rain intensity (bundled: both use getCurrent)
	weatherRainintensity = function()
		local cell = self and self.cell
		saveData.weatherInfo.windSpeed = saveData.weatherInfo.windSpeed or  0
		saveData.weatherInfo.maxWindSpeed = 0
		saveData.weatherInfo.rainIntensity =  0
		saveData.weatherInfo.rainSpeed = 0
		
		if not cell or not cellInfo.isExterior then
			saveData.weatherInfo.windSpeed = 0
			return 
		end
		local w = saveData.weatherInfo.currentWeather
		if w then
			saveData.weatherInfo.windSpeed = saveData.weatherInfo.windSpeed * 0.95 + core.weather.getCurrentWindSpeed(cell) * 0.05
			local maxWindSpeed = w.windSpeed or 0
			if saveData.weatherInfo.windSpeed == 0 and saveData.weatherInfo.isStorm or saveData.weatherInfo.weatherName == "Blight" then
				saveData.weatherInfo.windSpeed = 10
				maxWindSpeed = 10
			end
			saveData.weatherInfo.maxWindSpeed = maxWindSpeed
			saveData.weatherInfo.rainIntensity = w.rainMaxRaindrops or 0
			saveData.weatherInfo.rainSpeed = w.rainSpeed or 0
		end
	end,
	
	---- Glare (affects visibility/eye strain)
	--function(self)
	--	local cell = self and self.cell
	--	if not cell then return end
	--	local w = saveData.weatherInfo.currentWeather
	--	saveData.weatherInfo.glareView = w and w.glareView or 0
	--end,
	
	-- Weather transition (bundled: getTransition + getNext)
	weatherTransition = function()
		local cell = self and self.cell
		if not cell then return end
		saveData.weatherInfo.transition = core.weather.getTransition(cell)
		saveData.weatherInfo.nextWeather = core.weather.getNext(cell)
		if saveData.weatherInfo.nextWeather and (saveData.weatherInfo.transition or 0) < 0.5 then
			saveData.weatherInfo.currentWeather = saveData.weatherInfo.nextWeather
		else
			saveData.weatherInfo.currentWeather = core.weather.getCurrent(cell)
		end
	end,
	weatherUi = function()
		if weatherDbg then
			weatherDbg.display(saveData.weatherInfo)
		end
	end,
}

local function refreshAllWeatherInfoOnFrame()
	if G_WEATHER_API_AVAILABLE then
		for weatherInfoIndex in pairs(weatherInfoUpdaters) do
			weatherInfoUpdaters[weatherInfoIndex](self)
		end
	end
	onFrameJobs["refreshAllWeatherInfoOnFrame"] = nil
end

local function refreshAllWeatherInfo()
	saveData.weatherInfo.isInRain = false
	saveData.weatherInfo.isInShadow = false
	saveData.weatherInfo.shadowLength = 0
	saveData.weatherInfo.hasWindCover = nil
	--saveData.weatherInfo.currentWeather = nil
	saveData.weatherInfo.weatherName = "Unknown"
	saveData.weatherInfo.isStorm = false
	saveData.weatherInfo.stormDirection = nil
	saveData.weatherInfo.sunPercentage = 0
	saveData.weatherInfo.sunStrength = 0
	saveData.weatherInfo.sunVisibility = 0
	saveData.weatherInfo.windSpeed = 0
	saveData.weatherInfo.maxWindSpeed = 0
	saveData.weatherInfo.rainIntensity = 0
	saveData.weatherInfo.rainSpeed = 0
	saveData.weatherInfo.transition = 0
	saveData.weatherInfo.nextWeather = nil
	saveData.weatherInfo.currentWeather = nil
	onFrameJobs["refreshAllWeatherInfoOnFrame"] = refreshAllWeatherInfoOnFrame
	
end

--local function refreshWeatherInfo()
--	if weatherInfoUpdaters[weatherInfoIndex] then
--		weatherInfoUpdaters[weatherInfoIndex](self)
--	end
--	--debugWidget.update(saveData.weatherInfo)
--	-- Cycle to next updater
--	weatherInfoIndex = weatherInfoIndex + 1
--	if weatherInfoIndex > #weatherInfoUpdaters then
--		if weatherDbg then
--			weatherDbg.display(saveData.weatherInfo)
--		end
--		weatherInfoIndex = 1
--	end
--end

if G_WEATHER_API_AVAILABLE then
	for jobId, job in pairs(weatherInfoUpdaters) do
		--table.insert(onFrameJobsSluggish, job)
		onFrameJobsSluggish[jobId] = job
	end
	table.insert(sluggishScheduler, {weatherInfoUpdaters.weatherShadowCheck, weatherInfoUpdaters.weatherWindCover, weatherInfoUpdaters.weatherTransition})
	table.insert(sluggishScheduler, {weatherInfoUpdaters.weatherRainintensity, weatherInfoUpdaters.weatherRainCheck, weatherInfoUpdaters.weatherCurrentAndStorm, weatherInfoUpdaters.weatherSunExposure })
	table.insert(sluggishScheduler[4], weatherInfoUpdaters.weatherUi)
	--table.insert(onFrameJobsSluggish, refreshWeatherInfo)
end
-- ╭────────────────────────────────────────────────────────────────────╮
-- │ In water											  				│
-- ╰────────────────────────────────────────────────────────────────────╯
local function inWaterCheck()
   	if not self.cell then
		isInWater = 0
		return
	end
	local waterLevel = self.cell.waterLevel or -99999999
	isInWater = math.max(0,math.min(1, (-self.position.z+waterLevel)/saveData.playerInfo.noseLevel))
	--print(isInWater.." in water")
end
--table.insert(onFrameJobsSluggish, inWaterCheck)
table.insert(sluggishScheduler[4], inWaterCheck)
onFrameJobsSluggish.inWaterCheck = inWaterCheck

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Equipment changes									  				│
-- ╰────────────────────────────────────────────────────────────────────╯
local function equipCheck()
	-- equippedItems = {slot = item} -- fed externally by event
	local unequippedItems = {}
	local anythingUnequipped = false
	local currentEquipment = types.Actor.getEquipment(self)
	if previouslyEquippedItems then
		for slot, item in pairs(previouslyEquippedItems) do
			if not currentEquipment[slot] or equippedItems and equippedItems[slot] then
				unequippedItems[slot] = item
				anythingUnequipped = true
			end
		end
	end
	if equippedItems or anythingUnequipped then
		for _, func in pairs(equipmentChangedJobs) do
			func(unequippedItems, equippedItems or {})
		end
	end
	previouslyEquippedItems = currentEquipment
	equippedItems = nil

end
--table.insert(onFrameJobsSluggish, equipCheck)
table.insert(sluggishScheduler[3], equipCheck)
onFrameJobsSluggish.equipCheck = equipCheck

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Night Creature checks												│
-- ╰────────────────────────────────────────────────────────────────────╯
local function isInWerewolfFormCheck()
	local newWerewolf = types.NPC.isWerewolf(self)
	if saveData.playerInfo.isInWerewolfForm ~= newWerewolf then
		saveData.playerInfo.isInWerewolfForm = newWerewolf
		for _, func in pairs(onPlayerInfoChangedJobs) do
			func("isInWerewolfForm")
		end
	end
end
table.insert(perMinuteJobs, isInWerewolfFormCheck)

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Main logic loop													│
-- ╰────────────────────────────────────────────────────────────────────╯
function mainLogic()
	local gameTime = calendar.gameTime()
	--minute steps since last update
	local tempCurrentMinute = math.floor(gameTime / time.minute)
	local minutesPassed = tempCurrentMinute - saveData.lastUpdate
	
	
	--hour steps since last update
	local tempCurrentHour = math.floor(gameTime / time.hour)
	local lastHourProcessed = saveData.lastHourProcessed or math.floor(saveData.lastUpdate/60)
	
	for hour=lastHourProcessed+1, tempCurrentHour do
		
		local clockHour = (hour+CLOCK_OFFSET)%24
		if clockHour == 0 then 
			clockHour = 24
		end
		--call all perMinuteJobs once per hour during time skips
		for _, func in pairs(perHourJobs) do
			func(clockHour)
		end
		saveData.lastHourProcessed = hour  -- Track hour progress separately
		
		if minutesPassed >= 60 then
			local tempMinute = hour * 60 + tempCurrentMinute%60
			for _, func in pairs(perMinuteJobs) do
				func(clockHour, tempMinute, 60)
			end
			perMinuteJobIterator = nil
			saveData.lastUpdate = tempCurrentMinute
		end
	end
	
	-- if no hours passed, do load balanced perMinuteJobs (one per frame)
	if minutesPassed < 60 and minutesPassed > 0 then
		local clockHour = math.floor((tempCurrentMinute / 60 + CLOCK_OFFSET))%24
		if clockHour == 0 then 
			clockHour = 24
		end
		
		-- get next function using pairs iterator
		local func
		perMinuteJobIterator, func = next(perMinuteJobs, perMinuteJobIterator)
		if perMinuteJobIterator then
			func(clockHour, tempCurrentMinute, minutesPassed)
		else
			saveData.lastUpdate = tempCurrentMinute
		end
	end
end

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Consumption events													│
-- ╰────────────────────────────────────────────────────────────────────╯
local function onConsume(item)
	for _, func in pairs(onConsumeJobs) do
		func(item)
	end	
end

local function onConsumedWater(liquid)
	local remainingWater = 1
	for _, func in pairs(onConsumedWaterJobs) do
		remainingWater = func(liquid, remainingWater) or remainingWater
	end	
end

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Frame + update drivers												│
-- ╰────────────────────────────────────────────────────────────────────╯
local function onUpdate(dt)

end


function rebalancesluggishSchedulerAuto()
    -- Collect all job keys
    local jobKeys = {}
    for key, _ in pairs(onFrameJobsSluggish) do
        table.insert(jobKeys, key)
    end
    sluggishSchedulerAutoIndexCounter = #jobKeys
    
    -- Calculate number of groups (sluggishSchedulerAutoIndexCounter / 5)
    local numGroups = math.max(1, math.ceil(sluggishSchedulerAutoIndexCounter / 2))
    
    -- Reset scheduler
    sluggishSchedulerAuto = {}
    for i = 1, numGroups do
        sluggishSchedulerAuto[i] = {}
    end
    
    if sluggishSchedulerAutoIndexCounter == 0 then
        return
    end
    
    -- Create array of jobs with their keys and timings
    local jobsWithTimings = {}
    for i = 1, #jobKeys do
        local key = jobKeys[i]
        jobsWithTimings[i] = {
            key = key,
            timing = ((jobTimings[key] or 0) + (jobTimingsMax[key] or 0)) / 2
        }
    end
    
    -- Sort jobs by execution time (descending - longest first)
    table.sort(jobsWithTimings, function(a, b)
        return a.timing > b.timing
    end)
    
    -- Track load per group
    local groupLoads = {}
    for i = 1, numGroups do
        groupLoads[i] = 0
    end
    
    -- Distribute jobs using greedy bin-packing (assign each job to least loaded group)
    for i = 1, #jobsWithTimings do
        local job = jobsWithTimings[i]
        
        -- Find group with minimum load
        local minLoad = groupLoads[1]
        local minGroupIndex = 1
        for g = 2, numGroups do
            if groupLoads[g] < minLoad then
                minLoad = groupLoads[g]
                minGroupIndex = g
            end
        end
        
        -- Assign job to this group
        table.insert(sluggishSchedulerAuto[minGroupIndex], job.key)
        groupLoads[minGroupIndex] = groupLoads[minGroupIndex] + job.timing
    end
end


local function onFrame(dt)
	if not successfulInitialized then return end
	local currentPerfHit = core.getRealTime()
	mainLogic()
	if self.cell then
		--print(self.cell)
		if not currentCell then
			currentCell = self.cell
		elseif self.cell ~=currentCell then
			for _, func in pairs(cellChangedJobs) do
				func(currentCell) -- LAST CELL arg
			end
			currentCell = self.cell
			core.sendGlobalEvent("SunsDusk_getCellInfo", self)
		end
	end
	
	
	for _, func in pairs(onFrameJobs) do
		func(dt)
	end
	currentPerfHit = core.getRealTime()-currentPerfHit
	otherJobsAvg = otherJobsAvg * 0.9 + currentPerfHit * 0.1
	if currentPerfHit < otherJobsAvg then
		
		
		
	---- one per frame:
	--	local currentJob
	--	onFrameJobsSluggishIterator, currentJob = next(onFrameJobsSluggish, onFrameJobsSluggishIterator)
	--	if not onFrameJobsSluggishIterator then
	--		onFrameJobsSluggishIterator, currentJob = next(onFrameJobsSluggish)
	--	end
	--	currentJob()
	----	print(onFrameJobsSluggishIterator)
	----	print("+")
	
	---- hybrid (fixed timings):
	--	for _, job in pairs(sluggishScheduler[sluggishSchedulerIterator]) do
	--		job()
	--	end
	--	sluggishSchedulerIterator = sluggishSchedulerIterator + 1
	--	if sluggishSchedulerIterator > sluggishSchedulerSize then
	--		sluggishSchedulerIterator = 1
	--	end
	
	
	---- auto balancing:
		local numGroups = math.ceil(sluggishSchedulerAutoIndexCounter / 2)
		
		-- Get current group to execute
		local currentGroup = sluggishSchedulerAuto[sluggishSchedulerAutoIterator]
	
		--print("group",sluggishSchedulerAutoIterator)
		-- Execute all jobs in current group
		for i = 1, #currentGroup do
			local jobKey = currentGroup[i]
			local job = onFrameJobsSluggish[jobKey]
			
			if job then
				-- Time the job execution
				local startTime = core.getRealTime()
				job()
				local endTime = core.getRealTime()
				local executionTime = endTime - startTime
				
				-- Update running average for this job
				if dt > 0 then
					if jobTimings[jobKey] then
						jobTimings[jobKey] =jobTimings[jobKey] * (1 - 0.05) + executionTime * 0.05
						jobTimingsMax[jobKey] = math.max(executionTime, jobTimingsMax[jobKey]*0.98)
					else
						jobTimings[jobKey] = executionTime
						jobTimingsMax[jobKey] = executionTime
					end
					--print(pad_string(jobKey,25," ")..string.format("%.4f ms / %.4f ms  / %.4f ms ",executionTime*1000,jobTimings[jobKey]*1000,jobTimingsMax[jobKey]*1000))
				end
			end
		end
		
		-- Move to next group (round-robin)
		sluggishSchedulerAutoIterator = sluggishSchedulerAutoIterator + 1
		if sluggishSchedulerAutoIterator > numGroups then
		    sluggishSchedulerAutoIterator = 1
			if math.random() < 0.1 then
				local startTime = core.getRealTime()
				rebalancesluggishSchedulerAuto()
				local endTime = core.getRealTime()
				local executionTime = endTime - startTime
				--print(string.format("rebalancing: %.4f ms",executionTime))
			end
		end
	--	
	--
	--	print("+")
	--else
	--	print("-")
	end
	
	local cameraPos = camera.getPosition()
	local iMaxActivateDist = core.getGMST("iMaxActivateDist")+0.1
	local activationDistance = iMaxActivateDist + camera.getThirdPersonDistance()
	local telekinesis = types.Actor.activeEffects(self):getEffect(core.magic.EFFECT_TYPE.Telekinesis)
	if telekinesis then
		activationDistance = activationDistance + telekinesis.magnitude * 22
	end
	raycastResult = nearby.castRenderingRay(
		cameraPos,
		cameraPos + getCameraVector() * activationDistance,
		{ ignore = self }
	)
	if raycastResult.hitObject ~= lastRaycastHitObject then
		if raycastResult.hitObject then
			raycastResultType = tostring(raycastResult.hitObject.type)
		else
			raycastResultType = nil
		end
		for _, func in pairs(raycastChangedJobs) do
			func()
		end
		lastRaycastHitObject = raycastResult.hitObject
	end
	--camera.setMode(camera.MODE.FirstPerson, true)
end

local function onMouseWheel(direction)
	for _, func in pairs(mousewheelJobs) do
		func(direction)
	end
end



-- ──────────────────────────────────────────────────────────────────────────── Event Handlers ────────────────────────────────────────────────────────────────────────────

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Combat mechanics													│
-- ╰────────────────────────────────────────────────────────────────────╯
local function landedHit(data)
	local target = data[1]
	local attack = data[2]
	for _, func in pairs(landedHitJobs) do
		func(target, attack)
	end
end

local function landedSpellHit(data)
	local target = data[1]
	local activeSpellId = data[2]
	local foundSpell
	for i, spell in pairs(types.Actor.activeSpells(target)) do
		if spell.activeSpellId == activeSpellId then
			foundSpell = spell
		end
	end
	if foundSpell then
		for _, func in pairs(landedSpellHitJobs) do
			func(target, foundSpell)
		end
	end
end

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ UI mode flow · sleep begins and ends here							│
-- ╰────────────────────────────────────────────────────────────────────╯
local function UiModeChanged(data)
	if not successfulInitialized then return end
	local newCell = self.cell
	if lastUiModeCell then
		if lastUiModeCell ~= newCell then
			isTravelling = true
		else
			isTravelling = nil
		end
	end
	lastUiModeCell = newCell
	log(4, "ui mode "..tostring(data.oldMode).." -> " .. tostring(data.newMode), data.arg)
	-- actual sleeping logic
	if data.newMode == "Jail" then
		isInJail = true
	end
	if data.newMode == "Rest" and (data.arg or hasActivatedBed or not self.cell:hasTag("NoSleep")) and not saveData.playerInfo.isInWerewolfForm then
		G_preventAddingAnyBuffs = true
		for _, job in pairs(G_removeBuffsJobs) do
			job()
		end
		log(3,"[SD] start sleep")
		isSleeping = true
		hasActivatedBed = false
		currentBed = data.arg
	end
	mainLogic()
	if data.newMode == nil then --can happen when traveling (fixed for singleplayer)
		if isSleeping then
			log(3,"[SD] end sleep")
			isSleeping = false
			G_preventAddingAnyBuffs = false
			core.sendGlobalEvent("SunsDusk_checkIfVampireWerewolf", self)
		end
		currentBed = nil
		isInJail = nil
		hasActivatedBed = false
		lastUiModeCell = nil
	end
	for _, func in pairs(UiModeChangedJobs) do
		func(data)
	end
	if data.oldMode == "ChargenRace" then
		refreshPlayerInfo()
	end
end

local function activatedBed(bed)
	log(5,"[SD] activated bed")
	hasActivatedBed = true
end

local function NSS_preventedSleeping(bed)
	log(5,"[SD] prevented bed by daisy's mod")
	hasActivatedBed = false
end

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Companion counters													│
-- ╰────────────────────────────────────────────────────────────────────╯
local function releasedCompanion(actor)
	saveData.companions[actor.id] = nil
	local count = 0
	saveData.specialCompanion = false
	for i,actor in pairs(saveData.companions) do
		if actor:isValid() then
			if actor.recordId == "your love" then
				saveData.specialCompanion = true
			end
			count = count + 1
		else
			saveData.companions[i] = nil
		end
	end
	saveData.countCompanions = count
end

local function becameCompanion(actor)
	saveData.companions[actor.id] = actor
	local count = 0
	saveData.specialCompanion = false
	for i,actor in pairs(saveData.companions) do
		if actor:isValid() then
			if actor.recordId == "your love" then
				saveData.specialCompanion = true
			end
			count = count + 1
		else
			saveData.companions[i] = nil
		end
	end
	saveData.countCompanions = count	
end

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Misc helpers														│
-- ╰────────────────────────────────────────────────────────────────────╯
local function messageBox(str)
	ui.showMessage(str)
end


-- ─────────────────────────────────────────────────────────────────────────────── LifeCycle ───────────────────────────────────────────────────────────────────────────────

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Player info refresh + races, forms, flags							│
-- ╰────────────────────────────────────────────────────────────────────╯
-- onInit and on uiModeChange from ChargenRace

function refreshPlayerInfo()
	local npcRecord = types.NPC.record(self)
	local raceId = npcRecord.race -- record id key
	local raceRec = types.NPC.races.records[raceId]
	local name = tostring(raceId):lower()
	if not saveData.playerInfo then
		saveData.playerInfo = {}
	end
	
	local classId = npcRecord.class
	local classRecord = types.NPC.classes.records[classId]
	
	saveData.playerInfo.majorSkills = {}
	saveData.playerInfo.minorSkills = {}
	for _, skillId in ipairs(classRecord.majorSkills) do
		saveData.playerInfo.majorSkills[skillId] = true
	end
	for _, skillId in ipairs(classRecord.minorSkills) do
		saveData.playerInfo.minorSkills[skillId] = true
	end
	saveData.playerInfo.specialization = classRecord.specialization
	
	
	if npcRecord then
		if npcRecord.isMale then
			saveData.playerInfo.noseLevel = raceRec.height.male*147.79
		else
			saveData.playerInfo.noseLevel = raceRec.height.female*147.79
		end
	end
	
	local beastRaces = {
		["tsaesci"] = true,
		["chimeri-quey"] = true,
		["keptu-quey"] = true,
		["suthay-raht"] = true,
		["cathay-raht"] = true,
		["dagi-raht"] = true,
		["ohmes-raht"] = true,
	}

	local altmerRaces = {
		["ayleid"] = true,
	}
	
	local dunmerRaces = {
		["sea elf"] = true,
		["dark elf"] = true,
	}
	
	local bretonRaces = {
		["reachman"] = true,
	}
	
	local nordRaces = {
		["reachman"] = true,
	}
	
	local redguardRaces = {
		["duadri"] = true,
	}

--	redguard	Redguard
--	dark elf	Dark Elf
--	imperial	Imperial
--	breton	Breton
--	nord	Nord
--	wood elf	Wood Elf
--	high elf	Elf
--	khajiit	Khajiit
--	argonian	Argonian
--	orc	Orc
--	t_aka_tsaesci	Tsaesci
--	t_cnq_chimeriquey	Chimeri-Quey
--	t_cnq_keptu	Keptu-Quey
--	t_cyr_ayleid	Ayleid
--	t_els_cathay	Khajiit
--	t_els_cathay-raht	Khajiit
--	t_els_dagi-raht	Khajiit
--	t_els_ohmes	Khajiit
--	t_els_ohmes-raht	Khajiit
--	t_els_suthay	Khajiit
--	t_hr_ogre	Ogre
--	t_hr_riverfolk	Riverfolk
--	t_mw_malahk_orc	Malahk Orc
--	t_pya_seaelf	Sea Elf
--	t_sky_hill_giant	Hill Giant
--	t_sky_reachman	Reachman
--	t_val_imga	Imga
--	t_yne_ynesai	Ynesai
--	t_yok_duadri	Duadri
--	un_skeleton_race	Skeleton
--	un_lich_skull_race	Lich Skull
--	un_haunt_race	Haunt
--	un_ghost_race	Ghost
--	senche-raht	Suthay-Raht
--	cathay-raht	Cathay-Raht
--	dagi-raht	Dagi-Raht
--	war_ohmes	Ohmes-Raht
	saveData.playerInfo.isBeast = beastRaces[name] or raceRec and raceRec.isBeast or name:find("khajiit")
	saveData.playerInfo.isOrc = name:find("orc", 1, true) ~= nil
	saveData.playerInfo.isNord = nordRaces[name] or name:find("nord", 1, true) ~= nil
	saveData.playerInfo.isBreton = bretonRaces[name] or name:find("breton", 1, true)
	saveData.playerInfo.isBosmer = name:find("bosmer", 1, true) ~= nil or name:find("wood elf", 1, true) ~= nil
	saveData.playerInfo.isAltmer = altmerRaces[name] or name:find("altmer", 1, true) ~= nil or name:find("high elf", 1, true) ~= nil 
	saveData.playerInfo.isImperial = name:find("imperial", 1, true) ~= nil
	saveData.playerInfo.isDunmer = dunmerRaces[name] or name:find("dunmer", 1, true) ~= nil
	saveData.playerInfo.isRedguard = redguardRaces[name] or name:find("redguard", 1, true) ~= nil
	saveData.playerInfo.isFarmingTool = name:find("argonian", 1, true) ~= nil
	saveData.playerInfo.isInWerewolfForm = types.NPC.isWerewolf(self) -- isInWerewolfFormCheck()
	
	for a,b in pairs(saveData.playerInfo) do
		log(4,a,b)
	end
	
	if not saveData.playerInfo.isVampire then -- = ON INIT
		saveData.playerInfo.isVampire = 0
		saveData.playerInfo.isWerewolf = 0
		core.sendGlobalEvent("SunsDusk_checkIfVampireWerewolf", self)
		for _, func in pairs(onPlayerInfoChangedJobs) do
			func("init")
		end
	else
		for _, func in pairs(onPlayerInfoChangedJobs) do
			func("chargen")
		end
	end
end

local function checkedIfVampireWerewolf(values)
	local infosChanged = false
	values[1] = values[1] or 0
	values[2] = values[2] or 0
	if saveData.playerInfo.isVampire ~= values[1] then
		saveData.playerInfo.isVampire = values[1]
		print("[SD] Vampire status changed to", values[1])
		infosChanged = "isVampire"
	end
	if saveData.playerInfo.isWerewolf ~= values[2] then
		saveData.playerInfo.isWerewolf = values[2]
		print("[SD] Werewolf status changed to", values[2])
		infosChanged = "isWerewolf"
	end
	if infosChanged then
		for _, func in pairs(onPlayerInfoChangedJobs) do
			func(infosChanged)
		end
	end
end

local function receiveCellInfo(data)
	cellInfo = data
--[[{
		isExterior = false,
		isIceCave = false,
		isCave = false,
		isDwemer = false,
		isDaedric = false,
		isMine = false,
		isTomb = false
		isHouse = false,
		isCastle = false
		isExterior = false,
		isMushroom = false,
		fires = {}
	}
]]
	for _, func in pairs(onCellInfoChangedJobs) do
		func()
	end
end


local allSunsDuskBuffs = {"sd_h_sp_cannibal",
"sd_h_sp_corprus",
"sd_h_sp_fasting",
"sd_h_sp_foodpoisoning",
"sd_h_sp_foodpoisoning_2",
"sd_h_sp_foodpoisoning_3",
"sd_h_sp_foodpoisoning_c",
"sd_h_sp_greenpact",
"sd_h_sp_greenpact_2",
"sd_h_sp_varied",
"sd_hunger_0",
"sd_hunger_0_c",
"sd_hunger_1",
"sd_hunger_1_c",
"sd_hunger_2",
"sd_hunger_2_c",
"sd_hunger_3",
"sd_hunger_3_2",
"sd_hunger_3_3",
"sd_hunger_3_c",
"sd_hunger_4",
"sd_hunger_4_2",
"sd_hunger_4_3",
"sd_hunger_4_c",
"sd_hunger_5",
"sd_hunger_5_2",
"sd_hunger_5_3",
"sd_hunger_5_c",
"sd_t_sp_insomniac",
"sd_t_sp_morninglark",
"sd_t_sp_nightowl",
"sd_temp_0",
"sd_temp_1",
"sd_temp_2",
"sd_temp_3",
"sd_temp_4",
"sd_temp_5",
"sd_temp_6",
"sd_thirst_0",
"sd_thirst_0_c",
"sd_thirst_1",
"sd_thirst_1_c",
"sd_thirst_2",
"sd_thirst_2_c",
"sd_thirst_3",
"sd_thirst_3_2",
"sd_thirst_3_3",
"sd_thirst_3_c",
"sd_thirst_4",
"sd_thirst_4_2",
"sd_thirst_4_3",
"sd_thirst_4_c",
"sd_thirst_5",
"sd_thirst_5_2",
"sd_thirst_5_3",
"sd_thirst_5_c",
"sd_tiredness_0",
"sd_tiredness_0_c",
"sd_tiredness_1",
"sd_tiredness_1_c",
"sd_tiredness_2",
"sd_tiredness_2_c",
"sd_tiredness_3",
"sd_tiredness_3_2",
"sd_tiredness_3_3",
"sd_tiredness_3_c",
"sd_tiredness_4",
"sd_tiredness_4_2",
"sd_tiredness_4_3",
"sd_tiredness_4_c",
"sd_tiredness_5",
"sd_tiredness_5_2",
"sd_tiredness_5_3",
"sd_tiredness_5_c",
"sd_temp_sp_fire_slow",
"sd_temp_sp_frost_slow",
"sd_wet_1",
"sd_wet_2",
"sd_wet_3",
"sd_wet_4",
"sd_wet_5",
"sd_hearthfire_1",
"sd_hearthfire_2",
"sd_hearthfire_3",
"sd_hearthfire_4",
}


-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Save/load + external API											│
-- ╰────────────────────────────────────────────────────────────────────╯
local function onLoad(data)
	local eventName = data and "onLoad" or "onInit"
	for _, buff in pairs(allSunsDuskBuffs) do
		if not core.magic.spells.records[buff] then
			error(buff.." doesn't exist, make sure the omwaddon is installed correctly")
		end
	end
	if eventName == "onInit" then
		for _, buff in pairs(allSunsDuskBuffs) do
			typesActorSpellsSelf:remove(buff)
		end
	end
	saveData = data or {
		--specialCompanion = nil,
		--m_sleep = {},  -- defined in module
		--m_hunger = {}, -- defined in module
		--m_thirst = {}, -- defined in module
		version = 7,
		
		--companions = {}
		--countCompanions = 0
		--lastUpdate = math.floor(calendar.gameTime()/time.minute)
		--lastHourProcessed = math.floor(saveData.lastUpdate/60)
		--registeredConsumables = {}
		--chargenFinished = chargenFinished()
		--cellInfo = {}
		--playerInfo = {}
		--weatherInfo = {}
		
	}
	if not saveData.playerInfo then
		refreshPlayerInfo()
	end
	--migration from old save: (remove in final release)
	if not saveData.companions then
		saveData.companions = {}
	end
	if not saveData.countCompanions then
		saveData.countCompanions = 0
	end
	if not saveData.lastUpdate then
		saveData.lastUpdate = math.floor(calendar.gameTime()/time.minute)
	end
	if not saveData.lastHourProcessed then
		saveData.lastHourProcessed = math.floor(saveData.lastUpdate/60)
	end
	if not saveData.registeredConsumables then
		saveData.registeredConsumables = {}
	end
	if not saveData.chargenFinished then
		saveData.chargenFinished = chargenFinished()
	end
	cellInfo = {fires = {}}
	if self.cell then
		core.sendGlobalEvent("SunsDusk_getCellInfo", self)
	end
	
	if not saveData.playerInfo then
		saveData.playerInfo = {}
	end
	if not saveData.weatherInfo then
		saveData.weatherInfo = {}
		refreshAllWeatherInfo()
	end
	if not saveData.weatherInfo.sunStrength then
		saveData.weatherInfo.sunStrength = 0
	end
	if not saveData.lastPosition then
		saveData.lastPosition = self.position
		saveData.lastPositionTime = core.getSimulationTime()
	end
	
	
	if not saveData.version then
		saveData.version = 2
	end
	if saveData.version < 3 then
		for i, data in pairs(saveData.registeredConsumables) do
			if data.longLasting then
				data.foodValue2 = data.foodValue/5
				data.drinkValue2 = data.drinkValue/5
				data.wakeValue2 = data.wakeValue/5
				data.longLasting = nil
			end
		end
		saveData.version = 3
	end
	if saveData.version < 8 then
		refreshPlayerInfo()
		saveData.version = 8
	end
	saveData.cellInfo = nil
	--/migration
	
	-- calc clock offset
	local gameTime = calendar.gameTime()
	local tempCurrentHour = math.floor(gameTime / time.hour)%24
	local clockHour = tonumber(calendar.formatGameTime("%H", calendar.gameTime()))
	CLOCK_OFFSET = tempCurrentHour - clockHour
	if CLOCK_OFFSET > 12 then
		CLOCK_OFFSET = CLOCK_OFFSET -24
	elseif CLOCK_OFFSET < -12 then
		CLOCK_OFFSET = CLOCK_OFFSET +24
	end
	
	for _, func in pairs(onLoadJobs) do
		func(eventName)
	end
	
	successfulInitialized = true
	rebalancesluggishSchedulerAuto()
end

local function onSave()
	if not successfulInitialized and not saveData then return end
	saveData.weatherInfo.nextWeather = nil
	saveData.weatherInfo.currentWeather = nil
	
	return saveData
end

local function API_addConsumable(id, tbl)
	saveData.registeredConsumables[id] = tbl
end

local function event_addConsumable(data)
	local id = data[1]
	local tbl = data[2]
	saveData.registeredConsumables[id] = tbl
end

local function playSound(sound)
	ambient.playSound(sound)
end

local function equippedArmor(armor)
	local slot = getEquipmentSlot(armor)
	if not slot then
		error("Equipping failed, couldn't determine equipment slot for "..tostring(armor))
	end
	equippedItems = equippedItems or {}
	equippedItems[slot] = armor
end

local function registeredFire(fire)
	log(3,"registered",fire)
	table.insert(cellInfo.fires, fire)
end

local function onConsoleCommand(command, str)
    -- Handle "lua coords" - print current position
    if str:match("^lua coords") then
        local pos = self.position
        local coordString = string.format("util.vector3(%.1f, %.1f, %.1f),", pos.x, pos.y, pos.z)
        ui.printToConsole(coordString, ui.CONSOLE_COLOR.Success)
        return
    end
    
    -- Handle "lua tp" - teleport to position
    if str:match("^lua tp") then
        local x, y, z = str:match("util%.vector3%(([%d%.%-]+),%s*([%d%.%-]+),%s*([%d%.%-]+)%)")
        local position = util.vector3(tonumber(x), tonumber(y), tonumber(z))
        ui.printToConsole("tp", ui.CONSOLE_COLOR.Success)
        core.sendGlobalEvent("PMM_loadLoc", {self, {gridX = 0, gridY = 0, position = position}})
        return
    end
end

-- onFrameJobs["CheckIfLightHotkeyIsInstalled"] = function()
-- 	if input.actions['LightHotkey'] then
-- 		input.registerActionHandler('LightHotkey', async:callback(function()
-- 			equippedItems = equippedItems or {}
-- 			equippedItems[types.Actor.EQUIPMENT_SLOT.CarriedLeft] = types.Actor.getEquipment(self, types.Actor.EQUIPMENT_SLOT.CarriedLeft) 
-- 		end))
-- 	end
-- 	onFrameJobs["CheckIfTorchHotkeyIsInstalled"] = nil
-- end

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Event handlers														│
-- ╰────────────────────────────────────────────────────────────────────╯
eventHandlers.UiModeChanged = UiModeChanged
eventHandlers.SunsDusk_ActivatedBed = activatedBed
eventHandlers.NSS_showMessage = NSS_preventedSleeping
eventHandlers.SunsDusk_RegisterCompanion = becameCompanion
eventHandlers.SunsDusk_ReleaseCompanion = releasedCompanion
eventHandlers.SunsDusk_WaterBottles_consumedWater = onConsumedWater
eventHandlers.SunsDusk_messageBox = messageBox
eventHandlers.SunsDusk_landedHit = landedHit
eventHandlers.SunsDusk_landedSpellHit = landedSpellHit
eventHandlers.SunsDusk_checkedIfVampireWerewolf = checkedIfVampireWerewolf
eventHandlers.SunsDusk_addConsumable = event_addConsumable
eventHandlers.SunsDusk_receiveCellInfo = receiveCellInfo
eventHandlers.SunsDusk_playSound = playSound
eventHandlers.SunsDusk_equippedArmor = equippedArmor
eventHandlers.SunsDusk_registerFire = registeredFire

--local function onKeyPress(key)
--    if key.symbol == "u" then
--		G_forceSquareFalloff = not G_forceSquareFalloff
--		ui.showMessage("Force Square "..(G_forceSquareFalloff and "ON" or "OFF"))
--    end
--end

return {
	engineHandlers = {
		onUpdate = onUpdate,
		onFrame = onFrame,
		onInit = onLoad,
		onLoad = onLoad,
		onSave = onSave,
		onMouseWheel = onMouseWheel,
		onConsume = onConsume,	
		onConsoleCommand = onConsoleCommand,
		onKeyPress = onKeyPress,
	},
	eventHandlers = eventHandlers,
	interfaceName = "SunsDusk",
	interface = {
		version = 1,
		addConsumable = API_addConsumable,
	}
}
