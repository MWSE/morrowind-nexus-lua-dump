-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Cooking and Magic													  │
-- ╰──────────────────────────────────────────────────────────────────────╯
local cookingRecipeDB = require("scripts.SunsDusk.lib.cooking_recipes").recipes
local shortBits, longBits = unpack(require("scripts.SunsDusk.lib.foodBuffs"))
local foodOffsets, foodwareOffsets, soupFoodwareOffsets = unpack(require("scripts.SunsDusk.lib.foodwareOffsets"))

function toBitPositions(n, step)
	step = step or 1  -- default to standard binary (step of 1)
	n = math.floor(n / step) -- Convert magnitude to "units" based on step
	local result = {}
	local position = 1
	while n > 0 do
		if n % 2 == 1 then
			table.insert(result, position)
		end
		n = math.floor(n / 2)
		position = position + 1
	end
	return result
end


--maxlength	32

-- ──────────────────────────────────────────────────────────────────────────────── Create Stew ────────────────────────────────────────────────────────────────────────────────
local FALLBACK_MESH = "meshes/SunsDusk/contain_couldron10.nif"
local FALLBACK_ICON = "icons/SunsDusk/cooking_pot.dds"

local function createStew(data)
	local player = data[1]
	local foodData = data[2]
	local inv = types.Actor.inventory(player)
	
	local totalCount = foodData.count
	--local foodware = foodData.foodware -- "bowl", "plate", or nil
	local stewIcon = foodData.recipeIcon or FALLBACK_ICON
	local stewName = foodData.recipeName or "Stew"
	local recipeId = foodData.recipeId
	local forcedFoodware = foodData.forcedFoodware
	local innkeeper = foodData.innkeeper
	local placeAt = innkeeper and foodData.placeAt
	
	-- Determine container preference order
	local primaryType, secondaryType
	if foodData.isSoup then
		primaryType = "bowl"
		secondaryType = "plate"
	else
		primaryType = "plate"
		secondaryType = "bowl"
	end
	
	-- Group containers by mesh, tracking actual items for consumption
	-- First pass: primary container type
	-- Second pass: secondary container type (fallback)
	-- Group containers by recordId, tracking mesh for visuals
	local containerGroups = {} -- { [recordId] = { count=N, mesh=..., items={...} } }
	local totalContainers = 0
	
	local function gatherContainers(targetType)
		if not targetType then return end
		for _, item in ipairs(inv:getAll(types.Miscellaneous)) do
			if item:isValid() and item.count > 0 then
				if getFoodwareType(item) == targetType then
					local rec = types.Miscellaneous.record(item)
					local recordId = rec.id
					if not containerGroups[recordId] then
						containerGroups[recordId] = { 
							count = 0, 
							mesh = rec.model or FALLBACK_MESH, 
							items = {} 
						}
					end
					containerGroups[recordId].count = containerGroups[recordId].count + item.count
					table.insert(containerGroups[recordId].items, { item = item, available = item.count })
					totalContainers = totalContainers + item.count
				end
			end
		end
	end
	
	-- Handle forced foodware
	if forcedFoodware then
		-- Check if player has the forced foodware
		local forcedRecord = types.Miscellaneous.record(forcedFoodware)
		local forcedMesh = forcedRecord and forcedRecord.model or FALLBACK_MESH
		local forcedType = getFoodwareType(forcedFoodware)
		
		local forcedItem = inv:find(forcedFoodware)
		
		containerGroups[forcedFoodware] = { 
			count = forcedItem and forcedItem.count or 0, 
			mesh = forcedMesh, 
			items = forcedItem and {{ item = forcedItem, available = forcedItem.count }} or {}
		}
	else
		-- Gather primary type first
		gatherContainers(primaryType)
		-- If we need more, gather secondary type
		if totalContainers < totalCount then
			gatherContainers(secondaryType)
		end
	end
	
	-- Allocate requested count across container groups + fallback
	local allocations = {} -- { { mesh=..., count=..., containerRecordId=... }, ... }
	local allocated = 0
	
	if forcedFoodware then
		-- All items must use the forced foodware
		local group = containerGroups[forcedFoodware]
		table.insert(allocations, {
			mesh = group.mesh,
			count = totalCount,
			foodwareRecordId = forcedFoodware
		})
		allocated = totalCount
	else
		for recordId, group in pairs(containerGroups) do
			local toAllocate = math.min(group.count, totalCount - allocated)
			if toAllocate > 0 then
				table.insert(allocations, {
					mesh = group.mesh,
					count = toAllocate,
					foodwareRecordId = recordId
				})
				allocated = allocated + toAllocate
			end
			if allocated >= totalCount then break end
		end
		
		-- Fallback for remaining (no containers left)
		if allocated < totalCount then
			table.insert(allocations, {
				mesh = FALLBACK_MESH,
				count = totalCount - allocated,
				foodwareRecordId = nil
			})
		end
	end
	
	-- Calculate batches: min 4, max batch size = ceil(total/4)
	local maxBatchSize = math.ceil(totalCount / 4)
	local batches = {} -- { { mesh=..., count=..., foodwareRecordId=... }, ... }
	
	for _, alloc in ipairs(allocations) do
		local remaining = alloc.count
		while remaining > 0 do
			local batchCount = math.min(remaining, maxBatchSize)
			table.insert(batches, {
				mesh = alloc.mesh,
				count = batchCount,
				foodwareRecordId = alloc.foodwareRecordId
			})
			remaining = remaining - batchCount
		end
	end
	
	-- If under 4 batches, split largest until we hit 4 (or all size 1)
	while #batches < 4 do
		local largestIdx = 1
		local largestCount = batches[1].count
		for i, batch in ipairs(batches) do
			if batch.count > largestCount then
				largestIdx = i
				largestCount = batch.count
			end
		end
		
		if largestCount <= 1 then break end
		
		local half1 = math.ceil(largestCount / 2)
		local half2 = largestCount - half1
		local original = batches[largestIdx]
		batches[largestIdx] = { mesh = original.mesh, count = half1, foodwareRecordId = original.foodwareRecordId }
		table.insert(batches, { mesh = original.mesh, count = half2, foodwareRecordId = original.foodwareRecordId })
	end
	
	-- Prepare shared data
	local tmpl = types.Potion.record("sd_waterbottle_template")
	
	local infoBracket = ""
	if FOOD_NAME_INFO_BRACKETS then
		infoBracket = " [" .. math.floor(foodData.foodValue*200 + 0.5)
		if foodData.wakeValue > 0 then
			infoBracket = infoBracket .. "/" .. math.floor(foodData.drinkValue*200 + 0.5) .. "/" .. math.floor(foodData.wakeValue*200 + 0.5)
		elseif foodData.drinkValue > 0 then
			infoBracket = infoBracket .. "/" .. math.floor(foodData.drinkValue*200 + 0.5)
		end
		infoBracket = infoBracket .. "]"
	end
	local baseValue = 0
	for itemId, _ in pairs(foodData.consumedIngredients) do
		local record = types.Ingredient.records[itemId] or types.Potion.records[itemId]
		if record then
			baseValue = baseValue + record.value
		end
	end
	
	local timestamp = core.getGameTime()
	local placedFoodOnCounter = false
	-- Create records for each batch
	for _, batch in ipairs(batches) do
		-- Roll effects for this batch
		local newEffects = {}
		for uniqueId, effectData in pairs(foodData.dynamicEffects) do
			local magnitude = effectData.magnitude
			if math.random() < magnitude % 1 then
				magnitude = magnitude + 1
			end
			local step = 1
			local maxBits = longBits[uniqueId] or 0
			
			if foodData.shortBuff then
				step = 5
				maxBits = shortBits[uniqueId] or 0
				magnitude = math.floor(magnitude / 5 + 0.5) * 5
				if effectData.successfulContributors and effectData.successfulContributors > 0 then
					magnitude = math.max(5, magnitude)
				end
			else
				magnitude = math.floor(magnitude)
			end
			
			local maxMagnitude = step * (2 ^ maxBits - 1)
			magnitude = math.min(maxMagnitude, magnitude)
			
			if magnitude >= step then
				local sourcePotion = types.Potion.records[uniqueId]
				if sourcePotion then
					if foodData.shortBuff then
						table.insert(newEffects, sourcePotion.effects[math.floor(magnitude / 5)])
					else
						for _, pos in pairs(toBitPositions(magnitude, step)) do
							table.insert(newEffects, sourcePotion.effects[pos])
						end
					end
				end
			end
		end
		
		-- Recipe name with stats bracket
		local recordDraft = types.Potion.createRecordDraft({
			name     = " " .. stewName .. infoBracket,
			template = tmpl,
			model    = batch.mesh,
			icon     = stewIcon,
			weight   = 1,
			value    = baseValue,
			effects  = newEffects,
			mwscript = 'sd_loot_tracker',
		})
		
		local rec = world.createRecord(recordDraft)
		
		-- Register stew data for VFX, fresh/cold tracking, and container return
		local containerType = nil
		if recipeId and batch.mesh ~= FALLBACK_MESH then
			-- Determine the type based on the mesh used
			if batch.foodwareRecordId then
				-- Look up the actual container record to get its type
				containerType = getFoodwareType(batch.foodwareRecordId)
			end
		end
		local recipeData = recipeId and cookingRecipeDB[recipeId]
		
		if foodData.foodValue2 == 0 then
			foodData.foodValue2 = nil
		end
		if foodData.drinkValue2 == 0 then
			foodData.drinkValue2 = nil
		end
		if foodData.wakeValue == 0 then
			foodData.wakeValue = nil
		end
		if foodData.warmthValue == 0 then
			foodData.warmthValue = nil
		end
		if foodData.warmthValue2 == 0 then
			foodData.warmthValue2 = nil
		end
		
		saveData.stewRegistry[rec.id] = {
			timestamp = timestamp,
			recipeId = recipeId,
			foodwareRecordId = batch.foodwareRecordId, -- nil if no container used
			foodwareType = containerType, -- "bowl", "plate", or nil
			isSoup = recipeData and recipeData.isSoup or false,
			consumeCategory = foodData.consumeCategory,
			foodValue       = foodData.foodValue or 0,
			foodValue2      = foodData.foodValue2,
			drinkValue      = foodData.drinkValue or 0,
			drinkValue2     = foodData.drinkValue2,
			wakeValue       = foodData.wakeValue or 0,
			wakeValue2      = foodData.wakeValue2,
			warmthValue      = foodData.warmthValue,
			warmthValue2      = foodData.warmthValue2,
			isToxic         = foodData.isToxic,
			isGreenPact     = foodData.isGreenPact,
			isCookedMeal    = true,
		}
		
		local playerDbEntry = {
			timestamp = timestamp,
			recipeId = recipeId,
			--foodwareRecordId = batch.foodwareRecordId, -- nil if no container used
			--foodwareType = containerType, -- "bowl", "plate", or nil
			--isSoup = recipeData and recipeData.isSoup or false,
			consumeCategory = foodData.consumeCategory,
			foodValue       = foodData.foodValue or 0,
			foodValue2      = foodData.foodValue2,
			drinkValue      = foodData.drinkValue or 0,
			drinkValue2     = foodData.drinkValue2,
			wakeValue       = foodData.wakeValue or 0,
			wakeValue2      = foodData.wakeValue2,
			warmthValue      = foodData.warmthValue,
			warmthValue2      = foodData.warmthValue2,
			isToxic         = foodData.isToxic,
			isGreenPact     = foodData.isGreenPact,
			isCookedMeal    = true,
		}
		
		-- Register consumable
		for _, player in pairs(world.players) do
			player:sendEvent("SunsDusk_addConsumable", { rec.id, playerDbEntry})
		end
		
		-- Spawn items
		if placeAt and not placedFoodOnCounter then
			world.createObject(rec.id, batch.count):teleport(innkeeper.cell, placeAt)
			placedFoodOnCounter = true
			batch.count = batch.count - 1
		end
		if batch.count > 0 then
			world.createObject(rec.id, batch.count):moveInto(inv)
		end
	end
	
	-- Consume containers based on what we allocated
	local containerRemovals = {} -- { [recordId] = count }
	
	if forcedFoodware then
		containerRemovals[forcedFoodware] = totalCount
	else
		-- For normal foodware, sum up what needs to be removed per recordId
		for _, alloc in ipairs(allocations) do
			if alloc.foodwareRecordId then
				containerRemovals[alloc.foodwareRecordId] = (containerRemovals[alloc.foodwareRecordId] or 0) + alloc.count
			end
		end
	end
	
	-- Execute removals
	for recordId, count in pairs(containerRemovals) do
		local item = inv:find(recordId)
		if item and item.count > 0 then
			item:remove(math.min(item.count, count))
		end
	end
	
	local function consume(item)
		local consumed = math.min(item.count, foodData.consumedIngredients[item.recordId] or 0)
		if consumed > 0 then
			item:remove(consumed)
			foodData.consumedIngredients[item.recordId] = foodData.consumedIngredients[item.recordId] - consumed
		end
	end
	
	if innkeeper then
		local cell = innkeeper.cell
		for _, item in pairs(types.Actor.inventory(innkeeper):getAll(types.Ingredient)) do
			consume(item)
		end
		local innkeeperRecordId = innkeeper.recordId
		for _, container in pairs(cell:getAll(types.Container)) do
			if container.owner.recordId == innkeeperRecordId then
				for _, item in pairs(types.Container.inventory(container):getAll(types.Ingredient)) do
					consume(item)
				end
			end
		end
		for _, item in pairs(cell:getAll(types.Ingredient)) do
			if item.owner.recordId == innkeeperRecordId then
				consume(item)
			end
		end
	end
	-- Consume ingredients
	for _, item in pairs(inv:getAll(types.Ingredient)) do
		consume(item)
	end
