local core = require('openmw.core')
local I = require("openmw.interfaces")
local storage = require('openmw.storage')
local ui = require('openmw.ui')

local mDef = require('scripts.skill-evolution.config.definition')
local mWindows = require("scripts.skill-evolution.ui.windows")

local L = core.l10n(mDef.MOD_NAME)

local module = {}

module.check = function(incompatiblePlugins, requiredPlugins, requiredExclusivePlugins)
    if not mDef.isOpenMW50 then
        ui.create(mWindows.showErrorWindow(L("openMWRequired")))
        return false
    end

    local plugins = {}
    for i = 1, #incompatiblePlugins do
        if core.contentFiles.has(incompatiblePlugins[i]) then
            table.insert(plugins, incompatiblePlugins[i])
        end
    end
    if #plugins > 0 then
        ui.create(mWindows.showErrorWindow(L("pluginErrorPlugins"), L("pluginErrorNotCompatible"), plugins))
        return false
    end

    plugins = {}
    for i = 1, #requiredPlugins do
        if not core.contentFiles.has(requiredPlugins[i]) then
            table.insert(plugins, requiredPlugins[i])
        end
    end
    if #plugins > 0 then
        ui.create(mWindows.showErrorWindow(L("pluginErrorPlugins"), L("pluginErrorRequired"), plugins))
        return false
    end

    if requiredExclusivePlugins then
        local requiredExclusiveCount = 0
        for i = 1, #requiredExclusivePlugins do
            requiredExclusiveCount = requiredExclusiveCount + (core.contentFiles.has(requiredExclusivePlugins[i]) and 1 or 0)
        end
        if requiredExclusiveCount ~= 1 then
            ui.create(mWindows.showErrorWindow(
                    L("pluginErrorPlugins"),
                    requiredExclusiveCount == 0 and L("pluginErrorMissingOneOf") or L("pluginErrorTooMany"), requiredExclusivePlugins))
            return false
        end
    end
    return true
end

module.isQuickTrainUiEnabled = function()
    return I.TrainingLog_TWin and storage.playerSection("SettingsQuicktrain"):get("enableTrainingUIReplace")
end

return module
