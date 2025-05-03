local types = require("openmw.types")
local core = require("openmw.core")
local self = require("openmw.self")
local anim = require("openmw.animation")
local nearby = require("openmw.nearby")
local ambient = require('openmw.ambient')
local camera = require('openmw.camera')
local ui = require('openmw.ui')

local configGlobal = require('scripts.Keytar.config.global')
local configPlayer = require('scripts.Keytar.config.player')
local K = require("scripts.Keytar.keytarist")

local wavParser = require('scripts.Keytar.util.wav_parser')
local genres = wavParser.Genre

local bpmCoroutine = nil

local lastRealTime = core.getRealTime()
local lastFrameTime = core.getRealTime()

local ambientCheckTimer = 0
local ambientSilenced = false

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
            if actor.type == types.NPC and core.sound.isSoundFilePlaying("Sound\\keytar\\" .. configGlobal.customMusic.customMusicPath, actor) then
                return true
            end
        end
    end
    return false
end

local function triggerAmbientCheck()
    ambientCheckTimer = configGlobal.technical.silenceAmbientMusicInterval
end

local function triggerDetectBPM()
	if bpmCoroutine == nil then
		local fileName = "sound/keytar/" .. configGlobal.customMusic.customMusicPath
		local genre = genres[configGlobal.customMusic.customMusicGenre]
		wavParser.batchSizeMult = configGlobal.customMusic.autoDetectBatchSize
		bpmCoroutine = wavParser.calculateBPMByGenre(fileName, genre, configGlobal.customMusic.autoDetectVerbose)
		ui.showMessage("Detecting BPM, please wait...")
	end
end

local function handleAmbientCheck()
    if configGlobal.options.silenceAmbientMusic == true then
        ambientCheckTimer = ambientCheckTimer + (core.getRealTime() - lastFrameTime)
        if ambientCheckTimer >= configGlobal.technical.silenceAmbientMusicInterval then
            ambientCheckTimer = 0
            if isAnyPlaying() then
                ambient.streamMusic("Sound\\keytar\\silence.opus", { fadeOut = 0.5 })
                ambientSilenced = true
            elseif ambientSilenced then
                ambient.stopMusic()
                ambientSilenced = false
            end
        end
    end
end

local function frame()
    handleAmbientCheck()

    if bpmCoroutine ~= nil then
        if coroutine.status(bpmCoroutine) == "dead" then
            bpmCoroutine = nil
        else
            local success, done, bpm, confidence, duration = coroutine.resume(bpmCoroutine)
            if not success then
				ui.showMessage("Error in BPM detection, see log for details.")
                print("Error in BPM coroutine: " .. done)
                bpmCoroutine = nil
            elseif done then
				ui.showMessage("BPM detection complete!")
                print("Detected BPM: " .. bpm .. ", Confidence: " .. confidence)
                bpmCoroutine = nil
				core.sendGlobalEvent('DetectBPMComplete', {bpm = bpm, duration = duration})
            end
        end
    end

    lastFrameTime = core.getRealTime()
end

local function update(dt)
    if not canPlayKeytar() and K.isPlaying() then
        K.stopPlaying()
    end
    if not K.isPlaying() then
        K.musicTime = -1
        if anim.isPlaying(self, 'keytar') then
            anim.cancel(self, 'keytar')
        end
    else
        K.musicTime = (K.musicTime + (core.getRealTime() - lastRealTime)) % configGlobal.customMusic.customMusicLength

        -- allow mode transitions even during playing animation
        if camera.getQueuedMode() == camera.MODE.FirstPerson then
            camera.setMode(camera.MODE.FirstPerson, true)
        elseif camera.getQueuedMode() == camera.MODE.ThirdPerson then
            camera.setMode(camera.MODE.ThirdPerson, true)
        end

        if not anim.isPlaying(self, 'keytar') then
            K.startAnim('keytar')
        end

        K.handleMovement(dt)
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
        onFrame = frame,
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
        SendKeytarTime = receiveTime,
        RecheckAmbient = triggerAmbientCheck,
        engaging = triggerAmbientCheck,
        disengaging = triggerAmbientCheck,
        DetectBPMStart = triggerDetectBPM
    }
}