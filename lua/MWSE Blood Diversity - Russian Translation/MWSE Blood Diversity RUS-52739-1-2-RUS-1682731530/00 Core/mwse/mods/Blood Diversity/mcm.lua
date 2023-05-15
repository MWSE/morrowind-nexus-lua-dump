local this = {}

this.config = mwse.loadConfig("Blood Diversity") or {
	modEnabled = true,
	vampBlood = true,
	ghostBlood = true,
}

local contents

local function createDescription(parent, text)
	parent:destroyChildren()

	local label = parent:createLabel{text=text}
	label.heightProportional = 1.0
	label.widthProportional = 1.0
	label.wrapText = true

	parent:getTopLevelParent():updateLayout()
end


local function createWebsiteLink(parent, name, exec)
	local link = parent:createTextSelect{text=name}
	link.borderLeft = 14

	link.color = tes3ui.getPalette("link_color")
	link.widget.idle = tes3ui.getPalette("link_color")
	link.widget.over = tes3ui.getPalette("link_over_color")
	link.widget.pressed = tes3ui.getPalette("link_pressed_color")

	link:register("mouseClick", function (e)
		tes3.messageBox{
			message = "Открыть браузер?",
			buttons = {"Да", "нет"},
			callback = function (e)
				if e.button == 0 then
					os.execute(exec)
				end
			end
		}
	end)

	return link
end


local function createCredits(parent)
	parent:destroyChildren()

	local text = "Blood Diversity, Создано Anumaril21\n\nДобро пожаловать в меню конфигурации! Здесь вы можете настроить, какие функции мода будут включены или выключены.\n\nНаведите курсор на отдельные опции для получения дополнительной информации.\n\nBlood Diversity предоставляет новые типы крови для существ Morrowind, Tribunal, Bloodmoon, официальных плагинов и различных модов, основанных на реальном мире и лоре.\n\nЭтот мод стал возможен только благодаря моддерам, перечисленным ниже. Перейдите по указанным ссылкам, чтобы открыть для себя их великолепный контент\n\nАвторы:"
	local label = parent:createLabel{text=text}
	label.widthProportional = 1.0
	label.borderAllSides = 3
	label.borderBottom = 6
	label.wrapText = true

	local contributors = {
		[1] = {"SpaceDevo", "start https://www.nexusmods.com/morrowind/users/35003500"},
		[2] = {"Reizeron (R-Zero)", "start https://www.nexusmods.com/morrowind/users/3241081"},
		[3] = {"Nullcascade", "start https://www.nexusmods.com/morrowind/users/26153919"},
	}

	for i=1, #contributors do
		local name, url = unpack(contributors[i])
		createWebsiteLink(parent, name, url)
	end

	parent:getTopLevelParent():updateLayout()
end


local function asOnOff(bool)
	return bool and "On" or "Off"
end


local function createFeature(t)
	local block = t.parent:createBlock{}
	block.flowDirection = "left_to_right"
	block.widthProportional = 1.0
	block.autoHeight = true

	local state = this.config[t.key]
	local button = block:createButton{text=asOnOff(state)}
	button:register("mouseClick", function (e)
		this.config[t.key] = not this.config[t.key]
		e.source.text = asOnOff(this.config[t.key])
	end)

	local label = block:createLabel{text=t.label}
	label.borderAllSides = 3

	if t.text and t.textParent then
		label:register("mouseOver", function () createDescription(t.textParent, t.text) end)
		label:register("mouseLeave", function () createCredits(t.textParent) end)
	end

	return button
end

local function createPreferences()
	contents:destroyChildren()
	contents.flowDirection = "left_to_right"

	local left = contents:createBlock{}
	left.flowDirection = "top_to_bottom"
	left.widthProportional = 1.0
	left.heightProportional = 1.0
	left.paddingAllSides = 6

	local right = contents:createThinBorder{}
	right.flowDirection = "top_to_bottom"
	right.widthProportional = 1.0
	right.heightProportional = 1.0
	right.paddingAllSides = 6

	createFeature{
		parent = left,
		key = "modEnabled",
		label = "Включить Blood Diversity",
		textParent = right,
		text = "Включить Blood Diversity\n\nЭтот параметр определяет, включен ли мод и изменяются ли типы крови врагов.\n\nПо-умолчанию: Вкл",
	}
	createFeature{
		parent = left,
		key = "vampBlood",
		label = "Изменить Вампирскую кровь",
		textParent = right,
		text = "Изменить Вампирскую кровь\n\nЭтот параметр определяет, будет ли изменена кровь вампиров со стандартной на пыль, в соответствии с предметом Прах вампира.\n\nПо-умолчанию: Вкл",
	}
	createFeature{
		parent = left,
		key = "ghostBlood",
		label = "Изменить кровь Призрака",
		textParent = right,
		text = "Изменить кровь Призрака\n\nЭтот параметр определяет, будет ли кровь NPC-призраков изменена со стандартной на эктоплазменную, учитывая предмет Эктоплазма.\n\nПо-умолчанию: Вкл",
	}

	createCredits(right)

	contents:getTopLevelParent():updateLayout()
end

-- Events
function this.onCreate(parent)
	local tabs = parent:createBlock{}
	tabs.autoWidth, tabs.autoHeight = true, true

	local preferences

	preferences = tabs:createButton{text="Preferences"}
	preferences:register("mouseClick", function (e)
		if preferences.widget.state ~= 1 then
			preferences.widget.state = 1
			createPreferences(contents)
		end
	end)
	
	-- contents container
	contents = parent:createThinBorder{}
	contents.heightProportional = 1.0
	contents.widthProportional = 1.0
	contents.paddingAllSides = 6

	-- default to preferences
	preferences.widget.state = 1
	createPreferences()
end

function this.onClose(parent)
	mwse.saveConfig("Blood Diversity", this.config)
end


event.register("modConfigReady", function (e)
	mwse.registerModConfig("Blood Diversity", this)
end)
------------


return this