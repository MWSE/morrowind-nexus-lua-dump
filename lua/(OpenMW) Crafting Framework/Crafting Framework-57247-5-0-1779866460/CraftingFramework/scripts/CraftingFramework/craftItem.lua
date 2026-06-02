if hud_craftingFrameworkProgress then
	hud_craftingFrameworkProgress:destroy()
	hud_craftingFrameworkProgress = nil
end

local makeBorder = require("scripts.CraftingFramework.ui_makeborder")
local craftingSoundManager = require("scripts.CraftingFramework.CF_craftingSoundManager")
local borderOffset = 1
local borderFile = "thin"
local timeFliesBuffer = 0

-- crafting sound algorithm: return a profile-key string, a { sound, volume } table, or nil. edit freely.
local function getCraftingSound(craftingState)
	local cs = craftingState.recipe and craftingState.recipe.craftingSound
	if cs then
		return cs
	end
	--not craftingState.recipe.skill or craftingState.recipe.skill == "armorer" or craftingState.recipe.secondSkill == "armorer" then
	if craftingState.isSmithing then
		return "forging"
	end
	if craftingState.recipe.skill == "alchemy" or craftingState.recipe.secondSkill == "alchemy" then
		return "alchemy"
	end
	return { sound = "Sound/Fx/magic/altrA.wav", volume = 0.9 }
end

local borderTemplate = makeBorder(borderFile, nil, borderOffset, {
	type = ui.TYPE.Image,
	props = {
		resource = getTexture('black'),
		relativeSize = v2(1, 1),
		alpha = 0.4,
	}
}).borders


local function checkIngredient(ingredient)
	local returnedItems = {}
	local inventoryCount = 0

	if ingredient.type == "wildcard" then
		-- feasibility pool: strict locks to the resolved key, non-strict
		-- exposes the whole pool (any member can substitute).
		local pool = wildcardPool(ingredient.func)
		if ingredient.strict then
			local key = resolveWildcardKey(pool, ingredient.preferenceId, true)
			local b = key and pool.keys[key]
			if b then
				for _, e in ipairs(b.items) do
					if e.item.count > 0 then
						table.insert(returnedItems, e.item)
						inventoryCount = inventoryCount + e.item.count
					end
				end
			end
		else
			for _, b in pairs(pool.keys) do
				for _, e in ipairs(b.items) do
					if e.item.count > 0 then
						table.insert(returnedItems, e.item)
						inventoryCount = inventoryCount + e.item.count
					end
				end
			end
		end
	else
		-- weapons/armor: match by model, not id
		if ingredient.type == "Weapon" or ingredient.type == "Armor" then
			local targetRecord = nil
			if ingredient.type and types[ingredient.type] and ingredient.id then
				targetRecord = types[ingredient.type].records[ingredient.id]
			end

			if targetRecord then
				local totalCount = 0

				for _, inv in ipairs(inventorySources()) do
					for _, item in pairs(inv:getAll(types[ingredient.type])) do
						local itemRecord = types[ingredient.type].record(item)

						if itemRecord and
							itemRecord.model == targetRecord.model and
							(itemRecord.id:sub(1, 10) == "Generated:" or itemRecord.enchant == nil) then
							table.insert(returnedItems, item)
							totalCount = totalCount + item.count
						end
					end
				end

				inventoryCount = totalCount
			else
				-- fallback: no target record
				for _, inv in ipairs(inventorySources()) do
					local item = inv:find(ingredient.id)
					if item then
						inventoryCount = inventoryCount + item.count
						table.insert(returnedItems, item)
					end
				end
			end
		elseif ingredient.id:sub(1, 12) == "misc_soulgem" then
			for _, inv in ipairs(inventorySources()) do
				for _, item in pairs(inv:getAll(types.Miscellaneous)) do
					if item.recordId == ingredient.id and not types.Item.itemData(item).soul then
						inventoryCount = inventoryCount + item.count
						table.insert(returnedItems, item)
					end
				end
			end
		-- items with charges
		elseif ingredient.type == "Lockpick" or ingredient.type == "Probe" or ingredient.type == "Repair" then
			for _, inv in ipairs(inventorySources()) do
				for _, item in pairs(inv:getAll(ingredient.type)) do
					if item.recordId == ingredient.id and types.Item.itemData(item).condition >= types[ingredient.type].records[ingredient.id].maxCondition then
						inventoryCount = inventoryCount + item.count
						table.insert(returnedItems, item)
					end
				end
			end
		else
			for _, inv in ipairs(inventorySources()) do
				local item = inv:find(ingredient.id)
				if item then
					inventoryCount = inventoryCount + item.count
					table.insert(returnedItems, item)
				end
			end
		end
	end
	return returnedItems, inventoryCount
