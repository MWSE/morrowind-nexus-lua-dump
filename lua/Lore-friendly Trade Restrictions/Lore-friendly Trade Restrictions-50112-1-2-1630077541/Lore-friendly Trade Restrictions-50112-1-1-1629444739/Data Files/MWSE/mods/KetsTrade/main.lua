local contrabandList = require("KetsTrade.tradelist").contraband
local tradeList = require("KetsTrade.tradelist").trade
local trader = nil
local barterItem = ""
local barterTile = nil
local bartersContraband = false

local config = mwse.loadConfig("Lore-friendly Trade Restrictions")
config = config or {}
config.tradeEnabled = config.tradeEnabled or true
config.contrabandEnabled = config.contrabandEnabled or true

--trade interruption
local function tradeCrime()
	tes3.triggerCrime{type = tes3.crimeType.theft, value = 100}
end

local function closeDialogueMenu()
	local menu = tes3ui.findMenu(tes3ui.registerID("MenuDialog")):findChild(tes3ui.registerID("MenuDialog_button_bye")):triggerEvent("mouseClick")
	timer.start{type = timer.real, duration=.01, callback = tradeCrime}
end

local function closeBarterMenu()
	tes3ui.findMenu(tes3ui.registerID("MenuBarter")):findChild(tes3ui.registerID("MenuBarter_Cancelbutton")):triggerEvent("mouseClick")
	timer.start{type = timer.real, duration=.0001, callback = closeDialogueMenu}
end

local function sellBack()
	barterTile.element:triggerEvent("mouseClick")
	barterTile = nil
end

--contraband check
local function getContrabandType(id)
	local contrabandType = ""
	for i,conditions in pairs (contrabandList) do
		for _,item in ipairs (conditions["Items"]) do
			if id == item then
				contrabandType = i
			end
		end
	end
	return contrabandType
end

local function contrabandTolerance(id, trader)
	local contrabandType = getContrabandType(id)
	if contrabandType == "" then return true end
	local conditions = contrabandList[contrabandType]
	if conditions["Race"] then
		for _, race in ipairs(conditions["Race"]) do
			if trader.race.id == race then return true end
		end
	end
	if conditions["Faction"] and trader.faction then
		for _, faction in ipairs(conditions["Faction"]) do
			if trader.faction.id == faction then return true end
		end
	end
	return false
end

--trade check
local function buysItemType(itemType, trader)
	local class = trader.class.id
	if tradeList[class] then
		for _, i in ipairs(tradeList[class]) do
			if i == itemType then return true end
		end
		return false
	end
	return true
end

--events
local function onCalcBarterPrice(e)
	if e.buying then return	end
	if buysItemType(e.item.objectType, e.mobile.object) and contrabandTolerance(e.item.id, e.mobile.object) and (e.item.id ~= "Gold_001") then
		if not ((e.mobile.object.class.id == "Enchanter Service") and (e.item.enchantment == nil)) then
			barterItem = ""
			return
		end
	end
	if e.reference.object.disposition * (tes3.getMobilePlayer():getSkillValue(tes3.skill.mercantile) / 100) > 0.5 * e.mobile:getSkillValue(tes3.skill.mercantile) then
		bartersContraband = true
	else
		bartersContraband = false
	end
	barterItem = e.item
end

local function onFilterBarterMenu(e)
	if e.item and (e.item ~= barterItem) then return end
	local contrabandType = getContrabandType(e.item.id)
	if contrabandType ~= "" and config.contrabandEnabled then
		if bartersContraband then
			tes3.messageBox("It's illegal to trade "..contrabandType..". Get it away, or I'll call the guards.")
			timer.start{type = timer.real, duration=.0001, callback = sellBack}
		else
			tes3.setItemIsStolen{item = barterItem, from = tes3.player.baseObject, stolen = true}
			timer.start{type = timer.real, duration=.0001, callback = closeBarterMenu}
		end
	elseif config.tradeEnabled then
		tes3.messageBox(tes3.findGMST("sBarterDialog4").value)
		timer.start{type = timer.real, duration=.0001, callback = sellBack}
	end
	barterTile = e.tile
	barterItem = ""
end

--register
local function onInitialized()
	event.register("calcBarterPrice", onCalcBarterPrice)
	event.register("filterBarterMenu", onFilterBarterMenu)

	mwse.log("[Ket's Barter] Initialized")
end
event.register("initialized", onInitialized)

local modConfig = require("KetsTrade.mcm")
modConfig.config = config
local function registerModConfig()
	mwse.registerModConfig("Lore-friendly Trade Restrictions", modConfig)
end
event.register("modConfigReady", registerModConfig)
