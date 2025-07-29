local common = require("KBev.ProgressionMod.common")
local confPath = "KBev_ProgressionMod"
local config = mwse.loadConfig(confPath)
local defaultConfig = mwse.loadConfig("KCP Presets\\default settings")

if not config then config = defaultConfig end

local function updateConfig(newSettings)
	for k, v in pairs(newSettings) do
		config[k] = v
	end
end

--Backwards Compatibility with Old Configs
local function verifySettingsIntegrity()
	for setting, value in pairs(defaultConfig) do
		if config[setting] == nil then
			config[setting] = value
		end
	end
end

local function registerModConfig(e)
	local presetOptions = {}
	for file in lfs.dir("Data Files\\MWSE\\config\\KCP Presets\\") do
		common.dbg("Found Preset: " .. file)
		local path = "config\\KCP Presets\\" .. file
		local content = json.loadfile(path)
		if content then
			common.dbg("preset registered: " .. content.presetName)
			table.insert(presetOptions, {label = content.presetName, value = path})
		end
	end
	common.dbg("Registering MCM Menu")
    local menu = mwse.mcm.createTemplate{name = common.modName}
	menu:saveOnClose(confPath, config)
    
	--main settings)
	local xp = menu:createSideBarPage("Система опыта")
	local xpFeatures = xp:createCategory("Настройки")
	local xpRewards = xp:createCategory("Количество получаемого опыта")
	local xpSkill = xp:createCategory("Количество опыта за увеличение навыков")
	local xpLevel = xp:createCategory("Количество опыта, требуемого для повышения уровня")
	local leveling = menu:createSideBarPage("Прокачка")
	local levelFeatures = leveling:createCategory("Настройки")
	local pointAlloc = leveling:createCategory("Распределение и количество очков талантов, характеристик и навыков")
	local cgen = menu:createSideBarPage("Создание персонажа")
	local presets = menu:createSideBarPage("Пресеты")
	
	xpFeatures:createOnOffButton{
		label = "Включить систему опыта?",
		description = "(По умолчанию: ДА) если выключено, это возвращает игру к использованию ванильной системы повышения уровня путем повышения навыков.(Но все равно вы будете получать очки характеристик и очки талантов).",
		variable = mwse.mcm.createTableVariable{
			id = "xpEnabled",
			table = config,
			defaultSetting = true
		}
	}
	xpFeatures:createTextField{
		label = "Максимальный уровень",
		description = "(По умолчанию: 80)  Позволяет установить максимально возможный уровень.",
		numbersOnly = true,
		variable = mwse.mcm.createTableVariable{
			id = "xpLvlCap",
			table = config,
			defaultSetting = 80
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. " установлен на " .. config[self.variable.id])
		end
	
	}
	xpFeatures:createOnOffButton{
		label = "Включить получение опыта за открытие новых локаций?",
		description = "(По умолчанию: ДА). Опыт за посещение локаций и регионов в первый раз.",
		variable = mwse.mcm.createTableVariable{
			id = "cellXPEnabled",
			table = config,
			defaultSetting = true
		}
	}
	xpFeatures:createOnOffButton{
		label = "Включить получение опыта за убийство боссов?",
		description = "(По умолчанию: ДА) Если включено, то за победу над уникальными и сильными боссами, по типу Дагот Ура, Вивека, Пепельных Вампиров, Хирцина и т.д., вы получите очки опыта.",
		variable = mwse.mcm.createTableVariable{
			id = "bossXPEnabled",
			table = config,
			defaultSetting = true
		}
	}
	xpFeatures:createOnOffButton{
		label = "Включить получение опыта за убийство Фаргота?",
		description = "(По умолчанию: ДА) Если включено, то за победу над властелином того самого кольца, вы получите очки опыта.",
		variable = mwse.mcm.createTableVariable{
			id = "fargothXPEnabled",
			table = config,
			defaultSetting = true
		}
	}
	xpFeatures:createOnOffButton{
		label = "Разрешить повышать навыки путем их использования?",
		description = "(По умолчанию: НЕТ) Если включить, то навыки будут повышаться, как в ванили.",
		variable = mwse.mcm.createTableVariable{
			id = "allowExercise",
			table = config,
			defaultSetting = false
		}
	}
	xpFeatures:createOnOffButton{
		label = "Давать опыт за повышение навыков?",
		description = "(По умолчанию: НЕТ) Если включить, то повышение навыков будет так же приносить вам опыт.",
		variable = mwse.mcm.createTableVariable{
			id = "exerciseXPEnabled",
			table = config,
			defaultSetting = false
		}
	}
	xpFeatures:createOnOffButton{
		label = "Разрешить естественный рост навыков?",
		description = "(По умолчанию: НЕТ) Если включить, то шкалы навыков будут повышаться как в ванили, но накопив 100 опыта сам навык не повысится!",
		variable = mwse.mcm.createTableVariable{
			id = "blockSkillRaise",
			table = config,
			defaultSetting = false
		}
	}
	xpFeatures:createOnOffButton{
		label = "Включить опыт за чтение книг навыков?",
		description = "(По умолчанию: НЕТ) Если включить, то за чтение книг навыков вы так же будете получать опыт.",
		variable = mwse.mcm.createTableVariable{
			id = "skillBookXPEnabled",
			table = config,
			defaultSetting = false
		}
	}
	xpFeatures:createOnOffButton{
		label = "Включить опыт за обучение у тренеров навыков?",
		description = "(По умолчанию: НЕТ) Если включить, то за покупку навыков у тренера вы так же будете получать опыт.",
		variable = mwse.mcm.createTableVariable{
			id = "trainerXPEnabled",
			table = config,
			defaultSetting = false
		}
	}
	xpRewards:createTextField{
		label = "Опыт за главные квесты",
		description = "(По умолчанию: 150) Задает количество опыта за выполнение заданий главных квестов.",
		numbersOnly = true,
		variable = mwse.mcm.createTableVariable{
			id = "mainQuestXP",
			table = config,
			defaultSetting = 150
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. " установлен на " .. config[self.variable.id])
		end
	
	}
	xpRewards:createTextField{
		label = "Опыт за гильдейские квесты",
		description = "(По умолчанию: 100) Задает количество опыта за выполнение заданий гильдейских квестов.",
		numbersOnly = true,
		variable = mwse.mcm.createTableVariable{
			id = "guildQuestXP",
			table = config,
			defaultSetting = 100
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. " установлен на " .. config[self.variable.id])
		end
	
	}
	xpRewards:createTextField{
		label = "Опыт за второстепенные квесты",
		description = "(По умолчанию: 50) Задает количество опыта за выполнение второстепенных квестов.",
		numbersOnly = true,
		variable = mwse.mcm.createTableVariable{
			id = "sideQuestXP",
			table = config,
			defaultSetting = 50
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. " установлен на " .. config[self.variable.id])
		end
	
	}
	xpRewards:createTextField{
		label = "Опыт за мелкие задачки",
		description = "(По умолчанию: 10) Задает количество опыта за выполнение мелких задачек.",
		numbersOnly = true,
		variable = mwse.mcm.createTableVariable{
			id = "taskQuestXP",
			table = config,
			defaultSetting = 10
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. " установлен на " .. config[self.variable.id])
		end
	
	}
	xpRewards:createTextField{
		label = "Опыт за открытие новых локаций",
		description = "(По умолчанию: 20) Задает количество опыта за открытие новых локаций.(Требуется включить получение опыта за открытие новых локаций).",
		numbersOnly = true,
		variable = mwse.mcm.createTableVariable{
			id = "cellXP",
			table = config,
			defaultSetting = 20
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. " установлен на " .. config[self.variable.id])
		end
	
	}
	xpRewards:createTextField{
		label = "Опыт за поверженных боссов",
		description = "(По умолчанию: 120) Задает количество опыта за поверженных боссов.(Требуется включить получение опыта за убийство боссов).",
		numbersOnly = true,
		variable = mwse.mcm.createTableVariable{
			id = "bossXP",
			table = config,
			defaultSetting = 120
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. " установлен на " .. config[self.variable.id])
		end
	
	}
	xpRewards:createTextField{
		label = "Опыт за убийство Фаргота",
		description = "(По умолчанию: 200) Задает количество опыта за убийство Властелина Кольца.(Требуется включить получение опыта за убийство Фаргота).",
		numbersOnly = true,
		variable = mwse.mcm.createTableVariable{
			id = "fargothXP",
			table = config,
			defaultSetting = 200
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. " установлен на " .. config[self.variable.id])
		end
	
	}
	xpRewards:createTextField{
		label = "Опыт за прочитаные книги навыков",
		description = "(По умолчанию: 30) Задает количество опыта за прочитаные книги навыков.(Требуется включить опыт за чтение книг навыков).",
		numbersOnly = true,
		variable = mwse.mcm.createTableVariable{
			id = "bkSklXP",
			table = config,
			defaultSetting = 30
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. " установлен на " .. config[self.variable.id])
		end
	
	}
	xpRewards:createTextField{
		label = "Опыт за обучение у тренеров",
		description = "(По умолчанию: 30) Задает количество опыта за обучение у тренеров.(Требуется включить опыт за обучение у тренеров навыков).",
		numbersOnly = true,
		variable = mwse.mcm.createTableVariable{
			id = "trnSklXP",
			table = config,
			defaultSetting = 30
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. " установлен на " .. config[self.variable.id])
		end
	
	}
	xpSkill:createTextField{
		label = "Опыт главных навыков",
		description = "(По умолчанию: 30) Задает количество опыта за повышение главных навыков.",
		numbersOnly = true,
		variable = mwse.mcm.createTableVariable{
			id = "mjrSklXP",
			table = config,
			defaultSetting = 30
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. " установлен на " .. config[self.variable.id])
		end
	
	}
	xpSkill:createTextField{
		label = "Опыт важных навыков",
		description = "(По умолчанию: 30) Задает количество опыта за повышение важных навыков.",
		numbersOnly = true,
		variable = mwse.mcm.createTableVariable{
			id = "mnrSklXP",
			table = config,
			defaultSetting = 30
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. " установлен на " .. config[self.variable.id])
		end
	
	}
	xpSkill:createTextField{
		label = "Опыт маловажных навыков",
		description = "(По умолчанию: 0) Задает количество опыта за повышение маловажных навыков.",
		numbersOnly = true,
		variable = mwse.mcm.createTableVariable{
			id = "mscSklXP",
			table = config,
			defaultSetting = 0
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. " установлен на " .. config[self.variable.id])
		end
	
	}
	xpLevel:createTextField{
		label = "Базовое значение для повышения уровня",
		description = "(По умолчанию: 50) Задает базовое значение для повышения уровня. Количество опыта для повышения уровня вычисляется по формуле = (База + (Компонент уровня * Уровень)).",
		numbersOnly = true,
		variable = mwse.mcm.createTableVariable{
			id = "xpLvlBase",
			table = config,
			defaultSetting = 50
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. " установлено на " .. config[self.variable.id])
		end
	
	}
	xpLevel:createTextField {
		label = "Компонент уровня для повышения уровня",
		description = "(По умолчанию: 150) Задает компонент уровня для повышения уровня. Количество опыта для повышения уровня вычисляется по формуле = (База + (Компонент уровня * Уровень)).",
		numbersOnly = true,
		variable = mwse.mcm:createTableVariable {
			id = "xpLvlMult",
			table = config,
			defaultSetting = 150.0
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. " установлен на " .. config[self.variable.id])
		end
	}
	
	
	levelFeatures:createOnOffButton{
		label = "Включить таланты?",
		description = "(По умолчанию: ДА) Включить или отключить систему талантов.",
		variable = mwse.mcm.createTableVariable{
			id = "prkEnabled",
			table = config,
			defaultSetting = true
		},
		callback = function() event.trigger("KCP:updatePerkState") end,
	}
	levelFeatures:createOnOffButton{
		label = "Требуется ли отдохнуть для повышения уровня?",
		description = "(По умолчанию: ДА) Если эта опция отключена, повышение уровня происходит без необходимости отдыха, за исключением случаев, когда игрок находится в бою.",
		variable = mwse.mcm.createTableVariable{
			id = "lvlRst",
			table = config,
			defaultSetting = true
		},
		callback = function() event.trigger("KCP:checkForLevelUP") end
	}

	pointAlloc:createTextField {
		label = "Количество очков талантов за уровень",
		description = "(По умолчанию: 1) Определаяет, сколько очков талантов получит игрок при повышении уровня.",
		numbersOnly = true,
		variable = mwse.mcm:createTableVariable {
			id = "prkLvlMult",
			table = config,
			defaultSetting = 1
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. " установлено на " .. config[self.variable.id])
		end
	}
	pointAlloc:createTextField {
		label = "Интервал уровней, для получения очков талантов",
		description = "(По умолчанию: 2) Определяет частоту уровней, с которой игрок получает очки талантов..\n1 = каждый уровень\n2 = каждый второй уровень\nи т.д.",
		numbersOnly = true,
		variable = mwse.mcm:createTableVariable {
			id = "prkLvlInterval",
			table = config,
			defaultSetting = 2
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. " установлен на " .. config[self.variable.id])
		end
	}
	pointAlloc:createTextField {
		label = "Количество очков характеристик за уровень",
		description = "(По умолчанию: 10) Определаяет, сколько очков характеристик получит игрок при повышении уровня.",
		numbersOnly = true,
		variable = mwse.mcm:createTableVariable {
			id = "atrLvlMult",
			table = config,
			defaultSetting = 10
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. " установлено на " .. config[self.variable.id])
		end
	}
	pointAlloc:createTextField {
		label = "Интервал уровней, для получения очков характеристик",
		description = "(По умолчанию: 1) Определяет частоту уровней, с которой игрок получает очки характеристик..\n1 = каждый уровень\n2 = каждый второй уровень\nи т.д.",
		numbersOnly = true,
		variable = mwse.mcm:createTableVariable {
			id = "atrLvlInterval",
			table = config,
			defaultSetting = 1
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. " установлен на " .. config[self.variable.id])
		end
	}
	pointAlloc:createTextField{
		label = "Максимум повышения характеристики за уровень",
		description = "(По умолчанию: 5) Определяет, на сколько очков вы можете повысить одну характеристику за уровень.",
		numbersOnly = true,
		variable = mwse.mcm:createTableVariable {
			id = "atrIncMax",
			table = config,
			defaultSetting = 5
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. " установлен на " .. config[self.variable.id])
		end
	
	}
	pointAlloc:createTextField {
		label = "Максимальный уровень характеристик",
		description = "(По умолчанию: 200) Определяет, на сколько можно поднять уровень характеристик. Требуется \"Отключить лимит характеристик\" в настройках MCP(Morrowind Code Patch).",
		numbersOnly = true,
		variable = mwse.mcm:createTableVariable {
			id = "atrLvlCap",
			table = config,
			defaultSetting = 200
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. " установлен на " .. config[self.variable.id])
		end
	}
	pointAlloc:createTextField {
		label = "Количество очков главных навыков за уровень",
		description = "(По умолчанию: 10) Определаяет, сколько очков главных навыков получит игрок при повышении уровня.",
		numbersOnly = true,
		variable = mwse.mcm:createTableVariable {
			id = "mjrLvlMult",
			table = config,
			defaultSetting = 10
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. " установлено на " .. config[self.variable.id])
		end
	}
	pointAlloc:createTextField {
		label = "Интервал уровней, для получения очков главных навыков",
		description = "(По умолчанию: 1) Определяет частоту уровней, с которой игрок получает очки главных навыков..\n1 = каждый уровень\n2 = каждый второй уровень\nи т.д.",
		numbersOnly = true,
		variable = mwse.mcm:createTableVariable {
			id = "mjrLvlInterval",
			table = config,
			defaultSetting = 1
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. " установлен на " .. config[self.variable.id])
		end
	}
	pointAlloc:createTextField{
		label = "Максимум повышения главного навыка за уровень",
		description = "(По умолчанию: 15) Определяет, на сколько очков вы можете повысить один главный навык за уровень.",
		numbersOnly = true,
		variable = mwse.mcm:createTableVariable {
			id = "mjrIncMax",
			table = config,
			defaultSetting = 15
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. " установлен на " .. config[self.variable.id])
		end
	
	}
	pointAlloc:createTextField {
		label = "Максимальный уровень главных навыков",
		description = "(По умолчанию: 200) Определяет, на сколько можно поднять уровень главных навыков. Требуется \"Отключить лимит навыков\" в настройках MCP(Morrowind Code Patch).",
		numbersOnly = true,
		variable = mwse.mcm:createTableVariable {
			id = "mjrLvlCap",
			table = config,
			defaultSetting = 200
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. " установлен на " .. config[self.variable.id])
		end
	}
	pointAlloc:createTextField {
		label = "Количество очков важных навыков за уровень",
		description = "(По умолчанию: 5) Определаяет, сколько очков важных навыков получит игрок при повышении уровня.",
		numbersOnly = true,
		variable = mwse.mcm:createTableVariable {
			id = "mnrLvlMult",
			table = config,
			defaultSetting = 5
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. " установлено на " .. config[self.variable.id])
		end
	}
	pointAlloc:createTextField {
		label = "Интервал уровней, для получения очков важных навыков",
		description = "(По умолчанию: 1) Определяет частоту уровней, с которой игрок получает очки важных навыков..\n1 = каждый уровень\n2 = каждый второй уровень\nи т.д.",
		numbersOnly = true,
		variable = mwse.mcm:createTableVariable {
			id = "mnrLvlInterval",
			table = config,
			defaultSetting = 1
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. " установлен на " .. config[self.variable.id])
		end
	}
	pointAlloc:createTextField{
		label = "Максимум повышения важного навыка за уровень",
		description = "(По умолчанию: 10) Определяет, на сколько очков вы можете повысить один важный навык за уровень.",
		numbersOnly = true,
		variable = mwse.mcm:createTableVariable {
			id = "mnrIncMax",
			table = config,
			defaultSetting = 10
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. " установлен на " .. config[self.variable.id])
		end
	
	}
	pointAlloc:createTextField {
		label = "Максимальный уровень важных навыков",
		description = "(По умолчанию: 200) Определяет, на сколько можно поднять уровень важных навыков. Требуется \"Отключить лимит навыков\" в настройках MCP(Morrowind Code Patch).",
		numbersOnly = true,
		variable = mwse.mcm:createTableVariable {
			id = "mnrLvlCap",
			table = config,
			defaultSetting = 200
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. " установлен на " .. config[self.variable.id])
		end
	}
	pointAlloc:createTextField {
		label = "Количество очков маловажных навыков за уровень",
		description = "(По умолчанию: 5) Определаяет, сколько очков маловажных навыков получит игрок при повышении уровня.",
		numbersOnly = true,
		variable = mwse.mcm:createTableVariable {
			id = "mscLvlMult",
			table = config,
			defaultSetting = 5
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. " установлено на " .. config[self.variable.id])
		end
	}
	pointAlloc:createTextField {
		label = "Интервал уровней, для получения очков маловажных навыков",
		description = "(По умолчанию: 2) Определяет частоту уровней, с которой игрок получает очки маловажных навыков..\n1 = каждый уровень\n2 = каждый второй уровень\nи т.д..",
		numbersOnly = true,
		variable = mwse.mcm:createTableVariable {
			id = "mscLvlInterval",
			table = config,
			defaultSetting = 2
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. " установлен на " .. config[self.variable.id])
		end
	}
	pointAlloc:createTextField{
		label = "Максимум повышения маловажного навыка за уровень",
		description = "(По умолчанию: 5) Определяет, на сколько очков вы можете повысить один маловажный навык за уровень.",
		numbersOnly = true,
		variable = mwse.mcm:createTableVariable {
			id = "mscIncMax",
			table = config,
			defaultSetting = 5
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. " установлен на " .. config[self.variable.id])
		end
	
	}
	pointAlloc:createTextField {
		label = "Максимальный уровень маловажных навыков",
		description = "(По умолчанию: 200) Определяет, на сколько можно поднять уровень маловажных навыков. Требуется \"Отключить лимит навыков\" в настройках MCP(Morrowind Code Patch).",
		numbersOnly = true,
		variable = mwse.mcm:createTableVariable {
			id = "mscLvlCap",
			table = config,
			defaultSetting = 200
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. " установлен на " .. config[self.variable.id])
		end
	}
	
	cgen:createOnOffButton{
		label = "Предоставить возможность настроить характеристики при генерации персонажа?",
		description = "(По умолчанию: ДА) Если включено, дает возможность настроить значение характеристик при генерации персонажа самостоятельно.",
		variable = mwse.mcm.createTableVariable{
			id = "cgenEnabled",
			table = config,
			defaultSetting = true
		},
	}
	
	cgen:createTextField {
		label = "Количество очков характеристик при генерации персонажа для распределения",
		description = "(По умолчанию: 70) Определяет, сколько свободных очков характеристик у вас будет при создании персонажа для распределения.",
		numbersOnly = true,
		variable = mwse.mcm:createTableVariable {
			id = "cgenBudget",
			table = config,
			defaultSetting = 70
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. " установлено на " .. config[self.variable.id])
		end
	}
	
	cgen:createTextField {
		label = "Базовое значение характеристик",
		description = "(По умолчанию: 30) Определяет базовое значение всех характеристик для дальнейшего изменения. Ниже этого значения опустить характеристику нельзя.",
		numbersOnly = true,
		variable = mwse.mcm:createTableVariable {
			id = "cgenBase",
			table = config,
			defaultSetting = 30
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. " установлено на " .. config[self.variable.id])
		end
	}
	cgen:createTextField {
		label = "Максимальное значение характеристик при генерации персонажа",
		description = "(По умолчанию: 50) Максимальное значение характеристик, которое вы можете получить при генерации персонажа. Этот порог не распространяется на расовые бонусы, так что значение может быть выше, благодаря расовым особенностям.",
		numbersOnly = true,
		variable = mwse.mcm:createTableVariable {
			id = "cgenMax",
			table = config,
			defaultSetting = 50
		},
		callback = function(self) 
			config[self.variable.id] = tonumber(config[self.variable.id]) 
			tes3.messageBox(self.label .. " установлено на " .. config[self.variable.id])
		end
	}
	presets:createDropdown{
		label = "Загрузить пресет",
		description = "Загрузить настройки мода из json-файла.",
		options = presetOptions,
		variable = mwse.mcm:createVariable{
			get = (
				function(self)
					return "Choose a Preset"
				end
			),
			set = (function(self, newVal)
				common.dbg("Previous Preset: " .. config.presetName)
				updateConfig(json.loadfile(newVal))
				common.dbg("Loaded Preset: " .. config.presetName)
				tes3.messageBox("Пресет загружен: " .. config.presetName)
				verifySettingsIntegrity()
			end),
		},
	}
	presets:createTextField {
		label = "Сохранить пресет",
		description = "Сохранить настройки мода в json-файл.",
		variable = mwse.mcm:createVariable{
			get = (
				function(self)
					return "Введите название пресета"
				end
			),
			set = (function(self, newVal)
				if (newVal == "default settings") or (newVal == "5e Feats") then
					tes3.messageBox("Cannot Overwrite Base Presets")
					return
				end
				config.presetName = newVal
				common.dbg("Saving Preset: " .. newVal)
				json.savefile("config\\KCP Presets\\".. newVal, config)
				tes3.messageBox("Пресет сохранен: " .. newVal)
			end),
		
		},
	
	}
	mwse.mcm.register(menu)
	common.dbg("Created MCM Menu")
end
common.dbg("registering for mod config")
event.register("modConfigReady", registerModConfig)
common.dbg("registered for mod config")
return config