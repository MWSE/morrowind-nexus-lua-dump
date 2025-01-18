local logger = require("logging.logger")

-- We directly index into the "config" table in the configlib module.
local config = require("Candle Smoke.config").config

local log = logger.new({
	name = "Candle Smoke",
	logLevel = config.logLevel,
})

dofile("Candle Smoke.mcm")

local EffectManager = require("Candle Smoke.EffectManager")

-- Hints:
-- Records in OpenMW Lua correspond to tes3object types
-- Objects in OpenMW Lua correspond to tes3reference

local effectManager = EffectManager:new()

local function updateSmokeEffect()
	effectManager:onCellChange()
end
event.register("Candle Smoke: update effects", updateSmokeEffect)
event.register(tes3.event.cellChanged, updateSmokeEffect)

-- Apply smoke effect if the player dropped a candle
---@param e itemDroppedEventData
local function onItemDropped(e)
	effectManager:onItemDropped(e)
end
event.register(tes3.event.itemDropped, onItemDropped)


---@param e MidnightOil.LightToggleEventData
local function onToggleOn(e)
	effectManager:applyCandleSmokeEffect(e.reference, true)
end
-- Compatibility with lights tuggles on/off with Midnight Oil
event.register("MidnightOil:TurnedLightOn", onToggleOn)


---@param e referenceDeactivatedEventData|activateEventData|MidnightOil.LightToggleEventData
local function removeSmoke(e)
	local reference = e.reference or e.target
	effectManager:detachSmokeEffect(reference, true)
end
-- Remove smoke effect if a candle is picked up.
event.register(tes3.event.activate, removeSmoke, { priority = -2000 })
-- Some safety cleanup
event.register(tes3.event.referenceDeactivated, removeSmoke)
-- Compatibility with lights turned of with Midnight Oil
event.register("MidnightOil:RemovedLight", removeSmoke)
