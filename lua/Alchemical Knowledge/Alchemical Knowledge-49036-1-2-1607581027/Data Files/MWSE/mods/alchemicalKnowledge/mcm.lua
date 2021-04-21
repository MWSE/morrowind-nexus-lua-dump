local EasyMCM = require("easyMCM.EasyMCM")
local config  = require("alchemicalKnowledge.config")
local strings = require("alchemicalKnowledge.strings")

local template = EasyMCM.createTemplate(strings.mcm.modName)
template:saveOnClose("alchemyKnowledge", config)
template:register();

local page = template:createSideBarPage({
  label = strings.mcm.settings,
});
local settings = page:createCategory(strings.mcm.settings)

local function getIngredients()
    local temp = {}
    for obj in tes3.iterateObjects(tes3.objectType.ingredient) do
        temp[obj.id:lower()] = true
    end
    
    local list = {}
    for id in pairs(temp) do
        list[#list+1] = id
    end
    
    table.sort(list)
    return list
end

settings:createOnOffButton({
  label = strings.mcm.modEnabled,
  description = strings.mcm.modEnabledDesc,
  variable = EasyMCM.createTableVariable {
    id = "modEnabled",
    table = config
  }
})


settings:createSlider({
  label = strings.mcm.gmstValue,
  max = 100,
  description = strings.mcm.gmstValueDesc,
  variable = EasyMCM.createTableVariable {
    id = "gmstValue",
    table = config
  }
})

template:createExclusionsPage{
	label = strings.mcm.nonEdible,
	description = strings.mcm.nonEdibleDesc,
	leftListLabel = strings.mcm.nonEdible,
	rightListLabel = "Ingredients",
	variable = mwse.mcm.createTableVariable{
		id = "nonEdible",
		table = config,
	},
	filters = {
		{callback = getIngredients},
	},
}

