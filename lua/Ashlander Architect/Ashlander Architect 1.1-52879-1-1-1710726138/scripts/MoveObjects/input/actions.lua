local input = require('openmw.input')
local ui = require('openmw.ui')
local I = require('openmw.interfaces')
local storage = require('openmw.storage')
local async = require('openmw.async')
local self = require('openmw.self')
local types = require('openmw.types')


local keyBindings = storage.playerSection("AA_KeyBindings")

local bindings = {}
local registeredActions = {}
local forceReset = false

local knownActions = require("scripts.MoveObjects.input.knownActions")


local function registerAction(bindingName, shortDesc, keyId, controllerButton, controllerModifer, isHidden)
    if not registeredActions[bindingName] then
        input.registerTrigger({
            description = shortDesc,
            name = shortDesc,
            l10n = bindingName,
            key = bindingName,
        })
    end
    registeredActions[bindingName] = true
    if not keyBindings:get(bindingName .. "_key") or forceReset then
        keyBindings:set(bindingName .. "_key", keyId)
    elseif keyBindings:get(bindingName .. "_key") then
        keyId = keyBindings:get(bindingName .. "_key")
    end
    if not keyBindings:get(bindingName .. "_ctrl") or forceReset then
        keyBindings:set(bindingName .. "_ctrl", controllerButton)
    elseif keyBindings:get(bindingName .. "_ctrl") then
        controllerButton = keyBindings:get(bindingName .. "_ctrl")
    end
    I.AA_Bindings.registerBinding(bindingName, shortDesc, keyId, controllerButton, controllerModifer,isHidden)
    bindings[bindingName] = {
        key = keyId,
        controllerButton = controllerButton,
        shortDesc = shortDesc,
        pressed = false,
        controllerModifer = controllerModifer,
        defaultKey = keyId,
        isHidden = isHidden
    }
end
local function getKeyCodeKB(bindingName)
    return keyBindings:get(bindingName .. "_key")
end
local function registerDefaultBindings(force)
    if force then
        forceReset = true
    end
    registerAction(knownActions.removeGridRef, "Remove/Set Grid Reference Object", input.KEY.C, input.CONTROLLER_BUTTON.Y)
    registerAction(knownActions.toggleBuildMode, "Toggle Build Mode", input.KEY.B, input.CONTROLLER_BUTTON.Back)
    registerAction(knownActions.toggleSurfaceSnapping, "%s Surface Snapping", input.KEY.N, input.CONTROLLER_BUTTON.Y)
    registerAction(knownActions.toggleVerticalPositionLock, "%s Vertical Position Lock", input.KEY.G)
    registerAction(knownActions.grabTargetedObject, "Pick up Targeted Object", "rightMb", input.CONTROLLER_BUTTON.X, nil, true)
    registerAction(knownActions.destroySelectedObject, "Destroy Selected Object", input.KEY.Q)
    registerAction(knownActions.returnToOriginalPos, "Reset Object to Original Position", input.KEY.J)
    registerAction(knownActions.toggleUI, "Toggle UI", input.KEY.F11)

    registerAction(knownActions.toggleOverview, "Toggle Overhead Mode", input.KEY.I)
    registerAction(knownActions.startWallBuilding, "Start Wall Building", input.KEY.O)
    registerAction(knownActions.swapObject, "Swap Object for Varient", input.KEY.K)


    registerAction(knownActions.orderNPC, "Send Order/Stamp Object", "leftMb", input.CONTROLLER_BUTTON.A)


    registerAction(knownActions.resetHeightOffset, "Reset Height Offset", input.KEY.X, input.CONTROLLER_BUTTON.RightStick)
    registerAction(knownActions.resetRotation, "Reset Rotation", input.KEY.L, input.CONTROLLER_BUTTON.LeftStick)
    registerAction(knownActions.resetCursor, "Reset Cursor Position", input.KEY.U, input.CONTROLLER_BUTTON.LeftStick)
    --can't change these
    --registerAction(knownActions.rightClick, "Right Click", "rightMb", input.CONTROLLER_BUTTON.LeftStick)
    --
    registerAction(knownActions.arrowUp, "Arrow Up", input.KEY.UpArrow, input.CONTROLLER_BUTTON.DPadUp, nil, true)
    registerAction(knownActions.arrowDown, "Arrow Down", input.KEY.DownArrow, input.CONTROLLER_BUTTON.DPadDown, nil, true)
    registerAction(knownActions.arrowLeft, "Arrow Left", input.KEY.LeftArrow, input.CONTROLLER_BUTTON.DPadLeft, nil, true)
    registerAction(knownActions.arrowRight, "Arrow Right", input.KEY.RightArrow, input.CONTROLLER_BUTTON.DPadRight, nil, true)
    registerAction(knownActions.toggleScrollMode, "toggleScrollMode", input.KEY.LeftCtrl, input.CONTROLLER_BUTTON.DPadRight, nil, true)
    self:sendEvent("registerSettings",bindings)
    keyBindings:set("bindings",bindings)
    forceReset = false
end
registerDefaultBindings()
return{
    interfaceName = "AA_Actions",
    interface = {
        registerDefaultBindings = registerDefaultBindings,
    }
}