-- ╭──────────────────────────────────────────────────────────────────────────╮
-- │ Tea Brewing (Global Context)                                             │
-- ╰──────────────────────────────────────────────────────────────────────────╯

local WATER_USED = 500
local CUPS_PER_BREW = 2
local BREW_DELAY_SECONDS = 3

-- Teacup IDs that can be filled with tea
local teacupIds = {
	["misc_com_redware_cup"] = true,
	["misc_de_pot_redware_03"] = true,
	["ab_misc_deceramiccup_01"] = true,
	["ab_misc_deceramiccup_02"] = true,
	["ab_misc_deceramicflask_01"] = true,
}

-- Ingredient IDs required to make each tea type
local teaIngredients = {
	tea_H = "ingred_heather_01",
	tea_SF = "ingred_stoneflower_petals_01",
}


-- ╭──────────────────────────────────────────────────────────────────────────╮
-- │ Fill Teacups with Tea                                                    │
-- ╰──────────────────────────────────────────────────────────────────────────╯

local function teaFillTeacups(player, teaType, maxCups)
	local inv = types.Actor.inventory(player)
	local Misc = types.Miscellaneous
	local Potion = types.Potion
	
	local replaced = 0
	
	-- Fill empty teacups (Miscellaneous items)
	for _, item in ipairs(inv:getAll(Misc)) do
		if replaced >= maxCups then break end
		if item:isValid() and item.count > 0 then
			local rec = Misc.record(item)
			local origId = rec.id
			
			if teacupIds[origId] then
				local fullId = ensurePotionFor(origId, resolveMaxQ(origId), teaType)
				
				if fullId then
					local toFill = math.min(item.count, maxCups - replaced)
					item:remove(toFill)
					world.createObject(fullId, toFill):moveInto(inv)
					replaced = replaced + toFill
				end
			end
		end
	end
	
	-- Fill partially filled teacups (Potions)
	for _, item in ipairs(inv:getAll(Potion)) do
		if replaced >= maxCups then break end
		if item:isValid() and item.count > 0 then
			local rev = saveData.reverse[item.recordId:lower()]
			if rev and teacupIds[rev.orig] then
				local origId = rev.orig
				local maxQ = resolveMaxQ(origId)
				local fullId = ensurePotionFor(origId, maxQ, teaType)
				
				if maxQ and rev.q < maxQ and fullId then
					local toFill = math.min(item.count, maxCups - replaced)
					item:remove(toFill)
					world.createObject(fullId, toFill):moveInto(inv)
					replaced = replaced + toFill
				end
			end
		end
	end
	
	return replaced
end

-- ╭──────────────────────────────────────────────────────────────────────────╮
-- │ Brew Tea                                                                 │
-- ╰──────────────────────────────────────────────────────────────────────────╯

local function teaBrewTea(data)
	local player = data[1]
	local teaType = data[2]
	local objectId = data[3]
	
	local ingredientId = teaIngredients[teaType]
	if not ingredientId then
		log(2, "[Tea] Unknown tea type: " .. tostring(teaType))
		return
	end
	
	-- Consume the ingredient
	local inv = types.Actor.inventory(player)
	local consumed = false
	
	for _, item in ipairs(inv:getAll(types.Ingredient)) do
		if item:isValid() and item.count > 0 then
			local rec = types.Ingredient.record(item)
			if rec.id:lower() == ingredientId:lower() then
				item:remove(1)
				consumed = true
				log(3, "[Tea] Consumed 1x " .. ingredientId)
				break
			end
		end
	end
	
	
	
	if not consumed then
		player:sendEvent("SunsDusk_Tea_brewingCompleted", {replaced = 0, teaType = teaType, objectId = objectId})
		return
	end
	
	local mlConsumed = consumeMilliliters(player, WATER_USED, "water")
	
	-- Play brewing sound and notify player
	player:sendEvent("SunsDusk_Tea_playBrewingSound")
	
	-- Schedule the completion after delay
	async:newUnsavableSimulationTimer(BREW_DELAY_SECONDS, function()
		local replaced = teaFillTeacups(player, teaType, CUPS_PER_BREW)
		
		player:sendEvent("SunsDusk_Tea_brewingCompleted", {
			replaced = replaced,
			teaType = teaType,
			objectId = objectId
		})
	end)
end

-- ╭──────────────────────────────────────────────────────────────────────────╮
-- │ Legacy handlers                                                          │
-- ╰──────────────────────────────────────────────────────────────────────────╯

local function teaConsumeIngredient(data)
	local player = data[1]
	local ingredientId = data[2]
	local inv = types.Actor.inventory(player)
	
	for _, item in ipairs(inv:getAll(types.Ingredient)) do
		if item:isValid() and item.count > 0 then
			local rec = types.Ingredient.record(item)
			if rec.id:lower() == ingredientId:lower() then
				item:remove(1)
				log(3, "[Tea] Consumed 1x " .. ingredientId)
				return true
			end
		end
	end
	return false
end

local function teaRefillTeacups(data)
	local player = data[1]
	local teaType = data[2]
	local replaced = teaFillTeacups(player, teaType, math.huge)
	
	player:sendEvent("SunsDusk_Tea_teacupsRefilled", {replaced = replaced, teaType = teaType})
end

-- ╭──────────────────────────────────────────────────────────────────────────╮
-- │ Register Event Handlers                                                  │
-- ╰──────────────────────────────────────────────────────────────────────────╯

G_eventHandlers.SunsDusk_Tea_consumeIngredient = teaConsumeIngredient
G_eventHandlers.SunsDusk_Tea_refillTeacups = teaRefillTeacups
G_eventHandlers.SunsDusk_Tea_brewTea = teaBrewTea