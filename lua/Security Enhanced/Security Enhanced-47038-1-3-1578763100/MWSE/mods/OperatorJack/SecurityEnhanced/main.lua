local config = require("OperatorJack.SecurityEnhanced.config")
local lockpick = require("OperatorJack.SecurityEnhanced.lockpick")
local probe = require("OperatorJack.SecurityEnhanced.probe")

-- Register the mod config menu (using EasyMCM library).
event.register("modConfigReady", function()
    require("OperatorJack.SecurityEnhanced.mcm")
end)

local function initialized()
    lockpick.registerEvents()
    probe.registerEvents()

    print("[Security Enhanced: INFO] Security Enhanced Initialized")
end

event.register("initialized", initialized)