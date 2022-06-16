local config  = require("securityExpertise.config")
local common = require("securityExpertise.common")

local strings = common.dictionary

local template = mwse.mcm.createTemplate(strings.modName)
template:saveOnClose("securityExpertise", config)
template:register();

local page = template:createSideBarPage({
  label = strings.settings,
});
local settings = page:createCategory(strings.settings)


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

-- template:createExclusionsPage{
-- 	label = strings.smuggler,
-- 	description = strings.smugglerDesc,
-- 	leftListLabel = strings.smuggler,
-- 	rightListLabel = "NPCs",
-- 	variable = mwse.mcm.createTableVariable{
-- 		id = "smuggler",
-- 		table = config,
-- 	},
-- 	filters = {
-- 		{callback = getNPCs},
-- 	},
-- }

settings:createOnOffButton({
  label = strings.modEnabled,
  description = strings.modEnabledDesc,
  variable = mwse.mcm.createTableVariable {
    id = "modEnabled",
    table = config
  }
})

settings:createOnOffButton({
  label = strings.sellTrapPanels,
  description = strings.sellTrapPanelsDesc,
  variable = mwse.mcm.createTableVariable {
    id = "sellTrapPanels",
    table = config
  }
})

settings:createSlider{
	label = strings.canLock,
	description = strings.canLockDesc,
	min = 0,
	max = 200,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{
		id = "canLock",
		table = config
	}
}

settings:createSlider{
	label = strings.canTrap,
	description = strings.canTrapDesc,
	min = 0,
	max = 200,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{
		id = "canTrap",
		table = config
	}
}