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

-- Remove smoke effect if a candle is picked up.
---@param e activateEventData
local function onActivate(e)
	effectManager:detachSmokeEffect(e.target, true)
end
event.register(tes3.event.activate, onActivate, { priority = -2000 })

-- Some safety cleanup
---@param e referenceDeactivatedEventData
local function onReferenceDeactivated(e)
	effectManager:detachSmokeEffect(e.reference, true)
end
event.register(tes3.event.referenceDeactivated, onReferenceDeactivated)
