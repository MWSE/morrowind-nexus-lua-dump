local text = include("q.PredatorBeastRaces.MCM.mcmText")
local config = include("q.PredatorBeastRaces.config")
local settingsTable = config


local function newline(component)
	component:createInfo{ text = "\n" }
end
local function postFormat(self)
	--self.elements.outerContainer.borderAllSides = self.indent
	--self.elements.outerContainer.alignY = 1.0
	--self.elements.outerContainer.layoutHeightFraction = 1.0
	self.elements.info.layoutOriginFractionX = 0.5
end
local function addSideBar(component)
	component.sidebar:createInfo{
		text = text.sideBarDefault,
		postCreate = postFormat
	}
	component.sidebar:createHyperLink{
		text = "Сделано Qwerty",
		exec = "start https://www.nexusmods.com/users/57788911?tab=user+files",
		postCreate = postFormat,
	}
	component.sidebar:createHyperLink{
		text = "\nДополнительное кодирование от C3pa",
		exec = "start https://www.nexusmods.com/users/37172285?tab=user+files",
		postCreate = postFormat
	}
end
local function createTableVar(id, restart)
	return mwse.mcm.createTableVariable{ id = id, table = settingsTable, restartRequired = (restart or false) }
end


local template = mwse.mcm.createTemplate{
	name = "Хищные зверорасы",
	headerImagePath = "MWSE/mods/q/PredatorBeastRaces/MCM/Title.tga"
}


template.onClose = function()
	mwse.saveConfig("Predator Beast Races", settingsTable)
	local eventData = table.copy(settingsTable)
	event.trigger("PBR_updateSettings", eventData)
end


do	-- Settings
	do	-- Main settings page
		local page = template:createSideBarPage{ label = "Settings" }
		addSideBar(page)


		page:createCategory{ label = "Настройки когтей" }
		page:createInfo{ text = text.damageFormula }

		page:createSlider{
			label = "Базовый урон когтями = %s",
			description = text.clawBaseDamageDescription,
			min = 1,
			max = 50,
			step = 1,
			jump = 10,
			variable = createTableVar("clawBaseDamage"),
		}

		newline(page)
		page:createSlider{
			label = "Масштабирующий фактор рукопашного боя = %s",
			description = text.clawH2hModDescription,
			min = 1,
			max = 30,
			step = 1,
			jump = 10,
			variable = createTableVar("clawH2hMod"),
		}

		newline(page)
		page:createSlider{
			label = "Масштабирующий фактор силы = %s",
			description = text.clawStrengthModDescription,
			min = 1,
			max = 30,
			step = 1,
			jump = 10,
			variable = createTableVar("clawStrengthMod"),
		}

		newline(page)
		page:createYesNoButton{
			label = "Должен ли урон когтями масштабироваться со сложностью?",
			variable = createTableVar("clawApplyDifficulty"),
			description = text.clawApplyDifficultyDecription
		}


		page:createCategory{ label = "\nНастройки активных способностей\n" }

		page:createYesNoButton{
			label = "Показать сообщения обратной связи?",
			variable = createTableVar("showMessages"),
			description = text.messagesDescription
		}

		newline(page)
		page:createKeyBinder{
			label = "Горячая клавиша способности Нюх",
			description = text.scentHotkeyDescription,
			allowCombinations = false,
			variable = createTableVar("scentKey", true),
		}

		newline(page)
		page:createKeyBinder{
			label = "Горячая клавиша для способности Ночной глаз",
			description = text.visionHotkeyDescription,
			allowCombinations = false,
			variable = createTableVar("visionKey", true),
		}

		newline(page)
		page:createSlider{
			label = "Расход запаса сил для Нюха в секунду = %s",
			description = text.scentFatigueConsumption,
			min = 0,
			max = 15,
			step = 1,
			jump = 1,
			variable = createTableVar("scentFatigueCost"),
		}

		newline(page)
		page:createSlider{
			label = "Расход запаса сил для Ночного глаза в секунду = %s",
			description = text.lowFatigue,
			min = 0,
			max = 15,
			step = 1,
			jump = 1,
			variable = createTableVar("visionFatigueCost"),
		}

		newline(page)
		page:createSlider{
			label = "Низкий процент запаса сил  = %s",
			description = text.lowFatigue,
			min = 0,
			max = 100,
			step = 1,
			jump = 10,
			variable = createTableVar("lowFatigue"),
		}

	end
end

mwse.mcm.register(template)
