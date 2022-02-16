local config  = require("etheralGhosts.config")

local strings = {
	modName = "Etheral Ghosts",
	settings = "Settings",
	ghosts = "Ghosts",
	actors = "Actors",
	modEnabled = "Mod Enabled",
	modEnabledDesc = "Enabling and disabling the mod and all its functionality",
	ghostsDesc = "List of actors which are considered to be incorporeal"
}

local template = mwse.mcm.createTemplate(strings.modName)
template:saveOnClose("etheralGhosts", config)
template:register();

local page = template:createSideBarPage({
  label = strings.settings,
});
local settings = page:createCategory(strings.settings)

local function getActors()
    local temp = {}
    for obj in tes3.iterateObjects(tes3.objectType.npc) do
        temp[obj.id:lower()] = true
    end
	
	for obj in tes3.iterateObjects(tes3.objectType.creature) do
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
	label = strings.ghosts,
	description = strings.ghostsDesc,
	leftListLabel = strings.ghosts,
	rightListLabel = strings.actors,
	variable = mwse.mcm.createTableVariable{
		id = "ghosts",
		table = config,
	},
	filters = {
		{callback = getActors},
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