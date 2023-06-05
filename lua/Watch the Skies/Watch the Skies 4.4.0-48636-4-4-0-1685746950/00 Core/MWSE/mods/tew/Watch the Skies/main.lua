local util = require("tew.Watch the Skies.util")
local metadata = toml.loadMetadata("Watch the Skies")

local function init()
	if not (metadata) then
		util.metadataMissing()
	else
		dofile("Data Files\\MWSE\\mods\\tew\\Watch the Skies\\components\\events.lua")
		mwse.log(string.format("[Watch the Skies] Version %s initialised.", metadata.package.version))
	end
end

event.register(tes3.event.initialized, init, { priority = -150 })

-- Registers MCM menu --
event.register(tes3.event.modConfigReady, function()
	dofile("Data Files\\MWSE\\mods\\tew\\Watch the Skies\\mcm.lua")
end)
