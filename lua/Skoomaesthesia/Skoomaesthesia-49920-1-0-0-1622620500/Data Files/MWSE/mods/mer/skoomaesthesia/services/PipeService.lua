local PipeService = {}
local config = require('mer.skoomaesthesia.config')
local Util = require('mer.skoomaesthesia.util.Util')
local AnimationService = require('mer.skoomaesthesia.services.AnimationService')
local TripStateService = require('mer.skoomaesthesia.services.TripStateService')
PipeService.skipEquipSkooma = nil
PipeService.skipActivatePipe = nil

local function getDuration(duration)
    local tripping = TripStateService.getState()
    local multi = tripping and config.static.timeShift or 1.0
    return duration / multi
end

function PipeService.smokeSkooma(e)
    Util.log:debug("PipeService.smokeSkooma")
    if not Util.hasMoonSugar() then
        tes3.messageBox("You are out of moon sugar.")
        return
    end
    local pipeRef = e.reference
    local pipeObj = e.object or pipeRef and pipeRef.object
    AnimationService.smokeSkooma({reference=pipeRef, object=pipeObj})
    Util.log:debug("PipeService.smokeSkooma starting timer") 
    timer.start{
        type = timer.simulate, 
        iterations = 1,
        duration = getDuration(2.5),
        callback = function()
            Util.log:debug("PipeService.smokeSkooma calback 2.5")
            tes3.playSound{
                reference = tes3.player,
                soundPath = 'skoomaesthesia\\inhale.wav'
            }
            timer.start{
                type = timer.simulate, 
                iterations = 1,
                duration = getDuration(2),
                callback = function()   
                    Util.log:debug("PipeService.smokeSkooma 4.5")
                    config.skipEquip = true
                    tes3.addItem{ 
                        reference = tes3.player, 
                        item = "potion_skooma_01", 
                        count = 1, 
                        playSound = false, updateGUI = false 
                    }
                    tes3.removeItem{ 
                        reference = tes3.player, 
                        item = "ingred_moon_sugar_01", 
                        playSound = false,
                            count = 1
                    }
                    mwscript.equip{ 
                        reference = tes3.player, 
                        item="potion_skooma_01"
                    }
                    config.skipEquip = false
                    Util.log:debug("PipeService.smokeSkooma done")
                end
            }
        end
    }
end

function PipeService.showPipeMenu(e)
    local pipeRef = e.reference
    local pipeObj = pipeRef and pipeRef.object or e.object
    local buttons = {
        {
            text = "Smoke Moon Sugar",
            requirements = Util.hasMoonSugar,
            tooltipDisabled = {
                text = "You do not have any moon sugar."
            },
            callback = function()
                PipeService.smokeSkooma({reference=pipeRef, object=pipeObj})
            end,
        },
        {
            text = "Pick Up",
            showRequirements = function() return pipeRef ~= nil end,
            callback = function()
                timer.delayOneFrame(function()
                    PipeService.skipActivatePipe = true
                    tes3.player:activate(pipeRef)
                end)
            end
        }
    }
    Util.messageBox{
        message = pipeObj.name,
        buttons = buttons,
        doesCancel = true
    }
end

return PipeService