local common = require("mer.fishing.common")
local logger = common.createLogger("LineManager")
local config = require("mer.fishing.config")
local FishingLine = require("mer.fishing.FishingLine.FishingLine")
local FishingStateManager = require("mer.fishing.Fishing.FishingStateManager")

---@class Fishing.LineManager
local LineManager = {}

function LineManager.attachLines(lure)
    logger:debug("Spawning fishing line")
    local attachFishingLine1st = tes3.player1stPerson.sceneNode:getObjectByName("AttachFishingLine") --[[@as niNode]]
    local attachFishingLine3rd = tes3.player.sceneNode:getObjectByName("AttachFishingLine") --[[@as niNode]]
    if not attachFishingLine1st then
        logger:error("Could not find AttachFishingLine node on player 1st person")
        return
    end
    if not attachFishingLine3rd then
        logger:error("Could not find AttachFishingLine node on player 3rd person")
        return
    end

    local fishingLine = FishingLine.new()

    local updateFishingLine
    local lureSafeRef = tes3.makeSafeObjectHandle(lure)
    if lureSafeRef == nil then
        logger:error("Could not find lure reference")
        return
    end

    local function cancel()
        logger:debug("Cancelling fishing line")
        event.unregister("cameraControl", updateFishingLine)
        fishingLine:remove()
        FishingStateManager.endFishing()
    end

    local lureAttachPoint = lure.sceneNode:getObjectByName("AttachAnimLure") --[[@as niNode]]
    if not lureAttachPoint then
        logger:error("Could not find AttachAnimLure node on lure")
        cancel()
        return
    end

    local landed = false

    updateFishingLine = function()
        if FishingStateManager.isState("IDLE") then
            logger:debug("Player is idle, stopping fishing line")
            cancel()
            return
        end
        if not lureSafeRef:valid() then
            logger:debug("Lure is not valid, stopping fishing line")
            cancel()
            return
        end

        -- Get the appropriate 1st/3rd person pole position.
        lureAttachPoint:update({ controllers = true })
        local lurePosition = lureAttachPoint.worldTransform.translation

        -- Get the appropriate 1st/3rd person pole position.
        local attachFishingLine = tes3.is3rdPerson() and attachFishingLine3rd or attachFishingLine1st
        attachFishingLine:update({ controllers = true })
        local attachPosition = attachFishingLine.worldTransform.translation

        if lurePosition:distance(attachPosition) > config.constants.FISHING_LINE_MAX_DISTANCE then
            logger:debug("Player is too far away, stopping fishing line")
            cancel()
            return
        end

        -- Ensure the fishing line is attached to the lure.
        if fishingLine.sceneNode.parent ~= lureAttachPoint then
            fishingLine:attachTo(lureAttachPoint)
        end

        if FishingStateManager.isState("WAITING") then
            if not landed then
                logger:debug("Lure has landed, transitioning tension")
                fishingLine:lerpTension(0.3, 0.75)
                landed = true
                return
            end
        end

        -- Update the fishing line.
        fishingLine:updateEndPoints(attachPosition, lurePosition)
    end
    event.register("cameraControl", updateFishingLine, { priority = -9000 })
    return fishingLine
end

return LineManager