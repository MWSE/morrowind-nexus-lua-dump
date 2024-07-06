
local common = require("mer.fishing.common")
local logger = common.createLogger("LureCamera")


---@class Fishing.LureCamera.constructorParams
---@field positionLockTarget tes3reference The reference to lock the camera onto
---@field angleLockTarget tes3reference The reference to angle the camera towards
---@field offsetBack number The distance to keep the camera from the positionLockTarget
---@field offsetUp number The distance to keep the camera above the positionLockTarget
---@field allowUnderwater boolean? Whether to allow the camera to go underwater
---@field grounded boolean? Whether the fish crawls on the sea floor


-- Allows the camera to lock onto an object and follow it
-- And angle the camera towards a different target
---@class Fishing.LureCamera : Fishing.LureCamera.constructorParams
---@field positionLockTarget mwseSafeObjectHandle
---@field angleLockTarget mwseSafeObjectHandle
---@field wasInFirstPerson boolean
---@field previousMouseLookDisabled boolean
local LureCamera = {}


--- Creates a new instance of LureCamera.
---@param o Fishing.LureCamera.constructorParams? (optional) The optional table to use as the instance.
---@return Fishing.LureCamera The new LureCamera instance.
function LureCamera:new(o)
    if o then
        o.positionLockTarget = tes3.makeSafeObjectHandle(o.positionLockTarget)
        o.angleLockTarget = tes3.makeSafeObjectHandle(o.angleLockTarget)
    end
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

--- Sets the position lock target for the camera.
---@param target tes3reference The reference to lock the camera onto.
---@return Fishing.LureCamera The LureCamera instance.
function LureCamera:setPositionLockTarget(target)
    self.positionLockTarget = tes3.makeSafeObjectHandle(target)
    return self
end

--- Sets the angle lock target for the camera.
---@param target tes3reference The reference to angle the camera towards.
---@return Fishing.LureCamera The LureCamera instance.
function LureCamera:setAngleLockTarget(target)
    self.angleLockTarget = tes3.makeSafeObjectHandle(target)
    return self
end

--- Sets the offset back distance for the camera.
---@param offset number The distance to keep the camera from the positionLockTarget.
---@return Fishing.LureCamera The LureCamera instance.
function LureCamera:setOffsetBack(offset)
    self.offsetBack = offset
    return self
end

--- Sets the offset up distance for the camera.
---@param offset number The distance to keep the camera above the positionLockTarget.
---@return Fishing.LureCamera The LureCamera instance.
function LureCamera:setOffsetUp(offset)
    self.offsetUp = offset
    return self
end

function LureCamera:start()
    self.previousMouseLookDisabled = tes3.player.mobile.mouseLookDisabled
    tes3.player.mobile.mouseLookDisabled = true
    --set to 3rd person
    self.wasInFirstPerson = tes3.force3rdPerson()

    local positionLockTarget = self.positionLockTarget:getObject()
    if not positionLockTarget then
        logger:error("Position lock target is not valid")
        return
    end
    logger:debug("Starting LureCamera")

    local function updateCameraControl(e)
        if not tes3.player.data.fishingLureCameraActive then
            event.unregister("cameraControl", updateCameraControl)
        end
        self:updateCamera(e)
    end
    tes3.player.data.fishingLureCameraActive = true
    event.register("cameraControl", updateCameraControl)
    event.register("load", function()
        self:stop()
    end)

end

function LureCamera:stop(e)
    e = e or {}
    tes3.player.mobile.mouseLookDisabled = self.previousMouseLookDisabled
    if e.returnToFirstPersion == nil then e.returnToFirstPersion = true end
    logger:debug("Stopping LureCamera")
    tes3.player.data.fishingLureCameraActive = false
end

function LureCamera.isActive()
    return tes3.player.data.fishingLureCameraActive
end

---@param e cameraControlEventData
function LureCamera:updateCamera(e)
    logger:debug("Updating Camera")
    local angleLockTargetObject = self.angleLockTarget:getObject()
    if not angleLockTargetObject then
        logger:error("Angle lock target is not valid")
        self:stop()
        return
    end
    local positionLockTargetObject = self.positionLockTarget:getObject()
    if not positionLockTargetObject then
        logger:error("Position lock target is not valid")
        self:stop()
        return
    end

    local angleTargetPos = angleLockTargetObject.position
    local targetPos = positionLockTargetObject.position
    local cameraPos = positionLockTargetObject.position

    -- Calculate direction vector from camera to target
    local direction = angleTargetPos - cameraPos
    local normalizedDirection = direction:normalized()

    -- Step 3: Calculate new position for camera
    local back = normalizedDirection * self.offsetBack
    local newPos = targetPos - back

    local waterHeight = positionLockTargetObject.cell.waterLevel or 0
    if not self.allowUnderwater then
        newPos.z = waterHeight + self.offsetUp
    elseif self.grounded then
        newPos.z = positionLockTargetObject.position.z + self.offsetUp
    else
        newPos.z = positionLockTargetObject.position.z - self.offsetUp
    end

    e.cameraTransform.translation = newPos

    -- Step 4: Calculate new rotation for camera
    -- Point the camera towards the angle lock target
    local lookAt = angleTargetPos - newPos
    local lookAtNormalized = lookAt:normalized()
    local lookatMatrix = tes3matrix33.new()
    lookatMatrix:lookAt(lookAtNormalized, tes3vector3.new(0, 0, 1))

    e.cameraTransform.rotation = lookatMatrix

end

return LureCamera