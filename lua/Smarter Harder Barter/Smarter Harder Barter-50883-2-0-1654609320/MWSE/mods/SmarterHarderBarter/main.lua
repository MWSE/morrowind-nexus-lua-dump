--[[
	Mod Initialization: Smarter Harder Barter
	Author: quinnocent
	Credit: mort (author of original Harder Barter)
	Version: 2.0
]]--


local defaultConfig = {
	modEnabled = true,
	vanillaEnabled = true,
	logarithmEnabled = true,
	difficulty = 1,
	customCutoff = 300,
	customLogbase = 1.71,
	buyEnabled = true,
	buyLogarithmEnabled = true,
	buyCutoff = 5000,
	buyLogbase = 1.31,
	capEnabled = false,
	mercEnabled = true,
	mercChangeEnabled = false,
	mercAddend = 0,
	mercMultiplier = 0.94,
	mercMultiplier2 = 0.215,
	baseStatsEnabled = true,
	creatureEnabled = true,
	creatureStats = 55,
	haggleEnabled = true,
	haggleAddend = 0.2,
	haggleMultiplier = 5.4,
	haggleExponent = 2.5,
	haggleMinFactor = 11.5,
	haggleMinXP = 1.5,
	haggleMaxXP = 12.5,
	haggleXPScaling = true,
	haggleXPDivisor = 25,
	factionEnabled = true,
	factionBase = 0.05,
	factionMultiplier = 0.02,
	logLevel = "NONE",
	barterReject = false,
	haggleBlock = false,
	modClaim = false,
	modPriority = 0,
}
local config = mwse.loadConfig("SHBarter", defaultConfig)


local logger = require("logging.logger")
local log = logger.new{
    name = "SHBarter",
    logLevel = config.logLevel,
}


local stats = {}
local price = {}


---------- ---------- ---------- Pricing Function ---------- ---------- ----------



local function SHBarterPrice(basePricePer, count, buying, item, itemData, calledBy)

	-- calledBy is used to know which function is calling this function, since the data passed
	-- isn't exactly the same, and the calculations need to be adjusted accordingly.

	-- This value is automatically split by tile.item.value in barterOffer but not e.basePrice in
	-- calcBarterPrice
	if calledBy == "calcBarterPrice" then
		basePricePer = basePricePer / count
	end

	log:debug("P     Start - Item: %s - Buy: %s - #: %s - Value: %s", item, buying, count, basePricePer)

	--[[
	e.basePrice from calcBarterPrice factors in durability, light duration, and soulgem souls.
	These are not factored into tile.item.value from barterOffer.  As such, we need	to manually
	adjust the price in this case.

	If an item has full durability, itemData.condition returns nil, and if itemData is nil,
	attempts to evaluate itemData.condition will cause the function to error out.  So we're
	checking if itemData is nil first.  This check is needed even if itemData is set to false
	instead of nil.
	]]--
	if itemData then
		-- We need to confirm the right item type first, as itemData might spit out erroneous data
		-- otherwise according to the documentation.
		if item.hasDurability and itemData.condition then
			if calledBy == "barterOffer" then
				basePricePer = math.floor(basePricePer * (itemData.condition / item.maxCondition))
			end
			log:debug("P      Dura - Current: %s - Max: %s - Ratio: %s - basePricePer: %s", itemData.condition, item.maxCondition, itemData.condition / item.maxCondition, basePricePer)
		end
	
		-- We don't need to check the originating function, since we can overwrite either value
		-- with this formula.  It's preferable to do this to maximize uniformity.
		if item.isSoulGem and itemData.soul then
			-- itemData.soul returns the name of the soul.  We want itemData.soul.soul for the
			-- numeric value.  We're also using MCP's soulgem value formula, which seems to round
			-- to the nearest whole number, in my testing.
			basePricePer = math.round(0.0001 * itemData.soul.soul ^ 3 + 2 * itemData.soul.soul)
			log:debug("P      Soul - itemData.soul: %s - itemData.soul.soul: %s - basePricePer: %s", itemData.soul, itemData.soul.soul, basePricePer)
		end

		-- 1212631372 is the tes3.objectType code for lights.
		-- Sometimes lights have negative duration (light mods?), so we're cleaning that up.
		if item.objectType == 1212631372 and itemData.timeLeft then
			if calledBy == "barterOffer" then
				basePricePer = math.floor(basePricePer * (math.max(itemData.timeLeft,0) / item.time))
			end
			log:debug("P     Light - itemData.timeLeft: %s - item.time: %s - Ratio: %s - basePricePer: %s", itemData.timeLeft, item.time, math.max(itemData.timeLeft,0) / item.time, basePricePer)
		end
	end

	local cutoff
	local logbase
	if buying then
		-- Set to default values, as a safe fallback if the user inputs invalid values
		cutoff = 5000
		logbase = 1.31
		-- Avoiding custom inputs that will cause an error in the formula
		if config.buyCutoff >= 1 and config.buyLogbase >= 1.01 then
			cutoff = config.buyCutoff
			logbase = config.buyLogbase
		end
		log:debug("P   Log Buy - Cutoff: %s - Logbase: %s", cutoff, logbase)
	else
		-- Set to default values, as a safe fallback if the user inputs invalid values
		cutoff = 300
		logbase = 1.71
		if config.difficulty == 2 then
			cutoff = 250
			logbase = 1.54
		elseif config.difficulty == 3 then
			cutoff = 200
			logbase = 1.31
		-- Avoiding custom inputs that will cause an error in the formula
		elseif config.difficulty == 4 and config.customCutoff >= 1 and config.customLogbase >= 1.01 then
			cutoff = config.customCutoff
			logbase = config.customLogbase
		end
		log:debug("P  Log Sell - Diff: %s - Cutoff: %s - Logbase: %s", config.difficulty, cutoff, logbase)
	end

	if basePricePer > cutoff and ((buying and config.buyLogarithmEnabled) or (not buying and config.logarithmEnabled)) then
		-- Any amount above the cutoff value is divided by the difference between the logarithm
		-- (using the specified base) of the total price and the logarithm of the excess amount
		-- minus 1.  This means the divisor of the excess amount starts at 1, allowing for a
		-- gradual dropoff after the cutoff value.
		basePricePer = cutoff + (basePricePer - cutoff) / (math.log(basePricePer) / math.log(logbase) - (math.log(cutoff) / math.log(logbase) - 1))
		log:debug("P Logarithm - basePricePer: %s", basePricePer)
	end

	local vanillaRatio = 1
	if config.vanillaEnabled and not (stats.isCreature and not config.creatureEnabled) then
		if buying then
			vanillaRatio = stats.buyRatio - stats.factionBonus
		else
			vanillaRatio = stats.sellRatio + stats.factionBonus
		end
		log:debug("P   Vanilla - vanillaRatio: %s - buying: %s", vanillaRatio, buying)
	else
		log:debug("P   Vanilla - Disabled - vanillaEnabled: %s - isCreature: %s - creatureEnabled: %s", config.vanillaEnabled, stats.isCreature, config.creatureEnabled)
	end

	-- finalPrice is rounded here to mirror vanilla behavior, which we need for a few things.
	-- Keeping more granular values for basePrice lets us be slightly more generous and accurate
	-- with the faction bonus and max haggle margin.
	price.basePrice = basePricePer * count
	price.finalPrice = math.floor(basePricePer * vanillaRatio * count)
	log:debug("P       End - price.finalPrice: %s - price.basePrice: %s", price.finalPrice, price.basePrice)

