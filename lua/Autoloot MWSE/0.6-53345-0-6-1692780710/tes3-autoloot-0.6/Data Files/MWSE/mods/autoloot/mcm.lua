local logger = require("logging.logger")
local log = logger.getLogger("Autoloot")
local config = require("autoloot.config")


local function getCells(self)
    local temp = {}
	for _, cell in ipairs(tes3.dataHandler.nonDynamicData.cells) do
		if not temp[cell.id] then
			temp[cell.id] = true
		end
	end

    local list = {}
    for id in pairs(temp) do
        list[#list+1] = id
    end
    
    table.sort(list)
    return list
end

local function changeTimerState()
	if autoLootTimer and autoLootTimer.state == timer.active and (not config.enableTimer or not config.enableMod) then
		log:debug(tostring('changeTimerState cancel config.enableTimer "%s" config.timer "%s" config.enableMod "%s"'):format(config.enableTimer, config.timer, config.enableMod))
		autoLootTimer:cancel()
	end
	
	if config.enableMod and config.enableTimer then
		log:debug(tostring('changeTimerState start config.enableTimer "%s" config.timer "%s"'):format(config.enableTimer, config.timer))
		startAutoLootTimer()
	end
end

----------------------
-- Template --
----------------------
local template = mwse.mcm.createTemplate{name = "Autoloot"}

local preferences = template:createSideBarPage{label = "Settings" }

local settings = preferences:createCategory{label = "Settings"}
settings:createOnOffButton{
    label = "Enable mod",
    variable = mwse.mcm:createTableVariable{
        id = "enableMod",
        table = config,
		restartRequired = false,
    },
    callback = changeTimerState
}
settings:createDropdown{
    label = "Logging Level",
    description = "Set the log level.",
    options = {
        { label = "TRACE", value = "TRACE"},
        { label = "DEBUG", value = "DEBUG"},
        { label = "INFO", value = "INFO"},
        -- { label = "WARN", value = "WARN"},
        -- { label = "ERROR", value = "ERROR"},
        { label = "NONE", value = "NONE"},
    },
    variable = mwse.mcm.createTableVariable{
		id = "logLevel",
		table = config,
		restartRequired = false,
	},
    callback = function(self)
        log:setLogLevel(self.variable.value)
    end
}
settings:createOnOffButton{
    label = "Loot notification",
    variable = mwse.mcm:createTableVariable{
        id = "lootNotification",
        table = config,
		restartRequired = false,
    }
}
settings:createOnOffButton{
    label = "Loot containers",
    description = "Loot any containers like chests, sacks, etc.",
    variable = mwse.mcm:createTableVariable{
        id = "lootContainers",
        table = config.containers,
		restartRequired = false,
    },
}
settings:createOnOffButton{
    label = "Loot bodies",
    description = "Loot dead NPC's and creatures",
	variable = mwse.mcm:createTableVariable{
        id = "lootBodies",
        table = config.npcs,
		restartRequired = false,
    },
}
settings:createOnOffButton{
    label = "Loot items",
    description = "Loot dropped in world items",
    variable = mwse.mcm:createTableVariable{
        id = "lootItems",
        table = config,
		restartRequired = false,
    },
}
settings:createKeyBinder{
    label = "Assign manual loot keybind",
    allowCombinations = true,
    variable = mwse.mcm.createTableVariable{
        id = "hotkey",
        table = config,
        defaultSetting = {
            keyCode = tes3.scanCode.h,
            isShiftDown = false,
            isAltDown = false,
            isControlDown = false,
        },
		restartRequired = true,
    }
}
settings:createSlider{
	label = "Weigth/Value ratio",
	min = 0,
	max = 1000,
	step = 1,
	jump = 10,
	variable = mwse.mcm.createTableVariable({
		id = "weigthValueRatio",
		table = config,
		restartRequired = false,
	})
}
settings:createOnOffButton{
    label = "Check distance",
    variable = mwse.mcm:createTableVariable{
        id = "checkDistance",
        table = config,
		restartRequired = false,
    },
}
settings:createSlider{
	label = "Distance",
	min = 0,
	max = 9999,
	step = 1,
	jump = 10,
	variable = mwse.mcm.createTableVariable({
		id = "distance",
		table = config,
		restartRequired = false,
	}),
}
settings:createOnOffButton{
    label = "Enable timer",
    variable = mwse.mcm:createTableVariable{
        id = "enableTimer",
        table = config,
		restartRequired = false,
    },
    callback = changeTimerState
}
settings:createSlider{
	label = "Timer (ms)",
	min = 100,
	max = 60000,
	step = 100,
	jump = 1000,
	variable = mwse.mcm.createTableVariable({
		id = "timer",
		table = config,
		restartRequired = false,
	}),
    callback = changeTimerState
}
settings:createOnOffButton{
    label = "Ignore player encumberance",
    variable = mwse.mcm:createTableVariable{
        id = "ignoreEncumberance",
        table = config,
		restartRequired = false,
    },
}


		
local steal = preferences:createCategory{label = "Steal"}
local enableStealButton
local enableHiddenStealButton

enableStealButton = steal:createOnOffButton{
	label = "Enable stealing",
	description = "If player is in line of sight of any NPC - crime will be triggered with penalty of total items value stolen. If not seen by NPCs crime will not occur. Stolen item is still marked as stolen.\nUse only one of \"Enable stealing\" or \"Only steal when hidden\"",
	variable = mwse.mcm:createTableVariable{
		id = "enableSteal",
		table = config,
		restartRequired = false,
	},
}
enableHiddenStealButton = steal:createOnOffButton{
	label = "Only steal when hidden",
	description = "Steal only if player is not in line of sight of any NPC and is sneaking and is not detected by NPCs. Crime will not occur. Stolen item is still marked as stolen.\nUse only one of \"Enable stealing\" or \"Only steal when hidden\"",
	variable = mwse.mcm:createTableVariable{
		id = "enableHiddenSteal",
		table = config,
		restartRequired = false,
	},
}
steal:createOnOffButton{
    label = "NPC LOS detection",
    description = "If \"Only steal when hidden\" is enabled player detection can be set to specific type. If disabled mod only checks if UI element of player sneaking is visible. This is the most performance-wise option, so use this one if you don't have any mods that hides this icon. When enabled on detection check actually scans current cells and checks if player is in line of sight of any NPC",
	variable = mwse.mcm:createTableVariable{
		id = "useLOSdetection",
		table = config,
		restartRequired = false,
	},
}
steal:createOnOffButton{
	label = "Keep item owner",
	description = "Stolen item will keep ownership information. If you try to sell such item to the owner he will freak out and you will get a bounty.",
	variable = mwse.mcm:createTableVariable{
		id = "keepOwner",
		table = config,
		restartRequired = false,
	},
}
steal:createOnOffButton{
	label = "Enable steal bounty",
	description = "If you were not hidden while stealing and NPC sees that - you will incur a theft bounty just like with regular stealing.",
	variable = mwse.mcm:createTableVariable{
		id = "enableBounty",
		table = config,
		restartRequired = false,
	},
}
steal:createOnOffButton{
	label = "Ignore locks",
	description = "Container will stay locked but items will transfer to player inventory.",
	variable = mwse.mcm:createTableVariable{
		id = "ignoreLock",
		table = config,
		restartRequired = false,
	},
}
----------------------
-- NPCs --
----------------------
local npc = preferences:createCategory{label = "NPCs"}
npc:createOnOffButton{
	label = "Use whitelist",
	variable = mwse.mcm:createTableVariable{
		id = "useWhitelist",
		table = config.npcs,
		restartRequired = false,
	}
}
npc:createOnOffButton{
	label = "Use blacklist",
	variable = mwse.mcm:createTableVariable{
		id = "useBlacklist",
		table = config.npcs,
		restartRequired = false,
	}
}
----------------------
-- Containers --
----------------------
local containers = preferences:createCategory{label = "Containers"}
containers:createOnOffButton{
	label = "Use whitelist",
	variable = mwse.mcm:createTableVariable{
		id = "useWhitelist",
		table = config.containers,
		restartRequired = false,
	}
}
containers:createOnOffButton{
	label = "Use blacklist",
	variable = mwse.mcm:createTableVariable{
		id = "useBlacklist",
		table = config.containers,
		restartRequired = false,
	}
}
----------------------
-- Cells --
----------------------
local cells = preferences:createCategory{label = "Cells"}
cells:createOnOffButton{
	label = "Use whitelist",
	variable = mwse.mcm:createTableVariable{
		id = "useWhitelist",
		table = config.cells,
		restartRequired = false,
	},
}
cells:createOnOffButton{
	label = "Add current cell to whitelist",
	variable = mwse.mcm:createVariable{
		get = (
			function(self)
				-- if tes3.mobilePlayer then
					-- local cell = tes3.mobilePlayer.cell
					-- mwse.log('[createOnOffButton]'..cell.id)
					-- return cell.id
				-- end
				return 0
			end
		),
		set = (
			function(self, newVal)
			end
		),
		inGameOnly = true
	},
	callback = function()
		if tes3.mobilePlayer then
			local cell = tes3.mobilePlayer.cell
			if cell then
				config.cells.whitelist[cell.id] = true
				tes3.messageBox(cell.id.." added to whitelist")
			end
		end
	end,
}
cells:createOnOffButton{
	label = "Use blacklist",
	variable = mwse.mcm:createTableVariable{
		id = "useBlacklist",
		table = config.cells,
		restartRequired = false,
	},
}
cells:createOnOffButton{
	label = "Add current cell to blacklist",
	variable = mwse.mcm:createVariable{
		get = (
			function(self)
				return 0
			end
		),
		set = (
			function(self, newVal)
			end
		),
		inGameOnly = true
	},
	callback = function()
		if tes3.mobilePlayer then
			local cell = tes3.mobilePlayer.cell
			if cell then
				config.cells.blacklist[cell.id] = true
				tes3.messageBox(cell.id.." added to blacklist")
			end
		end
	end,
}

local categories = preferences:createCategory{label = "Categories"}

for name, category in pairs(config.categories) do
	local block = preferences:createCategory{label = name}

	block:createOnOffButton{
		label = "Enabled",
		variable = mwse.mcm:createTableVariable{
			id = "enabled",
			table = config.categories[name],
			restartRequired = false,
		}
	}
	block:createOnOffButton{
		label = "Use weigth/value ratio",
		variable = mwse.mcm:createTableVariable{
			id = "useWeigthValueRatio",
			table = config.categories[name],
			restartRequired = false,
		}
	}
	block:createOnOffButton{
		label = "Use whitelist",
		variable = mwse.mcm:createTableVariable{
			id = "useWhitelist",
			table = config.categories[name],
			restartRequired = false,
		}
	}
	block:createOnOffButton{
		label = "Use blacklist",
		variable = mwse.mcm:createTableVariable{
			id = "useBlacklist",
			table = config.categories[name],
			restartRequired = false,
		}
	}
end
----------------------
-- Cells --
----------------------
template:createExclusionsPage{
	label = "Cell whitelist",
	leftListLabel = "Allowed to loot in",
	rightListLabel = "All cells",
	variable = mwse.mcm:createTableVariable{
		id = "whitelist",
		table = config.cells,
		restartRequired = false,
	},
	filters = {
		{callback = getCells},
	},
}
template:createExclusionsPage{
	label = "Cell blacklist",
	leftListLabel = "Not allowed to loot in",
	rightListLabel = "All cells",
	variable = mwse.mcm:createTableVariable{
		id = "blacklist", 
		table = config.cells
	},
	filters = {
		{callback = getCells},
	},
}
----------------------
-- NPCs --
----------------------
template:createExclusionsPage{
	label = "NPC whitelist",
	leftListLabel = "Allowed to loot",
	rightListLabel = "All NPCs",
	variable = mwse.mcm:createTableVariable{
		id = "whitelist",
		table = config.npcs
	},
	filters = {
		{
			type = "Object",
			label = "NPCs",
			objectType = tes3.objectType.npc,
		},
		{
			type = "Object",
			label = "Creatures",
			objectType = tes3.objectType.creature,
		}
	}
}
template:createExclusionsPage{
	label = "NPC blacklist",
	leftListLabel = "Not allowed to loot",
	rightListLabel = "All NPCs",
	variable = mwse.mcm:createTableVariable{
		id = "blacklist",
		table = config.npcs
	},
	filters = {
		{
			type = "Object",
			label = "NPCs",
			objectType = tes3.objectType.npc,
		},
		{
			type = "Object",
			label = "Creatures",
			objectType = tes3.objectType.creature,
		}
	}
}
----------------------
-- Containers --
----------------------
template:createExclusionsPage{
	label = "Container whitelist",
	leftListLabel = "Allowed to loot",
	rightListLabel = "All containers",
	variable = mwse.mcm:createTableVariable{
		id = "whitelist",
		table = config.containers
	},
	filters = {
		{
			type = "Object",
			objectType = tes3.objectType.container,
		}
	}
}
template:createExclusionsPage{
	label = "Container blacklist",
	leftListLabel = "Not allowed to loot",
	rightListLabel = "All containers",
	variable = mwse.mcm:createTableVariable{
		id = "blacklist",
		table = config.containers
	},
	filters = {
		{
			type = "Object",
			objectType = tes3.objectType.container,
		}
	}
}
----------------------
-- Categories --
----------------------
for name, category in pairs(config.categories) do
	template:createExclusionsPage{
		label = name .. " whitelist",
		leftListLabel = "Allowed to loot",
		rightListLabel = "All items",
		variable = mwse.mcm:createTableVariable{
			id = "whitelist",
			table = config.categories[name]
		},
		filters = {
			{
				type = "Object",
				objectType = config.categories[name].type,
			}
		}
	}
	template:createExclusionsPage{
		label = name .. " blacklist",
		leftListLabel = "Not allowed to loot",
		rightListLabel = "All items",
		variable = mwse.mcm:createTableVariable{
			id = "blacklist",
			table = config.categories[name]
		},
		filters = {
			{
				type = "Object",
				objectType = config.categories[name].type,
			}
		}
	}
end


template:saveOnClose("autoloot", config)
template:register()
