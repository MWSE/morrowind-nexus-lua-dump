-- wildcard preferences; keyed by registered wildcard pool id. value = the
-- player's explicit pick (getItemKey), or nil for auto. written only by the
-- ui click handlers, never by render. reset on profession change and window
-- open; not persisted across save/load.
wildcardPreferences = {}

ore_difficulties = { 
	["t_ingmine_oreiron_01"] = 15,
	["t_ingmine_coal_01"] = 25,
	["t_ingmine_orecopper_01"] = 35,
	["t_ingmine_oresilver_01"] = 33,
	["t_ingmine_oregold_01"] = 36,
	["t_ingmine_oreorichalcum_01"] = 40,
	["ingred_diamond_01"] = 40,
	["ingred_adamantium_ore_01"] = 65,
	["ingred_raw_glass_01"] = 70,
	["ingred_raw_ebony_01"] = 75,
}

function deepcopy(orig)
	local orig_type = type(orig)
	local copy
	if orig_type == 'table' then
		copy = {}
		for orig_key, orig_value in next, orig, nil do
			copy[deepcopy(orig_key)] = deepcopy(orig_value)
		end
		setmetatable(copy, deepcopy(getmetatable(orig)))
	else
		copy = orig
	end
	return copy
end

function f1dot(number)
	return string.format("%.1f", number + 0.05)
end