end


---------- ---------- ---------- Adjustment Function ---------- ---------- ----------


local function SHBarterAdjust(e)

	if not config.modEnabled then
		log:debug("A Start End - modEnabled: %s", config.modEnabled)
		return
	end

	log:debug("A     Start - Item: %s - Buying: %s", e.item, e.buying)

	if config.baseStatsEnabled then
		stats.playerMercantile = tes3.mobilePlayer.mercantile.base
		stats.playerPersonality = tes3.mobilePlayer.personality.base
		stats.playerLuck = tes3.mobilePlayer.luck.base
	else
		stats.playerMercantile = tes3.mobilePlayer.mercantile.current
		stats.playerPersonality = tes3.mobilePlayer.personality.current
		stats.playerLuck = tes3.mobilePlayer.luck.current
	end
	
	local npc = tes3ui.getServiceActor()
	-- Using this method of getting skill value to avoid erroring out if the merchant is a creature
	stats.npcMercantile = npc:getSkillValue(tes3.skill.mercantile)
	stats.disposition = npc.object.disposition
	stats.isCreature = false
	
	-- Checking to see if merchant is a creature
	if not (stats.npcMercantile == nil or stats.disposition == nil) then
		if config.baseStatsEnabled then
			stats.npcMercantile = npc.mercantile.base
			stats.npcPersonality = npc.personality.base
			stats.npcLuck = npc.luck.base
		else
			stats.npcMercantile = npc.mercantile.current
			stats.npcPersonality = npc.personality.current
			stats.npcLuck = npc.luck.current
		end

		if config.mercEnabled then
			log:debug("A      Merc - Before: %s", stats.npcMercantile)

			local npcMercantileNew = math.round(stats.npcMercantile * config.mercMultiplier + config.mercAddend + (100 - stats.npcMercantile) * config.mercMultiplier2)

			stats.npcMercantile = math.max(npcMercantileNew,stats.npcMercantile)

			-- This is our semipermanent mercantile stat adjustment.  The code works, but it's
			-- disabled (via disabled and hidden MCM option) until I can figure out why it's not
			-- working how I want.

			if config.mercChangeEnabled and not (e.buying and not config.buyEnabled) then
				tes3.setStatistic{reference = npc, skill = tes3.skill.mercantile, current = stats.npcMercantile}
				log:debug("A MercChange - After: %s", npc.mercantile.current)
			end

			log:debug("A      Merc - After: %s - Add: %s - Mult: %s - Mult2: %s", stats.npcMercantile, config.mercAddend, config.mercMultiplier, config.mercMultiplier2)
		end
	-- Adjusting stats for creature merchants
	else
		stats.isCreature = true
		stats.npcMercantile = config.creatureStats
		stats.npcPersonality = config.creatureStats
		stats.npcLuck = config.creatureStats
		stats.disposition = 50
		log:debug("A  Creature - Detected - creatureStats: %s - creatureEnabled: %s", config.creatureStats, config.creatureEnabled)
	end

	log:debug("A    Player - Merc: %s - Pers: %s - Luck: %s - Base: %s", stats.playerMercantile, stats.playerPersonality, stats.playerLuck, config.baseStatsEnabled)
	log:debug("A       NPC - Merc: %s - Pers: %s - Luck: %s - Disp: %s", stats.npcMercantile, stats.npcPersonality, stats.npcLuck, stats.disposition)

	stats.playerBarterFactor = math.min(stats.disposition,100) - 50 + math.min(stats.playerMercantile,100) + math.min(stats.playerLuck,100)/10 + math.min(stats.playerPersonality,50)/5
	stats.npcBarterFactor = math.min(stats.npcMercantile,100) + math.min(stats.npcLuck,100)/10 + math.min(stats.npcPersonality,50)/5
	log:debug("A    Factor - Player: %s - NPC: %s", stats.playerBarterFactor, stats.npcBarterFactor)
	stats.sellRatio = 0.5 + (stats.playerBarterFactor - stats.npcBarterFactor) * 0.003125
	stats.buyRatio = 1.5 - (stats.playerBarterFactor - stats.npcBarterFactor) * 0.003125
	log:debug("A     Ratio - Sell: %s - Buy: %s", stats.sellRatio, stats.buyRatio)

	stats.factionBonus = 0
	-- Check if our NPC has a faction
	if config.factionEnabled and npc.object.faction then
		-- Get PC's rank in NPC's faction
		-- For rank in factions, -1 is not a member, and the first rank is 0.
		stats.playerFactionRank = npc.object.faction.playerRank + 1
		log:debug("A   Faction - NPC Faction: %s - playerFactionRank: %s", npc.object.faction, stats.playerFactionRank)

		if stats.playerFactionRank ~= 0 then
			stats.factionBonus = (1 - stats.sellRatio) * (config.factionBase + stats.playerFactionRank * config.factionMultiplier)
			log:debug("A   Faction - Raw Bonus: %s - factionBonus: %s", config.factionBase + stats.playerFactionRank * config.factionMultiplier, stats.factionBonus)
		end
	end

	-- This is the price cap feature.  It's disabled, with the option hidden, by default.
	-- I haven't tested this very much, but I think it works fine.  Just seemed unnecessary.
	if config.capEnabled and (stats.sellRatio + stats.factionBonus > 0.97 or stats.buyRatio - stats.factionBonus < 1.03) then
		log:debug("A     Ratio - Cap Exceeded - sell: %s - buy: %s", stats.sellRatio + stats.factionBonus, stats.buyRatio - stats.factionBonus)
		stats.factionBonus = 0
		stats.sellRatio = 0.97
		stats.buyRatio = 1.03
	end

	-- We want the basic calculations run above to be performed at least once, even if the purchase
	-- price adjustment option is disabled, to make sure the barterOffer function works properly.
	-- That's why this check is here instead of the start of this function.  Everything above
	-- (barring the mercantile change) is just internal calculations.
	if e.buying and not config.buyEnabled then
		log:debug("A   Buy End - Buying: %s - buyEnabled: %s", e.buying, config.buyEnabled)
		return
	end

	if config.modClaim then
		e.claim = true
		log:debug("A     Claim - modClaim: %s - modPriority: %s", config.modClaim, config.modPriority)
	end

	-- e.itemData is nil on items without itemData flags.  Setting it to false will prevent errors
	-- for functions that need a value, while still working with boolean logic.
	if e.itemData == nil then
		e.itemData = false
	end

	SHBarterPrice(e.basePrice, e.count, e.buying, e.item, e.itemData, "calcBarterPrice")
	e.price = price.finalPrice
	log:debug("A       End - e.price: %s", e.price)

