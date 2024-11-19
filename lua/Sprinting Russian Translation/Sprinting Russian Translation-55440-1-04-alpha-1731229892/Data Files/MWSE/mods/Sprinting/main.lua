local config = require("Sprinting.config").config

-- Variable Definitions --

local data
local activeFatigueDrawback = 0
local activeSpeedMultiplier = 1.0
local predefinedEffects

local runtimeStatus = {
    isModEnabled = false,
    keyCodes = {
        sprint = nil,
        forward = nil,
        back = nil,
        left = nil,
        right = nil,
        autoRun = nil
    },
    recovery = {
        minimumRecoveryDuration = nil
    },
    zooming = {
        isEnabled = false,
        isActive = false,
        activeSimulation = {
            callback = nil,
            priority = 0
        }
    }
}

-- Function Definitions --

local disableZooming
local enableZooming

local setZoom
local zoomIn
local zoomOut

local updateActiveZoomingEffect
local applyActiveZoomingEffect

local startRecoveryTimer

local startSprinting
local pauseSprinting
local stopSprinting
local applySprinting
local isSprintingPauseRequired

local updateKeyCodes
local registerKeyState
local disableSprintingKey
local updateSprintingKey

local disableSprinting
local enableSprinting
local updateConfiguration
local updateConfigurationOnMenuExit
local enableFourDirectionalMovement

local resetData
local saveData
local loadData

local onInitialized
local onSave
local onLoaded

-- Zooming --

function disableZooming()
    if runtimeStatus.zooming.isActive then

        runtimeStatus.zooming.activeSimulation = {
            callback = nil,
            priority = 0
        }
        event.unregister(tes3.event.simulate, applyActiveZoomingEffect)
        mge.setZoom(config.defaultZoomAmount)

        runtimeStatus.zooming.isActive = false
    end
end

function enableZooming()
    --[[
        Warning: There is no way to know if another mod relies in MGE's zoom functionality. That's
        why we may disable this setting only during initialization.
    ]]--
    if not runtimeStatus.zooming.isEnabled then
        mge.enableZoom()

        runtimeStatus.zooming.isEnabled = true
    end

    if not runtimeStatus.zooming.isActive then
        event.register(tes3.event.simulate, applyActiveZoomingEffect)

        runtimeStatus.zooming.isActive = true
    end
end

function setZoom(target)
    if mge.getZoom() ~= target then
        mge.setZoom{amount = target}
    end

    return false
end

function zoomIn(target, speed)
    local current = mge.getZoom()

    if current < target then

        --[[
            Warning: setZoom and zoomIn require named arguments.
        ]]--
        if current + speed > target then
            mge.setZoom{amount = target}
        else
            mge.zoomIn{amount = speed}

            return true
        end

    end

    return false
end

function zoomOut(target, speed)
    local current = mge.getZoom()

    if current > target then
        
        --[[
            Warning: setZoom and zoomOut require named arguments.
        ]]--
        if current - speed < target then
            mge.setZoom{amount = target}
        else
            mge.zoomOut{amount = speed}

            return true
        end

    end

    return false
end

function updateActiveZoomingEffect(e)
    local zooming = runtimeStatus.zooming

    if not zooming.activeSimulation.callback or e.priority >= zooming.activeSimulation.priority then
        zooming.activeSimulation = {
            callback = e.callback,
            priority = e.priority
        }
    end
end

function applyActiveZoomingEffect()
    local zooming = runtimeStatus.zooming
    local action = zooming.activeSimulation.callback

    if action then
        if not action() then
            zooming.activeSimulation = {
                callback = nil,
                priority = 0
            }
        end
    end

end

predefinedEffects = {
    zoomReset = function()
            return setZoom(config.defaultZoomAmount)
        end,
    zoomIn = function()
            return zoomIn(config.sprintingZoomMaxAmount, config.sprintingZoomSpeed)
        end,
    zoomOut = function()
            return zoomOut(config.defaultZoomAmount, config.sprintingZoomSpeed)
        end
}

-- Recovery --

function startRecoveryTimer(timeLeft)
    local duration = math.min(runtimeStatus.recovery.minimumRecoveryDuration, timeLeft)

    if duration > 0 then
        data.recoveryTimer = timer.start{
            duration = duration,
            --[[
                Info: A dummy function. We only need to check if the timer is expired or
                 not; which we can check by whether the timer exists.
            ]]--
            callback = function() end
        }

        data.isRecovering = true
    else
        data.recoveryTimer = {
            state = timer.expired
        }
    end

end

