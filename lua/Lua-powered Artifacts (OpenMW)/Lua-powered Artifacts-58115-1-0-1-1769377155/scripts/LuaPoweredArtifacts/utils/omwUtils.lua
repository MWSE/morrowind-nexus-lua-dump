local storage = require('openmw.storage')

local settingsDebug = storage.globalSection('SettingsLuaPoweredArtifacts_debug')

function Log(message)
    if settingsDebug:get("log") then
        print(message)
    end
end
