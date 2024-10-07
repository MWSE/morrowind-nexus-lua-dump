I = require("openmw.interfaces")
T = require('openmw.types')

AddItem = require('scripts.StoreIngredients.fn').AddItem
Storage = require('openmw.storage')
RingRecordId = require('scripts.StoreIngredients.fn').Symbol.ring_of_ingredients


-- local function inventory(e)
-- 	if e.type == T.Container then return T.Container.inventory(e) end
-- 	-- if e.type == T.Actor then return T.Actor.inventory(e) end
-- 	-- if e.type == T.NPC then return T.Actor.inventory(e) end
-- 	-- if e.type == T.Creature then return T.Actor.inventory(e) end
-- 	-- return e
-- 	return T.Actor.inventory(e)
-- end

local function inventory(e)
	if e == nil then return nil end
	if e.type == T.Container then
		return T.Container.inventory(e)
	end
	if (e.type == T.Player) or
		(e.type == T.Actor) or
		(e.type == T.NPC) or
		(e.type == T.Creature) then
		return T.Actor.inventory(e)
	end
	print('ERROR inventory -> nil. unhandled type = ' .. tostring(e.type))
	return nil
end

local function move(from, to)
	local fromi = inventory(from)
	local toi = inventory(to)
	if fromi == nil or toi == nil then
		print('INVALID MOVE')
		return
	end
	local cStacks = 0
	local cMoved = 0
	if toi and toi:find(RingRecordId) then
		for _, e in ipairs(fromi:getAll(T.Ingredient)) do
			e:moveInto(toi)
			cStacks = cStacks + 1
			cMoved = cMoved + e.count
		end
	else
		-- print( 'ring not in destination?' )
	end

	require('openmw.async'):newUnsavableSimulationTimer(2, function()
		local enc = string.format('%.1f', T.Container.encumbrance(to))
		local cap = T.Container.capacity(to)
		print(string.format('moved %d stacks with %d items, container weight: %s / %s (capacity)',
			cStacks, cMoved, enc, cap))
	end)
end

local isHalted = false

local function moveIngredients(data)
	if not isHalted then
		if data.toPlayer then
			move(data.container, data.actor)
		else
			move(data.actor, data.container)
		end
	end
end

local function removeRing(n)
	local Pc = require('scripts.StoreIngredients.fn').Player()
	local itm = T.Actor.inventory(Pc):find(RingRecordId)
	if itm.count > 1 then
		itm:remove(n)
	end
end

local function remove1Ring() removeRing(1) end

return {
	interfaceName  = 'StoreIngredientsRing',
	interface      = {
		removeRing = removeRing,
	},

	eventHandlers  = {
		toxStoreIngredients = moveIngredients,
		toxRemove1Ring = remove1Ring,
		toxStoreIngredientsHalt = function(data) isHalted = data.isHalted end,
	},

	engineHandlers = {
		onInit = function()
			require('openmw.async'):newUnsavableSimulationTimer(2, function()
				local Pc = require('scripts.StoreIngredients.fn').Player()
				if Pc then
					AddItem(RingRecordId, 1, Pc)
					print('added', RingRecordId)
				end
			end)
		end,
	},
}
