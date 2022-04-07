local config  = require("MTArmor.config")
local common = require("MTArmor.common")

local template = mwse.mcm.createTemplate(common.dictionary.modName)
template:saveOnClose("MTArmor", config)
template:register();

local page = template:createSideBarPage({
  label = common.dictionary.settings,
});
local settings = page:createCategory(common.dictionary.settings)


local function getMoragTongMembers()
  local temp = {}

  local moragTong = tes3.getFaction("Morag Tong")

  for obj in tes3.iterateObjects(tes3.objectType.npc) do
    if obj.faction == moragTong and not obj.isInstance then
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

settings:createOnOffButton({
  label = common.dictionary.modEnabled,
  description = common.dictionary.modEnabledDesc,
  variable = mwse.mcm.createTableVariable {
    id = "modEnabled",
    table = config
  }
})

settings:createOnOffButton({
  label = common.dictionary.replaceArmor,
  description = common.dictionary.replaceArmorDesc,
  variable = mwse.mcm.createTableVariable {
    id = "replaceArmor",
    table = config
  }
})


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

template:createExclusionsPage{
	label = common.dictionary.dontReplaceArmorOf,
	description = common.dictionary.dontReplaceArmorOfDesc,
	leftListLabel = common.dictionary.dontReplaceArmorOf,
	rightListLabel = common.dictionary.moragTongMembers,
	variable = mwse.mcm.createTableVariable{
		id = "dontReplaceArmorOf",
		table = config,
	},
	filters = {
		{callback = getMoragTongMembers},
	},
}

template:createExclusionsPage{
	label = common.dictionary.addFullSetTo,
	description = common.dictionary.addFullSetToDesc,
	leftListLabel = common.dictionary.addFullSetTo,
	rightListLabel = common.dictionary.moragTongMembers,
	variable = mwse.mcm.createTableVariable{
		id = "addFullSetTo",
		table = config,
	},
	filters = {
		{callback = getMoragTongMembers},
	},
}


