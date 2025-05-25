local core = require('openmw.core')
local nearby = require("openmw.nearby")
local I = require("openmw.interfaces")
local self = require("openmw.self")
local storage = require("openmw.storage")
local DynamicStats = require('openmw.types').Actor.stats.dynamic

local MOD_ID = "RestAndSleepRecoveryOptions"

I.Settings.registerPage {
    key = MOD_ID,
    l10n = MOD_ID,
    name = "Rest and Sleep Recovery Options",
    description =
	"Choose which stats to recover based on whether you are sleeping in a bed or resting.\n\n!!! WARNING !!!\nThe mod will simply try to restore the stats to their previous values following a short delay after sleeping or resting.\nThere might be unexpected events that cause the mod to fail, or even mess up your stats."
}

I.Settings.registerGroup {
	order = 0,
    key = "GeneralSettings" .. MOD_ID,
    page = MOD_ID,
    l10n = MOD_ID,
    name = "General",
    description = "",
    permanentStorage = true,
    settings = {
        {
            key = "modEnabled",
            renderer = "checkbox",
            name = "Enable Mod",
            description = "If enabled, the settings below will apply.",
            default = true
        },
		{
            key = "restoreDelay",
            renderer = "number",
			argument = { min = 0 },
            name = "Restore delay (seconds)",
            description = "The time that passes between the closure of the Rest / Sleep window and the restoration of your stats.",
            default = 0.5
        },
    }
}

I.Settings.registerGroup {
	order = 1,
    key = "RestSettings" .. MOD_ID,
    page = MOD_ID,
    l10n = MOD_ID,
    name = "Rest",
    description = "",
    permanentStorage = true,
    settings = {
		{
			key = "recoverHealthOnRest",
            renderer = "checkbox",
            name = "Recover health on rest",
            description = "If enabled, health will recover when resting.\n(Or when sleeping in some bed the mod doesn't cover.)",
            default = true
		},
		{
			key = "recoverMagickaOnRest",
            renderer = "checkbox",
            name = "Recover magicka on rest",
            description = "If enabled, magicka will recover when resting.\n(Or when sleeping in some bed the mod doesn't cover.)",
            default = true
		},
		{
			key = "recoverFatigueOnRest",
            renderer = "checkbox",
            name = "Recover fatigue on rest",
            description = "If enabled, fatigue will recover when resting.\nOr when sleeping in some bed the mod doesn't cover.)",
            default = true
		},
    }
}

I.Settings.registerGroup {
	order = 2,
    key = "RegularSleepSettings" .. MOD_ID,
    page = MOD_ID,
    l10n = MOD_ID,
    name = "Sleep (regular beds)",
    description = "",
    permanentStorage = true,
    settings = {
		{
			key = "recoverHealthOnSleep",
            renderer = "checkbox",
            name = "Recover health on sleep",
            description = "If enabled, health will recover when sleeping in (or resting near) a bed.",
            default = true
		},
		{
			key = "recoverMagickaOnSleep",
            renderer = "checkbox",
            name = "Recover magicka on sleep",
            description = "If enabled, magicka will recover when sleeping in (or resting near) a bed.",
            default = true
		},
		{
			key = "recoverFatigueOnSleep",
            renderer = "checkbox",
            name = "Recover fatigue on sleep",
            description = "If enabled, fatigue will recover when sleeping in (or resting near) a bed.",
            default = true
		},
		{
			key = "regularBeds",
            renderer = "textLine",
            name = "Additional bed IDs",
            description = "You can include additional bed IDs to search for when detecting nearby beds. Open the console and click an item to see its ID, then type the ID here in lowercase. Separate IDs by a comma (,) without spaces.",
            default = ""
		},
    }
}

