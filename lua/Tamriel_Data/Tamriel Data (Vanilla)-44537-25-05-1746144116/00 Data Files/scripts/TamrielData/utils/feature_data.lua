local features = {}

-- List of features which can be turned on or off in settings or which require a specific OpenMW version.
--  > requiredLuaApi is a minimum required core.API_REVISION number.
--  > settingsKey is a unique key for this feature in l10n and script settings renderer (where it also determines the setting order).
--  > settingsPlayerSectionStorageId is a key for the player storage holding the value of feature enable setting.
--  > settingsEnabledByDefault determines whether the feature should be enabled by default or not.

features["restrictEquipment"] = {
    requiredLuaApi = 44,
    settingsPlayerSectionStorageId = "Settings_TamrielData_page01Main_group01Main",
    settingsEnabledByDefault = true,
    settingsKey = "Settings_TamrielData_page01Main_group01Main_restrictEquipment"
}
features["miscSpells"] = {
    requiredLuaApi = 71,
    settingsPlayerSectionStorageId = "Settings_TamrielData_page01Main_group02Magic",
    settingsEnabledByDefault = true,
    settingsKey = "Settings_TamrielData_page01Main_group02Magic_miscSpells"
}
features["debugLogging"] = {
    requiredLuaApi = 44,
    settingsPlayerSectionStorageId = "Settings_TamrielData_page01Main_group99Misc",
    settingsEnabledByDefault = false,
    settingsKey = "Settings_TamrielData_page01Main_group99Misc_debugLogging"
}

return features