end

---------- ---------- ---------- Haggle Function ---------- ---------- ----------


--[[
Have you ever had one of those moments where you think, "Well, this should do it," believing that you're only a few steps away from being done?  And then you finish what you planned, and you confidently go to test your work, but you instead realize, "Oh.  This won't do at all.  Not only will I need to throw a lot of my earlier work away, but all I really accomplished was shining a light on the huge mountain of work that lies ahead."
]]--

local function SHBarterHaggle(e)

	if not config.modEnabled or not config.haggleEnabled or not config.vanillaEnabled or not config.buyEnabled then
		log:debug("H Start End - mod: %s - haggle: %s - vanilla: %s - buy: %s", config.modEnabled, config.haggleEnabled, config.vanillaEnabled, config.buyEnabled)
		return
	end
	log:debug("H     Start - e.value: %s - block: %s - claim: %s - priority: %s", e.value, config.haggleBlock, config.modClaim, config.modPriority)

	if config.haggleBlock then
		e.block = true
	end

	if config.modClaim then
		e.claim = true
	end

	local buyFinalTotal = 0
	local buyBaseTotal = 0
	local sellFinalTotal = 0
	local sellBaseTotal = 0

	if #e.buying > 0 then
		for _, tile in ipairs(e.buying) do
			log:debug("H  BuyStart - Item: %s - #: %s - Value: %s", tile.item.id, tile.count, tile.item.value)

			-- Need to sanitize tile.itemData to avoid erroring out by passing a nil value, but
			-- it's read-only.  We'll use a variable instead.
			if tile.itemData == nil then
				itemData = false
			else
				itemData = tile.itemData
			end
		
			-- We're manually setting the value for the buying boolean variable.
			SHBarterPrice(tile.item.value, tile.count, true, tile.item, itemData, "barterOffer")

			buyFinalTotal = buyFinalTotal + price.finalPrice
			buyBaseTotal = buyBaseTotal + price.basePrice
			log:debug("H    BuyEnd - finalPrice: %s - basePrice: %s", price.finalPrice, price.basePrice)
		end
		log:debug("H  BuyTotal - buyFinalTotal: %s - buyBaseTotal: %s", buyFinalTotal, buyBaseTotal)
	end

	if #e.selling > 0 then
		for _, tile in ipairs(e.selling) do
			log:debug("H SellStart - Item: %s - #: %s - Value: %s", tile.item.id, tile.count, tile.item.value)

			if tile.itemData == nil then
				itemData = false
			else
				itemData = tile.itemData
			end
			
			SHBarterPrice(tile.item.value, tile.count, false, tile.item, itemData, "barterOffer")

			sellFinalTotal = sellFinalTotal + price.finalPrice
			sellBaseTotal = sellBaseTotal + price.basePrice
			log:debug("H   SellEnd - finalPrice: %s - basePrice: %s", price.finalPrice, price.basePrice)
		end
		log:debug("H SellTotal - sellFinalTotal: %s - sellBaseTotal: %s", sellFinalTotal, sellBaseTotal)
	end

	local finalTotal = sellFinalTotal - buyFinalTotal
	local absBaseTotal = sellBaseTotal + math.abs(buyBaseTotal)
	log:debug("H     Total - buyF: %s - buyB: %s - sellF: %s - sellB: %s - f: %s - absB: %s", buyFinalTotal, buyBaseTotal, sellFinalTotal, sellBaseTotal, finalTotal, absBaseTotal)
	

	-- haggleMargin is the best possible proportional price change from haggling.
	-- haggleTotal is the total factoring in haggleMargin, or the most favorable possible deal.
	local haggleMargin = math.max(stats.playerBarterFactor,config.haggleMinFactor) / ((stats.sellRatio + stats.factionBonus + config.haggleAddend) * config.haggleMultiplier) ^ config.haggleExponent / 100
	local haggleTotal = math.ceil(sellBaseTotal * (stats.sellRatio + stats.factionBonus + haggleMargin) - buyBaseTotal * (stats.buyRatio - stats.factionBonus - haggleMargin))
	log:debug("H    Haggle - haggleMargin: %s - haggleTotal: %s", haggleMargin, haggleTotal)

	local mercantileMinXP = config.haggleMinXP
	if config.haggleXPScaling then
		mercantileMinXP = math.min(config.haggleMinXP, absBaseTotal / (config.haggleMaxXP * config.haggleXPDivisor) * config.haggleMinXP)
	end
	local mercantileXP = math.max(mercantileMinXP, (e.offer - finalTotal) / (haggleTotal - finalTotal) * config.haggleMaxXP)
	-- Checking if XP exceeds price-based cap, lowering it if it does
	if config.haggleXPScaling and mercantileXP > absBaseTotal / config.haggleXPDivisor then
		mercantileXP = absBaseTotal / config.haggleXPDivisor
	end
	log:debug("H        XP - Min: %s - Current: %s - Cap: %s - Scale: %s", mercantileMinXP, mercantileXP, absBaseTotal / config.haggleXPDivisor, config.haggleXPScaling)
	
	-- If you're mostly selling, lower prices are more favorable to the npc.
	-- If you're mostly buying, e.offer is negative, and lower values mean you're giving the npc
	-- more money, so that's also more favorable.
	-- Checking for creature merchants and Harder Creature Barter
	if not (stats.isCreature and not config.creatureEnabled) then
		if e.offer <= haggleTotal then
			if config.barterReject then
				e.success = false
				log:debug("H       End - Offer: %s - Accepted - barterReject", e.offer)
				tes3.messageBox("Accepted - barterReject")
			else
				e.success = true
				log:debug("H       End - Offer: %s - Accepted", e.offer)
			end

			tes3.mobilePlayer:exerciseSkill(tes3.skill.mercantile, mercantileXP)
			log:debug("H        XP - mercantileXP: %s", mercantileXP)
		else
			e.success = false
			log:debug("H       End - Offer: %s - Rejected", e.offer)
		end
	-- Refusing any haggle offers if using vanilla creature merchant behavior
	else
		if e.offer == finalTotal then
			if config.barterReject then
				e.success = false
				log:debug("H       End - Creature - Offer: %s - finalTotal: %s - Accepted - barterReject", e.offer, finalTotal)
			else
				e.success = true
				log:debug("H       End - Creature - Offer: %s - finalTotal: %s - Accepted", e.offer, finalTotal)
			end

			tes3.mobilePlayer:exerciseSkill(tes3.skill.mercantile, mercantileMinXP)
			log:debug("H        XP - mercantileMinXP: %s", mercantileMinXP)
		else
			e.success = false
			log:debug("H       End - Creature - Offer: %s - finalTotal: %s - Rejected", e.offer, finalTotal)
		end
	end

