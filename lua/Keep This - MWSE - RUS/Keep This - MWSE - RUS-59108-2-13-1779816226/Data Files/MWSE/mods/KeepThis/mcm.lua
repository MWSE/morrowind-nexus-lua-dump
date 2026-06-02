local mod = require("KeepThis.config")
local config = mod.config

local function registerModConfig()
	local template = mwse.mcm.createTemplate({
		name = "Придержи это",
		config = config,
		defaultConfig = mod.defaultConfig,
	})

	template:saveOnClose(mod.configPath, config)

	local page = template:createSideBarPage({
		label = "Настройки",
		description = "Этот мод позволяет помечать предметы, чтобы случайно не продать их или не выбросить.",
	})

	page:createYesNoButton({
		label = "Включение мода",
		description = "Включив мод, вы сможете вешать на предметы метку, предотвращающую случайную продажу или выбрасывание. При необходимости, метку можно снять. По умолчанию: Да.",
		variable = mwse.mcm.createTableVariable({
			id = "enabled",
			table = config,
		}),
	})

	page:createYesNoButton({
		label = "Предотвращение выбрасывания помеченных предметов",
		description = "Благодаря этой функции, вы не сможете случайно выбросить помеченные предметы. По умолчанию: Да.",
		variable = mwse.mcm.createTableVariable({
			id = "preventDropping",
			table = config,
		}),
	})

	page:createYesNoButton({
		label = "Предотвращение продажи помеченных предметов",
		description = "Благодаря этой функции, вы не сможете случайно продать помеченные предметы. По умолчанию: Да.",
		variable = mwse.mcm.createTableVariable({
			id = "preventSelling",
			table = config,
		}),
	})

	page:createKeyBinder({
		label = "Кнопка для пометки",
		description = "Наведя курсор на предмет и нажав эту кнопку, вы пометите его, или снимите ранее поставленную метку. По умолчанию: F3.",
		keybindName = "mark/unmark item",
		allowCombinations = false,
		allowMouse = false,
		configKey = "markKeyCombo",
	})

	page:createYesNoButton({
		label = "Показ сообщений",
		description = "Эта функция регулирует, будете ли вы получать всплывающие сообщения или нет. По умолчанию: Да.",
		variable = mwse.mcm.createTableVariable({
			id = "showMessages",
			table = config,
		}),
	})

	page:createYesNoButton({
		label = "Запись логов",
		description = "Данная функция позволяет записывать логи в MWSE.log. Удобно при тестировании. По умолчанию: Нет.",
		variable = mwse.mcm.createTableVariable({
			id = "debugLog",
			table = config,
		}),
	})

	page:createButton({
		label = "Удаление всех меток",
		buttonText = "Удалить",
		description = "Снимает все ранее выставленные метки с предметов.",
		callback = function()
			if tes3.player then
				tes3.player.data["KeepThis_markedItems"] = {}
				tes3.messageBox("Все метки сняты.")
			else
				tes3.messageBox("У вас нет выставленных меток.")
			end
		end,
	})

	template:register()
end

event.register(tes3.event.modConfigReady, registerModConfig)