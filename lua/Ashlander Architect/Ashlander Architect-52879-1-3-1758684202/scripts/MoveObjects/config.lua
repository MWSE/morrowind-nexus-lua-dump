local core = require("openmw.core")
local isUpdated = core.API_REVISION >= 76
local devMode = false

local devPrint = function(words)
    if devMode then
        print(words)
    end
end
return { isUpdated = isUpdated, buildDate = "Sept 23, 2025",print = devPrint }
