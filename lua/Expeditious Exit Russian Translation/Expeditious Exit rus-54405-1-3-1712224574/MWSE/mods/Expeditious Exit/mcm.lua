
local config = require("Expeditious Exit.config")

--- Setup MCM.
local function registerModConfig()
	local template = mwse.mcm.createTemplate({ name = "Быстрый выход из игры" })
	template:saveOnClose("Expeditious Exit", config)

	local page = template:createSideBarPage()
	page.sidebar:createInfo({
		text = "Быстрый выход из игры версия 1.3\nот NullCascade",
	})

	page:createOnOffButton({
		label = "Показывать окно подтверждения?",
		description = "Если включено, при нажатии кнопки выход будет отображаться стандартное окно подтверждения с вопросом, \"хотите ли вы выйти из игры?\"",
		variable = mwse.mcm.createTableVariable({ id = "showMenuOnExit", table = config }),
	})

	page:createOnOffButton({
		label = "Разрешить alt-F4?",
		description = "Если включено, комбинация alt-F4 закроет игру без запроса. Это не обязательно потребуется всем пользователям.",
		variable = mwse.mcm.createTableVariable({ id = "allowAltF4", table = config }),
	})

	page:createOnOffButton({
		label = "Использовать \"завершение процеса\"?",
		description = "При использовании сторонних перехватчиков, таких как DXVK, обычный метод закрытия может не сработать. Завершение процеса более надежный способ.",
		variable = mwse.mcm.createTableVariable({ id = "useTaskKill", table = config }),
	})

	template:register()
end
event.register("modConfigReady", registerModConfig)
