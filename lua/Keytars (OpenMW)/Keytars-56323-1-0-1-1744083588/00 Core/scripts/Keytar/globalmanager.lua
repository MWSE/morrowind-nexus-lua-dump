local core = require('openmw.core')
local types = require('openmw.types')
local world = require('openmw.world')

local configGlobal = require('scripts.Keytar.config.global')
local musicUtils = require('scripts.Keytar.util.music')

local actorData = {}
local playingCount = 0

local lastRealTime = core.getRealTime()

local resyncTimer = 0
local resyncInterval = 3

local realTimeOffset = -1
local gameTimeOffset = -1
local playing = false
local dagothReverb = false

local resetTimer = nil

local function getDagoth()
    local actors = world.activeActors
    dagothReverb = false
    for _, actor in ipairs(actors) do
        if actor and actor.type == types.Creature and (actor.recordId == "dagoth_ur_1" or actor.recordId == "dagoth_ur_2") then
            dagothReverb = actor.recordId == "dagoth_ur_2"
            return actor
        end
    end
    return nil
end

local function updatePlayingCount()
    playingCount = 0
    for _, actor in ipairs(world.activeActors) do
        if actorData[actor.id] then
            playingCount = playingCount + 1
        end
    end
    --[[if playingCount == 0 then
        if resetTimer == nil then
            resetTimer = configGlobal.technical.musicResetTime
        end
    else
        resetTimer = nil
    end]]--
end

local function handleStartSoundOnActor(data)
    local dagoth = getDagoth()

    local actualTime = data.desiredTime
    if realTimeOffset ~= -1 then
        actualTime = realTimeOffset % musicUtils.getSongLength()
    elseif dagoth ~= nil then
        actualTime = 0
    end

    local startDagoth = dagoth and not actorData[dagoth.id]
    if startDagoth and data.actor.type ~= types.Player then
        data.volume = configGlobal.technical.dagothKeytarVolume
    end

    local t1 = core.getRealTime()
    core.sound.playSoundFile3d(data.soundKey, data.actor, { timeOffset = actualTime, volume = data.volume, loop = true })
    local t2 = core.getRealTime()
    actualTime = actualTime + (t1 - t2)
    if startDagoth then
        core.sound.playSoundFile3d("Sound\\keytar\\dagoth-vocals.mp3", dagoth, { timeOffset = actualTime, volume = configGlobal.technical.dagothKeytarVolume, loop = true })
        actorData[dagoth.id] = {
            soundKey = "Sound\\keytar\\dagoth-vocals.mp3",
            volume = configGlobal.technical.dagothKeytarVolume
        }
    end

    actorData[data.actor.id] = {
        soundKey = data.soundKey,
        volume = data.volume
    }

    realTimeOffset = actualTime
    gameTimeOffset = actualTime

    resetTimer = nil
    updatePlayingCount()

    data.actor:sendEvent('SendKeytarTime', { time = actualTime, realTime = core.getRealTime() })

    playing = true
end

local function handleStopSoundOnActor(data)
    core.sound.stopSoundFile3d(data.soundKey, data.actor)
    actorData[data.actor.id] = nil

    updatePlayingCount()

    local dagoth = getDagoth()
    if dagoth ~= nil and actorData[dagoth.id] and playingCount == 1 then
        core.sound.stopSoundFile3d("Sound\\keytar\\dagoth-vocals.mp3", dagoth)
        actorData[dagoth.id] = nil
        playingCount = 0
    end

    if playingCount == 0 then
        if resetTimer == nil then
            resetTimer = configGlobal.technical.musicResetTime
        end
        dagothReverb = false
    end

    if not dagothReverb then
        core.sound.stopSoundFile3d("Sound\\keytar\\dagoth-reverb.mp3", world.players[1])
    end
end

local function resyncActor(actor)
    core.sound.playSoundFile3d(actorData[actor.id].soundKey, actor, { timeOffset = realTimeOffset, volume = actorData[actor.id].volume, loop = true })
    actor:sendEvent('SendKeytarTime', { time = realTimeOffset, realTime = core.getRealTime() })
end

local function resyncAudio()
    local currentRealTime = core.getRealTime()
    local deltaTime = currentRealTime - lastRealTime
    lastRealTime = currentRealTime

    if not playing then
        realTimeOffset = -1
        gameTimeOffset = -1
        return
    end

    realTimeOffset = (realTimeOffset + deltaTime) % musicUtils.getSongLength()
    gameTimeOffset = (gameTimeOffset + deltaTime) % musicUtils.getSongLength()
    if math.abs(gameTimeOffset - realTimeOffset) > 0.05 or deltaTime > 0.05 then
        for _, actor in ipairs(world.activeActors) do
            if actorData[actor.id] then
                resyncActor(actor)
            end
        end
        if dagothReverb then
            core.sound.playSoundFile3d("Sound\\keytar\\dagoth-reverb.mp3", world.players[1], { timeOffset = realTimeOffset, volume = configGlobal.technical.dagothReverbVolume, loop = true })
        end
        gameTimeOffset = realTimeOffset
    end
end

local function update(dt)
    if resyncTimer >= resyncInterval then
        for _, actor in ipairs(world.activeActors) do
            if actorData[actor.id] then
                if not core.sound.isSoundFilePlaying(actorData[actor.id].soundKey, actor) then
                    resyncActor(actor)
                end
            end
        end
        resyncTimer = 0
    else
        resyncTimer = resyncTimer + dt
    end

    updatePlayingCount()

    if resetTimer ~= nil and resetTimer > 0 then
        resetTimer = resetTimer - dt
        if resetTimer <= 0 then
            playing = false
            realTimeOffset = -1
            gameTimeOffset = -1
            resetTimer = nil
        end
    end

    if dagothReverb and not core.sound.isSoundFilePlaying("Sound\\keytar\\dagoth-reverb.mp3", world.players[1]) then
        core.sound.playSoundFile3d("Sound\\keytar\\dagoth-reverb.mp3", world.players[1], { timeOffset = realTimeOffset, volume = configGlobal.technical.dagothReverbVolume, loop = true })
    end

    resyncAudio()
end

return {
    engineHandlers = {
        onUpdate = update
    },
    eventHandlers = {
        KeytarStarted = handleKeytarStarted,
        StartSoundOnActor = handleStartSoundOnActor,
        StopSoundOnActor = handleStopSoundOnActor,
        ActorDiedOrInactive = function(data)
            if data.actor and actorData[data.actor.id] then
                handleStopSoundOnActor({ actor = data.actor, soundKey = actorData[data.actor.id].soundKey })
            end
        end,
        TeleportToPlayer = function(actor)
            actor:teleport(world.players[1].cell, world.players[1].position)
        end
    }
}