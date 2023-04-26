local config  = require("classAttributeLimit.config")
local common = require("classAttributeLimit.common")

local template = mwse.mcm.createTemplate(common.dictionary.modName)
template:saveOnClose("classAttributeLimit", config)
template:register();

local page = template:createSideBarPage({
  label = common.dictionary.settings,
});
local settings = page:createCategory(common.dictionary.settings)


-- local function getNPCs()
--     local temp = {}
--     for obj in tes3.iterateObjects(tes3.objectType.npc) do
--         temp[obj.id:lower()] = true
--     end
    
--     local list = {}
--     for id in pairs(temp) do
--         list[#list+1] = id
--     end
    
--     table.sort(list)
--     return list
-- end

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
  label = common.dictionary.modEnabled,
  description = common.dictionary.modEnabledDesc,
  variable = mwse.mcm.createTableVariable {
    id = "modEnabled",
    table = config
  }
})

settings:createSlider{
	label = common.dictionary.baseRaise,
	description = common.dictionary.baseRaiseDesc,
	min = 0,
	max = 100,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{
		id = "baseRaise",
		table = config
	}
}

settings:createSlider{
	label = common.dictionary.classCoef,
	description = common.dictionary.classCoefDesc,
	min = 0,
	max = 5,
	step = 1,
	jump = 3,
	variable = mwse.mcm.createTableVariable{
		id = "classCoef",
		table = config
	}
}
