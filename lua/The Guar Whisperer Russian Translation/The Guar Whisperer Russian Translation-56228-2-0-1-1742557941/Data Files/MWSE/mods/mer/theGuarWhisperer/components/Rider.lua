---A companion component that enables them to be mounted and ridden
local common = require("mer.theGuarWhisperer.common")
local logger = common.createLogger("Rider")

---@class GuarWhisperer.Rider.GuarCompanion.refData
---@field isRiding boolean True while the player is riding this guar
---@field isMovingForward boolean True while the guar is moving forward

---@class GuarWhisperer.Rider.GuarCompanion : GuarWhisperer.GuarCompanion

---@class GuarWhisperer.Rider
---@field guar GuarWhisperer.Rider.GuarCompanion
---@field refData GuarWhisperer.Rider.GuarCompanion.refData
local Rider = {
    ROTATE_SPEED = 0.07,
    MOVE_DISTANCE = 2000,
    MOVE_INTERVAL = 1,
}

function Rider.new(guar)
    local self = setmetatable({}, { __index = Rider })
    self.guar = guar
    self.refData = guar.refData
    return self
end

function Rider.lockPlayer()
    tes3.force1stPerson()
    tes3.player.mobile.viewSwitchDisabled = true
    --tes3.player.mobile.controlsDisabled = true
    tes3.player.mobile.vanityDisabled = true
    tes3.mobilePlayer.mobToMobCollision = false
    tes3.mobilePlayer.movementCollision = false
end

function Rider.unlockPlayer()
    --tes3.player.mobile.controlsDisabled = false
    tes3.player.mobile.viewSwitchDisabled = false
    tes3.player.mobile.vanityDisabled = false
    tes3.mobilePlayer.mobToMobCollision = true
    tes3.mobilePlayer.movementCollision = true

end

function Rider.getRefBeingRidden()
    return tes3.player.data.tgw_guarBeingRidden
        and tes3.getReference(tes3.player.data.tgw_guarBeingRidden)
end

function Rider:isRiding()
    return self.refData.isRiding
end

function Rider:setRiding(isRiding)
    self.refData.isRiding = isRiding
    tes3.player.data.tgw_guarBeingRidden = isRiding and self.guar.reference.id or nil
end

---@param loopCount number Default -1 (infinite). 0 = once, 1 = twice, etc.
function Rider:crouch(loopCount)
    loopCount = loopCount or -1
    tes3.playAnimation{
        reference = self.guar.reference,
        group = tes3.animationGroup.idle3,
        startFlag = tes3.animationStartFlag.immediate,
        loopCount = loopCount,
    }
end

function Rider.doShowMountInstructions()
    return not tes3.player.data.tgw_hasShownMountInstructions
end

function Rider.showMountInstructions()
    local instructions = {
        {
            message = "Прикажите своему гуару двигаться туда, куда вы смотрите. Удерживайте нажатой кнопку, чтобы двигаться по труднопроходимой местности.",
            code = tes3.getInputBinding(tes3.keybind.forward).code,
        },
        {
            message = "Прикажите своему гуару прекратить движение.",
            code = tes3.getInputBinding(tes3.keybind.back).code
        },
        {
            message = "Прикажите своему гуару присесть.",
            code = tes3.getInputBinding(tes3.keybind.sneak).code,
        },
        {
            message = "Откройте меню, чтобы отсоединиться или отдать другие команды.",
            code = common.config.mcm.commandToggleKey.keyCode
        },
        {
            message = "Переключение между ходьбой и бегом.",
            code = tes3.getInputBinding(tes3.keybind.alwaysRun).code,
        }

    }

    tes3ui.showMessageMenu{
        header = "Управление вашим гуаром",
        customBlock = function (parent)
            parent.minWidth = 400
            parent.paddingAllSides = 10
            for _, instruction in ipairs(instructions) do
                local key = common.util.getLetter(instruction.code)
                local block = parent:createBlock()
                block.flowDirection = "top_to_bottom"
                block.paddingAllSides = 4
                block.widthProportional = 1.0
                block.autoHeight = true
                do --Letter
                    local letter = string.format('"%s":', key)
                    local letterLabel = block:createLabel{ text = letter }
                    letterLabel.color = tes3ui.getPalette("header_color")
                    letterLabel.autoHeight = true
                    letterLabel.widthProportional = 1.0
                    letterLabel.justifyText = tes3.justifyText.center
                    letterLabel.wrapText = true
                end
                do --Message
                    local message = string.format(instruction.message, key)
                    local label = block:createLabel{text = message}
                    label.autoHeight = true
                    label.widthProportional = 1.0
                    label.justifyText = tes3.justifyText.center
                    label.wrapText = true
                end
            end
        end,
        buttons = {
            {
                text = "OK",
            },
            {
                text = "Больше не показывать",
                callback = function()
                    tes3.player.data.tgw_hasShownMountInstructions = true
                end
            }
        }
    }
end


