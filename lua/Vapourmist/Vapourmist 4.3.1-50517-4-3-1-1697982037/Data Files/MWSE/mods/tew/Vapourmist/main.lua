-- Vapourmist by tewlwolow
-- Main module
-->>>---------------------------------------------------------------------------------------------<<<--

local util = require("tew.Vapourmist.components.util")
local metadata = toml.loadMetadata("Vapourmist")


local function init()
    if not (metadata) then
		util.metadataMissing()
	end
    mwse.log("[" .. metadata.package.name .."] Version " .. metadata.package.version .. " initialised.")
    dofile("Data Files\\MWSE\\mods\\tew\\Vapourmist\\components\\events.lua")
end

event.register(tes3.event.initialized, init)

-- Registers MCM menu --
event.register(tes3.event.modConfigReady, function()
    dofile("Data Files\\MWSE\\mods\\tew\\Vapourmist\\mcm.lua")
end)
