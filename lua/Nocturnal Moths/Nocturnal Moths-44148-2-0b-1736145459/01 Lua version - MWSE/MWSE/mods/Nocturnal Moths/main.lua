local logger = require("logging.logger")

-- We directly index into the "config" table in the configlib module.
local config = require("Nocturnal Moths.config")


local log = logger.new({
	name = "Nocturnal Moths",
	logLevel = config.logLevel,
})

local EffectManager = require("Nocturnal Moths.EffectManager")
dofile("Nocturnal Moths.mcm")


local effectManager = EffectManager:new()

local function update()
	effectManager:update()
end
event.register(tes3.event.simulate, update)

---@param e itemDroppedEventData
local function onItemDropped(e)
	effectManager:onItemDropped(e)
end
event.register(tes3.event.itemDropped, onItemDropped)

---@param e referenceDeactivatedEventData|activateEventData
local function removeMoths(e)
	local reference = e.reference or e.target
	effectManager:detachMothEffect(reference)
end
event.register(tes3.event.activate, removeMoths, { priority = -330 }) -- Remove moths if a lantern is picked up.
event.register(tes3.event.referenceDeactivated, removeMoths) -- Some safety cleanup.

local function onCellChanged()
	effectManager:onCellChanged()
end
event.register(tes3.event.cellChanged, onCellChanged)

event.register(tes3.event.keyDown, function(e)
	if not tes3.isKeyEqual({ actual = e, expected = { keyCode = tes3.scanCode.p }}) then return end
	for ref, moths in pairs(effectManager.activeEffects) do
		log:debug("%q (%s): %s", ref, ref.cell.id, moths.name)
	end
end)


-- Midnight Oil compatibility
---@param e MidnightOil.LightToggleEventData
local function onLanternOn(e)
	-- Midnight Oil spawns a new light reference to turn the light on.
	effectManager:applyMothEffect(e.reference)
end
event.register("MidnightOil:TurnedLightOn", onLanternOn)
event.register("MidnightOil:RemovedLight", removeMoths)