end


local function checkIngredients(craftingState)
	local recipe = craftingState.recipe
	local ingredients = craftingState.ingredients
	if not recipe or not ingredients then return 0 end
	if cheatMode then
		return 10
	end

	for _, tool in ipairs(craftingState.tools or recipe.tools or {}) do
		if tool.type == "wildcard" and tool.func then
			-- wildcard tool: preference if available, else best-available
			local pool = wildcardPool(tool.func)
			local _, short = consumeWildcardPlan(pool, 1, tool.preferenceId, false)
			if short > 0 then return 0 end
		else
			local checkTool = {
				type = tool.type,
				id = tool.id,
				func = tool.func,
				name = tool.name,
				count = 1,
			}
			local toolItems = checkIngredient(checkTool)
			if not toolItems or #toolItems == 0 then
				return 0
			end
		end
	end

	-- precompute fixed (virtuals: same math, different read)
	local maxFromFixed = 999999
	local fixedUsage = {}

	for _, ingredient in ipairs(ingredients) do
		if ingredient.type == "virtual" then
			-- live countFunc read
			local def = virtuals[ingredient.virtualId]
			local available = def and def.countFunc and def.countFunc() or 0
			if available < ingredient.count then return 0 end
			maxFromFixed = math.min(maxFromFixed, math.floor(available / ingredient.count))
		elseif ingredient.type ~= "wildcard" then
			local foundItems, inventoryCount = checkIngredient(ingredient)
			if not foundItems or #foundItems == 0 then
				return 0
			end
			maxFromFixed = math.min(maxFromFixed, math.floor(inventoryCount / ingredient.count))
			-- one count per key per ingredient
			local seenKeys = {}
			for _, item in ipairs(foundItems) do
				local key = getItemKey(item)
				if not seenKeys[key] then
					seenKeys[key] = true
					fixedUsage[key] = (fixedUsage[key] or 0) + ingredient.count
				end
			end
		end
	end

	if maxFromFixed == 0 then
		return 0
	end

	-- precompute wildcards: group by key, not stack
	local wildcardData = {}
	for _, ingredient in ipairs(ingredients) do
		if ingredient.type == "wildcard" then
			local foundItems = checkIngredient(ingredient)
			if not foundItems or #foundItems == 0 then
				return 0
			end
			local keyTotals = {}
			for _, item in ipairs(foundItems) do
				local key = getItemKey(item)
				keyTotals[key] = (keyTotals[key] or 0) + item.count
			end
			local items = {}
			for key, count in pairs(keyTotals) do
				table.insert(items, {
					key = key,
					count = count,
					fixedNeed = fixedUsage[key] or 0
				})
			end
			table.insert(wildcardData, {
				items = items,
				countNeeded = ingredient.count
			})
		end
	end

	if #wildcardData == 0 then
		return maxFromFixed
	end

	-- hall's condition: union of each subset's pools must cover sum of its needs
	local k = #wildcardData
	local function canCraftN(n)
		if n <= 0 then return true end
		for mask = 1, 2 ^ k - 1 do
			local seen = {}
			local totalAvailable = 0
			local totalNeeded = 0
			for i = 1, k do
				if math.floor(mask / 2 ^ (i - 1)) % 2 == 1 then
					local wc = wildcardData[i]
					totalNeeded = totalNeeded + wc.countNeeded * n
					for _, item in ipairs(wc.items) do
						if not seen[item.key] then
							seen[item.key] = true
							local available = item.count - (item.fixedNeed * n)
							if available > 0 then
								totalAvailable = totalAvailable + available
							end
						end
					end
				end
			end
			if totalAvailable < totalNeeded then
				return false
			end
		end
		return true
	end

	local low, high = 0, maxFromFixed
	while low < high do
		local mid = math.ceil((low + high) / 2)
		if canCraftN(mid) then
			low = mid
		else
			high = mid - 1
		end
	end

	return low
end

