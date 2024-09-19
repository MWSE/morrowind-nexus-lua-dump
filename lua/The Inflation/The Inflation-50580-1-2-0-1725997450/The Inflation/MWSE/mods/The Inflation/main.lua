local configlib = require("The Inflation.config")
dofile("The Inflation.mcm")


local config = configlib.config
local netWorth = configlib.netWorth
local accountBalanceVars = {
	-- The Imperial Bank by vaelta44
	-- https://www.nexusmods.com/morrowind/mods/54889
	-- va_imperialbank.esp
	"BankAccount",
	-- Tamriel_Data.esm
	"T_Glob_Bank_Bri_AcctAmount",
	"T_Glob_Bank_Hla_AcctAmount",
}

local function getBankAccountBalance()
	local total = 0

	for _, varId in ipairs(accountBalanceVars) do
		local balance = tes3.getGlobal(varId)
		if balance then
			total = total + balance
		end
	end

	return total
end

local function getPlayerNetWorth()
	-- Take into account gold deposited in banks
	local worth = getBankAccountBalance()
	local playerActor = tes3.player.object --[[@as tes3npcInstance]]

	if config.netWorthCaluclation == netWorth.goldOnly then
		worth = tes3.getPlayerGold()
	elseif config.netWorthCaluclation == netWorth.equippedItems then
		worth = playerActor:getEquipmentValue({ useDurability = true })
	elseif config.netWorthCaluclation == netWorth.wholeInventory then
		for _, itemStack in pairs(playerActor.inventory) do
			local item = itemStack.object
			worth = worth + item.value * itemStack.count
		end
	end

	if config.spellsAffectNetWorth then
		for _, spell in pairs(playerActor.spells.iterator) do
			if spell.castType == tes3.spellType.spell then
				worth = worth + spell.value
			end
		end
	end

	return worth
end

--- @param e calcRepairPriceEventData|calcTravelPriceEventData
local function changeGenericPrice(e)
	local pw = getPlayerNetWorth()
	local mod = math.max(1, math.log(pw / e.basePrice, config.base))
	mod = mod ^ config.genericExp

	e.price = e.price * mod
end

--- @param e calcSpellPriceEventData
local function changeSpellPrice(e)
	local pw = getPlayerNetWorth()
	local mod = math.max(1, math.log(pw / e.basePrice, config.base))
	mod = mod ^ config.spellExp

	e.price = e.price * mod
end

--- @param e calcTrainingPriceEventData
local function changeTrainingPrice(e)
	local pw = getPlayerNetWorth()
	local mod = math.max(1, math.log(pw, e.basePrice * 10))
	mod = mod ^ config.trainingExp

	e.price = e.price * mod
end

--- @param e calcBarterPriceEventData
local function changeBarterPrice(e)
	local mod = 1.0

	if e.buying then
		local pw = getPlayerNetWorth()
		mod = math.max(1, math.log(pw, e.basePrice * 10))
		mod = mod ^ config.barterExp
	end

	e.price = e.price * mod
end

local function enableMod()
	if config.enableBarter then
		event.register(tes3.event.calcBarterPrice, changeBarterPrice)
	end

	if config.enableTraining then
		event.register(tes3.event.calcTrainingPrice, changeTrainingPrice)
	end

	if config.enableGeneric then
		event.register(tes3.event.calcRepairPrice, changeGenericPrice)
		event.register(tes3.event.calcTravelPrice, changeGenericPrice)
	end

	if config.enableSpells then
		event.register(tes3.event.calcSpellPrice, changeSpellPrice)
	end
end

event.register(tes3.event.initialized, enableMod)
event.register("The Inflation:Config Changed", function()
	event.unregister(tes3.event.calcBarterPrice, changeBarterPrice)
	event.unregister(tes3.event.calcTrainingPrice, changeTrainingPrice)
	event.unregister(tes3.event.calcRepairPrice, changeGenericPrice)
	event.unregister(tes3.event.calcTravelPrice, changeGenericPrice)
	event.unregister(tes3.event.calcSpellPrice, changeSpellPrice)

	enableMod()
end)
