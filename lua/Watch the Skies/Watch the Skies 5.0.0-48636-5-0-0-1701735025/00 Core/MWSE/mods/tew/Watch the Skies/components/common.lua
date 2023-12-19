local common = {}
local config = require("tew.Watch the Skies.config")
local debugLogOn = config.debugLogOn
local metadata = toml.loadMetadata("Watch the Skies")

common.centralTimerDuration = 8

function common.debugLog(message)
    if not debugLogOn then return end

    local info = debug.getinfo(2, "Sl")
    local module = info.short_src:match("^.+\\(.+).lua$")
    local prepend = ("[%s.%s.%s:%s]:"):format(metadata.package.name, metadata.package.version, module, info.currentline)
    local aligned = ("%-36s"):format(prepend)
    mwse.log(aligned .. " -- " .. string.format("%s", message))
end


return common
