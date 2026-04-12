local I = require("openmw.interfaces")
local recordId = not I.Activation and require('openmw.self').recordId

local mStore = require('scripts.HBFS.config.store')

return function(str, warning)
    if not warning and not mStore.settings.debugMode.value then return end
    local level = warning and "WARNING" or "DEBUG"
    if recordId then
        print(string.format("%s (%s): %s", level, recordId, str))
    else
        print(string.format("%s: %s", level, str))
    end
end