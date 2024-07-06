local seph = require("seph")

local mcm = seph.Mcm()

mcm.showEnabledButton = false

function mcm:onCreate()
    local config = self.mod.config
	local viewportWidth, viewportHeight = tes3ui.getViewportSize()

	local function highlight(elementName)
		local hud = self.mod.modules.hud
		if hud.elements[elementName] then
			self.mod.modules.highlighter:setHighlight(hud.elements[elementName])
		else
			self.mod.modules.highlighter:removeHighlight()
		end
		local menuMulti = tes3ui.findMenu(hud.uuids.menuMulti)
		if menuMulti then
			menuMulti:updateLayout()
		end
	end

	local function onCallback(component)
		self.mod.modules.hud:update()
		if component and component.elementName then
			highlight(component.elementName)
		end
	end

	local function onMouseOver(eventData)
		local component = eventData.component
		if component and component.elementName then
			highlight(component.elementName)
		end
	end

	local function booleanToReadableString(boolean)
		if boolean then
			return "Да"
		else
			return "Нет"
		end
	end

	local function flowDirectionToReadableString(flowDirection)
		if flowDirection:lower() == "left_to_right" then
			return "Horizontal"
		elseif flowDirection:lower() == "top_to_bottom" then
			return "Vertical"
		else
			return "None"
		end
	end

	local function updatePositionValueLabel(component)
		local value = ""
		if component.elements.slider then
			value = (component.elements.slider.widget.current + component.min) / 10.0
		end
        local text = ""
		if string.find(component.label, "%s", 1, true) then
			text = string.format(component.label, value)
		else
			text = component.label .. ": " .. value
		end
		component.elements.label.text = text
	end

	local function createSideBarPage(label)
		return self.template:createSideBarPage{
			label = label,
			description = "Наведите курсор на параметр для получения дополнительной информации.",
			postCreate =
				function()
					self.mod.modules.highlighter:removeHighlight()
				end
		}
	end

	local function createVisibleButton(parent, elementName)
		return parent:createYesNoButton{
			label = "Отображать?",
			description = string.format("Включает отображение данного элемента на экране.\n\nПо умолчанию: %s", booleanToReadableString(config.default[elementName].visible)),
			variable = mwse.mcm.createTableVariable{id = "visible", table = config.current[elementName], restartRequired = false},
			callback = onCallback,
			elementName = elementName
		}
	end

	local function createHorizontalPositionSlider(parent, elementName)
		return parent:createSlider{
			label = "Горизонтальная позиция: %s%%",
			description = string.format("Задает горизонтальное положение элемента. При значении 100%% он будет выровнен по правому краю экрана.\n\nПо умолчанию: %.1f", config.default[elementName].position.x / 10.0),
			min = 0, max = 1000, step = 1, jump = 10,
			variable = mwse.mcm.createTableVariable{id = "x", table = config.current[elementName].position, restartRequired = false},
			callback = onCallback,
			updateValueLabel = updatePositionValueLabel,
			elementName = elementName
		}
	end

	local function createVerticalPositionSlider(parent, elementName)
		return parent:createSlider{
			label = "Вертикальная позиция: %s%%",
			description = string.format("Задает вертикальное положение элемента. При значении 100%% он будет выровнен по нижнему краю экрана.\n\nПо умолчанию: %.1f", config.default[elementName].position.y / 10.0),
			min = 0, max = 1000, step = 1, jump = 10,
			variable = mwse.mcm.createTableVariable{id = "y", table = config.current[elementName].position, restartRequired = false},
			callback = onCallback,
			updateValueLabel = updatePositionValueLabel,
			elementName = elementName
		}
	end

	local function createWidthSlider(parent, elementName)
		return parent:createSlider{
			label = "Ширина",
			description = string.format("Задает ширину данного элемента.\n\nПо умолчанию: %d", config.default[elementName].width),
			min = 0, max = viewportWidth, step = 1, jump = 10,
			variable = mwse.mcm.createTableVariable{id = "width", table = config.current[elementName], restartRequired = false},
			callback = onCallback,
			elementName = elementName
		}
	end

	local function createHeightSlider(parent, elementName)
		return parent:createSlider{
			label = "Высота",
			description = string.format("Задает высоту данного элемента.\n\nПо умолчанию: %d", config.default[elementName].height),
			min = 0, max = viewportHeight, step = 1, jump = 10,
			variable = mwse.mcm.createTableVariable{id = "height", table = config.current[elementName], restartRequired = false},
			callback = onCallback,
			elementName = elementName
		}
	end

	local function createLayoutDropdown(parent, elementName)
		return parent:createDropdown{
			label = "Ориентация",
			description = string.format("Задает ориентацию панели. Значки магических эффектов будут располагаться либо по горизонтали, либо по вертикали.\n\nПо умолчанию: %s", flowDirectionToReadableString(config.default[elementName].layout)),
			options = {
				{label = "Горизонтальная", value = "left_to_right"},
				{label = "Вертикальная", value = "top_to_bottom"}
			},
			variable = mwse.mcm:createTableVariable{id = "layout", table = config.current[elementName], restartRequired = false},
			callback = onCallback,
			elementName = elementName
		}
	end

	local function createAlphaSlider(parent, elementName)
		return parent:createSlider{
			label = "Непрозрачность: %s%%",
			description = string.format("Устанавливает Непрозрачность индикатора. При значении 100%% он будет полностью непрозрачным.\n\nПо умолчанию: %d", config.default[elementName].alpha),
			min = 1, max = 100, step = 1, jump = 10,
			variable = mwse.mcm.createTableVariable{id = "alpha", table = config.current[elementName], restartRequired = false},
			callback = onCallback,
			elementName = elementName
		}
	end

	local function createColorSliders(parent, elementName)
        return{
            parent:createSlider{
                label = "Красный: %s%%",
                description = string.format("Задает уровень краснного цвета в элементе.\n\nПо умолчанию: %d", config.default[elementName].color.r),
                min = 0, max = 100, step = 1, jump = 10,
                variable = mwse.mcm.createTableVariable{id = "r", table = config.current[elementName].color, restartRequired = false},
                callback = onCallback,
				elementName = elementName
            },
            parent:createSlider{
                label = "Зеленый: %s%%",
                description = string.format("Задает уровень зеленого цвета в элементе.\n\nПо умолчанию: %d", config.default[elementName].color.g),
                min = 0, max = 100, step = 1, jump = 10,
                variable = mwse.mcm.createTableVariable{id = "g", table = config.current[elementName].color, restartRequired = false},
                callback = onCallback,
				elementName = elementName
            },
            parent:createSlider{
                label = "Синий: %s%%",
                description = string.format("Задает уровень синего цвета в элементе.\n\nПо умолчанию: %d", config.default[elementName].color.b),
                min = 0, max = 100, step = 1, jump = 10,
                variable = mwse.mcm.createTableVariable{id = "b", table = config.current[elementName].color, restartRequired = false},
                callback = onCallback,
				elementName = elementName
            }
        }
	end

	local function createModCategories(parent)
		for modElementName, modElementConfig in pairs(config.current.mods) do
			local modCategory = parent:createCategory(modElementConfig.name)
			if modElementConfig.options.visibility then
				modCategory:createYesNoButton{
					label = "Отображать?",
					description = string.format("Включает\\выключает отображение данного элемента на экране.\n\nПо умолчанию: %s", booleanToReadableString(config.current.mods[modElementName].defaults.visible)),
					variable = mwse.mcm.createTableVariable{id = "visible", table = config.current.mods[modElementName], restartRequired = false},
					callback = onCallback,
					elementName = modElementName
				}
			end
			if modElementConfig.options.position then
				modCategory:createSlider{
					label = "Горизонтальная позиция: %s%%",
					description = string.format("Задает горизонтальное положение элемента. При значении 100%% он будет выровнен по правому краю экрана.\n\nПо умолчанию: %.1f", config.current.mods[modElementName].defaults.positionX / 10.0),
					min = 0, max = 1000, step = 1, jump = 10,
					variable = mwse.mcm.createTableVariable{id = "positionX", table = config.current.mods[modElementName], restartRequired = false},
					callback = onCallback,
					updateValueLabel = updatePositionValueLabel,
					elementName = modElementName
				}
				modCategory:createSlider{
					label = "Вертикальная позиция: %s%%",
					description = string.format("Задает вертикальное положение элемента. При значении 100%% он будет выровнен по нижнему краю экрана.\n\nПо умолчанию: %.1f", config.current.mods[modElementName].defaults.positionY / 10.0),
					min = 0, max = 1000, step = 1, jump = 10,
					variable = mwse.mcm.createTableVariable{id = "positionY", table = config.current.mods[modElementName], restartRequired = false},
					callback = onCallback,
					updateValueLabel = updatePositionValueLabel,
					elementName = modElementName
				}
			end
			if modElementConfig.options.size then
				modCategory:createSlider{
					label = "Ширина",
					description = string.format("Задает ширину данного элемента.\n\nПо умолчанию: %d", config.current.mods[modElementName].defaults.width),
					min = 0, max = viewportWidth, step = 1, jump = 10,
					variable = mwse.mcm.createTableVariable{id = "width", table = config.current.mods[modElementName], restartRequired = false},
					callback = onCallback,
					elementName = modElementName
				}
				modCategory:createSlider{
					label = "Высота",
					description = string.format("Задает высоту данного элемента.\n\nПо умолчанию: %d", config.current.mods[modElementName].defaults.height),
					min = 0, max = viewportHeight, step = 1, jump = 10,
					variable = mwse.mcm.createTableVariable{id = "height", table = config.current.mods[modElementName], restartRequired = false},
					callback = onCallback,
					elementName = modElementName
				}
			end
			self.logger:debug(string.format("Created mod category '%s'", modElementConfig.name))
		end
	end

	event.register("MCM:MouseOver", onMouseOver)

    local generalPage = createSideBarPage("Общие")
	generalPage:createSlider{
		label = "Мертвая зона",
		description = string.format("Эта опция определяет мертвую зону, которая не позволяет элементам интерфейса располагаться слишком близко к краям экрана.\n\nПо умолчанию: %d", config.default.deadzone),
		min = 0, max = 100, step = 1, jump = 10,
		variable = mwse.mcm.createTableVariable{id = "deadzone", table = config.current, restartRequired = false},
		callback = onCallback
	}

	local highlightCategory = generalPage:createCategory("Индикатор активного элемента")
	highlightCategory.description = "Выделяет элемент интрефейса, редактируемый в данный момент. Виден только в меню конфигурации, при наведении курсора на различные настройки."
	createVisibleButton(highlightCategory, "highlight")
	createColorSliders(highlightCategory, "highlight")
	createAlphaSlider(highlightCategory, "highlight")

	local barPage = createSideBarPage("Шкала")

	local healthBarCategory = barPage:createCategory("Шкала Здоровья")
	healthBarCategory.description = "Индикатор здоровья персонажа"
	createVisibleButton(healthBarCategory, "healthBar")
	healthBarCategory:createYesNoButton{
		label = "Показать значения?",
		description = string.format("Определяет, будут ли отображаться текущие и максимальные значения на шкале здоровья.\n\nПо умолчанию: %s", booleanToReadableString(config.default.healthBar.showValues)),
		variable = mwse.mcm.createTableVariable{id = "showValues", table = config.current.healthBar, restartRequired = false},
		callback = onCallback,
		elementName = "healthBar"
	}
	createWidthSlider(healthBarCategory, "healthBar")
	createHeightSlider(healthBarCategory, "healthBar")
	createHorizontalPositionSlider(healthBarCategory, "healthBar")
	createVerticalPositionSlider(healthBarCategory, "healthBar")
	createColorSliders(healthBarCategory, "healthBar")
	-- createAlphaSlider(healthBarCategory, "healthBar")

	local magicBarCategory = barPage:createCategory("Шкала Магии")
	magicBarCategory.description = "Индикатор магии персонажа"
	createVisibleButton(magicBarCategory, "magicBar")
	magicBarCategory:createYesNoButton{
		label = "Показать значения?",
		description = string.format("Определяет, будут ли отображаться текущие и максимальные значения на шкале магии.\n\nПо умолчанию: %s", booleanToReadableString(config.default.magicBar.showValues)),
		variable = mwse.mcm.createTableVariable{id = "showValues", table = config.current.magicBar, restartRequired = false},
		callback = onCallback,
		elementName = "magicBar"
	}
	createWidthSlider(magicBarCategory, "magicBar")
	createHeightSlider(magicBarCategory, "magicBar")
	createHorizontalPositionSlider(magicBarCategory, "magicBar")
	createVerticalPositionSlider(magicBarCategory, "magicBar")
	createColorSliders(magicBarCategory, "magicBar")
	-- createAlphaSlider(magicBarCategory, "magicBar")

	local fatigueBarCategory = barPage:createCategory("Шкала Усталости")
	fatigueBarCategory.description = "Индикатор усталости персонажа"
	createVisibleButton(fatigueBarCategory, "fatigueBar")
	fatigueBarCategory:createYesNoButton{
		label = "Показать значения?",
		description = string.format("Определяет, будут ли отображаться текущие и максимальные значения на шкале усталости.\n\nПо умолчанию: %s", booleanToReadableString(config.default.fatigueBar.showValues)),
		variable = mwse.mcm.createTableVariable{id = "showValues", table = config.current.fatigueBar, restartRequired = false},
		callback = onCallback,
		elementName = "fatigueBar"
	}
	createWidthSlider(fatigueBarCategory, "fatigueBar")
	createHeightSlider(fatigueBarCategory, "fatigueBar")
	createHorizontalPositionSlider(fatigueBarCategory, "fatigueBar")
	createVerticalPositionSlider(fatigueBarCategory, "fatigueBar")
	createColorSliders(fatigueBarCategory, "fatigueBar")
	-- createAlphaSlider(fatigueBarCategory, "fatigueBar")

	local npcHealthBarCategory = barPage:createCategory("Шкала Здоровья NPC")
	npcHealthBarCategory.description = "Это индикатор здоровья враждебного NPC, который появляется при нанесении ему урона."
	createVisibleButton(npcHealthBarCategory, "npcHealthBar")
	createWidthSlider(npcHealthBarCategory, "npcHealthBar")
	createHeightSlider(npcHealthBarCategory, "npcHealthBar")
	createHorizontalPositionSlider(npcHealthBarCategory, "npcHealthBar")
	createVerticalPositionSlider(npcHealthBarCategory, "npcHealthBar")

	local equippedPage = createSideBarPage("Экипировка")

	local equippedWeaponCategory = equippedPage:createCategory("Оружие")
	equippedWeaponCategory.description = "Значок экипированного оружия."
	createVisibleButton(equippedWeaponCategory, "equippedWeapon")
	createHorizontalPositionSlider(equippedWeaponCategory, "equippedWeapon")
	createVerticalPositionSlider(equippedWeaponCategory, "equippedWeapon")
	-- createAlphaSlider(equippedWeaponCategory, "equippedWeapon")

	local equippedMagicCategory = equippedPage:createCategory("Магия")
	equippedMagicCategory.description = "Значок выбранного заклинания."
	createVisibleButton(equippedMagicCategory, "equippedMagic")
	createHorizontalPositionSlider(equippedMagicCategory, "equippedMagic")
	createVerticalPositionSlider(equippedMagicCategory, "equippedMagic")
	-- createAlphaSlider(equippedMagicCategory, "equippedMagic")

	local equippedNotificationCategory = equippedPage:createCategory("Уведомление")
	equippedNotificationCategory.description = "Текстовое уведомление с названием оружия или магии, которое появляется при выборе или смене экипировки."
	createVisibleButton(equippedNotificationCategory, "equippedNotification")
	createHorizontalPositionSlider(equippedNotificationCategory, "equippedNotification")
	createVerticalPositionSlider(equippedNotificationCategory, "equippedNotification")

	local mapPage = createSideBarPage("Карта")

	local mapCategory = mapPage:createCategory("Карта")
	mapCategory.description = "Миникарта."
	createVisibleButton(mapCategory, "map")
	createWidthSlider(mapCategory, "map")
	createHeightSlider(mapCategory, "map")
	createHorizontalPositionSlider(mapCategory, "map")
	createVerticalPositionSlider(mapCategory, "map")
	-- createAlphaSlider(mapCategory, "map")

	local mapNotificationCategory = mapPage:createCategory("Уведомление")
	mapNotificationCategory.description = "Текстовое уведомление с названием местности, которое появляется при входе в новую область/ячейку."
	createVisibleButton(mapNotificationCategory, "mapNotification")
	createHorizontalPositionSlider(mapNotificationCategory, "mapNotification")
	createVerticalPositionSlider(mapNotificationCategory, "mapNotification")

	local otherPage = createSideBarPage("Другие")

	local activeMagicEffectsCategory = otherPage:createCategory("Панель активных магических эффектов")
	activeMagicEffectsCategory.description = "Магические эффекты, которые в данный момент действуют на персонажа. Отображаются постоянные и временные эффекты."
	createVisibleButton(activeMagicEffectsCategory, "activeMagicEffects")
	createLayoutDropdown(activeMagicEffectsCategory, "activeMagicEffects")
	createHorizontalPositionSlider(activeMagicEffectsCategory, "activeMagicEffects")
	createVerticalPositionSlider(activeMagicEffectsCategory, "activeMagicEffects")

	local sneakIndicatorCategory = otherPage:createCategory("Индикатор скрытности")
	sneakIndicatorCategory.description = "Индикатор, который появляется, когда вы крадетесь и прячетесь."
	createVisibleButton(sneakIndicatorCategory, "sneakIndicator")
	createHorizontalPositionSlider(sneakIndicatorCategory, "sneakIndicator")
	createVerticalPositionSlider(sneakIndicatorCategory, "sneakIndicator")
	-- createAlphaSlider(sneakIndicatorCategory, "sneakIndicator")

	local menuNotifyCategory = otherPage:createCategory("Сообщения")
	menuNotifyCategory.description = "Сообщения, которые появляются по разным причинам, например, при повышении уровня навыков, совершении преступлений, убийстве важных NPC и так далее."
	createVisibleButton(menuNotifyCategory, "menuNotify")
	menuNotifyCategory:createYesNoButton{
		label = "Инвертировать?",
		description = string.format("Определяет расположение и направление смещения сообщений. Если установлено значение \"да\", сообщения будут отображаться в верхней части экрана и смещаться сверху вниз. Это также изменяет поведение параметра \"Смещение по вертикали\".\n\nПо умолчанию: %s", booleanToReadableString(config.default.menuNotify.flipped)),
		variable = mwse.mcm.createTableVariable{id = "flipped", table = config.current.menuNotify, restartRequired = false}
	}
	createHorizontalPositionSlider(menuNotifyCategory, "menuNotify")
	menuNotifyCategory:createSlider{
		label = "Vertical offset",
		description = string.format("Устанавливает вертикальное смещение для этого элемента. Чем больше это значение, тем выше будут появляться сообщения. Если включить инвертирование, увеличение этого значения приведет к тому, что сообщения будут отображаться ниже.\n\nПо умолчанию: %d", config.default.menuNotify.position.y),
		min = -viewportHeight, max = viewportHeight, step = 1, jump = 10,
		variable = mwse.mcm.createTableVariable{id = "y", table = config.current.menuNotify.position, restartRequired = false},
		callback = onCallback,
		elementName = "menuNotify"
	}

	local menuSwimFillBarCategory = otherPage:createCategory("Шкала Дыхания")
	menuSwimFillBarCategory.description = "Индикатор дыхания, который появляется, когда персонаж находится под водой."
	createVisibleButton(menuSwimFillBarCategory, "menuSwimFillBar")
	createHorizontalPositionSlider(menuSwimFillBarCategory, "menuSwimFillBar")
	createVerticalPositionSlider(menuSwimFillBarCategory, "menuSwimFillBar")

	local modsPage = createSideBarPage("Модификации")
	modsPage:createYesNoButton{
		label = "Удалять автоматически настройки неактивных модов?",
		description = string.format("Эта опция определяет, будут ли храниться настройки сторонних модификаций в файле конфигурации Настройщика интерфейса,  после их удаления. Если установленно значение \"Нет\" настройки будут сохранены.\n\nПо умолчанию: %s", booleanToReadableString(config.default.deleteInvalidModConfigs)),
		variable = mwse.mcm.createTableVariable{id = "deleteInvalidModConfigs", table = config.current, restartRequired = false}
	}
    modsPage.postCreate =
        function(component)
            component.postCreate = nil
			self.mod.config:cleanMods()
            createModCategories(modsPage)
            self.template:clickTab(component)
        end
end

function mcm:onClose()
	self.mod.modules.hud:update()
	self.mod.modules.highlighter:removeHighlight()
end

function mcm:onResetButtonClicked()
	self.mod.modules.hud:update()
end

return mcm