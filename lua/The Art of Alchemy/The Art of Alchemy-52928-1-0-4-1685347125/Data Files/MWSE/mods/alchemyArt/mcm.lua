local config  = require("alchemyArt.config")
local common = require("alchemyArt.common")

local template = mwse.mcm.createTemplate(common.dictionary.modName)
template:saveOnClose("alchemyArt", config)
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

settings:createOnOffButton({
  label = common.dictionary.extraHelpMenu,
  description = common.dictionary.extraHelpMenuDesc,
  variable = mwse.mcm.createTableVariable {
    id = "tutorialMode",
    table = config
  }
})

settings:createOnOffButton({
  label = common.dictionary.rebalanceApparatus,
  description = common.dictionary.rebalanceApparatusDesc,
  variable = mwse.mcm.createTableVariable {
    id = "rebalanceApparatus",
    table = config
  }
})

settings:createOnOffButton({
  label = common.dictionary.rebalancePotions,
  description = common.dictionary.rebalancePotionsDesc,
  variable = mwse.mcm.createTableVariable {
    id = "rebalancePotions",
    table = config
  }
})

settings:createOnOffButton({
  label = common.dictionary.fixApparatusModels,
  description = common.dictionary.fixApparatusModelsDesc,
  variable = mwse.mcm.createTableVariable {
    id = "fixApparatusModels",
    table = config
  }
})

settings:createOnOffButton({
  label = common.dictionary.hideUngrindedEffects,
  description = common.dictionary.hideUngrindedEffectsDesc,
  variable = mwse.mcm.createTableVariable {
    id = "hideUngrindedEffects",
    table = config
  }
})

settings:createOnOffButton({
  label = common.dictionary.overhaulIngredients,
  description = common.dictionary.overhaulIngredientsDesc,
  variable = mwse.mcm.createTableVariable {
    id = "overhaulIngredients",
    table = config
  }
})

settings:createSlider{
	label = common.dictionary.alchemyTime,
	description = common.dictionary.alchemyTimeDesc,
	min = 1,
	max = 12,
	step = 1,
	jump = 3,
	variable = mwse.mcm.createTableVariable{
		id = "alchemyTime",
		table = config
	}
}

settings:createSlider{
	label = common.dictionary.experienceGain,
	description = common.dictionary.experienceGainDesc,
	min = 1,
	max = 7,
	step = 1,
	jump = 2,
	variable = mwse.mcm.createTableVariable{
		id = "experienceGain",
		table = config
	}
}

