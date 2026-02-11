local async = require('openmw.async')
local I = require("openmw.interfaces")
local recordId
if I.Controls or I.AI then
    recordId = require('openmw.self').recordId
end

local mStore = require('scripts.FairCare.config.store')

local doLog = mStore.groups.global.get("debugMode")

mStore.groups.global.get():subscribe(async:callback(function(_, key)
    if key == "debugMode" then
        doLog = mStore.groups.global.get("debugMode")
    end
end))

return function(str)
    if not doLog then return end
    if recordId then
        print(string.format("DEBUG (%s): %s", recordId, str))
    else
        print("DEBUG: " .. str)
    end
end
