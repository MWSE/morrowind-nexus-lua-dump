local common = {}

local useMCPSoulgemValueRebalance = tes3.hasCodePatchFeature(65)

common.dialogueId = {
    ["2350820932343717228"] = true,
    ["27431251821030328588"] = true,
    ["745815156108126115"] = true,
    ["1094918899840230767"] = true,
    ["170686103927626649"] = true,
    ["437731057154051750"] = true,
    ["2456544071464426424"] = true,
    ["781926249198433643"] = true,
    ["27861296403221528233"] = true,
    ["287378702993122269"] = true,
    ["29036265711176618107"] = true,
    ["2821782961190224094"] = true,
    ["3576191201815529709"] = true,
    ["3034922702178419782"] = true,
    ["277125218205084722"] = true,
    ["2797025664259225507"] = true,
}

local function loadTranslation()
	-- Get the ISO language code.
	local language = tes3.getLanguage()

	-- Load the dictionaries, and start off with English.
	local dictionaries = dofile("buyingGame.translations")
	local dictionary = dictionaries[language]

	-- If we aren't doing English, copy over missing entries.
	if (language ~= "eng") then
		table.copymissing(dictionary, dictionaries["eng"])
	end
	-- Set the dictionary.
	return dictionary
end

common.dictionary = loadTranslation()

common.createInvest = function(menu, border, value)
	local actor = tes3ui.getServiceActor().reference
	local barterGold = actor.object.baseObject.barterGold
	local playerGold = tes3.getPlayerGold()
	local invest = border:createTextSelect{id = tes3ui.registerID("MenuInvestment_invest50"), text="Invest "..tostring(barterGold*value/2), state = playerGold >= barterGold*value/2 and 1 or 2}
	invest:triggerEvent("mouseLeave")
	invest.widget.overDisabled = invest.widget.idleDisabled
	invest.widget.pressedDisabled = invest.widget.idleDisabled
	if invest.widget.state == 1 then
		invest:register("mouseClick", function()
			tes3.removeItem{reference = tes3.player, item = "gold_001", count = barterGold*value/2}
			tes3.mobilePlayer:exerciseSkill(tes3.skill.mercantile, value)
			actor.data.buyingGame = actor.data.buyingGame or {}
			actor.data.buyingGame.investment = value/10
			actor.object.baseObject.barterGold = barterGold + value*barterGold/10
			actor.object.baseObject.modified = true
			menu:destroy()
			tes3ui.leaveMenuMode(tes3ui.registerID("MenuInvestment"))
			menu = tes3ui.findMenu(tes3ui.registerID("MenuDialog"))
			local investment = menu:findChild(tes3ui.registerID("MenuDialog_investment"))
			investment:destroy()
			menu:updateLayout()
		end)
	end
end


common.isExport = function(item)
	local cell = string.sub(tes3.player.cell.id, string.find(tes3.player.cell.id, "^[%w -]+"))

	if common.config[cell] then
		if common.config[cell].export and common.config[cell].export[item] then
			return true
		end
	else
		local region = tes3.getCell{id = cell}.region or tes3.getRegion{useDoors = true}
		return common.config[region.id] and common.config[region.id].export and common.config[region.id].export[item]
	end
end

common.isImport = function(item)
	local cell = string.sub(tes3.player.cell.id, string.find(tes3.player.cell.id, "^[%w -]+"))
	if common.config[cell] then
		if common.config[cell].import and common.config[cell].import[item] then
			return true
		end
	else
		local region = tes3.getCell{id = cell}.region or tes3.getRegion{useDoors = true}
		return common.config[region.id] and common.config[region.id].import and common.config[region.id].import[item]
	end
end

common.deltaTrade = function(mobile) 
	local rank = mobile.object.faction and mobile.object.faction.playerRank + 1 or 0		
	local playerTrade = tes3.mobilePlayer.mercantile.current + tes3.mobilePlayer.personality.current/5 + tes3.mobilePlayer.luck.current/10 + rank*2
	local traderTrade = mobile:getSkillValue(tes3.skill.mercantile) + mobile.personality.current/5 + mobile.luck.current/10 + 50 - math.min(mobile.object.disposition or 50, 100)/2
	return (traderTrade - playerTrade)/100
end

common.applyValueModifiers = function(value, item, itemData, typeOfDeal)
	if itemData then
		if itemData.condition and item.maxCondition then
			value = value * itemData.condition/item.maxCondition
		--else
			--mwse.log(itemData.condition)
		end
	end
	
	if typeOfDeal == "buy" then
		if common.isImport(item.id) then
			value = value * (1 + common.config.sdModifier/100)
		elseif common.isExport(item.id) and tes3.mobilePlayer.mercantile.current >= common.config.knowsExport then
			value = value * (1 - common.config.sdModifier/100)
		end
	elseif typeOfDeal == "sell" then
		if common.isExport(item.id) then
			value = value * (1 - common.config.sdModifier/100)
		elseif common.isImport(item.id) and tes3.mobilePlayer.mercantile.current >= common.config.knowsExport then
			value = value * (1 + common.config.sdModifier/100)
		end
	end
	
	return value

end

common.getArrayValue = function(barterArray, typeOfDeal)
	local sumValue = 0
	for i, tile in ipairs(barterArray) do
		local value = tile.item.value
		-- Filled soulgem value depends on trapped soul
		if tile.item.isSoulGem then
			if (tile.itemData and tile.itemData.soul) then
				local soulValue = tile.itemData.soul.soul
				-- Fixup item value based on MCP feature state
				if (useMCPSoulgemValueRebalance) then
					value = (soulValue ^ 3) / 10000 + soulValue * 2
				else
					value = tile.item.value * soulValue
				end
			end
		end
	
		sumValue = sumValue + math.floor(common.applyValueModifiers(value, tile.item, tile.itemData, typeOfDeal)*tile.count)
	end
	return sumValue
end

common.hasForbiddenItems = function(barterArray, merchant)
	for i, tile in ipairs(barterArray) do
		if merchant.object.race.id == "Khajiit" and tile.item.id == "ingred_moon_sugar_01" then

		elseif common.config.forbidden[tile.item.id] then
			return tile.item
		end
	end
	return false
end

common.removeForbidden = function(reference)
	for _, stack in pairs(reference.object.inventory) do
		if common.config.forbidden[stack.object.id] then
			tes3.removeItem{reference=reference, item=stack.object, count=stack.count}
		end
	end
end

return common