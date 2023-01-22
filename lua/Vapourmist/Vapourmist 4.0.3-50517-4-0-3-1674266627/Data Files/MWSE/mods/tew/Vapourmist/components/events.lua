-- Events declarations
-->>>---------------------------------------------------------------------------------------------<<<--

local config = require("tew.Vapourmist.config")

local services = {
	clouds = {
		init = function()
			local clouds = require("tew.Vapourmist.services.clouds")
			event.register("VAPOURMIST:enteredInterior", clouds.detachAll)
			event.register(tes3.event.loaded, clouds.onLoaded)
			event.register(tes3.event.cellChanged, clouds.conditionCheck)
			event.register(tes3.event.weatherChangedImmediate, clouds.onWeatherChanged)
			event.register(tes3.event.weatherTransitionStarted, clouds.onWeatherChanged)
			event.register(tes3.event.weatherTransitionFinished, clouds.onWeatherChanged)
			event.register(tes3.event.uiActivated, clouds.onWaitMenu, { filter = "MenuTimePass"})
		end
	},
	mistShader = {
		init = function()
			local mistShader = require("tew.Vapourmist.services.mistShader")
			event.register("VAPOURMIST:enteredInterior", mistShader.removeMist)
			event.register(tes3.event.loaded, mistShader.onLoaded)
			event.register(tes3.event.cellChanged, mistShader.conditionCheck)
			event.register(tes3.event.weatherChangedImmediate, mistShader.onWeatherChangedImmediate)
			event.register(tes3.event.weatherTransitionStarted, mistShader.onWeatherChanged)
			event.register(tes3.event.uiActivated, mistShader.onWaitMenu, { filter = "MenuTimePass"})
		end
	},
	mistNIF = {
		init = function()
			local mistNIF = require("tew.Vapourmist.services.mistNIF")
			event.register("VAPOURMIST:enteredInterior", mistNIF.detachAll)
			event.register(tes3.event.loaded, mistNIF.onLoaded)
			event.register(tes3.event.cellChanged, mistNIF.conditionCheck)
			event.register(tes3.event.weatherChangedImmediate, mistNIF.conditionCheck)
			event.register(tes3.event.weatherTransitionStarted, mistNIF.onWeatherChanged)
			event.register(tes3.event.weatherTransitionFinished, mistNIF.conditionCheck)
			event.register(tes3.event.uiActivated, mistNIF.onWaitMenu, { filter = "MenuTimePass"})
		end
	},
	interior = {
		init = function()
			local interior = require("tew.Vapourmist.services.interior")
			event.register(tes3.event.cellChanged, interior.onCellChanged)
		end
	}
}

for serviceName, service in pairs(services) do
	if config[serviceName] then
		service.init()
	end
end

-->>>---------------------------------------------------------------------------------------------<<<--

local function interiorCheck(e)
	local cell = e.cell
	if not (cell.isOrBehavesAsExterior) then
		event.trigger("VAPOURMIST:enteredInterior")
	end
end

event.register(tes3.event.cellChanged, interiorCheck)