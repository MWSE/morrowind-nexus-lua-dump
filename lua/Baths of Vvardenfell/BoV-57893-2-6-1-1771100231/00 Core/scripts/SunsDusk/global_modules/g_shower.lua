-- ╭──────────────────────────────────────────────────────────────────────────╮
-- │ Shower Water Handling (Global Context)                                   │
-- ╰──────────────────────────────────────────────────────────────────────────╯

local STEP_ML = 250

local function lc(s)
	if s then
		return string.lower(s)
	end
	return s
end

-- Consume water from player inventory for filling shower
-- Uses the same pattern as liquids.lua consumeWater but reports back to player
local function showerConsumeWater(data)
	local player = data[1]
	local amountMl = data[2] or 500
	local objectId = data[3]
	local mlConsumed = consumeMilliliters(player, amountMl, "water")
	
	log(4, string.format("[Shower] Consumed %d/%d ml from player inventory", mlConsumed, amountMl))
	
	-- Report back to player
	player:sendEvent("SunsDusk_Shower_waterConsumed", {consumed = mlConsumed, objectId = objectId})
end

G_eventHandlers.SunsDusk_Shower_consumeWater = showerConsumeWater
