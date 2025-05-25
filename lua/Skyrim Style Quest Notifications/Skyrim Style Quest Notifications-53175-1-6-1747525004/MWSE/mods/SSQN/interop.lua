local iconlist = require("SSQN.iconlist")
local common = require("SSQN.common")
local interop = {}

function interop.registerQIcon(id,path)
    if (iconlist[id]) then
        common.log:warn(id .. " already exists in Iconlist")
    else
        iconlist[id] = path
    end
end

function interop.registerQBlock(id)
    if (iconlist[id] == "BLOCKED") then
        common.log:warn(id .. " already exists in Blocklist")
    elseif (iconlist[id]) then
        common.log:info(id .. " will not be blocked exists in Iconlist already")
    else
        iconlist[id] = "BLOCKED"
    end
end

return interop