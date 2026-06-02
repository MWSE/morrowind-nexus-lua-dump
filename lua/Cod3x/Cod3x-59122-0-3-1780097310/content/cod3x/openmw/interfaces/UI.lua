---@meta

-- Dedicated LuaLS stub for require("openmw.interfaces").UI.
-- Source: files/data/scripts/omw/ui.lua
-- Runtime availability depends on script context, OpenMW version, and active content files.

-- OpenMW script contexts: player

---@class openmw.interfaces.UI
---@field version number
---@field MODE table
---@field WINDOW table
---@field modes any
local UI = {}

---Interface version
---@type number
UI.version = nil

---All available UI modes.
---Use `view(I.UI.MODE)` in `luap` console mode to see the list.
---@type table
UI.MODE = nil

---All windows.
---Use `view(I.UI.WINDOW)` in `luap` console mode to see the list.
---@type table
UI.WINDOW = nil

---Stack of currently active modes
---@type any
UI.modes = nil

---Register new implementation for the window with given name; overrides previous implementation.
---Adding new windows is not supported yet. At the moment it is only possible to override built-in windows.
---@param windowName string
---@param showFn fun(...): any Callback that will be called when the window should become visible
---@param hideFn fun(...): any Callback that will be called when the window should be hidden
function UI.registerWindow(windowName, showFn, hideFn) end

---Returns windows that can be shown in given mode.
---@param mode string
---@return table
function UI.getWindowsForMode(mode) end

---Get current mode (nil if all windows are closed), equivalent to `I.UI.modes[#I.UI.modes]`
---@return string
function UI.getMode() end

---Drop all active modes and set mode.
---I.UI.setMode('Interface', {windows = {'Map'}})
---@param mode? string (optional) New mode
---@param options? table (optional) Table with keys 'windows' and/or 'target' (see example).
function UI.setMode(mode, options) end

---Add mode to stack without dropping other active modes.
---I.UI.addMode('Barter', {target = actor})
---@param mode string New mode
---@param options? table (optional) Table with keys 'windows' and/or 'target' (see example).
function UI.addMode(mode, options) end

---Remove the specified mode from active modes.
---@param mode string Mode to drop
function UI.removeMode(mode) end

---Set whether the mode should pause the game.
---@param mode string Mode to configure
---@param shouldPause boolean
function UI.setPauseOnMode(mode, shouldPause) end

---Set whether the UI should be visible.
---@param showHud boolean
function UI.setHudVisibility(showHud) end

---Returns if the player HUD is visible or not
---@return boolean
function UI.isHudVisible() end

---Returns if the given window is visible or not
---@param windowName string
---@return boolean
function UI.isWindowVisible(windowName) end

---Shows a message as an interactive message box pausing the game, with a single button with the localized text OK.
---TODO
---registerHudElement = function(name, showFn, hideFn) end,
---showHudElement = function(name, bool) end,
---hudElements,  -- map from element name to its visibility
---@param message string Message to display
---@param options table Options (none yet)
function UI.showInteractiveMessage(message, options) end

return UI
