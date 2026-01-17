local this = {}

local common = require("tew.AURA.common")
local debugLog = common.debugLog
local moduleData = require("tew.AURA.moduleData")
local volumeController = require("tew.AURA.volumeController")
local adjustVolume = volumeController.adjustVolume

local TICK = 0.1
local MAX = 1
local MIN = 0

local function parse(options)
    local moduleName = options.module
    local ref = options.reference
    local track = options.track
    local fadeType = options.fadeType
	local oppositeType = (fadeType == "out") and "in" or "out"
	local lastVolume = moduleData[options.module].lastVolume
    local volume = options.volume or lastVolume or track.volume
    local pitch = options.pitch or MAX
    local targetDuration = options.duration or moduleData[moduleName].faderData[fadeType].duration
    local currentVolume
	local fadeInProgress = {}
	local iterTimer
	local fadeTimer


    if not (track and ref) then
        debugLog(string.format("[!][%s] Track: %s, ref: %s. Returning.", moduleName, tostring(track), tostring(ref)))
        return
    end

	if this.isRunning{
		module = moduleName,
		fadeType = fadeType,
		track = track,
		reference = ref,
	} then
		--debugLog(string.format("[%s] Already fading %s %s on %s. Returning.", moduleName, fadeType, track.id, tostring(ref)))
		return
	end

	if this.isRunning{
		module = moduleName,
		fadeType = oppositeType,
		track = track,
		reference = ref,
	} then
        debugLog(string.format("[%s] wants to fade %s %s but fade %s is in progress for this track. Trying later.", moduleName, fadeType, track.id, oppositeType))
		timer.start {
			callback = function()
				parse(options)
			end,
			type = timer.real,
			iterations = 1,
			duration = 2
		}
		return
	end

    local fadeStep = TICK * volume / targetDuration
	local ITERS = math.ceil(volume / fadeStep) -- corner case: (0 / 0) = NaN
	ITERS = ITERS ~= ITERS and 1 or ITERS -- if NaN, set ITERS to 1 in order to avoid infinite iterations on iterTimer
    local fadeDuration = TICK * ITERS

    if fadeType == "in" then
        currentVolume = MIN
    else
		currentVolume = options.volume and volume or lastVolume or volume
    end

    if (not tes3.getSoundPlaying{sound = track, reference = ref}) then
        debugLog(string.format("[%s] Track %s not playing on ref %s, cannot fade %s. Returning.", moduleName, track.id, tostring(ref), fadeType))
        return
    end

    debugLog(string.format("[%s] Running fade %s for %s -> %s", moduleName, fadeType, track.id, tostring(ref)))

	fadeInProgress.track = track
	fadeInProgress.ref = ref

    local function fader()
        if fadeType == "in" then
            currentVolume = currentVolume + fadeStep
            if currentVolume > volume then currentVolume = volume end
        else
            currentVolume = currentVolume - fadeStep
            if currentVolume < 0 then currentVolume = 0 end
        end

        if not tes3.getSoundPlaying { sound = track, reference = ref } then
			debugLog(string.format("[%s] %s suddenly not playing on ref %s. Canceling fade %s timers.", moduleName, track.id, tostring(ref), fadeType))
			fadeInProgress.iterTimer:cancel()
			fadeInProgress.fadeTimer:cancel()
			common.setRemove(moduleData[moduleName].faderData[fadeType].inProgress, fadeInProgress)
			return
		end

        adjustVolume{
            module = moduleName,
            track = track,
            reference = ref,
            volume = currentVolume,
            inOrOut = fadeType,
        }
    end

	fadeInProgress.iterTimer = timer.start{
        iterations = ITERS,
        duration = TICK,
        callback = fader
    }

	fadeInProgress.fadeTimer = timer.start{
        iterations = 1,
        duration = fadeDuration + 0.1,
        callback = function()
			debugLog(string.format("[%s] Fade %s for %s -> %s finished in %.3f s.", moduleName, fadeType, track.id, tostring(ref), fadeDuration))
            if (fadeType == "out") then
				if tes3.getSoundPlaying{sound = track, reference = ref} then
					tes3.removeSound{sound = track, reference = ref}
					debugLog(string.format("[%s] Track %s removed from -> %s.", moduleName, track.id, tostring(ref)))
				end
            end
			common.setRemove(moduleData[moduleName].faderData[fadeType].inProgress, fadeInProgress)
			moduleData[options.module].old = track
			moduleData[options.module].lastVolume = currentVolume
        end
    }
	common.setInsert(moduleData[moduleName].faderData[fadeType].inProgress, fadeInProgress)
	debugLog(string.format("[%s] Fade %ss in progress: %s", moduleName, fadeType, #moduleData[moduleName].faderData[fadeType].inProgress))

end

function this.isRunning(optsOrModule)
	local moduleName, fadeType, track, ref

	local function typeRunning(fadeType)
		for _, fade in ipairs(moduleData[moduleName].faderData[fadeType].inProgress) do
			if (fade.track == track) and (fade.ref == ref) then
				return true
			end
		end
		return false
	end

	local function timerRunning(fadeType)
		for _, fade in ipairs(moduleData[moduleName].faderData[fadeType].inProgress) do
			if common.isTimerAlive(fade.iterTimer) or common.isTimerAlive(fade.fadeTimer) then
				return true
			end
		end
		return false
	end

	if type(optsOrModule) == "table" then
		moduleName = optsOrModule.module
		track = optsOrModule.track
		ref = optsOrModule.reference
		fadeType = optsOrModule.fadeType
		if moduleName and track and ref and fadeType then
			return typeRunning(fadeType)
		end
	end

	if (type(optsOrModule) == "string") and (moduleData[optsOrModule]) then
		moduleName = optsOrModule
		return timerRunning("out") or timerRunning("in")
	end

	return false
end

-- Cancels any fade in/out currently in progress for the given module,
-- or just in/out for the given track and ref. Does not remove tracks.
-- Make sure to remove tracks after calling this function if necessary.
function this.cancel(moduleName, track, ref)
	if not moduleData[moduleName] then return end
	for fadeType in pairs(moduleData[moduleName].faderData) do
		for k, fade in ipairs(moduleData[moduleName].faderData[fadeType].inProgress) do
			if track and ref then
				if not (fade.track == track and fade.ref == ref) then
					goto continue
				end
			end
			fade.iterTimer:cancel()
			fade.fadeTimer:cancel()
			debugLog(string.format("[%s] Fade %s canceled for track %s -> %s.", moduleName, fadeType, fade.track.id, tostring(fade.ref)))
			moduleData[moduleName].faderData[fadeType].inProgress[k] = nil
			:: continue ::
		end
	end
end

function this.fadeIn(options)
    options.fadeType = "in"
    parse(options)
end

function this.fadeOut(options)
    options.fadeType = "out"
    parse(options)
end

local function onLoaded()
	debugLog("Resetting fader data.")
	for moduleName in pairs(moduleData) do
		moduleData[moduleName].faderData["out"].inProgress = {}
		moduleData[moduleName].faderData["in"].inProgress = {}
	end
end
event.register("loaded", onLoaded)

return this