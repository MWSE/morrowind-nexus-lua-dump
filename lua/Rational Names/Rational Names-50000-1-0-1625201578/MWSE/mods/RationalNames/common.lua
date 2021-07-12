local modInfo = require("RationalNames.modInfo")
local config = require("RationalNames.config")

local this = {}

this.logMsg = function(msg)
    if config.logging then
        mwse.log("%s %s", modInfo.modVersion, msg)
    end
end

return this