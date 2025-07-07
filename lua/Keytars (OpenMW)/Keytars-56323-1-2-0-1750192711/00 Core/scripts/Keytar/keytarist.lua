local K = {}

local types = require("openmw.types")
local core = require("openmw.core")
local self = require("openmw.self")
local anim = require("openmw.animation")
local I = require("openmw.interfaces")
local nearby = require("openmw.nearby")

local configGlobal = require('scripts.Keytar.config.global')

K.keytarId = "_rlts_wep_keytar"
K.musicTime = -1
K.startTimes = { 0, 13.062, 26.123, 65.307, 78.369, 130.613 }

K.danceSendTimer = 0
K.danceSendInterval = 0.25

K.wasMoving = false
K.idleTimer = nil

local function getRandomStartTime()
    if configGlobal.customMusic.customMusicPath ~= "dagoth.mp3" then
        return 0
    else
        return K.startTimes[math.random(1, #K.startTimes)]
    end
end

local function getBpmConstant()
    local bpm = configGlobal.customMusic.customMusicBpm
    local animFps = 24
    local animFramesPerBeat = 10
    local animBpm = animFps * 60 / animFramesPerBeat
    return bpm / animBpm
end

local function getAnimStartPoint(timeOffset)
    if timeOffset == -1 then
        return 0
    end
    local songBeatLength = 1 / (configGlobal.customMusic.customMusicBpm / 60)
    local songTime = timeOffset % (songBeatLength * 16) -- in seconds
    local animTime = songTime / (songBeatLength * 16) -- from 0 to 1
    return animTime
end

function K.getMusicPath()
    return "Sound\\keytar\\" .. configGlobal.customMusic.customMusicPath
end

function K.isValidKeytarist(actor)
    local equippedR = types.Actor.getEquipment(actor, types.Actor.EQUIPMENT_SLOT.CarriedRight)
    return equippedR and equippedR.recordId == K.keytarId
end

function K.isPlaying()
    return core.sound.isSoundFilePlaying(K.getMusicPath(), self)
end

function K.startAnim(animKey, offsetVariation)
    offsetVariation = offsetVariation or 0
    anim.setLoopingEnabled(self, animKey, true)
    I.AnimationController.playBlendedAnimation(animKey, { 
        loops = 1000000000,
        priority = {
            [anim.BONE_GROUP.LeftArm] = anim.PRIORITY.Hit,
            [anim.BONE_GROUP.RightArm] = anim.PRIORITY.Hit,
            [anim.BONE_GROUP.Torso] = anim.PRIORITY.Hit,
            [anim.BONE_GROUP.LowerBody] = anim.PRIORITY.WeaponLowerBody
        },
        startPoint = (getAnimStartPoint(K.musicTime) + offsetVariation) % 1
    })
    anim.setSpeed(self, animKey, getBpmConstant())
end

function K.resyncAnim(key)
    if anim.isPlaying(self, key) then
        anim.cancel(self, key)
        K.startAnim(key)
    end
end

function K.startPlaying(vol)
    local data = {
        actor = self, 
        soundKey = K.getMusicPath(), 
        volume = vol,
        desiredTime = getRandomStartTime()
    }

    core.sendGlobalEvent('StartSoundOnActor', data)
end

function K.stopPlaying()
    core.sendGlobalEvent('StopSoundOnActor', { actor = self, soundKey = K.getMusicPath() })
    K.musicTime = -1
end

function K.distTo(obj)
    if obj then
        return (obj.position - self.position):length()
    end
    return math.huge
end

function K.tickDanceSend(dt)
    K.danceSendTimer = K.danceSendTimer + dt
    if K.danceSendTimer >= K.danceSendInterval then
        K.danceSendTimer = 0
        if K.isPlaying() then
            for _, actor in ipairs(nearby.actors) do
                if actor.type == types.NPC and actor.id ~= self.id and K.distTo(actor) < configGlobal.technical.npcDanceDistance then
                    actor:sendEvent('TimeToDance', K.musicTime)
                end
            end
        end
    end
end

return K