local async = require 'openmw.async'
local core = require 'openmw.core'
local gameSelf = require 'openmw.self'
local input = require 'openmw.input'
local storage = require 'openmw.storage'
local types = require 'openmw.types'
local util = require 'openmw.util'

local Player = types.Player
local I = require 'openmw.interfaces'

local ModInfo = require 'Scripts.SW4.modinfo'

local SW4InputSectionName = 'SettingsGlobal' .. ModInfo.name .. 'MoveTurnGroup'
local SW4InputSection = storage.globalSection(SW4InputSectionName)

local EngineMovementSettings = storage.playerSection('SettingsOMWControls')

-- Setting-related movement state
---@class InputManager:ProtectedTable
---@field Enabled boolean
---@field TurnByWheel boolean
---@field UseQuickTurn boolean
---@field QuickTurnMult integer
---@field QuickTurnTimeWindow number
---@field MoveRampUpTimeMax number
---@field MoveRampUpMinSpeed number
---@field MoveRampUpMaxSpeed number
---@field MoveBackRampUpTimeMax number
---@field MoveBackRampUpMinSpeed number
---@field MoveBackRampUpMaxSpeed number
---@field MoveRampDownTimeMax number
---@field MoveSpeedPeak number
---@field TurnRampTimeMax number
---@field TurnDegreesPerSecondMax number
---@field TurnDegreesPerSecondMin number
---@field SideMovementMaxSpeed number
local InputManager = I.StarwindVersion4ProtectedTable.new {
    modName = ModInfo.name,
    logPrefix = ModInfo.logPrefix,
    inputGroupName = SW4InputSectionName,
}

local Enabled,
MoveRampUpTimeMax,
MoveRampUpMinSpeed,
MoveRampUpMaxSpeed,
MoveBackRampUpTimeMax,
MoveBackRampUpMinSpeed,
MoveBackRampUpMaxSpeed,
MoveRampDownTimeMax,
MoveSpeedPeak,
TurnRampTimeMax,
TurnDegreesPerSecondMax,
TurnDegreesPerSecondMin,
SideMovementMaxSpeed,
newMax

-- non-setting movement state
local CurrentForwardRampTime = 0.0
local CurrentTurnRampTime = 0.0
local lastPressedBackTime = 0.0
local degreesTurned = 0
local autoMove = false
local attemptToJump = false
local movementControlsOverridden = false
local didPressRun = false
local doQuickTurn = false

---@type ManagementStore
local GlobalManagement

--- Updates local variables corresponding to internal setting values
function InputManager:updateSettings()
    MoveRampUpTimeMax = self.MoveRampUpTimeMax

    MoveRampUpMinSpeed = self.MoveRampUpMinSpeed
    MoveRampUpMaxSpeed = self.MoveRampUpMaxSpeed

    MoveBackRampUpTimeMax = self.MoveBackRampUpTimeMax

    MoveBackRampUpMinSpeed = self.MoveBackRampUpMinSpeed
    MoveBackRampUpMaxSpeed = self.MoveBackRampUpMaxSpeed

    MoveRampDownTimeMax = self.MoveRampDownTimeMax

    MoveSpeedPeak = self.MoveSpeedPeak
    newMax = MoveSpeedPeak

    TurnRampTimeMax = self.TurnRampTimeMax

    TurnDegreesPerSecondMax = self.TurnDegreesPerSecondMax
    TurnDegreesPerSecondMin = self.TurnDegreesPerSecondMin

    SideMovementMaxSpeed = self.SideMovementMaxSpeed

    Enabled = self.Enabled
    I.Controls.overrideMovementControls(Enabled)
end

SW4InputSection:subscribe(async:callback(function()
    InputManager:updateSettings()
end))

function InputManager.controlsAllowed()
    return not core.isWorldPaused()
        and Player.getControlSwitch(gameSelf, Player.CONTROL_SWITCH.Controls)
        and not I.UI.getMode()
end

function InputManager.movementAllowed()
    return InputManager.controlsAllowed() and not movementControlsOverridden
end

input.registerActionHandler('MoveBackward',
    async:callback(
        function(state)
            if not InputManager.Enabled or not InputManager.UseQuickTurn or not state or state == 0 then return end

            local currentTime = core.getRealTime()

            if currentTime - lastPressedBackTime < InputManager.QuickTurnTimeWindow then
                doQuickTurn = true
            end

            lastPressedBackTime = currentTime
        end
    )
)