end

---------- ---------- ---------- Initialize ---------- ---------- ----------


local function initialize()
	if (mwse.buildDate == nil or mwse.buildDate < 20190715) then
		modConfig.hidden = true
		tes3.messageBox("Smarter Harder Barter requires a newer version of MWSE. Please run MWSE-Update.exe.", mwse.buildDate)
		return
	end
	event.register("calcBarterPrice", SHBarterAdjust, {priority = config.modPriority})
	event.register("barterOffer", SHBarterHaggle, {priority = config.modPriority})

	print("[Smarter Harder Barter Initialized]")
end

event.register("initialized", initialize)


---------- ---------- ---------- Mod Config Menu ---------- ---------- ----------


local function createTableVar(id)
	return mwse.mcm.createTableVariable{
		id = id,
		table = config
	}
end


-- This might be handy in the future?  I was gonna work on compatibility features, but I decided
-- to publish 2.0 first, so I'll just leave this alone for now.  This function's call is commented,
-- so it will do nothing for now.
-- It seems to work in the small amount of testing I've done, but idk.
local function reregisterEvents(newPriority)
	event.unregister("calcBarterPrice", SHBarterAdjust)
	event.unregister("barterOffer", SHBarterHaggle)
	event.register("calcBarterPrice", SHBarterAdjust, {priority = newPriority})
	event.register("barterOffer", SHBarterHaggle, {priority = newPriority})

	if config.logLevel ~= "NONE" then
		tes3.messageBox("reregisterEvents")
	end
end


