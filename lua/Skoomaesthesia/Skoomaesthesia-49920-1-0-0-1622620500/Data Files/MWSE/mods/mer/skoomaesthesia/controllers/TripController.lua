local config = require('mer.skoomaesthesia.config')
local Util = require('mer.skoomaesthesia.util.Util')
local ShaderService = require('mer.skoomaesthesia.services.ShaderService')
local MusicService = require('mer.skoomaesthesia.services.MusicService')
local TripStateService = require('mer.skoomaesthesia.services.TripStateService')
local AddictionService = require('mer.skoomaesthesia.services.AddictionService')

local function startTrip()
    if not TripStateService.isState('beginning') then
        TripStateService.updateState('beginning')
        ShaderService.turnOnShaderEffects()
        MusicService.playCreepySounds()
        AddictionService.removeWithdrawals()
    end
end

local function endTrip()
    if not TripStateService.isState('ending') then
        TripStateService.updateState('ending')
        ShaderService.turnOffShaderEffects()
        MusicService.stopCreepySounds()
    end
end

local function skoomaSpellTick(e)
    if e.target ~= tes3.player then return end
    if e.source.name and e.source.name:lower() == "skooma" then
        if e.effectInstance.state == tes3.spellState.beginning then
            if config.mcm.enableHallucinations then
                if TripStateService.isState('ending') or TripStateService.getState() == nil then
                    Util.log:debug("Drank Skooma, starting Trip")
                    startTrip()
                    if config.mcm.enableAddiction then
                        AddictionService.smoke()
                    end
                end
            end
        end
    end
end
event.register("spellTick", skoomaSpellTick)


local function checkSkoomaExpired()
    if TripStateService.isState('ending') or not TripStateService.getState() then return end
    local skoomaActive = false
    local activeEffect = tes3.mobilePlayer.activeMagicEffects
    for _ = 1, tes3.mobilePlayer.activeMagicEffectCount+1 do
        local instance = activeEffect.instance
        if instance and instance.item and instance.item.name then
            if instance.item.name:lower() == "skooma" then
                skoomaActive = true
            end
        end
        activeEffect = activeEffect.next
    end
    if not skoomaActive then
        Util.log:debug("Skooma ran out, ending Trip")
        endTrip()
    end
end

local function handleTripOnLoad(e)
    config.pipeAnimating = nil
    ShaderService.resetShader()
    timer.start{
        type = timer.simulate,
        duration = 1,
        callback = function()
            Util.log:debug("Checking trip on load")
            local tripState = TripStateService.getState()
            Util.log:debug("Tripstate: %s", tripState)
            if tripState == "ending" then
                Util.log:debug("ending")
                TripStateService.updateState(nil)
            elseif tripState and config.mcm.enableHallucinations then
                Util.log:debug("Has a trip state, turning on shader effects")
                MusicService.playCreepySounds()
                ShaderService.turnOnShaderEffects()
            end
            timer.start{
                type = timer.simulate,
                duration = 0.1,
                callback = checkSkoomaExpired,
                iterations = -1
            }
        end
    }
end
event.register("loaded", handleTripOnLoad)


--Time Effects
local function getColorCycle()
    local moduloMinutes = (os.clock()*0.1)%2
    moduloMinutes = (moduloMinutes < 1) 
        and moduloMinutes 
        or (1 - (moduloMinutes-1))
    return moduloMinutes
end

local function slowTime(e)
    if tes3ui.menuMode() or not tes3.player then return end
    if TripStateService.getState() ~= nil then
        tes3.worldController.deltaTime = tes3.worldController.deltaTime * config.static.timeShift
    end
    mge.setShaderFloat{
        shader=config.static.shaderName,
        variable="cycle",
        value= getColorCycle()
    }
end
event.register("enterFrame", slowTime)

local function slowDownSoundEffects(e)
    if tes3ui.menuMode() or not tes3.player then return end
    if TripStateService.getState() ~= nil then
        e.pitch = e.pitch / 2
        e.isVoiceover = false
    end
end
event.register("addSound", slowDownSoundEffects)

local function blockMusicChange(e)
    if (TripStateService.getState() ~= nil) and not TripStateService.isState('ending') then
        Util.log:debug("Changing music path to Skoomaesthesia")
        e.music = config.static.musicPath
    end 
end
event.register("musicSelectTrack", blockMusicChange)

local function blockEquipWhileAnimating(e)
    if config.pipeAnimating then
        return false
    end
end
event.register("equip", blockEquipWhileAnimating, { priority = 1234 })

