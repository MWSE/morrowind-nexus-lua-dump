local config  = require("moragTong.config")
local common = require("moragTong.common")

local strings = common.dictionary

local template = mwse.mcm.createTemplate(strings.modName)
template:saveOnClose("moragTong", config)
template:register();

local page = template:createSideBarPage({
  label = strings.settings,
});
local settings = page:createCategory(strings.settings)


local function getHelmets()
    local temp = {}
    for obj in tes3.iterateObjects(tes3.objectType.armor) do
        if obj.slot == tes3.armorSlot.helmet then
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

local function getArmorAndClothing()
    local temp = {}
    for obj in tes3.iterateObjects(tes3.objectType.armor) do
        temp[obj.id:lower()] = true
    end

	for obj in tes3.iterateObjects(tes3.objectType.clothing) do
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
	label = strings.closedHelmets,
	description = strings.closedHelmetsDesc,
	leftListLabel = strings.closedHelmets,
	rightListLabel = "Helmets",
	variable = mwse.mcm.createTableVariable{
		id = "closedHelmets",
		table = config,
	},
	filters = {
		{callback = getHelmets},
	},
}

template:createExclusionsPage{
	label = strings.moragTongItems,
	description = strings.moragTongItemsDesc,
	leftListLabel = strings.moragTongItems,
	rightListLabel = "Armor and Clothing",
	variable = mwse.mcm.createTableVariable{
		id = "moragTongItems",
		table = config,
	},
	filters = {
		{callback = getArmorAndClothing},
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

settings:createSlider{
	label = strings.revelationCount,
	description = strings.revelationCountDesc,
	min = 1,
	max = 100,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{
		id = "revelationCount",
		table = config
	}
}

settings:createSlider{
	label = strings.privilegedRank,
	description = strings.privilegedRankDesc,
	min = 0,
	max = 10,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{
		id = "privilegedRank",
		table = config
	}
}