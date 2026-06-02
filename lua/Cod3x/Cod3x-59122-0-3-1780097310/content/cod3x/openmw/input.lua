---@meta

-- This file was mechanically drafted from files/lua_api/openmw/input.lua.
-- It uses LuaLS/LLS annotations and stub bodies only; runtime behavior is provided by OpenMW.
-- OpenMW script contexts: menu|player

---Most mods should prefer to use the actions/triggers API over the direct input device methods.
---Actions have one value on each frame (resolved just before the `onFrame` engine handler),
--- while Triggers don't have a value, but can occur multiple times on each frame.
---Prefer to use built-in methods of binding actions, such as the [inputBinding setting renderer](setting_renderers.html#inputbinding)
----- Example of Action usage
---input.registerAction {
---}
---return {
---}
----- Example of Trigger usage
---input.registerTrigger {
---}
---input.registerTriggerHandler('MyTrigger', async:callback(function() print('MyTrigger') end))
---@class openmw.input
local input = {}

---String id of a CONTROL_SWITCH
---@class openmw.input.ControlSwitch
local ControlSwitch = {}

---@class openmw.input.CONTROL_SWITCH
---@field Controls openmw.input.ControlSwitch Ability to move
---@field Fighting openmw.input.ControlSwitch Ability to attack
---@field Jumping openmw.input.ControlSwitch Ability to jump
---@field Looking openmw.input.ControlSwitch Ability to change view direction
---@field Magic openmw.input.ControlSwitch Ability to use magic
---@field ViewMode openmw.input.ControlSwitch Ability to toggle 1st/3rd person view
---@field VanityMode openmw.input.ControlSwitch Vanity view if the player doesn't touch controls for a long time
local CONTROL_SWITCH = {}

---(DEPRECATED, use actions with matching keys)
---@class openmw.input.ACTION
---@field GameMenu number
---@field Screenshot number
---@field Inventory number
---@field Console number
---@field MoveLeft number
---@field MoveRight number
---@field MoveForward number
---@field MoveBackward number
---@field Activate number
---@field Use number
---@field Jump number
---@field AutoMove number
---@field Journal number
---@field Run number
---@field CycleSpellLeft number
---@field CycleSpellRight number
---@field CycleWeaponLeft number
---@field CycleWeaponRight number
---@field AlwaysRun number
---@field Sneak number
---@field QuickSave number
---@field QuickLoad number
---@field QuickMenu number
---@field ToggleWeapon number
---@field ToggleSpell number
---@field TogglePOV number
---@field QuickKey1 number
---@field QuickKey2 number
---@field QuickKey3 number
---@field QuickKey4 number
---@field QuickKey5 number
---@field QuickKey6 number
---@field QuickKey7 number
---@field QuickKey8 number
---@field QuickKey9 number
---@field QuickKey10 number
---@field QuickKeysMenu number
---@field ToggleHUD number
---@field ToggleDebug number
---@field ZoomIn number
---@field ZoomOut number
---@field TogglePostProcessorHUD number
local ACTION = {}

---@class openmw.input.CONTROLLER_BUTTON
---@field A number
---@field B number
---@field X number
---@field Y number
---@field Back number
---@field Guide number
---@field Start number
---@field LeftStick number
---@field RightStick number
---@field LeftShoulder number
---@field RightShoulder number
---@field DPadUp number
---@field DPadDown number
---@field DPadLeft number
---@field DPadRight number
---@field Misc1 number
---@field Paddle1 number
---@field Paddle2 number
---@field Paddle3 number
---@field Paddle4 number
---@field Touchpad number
local CONTROLLER_BUTTON = {}

---Ids of game controller axises. Used as an argument in getAxisValue.
---@class openmw.input.CONTROLLER_AXIS
---@field LeftX number Left stick horizontal axis (from -1 to 1)
---@field LeftY number Left stick vertical axis (from -1 to 1)
---@field RightX number Right stick horizontal axis (from -1 to 1)
---@field RightY number Right stick vertical axis (from -1 to 1)
---@field TriggerLeft number Left trigger (from 0 to 1)
---@field TriggerRight number Right trigger (from 0 to 1)
---@field LookUpDown number (DEPRECATED, use the LookUpDown action) View direction vertical axis (RightY by default, can be mapped to another axis in Options/Controls menu)
---@field LookLeftRight number (DEPRECATED, use the LookLeftRight action) View direction horizontal axis (RightX by default, can be mapped to another axis in Options/Controls menu)
---@field MoveForwardBackward number (DEPRECATED, use the MoveForwardBackward action) Movement forward/backward (LeftY by default, can be mapped to another axis in Options/Controls menu)
---@field MoveLeftRight number (DEPRECATED, use the MoveLeftRight action) Side movement (LeftX by default, can be mapped to another axis in Options/Controls menu)
local CONTROLLER_AXIS = {}

---Numeric id of a KEY
---@class openmw.input.KeyCode
local KeyCode = {}

---@class openmw.input.KEY
---@field _0 openmw.input.KeyCode
---@field _1 openmw.input.KeyCode
---@field _2 openmw.input.KeyCode
---@field _3 openmw.input.KeyCode
---@field _4 openmw.input.KeyCode
---@field _5 openmw.input.KeyCode
---@field _6 openmw.input.KeyCode
---@field _7 openmw.input.KeyCode
---@field _8 openmw.input.KeyCode
---@field _9 openmw.input.KeyCode
---@field NP_0 openmw.input.KeyCode
---@field NP_1 openmw.input.KeyCode
---@field NP_2 openmw.input.KeyCode
---@field NP_3 openmw.input.KeyCode
---@field NP_4 openmw.input.KeyCode
---@field NP_5 openmw.input.KeyCode
---@field NP_6 openmw.input.KeyCode
---@field NP_7 openmw.input.KeyCode
---@field NP_8 openmw.input.KeyCode
---@field NP_9 openmw.input.KeyCode
---@field NP_Divide openmw.input.KeyCode
---@field NP_Enter openmw.input.KeyCode
---@field NP_Minus openmw.input.KeyCode
---@field NP_Multiply openmw.input.KeyCode
---@field NP_Delete openmw.input.KeyCode
---@field NP_Plus openmw.input.KeyCode
---@field F1 openmw.input.KeyCode
---@field F2 openmw.input.KeyCode
---@field F3 openmw.input.KeyCode
---@field F4 openmw.input.KeyCode
---@field F5 openmw.input.KeyCode
---@field F6 openmw.input.KeyCode
---@field F7 openmw.input.KeyCode
---@field F8 openmw.input.KeyCode
---@field F9 openmw.input.KeyCode
---@field F10 openmw.input.KeyCode
---@field F11 openmw.input.KeyCode
---@field F12 openmw.input.KeyCode
---@field A openmw.input.KeyCode
---@field B openmw.input.KeyCode
---@field C openmw.input.KeyCode
---@field D openmw.input.KeyCode
---@field E openmw.input.KeyCode
---@field F openmw.input.KeyCode
---@field G openmw.input.KeyCode
---@field H openmw.input.KeyCode
---@field I openmw.input.KeyCode
---@field J openmw.input.KeyCode
---@field K openmw.input.KeyCode
---@field L openmw.input.KeyCode
---@field M openmw.input.KeyCode
---@field N openmw.input.KeyCode
---@field O openmw.input.KeyCode
---@field P openmw.input.KeyCode
---@field Q openmw.input.KeyCode
---@field R openmw.input.KeyCode
---@field S openmw.input.KeyCode
---@field T openmw.input.KeyCode
---@field U openmw.input.KeyCode
---@field V openmw.input.KeyCode
---@field W openmw.input.KeyCode
---@field X openmw.input.KeyCode
---@field Y openmw.input.KeyCode
---@field Z openmw.input.KeyCode
---@field LeftArrow openmw.input.KeyCode
---@field RightArrow openmw.input.KeyCode
---@field UpArrow openmw.input.KeyCode
---@field DownArrow openmw.input.KeyCode
---@field LeftAlt openmw.input.KeyCode
---@field LeftCtrl openmw.input.KeyCode
---@field LeftBracket openmw.input.KeyCode
---@field LeftSuper openmw.input.KeyCode
---@field LeftShift openmw.input.KeyCode
---@field RightAlt openmw.input.KeyCode
---@field RightCtrl openmw.input.KeyCode
---@field RightBracket openmw.input.KeyCode
---@field RightSuper openmw.input.KeyCode
---@field RightShift openmw.input.KeyCode
---@field Apostrophe openmw.input.KeyCode
---@field BackSlash openmw.input.KeyCode
---@field Backspace openmw.input.KeyCode
---@field CapsLock openmw.input.KeyCode
---@field Comma openmw.input.KeyCode
---@field Delete openmw.input.KeyCode
---@field End openmw.input.KeyCode
---@field Enter openmw.input.KeyCode
---@field Equals openmw.input.KeyCode
---@field Escape openmw.input.KeyCode
---@field Home openmw.input.KeyCode
---@field Insert openmw.input.KeyCode
---@field Minus openmw.input.KeyCode
---@field NumLock openmw.input.KeyCode
---@field PageDown openmw.input.KeyCode
---@field PageUp openmw.input.KeyCode
---@field Pause openmw.input.KeyCode
---@field Period openmw.input.KeyCode
---@field PrintScreen openmw.input.KeyCode
---@field ScrollLock openmw.input.KeyCode
---@field Semicolon openmw.input.KeyCode
---@field Slash openmw.input.KeyCode
---@field Space openmw.input.KeyCode
---@field Tab openmw.input.KeyCode
local KEY = {}

---The argument of `onKeyPress`/`onKeyRelease` engine handlers.
---@class openmw.input.KeyboardEvent
---@field symbol string The pressed symbol (1-symbol string if can be represented or an empty string otherwise).
---@field code openmw.input.KeyCode Key code.
---@field withShift boolean Is `Shift` key pressed.
---@field withCtrl boolean Is `Control` key pressed.
---@field withAlt boolean Is `Alt` key pressed.
---@field withSuper boolean Is `Super`/`Win` key pressed.
local KeyboardEvent = {}

---The argument of onTouchPress/onTouchRelease/onTouchMove engine handlers.
---@class openmw.input.TouchEvent
---@field device number Device id (there might be multiple touch devices connected). Note: the specific device ids are not guaranteed. Always use previous user input (onTouch... handlers) to get a valid device id (e. g. in your script's settings page).
---@field finger number Finger id (the device might support multitouch).
---@field position openmw.util.Vector2 Relative position on the touch device (0 to 1 from top left corner),
---@field pressure number Pressure of the finger.
local TouchEvent = {}

---@class openmw.input.ActionType
local ActionType = {}

---@class openmw.input.ACTION_TYPE
---@field Boolean openmw.input.ActionType Input action with value of true or false
---@field Number openmw.input.ActionType Input action with a numeric value
---@field Range openmw.input.ActionType Input action with a numeric value between 0 and 1 (inclusive)
local ACTION_TYPE = {}

---@class openmw.input.ActionInfo
---@field key string
---@field type openmw.input.ActionType
---@field l10n string Localization context containing the name and description keys
---@field name string Localization key of the action's name
---@field description string Localization key of the action's description
---@field defaultValue any initial value of the action
local ActionInfo = {}

---@class openmw.input.TriggerInfo
---@field key string
---@field l10n string Localization context containing the name and description keys
---@field name string Localization key of the trigger's name
---@field description string Localization key of the trigger's description
local TriggerInfo = {}

---Is the player idle.
---@return boolean
function input.isIdle() end

---(DEPRECATED, use getBooleanActionValue) Input bindings can be changed in-game using Options/Controls menu.
---@param actionId number One of openmw.input.ACTION
---@return boolean
function input.isActionPressed(actionId) end

---Is a keyboard button currently pressed.
---@param keyCode openmw.input.KeyCode Key code (see openmw.input.KEY)
---@return boolean
function input.isKeyPressed(keyCode) end

---Is a controller button currently pressed.
---@param buttonId number Button index (see openmw.input.CONTROLLER_BUTTON)
---@return boolean
function input.isControllerButtonPressed(buttonId) end

---Is `Shift` key pressed.
---@return boolean
function input.isShiftPressed() end

---Is `Ctrl` key pressed.
---@return boolean
function input.isCtrlPressed() end

---Is `Alt` key pressed.
---@return boolean
function input.isAltPressed() end

---Is `Super`/`Win` key pressed.
---@return boolean
function input.isSuperPressed() end

---Is a mouse button currently pressed.
---@param buttonId number Button index (1 - left, 2 - middle, 3 - right, 4 - X1, 5 - X2)
---@return boolean
function input.isMouseButtonPressed(buttonId) end

---Horizontal mouse movement during the last frame.
---@return number
function input.getMouseMoveX() end

---Vertical mouse movement during the last frame.
---@return number
function input.getMouseMoveY() end

---Get value of an axis of a game controller.
---@param axisId number Index of a controller axis, one of openmw.input.CONTROLLER_AXIS.
---@return number value Value in range [-1, 1].
function input.getAxisValue(axisId) end

---Returns a human readable name for the given key code
---@param code openmw.input.KeyCode A key code (see openmw.input.KEY)
---@return string
function input.getKeyName(code) end

---[Deprecated, moved to types.Player] Get state of a control switch. I.e. is the player able to move/fight/jump/etc.
---@param key openmw.input.ControlSwitch Control type (see openmw.input.CONTROL_SWITCH)
---@return boolean
function input.getControlSwitch(key) end

---[Deprecated, moved to types.Player] Set state of a control switch. I.e. forbid or allow the player to move/fight/jump/etc.
---@param key openmw.input.ControlSwitch Control type (see openmw.input.CONTROL_SWITCH)
---@param value boolean
function input.setControlSwitch(key, value) end

---[Deprecated, moved to types.Player] Values that can be used with getControlSwitch/setControlSwitch.
---@type openmw.input.CONTROL_SWITCH
input.CONTROL_SWITCH = nil

---(DEPRECATED, use getBooleanActionValue) Values that can be used with isActionPressed.
---@type openmw.input.ACTION
input.ACTION = nil

---Values that can be passed to onControllerButtonPress/onControllerButtonRelease engine handlers.
---@type openmw.input.CONTROLLER_BUTTON
input.CONTROLLER_BUTTON = nil

---Values that can be used with getAxisValue.
---@type openmw.input.CONTROLLER_AXIS
input.CONTROLLER_AXIS = nil

---Key codes.
---@type openmw.input.KEY
input.KEY = nil

---Values that can be used in registerAction
---@type openmw.input.ACTION_TYPE
input.ACTION_TYPE = nil

---Map of all currently registered actions
---@type table<string, openmw.input.ActionInfo>
input.actions = nil

---Registers a new input action. The key must be unique
---@param info openmw.input.ActionInfo
function input.registerAction(info) end

---Provides a function computing the value of given input action.
---  The callback is called once a frame, after the values of dependency actions are resolved.
---  Throws an error if a cyclic action dependency is detected.
---@param key string
---@param callback openmw.async.Callback returning the new value of the action, and taking as arguments: frame time in seconds, value of the function, value of the first dependency action, ...
---@param dependencies string[]
function input.bindAction(key, callback, dependencies) end

---Registers a function to be called whenever the action's value changes
---@param key string
---@param callback openmw.async.Callback takes the new action value as the only argument
function input.registerActionHandler(key, callback) end

---Returns the value of a Boolean action
---@param key string
---@return boolean
function input.getBooleanActionValue(key) end

---Returns the value of a Number action
---@param key string
---@return number
function input.getNumberActionValue(key) end

---Returns the value of a Range action
---@param key string
---@return number
function input.getRangeActionValue(key) end

---Map of all currently registered triggers
---@type table<string, openmw.input.TriggerInfo>
input.triggers = nil

---Registers a new input trigger. The key must be unique
---@param info openmw.input.TriggerInfo
function input.registerTrigger(info) end

---Registers a function to be called whenever the trigger activates
---@param key string
---@param callback openmw.async.Callback takes the new action value as the only argument
function input.registerTriggerHandler(key, callback) end

---Activates the trigger with the given key
---@param key string
function input.activateTrigger(key) end

return input
