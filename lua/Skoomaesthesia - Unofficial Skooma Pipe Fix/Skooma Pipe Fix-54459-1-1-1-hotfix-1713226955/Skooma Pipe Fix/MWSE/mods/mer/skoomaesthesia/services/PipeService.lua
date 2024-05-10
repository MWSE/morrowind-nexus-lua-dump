
local common = require('mer.skoomaesthesia.common')
local logger = common.createLogger('PipeService')
local config = require('mer.skoomaesthesia.config')
local AnimationService = require('mer.skoomaesthesia.services.AnimationService')
local TripStateService = require('mer.skoomaesthesia.services.TripStateService')
local ItemService = require('mer.skoomaesthesia.services.ItemService')

local PipeService = {
    skipEquipSkooma = nil,
    skipActivatePipe = nil
}

local function getDuration(duration)
    local tripping = TripStateService.getState()
    local multi = tripping and config.static.timeShift or 1.0
    return duration / multi
end

function PipeService.smokeSkooma(e)
    logger:debug("PipeService.smokeSkooma")
    if not ItemService.playerHasMoonSugar() then
        tes3.messageBox("You are out of moon sugar.")
        return
    end
    local pipeRef = e.reference
    local pipeObj = e.object or pipeRef and pipeRef.object
    AnimationService.smokeSkooma({reference=pipeRef, object=pipeObj})
    logger:debug("PipeService.smokeSkooma starting timer")
    timer.start{
        type = timer.simulate,
        iterations = 1,
        duration = getDuration(2.5),
        callback = function()
            tes3.playSound{
                reference = tes3.player,
                soundPath = 'skoomaesthesia\\inhale.wav'
            }
            timer.start{
                type = timer.simulate,
                iterations = 1,
                duration = getDuration(2),
                callback = function()
                    config.skipEquip = true
                    tes3.addItem{
                        reference = tes3.player,
                        item = "potion_skooma_01",
                        count = 1,
                        playSound = false,
                        updateGUI = false
                    }

						timer.delayOneFrame(function()
						mwscript.equip{ ---@diagnostic disable-line
							reference = tes3.player,
							item="potion_skooma_01"
                    }
						end)

                    local moonSugar = ItemService.getMoonSugar()
                    if moonSugar then
                        tes3.removeItem{
                            reference = tes3.player,
                            item = moonSugar,
                            playSound = false,
                            count = 1
                        }
                    else
                        logger:warn("No moon sugar found in player inventory")
                    end
                    config.skipEquip = false
                    logger:debug("PipeService.smokeSkooma done")
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
            requirements = ItemService.playerHasMoonSugar,
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
    tes3ui.showMessageMenu{
        message = pipeObj.name,
        buttons = buttons,
        cancels = true
    }
end

return PipeService