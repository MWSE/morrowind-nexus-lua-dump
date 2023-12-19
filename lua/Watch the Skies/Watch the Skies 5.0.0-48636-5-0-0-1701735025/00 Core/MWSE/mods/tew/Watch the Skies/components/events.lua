local config = require("tew.Watch the Skies.config")

local services = {
	particleMesh = {
		init = function()
			local particleMesh = require("tew.Watch the Skies.services.particleMesh")
			particleMesh.init()
			event.register(tes3.event.weatherTransitionStarted, particleMesh.particleMeshChecker, { priority = -250 })
			event.register(tes3.event.weatherTransitionFinished, particleMesh.particleMeshChecker, { priority = -250 })
			event.register(tes3.event.weatherChangedImmediate, particleMesh.particleMeshChecker, { priority = -250 })
			event.register(tes3.event.loaded, particleMesh.particleMeshChecker, { priority = -250 })
			event.register(tes3.event.enterFrame, particleMesh.reColourParticleMesh)
		end,
	},
	skyTexture = {
		init = function()
			local skyTexture = require("tew.Watch the Skies.services.skyTexture")
			skyTexture.init()
			event.register(tes3.event.loaded, skyTexture.startTimer)
		end,
	},
	dynamicWeatherChanges = {
		init = function()
			local dynamicWeatherChanges = require("tew.Watch the Skies.services.dynamicWeatherChanges")
			dynamicWeatherChanges.init()
			event.register(tes3.event.loaded, dynamicWeatherChanges.startTimer)
		end,
	},
	particleAmount = {
		init = function()
			local particleAmount = require("tew.Watch the Skies.services.particleAmount")
			particleAmount.init()
			event.register(tes3.event.loaded, particleAmount.startTimer)
		end,
	},
	cloudSpeed = {
		init = function()
			local cloudSpeed = require("tew.Watch the Skies.services.cloudSpeed")
			cloudSpeed.init()
		end,
	},
	seasonalWeather = {
		init = function()
			local seasonalWeather = require("tew.Watch the Skies.services.seasonalWeather")
			event.register(tes3.event.loaded, seasonalWeather.startTimer)
		end,
	},
	seasonalDaytime = {
		init = function()
			local seasonalDaytime = require("tew.Watch the Skies.services.seasonalDaytime")
			event.register(tes3.event.loaded, seasonalDaytime.startTimer)
		end,
	},
	interiorTransitions = {
		init = function()
			local interiorTransitions = require("tew.Watch the Skies.services.interiorTransitions")
			event.register(tes3.event.cellChanged, interiorTransitions.onCellChanged, { priority = -150 })
		end,
	},
}

for serviceName, service in pairs(services) do
	if config[serviceName] then
		service.init()
	end
end
