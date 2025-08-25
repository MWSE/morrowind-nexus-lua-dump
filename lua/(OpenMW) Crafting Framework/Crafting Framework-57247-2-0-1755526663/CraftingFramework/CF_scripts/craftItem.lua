if hud_craftingFrameworkProgress then
	hud_craftingFrameworkProgress:destroy()
	hud_craftingFrameworkProgress = nil
end

local makeBorder = require("CF_scripts.ui_makeborder") 
local borderOffset = 1
local borderFile = "thin"
local borderTemplate = makeBorder(borderFile, nil, borderOffset, {
		type = ui.TYPE.Image,
		props = {
			resource = getTexture('black'),
			relativeSize = v2(1,1),
			alpha = 0.4,
		}
	}).borders


	
-- copypasta EDITED
local function checkIngredient(ingredient)
	local returnedItem
	local inventoryCount = 0
	if ingredient.type == "wildcard" then
		local qualifyingIngredients = ingredient.func()
		if next(qualifyingIngredients) then
			local item = qualifyingIngredients[1]
			inventoryCount = item.count
			returnedItem = item
			for _, item in pairs(qualifyingIngredients) do
				if item.count > ingredient.count then
					returnedItem = item
					inventoryCount = item.count
					break
				end
			end
		end
	else
		-- Special handling for weapons and armor - search by model and weight
		if ingredient.type == "Weapon" or ingredient.type == "Armor" then
			local targetRecord = nil
			if ingredient.type and types[ingredient.type] and ingredient.id then
				targetRecord = types[ingredient.type].records[ingredient.id]
			end
			
			if targetRecord then
				local allItems = types.Player.inventory(self):getAll(types[ingredient.type])
				local matchingItem = nil
				local totalCount = 0
				
				-- Search through inventory for matching items by model and weight
				for _, item in pairs(allItems) do
					local itemRecord = types[ingredient.type].record(item)
					
					-- Check if this item matches by model, weight, and no enchantment
					if itemRecord and
					   itemRecord.model == targetRecord.model and 
					   itemRecord.weight == targetRecord.weight and 
					   itemRecord.enchant == nil and
					   item.count >=ingredient.count then
						if not matchingItem then
							matchingItem = item
						end
						totalCount = totalCount + item.count
					end
				end
				
				inventoryCount = totalCount
				returnedItem = matchingItem
			else
				-- Fallback if no target record found
				local item = types.Player.inventory(self):find(ingredient.id)
				inventoryCount = item and item.count or 0
				returnedItem = item
			end
		elseif ingredient.id:sub(1,12) == "misc_soulgem" then
			local allItems = types.Player.inventory(self):getAll(types.Miscellaneous)
			for _, item in pairs(allItems) do
				if item.recordId == ingredient.id and not types.Item.itemData(item).soul and item.count >=ingredient.count then
					inventoryCount = item.count
					returnedItem = item
					break
				end
			end
		-- Items with charges
		elseif ingredient.type == "Lockpick" or ingredient.type == "Probe" or ingredient.type == "Repair" then
			local allItems = types.Player.inventory(self):getAll(ingredient.type)
			for _, item in pairs(allItems) do
				if item.recordId == ingredient.id and types.Item.itemData(item).condition >= types[ingredient.type].records[ingredient.id].maxCondition and item.count >= ingredient.count then
					inventoryCount = item.count
					returnedItem = item
					break
				end
			end
		else
			-- Default behavior for other item types
			local item = types.Player.inventory(self):find(ingredient.id)
			if item.count >= ingredient.count then
				inventoryCount = item and item.count or 0
				returnedItem = item
			end
		end
	end
	return returnedItem, inventoryCount
end


local function checkIngredients(recipe, artisansTouch)
	if not recipe or not recipe.ingredients then return 0 end
	
	local maxCraftCount = 999999
	local virtuallyConsumed = {}
	local itemTypes = {}
	
	for _, ingredient in ipairs(getIngredients(recipe, artisansTouch)) do
		local foundItem = checkIngredient(ingredient)
		
		if foundItem then
			local key = foundItem.recordId
			virtuallyConsumed[key] = (virtuallyConsumed[key] or 0) + ingredient.count
			
			if not itemTypes[key] or itemTypes[key] == "wildcard" then
				itemTypes[key] = ingredient
			end
		else
			return 0
		end
	end
	
	for key, totalNeeded in pairs(virtuallyConsumed) do
		local foundItem, inventoryCount = checkIngredient({id = key, type = itemTypes[key].type, count = totalNeeded, func = itemTypes[key].func})
		maxCraftCount = math.min(maxCraftCount, math.floor(inventoryCount / totalNeeded))
	end
	
	return maxCraftCount
