local this = {}

local config = require("tew.AURA.config")
local cellData = require("tew.AURA.cellData")
local moduleData = require("tew.AURA.moduleData")
local soundData = require("tew.AURA.soundData")
local sounds = require("tew.AURA.sounds")
local common = require("tew.AURA.common")
local debugLog = common.debugLog

local waterLevel
local playerPosZ
local playerHeight

local originalVolumes = {}

local function setVolume(track, volume)
	local rounded = math.round(volume, 2)
	debugLog(string.format("Setting volume for track %s to %s", track.id, rounded))
	track.volume = rounded
end

local function storeOriginalVolumes()
    debugLog("Storing current weather volumes.")
    table.clear(originalVolumes)
    for _, sound in pairs(soundData.weatherLoops) do
        originalVolumes[sound.id] = sound.volume
	end
end

-- Only modify volumes for actively playing `rainLoopSound`, or for weather
-- loops if they play attached to the player reference (player is underwater
-- in interior and IW module is active), or in case they play unattached,
-- check for eligible weather index before we do.
local function modifyWeatherVolume()
    local cw = tes3.worldController.weatherController.currentWeather
    local mp = tes3.mobilePlayer
    for _, sound in pairs(soundData.weatherLoops) do
        local originalVol = originalVolumes[sound.id]
		if sound:isPlaying() then
            if (cw and cw.rainLoopSound and cw.rainLoopSound == sound)
            or (cw and (cw.index == 6 or cw.index == 7 or cw.index == 9))
            or (mp and tes3.getSoundPlaying{sound = sound, reference = mp.reference}) then
                local volume = math.clamp(originalVol - math.remap(waterLevel - (playerPosZ + playerHeight), 0, 1500, 0, originalVol), 0.0, originalVol)
                if (math.round(volume, 2) ~= math.round(sound.volume, 2)) then
                    setVolume(sound, volume)
                end
            end
		end
	end
end

-- Only reset tracks that play attached to the player reference.
-- Don't want to reset tracks attached to windoors, rainyStatics etc.
-- Modules will handle that individually.
local function underwaterResetModules()
    for moduleName, data in pairs(moduleData) do
        if tes3.mobilePlayer
        and sounds.getTrackPlaying(moduleData[moduleName].new, tes3.mobilePlayer.reference)
        and not sounds.isStopping(moduleName, tes3.mobilePlayer.reference)
        then
            debugLog("Resetting sounds for module " .. moduleName)
            sounds.removeImmediate { module = moduleName }
            sounds.playImmediate { module = moduleName, last = true }
        end
    end
end

local splashVol = config.volumes.misc.splashVol / 100
local function underwaterCheck(e)
	if not (tes3.player and tes3.mobilePlayer) then return end
    waterLevel = tes3.player.cell.waterLevel or 0
    playerPosZ = tes3.player.position.z or 0
    playerHeight = tes3.player.object.boundingBox and tes3.player.object.boundingBox.max.z or 0
	if (not cellData.playerUnderwater) and tes3.mobilePlayer.isSwimming and (playerPosZ + playerHeight < waterLevel) then
        cellData.playerUnderwater = true
        debugLog("Player underwater.")
        if config.playSplash then
            tes3.playSound { sound = "splash_lrg", volume = 0.5 * splashVol, pitch = 0.6 }
        end
        underwaterResetModules()
        if config.underwaterRain then
            storeOriginalVolumes()
            event.unregister(tes3.event.simulate, modifyWeatherVolume)
            event.register(tes3.event.simulate, modifyWeatherVolume)
            debugLog("Started underwater volume scaling.")
        end
        event.trigger("AURA:enteredUnderwater")
    elseif cellData.playerUnderwater and ((not tes3.mobilePlayer.isSwimming) or (playerPosZ + playerHeight >= waterLevel)) then
        cellData.playerUnderwater = false
        debugLog("Player above water level.")
        if config.playSplash then
            tes3.playSound { sound = "splash_sml", volume = 0.6 * splashVol, pitch = 0.7 }
        end
        if config.underwaterRain then
            event.unregister(tes3.event.simulate, modifyWeatherVolume)
            event.unregister(tes3.event.simulate, underwaterCheck)
            debugLog("Stopped underwater volume scaling, restoring original volumes.")
            for id, originalVol in pairs(originalVolumes) do
                local sound = tes3.getSound(id)
                setVolume(sound, originalVol)
            end
            event.register(tes3.event.simulate, underwaterCheck)
        end
        -- Make sure we reset modules _after_ restoring original volumes,
        -- so that sounds play at the correct volume for each module.
        underwaterResetModules()
        event.trigger("AURA:exitedUnderwater")
    end
end

event.unregister(tes3.event.simulate, underwaterCheck)
event.register(tes3.event.simulate, underwaterCheck)