-- Sprinting --

function startSprinting()
    if tes3.mobilePlayer and not tes3.menuMode() then

        if data.isRecovering then
            if data.recoveryTimer.state == timer.expired and tes3.mobilePlayer.fatigue.normalized >= config.minimumRecoveryFatiguePercentage then
                data.isRecovering = false
            end
        end

        if not data.isRecovering then
            activeFatigueDrawback = math.max(
                config.fatigueDrawbackMaxAmount - tes3.mobilePlayer.athletics.current * config.fatigueDrawbackAthleticsModifier,
                config.fatigueDrawbackMinAmount)

            --[[
                Info: There are multiple logical places to reset the speed multiplier, but the
                safest choice is to probably reset it just before start sprinting.
            ]]--
            activeSpeedMultiplier = 1.0

            data.isSprinting = true

        elseif config.enableRecoveryNotifications then
            tes3.messageBox("Вам нужно перевести дух.")
        end
        
    end
end

--[[
    Note: The functions pauseSprinting and stopSprinting are verys similar. The reason we duplicate
    some of the code in them is to allow for the possibility of using different zooming effects for
    each of them if we so desire. However, by default both of them use the same zoom out effect.
]]--
function pauseSprinting(e)
    if tes3.mobilePlayer and not tes3.menuMode() then

        if e and e.keyCode then
            if tes3.mobilePlayer.autoRun then
                --[[
                    Info: It seems that the way auto-running works in Morrowind is by hammering the
                    forward button. As a result the keyUp event for the forward keybind is triggered
                    out-of-place if auto running is active.
                ]]--
                if e.keyCode == runtimeStatus.keyCodes.forward then
                    return
                end
            --[[
                Info: We also need to pause the sprinting when the auto-move keybind is pressed, but
                only if auto-running is currently active.
            ]]--
            elseif e.keyCode == runtimeStatus.keyCodes.autoRun then
                return
            end

        end

        if runtimeStatus.zooming.isActive then
            updateActiveZoomingEffect{
                callback = predefinedEffects.zoomOut,
                priority = 0
            }
        end

        data.isZooming = false

    end
end

function stopSprinting()
    if tes3.mobilePlayer and not tes3.menuMode() then

        data.isSprinting = false

        if runtimeStatus.zooming.isActive then
            updateActiveZoomingEffect{
                callback = predefinedEffects.zoomOut,
                priority = 0
            }
        end

        data.isZooming = false

    end
end

function applySprinting(e)
    if e.mobile == tes3.mobilePlayer then

        if data.isSprinting and not data.isRecovering then

            -- Pause --

            if isSprintingPauseRequired() then

                if data.isZooming then
                    pauseSprinting()
                end

                return
            end
            
            -- Activate Recovery --

            local isFainting = (activeFatigueDrawback > e.mobile.fatigue.current)

            if isFainting then
                resetData(true)

                startRecoveryTimer(runtimeStatus.recovery.minimumRecoveryDuration)
            end

            -- Zooming --

            if not data.isZooming and runtimeStatus.zooming.isActive and not isFainting then
                
                updateActiveZoomingEffect{
                    callback = predefinedEffects.zoomIn,
                    priority = 0
                }

                data.isZooming = true
            end

            -- Sprinting --

            if config.fatigueDrawbackAllowFainting or not isFainting then

                activeSpeedMultiplier = math.min(
                    activeSpeedMultiplier + config.speedMultiplierIncrement,
                    config.speedMultiplierMaxAmount)

                e.speed = e.speed * activeSpeedMultiplier
                e.mobile.fatigue.current = e.mobile.fatigue.current - activeFatigueDrawback

            end
        end

    end
end

function isSprintingPauseRequired()

    if not config.enableMultiDirectionalMovement then
        for  _, keyBind in ipairs{"back", "left", "right"} do
            if data.inputState[runtimeStatus.keyCodes[keyBind]] then
                return true
            end
        end
    end

    return false
end

-- Configuration --