-- pure: returns {[item]=count} the craft would consume from current inventory.
-- partial allocations possible if inventory is short. cheatMode is handled by the consume wrapper.
-- fillSynthetic=true (preview only): adds synthetic { recordId = id } entries for any
-- shortfall so modifiers see the full intended plan regardless of inventory state.
-- synthetic entries have no :remove() method, NEVER pass them to the craft path.
function resolveConsumedIngredients(recipe, ingredients, fillSynthetic)
	if not recipe or not ingredients then return {} end

	local fixedIngredients = {}
	local wildcardIngredients = {}
	local virtualIngredients = {}
	for _, ingredient in ipairs(ingredients) do
		if ingredient.type == "wildcard" then
			table.insert(wildcardIngredients, ingredient)
		elseif ingredient.type == "virtual" then
			table.insert(virtualIngredients, ingredient)
		else
			table.insert(fixedIngredients, ingredient)
		end
	end

	local consumed = {}
	local consumedIngredients = {}
	local consumedVirtuals = {}

	-- fixed first: needs specific items
	for _, ingredient in ipairs(fixedIngredients) do
		local items = checkIngredient(ingredient)
		local remainingToConsume = ingredient.count

		for _, item in ipairs(items or {}) do
			if remainingToConsume <= 0 then break end

			local alreadyConsumed = consumed[item] or 0
			local available = item.count - alreadyConsumed

			if available > 0 then
				local consumeAmount = math.min(available, remainingToConsume)
				consumedIngredients[item] = (consumedIngredients[item] or 0) + consumeAmount
				consumed[item] = alreadyConsumed + consumeAmount
				remainingToConsume = remainingToConsume - consumeAmount
			end
		end
		-- synthetic fill: preview-only, lets modifiers see ingredients the player doesn't have yet
		if fillSynthetic and remainingToConsume > 0 and ingredient.id then
			consumedIngredients[{ recordId = ingredient.id }] = remainingToConsume
		end
	end

	-- wildcard after fixed; net out stacks already taken so an item shared
	-- with a fixed ingredient is not double-allocated.
	for _, ingredient in ipairs(wildcardIngredients) do
		local pool = wildcardPool(ingredient.func, nil, consumed)
		local plan, shortfall = consumeWildcardPlan(pool, ingredient.count, ingredient.preferenceId, ingredient.strict)
		for _, e in ipairs(plan) do
			consumedIngredients[e.item] = (consumedIngredients[e.item] or 0) + e.count
			consumed[e.item] = (consumed[e.item] or 0) + e.count
		end
		-- synthetic fill: only possible when an explicit preferenceId names the recordId
		if fillSynthetic and shortfall > 0 and ingredient.preferenceId then
			consumedIngredients[{ recordId = ingredient.preferenceId }] = shortfall
		end
	end

	-- virtuals: sum per id
	for _, ingredient in ipairs(virtualIngredients) do
		consumedVirtuals[ingredient.virtualId] = (consumedVirtuals[ingredient.virtualId] or 0) + ingredient.count
	end

	return consumedIngredients, consumedVirtuals
end

-- craft-path wrapper: gates on the feasibility check first
local function consumeIngredients(craftingState)
	local recipe = craftingState.recipe
	local ingredients = craftingState.ingredients
	if not recipe or not ingredients then return false end
	if cheatMode then return {} end
	if checkIngredients(craftingState) < 1 then return false end
	return resolveConsumedIngredients(recipe, ingredients)
end



local function getBestHammer()
	local repairTools = types.Player.inventory(self):getAll(types.Repair)
	local bestHammer = nil
	local bestHammerQuality = 0.001

	for a, b in pairs(repairTools) do
		if types.Repair.record(b).quality > bestHammerQuality then
			bestHammer = b
			bestHammerQuality = types.Repair.record(b).quality
		end
	end
	return bestHammerQuality, bestHammer
end

local function getResultItem(recipe, modifiedName, resultId, resultType, resultCount)
	local resultRecord
	if resultType and types[resultType] and resultId then
		resultRecord = types[resultType].records[resultId]
	end
	local icon = nil
	if recipe.icon then
		icon = recipe.icon
	elseif resultRecord then
		icon = resultRecord.icon
	end
	local nameText = "ERROR: " .. (resultId or "no id")
	if modifiedName then
		nameText = modifiedName
	elseif resultRecord then
		nameText = resultRecord.name
	end
	if resultCount and resultCount ~= 1 then
		if resultCount < 1 then
			nameText = nameText .. " (" .. math.floor(resultCount * 100) .. "%)"
		else
			nameText = nameText .. " (x " .. resultCount .. ")"
		end
	end
	-- append additional product names
	for _, product in ipairs(recipe.additionalProducts or {}) do
		local productRecord = types[product.type] and types[product.type].records[product.id]
		local productName = productRecord and productRecord.name or product.id
		if product.count and product.count ~= 1 then
			nameText = nameText .. " + " .. productName .. " x" .. product.count
		else
			nameText = nameText .. " + " .. productName
		end
	end
	return nameText, icon
end

-- crafting state
if not craftingState then
	craftingState = {
		isActive = false,
		duration = 0,
		itemName = "",
		elapsedTime = 0,
		initialHealth = 0,
		lastFxStep = -1,
		speed = 1,
		tool = nil,
		recipe = {},
	}
end

local fontSize = 18
local barWidth = 180
local barHeight = 16


local progressColor = morrowindBlue

