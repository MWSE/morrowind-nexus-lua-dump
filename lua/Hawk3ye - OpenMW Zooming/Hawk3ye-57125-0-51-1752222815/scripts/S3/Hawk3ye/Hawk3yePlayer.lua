local async = require 'openmw.async'
local camera = require 'openmw.camera'
local core = require 'openmw.core'
local input = require 'openmw.input'
local self = require 'openmw.self'
local storage = require 'openmw.storage'
local util = require 'openmw.util'

local I = require 'openmw.interfaces'

local MOD_NAME = "Hawk3ye"

local zoomActive = false

---@type number FOV defined in settings.cfg
local DefaultFOV = camera.getBaseFieldOfView()

---@type number Real FOV from RenderingManager
local currentFOV = camera.getFieldOfView()
local currentCameraMode

local settings = storage.playerSection("Settings" .. MOD_NAME)

local ToggleEventName = 'Hawk3yeToggle'
local ToggleSettingName = 'enabled'
local DurationSettingName = 'zoom_time'
local FOVSettingName = 'zoom_fov_degrees'

local ZoomDuration = settings:get(DurationSettingName)
local ZoomEnabled = settings:get(ToggleSettingName)
local ZoomFov = math.rad(
    settings:get(FOVSettingName)
)

local function updateFOVRange()
    I.Settings.updateRendererArgument('Settings' .. MOD_NAME, FOVSettingName, { max = (math.deg(DefaultFOV) - 1) })
end
updateFOVRange()

--- Used for determining what kind of state change occurred. This enum can also be re-used
--- When emitting your own Hawk3yeToggle events.
---@enum ZoomType
local ZoomState = {
    RESET = 1,
    DISABLE = 2,
    ENABLE = 3,
}

local ReadOnlyStates = util.makeReadOnly(ZoomState)

settings:subscribe(
    async:callback(
        function(_, key)
            if not key or key == FOVSettingName then
                ZoomFov = math.rad(
                    settings:get(FOVSettingName)
                )
            end

            if not key or key == DurationSettingName then
                ZoomDuration = settings:get(DurationSettingName)
            end

            if not key or key == ToggleSettingName then
                ZoomEnabled = settings:get(ToggleSettingName)
            end
        end
    )
)

input.registerTriggerHandler(
    MOD_NAME .. 'ToggleTrigger',
    async:callback(
        function()
            self:sendEvent(ToggleEventName, zoomActive and ZoomState.DISABLE or ZoomState.ENABLE)
        end
    )
)

input.registerActionHandler(
    MOD_NAME .. 'HoldAction',
    async:callback(
        function(pressed)
            self:sendEvent(ToggleEventName, pressed and ZoomState.ENABLE or ZoomState.DISABLE)
        end
    )
)

---@return boolean canZoom Whether or not the player is currently able to zoom in
local function canZoom()
    return ZoomEnabled and not I.UI.getMode() and not core.isWorldPaused()
end

local function updateZoom(dt)
    local targetFOV = zoomActive and ZoomFov or DefaultFOV

    if math.abs(currentFOV - targetFOV) > 0.001 then
        local smoothing = 5.0 / ZoomDuration

        currentFOV = currentFOV + (targetFOV - currentFOV) * (1.0 - math.exp(-smoothing * dt))

        camera.setFieldOfView(currentFOV)
    end
end

return {
    interfaceName = MOD_NAME,
    interface = {

        ---@return boolean isZoomed Whether or not the zoom action is currently engaged. It cannot be overridden
        isZoomed = function()
            return zoomActive
        end,

        CanZoom = canZoom,

        ZoomStates = ReadOnlyStates,
    },

    eventHandlers = {

        UiModeChanged = function(data)
            if data.newMode then
                self:sendEvent(ToggleEventName, ZoomState.RESET)
            elseif data.oldMode == I.UI.MODE.MainMenu then
                DefaultFOV = camera.getBaseFieldOfView()
            end
        end,

        ---@param zoomType ZoomType Whether or not to enage zoom
        Hawk3yeToggle = function(zoomType)
            zoomActive = zoomType == ZoomState.ENABLE

            if zoomActive then
                currentCameraMode = camera.getMode()

                if currentCameraMode ~= camera.MODE.FirstPerson then
                    camera.setMode(camera.MODE.FirstPerson)
                end
            else
                if currentCameraMode and currentCameraMode ~= camera.MODE.FirstPerson then
                    camera.setMode(currentCameraMode)
                    currentCameraMode = nil
                end

                if zoomType == ZoomState.RESET then
                    currentFOV = camera.getBaseFieldOfView()
                    DefaultFOV = currentFOV

                    camera.setFieldOfView(currentFOV)

                    updateFOVRange()
                end
            end
        end,
    },

    engineHandlers = {
        onFrame = function(dt)
            if not canZoom() then return end

            updateZoom(dt)
        end,

        onKeyPress = function(key)
            if key.symbol == input.KEY.Escape and zoomActive then
                self:sendEvent(ToggleEventName, ZoomState.DISABLE)
            end
        end
    }
}
