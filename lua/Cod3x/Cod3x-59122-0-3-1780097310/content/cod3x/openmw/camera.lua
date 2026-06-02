---@meta

-- This file was mechanically drafted from files/lua_api/openmw/camera.lua.
-- It uses LuaLS/LLS annotations and stub bodies only; runtime behavior is provided by OpenMW.
-- OpenMW script contexts: player

---Controls camera.
---@class openmw.camera
local camera = {}

---Camera mode; see openmw.camera.MODE for possible values
---@class openmw.camera.Mode
local Mode = {}

---@class openmw.camera.MODE Camera modes.
---@field Static openmw.camera.Mode Camera doesn't track player; player inputs doesn't affect camera; use `setStaticPosition` to move the camera.
---@field FirstPerson openmw.camera.Mode First person mode.
---@field ThirdPerson openmw.camera.Mode Third person mode; player character turns to the view direction.
---@field Vanity openmw.camera.Mode Similar to Preview; camera slowly moves around the player.
---@field Preview openmw.camera.Mode Third person mode, but player character doesn't turn to the view direction.
local MODE = {}

---Camera modes.
---@type openmw.camera.MODE
camera.MODE = nil

---Return the current openmw.camera.MODE.
---@return openmw.camera.Mode
function camera.getMode() end

---Return the mode the camera will switch to after the end of the current animation. Can be nil.
---@return openmw.camera.Mode
function camera.getQueuedMode() end

---Change openmw.camera.MODE; if the second (optional, true by default) argument is set to false, the switching can be delayed (see `getQueuedMode`).
---@param mode openmw.camera.Mode
---@param force boolean
function camera.setMode(mode, force) end

---If set to true then after switching from Preview to ThirdPerson the player character turns to the camera view direction. Otherwise, the camera turns to the character view direction.
---@param boolValue boolean
function camera.allowCharacterDeferredRotation(boolValue) end

---Show/hide the crosshair.
---@param boolValue boolean
function camera.showCrosshair(boolValue) end

---Current position of the tracked object (the characters head if there is no animation).
---@return openmw.util.Vector3
function camera.getTrackedPosition() end

---Current position of the camera.
---@return openmw.util.Vector3
function camera.getPosition() end

---Camera pitch angle (radians) without taking extraPitch into account.
---Full pitch is `getPitch()+getExtraPitch()`.
---@return number
function camera.getPitch() end

---Force the pitch angle to the given value (radians); player input on this axis is ignored in this frame.
---@param value number
function camera.setPitch(value) end

---Camera yaw angle (radians) without taking extraYaw into account.
---Full yaw is `getYaw()+getExtraYaw()`.
---@return number
function camera.getYaw() end

---Force the yaw angle to the given value (radians); player input on this axis is ignored in this frame.
---@param value number
function camera.setYaw(value) end

---Get the camera roll angle (radians).
---@return number
function camera.getRoll() end

---Set the camera roll angle (radians).
---@param value number
function camera.setRoll(value) end

---Additional summand for the pitch angle that is not affected by player input.
---Full pitch is `getPitch()+getExtraPitch()`.
---@return number
function camera.getExtraPitch() end

---Additional summand for the pitch angle; useful for camera shaking effects.
---Setting extra pitch doesn't block player input.
---Full pitch is `getPitch()+getExtraPitch()`.
---@param value number
function camera.setExtraPitch(value) end

---Additional summand for the yaw angle that is not affected by player input.
---Full yaw is `getYaw()+getExtraYaw()`.
---@return number
function camera.getExtraYaw() end

---Additional summand for the yaw angle; useful for camera shaking effects.
---Full yaw is `getYaw()+getExtraYaw()`.
---@param value number
function camera.setExtraYaw(value) end

---Additional summand for the roll angle that is not affected by player input.
---Full yaw is `getRoll()+getExtraRoll()`.
---@return number
function camera.getExtraRoll() end

---Additional summand for the roll angle; useful for camera shaking effects.
---Full roll is `getRoll()+getExtraRoll()`.
---@param value number
function camera.setExtraRoll(value) end