-- root
hud_craftingFrameworkProgress = ui.create({
	type = ui.TYPE.Container,
	layer = 'HUD',
	name = "hud_craftingFrameworkProgress",
	props = {
		relativePosition = v2(0.5, 0.8),
		anchor = v2(0.5, 0.5),
		visible = false,
	},
	content = ui.content {}
})

-- main flex
local mainFlex = {
	type = ui.TYPE.Flex,
	props = {
		autoSize = true,
		arrange = ui.ALIGNMENT.Center,
	},
	content = ui.content {}
}
hud_craftingFrameworkProgress.layout.content:add(mainFlex)

-- header text
local itemNameText = {
	type = ui.TYPE.Text,
	name = "itemNameText",
	props = {
		text = "Crafting...",
		textColor = morrowindGold,
		textShadow = true,
		textShadowColor = util.color.rgba(0, 0, 0, 1),
		textSize = fontSize,
		textAlignH = ui.ALIGNMENT.Center,
		textAlignV = ui.ALIGNMENT.Center,
		autoSize = true,
	}
}
mainFlex.content:add(itemNameText)

-- queue info text
local queueInfoText = {
	type = ui.TYPE.Text,
	name = "queueInfoText",
	props = {
		text = "",
		textColor = morrowindBlue,
		textShadow = true,
		textShadowColor = util.color.rgba(0, 0, 0, 1),
		textSize = fontSize - 4,
		textAlignH = ui.ALIGNMENT.Center,
		textAlignV = ui.ALIGNMENT.Center,
		autoSize = true,
	}
}
mainFlex.content:add(queueInfoText)

-- spacer
mainFlex.content:add { props = { size = v2(1, 1) } }

-- progress container
local progressContainer = {
	type = ui.TYPE.Widget,
	template = borderTemplate,
	props = {
		size = v2(barWidth + 4, barHeight + 4),
	},
	content = ui.content {}
}
mainFlex.content:add(progressContainer)

-- progress fill
local progressFill = {
	type = ui.TYPE.Image,
	name = "progressFill",
	props = {
		resource = getTexture('white'),
		color = progressColor,
		relativeSize = v2(0, 1),
		alpha = 1
	}
}
progressContainer.content:add(progressFill)

-- progress text
local progressText = {
	type = ui.TYPE.Text,
	name = "progressText",
	props = {
		text = "0%",
		textColor = textColor,
		textShadow = true,
		textShadowColor = util.color.rgba(0, 0, 0, 1),
		textSize = fontSize - 4,
		textAlignH = ui.ALIGNMENT.End,
		textAlignV = ui.ALIGNMENT.Center,
		relativePosition = v2(1, 0.5),
		anchor = v2(1, 0.5),
		relativeSize = v2(1, 1),
		autoSize = true,
	}
}
progressContainer.content:add(progressText)

-- start next queued item
local function processNextQueueItem()
	if #craftingQueue > 0 and not craftingState.isActive then
		craftItem()
	else
		craftingState.isActive = false
		hud_craftingFrameworkProgress.layout.props.visible = false
		hud_craftingFrameworkProgress:update()
	end
end

-- silent skip: no fail sound, no interrupt event, no ingredient recheck.
function skipCurrentRecipe()
	if #craftingQueue == 0 then return end
	craftingSoundManager:stop()
	craftingState.isActive = false
	table.remove(craftingQueue, 1)
	processNextQueueItem()
end
API.skipCurrentRecipe = skipCurrentRecipe -- api-only

-- exp award (calculateRecipeExp) lives in CF_core.

