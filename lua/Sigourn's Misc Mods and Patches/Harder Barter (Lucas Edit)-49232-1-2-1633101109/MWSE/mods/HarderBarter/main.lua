--[[
	Mod Initialization: Harder Barter
	Author: mort
	Version 1.2
]]--

-- The default configuration values.
local defaultConfig = {
	modEnabled = true,
	--adjustmentFactor = 0
}

-- Load our config file, and fill in default values for missing elements.
local config = mwse.loadConfig("mortBarter")
if (config == nil) then
	config = defaultConfig
else
	for k, v in pairs(defaultConfig) do
		if (config[k] == nil) then
			config[k] = v
		end
	end
end

local function mort_barterAdjust(e)
	if ( config.modEnabled == true ) then
		if e.buying == false then
			local basePricePer = e.basePrice / e.count
			if basePricePer > 10 then
				-- The final price will be the same price as it usually would, plus 6 gold to compensate
				-- for the math.log function making 11 gold items be worth 6 gold LESS than 10 gold items.
				e.price = e.price / math.log(basePricePer) + 6
			end
			-- Reduces one gold from the final value to account for players potential selling one item at a time
			-- to get a higher sell value over selling the items in a stack
			e.price = e.price - 1
		end
	end
end

local function initialize()
	if (mwse.buildDate == nil or mwse.buildDate < 20190715) then
		modConfig.hidden = true
		tes3.messageBox("Harder Barter requires a newer version of MWSE. Please run MWSE-Update.exe.", mwse.buildDate)
		return
	end
	event.register("calcBarterPrice", mort_barterAdjust)
	print("[Harder Barter Initialized]")
end

event.register("initialized", initialize)

---
--- Mod Config
---

local function createtableVar(id)
	return mwse.mcm.createTableVariable{
		id = id,
		table = config
	}  
end

local function registerModConfig()
    local template = mwse.mcm.createTemplate("Harder Barter")
	template:saveOnClose("mortBarter", config)
	
    local page = template:createPage()
    local categoryMain = page:createCategory("Settings")
	categoryMain:createYesNoButton{ label = "Enable Harder Barter",
								variable = createtableVar("modEnabled"),
								defaultSetting = true}
								

	-- categoryMain:createSlider{ label = "Difficulty adjustment (-1 easy, 0 standard, 1 hard)",
						-- variable = createtableVar("adjustmentFactor"),
						-- max = 1,
						-- min = -1,
						-- jump = 1,
						-- defaultSetting = 0}

	mwse.mcm.register(template)
end
event.register("modConfigReady", registerModConfig)