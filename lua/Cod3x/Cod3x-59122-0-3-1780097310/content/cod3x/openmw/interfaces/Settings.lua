---@meta

-- Dedicated LuaLS stub for require("openmw.interfaces").Settings.
-- Source: files/data/scripts/omw/settings/player.lua
-- Runtime availability depends on script context, OpenMW version, and active content files.

-- OpenMW script contexts: global|menu|player

----- In a player script
---local storage = require('openmw.storage')
---local I = require('openmw.interfaces')
---I.Settings.registerPage {
---}
---I.Settings.registerGroup {
---}
---local playerSettings = storage.playerSection('SettingsPlayerMyMod')
---...
---ui.showMessage(playerSettings:get('Greeting'))
----- ...
----- access a setting page registered by a global script
---local globalSettings = storage.globalSection('SettingsGlobalMyMod')
---@class openmw.interfaces.Settings
---@field version number
local Settings = {}

---@class openmw.interfaces.Settings.GroupOptions
---@field key string A unique key, starts with "Settings" by convention
---@field l10n string A localization context (an argument of core.l10n)
---@field name string A key from the localization context
---@field description string A key from the localization context (optional, can be `nil`)
---@field page string Key of a page which will contain this group
---@field order number Groups within the same page are sorted by this number, or their key for equal values. Defaults to 0.
---@field permanentStorage boolean Whether the group should be stored in permanent storage, or in the save file
---@field settings openmw.interfaces.Settings.SettingOptions[] A [iterables#List](iterables.html#List) table of #SettingOptions
local GroupOptions = {}

---@class openmw.interfaces.Settings.PageOptions
---@field key string A unique key
---@field l10n string A localization context (an argument of core.l10n)
---@field name string A key from the localization context
---@field description string A key from the localization context (optional, can be `nil`)
local PageOptions = {}

---Table of setting options
---@class openmw.interfaces.Settings.SettingOptions
---@field key string A unique key
---@field name string A key from the localization context
---@field description string A key from the localization context (optional, can be `nil`)
---@field default any A default value
---@field renderer string A renderer key (see the "Setting Renderers" page)
---@field argument any An argument for the renderer
local SettingOptions = {}

---@type number
Settings.version = nil

---I.Settings.registerPage({
---})---
---Register a page to be displayed in the settings menu, available in player and menu scripts
---@param options openmw.interfaces.Settings.PageOptions
function Settings.registerPage(options) end

---I.Settings.registerRenderer('text', function(value, set, arg)
---end)
---Register a renderer, only available in menu scripts (DEPRECATED in player scripts)
---@param key string
---@param renderer fun(...): any A renderer function, receives setting's value, a function to change it and an argument from the setting options
function Settings.registerRenderer(key, renderer) end

---I.Settings.registerGroup {
---}
---Register a group to be attached to a page, available in player, menu and global scripts Note: menu scripts only allow group with permanentStorage = true, but can render the page before a game is loaded!
---@param options openmw.interfaces.Settings.GroupOptions
function Settings.registerGroup(options) end

---Change the renderer argument of a setting available both in player, menu and global scripts
---@param groupKey string A settings group key
---@param settingKey string A setting key
---@param argument any A renderer argument
function Settings.updateRendererArgument(groupKey, settingKey, argument) end

return Settings