I.Settings.registerGroup {
	order = 3,
    key = "PortableSleepSettings" .. MOD_ID,
    page = MOD_ID,
    l10n = MOD_ID,
    name = "Sleep (portable beds)",
    description = "You can set different behaviour for portable beds if you have any camping mods like Frostwind installed. If not recognized, they act as resting. Add them below so the portable bed settings apply to them.",
    permanentStorage = true,
    settings = {
		{
			key = "recoverHealthOnSleepPortable",
            renderer = "checkbox",
            name = "Recover health when sleeping in a portable bed",
            description = "If enabled, health will recover when sleeping in (or resting near) a portable bed.",
            default = true
		},
		{
			key = "recoverMagickaOnSleepPortable",
            renderer = "checkbox",
            name = "Recover magicka when sleeping in a portable bed",
            description = "If enabled, magicka will recover when sleeping in (or resting near) a portable bed.",
            default = true
		},
		{
			key = "recoverFatigueOnSleepPortable",
            renderer = "checkbox",
            name = "Recover fatigue when sleeping in a portable bed",
            description = "If enabled, fatigue will recover when sleeping in (or resting near) a portable bed.",
            default = true
		},
		{
			key = "portableBeds",
            renderer = "textLine",
            name = "Portable bed IDs",
            description = "You can specify the IDs of portable beds to search for when detecting nearby beds. Open the console and click an item to see its ID, then type the ID here in lowercase. Separate IDs by a comma (,) without spaces.",
            default = "a_bed_roll,a_bed_covered_activator,nom_bedroll_activator"
		},
    }
}

local generalSettings = storage.playerSection("GeneralSettings" .. MOD_ID)
local restSettings = storage.playerSection("RestSettings" .. MOD_ID)
local regularSleepSettings = storage.playerSection("RegularSleepSettings" .. MOD_ID)
local portableSleepSettings = storage.playerSection("PortableSleepSettings" .. MOD_ID)

local function modEnabled()
	return generalSettings:get("modEnabled")
end

local function calcDistance(vector1, vector2)
    local dx = vector2.x - vector1.x
    local dy = vector2.y - vector1.y
    local dz = vector2.z - vector1.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function splitString(input, delimiter)
    local result = {}
    for match in (input .. delimiter):gmatch("(.-)" .. delimiter) do
        table.insert(result, match)
    end
    return result
end

local hasNearbyRegularBed = false
local hasNearbyPortableBed = false

local function detectBeds()
	hasNearbyRegularBed = false
	hasNearbyPortableBed = false
	
	local regularBedsString = regularSleepSettings:get("regularBeds")
	local portableBedsString = portableSleepSettings:get("portableBeds")
	
	local regularBedIds = {}
	if regularBedsString ~= "" then
		regularBedIds = splitString(regularBedsString, ",")
	end
	
	local portableBedIds = {}
	if portableBedsString ~= "" then
		portableBedIds = splitString(portableBedsString, ",")
	end
	
	for _, item in ipairs(nearby.items) do
		local record = item.type.record(item)
        local dist = calcDistance(self.position, item.position)
		
		if dist > 250 then goto continue_item_search end
		
		for _, bedId in ipairs(regularBedIds) do
			if record.id == bedId then
				hasNearbyRegularBed = true
			end
		end
		
		for _, bedId in ipairs(portableBedIds) do
			if record.id == bedId then
				hasNearbyPortableBed = true
			end
		end
		::continue_item_search::
	end
	
	for _, activator in ipairs(nearby.activators) do
        local record = activator.type.record(activator)
        local script = record.mwscript
		local dist = calcDistance(self.position, activator.position)
		
		if dist > 250 then goto continue_activator_search end
		 
        local isVanillaBed = record.name == "Bed" or script == "bed_standard" -- vanilla beds
		
		if isVanillaBed then
			hasNearbyRegularBed = true
		end
		
		for _, bedId in ipairs(regularBedIds) do
			if record.id == bedId then
				hasNearbyRegularBed = true
			end
		end
		
		for _, bedId in ipairs(portableBedIds) do
			if record.id == bedId then
				hasNearbyPortableBed = true
			end
		end
		::continue_activator_search::
    end