-- onframe handler
local function updateCraftingProgress(onFrameDt)
	local dt = core.getRealFrameDuration()
	if not craftingState.isActive then
		if craftingSoundManager:isActive() then
			craftingSoundManager:update(1)
		end
		return
	end

	local movement
	if craftingState.manualProgress then
		local maxDist = 250
		if type(craftingState.manualProgress) == "number" then
			maxDist = craftingState.manualProgress
		end
		movement = (self.position - craftingState.initialPosition):length() - maxDist
	else
		movement = math.max(math.abs(self.controls.movement), math.abs(self.controls.sideMovement))
	end
	local currentHealth = playerHealth.current / playerHealth.base + 0.01
	if (currentHealth < 1 and currentHealth < craftingState.initialHealth) or movement > 0 then
		self:sendEvent("CraftingFramework_craftInterrupted", {
			recipeId   = craftingState.recipe and craftingState.recipe.id,
			profession = craftingState.recipe and craftingState.recipe.profession,
			reason     = (movement and movement > 0) and "movement" or "health",
		})
		craftingSoundManager:stop()
		clearCraftingQueue()
		ambient.playSound("enchant fail")
		return
	end

	-- manual progress: skip auto time advance
	if not craftingState.manualProgress then
		craftingState.elapsedTime = craftingState.elapsedTime + dt
		craftingState.elapsedTime = math.min(craftingState.elapsedTime, craftingState.duration)
	end

	local progress = craftingState.elapsedTime / craftingState.duration

	craftingSoundManager:update(progress)

	progressFill.props.relativeSize = v2(progress, 1)

	if not craftingState.noTool then
		if craftingState.manualProgress then
			progressText.props.text = math.floor((craftingState.manualPercent or 0)*100) .. "%"
		else
			progressText.props.text = f1(-(1 - progress) * craftingState.duration) .. "s"
		end
	end

	if #craftingQueue > 1 then
		queueInfoText.props.text = "Queue: " .. #craftingQueue - 1 .. " remaining"
	else
		queueInfoText.props.text = ""
	end

	local baseInterval = craftingState.recipe.craftingInterval or 0.7
	local targetFxCount = math.max(2, math.ceil(craftingState.duration / baseInterval))
	local fxInterval = craftingState.duration / targetFxCount
	local currentFxStep = math.floor((craftingState.elapsedTime + 0.001) / fxInterval)

	-- manual progress: validate stations on first tick only
	if craftingState.manualProgress then
		if craftingState.lastFxStep == -1 then
			craftingState.lastFxStep = 0

			for _, station in ipairs(craftingState.recipe.stations or {}) do
				if station.func then
					local returns = { station.func(0, craftingState) }
					if returns[1] == nil or returns[1] == false then
						self:sendEvent("CraftingFramework_craftInterrupted", {
							recipeId   = craftingState.recipe and craftingState.recipe.id,
							profession = craftingState.recipe and craftingState.recipe.profession,
							reason     = "station",
						})
						craftingSoundManager:stop()
						clearCraftingQueue()
						ambient.playSound("enchant fail")
						return
					end
					-- manual caller supplies snapshot data
				end
			end
		end
	elseif currentFxStep > craftingState.lastFxStep then
		types.Actor.stats.dynamic.fatigue(self).current = math.max(0,
			types.Actor.stats.dynamic.fatigue(self).current - 1.5)
		craftingState.lastFxStep = currentFxStep

		-- station snapshots
		for _, station in ipairs(craftingState.recipe.stations or {}) do
			if station.func then
				local returns = { station.func(currentFxStep, craftingState) }
				if returns[1] == nil or returns[1] == false then
					self:sendEvent("CraftingFramework_craftInterrupted", {
						recipeId   = craftingState.recipe and craftingState.recipe.id,
						profession = craftingState.recipe and craftingState.recipe.profession,
						reason     = "station",
					})
					craftingSoundManager:stop()
					clearCraftingQueue()
					ambient.playSound("enchant fail")
					return
				elseif returns[1] ~= true then
					table.insert(craftingState.stationSnapshots, returns)
				end
			end
		end

		if not craftingSoundManager.entries then
			local now = core.getRealTime()
			if now > lastFxTime + 0.1 then
				local def = craftingState.fxSound
				if type(def) == "table" then
					if vfs.fileExists(def.sound) then
						ambient.playSoundFile(def.sound, { volume = def.volume or 0.9 })
					else
						ambient.playSound(def.sound, { volume = def.volume or 0.9 })
					end
				end
				lastFxTime = core.getRealTime()
			end
		end
		if currentFxStep > 0 and (checkIngredients(craftingState) < 1 or craftingState.recipe.disabled) then
			self:sendEvent("CraftingFramework_craftInterrupted", {
				recipeId   = craftingState.recipe and craftingState.recipe.id,
				profession = craftingState.recipe and craftingState.recipe.profession,
				reason     = craftingState.recipe.disabled and "disabled" or "ingredients",
			})
			craftingSoundManager:stop()
			clearCraftingQueue()
			ambient.playSound("enchant fail")
			return
		end
	end
	-- time flies: pass game time
	if HAS_TIME_FLIES and S_CRAFTING_TIME > 0 and dt > 0 then
		core.sendGlobalEvent('TimeFlies_passMinutes', {
			minutes = dt * S_CRAFTING_TIME,
			reason = 'crafting',
			args = { recipe = craftingState.recipe.displayName },
			instant = true,
		})
	end
	hud_craftingFrameworkProgress:update()

	if craftingState.elapsedTime >= craftingState.duration then

		local playPickupSound = (not craftingSoundManager.entries) and true or false

		craftingSoundManager:stop()
		craftingState.isActive = false
		local consumedIngredients, consumedVirtuals = consumeIngredients(craftingState)
		if consumedIngredients then
			-- fire listeners, drop cache for fresh countFunc
			if consumedVirtuals and next(consumedVirtuals) then
				for virtualId, count in pairs(consumedVirtuals) do
					local payload = { virtualId = virtualId, count = count, recipe = craftingState.recipe }
					-- def callback, then globals
					local def = virtuals[virtualId]
					if def and def.consumed then def.consumed(payload) end
					for _, fn in ipairs(virtualConsumedListeners or {}) do
						fn(payload)
					end
				end
				invalidateInventoryCache()
			end

			-- tools snapshot (one instance per slot)
			local toolsUsed = {}
			for _, tool in ipairs(craftingState.tools or craftingState.recipe.tools or {}) do
				if tool.type == "wildcard" and tool.func then
					local pool = wildcardPool(tool.func)
					local plan = consumeWildcardPlan(pool, 1, tool.preferenceId, false)
					if plan[1] and plan[1].item then
						table.insert(toolsUsed, plan[1].item)
					end
				else
					local checkTool = {
						type = tool.type,
						id = tool.id,
						func = tool.func,
						name = tool.name,
						count = 1,
					}
					local toolItems = checkIngredient(checkTool)
					if toolItems then
						for _, item in ipairs(toolItems) do
							table.insert(toolsUsed, item)
							break
						end
					end
				end
			end

			local craftingEvent = craftingState.recipe.craftingEvent or 'CraftingFramework_getItem'
			if craftingEvent ~= "CraftingFramework_getItem" then
				print("craftingEvent", craftingEvent)
			end
			-- resolve target first so every downstream chain sees the swap
			craftingState.resultId, craftingState.resultType = resolveResultItem(craftingState.recipe, craftingState.touches, false, craftingState.ingredients, craftingState.craftData)
			craftingState.resultCount = resolveResultCount(craftingState.recipe, craftingState.touches, false, craftingState.ingredients, craftingState.craftData, craftingState.resultId, craftingState.resultType)
			local quality = calculateQuality(craftingState.recipe, craftingState.touches, false, craftingState.ingredients, craftingState.craftData)
			local stats = computeCraftedStats(craftingState.recipe, {
				recordType = craftingState.resultType,
				recordId = craftingState.resultId,
				qualityMult = quality,
				touches = craftingState.touches,
				snapshotIngredients = craftingState.ingredients,
				craftData = craftingState.craftData,
			})
			local enchantment = computeCraftedEnchantment(craftingState.recipe, {
				recordType = craftingState.resultType,
				recordId = craftingState.resultId,
				qualityMult = quality,
				touches = craftingState.touches,
				snapshotIngredients = craftingState.ingredients,
				craftData = craftingState.craftData,
			})
			local resultValue = calculateResultValue(craftingState.recipe, craftingState.touches, quality, false, craftingState.ingredients, craftingState.craftData)
			local customName = resolveRecipeName(craftingState.recipe, craftingState.touches, quality, false, craftingState.ingredients, craftingState.craftData)
			-- per-skill exp; a craft grants both when secondSkill splits it
			local expBySkill = calculateRecipeExp(craftingState.recipe, craftingState.touches, consumedIngredients, craftingState.craftData, false)

			-- finalize: last-chance bundle rewrite once everything else resolved.
			-- modifier may swap resultId, count, value, qualityMult, stats,
			-- enchantment, customName, expBySkill, additionalProducts.
			local finalized = computeFinalizeCraft(craftingState.recipe, {
				touches = craftingState.touches,
				craftData = craftingState.craftData,
				ingredients = resolveIngredients(craftingState.recipe, craftingState.touches, craftingState.ingredients),
				consumedIngredients = consumedIngredients,
				consumedVirtuals = consumedVirtuals,
				toolsUsed = toolsUsed,
				shiftPressed = craftingState.shiftPressed,
				stationSnapshots = craftingState.stationSnapshots,
				duration = craftingState.duration,
				resultType = craftingState.resultType,
				bundle = {
					resultId = craftingState.resultId,
					count = craftingState.resultCount or craftingState.recipe.count or 1,
					value = resultValue,
					qualityMult = quality,
					stats = stats,
					enchantment = enchantment,
					customName = customName,
					expBySkill = expBySkill,
					additionalProducts = deepcopy(craftingState.recipe.additionalProducts or {}),
				},
			})

			-- re-validate resultId on swap; fall back on miss
			if finalized.resultId ~= craftingState.resultId then
				local newType = getItemType(finalized.resultId)
				if newType then
					craftingState.resultId = finalized.resultId
					craftingState.resultType = newType
				else
					print("\27[91m finalizeCraft: modifier returned invalid recordId '" .. tostring(finalized.resultId) .. "', falling back")
					finalized.resultId = craftingState.resultId
				end
			end

			-- award final exp; awardExp invalidates the skill cache itself
			local i = 0
			for skillId, v in pairs(finalized.expBySkill or {}) do
				print(skillId .. " exp: " .. math.floor(v*100)/100)
				expText(v, v2(0.5, 0.77 - i * 0.01))
				awardExp(skillId, v)
				i = i + 1
			end
			updateProfessionProgressBar()

			-- shift-press: unequip ammo when result is ammo. uses final resultId.
			if craftingState.shiftPressed and getEquipmentSlot({ type = craftingState.resultType, recordId = craftingState.resultId }) == types.Actor.EQUIPMENT_SLOT.Ammunition then
				local eq = types.Actor.getEquipment(self)
				eq[types.Actor.EQUIPMENT_SLOT.Ammunition] = nil
				types.Actor.setEquipment(self, eq)
			end

			-- stats: count craft, ingredients, value/time, touches, quality
			local saveStats = saveData and saveData.stats
			if saveStats then
				local rId = craftingState.recipe.id
				local rCount = finalized.count or craftingState.recipe.count or 1
				saveStats.perRecipe[rId] = (saveStats.perRecipe[rId] or 0) + rCount
				for item, count in pairs(consumedIngredients) do
					saveStats.perIngredient[item.recordId] = (saveStats.perIngredient[item.recordId] or 0) + count
				end
				for _, touch in ipairs(touchList) do
					if craftingState.touches and craftingState.touches[touch.id] and touch.label then
						saveStats.touches[touch.label] = (saveStats.touches[touch.label] or 0) + 1
					end
				end
				saveStats.totalValue = saveStats.totalValue + (finalized.value or 0) * rCount
				saveStats.totalTime = saveStats.totalTime + (craftingState.duration or 0)
				local q = saveStats.quality[rId]
				if not q then
					q = { best = finalized.qualityMult, sum = 0, n = 0 }
					saveStats.quality[rId] = q
				end
				if finalized.qualityMult > q.best then q.best = finalized.qualityMult end
				q.sum = q.sum + finalized.qualityMult
				q.n = q.n + 1
			end

			core.sendGlobalEvent(craftingEvent, {
				player = self,
				recordType = craftingState.resultType,
				recordId = craftingState.resultId,
				customName = finalized.customName,
				count = finalized.count or craftingState.recipe.count or 1,
				value = finalized.value,
				qualityMult = finalized.qualityMult,
				stats = finalized.stats,
				enchantment = finalized.enchantment,
				touches = craftingState.touches,
				preserveRecordId = craftingState.recipe.preserveRecordId,
				shiftPressed = craftingState.shiftPressed,
				consumedIngredients = consumedIngredients,
				stationSnapshots = craftingState.stationSnapshots,
				playPickupSound = playPickupSound,
				additionalProducts = finalized.additionalProducts,
				toolsUsed = toolsUsed,
				craftData = craftingState.craftData,
			})

			if #craftingQueue > 0 then
				table.remove(craftingQueue, 1)
			end
			--removeFromCraftingQueue()
			processNextQueueItem()
		end
	end