function updateKeyCodes()
    local runtimeKeyCodes = runtimeStatus.keyCodes

    --[[
        Info: Realeasing the forward button results in a zoom out effect without stoping sprinting,
        i.e., by pressing the forward button again the player can continue to sprint.
    ]]--
    local forwardKeyCode = tes3.getInputBinding(tes3.keybind.forward).code

    if runtimeKeyCodes.forward ~= forwardKeyCode then

        if runtimeKeyCodes.forward then
            event.unregister(tes3.event.keyUp, pauseSprinting, { filter = runtimeKeyCodes.forward })
        end
        event.register(tes3.event.keyUp, pauseSprinting, { filter = forwardKeyCode })

        runtimeKeyCodes.forward = forwardKeyCode
    end

    --[[
        Info: Pressing the auto-run button while running also results in a zoom out effect without
        stoping sprinting as above.
    ]]--
    local autoRunKeyCode = tes3.getInputBinding(tes3.keybind.autoRun).code

    if runtimeKeyCodes.autoRun ~= autoRunKeyCode then

        if runtimeKeyCodes.autoRun then
            event.unregister(tes3.event.keyDown, pauseSprinting, { filter = runtimeKeyCodes.autoRun })
        end
        event.register(tes3.event.keyDown, pauseSprinting, { filter = autoRunKeyCode })

        runtimeKeyCodes.autoRun = autoRunKeyCode
    end

    --[[
        Info: If enabled in the MCM, pressing any other directional button, rather than the forward
        button, results in stopping the sprint.
    ]]--
    if not config.enableMultiDirectionalMovement then
        for  _, keyBind in ipairs{"back", "left", "right"} do
            keyCode = tes3.getInputBinding(tes3.keybind[keyBind]).code

            if runtimeKeyCodes[keyBind] ~= keyCode then

                if runtimeKeyCodes[keyBind] then
                    event.unregister(tes3.event.key, registerKeyState, { filter = runtimeKeyCodes[keyBind] })

                    if data then
                        data.inputState[runtimeKeyCodes[keyBind]] = nil
                    end
                end
                event.register(tes3.event.key, registerKeyState, { filter = keyCode })

                if data then
                    data.inputState[keyCode] = tes3.worldController.inputController:isKeyDown(keyCode)
                end

                runtimeKeyCodes[keyBind] = keyCode
            end
        end
    end

    

end

function registerKeyState(e)
    if data and not tes3.menuMode() then
        data.inputState[e.keyCode] = e.pressed
    end
end

function disableSprintingKey()
    local currentKeyCode = runtimeStatus.keyCodes.sprint

    if currentKeyCode then
        event.unregister(tes3.event.keyDown, startSprinting, { filter = currentKeyCode })
        event.unregister(tes3.event.keyUp, stopSprinting, { filter = currentKeyCode })
    end

    runtimeStatus.keyCodes.sprint = nil
end

function updateSprintingKey()
    local currentKeyCode = runtimeStatus.keyCodes.sprint

    if currentKeyCode ~= config.keySprinting.keyCode then

        disableSprintingKey()

        currentKeyCode = config.keySprinting.keyCode
        event.register(tes3.event.keyDown, startSprinting, { filter = currentKeyCode })
        event.register(tes3.event.keyUp, stopSprinting, { filter = currentKeyCode })

        runtimeStatus.keyCodes.sprint = currentKeyCode
    end
end

function enableFourDirectionalMovement()
    local runtimeKeyCodes = runtimeStatus.keyCodes

    for _, keyBind in ipairs{"back", "left", "right"} do
        if runtimeKeyCodes[keyBind] then
            event.unregister(tes3.event.key, registerKeyState, { filter = runtimeKeyCodes[keyBind] })
        end

        if data then
            data.inputState[runtimeKeyCodes[keyBind]] = nil
        end

        runtimeKeyCodes[keyBind] = nil
    end

end

function updateConfiguration()
    local requiresPersistedDataReset = false

    -- Enable/Disable Mod --

    if config.enableMod ~= runtimeStatus.isModEnabled then

        if config.enableMod then
            enableSprinting()
        else
            disableSprinting()

            requiresPersistedDataReset = true
        end

    --[[
        Info: We only need to update the following features if the mod is enabled and its status
        wasn't just updated. In the later the status of these features has already been updated.
    ]]--
    elseif config.enableMod then

        if runtimeStatus.zooming.isActive ~= config.enableSprintingZoom then
            if config.enableSprintingZoom then
                enableZooming()
            else
                disableZooming()
            end
        end

        --[[
            Info: It's sufficient to check for the existence of one of the keyBinds since all of
            them are always get updated together.
        ]]--
        if runtimeStatus.keyCodes.back then
            if config.enableMultiDirectionalMovement then
                enableFourDirectionalMovement()
            end
        elseif not config.enableMultiDirectionalMovement then
            updateKeyCodes()
        end

        updateSprintingKey()

        if runtimeStatus.recovery.minimumRecoveryDuration ~= config.minimumRecoveryDuration then
            runtimeStatus.recovery.minimumRecoveryDuration = config.minimumRecoveryDuration

            if data and data.recoveryTimer.state ~= timer.expired then
                local recoveryTimeLeft = data.recoveryTimer.timeLeft

                data.recoveryTimer:cancel()
                startRecoveryTimer(recoveryTimeLeft)
            end
        end

    end

    -- Reset Data --

    if data then
        resetData(requiresPersistedDataReset)
    end

