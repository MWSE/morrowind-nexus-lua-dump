local core = require('openmw.core')
local input = require('openmw.input')
local self = require('openmw.self')
local util = require('openmw.util')
local ui = require('openmw.ui')
local Actor = require('openmw.types').Actor
local Player = require('openmw.types').Player

local storage = require('openmw.storage')
local I = require('openmw.interfaces')

local settingsGroup = 'TRTSettingsOMWControls'
local controllerSettings = storage.playerSection("SettingsAshlanderArchitectController")
local controlledActor = self


local settings = storage.playerSection(settingsGroup)

local attemptJump = false
local startAttack = false
local autoMove = false
local movementControlsOverridden = true
local combatControlsOverridden = true
local cbut = input.CONTROLLER_BUTTON
local function processMovement()
    local controllerMovement = -input.getAxisValue(input.CONTROLLER_AXIS.MoveForwardBackward)
    local controllerSideMovement = input.getAxisValue(input.CONTROLLER_AXIS.MoveLeftRight)
    if controllerMovement ~= 0 or controllerSideMovement ~= 0 then
        -- controller movement
        if util.vector2(controllerMovement, controllerSideMovement):length2() < 0.25
           and not controlledActor.controls.sneak and Actor.isOnGround(controlledActor) and not Actor.isSwimming(controlledActor) then
            controlledActor.controls.run = false
            controlledActor.controls.movement = controllerMovement * 2
            controlledActor.controls.sideMovement = controllerSideMovement * 2
        else
            controlledActor.controls.run = true
            controlledActor.controls.movement = controllerMovement
            controlledActor.controls.sideMovement = controllerSideMovement
        end
    else
     --   if(controllerSettings:get("ForceControllerMode") == false) then

        -- keyboard movement
        controlledActor.controls.movement = 0
        controlledActor.controls.sideMovement = 0
        if input.isActionPressed(input.ACTION.MoveLeft ) and input.isControllerButtonPressed(cbut.DPadLeft) == false then
           controlledActor.controls.sideMovement = controlledActor.controls.sideMovement - 1
        end
        if input.isActionPressed(input.ACTION.MoveRight)  and input.isControllerButtonPressed(cbut.DPadRight) == false then
          controlledActor.controls.sideMovement = controlledActor.controls.sideMovement + 1
        end
        if input.isActionPressed(input.ACTION.MoveBackward) and input.isControllerButtonPressed(cbut.DPadDown) == false then
            controlledActor.controls.movement = controlledActor.controls.movement - 1
        end
        if input.isActionPressed(input.ACTION.MoveForward) and input.isControllerButtonPressed(cbut.DPadUp) == false then
           controlledActor.controls.movement = controlledActor.controls.movement + 1
        end
        controlledActor.controls.run = input.isActionPressed(input.ACTION.Run) ~= settings:get('alwaysRun')
  --  end
    end
    if controlledActor.controls.movement ~= 0 or not Actor.canMove(controlledActor) then
        autoMove = false
    elseif autoMove then
        controlledActor.controls.movement = 1
    end
    controlledActor.controls.jump = attemptJump and input.getControlSwitch(input.CONTROL_SWITCH.Jumping)
    if not settings:get('toggleSneak') then
        controlledActor.controls.sneak = input.isActionPressed(input.ACTION.Sneak)
    end
end

local function processAttacking()
    if startAttack then
        controlledActor.controls.use = 1
    elseif Actor.stance(controlledActor) == Actor.STANCE.Spell then
        controlledActor.controls.use = 0
    elseif input.getAxisValue(input.CONTROLLER_AXIS.TriggerRight) < 0.6
           and not input.isActionPressed(input.ACTION.Use) then
        -- The value "0.6" shouldn't exceed the triggering threshold in BindingsManager::actionValueChanged.
        -- TODO: Move more logic from BindingsManager to Lua and consider to make this threshold configurable.
        controlledActor.controls.use = 0
    end
end

local function onFrame(dt)
    controlsAllowed =  not core.isWorldPaused()
    if not movementControlsOverridden then
        if controlsAllowed then
            processMovement()
        else
            controlledActor.controls.movement = 0
            controlledActor.controls.sideMovement = 0
            controlledActor.controls.jump = false
        end
    end
    if controlsAllowed and not combatControlsOverridden then
        processAttacking()
    end
    attemptJump = false
    startAttack = false
end

local function onInputAction(action)
    if core.isWorldPaused()  then
        return
    end

    if action == input.ACTION.Jump then
        attemptJump = true
    elseif action == input.ACTION.Use then
        startAttack = Actor.stance(controlledActor) ~= Actor.STANCE.Nothing
    elseif action == input.ACTION.AutoMove and not movementControlsOverridden then
        autoMove = not autoMove
    elseif action == input.ACTION.AlwaysRun and not movementControlsOverridden then
        settings:set('alwaysRun', not settings:get('alwaysRun'))
    elseif action == input.ACTION.Sneak and not movementControlsOverridden then
        if settings:get('toggleSneak') then
            controlledActor.controls.sneak = not controlledActor.controls.sneak
        end
    elseif action == input.ACTION.ToggleSpell and not combatControlsOverridden then
        if Actor.stance(controlledActor) == Actor.STANCE.Spell then
            Actor.setStance(controlledActor, Actor.STANCE.Nothing)
        elseif input.getControlSwitch(input.CONTROL_SWITCH.Magic) then
            if Player.isWerewolf(controlledActor) then
                ui.showMessage(core.getGMST('sWerewolfRefusal'))
            else
                Actor.setStance(controlledActor, Actor.STANCE.Spell)
            end
        end
    elseif action == input.ACTION.ToggleWeapon and not combatControlsOverridden then
        if Actor.stance(controlledActor) == Actor.STANCE.Weapon then
            Actor.setStance(controlledActor, Actor.STANCE.Nothing)
        elseif input.getControlSwitch(input.CONTROL_SWITCH.Fighting) then
            Actor.setStance(controlledActor, Actor.STANCE.Weapon)
        end
    end
end

return {
    engineHandlers = {
        onFrame = onFrame,
        onInputAction = onInputAction,
    },
    interfaceName = 'ControlsZack',
    ---
    -- @module Controls
    -- @usage require('openmw.interfaces').Controls
    interface = {
        --- Interface version
        -- @field [parent=#Controls] #number version
        version = 0,

        --- When set to true then the movement controls including jump and sneak are not processed and can be handled by another script.
        -- If movement should be dissallowed completely, consider to use `input.setControlSwitch` instead.
        -- @function [parent=#Controls] overrideMovementControls
        -- @param #boolean value
        overrideMovementControls = function(v) movementControlsOverridden = v end,

        --- When set to true then the controls "attack", "toggle spell", "toggle weapon" are not processed and can be handled by another script.
        -- If combat should be dissallowed completely, consider to use `input.setControlSwitch` instead.
        -- @function [parent=#Controls] overrideCombatControls
        -- @param #boolean value
        overrideCombatControls = function(v) combatControlsOverridden = v end,
    }
}

