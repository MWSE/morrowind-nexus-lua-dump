local config = require("Magicka Regen.config")

local template = mwse.mcm.createTemplate("Magicka Regen")
template:saveOnClose("Magicka Regen", config)

local page = template:createSideBarPage()
page.label = "Настройки"
page.description = 
	(
		"MWSE Magicka Regen добавляет в Morrowind функциональную и настраиваемую систему восстановления магии " ..
		"как для игроков, так и для NPC. Этот мод работает независимо от расы " ..
		"или знака рождения за исключением знака Атронаха. " ..
		"Кроме того, восстановление магии рассчитывается на основе времени ожидания/отдыха. "
	)
page.noScroll = false

local category = page:createCategory("Settings")

local pcRegenButton = category:createOnOffButton({
	label = "Включить восстановление магии для игрока",
	description = "Эта опция определяет, будет ли магия персонажа игрока восстанавливаться с течением времени. Скорость восстановления зависит от интеллекта и силы воли персонажа игрока.\n\nПо умолчанию: Включено",
	variable = mwse.mcm:createTableVariable{id = "pcRegen", table = config}
})

local npcRegenButton = category:createOnOffButton({
	label = "Включить восстановление магии для NPC",
	description = "Эта опция определяет, будет ли магия NPC восстанавливаться с течением времени. Скорость восстановления зависит от интеллекта и силы воли NPC.\n\nПо умолчанию: Включено",
	variable = mwse.mcm:createTableVariable{id = "npcRegen", table = config}
})

local vanillaButton = category:createOnOffButton({
	label = "Использовать формулу ванильного восстановления",
	description = "Рассчитывать скорость восстановлени ямагии на основе формулы ванильного восстановления, а не на основе перебалансированной, в большей степени основанной на значениях характеристик, формулы по умолчанию из мода.\n\nПо умолчанию: Выключено",
	variable = mwse.mcm:createTableVariable{id = "vanillaRate", table = config}
})

local vanillaButton = category:createOnOffButton({
	label = "Включить замедление восстановления",
	description = "Уменьшать скорость восстановления магии по мере приближения значения магии к максимальному значению.\n\nПо умолчанию: Выключено",
	variable = mwse.mcm:createTableVariable{id = "magickaDecay", table = config}
})

local pcRegenSlider = category:createSlider({
	label = "Скорость восстановления магии игрока: %s%%",
	description = "Скорость, с которой магия игрока будет восстанавливаться с течением времени.\n\nПо умолчанию: 100%",
	min = 0,
	max = 200,
	step = 1,
	jump = 24,
	variable = mwse.mcm.createTableVariable{id = "pcRate", table = config },
})

local npcRegenSlider = category:createSlider({
	label = "Скорость восстановления магии NPC: %s%%",
	description = "Скорость, с которой магия NPC будет восстанавливаться с течением времени.\n\nПо умолчанию: 100%",
	min = 0,
	max = 200,
	step = 1,
	jump = 24,
	variable = mwse.mcm.createTableVariable{id = "npcRate", table = config },
})

mwse.mcm.register(template)