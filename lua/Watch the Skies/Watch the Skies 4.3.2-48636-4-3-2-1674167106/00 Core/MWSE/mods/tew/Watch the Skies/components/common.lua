local common = {}
local config = require("tew.Watch the Skies.config")
local debugLogOn = config.debugLogOn
local modversion = require("tew.Watch the Skies.version")
local version = modversion.version

common.centralTimerDuration = 8

function common.debugLog(message)
    if not debugLogOn then return end

    local info = debug.getinfo(2, "Sl")
    local module = info.short_src:match("^.+\\(.+).lua$")
    local prepend = ("[Watch the Skies.%s.%s:%s]:"):format(version, module, info.currentline)
    local aligned = ("%-36s"):format(prepend)
    mwse.log(aligned .. " -- " .. string.format("%s", message))
end


return common