---Applies an offset to the cameras projection matrix, measured in pixels.
---Small offsets of up to roughly 2 pixels are safe, large offsets are only for debugging and will cause visual glitches.
---@param offset openmw.util.Vector2
function camera.setProjectionOffset(offset) end

---The offset applied to the cameras projection matrix, in pixels.
---@return openmw.util.Vector2
function camera.getProjectionOffset() end

---Set the camera position; can be used only if camera is in Static mode.
---@param pos openmw.util.Vector3
function camera.setStaticPosition(pos) end

---The offset between the characters head and the camera in first person mode (3d vector).
---@return openmw.util.Vector3
function camera.getFirstPersonOffset() end

---Set the offset between the characters head and the camera in first person mode (3d vector).
---@param offset openmw.util.Vector3
function camera.setFirstPersonOffset(offset) end

---Preferred offset between the tracked position (see `getTrackedPosition`) and the camera focal point (the center of the screen) in third person mode.
---See `setFocalPreferredOffset`.
---@return openmw.util.Vector2
function camera.getFocalPreferredOffset() end

---Set the preferred offset between the tracked position (see `getTrackedPosition`) and the camera focal point (the center of the screen) in third person mode.
---The offset is a 2d vector (X, Y) where X is horizontal (to the right from the character) and Y component is vertical (upward).
---The real offset can differ from the preferred one during smooth transition or if blocked by an obstacle.
---Smooth transition happens by default every time the preferred offset changes. Use `instantTransition()` to skip the current transition.
---@param offset openmw.util.Vector2
function camera.setFocalPreferredOffset(offset) end

---The actual distance between the camera and the character in third person mode; can differ from the preferred one if there is an obstacle.
---@return number
function camera.getThirdPersonDistance() end

---Set preferred distance between the camera and the character in third person mode.
---@param distance number
function camera.setPreferredThirdPersonDistance(distance) end

---The current speed coefficient of focal point (the center of the screen in third person mode) smooth transition.
---@return number
function camera.getFocalTransitionSpeed() end

---Set the speed coefficient of focal point (the center of the screen in third person mode) smooth transition.
---Smooth transition happens by default every time the preferred offset changes. Use `instantTransition()` to skip the current transition.
---Set the speed coefficient
---@param speed number
function camera.setFocalTransitionSpeed(speed) end

---Make instant the current transition of camera focal point and the current deferred rotation (see `allowCharacterDeferredRotation`).
function camera.instantTransition() end

---Get the current camera collision type (see openmw.nearby.COLLISION_TYPE).
---@return number
function camera.getCollisionType() end

---Set the camera collision type (see openmw.nearby.COLLISION_TYPE).
---@param collisionType number
function camera.setCollisionType(collisionType) end

---Return the base field of view vertical angle in radians
---@return number
function camera.getBaseFieldOfView() end

---Return the current field of view vertical angle in radians
---@return number
function camera.getFieldOfView() end

---Set the field of view
---@param fov number Field of view vertical angle in radians
function camera.setFieldOfView(fov) end

---Return the base view distance.
---@return number
function camera.getBaseViewDistance() end

---Return the current view distance.
---@return number
function camera.getViewDistance() end

---Takes effect on the next frame.
---@param distance number View distance in game units
function camera.setViewDistance(distance) end

---Get the world to local transform for the camera.
---@return openmw.util.Transform
function camera.getViewTransform() end

---Get a vector from the camera to the world for the given point in the viewport.
---(0, 0) is the top left corner of the screen.
---@param normalizedScreenPos openmw.util.Vector2
---@return openmw.util.Vector3
function camera.viewportToWorldVector(normalizedScreenPos) end

---Get a vector from the world to the viewport for the given point in the world space.
---(0, 0) is the top left corner of the screen.
---The z component of the return value holds the distance from the camera to the position, in world space
---@param worldPos openmw.util.Vector3
---@return openmw.util.Vector3
function camera.worldToViewportVector(worldPos) end

return camera
