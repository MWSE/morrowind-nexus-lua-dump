---@meta

-- Dedicated LuaLS stub for require("openmw.interfaces").Camera.
-- Source: files/data/scripts/omw/camera/camera.lua
-- Runtime availability depends on script context, OpenMW version, and active content files.

-- OpenMW script contexts: player

---@class openmw.interfaces.Camera
---@field version number
local Camera = {}

---Interface version is 1
---@type number
Camera.version = nil

---Return the primary mode (MODE.FirstPerson or MODE.ThirdPerson).
---@return number openmw.camera.MODE
function Camera.getPrimaryMode() end

---Get the base third person distance (without applying angle and speed modifiers).
---@return number
function Camera.getBaseThirdPersonDistance() end

---Set the base third person distance
---@param value number
function Camera.setBaseThirdPersonDistance(value) end

---Get the desired third person distance if there would be no obstacles (with angle and speed modifiers)
---@return number
function Camera.getTargetThirdPersonDistance() end

---Whether the built-in mode control logic is enabled.
---@return boolean
function Camera.isModeControlEnabled() end

---Disable with (optional) tag until the corresponding enable function is called with the same tag.
---@param tag? string (optional, empty string by default) Will be disabled until the enabling function is called with the same tag
function Camera.disableModeControl(tag) end

---Undo disableModeControl
---@param tag? string (optional, empty string by default)
function Camera.enableModeControl(tag) end

---Whether the built-in standing preview logic is enabled.
---@return boolean
function Camera.isStandingPreviewEnabled() end

---Disable with (optional) tag until the corresponding enable function is called with the same tag.
---@param tag? string (optional, empty string by default) Will be disabled until the enabling function is called with the same tag
function Camera.disableStandingPreview(tag) end

---Undo disableStandingPreview
---@param tag? string (optional, empty string by default)
function Camera.enableStandingPreview(tag) end

---Whether head bobbing is enabled.
---@return boolean
function Camera.isHeadBobbingEnabled() end

---Disable with (optional) tag until the corresponding enable function is called with the same tag.
---@param tag? string (optional, empty string by default) Will be disabled until the enabling function is called with the same tag
function Camera.disableHeadBobbing(tag) end

---Undo disableHeadBobbing
---@param tag? string (optional, empty string by default)
function Camera.enableHeadBobbing(tag) end

---Whether the built-in zooming is enabled.
---@return boolean
function Camera.isZoomEnabled() end

---Disable with (optional) tag until the corresponding enable function is called with the same tag.
---@param tag? string (optional, empty string by default) Will be disabled until the enabling function is called with the same tag
function Camera.disableZoom(tag) end

---Undo disableZoom
---@param tag? string (optional, empty string by default)
function Camera.enableZoom(tag) end

---Whether the the third person offset can be changed by the built-in camera script.
---@return boolean
function Camera.isThirdPersonOffsetControlEnabled() end

---Disable with (optional) tag until the corresponding enable function is called with the same tag.
---@param tag? string (optional, empty string by default) Will be disabled until the enabling function is called with the same tag
function Camera.disableThirdPersonOffsetControl(tag) end

---Undo disableThirdPersonOffsetControl
---@param tag? string (optional, empty string by default)
function Camera.enableThirdPersonOffsetControl(tag) end

return Camera
