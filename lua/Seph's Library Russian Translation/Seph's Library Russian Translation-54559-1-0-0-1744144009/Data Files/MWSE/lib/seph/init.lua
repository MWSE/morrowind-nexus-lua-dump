if (mwse.buildDate == nil or mwse.buildDate < 20220101) then
    local message = "'Seph's Library' requires a more recent build of MWSE. Please close Morrowind and run 'MWSE-Update.exe' to update MWSE."
    event.register("enterFrame",
        function()
            tes3.messageBox{message = message, buttons = {"Okay"}}
        end,
        {doOnce = true}
    )
    print(debug.traceback(message))
    error()
end

local seph = {}

seph.Class = require("seph.class")
seph.Version = require("seph.version")
seph.Mod = require("seph.mod")
seph.Config = require("seph.config")
seph.Mcm = require("seph.mcm")
seph.Module = require("seph.module")

seph.common = require("seph.common")
seph.table = require("seph.table")
seph.math = require("seph.math")

seph.version = seph.Version{major = 1, minor = 0, patch = 0}

return seph