end

function updateConfigurationOnMenuExit()

    --[[
        Warning: Only keyboard and mouse bindings are currently supported by MWSE, but I don'tknow
        of a reliable way to distinct the type of the device. Therefore, I am assuming that the
        player's movement is binded to the keyboard for simplicitly.
    ]]--
    updateKeyCodes()

    --[[
        Info: Since we only toggle sprinting during simulation time it might be the case that the
        sprint key's state changed outside that time, i.e., while browsing a menu. We don't want to
        trigger events during that time because the player's sprinting condition should remain
        unaffected while a menu is open, however, we should toggle sprinting on exiting the menu if
        the sprint key's state changed.
    ]]--
    if data and data.isSprinting then
        if not tes3.worldController.inputController:isKeyDown(runtimeStatus.keyCodes.sprint) then
            stopSprinting()
        end
    end

end

function disableSprinting()
    local runtimeKeyCodes = runtimeStatus.keyCodes

    event.unregister(tes3.event.menuExit, updateConfigurationOnMenuExit)
    event.unregister(tes3.event.calcRunSpeed, applySprinting)

    if runtimeKeyCodes.forward then
        event.unregister(tes3.event.keyUp, pauseSprinting, { filter = runtimeKeyCodes.forward })
    end
    if runtimeKeyCodes.autoRun then
        event.unregister(tes3.event.keyDown, pauseSprinting, { filter = runtimeKeyCodes.autoRun })
    end
    enableFourDirectionalMovement()
    disableSprintingKey()
    
    disableZooming()

    event.unregister(tes3.event.save, onSave)
    if tes3.player then
        tes3.player.data.Sprinting = nil
    end

    event.unregister(tes3.event.loaded, onLoaded)

    runtimeStatus.isModEnabled = false

    mwse.log("[Sprinting] Unregistered")
end

function enableSprinting()

    event.register(tes3.event.menuExit, updateConfigurationOnMenuExit)
    event.register(tes3.event.calcRunSpeed, applySprinting)

    updateKeyCodes()
    updateSprintingKey()

    if config.enableSprintingZoom then
        enableZooming()
    end

    event.register(tes3.event.save, onSave)
    event.register(tes3.event.loaded, onLoaded)

    runtimeStatus.recovery.minimumRecoveryDuration = config.minimumRecoveryDuration
    runtimeStatus.isModEnabled = true

    mwse.log("[Sprinting] Registered")
end

-- Player Data --

function resetData(resetPersisted)

    -- Initialize Variables --

    local defaultData = {
        isSprinting   = false,
        isZooming     = false,
        isRecovering  = false,
        recoveryTimer = {
                state = timer.expired
            },
        inputState = {}
    }

    -- Reset Zooming --

    if runtimeStatus.zooming.isActive then
        updateActiveZoomingEffect{
            callback = predefinedEffects.zoomReset,
            priority = 1
        }
    end

    if data then
        if resetPersisted then

            -- Reset Recovery --

            if data.recoveryTimer.state ~= timer.expired then
                data.recoveryTimer:cancel()
            end

        else

            defaultData.isRecovering = data.isRecovering
            defaultData.recoveryTimer = data.recoveryTimer

        end
    end
    
    tes3.player.tempData.Sprinting = defaultData
    data = tes3.player.tempData.Sprinting
end

function saveData()
    tes3.player.data.Sprinting = {
        isRecovering = data.isRecovering,
        recoveryTimer = {
            timeLeft = (data.recoveryTimer.timeLeft or 0)
        }
    }
end

function loadData()
    local savedData = tes3.player.data.Sprinting

    if tes3.player.data.Sprinting then

        data.isRecovering = savedData.isRecovering
        
        startRecoveryTimer(savedData.recoveryTimer.timeLeft)
    end
end

-- Saving/Loading --

function onSave()
    saveData()
end

function onLoaded()
    resetData(true)
    loadData()
end

-- Initialization --

function onInitialized()

    if config.enableMod then
        enableSprinting()
    end

end

event.register("initialized", onInitialized)
event.register("Sprinting:UpdateConfiguration", updateConfiguration)

require("Sprinting.mcm")
