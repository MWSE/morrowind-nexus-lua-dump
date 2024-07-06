local storage = require('openmw.storage')
local logging = storage.globalSection and storage.globalSection("MWR_By_Diject"):get("logging") or
    (storage.playerSection and storage.playerSection("Settings_MWR_By_Diject_generator"):get("logging") or false)

return function(...)
    if logging then
        print(...)
    end
end