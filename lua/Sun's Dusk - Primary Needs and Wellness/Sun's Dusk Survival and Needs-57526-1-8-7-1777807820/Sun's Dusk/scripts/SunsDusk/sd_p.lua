-- ╭────────────────────────────────────────────────────────────────────╮
-- │  Sun's Dusk - Player                                               │
-- ╰────────────────────────────────────────────────────────────────────╯

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

typesActorSpellsSelf = types.Actor.spells(self)
typesActorActiveSpellsSelf = types.Actor.activeSpells(self)
typesActorActiveEffectsSelf = types.Actor.activeEffects(self)
typesActorInventorySelf = types.Actor.inventory(self)

typesPlayerStatsSelf = {
	health = types.Actor.stats.dynamic.health(self),
	magicka = types.Actor.stats.dynamic.magicka(self),
	fatigue = types.Actor.stats.dynamic.fatigue(self),
	level = types.Actor.stats.level(self),
	endurance = types.Actor.stats.attributes.endurance(self),
	intelligence = types.Actor.stats.attributes.intelligence(self),
	strength = types.Actor.stats.attributes.strength(self),
	alchemy = types.Player.stats.skills.alchemy(self),
	shortblade = types.Player.stats.skills.shortblade(self),
	luck = types.Player.stats.attributes.luck(self),
	mercantile = types.Player.stats.skills.mercantile(self),
	personality = types.Player.stats.attributes.personality(self),
}

WAKEVALUE_MULT = 1
FOODVALUE_MULT = 1
DRINKVALUE_MULT = 1
G_WEATHER_API_AVAILABLE = core.weather and core.weather.getCurrent
G_STARWIND_INSTALLED = false
local raycast = nearby.castRenderingRay
if types.Container.records["sw_locker"] and types.Container.records["sw_crate"] and types.Potion.records["sw_medkit"] then
	raycast = nearby.castRay -- what the hell is wrong with the performance of that mod?
	--I.SharedRay.setRayType(nearby.castRay)
	G_STARWIND_INSTALLED = true
	print("[SunsDusk] Starwind detected")
end

makeBorder = require("scripts.SunsDusk.ui_makeborder") 
require('scripts.SunsDusk.sd_helpers')
require('scripts.SunsDusk.constants')

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ MESSAGE BOXES                                                      │
-- ╰────────────────────────────────────────────────────────────────────╯

function messageBox(level, ...)
	local lvl, str = 2, ""
	if type(level) == "table" then
		lvl = tonumber(level[1]) or 0
		str = table.concat(level, " ", 2)
	else
		lvl = tonumber(level) or 0
		str = table.concat({...}, " ")
	end
	--print(lvl, str)
	if lvl <= MESSAGE_BOX_LEVEL then
		ui.showMessage(str)
	end	
end

require('scripts.SunsDusk.localization')

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Globals : add modules here                                         │
-- ╰────────────────────────────────────────────────────────────────────╯
--- FOR MODDING THIS MOD ---

-- ── UI scaling ──────────────────────────────────────────────────────
local layerId   = ui.layers.indexOf("HUD")
G_hudLayerSize  = ui.layers[layerId].size
G_screenSize    = ui.screenSize()
G_uiScale       = G_hudLayerSize.x / G_screenSize.x

-- ── Job registries ──────────────────────────────────────────────────
-- Time-based
G_perHourJobs                   = {} -- (clockHour) 1-24
G_perMinuteJobs                 = {} -- (clockHour, gameMinute, minutesPassed) load-balanced one-per-frame, or all-at-once during time skips
G_onFrameJobs                   = {} -- (dt) every frame
G_onFrameJobsSluggish           = {} -- () auto-scheduled in rotating groups, ~1 group per frame
-- Engine events
G_onLoadJobs                    = {} -- (eventName) "onInit" or "onLoad"
G_onSaveJobs                    = {}
G_onConsumeJobs                 = {} -- (item) game object, from engineHandlers.onConsume
G_mousewheelJobs                = {} -- (direction) scroll direction
G_controllerButtonPressJobs     = {} -- (keyCode)
G_controllerButtonReleaseJobs   = {} -- (keyCode)
G_keyPressJobs                  = {} -- (keyCode) from key.code
G_keyReleaseJobs                = {} -- (keyCode) from key.code
G_consoleJobs                   = {} -- (command)
-- Cell and environment
G_cellChangedJobs               = {} -- (previousCell, jobKey) - not called on load
G_onCellInfoChangedJobs         = {} -- () after G_cellInfo is updated
G_raycastChangedJobs            = {} -- () when G_lastRaycastHitObject changes
-- Player state
G_UiModeChangedJobs             = {} -- (data) {oldMode, newMode, arg}
G_onPlayerInfoChangedJobs       = {} -- (reason) can be "init", "chargen", "isVampire", "isWerewolf" or "isInWerewolfForm"
G_equipmentChangedJobs          = {} -- (unequippedItems, equippedItems) both are {slot = gameObject}
G_onInventoryChangedJobs        = {} -- (gained, lost, container) gained/lost are {recordId = count}, container is from QuickLoot or nil, only when encumbrance changes
G_onConsumedWaterJobs           = {} -- (liquid, remainingWater) please dont register last (temperature spills water there) and return remainingWater
G_onMiscUsedJobs                = {} -- (item) game object
G_landedHitJobs                 = {} -- (target, attack) target is game object, attack is attack data
G_landedSpellHitJobs            = {} -- (target, spell) target is game object, spell is resolved activeSpell
-- Sleep
G_removeAbilitiesJobs           = {} -- () called when the rest menu opens to remove all buffs for the LevelUp screen
G_postSleepJobs                 = {} -- () called when sleep ends
G_refreshNeedsJobs              = {} -- (needId) force-recompute buffs/widgets; needId nil = all, otherwise modules ignore unless they match
-- Settings and UI
G_settingsChangedJobs           = {} -- (sectionName, setting, oldValue)
G_refreshWidgetJobs             = {} -- () rebuild widgets after settings change
G_destroyHudJobs                = {} -- () tear down HUD elements before full rebuild
G_refreshTooltipJobs            = {} -- () refresh all tooltip content
-- World interactions (module tables, not callbacks)
G_worldInteractions             = {} -- [moduleId] = { canInteract(obj, type), getActions(obj, type) }
-- Event handlers (registered in sd_p and player_modules, exported in return block)
G_eventHandlers                 = {}
G_woodcutting_woodCountHandlers = {} -- functions for modifying wood drops, registered via API

-- ── World state ─────────────────────────────────────────────────────
-- Raycast
G_raycastResult                 = nil   -- full ray result from castRay/castRenderingRay
G_raycastResultType             = nil   -- hitTypeName string
G_lastRaycastHitObject          = nil   -- previous frame's hitObject, triggers G_raycastChangedJobs on change
-- Player environment
G_isInWater                     = 0     -- depth level, 0 = not in water
G_waterObject                   = nil   -- only checked if NEEDS_CLEAN
G_isSleeping                    = false
G_isInJail                      = nil
G_isTravelling                  = false -- set when cell differs between UiModeChanged calls
G_isLongTravel                  = nil   -- set when >= 12 hours passed and isTravelling
G_currentBed                    = nil
-- Temperature strings (set by p_temp, read via interface)
G_trueExteriorTempString        = ""  -- exterior temp before race/equipment modifiers
G_playerCurrentTempString       = ""  -- current temp after all modifiers
G_playerTempBuffString          = ""  -- active temperature buff description
G_playerTargetTempString        = ""  -- target temp player is moving toward
-- Wetness
G_SW_isWet                      = 0
-- Databases (synced from global)
G_liquids                       = {}    -- UNUSED [recordId] = liquid data,
G_stewNames                     = {}    -- [displayName] = recordId, built from registeredConsumables
-- Misc
G_isBathingItem                 = function()end -- overridden by p_clean
G_currentDialogueNPC            = nil
G_teleportNPCs                  = {
	uvi_travelring              = true,
	uvi_travelring_ut           = true,
	uvi_travelring_v            = true,
	uvi_travelring_z            = true,
}
--function G_isWoodcuttingActivator(object, objectType) -- overridden by p_woodcutting
--function G_isCookingActivator(object, objectType)     -- overridden by p_cooking

-- ── Vignette and heartbeat ──────────────────────────────────────────
G_heartbeatFlags                = {}     -- [moduleName] = volume
G_vignetteFlags                 = {}      -- [moduleName] = alpha
G_vignetteColorFlags            = {} -- [moduleName] = "hot" | "cold" | nil
G_flashVignette                 = 0       -- set up to 1, it fades automatically
G_heartbeatInterval             = 1.0

