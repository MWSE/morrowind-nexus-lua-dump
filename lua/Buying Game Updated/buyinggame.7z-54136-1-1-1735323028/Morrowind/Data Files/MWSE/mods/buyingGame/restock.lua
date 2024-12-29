local restock = {}
local common = require("buyingGame.common")
-- local strings = require("buyingGame.strings")

local function getItemCount(inventory, id)
	for _, stack in pairs(inventory) do
		if stack.object.id == id then return stack.count end
	end
	return 0
end

local function removeLeveledItem(leveledItem, count, reference)
	for _, listNode in ipairs(leveledItem.list) do
		local item = listNode.object
		local currentInventory = reference.object.inventory
		local baseInventory = reference.object.baseObject.inventory
		local delta = getItemCount(currentInventory, item.id) - getItemCount(baseInventory, item.id)
		if delta > 0 then
			delta = math.min(delta, count)
			tes3.removeItem({ reference = reference, item = item, count = delta})
			count = count - delta
			if count <= 0 then
				break
			end
		end
	end
end

local function traderStock(func, trader)
	func{reference = trader}
	for cont in tes3.getPlayerCell():iterateReferences(tes3.objectType.container) do
		if tes3.getOwner(cont) == trader.object.baseObject then
			func{reference=cont, traderRef = trader}
		end
	end
end

local function randomizeCondition(reference)
	for _, stack in pairs(reference.object.inventory) do
		for i = 1, stack.count do
			if (stack.object.objectType == tes3.objectType.weapon and stack.object.type ~= tes3.weaponType.marksmanThrown ) or stack.object.objectType == tes3.objectType.armor then
				local itemData = tes3.addItemData{to = reference, item = stack.object}
				if itemData and itemData.condition then
					itemData.condition = math.random(1, stack.object.maxCondition - 1)
				end
			elseif stack.object.objectType == tes3.objectType.light then
				local itemData = tes3.addItemData{to = reference, item = stack.object}
				if itemData and itemData.timeLeft then
					itemData.timeLeft = math.random(10, stack.object.time - 1)
				end
			end
		end
	end
end


local function restockItems(params)
	local reference = params.reference
	local mercant = params.traderRef or reference
	-- mwse.log("Restocking Items for %s. Trader is %s", reference.id, mercant.id)
	reference:clone()
	local inventory = reference.object.inventory
	local investment = mercant.data.buyingGame and mercant.data.buyingGame.investment or 0
	
	
	
	--mwse.log("BUYING GAME: Loop over base object")
	for _, stack in pairs(reference.object.baseObject.inventory) do -- loop over base inventory
		local count = math.abs(stack.count)
		count = count + math.floor(count * investment)
		local current = getItemCount(inventory, stack.object.id)
		if current < count and ( stack.count < 0 or reference.object.baseObject.respawns ) then
			-- mwse.log("BUYING GAME: %s < %s for %s", current, count, stack.object.id)
			-- Removing previously resolved leveled items
		
			if (stack.object.objectType == tes3.objectType.leveledItem) then
				removeLeveledItem(stack.object, count, reference)
			end
			-- Adding new items
			-- mwse.log("BUYING GAME: Adding New Items to %s", reference.id)
			if not reference.object.capacity or inventory:calculateWeight() < reference.object.capacity then
				-- mwse.log("Adding: %s", stack.object.id)
				tes3.addItem{reference = reference, item = stack.object.id, count = (count-current)}
			end
		end
	end
	
	if mercant.baseObject.class and mercant.baseObject.class.id == "Pawnbroker" then
		randomizeCondition(reference)
	end
end

local function parseNegativeItems(params)
	local reference = params.reference
	-- mwse.log("Parsing Negative Items for %s", reference.id)
	reference:clone()

	-- Remove negative items from the instance one by one and then replace them with equal positive count
	
	for _, stack in pairs(reference.object.inventory) do
		local count = stack.count
		if stack.count < 0 then
			-- Doesn't work without mwscript
			-- mwse.log("Removing %s", stack.object.id)
			mwscript.removeItem({ reference = reference, item = stack.object, count = -count})
		end
	end
end

restock.check = function(trader)
	-- mwse.log("Check Restock %s", trader.id)
	local timestamp = trader.data.buyingGame and trader.data.buyingGame.timestamp
	local newTimestamp = tes3.getSimulationTimestamp()
	
	
	if not timestamp then -- first time talking to this trader
		traderStock(parseNegativeItems, trader)
		trader.data.buyingGame = trader.data.buyingGame or {}
		trader.data.buyingGame.timestamp = newTimestamp
		traderStock(restockItems, trader)
		return
	end
	
	if newTimestamp - timestamp >= tes3.findGMST(tes3.gmst.fBarterGoldResetDelay).value * common.config.restockTime then
		--local times = math.floor((newTimestamp - timestamp)/tes3.findGMST(tes3.gmst.fBarterGoldResetDelay).value * common.config.restockTime)
		trader.data.buyingGame.timestamp = newTimestamp
		--for i = 1, times do
		-- Removing every remembered bought item if config option is enabled and merchant isn't a Pawnbroker
		if common.config.removeBought then
			if  trader.data.buyingGame.boughtItems then
				if not (trader.baseObject.class and trader.baseObject.class.id == "Pawnbroker") then
					for item, count in pairs(trader.data.buyingGame.boughtItems) do -- loop over bought items
						-- mwse.log("Removing bought item %s %s", item, count)
						tes3.removeItem{reference = trader, item = item, count = count}
						trader.data.buyingGame.boughtItems[item] = nil
					end
				end
			end
		end
		traderStock(restockItems, trader)
		--end
	end
end 

return restock