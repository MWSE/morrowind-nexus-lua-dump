local camera = require 'openmw.camera'
local gameSelf = require 'openmw.self'
local util = require 'openmw.util'

local ModInfo = require 'Scripts.SW4.modinfo'

local I = require 'openmw.interfaces'

---@type ManagementStore
local GlobalManagement

---@class CameraManager:ProtectedTable
---@field NoThirdPerson boolean
---@field PitchLocked boolean
---@field CursorCamPitch number configured pitch lock
local CameraManager = I.StarwindVersion4ProtectedTable.new {
    inputGroupName = 'SettingsGlobal' .. ModInfo.name .. 'MoveTurnGroup',
    modName = ModInfo.name,
    logPrefix = ModInfo.logPrefix
}

---@class CameraManagerState
---@field yawDelta number yaw change between current and last frame
---@field yawThisFrame number
---@field yawLastFrame number
---@field pitchDelta number yaw change between current and last frame
---@field pitchThisFrame number
---@field pitchLastFrame number
---@field isWielding boolean whether or not the player has a weapon or spell drawn
CameraManager.state = {
    yawDelta = 0,
    yawThisFrame = 0,
    yawLastFrame = 0,

    pitchDelta = 0,
    pitchThisFrame = 0,
    pitchLastFrame = 0,

    isWielding = false,
    canDoLockOn = false,
}

function CameraManager:updateTransform()
    self.state.yawThisFrame = camera.getYaw()
    self.state.pitchThisFrame = camera.getPitch()
    self.state.isWielding = gameSelf.type.getStance(gameSelf) ~= gameSelf.type.STANCE.Nothing
end

function CameraManager:isWielding()
    return self.state.isWielding
end

function CameraManager.isMoving()
    return gameSelf.controls.sideMovement ~= 0 or gameSelf.controls.movement ~= 0
end

function CameraManager.isThirdPerson()
    return camera.getMode() ~= camera.MODE.FirstPerson
end

--- Override yawChange from mouseInput
---@param dt number deltaTime
function CameraManager:onFrameBegin(dt)
    CameraManager:updateTransform()

    if camera.getMode() == camera.MODE.Preview then
        camera.setMode(camera.MODE.ThirdPerson)
    end

    if GlobalManagement.LockOn.getMarkerVisibility() or GlobalManagement.Cursor:getCursorVisible() then
        gameSelf.controls.pitchChange = 0
    end
end

--- Tracks yaw and pitch change between frames
function CameraManager:updateDelta()
    if self.state.yawThisFrame ~= 0 then
        self.state.yawDelta = self.state.yawThisFrame - self.state.yawLastFrame
    end

    if self.state.pitchThisFrame ~= 0 then
        self.state.pitchDelta = self.state.pitchThisFrame - self.state.pitchLastFrame
    end
end

function CameraManager:trackTargetUsingViewport(targetObject, normalizedPos)
    if not targetObject then return end

    -- Desired screen position (center of the screen)
    local desiredScreenPos = util.vector2(0.5, 0.5)

    -- Convert the current and desired screen positions to world-space directions
    local currentWorldDir = camera.viewportToWorldVector(normalizedPos.xy)
    local desiredWorldDir = camera.viewportToWorldVector(desiredScreenPos)

    -- Normalize the directions
    currentWorldDir = currentWorldDir:normalize()
    desiredWorldDir = desiredWorldDir:normalize()

    -- Calculate the yaw and pitch differences
    local yawDifference = math.atan2(currentWorldDir.x, currentWorldDir.y) -
        math.atan2(desiredWorldDir.x, desiredWorldDir.y)

    local pitchDifference = math.asin(currentWorldDir.z) - math.asin(desiredWorldDir.z)

    camera.setYaw(util.normalizeAngle(camera.getYaw() + yawDifference))
    camera.setPitch(util.normalizeAngle(camera.getPitch() - pitchDifference))

    gameSelf.controls.yawChange = yawDifference
    gameSelf.controls.pitchChange = -pitchDifference

    return yawDifference, pitchDifference
end

--- Add settings for forcing third person and locking pitch
--- Figure out how to handle perspective out of combat
---@param dt number deltaTime
---@param Managers ManagementStore
function CameraManager:onFrameEnd(dt, Managers)
    CameraManager:updateDelta()

    if self.NoThirdPerson and camera.getMode() == camera.MODE.FirstPerson then
        camera.setMode(camera.MODE.ThirdPerson)
    end

    local targetPitch
    if Managers.Cursor:getCursorVisible() then
        targetPitch = math.rad(self.CursorCamPitch)
    elseif self.PitchLocked and not self.state.isWielding then
        targetPitch = 0
    end

    if targetPitch then
        camera.setPitch(targetPitch)
    end

    self.state.yawLastFrame = self.state.yawThisFrame
    self.state.pitchLastFrame = self.state.pitchThisFrame
end

---@param managementStore ManagementStore
---@return CameraManager
return function(managementStore)
    assert(managementStore)
    GlobalManagement = managementStore

    return CameraManager
end
