-- Ore difficulties lookup table
ore_difficulties = {}


for a,b in pairs{["T_IngMine_OreIron_01"] = 15,	 
	["T_IngMine_Coal_01"] = 25,		
	["T_IngMine_OreCopper_01"] = 35, 
	["T_IngMine_OreSilver_01"] = 33,   
	["T_IngMine_OreGold_01"] = 36,
	["T_IngMine_OreOrichalcum_01"] = 40,
	["ingred_diamond_01"] = 40,
	["ingred_adamantium_ore_01"] = 65,
	["ingred_raw_glass_01"] = 70,	   
	["ingred_raw_ebony_01"] = 75,	   
} do
	ore_difficulties[a:lower()] = b
end



-- general utils
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
	return string.format("%.1f",number+0.05)
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
		textureCache[path] = ui.texture{path = path}
	end
	return textureCache[path]
end

-- Get ingredients with artisan's touch consideration
function getIngredients(recipe, artisansTouch)
	if not artisansTouch then
		return recipe.ingredients
	elseif recipe.type ~= "Weapon" and recipe.type ~= "Armor" and recipe.type ~= "Clothing" then
		return recipe.ingredients
	elseif protectedRecordIds[recipe.id] then
		return recipe.ingredients
	else
		local ingr = deepcopy(recipe.ingredients)
		local foundDiamond = false
		for _, i in pairs(ingr) do
			if i.id == "ingred_diamond_01" then
				i.count = i.count + 1
				foundDiamond = true
				break
			end
		end
		if not foundDiamond then
			table.insert(ingr, {type = "Ingredient", id = "ingred_diamond_01", count = 1})
		end
		return ingr
	end
end

-- Color utility functions
function getColorFromGameSettings(colorTag)
	local result = core.getGMST(colorTag)
	if not result then
		return util.color.rgb(1,1,1)
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
	return util.color.rgb(color1.r*mult+color2.r*(1-mult), color1.g*mult+color2.g*(1-mult), color1.b*mult+color2.b*(1-mult))
end

function darkenColor(color, mult)
	return util.color.rgb(color.r*mult, color.g*mult, color.b*mult)
end

function getColorByChance(chance)
	if chance < 1 then
		return util.color.rgb(1, chance * 0.65, 0)  -- Rot zu Orange
	elseif chance == 1 then
		return util.color.rgb(1, 1, 0)  -- Gelb
	else
		return util.color.rgb(math.max(0, 1 - chance/2), 1, 0)  -- Gelb zu Grün
	end
end

function getSkill(skillId)
	if not skillCache[skillId] then
		skillCache[skillId] = types.NPC.stats.skills[skillId](self).modified
	end
	return skillCache[skillId]
end

function getBaseSkill(skillId)
	if not baseSkillCache[skillId] then
		baseSkillCache[skillId] = types.NPC.stats.skills[skillId](self).base
	end
	return baseSkillCache[skillId]
end

function checkSkill(recipe)
	local firstSkill = getSkill(recipe.firstSkill or "armorer") - (recipe.level or 0)
	if recipe.secondSkill then
		return math.min(firstSkill, getSkill(recipe.secondSkill or "armorer") - (recipe.secondLevel or 0))
	else
		return firstSkill
	end
end

function calculateQuality(recipe, artisansTouch)
	if not artisansTouch then
		return nil
	end
	local skillDelta = checkSkill(recipe)
	return 1 + ( math.floor(skillDelta/2)*2)/200 + 0.05
end

function getRecipeColor(recipe)
	local diffMod = math.min(1,(recipe.level or 1)/getBaseSkill(recipe.firstSkill or "armorer"))
	if recipe.secondSkill then
		diffMod = (diffMod + math.min(1,(recipe.secondLevel or 1)/getBaseSkill(recipe.secondSkill)))/2
	end
	return mixColors(morrowindGold, textColor, diffMod^2)
end


