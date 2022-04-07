--[[
	Mod Initialization: Smarter Harder Barter
	Author: quinnocent (original author: mort)
	Version: 1.0
]]--


local defaultConfig = {
	modEnabled = true,
	vanillaEnabled = true,
	logarithmEnabled = true,
	creatureEnabled = true,
	difficulty = 1,
	customCutoff = 300,
	customLogbase = 1.71,
	creatureStats = 55,
	vanillaCap = 1,
	logLevel = "NONE",
}
local config = mwse.loadConfig("SHBarter", defaultConfig)


local logger = require("logging.logger")
local log = logger.new{
    name = "SHBarter",
    logLevel = config.logLevel,
}


local function SHBarterAdjust(e)
	if not config.modEnabled or e.buying then
		return
	end
	
	local basePricePer = e.basePrice / e.count
	local vanillaRatio = 1
	local creatureDetected

	log:debug("    Start - Base: %s - Count: %s - Diff: %s - Van: %s - Log: %s", basePricePer, e.count, config.difficulty, config.vanillaEnabled, config.logarithmEnabled)

	local playerMercantile = tes3.mobilePlayer.mercantile.current
	local playerPersonality = tes3.mobilePlayer.personality.current
	local playerLuck = tes3.mobilePlayer.luck.current

	local npc = tes3ui.getServiceActor()
	local npcMercantile = npc:getSkillValue(tes3.skill.mercantile)
	local npcPersonality = npc.personality.current
	local npcLuck = npc.luck.current
	local disposition = npc.object.disposition

	-- Checking to see if merchant is a creature.  Assigning stats using creatureStats if they are
	if npcMercantile == nil or disposition == nil then
		creatureDetected = true
		npcMercantile = config.creatureStats
		npcPersonality = config.creatureStats
		npcLuck = config.creatureStats
		disposition = 50
		log:debug(" Creature - Detected - creatureStats: %s",config.creatureStats)
	end

	log:debug("   Player - Merc: %s - Pers: %s - Luck: %s", playerMercantile, playerPersonality, playerLuck)
	log:debug("      NPC - Merc: %s - Pers: %s - Luck: %s - Disp: %s", npcMercantile, npcPersonality, npcLuck, disposition)

	-- Declared using Standard difficulty, as a safe fallback if the user inputs invalid custom values
	local cutoff = 300
	local logbase = 1.71
	if config.difficulty == 2 then
		cutoff = 250
		logbase = 1.54
	end
	if config.difficulty == 3 then
		cutoff = 200
		logbase = 1.31
	end
	-- Avoiding custom inputs that will cause an error in the formula
	if config.difficulty == 4 and config.customCutoff >= 1 and config.customLogbase >= 1.01 then
		cutoff = config.customCutoff
		logbase = config.customLogbase
		log:debug("   Custom - Cutoff: %s - Logbase: %s", cutoff, logbase)
	end

	if config.vanillaEnabled then
		-- This is the patched MCP version of the vanilla sales price formula
		vanillaRatio = 0.34375 + (math.min(disposition,100) + math.min(playerMercantile,100) - math.min(npcMercantile,100) + math.min(playerLuck,100)/10 - math.min(npcLuck,100)/10 + math.min(playerPersonality,50)/5 - math.min(npcPersonality,50)/5) * 0.003125
		log:debug("  Vanilla - vanillaRatio: %s", vanillaRatio)
		
		if vanillaRatio > config.vanillaCap then
			vanillaRatio = config.vanillaCap
			log:debug("  Van Cap - vanillaRatio set to vanillaCap: %s", config.vanillaCap)
		end
		
		if creatureDetected and not config.creatureEnabled then
			vanillaRatio = 1
			log:debug(" Creature - creatureEnabled false - vanillaRatio set to 1")
		end
	end

	if config.logarithmEnabled and basePricePer > cutoff then
		-- Any amount above the cutoff value is divided by the difference between the
		-- logarithm (using the specified base) of the total price and the logarithm of the
		-- excess amount minus 1.  This means the divisor of the excess amount starts at 1,
		-- allowing for a gradual dropoff after the cutoff value.
		basePricePer = cutoff + (basePricePer - cutoff) / (math.log(basePricePer) / math.log(logbase) - (math.log(cutoff) / math.log(logbase) - 1))
		log:debug("Logarithm - basePricePer: %s", basePricePer)
	end

	e.price = math.floor(basePricePer * vanillaRatio * e.count)
	log:debug("    Final - e.price: %s", e.price)
