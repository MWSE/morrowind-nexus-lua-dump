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
			clouds.onLoaded()
		end,
		stop = function()
			local clouds = require("tew.Vapourmist.services.clouds")
			event.unregister("VAPOURMIST:enteredInterior", clouds.detachAll)
			event.unregister(tes3.event.loaded, clouds.onLoaded)
			event.unregister(tes3.event.cellChanged, clouds.conditionCheck)
			event.unregister(tes3.event.weatherChangedImmediate, clouds.onWeatherChanged)
			event.unregister(tes3.event.weatherTransitionStarted, clouds.onWeatherChanged)
			event.unregister(tes3.event.weatherTransitionFinished, clouds.onWeatherChanged)
			event.unregister(tes3.event.uiActivated, clouds.onWaitMenu, { filter = "MenuTimePass"})
			clouds.detachAll()
		end
	},
	mistShader = {
		init = function()
			local mistShader = require("tew.Vapourmist.services.mistShader")
			local shader = require("tew.Vapourmist.components.shader")
			event.register("VAPOURMIST:enteredInterior", mistShader.removeMist)
			event.register(tes3.event.loaded, mistShader.onLoaded)
			event.register(tes3.event.cellChanged, mistShader.conditionCheck, {priority = -500})
			event.register(tes3.event.weatherChangedImmediate, mistShader.onWeatherChangedImmediate)
			event.register(tes3.event.weatherTransitionStarted, mistShader.onWeatherChanged)
			event.register(tes3.event.uiActivated, mistShader.onWaitMenu, { filter = "MenuTimePass"})
			event.register("VAPOURMIST:enteredUnderwater", shader.disableFog)
			event.register("VAPOURMIST:exitedUnderwater", shader.enableFog)
			mistShader.onLoaded()
		end,
		stop = function()
			local mistShader = require("tew.Vapourmist.services.mistShader")
			local shader = require("tew.Vapourmist.components.shader")
			event.unregister("VAPOURMIST:enteredInterior", mistShader.removeMist)
			event.unregister(tes3.event.loaded, mistShader.onLoaded)
			event.unregister(tes3.event.cellChanged, mistShader.conditionCheck, {priority = -500})
			event.unregister(tes3.event.weatherChangedImmediate, mistShader.onWeatherChangedImmediate)
			event.unregister(tes3.event.weatherTransitionStarted, mistShader.onWeatherChanged)
			event.unregister(tes3.event.uiActivated, mistShader.onWaitMenu, { filter = "MenuTimePass"})
			event.unregister("VAPOURMIST:enteredUnderwater", shader.disableFog)
			event.unregister("VAPOURMIST:exitedUnderwater", shader.enableFog)
			mistShader.removeMist()
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
			event.register("VAPOURMIST:enteredUnderwater", mistNIF.hideAll)
			event.register("VAPOURMIST:exitedUnderwater", mistNIF.unhideAll)
			mistNIF.onLoaded()
		end,
		stop = function()
			local mistNIF = require("tew.Vapourmist.services.mistNIF")
			event.unregister("VAPOURMIST:enteredInterior", mistNIF.detachAll)
			event.unregister(tes3.event.loaded, mistNIF.onLoaded)
			event.unregister(tes3.event.cellChanged, mistNIF.conditionCheck)
			event.unregister(tes3.event.weatherChangedImmediate, mistNIF.conditionCheck)
			event.unregister(tes3.event.weatherTransitionStarted, mistNIF.onWeatherChanged)
			event.unregister(tes3.event.weatherTransitionFinished, mistNIF.conditionCheck)
			event.unregister(tes3.event.uiActivated, mistNIF.onWaitMenu, { filter = "MenuTimePass"})
			event.unregister("VAPOURMIST:enteredUnderwater", mistNIF.hideAll)
			event.unregister("VAPOURMIST:exitedUnderwater", mistNIF.unhideAll)
			mistNIF.detachAll()
		end
	},
	interior = {
		init = function()
			local interior = require("tew.Vapourmist.services.interior")
			event.register(tes3.event.cellChanged, interior.onCellChanged, {priority = 500})
			event.register("VAPOURMIST:enteredUnderwater", interior.hideAll)
			event.register("VAPOURMIST:exitedUnderwater", interior.unhideAll)
			interior.onCellChanged()
		end,
		stop = function()
			local interior = require("tew.Vapourmist.services.interior")
			event.unregister(tes3.event.cellChanged, interior.onCellChanged, {priority = 500})
			event.unregister("VAPOURMIST:enteredUnderwater", interior.hideAll)
			event.unregister("VAPOURMIST:exitedUnderwater", interior.unhideAll)
			interior.removeAllFog()
		end
	}
}

for serviceName, service in pairs(services) do
	if config.modEnabled then
		if config[serviceName] then
			service.stop()
			service.init()
		end
	else
		if config[serviceName] then
			service.stop()
		end
	end
end

-->>>---------------------------------------------------------------------------------------------<<<--

local function interiorCheck(e)
	local cell = e.cell
	if not (cell.isOrBehavesAsExterior) then
		event.trigger("VAPOURMIST:enteredInterior")
	end
end

event.unregister(tes3.event.cellChanged, interiorCheck)
event.register(tes3.event.cellChanged, interiorCheck)

local underwaterPrev
---@param e simulateEventData
local function underWaterCheck(e)
	local mp = tes3.mobilePlayer
	if mp then
		if mp.isSwimming and not underwaterPrev then
			underwaterPrev = true
			event.trigger("VAPOURMIST:enteredUnderwater")
			return
		end

		if not mp.isSwimming and underwaterPrev then
			underwaterPrev = false
			event.trigger("VAPOURMIST:exitedUnderwater")
		end
	end
end
event.unregister(tes3.event.simulate, underWaterCheck)
event.register(tes3.event.simulate, underWaterCheck)


