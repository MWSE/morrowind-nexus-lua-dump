-- Vapourmist by tewlwolow
-- Main module
-->>>---------------------------------------------------------------------------------------------<<<--

local version = require("tew.Vapourmist.version")
local VERSION = version.version

local function init()
    mwse.log("[Vapourmist] Version " .. VERSION .. " initialised.")
    dofile("Data Files\\MWSE\\mods\\tew\\Vapourmist\\components\\events.lua")
end

event.register(tes3.event.initialized, init)

-- Registers MCM menu --
event.register(tes3.event.modConfigReady, function()
    dofile("Data Files\\MWSE\\mods\\tew\\Vapourmist\\mcm.lua")
end)