function f1(number)
	local formatted = string.format("%.1f", number)
	if formatted:sub(#formatted, #formatted) == "0" then
		return tonumber(string.format("%.0f", number))
	end
	return formatted
end

function getTexture(path)
	if not textureCache[path] then
		textureCache[path] = ui.texture { path = path }
	end
	return textureCache[path]
end


function isTheft(item)
	if item.owner.recordId then
		return true
	elseif item.owner.factionId and types.NPC.getFactionRank(self, item.owner.factionId) == 0 then
		return true
	elseif item.owner.factionId and types.NPC.getFactionRank(self, item.owner.factionId) < (item.owner.factionRank or 0) then
		return true
	end
	return false
end

-- shared source list: player inventory + nearby unowned, unlocked,
-- non-organic containers within 700 units. used by fixed ingredients,
-- wildcard funcs, and the temp inventory snapshot so they all agree.
function inventorySources()
	local myPos = self.position
	local sources = { types.Player.inventory(self) }
	for _, container in ipairs(nearby.containers) do
		if not types.Container.record(container).isOrganic
		and not isTheft(container)
		and not types.Lockable.isLocked(container)
		and (container.position - myPos):length() <= 700 then
			table.insert(sources, types.Container.content(container))
		end
	end
	return sources
end

-- inventory key; filled soul gems append ":soul:creatureId"
function getItemKey(item)
	local rid = item.recordId
	if rid:sub(1, 12) == "misc_soulgem" or rid:find("soulgem") or rid:find("soul_gem") then
		local soul = types.Item.itemData(item).soul
		if soul then
			return rid .. ":soul:" .. soul
		end
	end
	return rid
end

-- ctx.modified not initialized, first mutator calls ingredientsMutable(ctx)
function getIngredients(recipe, touches)
	local ctx = {
		base = recipe.ingredients,
		modified = nil,
		recipe = recipe,
		touches = touches,
	}
	if recipe.ingredientsFunc then
		local entry = ingredientsModifierChain.byId(recipe.ingredientsFunc)
		if entry and entry.func(recipe, ctx) == false then
			return ctx.modified or recipe.ingredients
		end
	end
	ingredientsModifierChain.apply(recipe, ctx, recipe.ingredientsFunc)
	return ctx.modified or recipe.ingredients
end

-- bypasses theme replacers
local vanillaColors = {
	fontcolor_color_normal               = util.color.hex("caa560"),
	fontcolor_color_normal_over          = util.color.hex("dfc99f"),
	fontcolor_color_journal_link         = util.color.hex("253170"),
	fontcolor_color_journal_link_over    = util.color.hex("3a4daf"),
	fontcolor_color_journal_link_pressed = util.color.hex("707ecf"),
}

function getColorFromGameSettings(colorTag)
	if S_USE_VANILLA_COLORS then
		local hit = vanillaColors[colorTag:lower()]
		if hit then return hit end
	end
	local result = core.getGMST(colorTag)
	if not result then
		return util.color.rgb(1, 1, 1)
	end
	local rgb = {}
	for color in string.gmatch(result, '(%d+)') do
		table.insert(rgb, tonumber(color))
	end
	if #rgb ~= 3 then
		print("UNEXPECTED COLOR: rgb of size=", #rgb)
		return util.color.rgb(1, 1, 1)
	end
	return util.color.rgb(rgb[1] / 255, rgb[2] / 255, rgb[3] / 255)
end

function mixColors(color1, color2, mult)
	local mult = mult or 0.5
	return util.color.rgb(	color1.r * mult + color2.r * (1 - mult), 
							color1.g * mult + color2.g * (1 - mult),
							color1.b * mult + color2.b * (1 - mult))
end

function darkenColor(color, mult)
	return util.color.rgb(color.r * mult, color.g * mult, color.b * mult)
end

function getColorByChance(chance)
	if chance < 1 then
		return util.color.rgb(1, chance * 0.65, 0) -- red to orange
	elseif chance == 1 then
		return util.color.rgb(1, 1, 0) -- yellow
	else
		return util.color.rgb(math.max(0, 1 - chance / 2), 1, 0) -- yellow to green
	end
end

local skillObjectCache = {}

function getSkill(skillId)
	if not skillObjectCache[skillId] then
		local vanillaSkill = types.NPC.stats.skills[skillId]
		if vanillaSkill then
			skillObjectCache[skillId] = vanillaSkill(self)
		elseif I.SkillFramework then
			skillObjectCache[skillId] = I.SkillFramework.getSkillStat(skillId)
		end
	end
	return skillObjectCache[skillId]
end

function getResolvedSkill(skillId)
	if skillValueCache[skillId] == nil then
		local obj = getSkill(skillId)
		if obj then
			skillValueCache[skillId] = {base = obj.base, modified = obj.modified, progress = obj.progress}
		else
			skillValueCache[skillId] = false
		end
	end
	return skillValueCache[skillId]
end
-- fallback used when skill unresolved
function getModifiedSkill(skillId, fallback)
	local obj = getResolvedSkill(skillId)
	return obj and obj.modified or fallback or 0
end

function getBaseSkill(skillId, fallback)
	local obj = getResolvedSkill(skillId)
	return obj and obj.base or fallback or 0
end

function getSkillProgress(skillId)
	local obj = getResolvedSkill(skillId)
	return obj and obj.progress or 0
end

-- localized skill name, vanilla or skill framework. retries on miss
local skillNameCache = {}
function getSkillName(skillId)
	if not skillNameCache[skillId] then
		local rec = core.stats.Skill.records[skillId]
		if rec then
			skillNameCache[skillId] = rec.name
		elseif I.SkillFramework then
			local sfRec = I.SkillFramework.getSkillRecord(skillId)
			if sfRec then skillNameCache[skillId] = sfRec.name end
		end
	end
	return skillNameCache[skillId] or skillId
end

function checkSkill(recipe)
	local skill = getModifiedSkill(recipe.skill or "armorer", recipe.level) - (recipe.level or 0)
	if recipe.secondSkill then
		return math.min(skill, getModifiedSkill(recipe.secondSkill, recipe.secondLevel) - (recipe.secondLevel or 0))
	else
		return skill
	end
end

local isVanillaSkill = {
	["acrobatics"] = true,
	["alchemy"] = true,
	["alteration"] = true,
	["armorer"] = true,
	["athletics"] = true,
	["axe"] = true,
	["block"] = true,
	["bluntweapon"] = true,
	["conjuration"] = true,
	["destruction"] = true,
	["enchant"] = true,
	["handtohand"] = true,
	["heavyarmor"] = true,
	["illusion"] = true,
	["lightarmor"] = true,
	["longblade"] = true,
	["marksman"] = true,
	["mediumarmor"] = true,
	["mercantile"] = true,
	["mysticism"] = true,
	["restoration"] = true,
	["security"] = true,
	["shortblade"] = true,
	["sneak"] = true,
	["spear"] = true,
	["speechcraft"] = true,
	["unarmored"] = true,
}
function awardExp(skillId, skillGain, useType)
	if isVanillaSkill[skillId] then
		for i = 1, 4 do
			I.SkillProgression.skillUsed(skillId, { skillGain = skillGain/4, useType = useType or 0, scale = nil })
		end
	elseif I.SkillFramework and I.SkillFramework.getSkillStat(skillId) then
		for i = 1, 4 do
			I.SkillFramework.skillUsed(skillId, { skillGain = skillGain/4, useType = useType })
		end
	end
	-- invalidate snapshot so next read sees new base/progress
	skillValueCache[skillId] = nil
	-- stats: bucket exp by skill
	local stats = saveData and saveData.stats
	if stats then
		stats.perSkillExp[skillId] = (stats.perSkillExp[skillId] or 0) + skillGain
	end
end

function calculateQuality(recipe, touches, isPreview, snapshotIngredients, craftData)
	-- skill penalty: -10% per 5 levels below recipe level (additive for dual skills)
	local deficit = math.max(0, (recipe.level or 0) - getBaseSkill(recipe.skill or "armorer", recipe.level))
	if recipe.secondSkill then
		deficit = deficit + math.max(0, (recipe.secondLevel or 0) - getBaseSkill(recipe.secondSkill, recipe.secondLevel))
	end
	local skillMult = math.max(0.1, 1 - math.floor(deficit / 5) * 0.10)
	local base = skillMult
	local ctx = {
		base = base,
		modified = base,
		skillMult = skillMult,
		artisanMult = 1,
		touches = touches,
		isPreview = isPreview,
		ingredients = resolveIngredients(recipe, touches, snapshotIngredients),
		craftData = craftData or {},
	}

	if recipe.qualityFunc then
		local entry = qualityModifierChain.byId(recipe.qualityFunc)
		if entry and entry.func(recipe, ctx) == false then
			return ctx.modified
		end
	end

	return qualityModifierChain.apply(recipe, ctx, recipe.qualityFunc)
end

function getRecipeColor(recipe)
	local diffMod = math.max(0, math.min(1,
		((recipe.level or 1) / getBaseSkill(recipe.skill or "armorer", recipe.level) - 0.4) / 0.6
	))

	if recipe.secondSkill then
		local secondDiffMod = math.max(0, math.min(1,
			((recipe.secondLevel or 1) / getBaseSkill(recipe.secondSkill, recipe.secondLevel) - 0.4) / 0.6
		))
		diffMod = (diffMod + secondDiffMod) / 2
	end
	return checkSkill(recipe) < 0 and util.color.rgb(1, 0, 0) or mixColors(morrowindGold, textColor, diffMod)
end


function updateRecipeAvailability(force)
	if skillChanged or force or filterRecipes and not tempInventory then
		skillChanged = false
		for categoryIndex, category in ipairs(professions[currentProfessionName]) do
			for _, recipe in ipairs(category.recipes) do
				local skillDelta = checkSkill(recipe)
				if skillDelta >= -5 then
					if skillDelta < 0 then
						recipe.disabled = true
						recipe.textColor = util.color.rgb(1, 0, 0)
						recipe.description = "Requires " .. getSkillName(recipe.skill or "armorer") .. " level " .. (recipe.level or 0)
						if recipe.secondSkill and recipe.secondLevel and recipe.secondLevel > 5 then
							recipe.description = recipe.description .. " and " .. getSkillName(recipe.secondSkill) .. " level " .. recipe.secondLevel
						end
					else
						recipe.textColor = getRecipeColor(recipe)
						recipe.disabled = nil
						recipe.description = nil
					end
					if recipe.faction and types.NPC.getFactionRank(self, recipe.faction) < recipe.factionRank then
						if recipe.description then
							recipe.description = recipe.description .. " and " .. recipe.faction .. " rank " .. recipe.factionRank
						else
							recipe.description = "Requires " .. recipe.faction .. " rank " .. recipe.factionRank
						end
						recipe.disabled = true
						recipe.textColor = util.color.rgb(1, 0, 0)
					end
					if recipe.externallyDisabled and not saveData.enabledRecipes[recipe.id..":"..recipe.externallyDisabled] then
						if recipe.description then
							recipe.description = recipe.description .. " and " .. recipe.externallyDisabled
						else
							recipe.description = recipe.externallyDisabled
						end
						recipe.disabled = true
						recipe.textColor = util.color.rgb(1, 0, 0)
					end
				end
				-- visibility: nil = culled from list this frame, true = shown
				local hide = skillDelta < -5
					or (filterRecipes and checkIngredientsWithQueue(recipe, #craftingQueue) == 0)
					or (recipe.externallyHidden and not saveData.discoveredRecipes[recipe.id..":"..recipe.externallyHidden])
				recipe.visible = (not hide) or nil
				if cheatMode then
					recipe.visible = true
					recipe.disabled = false
					recipe.textColor = nil
					recipe.description = nil
				end
			end
		end
	end
end

------------------------------ wildcard resolution ------------------------------

-- pool snapshot for a wildcard func, grouped by getItemKey.
-- tempInv given: counts come from tempInv (queue/projection math), byKey plan.
-- tempInv nil: live counts from the func's own items, with object refs for
-- removal. consumedMap (live only): item -> already-consumed, netted out so a
-- stack shared with a fixed ingredient is not double-allocated.
function wildcardPool(func, tempInv, consumedMap)
	-- snapshot for func; nil = walk live
	local snap = nil
	if tempInv then
		snap = { byKey = tempInv, byType = tempInventoryByType or {}, byRecord = tempInventoryByRecord or {} }
	end
	local keys = {}
	-- preserves the order the wildcard func returned each unique key in
	local keyOrder = {}
	for _, item in ipairs(func(snap)) do
		local key = getItemKey(item)
		local bucket = keys[key]
		if not bucket then
			bucket = { count = 0, items = {}, sample = item }
			keys[key] = bucket
			table.insert(keyOrder, key)
		end
		if tempInv then
			table.insert(bucket.items, { item = item, avail = 0 })
		else
			local avail = item.count - (consumedMap and consumedMap[item] or 0)
			if avail < 0 then avail = 0 end
			table.insert(bucket.items, { item = item, avail = avail })
			bucket.count = bucket.count + avail
		end
	end
	if tempInv then
		for key, bucket in pairs(keys) do
			bucket.count = tempInv[key] and tempInv[key].count or 0
		end
	end
	return { byKey = tempInv ~= nil, keys = keys, keyOrder = keyOrder }
end

-- effective consume plan for a wildcard slot. pure, no mutation.
-- preferenceId: explicit pick or nil (auto). strict: lock one key, never
-- substitute. non-strict auto rolls in func-returned order across the pool.
-- byKey pool -> { key, count }; live pool -> { key, count, item } per stack.
-- returns the ordered plan and the uncovered shortfall.
function consumeWildcardPlan(pool, count, preferenceId, strict)
	local buckets = pool.keys
	local order = {}
	if strict then
		-- strict + pick: lock that key even if gone (no substitution).
		-- strict + auto: lock onto the first in-stock key in func order.
		local lock = preferenceId
		if not lock then
			for _, key in ipairs(pool.keyOrder) do
				if buckets[key].count > 0 then
					lock = key
					break
				end
			end
		end
		if lock then
			table.insert(order, lock)
		end
	else
		if preferenceId and buckets[preferenceId] and buckets[preferenceId].count > 0 then
			table.insert(order, preferenceId)
		end
		-- walk in func order; the wildcard author chose the ranking
		for _, key in ipairs(pool.keyOrder) do
			if key ~= preferenceId and buckets[key].count > 0 then
				table.insert(order, key)
			end
		end
	end

	local plan = {}
	local remaining = count
	for _, key in ipairs(order) do
		if remaining <= 0 then break end
		local b = buckets[key]
		if b then
			if pool.byKey then
				local take = math.min(b.count, remaining)
				if take > 0 then
					table.insert(plan, { key = key, count = take })
					remaining = remaining - take
				end
			else
				for _, e in ipairs(b.items) do
					if remaining <= 0 then break end
					local take = math.min(e.avail, remaining)
					if take > 0 then
						table.insert(plan, { key = key, count = take, item = e.item })
						remaining = remaining - take
					end
				end
			end
		end
	end
	return plan, math.max(0, remaining)
end

-- effective single item key for previews/display (the first item the consume
-- plan would draw). nil if nothing resolves.
function resolveWildcardKey(pool, preferenceId, strict)
	local plan = consumeWildcardPlan(pool, 1, preferenceId, strict)
	return plan[1] and plan[1].key or nil
end

function invalidateInventoryCache()
	tempInventory = nil
	tempInventoryByType = nil
	tempInventoryByRecord = nil
	tempInventoryVirtual = nil
end

function createTempInventory()
	if tempInventory then
		return tempInventory
	end
	local benchT0 = core.getRealTime()
	tempInventory = {}
	-- live-handle indices; queue entries excluded
	tempInventoryByType = {}
	tempInventoryByRecord = {}
	for _, inv in ipairs(inventorySources()) do
		for _, item in pairs(inv:getAll()) do
			local key = getItemKey(item)
			local itemTypeStr = tostring(item.type)

			-- exclude damaged tools
			local dominated = itemTypeStr == "Lockpick" or itemTypeStr == "Probe" or itemTypeStr == "Repair"
			if not dominated or types.Item.itemData(item).condition >= types[itemTypeStr].records[item.recordId].maxCondition then
				-- index by type + recordId
				if not tempInventoryByType[itemTypeStr] then
					tempInventoryByType[itemTypeStr] = {}
				end
				table.insert(tempInventoryByType[itemTypeStr], item)
				if not tempInventoryByRecord[item.recordId] then
					tempInventoryByRecord[item.recordId] = {}
				end
				table.insert(tempInventoryByRecord[item.recordId], item)

				if tempInventory[key] then
					tempInventory[key].count = tempInventory[key].count + item.count
				else
					tempInventory[key] = {
						count = item.count,
						type = itemTypeStr,
						record = item.type.record(item),
						item = item
					}
				end
			end
		end
	end

	-- virtuals: countFunc, queue-adjusted below
	tempInventoryVirtual = {}
	for id, def in pairs(virtuals or {}) do
		tempInventoryVirtual[id] = {
			count = def.countFunc and def.countFunc() or 0,
			def = def,
		}
	end

	-- apply queue changes
	for _, queueItem in ipairs(craftingQueue) do
		for _, ingredient in ipairs(queueItem.ingredients) do
			if ingredient.type == "virtual" then
				-- subtract count; skip unknown ids
				local v = tempInventoryVirtual[ingredient.virtualId]
				if v then v.count = v.count - ingredient.count end
			elseif ingredient.type ~= "wildcard" then
				local key = ingredient.id
				if tempInventory[key] then
					-- keep negative counts for queue math
					tempInventory[key].count = tempInventory[key].count - ingredient.count
				else
					local ingredientRecord = nil
					if ingredient.type and types[ingredient.type] and types[ingredient.type].records then
						ingredientRecord = types[ingredient.type].records[ingredient.id]
					end

					tempInventory[key] = {
						count = -ingredient.count,
						type = ingredient.type or "Unknown",
						record = ingredientRecord,
						item = nil
					}
				end
			else
				-- wildcard: effective consume against the running temp
				-- inventory. baked preference (nil = auto) re-resolves each
				-- queued craft, so a decimated stack rolls to next-best.
				local pool = wildcardPool(ingredient.func, tempInventory)
				local plan = consumeWildcardPlan(pool, ingredient.count, ingredient.preferenceId, ingredient.strict)
				for _, e in ipairs(plan) do
					if tempInventory[e.key] then
						-- keep negative counts for queue math
						tempInventory[e.key].count = tempInventory[e.key].count - e.count
					end
				end
			end
		end

		-- add result
		local resultKey = queueItem.result.id
		if tempInventory[resultKey] then
			tempInventory[resultKey].count = tempInventory[resultKey].count + queueItem.result.count
		else
			local resultType = queueItem.result.type or "Unknown"
			local resultRecord = nil
			if resultType ~= "Unknown" and types[resultType] and types[resultType].records then
				resultRecord = types[resultType].records[resultKey]
			end

			tempInventory[resultKey] = {
				count = queueItem.result.count,
				type = resultType,
				record = resultRecord,
				item = nil -- not available until craft completes
			}
		end

		-- additional products
		for _, product in ipairs(queueItem.result.additionalProducts or {}) do
			local productKey = product.id
			if tempInventory[productKey] then
				tempInventory[productKey].count = tempInventory[productKey].count + product.count
			else
				local productRecord = types[product.type] and types[product.type].records[productKey]
				tempInventory[productKey] = {
					count = product.count,
					type = product.type,
					record = productRecord,
					item = nil
				}
			end
		end
	end
	return tempInventory
end

function findItemsByModelAndWeight(tempInventory, itemType, targetModel, targetWeight)
	local totalCount = 0
	local bestRecord = nil

	for itemId, data in pairs(tempInventory) do
		if data.type == itemType and data.record
		and data.record.model == targetModel
		and data.record.weight == targetWeight
		and not data.record.enchant
		then
			totalCount = totalCount + data.count
			if not bestRecord or data.count > 0 then
				bestRecord = data.record
			end
		end
	end

	return totalCount, bestRecord
end

--- pool total + a representative record, queue-adjusted.
--- record falls back to any qualifying item even when none are in stock.
---@param tempInventory table
---@param wildcardFunc function
---@return integer
---@return any
function findWildcardItems(tempInventory, wildcardFunc)
	local pool = wildcardPool(wildcardFunc, tempInventory)
	local totalCount = 0
	local bestRecord = nil
	local bestCount = 0
	for _, b in pairs(pool.keys) do
		if b.count > 0 then
			totalCount = totalCount + b.count
			if b.count > bestCount then
				bestCount = b.count
				bestRecord = b.sample.type.record(b.sample)
			end
		end
	end
	if not bestRecord then
		for _, b in pairs(pool.keys) do
			bestRecord = b.sample.type.record(b.sample)
			break
		end
	end
	return totalCount, bestRecord
end

--- check ingredient availability with queue consideration
---@param ingredient Ingredient
---@return any
---@return integer
function checkIngredientWithQueue(ingredient)
	local ingredientRecord
	local adjustedCount = 0

	createTempInventory()
	---@cast tempInventory -?

	if ingredient.type == "wildcard" then
		adjustedCount, ingredientRecord = findWildcardItems(tempInventory, ingredient.func)
	elseif ingredient.type and (ingredient.type == "Armor" or ingredient.type == "Weapon") then
		-- armor/weapons: match by model
		local targetRecord = types[ingredient.type].records[ingredient.id]
		if not targetRecord then
			return nil, 0
		end


		adjustedCount = 0
		for itemId, data in pairs(tempInventory) do
			if data.type == ingredient.type and data.record
			and data.record.model == targetRecord.model
			and (data.record.id:sub(1, 10) == "Generated:" or not data.record.enchant)
			then
				adjustedCount = adjustedCount + data.count
				if not ingredientRecord or data.count > 0 then
					ingredientRecord = data.record
				end
			end
		end

		-- fallback: target record
		if not ingredientRecord then
			ingredientRecord = targetRecord
		end
	else
		if tempInventory[ingredient.id] then
			adjustedCount = tempInventory[ingredient.id].count
			ingredientRecord = tempInventory[ingredient.id].record
		else
			adjustedCount = 0
		end

		-- load fallback record
		if not ingredientRecord and ingredient.type and types[ingredient.type] and ingredient.id then
			ingredientRecord = types[ingredient.type].records[ingredient.id]
		end
	end

	return ingredientRecord, math.max(0, adjustedCount)
end

function checkIngredientsWithQueue(recipe, queueLength)
	if not recipe or not recipe.ingredients then return 0 end
	if cheatMode then
		return 10
	end
	
	createTempInventory()
	
	for _, tool in ipairs(recipe.tools or {}) do
		if tool.type == "wildcard" then
			local pool = wildcardPool(tool.func, tempInventory)
			local _, short = consumeWildcardPlan(pool, 1, wildcardPreferences[tool.wildcardId], false)
			if short > 0 then return 0 end
		else
			local _, adjustedCount = checkIngredientWithQueue({
				type = tool.type,
				id = tool.id,
				count = 1,
			})
			if adjustedCount < 1 then return 0 end
		end
	end
	
	local allIngredients = getIngredients(recipe, getActiveTouches(recipe))
	
	-- precompute fixed
	local maxFromFixed = 999999
	local fixedUsage = {}
	local fixedCounts = {}
	
	for _, ingredient in ipairs(allIngredients) do
		if ingredient.type == "virtual" then
			-- queue-adjusted count
			local v = tempInventoryVirtual and tempInventoryVirtual[ingredient.virtualId]
			local available = v and math.max(0, v.count) or 0
			maxFromFixed = math.min(maxFromFixed, math.floor(available / ingredient.count))
		elseif ingredient.type ~= "wildcard" then
			local _, adjustedCount = checkIngredientWithQueue(ingredient)
			maxFromFixed = math.min(maxFromFixed, math.floor(adjustedCount / ingredient.count))
			fixedUsage[ingredient.id] = ingredient.count
			fixedCounts[ingredient.id] = adjustedCount
		end
	end
	
	if maxFromFixed == 0 then
		return 0
	end
	
	-- precompute wildcards; strict ones lock to the resolved key
	local wildcardData = {}
	for _, ingredient in ipairs(allIngredients) do
		if ingredient.type == "wildcard" then
			local items = {}
			local pool = wildcardPool(ingredient.func, tempInventory)
			local pref = wildcardPreferences[ingredient.wildcardId]
			if ingredient.strict then
				local key = resolveWildcardKey(pool, pref, true)
				local b = key and pool.keys[key]
				if b and b.count > 0 then
					table.insert(items, {
						key = key,
						count = b.count,
						fixedNeed = fixedUsage[key] or 0
					})
				end
			else
				for key, b in pairs(pool.keys) do
					if b.count > 0 then
						table.insert(items, {
							key = key,
							count = b.count,
							fixedNeed = fixedUsage[key] or 0
						})
					end
				end
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

function refreshRecipesAndWindow()
	if WINDOW.craftingWindow then
		updateRecipeAvailability()

		refreshRecipeList()
		updateinfoContent()
	end
end

function addToCraftingQueue(recipe, count, shiftPressed)
	count = count or 1
	-- snapshot per-touch gate (getActiveTouches handles per-recipe gating)
	local touches = getActiveTouches(recipe)
	for i = 1, count do
		-- snapshot ingredients; resolve wildcards
		local snapshotIngredients = {}
		for _, ingredient in ipairs(getIngredients(recipe, touches)) do
			local copy = {
				type = ingredient.type,
				id = ingredient.id,
				func = ingredient.func,
				name = ingredient.name,
				count = ingredient.count,
				strict = ingredient.strict,
			}
			if ingredient.type == "wildcard" then
				copy.wildcardId = ingredient.wildcardId
				-- bake the explicit pick only; auto stays auto (nil) and
				-- re-resolves best-available per queued craft.
				copy.preferenceId = wildcardPreferences[ingredient.wildcardId]
			elseif ingredient.type == "virtual" then
				-- carry id for feasibility/consume
				copy.virtualId = ingredient.virtualId
			end
			table.insert(snapshotIngredients, copy)
		end
		local snapshotTools = {}
		for _, tool in ipairs(recipe.tools or {}) do
			local copy = {
				type = tool.type,
				id = tool.id,
				func = tool.func,
				name = tool.name,
				count = 1,
			}
			if tool.type == "wildcard" then
				copy.wildcardId = tool.wildcardId
				copy.preferenceId = wildcardPreferences[tool.wildcardId]
			end
			table.insert(snapshotTools, copy)
		end
		table.insert(craftingQueue, {
			recipe = recipe,
			id = recipe.id,
			ingredients = snapshotIngredients,
			tools = snapshotTools,
			touches = touches,
			result = {
				id = recipe.id,
				count = recipe.count or 1,
				type = recipe.type,
				additionalProducts = recipe.additionalProducts,
			},
			shiftPressed = shiftPressed
		})
	end
	invalidateInventoryCache()
	if filterRecipes then
		updateRecipeAvailability(true)
	end
	refreshRecipesAndWindow()
	craftItem()
end

function clearCraftingQueue()
	craftingQueue = {}
	pendingInventoryChanges = {}
	craftingState.isActive = false
	craftingState.queueProcessing = false
	hud_craftingFrameworkProgress.layout.props.visible = false
	hud_craftingFrameworkProgress:update()
	invalidateInventoryCache()
end
API.clearCraftingQueue = clearCraftingQueue -- bare-used internally (craftItem, ui_craftingWindow)

-- both paths shallow-copy wildcard entries and stamp the effective selectedId
-- (preference if available, else best-available). snapshot path takes the
-- baked preferenceId; preview path reads the live preference store. never
-- mutates recipe.ingredients.
function resolveIngredients(recipe, touches, snapshotIngredients)
	local ingredients = snapshotIngredients or getIngredients(recipe, touches)
	-- preview: snapshot; craft: live walk
	local snap = nil
	if not snapshotIngredients then
		createTempInventory()
		snap = tempInventory
	end
	local resolved = {}
	for i, ingredient in ipairs(ingredients) do
		if ingredient.type == "wildcard" then
			local pref = snapshotIngredients and ingredient.preferenceId
				or wildcardPreferences[ingredient.wildcardId]
			resolved[i] = {
				type = ingredient.type,
				id = ingredient.id,
				func = ingredient.func,
				name = ingredient.name,
				count = ingredient.count,
				strict = ingredient.strict,
				wildcardId = ingredient.wildcardId,
				preferenceId = pref,
				selectedId = resolveWildcardKey(wildcardPool(ingredient.func, snap), pref, ingredient.strict),
			}
		else
			resolved[i] = ingredient
		end
	end
	return resolved
end

function calculateResultValue(recipe, touches, qualityMult, isPreview, snapshotIngredients, craftData)
	local itemValue = 0
	local ingredients = resolveIngredients(recipe, touches, snapshotIngredients)
	for _, ingredient in ipairs(ingredients) do
		if ingredient.type == "wildcard" then
			-- resolve selected wildcard item; fall back to 10 gold
			local wildcardValue = 10
			if ingredient.selectedId and ingredient.func then
				for _, item in ipairs(ingredient.func()) do
					if getItemKey(item) == ingredient.selectedId then
						local rec = item.type.record(item)
						if rec and rec.value then
							wildcardValue = rec.value
						end
						break
					end
				end
			end
			itemValue = itemValue + wildcardValue * ingredient.count
		elseif ingredient.type:lower() == "ingredient" and types.Ingredient.records[ingredient.id] then
			itemValue = itemValue + (types.Ingredient.records[ingredient.id].value or 1) * ingredient.count
		end
	end
	itemValue = itemValue / (recipe.count or 1)

	itemValue = itemValue * (recipe.level / 100 * 1.5 + 0.5)
	local ctx = {
		base = itemValue,
		modified = itemValue,
		touches = touches,
		qualityMult = qualityMult,
		ingredients = ingredients,
		isPreview = isPreview,
		craftData = craftData or {},
	}
	if recipe.valueFunc then
		local entry = valueModifierChain.byId(recipe.valueFunc)
		if entry and entry.func(recipe, ctx) == false then
			return ctx.modified
		end
	end
	return valueModifierChain.apply(recipe, ctx, recipe.valueFunc)
end

-- runs first so other chains see the swapped target. invalid id -> fallback to recipe.id.
function resolveResultItem(recipe, touches, isPreview, snapshotIngredients, craftData)
	local base = recipe.id
	local ctx = {
		base = base,
		modified = base,
		touches = touches,
		ingredients = resolveIngredients(recipe, touches, snapshotIngredients),
		isPreview = isPreview,
		craftData = craftData or {},
	}
	local result
	if recipe.resultFunc then
		local entry = resultItemModifierChain.byId(recipe.resultFunc)
		if entry and entry.func(recipe, ctx) == false then
			result = ctx.modified or base
		end
	end
	if not result then
		result = resultItemModifierChain.apply(recipe, ctx, recipe.resultFunc) or base
	end
	-- validate modifier-supplied id, fall back on miss
	local rtype = getItemType(result)
	if not rtype and result ~= base then
		print("\27[91m resolveResultItem: modifier returned invalid recordId '" .. tostring(result) .. "' for recipe '" .. tostring(base) .. "', falling back")
		result = base
		rtype = getItemType(base)
	end
	return result, rtype or recipe.type
end

-- resultId/resultType passed in so modifiers can branch on the swap.
function resolveResultCount(recipe, touches, isPreview, snapshotIngredients, craftData, resultId, resultType)
	local base = recipe.count or 1
	local ctx = {
		base = base,
		modified = base,
		touches = touches,
		ingredients = resolveIngredients(recipe, touches, snapshotIngredients),
		isPreview = isPreview,
		craftData = craftData or {},
		resultId = resultId,
		resultType = resultType,
	}
	if recipe.countFunc then
		local entry = resultCountModifierChain.byId(recipe.countFunc)
		if entry and entry.func(recipe, ctx) == false then
			return ctx.modified or base
		end
	end
	return resultCountModifierChain.apply(recipe, ctx, recipe.countFunc) or base
end

-- nil result means callers should fall back to record.name.
function resolveRecipeName(recipe, touches, qualityMult, isPreview, snapshotIngredients, craftData)
	local base = recipe.name
	local ctx = {
		base = base,
		modified = base,
		touches = touches,
		qualityMult = qualityMult,
		ingredients = resolveIngredients(recipe, touches, snapshotIngredients),
		isPreview = isPreview,
		craftData = craftData or {},
	}
	if recipe.nameFunc then
		local entry = recipeNameModifierChain.byId(recipe.nameFunc)
		if entry and entry.func(recipe, ctx) == false then
			return ctx.modified
		end
	end
	return recipeNameModifierChain.apply(recipe, ctx, recipe.nameFunc)
end

-- returns base duration; player-skill/speed scaling applied later.
function calculateCraftingTime(recipe, touches, snapshotIngredients, craftData)
	local base = recipe.craftingTime or 5
	local ctx = {
		base = base,
		modified = base,
		touches = touches,
		ingredients = resolveIngredients(recipe, touches, snapshotIngredients),
		craftData = craftData or {},
	}
	if recipe.timeFunc then
		local entry = timeModifierChain.byId(recipe.timeFunc)
		if entry and entry.func(recipe, ctx) == false then
			return ctx.modified
		end
	end
	return timeModifierChain.apply(recipe, ctx, recipe.timeFunc)
end

function calculateItemExp(recipe, touches)
	if recipe.experience then
		return recipe.experience
	end
	local itemValue = 0.5
	for _, ingredient in pairs(getIngredients(recipe, touches)) do
		-- skip virtuals, count might be huge
		if ingredient.type ~= "virtual" then
			if ore_difficulties[ingredient.id] then
				itemValue = itemValue + ingredient.count * (ore_difficulties[ingredient.id] ^ 0.18 - 0.1) *	(ingredientExpMultipliers[ingredient.id] or 1)
			else
				itemValue = itemValue + ingredient.count * 0.9 * (ingredientExpMultipliers[ingredient.id] or 1)
			end
		end
	end
	-- artisans xp bonus lives in the xp chain (CF_recipes/_artisansTouch.lua)
	return itemValue * 3
end

-- exp per skill for a recipe: { [skillId] = value }. modifiers mutate ctx.modified[skillId].
function calculateRecipeExp(recipe, touches, ingredients, craftData, isPreview)
	local recipeExp = calculateItemExp(recipe, touches) * S_GLOBAL_EXP_MULT
	local fileExpMult = (recipe.sourceFile and S_FILE_EXP_MULTS[recipe.sourceFile]) or 1
	local splittedExp = recipe.secondSkill ~= nil
	-- previews don't pass ingredients; resolve from inventory and fill any shortfall
	-- with synthetic entries so modifiers see the full intended plan.
	-- resolveIngredients (not getIngredients) so live wildcard preferences are stamped.
	if not ingredients and resolveConsumedIngredients then
		ingredients = resolveConsumedIngredients(recipe, resolveIngredients(recipe, touches), true)
	end
	local base = {}
	local skills = {}
	-- per-skill base. artisans diffMod^0.5 lives in the xp chain
	local function addSkill(skillId, level, isSecondSkill)
		local diffMod = math.max(0.4, math.min(1, level / getBaseSkill(skillId, level)))
		local skillExpMult = S_SKILL_EXP_MULTS[skillId] or 1
		local b = diffMod * recipeExp * fileExpMult * skillExpMult
		-- split recipes halve each per-skill award
		if splittedExp then b = b / 2 end
		base[skillId] = (base[skillId] or 0) + b
		skills[skillId] = {
			diffMod = diffMod,
			level = level,
			skillExpMult = skillExpMult,
			isSecondSkill = isSecondSkill,
		}
	end
	addSkill(recipe.skill or "armorer", recipe.level or 1, false)
	if recipe.secondSkill then
		addSkill(recipe.secondSkill, recipe.secondLevel or 1, true)
	end
	-- modified starts as a copy of base; modifiers mutate it
	local modified = {}
	for k, v in pairs(base) do modified[k] = v end
	local ctx = {
		base = base,
		modified = modified,
		recipe = recipe,
		recipeExp = recipeExp,
		touches = touches,
		skills = skills,
		ingredients = ingredients or {},
		globalExpMult = S_GLOBAL_EXP_MULT,
		fileExpMult = fileExpMult,
		splittedExp = splittedExp,
		isPreview = isPreview or false,
		craftData = craftData,
	}
	-- recipe-tied modifier runs first; false halts, otherwise chain runs.
	if recipe.expFunc then
		local entry = expModifierChain.byId(recipe.expFunc)
		if entry and entry.func(recipe, ctx) == false then
			return ctx.modified
		end
	end
	return expModifierChain.apply(recipe, ctx, recipe.expFunc)
end

function getEquipmentSlot(item)
	if (item == nil) then
		return
	end

	if item.type == types.Armor then
		local armorRecord = types.Armor.records[item.recordId]
		if (armorRecord.type == types.Armor.TYPE.RGauntlet) then
			return types.Actor.EQUIPMENT_SLOT.RightGauntlet
		elseif (armorRecord.type == types.Armor.TYPE.LGauntlet) then
			return types.Actor.EQUIPMENT_SLOT.LeftGauntlet
		elseif (armorRecord.type == types.Armor.TYPE.Boots) then
			return types.Actor.EQUIPMENT_SLOT.Boots
		elseif (armorRecord.type == types.Armor.TYPE.Cuirass) then
			return types.Actor.EQUIPMENT_SLOT.Cuirass
		elseif (armorRecord.type == types.Armor.TYPE.Greaves) then
			return types.Actor.EQUIPMENT_SLOT.Greaves
		elseif (armorRecord.type == types.Armor.TYPE.LBracer) then
			return types.Actor.EQUIPMENT_SLOT.LeftGauntlet
		elseif (armorRecord.type == types.Armor.TYPE.RBracer) then
			return types.Actor.EQUIPMENT_SLOT.RightGauntlet
		elseif (armorRecord.type == types.Armor.TYPE.RPauldron) then
			return types.Actor.EQUIPMENT_SLOT.RightPauldron
		elseif (armorRecord.type == types.Armor.TYPE.LPauldron) then
			return types.Actor.EQUIPMENT_SLOT.LeftPauldron
		elseif (armorRecord.type == types.Armor.TYPE.RPauldron) then
			return types.Actor.EQUIPMENT_SLOT.RightPauldron
		elseif (armorRecord.type == types.Armor.TYPE.Helmet) then
			return types.Actor.EQUIPMENT_SLOT.Helmet
		elseif (armorRecord.type == types.Armor.TYPE.Shield) then
			return types.Actor.EQUIPMENT_SLOT.CarriedLeft
		end
	elseif item.type == types.Clothing then
		local clothingRecord = types.Clothing.records[item.recordId]
		if (clothingRecord.type == types.Clothing.TYPE.Amulet) then
			return types.Actor.EQUIPMENT_SLOT.Amulet
		elseif (clothingRecord.type == types.Clothing.TYPE.Belt) then
			return types.Actor.EQUIPMENT_SLOT.Belt
		elseif (clothingRecord.type == types.Clothing.TYPE.LGlove) then
			return types.Actor.EQUIPMENT_SLOT.LeftGauntlet
		elseif (clothingRecord.type == types.Clothing.TYPE.RGlove) then
			return types.Actor.EQUIPMENT_SLOT.RightGauntlet
		elseif (clothingRecord.type == types.Clothing.TYPE.Ring) then
			return types.Actor.EQUIPMENT_SLOT.RightRing
		elseif (clothingRecord.type == types.Clothing.TYPE.Skirt) then
			return types.Actor.EQUIPMENT_SLOT.Skirt
		elseif (clothingRecord.type == types.Clothing.TYPE.Shirt) then
			return types.Actor.EQUIPMENT_SLOT.Shirt
		elseif (clothingRecord.type == types.Clothing.TYPE.Shoes) then
			return types.Actor.EQUIPMENT_SLOT.Boots
		elseif (clothingRecord.type == types.Clothing.TYPE.Robe) then
			return types.Actor.EQUIPMENT_SLOT.Robe
		elseif (clothingRecord.type == types.Clothing.TYPE.Pants) then
			return types.Actor.EQUIPMENT_SLOT.Pants
		end
	elseif item.type == types.Weapon then
		local weaponRecord = item.type.records[item.recordId]
		if (weaponRecord.type == types.Weapon.TYPE.Arrow or weaponRecord.type == types.Weapon.TYPE.Bolt) then
			return types.Actor.EQUIPMENT_SLOT.Ammunition
		end
		return types.Actor.EQUIPMENT_SLOT.CarriedRight
	elseif item.type == types.Lockpick then
		return types.Actor.EQUIPMENT_SLOT.CarriedRight
	elseif item.type == types.Probe then
		return types.Actor.EQUIPMENT_SLOT.CarriedRight
	elseif item.type == types.Light then
		return types.Actor.EQUIPMENT_SLOT.CarriedLeft
	end
	return nil
end


MATERIALCOUNT = 5
TOOLCOUNT = 3
STATIONCOUNT = 3

function printInvalidRecords(invalidFactions)
    if next(invalidFactions) then
        print("invalid factions:")
        for a in pairs(invalidFactions) do
            print("'" .. a .. "'")
        end
    end
end

-- one-time validation of profession skills
local recipeSkillsValidated = false
function validateRecipeSkills(professions)
    if recipeSkillsValidated then return end
    recipeSkillsValidated = true
    local invalidSkills = {}
    local professionSkills = {}
	-- count skills for each profession, flag invalid skills
    for professionName, categories in pairs(professions or {}) do
        local needsAutoRegister = professionSkills[professionName] == nil
        for _, sortedCategory in ipairs(categories) do
            for _, recipe in ipairs(sortedCategory.recipes) do
                local firstSkill = recipe.skill or "armorer"
				firstSkill = getSkill(firstSkill) and firstSkill or false
                local secondSkill = recipe.secondSkill and getSkill(recipe.secondSkill) and recipe.secondSkill or false
                if recipe.skill and not firstSkill then
                    invalidSkills[recipe.skill] = true
                    recipe.warnings = recipe.warnings or {}
                    table.insert(recipe.warnings, "missing skill: " .. recipe.skill)
                end
                if recipe.secondSkill and not secondSkill then
                    invalidSkills[recipe.secondSkill] = true
                    recipe.warnings = recipe.warnings or {}
                    table.insert(recipe.warnings, "missing skill: " .. recipe.secondSkill)
                end
                if needsAutoRegister then
                    professionSkills[professionName] = professionSkills[professionName] or {}
                    if firstSkill then
                        professionSkills[professionName][firstSkill] = (professionSkills[professionName][firstSkill] or 0) + 1.3
                    end
                    if secondSkill then
                        professionSkills[professionName][secondSkill] = (professionSkills[professionName][secondSkill] or 0) + 1
                    end
                end
            end
        end
    end
    -- auto-register unregistered professions
    for professionName, tbl in pairs(professionSkills) do
        local bestSkill, bestCount = "armorer", 0
        for skillId, count in pairs(tbl) do
            if count > bestCount then
                bestSkill = skillId
                bestCount = count
            end
        end
        registerProfession{ name = professionName, skillId = bestSkill }
        print("auto-registered profession '" .. professionName .. "' -> skill '" .. bestSkill .. "'")
    end
    if next(invalidSkills) then
        print("invalid skills:")
        for a in pairs(invalidSkills) do
            print("'" .. a .. "'")
        end
    end
end

function getItemType(id)
    if id then
        id = id:lower()
        if types.Ingredient.records[id] then
            return "Ingredient"
        elseif types.Weapon.records[id] then
            return "Weapon"
        elseif types.Armor.records[id] then
            return "Armor"
        elseif types.Miscellaneous.records[id] then
            return "Miscellaneous"
        elseif types.Repair.records[id] then
            return "Repair"
        elseif types.Probe.records[id] then
            return "Probe"
        elseif types.Potion.records[id] then
            return "Potion"
        elseif types.Lockpick.records[id] then
            return "Lockpick"
        elseif types.Light.records[id] then
            return "Light"
        elseif types.Clothing.records[id] then
            return "Clothing"
        elseif types.Book.records[id] then
            return "Book"
        elseif types.Apparatus.records[id] then
            return "Apparatus"
        end
    end
    return nil
end

function view(t, depth)
    depth = depth or 0
    local indent = string.rep("    ", depth)
	
	if type(t) ~= "table" then
		print(indent..tostring(t).." (ERROR)")
		return
	end
	
    for key, value in pairs(t) do
        local formatted

        if type(value) == "string" then
            formatted = string.format("%q", value) -- Properly quoted string
        elseif type(value) == "table" then
            formatted = "{"
        else
            formatted = tostring(value)
        end

        print(string.format("%s[%s] = %s", indent, type(key) == "string" and '"'..tostring(key)..'"' or tostring(key), formatted))

        if type(value) == "table" then
            view(value, depth + 1)
            print(indent .. "}")
        end
    end
end


-- returns recipe, category or nil, errorMessage
function createRecipe(recipe, invalidFactions)
    -- normalize simple fields
    recipe.id = (recipe.id or ""):lower()
    recipe.types = recipe.types or ""
    recipe.craftingCategory = recipe.craftingCategory or ""
    recipe.level = tonumber(recipe.level) or 0
    recipe.producedCountOpt = tonumber(recipe.producedCountOpt)
    recipe.craftingTime = tonumber(recipe.craftingTime)
    recipe.experience = tonumber(recipe.experience)
    recipe.secondLevel = tonumber(recipe.secondLevel)
    recipe.factionRank = recipe.factionRank and recipe.factionRank ~= "" and tonumber(recipe.factionRank) or nil
    recipe.faction = recipe.faction and recipe.faction ~= "" and recipe.faction or nil
    recipe.skill = recipe.skill and recipe.skill ~= "" and recipe.skill:lower() or nil
    recipe.secondSkill = recipe.secondSkill and recipe.secondSkill ~= "" and recipe.secondSkill:lower() or nil
    recipe.craftingSound = recipe.craftingSound and recipe.craftingSound ~= "" and recipe.craftingSound or nil
    recipe.nameOpt = recipe.nameOpt and recipe.nameOpt ~= "" and recipe.nameOpt or nil
    recipe.disabled = recipe.disabled and recipe.disabled ~= "" and recipe.disabled or nil
    recipe.hidden = recipe.hidden and recipe.hidden ~= "" and recipe.hidden or nil
    recipe.ingredients = recipe.ingredients or {}
    recipe.tools = recipe.tools or {}
    recipe.stations = recipe.stations or {}
    -- preserve prefix
    if recipe.id:sub(1, 1) == "!" then
        recipe.preserveRecordId = true
        recipe.id = recipe.id:sub(2)
    end

    if recipe.id == "" then
        return nil, "empty id"
    end

    local isProjectile = recipe.types == "Ammo"
    local resultType = types[recipe.types] and recipe.types or "Weapon"

    local count = recipe.producedCountOpt or (isProjectile and 20 or 1)
    if count <= 0 then
        count = 1
    end

    if recipe.craftingTime and recipe.craftingTime <= 0 then
        recipe.craftingTime = 1
    end

    -- parse warnings for window info panel
    local warnings = {}

    -- skills validated lazily on first window open; SkillFramework must register first
    if recipe.craftingSound and not craftingSounds[recipe.craftingSound] and not core.sound.records[recipe.craftingSound] and not vfs.fileExists(recipe.craftingSound) then
        print("invalid crafting sound: " .. recipe.craftingSound)
        table.insert(warnings, "unknown crafting sound: " .. recipe.craftingSound)
        recipe.craftingSound = nil
    end

    if not recipe.factionRank or not recipe.faction or not core.factions.records[recipe.faction] then
        if recipe.factionRank and recipe.faction then
            invalidFactions[recipe.faction] = true
            table.insert(warnings, "unknown faction: " .. recipe.faction)
        end
        recipe.faction = nil
        recipe.factionRank = nil
    end

    -- resolve record type
    local record = types[resultType] and types[resultType].record(recipe.id)
    if not record then
        local detected = getItemType(recipe.id)
        if detected then
            resultType = detected
            record = types[resultType] and types[resultType].record(recipe.id)
        end
    end

    if not record then
        return nil, "invalid record: " .. resultType .. "." .. recipe.id
    end
	
    -- build ingredients
    local ingredients = {}
    for _, mat in ipairs(recipe.ingredients) do
        local material = mat.id or ""
        local amount = tonumber(mat.count) or 0
        if amount > 0 and material ~= "" and recipe.level >= 1 then
            -- aliases live in tsvParser (legacy tsv only)
            local materialId = material
            if wildcards[material] then
                table.insert(ingredients, {
                    type = "wildcard",
                    wildcardId = material,
                    func = wildcards[material],
                    count = amount,
                    name = wildcardNames[material] or material,
                    icon = wildcardIcons[material],
                    strict = wildcardStrict[material] or false,
                })
            elseif virtuals[material] then
                -- virtual: resolved live from def
                table.insert(ingredients, {
                    type = "virtual",
                    virtualId = material,
                    count = amount,
                })
            else
                local materialType = getItemType(materialId)
                if materialType then
                    table.insert(ingredients, {
                        type = materialType,
                        id = materialId:lower(),
                        count = amount,
                    })
                else
                    print("WARNING: " .. material:lower() .. " in " .. recipe.id)
                    table.insert(warnings, "unknown ingredient: " .. material:lower())
                end
            end
        end
    end

    -- build tools
    local tools = {}
    for _, t in ipairs(recipe.tools) do
        local tool = t.id or ""
        if tool ~= "" then
            if wildcards[tool] then
                table.insert(tools, {
                    type = "wildcard",
                    wildcardId = tool,
                    func = wildcards[tool],
                    name = wildcardNames[tool] or tool,
                    icon = wildcardIcons[tool],
                })
            else
                local toolType = getItemType(tool)
                if toolType then
                    table.insert(tools, {
                        type = toolType,
                        id = tool:lower(),
                    })
                elseif #tool > 1 then
                    print("WARNING: invalid tool " .. tool .. " in " .. recipe.id)
                    table.insert(warnings, "unknown tool: " .. tool)
                end
            end
        end
    end

    -- build stations
    local recipeStations = {}
    for _, s in ipairs(recipe.stations) do
        local station = s.id or ""
        if station ~= "" then
            if stations[station] then
                table.insert(recipeStations, {
                    type = "wildcard",
                    func = stations[station],
                    name = station,
                })
            else
                local stationType = getItemType(station)
                if stationType then
                    table.insert(recipeStations, {
                        type = stationType,
                        id = station:lower(),
                    })
                else
                    print("WARNING: invalid station " .. station .. " in " .. recipe.id)
                    table.insert(warnings, "unknown station: " .. station)
                end
            end
        end
    end

    -- build additional products
    local additionalProducts = {}
    for _, p in ipairs(recipe.additionalProducts or {}) do
        local productId = (p.id or ""):lower()
        local productCount = tonumber(p.count) or 1
        if productId ~= "" and productCount > 0 then
            local productType = p.types or p.type
            if productType and types[productType] and types[productType].records[productId] then
                -- explicit type valid
            else
                productType = getItemType(productId)
            end
            if productType then
                table.insert(additionalProducts, {
                    id = productId,
                    type = productType,
                    count = productCount,
                })
            else
                print("WARNING: invalid product " .. productId .. " in " .. recipe.id)
                table.insert(warnings, "unknown product: " .. productId)
            end
        end
    end

    -- final validation
    if #ingredients == 0 or recipe.level < 1 then
        return nil, recipe.id.." = no ingredients or level < 1"
    end

    -- category
    local category = isProjectile and "Ammo" or (categoryMapping[recipe.craftingCategory] or recipe.craftingCategory)
	
    local profession = recipe.profession and recipe.profession ~= "" and recipe.profession or "Crafting"
	local displayName = recipe.nameOpt or record.name or ""..math.random()
	local uid = displayName
	if usedUids[uid] then
		local i = 2
		while usedUids[uid..":"..i] do
			i=i+1
		end
		uid = uid..":"..i
	end
	usedUids[uid] = true
	
	local craftingEvent
	if recipe.craftingEvent ~= "" then
		craftingEvent = recipe.craftingEvent
	end
	
    return {
        type = resultType,
        id = recipe.id,
        name = recipe.nameOpt,
        count = count,
        level = recipe.level,
        ingredients = ingredients,
        tools = #tools > 0 and tools or nil,
        stations = #recipeStations > 0 and recipeStations or nil,
        faction = recipe.faction,
        factionRank = recipe.factionRank,
        externallyDisabled = recipe.disabled,
        externallyHidden = recipe.hidden,
        craftingSound = recipe.craftingSound,
        craftingTime = recipe.craftingTime,
        experience = recipe.experience,
        skill = recipe.skill,
        secondLevel = recipe.secondLevel,
        secondSkill = recipe.secondSkill,
        preserveRecordId = recipe.preserveRecordId,
		displayName = displayName,
		uid = uid,
		manualProgress = recipe.manualProgress,
		profession = profession,
		craftingEvent = craftingEvent,
		qualityFunc = recipe.qualityFunc,
		expFunc = recipe.expFunc,
		statsFunc = recipe.statsFunc,
		enchantmentFunc = recipe.enchantmentFunc,
		valueFunc = recipe.valueFunc,
		resultFunc = recipe.resultFunc,
		countFunc = recipe.countFunc,
		nameFunc = recipe.nameFunc,
		ingredientsFunc = recipe.ingredientsFunc,
		timeFunc = recipe.timeFunc,
		finalizeCraftFunc = recipe.finalizeCraftFunc,
		userData = recipe.userData,
		craftingInterval = tonumber(recipe.craftingInterval),
		additionalProducts = #additionalProducts > 0 and additionalProducts or nil,
		warnings = #warnings > 0 and warnings or nil,
    }, category, profession
end

------------------------------ text tooltip ------------------------------
-- cursor-anchored bordered text tooltip. makeTextTooltip returns the live
-- element; addTextTooltip wires hover/move on a live element, chaining any
-- existing focusGain/focusLoss/mouseMove. shared slot WINDOW.textTooltip.

TOOLTIP_FONT_SIZE = 20
TOOLTIP_FONT_COLOR = util.color.hex("dfc99f")
TOOLTIP_OPACITY = 0.8
TOOLTIP_LAYER = "Notification"

local borderTemplate
local function ensureBorderTemplate()
	if borderTemplate then return borderTemplate end
	borderTemplate = makeBorder("thin", nil, 1, {
		type = ui.TYPE.Image,
		props = {
			resource = ui.texture { path = "black" },
			relativeSize = v2(1, 1),
			alpha = TOOLTIP_OPACITY,
		},
	}).borders
	return borderTemplate
end

-- generic: caller supplies a ui.content array (or whatever fits as content).
-- bordered Flex container, fixed bottom-right anchor at cursor.
function makeTooltip(position, content)
	local offsetX = 13
	local offsetY = 25
	return ui.create{
		type = ui.TYPE.Flex,
		layer = TOOLTIP_LAYER,
		template = ensureBorderTemplate(),
		props = {
			autoSize = true,
			anchor = v2(0, 0),
			position = v2(position.x + offsetX, position.y + offsetY),
		},
		content = content,
		userData = {
			offset = v2(offsetX, offsetY),
		},
	}
end

-- wraps text with 2/5 vertical and 4/5 horizontal padding
function makeTextTooltip(position, text)
	return makeTooltip(position, ui.content {
		{ props = { size = v2(1, 1) } },
		{
			type = ui.TYPE.Flex,
			props = { horizontal = true },
			content = ui.content {
				{ props = { size = v2(2, 2) } },
				{
					type = ui.TYPE.Text,
					props = {
						text = text,
						textSize = S_FONT_SIZE,
						textColor = TOOLTIP_FONT_COLOR,
						multiline = true,
					},
				},
				{ props = { size = v2(2, 2) } },
			},
		},
		{ props = { size = v2(2, 2) } },
	})
end


-- accepts string, function, table/userdata
-- example: addTooltip(WINDOW.topBarButtonFlex["touch:artisan"].content.clickbox, "foo") -- note: errors if it doesnt exist
function addTooltip(element, payload)
	local target = element.layout or element
	target.events = target.events or {}
	local events = target.events
	local prevFocusGain = events.focusGain
	local prevFocusLoss = events.focusLoss
	local prevMouseMove = events.mouseMove
	events.focusGain = async:callback(function(data, elem)
		if not WINDOW.mouseTooltip then
			local p = type(payload) == "function" and payload() or payload
			if p then
				if type(p) == "string" then
					WINDOW.mouseTooltip = makeTextTooltip(v2(0,0), p)
				else
					WINDOW.mouseTooltip = makeTooltip(v2(0,0), p)
				end
			end
		end
		if prevFocusGain then prevFocusGain(data, elem) end
	end)
	events.focusLoss = async:callback(function(data, elem)
		if WINDOW.mouseTooltip then
			WINDOW.mouseTooltip:destroy()
			WINDOW.mouseTooltip = nil
		end
		if prevFocusLoss then prevFocusLoss(data, elem) end
	end)
	events.mouseMove = async:callback(function(data, elem)
		if WINDOW.mouseTooltip then
			local offset = WINDOW.mouseTooltip.layout.userData.offset
			lastTooltipPos = v2(data.position.x + offset.x, data.position.y + offset.y)
			WINDOW.mouseTooltip.layout.props.position = lastTooltipPos
			WINDOW.mouseTooltip:update()
		end
		if prevMouseMove then prevMouseMove(data, elem) end
	end)
end