end


if onFrameFunctions then
	table.insert(onFrameFunctions, updateCraftingProgress)
end


-- advance manual-progress crafting.
-- id: must match recipe.manualProgress.
-- percent: progress to add (e.g. 25 = 25%).
-- data: optional snapshot, replaces auto station calls.
-- returns true on advance, false on fail or id mismatch.
function advanceManualCrafting(id, percent, data)
	if not craftingState.isActive then return false end
	if not craftingState.manualProgress then return false end
	if craftingState.manualProgress ~= id then return false end

	-- recheck ingredients each call
	if checkIngredients(craftingState) < 1 or craftingState.recipe.disabled then
		self:sendEvent("CraftingFramework_craftInterrupted", {
			recipeId   = craftingState.recipe and craftingState.recipe.id,
			profession = craftingState.recipe and craftingState.recipe.profession,
			reason     = craftingState.recipe.disabled and "disabled" or "ingredients",
		})
		craftingSoundManager:stop()
		clearCraftingQueue()
		return false
	end

	craftingState.manualPercent = (craftingState.manualPercent or 0) + (percent or 0)
	craftingState.manualPercent = math.min(craftingState.manualPercent, 1)

	-- map percent to elapsedTime for completion check
	craftingState.elapsedTime = (craftingState.manualPercent) * craftingState.duration

	if data ~= nil then
		table.insert(craftingState.stationSnapshots, data)
	end

	return true
