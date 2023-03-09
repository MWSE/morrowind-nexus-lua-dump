local config  = require("cureMagnitude.config")
local common = require("cureMagnitude.common")

local template = mwse.mcm.createTemplate(common.dictionary.modName)
template:saveOnClose("cureMagnitude", config)
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
  label = common.dictionary.alchemyRebalance,
  description = common.dictionary.alchemyRebalanceDesc,
  variable = mwse.mcm.createTableVariable {
    id = "alchemyRebalance",
    table = config
  }
})


local cureCommon = page:createCategory(common.dictionary.cureCommon)

cureCommon:createOnOffButton({
  label = common.dictionary.scaleCureCommon,
  description = common.dictionary.scaleCureCommonDesc,
  variable = mwse.mcm.createTableVariable {
    id = "scaleCureCommon",
    table = config
  }
})

cureCommon:createSlider{
	label = common.dictionary.defaultAlchemyMagnitude,
	description = common.dictionary.defaultAlchemyMagnitudeDesc,
	min = 1,
	max = 100,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{
		id = tostring(tes3.objectType.alchemy),
		table = config.defaultMagnitude[tostring(tes3.effect.cureCommonDisease)]
	}
}

cureCommon:createSlider{
	label = common.dictionary.defaultEnchantmentMagnitude,
	description = common.dictionary.defaultEnchantmentMagnitudeDesc,
	min = 1,
	max = 100,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{
		id = tostring(tes3.objectType.enchantment),
		table = config.defaultMagnitude[tostring(tes3.effect.cureCommonDisease)]
	}
}

cureCommon:createSlider{
	label = common.dictionary.defaultSpellMagnitude,
	description = common.dictionary.defaultSpellMagnitudeDesc,
	min = 1,
	max = 100,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{
		id = tostring(tes3.objectType.spell),
		table = config.defaultMagnitude[tostring(tes3.effect.cureCommonDisease)]
	}
}

local cureBlight = page:createCategory(common.dictionary.cureBlight)

cureBlight:createOnOffButton({
  label = common.dictionary.scaleCureBlight,
  description = common.dictionary.scaleCureBlightDesc,
  variable = mwse.mcm.createTableVariable {
    id = "scaleCureBlight",
    table = config
  }
})

cureBlight:createSlider{
	label = common.dictionary.defaultAlchemyMagnitude,
	description = common.dictionary.defaultAlchemyMagnitudeDesc,
	min = 1,
	max = 100,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{
		id = tostring(tes3.objectType.alchemy),
		table = config.defaultMagnitude[tostring(tes3.effect.cureBlightDisease)]
	}
}

cureBlight:createSlider{
	label = common.dictionary.defaultEnchantmentMagnitude,
	description = common.dictionary.defaultEnchantmentMagnitudeDesc,
	min = 1,
	max = 100,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{
		id = tostring(tes3.objectType.enchantment),
		table = config.defaultMagnitude[tostring(tes3.effect.cureBlightDisease)]
	}
}

cureBlight:createSlider{
	label = common.dictionary.defaultSpellMagnitude,
	description = common.dictionary.defaultSpellMagnitudeDesc,
	min = 1,
	max = 100,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{
		id = tostring(tes3.objectType.spell),
		table = config.defaultMagnitude[tostring(tes3.effect.cureBlightDisease)]
	}
}

local curePoison = page:createCategory(common.dictionary.curePoison)

curePoison:createOnOffButton({
  label = common.dictionary.scaleCurePoison,
  description = common.dictionary.scaleCurePoisonDesc,
  variable = mwse.mcm.createTableVariable {
    id = "scaleCurePoison",
    table = config
  }
})

curePoison:createSlider{
	label = common.dictionary.defaultAlchemyMagnitude,
	description = common.dictionary.defaultAlchemyMagnitudeDesc,
	min = 1,
	max = 100,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{
		id = tostring(tes3.objectType.alchemy),
		table = config.defaultMagnitude[tostring(tes3.effect.curePoison)]
	}
}

curePoison:createSlider{
	label = common.dictionary.defaultEnchantmentMagnitude,
	description = common.dictionary.defaultEnchantmentMagnitudeDesc,
	min = 1,
	max = 100,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{
		id = tostring(tes3.objectType.enchantment),
		table = config.defaultMagnitude[tostring(tes3.effect.curePoison)]
	}
}

curePoison:createSlider{
	label = common.dictionary.defaultSpellMagnitude,
	description = common.dictionary.curPoisonDefaultSpellMagnitudeDesc,
	min = 1,
	max = 100,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{
		id = tostring(tes3.objectType.spell),
		table = config.defaultMagnitude[tostring(tes3.effect.curePoison)]
	}
}

local cureParalyzation = page:createCategory(common.dictionary.cureParalyzation)

cureParalyzation:createOnOffButton({
  label = common.dictionary.scaleCureParalyzation,
  description = common.dictionary.scaleCureParalyzationDesc,
  variable = mwse.mcm.createTableVariable {
    id = "scaleCureParalyzation",
    table = config
  }
})


cureParalyzation:createSlider{
	label = common.dictionary.defaultAlchemyMagnitude,
	description = common.dictionary.defaultAlchemyMagnitudeDesc,
	min = 1,
	max = 100,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{
		id = tostring(tes3.objectType.alchemy),
		table = config.defaultMagnitude[tostring(tes3.effect.cureParalyzation)]
	}
}

cureParalyzation:createSlider{
	label = common.dictionary.defaultEnchantmentMagnitude,
	description = common.dictionary.defaultEnchantmentMagnitudeDesc,
	min = 1,
	max = 100,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{
		id = tostring(tes3.objectType.enchantment),
		table = config.defaultMagnitude[tostring(tes3.effect.cureParalyzation)]
	}
}

cureParalyzation:createSlider{
	label = common.dictionary.defaultSpellMagnitude,
	description = common.dictionary.curParalyzationDefaultSpellMagnitudeDesc,
	min = 1,
	max = 100,
	step = 1,
	jump = 5,
	variable = mwse.mcm.createTableVariable{
		id = tostring(tes3.objectType.spell),
		table = config.defaultMagnitude[tostring(tes3.effect.cureParalyzation)]
	}
}