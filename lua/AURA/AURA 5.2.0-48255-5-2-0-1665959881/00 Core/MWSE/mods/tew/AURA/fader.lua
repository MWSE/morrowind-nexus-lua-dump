local this = {}

--local modversion = require("tew.AURA.version")
--local version = modversion.version
local common = require("tew.AURA.common")
local debugLog = common.debugLog

local TIME = 0.5
local TICK = 0.1
local MAX = 1
local MIN = 0
local fadeTimer
local crossFadeTimer

this.crossFadeRunning = false
this.fadeRunning = false

local function playTrack(options)
    local track = options.track
    local ref = options.reference or tes3.mobilePlayer.reference
    local volume = options.volume or MIN
    local pitch = options.pitch or MAX
    if not track then return end
    debugLog(string.format("Playing with volume %s: %s -> %s", volume, track.id, tostring(ref)))
    tes3.playSound {
        sound = track,
        loop = true,
        reference = ref,
        volume = volume,
        pitch = pitch,
    }
end


local function parse(options)
    local ref = options.reference or tes3.mobilePlayer.reference
    local track = options.track
    local fadeType = options.fadeType
    local volume = options.volume or MAX
    local pitch = options.pitch or MAX
    local targetDuration = options.duration or TIME
    local currentVolume

    local fadeStep = TICK * volume / targetDuration
	local ITERS = math.ceil(volume / fadeStep)
    local fadeDuration = TICK * ITERS

    if not track then
        debugLog("No track to fade " .. fadeType .. ". Returning.")
        return
    end

    if fadeType == "in" then
        playTrack{track = track, reference = ref, volume = MIN, pitch = pitch}
        currentVolume = MIN
    else
        currentVolume = volume
    end

    if (not tes3.getSoundPlaying{sound = track, reference = ref}) then
        debugLog("Track not playing, cannot fade " .. fadeType .. ". Returning.")
        return
    end

    debugLog("Running fade " .. fadeType .. " for: " .. track.id)

    local function fader()
        if fadeType == "in" then
            currentVolume = currentVolume + fadeStep
            if currentVolume > volume then currentVolume = volume end
        else
            currentVolume = currentVolume - fadeStep
            if currentVolume < 0 then currentVolume = 0 end
        end
    
        debugLog(string.format("Adjusting volume %s: %s -> %s | %.3f", fadeType, track.id, tostring(ref), currentVolume))

        tes3.adjustSoundVolume{sound = track, volume = currentVolume, reference = ref}
    end

    this.fadeRunning = true

    timer.start{
        iterations = ITERS,
        duration = TICK,
        callback = fader
    }

    fadeTimer = timer.start{
        iterations = 1,
        duration = fadeDuration + 0.1,
        callback = function()
            if fadeType == "out" then
                if tes3.getSoundPlaying{sound = track, reference = ref} then
                    tes3.removeSound{sound = track, reference = ref}
                end
            end
            debugLog(string.format("Fade %s for %s finished in %.3f s.", fadeType, track.id, fadeDuration))
            this.fadeRunning = false
        end
    }
end

function this.isRunning()
    return this.crossFadeRunning or this.fadeRunning
end

function this.getTimeLeft()
    if crossFadeTimer and (crossFadeTimer.state == 0) then
        return crossFadeTimer.timeLeft
    elseif fadeTimer and (fadeTimer.state == 0) then
        return fadeTimer.timeLeft
    else
        return 0
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

function this.crossFade(options)
    local volume = options.volume or MAX
    local pitch = options.pitch or MAX
    local trackOld = options.trackOld
    local trackNew = options.trackNew
    local refOld = options.refOld
    local refNew = options.refNew
    local fadeInDuration = options.fadeInDuration
    local fadeOutDuration = options.fadeOutDuration
    local fadeInStep = TICK*volume/fadeInDuration
    local fadeOutStep = TICK*volume/fadeOutDuration
    local ITERS = (math.ceil(volume / fadeInStep)) + (math.ceil(volume / fadeOutStep))
    local crossFadeDuration = TICK * ITERS
    
    if not trackOld or not trackNew then return end
    debugLog("Running crossfade for: " .. trackOld.id .. ", " .. trackNew.id)
    debugLog("Crossfading from old ref " .. tostring(refOld) .. " to new ref " .. tostring(refNew))
    this.crossFadeRunning = true
    this.fadeOut({
        track = trackOld,
        reference = refOld,
        volume = volume,
        duration = fadeOutDuration,
    })
    this.fadeIn({
        track = trackNew,
        reference = refNew,
        volume = volume,
        pitch = pitch,
        duration = fadeInDuration,
    })
    crossFadeTimer = timer.start{
        iterations = 1,
        duration = crossFadeDuration + 0.2,
        callback = function()
            debugLog(string.format("Crossfade took %.3f s.", crossFadeDuration))
            this.crossFadeRunning = false
        end
    }
end


return this