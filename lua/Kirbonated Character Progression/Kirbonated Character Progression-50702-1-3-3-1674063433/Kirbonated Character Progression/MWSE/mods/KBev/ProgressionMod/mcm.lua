local common = require("KBev.ProgressionMod.common")
local confPath = "KBev_ProgressionMod"
local config = mwse.loadConfig(confPath)
local defaultConfig = mwse.loadConfig("KCP Presets\\default settings")

if not config then config = defaultConfig end

local function updateConfig(newSettings)
	for k, v in pairs(newSettings) do
		config[k] = v
	end
end

--Backwards Compatibility with Old Configs
local function verifySettingsIntegrity()
	for setting, value in pairs(defaultConfig) do
		if config[setting] == nil then
			config[setting] = value
		end
	end
end

local function registerModConfig(e)
	local presetOptions = {}
	for file in lfs.dir("Data Files\\MWSE\\config\\KCP Presets\\") do
		common.dbg("Found Preset: " .. file)
		local path = "config\\KCP Presets\\" .. file
		local content = json.loadfile(path)
		if content then
			common.dbg("preset registered: " .. content.presetName)
			table.insert(presetOptions, {label = content.presetName, value = path})
		end
	end
	common.dbg("Registering MCM Menu")
    local menu = mwse.mcm.createTemplate{name = common.modName}
	menu:saveOnClose(confPath, config)
    
	--main settings)
	local xp = menu:createSideBarPage("XP")
	local xpFeatures = xp:createCategory("Features")
	local xpRewards = xp:createCategory("XP Reward Values")
	local xpSkill = xp:createCategory("Skill Exercise XP")
	local xpLevel = xp:createCategory("Level Up Requirement")
	local leveling = menu:createSideBarPage("Leveling")
	local levelFeatures = leveling:createCategory("Features")
	local pointAlloc = leveling:createCategory("Point Allocation")
	local cgen = menu:createSideBarPage("Character Creation")
	local presets = menu:createSideBarPage("Presets")
	
	xpFeatures:createOnOffButton{
		label = "Enable XP?",
		description = "(Default ON) if turned off, this reverts the game to using the standard skill increase method of gaining xp, and disables skill point gain (you still gain attribute points/perk points)",
		variable = mwse.mcm.createTableVariable{
			id = "xpEnabled",
			table = config,
			defaultSetting = true
		}
	}
	xpFeatures:createTextField{
		label = "Level Cap",
		description = "(Default 80)  Allows you to set a hard level cap.",
		numbersOnly = true,
		variable = mwse.mcm.createTableVariable{
			id = "xpLvlCap",
			table = config,
			defaultSetting = 80
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. "set to " .. config[self.variable.id])
		end
	
	}
	xpFeatures:createOnOffButton{
		label = "Enable XP for discovering new locations?",
		description = "(Default ON). Awards XP for visiting a named Cell or Region for the first time",
		variable = mwse.mcm.createTableVariable{
			id = "cellXPEnabled",
			table = config,
			defaultSetting = true
		}
	}
	xpFeatures:createOnOffButton{
		label = "Enable XP for defeating boss monsters?",
		description = "(Default ON) When turned on, defeating certain extra powerful creatures, such as Ash Vampires, The Imperfect, the Udyrfrykte, Dagoth Ur, Vivec, and Almalexia, will award the player a large amount of XP.",
		variable = mwse.mcm.createTableVariable{
			id = "bossXPEnabled",
			table = config,
			defaultSetting = true
		}
	}
	xpFeatures:createOnOffButton{
		label = "Enable XP for Defeating Fargoth",
		description = "(Default ON) When turned on, defeating a owner of a certain legendary ring will award the player a large amount of XP.",
		variable = mwse.mcm.createTableVariable{
			id = "fargothXPEnabled",
			table = config,
			defaultSetting = true
		}
	}
	xpFeatures:createOnOffButton{
		label = "Allow Skill Exercise?",
		description = "(Default OFF) Allows Skills to be raised via exercise (The Vanilla method of skill leveling)",
		variable = mwse.mcm.createTableVariable{
			id = "allowExercise",
			table = config,
			defaultSetting = false
		}
	}
	xpFeatures:createOnOffButton{
		label = "Enable XP from Skill Exercise?",
		description = "(Default OFF) When Enabled, Exercising a Skill grants you XP",
		variable = mwse.mcm.createTableVariable{
			id = "exerciseXPEnabled",
			table = config,
			defaultSetting = false
		}
	}
	xpFeatures:createOnOffButton{
		label = "Block natural Skill Raise?",
		description = "(Default OFF) When Enabled, Skills will still gain exercise progress, but reaching 100 will not increase your skill. Can be slightly jank",
		variable = mwse.mcm.createTableVariable{
			id = "blockSkillRaise",
			table = config,
			defaultSetting = false
		}
	}
	xpFeatures:createOnOffButton{
		label = "Enable XP from Skill Books?",
		description = "(Default OFF) When Enabled, Reading Skill Books grants you XP",
		variable = mwse.mcm.createTableVariable{
			id = "skillBookXPEnabled",
			table = config,
			defaultSetting = false
		}
	}
	xpFeatures:createOnOffButton{
		label = "Enable XP from Trainers?",
		description = "(Default OFF) When Enabled, Training a skill with a trainer grants you XP",
		variable = mwse.mcm.createTableVariable{
			id = "trainerXPEnabled",
			table = config,
			defaultSetting = false
		}
	}
	xpRewards:createTextField{
		label = "Main Quest XP",
		description = "(Default 150) Controls the amount of XP given for completing Main Quests",
		numbersOnly = true,
		variable = mwse.mcm.createTableVariable{
			id = "mainQuestXP",
			table = config,
			defaultSetting = 150
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. "set to " .. config[self.variable.id])
		end
	
	}
	xpRewards:createTextField{
		label = "Guild Quest XP",
		description = "(Default 100) Controls the amount of XP given for completing Guild Quests",
		numbersOnly = true,
		variable = mwse.mcm.createTableVariable{
			id = "guildQuestXP",
			table = config,
			defaultSetting = 100
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. "set to " .. config[self.variable.id])
		end
	
	}
	xpRewards:createTextField{
		label = "Side Quest XP",
		description = "(Default 50) Controls the amount of XP given for completing Side Quests",
		numbersOnly = true,
		variable = mwse.mcm.createTableVariable{
			id = "sideQuestXP",
			table = config,
			defaultSetting = 50
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. "set to " .. config[self.variable.id])
		end
	
	}
	xpRewards:createTextField{
		label = "Misc Task XP",
		description = "(Default 10) Controls the amount of XP given for completing Tasks",
		numbersOnly = true,
		variable = mwse.mcm.createTableVariable{
			id = "taskQuestXP",
			table = config,
			defaultSetting = 10
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. "set to " .. config[self.variable.id])
		end
	
	}
	xpRewards:createTextField{
		label = "Location Discovery XP",
		description = "(Default 20)controls the amount of XP granted for discovering new locations",
		numbersOnly = true,
		variable = mwse.mcm.createTableVariable{
			id = "cellXP",
			table = config,
			defaultSetting = 20
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. "set to " .. config[self.variable.id])
		end
	
	}
	xpRewards:createTextField{
		label = "Boss Monster XP",
		description = "(Default 120)controls the amount of XP granted for defeating Boss Monsters",
		numbersOnly = true,
		variable = mwse.mcm.createTableVariable{
			id = "bossXP",
			table = config,
			defaultSetting = 120
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. "set to " .. config[self.variable.id])
		end
	
	}
	xpRewards:createTextField{
		label = "Fargoth XP",
		description = "(Default 200)controls the amount of XP granted for defeating Fargoth",
		numbersOnly = true,
		variable = mwse.mcm.createTableVariable{
			id = "fargothXP",
			table = config,
			defaultSetting = 200
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. "set to " .. config[self.variable.id])
		end
	
	}
	xpRewards:createTextField{
		label = "Skill Book XP",
		description = "(Default 30)controls the amount of XP granted for reading Skill books",
		numbersOnly = true,
		variable = mwse.mcm.createTableVariable{
			id = "bkSklXP",
			table = config,
			defaultSetting = 30
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. "set to " .. config[self.variable.id])
		end
	
	}
	xpRewards:createTextField{
		label = "Trainer XP",
		description = "(Default 30)controls the amount of XP granted for visiting trainers",
		numbersOnly = true,
		variable = mwse.mcm.createTableVariable{
			id = "trnSklXP",
			table = config,
			defaultSetting = 30
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. "set to " .. config[self.variable.id])
		end
	
	}
	xpSkill:createTextField{
		label = "Major Skill XP",
		description = "(Default 30)controls the amount of XP granted for exercising a major skill",
		numbersOnly = true,
		variable = mwse.mcm.createTableVariable{
			id = "mjrSklXP",
			table = config,
			defaultSetting = 30
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. "set to " .. config[self.variable.id])
		end
	
	}
	xpSkill:createTextField{
		label = "Minor Skill XP",
		description = "(Default 30)controls the amount of XP granted for exercising a minor skill",
		numbersOnly = true,
		variable = mwse.mcm.createTableVariable{
			id = "mnrSklXP",
			table = config,
			defaultSetting = 30
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. "set to " .. config[self.variable.id])
		end
	
	}
	xpSkill:createTextField{
		label = "Misc Skill XP",
		description = "(Default 0)controls the amount of XP granted for exercising a misc skill",
		numbersOnly = true,
		variable = mwse.mcm.createTableVariable{
			id = "mscSklXP",
			table = config,
			defaultSetting = 0
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. "set to " .. config[self.variable.id])
		end
	
	}
	xpLevel:createTextField{
		label = "Base XP to level up",
		description = "(Default 50) Determines the BaseXP component of the Levelup requirement.\nXP to Level up = (BaseXP + (XPLevelMult * Level))",
		numbersOnly = true,
		variable = mwse.mcm.createTableVariable{
			id = "xpLvlBase",
			table = config,
			defaultSetting = 50
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. "set to " .. config[self.variable.id])
		end
	
	}
	xpLevel:createTextField {
		label = "XP Level Mult",
		description = "(Default 150) Determines the XPLevelMult component of the Levelup requirement.\nXP to Level up = (BaseXP + (XPLevelMult * Level))",
		numbersOnly = true,
		variable = mwse.mcm:createTableVariable {
			id = "xpLvlMult",
			table = config,
			defaultSetting = 150.0
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. "set to " .. config[self.variable.id])
		end
	}
	
	
	levelFeatures:createOnOffButton{
		label = "Enable Perks?",
		description = "(Default ON) Enables or Disables the Perk system",
		variable = mwse.mcm.createTableVariable{
			id = "prkEnabled",
			table = config,
			defaultSetting = true
		},
		callback = function() event.trigger("KCP:updatePerkState") end,
	}
	levelFeatures:createOnOffButton{
		label = "Require Rest to Level Up?",
		description = "(Default ON) When disabled, allows levelups to occur outside of resting, as long as the player is not in combat.",
		variable = mwse.mcm.createTableVariable{
			id = "lvlRst",
			table = config,
			defaultSetting = true
		},
		callback = function() event.trigger("KCP:checkForLevelUP") end
	}

	pointAlloc:createTextField {
		label = "Perk Points per Interval",
		description = "(Default 1) Determines the amount of perk points gained per levelup interval",
		numbersOnly = true,
		variable = mwse.mcm:createTableVariable {
			id = "prkLvlMult",
			table = config,
			defaultSetting = 1
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. "set to " .. config[self.variable.id])
		end
	}
	pointAlloc:createTextField {
		label = "Perk Point Interval",
		description = "(Default 2) The Frequency by which the player gains perk points.\n1 = every level\n2 = every 2 levels\netc.",
		numbersOnly = true,
		variable = mwse.mcm:createTableVariable {
			id = "prkLvlInterval",
			table = config,
			defaultSetting = 2
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. "set to " .. config[self.variable.id])
		end
	}
	pointAlloc:createTextField {
		label = "Attribute Points per Interval",
		description = "(Default 10) Determines the amount of Attribute points gained per levelup interval",
		numbersOnly = true,
		variable = mwse.mcm:createTableVariable {
			id = "atrLvlMult",
			table = config,
			defaultSetting = 10
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. "set to " .. config[self.variable.id])
		end
	}
	pointAlloc:createTextField {
		label = "Attribute Point Interval",
		description = "(Default 1) The Frequency by which the player gains Attribute points.\n1 = every level\n2 = every 2 levels\netc.",
		numbersOnly = true,
		variable = mwse.mcm:createTableVariable {
			id = "atrLvlInterval",
			table = config,
			defaultSetting = 1
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. "set to " .. config[self.variable.id])
		end
	}
	pointAlloc:createTextField{
		label = "Max Attribute Point Increase",
		description = "(Default 5) The maximum amount of points you can allocate to a single attribute per level",
		numbersOnly = true,
		variable = mwse.mcm:createTableVariable {
			id = "atrIncMax",
			table = config,
			defaultSetting = 5
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. "set to " .. config[self.variable.id])
		end
	
	}
	pointAlloc:createTextField {
		label = "Attribute Point Cap",
		description = "(Default 200) The maximum base value that the player can raise an Attribute to. Requires \"Uncapped Attributes\" option in MCP",
		numbersOnly = true,
		variable = mwse.mcm:createTableVariable {
			id = "atrLvlCap",
			table = config,
			defaultSetting = 200
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. "set to " .. config[self.variable.id])
		end
	}
	pointAlloc:createTextField {
		label = "Major Skill Points per Interval",
		description = "(Default 10) Determines the amount of Major Skill points gained per levelup interval",
		numbersOnly = true,
		variable = mwse.mcm:createTableVariable {
			id = "mjrLvlMult",
			table = config,
			defaultSetting = 10
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. "set to " .. config[self.variable.id])
		end
	}
	pointAlloc:createTextField {
		label = "Major Skill Point Interval",
		description = "(Default 1) The Frequency by which the player gains Major Skill points.\n1 = every level\n2 = every 2 levels\netc.",
		numbersOnly = true,
		variable = mwse.mcm:createTableVariable {
			id = "mjrLvlInterval",
			table = config,
			defaultSetting = 1
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. "set to " .. config[self.variable.id])
		end
	}
	pointAlloc:createTextField{
		label = "Max Major Skill Point Increase",
		description = "(Default 15) The maximum amount of points you can allocate to a single Major Skill per level",
		numbersOnly = true,
		variable = mwse.mcm:createTableVariable {
			id = "mjrIncMax",
			table = config,
			defaultSetting = 15
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. "set to " .. config[self.variable.id])
		end
	
	}
	pointAlloc:createTextField {
		label = "Major Skill Cap",
		description = "(Default 200) The maximum base value that the player can raise a Major Skill to. Requires \"Uncapped Skills\" option in MCP",
		numbersOnly = true,
		variable = mwse.mcm:createTableVariable {
			id = "mjrLvlCap",
			table = config,
			defaultSetting = 200
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. "set to " .. config[self.variable.id])
		end
	}
	pointAlloc:createTextField {
		label = "Minor Skill Points per Interval",
		description = "(Default 5) Determines the amount of Minor Skill points gained per levelup interval",
		numbersOnly = true,
		variable = mwse.mcm:createTableVariable {
			id = "mnrLvlMult",
			table = config,
			defaultSetting = 5
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. "set to " .. config[self.variable.id])
		end
	}
	pointAlloc:createTextField {
		label = "Minor Skill Point Interval",
		description = "(Default 1) The Frequency by which the player gains Minor Skill points.\n1 = every level\n2 = every 2 levels\netc.",
		numbersOnly = true,
		variable = mwse.mcm:createTableVariable {
			id = "mnrLvlInterval",
			table = config,
			defaultSetting = 1
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. "set to " .. config[self.variable.id])
		end
	}
	pointAlloc:createTextField{
		label = "Max Minor Skill Point Increase",
		description = "(Default 10) The maximum amount of points you can allocate to a single Minor Skill per level",
		numbersOnly = true,
		variable = mwse.mcm:createTableVariable {
			id = "mnrIncMax",
			table = config,
			defaultSetting = 10
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. "set to " .. config[self.variable.id])
		end
	
	}
	pointAlloc:createTextField {
		label = "Minor Skill Cap",
		description = "(Default 200) The maximum base value that the player can raise a Minor Skill to. Requires \"Uncapped Skills\" option in MCP",
		numbersOnly = true,
		variable = mwse.mcm:createTableVariable {
			id = "mnrLvlCap",
			table = config,
			defaultSetting = 200
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. "set to " .. config[self.variable.id])
		end
	}
	pointAlloc:createTextField {
		label = "Misc Skill Points per Interval",
		description = "(Default 5) Determines the amount of Misc Skill points gained per levelup interval",
		numbersOnly = true,
		variable = mwse.mcm:createTableVariable {
			id = "mscLvlMult",
			table = config,
			defaultSetting = 5
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. "set to " .. config[self.variable.id])
		end
	}
	pointAlloc:createTextField {
		label = "Misc Skill Point Interval",
		description = "(Default 2) The Frequency by which the player gains Misc Skill points.\n1 = every level\n2 = every 2 levels\netc.",
		numbersOnly = true,
		variable = mwse.mcm:createTableVariable {
			id = "mscLvlInterval",
			table = config,
			defaultSetting = 2
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. "set to " .. config[self.variable.id])
		end
	}
	pointAlloc:createTextField{
		label = "Max Misc Skill Point Increase",
		description = "(Default 5) The maximum amount of points you can allocate to a single Misc Skill per level",
		numbersOnly = true,
		variable = mwse.mcm:createTableVariable {
			id = "mscIncMax",
			table = config,
			defaultSetting = 5
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. "set to " .. config[self.variable.id])
		end
	
	}
	pointAlloc:createTextField {
		label = "Misc Skill Cap",
		description = "(Default 200) The maximum base value that the player can raise a Misc Skill to. Requires \"Uncapped Skills\" option in MCP",
		numbersOnly = true,
		variable = mwse.mcm:createTableVariable {
			id = "mscLvlCap",
			table = config,
			defaultSetting = 200
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. "set to " .. config[self.variable.id])
		end
	}
	
	cgen:createOnOffButton{
		label = "Enable Point Buy?",
		description = "(Default ON) When Enabled, allows you to customize your starting attribute values when creating a new character.",
		variable = mwse.mcm.createTableVariable{
			id = "cgenEnabled",
			table = config,
			defaultSetting = true
		},
	}
	
	cgen:createTextField {
		label = "Point Buy Budget",
		description = "(Default 70) How many attribute points you can allocate at character creation",
		numbersOnly = true,
		variable = mwse.mcm:createTableVariable {
			id = "cgenBudget",
			table = config,
			defaultSetting = 70
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. "set to " .. config[self.variable.id])
		end
	}
	
	cgen:createTextField {
		label = "Point Buy Attribute Base",
		description = "(Default 30) The Base value of all attributes in character creation. Stats cannot be lowered beneath this value in character creation",
		numbersOnly = true,
		variable = mwse.mcm:createTableVariable {
			id = "cgenBase",
			table = config,
			defaultSetting = 30
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. "set to " .. config[self.variable.id])
		end
	}
	cgen:createTextField {
		label = "Point Buy Attribute Max",
		description = "(Default 50) The Maximum value you can set an attribute to in character creation. This does not include the bonuses from your class",
		numbersOnly = true,
		variable = mwse.mcm:createTableVariable {
			id = "cgenMax",
			table = config,
			defaultSetting = 50
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. "set to " .. config[self.variable.id])
		end
	}
	presets:createDropdown{
		label = "Load Preset",
		description = "Loads MCM settings from a json file",
		options = presetOptions,
		variable = mwse.mcm:createVariable{
			get = (
				function(self)
					return "Choose a Preset"
				end
			),
			set = (function(self, newVal)
				common.dbg("Previous Preset: " .. config.presetName)
				updateConfig(json.loadfile(newVal))
				common.dbg("Loaded Preset: " .. config.presetName)
				tes3.messageBox("Preset Loaded: " .. config.presetName)
				verifySettingsIntegrity()
			end),
		},
	}
	presets:createTextField {
		label = "Save Preset",
		description = "Save Current MCM settings to a json file",
		variable = mwse.mcm:createVariable{
			get = (
				function(self)
					return "Name your Preset"
				end
			),
			set = (function(self, newVal)
				if (newVal == "default settings") or (newVal == "5e Feats") then
					tes3.messageBox("Cannot Overwrite Base Presets")
					return
				end
				config.presetName = newVal
				common.dbg("Saving Preset: " .. newVal)
				json.savefile("config\\KCP Presets\\".. newVal, config)
				tes3.messageBox("Preset Saved: " .. newVal)
			end),
		
		},
	
	}
	mwse.mcm.register(menu)
	common.dbg("Created MCM Menu")
end
common.dbg("registering for mod config")
event.register("modConfigReady", registerModConfig)
common.dbg("registered for mod config")
return config