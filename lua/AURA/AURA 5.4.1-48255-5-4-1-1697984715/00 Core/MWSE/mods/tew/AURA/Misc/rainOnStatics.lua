local cellData = require("tew.AURA.cellData")
local common = require("tew.AURA.common")
local config = require("tew.AURA.config")
local moduleData = require("tew.AURA.moduleData")
local sounds = require("tew.AURA.sounds")
local soundData = require("tew.AURA.soundData")
local debugLog = common.debugLog
local fader = require("tew.AURA.fader")

local WtC
local mainTimer
local playerRef
local playingBlocked
local staticsCache = {}
local currentShelter = {}
local moduleName = "rainOnStatics"

local INTERVAL = 0.55 -- The lower this value, the snappier the fades

local rainyStatics = {
	"flag",
	"tent",
	"drs_tnt",
	"a1_dat_srt_ext", -- Sea Rover's Tent
	"skin",
	"shed", -- sheds are generally made out of wood, but so are some awnings
	"fabric",
	"awning",
	"banner",
	"_ban_", -- also banner
	"overhang",
	"marketstand", -- relevant Tamriel_Data and OAAB_Data assets
	"gather",
}

local shelterStatics = {
	"tent",
	"shed",
	"overhang",
	"awning",
}

local blockedStatics = {
	"bannerpost",
	"_at_banner", -- On the move bannerpost
	"hanger",
	"ex_ashl_banner", -- vanilla bannerpost
	"flagpole",
	"flagon", -- OAAB_Data
	"aaa_refernce_flag", -- ?
	"crushed",
	"houseshed",
	"setsky_x_shed", -- Tamriel_Data house addon
}

local rayTestIgnoreStatics = {
	-- If a rayTest result matches either one of these, it will ignore it
	-- and move on to the next result. e.g.: A banner can't be sheltered
	-- by the railing it hangs from, or by another banner. (Inception!)
	"signpost",
	"signpole",
	"_pole",
	"railing",
	"hanger",
	"banner",
	"_ban_",
	"flag",
	"hv_de_setveloth_beam_01", -- wood log used as a flag hanger in Heart of the Velothi - Gnisis
	"ex_t_brace_01", -- used as a banner hanger
}

local exemptedFromShelteredTest = {
	-- We want these to play a loop no matter where they are placed
	-- in the world. That means no rayTest to check if they are
	-- sheltered by another object.

	-- RayTest results for awnings may return some false positives
	-- e.g. only a small edge of an awning may happen to be sheltered
	-- by a larger structure, and we shouln't really care about that.
	-- (see ex_common_awning_wood_01 in vanilla Ebonheart)

	"awning",

	-- A portable tent can be tricky to deal with because
	-- for instance if placed under a leafless tree, then
	-- isRefSheltered() is likely to return true, but
	-- technically speaking, rain should still be able to hit it.

	--"ashfall_tent",
}

local function isRelevantRef(ref)
	-- We are interested in both statics and activators. Skipping location
	-- markers because they are invisible in-game. Also checking if
	-- the ref is deleted because even if they are, they get caught by
	-- cell:iterateReferences. As for ref.disabled, some mods disable
	-- instead of delete refs, but it's actually useful if used correctly.
	-- Gotta be extra careful not to call this function when a ref is
	-- deactivated, because its "disabled" property will be true.
	-- Also skipping refs with no implicit tempData tables because they're
	-- most likely not interesting to us. A location marker is one of them.
	if ref.object
	and ((ref.object.objectType == tes3.objectType.static) or
		((ref.object.objectType == tes3.objectType.activator)))
	and (not ref.object.isLocationMarker)
	and (not (ref.deleted or ref.disabled))
	and (ref.tempData)
	then
		if common.getMatch(blockedStatics, ref.object.id:lower()) then
			debugLog("Skipping blocked static: " .. tostring(ref))
			return false
		end
		if common.getMatch(rainyStatics, ref.object.id:lower()) then
			return true
		end
	end
	return false
end

local function removeSound(ref)
	for _, track in pairs(soundData.interiorRainLoops["ten"]) do
		if tes3.getSoundPlaying{ sound = track, reference = ref } then
			debugLog("Track " .. track.id .. " playing on ref " .. tostring(ref) .. ", now removing it.")
			tes3.removeSound{ sound = track, reference = ref }
		end
	end
