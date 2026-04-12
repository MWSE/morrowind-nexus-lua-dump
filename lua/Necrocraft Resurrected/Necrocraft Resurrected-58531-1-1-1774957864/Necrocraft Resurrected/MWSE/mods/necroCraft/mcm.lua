local config = require("NecroCraft.config")
local strings = require("NecroCraft.strings")

local function getNPCs()
	local temp = {}
	for obj in tes3.iterateObjects(tes3.objectType.npc) do
		---@cast obj tes3npc
		temp[obj.name:lower()] = true
	end

	local list = {}
	for name in pairs(temp) do
		list[#list + 1] = name
	end

	table.sort(list)
	return list
end

local function registerModConfig()
	local template = mwse.mcm.createTemplate({
		name = strings.mcm.modName,
		config = config,
	})
	template:saveOnClose("NecroCraft", config)
	template:register()

	local page = template:createSideBarPage({ label = strings.mcm.settings, showReset = true })
	local settings = page:createCategory(strings.mcm.settings)

	settings:createLogLevelOptions{ label = strings.mcm.logLevel, configKey = "logLevel" }

	settings:createOnOffButton{
		label = strings.mcm.preserveTooltip,
		description = strings.mcm.preserveTooltipDesc,
		configKey = "preserveTooltip",
	}
	settings:createOnOffButton{
		label = strings.mcm.editSummonUndeadEffects,
		description = strings.mcm.editSummonUndeadEffectsDesc,
		configKey = "editSummonUndeadEffects",
	}
	settings:createOnOffButton{
		label = strings.mcm.replaceSummonUndeadSpells,
		description = strings.mcm.replaceSummonUndeadSpellsDesc,
		configKey = "replaceSummonUndeadSpells",
	}
	settings:createSlider{
		label = strings.mcm.bountyValue,
		description = strings.mcm.bountyValueDesc,
		min = 500,
		max = 5000,
		step = 10,
		jump = 500,
		configKey = "bountyValue",
	}

	local crafting = page:createCategory(strings.mcm.crafting)

	crafting:createSlider{
		label = strings.mcm.experienceGain,
		description = strings.mcm.experienceGainDesc,
		min = 10,
		max = 100,
		step = 1,
		jump = 5,
		variable = mwse.mcm.createTableVariable{ id = "experienceGain", table = config.crafting },
	}

	template:createExclusionsPage{
		label = strings.mcm.necromancers,
		description = strings.mcm.necromancersDesc,
		leftListLabel = strings.mcm.necromancers,
		rightListLabel = "NPCs",
		variable = mwse.mcm.createTableVariable{ id = "necromancers", table = config },
		filters = { { label = "NPCs", callback = getNPCs } },
	}

	template:createExclusionsPage{
		label = strings.mcm.summonTeachers,
		description = strings.mcm.summonTeachersDesc,
		leftListLabel = strings.mcm.summonTeachers,
		rightListLabel = "NPCs",
		variable = mwse.mcm.createTableVariable{ id = "summonTeachers", table = config },
		filters = { { label = "Teachers", callback = getNPCs } },
	}
end

event.register("modConfigReady", registerModConfig)
