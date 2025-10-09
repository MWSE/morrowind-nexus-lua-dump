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
local function processMovement(data)
    local MFBA = data.MFBA                 --input.CONTROLLER_AXIS.MoveForwardBackward
    local CSM = data.CSM                   --input.getAxisValue(input.CONTROLLER_AXIS.MoveLeftRight)
    local moveLeft = data.moveLeft         -- input.isActionPressed(input.ACTION.MoveLeft )
    local moveRight = data.moveRight       -- input.isActionPressed(input.ACTION.MoveLeft )
    local moveBackward = data.moveBackward -- input.isActionPressed(input.ACTION.MoveLeft )
    local moveForward = data.moveForward   -- input.isActionPressed(input.ACTION.MoveLeft )
    local jumping = data.jumping           --input.getControlSwitch(input.CONTROL_SWITCH.Jumping)
    local sneaking = data.sneaking         -- input.isActionPressed(input.ACTION.Sneak)
    local controllerMovement = MFBA        ---input.getAxisValue(input.CONTROLLER_AXIS.MoveForwardBackward)
    local controllerSideMovement = CSM     --input.getAxisValue(input.CONTROLLER_AXIS.MoveLeftRight)
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
        if moveLeft and input.isControllerButtonPressed(cbut.DPadLeft) == false then
            controlledActor.controls.sideMovement = controlledActor.controls.sideMovement - 1
        end
        if moveRight and input.isControllerButtonPressed(cbut.DPadRight) == false then
            controlledActor.controls.sideMovement = controlledActor.controls.sideMovement + 1
        end
        if moveBackward and input.isControllerButtonPressed(cbut.DPadDown) == false then
            controlledActor.controls.movement = controlledActor.controls.movement - 1
        end
        if moveForward and input.isControllerButtonPressed(cbut.DPadUp) == false then
            controlledActor.controls.movement = controlledActor.controls.movement + 1
        end
        controlledActor.controls.run = true --input.isActionPressed(input.ACTION.Run) ~= settings:get('alwaysRun')
        --  end
    end
    if controlledActor.controls.movement ~= 0 or not Actor.canMove(controlledActor) then
        autoMove = false
    elseif autoMove then
        controlledActor.controls.movement = 1
    end
    controlledActor.controls.jump = attemptJump and jumping
    if not settings:get('toggleSneak') then
     controlledActor.controls.sneak = false
    end
end

local function processAttacking(data)
    local triggerRight = data.triggerRight --input.getAxisValue(input.CONTROLLER_AXIS.TriggerRight)
    local useAction = data.useAction       --input.isActionPressed(input.ACTION.Use)
    if startAttack then
        controlledActor.controls.use = 1
    elseif Actor.stance(controlledActor) == Actor.STANCE.Spell then
        controlledActor.controls.use = 0
    elseif triggerRight < 0.6
        and not useAction then
        -- The value "0.6" shouldn't exceed the triggering threshold in BindingsManager::actionValueChanged.
        -- TODO: Move more logic from BindingsManager to Lua and consider to make this threshold configurable.
        controlledActor.controls.use = 0
    end
end

local function onFrame(dt)
    if (combatControlsOverridden) then
        return
    end
    controlsAllowed = not core.isWorldPaused()
    if not movementControlsOverridden then
        if controlsAllowed then
            local MFBA = -input.getAxisValue(input.CONTROLLER_AXIS.MoveForwardBackward)
            local CSM = input.getAxisValue(input.CONTROLLER_AXIS.MoveLeftRight)
            local moveLeft = input.isActionPressed(input.ACTION.MoveLeft)
            local moveRight = input.isActionPressed(input.ACTION.MoveRight)
            local moveBackward = input.isActionPressed(input.ACTION.MoveBackward)
            local moveForward = input.isActionPressed(input.ACTION.MoveForward)
            local jumping = input.getControlSwitch(input.CONTROL_SWITCH.Jumping)
            local sneaking = input.isActionPressed(input.ACTION.Sneak)
            if (controlledActor.id == self.id) then
                processMovement({
                    CSM = CSM,
                    MFBA = MFBA,
                    moveLeft = moveLeft,
                    moveRight = moveRight,
                    moveBackward = moveBackward,
                    moveForward = moveForward,
                    jumping = jumping,
                    sneaking = sneaking
                })
            else
                controlledActor:sendEvent("processMovement",
                    {
                        CSM = CSM,
                        MFBA = MFBA,
                        moveLeft = moveLeft,
                        moveRight = moveRight,
                        moveBackward = moveBackward,
                        moveForward = moveForward,
                        jumping = jumping,
                        sneaking = sneaking
                    })
            end
        else
            self.controls.movement = 0
            self.controls.sideMovement = 0
            self.controls.jump = false
        end
    end
    if controlsAllowed and not combatControlsOverridden and controlledActor.id == self.id then
        local triggerRight = input.getAxisValue(input.CONTROLLER_AXIS.TriggerRight)
        local useAction = input.isActionPressed(input.ACTION.Use)
        processAttacking({ triggerRight = triggerRight, useAction = useAction })
    elseif (combatControlsOverridden == false) then
        local triggerRight = input.getAxisValue(input.CONTROLLER_AXIS.TriggerRight)
        local useAction = input.isActionPressed(input.ACTION.Use)
        if (useAction) then
            controlledActor:sendEvent("processAttacking", { triggerRight = triggerRight, useAction = useAction })
        end
    end
    attemptJump = false
    startAttack = false
