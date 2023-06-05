-- Happenstance Hodokinesis by tewlwolow --

local util = require("tew.Happenstance Hodokinesis.util")
local metadata = toml.loadMetadata("Happenstance Hodokinesis")

-- Initialise our mod --
local function init()
    if not (metadata) then
		util.metadataMissing()
    else
        mwse.log("[" .. metadata.package.name .."] Version " .. metadata.package.version .. " initialised.")
	end
    dofile("Data Files\\MWSE\\mods\\tew\\Happenstance Hodokinesis\\events.lua")
end

event.register(tes3.event.initialized, init)

-- Registers MCM menu --
event.register(tes3.event.modConfigReady, function()
    dofile("Data Files\\MWSE\\mods\\tew\\Happenstance Hodokinesis\\mcm.lua")
end)