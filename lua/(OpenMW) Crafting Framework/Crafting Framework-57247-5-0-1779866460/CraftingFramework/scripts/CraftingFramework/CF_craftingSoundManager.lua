--[[
    plays sound defs tied to crafting progress (0..1).
    entries in recipe.craftingSounds:
      one-shot   { sound, at, volume }                 -- fires once at `at`
                 add `to` + `duration` to fade it out so it's silent by `to`
      loop       { sound, from, to, duration, fade_in, fade_out, volume,
                   interval, minTimeToEnd, skipIfIncomplete }
    `at` present => one-shot (ranged if it also has `to`); otherwise loops from..to.
    use `sounds = {{sound,duration},...}` instead of `sound`/`duration` for a random pool;
    loops cycle to a new random pick after each playback completes.

    fields:
      sound        sound id or file path (autodetected via vfs.fileExists)
      sounds       random pool, mutually exclusive with sound
      duration     seconds; required for fade_in/fade_out, interval and cycling
      at           0..1 trigger fraction for one-shots
      from / to    0..1 active range (loop); `to` also = fade-out deadline for `at`+`to`
      interval     period between loop plays, start to start; seconds, number or {min,max}.
                   if <= duration the sound retriggers continuously; if > duration
                   the leftover is silence between plays
      volume       default 0.9
      pitch        default 1.0; number or {min,max}
      fade_in      seconds, default 0; ramps from start
      fade_out     seconds, default 0.3; completes exactly at `to`, longer starts earlier
      pitch_fade_in  {duration, from}; glides `from`->resolved from start
      pitch_fade_out {duration, to}; glides resolved->`to`, completes exactly at `to`;
                     longer duration just starts earlier (no extra trigger needed)
      randomOffset {min,max} start offset for loops
      minTimeToEnd seconds; skip cycle if less time remains before `to`; default: 0.5*duration
      skipIfIncomplete true => don't play if won't finish before `to`
]]

local ambient = require('openmw.ambient')
local core = require('openmw.core')
local vfs = require('openmw.vfs')

local DEFAULT_VOLUME = 0.9
local DEFAULT_FADE_OUT = 0.3
local FALLBACK_FADE = 0.5

local fileCache = {}

local function print()
end


local function isFile(soundId)
    if fileCache[soundId] == nil then
        fileCache[soundId] = vfs.fileExists(soundId)
    end
    return fileCache[soundId]
end

