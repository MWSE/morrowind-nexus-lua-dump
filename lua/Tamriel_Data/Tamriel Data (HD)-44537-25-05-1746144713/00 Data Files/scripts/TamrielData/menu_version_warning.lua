local menu = require('openmw.menu')
if menu.getState() ~= menu.STATE.NoGame then
    return
end

local ui = require('openmw.ui')
local core = require('openmw.core')
local l10n = core.l10n("TamrielData")
local feature_data = require("scripts.TamrielData.utils.feature_data")
local version_check = require("scripts.TamrielData.utils.version_check")

local function listEnabledButUnsupportedFeatures()
    local result = {}
    for featureName, _ in pairs(feature_data) do
        if version_check.isFeatureEnabled(featureName) and not version_check.isFeatureSupported(featureName) then
            table.insert(result, featureName)
        end
    end
    return result
end

if core.contentFiles and not core.contentFiles.has("Tamriel_Data.esm") then
    error(string.format("[%s]: %s", l10n("TamrielData_main_modName"), l10n("TamrielData_main_noEsmLoaded")))
end

local wrongFeatures = listEnabledButUnsupportedFeatures()
if #wrongFeatures > 0 then
    for _, name in pairs(wrongFeatures) do
        print(string.format(
            "[%s][%s]: %s",
            l10n("TamrielData_main_modName"),
            name,
            l10n("TamrielData_main_luaApiTooLow", { requiredRevision = feature_data[name].requiredLuaApi, currentRevision = core.API_REVISION })))
    end
    ui.showMessage(string.format("%s: %s", l10n("TamrielData_main_modName"), l10n("TamrielData_main_publicVersionMismatchWarning")))
end