-- Update recipe availability based on skill level
function updateRecipeAvailability(force)
	--local armorerSkill = types.NPC.stats.skills.armorer(self).modified
	if skillChanged or force or filterRecipes and not tempInventory then
		skillChanged = false
		skillCache = {}
		baseSkillCache = {}
		for categoryIndex, category in ipairs(profession.categories) do
			for _, recipe in ipairs(category.recipes) do
				--local requiredSkill = recipe.level or 0
				local skillDelta = checkSkill(recipe)
				if skillDelta >= -5 then
					if skillDelta < 0 then
						recipe.disabled = true
						recipe.textColor = util.color.rgb(1,0,0)
						recipe.description = "Requires "..(recipe.firstSkill or "armorer").." level "..(recipe.level or 0)
						if recipe.secondSkill and recipe.secondLevel and recipe.secondLevel > 5 then
							recipe.description = recipe.description.." and "..recipe.secondSkill.." level "..recipe.secondLevel
						end
					else
						recipe.textColor = getRecipeColor(recipe)
						recipe.disabled = nil
						recipe.description = nil
					end
					if recipe.faction and types.NPC.getFactionRank(self, recipe.faction)<recipe.factionRank then
						if recipe.description then
							recipe.description = recipe.description .. " and "..recipe.faction.." rank "..recipe.factionRank
						else
							recipe.description ="Requires "..recipe.faction.." rank "..recipe.factionRank
						end
						recipe.disabled = true
						recipe.textColor = util.color.rgb(1,0,0)
					end
					if recipe.externallyDisabled and not saveData.enabledRecipes[recipe.id] then
						if recipe.description then
							recipe.description = recipe.description .. " and "..recipe.externallyDisabled
						else
							recipe.description = recipe.externallyDisabled
						end
						recipe.disabled = true
						recipe.textColor = util.color.rgb(1,0,0)
					end
				end
				recipe.hidden = skillDelta < -5 or filterRecipes and checkIngredientsWithQueue(recipe, #craftingQueue)==0 or nil
			end
		end
	end
end

-- Create temporary inventory that includes queue changes
function createTempInventory()
	if tempInventory then
		return tempInventory
	end
	tempInventory = {}
	--print("new temp inventory")
	-- Aktuelles Inventar kopieren mit Typ-Information
	for _, item in pairs(types.Player.inventory(self):getAll()) do
		local key = item.recordId
		if (key:sub(1,12) ~= "misc_soulgem" or not types.Item.itemData(item).soul)
		and (
			tostring(item.type) ~= "Lockpick" and tostring(item.type) ~= "Probe" and tostring(item.type) ~= "Repair"
			or types.Item.itemData(item).condition >= types[ tostring(item.type)].records[item.recordId].maxCondition
		) then
			tempInventory[key] = {
				count = item.count,
				type = tostring(item.type),
				record = item.type.record(item),
				item = item
			}
		end
	end
	
	-- Queue-Änderungen anwenden
	for _, queueItem in ipairs(craftingQueue) do
		-- Zutaten abziehen
		for _, ingredient in ipairs(queueItem.ingredients) do
			if ingredient.type ~= "wildcard" then
				-- Standard Item
				local key = ingredient.id
				if tempInventory[key] then
					tempInventory[key].count = tempInventory[key].count - ingredient.count
					-- Behalte Items auch mit negativen Mengen für korrekte Queue-Berechnung
				else
					-- Erstelle Eintrag für nicht vorhandenes Item mit negativer Menge
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
				-- Wildcard: ziehe von den besten verfügbaren Items ab
				local remainingNeeded = ingredient.count
				
				while remainingNeeded > 0 do
					-- Bei jeder Iteration neu sortieren basierend auf aktuellem temp Inventar
					local qualifyingItems = ingredient.func()
					local availableItems = {}
					
					-- Nur Items mit verfügbarer Menge im temp Inventar sammeln
					for _, item in ipairs(qualifyingItems) do
						local available = tempInventory[item.recordId] and tempInventory[item.recordId].count or 0
						if available > 0 then
							table.insert(availableItems, {
								recordId = item.recordId,
								available = available,
								originalItem = item
							})
						end
					end
					
					-- Keine Items mehr verfügbar
					if #availableItems == 0 then
						break
					end
					
					-- Nach aktuell verfügbarer Menge sortieren (höchste zuerst)
					table.sort(availableItems, function(a, b) return a.available > b.available end)
					
					-- Vom besten verfügbaren Item nehmen
					local bestItem = availableItems[1]
					local toRemove = math.min(bestItem.available, remainingNeeded)
					
					if tempInventory[bestItem.recordId] then
						tempInventory[bestItem.recordId].count = tempInventory[bestItem.recordId].count - toRemove
						-- Behalte auch negative Mengen für korrekte Queue-Berechnung
					else
						tempInventory[bestItem.recordId] = {
							count = -toRemove,
							type = bestItem.originalItem.type.className,
							record = bestItem.originalItem.type.record(bestItem.originalItem),
							item = bestItem.originalItem
						}
					end
					remainingNeeded = remainingNeeded - toRemove
				end
			end
		end
		
		-- Ergebnis hinzufügen
		local resultKey = queueItem.result.id
		if tempInventory[resultKey] then
			tempInventory[resultKey].count = tempInventory[resultKey].count + queueItem.result.count
		else
			-- Neues Item zur Queue hinzugefügt
			local resultType = queueItem.result.type or "Unknown"
			local resultRecord = nil
			if resultType ~= "Unknown" and types[resultType] and types[resultType].records then
				resultRecord = types[resultType].records[resultKey]
			end
			
			tempInventory[resultKey] = {
				count = queueItem.result.count,
				type = resultType,
				record = resultRecord,
				item = nil -- Wird erst nach dem Crafting verfügbar sein
			}
		end
	end
	return tempInventory
end

-- Find items by model and weight
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

-- Find wildcard items in temp inventory
function findWildcardItems(tempInventory, wildcardFunc)
	local totalCount = 0
	local bestRecord = nil
	local bestCount = 0
	
	-- Erstelle eine Lookup-Tabelle für qualifizierende Items
	local qualifyingItems = wildcardFunc()
	local qualifyingIds = {}
	for _, item in pairs(qualifyingItems) do
		qualifyingIds[item.recordId] = true
	end
	
	-- Durchsuche temp Inventar
	for itemId, data in pairs(tempInventory) do
		if qualifyingIds[itemId] and data.count > 0 then
			totalCount = totalCount + data.count
			if data.count > bestCount then
				bestCount = data.count
				bestRecord = data.record
			end
		end
	end
	
	return bestCount, bestRecord
end

-- Check ingredient availability with queue consideration
function checkIngredientWithQueue(ingredient)
	local ingredientRecord
	local adjustedCount = 0
	
	createTempInventory()
	
	if ingredient.type == "wildcard" then
		adjustedCount, ingredientRecord = findWildcardItems(tempInventory, ingredient.func)
		
		-- Fallback auf bestes aktuelles Item wenn kein Record gefunden
		if not ingredientRecord then
			local qualifyingIngredients = ingredient.func()
			if next(qualifyingIngredients) then
				table.sort(qualifyingIngredients, function(a, b) return a.count > b.count end)
				ingredientRecord = qualifyingIngredients[1].type.record(qualifyingIngredients[1])
			end
		end
		
	elseif ingredient.type and (ingredient.type == "Armor" or ingredient.type == "Weapon") then
		-- Model+Gewicht-basierte Behandlung für Rüstungen/Waffen
		local targetRecord = types[ingredient.type].records[ingredient.id]
		if not targetRecord then
			return nil, 0
		end
		
		
		-- Durchsuche temp Inventar nach Items mit gleichem Model und Gewicht
		adjustedCount = 0
		for itemId, data in pairs(tempInventory) do
			if data.type == ingredient.type and data.record  
			   and data.record.model == targetRecord.model  
			   and data.record.weight == targetRecord.weight 
			   and not data.record.enchant
			   then
				adjustedCount = adjustedCount + data.count
				if not ingredientRecord or data.count > 0 then
					ingredientRecord = data.record
				end
			end
		end
		
		-- Fallback auf Target Record
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
		
		-- Fallback Record laden
		if not ingredientRecord and ingredient.type and types[ingredient.type] and ingredient.id then
			ingredientRecord = types[ingredient.type].records[ingredient.id]
		end
	end
	
	return ingredientRecord, math.max(0, adjustedCount)
end

-- Check all ingredients for a recipe with queue consideration
function checkIngredientsWithQueue(recipe)
    if not recipe or not recipe.ingredients then return 0 end
    local maxCraftCount = 999999
    
    -- Verwende das temporäre Inventar wenn verfügbar, sonst erstelle es
    local virtualInventory = tempInventory or createTempInventory()
    
    for _, ingredient in ipairs(getIngredients(recipe, artisansTouch, virtualInventory)) do
        local _, adjustedCount = checkIngredientWithQueue(ingredient)
        maxCraftCount = math.min(maxCraftCount, math.floor(adjustedCount / ingredient.count))
    end
    return maxCraftCount
end

-- Refresh crafting window
function refreshRecipesAndWindow()
	if craftingWindow then
		updateRecipeAvailability()
		
		refreshRecipeList()
		updateinfoContent()
		--require("CF_scripts.ui_craftingWindow")
	end
end

-- Add recipe to crafting queue
function addToCraftingQueue(recipe, count)
	count = count or 1
	local atouch = artisansTouch
	if recipe.type ~= "Weapon" and recipe.type ~= "Armor" and recipe.type ~= "Clothing" or protectedRecordIds[recipe.id] then
		atouch = false
	end
	for i = 1, count do
		table.insert(craftingQueue, {
			recipe = recipe,
			id = recipe.id,
			ingredients = getIngredients(recipe, atouch),
			artisansTouch = atouch,
			result = {
				id = recipe.id,
				count = recipe.count or 1,
				type = recipe.type
			}
		})
	end
	tempInventory = nil
	if filterRecipes then
		updateRecipeAvailability(true)
	end
	refreshRecipesAndWindow()
	craftItem()
end

---- Remove first item from crafting queue after successful crafting
--function removeFromCraftingQueue()
--	if #craftingQueue > 0 then
--		table.remove(craftingQueue, 1)
--		--tempInventory = nil
--		--refreshRecipesAndWindow()
--	end
--end

-- Clear entire crafting queue
function clearCraftingQueue()
	craftingQueue = {}
	pendingInventoryChanges = {}
	craftingState.isActive = false
	craftingState.queueProcessing = false
	hud_craftingFrameworkProgress.layout.props.visible = false
	hud_craftingFrameworkProgress:update()
	tempInventory = nil
end

-- Calculate result value for a recipe
function calculateResultValue(recipe, artisansTouch)
	local itemValue = 0
	for _, ingredient in pairs(getIngredients(recipe, artisansTouch)) do
		if ingredient.type == "wildcard" then
			itemValue = itemValue + 10*ingredient.count
		elseif ingredient.type:lower() == "ingredient" and types.Ingredient.records[ingredient.id] then
			itemValue = itemValue + (types.Ingredient.records[ingredient.id].value or 1)*ingredient.count
		end
	end
	itemValue = itemValue / (recipe.count or 1)
	
	itemValue = itemValue * (recipe.level/100*1.5+0.5)
	--if itemValue > types[recipe.type].record(recipe.id).value then
	--	return nil
	--end
	return itemValue
end	

-- Calculate experience gain for crafting an item
function calculateItemExp(recipe, artisansTouch)
	if recipe.experience then
		print(recipe.experience)
		return recipe.experience
	end
	local itemValue = 0.5
	--print("0.5")
	for _, ingredient in pairs(getIngredients(recipe, artisansTouch)) do
		if ore_difficulties[ingredient.id] then
			itemValue = itemValue + ingredient.count *  (ore_difficulties[ingredient.id]^0.18 - 0.1) * (ingredientExpMultipliers[ingredient.id] or 1)
			--print("+"..f1dot(ingredient.count *  (ore_difficulties[ingredient.id]^0.18 - 0.1) * (ingredientExpMultipliers[ingredient.id] or 1)).." ("..ingredient.id..")")
		else
			itemValue = itemValue + ingredient.count * 0.9 * (ingredientExpMultipliers[ingredient.id] or 1)
			--print("+"..f1dot( ingredient.count * 0.9 * (ingredientExpMultipliers[ingredient.id] or 1)).." ("..(ingredient.id or ingredient.type)..")")
		end
	end
	if artisansTouch then
		itemValue = (itemValue + 0.5)*1.15
		--print("+1")
	end
	return itemValue /1.5
end