end


local function initialize()
	if (mwse.buildDate == nil or mwse.buildDate < 20190715) then
		modConfig.hidden = true
		tes3.messageBox("Smarter Harder Barter requires a newer version of MWSE. Please run MWSE-Update.exe.", mwse.buildDate)
		return
	end
	event.register("calcBarterPrice", SHBarterAdjust)
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

local function registerModConfig()
    local template = mwse.mcm.createTemplate("Smarter Harder Barter")
	template:saveOnClose("SHBarter", config)

    local page = template:createSideBarPage()
    local categoryMain = page:createCategory("Settings")

	page.sidebar:createInfo{
		text = "This mod adjusts prices downward, leaving items with a base price below the cutoff value alone while gradually reducing the value of items above that.  The function is logarithmic, so the largest decreases will be seen by the most expensive items.  In all cases, normal vanilla price calculations (the usual price adjustments caused by disposition, mercantile, etc.) still apply.  The goal is to leave mundane trading alone while drastically reducing the economy-breaking potential of the most expensive items.\n\n" ..
		"This mod uses the fixed price formula implemented by the Morrowind Code Patch, listed as 'Mercantile fix' under 'Bug fixes'.  It is highly recommended that you enable that patch in MCP if you use this mod, to avoid serious imbalances between purchase and sales prices.\n\n" ..
		"Mouse over individual settings for more information.  Additional details can be found on the mod page or in the readme file."
	}

	categoryMain:createYesNoButton{
		label = "Enable Smarter Harder Barter",
		description = "Toggles all functions on or off.\n\n" ..
		"Default: Yes",
		variable = createTableVar("modEnabled"),
		defaultSetting = true
	}

	categoryMain:createYesNoButton{
		label = "Enable Vanilla Price Calculations",
		description = "Toggles vanilla price calculations (the normal price adjustments caused by disposition, mercantile, etc.).\n\n" ..
		"This mod uses the fixed price formula implemented by the Morrowind Code Patch, listed as 'Mercantile fix' under 'Bug fixes'.  It is highly recommended that you enable that patch in MCP if you use this mod, to avoid serious imbalances between purchase and sales prices.\n\n"..
		"This setting is designed to be used alongside the Logarithmic Function setting, and it's recommended that you keep both enabled.\n\n"..
		"Default: Yes",
		variable = createTableVar("vanillaEnabled"),
		defaultSetting = true
	}

	categoryMain:createYesNoButton{
		label = "Enable Logarthmic Function",
		description = "Toggles the logarithmic rolloff function which gradually decreases the sale value of items above the cutoff value, with very large price decreases for the most expensive items.\n\n" ..
		"This setting is designed to be used alongside the Vanilla Price Calculation setting, and it's recommended that you keep both enabled.\n\n"..
		"Default: Yes",
		variable = createTableVar("logarithmEnabled"),
		defaultSetting = true
	}

	categoryMain:createYesNoButton{
		label = "Enable Harder Creature Barter",
		description = "This setting limits the utility of creature merchants like the Creeper (the scamp merchant) and mudcrab merchant.  Creature merchants have no mercantile skill, which causes them to bypass price calculations and buy items for their full base price.  For those who wish to use these NPC's, this can be economy-breaking.\n\n" ..
		"Enabling this setting will make the mod detect creature merchants and assign them stats for the purpose of the vanilla price formula.  To balance their high gold total and broad buy list, they have become shrewd negotiators with formidable stats.  Compared to regular merchants, their stats are tuned to pay out roughly 20% less to player characters with middling stats and 30% less to characters with very high stats.  This should leave them with some utility, without them necessarily being the best choice for selling all items.\n\n"..
		"If this setting is enabled, creature merchants are treated as having 50 disposition toward you, with their relevant bargaining stats assumed to be 55.  This number can be changed via the Creature Merchant Stats option below.\n\n"..
		"Even if this option is disabled, the logarithmic price reduction for expensive items still applies.\n\n"..
		"Default: Yes",
		variable = createTableVar("creatureEnabled"),
		defaultSetting = true
	}

	categoryMain:createDropdown{
		label = "Difficulty:",
		description = "Standard Difficulty: The cutoff value is 300, with a log base of 1.71.  Sharp decrease in item value above 1,000 septims.  Items above 5,000 septims are worth 1/5th to 1/10th of their original value.\n\n" ..
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
		label = "Custom Cutoff Value:",
		description = "Items with a base price below this value will be unaffected by the logarithmic function, and prices will gradually roll off beyond it.\n\n" ..
		"This value must be 1 or greater, or the mod will default to Standard difficulty when Custom is selected.\n\n" ..
		"You must set the Difficulty to '4. Custom' for the Custom Cutoff Value and Custom Log Base to have any effect.",
		variable = mwse.mcm.createTableVariable{
			id = "customCutoff",
			table = config,
			converter = tonumber
		},
		numbersOnly = true
	}

	categoryMain:createTextField{
		label = "Custom Log Base:",
		description = "The log base controls the rate of price falloff past the cutoff value.  Lower values will cause prices to decrease faster, and higher values will be slower.  It is recommended that you start with one of the values from the preset difficulties and tweak from there.\n\n" ..
		"This value must be 1.01 or greater, or the mod will default to Standard difficulty when Custom is selected.\n\n" ..
		"You must set the Difficulty to '4. Custom' for the Custom Cutoff Value and Custom Log Base to have any effect.",
		variable = mwse.mcm.createTableVariable{
			id = "customLogbase",
			table = config,
			converter = tonumber
		},
		numbersOnly = true
	}

	categoryMain:createTextField{
		label = "Creature Merchant Stats:",
		description = "This is the value used to override creature merchant stats, if the Harder Creature Barter setting above is enabled.  Please see that setting for more details.\n\n" ..
		"Default: 55",
		variable = mwse.mcm.createTableVariable{
			id = "creatureStats",
			table = config,
			converter = tonumber
		},
		numbersOnly = true
	}


	--[[
	I disabled this setting because it started to seem like a solution in search of a problem.
	This setting will likely only really be of use fairly late in the game, and by that time,
	reducing sales prices by a few percent isn't likely to make a material difference.  It also
	possibly goes against the mod's philosophy of using a light touch and only reigning in
	large imbalances.

	The setting is fully functional as is, if you wish to uncomment this setting field and use
	it.  I can enable it again if people end up wanting it.
	]]--

	--[[
	categoryMain:createTextField{
		label = "Vanilla Price Cap:",
		description = "This puts a hard cap on the sales prices that result from the vanilla sales price formula.  This has no effect on the reduction from the logarithmic function, which is applied separately.\n\n" ..
		"This setting can help limit lategame scenarios where near max barter stats result in very high sales prices when dealing with less skilled merchants.\n\n" ..
		"This cap is expressed as a proportion of the item's base price.  For example, if you set it to 0.95, an item with a base price of 1,000 would not have a price higher than 950 septims after the vanilla price calculation.\n\n" ..
		"Default: 1.0",
		variable = mwse.mcm.createTableVariable{
			id = "vanillaCap",
			table = config,
			converter = tonumber
		},
		numbersOnly = true
	}
	]]--

	categoryMain:createDropdown{
		label = "Logging Level:",
		description = "This setting controls the level of logging for the mod.\n\n"..
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

	mwse.mcm.register(template)
end
event.register("modConfigReady", registerModConfig)
								

