local async = require('openmw.async')

local mStore = require('scripts.FairCare.config.store')

local doLog = mStore.groups.global.get("debugMode")

mStore.groups.global.get():subscribe(async:callback(function(_, key)
    if key == "debugMode" then
        doLog = mStore.groups.global.get("debugMode")
    end
end))

return function(str)
    if doLog then
        print("DEBUG: " .. str)
    end
end
