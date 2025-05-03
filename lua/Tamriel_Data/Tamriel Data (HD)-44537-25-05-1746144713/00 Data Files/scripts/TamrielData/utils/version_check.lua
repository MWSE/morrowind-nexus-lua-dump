local core = require('openmw.core')
local storage = require('openmw.storage')
local feature_data = require("scripts.TamrielData.utils.feature_data")

local V = { }

function V.isFeatureSupported(featureName)
    return core.API_REVISION and feature_data[featureName] and core.API_REVISION >= feature_data[featureName].requiredLuaApi
end

function V.isFeatureEnabled(featureName)
    local featureSettingsStorage = feature_data[featureName] and storage.playerSection(feature_data[featureName].settingsPlayerSectionStorageId)
    return featureSettingsStorage and featureSettingsStorage:get(feature_data[featureName].settingsKey)
end

return V