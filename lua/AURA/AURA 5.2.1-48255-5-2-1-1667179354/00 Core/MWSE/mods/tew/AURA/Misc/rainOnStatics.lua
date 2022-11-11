local sounds = require("tew.AURA.sounds")
local common = require("tew.AURA.common")
local debugLog = common.debugLog
local fader = require("tew.AURA.fader")

local soundData = {
	["tew_t_rainlight"] = {
		[4] = {
			volume = 1.0,
			pitch = 1.0
		},
		[5] = {
			volume = 1.0,
			pitch = 1.0
		},
	},
	["tew_t_rainmedium"] = {
		[4] = {
			volume = 0.7,
			pitch = 1.0
		},
		[5] = {
			volume = 0.8,
			pitch = 1.0
		},
	},
	["tew_t_rainheavy"] = {
		[4] = {
			volume = 0.7,
			pitch = 1.0
		},
		[5] = {
			volume = 0.8,
			pitch = 1.0
		},
	},
}

local WtC
local mainTimer
local playerRef
local playingBlocked
local staticsCache = {}
local currentShelter = {}

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
		if common.findMatch(blockedStatics, ref.object.id:lower()) then
			debugLog("Skipping blocked static: " .. tostring(ref))
			return false
		end
		if common.findMatch(rainyStatics, ref.object.id:lower()) then
			return true
		end
	end
	return false
end

local function removeSound(ref)
	for trackName, arr in pairs(soundData) do
		if tes3.getSoundPlaying{
			sound = trackName,
			reference = ref
		} then
			debugLog("Track " .. trackName .. " playing on ref " .. tostring(ref) .. ", now removing it.")
			tes3.removeSound{
				sound = trackName,
				reference = ref
			}
		end
	end
end

local function isRainLoopSoundPlaying()
    if WtC.currentWeather.rainLoopSound
	and WtC.currentWeather.rainLoopSound:isPlaying() then
        return true
    else
        return false
    end
end

local function clearCurrentShelter()
	if currentShelter.sound then
		debugLog(currentShelter.sound.id .. " playing on playerRef. Running fadeOut.")
		fader.fadeOut({
			volume = currentShelter.volume,
			reference = playerRef,
			track = currentShelter.sound,
			-- Here the duration can be higher than usual because this function
			-- gets called on rare occasions. e.g. when you're chillaxing in a
			-- tent waiting for the rain to stop, you want the fade out to be as
			-- long as possible for extra immersion.
			duration = 2,
		})
		currentShelter.ref = nil
		currentShelter.sound = nil
		currentShelter.volume = nil
	end
end

