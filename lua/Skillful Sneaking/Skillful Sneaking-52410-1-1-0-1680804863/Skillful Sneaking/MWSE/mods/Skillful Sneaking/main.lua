--[[
    Skillful Sneaking
    Author: None
--]]

local config = require("Skillful Sneaking.config")

dofile("Skillful Sneaking.mcm")

-- Scaling Sneaking Speed
local function onCalcMoveSpeed(e)
    if (not config.enabled) then
        return
    end

    if (e.reference == tes3.player and tes3.mobilePlayer.isSneaking) then
        local refSpeed = ( ( tes3.mobilePlayer.runSpeed / tes3.findGMST(1199).value ) * ( config.speedCap / 100 ) )
        local newSpeed = e.speed + ( tes3.mobilePlayer.sneak.current * ( config.skillScaling / 100) )
            if (newSpeed > refSpeed) then
                newSpeed = refSpeed
            end
        e.speed = newSpeed
    end
end
event.register(tes3.event.calcMoveSpeed, onCalcMoveSpeed)

-- Sneak Jumping
local function keyDownCallback(e)
    if (not config.enabled) then
        return
    end

    if e.keyCode == tes3.getInputBinding(tes3.keybind.jump).code then
        if tes3.menuMode() ~= true and tes3.mobilePlayer.isSneaking then

            local forwardKey = tes3.getInputBinding(0).code
            local backwardKey = tes3.getInputBinding(1).code
            local leftKey = tes3.getInputBinding(2).code
            local rightKey = tes3.getInputBinding(3).code

            local forward = tes3.mobilePlayer.reference.forwardDirection
            local right = tes3.mobilePlayer.reference.rightDirection
            local input = tes3.worldController.inputController

            local jumpDirection = tes3vector2.new(0,0)
            if input:isKeyDown(forwardKey) or tes3.mobilePlayer.autoRun then
                jumpDirection = jumpDirection + forward
            elseif input:isKeyDown(backwardKey) then
                jumpDirection = jumpDirection - forward
            end
            if input:isKeyDown(rightKey) then
                jumpDirection = jumpDirection + right
            elseif input:isKeyDown(leftKey) then
                jumpDirection = jumpDirection - right
            end
            local playerVelocity = tes3.mobilePlayer:calculateJumpVelocity({ direction = jumpDirection })

            tes3.mobilePlayer:doJump({ velocity = ( playerVelocity * ( config.jumpCap / 100 ) ), applyFatigueCost = true })
            tes3.mobilePlayer:exerciseSkill(tes3.skill.acrobatics, 0.1)
        end
    end
end
event.register(tes3.event.keyDown, keyDownCallback)