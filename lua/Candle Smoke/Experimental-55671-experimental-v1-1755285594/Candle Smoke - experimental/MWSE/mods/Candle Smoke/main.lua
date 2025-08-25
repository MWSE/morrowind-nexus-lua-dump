local config = require("Candle Smoke.config")
local util = require("Candle Smoke.util")

local log = mwse.Logger.new({
	name = "Candle Smoke",
	logLevel = config.logLevel,
})

dofile("Candle Smoke.mcm")

local EffectManager = require("Candle Smoke.EffectManager")

-- Hints:
-- Records in OpenMW Lua correspond to tes3object types
-- Objects in OpenMW Lua correspond to tes3reference

local effectManager = EffectManager:new()


local function updateIntensity()
	effectManager:updateEffectMaterial(util.getEmissiveColorFromConfig())
end
event.register("Candle Smoke: intensity updated", updateIntensity)

local function onCellChanged()
	timer.delayOneFrame(function(e)
		effectManager:applySmokeOnAllCandles()
	end)
end
event.register(tes3.event.cellChanged, onCellChanged)

---@param e MidnightOil.LightToggleEventData|itemDroppedEventData
local function onLightSpawned(e)
	effectManager:applyCandleSmokeEffect(e.reference)
end
-- Compatibility with lights tuggles on/off with Midnight Oil
event.register("MidnightOil:TurnedLightOn", onLightSpawned)
-- Apply smoke effect if the player dropped a candle
event.register(tes3.event.itemDropped, onLightSpawned)


---@param e referenceDeactivatedEventData|activateEventData|MidnightOil.LightToggleEventData
local function removeSmoke(e)
	local reference = e.reference or e.target
	effectManager:detachSmokeEffect(reference)
end
-- Remove smoke effect if a candle is picked up.
event.register(tes3.event.activate, removeSmoke, { priority = -330 })
-- Some safety cleanup.
event.register(tes3.event.referenceDeactivated, removeSmoke)
-- Compatibility with lights turned off with Midnight Oil.
event.register("MidnightOil:RemovedLight", removeSmoke)
