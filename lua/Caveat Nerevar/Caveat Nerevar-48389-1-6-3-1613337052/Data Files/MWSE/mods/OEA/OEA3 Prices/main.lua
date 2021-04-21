local config = require("OEA.OEA3 Prices.config")

local GoldAmount
local H = {}
local I = {}

local function PriceChange(Item)
	if (config.TurnedOn == true) and (Item ~= nil) and (Item.value ~= nil) and (H[Item.id] == nil) then
		if (Item.value > (10 * config.Y2)) and ((Item.isSoulGem == nil) or (Item.isSoulGem == false)) then
			if (config.Logarithm == true) then
				Item.value = (config.X1) * (Item.value / math.log(Item.value / config.Y2))
				if (Item.value < 1) then
					Item.value = 1
				end
				H[Item.id] = Item.id
			elseif (config.Logarithm == false) then
				Item.value = (config.X1) * (Item.value / math.log10(Item.value / config.Y2))
				if (Item.value < 1) then
					Item.value = 1
				end
				H[Item.id] = Item.id
			end
		end
	end
end

local function ItemUpdate(e)
	PriceChange(e.item)
end

local function ObjectTooltip(e)
	local GoldAdd

	if (tes3.player.data.OEA3 == nil) then
		tes3.player.data.OEA3 = {}
	end

	if (e.reference ~= nil) and (e.reference.object.value ~= nil) then
		PriceChange(e.reference.object)
		return
	end

	if (e.reference ~= nil) and ((e.reference == tes3.player) or (e.reference == tes3.mobilePlayer)) then
		return
	end

	if (e.reference ~= nil) and (e.reference.mobile ~= nil) and (e.reference.mobile.mercantile ~= nil) then
		if (I[e.reference.id] == nil) then
			e.reference.mobile.mercantile.current = (e.reference.mobile.mercantile.base + config.Merch)
  			I[e.reference.id] = e.reference.id
		end
	end

	if (e.reference ~= nil) and (e.reference.mobile ~= nil) and (e.reference.mobile.barterGold ~= nil) then
		if (tes3.player.data.OEA3[e.reference.id] == nil) and (tonumber(config.BarterGold) ~= 1) then
			GoldAdd = (e.reference.baseObject.barterGold * config.BarterGold) - e.reference.mobile.barterGold
			mwscript.addItem({ reference = e.reference, item = "Gold_001", count = GoldAdd })
			e.reference.mobile.barterGold = e.reference.baseObject.barterGold * config.BarterGold
			tes3.player.data.OEA3[e.reference.id] = 1
		elseif (tonumber(config.BarterGold) == 1) and (tes3.player.data.OEA3[e.reference.id] ~= nil) and (tes3.player.data.OEA3[e.reference.id] == 1) then
			GoldAdd = (e.reference.baseObject.barterGold * config.BarterGold) - e.reference.mobile.barterGold
			mwscript.removeItem({ reference = e.reference, item = "Gold_001", count = GoldAdd })
			e.reference.mobile.barterGold = e.reference.baseObject.barterGold
			tes3.player.data.OEA3[e.reference.id] = nil
		end
	end
end

local function PreTalk(e)
	GoldAmount = tes3.getPlayerGold()
end

local function PostTalk(e)
	local GoldDifference2

	if (config.Dialogue == false) then
		return
	end
	
	if (config.TurnedOn == false) then
		return
	end

	if ((e.dialogue.id):lower() == "alms for the poor") then
		return
	end

	local NewGoldAmount = tes3.getPlayerGold()
	if (NewGoldAmount > GoldAmount) then
		local GoldDifference = NewGoldAmount - GoldAmount
		if (GoldDifference <= (10 * config.Y2)) then
			return
		end
		if (config.Logarithm == true) then
			GoldDifference2 = (config.X1) * (GoldDifference / math.log(GoldDifference / config.Y2))
			if (GoldDifference2 < 1) then
				GoldDifference2 = 1
			end
			GoldDifference2 = math.ceil(GoldDifference2)
		elseif (config.Logarithm == false) then
			GoldDifference2 = (config.X1) * (GoldDifference / math.log10(GoldDifference / config.Y2))
			if (GoldDifference2 < 1) then
				GoldDifference2 = 1
			end
			GoldDifference2 = math.ceil(GoldDifference2)
		end
		tes3.removeItem({ reference = tes3.player, item = "Gold_001", count = GoldDifference })
		tes3.addItem({ reference = tes3.player, item = "Gold_001", count = GoldDifference2 })
		tes3.messageBox(("[Caveat Nerevar] After economic adjustment, you only receive %s Gold."):format(GoldDifference2))
	end
end		

local function OnLoad(e)
	mwse.log("[Caveat Nerevar] Initialized.")
	event.register("itemTileUpdated", ItemUpdate)
	event.register("uiObjectTooltip", ObjectTooltip)
	event.register("infoResponse", PreTalk)
	event.register("postInfoResponse", PostTalk)

	tes3.findGMST("fTravelMult").value = 4000 * (config.Travel / 100)
	tes3.findGMST("fMagesGuildTravel").value = 10 * (config.TravelMage / 100)
	tes3.findGMST("iTrainingMod").value = math.ceil(10 * (config.Train / 100))
	tes3.findGMST("fEnchantmentValueMult").value = 1000 * (config.Enchant / 100)
end

event.register("initialized", OnLoad)

-- Register the mod config menu (using EasyMCM library).
event.register("modConfigReady", function()
	require("OEA.OEA3 Prices.mcm")
end)
