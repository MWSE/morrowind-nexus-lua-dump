local config  = require("buyingGame.config")
local common = require("buyingGame.common")
local strings = common.dictionary

local template = mwse.mcm.createTemplate(strings.modName)
template:saveOnClose("buyingGame", config)
template:register();

local page = template:createSideBarPage({
  label = "Settings",
});
local settings = page:createCategory("Settings")


local function getItems()
    local temp = {}
	
	local itemTypes = { 
		[tes3.objectType.alchemy] = true,
		[tes3.objectType.ammunition] = true,
		[tes3.objectType.apparatus] = true,
		[tes3.objectType.armor] = true,
		[tes3.objectType.book] = true,
		[tes3.objectType.clothing] = true,
		[tes3.objectType.ingredient] = true,
		[tes3.objectType.light] = true,
		[tes3.objectType.lockpick] = true,
		[tes3.objectType.miscItem] = true,
		[tes3.objectType.probe] = true,
		[tes3.objectType.repairItem] = true,
		[tes3.objectType.weapon] = true
	}	
	
	for itemType, _ in pairs(itemTypes)do
		for obj in tes3.iterateObjects(itemType) do
			temp[obj.id:lower()] = true
		end
	end
	
    local list = {}
    for id in pairs(temp) do
        list[#list+1] = id
    end
    
    table.sort(list)
    return list
end

local function getNPCs()
    local temp = {}
    for obj in tes3.iterateObjects(tes3.objectType.npc) do
        temp[obj.id:lower()] = true
    end
    
    local list = {}
    for id in pairs(temp) do
        list[#list+1] = id
    end
    
    table.sort(list)
    return list
end

template:createExclusionsPage{
	label = strings.forbidden,
	description = strings.forbiddenDesc,
	leftListLabel = strings.forbidden,
	rightListLabel = "Items",
	variable = mwse.mcm.createTableVariable{
		id = "forbidden",
		table = config,
	},
	filters = {
		{callback = getItems},
	},
}

template:createExclusionsPage{
	label = strings.smuggler,
	description = strings.smugglerDesc,
	leftListLabel = strings.smuggler,
	rightListLabel = "NPCs",
	variable = mwse.mcm.createTableVariable{
		id = "smuggler",
		table = config,
	},
	filters = {
		{callback = getNPCs},
	},
}

settings:createOnOffButton({
  label = strings.modEnabled,
  description = strings.modEnabledDesc,
  variable = mwse.mcm.createTableVariable {
    id = "modEnabled",
    table = config
  }
})

settings:createOnOffButton({
  label = strings.removeBought,
  description = strings.removeBoughtDesc,
  variable = mwse.mcm.createTableVariable {
    id = "removeBought",
    table = config
  }
})

settings:createSlider{
	label = strings.difficultyLevel,
	description = strings.difficultyLevelDesc,
	min = 1,
	max = 5,
	step = 1,
	jump = 2,
	variable = mwse.mcm.createTableVariable{
		id = "difficultyLevel",
		table = config
	}
}

settings:createSlider{
	label = strings.restockTime,
	description = strings.restockTimeDesc,
	min = 1,
	max = 100,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{
		id = "restockTime",
		table = config
	}
}

local perks = page:createCategory(strings.perks)

perks:createSlider{
	label = strings.knowsPrice,
	description = strings.knowsPriceDesc,
	min = 0,
	max = 200,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{
		id = "knowsPrice",
		table = config
	}
}

perks:createSlider{
	label = strings.knowsForbid,
	description = strings.knowsForbidDesc,
	min = 0,
	max = 200,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{
		id = "knowsForbidden",
		table = config
	}
}

perks:createSlider{
	label = strings.knowsSpecialization,
	description = strings.knowsSpecializationDesc,
	min = 0,
	max = 200,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{
		id = "knowsSpecialization",
		table = config
	}
}

perks:createSlider{
	label = strings.knowsExport,
	description = strings.knowsExportDesc,
	min = 0,
	max = 200,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{
		id = "knowsExport",
		table = config
	}
}

perks:createSlider{
	label = strings.sdModifier,
	description = strings.sdModifierDesc,
	min = 10,
	max = 80,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{
		id = "sdModifier",
		table = config
	}
}

perks:createSlider{
	label = strings.canInvest,
	description = strings.canInvestDesc,
	min = 0,
	max = 200,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{
		id = "canInvest",
		table = config
	}
}

perks:createSlider{
	label = strings.canTradeWithEveryone,
	description = strings.canTradeWithEveryoneDesc,
	min = 0,
	max = 200,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{
		id = "canTradeWithEveryone",
		table = config
	}
}

perks:createSlider{
	label = strings.canBarterEquipped,
	description = strings.canBarterEquippedDesc,
	min = 0,
	max = 200,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{
		id = "canBarterEquipped",
		table = config
	}
}