end

G_onLoadJobs.cooking = function(data)
	saveData.stewRegistry = saveData.stewRegistry or {}
	if not saveData.foodVersion then
		saveData.foodVersion = 1
		for recordId, data in pairs(saveData.stewRegistry) do
			if data.foodValue then
				data.foodValue       = data.foodValue/200
			end
			if data.foodValue2 then
				data.foodValue2      = data.foodValue2/200
			end
			if data.drinkValue then
				data.drinkValue      = data.drinkValue/200
			end
			if data.drinkValue2 then
				data.drinkValue2     = data.drinkValue2/200
			end
			if data.wakeValue then
				data.wakeValue       = data.wakeValue/200
			end
			if data.wakeValue2 then
				data.wakeValue2      = data.wakeValue2/200
			end
		end
	end
end

-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Stew Steam VFX                                                       │
-- ╰──────────────────────────────────────────────────────────────────────╯

local useVfx = world.vfx and world.vfx.remove ~= nil


-- stews dont have the issue of resetting their scale?
G_onObjectActiveJobs.cooking = function(object)
	local stewData = saveData.stewRegistry[object.recordId]
	if not stewData then return end
	
	if saveData.consumableVfx[object.id] then
		if useVfx then
			-- VFX needs to be recreated every activation; remove old ones just in case
			local old = saveData.consumableVfx[object.id]
			if old.vfxId then world.vfx.remove(old.vfxId) end
			if old.steamVfxId then world.vfx.remove(old.steamVfxId) end
			if old.static and old.static:isValid() and old.static.count > 0 then
				old.static:remove()
			end
			if old.steamStatic and old.steamStatic:isValid() and old.steamStatic.count > 0 then
				old.steamStatic:remove()
			end
			saveData.consumableVfx[object.id] = nil
			-- fall through to recreate
		else
			return
		end
	end
	
	saveData.consumableVfxCounter = saveData.consumableVfxCounter + 1
	local lootId = saveData.consumableVfxCounter
	
	local mwscript = world.mwscript.getLocalScript(object)
	if mwscript then
		mwscript.variables.lootId = lootId
	end
	
	-- Get base food offset (normalized position for this recipe)
	local baseData = foodOffsets[stewData.recipeId]
	local baseOffset = baseData and baseData.offset or v3(0,0,0)
	local baseScale = baseData and baseData.scale or 1
	
	-- Get foodware-specific adjustment (multiplier for this specific bowl/plate)
	-- Use soupFoodwareOffsets for soups, foodwareOffsets for normal food
	local foodwareOffsetsTable = stewData.isSoup and soupFoodwareOffsets or foodwareOffsets
	local foodwareAdjust = stewData.foodwareRecordId and foodwareOffsetsTable[stewData.foodwareRecordId]
	local foodwareOffset, foodwareScale
	
	if foodwareAdjust then
		foodwareOffset = foodwareAdjust.offset
		foodwareScale = foodwareAdjust.scale
	else
		-- Fallback: calculate offset/scale from the object's bounding box
		local bbox = object:getBoundingBox()
		if not isValidBBox(bbox) then
			return
		end
		local shortestSide = math.min(bbox.halfSize.x * 2, bbox.halfSize.y * 2)
		foodwareScale = shortestSide * 1.414 / 20.495 * 1.15
		if stewData.isSoup then
			foodwareOffset = bbox.center-object.position + v3(0, 0, bbox.halfSize.z / 2)
		else
			foodwareOffset = bbox.center-object.position - v3(0, 0, bbox.halfSize.z / 2)
		end
	end
	
	
	-- Apply both: base offset scales with food, then add foodware adjustment
	local finalOffset = baseOffset * foodwareScale + foodwareOffset
	--print("rotation:", object.rotation)
	--print("rotation type:", type(object.rotation))
	--local rotationTransform = util.transform.rotateZ(object.rotation.z) * util.transform.rotateX(object.rotation.x) * util.transform.rotateY(object.rotation.y)
	local rotatedOffset = object.rotation:apply(finalOffset)
	local finalScale = baseScale * foodwareScale
	
	local static, foodVfxId
	if useVfx then
		foodVfxId = "sd_food_" .. tostring(object.id)
		local model = types.Static.records[stewData.recipeId].model
		world.vfx.spawn(model, object.position + rotatedOffset, {
			loop = true,
			vfxId = foodVfxId,
			scale = finalScale,
		})
	else
		static = world.createObject(stewData.recipeId)
		static:teleport(object.cell, object.position + rotatedOffset, {onGround = false})
		static:setScale(finalScale)
	end
	
	local steamStatic, steamVfxId
	local currentTime = core.getGameTime()
	local ageInHours = (currentTime - stewData.timestamp) / 3600
	
	if ageInHours < 3 then
		if useVfx then
			steamVfxId = "sd_fstm_" .. tostring(object.id)
			local steamModel = types.Static.records["sd_food_steam"].model
			world.vfx.spawn(steamModel, object.position + rotatedOffset, {
				loop = true,
				vfxId = steamVfxId,
				scale = finalScale,
			})
		else
			steamStatic = world.createObject("sd_food_steam")
			steamStatic:teleport(object.cell, object.position + rotatedOffset, {onGround = false})
			steamStatic:setScale(finalScale)
		end
	end
	
	saveData.consumableVfx[object.id] = {
		object = object,
		static = static,
		steamStatic = steamStatic,
		vfxId = foodVfxId,
		steamVfxId = steamVfxId,
		lootId = lootId,
		timestamp = stewData.timestamp,
	}
