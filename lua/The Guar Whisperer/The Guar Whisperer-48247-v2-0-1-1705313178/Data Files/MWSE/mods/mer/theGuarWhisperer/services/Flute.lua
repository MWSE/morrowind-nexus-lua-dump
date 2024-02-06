local GuarCompanion = require("mer.theGuarWhisperer.GuarCompanion")
local Controls = require("mer.theGuarWhisperer.services.Controls")
local common = require("mer.theGuarWhisperer.common")
local logger = common.createLogger("Flute")

local function onEquipFlute(e)
    if not common.getModEnabled() then
        logger:trace("Mod disabled")
        return
    end
    if not ( e.item.id == common.fluteId ) then
        logger:trace("Activated item not a flute: %s", e.item.id)
    else
        logger:debug("Found a flute. Leaving menu mode: %s", e.item.id)
        tes3ui.leaveMenuMode()
        timer.delayOneFrame(function()
            local buttons = {}
            if tes3.player.cell.isInterior ~= true then
                logger:debug("Finding companions to summon")
                ---@param guar GuarWhisperer.GuarCompanion
                for _, guar in ipairs(GuarCompanion.getAll()) do
                    local animalName = guar:getName()
                    if not guar:canBeSummoned() then
                        logger:debug("%s cannot be summoned", animalName)
                    else
                        logger:debug("%s can be summoned, adding to list", animalName)
                        table.insert(buttons, {
                            text = animalName,
                            callback = function()
                                timer.delayOneFrame(function()
                                    if not guar:isValid() then return end
                                    tes3.playSound{ reference = tes3.player, sound = common.fluteSound, }
                                    guar.ai:wait()
                                    timer.start{
                                        duration = 1,
                                        callback = function()
                                            if guar:isValid() then guar.ai:teleportToPlayer(400) end
                                        end
                                    }
                                    Controls.fadeTimeOut( 0, 2, function()
                                        if guar:isValid() then
                                            guar.ai:playAnimation("pet")
                                            guar.ai:follow()
                                        end
                                    end)
                                end)
                            end
                        })
                    end
                end
            else
                logger:debug("In interior, flute won't work")
            end
            if #buttons > 0 then
                logger:debug("Found at least one companion, calling messageBox")
                table.insert(buttons, { text = "Cancel"})
                tes3ui.showMessageMenu{
                    message = "Which guar do you want to call?",
                    buttons = buttons
                }
            else
                logger:debug("No companions found, playing flute sound")
                tes3.playSound{ reference = tes3.player, sound = common.fluteSound, }
            end
        end)
    end
end


event.register("equip", onEquipFlute)