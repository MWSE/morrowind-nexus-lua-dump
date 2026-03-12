-- ╭──────────────────────────────────────────────────────────────────────────╮
-- │ Tea Brewing (Global Context) — receives object refs from player          │
-- ╰──────────────────────────────────────────────────────────────────────────╯

local function createObject(id, quantity)
	local object = world.createObject(id, quantity)
	table.insert(G_delayedUpdateJobs, {
			3,  -- Wait 3 ticks
			function(dt)
				if object:isValid() and object.count > 0 then
					local mwscript = world.mwscript.getLocalScript(object)
					if mwscript and mwscript.variables.timestamp then
						mwscript.variables.timestamp = math.floor(core.getGameTime())
					end
				end
			end
	})
	return object
end

-- ╭──────────────────────────────────────────────────────────────────────────╮
-- │ Fill Teacups from pre-identified object refs                             │
-- ╰──────────────────────────────────────────────────────────────────────────╯

-- Remove cups immediately, return map of origId -> count to fill after timer
local function removeCups(waterCupRefs, emptyCupRefs)
	local toFill = {}
	local total = 0

	-- 1) Water-filled teacups
	for _, item in ipairs(waterCupRefs) do
		if total >= G_CUPS_PER_BREW then break end
		if item:isValid() and item.count > 0 then
			local rev = saveData.reverse[item.recordId]
			local origId = rev and rev.orig or item.recordId
			local n = math.min(item.count, G_CUPS_PER_BREW - total)
			item:remove(n)
			toFill[origId] = (toFill[origId] or 0) + n
			total = total + n
		end
	end

	-- 2) Empty teacups
	for _, item in ipairs(emptyCupRefs) do
		if total >= G_CUPS_PER_BREW then break end
		if item:isValid() and item.count > 0 then
			local origId = item.recordId
			local n = math.min(item.count, G_CUPS_PER_BREW - total)
			item:remove(n)
			toFill[origId] = (toFill[origId] or 0) + n
			total = total + n
		end
	end

	return toFill, total
end

-- Create tea-filled cups from origId -> count map
local function createTeaCups(player, teaType, toFill)
	local inv = types.Actor.inventory(player)
	local filled = 0

	for origId, count in pairs(toFill) do
		local fullId = ensurePotionFor(origId, resolveMaxQ(origId), teaType)
		if fullId then
			createObject(fullId, count):moveInto(inv)
			filled = filled + count
		end
	end

	return filled
end

-- ╭──────────────────────────────────────────────────────────────────────────╮
-- │ Brew Tea                                                                 │
-- ╰──────────────────────────────────────────────────────────────────────────╯

local function teaBrewTea(data)
	local player              = data[1]
	local teaType             = data[2]
	local objectId            = data[3]
	local waterCupRefs        = data[4]  -- teacup potions holding water
	local emptyCupRefs        = data[5]  -- empty teacup misc items
	local externalWaterNeeded = data[6]  -- ml to draw from bottles
	
	local ingredientId = G_teaIngredients[teaType]
	if not ingredientId then
		log(2, "[Tea] Unknown tea type: " .. tostring(teaType))
		return
	end
	
	-- Verify ingredient
	local inv = types.Actor.inventory(player)
	local foundIngredient = inv:find(ingredientId)
	
	if not foundIngredient or foundIngredient.count == 0 then
		player:sendEvent("SunsDusk_Tea_brewingFailed", {
			reason = "No " .. ingredientId .. " in inventory",
			objectId = objectId
		})
		return
	else
		player:sendEvent("SunsDusk_refreshTooltips")
	end
	
	-- Consume resources immediately
	foundIngredient:remove(1)
	
	if externalWaterNeeded > 0 then
		consumeMilliliters(player, externalWaterNeeded, "water")
	end
	
	-- Remove cups now (before timer), store origId -> count map
	local toFill, cupCount = removeCups(waterCupRefs, emptyCupRefs)
	
	if cupCount == 0 then
		player:sendEvent("SunsDusk_Tea_brewingFailed", {
			reason = "Teacups no longer available",
			objectId = objectId
		})
		return
	end
	
	-- Play brewing sound and notify player
	player:sendEvent("SunsDusk_Tea_playBrewingSound")
	
	-- Create tea-filled cups after delay
	async:newUnsavableSimulationTimer(G_BREW_DELAY_SECONDS, function()
		local filled = createTeaCups(player, teaType, toFill)
		
		player:sendEvent("SunsDusk_Tea_brewingCompleted", {
			replaced = filled,
			teaType = teaType,
			objectId = objectId
		})
	end)
end

-- ╭──────────────────────────────────────────────────────────────────────────╮
-- │ Register Event Handlers                                                  │
-- ╰──────────────────────────────────────────────────────────────────────────╯

G_eventHandlers.SunsDusk_Tea_brewTea = teaBrewTea