local function registerModConfig()
    local template = mwse.mcm.createTemplate("Smarter Harder Barter")
	template:saveOnClose("SHBarter", config)

	function template.onClose()
		mwse.saveConfig("SHBarter", config)
		--reregisterEvents(config.modPriority)
	end

    local page = template:createSideBarPage("Main Settings")
    local categoryMain = page:createCategory("Settings")

	page.sidebar:createInfo{
		text = "Smarter Harder Barter is a price adjustment mod, made with the goal of creating a vanilla+ yet more balanced trading experience.\n\n" ..
		"Mouse over individual settings for more information.  Additional details can be found on the mod page or in the readme file.\n\n" ..
		"Version 2.0 marked a major overhaul of this mod, with a number of new features added.  If you're updating from 1.0, please see the mod page for more details."
	}

	categoryMain:createYesNoButton{
		label = "Enable Smarter Harder Barter",
		description = "Toggles all functions on or off.\n\n" ..
		"Default: Yes",
		variable = createTableVar("modEnabled"),
		defaultSetting = true
	}

	categoryMain:createYesNoButton{
		label = "Enable Basic Price Calculations",
		description = "Toggles basic price calculations (the normal price adjustments caused by disposition, mercantile, etc.).\n\n" ..
		"This mod's basic price formula is the same as that implemented by the Morrowind Code Patch, listed as 'Mercantile fix' under 'Bug fixes'.  You may notice different prices compared to the vanilla game, due to the effects of other settings.\n\n"..
		"Default: Yes",
		variable = createTableVar("vanillaEnabled"),
		defaultSetting = true
	}

	categoryMain:createYesNoButton{
		label = "Enable Sales Price Log Function",
		description = "This setting leaves the prices of most items (those below the specified cutoff value) alone while gradually decreasing the sale value of items above that.  One should expect large price decreases for the most expensive items.  This is designed to curtail the economy-breaking potential of finding and selling certain very expensive items (daedric items, artifacts, etc.).\n\n" ..
		"Default: Yes",
		variable = createTableVar("logarithmEnabled"),
		defaultSetting = true
	}

	categoryMain:createDropdown{
		label = "Sales Price Log Function Difficulty:",
		description = "These presets adjust the intensity of the sales price logarithmic function.\n\n" ..
		"Standard Difficulty: The cutoff value is 300, with a log base of 1.71.  Sharp decrease in item value above 1,000 septims.  Items above 5,000 septims are worth 1/5th to 1/10th of their original value.\n\n" ..
		"Harder Difficulty: Cutoff value is 250, with a log base of 1.54.  Expensive items are worth roughly 20% less than Standard.\n\n" ..
		"Harderer Difficulty: Cutoff value is 200, with a log base of 1.31.  Expensive items are worth roughly 50% less than Standard.\n\n" ..
		"Custom Difficulty: Select Custom to use a specified cutoff value and log base.  Cutoff value must be 1 or greater, and log base must be 1.01 or greater, or the mod will default back to Standard difficulty when Custom is selected.\n\n" ..
		"Default: 1. Standard",
		options = {
			{ label = "1. Standard", value = 1 },
			{ label = "2. Harder", value = 2 },
			{ label = "3. Harderer", value = 3 },
			{ label = "4. Custom", value = 4 },
		},
		variable = mwse.mcm.createTableVariable{
			id = "difficulty",
			table = config,
			converter = tonumber
        },
	}

	categoryMain:createTextField{
		label = "Custom Sales Price Cutoff Value:",
		description = "Items with a base price below this value will be unaffected by the logarithmic function, and prices will gradually roll off beyond it.\n\n" ..
		"This value must be 1 or greater, or the mod will default to Standard difficulty when Custom is selected.\n\n" ..
		"You must set the Difficulty to '4. Custom' for the Custom Sales Price Cutoff Value and Custom Sales Price Log Base to have any effect.\n\n" ..
		"Default: 300",
		variable = mwse.mcm.createTableVariable{
			id = "customCutoff",
			table = config,
			converter = tonumber
		},
		numbersOnly = true
	}

	categoryMain:createTextField{
		label = "Custom Sales Price Log Base:",
		description = "The log base controls the rate of price falloff past the cutoff value.  Lower values will cause prices to decrease faster, and higher values will be slower.\n\n" ..
		"This value must be 1.01 or greater, or the mod will default to Standard difficulty when Custom is selected.\n\n" ..
		"You must set the Difficulty to '4. Custom' for the Custom Sales Price Cutoff Value and Custom Sales Price Log Base to have any effect.\n\n" ..
		"Default: 1.71",
		variable = mwse.mcm.createTableVariable{
			id = "customLogbase",
			table = config,
			converter = tonumber
		},
		numbersOnly = true
	}

	categoryMain:createYesNoButton{
		label = "Enable Purchase Price Adjustments",
		description = "Toggles the mod's ability to affect purchase prices (how much you pay merchants to buy items).\n\n" ..
		"This setting is a significant rebalance of purchase prices, and one should expect to pay more for items.  If enabled, merchants will no longer sell items for less than the item's base price, and there will no longer be any advantage to artificially lowering disposition or one's stats.\n\n"..
		"Mercantile, disposition, and other stats will still affect prices, with their effect on purchase prices mirroring their effect on sales prices.  For example, if your skills normally result in sales prices that are 70% of an item's base price, this setting would result in purchase prices that are 130% of base price.  Similarly, a sales price of 90% would be reflected by a purchase price of 110%.\n\n"..
		"Default: Yes",
		variable = createTableVar("buyEnabled"),
		defaultSetting = true
	}

	categoryMain:createYesNoButton{
		label = "Enable Purchase Price Logarithmic Function",
		description = "Toggles a separate logarithmic function designed to reduce purchase prices in extreme scenarios.\n\n" ..
		"This setting is a roleplay consistency and fairness mechanic, making it feasible to buy back very expensive items whose sale price was significantly reduced by the sales price logarithmic function.\n\n"..
		"By default, this function uses a very high cutoff value, so it should not make normal purchases easier.  The log base is also tuned such that you'll still pay a significant premium over the item's sales price.  This is primarily intended to limit your losses to a few thousand septims versus tens of thousands.\n\n"..
		"Default: Yes",
		variable = createTableVar("buyLogarithmEnabled"),
		defaultSetting = true
	}

	categoryMain:createTextField{
		label = "Purchase Price Cutoff Value:",
		description = "Items with a base price below this value will be unaffected by the logarithmic function applied to buying items, and prices will gradually roll off beyond it.\n\n" ..
		"This value must be 1 or greater, or the mod will use default values instead.\n\n" ..
		"Default: 5000",
		variable = mwse.mcm.createTableVariable{
			id = "buyCutoff",
			table = config,
			converter = tonumber
		},
		numbersOnly = true
	}

	categoryMain:createTextField{
		label = "Purchase Price Log Base:",
		description = "The log base controls the rate of price falloff past the cutoff value.  Lower values will cause prices to decrease faster, and higher values will be slower.\n\n" ..
		"It is recommended not to adjust this value below 1.17, to avoid potential price exploits.\n\n" ..
		"This value must be 1.01 or greater, or the mod will use default values instead.\n\n" ..
		"Default: 1.31",
		variable = mwse.mcm.createTableVariable{
			id = "buyLogbase",
			table = config,
			converter = tonumber
		},
		numbersOnly = true
	}

-- I'm not sure if this setting will be useful, and it will intereact badly with certain configs.
-- I'm also worried about confusing people with option bloat.  So I'm disabling this.
-- 0.97 and 1.03 were selected because those values keep ppl at 0.99 and 1.01 after haggling.
--[[
	categoryMain:createYesNoButton{
		label = "Enable Safe Price Limit",
		description = "This setting adds a hard cap of 97% of base price for sales prices and a hard floor of 103% for purchase prices.\n\n" ..
		"This setting is generally not necessary, as even in the most advantageous situations, you cannot hit these limits with the default settings of this mod.  It is only possible if specific settings are disabled.  This setting is offered as an optional guard rail to prevent potential exploits in those situations.\n\n"..
		"This setting may not work well with certain configurations of this mod.\n\n"..
		"Default: No",
		variable = createTableVar("capEnabled"),
		defaultSetting = false
	}
]]--


