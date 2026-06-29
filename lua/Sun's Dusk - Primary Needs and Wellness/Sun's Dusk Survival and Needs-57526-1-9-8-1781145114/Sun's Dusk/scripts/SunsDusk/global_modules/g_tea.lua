-- Tea Brewing

-- ======================================
-- Teapot World Swap
-- ======================================

-- replace a world object's record at the same position/rotation/owner
local function swapWorldRecord(obj, newId)
	local cell  = obj.cell
	local pos   = obj.position
	local rot   = obj.rotation
	local owner = obj.owner
	-- drop stale vfx tied to the doomed object before swap
	if saveData.consumableVfx[obj.id] then
		G_cleanupVfxEntry(saveData.consumableVfx[obj.id])
		saveData.consumableVfx[obj.id] = nil
	end
	obj:remove()
	local newObj = G_createBeverage(newId, 1)
	newObj.owner.factionId   = owner.factionId
	newObj.owner.factionRank = owner.factionRank
	newObj.owner.recordId    = owner.recordId
	newObj:teleport(cell, pos, rot)
	return newObj
end

-- recover (origId, currentQ) for a teapot world object; nil if not a tracked vessel
local function teapotState(teapot)
	if teapot.type == types.Potion then
		local rev = saveData.reverse[teapot.recordId]
		if not rev then return nil end
		return rev.orig, rev.q
	end
	return teapot.recordId, 0
end

-- ======================================
-- Add Water - upgrade teapot via ensurePotionFor
-- ======================================

G_eventHandlers.SunsDusk_Tea_addWaterToTeapot = function(data)
	local player = data.player
	local teapot = data.teapot
	local addQ   = data.addQ or 1
	
	if not teapot or not teapot:isValid() then return end
	
	local origId, currentQ = teapotState(teapot)
	if not origId then return end
	
	local maxQ = resolveMaxQ(origId)
	local newQ = math.min(currentQ + addQ, maxQ)
	if newQ == currentQ then return end
	
	consumeMilliliters(player, (newQ - currentQ) * G_WATER_PER_CUP, "water")
	
	local newId = ensurePotionFor(origId, newQ, "water")
	if newId then
		swapWorldRecord(teapot, newId)
	end
end

-- ======================================
-- Brew Simple - convert kettle water to tea, downgrade by amount used
-- ======================================

G_eventHandlers.SunsDusk_Tea_brewSimple = function(data)
	local player  = data.player
	local teapot  = data.teapot
	local teaType = data.teaType
	local cupRefs = data.cupRefs
	
	if not teapot or not teapot:isValid() then return end
	if teapot.type ~= types.Potion then return end
	
	local origId, kettleQ = teapotState(teapot)
	if not origId or kettleQ <= 0 then return end
	
	-- empty cups available in inventory
	local cupsAvailable = 0
	for _, item in ipairs(cupRefs) do
		if item:isValid() and item.count > 0 then
			cupsAvailable = cupsAvailable + item.count
		end
	end
	
	local brewCount = math.min(kettleQ, cupsAvailable)
	if brewCount == 0 then return end
	
	-- verify and consume one tea ingredient
	local ingredientId = G_teaIngredients[teaType]
	local inv = types.Actor.inventory(player)
	local ingredient = ingredientId and inv:find(ingredientId)
	if not ingredient or ingredient.count == 0 then return end
	ingredient:remove(1)
	
	-- remove brewCount empty cups, track cup origId -> count
	local toFill = {}
	local total = 0
	for _, item in ipairs(cupRefs) do
		if total >= brewCount then break end
		if item:isValid() and item.count > 0 then
			local cupOrigId = item.recordId
			local n = math.min(item.count, brewCount - total)
			item:remove(n)
			toFill[cupOrigId] = (toFill[cupOrigId] or 0) + n
			total = total + n
		end
	end
	
	if total == 0 then return end
	
	-- spawn tea-filled cups into the player inventory
	for cupOrigId, count in pairs(toFill) do
		local fullId = ensurePotionFor(cupOrigId, resolveMaxQ(cupOrigId), teaType)
		if fullId then
			G_createBeverage(fullId, count):moveInto(inv)
		end
	end
	
	player:sendEvent("SunsDusk_Tea_brewingCompleted", {
		replaced = total,
		teaType = teaType,
	})
	
	-- downgrade kettle by amount used
	local newQ = kettleQ - brewCount
	if newQ <= 0 then
		swapWorldRecord(teapot, origId)
	else
		local newId = ensurePotionFor(origId, newQ, "water")
		if newId then
			swapWorldRecord(teapot, newId)
		end
	end
end

-- ======================================
-- TeaMod Cup Replacement
-- ======================================

-- tea removed with 1 frame delay due to bug with magic effect application
G_eventHandlers.SunsDusk_TeaMod_replaceWorldObj = function(data)
	local obj = data.sourceObject
	if not obj or not obj:isValid() then return end
	local cell = obj.cell
	local pos = obj.position
	local rot = obj.rotation
	local cupId = data.cupId
	async:newUnsavableSimulationTimer(0.0001, function()
		if obj:isValid() then
			-- drop stale vfx tied to the doomed cup before removal
			if saveData.consumableVfx[obj.id] then
				G_cleanupVfxEntry(saveData.consumableVfx[obj.id])
				saveData.consumableVfx[obj.id] = nil
			end
			obj:remove()
		end
		world.createObject(cupId, 1):teleport(cell, pos, {rotation = rot})
	end)
end