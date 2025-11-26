local core = require('openmw.core')
local ui = require('openmw.ui')

local mDef = require('scripts.NCG.config.definition')
local mWindows = require("scripts.NCG.ui.windows")

local L = core.l10n(mDef.MOD_NAME)

local module = {}

module.check = function(incompatiblePlugins, requiredPlugins, requiredExclusivePlugins)
    if not mDef.isOpenMW49 then
        ui.create(mWindows.showErrorWindow(L("openMWVersionRequired")))
        return false
    end

    local plugins = {}
    for _, plugin in ipairs(incompatiblePlugins) do
        if core.contentFiles.has(plugin) then
            table.insert(plugins, plugin)
        end
    end
    if #plugins > 0 then
        ui.create(mWindows.showErrorWindow(L("pluginErrorPlugins"), L("pluginErrorNotCompatible"), plugins))
        return false
    end

    plugins = {}
    for _, plugin in ipairs(requiredPlugins) do
        if not core.contentFiles.has(plugin) then
            table.insert(plugins, plugin)
        end
    end
    if #plugins > 0 then
        ui.create(mWindows.showErrorWindow(L("pluginErrorPlugins"), L("pluginErrorRequired"), plugins))
        return false
    end

    if requiredExclusivePlugins then
        local requiredExclusiveCount = 0
        for _, plugin in ipairs(requiredExclusivePlugins) do
            requiredExclusiveCount = requiredExclusiveCount + (core.contentFiles.has(plugin) and 1 or 0)
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

return module
