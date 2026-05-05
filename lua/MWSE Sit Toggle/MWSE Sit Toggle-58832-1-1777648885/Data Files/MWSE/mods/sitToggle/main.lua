local config = require("sitToggle.config")

------------------------------------------------------------
-- Mod Config
------------------------------------------------------------
local function registerModConfig()
    require("sitToggle.mcm")
end
event.register("modConfigReady", registerModConfig)

------------------------------------------------------------
-- State
------------------------------------------------------------
local isSitting = false
local wasThirdPerson = false

local originalCameraHeight = nil
local desiredCameraHeight = nil
local currentCameraHeight = nil

local isInterpolating = false
local transitionSpeed = 0.2 -- 0–1, higher = faster

------------------------------------------------------------
-- Sit Down
------------------------------------------------------------
local function sitDown()
    local mp = tes3.mobilePlayer
    if isSitting or not mp then
        return
    end

    wasThirdPerson = mp.is3rdPerson

    if config.forceThirdPerson and not wasThirdPerson then
        tes3.force3rdPerson()
    end

    isSitting = true
    lockRotation = true
    isInterpolating = true

    originalCameraHeight = mp.cameraHeight
    currentCameraHeight = originalCameraHeight
    desiredCameraHeight = originalCameraHeight - config.cameraOffset

    tes3.setPlayerControlState{
        enabled = true,
        attack = false,
        jumping = false,
    }

    local player = tes3.player
    tes3.loadAnimation({ reference = player, file = "VA_sitting.nif" })
    tes3.playAnimation({ reference = player, group = config.sitAnimationGroup })
end

------------------------------------------------------------
-- Stand Up
------------------------------------------------------------
local function standUp()
    if not isSitting then
        return
    end

    local mp = tes3.mobilePlayer
    if not mp then
        return
    end

    isSitting = false
    lockRotation = false

    currentCameraHeight = mp.cameraHeight
    desiredCameraHeight = originalCameraHeight
    isInterpolating = true

    if config.forceThirdPerson and not wasThirdPerson then
        tes3.force1stPerson()
    end

    tes3.setPlayerControlState{
        enabled = true,
        attack = true,
        jumping = true,
    }

    local player = tes3.player
    tes3.loadAnimation({ reference = player })
    tes3.playAnimation({ reference = player, group = tes3.animationGroup.idle1 })
end

------------------------------------------------------------
-- Keybind
------------------------------------------------------------
local function onKeyDown(e)
    if tes3.menuMode() then
        return
    end

    local key = config.sitKey.keyCode
    if type(key) == "table" then
        key = key.keyCode
    end

    if e.keyCode ~= key then
        return
    end

    if isSitting then
        standUp()
    else
        sitDown()
    end
end

event.register("loaded", function()
    event.register("keyDown", onKeyDown)
    if isSitting then
        standUp()
    end
end)

------------------------------------------------------------
-- Camera Interpolation
------------------------------------------------------------
local function updateCameraHeight()
    local mp = tes3.mobilePlayer
    if not mp then
        return
    end

    if not isSitting and not isInterpolating then
        return
    end

    if isInterpolating and desiredCameraHeight then
        currentCameraHeight = currentCameraHeight
            + (desiredCameraHeight - currentCameraHeight) * transitionSpeed

        if math.abs(desiredCameraHeight - currentCameraHeight) < 0.1 then
            currentCameraHeight = desiredCameraHeight
            isInterpolating = false
        end
    end

    if isSitting or isInterpolating then
        mp.cameraHeight = currentCameraHeight
    end
end

event.register("cameraControl", updateCameraHeight, { priority = -20000 })
