---@omw-context all
local modInfo = require('scripts.canttouchthis.modinfo')

local function stringToKey(suffix)
    return ('%s_%s'):format(modInfo.modKey, suffix)
end

local function keyToDefault(key)
    local defaultKey = key:gsub(modInfo.modKey .. "_", "")
    defaultKey = defaultKey:gsub("Key", "Default")
    return defaultKey
end

local SettingsConstants = {}

--read Setting with fallback
SettingsConstants.readSetting = function(settings, key)
    local value = settings:get(key)
    if value == nil then
        value = SettingsConstants[keyToDefault(key)]
    end
    return value
end

SettingsConstants.keyToLocal = function(key)
    local localName = key:gsub(modInfo.modKey .. "_", "")
    return localName:gsub("Key", "")
end


SettingsConstants.settingsStorageKey                 = ("Settings_%s"):format(stringToKey("settingsStorageKey"))
SettingsConstants.playMissAnimationsForPlayerKey     = stringToKey("playMissAnimationsForPlayerKey")
SettingsConstants.playMissAnimationsForPlayerDefault = false

return SettingsConstants
