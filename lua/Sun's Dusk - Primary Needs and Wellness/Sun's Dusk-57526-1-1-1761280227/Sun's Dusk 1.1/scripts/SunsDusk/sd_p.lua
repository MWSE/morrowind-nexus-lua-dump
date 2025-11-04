--[[
╭──────────────────────────────────────────────────────────────────────╮
│  Sun's Dusk : Player Runtime                      		           │
│  orchestrate per-minute/hour jobs, UI hooks, rain/water checks       │
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
-- │ Job registries : add modules here              	                │
-- ╰────────────────────────────────────────────────────────────────────╯
--- FOR MODDING THIS MOD ---
perHourJobs = {}
perMinuteJobs = {}
mousewheelJobs = {}
UiModeChangedJobs = {}
onLoadJobs = {}
refreshWidgetJobs = {}
onFrameJobs = {}
onFrameJobsSluggish = {}
onFrameJobsSluggishIterator = nil
cellChangedJobs = {}
onConsumeJobs = {}
settingsChangedJobs = {}
onConsumedWaterJobs = {}
raycastResult = {}
raycastChangedJobs = {}
onPlayerInfoChangedJobs = {}
landedHitJobs = {}
landedSpellHitJobs = {}
eventHandlers  = {}


lastRaycastHitObject = nil
isInWater = 0
uiWidgets = {}




-- ─────────────────────────────────────────────────────────────────────────────── Libraries ───────────────────────────────────────────────────────────────────────────────
isSleeping = false
CLOCK_OFFSET = 0
local hasActivatedBed = false


-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Texture pack discovery (Before settings)                           │
-- ╰────────────────────────────────────────────────────────────────────╯
require('scripts.SunsDusk.sd_loadTexturePacks')


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
		
		for _, func in pairs(refreshWidgetJobs) do
			func(minute)
		end
		
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
		log(3, "[SD] Loaded "..require_path)
		require(require_path)
	end
end


-- ─────────────────────────────────────────────────────────────────────────────── UI ─────────────────────────────────────────────────────────────────────────────────────
-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Global Style                                                       │
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
makeBorder = require("scripts.SunsDusk.ui_makeborder") 
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


-- ─────────────────────────────────────────────────────────────────────────────── on Update ────────────────────────────────────────────────────────────────────────────────
-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Weather + rain sensing                                             │
-- ╰────────────────────────────────────────────────────────────────────╯

-- Cache once to avoid repeated checks
local WEATHER_API_AVAILABLE = core.weather and core.weather.getCurrent

-- Optional one-time log
 if not WEATHER_API_AVAILABLE then
     -- why: inform users on older OpenMW that rain hydration is disabled
    log(1, "[SunsDusk] Weather API not available (OpenMW < 0.50). Some features like Argonian rain hydration disabled.")
 end

-- Use feature detection + sky guard
local function inRainCheck()
    if not WEATHER_API_AVAILABLE then
        return false -- on 0.49 and older
    end
    local cell = self and self.cell
    if not cell or not cell.hasSky then
		--print("not in rain 1")
        return false
    end
    local ok, w = pcall(core.weather.getCurrent, cell)
    if not ok or not w then
		--print("not in rain 2")
        return false
    end
	local playerPos = self.position + v3(0,0,20)
	local skyPos = self.position + v3(0,0,1500)
	local ray = nearby.castRay(playerPos, skyPos, { collisionType = nearby.COLLISION_TYPE.AnyPhysical, ignore = self })

	if ray.hit then
		--print("not in rain 3")
		return false
	end
    -- treat as rain if weather defines rain visuals
    if w.rainEffect ~= nil then 
		--print("in rain 4")
		return true 
	end
    if w.rainMaxRaindrops and w.rainMaxRaindrops > 0 then 
		--print("in rain 5") 
		return true 
	end
    return false
end
table.insert(perMinuteJobs, inRainCheck)

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ In water                                              		        │
-- ╰────────────────────────────────────────────────────────────────────╯
local function inWaterCheck()
   	local npcRecord = types.NPC.record(self)
	if npcRecord then
		if npcRecord.isMale then
			noseLevel = types.NPC.races.record(npcRecord.race).height.male*147.79
		else
			noseLevel = types.NPC.races.record(npcRecord.race).height.female*147.79
		end
	end
	local waterLevel = self.cell.waterLevel or -99999999
	isInWater = math.max(0,math.min(1, (-self.position.z+waterLevel)/noseLevel))
	--print(isInWater.." in water")
end
table.insert(onFrameJobsSluggish, inWaterCheck)

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Night Creature checks                                              │
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
-- │ Main logic loop                                                    │
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
-- │ Consumption events                                                 │
-- ╰────────────────────────────────────────────────────────────────────╯
local function onConsume(item)
	for _, func in pairs(onConsumeJobs) do
		func(item)
	end	
end

local function onConsumedWater(liquid)
	for _, func in pairs(onConsumedWaterJobs) do
		func(liquid)
	end	
end

local function onUpdate(dt)
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
        end
    end
end

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Frame + update drivers                                             │
-- ╰────────────────────────────────────────────────────────────────────╯
local function onUpdate(dt)
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
        end
    end
end

local function onFrame(dt)
	--print(1)
	for _, func in pairs(onFrameJobs) do
		func(dt)
	end
	-- onFrame Sluggish
	local currentJob
	onFrameJobsSluggishIterator, currentJob = next(onFrameJobsSluggish, onFrameJobsSluggishIterator)
	if not onFrameJobsSluggishIterator then
		onFrameJobsSluggishIterator, currentJob = next(onFrameJobsSluggish)
	end
	currentJob(dt)
	
	local cameraPos = camera.getPosition()
	local iMaxActivateDist = core.getGMST("iMaxActivateDist")+0.1
	local activationDistance = iMaxActivateDist + camera.getThirdPersonDistance()
	local telekinesis = types.Actor.activeEffects(self):getEffect(core.magic.EFFECT_TYPE.Telekinesis)
	if telekinesis then
		activationDistance = activationDistance + telekinesis.magnitude * 22
	end
	raycastResult = nearby.castRenderingRay(
		cameraPos,
		cameraPos + camera.viewportToWorldVector(v2(0.5,0.5)) * activationDistance,
		{ ignore = self }
	)
	if raycastResult.hitObject ~= lastRaycastHitObject then
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
-- │ Combat mechanics                                                   │
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
-- │ UI mode flow · sleep begins and ends here                          │
-- ╰────────────────────────────────────────────────────────────────────╯
local function UiModeChanged(data)
	
	log(4, "ui mode "..tostring(data.oldMode).." -> " .. tostring(data.newMode), data.arg)
	-- actual sleeping logic
	if data.newMode == "Rest" and (data.arg or hasActivatedBed or not self.cell:hasTag("NoSleep")) and not saveData.playerInfo.isInWerewolfForm then
		log(3,"[SD] start sleep")
		isSleeping = true
		hasActivatedBed = false
	end
	mainLogic()
	if data.newMode == nil then --can happen when traveling (fixed for singleplayer)
		if isSleeping then
			log(3,"[SD] end sleep")
			isSleeping = false
			core.sendGlobalEvent("SunsDusk_checkIfVampireWerewolf", self)
		end
		hasActivatedBed = false
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
-- │ Companion counters                                                 │
-- ╰────────────────────────────────────────────────────────────────────╯
local function releasedCompanion(actor)
	saveData.companions[actor.id] = nil
	local count = 0
	saveData.specialCompanion = false
	for i,actor in pairs(saveData.companions) do
		if actor.recordId == "your love" then
			saveData.specialCompanion = true
		end
		count = count + 1
	end
	saveData.countCompanions = count
end

local function becameCompanion(actor)
	saveData.companions[actor.id] = actor
	local count = 0
	saveData.specialCompanion = false
	for i,actor in pairs(saveData.companions) do
		if actor.recordId == "your love" then
			saveData.specialCompanion = true
		end
		count = count + 1
	end
	saveData.countCompanions = count	
end

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Misc helpers                                                       │
-- ╰────────────────────────────────────────────────────────────────────╯
local function messageBox(str)
	ui.showMessage(str)
end


-- ─────────────────────────────────────────────────────────────────────────────── LifeCycle ───────────────────────────────────────────────────────────────────────────────

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Player info refresh + races, forms, flags                          │
-- ╰────────────────────────────────────────────────────────────────────╯
-- onInit and on uiModeChange from ChargenRace

function refreshPlayerInfo()
    local raceId = types.NPC.record(self).race -- record id key
    local raceRec = types.NPC.races.records[raceId]
    local name = tostring(raceId):lower()
    if not saveData.playerInfo then
		saveData.playerInfo = {}
	end
	
	local classId = types.NPC.record(self).class
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
	
	saveData.playerInfo.isBeast = raceRec and raceRec.isBeast or false
	saveData.playerInfo.isOrc = name:find("orc", 1, true) ~= nil
	saveData.playerInfo.isBosmer = name:find("bosmer", 1, true) ~= nil or name:find("wood elf", 1, true) ~= nil
	saveData.playerInfo.isAltmer = name:find("altmer", 1, true) ~= nil or name:find("high elf", 1, true) ~= nil
	saveData.playerInfo.isImperial = name:find("imperial", 1, true) ~= nil
	saveData.playerInfo.isDunmer = name:find("dunmer", 1, true) ~= nil
	saveData.playerInfo.isRedguard = name:find("redguard", 1, true) ~= nil
	saveData.playerInfo.isFarmingTool = name:find("argonian", 1, true) ~= nil
	saveData.playerInfo.isInWerewolfForm = types.NPC.isWerewolf(self) -- isInWerewolfFormCheck()
	
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




-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Save/load + external API                                           │
-- ╰────────────────────────────────────────────────────────────────────╯
local function onLoad(data)
	local originalData = data
	saveData = data or {
		companions = {},
		countCompanions = 0,
		--specialCompanion = nil,
		lastUpdate = math.floor(calendar.gameTime()/time.minute),
		--m_sleep = {},  -- defined in module
		--m_hunger = {}, -- defined in module
		--m_thirst = {}, -- defined in module
		version = 3,
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
	if not saveData.version then
		saveData.version = 2
		refreshPlayerInfo()
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
	end
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
		func(originalData)
	end
end

local function onSave()
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

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Event handlers                                                     │
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

return {
	engineHandlers = {
		onUpdate = onUpdate,
		onFrame = onFrame,
		onInit = onLoad,
		onLoad = onLoad,
		onSave = onSave,
		onMouseWheel = onMouseWheel,
		onConsume = onConsume,		
	},
	eventHandlers = eventHandlers,
	interfaceName = "SunsDusk",
	interface = {
		version = 1,
		addConsumable = API_addConsumable,
	}
}
