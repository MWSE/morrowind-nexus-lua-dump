---@meta

-- This file was mechanically drafted from files/lua_api/openmw/storage.lua.
-- It uses LuaLS/LLS annotations and stub bodies only; runtime behavior is provided by OpenMW.
-- OpenMW script contexts: global|menu|local|player|load

---Contains functions to work with permanent Lua storage.
---local storage = require('openmw.storage')
---local myModData = storage.globalSection('MyModExample')
---myModData:set("someVariable", 1.0)
---myModData:set("anotherVariable", { exampleStr='abc', exampleBool=true })
---local async = require('openmw.async')
---myModData:subscribe(async:callback(function(section, key)
---end))
---@class openmw.storage: openmw.storage.Global, openmw.storage.PlayerMenu
local storage = {}

---`storage.LIFE_TIME`
---@class openmw.storage.LifeTime
---@field Persistent number "0" Data is stored for the whole game session and remains on disk after quitting the game
---@field GameSession number "1" Data is stored for the whole game session
---@field Temporary number "2" Data is stored until script context reset
local LifeTime = {}

---A map `key -> value` that represents a storage section.
---@class openmw.storage.StorageSection
---@field get fun(self: openmw.storage.StorageSection, key: string): any Get a value by a string key; if the value is a table it is readonly.
---@field getCopy fun(self: openmw.storage.StorageSection, key: string): any Get a value by a string key; if the value is a table it returns a copy.
---@field subscribe fun(self: openmw.storage.StorageSection, callback: openmw.async.Callback) Subscribe to changes in this section.
---@field asTable fun(self: openmw.storage.StorageSection): table Copy all values and return them as a table.
local StorageSection = {}

---A mutable map `key -> value` that represents a storage section.
---@class openmw.storage.MutableStorageSection: openmw.storage.StorageSection
---@field reset fun(self: openmw.storage.MutableStorageSection, values?: table) Remove all existing values and assign values from given table.
---@field removeOnExit fun(self: openmw.storage.MutableStorageSection) Make the whole section temporary.
---@field setLifeTime fun(self: openmw.storage.MutableStorageSection, lifeTime: openmw.storage.LifeTime) Set the lifetime of given storage section.
---@field set fun(self: openmw.storage.MutableStorageSection, key: string, value: any) Set a value by a string key.
local MutableStorageSection = {}

---Common storage module surface valid in every script context.
---@class openmw.storage.All
---@field LIFE_TIME openmw.storage.LifeTime Possible LifeTime values
---@field globalSection fun(sectionName: string): openmw.storage.StorageSection Get a section of the global storage.
local StorageAll = {}

---Global-script storage module surface.
---@class openmw.storage.Global: openmw.storage.All
---@field globalSection fun(sectionName: string): openmw.storage.MutableStorageSection Get a mutable section of the global storage.
---@field allGlobalSections fun(): table<string, openmw.storage.MutableStorageSection> Get all global sections as a table.
local StorageGlobal = {}

---Player/menu-script storage module surface.
---@class openmw.storage.PlayerMenu: openmw.storage.All
---@field globalSection fun(sectionName: string): openmw.storage.StorageSection Get a read-only section of the global storage.
---@field playerSection fun(sectionName: string): openmw.storage.MutableStorageSection Get a section of the player storage.
---@field allPlayerSections fun(): table<string, openmw.storage.MutableStorageSection> Get all player sections as a table.
local StoragePlayerMenu = {}

---@alias openmw.storage.Load openmw.storage.All
---@alias openmw.storage.Local openmw.storage.All
---@alias openmw.storage.Player openmw.storage.PlayerMenu
---@alias openmw.storage.Menu openmw.storage.PlayerMenu
---@alias openmw.storage.Runtime openmw.storage.All

---Possible LifeTime values
---@type openmw.storage.LifeTime
storage.LIFE_TIME = nil
StorageAll.LIFE_TIME = nil

