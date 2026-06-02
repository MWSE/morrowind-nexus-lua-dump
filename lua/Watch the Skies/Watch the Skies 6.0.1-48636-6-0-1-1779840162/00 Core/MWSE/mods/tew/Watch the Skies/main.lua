local util = require("tew.Watch the Skies.util")
local events = require("tew.Watch the Skies.components.events")
local metadata = toml.loadMetadata("Watch the Skies")
local config = require("tew.Watch the Skies.config")

local function init()
	if not (metadata) then
		util.metadataMissing()
	else
		mwse.log(string.format("[Watch the Skies] Version %s initialised.", metadata.package.version))
	end

	if config.modEnabled then
		for serviceName, service in pairs(events.services) do
			if config[serviceName] then
				service.init()
			end
		end
	end
end

-- For TR/PT updates etc.
-- event.register(tes3.event.loaded, util.getRegionWeatherChances)

event.register(tes3.event.initialized, init, { priority = -150 })

-- Registers MCM menu --
event.register(tes3.event.modConfigReady, function()
	dofile("Data Files\\MWSE\\mods\\tew\\Watch the Skies\\mcm.lua")
end)
