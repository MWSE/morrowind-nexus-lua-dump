local core = require("openmw.core")
local isUpdated = core.API_REVISION >= 56
local devMode = false

local devPrint = function(words)
    if devMode then
        print(words)
    end
end
return { isUpdated = isUpdated, buildDate = "March 1, 2024",print = devPrint }
