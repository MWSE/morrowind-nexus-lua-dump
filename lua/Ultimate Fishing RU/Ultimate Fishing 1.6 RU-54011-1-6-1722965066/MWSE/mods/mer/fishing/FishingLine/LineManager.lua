local common = require("mer.fishing.common")
local logger = common.createLogger("LineManager")
local config = require("mer.fishing.config")
local FishingLine = require("mer.fishing.FishingLine.FishingLine")
local FishingStateManager = require("mer.fishing.Fishing.FishingStateManager")
local LureCamera= require("mer.fishing.Camera.LureCamera")
local FishingRod = require("mer.fishing.FishingRod.FishingRod")

---@class Fishing.LineManager
local LineManager = {
    ---@type niNode
    lureAttachPoint = nil
}

function LineManager.setLureAttachPoint(lureAttachPoint)
    LineManager.lureAttachPoint = lureAttachPoint
end

---@param lineEnd niNode
---@return tes3vector3?
local function getFixedAttachPos(lineEnd)
    if not tes3.player.mobile.is3rdPerson then
        logger:debug("Player is not in 3rd person, returning worldTransform")
        return lineEnd.worldTransform.translation
    end

    local sceneNode = tes3.player.sceneNode
    if not sceneNode then
        logger:error("Could not find player scene node")
        return
    end
    local weaponBone = sceneNode:getObjectByName("Weapon Bone")
    if not weaponBone then
        logger:error("Could not find Weapon Bone node on player")
        return
    end

    local armature = weaponBone:getObjectByName("FISHING_ROD_ARMATURE")
    if not armature then
        logger:error("Could not find FISHING_ROD_ARMATURE node on Weapon Bone")
        return
    end

    local skeletonRootTf = armature.worldTransform
    local lineEndTf = lineEnd.worldTransform

    -- Skinning assumes uniform scaling, so it uses a cheap transpose instead of a full matrix inverse.
    -- We need to work around this to get the skinned world position of the line attach point.
    local badRot = skeletonRootTf.rotation:transpose()
    local badTr = badRot * skeletonRootTf.translation * -1
    local worldAttachPos = skeletonRootTf * (badRot * lineEndTf.translation + badTr)

    return worldAttachPos
end


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
        event.unregister(tes3.event.simulated, updateFishingLine)
        FishingRod.updateRodBend(config.constants.TENSION_LINE_ROD_TRANSITION)
        fishingLine:remove()
        FishingStateManager.endFishing()
    end

    LineManager.lureAttachPoint = lure.sceneNode:getObjectByName("AttachAnimLure")
    if not LineManager.lureAttachPoint then
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

        local tension = FishingStateManager.getTension()
        FishingRod.updateRodBend(tension)

        -- Get the appropriate 1st/3rd person pole position.
        LineManager.lureAttachPoint:update()
        local lurePosition = LineManager.lureAttachPoint.worldTransform.translation

        -- Get the appropriate 1st/3rd person pole position.
        local attachFishingLine = tes3.is3rdPerson() and attachFishingLine3rd or attachFishingLine1st
        local attachPosition = getFixedAttachPos(attachFishingLine)
        if not attachPosition then
            logger:error("Could not get attach position")
            cancel()
            return
        end

        if lurePosition:distance(attachPosition) > config.constants.FISHING_LINE_MAX_DISTANCE then
            logger:debug("Player is too far away, stopping fishing line")
            cancel()
            return
        end

        -- Ensure the fishing line is attached to the lure.
        local lineAttachNode = LineManager.lureAttachPoint
        if fishingLine.sceneNode.parent ~= lineAttachNode then
            fishingLine:attachTo(lineAttachNode)
        end

        if FishingStateManager.isState("WAITING") then
            if not landed then
                logger:debug("Lure has landed, transitioning tension")
                FishingStateManager.lerpTension(config.constants.TENSION_MINIMUM, 0.75)
                landed = true
                return
            end
        end

        fishingLine:updateEndPoints(attachPosition, lurePosition)
    end
    event.register(tes3.event.simulated, updateFishingLine, { priority = -9000 })

    return fishingLine
end

return LineManager