function Rider:mount()
    tes3.messageBox(self.guar:format("Ехать {name}"))
    if Rider.getRefBeingRidden() then
        logger:debug(self.guar:format("{Name} уже выполняет"))
        return
    end
    Rider.lockPlayer()
    self.guar.ai:follow()
    self:crouch(0)
    timer.start{
        duration = 0.75,
        callback = function()
            if not self.guar:isValid() then return end
            self:setRiding(true)
            tes3.player.orientation = self.guar.reference.orientation:copy()

            if self.guar:isOverEncumbered() then
                tes3.messageBox(self.guar:format("{Name} перегружен и не может двигаться."))
            end

            if Rider.doShowMountInstructions() then
                timer.start{
                    duration = 0.5,
                    callback = function()
                        Rider.showMountInstructions()
                    end
                }
            end
        end
    }
end

function Rider:cancel()
    self:setRiding(false)
    Rider.unlockPlayer()
end

function Rider:dismount()
    self:crouch(0)
    timer.start{
        duration = 0.75,
        callback = function()
            if not self.guar:isValid() then return end
            self:cancel()
            local zRot = self.guar.reference.orientation.z - (math.pi / 2)
            --position player to guars left
            local dropPosition = self.guar.reference.position:copy() + tes3vector3.new(
                math.sin(zRot) * 100,
                math.cos(zRot) * 100,
                0
            )

            tes3.player.position = dropPosition
            self.guar.ai:wait()
        end
    }
end


function Rider:isMovingForward()
    return self.guar.reference.mobile.actionData.aiBehaviorState == tes3.aiBehaviorState.walk
end

--- Find a valid position ahead of the guar to move to
---@param e { movingLeft: boolean, movingRight: boolean }
function Rider:getAheadPosition(e)
    --do a ray test to find position ahead of guar by looking ahead and slightly down
    local position = tes3.getPlayerEyePosition()
    local direction = tes3.getPlayerEyeVector()
    local hitResult = tes3.rayTest{
        position = position,
        direction = direction,
        ignore = { self.guar.reference },
        maxDistance = 10000
    }
    if hitResult then
        logger:debug("Ahead position (down): %s", hitResult.intersection)
        return hitResult.intersection
    end

    local aheadPosition = self.guar.reference.position:copy()
    local zOrientation = tes3.player.orientation.z
    aheadPosition = aheadPosition + tes3vector3.new(
        math.sin(zOrientation) * Rider.MOVE_DISTANCE,
        math.cos(zOrientation) * Rider.MOVE_DISTANCE,
        0
    )
    hitResult = tes3.rayTest{
        position = aheadPosition,
        direction = tes3vector3.new(0, 0, -1),
        ignore = { self.guar.reference },
        maxDistance = 10000
    }
    if hitResult then
        logger:debug("Ahead position (down): %s", hitResult.intersection)
        return hitResult.intersection
    end

    hitResult = tes3.rayTest{
        position = aheadPosition,
        direction = tes3vector3.new(0, 0, 1),
        ignore = { self.guar.reference },
        accurateSkinned = true,
    }
    if hitResult then
        logger:debug("Ahead position (up): %s", hitResult.intersection)
        return hitResult.intersection
    end

    logger:warn("Couldn't find ahead position")
end

---@param e { movingLeft: boolean, movingRight: boolean }?
function Rider:moveForward(e)
    e = e or {}

    local aheadPosition = self:getAheadPosition(e)
    if not aheadPosition then
        logger:debug("Couldn't find ahead position")
        return
    end

    logger:debug("Moving from position %s to %s", self.guar.reference.position, aheadPosition)
    self.guar.ai:collisionFix()
    self.guar.ai:moveTo(aheadPosition)
end

function Rider:turnLeft()
    self.guar.reference.orientation = self.guar.reference.orientation - tes3vector3.new(0, 0, Rider.ROTATE_SPEED)
    --tes3.player.orientation = tes3.player.orientation - tes3vector3.new(0, 0, Rider.ROTATE_SPEED)
end

function Rider:turnRight()
    self.guar.reference.orientation = self.guar.reference.orientation + tes3vector3.new(0, 0, Rider.ROTATE_SPEED)
    --tes3.player.orientation = tes3.player.orientation + tes3vector3.new(0, 0, Rider.ROTATE_SPEED)
end


function Rider:halt()
    self.guar.ai:follow()
end

---Set the guar to run based on the player's run controls
function Rider:updateIsRunning()
    self.guar.reference.mobile.isRunning = common.util.isRunningEnabled()
end

---Update the player position to be on the guar
function Rider:updatePlayerPosition()
    Rider.lockPlayer()
    --To prevent fall damage
    tes3.mobilePlayer.isFalling = false

    local attachNode = self.guar.reference.sceneNode:getObjectByName("ATTACH_PLAYER")
    -- tes3.player.position = attachNode.worldTransform.translation:copy()
    local guarZRot = self.guar.reference.orientation.z

    tes3.player.position = tes3vector3.new(
        self.guar.reference.position.x + math.sin(guarZRot) * 0,
        self.guar.reference.position.y + math.cos(guarZRot) * -0,
        (attachNode.worldTransform.translation.z + self.guar.reference.position.z + 100) / 2
    )
end



return Rider
