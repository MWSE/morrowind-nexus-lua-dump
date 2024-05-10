local seph = require("seph")
local npcSoulMode = require("seph.npcSoulTrapping.npcSoulMode")

local mcm = seph.Mcm()

function mcm:onCreate()
	local config = self.mod.config

	local function booleanToReadableString(boolean)
		if boolean then
			return "Да"
		else
			return "Нет"
		end
	end

	local function createSideBarPage(label)
		return self.template:createSideBarPage{
			label = label,
			description = "Наведите курсор на параметр, чтобы получить дополнительную информацию."
		}
	end

	local settingsPage = createSideBarPage("Настройки")

	local blackSoulGemCategory = settingsPage:createCategory("Черные камни душ")

	blackSoulGemCategory:createYesNoButton{
		label = "Включить для захвата душ NPC?",
		description = string.format("Этот параметр определяет, нужны ли черные камни душ для ловли душ NPC. Если установлено значение «Нет» все камни душ смогут ловить души NPC, .\n\nПо умолчанию: %s", booleanToReadableString(config.default.blackSoulGem.required)),
		variable = mwse.mcm.createTableVariable{id = "required", table = config.current.blackSoulGem, restartRequired = false}
	}

	blackSoulGemCategory:createYesNoButton{
		label = "Разрешить захватывать души существ?",
		description = string.format("Этот парметр определяет, способны ли черные камни душ ловить души существ. Черные камни душ могут содержать души NPC, только если для этого параметра установлено значение «Нет».\n\nПо умолчанию: %s", booleanToReadableString(config.default.blackSoulGem.canSoulTrapCreatures)),
		variable = mwse.mcm.createTableVariable{id = "canSoulTrapCreatures", table = config.current.blackSoulGem, restartRequired = false}
	}

	blackSoulGemCategory:createYesNoButton{
		label = "Считать \"Звезду Азуры\" черным камнем душ?",
		description = string.format("Этот параметр определяет, следует ли считать «Звезду Азуры» черным камнем душ. Работает только в том случае, если параметр \"Включить для захвата душ NPC?\" включен.\n\nПо умолчанию: %s", booleanToReadableString(config.default.blackSoulGem.defineAzuraAsBlackSoulGem)),
		variable = mwse.mcm.createTableVariable{id = "defineAzuraAsBlackSoulGem", table = config.current.blackSoulGem, restartRequired = false}
	}

	blackSoulGemCategory:createSlider{
		label = "Стоимость",
		description = string.format("Этот параметр устанавливает стоимость черного камня душ. А также определяет емкость камня душ в зависимости от ваших значений GMST. По умолчанию емкость камней душ в 3 раза превышает их стоимость.\n\nПо умолчанию: %d", config.default.blackSoulGem.value),
		min = 1, max = 1000, step = 1, jump = 10,
		variable = mwse.mcm.createTableVariable{id = "value", table = config.current.blackSoulGem, restartRequired = false}
	}

	blackSoulGemCategory:createSlider{
		label = "Шанс выпадения: %s%%",
		description = string.format("Этот параметр опеределяет вероятность появления черного камня душ вместо Великого камня душ в случайной добыче. Если установить значение 100%%, все великие камни душ в случайной добыче будут заменены черными камнями душ. Установка значения 0%% предотвратит появление черных камней душ. Имейте в виду, что великие камни душ не появляются в добыче, пока вы не достигнете более высокого уровня в ванильном Морровинде. Это также относится и к черным камням душ.\n\nПо умолчанию: %d", config.default.blackSoulGem.swapChance),
		min = 0, max = 100, step = 1, jump = 10,
		variable = mwse.mcm.createTableVariable{id = "swapChance", table = config.current.blackSoulGem, restartRequired = false}
	}

	local npcSoulCategory = settingsPage:createCategory("Цена души")

	npcSoulCategory:createDropdown{
		label = "Режим",
		description = string.format("Этот параметр устанавливает тип расчета, который будет использоваться для определения ценности души NPC.\n\nУровень: будет установлено значение \"уровень NPC * множитель уровня\".\n\nАтрибуты: будет установлено значение суммы всех атрибутов NPC.\n\nЗдоровье: будет установлено значение максимального здоровья NPC.\n\nФиксированное: для каждого NPC будет установлено фиксированное значение, указанное ниже.\n\nПо умолчанию: %s", config.default.npcSoul.mode),
		options = {
			{label = npcSoulMode.level, value = npcSoulMode.level},
			{label = npcSoulMode.attributes, value = npcSoulMode.attributes},
			{label = npcSoulMode.health, value = npcSoulMode.health},
			{label = npcSoulMode.fixed, value = npcSoulMode.fixed},
			{label = npcSoulMode.fixedLevel, value = npcSoulMode.fixedLevel},
			{label = npcSoulMode.fixedAttributes, value = npcSoulMode.fixedAttributes},
			{label = npcSoulMode.fixedHealth, value = npcSoulMode.fixedHealth}
		},
		variable = mwse.mcm:createTableVariable{id = "mode", table = config.current.npcSoul, restartRequired = false}
	}

	npcSoulCategory:createSlider{
		label = "Фиксированное",
		description = string.format("Это устанавливает фиксированное значение для каждого NPC для режима значения души «Фиксированное».\n\nПо умолчанию: %d", config.default.npcSoul.fixedValue),
		min = 10, max = 10000, step = 1, jump = 10,
		variable = mwse.mcm.createTableVariable{id = "fixedValue", table = config.current.npcSoul, restartRequired = false}
	}

	npcSoulCategory:createSlider{
		label = "Множитель уровня",
		description = string.format("Этот параметр устанавливает множитель уровня для режима значения души \"Уровень\".\n\nПо умолчанию: %d", config.default.npcSoul.levelMultiplier),
		min = 1, max = 100, step = 1, jump = 10,
		variable = mwse.mcm.createTableVariable{id = "levelMultiplier", table = config.current.npcSoul, restartRequired = false}
	}

	npcSoulCategory:createTextField{
		label = "Множитель",
		numbersOnly = true,
		description = string.format("Этот параметр устанавливает окончательный множитель ценности души. Установка значения 0,5 уменьшит ценность души вдвое, тогда как значения выше 1,0 увеличат ценность души. Данную функцию можно использовать для точной настройки значения души для любого режима.\n\nПо умолчанию: %d", config.default.npcSoul.multiplier),
		variable = mwse.mcm.createTableVariable{id = "multiplier", table = config.current.npcSoul, restartRequired = false},
		callback =
			function()
				config.current.npcSoul.multiplier = tonumber(config.current.npcSoul.multiplier or 0)
			end
	}

	self.template:createExclusionsPage{
		label = "NPCs",
		description = "Вы можете добавить из правого списка в левый любого NPC, к которому следует относиться как к существу, для захвата души которого не требуется черный камень душ. Это не влияет на ценность души NPC. Действует только в том случае, если для поимки душ NPC требуются черные камни душ.",
		leftListLabel = "Не требует черного камня душ",
		rightListLabel = "Требуется черный камень душ",
		variable = mwse.mcm:createTableVariable{id = "npcExceptions", table = config.current},
		filters = {
			{
				label = "NPCs",
				type = "Object",
				objectType = tes3.objectType.npc,
			}
		}
	}

	self.template:createExclusionsPage{
		label = "Существа",
		description = "Вы можете добавить из правого списка в левый любое существо, к которому следует относиться как к NPC, для захвата души которого требуется черный камень душ. Это не влияет на стоимость души существа. Действует только в том случае, если для поимки душ NPC требуются черные камни душ.",
		leftListLabel = "Требуется черный камень душ",
		rightListLabel = "Не требует черного камня душ",
		variable = mwse.mcm:createTableVariable{id = "creatureExceptions", table = config.current},
		filters = {
			{
				label = "Creatures",
				type = "Object",
				objectType = tes3.objectType.creature,
			}
		}
	}
end

function mcm:onClose()
	self.mod.modules.blackSoulGem.item.value = self.mod.config.current.blackSoulGem.value
end

return mcm