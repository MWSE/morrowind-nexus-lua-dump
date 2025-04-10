local config = require("Character Sound Overhaul.config")

local template = mwse.mcm.createTemplate{name = "CSO - переработка звуков персонажа", headerImagePath = "\\Textures\\Anu\\CSO\\CSO_Logo.tga"}
template:saveOnClose("Character Sound Overhaul", config)
template:register()


-- Create Pages


local function createPage(label)
	local page = template:createSideBarPage{
		label = label,
		noScroll = true,
	}
	page.sidebar:createInfo{
		text = "CSO - переработка звуков персонажа\n\nДинамическая переработка звуков взаимодействия персонажа (передвижение, бой, активация предметов и т.д.) в Morrowind.\n\nИспользуйте это меню настроек, чтобы настроить звуковое окружение в игре.\n\nНаведите курсор на отдельные параметры, чтобы получить дополнительную информацию."
	}
	page.sidebar:createHyperLink {
		text = "Автор: Anumaril21",
		exec = "start https://www.nexusmods.com/morrowind/users/60236996?tab=user+files",
		postCreate = function(self)
			self.elements.outerContainer.borderAllSides = self.indent
			self.elements.outerContainer.alignY = 1.0
			--self.elements.outerContainer.layoutHeightFraction = 1.0
			self.elements.info.layoutOriginFractionX = 0.5
		end,
	}
	return page
end

local pageMovement = createPage("Звуки движения")
local pageCombat = createPage("Звуки боя")
local pageItems = createPage("Звуки предметов")
local pageMisc = createPage("Прочие звуки")


-- Movement Category


local categoryMovement = pageMovement:createCategory{
	label = "Настройки звуков движения",
	description = ""
}
categoryMovement:createOnOffButton{
	label = "Включить звуки движения",
	description = "Включить звуки движения\n\nОпределяет, будут ли во время движения воспроизводиться звуковые эффекты, основанные на рельефе местности.\n\nПо умолчанию: Включено",
	variable = mwse.mcm:createTableVariable{id = "footstepSounds", table = config}
}
categoryMovement:createSlider{
	label = "Громкость движений игрока: %s%%",
	description = "Громкость движений игрока\n\n Определяет, насколько громкими будут звуки передвижения игрока.\n\n По умолчанию: 65%",
	min = 0,
	max = 100,
	step = 1,
	jump = 10,
	variable = mwse.mcm.createTableVariable{id = "PCfootstepVolume", table = config}
}
categoryMovement:createSlider{
	label = "Громкость передвижения NPC: %s%%",
	description = "Громкость передвижения NPC\n\n Определяет, насколько громкими будут звуки передвижения NPC и существ.\n\nЗначение по умолчанию: 85%",
	min = 0,
	max = 100,
	step = 1,
	jump = 10,
	variable = mwse.mcm.createTableVariable{id = "NPCfootstepVolume", table = config}
}


-- Armor Category


local categoryArmor = pageMovement:createCategory{
	label = "Настройки звуков доспехов",
	description = ""
}
categoryArmor:createOnOffButton{
	label = "Включить звуки доспехов",
	description = "Включить звуки доспехов\n\nОпределяет, будут ли воспроизводиться во время движения звуковые эффекты, соответствующие экипированным доспехам.\n\nПо умолчанию: Включено.",
	variable = mwse.mcm:createTableVariable{id = "armorSounds", table = config}
}
categoryArmor:createOnOffButton{
	label = "Включить альтернативную механику типа доспехов",
	description = "Включить альтернативную механику типа доспехов\n\nОпределяет, будут ли звуковые эффекты доспехов для всех рас зависеть от экипированной кирасы. В оригинальной игре тип доспехов для большинства рас определялся ботинками, а для звероподобных рас - кирасой.\n\nПо умолчанию: Выключено",
	variable = mwse.mcm:createTableVariable{id = "altArmor", table = config}
}
categoryArmor:createSlider{
	label = "Громкость доспехов игрока: %s%%",
	description = "Громкость доспехов игрока\n\nОпределяет, насколько громкими будут звуки доспехов при передвижении игрока.\n\nПо умолчанию: 65%",
	min = 0,
	max = 100,
	step = 1,
	jump = 10,
	variable = mwse.mcm.createTableVariable{id = "PCarmorVolume", table = config}
}
categoryArmor:createSlider{
	label = "Громкость доспехов NPC: %s%%",
	description = "Громкость доспехов NPC\n\nОпределяет, насколько громкими будут звуки доспехов при передвижении NPC и существ.\n\nПо умолчанию: 85%",
	min = 0,
	max = 100,
	step = 1,
	jump = 10,
	variable = mwse.mcm.createTableVariable{id = "NPCarmorVolume", table = config}
}


-- Weather Category