end

local healthBeforeRest = -1
local magickaBeforeRest = -1
local fatigueBeforeRest = -1

local function clearSavedStats()
	healthBeforeRest = -1
	magickaBeforeRest = -1
	fatigueBeforeRest = -1
end

local function saveDynamicStats()
	clearSavedStats()
	
	detectBeds()
	
	if hasNearbyRegularBed then
		-- sleeping in regular bed
		if not regularSleepSettings:get("recoverHealthOnSleep") then
			healthBeforeRest = math.floor(DynamicStats.health(self).current)
		end
		if not regularSleepSettings:get("recoverMagickaOnSleep") then
			magickaBeforeRest = math.floor(DynamicStats.magicka(self).current)
		end
		if not regularSleepSettings:get("recoverFatigueOnSleep") then
			fatigueBeforeRest = math.floor(DynamicStats.fatigue(self).current)
		end
	elseif hasNearbyPortableBed then
		-- sleeping in portable bed
		if not portableSleepSettings:get("recoverHealthOnSleepPortable") then
			healthBeforeRest = math.floor(DynamicStats.health(self).current)
		end
		if not portableSleepSettings:get("recoverMagickaOnSleepPortable") then
			magickaBeforeRest = math.floor(DynamicStats.magicka(self).current)
		end
		if not portableSleepSettings:get("recoverFatigueOnSleepPortable") then
			fatigueBeforeRest = math.floor(DynamicStats.fatigue(self).current)
		end
	else
		-- resting
		if not restSettings:get("recoverHealthOnRest") then
			healthBeforeRest = math.floor(DynamicStats.health(self).current)
		end
		if not restSettings:get("recoverMagickaOnRest") then
			magickaBeforeRest = math.floor(DynamicStats.magicka(self).current)
		end
		if not restSettings:get("recoverFatigueOnRest") then
			fatigueBeforeRest = math.floor(DynamicStats.fatigue(self).current)
		end
	end
	
	if healthBeforeRest ~= -1 then
		print("Saved Health: ", healthBeforeRest)
	end
	if magickaBeforeRest ~= -1 then
		print("Saved Magicka: ", magickaBeforeRest)
	end
	if fatigueBeforeRest ~= -1 then
		print("Saved Fatigue: ", fatigueBeforeRest)
	end
end

local function loadDynamicStats()
	if healthBeforeRest > 0 then
		DynamicStats.health(self).current = healthBeforeRest
		print("Restored HP: ", healthBeforeRest)
	end
	
	if magickaBeforeRest > 0 then
		DynamicStats.magicka(self).current = magickaBeforeRest
		print("Restored Magicka: ", magickaBeforeRest)
	end
	
	if fatigueBeforeRest > 0 then
		DynamicStats.fatigue(self).current = fatigueBeforeRest
		print("Restored Fatigue: ", fatigueBeforeRest)
	end
end

local resting = false
local loadStats = false
local restEndTimeSec = -1

local function onUiModeChange(data)
	if not modEnabled() then return end
	
	if not resting and data.oldMode == "Rest" and data.newMode == "Loading" then
		-- Rest started
		saveDynamicStats()
		resting = true
		return
	end
	
	if resting and data.oldMode == "Rest" and data.newMode == nil then
		-- Rest ended
		restEndTimeSec = core.getRealTime()
		resting = false
		loadStats = true
		return
	end
end

local function onUpdate()
	if not loadStats then return end

	local currentTimeSec = core.getRealTime()
	
	if currentTimeSec > restEndTimeSec + generalSettings:get("restoreDelay") then
		loadDynamicStats()
		loadStats = false
	end
end

return {
    eventHandlers = {
        UiModeChanged = onUiModeChange
    },
	engineHandlers = {
        onUpdate = onUpdate
	}
}