---@meta

-- This file was mechanically drafted from files/lua_api/openmw/menu.lua.
-- It uses LuaLS/LLS annotations and stub bodies only; runtime behavior is provided by OpenMW.
-- OpenMW script contexts: menu

---Provides interfaces to interact with menu elements.
---@class openmw.menu
local menu = {}

---@class openmw.menu.STATE
---@field NoGame any
---@field Running any
---@field Ended any
local STATE = {}

---@class openmw.menu.SaveInfo
---@field description string
---@field playerName string
---@field playerLevel string
---@field timePlayed number Gameplay time for this saved game. Note: available even with [time played](../modding/settings/saves.html#timeplayed) turned off
---@field creationTime number Time at which the game was saved, as a timestamp in seconds. Can be passed as the second argument to `os.data`.
---@field contentFiles string[]
local SaveInfo = {}

---All possible game states returned by menu.getState
---@type openmw.menu.STATE
menu.STATE = nil

---Current game state
---@return openmw.menu.STATE
function menu.getState() end

---Start a new game
function menu.newGame() end

---Load the game from a save slot
---@param directory string name of the save directory (e. g. character)
---@param slotName string name of the save slot
function menu.loadGame(directory, slotName) end

---Delete a saved game
---@param directory string name of the save directory (e. g. character)
---@param slotName string name of the save slot
function menu.deleteGame(directory, slotName) end

---Current save directory
---@return string
function menu.getCurrentSaveDir() end

---Save the game
---@param description string human readable description of the save
---@param slotName string name of the save slot
function menu.saveGame(description, slotName) end

---All the saves for the given directory
---@param directory string name of the save directory (e. g. character)
---@return table<string, openmw.menu.SaveInfo> map with save filenames as keys
function menu.getSaves(directory) end

---List of all available saves, grouped by directory
---@return table<string, table<string, openmw.menu.SaveInfo>> map with directory names as keys, returning maps with save filenames as keys
function menu.getAllSaves() end

---Exit the game
function menu.quit() end

return menu
