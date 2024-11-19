local config = require("Skillful Sneaking.config")

local function registerModConfig()

	local template = mwse.mcm.createTemplate({ name = ("Мастерство скрытности") })
	template:saveOnClose("Skillful Sneaking", config)

	local page = template:createSideBarPage({ label = "Sidebar Page Label" })
	page.sidebar:createInfo({ text = ("Мастерство скрытности") .. " " .. ("1.1.0") .. "\n" .. ("1.1.0") .. "\n\n" .. ("Позволяет прыгать в режиме скрытности и настраивать скорость передвижения в зависимости от уровня навыка.") })

	page:createOnOffButton({
		label = ("Включить мод"),
		description = ("Включает\\Выключает мод"),
		variable = mwse.mcm.createTableVariable({ id = "enabled", table = config }),
	})

	--Sneak Speed Cap
	page:createSlider({
		label = "Макс. скорость при скрытности",
		description = "Меняется в процентном соотношении от обычной скорости бега. Значение 100 позволяет подкрадываться со скоростью стандартного бега. По умолчанию - 70.",
		min = 0,
		max = 100,
		step = 1,
		jump = 20,
		variable = mwse.mcm.createTableVariable({ id = "speedCap", table = config }),
	})

	--Jump Height Cap
	page:createSlider({
		label = "Макс. высота прыжка при скрытности",
		description = "Меняется в процентном соотношении от обычной высоты прыжка. Значение 100 позволяет совершать скрытные прыжки на высоту стандартного прыжка. По умолчанию - 80.",
		min = 0,
		max = 100,
		step = 1,
		jump = 20,
		variable = mwse.mcm.createTableVariable({ id = "jumpCap", table = config }),
	})

	--Skill Point Scaling
	page:createSlider({
		label = "Зависимость от уровня навыка",
		description = "Изменение скорости подкрадывания относительно уровня навыка скрытности. Одно очко навыка / 100 пунктов скорости передвижения. По умолчанию 300 (3.0/очко навыка).",
		min = 0,
		max = 500,
		step = 1,
		jump = 50,
		variable = mwse.mcm.createTableVariable({ id = "skillScaling", table = config }),
	})

	template:register()
end

event.register("modConfigReady", registerModConfig)