local function resolveSound(def)
    if def.sounds then
        local pick = def.sounds[math.random(#def.sounds)]
        return pick.sound or pick[1], pick.duration or pick[2]
    end
    return def.sound, def.duration
end

local function playRaw(soundId, opts)
    if isFile(soundId) then
        ambient.playSoundFile(soundId, opts)
    else
        ambient.playSound(soundId, opts)
    end
end

local function stopRaw(soundId)
    if isFile(soundId) then
        ambient.stopSoundFile(soundId)
    else
        ambient.stopSound(soundId)
    end
end

local function restartAtOffset(soundId, cycleStartedAt, duration, volume, engineLoop, pitch)
    local offset = (core.getRealTime() - cycleStartedAt) % duration
    stopRaw(soundId)
    playRaw(soundId, { volume = volume, loop = engineLoop, timeOffset = offset, pitch = pitch or 1.0 })
end

local function getInterval(intervalDef)
    if type(intervalDef) == "number" then
        return intervalDef
    end
    local min = intervalDef.min or intervalDef[1] or 1
    local max = intervalDef.max or intervalDef[2] or min
    return min + math.random() * (max - min)
end

local function getPitch(pitchDef)
    if not pitchDef then return 1.0 end
    if type(pitchDef) == "number" then
        return pitchDef
    end
    local min = pitchDef.min or pitchDef[1] or 1.0
    local max = pitchDef.max or pitchDef[2] or min
    return min + math.random() * (max - min)
end

local function getRandomOffset(def)
    if not def.randomOffset then return 0 end
    local oMin = def.randomOffset.min or def.randomOffset[1] or 0
    local oMax = def.randomOffset.max or def.randomOffset[2] or oMin
    return oMin + math.random() * (oMax - oMin)
end

-- volume: fade-in ramps from start; fade-out reaches 0 exactly at `to`.
-- timeUntilTo = seconds left before `to`; nil for sounds with no range end.
local function getFadeMultiplier(def, loopStartedAt, timeUntilTo, now)
    local fadeInMult = 1
    local fadeInDur = def.fade_in or 0
    if fadeInDur > 0 and loopStartedAt then
        fadeInMult = math.min(1, (now - loopStartedAt) / fadeInDur)
    end

    local fadeOutMult = 1
    local fadeOutDur = def.fade_out or DEFAULT_FADE_OUT
    if fadeOutDur > 0 and timeUntilTo then
        fadeOutMult = math.max(0, math.min(1, timeUntilTo / fadeOutDur))
    end

    return fadeInMult * fadeOutMult
end

-- pitch: fade-out glides resolved->`to` and lands exactly at `to`; takes
-- priority over fade-in, which glides `from`->resolved from start.
local function getPitchWithFade(def, resolvedPitch, loopStartedAt, timeUntilTo, now)
    if def.pitch_fade_out and timeUntilTo then
        local dur = def.pitch_fade_out.duration or 0
        if dur > 0 and timeUntilTo < dur then
            local toPitch = def.pitch_fade_out.to or 0.5
            local p = math.max(0, math.min(1, 1 - timeUntilTo / dur))
            return resolvedPitch + (toPitch - resolvedPitch) * p
        end
    end

    if def.pitch_fade_in and loopStartedAt then
        local dur = def.pitch_fade_in.duration or 0
        if dur > 0 then
            local p = math.min(1, (now - loopStartedAt) / dur)
            if p < 1 then
                local fromPitch = def.pitch_fade_in.from or 0.5
                return fromPitch + (resolvedPitch - fromPitch) * p
            end
        end
    end

    return resolvedPitch
end

local function shouldSkipCycle(def, soundDur, elapsed, totalDuration, progressTo)
    if not def.skipIfIncomplete or not soundDur or soundDur <= 0 then
        return false
    end
    local minTime = def.minTimeToEnd or (soundDur * 0.5)
    local timeUntilEnd = (progressTo * totalDuration) - elapsed
    return timeUntilEnd < minTime
end

local function restartLoopSound(entry, def, soundId, soundDur, volume, timeUntilTo, now)
    local pitch = getPitchWithFade(def, entry.resolvedPitch or 1.0, entry.loopStartedAt, timeUntilTo, now)
    restartAtOffset(soundId, entry.cycleStartedAt, soundDur, volume, entry.engineLoop, pitch)
end


------------------------------ orphan management ------------------------------
-- orphans are detached loops still fading out

local orphans = {}

-- move active loops from entries into the orphan list to fade out
local function retireEntries(entries, fadeDuration)
    if not entries then return end
    local now = core.getRealTime()
    for _, entry in pairs(entries) do
        if entry.loopActive then
            local def = entry.def
            local soundId = entry.resolvedSound or def.sound
            local soundDur = entry.resolvedDuration or def.duration
            if soundDur and soundDur > 0 then
                table.insert(orphans, {
                    sound = soundId,
                    duration = soundDur,
                    loopStartedAt = entry.cycleStartedAt or entry.loopStartedAt,
                    engineLoop = entry.engineLoop,
                    fadeStartTime = now,
                    fadeDuration = fadeDuration or def.fade_out or FALLBACK_FADE,
                    fadeBaseVolume = def.volume or DEFAULT_VOLUME,
                    resolvedPitch = entry.resolvedPitch or 1.0,
                    def = def,
                })
            else
                stopRaw(soundId)
            end
        end
    end
end


------------------------------ manager ------------------------------

local manager = {}

-- key indexes craftingSounds. returns false if it's a plain path/vanilla sound.
function manager:start(key, totalDuration)
    retireEntries(self.entries)

    local definitions = craftingSounds[key]
    if not definitions then return false end

    self.definitions = definitions
    self.totalDuration = totalDuration or 1
    self.entries = {}

    for i, def in ipairs(self.definitions) do
        self.entries[i] = {
            def = def,
            fired = false,
            loopActive = false,
            engineLoop = false,
            loopStartedAt = nil,
            cycleStartedAt = nil,
            cycleInterval = nil,
            resolvedSound = nil,
            resolvedDuration = nil,
            resolvedPitch = nil,
            stopped = false,
        }
    end
    return true
end

-- call every frame while crafting is active, and after completion until isActive() is false
function manager:update(progress)
    local now = core.getRealTime()

    -- orphan fade-outs: abrupt-stop tail, fades over its own fadeDuration
    local i = 1
    while i <= #orphans do
        local o = orphans[i]
        local remaining = o.fadeDuration - (now - o.fadeStartTime)

        if remaining <= 0 then
            stopRaw(o.sound)
            table.remove(orphans, i)
        else
            local vol = o.fadeBaseVolume * (remaining / o.fadeDuration)
            local pitch = getPitchWithFade(o.def, o.resolvedPitch, nil, remaining, now)
            restartAtOffset(o.sound, o.loopStartedAt, o.duration, vol, o.engineLoop, pitch)
            i = i + 1
        end
    end

    if not self.entries then return end

    local elapsed = progress * self.totalDuration

    for _, entry in pairs(self.entries) do
        local def = entry.def

        -- one-shot at `at`; with `to` it fades out so it's silent by `to`
        if def.at then
            if not def.to then
                if not entry.fired and progress >= def.at then
                    local soundId = resolveSound(def)
                    entry.resolvedPitch = getPitch(def.pitch)
                    playRaw(soundId, { volume = def.volume or DEFAULT_VOLUME, pitch = entry.resolvedPitch })
                    entry.fired = true
                end
            else
                local to = def.to
                local baseVol = def.volume or DEFAULT_VOLUME
                local soundId = entry.resolvedSound
                local soundDur = entry.resolvedDuration

                if not entry.fired and progress >= def.at then
                    soundId, soundDur = resolveSound(def)
                    entry.resolvedSound = soundId
                    entry.resolvedDuration = soundDur
                    entry.resolvedPitch = getPitch(def.pitch)
                    entry.loopStartedAt = now
                    local timeUntilTo = (to - progress) * self.totalDuration
                    local pitch = getPitchWithFade(def, entry.resolvedPitch, entry.loopStartedAt, timeUntilTo, now)
                    playRaw(soundId, { volume = baseVol, pitch = pitch })
                    entry.fired = true
                end

                if not entry.fired or entry.stopped then goto continue end
                if not (soundDur and soundDur > 0) then goto continue end

                local timeUntilTo = (to - progress) * self.totalDuration
                if timeUntilTo <= 0 then
                    stopRaw(soundId)
                    entry.stopped = true
                    goto continue
                end

                -- plays once; only touch it while still playing and inside the fade tail
                local playElapsed = now - entry.loopStartedAt
                if playElapsed >= soundDur then goto continue end

                local fadeMult = getFadeMultiplier(def, entry.loopStartedAt, timeUntilTo, now)
                if fadeMult < 1 then
                    local pitch = getPitchWithFade(def, entry.resolvedPitch or 1.0, entry.loopStartedAt, timeUntilTo, now)
                    stopRaw(soundId)
                    playRaw(soundId, { volume = baseVol * fadeMult, pitch = pitch, timeOffset = playElapsed })
                end
            end

        -- loop over from..to; optional `interval` = period between plays (start to start)
        else
            local from = def.from or 0
            local to = def.to or 1
            local baseVol = def.volume or DEFAULT_VOLUME
            local multiSound = def.sounds ~= nil
            local hasInterval = def.interval ~= nil
            local soundId = entry.resolvedSound
            local soundDur = entry.resolvedDuration
            local hasDuration = soundDur and soundDur > 0

            -- start the loop
            if not entry.loopActive and not entry.stopped and progress >= from then
                soundId, soundDur = resolveSound(def)
                if shouldSkipCycle(def, soundDur, elapsed, self.totalDuration, to) then
                    goto continue
                end
                entry.resolvedSound = soundId
                entry.resolvedDuration = soundDur
                entry.resolvedPitch = getPitch(def.pitch)
                -- interval needs manual re-trigger, so no engine loop
                entry.engineLoop = not multiSound and not hasInterval
                entry.cycleInterval = hasInterval and getInterval(def.interval) or nil
                hasDuration = soundDur and soundDur > 0

                -- loopStartedAt drives fade-in clocks (real start); cycleStartedAt
                -- is back-dated so the audio begins at the random offset
                local startOffset = getRandomOffset(def)
                entry.loopActive = true
                entry.loopStartedAt = now
                entry.cycleStartedAt = now - startOffset

                local timeUntilTo = (to - progress) * self.totalDuration
                local fadeMult = getFadeMultiplier(def, entry.loopStartedAt, timeUntilTo, now)
                local pitch = getPitchWithFade(def, entry.resolvedPitch, entry.loopStartedAt, timeUntilTo, now)
                playRaw(soundId, {
                    volume = baseVol * fadeMult,
                    pitch = pitch,
                    loop = entry.engineLoop,
                    timeOffset = startOffset,
                })
                goto continue
            end

            if not entry.loopActive then goto continue end

            local timeUntilTo = (to - progress) * self.totalDuration
            local cycleElapsed = now - entry.cycleStartedAt

            -- next cycle: after the period (interval) or, with no interval, the sound
            local cyclePeriod = (hasInterval and entry.cycleInterval) or soundDur
            if hasDuration and (multiSound or hasInterval)
                and cycleElapsed >= cyclePeriod and timeUntilTo > 0 then
                stopRaw(soundId)
                soundId, soundDur = resolveSound(def)
                if shouldSkipCycle(def, soundDur, elapsed, self.totalDuration, to) then
                    entry.loopActive = false
                    goto continue
                end
                entry.resolvedSound = soundId
                entry.resolvedDuration = soundDur
                entry.resolvedPitch = getPitch(def.pitch)
                local cycleOffset = getRandomOffset(def)
                entry.cycleStartedAt = now - cycleOffset
                entry.cycleInterval = hasInterval and getInterval(def.interval) or nil
                hasDuration = soundDur and soundDur > 0

                local fadeMult = getFadeMultiplier(def, entry.loopStartedAt, timeUntilTo, now)
                local pitch = getPitchWithFade(def, entry.resolvedPitch, entry.loopStartedAt, timeUntilTo, now)
                playRaw(soundId, { volume = baseVol * fadeMult, pitch = pitch, timeOffset = cycleOffset })
                goto continue
            end

            -- reached `to`: fades have already completed, stop cleanly
            if timeUntilTo <= 0 then
                stopRaw(soundId)
                entry.loopActive = false
                entry.stopped = true
                goto continue
            end

            -- silence during the interval gap, otherwise keep fade applied
            if hasInterval and hasDuration and cycleElapsed >= soundDur then
                stopRaw(soundId)
            elseif hasDuration then
                local fadeMult = getFadeMultiplier(def, entry.loopStartedAt, timeUntilTo, now)
                restartLoopSound(entry, def, soundId, soundDur, baseVol * fadeMult, timeUntilTo, now)
            end
        end

        ::continue::
    end
end


-- loops with duration fade via orphans; others hard-stop. fadeDuration overrides per-sound fade_out
function manager:stop(fadeDuration)
    retireEntries(self.entries, fadeDuration)
    self.entries = nil
    self.definitions = nil
end

-- immediate kill, no fade
function manager:killAll()
    if self.entries then
        for _, entry in pairs(self.entries) do
            if entry.loopActive then
                stopRaw(entry.resolvedSound or entry.def.sound)
            end
        end
    end
    for _, o in ipairs(orphans) do
        stopRaw(o.sound)
    end
    orphans = {}
    self.entries = nil
    self.definitions = nil
end


function manager:isActive()
    if #orphans > 0 then return true end
    if not self.entries then return false end

    for _, entry in pairs(self.entries) do
        if entry.loopActive then return true end
    end

    self.entries = nil
    self.definitions = nil
    return false
end


return manager