end

--local function unhookStew(object)
--	if not saveData.steamingStews[object.id] then return end
--	local static = saveData.steamingStews[object.id].static
--	if static.count > 0 then
--		static:remove()
--	end
--	print("-", object.id, static, static.count)
--	saveData.steamingStews[object.id] = nil
--end



--G_onUpdateJobs.cooking = function(dt)
--	for objectId, data in pairs(saveData.steamingStews) do
--		local object = data.object
--		if not object or not object:isValid() or object.count < 1 then
--			saveData.steamingStews[objectId] = nil
--		else
--			data.timer = data.timer + dt
--			if data.timer >= 0.5 then
--				data.timer = 0
--				world.vfx.spawn(
--					data.vfxMesh,
--					object.position,
--					{
--						vfxId = data.vfxId
--					}
--				)
--			end
--		end
--	end
--end


local function returnContainer(data)
	local player = data.player
	local item = data.item
	local stewId = item.recordId
	
	if not stewId then return end
	if downgradedWorldObjects[item.id] then
		return false
	end
	local stewData = saveData.stewRegistry[stewId]
	if stewData and stewData.foodwareRecordId then
		local inv = types.Actor.inventory(player)
		world.createObject(stewData.foodwareRecordId, 1):moveInto(inv)
	end
end

G_eventHandlers.SunsDusk_returnContainer = returnContainer
G_eventHandlers.SunsDusk_createStew = createStew
G_eventHandlers.SunsDusk_UnhookStew = unhookStew