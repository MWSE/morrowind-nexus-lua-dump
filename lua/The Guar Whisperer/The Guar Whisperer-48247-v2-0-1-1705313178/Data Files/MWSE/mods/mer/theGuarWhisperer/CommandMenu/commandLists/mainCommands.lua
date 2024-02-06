local GuarCompanion = require("mer.theGuarWhisperer.GuarCompanion")
local common = require("mer.theGuarWhisperer.common")
local logger = common.createLogger("mainCommands")

---@class GuarWhisperer.CMenu
local this = {}
this.getTitle = function(e)
    ---@type GuarWhisperer.GuarCompanion
    local guar = e.activeCompanion
    return guar:format("Command {Name}")
end


return this