-- Register the mod config menu (using EasyMCM library).
event.register("modConfigReady", function()
    require("OperatorJack.BetterBuoyancy.mcm")
end)

local config = require("OperatorJack.BetterBuoyancy.config")

event.register("simulate", function(e)
    if (tes3.mobilePlayer.encumbrance.normalized > 1.0 or tes3.mobilePlayer.paralyze > 0) then
        return
    end

    if (tes3.mobilePlayer.levitate > 0 and config.levitationControlsEnabled == true) then
        local delta = tes3.mobilePlayer.flySpeed

        local inputController = tes3.worldController.inputController
        local isUpPressed = inputController:keybindTest(tes3.keybind.jump, tes3.keyTransition.up)
        local isDownPressed = inputController:keybindTest(tes3.keybind.sneak, tes3.keyTransition.up)

        if (isUpPressed == true) then
            tes3.mobilePlayer.velocity.z = delta
            return
        end
        
        if (isDownPressed == true and (tes3.player.position.z - tes3.mobilePlayer.lastGroundZ) >= delta) then
            tes3.mobilePlayer.velocity.z = delta * -1
            return
        end
    elseif (tes3.mobilePlayer.underwater == true and config.underwaterControlsEnabled == true) then
        local delta = e.delta * (tes3.mobilePlayer.isRunning and tes3.mobilePlayer.swimRunSpeed or tes3.mobilePlayer.swimSpeed)

        local inputController = tes3.worldController.inputController
        local isUpPressed = inputController:keybindTest(tes3.keybind.jump, tes3.keyTransition.up)
        local isDownPressed = inputController:keybindTest(tes3.keybind.sneak, tes3.keyTransition.up)

        if (isUpPressed == true) then
            local eyepos = tes3.getPlayerEyePosition()
            local rayhit = tes3.rayTest({
                position = eyepos, 
                direction = tes3vector3.new(0, 0, 1), 
                ignore = {
                    tes3.player
                }
            })
            if rayhit then
                if (eyepos:distance(rayhit.intersection) <= delta + 20) then
                    return
                end
            end

            tes3.player.position.z = tes3.player.position.z + delta
            return
        end
        
        if (isDownPressed == true and (tes3.player.position.z - tes3.mobilePlayer.lastGroundZ) >= delta) then
            tes3.player.position.z = tes3.player.position.z - delta
            return
        end
    end
end)