---Get a section of the global storage; can be used by any script, but only global scripts can change values.
---Menu scripts can only access it when a game is running.
---Creates the section if it doesn't exist.
---@param sectionName string
---@return openmw.storage.StorageSection
function StorageAll.globalSection(sectionName) end

---Get a section of the global storage; can be used by any script, but only global scripts can change values.
---Menu scripts can only access it when a game is running.
---Creates the section if it doesn't exist.
---@param sectionName string
---@return openmw.storage.MutableStorageSection
function StorageGlobal.globalSection(sectionName) end

---Get a section of the global storage; can be used by any script, but only global scripts can change values.
---Menu scripts can only access it when a game is running.
---Creates the section if it doesn't exist.
---@param sectionName string
---@return openmw.storage.StorageSection
function storage.globalSection(sectionName) end

---Get a section of the player storage; can only be used by player and menu scripts.
---Creates the section if it doesn't exist.
---@param sectionName string
---@return openmw.storage.MutableStorageSection
function StoragePlayerMenu.playerSection(sectionName) end

---Get a section of the player storage; can only be used by player and menu scripts.
---Creates the section if it doesn't exist.
---@param sectionName string
---@return openmw.storage.MutableStorageSection
function storage.playerSection(sectionName) end

---Get all global sections as a table; can be used by global scripts only.
---Note that adding/removing items to the returned table doesn't create or remove sections.
---@return table<string, openmw.storage.MutableStorageSection>
function StorageGlobal.allGlobalSections() end

---Get all global sections as a table; can be used by global scripts only.
---Note that adding/removing items to the returned table doesn't create or remove sections.
---@return table<string, openmw.storage.MutableStorageSection>
function storage.allGlobalSections() end

---Get all player sections as a table; can only be used by player and menu scripts.
---Note that adding/removing items to the returned table doesn't create or remove sections.
---@return table<string, openmw.storage.MutableStorageSection>
function StoragePlayerMenu.allPlayerSections() end

---Get all player sections as a table; can only be used by player and menu scripts.
---Note that adding/removing items to the returned table doesn't create or remove sections.
---@return table<string, openmw.storage.MutableStorageSection>
function storage.allPlayerSections() end

---Get a value by a string key; if the value is a table it is readonly.
---@param key string
---@return any
function StorageSection:get(key) end

---Get a value by a string key; if the value is a table it returns a copy.
---@param key string
---@return any
function StorageSection:getCopy(key) end

---Subscribe to changes in this section.
---First argument of the callback is the name of the section (so one callback can be used for different sections).
---The second argument is the changed key (or `nil` if `reset` was used and all values were changed at the same time)
---@param callback openmw.async.Callback
function StorageSection:subscribe(callback) end

---Copy all values and return them as a table.
---@return table
function StorageSection:asTable() end

---Remove all existing values and assign values from given (the arg is optional) table.
---This function can not be used for a global storage section from a local script.
---Note: `section:reset()` removes the section.
---@param values? table (optional) New values
function MutableStorageSection:reset(values) end

---(DEPRECATED, use `setLifeTime(openmw.storage.LIFE_TIME.Temporary)`) Make the whole section temporary: will be removed on exit or when load a save.
---Temporary sections have the same interface to get/set values, the only difference is they will not
---be saved to the permanent storage on exit.
---This function can be used for a global storage section from a global script or for a player storage section from a player or menu script.
---local storage = require('openmw.storage')
---local myModData = storage.globalSection('MyModExample')
---myModData:removeOnExit()
function MutableStorageSection:removeOnExit() end

---Set the lifetime of given storage section.
---New sections initially have a Persistent lifetime.
---This function can be used for a global storage section from a global script or for a player storage section from a player or menu script.
---local storage = require('openmw.storage')
---local myModData = storage.globalSection('MyModExample')
---myModData:setLifeTime(storage.LIFE_TIME.Temporary)
---@param lifeTime openmw.storage.LifeTime Section life time
function MutableStorageSection:setLifeTime(lifeTime) end

---Set a value by a string key; can not be used for global storage from a local script.
---@param key string
---@param value any
function MutableStorageSection:set(key, value) end

return storage