-- ── Clock ───────────────────────────────────────────────────────────
G_clockOffset                   = 0         -- if gameTime%24 isnt exactly the clock hour

-- ── HUD widget registration ────────────────────────────────────────
-- icons go into columns, bars go into rows
G_rowWidgets                    = {}
G_columnWidgets                 = {}
G_rowsNeedUpdate                = false
G_columnsNeedUpdate             = false

-- ── Spell helpers ───────────────────────────────────────────────────
G_preventAddingAnyBuffs = false
G_addSpellWhenAwake = function(spell) --legacy
	if not G_preventAddingAnyBuffs then
		typesActorSpellsSelf:add(spell)
	end
end
G_refreshTooltips = function()
	for _, job in pairs(G_refreshTooltipJobs) do
		job()
	end
end
-- forces all needs modules to recompute buffs/widgets; pass needId to target one module
G_refreshNeeds = function(needId)
	for _, job in pairs(G_refreshNeedsJobs) do
		job(needId)
	end
end
-- after sleep ends, wait at least 3 frames AND for ui to leave LevelUp before refreshing needs
table.insert(G_postSleepJobs, function(slept)
	local framesWaited = 0
	G_onFrameJobs["postSleepRefreshNeeds"] = function(dt)
		framesWaited = framesWaited + 1
		if framesWaited < 10 then return end
		if I.UI.getMode() == "LevelUp" then return end
		G_refreshNeeds()
		G_onFrameJobs["postSleepRefreshNeeds"] = nil
	end
end)

-- ── Cell info (populated by g_cellInfo.lua, received via SunsDusk_receiveCellInfo) ──
G_cellInfo = { fires = {} }
-- Cell type flags (set by sd_g, flushed on cell change)
-- .isExterior = true or nil,
-- .isIceCave = true or nil,
-- .isCave = true or nil,
-- .isDwemer = true or nil,
-- .isDaedric = true or nil,
-- .isMine = true or nil,
-- .isTomb = true or nil,
-- .isHouse = true or nil,
-- .isCastle = true or nil,
-- .isMushroom = true or nil,
-- .isHlaalu = true or nil,
-- .isRedoran = true or nil,
-- .isSewer = true or nil,
-- .isTemple = true or nil,
-- .isBath = true or nil,
-- .isAshlander = true or nil,
-- .hasPublican = true or nil,
-- .fixedTemperature = true or nil,   -- true = temperature from dbStatics 

-- Climate (set by p_temp)
-- .temperature = number,             -- current cell temperature
-- .climateType = string,             -- dominant climate type ("arctic", "volcanic", etc.)
-- .solarHeating = number,            -- solar + night effect; exterior's own or next exterior's

-- Next exterior (flushed on cell change, temperature/climate cached once)
-- .nextExteriorCell = cell,          -- can be quasi exterior
-- .nextExteriorPosition = v3,        -- can be quasi exterior
-- .nextExteriorAnchor = gameobject,  -- can be quasi exterior
-- .nextExteriorCellIsQuasiExterior = true, false or nil,
-- .nextExteriorTemperature = number, -- cached, from CLIMATE_SOURCES or QUASI_EXTERIOR lookup
-- .nextExteriorClimateType = string, -- cached, dominant climate at next exterior

-- .fires = {}

-- ── Save data structure ────────────────────────────────────────────
--saveData =
-- .m_sleep = {}, 
-- .m_hunger = {},
-- .m_thirst = {},
-- .m_temp = {},
-- .weatherInfo = 
--   .isInRain = false
--   .isInShadow = false
--   .hasWindCover = nil
--   .shadowLength = 0
--   .windSpeed = 0
--   .sunStrength = 0
-- .playerInfo = 
--   .majorSkills = {} --skill = true
--   .minorSkills = {} --skill = true
--   .isBeast = false
--   .isOrc = false
--   .isNord = false
--   .isBreton = false
--   .isBosmer = false
--   .isAltmer = false
--   .isImperial = false
--   .isDunmer = false
--   .isRedguard = false
--   .isFarmingTool = false
--   .isInWerewolfForm = false
--   .isVampire = 0 -- 1 = vampire curse
--   .isWerewolf = 0 -- 1 = werewolf curse
-- .companions = {}
-- .countCompanions = 0

-- scheduler
local onFrameJobsSluggishIterator   = nil
local sluggishSchedulerAuto         = {}
local sluggishSchedulerAutoIterator = 1
G_sluggishScheduler                 = {} -- currently unused
local sluggishSchedulerIterator     = 1
local sluggishSchedulerSize         = 0
local jobTimings                    = {} -- [jobId] = {avgTime = 0.0001, lastRun = 0}
local jobTimingsMax                 = {} -- [jobId] = {avgTime = 0.0001, lastRun = 0}
local otherJobsAvg                  = 0.1

