local configPath = "OAAB Glowbugs"
local config = require("OAAB.glowbugs.config")
local defaults = require("OAAB.glowbugs.defaults")

local function registerVariable(id)
    return mwse.mcm.createTableVariable{
        id = id,
        table = config
    }
end

local template = mwse.mcm.createTemplate{
    name="OAAB Светлячки",
    headerImagePath="\\Textures\\OAAB\\mcm\\glowbugs\\glowbugs_logo.dds"
}

---
local mainPage = template:createPage{label="Основные настройки"}

mainPage:createCategory{
	label = "OAAB Светлячки от команды OAAB team.\nЭто MWSE-код, контролирующий появление светлячков.\n\nНастройки:",
}

mainPage:createSlider {
    label = string.format("Плотность светлячков (количество их стаек) на ячейку.\nПо умолчанию - %s.\nПлотность светлячков.", defaults.bugDensity),
    min = 1,
    max = 20,
    step = 1,
    jump = 10,
    variable = registerVariable("bugDensity")
}

mainPage:createSlider {
    label = string.format("Вероятность того, что светлячки появятся при соблюдении других условий.\nПо умолчанию - %s%%.\nВероятность появления.", defaults.spawnChance),
    min = 0,
    max = 100,
    step = 1,
    jump = 10,
    variable = registerVariable("spawnChance")
}

---
template:createExclusionsPage{
	label = "Зеленые",
	description = "Выберите, в каких районах будут появляться зеленые светлячки. Переместите районы в левую таблицу, чтобы включить их.",
	toggleText = "Переключить",
	leftListLabel = "Активные районы",
	rightListLabel = "Все районы",
	showAllBlocked = false,
	variable = registerVariable("greenBugsRegions"),
	filters = {

		{
			label = "Районы",
			callback = (
				function()
					local regionIDs = {}
					for region in tes3.iterate(tes3.dataHandler.nonDynamicData.regions) do
						table.insert(regionIDs, region.id)
					end
					return regionIDs
				end
			)
		},

	}
}

---
template:createExclusionsPage{
	label = "Синие",
	description = "Выберите, в каких районах будут появляться зеленые светлячки. Переместите районы в левую таблицу, чтобы включить их.",
	toggleText = "Переключить",
	leftListLabel = "Активные районы",
	rightListLabel = "Все районы",
	showAllBlocked = false,
	variable = registerVariable("blueBugsRegions"),
	filters = {

		{
			label = "Районы",
			callback = (
				function()
					local regionIDs = {}
					for region in tes3.iterate(tes3.dataHandler.nonDynamicData.regions) do
						table.insert(regionIDs, region.id)
					end
					return regionIDs
				end
			)
		},

	}
}

--- Only show additional options is our esp is active
if tes3.isModActive("OAAB_Red&Violet_Glowbugs.esp") then
	---
	template:createExclusionsPage{
		label = "Красные",
		description = "Выберите, в каких районах будут появляться зеленые светлячки. Переместите районы в левую таблицу, чтобы включить их.",
		toggleText = "Переключить",
		leftListLabel = "Активные районы",
		rightListLabel = "Все районы",
		showAllBlocked = false,
		variable = registerVariable("redBugsRegions"),
		filters = {

			{
				label = "Районы",
				callback = (
					function()
						local regionIDs = {}
						for region in tes3.iterate(tes3.dataHandler.nonDynamicData.regions) do
							table.insert(regionIDs, region.id)
						end
						return regionIDs
					end
				)
			},

		}
	}

	---
	template:createExclusionsPage{
		label = "Фиолетовые",
		description = "Выберите, в каких районах будут появляться зеленые светлячки. Переместите районы в левую таблицу, чтобы включить их.",
		toggleText = "Переключить",
		leftListLabel = "Активные районы",
		rightListLabel = "Все районы",
		showAllBlocked = false,
		variable = registerVariable("violetBugsRegions"),
		filters = {

			{
				label = "Районы",
				callback = (
					function()
						local regionIDs = {}
						for region in tes3.iterate(tes3.dataHandler.nonDynamicData.regions) do
							table.insert(regionIDs, region.id)
						end
						return regionIDs
					end
				)
			},

		}
	}
end

template:saveOnClose(configPath, config)
mwse.mcm.register(template)
