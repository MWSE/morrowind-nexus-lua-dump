local I = require("openmw.interfaces")
local recordId
if I.Controls or I.AI then
    recordId = require('openmw.self').recordId
end

local mS = require('scripts.BMS.config.settings')

return function(str)
    if not mS.globalStorage:get("debugMode") then return end
    if recordId then
        print(string.format("DEBUG (%s): %s", recordId, str))
    else
        print("DEBUG: " .. str)
    end
end