G_sluggishScheduler = setmetatable({}, {
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
	G_sluggishScheduler[i] = {}
end

-- heartbeats
local isHeartbeatPlaying = false
local lastHeartbeatVolume = 0
local lastHeartbeatPlayed = 0
local nextHeartbeatFlash = math.huge
local heartbeatFlashing = 0

-- misc
local hasActivatedBed = false
local equippedItems = nil -- tracks external equipment events 
G_forceSquareFalloff = nil --just for testing
G_module_clean_swampFunction = function() end
-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Texture pack discovery                                             │
-- ╰────────────────────────────────────────────────────────────────────╯

require('scripts.SunsDusk.sd_loadTexturePacks')

-- ─────────────────────────────────────────────────────────────────────────────── UI ─────────────────────────────────────────────────────────────────────────────────────

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Global Style                                                       │
-- ╰────────────────────────────────────────────────────────────────────╯

-- Borders
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

require('scripts.SunsDusk.settings.sd_settings')

-- ──────────────────────────────────────────────────────────────────────────────  Databases ───────────────────────────────────────────────────────────────────────────────

require('scripts.SunsDusk.spreadsheetParser') -- dbConsumables
require('scripts.SunsDusk.staticsParser') -- dbStatics

-- ────────────────────────────────────────────────────────────────────────── Consumables Database ────────────────────────────────────────────────────────────────────────

for filename in vfs.pathsWithPrefix("scripts/SunsDusk/player_modules/p_") do
	if filename:match("%.lua$") and not filename:match("/%._") then
		-- Remove .lua extension
		local require_path = filename:gsub("%.lua$", "")
		-- Replace forward slashes with dots
		require_path = require_path:gsub("/", ".")
		require(require_path)
	end
end

-- fix for dubious
local function getFileSize(path)
	local f = vfs.open(path)
	if f then
		local size = f:seek("end")
		f:close()
		return size
	end
	return nil
end
local newModule = getFileSize("scripts/SunsDusk/player_modules/p_shower.lua")
if not newModule and getFileSize("scripts/SunsDusk/modules/module_shower.lua") then
	require("scripts.SunsDusk.modules.module_shower")
	print("loaded legacy Baths of Vvardenfell. Please Update")
end

-- ─────────────────────────────────────────────────────────────────────────────── on Update ────────────────────────────────────────────────────────────────────────────────

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Inventory change tracker                                           │
-- │ Snapshots inventory, diffs on QL events or encumbrance changes     │
-- │ Dispatches: G_onInventoryChangedJobs(gained, lost)                 │
-- ╰────────────────────────────────────────────────────────────────────╯

local invSnapshot = {}
local lastEncumbrance = nil
local scanInventoryChanges -- forward declaration

G_onFrameJobsSluggish.inventoryTracker = function()
	if types.Actor.getEncumbrance(self) ~= lastEncumbrance then
		--scanInventoryChanges()
		
		--temp workaround:
		lastEncumbrance = types.Actor.getEncumbrance(self)
		for _, job in pairs(G_onInventoryChangedJobs) do
			job({["sd_wood"] = 1}, nil, nil)
		end
	end
end

--local function buildInventorySnapshot()
--	local snapshot = {}
--	for _, item in ipairs(typesActorInventorySelf:getAll()) do
--		snapshot[item.recordId] = (snapshot[item.recordId] or 0) + item.count
--	end
--	return snapshot
--end

--scanInventoryChanges = function(container)
--	local newSnapshot = buildInventorySnapshot()
--	local gained, lost = {}, {}
--	local hasChanges = false

--	-- check for gained or increased
--	for id, count in pairs(newSnapshot) do
--		local old = invSnapshot[id] or 0
--		if count > old then
--			gained[id] = count - old
--			hasChanges = true
--		end
--	end

--	-- check for lost or decreased
--	for id, count in pairs(invSnapshot) do
--		local new = newSnapshot[id] or 0
--		if new < count then
--			lost[id] = count - new
--			hasChanges = true
--		end
--	end
--	
--	invSnapshot = newSnapshot
--	lastEncumbrance = types.Actor.getEncumbrance(self)
--	
--	if hasChanges then
--		for _, job in pairs(G_onInventoryChangedJobs) do
--			job(gained, lost, container)
--		end
--	end
--end

--table.insert(G_onLoadJobs, function()
--	invSnapshot = buildInventorySnapshot()
--end)

G_eventHandlers.OwnlysQuickLoot_lootedItem = function(data) -- (data) {container, item}
	--scanInventoryChanges(data[1])
	--temp workaround:
	for _, job in pairs(G_onInventoryChangedJobs) do
		job({[data[2].recordId] = 1}, {}, data[1])
	end
end

G_eventHandlers.OwnlysQuickLoot_lootedItems = function(data) -- (data) {container, items[]}
	--scanInventoryChanges(data[1])
	--temp workaround:
	local gained = {}
	for _, item in ipairs(data[2]) do
		gained[item.recordId] = (gained[item.recordId] or 0) + 1
	end
	for _, job in pairs(G_onInventoryChangedJobs) do
		job(gained, {}, data[1])
	end
end

function updateHeartbeat(dt)
	-- Calculate maximum intensity from all flags
	local maxIntensity = 0
	
	for moduleName, intensity in pairs(G_heartbeatFlags) do
		maxIntensity = math.max(maxIntensity, intensity)
	end
	
	-- Only play if intensity > 0
	if maxIntensity > 0 then
		local currentTime = core.getRealTime()
		-- Check if enough time has passed since last heartbeat
		if heartbeatFlashing > 0 and currentTime > nextHeartbeatFlash then
			G_flashVignette = heartbeatFlashing
			nextHeartbeatFlash = math.huge
		end
		if currentTime - lastHeartbeatPlayed >= G_heartbeatInterval then
			ambient.playSoundFile("sound/SunsDusk/Heartbeat1_by_Latzii.ogg", {
				volume = maxIntensity,
				loop = false,
				scale = false
			})
			lastHeartbeatPlayed = currentTime
			if heartbeatFlashing > 0 then
				nextHeartbeatFlash = currentTime + 0.4
			end
		end
	end
end
--table.insert(G_onFrameJobsSluggish, updateHeartbeat)
table.insert(G_sluggishScheduler[5], updateHeartbeat)
G_onFrameJobsSluggish.updateHeartbeat = updateHeartbeat

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Weather + rain sensing                                             │
-- ╰────────────────────────────────────────────────────────────────────╯

-- Optional one-time log
 if not G_WEATHER_API_AVAILABLE then
	 -- why: inform users on older OpenMW that rain hydration is disabled
	log(1, "[SunsDusk] Weather API not available (OpenMW < 0.50). Some features like Argonian rain hydration disabled.")
 end

local stormDirs = {
	Blizzard = v3(0,1,0), --isStorm = true, correct storm dir
	Blight = v3(0,1,0),  --isStorm = false, random storm dir
	Ashstorm = v3(0,1,0), --isStorm = false, random storm dir
	Snow = false, --isStorm = false, 0,1,0
	Overcast = false, --isStorm = false, 0,1,0
	Rain = false, --isStorm = false, 0,1,0
	Cloudy = false, --isStorm = false, 0,1,0
	Foggy = false, --isStorm = false, 0,1,0
	Clear = false, --isStorm = false, 0,1,0
	Thunderstorm = false, --isStorm = false, 0,1,0 (triggers banner animations, high wind speed, but rain falls straight down)
}
local fallbackStormDir = v3(0,0,1)

local noStormRaycasts = {
	v3(1,0,0),
	v3(-1,0,0),
	v3(0,1,0),
	v3(0,-1,0),
}

local weatherInfoIndex = 1
local weatherInfoUpdaters = {

	-- Rain check (RAYCAST + getCurrent)
	weatherRainCheck = function(isOnUpdate)
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
		if G_isInWater >=0.9 then
			saveData.weatherInfo.isInRain = false
			return
		end
		local playerPos = self.position + v3(0,0,saveData.playerInfo.noseLevel)
		local skyPos = self.position + v3(0,0,1800)
		local raycast = raycast
		if isOnUpdate then
			raycast = nearby.castRay
		end
		local ray = raycast(playerPos, skyPos, { collisionType = nearby.COLLISION_TYPE.AnyPhysical+nearby.COLLISION_TYPE.VisualOnly, ignore = self })
		if ray.hit then
			saveData.weatherInfo.isInRain = false
		elseif w.rainEffect ~= nil or (w.rainMaxRaindrops and w.rainMaxRaindrops > 0) then 
			saveData.weatherInfo.isInRain = true
		else
			saveData.weatherInfo.isInRain = false
		end
	end,
	
	-- Current weather + Storm status
	weatherCurrentAndStorm = function()
		local cell = self and self.cell
		if not cell then return end
		local w = saveData.weatherInfo.currentWeather
		saveData.weatherInfo.weatherName = w and w.name or "Unknown"
		if not w then
			saveData.weatherInfo.isStorm = nil
			saveData.weatherInfo.stormDirection = nil
			return
		end
		
		local stormDir = stormDirs[saveData.weatherInfo.weatherName]
		if stormDir ~= nil then
			saveData.weatherInfo.isStorm = stormDir and true
			saveData.weatherInfo.stormDirection = stormDir or fallbackStormDir
		else
			saveData.weatherInfo.isStorm = w.isStorm
			saveData.weatherInfo.stormDirection =  core.weather.getCurrentStormDirection(cell)
		end
		
	end,
	
	-- Shadow check (RAYCAST + sunLightDirection)
	weatherShadowCheck = function(isOnUpdate)
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
		local raycast = raycast
		if isOnUpdate then
			raycast = nearby.castRay
		end
		local ray = raycast(playerPos, sunPos, { collisionType = nearby.COLLISION_TYPE.AnyPhysical, ignore = self })
		
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
		local windSourceOffset
		if self.controls.sneak then
			playerPos= self.position + v3(0,0,30)
			windSourceOffset = playerPos + v3(0,0,120)
		else
			playerPos= self.position + v3(0,0,80)
			windSourceOffset = playerPos + v3(0,0,180)
		end
		-- Raycast in direction wind is coming FROM (check for blocking wall/structure)
		if saveData.weatherInfo.isStorm then
			local ray = nearby.castRay(playerPos, windSourceOffset + (windDir * -400), { collisionType = nearby.COLLISION_TYPE.AnyPhysical, ignore = self })
			saveData.weatherInfo.hasWindCover = ray.hit
		else
			local hits = 0
			for _, dir in pairs(noStormRaycasts) do
				local ray = nearby.castRay(playerPos, windSourceOffset + (dir * 300), { collisionType = nearby.COLLISION_TYPE.AnyPhysical, ignore = self })
				if ray.hit then
					hits = hits + 1
				end
			end
			saveData.weatherInfo.hasWindCover = hits >= 2
		end
	end,
	
	-- Wind speed + Rain intensity (bundled: both use getCurrent)
	weatherRainintensity = function()
		local cell = self and self.cell
		saveData.weatherInfo.windSpeed = saveData.weatherInfo.windSpeed or  0
		saveData.weatherInfo.maxWindSpeed = 0
		saveData.weatherInfo.rainIntensity =  0
		saveData.weatherInfo.rainSpeed = 0
		
		if not cell or not G_cellInfo.isExterior then
			saveData.weatherInfo.windSpeed = 0
			return 
		end
		local w = saveData.weatherInfo.currentWeather
		if w then
			saveData.weatherInfo.windSpeed = saveData.weatherInfo.windSpeed * 0.95 + (core.weather.getCurrentWindSpeed(cell) or 0) * 0.05
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

local function refreshAllWeatherInfoOnFrame(dt)
	if G_WEATHER_API_AVAILABLE then
		for weatherInfoIndex in pairs(weatherInfoUpdaters) do
			weatherInfoUpdaters[weatherInfoIndex](not dt)
		end
	end
	G_onFrameJobs["refreshAllWeatherInfoOnFrame"] = nil
end

local function refreshAllWeatherInfo()
	saveData.weatherInfo.isInRain = false
	saveData.weatherInfo.isInShadow = false
	saveData.weatherInfo.hasWindCover = nil
	saveData.weatherInfo.shadowLength = 0
	saveData.weatherInfo.windSpeed = 0
	saveData.weatherInfo.sunStrength = 0
	--saveData.weatherInfo.currentWeather = nil
	saveData.weatherInfo.weatherName = "Unknown"
	saveData.weatherInfo.isStorm = false
	saveData.weatherInfo.stormDirection = nil
	saveData.weatherInfo.sunPercentage = 0
	saveData.weatherInfo.sunVisibility = 0
	saveData.weatherInfo.maxWindSpeed = 0
	saveData.weatherInfo.rainIntensity = 0
	saveData.weatherInfo.rainSpeed = 0
	saveData.weatherInfo.transition = 0
	saveData.weatherInfo.nextWeather = nil
	saveData.weatherInfo.currentWeather = nil
	G_onFrameJobs["refreshAllWeatherInfoOnFrame"] = refreshAllWeatherInfoOnFrame
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
		--table.insert(G_onFrameJobsSluggish, job)
		G_onFrameJobsSluggish[jobId] = job
	end
	table.insert(G_sluggishScheduler, {weatherInfoUpdaters.weatherShadowCheck, weatherInfoUpdaters.weatherWindCover, weatherInfoUpdaters.weatherTransition})
	table.insert(G_sluggishScheduler, {weatherInfoUpdaters.weatherRainintensity, weatherInfoUpdaters.weatherRainCheck, weatherInfoUpdaters.weatherCurrentAndStorm, weatherInfoUpdaters.weatherSunExposure })
	table.insert(G_sluggishScheduler[4], weatherInfoUpdaters.weatherUi)
	--table.insert(G_onFrameJobsSluggish, refreshWeatherInfo)
end

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ In water                                                           │
-- ╰────────────────────────────────────────────────────────────────────╯

local function inWaterCheck()
   	if not self.cell then
		G_isInWater = 0
		return
	end
	local waterLevel = self.cell.waterLevel or -99999999
	if self.controls.sneak then
		G_isInWater = math.max(0,math.min(1, (-self.position.z+waterLevel)/(saveData.playerInfo.noseLevel*0.6)))
	else
		G_isInWater = math.max(0,math.min(1, (-self.position.z+waterLevel)/saveData.playerInfo.noseLevel))
	end
	if G_isInWater > 0.02 and saveData.m_clean then
		local waterPos = v3(self.position.x, self.position.y, waterLevel+10)

		local raycastResult = raycast(
			waterPos,
			waterPos - v3(0,0,10),
			{ ignore = self }
		)
		G_waterObject = raycastResult.hitObject and raycastResult.hitObject.recordId 
		if G_waterObject then
			G_module_clean_swampFunction()
		end
		--print(G_waterObject)
	else
		G_waterObject = nil
	end
	--print(G_isInWater.." in water")
end
--table.insert(G_onFrameJobsSluggish, inWaterCheck)
table.insert(G_sluggishScheduler[4], inWaterCheck)
G_onFrameJobsSluggish.inWaterCheck = inWaterCheck

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Equipment changes                                                  │
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
		for _, func in pairs(G_equipmentChangedJobs) do
			func(unequippedItems, equippedItems or {})
		end
	end
	previouslyEquippedItems = currentEquipment
	equippedItems = nil

end
--table.insert(G_onFrameJobsSluggish, equipCheck)
table.insert(G_sluggishScheduler[3], equipCheck)
G_onFrameJobsSluggish.equipCheck = equipCheck

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Night Creature checks                                              │
-- ╰────────────────────────────────────────────────────────────────────╯

local function isInWerewolfFormCheck()
	local newWerewolf = types.NPC.isWerewolf(self)
	if saveData.playerInfo.isInWerewolfForm ~= newWerewolf then
		saveData.playerInfo.isInWerewolfForm = newWerewolf
		for _, func in pairs(G_onPlayerInfoChangedJobs) do
			func("isInWerewolfForm")
		end
	end
end
table.insert(G_perMinuteJobs, isInWerewolfFormCheck)

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Main logic loop                                                    │
-- ╰────────────────────────────────────────────────────────────────────╯

function mainLogic()
	local gameTime = calendar.gameTime()
	--minute steps since last update
	local tempCurrentMinute = math.floor(gameTime / time.minute)
	local minutesPassed = tempCurrentMinute - saveData.lastUpdate
	if minutesPassed < 0 then
		saveData.lastUpdate = tempCurrentMinute
		saveData.lastHourProcessed = math.floor(gameTime / time.hour)
		perMinuteJobIterator = nil
		return
	end
	-- uvirith's legacy teleport ring
	if G_currentDialogueNPC and G_teleportNPCs[G_currentDialogueNPC.recordId] then
		local gameTime = calendar.gameTime()
		saveData.lastUpdate = math.floor(gameTime / time.minute)
		saveData.lastHourProcessed = math.floor(gameTime / time.hour)
	end
	
	--hour steps since last update
	local tempCurrentHour = math.floor(gameTime / time.hour)
	local lastHourProcessed = saveData.lastHourProcessed or math.floor(saveData.lastUpdate/60)
	if G_isTravelling and tempCurrentHour - lastHourProcessed >= 8 then
		G_isLongTravel = true
	else
		G_isLongTravel = false
	end
	for hour=lastHourProcessed+1, tempCurrentHour do
		
		local clockHour = (hour+G_clockOffset)%24
		if clockHour == 0 then 
			clockHour = 24
		end
		--call all G_perMinuteJobs once per hour during time skips
		for _, func in pairs(G_perHourJobs) do
			func(clockHour)
		end
		saveData.lastHourProcessed = hour  -- Track hour progress separately
		
		if minutesPassed >= 60 then
			refreshAllWeatherInfoOnFrame(dt)
			local tempMinute = hour * 60 + tempCurrentMinute%60
			for _, func in pairs(G_perMinuteJobs) do
				func(clockHour, tempMinute, 60)
			end
			perMinuteJobIterator = nil
			saveData.lastUpdate = tempCurrentMinute
		end
	end
	
	-- if no hours passed, do load balanced G_perMinuteJobs (one per frame)
	if minutesPassed < 60 and minutesPassed > 0 then
		local clockHour = math.floor((tempCurrentMinute / 60 + G_clockOffset))%24
		if clockHour == 0 then 
			clockHour = 24
		end
		
		-- get next function using pairs iterator
		local func
		perMinuteJobIterator, func = next(G_perMinuteJobs, perMinuteJobIterator)
		if perMinuteJobIterator then
			func(clockHour, tempCurrentMinute, minutesPassed)
		else
			saveData.lastUpdate = tempCurrentMinute
		end
	end
end

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Consumption events                                                 │
-- ╰────────────────────────────────────────────────────────────────────╯

local function onConsume(item)
	if DEBUG_LEVEL >= 3 then
		local itemRecord = item.type.record(item)
		local output = "Consumed "..item.recordId.." ("..itemRecord.name..")"
		local entry = saveData.registeredConsumables[item.recordId] or dbConsumables[item.recordId]
		if entry then
			output = output.." (in DB)"
			--for a,b in pairs(entry) do
			--	print(a,b)
			--end
		end
		log(3,output)
	end
	--log(3, "item ID:  "..item.recordId.."  ;  item name: "..tostring(item.type.record(item).name).."  ;  wake value:  "..entry.wakeValue.."  ;  wake value2:  "..tostring(entry.wakeValue2))
	
	for _, func in pairs(G_onConsumeJobs) do
		func(item)
	end	
end

local function onMiscUsed(item)
	for _, func in pairs(G_onMiscUsedJobs) do
		func(item)
	end	
end

local function onConsumedWater(liquid)
	if liquid ~= "water" and liquid ~= "susWater" then return end --and liquid ~= "saltWater" then return end
	local remainingWater = 1
	for _, func in pairs(G_onConsumedWaterJobs) do
		remainingWater = func(liquid, remainingWater) or remainingWater
	end
end

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Frame + update drivers                                             │
-- ╰────────────────────────────────────────────────────────────────────╯

local function onUpdate(dt)
end

function rebalancesluggishSchedulerAuto()
	-- Collect all job keys
	local jobKeys = {}
	for key, _ in pairs(G_onFrameJobsSluggish) do
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

local function errorDetection(data)
	errorMessage = data.message or
[[Sun's Dusk (Global Script) encountered an error.
Please upload your openmw.log
(in Documents\My Games\OpenMW)
to our OpenMW Discord channel
or at https://www.nexusmods.com/morrowind/mods/57526]]
		
	errorDetails = data.error or nil
		
	require("scripts.sunsdusk.ui_errorDialogue")
end


local function onFrame(dt)
	if not successfulInitialized then 
		return 
	end
	--print("-----", core.getGameTime())
	--for _, spell in pairs(typesActorActiveSpellsSelf) do
	--	print(spell.id)
	--	for _, effect in pairs(spell.effects) do
	--		print(" ", effect, effect.magnitudeThisFrame)
	--	end
	--end
	--print("-----")
	local currentPerfHit = core.getRealTime()
	mainLogic(dt)
	if self.cell then
		--print(self.cell)
		if not currentCell then
			currentCell = self.cell
		elseif self.cell ~=currentCell then
			for i, func in pairs(G_cellChangedJobs) do
				func(currentCell,i) -- LAST CELL arg
			end
			currentCell = self.cell
			core.sendGlobalEvent("SunsDusk_getCellInfo", self)
		end
	end
	
	if WHISPER_FIX then
		ambient.stopSoundFile("sounds\\DynamicSounds\\weather\\blight_whispers_lp.wav")
		ambient.stopSoundFile("sounds\\DynamicSounds\\daedric\\whispers.wav")
		--ambient.stopSoundFile("sounds\\DynamicSounds\\temple\\whispers1.wav")
		--ambient.stopSoundFile("sounds\\DynamicSounds\\temple\\whispers.wav")
		--ambient.stopSoundFile("sounds\\DynamicSounds\\temple\\whispers3.wav")
		--ambient.stopSoundFile("sounds\\DynamicSounds\\temple\\whispers4.wav")
	end
	for _, func in pairs(G_onFrameJobs) do
		func(dt)
	end
	currentPerfHit = core.getRealTime()-currentPerfHit
	otherJobsAvg = otherJobsAvg * 0.9 + currentPerfHit * 0.1
	if currentPerfHit < otherJobsAvg then
		
	--	one per frame:
	--	local currentJob
	--	onFrameJobsSluggishIterator, currentJob = next(G_onFrameJobsSluggish, onFrameJobsSluggishIterator)
	--	if not onFrameJobsSluggishIterator then
	--		onFrameJobsSluggishIterator, currentJob = next(G_onFrameJobsSluggish)
	--	end
	--	currentJob()
	--	print(onFrameJobsSluggishIterator)
	--	print("+")
	
	--	hybrid (fixed timings):
	--	for _, job in pairs(G_sluggishScheduler[sluggishSchedulerIterator]) do
	--		job()
	--	end
	--	sluggishSchedulerIterator = sluggishSchedulerIterator + 1
	--	if sluggishSchedulerIterator > sluggishSchedulerSize then
	--		sluggishSchedulerIterator = 1
	--	end
	
	--  auto balancing:
		local numGroups = math.ceil(sluggishSchedulerAutoIndexCounter / 2)
		
		-- Get current group to execute
		local currentGroup = sluggishSchedulerAuto[sluggishSchedulerAutoIterator]
	
		--print("group",sluggishSchedulerAutoIterator)
		-- Execute all jobs in current group
		for i = 1, #currentGroup do
			local jobKey = currentGroup[i]
			local job = G_onFrameJobsSluggish[jobKey]
			
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
	--	print("+")
	--else
	--	print("-")
	end
	
	-- Consume shared raycast from SharedRay interface
	G_raycastResult = I.SharedRay.get()
	G_raycastResultType = G_raycastResult.hitTypeName
	if G_raycastResult.hitObject ~= G_lastRaycastHitObject then
		G_lastRaycastHitObject = G_raycastResult.hitObject
		for _, func in pairs(G_raycastChangedJobs) do
			func()
		end
	end
end

local function onMouseWheel(direction)
	for _, func in pairs(G_mousewheelJobs) do
		func(direction)
	end
end

-- ──────────────────────────────────────────────────────────────────────────── Event Handlers ────────────────────────────────────────────────────────────────────────────

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Combat mechanics                                                   │
-- ╰────────────────────────────────────────────────────────────────────╯

local function landedHit(data)
	local target = data[1]
	local attack = data[2]
	for _, func in pairs(G_landedHitJobs) do
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
		for _, func in pairs(G_landedSpellHitJobs) do
			func(target, foundSpell)
		end
	end
end

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ UI mode flow · sleep begins and ends here                          │
-- ╰────────────────────────────────────────────────────────────────────╯

local chargenModes = {
	["ChargenName"] = true,
	["ChargenRace"] = true,
	["ChargenClass"] = true,
	["ChargenClassCreate"] = true,
	["ChargenClassPick"] = true,
	["ChargenClassGenerate"] = true,
	["ChargenBirth"] = true,
	["ChargenClassReview"] = true,
}

local startedSleeping = nil
local function UiModeChanged(data)
	--print(data.oldMode, data.newMode)
	if not successfulInitialized then return end
	local newCell = self.cell
	if lastUiModeCell then
		if lastUiModeCell ~= newCell then
			G_isTravelling = true
		else
			G_isTravelling = nil
		end
	end
	lastUiModeCell = newCell
	log(4, "ui mode "..tostring(data.oldMode).." -> " .. tostring(data.newMode), data.arg)
	-- actual sleeping logic
	if data.newMode == "Travel" then
		G_isTravelling = true
	else
		G_isTravelling = nil
	end
	if data.newMode == "Jail" then
		G_isInJail = true
	end
	if data.newMode == "Rest" and data.oldMode == nil and (data.arg or hasActivatedBed or not self.cell:hasTag("NoSleep")) and not saveData.playerInfo.isInWerewolfForm then
		G_preventAddingAnyBuffs = true
		for _, job in pairs(G_removeAbilitiesJobs) do
			job()
		end
		log(3,"[SD] start sleep")
		G_isSleeping = true
		startedSleeping = core.getGameTime()
		hasActivatedBed = false
		G_currentBed = data.arg
	end
	if data.newMode == "Dialogue" and data.arg then
		G_currentDialogueNPC = data.arg
	end

	mainLogic()
	if data.newMode == nil then --can happen when traveling (fixed for singleplayer)
		G_currentDialogueNPC = nil
		G_onFrameJobs["endSleep"] = function(dt)
			if dt == 0 then return end
			if G_isSleeping then
				log(3,"[SD] end sleep")
				G_isSleeping = false
				G_preventAddingAnyBuffs = false
				core.sendGlobalEvent("SunsDusk_checkIfVampireWerewolf", self)
				local slept = (core.getGameTime() - startedSleeping) / time.hour
				for _, job in pairs(G_postSleepJobs) do
					job(slept)
				end
				startedSleeping = nil
			end
			G_currentBed = nil
			G_isInJail = nil
			hasActivatedBed = false
			lastUiModeCell = nil
			G_onFrameJobs["endSleep"] = nil
		end
	end
	if data.oldMode == "Dialogue" and data.newMode == nil then
		core.sendGlobalEvent("SunsDusk_convertMerchantItems", self)
	end
	
	for _, func in pairs(G_UiModeChangedJobs) do
		func(data)
	end
	if chargenModes[data.oldMode] then -- == "ChargenRace" then
		local delay = 7
		G_onFrameJobs["AfterChargenCheck"] = function()
			delay = delay - 1
			if delay <= 0 then
				if not chargenModes[I.UI.getMode()] then
					refreshPlayerInfo()
				end
				G_onFrameJobs["AfterChargenCheck"] = nil
			end
		end
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
-- │ Companion counters                                                 │
-- ╰────────────────────────────────────────────────────────────────────╯

local function releasedCompanion(actor)
	saveData.companions[getId(actor)] = nil
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
	saveData.companions[getId(actor)] = actor
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
-- │ Book spawning                                                      │
-- ╰────────────────────────────────────────────────────────────────────╯
local function cellChanged(lastCell)
	-- function to unregister this function on next frame:
	local function removeSelf()
		for i, func in ipairs(G_cellChangedJobs) do
			if func == cellChanged then
				table.remove(G_cellChangedJobs, i)
				break
			end
		end
		G_onFrameJobs["removeCellChangedJob"] = nil
	end
	
	-- check if the player was already served the first time they change cell
	if saveData.got_sd_book_1_needs and saveData.got_sd_book_2_temp and saveData.got_sd_book_3_cook_1 and saveData.got_sd_book_4_clean and saveData.got_sd_backpack_satchelbrown and saveData.got_sd_chargen_bread then
		G_onFrameJobs["removeCellChangedJob"] = removeSelf
		return 
	end
	
	-- check if the cell has the chargen dude and put the book in the bookshelf
	local chargenClassPosition = v3(242, -111, 193)
	for _, npc in pairs(nearby.actors) do
		if npc.recordId == "chargen class" and (npc.position - chargenClassPosition):length() < 100 then --<5ft
			core.sendGlobalEvent("SunsDusk_Books_spawnBooksInChargenArea", {self})
			saveData.got_sd_book_1_needs = true
			saveData.got_sd_book_2_temp = true
			saveData.got_sd_book_3_cook_1 = true
			saveData.got_sd_book_4_clean = true
			saveData.got_sd_backpack_satchelbrown = true
			saveData.got_sd_chargen_bread = true
			G_onFrameJobs["removeCellChangedJob"] = removeSelf
			return
		end
	end
end
table.insert(G_cellChangedJobs, 1, cellChanged)

G_onFrameJobs["giveBook"] = function()
	if saveData.got_sd_book_1_needs and saveData.got_sd_book_2_temp and saveData.got_sd_book_3_cook_1 and saveData.got_sd_book_4_clean and saveData.got_sd_backpack_satchelbrown and saveData.got_sd_chargen_bread then
		G_onFrameJobs["giveBook"] = nil
		return 
	end
	if chargenFinished() then
		if not saveData.got_sd_book_1_needs then
			ui.showMessage("A Traveler’s Guide to Morrowind and an Adventurer’s Satchel have been added to your inventory.")
			core.sendGlobalEvent("SunsDusk_addItem", {self, "sd_book_1_needs", 1})
		end
		if not saveData.got_sd_book_2_temp then
			core.sendGlobalEvent("SunsDusk_addItem", {self, "sd_book_2_temp", 1})
		end
		if not saveData.got_sd_book_3_cook_1 then
			core.sendGlobalEvent("SunsDusk_addItem", {self, "sd_book_3_cook_1", 1})
		end
		if not saveData.got_sd_book_4_clean then
			core.sendGlobalEvent("SunsDusk_addItem", {self, "sd_book_4_clean", 1})
		end
		if not saveData.got_sd_backpack_satchelbrown then
			core.sendGlobalEvent("SunsDusk_addItem", {self, "sd_backpack_satchelbrown", 1})
		end
		if not saveData.got_sd_chargen_bread then
			core.sendGlobalEvent("SunsDusk_addItem", {self, "ingred_bread_01", 2})
		end
		saveData.got_sd_book_1_needs = true
		saveData.got_sd_book_2_temp = true
		saveData.got_sd_book_3_cook_1 = true
		saveData.got_sd_book_4_clean = true
		saveData.got_sd_backpack_satchelbrown = true
		saveData.got_sd_chargen_bread = true
		G_onFrameJobs["giveBook"] = nil
	end
end

-- ─────────────────────────────────────────────────────────────────────────────── LifeCycle ───────────────────────────────────────────────────────────────────────────────

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Player info refresh + races, forms, flags                          │
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
	
	local khajiitRaces = {
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

--[[	redguard	Redguard
	dark elf	Dark Elf
	imperial	Imperial
	breton	Breton
	nord	Nord
	wood elf	Wood Elf
	high elf	Elf
	khajiit	Khajiit
	argonian	Argonian
	orc	Orc
	t_aka_tsaesci	Tsaesci
	t_cnq_chimeriquey	Chimeri-Quey
	t_cnq_keptu	Keptu-Quey
	t_cyr_ayleid	Ayleid
	t_els_cathay	Khajiit
	t_els_cathay-raht	Khajiit
	t_els_dagi-raht	Khajiit
	t_els_ohmes	Khajiit
	t_els_ohmes-raht	Khajiit
	t_els_suthay	Khajiit
	t_hr_ogre	Ogre
	t_hr_riverfolk	Riverfolk
	t_mw_malahk_orc	Malahk Orc
	t_pya_seaelf	Sea Elf
	t_sky_hill_giant	Hill Giant
	t_sky_reachman	Reachman
	t_val_imga	Imga
	t_yne_ynesai	Ynesai
	t_yok_duadri	Duadri
	un_skeleton_race	Skeleton
	un_lich_skull_race	Lich Skull
	un_haunt_race	Haunt
	un_ghost_race	Ghost
	senche-raht	Suthay-Raht
	cathay-raht	Cathay-Raht
	dagi-raht	Dagi-Raht
	war_ohmes	Ohmes-Raht
]]
	saveData.playerInfo.isBeast = khajiitRaces[name] or raceRec and raceRec.isBeast or name:find("khajiit")
	saveData.playerInfo.isKhajiit = khajiitRaces[name] or name:find("khajiit")
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
	
	saveData.playerInfo.raceName = "Race"
	if saveData.playerInfo.isFarmingTool then saveData.playerInfo.raceName =  "Argonian"
	elseif saveData.playerInfo.isKhajiit then saveData.playerInfo.raceName =  "Khajiit"
	elseif saveData.playerInfo.isNord then saveData.playerInfo.raceName =  "Nord"
	elseif saveData.playerInfo.isBreton then saveData.playerInfo.raceName =  "Breton"
	elseif saveData.playerInfo.isBosmer then saveData.playerInfo.raceName =  "Bosmer"
	elseif saveData.playerInfo.isAltmer then saveData.playerInfo.raceName =  "Altmer"
	elseif saveData.playerInfo.isImperial then saveData.playerInfo.raceName =  "Imperial"
	elseif saveData.playerInfo.isDunmer then saveData.playerInfo.raceName =  "Dunmer"
	elseif saveData.playerInfo.isRedguard then saveData.playerInfo.raceName =  "Redguard"
	elseif saveData.playerInfo.isOrc then saveData.playerInfo.raceName =  "Orc"
	end
	
	
	for a,b in pairs(saveData.playerInfo) do
		log(4,a,b)
	end
	
	if not saveData.playerInfo.isVampire then -- = ON INIT
		saveData.playerInfo.isVampire = 0
		saveData.playerInfo.isWerewolf = 0
		core.sendGlobalEvent("SunsDusk_checkIfVampireWerewolf", self)
		for _, func in pairs(G_onPlayerInfoChangedJobs) do
			func("init")
		end
	else
		for _, func in pairs(G_onPlayerInfoChangedJobs) do
			func("chargen")
		end
	end
end

-- ran after waking up and when selecting the roguelite challenge
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
		for _, func in pairs(G_onPlayerInfoChangedJobs) do
			func(infosChanged)
		end
	end
end

local function receiveCellInfo(data)
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
		waterType = "water" etc or nil
	}
]]
	-- instead of G_cellInfo = data....
	
	-- clear old cellInfo
	for k in pairs(G_cellInfo) do 
		G_cellInfo[k] = nil 
	end
	if data.nextExteriorAnchor then
		G_cellInfo.nextExterior = data.nextExteriorAnchor.cell
	end
	-- if dbstatics has something, only fill that in
	if dbStatics[self.cell.id] and dbStatics[self.cell.id].cell then
		G_cellInfo.fires = data.fires
		for a, b in pairs(dbStatics[self.cell.id].cell) do 
			G_cellInfo[a] = b 
		end
		if G_cellInfo.temperature then
			G_cellInfo.fixedTemperature = true
		end
		if G_cellInfo.climateType then -- unused right now, seems fine already
			G_cellInfo.fixedClimateType = true
		end
	else
		-- otherwise just write the new cell info
		for k, v in pairs(data) do 
			G_cellInfo[k] = v 
		end
	end
	
	-- internal event
	for _, func in pairs(G_onCellInfoChangedJobs) do
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
"sd_clean_0",
"sd_clean_1",
"sd_clean_2",
"sd_clean_3",
"sd_clean_4",
"sd_clean_5",
}

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Save/load + external API                                           │
-- ╰────────────────────────────────────────────────────────────────────╯

local function onLoadInternal(data)
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
		version = 16,
		
		--companions = {}
		--countCompanions = 0
		--lastUpdate = math.floor(calendar.gameTime()/time.minute)
		--lastHourProcessed = math.floor(saveData.lastUpdate/60)
		--registeredConsumables = {}
		--chargenFinished = chargenFinished()
		--G_cellInfo = {}
		--playerInfo = {}
		--weatherInfo = {}
	}
	
	if not saveData.playerInfo then
		refreshPlayerInfo()
	end
	--migration from old save: (remove in final release)
	if not saveData.companions then
		saveData.companions = {}
	else
		saveData.countCompanions = 0
		saveData.specialCompanion = false
		for i, companion in pairs(saveData.companions) do
			if companion:isValid() then
				if companion.recordId == "your love" then
					saveData.specialCompanion = true
				end
				saveData.countCompanions = saveData.countCompanions + 1
			else
				saveData.companions[i] = nil
			end
		end
	end
	saveData.countCompanions = saveData.countCompanions or 0
	saveData.lastUpdate = saveData.lastUpdate or math.floor(calendar.gameTime()/time.minute)
	saveData.lastHourProcessed = saveData.lastHourProcessed or math.floor(saveData.lastUpdate/60)
	saveData.registeredConsumables = saveData.registeredConsumables or {}
	saveData.chargenFinished = saveData.chargenFinished or chargenFinished()
	
	if self.cell then
		core.sendGlobalEvent("SunsDusk_getCellInfo", self)
	end
	
	saveData.playerInfo = saveData.playerInfo or {}
	
	if not saveData.weatherInfo then
		saveData.weatherInfo = {}
		refreshAllWeatherInfo()
	end
	
	saveData.weatherInfo.sunStrength = saveData.weatherInfo.sunStrength or 0
	
	if not saveData.lastPosition then
		saveData.lastPosition = self.position
		saveData.lastPositionTime = core.getSimulationTime()
	end
	
	if not saveData.version or saveData.version < 3 then
		for id, data in pairs(saveData.registeredConsumables) do
			if data.longLasting then
				data.foodValue2 = data.foodValue/5
				data.drinkValue2 = data.drinkValue/5
				data.wakeValue2 = data.wakeValue/5
				data.longLasting = nil
			end
		end
		saveData.version = 3
	end
	if saveData.version < 11 then
		for id, data in pairs(saveData.registeredConsumables) do
			if data.wakeValue2 then
				data.timestamp = core.getGameTime()
			end
		end
		saveData.version = 11
	end
	if saveData.version < 12 then
		for id, data in pairs(saveData.registeredConsumables) do
			if data.foodValue then
				data.foodValue       = data.foodValue/200
			end
			if data.foodValue2 then
				data.foodValue2      = data.foodValue2/200
			end
			if data.drinkValue then
				data.drinkValue      = data.drinkValue/200
			end
			if data.drinkValue2 then
				data.drinkValue2     = data.drinkValue2/200
			end
			if data.wakeValue then
				data.wakeValue       = data.wakeValue/200
			end
			if data.wakeValue2 then
				data.wakeValue2      = data.wakeValue2/200
			end
		end
		saveData.version = 12
	end
	if saveData.version < 13 then
		saveData.countCompanions = 0
		saveData.specialCompanion = false
		local newCompanions = {}
		for i, companion in pairs(saveData.companions) do
			local isActive = false
			for _, actor in pairs(nearby.actors) do
				if actor == companion then
					isActive = true
					break
				end
			end
			if isActive then
				saveData.countCompanions = saveData.countCompanions + 1
				newCompanions[getId(companion)] = companion
			else
				print("found stale companion:", saveData.companions[i])
			end
		end
		saveData.companions = newCompanions
		saveData.version = 13
	end
	if saveData.version < 14 then
		saveData.featherMagnitude =nil
		for i=1, 8 do
			local abilityId = "sd_feather_f" .. i
			if core.magic.spells.records[abilityId] then
				typesActorSpellsSelf:remove(abilityId)
			end
		end
		saveData.version = 14
	end
	if saveData.version < 16 then
		refreshPlayerInfo()
		saveData.version = 16
	end
	
	-- validation
	if saveData.m_temp then
		saveData.m_temp.currentTemp = math.max(-100, math.min(100, saveData.m_temp.currentTemp))
	end
	if saveData.m_hunger then
		saveData.m_hunger.hunger = math.max(0, math.min(1, saveData.m_hunger.hunger))
	end
	if saveData.m_thirst then
		saveData.m_thirst.thirst = math.max(0, math.min(1, saveData.m_thirst.thirst))
	end
	if saveData.m_clean then
		saveData.m_clean.dirt = math.max(0, math.min(1, saveData.m_clean.dirt))
	end
	if saveData.m_sleep then
		saveData.m_sleep.tiredness = math.max(0, math.min(1, saveData.m_sleep.tiredness))
	end
	
	
	G_stewNames = {}
	for id, data in pairs(saveData.registeredConsumables) do
		if types.Potion.records[id] then
			G_stewNames[types.Potion.records[id].name] = id
		end
	end
	
	saveData.cellInfo = nil
	--/migration
	
	-- calc clock offset
	local gameTime = calendar.gameTime()
	local tempCurrentHour = math.floor(gameTime / time.hour)%24
	local clockHour = tonumber(calendar.formatGameTime("%H", calendar.gameTime()))
	G_clockOffset = tempCurrentHour - clockHour
	if G_clockOffset > 12 then
		G_clockOffset = G_clockOffset -24
	elseif G_clockOffset < -12 then
		G_clockOffset = G_clockOffset +24
	end
	core.sendGlobalEvent("SunsDusk_convertMerchantItems", self)
	
	for _, func in pairs(G_onLoadJobs) do
		func(eventName)
	end
	
	rebalancesluggishSchedulerAuto()
end

local function onLoad(data)
	local success, err = pcall(onLoadInternal, data)
	if success then
		successfulInitialized = true
	else
		print("[SunsDusk PLAYER] ERROR in onLoad: " .. tostring(err))
		
		errorMessage = [[Sun's Dusk failed to initialize.
Please report this Error on our OpenMW Discord channel
or at www.nexusmods.com/morrowind/mods/57526]] 
		errorDetails = tostring(err)
		
		require("scripts.sunsdusk.ui_errorDialogue")
	end
end

local function onSave()
	if not successfulInitialized and not saveData then 
		return 
	end
	for _, func in pairs(G_onSaveJobs) do
		func(eventName)
	end
	saveData.weatherInfo.nextWeather = nil
	saveData.weatherInfo.currentWeather = nil
	return saveData
end

local function API_addConsumable(id, tbl)
	saveData.registeredConsumables[id] = tbl
end

local function event_addConsumable(data)
	local recordId = data[1]
	local tbl = data[2]
	saveData.registeredConsumables[recordId] = tbl
	if tbl.timestamp and types.Potion.records[recordId] then
		--print(types.Potion.records[recordId].name, recordId)
		G_stewNames[types.Potion.records[recordId].name] = recordId
	end
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
	table.insert(G_cellInfo.fires, fire)
end

local function onConsoleCommand(command, str, selectedObject)
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
	
	if str:match("^lua companions") then
		for i,actor in pairs(saveData.companions) do
			print(actor, actor:isValid(), actor.count)
		end
		return
	end
	
	if str:lower()== "lua lava" then
		-- scan registered cell fires for "lava" recordId
		local found = 0
		for _, obj in ipairs(G_cellInfo.fires) do
			if obj and obj:isValid() and obj.recordId and obj.recordId:lower():find("lava") then
				found = found + 1
				local refStr = obj.contentFile
					and ("&" .. obj.contentFile .. "/" .. tostring(tonumber(obj.id:sub(-6), 16)))
					or "(no contentfile)"
				ui.printToConsole(obj.recordId .. "  " .. refStr, ui.CONSOLE_COLOR.Success)
			end
		end
		if found == 0 then
			ui.printToConsole("lava: no matches in cell", ui.CONSOLE_COLOR.Info)
		end
		return
	end

	if str:lower() =="lua refid" or str:lower() =="lua id" then
		if not selectedObject then
			ui.printToConsole("refid: no console target", ui.CONSOLE_COLOR.Error)
			return
		end
		ui.printToConsole("recordId: " .. tostring(selectedObject.recordId), ui.CONSOLE_COLOR.Success)
		if selectedObject.contentFile then
			local refNumDec = tonumber(selectedObject.id:sub(-6), 16)
			ui.printToConsole("refId:    &" .. selectedObject.contentFile .. "/" .. tostring(refNumDec), ui.CONSOLE_COLOR.Success)
		else
			ui.printToConsole("refId:    (not from a contentfile)", ui.CONSOLE_COLOR.Info)
		end
		return
	end
	
	for _, job in pairs(G_consoleJobs) do
		if job(command, str) then return end
	end
end

local function lightHotkey()
	async:newUnsavableSimulationTimer(0.1, function()
		equippedItems = equippedItems or {}
		equippedItems[types.Actor.EQUIPMENT_SLOT.CarriedLeft] = types.Actor.getEquipment(self, types.Actor.EQUIPMENT_SLOT.CarriedLeft)
	end)
end

G_onFrameJobs["CheckIfTorchHotkeyIsInstalled"] = function()
	if input.actions['Light'] then
		input.registerActionHandler('Light', async:callback(function()
			lightHotkey()
		end))
	end
	G_onFrameJobs["CheckIfTorchHotkeyIsInstalled"] = nil
end

local function syncDatabases(data)
	G_liquids = data[1]
	--G_stews = data[2]
end

local function refreshInventory()
	if I.UI.getMode() == "Interface" then
		I.UI.setMode()
		I.UI.setMode("Interface")
	end
end

------------------------------------------------------------------------------------------------------------

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Event handlers                                                     │
-- ╰────────────────────────────────────────────────────────────────────╯

G_eventHandlers.UiModeChanged = UiModeChanged                                   -- (data) {oldMode, newMode}
G_eventHandlers.SunsDusk_ActivatedBed = activatedBed                           -- (bed) game object
G_eventHandlers.NSS_showMessage = NSS_preventedSleeping                        -- (bed) game object, from Daisy's sleep mod
G_eventHandlers.SunsDusk_RegisterCompanion = becameCompanion                   -- (actor) game object
G_eventHandlers.SunsDusk_ReleaseCompanion = releasedCompanion                  -- (actor) game object
G_eventHandlers.SunsDusk_WaterBottles_consumedWater = onConsumedWater          -- (liquid) string: "water" | "susWater"
G_eventHandlers.SunsDusk_messageBox = messageBox                               -- (level, ...) or {level, ...strings}
G_eventHandlers.SunsDusk_landedHit = landedHit                                 -- (data) {target, attack}
G_eventHandlers.SunsDusk_landedSpellHit = landedSpellHit                       -- (data) {target, activeSpellId}
G_eventHandlers.SunsDusk_checkedIfVampireWerewolf = checkedIfVampireWerewolf   -- (values) {vampireStatus, werewolfStatus}
G_eventHandlers.SunsDusk_addConsumable = event_addConsumable                   -- (data) {recordId, consumableTable}
G_eventHandlers.SunsDusk_receiveCellInfo = receiveCellInfo                     -- (data) cellInfo table from g_cellInfo
G_eventHandlers.SunsDusk_playSound = playSound                                 -- (sound) string
G_eventHandlers.SunsDusk_equippedArmor = equippedArmor                         -- (armor) game object
G_eventHandlers.SunsDusk_registerFire = registeredFire                         -- (fire) game object
G_eventHandlers.LH_lightEquipped = lightHotkey                                 -- () no params, from Light Hotkey mod
G_eventHandlers.SunsDusk_syncDatabases = syncDatabases                         -- (data) {liquidsDB}
G_eventHandlers.SunsDusk_miscUsed = onMiscUsed                                 -- (item) game object
G_eventHandlers.SunsDusk_refreshTooltips = G_refreshTooltips                   -- ()
G_eventHandlers.SunsDusk_refreshInventory = refreshInventory                   -- ()
G_eventHandlers.SunsDusk_errorDetection = errorDetection                       -- (data) {message, error}
-- MISSING: sent but unhandled --
--G_eventHandlers.SunsDusk_finishedBath                                        -- () sent from p_clean
--G_eventHandlers.SunsDusk_attackedTree                                        -- (data) {target, progressData}, sent from p_woodcutting
--G_eventHandlers.SunsDusk_actorDied                                           -- (actor) game object, sent from sd_a
--G_eventHandlers.Audiobooks2_listenedOneSecond                                -- (data) {currentBookId, currentTime, totalDuration}

local function onControllerButtonPress(keyCode)
	for _, job in pairs(G_controllerButtonPressJobs) do
		job(keyCode)
	end
end

local function onControllerButtonRelease(keyCode)
	for _, job in pairs(G_controllerButtonReleaseJobs) do
		job(keyCode)
	end
end

local function onKeyPress(key)
	for _, job in pairs(G_keyPressJobs) do
		job(key.code)
	end
end

local function onKeyRelease(key)
	for _, job in pairs(G_keyReleaseJobs) do
		job(key.code)
	end
end

--local function onKeyPress(key)
--	if not G_raycastResultType then return end
--	
--	local obj = G_raycastResult.hitObject
--	
--	if key.symbol == "1" then
--		core.sendGlobalEvent("scaleUp", G_raycastResult.hitObject)
--	elseif key.symbol == "2" then
--		core.sendGlobalEvent("scaleDown", G_raycastResult.hitObject)
--	elseif key.symbol == "3" then
--		core.sendGlobalEvent("moveUp", G_raycastResult.hitObject)
--	elseif key.symbol == "4" then
--		core.sendGlobalEvent("moveDown", G_raycastResult.hitObject)
--	elseif key.symbol == "5" then
--		core.sendGlobalEvent("toggleBlacklist", G_raycastResult.hitObject)
--	elseif key.code == input.KEY.LeftArrow then
--		core.sendGlobalEvent("moveLeft", G_raycastResult.hitObject)
--	elseif key.code == input.KEY.RightArrow then
--		core.sendGlobalEvent("moveRight", G_raycastResult.hitObject)
--	elseif key.code == input.KEY.UpArrow then
--		core.sendGlobalEvent("moveForward", G_raycastResult.hitObject)
--	elseif key.code == input.KEY.DownArrow then
--		core.sendGlobalEvent("moveBack", G_raycastResult.hitObject)
--	elseif key.symbol == "0" then
--		core.sendGlobalEvent("printAllOffsets")
--	end
--end

-- sd = I.SunsDusk.getSaveData()
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
		onControllerButtonPress = onControllerButtonPress,
		onControllerButtonRelease = onControllerButtonRelease,
		onKeyPress = onKeyPress,
		onKeyRelease = onKeyRelease,
	},
	eventHandlers = G_eventHandlers,
	interfaceName = "SunsDusk",
	interface = {
		version = 5,
		addConsumable = API_addConsumable,
		-- exterior temperatures before any modifiers (such as race and equipment are applied)
		getTrueExternalTemperature = function()
			return G_trueExteriorTempString
		end,
		-- current player temperature after all modifiers are applied
		getPlayerCurrentTemperature = function()
			return G_playerCurrentTempString
		end,
		getPlayerTargetTemperature = function()
			return G_playerTargetTempString
		end,
		getPlayerTemperatureBuff = function()
			return G_playerTempBuffString
		end,
		getIsWet = function()
			return G_SW_isWet
		end,
		getSaveData = function()
			return saveData
		end,
		getCellInfo = function()
			return G_cellInfo
		end,
		cellInfo = G_cellInfo,
		isConsumable = function(obj)
			local recordId = type(obj) == "string" and obj or obj.recordId
			local typ = nil
			local ret = nil
			if saveData.registeredConsumables[recordId] then
				typ = "cooked"
				ret = saveData.registeredConsumables[recordId]
			elseif dbConsumables[recordId] then
				typ = "database"
				ret = dbConsumables[recordId]
			end
			return ret, typ
		end,
		-- Register a function that returns how much wood spawns
		-- ctx: { woodCount, originalWoodCount, item, tree, treeSize, toolValue, skill, difficulty }
		addWoodCountModifier = function(fn)
			if type(fn) ~= "function" then
				error("addWoodCountModifier expects a function", 2)
			end
			table.insert(G_woodcutting_woodCountHandlers, fn)
			return fn
		end,
		removeWoodCountModifier = function(fn)
			for i, f in ipairs(G_woodcutting_woodCountHandlers) do
				if f == fn then
					table.remove(G_woodcutting_woodCountHandlers, i)
					return true
				end
			end
			return false
		end,
		-- force-recompute buffs/widgets for one need ("thirst"|"hunger"|"sleep"|"temp") or all when needId is nil
		refreshNeeds = function(needId)
			G_refreshNeeds(needId)
		end,

	--	getGlobals = function()
	--		return _G
	--	end
	}
}