end

local function isRainLoopSoundPlaying()
    if WtC.currentWeather
	and WtC.currentWeather.rainLoopSound
	and WtC.currentWeather.rainLoopSound:isPlaying() then
        return true
    else
        return false
    end
end

local function clearCurrentShelter()
	if currentShelter.sound then
		debugLog(currentShelter.sound.id .. " playing on playerRef. Running fadeOut.")
		sounds.remove{
			module = moduleName,
			volume = currentShelter.volume,
			reference = playerRef,
			duration = 2,
		}
		currentShelter.ref = nil
		currentShelter.sound = nil
		currentShelter.volume = nil
	end
end

local function addToCache(ref)
	-- Resetting the timer on every add to kind of block it
	-- from running while the cache is being populated.
	if mainTimer then mainTimer:reset() end
	if (not isRelevantRef(ref)) or (common.cellIsInterior(ref.cell)) then
		return
	end
	-- We only add a static to the cache if it's not already in there.
	if not table.find(staticsCache, ref) then
		if not ref.tempData.tew then
			ref.tempData.tew = {}
		end
		-- Adding (bool) sheltered temp data to every static in the cache
		-- so that we later know whether to add a sound to it or not.
		if not common.getMatch(exemptedFromShelteredTest, ref.object.id:lower()) then
			ref.tempData.tew.sheltered = common.isRefSheltered{originRef = ref, ignoreList = rayTestIgnoreStatics}
		end
		table.insert(staticsCache, ref)
		debugLog("Added static " .. tostring(ref) .. " to cache. staticsCache: " .. #staticsCache)
	else
		debugLog("Already in cache: " .. tostring(ref))
	end
end

local function removeFromCache(ref)
	-- Same logic as above, just backwards.
	-- Make sure not to call isRelevantRef() here.

	if mainTimer then mainTimer:reset() end
	if (#staticsCache == 0) then return end

	-- We need the ref's index for table.remove()
	local index = table.find(staticsCache, ref)
	if not index then return end

	removeSound(ref)
	table.remove(staticsCache, index)
	if (currentShelter.ref)
	and (currentShelter.ref == ref) then
		-- Immediately removing playerRef sound.
		removeSound(playerRef)
		currentShelter.ref = nil
		currentShelter.volume = nil
		currentShelter.sound = nil
	end
	debugLog("Removed static " .. tostring(ref) .. " from cache. staticsCache: " .. #staticsCache)
end

-- Decide whether to add or remove sounds depending on weather type, distance to ref,
-- whilst also checking if the player (or the ref itself) is sheltered.
local function processRef(ref)
	local sound = soundData.interiorWeather["ten"][WtC.currentWeather.index]
    local rainType = cellData.rainType[WtC.currentWeather.index]
	if not (sound and rainType) then return end

	if ref.tempData.tew then
		if ref.tempData.tew.sheltered then
			-- Current ref is sheltered by another object. Moving on.
			return
		end
	end

	if fader.isRunning(moduleName) then return end

	local playerPos = tes3.player.position:copy()
	local refPos = ref.position:copy()
	local objId = ref.object.id:lower()
    local pitch = moduleData[moduleName].soundConfig[rainType][WtC.currentWeather.index].pitch

	-- Check if sheltered by current ref.
	-- If we are, then either fadeIn or crossFade.

	if (not currentShelter.ref)
	and (common.getMatch(shelterStatics, objId))
	and (playerPos:distance(refPos) < 280)
	and (common.isRefSheltered{targetRef = ref, ignoreList = rayTestIgnoreStatics}) then
		debugLog("Player sheltered.")
		if not tes3.getSoundPlaying{sound = sound, reference = ref} then
			debugLog("[sheltered] Sound not playing on shelter ref. Running fadeIn.")
			sounds.play{
				module = moduleName,
				pitch = pitch,
				newRef = playerRef,
				newTrack = sound,
				duration = 0.7,
			}
		else
			debugLog("[sheltered] Sound playing on shelter ref. Running crossfade.")
			sounds.play{
				module = moduleName,
				pitch = pitch,
				oldRef = ref,
				newRef = playerRef,
				oldTrack = sound,
				newTrack = sound,
				duration = 0.7,
			}
		end
		-- Also add data to our new shelter so that we remove playerRef
		-- sound correctly when player is no longer sheltered by this ref.
		currentShelter.ref = ref
		currentShelter.sound = sound
		currentShelter.volume = volume
		return
	end

	-- If we're currently sheltered, then keep checking until not we're not
	-- sheltered anymore. If we're currently not sheltered, get rid of the
	-- sound playing on playerRef. Can choose between crossfade or fade out.
	-- For now, just fade out and let a subsequent call to this function add
	-- ref sound when the fade has finished.

	if (currentShelter.ref == ref)
	and (not common.isRefSheltered{originRef = playerRef, targetRef = ref}) then
		debugLog("[not sheltered] Running fadeOut.")
		sounds.remove{
			module = moduleName,
			volume = volume,
			reference = playerRef,
			duration = 0.7,
		}
		-- Since we're no longer sheltered, let's clear shelter data.
		currentShelter.ref = nil
		currentShelter.sound = nil
		currentShelter.volume = nil
		return
	end

	-- If current ref isn't a viable shelter then just add ref sound.

	if (not currentShelter.ref)
		and (not tes3.getSoundPlaying{sound = sound, reference = ref})
		and (playerPos:distance(refPos) < 800) then
		debugLog("Adding sound " .. sound.id .. " for -> " .. objId)
        sounds.playImmediate{
            module = moduleName,
            track = sound,
			reference = ref,
			pitch = pitch, 
        }
	end
end

local function tick()
	if fader.isRunning(moduleName) then
		debugLog("Fader is running. Returning.")
		return
	end
	if isRainLoopSoundPlaying() then
		playingBlocked = false
		for _, ref in ipairs(staticsCache) do
			processRef(ref)
		end
	else
		if (not playingBlocked) and (#staticsCache > 0) then
			-- Best not to clear the cache if it's not raining.
			-- Just remove any sounds that are currently playing.
			debugLog("Not raining. Removing sounds.")
			for _, ref in ipairs(staticsCache) do
				removeSound(ref)
			end
			clearCurrentShelter()
			playingBlocked = true
		end
	end
end

local function refreshCache()
	local cell = tes3.getPlayerCell()
	if common.cellIsInterior(cell) then return end
	debugLog("Commencing dump!")
	for ref in cell:iterateReferences() do
		addToCache(ref)
	end
	debugLog("staticsCache currently holds " .. #staticsCache .. " statics.")
end

local function onLoaded()
	playerRef = tes3.player
	-- Refresh is needed on "loaded" to cover edge case when refs wouldn't
	-- properly reactivate after loading a game in the same cell.
	debugLog("Refreshing cache.")
	refreshCache()
	debugLog("Starting timer.")
	if mainTimer then
		mainTimer:reset()
	else
		mainTimer = timer.start{
			type = timer.simulate,
			duration = INTERVAL,
			iterations = -1,
			callback = tick
		}
	end
end

local function onWeatherTransitionFinished()
	debugLog("[weatherTransitionFinished] Resetting all sounds.")
	-- Remove all sounds and refresh the cache. If the weather has
	-- changed, we want all the sounds that are currently playing
	-- to update according to the new weather type. To be noted that
	-- the cache stays the same. We don't remove any statics from it.
	for _, ref in ipairs(staticsCache) do
		removeSound(ref)
	end
	clearCurrentShelter()
	refreshCache()
end

local function onReferenceActivated(e)
	-- Here is where the initial resolve happens.
	-- This event triggers before "cellChanged" and before "loaded".
	addToCache(e.reference)
end

local function onReferenceDeactivated(e)
	-- Same as above, but instead of adding, we remove from the cache.
	removeFromCache(e.reference)
end

WtC = tes3.worldController.weatherController

event.register("loaded", onLoaded, { priority = -300 })
event.register("weatherTransitionFinished", onWeatherTransitionFinished, { priority = -270 })
event.register("referenceActivated", onReferenceActivated, { priority = -250 })
event.register("referenceDeactivated", onReferenceDeactivated, { priority = -250 })