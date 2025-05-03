local version_check = require("scripts.TamrielData.utils.version_check")

if not version_check.isFeatureSupported("debugLogging") then
    return
end

local l10n = require('openmw.core').l10n("TamrielData")

local DL = {}

function DL.log(text, scopeName)
    if not version_check.isFeatureEnabled("debugLogging") then return end

    print(string.format(
        "[%s][%s]: %s",
        l10n("TamrielData_main_modName"),
        scopeName or "",
        text))
end

return DL