---------- ---------- ---------- Stats Settings Page ---------- ---------- ----------


    local page2 = template:createSideBarPage("Stat Adjustment")
	local categoryStats = page2:createCategory("Settings")

	page2.sidebar:createInfo{
		text = "This page is used for settings that tweak the skills and attributes using during the trading process.\n\n" ..
		"Mouse over individual settings for more information.  Additional details can be found on the mod page or in the readme file."
	}

	categoryStats:createYesNoButton{
		label = "Enable Mercantile Adjustment",
		description = "Toggles a scaling mercantile boost for all merchants.  This bonus is greater for merchants with lower skill.\n\n" ..
		"By default, most merchants in Morrowind have a fairly low mercantile skill, often in the 10-20 range.  This feature boosts these numbers to more realistic levels.  Using default settings, 5 mercantile becomes 25, 25 becomes 40, 50 becomes 58, etc.  The bonus gradually diminishes with higher skill, with boosted and base game stats converging at 80 mercantile.\n\n" ..
		"Enabling this setting doesn't actually change a merchant's stats, only the mod's internal calculations, so it shouldn't conflict with other mods or cause lasting changes.\n\n" ..
		"If the values specified would lower a given merchant's mercantile, their mercantile will instead be left as-is.\n\n" ..
		"Default: Yes",
		variable = createTableVar("mercEnabled"),
		defaultSetting = true
	}

	-- This kinda works, but it has proven not quite as temporary as I'd like, and I'm not sure how
	-- to fix it right now.  I think it's better to just leave the option hidden for now than risk
	-- messing with somebody's save.
	--[[
	categoryStats:createYesNoButton{
		label = "Enable Mercantile Stat Change",
		description = "This setting enables a temporary change to a merchant's actual mercantile stat, using the same formula as the Mercantile Adjustment setting above.\n\n" ..
		"This setting is not necessary if you are using default settings.  However, if you disabled this mod's Haggle Revamp or Purchase Price Adjustment, it is recommended to enable this setting instead, as this will improve the tuning of vanilla mechanics (the Enable Mercantile Adjustment setting above has no effect on calculations not performed by the mod).  Note that enabling this setting may cause compatibility issues with other mods that are affected by a merchant's mercantile stat.\n\n" ..
		"This setting will only take effect if Enable Mercantile Adjustment is also set to true.\n\n" ..
		"Default: No",
		variable = createTableVar("mercChangeEnabled"),
		defaultSetting = false
	}
	]]--

	categoryStats:createTextField{
		label = "Mercantile Addend",
		description = "This is a flat value added to the NPC's mercantile.\n\n" ..
		"If the values specified would lower a given merchant's mercantile, their mercantile will instead be left as-is.\n\n" ..
		"Formula: Round(Base * Multiplier1 + Addend + (100 - Base) * Multiplier2)\n\n" ..
		"Default: 0",
		variable = mwse.mcm.createTableVariable{
			id = "mercAddend",
			table = config,
			converter = tonumber
		},
		numbersOnly = true
	}

	categoryStats:createTextField{
		label = "Mercantile Multiplier 1",
		description = "This is a multiplier applied to the NPC's base mercantile.  It is applied before the addend.  The default value is set below 1 to help flatten scaling at higher mercantile levels.\n\n" ..
		"If the values specified would lower a given merchant's mercantile, their mercantile will instead be left as-is.\n\n" ..
		"Formula: Round(Base * Multiplier1 + Addend + (100 - Base) * Multiplier2)\n\n" ..
		"Default: 0.94",
		variable = mwse.mcm.createTableVariable{
			id = "mercMultiplier",
			table = config,
			converter = tonumber
		},
		numbersOnly = true
	}

	categoryStats:createTextField{
		label = "Mercantile Multiplier 2",
		description = "This value is multiplied by the difference between 100 and the NPC's mercantile, with the result added as a bonus.  This provides the inverse scaling which boosts less-skilled merchants more.\n\n" ..
		"If the values specified would lower a given merchant's mercantile, their mercantile will instead be left as-is.\n\n" ..
		"Formula: Round(Base * Multiplier1 + Addend + (100 - Base) * Multiplier2)\n\n" ..
		"Default: 0.215",
		variable = mwse.mcm.createTableVariable{
			id = "mercMultiplier2",
			table = config,
			converter = tonumber
		},
		numbersOnly = true
	}

	categoryStats:createYesNoButton{
		label = "Use Base Stats",
		description = "This setting forces the mod to use the base stats of both the player and merchant, rather than their fortified or drained stats, for the purpose of basic price calculations.  This should still factor in the Personality bonus from The Lady birthsign.\n\n" ..
		"This setting is intended to reduce the power of combining menu pausing and high magnitude, low duration spells.\n\n" ..
		"Default: Yes",
		variable = createTableVar("baseStatsEnabled"),
		defaultSetting = true
	}

	categoryStats:createYesNoButton{
		label = "Enable Harder Creature Barter",
		description = "This setting limits the utility of creature merchants like the Creeper (the scamp merchant) and mudcrab merchant.\n\n" ..
		"Creature merchants have no mercantile skill, which causes them to bypass price calculations and buy items for their full base price.  For those who wish to use these NPC's, this can potentially be disruptive to the game economy.  Enabling this setting will make the mod detect creature merchants and assign them stats for the purpose of the basic price formula.  To balance their high gold amounts and buy list, they have become shrewd negotiators with formidable stats.  Compared to regular merchants, their stats are tuned to pay out roughly 35% less to player characters with lower barter stats and 25% less to characters with very high barter stats.  This should leave them with some utility, without them necessarily being the best choice for selling all items.\n\n"..
		"If this setting is enabled, creature merchants are treated as having 50 disposition toward you, with their relevant bargaining stats assumed to be 55.  This number can be changed via the Creature Merchant Stats option below.\n\n"..
		"Even if this option is disabled, the logarithmic price reduction for expensive items still applies while using creature merchants.\n\n"..
		"Default: Yes",
		variable = createTableVar("creatureEnabled"),
		defaultSetting = true
	}

	categoryStats:createTextField{
		label = "Creature Merchant Stats:",
		description = "This is the value used to override creature merchant stats if the Harder Creature Barter setting above is enabled.  Please see that setting for more details.\n\n" ..
		"Default: 55",
		variable = mwse.mcm.createTableVariable{
			id = "creatureStats",
			table = config,
			converter = tonumber
		},
		numbersOnly = true
	}