end
local function toggleSneak(sneak)
  --  self.controls.sneak = not self.controls.sneak
end
local function takeControlOfActor(actor, force)
    if force == nil then
        force = false
    end
    if (actor.id == self.id) then
        I.ControlsZack.overrideMovementControls(not force)
        I.ControlsZack.overrideCombatControls(not force)
        I.Controls.overrideMovementControls(force)
        I.Controls.overrideCombatControls(force)
        --   I.SlaveScript.setCameraTarget(self)
        I.ControlsZack.setTargetActor(self)
    else
        I.ControlsZack.overrideMovementControls(false)
        I.ControlsZack.overrideCombatControls(false)
        I.Controls.overrideMovementControls(true)
        I.Controls.overrideCombatControls(true)
        --   I.SlaveScript.setCameraTarget(actor)
        I.ControlsZack.setTargetActor(actor)
        actor:sendEvent("setAIState", false)
    end
end
local function startAttackNow()
    startAttack = Actor.stance(controlledActor) ~= Actor.STANCE.Nothing
end
local function onInputAction(action)
    if core.isWorldPaused() then
        return
    end

    if action == input.ACTION.Jump then
        if (controlledActor.id ~= self.id) then
            controlledActor:sendEvent("jump")
        else
            attemptJump = true
        end
    elseif action == input.ACTION.Use then
        if (controlledActor.id ~= self.id) then
            controlledActor:sendEvent("startAttackNow")
        else
            startAttackNow()
        end
    elseif action == input.ACTION.AutoMove and not movementControlsOverridden then
       -- autoMove = not autoMove
    elseif action == input.ACTION.AlwaysRun and not movementControlsOverridden then
        settings:set('alwaysRun', not settings:get('alwaysRun'))
    elseif action == input.ACTION.Sneak and not movementControlsOverridden then
        if settings:get('toggleSneak') then
            toggleSneak()
        end
    elseif action == input.ACTION.ToggleSpell and not combatControlsOverridden then
        if (controlledActor.id ~= self.id) then
            controlledActor:sendEvent("readySpell")
        else
            if Actor.stance(controlledActor) == Actor.STANCE.Spell then
                Actor.setStance(controlledActor, Actor.STANCE.Nothing)
            elseif input.getControlSwitch(input.CONTROL_SWITCH.Magic) then
                if Player.isWerewolf(controlledActor) then
                    ui.showMessage(core.getGMST('sWerewolfRefusal'))
                else
                    Actor.setStance(controlledActor, Actor.STANCE.Spell)
                end
            end
        end
    elseif action == input.ACTION.ToggleWeapon and not combatControlsOverridden then
        if (controlledActor.id ~= self.id) then
            controlledActor:sendEvent("toggleWeapon")
        else
            if Actor.stance(controlledActor) == Actor.STANCE.Weapon then
                Actor.setStance(controlledActor, Actor.STANCE.Nothing)
            elseif input.getControlSwitch(input.CONTROL_SWITCH.Fighting) then
                Actor.setStance(controlledActor, Actor.STANCE.Weapon)
            end
        end
    end
end
local function setTargetActor(actor)
    controlledActor = actor
end
return {
    engineHandlers = {
        onFrame = onFrame,
        onInputAction = onInputAction,
    },
    eventHandlers = { processAttacking = processAttacking },
    interfaceName = 'ControlsZack',
    ---
    -- @module Controls
    -- @usage require('openmw.interfaces').Controls
    interface = {
        takeControlOfActor = takeControlOfActor,
        --- Interface version
        -- @field [parent=#Controls] #number version
        version = 0,
        setTargetActor = function(a) controlledActor = a end,

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
