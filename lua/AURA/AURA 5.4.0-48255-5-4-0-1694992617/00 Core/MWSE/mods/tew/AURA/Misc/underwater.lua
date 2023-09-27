local this = {}

local config = require("tew.AURA.config")
local cellData = require("tew.AURA.cellData")
local fader = require("tew.AURA.fader")
local moduleData = require("tew.AURA.moduleData")
local sounds = require("tew.AURA.sounds")
local common = require("tew.AURA.common")
local debugLog = common.debugLog

local function underwaterReset(pitch)
    for moduleName, data in pairs(moduleData) do
        if data.playUnderwater and cellData.cell
        and ((not cellData.cell.isInterior) or (cellData.cell.behavesAsExterior))
        and sounds.getTrackPlaying(moduleData[moduleName].new, moduleData[moduleName].newRef)
        and (not fader.isRunning{module=moduleName, track=moduleData[moduleName].new, reference=moduleData[moduleName].newRef, fadeType="out"})
        then
            sounds.removeImmediate { module = moduleName }
            sounds.playImmediate { module = moduleName, last = true, pitch = pitch }
        end
    end
end

local splashVol = config.volumes.misc.splashVol / 100
local function underwaterCheck()
    if not tes3.mobilePlayer then return end
    if tes3.mobilePlayer.underwater then
        if not cellData.playerUnderwater then
            cellData.playerUnderwater = true
            debugLog("Player underwater.")
            if config.playSplash then
                tes3.playSound { sound = "splash_lrg", volume = 0.5 * splashVol, pitch = 0.6 }
            end
            underwaterReset(0.5)
            timer.start{
                duration = 1,
                callback = function()
                    event.trigger("AURA:aboveOrUnderwater")
                end,
            }
        end
    else
        if cellData.playerUnderwater then
            cellData.playerUnderwater = false
            debugLog("Player above water level.")
            if config.playSplash then
                tes3.playSound { sound = "splash_sml", volume = 0.6 * splashVol, pitch = 0.7 }
            end
            underwaterReset(1)
            timer.start{
                duration = 1,
                callback = function()
                    event.trigger("AURA:aboveOrUnderwater")
                end,
            }
        end
    end
end
event.register("simulate", underwaterCheck)