---------- ---------- ---------- Haggle Settings Page ---------- ---------- ----------


    local page3 = template:createSideBarPage("Haggle")
	local categoryHaggle = page3:createCategory("Settings")

	page3.sidebar:createInfo{
		text = "This page is for settings that affect haggling, the mechanic by which player characters manually change their price offer, which a merchant may accept or reject.\n\n" ..
		"Mouse over individual settings for more information.  Additional details can be found on the mod page or in the readme file."
	}

	categoryHaggle:createYesNoButton{
		label = "Enable Haggle Revamp",
		description = "This setting completely revamps haggling.  When combined with the default configuration of this mod, merchants will no longer purchase items for more than their sale price, eliminating potential infinite gold exploits.\n\n" ..
		"With this setting enabled, it will get much harder to haggle prices up or down as you get closer to an item's base price.  For example, somebody with lower barter skills would be able to haggle their price from 40% to 44% of the base price, resulting in a 10% overall increase.  Meanwhile, somebody with peak barter skills might only be able to haggle their initial price from 90% to 92%.  The same applies to haggling down prices while buying.\n\n" ..
		"This is balanced such that, when factoring in both haggling and initial prices, you're always better off with higher skills and attributes.  For this reason, it's neither useful nor possible to game this system by deliberately lowering your disposition or stats.\n\n"..
		"This setting also eliminates randomness from the haggling process.  Merchants will now simply accept or refuse trade offers, with no dice roll.  Mercantile XP has also been retuned to compensate for these changes, with a goal of maintaining a mostly vanilla rate of progress.\n\n"..
		"This feature requires Basic Price Calculations and Purchase Price Adjustments to both be enabled to function.\n\n"..
		"Default: Yes",
		variable = createTableVar("haggleEnabled"),
		defaultSetting = true
	}

	categoryHaggle:createTextField{
		label = "Haggle Addend",
		description = "This value is a flat modifier added to the sales price ratio before other calculations, which helps to smooth progression and mitigate broken results when dealing with very low prices.  This should be a low decimal value, recommended to be in the range of 0.1 to 0.3.\n\n" ..
		"These values are used to calculate the maximum margin attainable by haggling for a given initial price.  Both this margin and the sales price mentioned in the formula below are decimal values that are a ratio of the item's base price.\n\n" ..
		"Formula: Margin = Max(PC Barter Factor, Minimum) / ((Price + Addend) * Multiplier) ^ Exponent / 100\n\n" ..
		"Default: 0.2",
		variable = mwse.mcm.createTableVariable{
			id = "haggleAddend",
			table = config,
			converter = tonumber
		},
		numbersOnly = true
	}

	categoryHaggle:createTextField{
		label = "Haggle Multiplier",
		description = "This value controls linear scaling.  This should be tuned in conjunction with the exponent setting below to get the desired price scaling.  Recommended values are in the 4 to 10 range.\n\n" ..
		"These values are used to calculate the maximum margin attainable by haggling for a given initial price.  Both this margin and the sales price mentioned in the formula below are decimal values that are a ratio of the item's base price.\n\n" ..
		"Formula: Margin = Max(PC Barter Factor, Minimum) / ((Price + Addend) * Multiplier) ^ Exponent / 100\n\n" ..
		"Default: 5.4",
		variable = mwse.mcm.createTableVariable{
			id = "haggleMultiplier",
			table = config,
			converter = tonumber
		},
		numbersOnly = true
	}

	categoryHaggle:createTextField{
		label = "Haggle Exponent",
		description = "This controls the exponential scaling of this feature, allowing for a rolloff of haggle margins with higher skill levels.  This should be tuned in concert with the multiplier setting above, with recommended values being between 1.25 and 3.\n\n" ..
		"These values are used to calculate the maximum margin attainable by haggling for a given initial price.  Both this margin and the sales price mentioned in the formula below are decimal values that are a ratio of the item's base price.\n\n" ..
		"Formula: Margin = Max(PC Barter Factor, Minimum) / ((Price + Addend) * Multiplier) ^ Exponent / 100\n\n" ..
		"Default: 2.5",
		variable = mwse.mcm.createTableVariable{
			id = "haggleExponent",
			table = config,
			converter = tonumber
		},
		numbersOnly = true
	}

	categoryHaggle:createTextField{
		label = "Haggle Minimum Barter Factor",
		description = "This setting adds a floor for the PC's barter factor for the purpose of this equation.  This offers a minor bonus to characters with very low barter skills, allowing them to haggle too, but the primary purpose is preventing the bugs and balance issues which appear in this formula if the player's barter factor is near zero or negative.  Values in the 10 to 20 range are recommended.\n\n" ..
		"These values are used to calculate the maximum margin attainable by haggling for a given base price.  Both this margin and the sales price ratio are decimal values that are a ratio of the item's base price.\n\n" ..
		"Formula: Margin = Max(PC Barter Factor, Minimum) / ((Price + Addend) * Multiplier) ^ Exponent / 100\n\n" ..
		"Default: 11.5",
		variable = mwse.mcm.createTableVariable{
			id = "haggleMinFactor",
			table = config,
			converter = tonumber
		},
		numbersOnly = true
	}

	categoryHaggle:createTextField{
		label = "Minimum Mercantile XP",
		description = "This number determines the minimum Mercantile XP you will get while trading.  This includes both trades while haggling and trades where you don't haggle at all.\n\n" ..
		"The vanilla value is 0.3, but the significantly higher default of 1.5 in this mod is intended to offer some incremental progress for those who don't consistently use the haggle system.\n\n" ..
		"This value may be lowered by the Price-Based XP Scaling feature below.\n\n" ..
		"Default: 1.5",
		variable = mwse.mcm.createTableVariable{
			id = "haggleMinXP",
			table = config,
			converter = tonumber
		},
		numbersOnly = true
	}

	categoryHaggle:createTextField{
		label = "Maximum Mercantile XP",
		description = "This number the maximum possible XP you will get from haggling.\n\n" ..
		"The value set here is the maximum possible XP, which you will get if you negotiate the best possible deal which the merchant will accept.  Anything less will get you a proportion of that XP.  For example, if your price is halfway between the starting price and the best possible price, you will get half of this amount.\n\n" ..
		"The theoretical maximum in the vanilla game is 30, but this is only attainable by repeatedly clicking extremely unlikely trades.  This mod's default value of 12.5 (42% of the vanilla maximum) was chosen because it was more reflective of a real world advancement rate in the vanilla game.\n\n" ..
		"This value may be lowered by the Price-Based XP Scaling feature below.\n\n" ..
		"Default: 12.5",
		variable = mwse.mcm.createTableVariable{
			id = "haggleMaxXP",
			table = config,
			converter = tonumber
		},
		numbersOnly = true
	}

	categoryHaggle:createYesNoButton{
		label = "Enable Price-Based XP Scaling",
		description = "This setting partially ties mercantile XP to item value, meaning you will not get the full XP reward when selling low value items.  This setting prevents excessive XP reward from buying or selling multitudes of low value items, and it allows for more generous XP tuning for larger transactions.\n\n" ..
		"If enabled, this setting combines the base price of all items being bought and sold in a given trade and divides them by the divisor below.  The result is a cap on the XP you can gain for that trade.\n\n" ..
		"Minimum XP also scales, though in a different way.   In this case, the formula is: Scaled Min XP = Total Base Value / (Max XP * XP Divisor) * Min XP\n\n" ..
		"Default: True",
		variable = createTableVar("haggleXPScaling"),
		defaultSetting = true

	}

	categoryHaggle:createTextField{
		label = "Mercantile XP Scaling Divisor",
		description = "This number sets the divisor used to control the price-based scaling of Mercantile XP rewards.\n\n" ..
		"Default: 25",
		variable = mwse.mcm.createTableVariable{
			id = "haggleXPDivisor",
			table = config,
			converter = tonumber
		},
		numbersOnly = true
	}


