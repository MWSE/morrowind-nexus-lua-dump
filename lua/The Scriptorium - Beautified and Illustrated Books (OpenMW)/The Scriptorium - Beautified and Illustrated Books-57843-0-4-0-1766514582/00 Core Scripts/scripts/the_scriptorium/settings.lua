local storage = require('openmw.storage')
local I = require('openmw.interfaces')

local l10nKey = 'the_scriptorium'
local settingsPageKey = "TheScriptoriumMainPage"

local S = {}

local settingToStorage = {}

local function boolSetting(settingKey, default, storageForThisSetting)
    S[settingKey] = function() return storageForThisSetting:get(settingKey) end
    settingToStorage[settingKey] = storageForThisSetting
    return {
        key = settingKey,
        renderer = 'checkbox',
        name = settingKey,
        description = settingKey .. 'Description',
        default = default
    }
end

-- Register settings page
I.Settings.registerPage({
    key = settingsPageKey,
    l10n = l10nKey,
    name = 'TheScriptoriumModName',
    description = settingsPageKey .. "Description",
})

-- General settings
local generalSettingsKey = "TheScriptoriumGeneralSettings"
local storageGeneralSettings = storage.playerSection(generalSettingsKey)

I.Settings.registerGroup({
    key = generalSettingsKey,
    page = settingsPageKey,
    l10n = l10nKey,
    name = 'TheScriptoriumGeneralSettings',
    permanentStorage = true,
    settings = {
        boolSetting(
            'TheScriptoriumEnableMod',
            true,
            storageGeneralSettings),
        boolSetting(
            'TheScriptoriumEnableCalibrateMode',
            false,
            storageGeneralSettings),
    },
})

return S
