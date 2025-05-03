local I = require('openmw.interfaces')
local feature_data = require("scripts.TamrielData.utils.feature_data")

-- Settings renderer initiator

local l10nKey = 'TamrielData'
local settingsPageKey = "Settings_TamrielData_page01Main"

local function featureToggleSetting(settingKey, default)
    return {
        key = settingKey,
        renderer = 'checkbox',
        name = settingKey,
        description = settingKey .. '_Description',
        default = default
    }
end

I.Settings.registerPage({
    key = settingsPageKey,
    l10n = l10nKey,
    name = 'TamrielData_main_modName',
    description = settingsPageKey .. "_Description",
})

local settingGroupsToRegister = {}

for _, featureParameters in pairs(feature_data) do
    if featureParameters then
        local storageId = featureParameters.settingsPlayerSectionStorageId

        if settingGroupsToRegister[storageId] == nil then
            settingGroupsToRegister[storageId] = {}
        end

        table.insert(
            settingGroupsToRegister[storageId],
            featureToggleSetting(featureParameters.settingsKey, featureParameters.settingsEnabledByDefault)
        )
    end
end

for storageGroupId, storageSettings in pairs(settingGroupsToRegister) do
    I.Settings.registerGroup({
        key = storageGroupId,
        page = settingsPageKey,
        l10n = l10nKey,
        name = storageGroupId,
        permanentStorage = true,
        settings = storageSettings,
    })
end