end
API.advanceManualCrafting = advanceManualCrafting -- bare-used internally (event handler)


-- drop funcs; events must serialize
local function stripFuncs(v)
	if type(v) ~= "table" then return v end
	local out = {}
	for k, val in pairs(v) do
		if type(val) == "table" then
			out[k] = stripFuncs(val)
		elseif type(val) ~= "function" then
			out[k] = val
		end
	end
	return out
end


return function()
	if craftingState.isActive then
		return
	end
	if not craftingQueue[1] then
		return
	end
	local recipe = craftingQueue[1].recipe
	if recipe.disabled then
		-- recipe not yet on craftingState; read queue entry
		self:sendEvent("CraftingFramework_craftInterrupted", {
			recipeId   = recipe.id,
			profession = recipe.profession,
			reason     = "disabled",
		})
		craftingSoundManager:stop()
		clearCraftingQueue()
		ambient.playSound("enchant fail")
		return
	end
	craftingState.recipe = recipe
	craftingState.ingredients = craftingQueue[1].ingredients
	craftingState.tools = craftingQueue[1].tools
	craftingState.initialPosition = self.position
	-- shared bag: any modifier writes, event payloads read.
	craftingState.craftData = {}
	-- resolve result first so downstream chains see the swapped target.
	craftingState.resultId, craftingState.resultType = resolveResultItem(recipe, craftingQueue[1].touches, true, craftingState.ingredients, craftingState.craftData)
	craftingState.resultCount = resolveResultCount(recipe, craftingQueue[1].touches, true, craftingState.ingredients, craftingState.craftData, craftingState.resultId, craftingState.resultType)
	local skill = getModifiedSkill(craftingState.recipe.skill or "armorer", craftingState.recipe.level)
	if craftingState.recipe.secondSkill then
		skill = (skill + getModifiedSkill(craftingState.recipe.secondSkill, craftingState.recipe.secondLevel)) / 2
	end

	local speed = 1 + skill / 100
	if not craftingState.recipe.skill or craftingState.recipe.skill == "armorer" or craftingState.recipe.secondSkill == "armorer" or craftingState.recipe.skill == "crafting_skill" or craftingState.recipe.secondSkill == "crafting_skill" then
		craftingState.speed = math.max(0.5, math.log(7, 7 * getBestHammer()) * speed)
		craftingState.isSmithing = true
	else
		craftingState.speed = speed
		craftingState.isSmithing = false
	end
	if cheatMode then
		craftingState.speed = cheatMode
	end
	craftingState.speed = craftingState.speed * S_CRAFTING_SPEED
	craftingState.itemName = getResultItem(recipe, resolveRecipeName(recipe, craftingQueue[1].touches, nil, true, craftingState.ingredients, craftingState.craftData), craftingState.resultId, craftingState.resultType, craftingState.resultCount)

	local color = textColor

	local duration = calculateCraftingTime(recipe, craftingQueue[1].touches, craftingState.ingredients, craftingState.craftData)
	craftingState.touches = craftingQueue[1].touches
	craftingState.shiftPressed = craftingQueue[1].shiftPressed
	craftingState.isActive = true
	craftingState.duration = duration / craftingState.speed

	craftingState.elapsedTime = 0
	craftingState.initialHealth = playerHealth.current / playerHealth.base
	craftingState.lastFxStep = -1
	craftingState.stationSnapshots = {}
	craftingState.manualProgress = recipe.manualProgress
	craftingState.manualPercent = 0

	-- strip wildcard funcs so the event payload serializes
	local t = stripFuncs({
		recipe = recipe,
		ingredients = craftingState.ingredients,
		tools = craftingState.tools,
		touches = craftingState.touches,
		shiftPressed = craftingState.shiftPressed,
		duration = craftingState.duration,
		speed = craftingState.speed,
		isSmithing = craftingState.isSmithing,
	})
	self:sendEvent("CraftingFramework_craftStarted", t)

	-- fx interval
	local baseInterval = recipe.craftingInterval or 0.7
	local targetFxCount = math.ceil(craftingState.duration / baseInterval)
	if targetFxCount < 1 then targetFxCount = 1 end
	craftingState.fxInterval = craftingState.duration / targetFxCount

	-- decide the craft sound once; registered key => profile, other string => raw per-step sound
	craftingState.fxSound = getCraftingSound(craftingState)
	if type(craftingState.fxSound) == "string" then
		if craftingSounds[craftingState.fxSound] then
			craftingSoundManager:start(craftingState.fxSound, craftingState.duration)
		else
			craftingState.fxSound = { sound = craftingState.fxSound, volume = 0.9 }
		end
	end

	hud_craftingFrameworkProgress.layout.props.visible = true

	itemNameText.props.text = " " .. craftingState.itemName .. " "
	itemNameText.props.textColor = color

	progressFill.props.size = v2(1, barHeight)
	progressText.props.text = "0%"

	hud_craftingFrameworkProgress:update()
end