local categoryWeather = pageMovement:createCategory{
	label = "Настройки звуков погоды",
	description = ""
}
categoryWeather:createOnOffButton{
	label = "Включить звуки погоды",
	description = "Включить звуки погоды\n\nОпределяет, будут ли воспроизводиться во время движения звуковые эффекты, основанные на текущей погоде.\n\nПо умолчанию: Включено",
	variable = mwse.mcm:createTableVariable{id = "weatherSounds", table = config}
}
categoryWeather:createSlider{
	label = "Громкость звуков погоды игрока: %s%%",
	description = "Громкость звуков погоды игрока.\n\nОпределяет, насколько громкими будут погодные эффекты при движении игрока.\n\nПо умолчанию: 60%",
	min = 0,
	max = 100,
	step = 1,
	jump = 10,
	variable = mwse.mcm.createTableVariable{id = "PCweatherFootstepVolume", table = config}
}
categoryWeather:createSlider{
	label = "Громкость звуков погоды NPC: %s%%",
	description = "Громкость звуков погоды NPC.\n\nОпределяет, насколько громкими будут погодные эффекты при движении NPC и существ.\n\nПо умолчанию: 80%",
	min = 0,
	max = 100,
	step = 1,
	jump = 10,
	variable = mwse.mcm.createTableVariable{id = "NPCweatherFootstepVolume", table = config}
}


-- Combat Category


local categoryCombat = pageCombat:createCategory{
	label = "Настройки звуков боя",
	description = ""
}
categoryCombat:createOnOffButton{
	label = "Включить звуки оружия",
	description = "Включить звуки оружия\n\n Определяет, будут ли воспроизводиться звуковые эффекты при экипировке оружия, вложении его в ножны, размахивании им и нанесении урона.\n\nПо умолчанию: Включено",
	variable = mwse.mcm:createTableVariable{id = "weaponSounds", table = config}
}
categoryCombat:createSlider{
	label = "Громкость оружия игрока: %s%%",
	description = "Громкость оружия игрока.\n\nОпределяет, насколько громкими будут звуки оружия игрока.\n\nПо умолчанию: 65%.",
	min = 0,
	max = 100,
	step = 1,
	jump = 10,
	variable = mwse.mcm.createTableVariable{id = "PCweaponVolume", table = config}
}
categoryCombat:createSlider{
	label = "Громкость оружия NPC: %s%%",
	description = "Громкость оружия NPC\n\nОпределяет, насколько громкими будут звуки оружия NPC и существ.\n\nПо умолчанию: 85%.",
	min = 0,
	max = 100,
	step = 1,
	jump = 10,
	variable = mwse.mcm.createTableVariable{id = "NPCweaponVolume", table = config}
}


-- Items Category


local categoryItems = pageItems:createCategory{
	label = "Настройки звуков предметов",
	description = ""
}
categoryItems:createOnOffButton{
	label = "Включите звуки предметов в инвентаре",
	description = "Включить звуки предметов в инвентаре.\n\nОпределяет, будут ли включены звуковые эффекты предметов в инвентаре, подбора предметов и выбрасывания предметов.\n\nПо умолчанию: Включено",
	variable = mwse.mcm:createTableVariable{id = "itemSounds", table = config}
}
categoryItems:createOnOffButton{
	label = "Включить звуки использования предметов",
	description = "Включить звуки использования предметов\n\n Определяет, будут ли включены звуковые эффекты для таких действий, как питье зелий и ремонт предметов.\n\n По умолчанию: Включено",
	variable = mwse.mcm:createTableVariable{id = "itemUseSounds", table = config}
}
categoryItems:createSlider{
	label = "Громкость звука предметов: %s%%",
	description = "Громкость звука предметов\n\nОпределяет, насколько громкими будут звуки в инвентаре и при использовании предметов.\n\nПо умолчанию: 75%",
	min = 0,
	max = 100,
	step = 1,
	jump = 10,
	variable = mwse.mcm.createTableVariable{id = "itemVolume", table = config}
}


-- Misc Category


local categoryMisc = pageMisc:createCategory{
	label = "Настройки прочих звуков",
	description = ""
}
categoryMisc:createOnOffButton{
	label = "Включить звуки журнала",
	description = "Включить звуки журнала\n\nОпределяет, будут ли включены звуковые эффекты при обновлении журнала.\n\nПо умолчанию: Включено",
	variable = mwse.mcm:createTableVariable{id = "journalSounds", table = config}
}
categoryMisc:createOnOffButton{
	label = "Включить звуки разграбления тел\\трупов",
	description = "Включить звуки при разграблении тел\\трупов.\n\nОпределяет, будут ли включены звуковые эффекты при входе и выходе из экрана разграбления мертвых персонажей и трупов.\n\nПо умолчанию: Включено",
	variable = mwse.mcm:createTableVariable{id = "lootSounds", table = config}
}
categoryMisc:createOnOffButton{
	label = "Включить стандартные звуки ударов",
	description = "Включить стандартные звуки ударов\n\nСохраняет самую важную особенность игры без изменений.\n\nПо умолчанию: Выключено",
	variable = mwse.mcm:createTableVariable{id = "thumps", table = config}
}
categoryMisc:createSlider{
	label = "Громкость прочих звуков: %s%%",
	description = "Громкость прочих звуков\n\nОпределяет, насколько громкими будут выбранные прочие звуки.\n\nПо умолчанию: 75%.",
	min = 0,
	max = 100,
	step = 1,
	jump = 10,
	variable = mwse.mcm.createTableVariable{id = "miscVolume", table = config}
}