---------- ---------- ---------- Faction Settings Page ---------- ---------- ----------


    local page4 = template:createSideBarPage("Faction")
	local categoryFaction = page4:createCategory("Settings")

	page4.sidebar:createInfo{
		text = "These settings control the mod's faction bonus settings.\n\n" ..
		"Mouse over individual settings for more information.  Additional details can be found on the mod page or in the readme file."
	}

	categoryFaction:createYesNoButton{
		label = "Enable Faction Bonus",
		description = "This feature offers better sales and purchase prices when shopping at vendors from factions you belong to.  This is designed to provide a roleplay-based alternative to raising your barter skills, to help balance the increased difficulty of this mod for characters with lower barter skills.\n\n"..
		"Merchants still won't offer you deals that don't make financial sense for them, so this bonus gets smaller as you approach the item's base price, meaning it has significantly more effect for characters with lower barter skills.  For example, if your normal sales price is 40% of the item's base price, and you have a 20% faction bonus, your bonus will be be 0.2 * (1 - 0.4), or 12% of the item's base price.  This would give you an initial price of 52% instead of 40%.  Meanwhile, somebody with a 90% initial price and a 20% faction bonus would instead get 92%, a much smaller proportional increase.\n\n"..
		"Default: Yes",
		variable = createTableVar("factionEnabled"),
		defaultSetting = true
	}

	categoryFaction:createTextField{
		label = "Faction Base Bonus",
		description = "This is the base bonus you get for belonging to the same faction as a NPC.  Your bonus will be higher than this in practice, as you start with one level of the rank bonus below.\n\n" ..
		"This setting defaults to a low value to account for the ease of joining factions, with the bonus growing much larger as you rise in rank.\n\n" ..
		"In the formula below, both the Bonus and Sales Price are decimal values that denote a proportion of the item's base price.  It's recommended to keep the full bonus at max faction rank in the 0.1 to 0.5 range.\n\n" ..
		"Formula: Bonus = (1 - Sales Price) * (Base Bonus + Rank Bonus * Rank)\n\n" ..
		"Default: 0.05",
		variable = mwse.mcm.createTableVariable{
			id = "factionBase",
			table = config,
			converter = tonumber
		},
		numbersOnly = true
	}

	categoryFaction:createTextField{
		label = "Faction Rank Bonus",
		description = "This bonus is multiplied by your faction rank (which ranges from 1 to 10) and added to the base bonus above.  This starts at rank 1, so you will always have at least one level of this bonus.\n\n" ..
		"In the formula below, both the Bonus and Sales Price are decimal values that denote a proportion of the item's base price.  It's recommended to keep the full bonus at max faction rank in the 0.1 to 0.5 range.\n\n" ..
		"Formula: Bonus = (1 - Sales Price) * (Base Bonus + Rank Bonus * Rank)\n\n" ..
		"Default: 0.02",
		variable = mwse.mcm.createTableVariable{
			id = "factionMultiplier",
			table = config,
			converter = tonumber
		},
		numbersOnly = true
	}


---------- ---------- ---------- Debug Settings Page ---------- ---------- ----------


    local page5 = template:createSideBarPage("Debug")
	local categoryDebug = page5:createCategory("Settings")

	page5.sidebar:createInfo{
		text = "These settings are used for logging and debugging, to help with development and troubleshooting.  These settings should not be changed during normal use.\n\n" ..
		"Mouse over individual settings for more information."
	}

	categoryDebug:createDropdown{
		label = "Logging Level:",
		description = "This setting controls the level of logging for the mod.  Use the DEBUG setting for more information.  This mod's logging is quite verbose, so it should be disabled during normal use.\n\n"..
		"Default: NONE",
		options = {
			{ label = "TRACE", value = "TRACE" },
			{ label = "DEBUG", value = "DEBUG" },
			{ label = "INFO", value = "INFO" },
			{ label = "ERROR", value = "ERROR" },
			{ label = "NONE", value = "NONE" },
		},
		variable = createTableVar("logLevel"),
		callback = function(self)
			log:setLogLevel(self.variable.value)
		end
	}

	-- A few of these served a purpose earlier while I was testing new features.  I considered
	-- leaving mod priority and mod claim visible for advanced users, but I guess it's better
	-- to just disable all of these, to avoid ppl causing issues for themselves.

	-- Most are functional, but I should probably remove the code for some of these entirely later,
	-- to clean things up.
	
	--[[
	categoryDebug:createYesNoButton{
		label ="All Barter Offers Rejected",
		description = "* WARNING *  If you enable this, you will NOT be able to buy or sell ANYTHING.  This setting is for testing only.\n\n" ..
		"This setting causes all barter offers to be rejected.  This is useful for testing the script's function during the barterOffer event without needing to buy back or spawn items for successive tests.\n\n" ..
		"Default: No",
		variable = createTableVar("barterReject"),
		defaultSetting = false
	}

	categoryDebug:createYesNoButton{
		label ="Block Vanilla Haggle Logic",
		description = "* WARNING * Enabling this will make you NOT be able to buy or sell ANYTHING.  This setting is for testing only.\n\n" ..
		"This setting sets e.block, which causes all successful barterOffer offers to instead trigger the barter failure event.  Being able to toggle this is useful for testing certain behaviors, particularly comparing success results with and without the plugin.\n\n" ..
		"Default: No",
		variable = createTableVar("haggleBlock"),
		defaultSetting = false
	}

	categoryDebug:createYesNoButton{
		label = "Override Other Mods",
		description = "* WARNING * Enabling this setting might break or cause unexpected behavior with other mods.  This setting does not guarantee compatibility, so use it at your own risk, and only if you know what you're doing.\n\n" ..
		"Enabling this setting will set e.claim to true, causing the mod to disable lower priority mods during the barterOffer and calcBarterPrice events.  This is for testing purposes only, as it may cause seemingly unrelated functions of other mods to break.\n\n" ..
		"Default: No",
		variable = createTableVar("modClaim"),
		defaultSetting = false
	}

	categoryDebug:createTextField{
		label = "Mod Priority:",
		description = "This sets the mod's priority, controlling when it runs in relation to other scripted mods that deal with the same things.\n\n" ..
		"Using a higher value than a given mod will cause this mod's scripts to run first.  A lower value will cause them to run after.  If you've enabled the Override Other Mods setting, this mod will block any lower priority mods from running after it.\n\n" ..
		"0 is the value which mods default to if no priority is set.\n\n" ..
		"Default: 0",
		variable = mwse.mcm.createTableVariable{
			id = "modPriority",
			table = config,
			converter = tonumber
		},
		numbersOnly = true
	}
	]]--

	mwse.mcm.register(template)
end
event.register("modConfigReady", registerModConfig)
								
