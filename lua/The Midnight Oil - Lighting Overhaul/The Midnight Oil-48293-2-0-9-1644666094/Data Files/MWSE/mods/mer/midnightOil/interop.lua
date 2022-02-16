local common = require("mer.midnightOil.common")
local this = {}

--[[
    add an object id to the blacklist
    Will block it from being registered as a light, candle, oil etc
]]
function this.addToBlacklist(lightId)
    common.blacklist[lightId:lower()] = true
end

function this.getCandleIds()
    return common.candle
end

return this