end

local function consumeIngredients(recipe, artisansTouch)
	if not recipe or not recipe.ingredients then return false end
	if checkIngredients(recipe, artisansTouch)<1 then return false end
	local maxCraftCount = 999999
	local accumulatedIngredients = {}
	for _, ingredient in ipairs(getIngredients(recipe, artisansTouch)) do
		local item, inventoryCount = checkIngredient(ingredient)
		core.sendGlobalEvent("CraftingFramework_removeItem",{self, item, ingredient.count})
	end
	return maxCraftCount
end



local function getBestHammer()
	local repairTools = types.Player.inventory(self):getAll(types.Repair) 
	local bestHammer = nil
	local bestHammerQuality = 0.001
	
	for a,b in pairs(repairTools) do
		if types.Repair.record(b).quality > bestHammerQuality then
			bestHammer = b
			bestHammerQuality = types.Repair.record(b).quality
		end
	end
	return bestHammerQuality,bestHammer
end

local function getResultItem(recipe)
	local resultRecord
	if recipe.type and types[recipe.type] and recipe.id then
		resultRecord = types[recipe.type].records[recipe.id]
	end
	local icon = nil
	if recipe.icon then 
		icon = recipe.icon
	elseif resultRecord then
		icon = resultRecord.icon
	end
	local nameText ="ERROR: "..(recipe.id or "no id")
	if recipe.name then
		nameText = recipe.name
	elseif resultRecord then
		nameText = resultRecord.name
	end
	if recipe.count and recipe.count ~= 1 then
		nameText = nameText.." (x "..recipe.count..")"
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
		queueProcessing = false,
	}
end

local fontSize = 18
local barWidth = 180
local barHeight = 16


local progressColor = morrowindBlue

-- Root
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

-- Main flex
local mainFlex = {
	type = ui.TYPE.Flex,
	props = {
		autoSize = true,
		arrange = ui.ALIGNMENT.Center,
	},
	content = ui.content {}
}
hud_craftingFrameworkProgress.layout.content:add(mainFlex)

-- Header text
local itemNameText = {
	type = ui.TYPE.Text,
	name = "itemNameText",
	props = {
		text = "Crafting...",
		textColor = morrowindGold,
		textShadow = true,
		textShadowColor = util.color.rgba(0,0,0,1),
		textSize = fontSize,
		textAlignH = ui.ALIGNMENT.Center,
		textAlignV = ui.ALIGNMENT.Center,
		autoSize = true,
	}
}
mainFlex.content:add(itemNameText)

-- Queue info text
local queueInfoText = {
	type = ui.TYPE.Text,
	name = "queueInfoText",
	props = {
		text = "",
		textColor = morrowindBlue,
		textShadow = true,
		textShadowColor = util.color.rgba(0,0,0,1),
		textSize = fontSize - 4,
		textAlignH = ui.ALIGNMENT.Center,
		textAlignV = ui.ALIGNMENT.Center,
		autoSize = true,
	}
}
mainFlex.content:add(queueInfoText)

-- Spacer
mainFlex.content:add{ props = { size = v2(1, 1) } }

-- Progress bar container
local progressContainer = {
	type = ui.TYPE.Widget,
	template = borderTemplate,
	props = {
		size = v2(barWidth + 4, barHeight + 4),
	},
	content = ui.content {}
}
mainFlex.content:add(progressContainer)

-- Progress fill
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

-- Progress percentage text
local progressText = {
	type = ui.TYPE.Text,
	name = "progressText",
	props = {
		text = "0%",
		textColor = textColor,
		textShadow = true,
		textShadowColor = util.color.rgba(0,0,0,1),
		textSize = fontSize - 4,
		textAlignH = ui.ALIGNMENT.End,
		textAlignV = ui.ALIGNMENT.Center,
		relativePosition = v2(1, 0.5),
		anchor = v2(1, 0.5),
		relativeSize = v2(1,1),
		autoSize = true,
	}
}
progressContainer.content:add(progressText)

