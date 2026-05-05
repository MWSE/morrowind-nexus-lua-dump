local I = require("openmw.interfaces")
local recordId
if I.Controls or I.AI then
    recordId = require('openmw.self').recordId
end

local mStore = require('scripts.MRF.config.store')

return function(str)
    if not mStore.settings.debugMode.value then return end
    if recordId then
        print(string.format("DEBUG (%s): %s", recordId, str))
    else
        print("DEBUG: " .. str)
    end
end