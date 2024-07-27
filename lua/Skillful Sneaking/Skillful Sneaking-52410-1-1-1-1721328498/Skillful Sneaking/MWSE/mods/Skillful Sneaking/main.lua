--[[
    Skillful Sneaking
    Author: None
--]]

local config = require("Skillful Sneaking.config")

dofile("Skillful Sneaking.mcm")

local function isMoving(mobile)
    return mobile.isMovingForward or mobile.isMovingBack or mobile.isMovingLeft or mobile.isMovingRight
end

-- Scaling Sneaking Speed
local function onCalcMoveSpeed(e)
    if (not config.enabled) then
        return
    end

    if (e.reference == tes3.player and tes3.mobilePlayer.isSneaking and isMoving(tes3.mobilePlayer)) then
        if (tes3.mobilePlayer.encumbrance.current > tes3.mobilePlayer.encumbrance.base) then
            return
        end
        local refSpeed = (( tes3.mobilePlayer.runSpeed / tes3.findGMST(tes3.gmst.fSneakSpeedMultiplier).value ) * ( config.speedCap / 100 ))
        local newSpeed = e.speed + ( tes3.mobilePlayer.sneak.current * ( config.skillScaling / 100 ))
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
            if ( tes3.mobilePlayer.encumbrance.current > tes3.mobilePlayer.encumbrance.base ) then
                if ( tes3ui.findHelpLayerMenu("MenuNotify3") ) then
                    if ( tes3ui.findHelpLayerMenu("MenuNotify3"):findChild(-580).text == tes3.findGMST(tes3.gmst.sNotifyMessage59).value ) then
                        return
                    end
                end
                tes3.messageBox(tes3.findGMST(tes3.gmst.sNotifyMessage59).value )
                return
            end

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

            tes3.mobilePlayer:doJump({ velocity = ( playerVelocity * ( config.jumpCap / 100 )), applyFatigueCost = true })
            tes3.mobilePlayer:exerciseSkill(tes3.skill.acrobatics, 0.1)
        end
    end
end
event.register(tes3.event.keyDown, keyDownCallback)