function InputManager:processMovement(dt)
    if not InputManager.movementAllowed() then return end

    local MoveBackward = input.getRangeActionValue('MoveBackward')

    local movement = input.getRangeActionValue('MoveForward') - MoveBackward
    local sideMovement = input.getRangeActionValue('MoveRight') - input.getRangeActionValue('MoveLeft')
    local run = EngineMovementSettings:get('alwaysRun')
    local hasSpeederEquipped = GlobalManagement.MountFunctions.hasSpeederEquipped()

    if movement ~= 0 then
        autoMove = false
    elseif autoMove then
        movement = 1
    end

    if sideMovement == 0 then
        CurrentTurnRampTime = 0.0
    end

    local wheelTurnEngaged = self.TurnByWheel and input.isMouseButtonPressed(2)

    --- Strafe if the marker is up
    local strafeInsteadOfTurn = GlobalManagement.LockOn.getMarkerVisibility()
    --- But not if you're wearing a speeder and the marker is off
    strafeInsteadOfTurn = strafeInsteadOfTurn and not hasSpeederEquipped
    --- If wheel turning is enabled, then allow strafing
    strafeInsteadOfTurn = strafeInsteadOfTurn or
        (wheelTurnEngaged and not hasSpeederEquipped)

    --- When the player first starts running, bring their ramp down to match where they were before
    if strafeInsteadOfTurn and not didPressRun then
        CurrentForwardRampTime = CurrentForwardRampTime * MoveRampUpMaxSpeed
    end

    --- Don't ramp, walk, or strafe on a speeder
    if hasSpeederEquipped then
        CurrentForwardRampTime = 0.0
        run = true
    elseif movement == 1 or autoMove then
        CurrentForwardRampTime = math.min(MoveRampUpTimeMax, CurrentForwardRampTime + dt)

        newMax = strafeInsteadOfTurn and MoveSpeedPeak or MoveRampUpMaxSpeed

        movement = util.remap(CurrentForwardRampTime, 0.0, MoveRampUpTimeMax, MoveRampUpMinSpeed, newMax) *
            (movement < 0 and -1 or 1)
    elseif movement == -1 then
        CurrentForwardRampTime = math.min(MoveBackRampUpTimeMax, CurrentForwardRampTime + dt)

        newMax = MoveBackRampUpMaxSpeed

        movement = util.remap(CurrentForwardRampTime, 0.0, MoveBackRampUpTimeMax, MoveBackRampUpMinSpeed,
            MoveBackRampUpMaxSpeed)
    else
        CurrentForwardRampTime = math.min(
            math.max(
                0.0, CurrentForwardRampTime - dt
            ),
            MoveRampDownTimeMax)

        movement = util.remap(CurrentForwardRampTime, 0.0, MoveRampDownTimeMax, 0.0, newMax)
            * (gameSelf.controls.movement < 0 and -1 or 1)
    end

    gameSelf.controls.movement = movement
    local CursorManager = GlobalManagement.Cursor

    if strafeInsteadOfTurn and not hasSpeederEquipped and not CursorManager:getCursorVisible() then
        gameSelf.controls.sideMovement = math.min(
                math.abs(sideMovement), SideMovementMaxSpeed
            ) *
            (sideMovement < 0 and -1 or 1)

        gameSelf.controls.yawChange = 0
    else
        CurrentTurnRampTime = math.min(TurnRampTimeMax, CurrentTurnRampTime + dt)

        local turnSpeed = util.round(
            util.remap(CurrentTurnRampTime,
                0.0,
                TurnRampTimeMax,
                TurnDegreesPerSecondMin,
                TurnDegreesPerSecondMax)
        )

        if wheelTurnEngaged and CursorManager:getCursorVisible()
        then
            local mouseMoveThisFrame = CursorManager.state.changeThisFrame

            local turnRadiusBase = mouseMoveThisFrame:length() * CursorManager.Sensitivity *
                (mouseMoveThisFrame.x < 0 and -1 or 1)

            gameSelf.controls.yawChange = math.rad(turnRadiusBase)

            gameSelf.controls.sideMovement = math.min(
                    math.abs(sideMovement), SideMovementMaxSpeed
                ) *
                (sideMovement < 0 and -1 or 1)
        else
            gameSelf.controls.yawChange = math.rad(sideMovement * turnSpeed * dt)
            gameSelf.controls.sideMovement = 0
        end
    end

    if doQuickTurn then
        local turnThisFrame = math.rad(180 * dt * self.QuickTurnMult)
        gameSelf.controls.yawChange = turnThisFrame

        degreesTurned = degreesTurned + turnThisFrame
        if degreesTurned >= math.rad(180) then
            doQuickTurn = false
            degreesTurned = 0
        end
    end

    gameSelf.controls.run = run
    gameSelf.controls.jump = attemptToJump
    didPressRun = strafeInsteadOfTurn
    attemptToJump = false

    if not EngineMovementSettings:get('toggleSneak') then
        gameSelf.controls.sneak = input.getBooleanActionValue('Sneak')
    end
end

input.registerTriggerHandler('Jump', async:callback(function()
    if not InputManager.movementAllowed() then return end

    attemptToJump = Player.getControlSwitch(gameSelf, Player.CONTROL_SWITCH.Jumping)
end))

input.registerTriggerHandler('ToggleSneak', async:callback(function()
    if not InputManager.movementAllowed() or not EngineMovementSettings:get('toggleSneak') then return end

    gameSelf.controls.sneak = not gameSelf.controls.sneak
end))

input.registerTriggerHandler('AlwaysRun', async:callback(function()
    if not InputManager.movementAllowed() then return end

    EngineMovementSettings:set('alwaysRun', not EngineMovementSettings:get('alwaysRun'))
end))

input.registerTriggerHandler('AutoMove', async:callback(function()
    if not InputManager.movementAllowed() then return end

    autoMove = not autoMove
end))

function InputManager:onFrameBegin(dt)
end

function InputManager:onFrame(dt)
    if not Enabled then return end
    self:processMovement(dt)
end

function InputManager:onFrameEnd(dt)
end

---@param managementStore ManagementStore
---@return InputManager
return function(managementStore)
    assert(managementStore)
    GlobalManagement = managementStore
    InputManager:updateSettings()
    return InputManager
end