-- Funktion zum Starten des nächsten Items aus der Queue
local function processNextQueueItem()
	if #craftingQueue > 0 and not craftingState.isActive then
		--local nextRecipe = craftingQueue[1].recipe
		--if checkIngredients(nextRecipe) >= 1 then
		--	craftingState.queueProcessing = true
		--	return craftItem(nextRecipe)
		--else
		--	-- Nicht genug Zutaten, Queue leeren oder Item überspringen
		--	removeFromCraftingQueue()
		--	processNextQueueItem()
		--end
		--return craftItem(nextRecipe)
		craftItem()
	else
		craftingState.queueProcessing = false
		craftingState.isActive = false
		hud_craftingFrameworkProgress.layout.props.visible = false
		hud_craftingFrameworkProgress:update()
	end
end

-- onFrameFunction
local function updateCraftingProgress(dt)
	local dt =  core.getRealFrameDuration() 
	if not craftingState.isActive then
		return
	end
	
	-- Check if health dropped or player moved
	local movement = math.abs(math.max(self.controls.movement, self.controls.sideMovement))
	local currentHealth = types.Actor.stats.dynamic.health(self).current
	if currentHealth < craftingState.initialHealth or movement > 0 then
		clearCraftingQueue()
		ambient.playSound("enchant fail")
		return
	end
	
	craftingState.elapsedTime = craftingState.elapsedTime + dt
	craftingState.elapsedTime = math.min(craftingState.elapsedTime, craftingState.duration)
	
	local progress = craftingState.elapsedTime / craftingState.duration
	
	progressFill.props.relativeSize = v2(progress, 1)
	
	if not craftingState.noTool then
		progressText.props.text = f1(-(1-progress)*craftingState.duration) .. "s"
	end
	
	-- Update queue info
	if #craftingQueue > 1 then
		queueInfoText.props.text = "Queue: " .. #craftingQueue-1 .. " remaining"
	else
		queueInfoText.props.text = ""
	end
	
	local targetFxCount = math.max(2, math.ceil(craftingState.duration / 0.7))
	local fxInterval = craftingState.duration / targetFxCount
	local currentFxStep = math.floor((craftingState.elapsedTime+0.001) / fxInterval)
	
	if currentFxStep > craftingState.lastFxStep then
		types.Actor.stats.dynamic.fatigue(self).current = math.max(0,types.Actor.stats.dynamic.fatigue(self).current - 1.5)
		craftingState.lastFxStep = currentFxStep
		local now = core.getRealTime()
		if now > lastFxTime +0.1 then
			if not craftingState.recipe.craftingSound then
				if craftingState.isSmithing or not vfs.fileExists("Sound/TR/fx/TR_misc_drum.wav") then
					ambient.playSound("Heavy Armor Hit", {volume =0.9})
				else
					ambient.playSoundFile("Sound/TR/fx/TR_misc_drum.wav", {volume =0.9})
				end
			elseif vfs.fileExists(craftingState.recipe.craftingSound) then
				ambient.playSoundFile(craftingState.recipe.craftingSound, {volume =0.9})
			else
				ambient.playSound(craftingState.recipe.craftingSound, {volume =0.9})
			end
			lastFxTime = core.getRealTime()
		end
		if currentFxStep > 0 and (checkIngredients(craftingState.recipe, craftingState.artisansTouch) <1 or craftingState.recipe.disabled) then
			--removeFromCraftingQueue()
			--processNextQueueItem()
			clearCraftingQueue()
			ambient.playSound("enchant fail")
			return 
		end
	end
	
	hud_craftingFrameworkProgress:update()
	
	-- Check if completed
	if craftingState.elapsedTime >= craftingState.duration then
		craftingState.isActive = false
		
		if consumeIngredients(craftingState.recipe, craftingState.artisansTouch) then
			local skill = getSkill(craftingState.recipe.firstSkill or "armorer")
			local base = types.NPC.stats.skills[craftingState.recipe.firstSkill or "armorer"](self).base

			
			local diffMod = math.min(1,(craftingState.recipe.level or 1)/base)
			if craftingState.artisansTouch then
				diffMod = math.min(1,(craftingState.recipe.level or 1)/base)^0.55
			end
			if craftingState.recipe.secondSkill then
				diffMod = diffMod / 2
			end
			local recipeExp = calculateItemExp(craftingState.recipe, craftingState.artisansTouch)*playerSection:get("EXPERIENCE_MULT")
			print((craftingState.recipe.firstSkill or "armorer").." exp: "..math.floor(recipeExp*100)/100 .." * "..math.floor(diffMod*100)/100)
			expText(diffMod * recipeExp, v2(0.5,0.77))
			--local qualityMult = nil
			--if craftingState.artisansTouch then
			--	qualityMult = 1 + ( math.floor(armorerSkill/2)*2 - craftingState.recipe.level)/200 + 0.05
			--end
			for i=1, 4 do
				I.SkillProgression.skillUsed(craftingState.recipe.firstSkill or "armorer", {skillGain = diffMod * recipeExp / 4, useType = 0, scale = nil})
			end
			core.sendGlobalEvent('CraftingFramework_getItem', {self, craftingState.recipe.type, craftingState.recipe.id, craftingState.recipe.name, craftingState.recipe.count or 1, calculateResultValue(craftingState.recipe, craftingState.artisansTouch), calculateQuality(craftingState.recipe, craftingState.artisansTouch) })
			
			if craftingState.recipe.secondSkill then
				skill = getSkill(craftingState.recipe.secondSkill)
				base = getBaseSkill(craftingState.recipe.secondSkill)
				diffMod = math.min(1,(craftingState.recipe.secondLevel or 1)/base)
				if craftingState.artisansTouch then
					diffMod = math.min(1,(craftingState.recipe.secondLevel or 1)/base)^0.55
				end
				diffMod = diffMod / 2
				print(craftingState.recipe.secondSkill.." exp: "..math.floor(recipeExp*100)/100 .." * "..math.floor(diffMod*100)/100)
				expText(diffMod * recipeExp, v2(0.5,0.76))
				for i=1, 4 do
					I.SkillProgression.skillUsed(craftingState.recipe.secondSkill, {skillGain = diffMod * recipeExp / 4, useType = 0, scale = nil})
				end
			end
			
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


