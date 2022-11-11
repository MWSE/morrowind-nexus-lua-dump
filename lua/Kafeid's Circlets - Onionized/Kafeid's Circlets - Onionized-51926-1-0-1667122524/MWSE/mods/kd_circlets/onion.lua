local onion = require("sb_onion.interop")
local items = require("kd_circlets.items")


local function defaultArguments(id)
	return {
	    id        = id,
        slot      = onion.slots.headband,
        exSlot    = {},
        cull      = {},
		racePos   = {
			[""] = { 2.8, 0, 0 },
			["Wood Elf"] = { 2.8, 0.2, 0 },
			["Argonian"] = { 3.5, 0.1, 0 }
		},
        raceSub   = {},
		raceScale = {
			[""] = 1,
		},
	}
end

local function setup(collection)
	for _, item in ipairs(collection) do
	    onion.register(defaultArguments(item), onion.mode.wearable)
	end
end

local function setupCirclets()
	for _, item in ipairs(items.circlets) do
		args = defaultArguments(item)
		args.racePos.Breton = { 2.8, 0.1, 0 }
		args.racePos.Nord = { 2.8, 0.1, 0 }
	    onion.register(args, onion.mode.wearable)
	end
end

local function setupDiadems()

	for _, item in ipairs(items.diadems_g) do
		local args = defaultArguments(item)
		for race, pos in pairs(args.racePos) do
			pos[1] = pos[1] - 0.4
			pos[2] = pos[2] - 4.0
		end
	    onion.register(args, onion.mode.wearable)
	end

	for _, item in ipairs(items.diadems_e) do
		local args = defaultArguments(item)
		for race, pos in pairs(args.racePos) do
			pos[1] = pos[1] - 0.4
		end
	    onion.register(args, onion.mode.wearable)
	end

	for _, item in ipairs(items.diadems_s) do
		local args = defaultArguments(item)
		for race, pos in pairs(args.racePos) do
			pos[1] = pos[1] - 0.4
			pos[2] = pos[2] + 0.3
			pos[3] = pos[3] - 0.4
		end
	    onion.register(args, onion.mode.wearable)
	end
end

local function setupCrowns()
	for _, item in ipairs(items.crowns) do
		local args = defaultArguments(item)
		for race, pos in pairs(args.racePos) do
			pos[2] = pos[2] + 0.3
		end
	    onion.register(args, onion.mode.wearable)
	end
end

local function noExSlotWhileLoading(e)
	for _, item in ipairs(items.all) do
		onion.wearables[item].exSlot = {}
	end
end

local function yesExSlotAfterLoading(e)
	for _, item in ipairs(items.all) do
		onion.wearables[item].exSlot = {tes3.armorSlot.helmet}
	end
end

local meshLookup = {}

local function setupMeshLookup()
	for _, item in pairs(items.all) do
		local mesh = tes3.getObject(item).mesh
		meshLookup[mesh] = item
	end
end

---jitRegisterOfEnchantedItem
---@param e equipEventData
local function jitRegisterOfEnchantedItem(e)
	if onion.wearables[e.item.id] then
		return
	end
	-- Discover the original item of the homebrew item by cross-checking its mesh with circlet objects
	-- This works as long as we only use each mesh once
	if e.item.mesh:startswith("KDCirclets") then
		local originalCircletId = meshLookup[e.item.mesh]
		local originalCircletWearableArgs = onion.wearables[originalCircletId]
		-- Add the item directly because we want to use the same object for both entries
		-- This way our OTHER bugfix (changing exSlots) will propagate to the enchanted circlets
		onion.wearables[e.item.id] = originalCircletWearableArgs
	end
end

local function initializedCallback(e)
	setup(items.bands)
	setup(items.chains)
	setupCirclets()
	setupDiadems()
	setupCrowns()

	-- Work around an onion bug where wearing onionized items with an exSlot causes ctd when loading save game
	-- Manually edit the wearables database so they don't have their exSlot during save loading
	event.register(tes3.event.load, noExSlotWhileLoading)
	event.register(tes3.event.loaded, yesExSlotAfterLoading)
	-- Work around bug where enchanted items (homebrew or DRIP) have a random ID and wont be recognized by onion
	-- Register new onion wearables just-in-time if they are circlet-like at time of equipping
	setupMeshLookup()
	event.register("equip", jitRegisterOfEnchantedItem, { priority = 2} )
end

event.register("initialized", initializedCallback, { priority = onion.offsetValue + 1 })