local function addToCache(ref)
	-- Resetting the timer on every add to kind of block it
	-- from running while the cache is being populated.
	if mainTimer then mainTimer:reset() end
	if (common.cellIsInterior(ref.cell)) or (not isRelevantRef(ref)) then
		return
	end
	-- We only add a static to the cache if it's not already in there.
	if not common.getIndex(staticsCache, ref) then
		if not ref.tempData.tew then
			ref.tempData.tew = {}
		end
		-- Adding (bool) sheltered temp data to every static in the cache
		-- so that we later know whether to add a sound to it or not.
		if not common.findMatch(exemptedFromShelteredTest, ref.object.id:lower()) then
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
	local index = common.getIndex(staticsCache, ref)
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
	local sound = sounds.interiorWeather["ten"][WtC.currentWeather.index]
	if not sound then return end

	if ref.tempData.tew then
		if ref.tempData.tew.sheltered then
			-- Current ref is sheltered by another object. Moving on.
			return
		end
	end

	if fader.isRunning() then return end

	local playerPos = tes3.player.position:copy()
	local refPos = ref.position:copy()
	local objId = ref.object.id:lower()
	local volume = soundData[sound.id][WtC.currentWeather.index].volume
	local pitch = soundData[sound.id][WtC.currentWeather.index].pitch

	-- Check if sheltered by current ref.
	-- If we are, then either fadeIn or crossFade.

	if (not currentShelter.ref)
	and (common.findMatch(shelterStatics, objId))
	and (playerPos:distance(refPos) < 280)
	and (common.isRefSheltered{targetRef = ref, ignoreList = rayTestIgnoreStatics}) then
		debugLog("Player sheltered.")
		if not tes3.getSoundPlaying{sound = sound, reference = ref} then
			debugLog("[sheltered] Sound not playing on shelter ref. Running fadeIn.")
			fader.fadeIn({
				volume = volume,
				pitch = pitch,
				reference = playerRef,
				track = sound,
				duration = 0.7,
			})
		else
			debugLog("[sheltered] Sound playing on shelter ref. Running crossFade.")
			fader.crossFade{
				volume = volume,
				pitch = pitch,
				trackOld = sound,
				trackNew = sound,
				refOld = ref,
				refNew = playerRef,
				fadeInDuration = 0.5,
				fadeOutDuration = 1,
			}
		end
		-- Also add data to our new shelter so that we remove playerRef
		-- sound correctly when clearCurrentShelter() gets called.
		currentShelter.ref = ref
		currentShelter.sound = sound
		currentShelter.volume = volume
		return
	end

	-- If we're currently sheltered, then keep checking until not we're not
	-- sheltered anymore. If we're currently not sheltered, get rid of the
	-- sound playing on playerRef. Here we can either crossFade (takes longer)
	-- or just fadeOut. For now, just fadeOut and let a subsequent call to this
	-- function add ref sound when the fade has finished.

	if (currentShelter.ref == ref)
	and (not common.isRefSheltered{originRef = playerRef, targetRef = ref}) then
		debugLog("[not sheltered] Running fadeOut.")
		fader.fadeOut({
			volume = currentShelter.volume,
			reference = playerRef,
			track = currentShelter.sound,
			duration = 0.8,
		})
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
		tes3.playSound{
			sound = sound,
			reference = ref,
			loop = true,
			volume = volume,
			pitch = pitch,
		}
	end
end

local function tick()
	if fader.isRunning() then
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
			debugLog("Not raining. Removing any sounds that might be playing.")
			for _, ref in ipairs(staticsCache) do
				removeSound(ref)
			end
			clearCurrentShelter()
			playingBlocked = true
			debugLog("Playing is blocked.")
		end
	end
end

local function runTimer()
	playerRef = tes3.player
	debugLog("Starting timer.")
	mainTimer = timer.start{
		type = timer.simulate,
		duration = INTERVAL,
		iterations = -1,
		callback = tick
	}
end

local function refreshCache()
	local cell = tes3.getPlayerCell()
	debugLog("Commencing dump!")
	for ref in cell:iterateReferences() do
		addToCache(ref)
	end
	debugLog("staticsCache currently holds " .. #staticsCache .. " statics.")
end

local function onCOC(e)
	-- Since "referenceActivated" and "referenceDeactivated" events
	-- occur before "cellChanged", at this point all statics should be
	-- already resolved. Just making sure no rainy static has been left
	-- behind when stepping into a new cell. Probably unnecessary, but
	-- should cover some exotic edge cases.
	debugLog("Cell changed.")
	if e.previousCell then
		debugLog("Got previousCell.")
		if (not common.cellIsInterior(e.cell)) and (e.cell ~= e.previousCell) then
			debugLog("New exterior cell. Refreshing cache.")
			refreshCache()
		end
	else
		-- previousCell should be nil when loading a game, no need to do
		-- anything if that's the case.
		debugLog("No previousCell.")
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

event.register("loaded", runTimer, { priority = -300 })
event.register("cellChanged", onCOC, { priority = -170 })
event.register("weatherTransitionFinished", onWeatherTransitionFinished, { priority = -270 })
event.register("referenceActivated", onReferenceActivated, { priority = -250 })
event.register("referenceDeactivated", onReferenceDeactivated, { priority = -250 })