return function()
	
	if craftingState.isActive then 
		return 
	end
	if not craftingQueue[1] then 
		return 
	end
	local recipe = craftingQueue[1].recipe
	if recipe.disabled then 
		clearCraftingQueue()
		ambient.playSound("enchant fail")
		return 
	end
	craftingState.recipe = recipe
	
	local skill = getSkill(craftingState.recipe.firstSkill or "armorer")
	if craftingState.recipe.secondSkill then
		skill = (skill + getSkill(craftingState.recipe.secondSkill))/2
	end
	
	local speed = 1+skill/100
	if not craftingState.recipe.firstSkill or craftingState.recipe.secondSkill == "armorer" then
		craftingState.speed = math.max(0.5, math.log(7, 7*getBestHammer())*speed)
		craftingState.isSmithing = true
	else
		craftingState.speed = speed
		craftingState.isSmithing = false
	end
	print(craftingState.speed)
	craftingState.itemName = getResultItem(recipe)
	
	local color = textColor
	
	local duration = recipe.craftingTime or 5
	if craftingQueue[1].artisansTouch then
		duration = duration * 2
	end
	craftingState.artisansTouch = craftingQueue[1].artisansTouch
	craftingState.isActive = true
	craftingState.duration = duration/craftingState.speed
	
	craftingState.elapsedTime = 0
	craftingState.initialHealth = types.Actor.stats.dynamic.health(self).current
	craftingState.lastFxStep = -1
	
	-- Berechne optimales FX-Interval
	local targetFxCount = math.ceil(craftingState.duration / 0.7)
	if targetFxCount < 1 then targetFxCount = 1 end
	craftingState.fxInterval = craftingState.duration / targetFxCount
	craftingState.totalFxCount = 0
	
	-- Show the UI
	hud_craftingFrameworkProgress.layout.props.visible = true
	
	-- Update item name
	itemNameText.props.text = " " .. craftingState.itemName .. " "
	itemNameText.props.textColor = color
	
	-- Reset progress bar
	progressFill.props.size = v2(1, barHeight)
	progressText.props.text = "0%"
	
	hud_craftingFrameworkProgress:update()
end