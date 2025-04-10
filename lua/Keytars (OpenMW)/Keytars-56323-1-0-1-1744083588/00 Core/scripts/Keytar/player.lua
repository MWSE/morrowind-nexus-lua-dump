local types = require("openmw.types")
local core = require("openmw.core")
local self = require("openmw.self")
local anim = require("openmw.animation")
local I = require("openmw.interfaces")
local nearby = require("openmw.nearby")
local ambient = require('openmw.ambient')
local input = require('openmw.input')
local camera = require('openmw.camera')

local configGlobal = require('scripts.Keytar.config.global')
local configPlayer = require('scripts.Keytar.config.player')
local K = require("scripts.Keytar.keytarist")

local lastRealTime = core.getRealTime()

local ambientCheckTimer = 0
local ambientCheckInterval = 0.1 -- seconds

local function canPlayKeytar()
    return K.isValidKeytarist(self) and types.Actor.getStance(self) == types.Actor.STANCE.Weapon
end

local function togglePlaying()
    if K.isPlaying() then
        K.stopPlaying()
    elseif canPlayKeytar() then
        K.startPlaying(configGlobal.technical.playerKeytarVolume)
    end
end

local function receiveTime(time)
    K.musicTime = time.time + (core.getRealTime() - time.realTime)
    anim.cancel(self, 'keytar')
    K.startAnim('keytar')
end

local function handleKeyPress(key)
    if key.code == configPlayer.keybinds.toggleKeytar then
        togglePlaying()
    end
end

local function isAnyPlaying()
    if K.isPlaying() or core.sound.isSoundFilePlaying("Sound\\keytar\\dagoth-reverb.mp3", self) then
        return true
    else
        for _, actor in ipairs(nearby.actors) do
            if actor.type == types.NPC and core.sound.isSoundFilePlaying("Sound\\keytar\\dagoth.mp3", actor) then
                return true
            end
        end
    end
    return false
end

local function handleAmbientCheck(dt)
    if configGlobal.options.silenceAmbientMusic == true then
        ambientCheckTimer = ambientCheckTimer + (core.getRealTime() - lastRealTime)
        if ambientCheckTimer >= ambientCheckInterval then
            ambientCheckTimer = 0
            if isAnyPlaying() and not ambient.isSoundFilePlaying("Sound\\keytar\\silence.wav") then
                ambient.streamMusic("Sound\\keytar\\silence.wav", { fadeOut = 0.5 })
            end
        end
    end
end

local function update(dt)
    if not canPlayKeytar() then
        K.stopPlaying()
    end
    if not K.isPlaying() then
        K.musicTime = -1
        anim.cancel(self, 'keytar')
    else
        K.musicTime = (K.musicTime + (core.getRealTime() - lastRealTime)) % K.musicUtils.getSongLength()

        -- allow mode transitions even during playing animation
        if camera.getQueuedMode() == camera.MODE.FirstPerson then
            camera.setMode(camera.MODE.FirstPerson, true)
        elseif camera.getQueuedMode() == camera.MODE.ThirdPerson then
            camera.setMode(camera.MODE.ThirdPerson, true)
        end

        if not anim.isPlaying(self, 'keytar') then
            K.startAnim('keytar')
        end
    end

    if core.getRealTime() - lastRealTime > 0.25 then
        K.resyncAnim('keytar')
    end
    
    lastRealTime = core.getRealTime()
    K.tickDanceSend(dt)
end

return {
    engineHandlers = {
        onUpdate = update,
        onFrame = handleAmbientCheck,
        onKeyPress = handleKeyPress
    },
    eventHandlers = {
        ReceiveInspiration = function()
            types.Actor.activeSpells(self):add({  
                id = '_rlts_bardinspiration',
                effects = { 0 },
                ignoreResistances = true,
                ignoreSpellAbsorption = true,
                ignoreReflect = true
            })
        end,
        SendKeytarTime = receiveTime
    }
}