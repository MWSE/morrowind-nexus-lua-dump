local mod = "Декоративное изменение инвентаря"
local version = "1.2.0"

local function logMessage(message)
	mwse.log("[" .. mod .. " " .. version .. "] " .. message)
end

local lfs = require("lfs")

local defaultConfig = {
	showBorders = true,
	showColoredBackgrounds = true,
	showEquipmentEffectIcons = true,
	showAlchemyEffectIcons = true,
	showScrollEffectIcons = true,
	removeVanillaDecorators = true,
	backgroundAlpha = 20,
	borderSize = 42,
	borderColorRed = 35,
	borderColorGreen = 25,
	borderColorBlue = 20,
	borderAlpha = 100,
	equippedColorRed = 10,
	equippedColorGreen = 100,
	equippedColorBlue = 10,
	barteredColorRed = 100,
	barteredColorGreen = 80,
	barteredColorBlue = 10,
	effectIconSize = 12,
	effectIconStyle = "icon",
	effectIconPositionX = 90,
	effectIconPositionY = 10
}

local config = mwse.loadConfig(mod, defaultConfig)

local idItemTileBorder = nil
local idItemTileRect = nil
local idItemTileEffectIcon = nil

local function getEnchantmentEffectIconPath(item)
    local success, icon = pcall(function()
			return "Icons/" .. item.enchantment.effects[1].object[config.effectIconStyle]
		end)
    return success and icon
end

local function getAlchemyEffectIconPath(item)
    local success, icon = pcall(function()
			return "Icons/" .. item.effects[1].object[config.effectIconStyle]
		end)
    return success and icon
end

local function addIcon(element, path)
	local image = element:createImage{ id = idItemTileEffectIcon, path = path }
	image.width = config.effectIconSize
	image.height = config.effectIconSize
	image.scaleMode = true
	image.absolutePosAlignX = config.effectIconPositionX / 100
	image.absolutePosAlignY = config.effectIconPositionY / 100
	image.consumeMouseEvents = false
end

local function addEnchantmentEffectIcon(element, item)
    local path = getEnchantmentEffectIconPath(item)
    if path then
		addIcon(element, path)
    end
end

local function addAlchemyEffectIcon(element, item)
    local path = getAlchemyEffectIconPath(item)
    if path then
       addIcon(element, path)
    end
end

local function addRect(element, tile)
	local rect = element:createRect{ id = idItemTileRect }
	rect.width = config.borderSize
	rect.height = config.borderSize
	rect.absolutePosAlignX = 0.5
	rect.absolutePosAlignY = 0.5
	rect.consumeMouseEvents = true
	rect.alpha = config.backgroundAlpha / 100
	if tile.isEquipped then
		rect.color = {config.equippedColorRed / 100, config.equippedColorGreen / 100, config.equippedColorBlue / 100}
	elseif tile.isBartered then
		rect.color = {config.barteredColorRed / 100, config.barteredColorGreen / 100, config.barteredColorBlue / 100}
	else
		rect.alpha = 0.0
	end
	element:reorderChildren(0, rect, 1)
end

local function addBorder(element, tile)
	-- Can't use element:createThinBorder here because it actually is slow as hell.
	local border = element:createImage{ id = idItemTileBorder, path = "Textures/Seph/InventoryDecorator/Border.dds" }
	border.width = config.borderSize
	border.height = config.borderSize
	border.absolutePosAlignX = 0.5
	border.absolutePosAlignY = 0.5
	border.borderAllSides = 2
	border.consumeMouseEvents = false
	border.scaleMode = true
	border.alpha = config.borderAlpha / 100
	if not config.showColoredBackgrounds then
		if tile.isEquipped then
			border.color = {config.equippedColorRed / 100, config.equippedColorGreen / 100, config.equippedColorBlue / 100}
		elseif tile.isBartered then
			border.color = {config.barteredColorRed / 100, config.barteredColorGreen / 100, config.barteredColorBlue / 100}
		else
			border.color = {config.borderColorRed / 100, config.borderColorGreen / 100, config.borderColorBlue / 100}
		end
	else
		border.color = {config.borderColorRed / 100, config.borderColorGreen / 100, config.borderColorBlue / 100}
	end
end

local function removeVanillaDecorators(element)
	if element and element.contentPath then
		element.contentPath = "Textures/menu_icon_none.tga"
	end
end

local function onItemTileUpdated(e)
	if e.element and e.tile then
		if config.showColoredBackgrounds then
			addRect(e.element, e.tile)
		end
		if config.showBorders then
			addBorder(e.element, e.tile)
		end
		if e.item and e.item.enchantment then
			if (e.item.objectType == tes3.objectType.weapon or e.item.objectType == tes3.objectType.armor or e.item.objectType == tes3.objectType.clothing or e.item.objectType == tes3.objectType.ammunition) and config.showEquipmentEffectIcons then
				addEnchantmentEffectIcon(e.element, e.item)
			elseif (e.item.objectType == tes3.objectType.book and e.item.type == tes3.bookType.scroll) and config.showScrollEffectIcons then
				addEnchantmentEffectIcon(e.element, e.item)
			end
		end
		if (e.item and e.item.objectType == tes3.objectType.alchemy) and config.showAlchemyEffectIcons then
			addAlchemyEffectIcon(e.element, e.item)
		end
		if config.removeVanillaDecorators then
			removeVanillaDecorators(e.element)
		end
	end
end

local function refreshBarterMenu()
	local barterMenu = tes3ui.findMenu(tes3ui.registerID("MenuBarter"))
	if barterMenu then
		timer.frame.delayOneFrame(
			function()
				tes3ui.updateBarterMenuTiles()
			end
		)
	end
end

local function onInventoryTileClicked(e)
	refreshBarterMenu()
	e.source:forwardEvent(e)
end

local function onInventoryItemTileUpdated(e)
	e.element:register("mouseClick", onInventoryTileClicked)
end

local function onInitialized(e)
	idItemTileBorder = tes3ui.registerID("SephsInventoryDecorator:ItemTileBorder")
	idItemTileRect = tes3ui.registerID("SephsInventoryDecorator:ItemTileRect")
	idItemTileEffectIcon = tes3ui.registerID("SephsInventoryDecorator:ItemTileEffectIcon")
	event.register("itemTileUpdated", onItemTileUpdated)
	-- If possible, use the provided UI Expansion event instead of registering our own on the same element.
	if lfs.directoryexists("Data Files\\MWSE\\mods\\UI Expansion") or lfs.directoryexists("Data Files\\MWSE\\mods\\User Interface Expansion") then
		event.register("UIEX:InventoryTileClicked", refreshBarterMenu)
	else
		event.register("itemTileUpdated", onInventoryItemTileUpdated, { filter = "MenuInventory" })
	end
    logMessage("Initialized")
end
event.register("initialized", onInitialized)

local function onModConfigClose()
	mwse.saveConfig(mod, config)
end

local function onModConfigReady(e)
	local function booleanToReadableString(boolean)
		if boolean then
			return "Да"
		else
			return "Нет"
		end
	end

	local function effectIconStyleToReadableString(effectIconStyle)
		if effectIconStyle:lower() == "icon" then
			return "Простой"
		else
			return "Детальный"
		end
	end
	
    local template = mwse.mcm.createTemplate{ name = mod }
    template.onClose = onModConfigClose
    template:register()

    local page = template:createSideBarPage()
    page.description = mod .. " " .. version .. "\n\nЭтот мод добавляет больше информации и декораций к элементам инвентаря для более удобного управления предметами и их обнаружения."

	local generalCategory = page:createCategory("Основные настройки")

    generalCategory:createYesNoButton{
        label = "Показывать рамку вокруг предметов?",
        description = string.format("По умолчанию: %s", booleanToReadableString(defaultConfig.showBorders)),
        variable = mwse.mcm.createTableVariable{id = "showBorders", table = config, restartRequired = false}
    }
	
	generalCategory:createYesNoButton{
        label = "Показывать задний цветной фон для экипированных/обмениваемых предметов?",
        description = string.format("По умолчанию: %s", booleanToReadableString(defaultConfig.showColoredBackgrounds)),
        variable = mwse.mcm.createTableVariable{id = "showColoredBackgrounds", table = config, restartRequired = false}
    }
	
	generalCategory:createYesNoButton{
        label = "Показывать иконку первого эффекта на экипированных предметах?",
        description = string.format("По умолчанию: %s", booleanToReadableString(defaultConfig.showEquipmentEffectIcons)),
        variable = mwse.mcm.createTableVariable{id = "showEquipmentEffectIcons", table = config, restartRequired = false}
    }
	
	generalCategory:createYesNoButton{
        label = "Показывать иконку первого эффекта на зельях?",
        description = string.format("По умолчанию: %s", booleanToReadableString(defaultConfig.showAlchemyEffectIcons)),
        variable = mwse.mcm.createTableVariable{id = "showAlchemyEffectIcons", table = config, restartRequired = false}
    }
	
	generalCategory:createYesNoButton{
        label = "Показывать иконку первого эффекта на свитках?",
        description = string.format("По умолчанию: %s", booleanToReadableString(defaultConfig.showScrollEffectIcons)),
        variable = mwse.mcm.createTableVariable{id = "showScrollEffectIcons", table = config, restartRequired = false}
    }
	
	generalCategory:createYesNoButton{
        label = "Скрыть ванильные рамки и задний фон для экипированных/магических предметов?",
        description = string.format("По умолчанию: %s", booleanToReadableString(defaultConfig.removeVanillaDecorators)),
        variable = mwse.mcm.createTableVariable{id = "removeVanillaDecorators", table = config, restartRequired = false}
    }
	
	local backgroundCategory = page:createCategory("Задний фон")
	
	backgroundCategory:createSlider{
		label = "Непрозрачность: %s%%",
		description = string.format("По умолчанию: %d", defaultConfig.backgroundAlpha),
		min = 0,
		max = 100,
		step = 1,
		jump = 10,
		variable = mwse.mcm.createTableVariable{id = "backgroundAlpha", table = config,	restartRequired = false}
	}
	
	local borderCategory = page:createCategory("Рамка")
	
	borderCategory:createSlider{
		label = "Размер",
		description = string.format("По умолчанию: %d", defaultConfig.borderSize),
		min = 0,
		max = 50,
		step = 1,
		jump = 5,
		variable = mwse.mcm.createTableVariable{id = "borderSize", table = config, restartRequired = false}
	}
	
	borderCategory:createSlider{
		label = "Красный: %s%%",
		description = string.format("По умолчанию: %d", defaultConfig.borderColorRed),
		min = 0,
		max = 100,
		step = 1,
		jump = 10,
		variable = mwse.mcm.createTableVariable{id = "borderColorRed", table = config, restartRequired = false}
	}
	
	borderCategory:createSlider{
		label = "Зеленый: %s%%",
		description = string.format("По умолчанию: %d", defaultConfig.borderColorGreen),
		min = 0,
		max = 100,
		step = 1,
		jump = 10,
		variable = mwse.mcm.createTableVariable{id = "borderColorGreen", table = config, restartRequired = false}
	}
	
	borderCategory:createSlider{
		label = "Синий: %s%%",
		description = string.format("По умолчанию: %d", defaultConfig.borderColorBlue),
		min = 0,
		max = 100,
		step = 1,
		jump = 10,
		variable = mwse.mcm.createTableVariable{id = "borderColorBlue",	table = config,	restartRequired = false}
	}
	
	borderCategory:createSlider{
		label = "Непрозрачность: %s%%",
		description = string.format("По умолчанию: %d", defaultConfig.borderAlpha),
		min = 0,
		max = 100,
		step = 1,
		jump = 10,
		variable = mwse.mcm.createTableVariable{id = "borderAlpha", table = config,	restartRequired = false}
	}
	
	local equippedCategory = page:createCategory("Задний фон экипированных предметов")
	
	equippedCategory:createSlider{
		label = "Красный: %s%%",
		description = string.format("По умолчанию: %d", defaultConfig.equippedColorRed),
		min = 0,
		max = 100,
		step = 1,
		jump = 10,
		variable = mwse.mcm.createTableVariable{id = "equippedColorRed", table = config, restartRequired = false}
	}
	
	equippedCategory:createSlider{
		label = "Зеленый: %s%%",
		description = string.format("По умолчанию: %d", defaultConfig.equippedColorGreen),
		min = 0,
		max = 100,
		step = 1,
		jump = 10,
		variable = mwse.mcm.createTableVariable{id = "equippedColorGreen", table = config, restartRequired = false}
	}
	
	equippedCategory:createSlider{
		label = "Синий: %s%%",
		description = string.format("По умолчанию: %d", defaultConfig.equippedColorBlue),
		min = 0,
		max = 100,
		step = 1,
		jump = 10,
		variable = mwse.mcm.createTableVariable{id = "equippedColorBlue", table = config, restartRequired = false}
	}
	
	local barteredCategory = page:createCategory("Задний фон обмениваемых предметов")
	
	barteredCategory:createSlider{
		label = "Красный: %s%%",
		description = string.format("По умолчанию: %d", defaultConfig.barteredColorRed),
		min = 0,
		max = 100,
		step = 1,
		jump = 10,
		variable = mwse.mcm.createTableVariable{id = "barteredColorRed", table = config, restartRequired = false}
	}
	
	barteredCategory:createSlider{
		label = "Зеленый: %s%%",
		description = string.format("По умолчанию: %d", defaultConfig.barteredColorGreen),
		min = 0,
		max = 100,
		step = 1,
		jump = 10,
		variable = mwse.mcm.createTableVariable{id = "barteredColorGreen", table = config, restartRequired = false}
	}
	
	barteredCategory:createSlider{
		label = "Синий: %s%%",
		description = string.format("По умолчанию: %d", defaultConfig.barteredColorBlue),
		min = 0,
		max = 100,
		step = 1,
		jump = 10,
		variable = mwse.mcm.createTableVariable{id = "barteredColorBlue", table = config, restartRequired = false}
	}
	
	local effectIconCategory = page:createCategory("Иконки эффектов")
	
	effectIconCategory:createDropdown{
		label = "Стиль",
		description = string.format("По умолчанию: %s", effectIconStyleToReadableString(defaultConfig.effectIconStyle)),
		options = {
			{label = "Простой", value = "icon"},
			{label = "Детальный", value = "bigIcon"}
		},
		variable = mwse.mcm:createTableVariable{id = "effectIconStyle", table = config, restartRequired = false}
	}
	
	effectIconCategory:createSlider{
		label = "Размер",
		description = string.format("По умолчанию: %d", defaultConfig.effectIconSize),
		min = 0,
		max = 50,
		step = 1,
		jump = 5,
		variable = mwse.mcm.createTableVariable{id = "effectIconSize", table = config, restartRequired = false}
	}
	
	effectIconCategory:createSlider{
		label = "Позиция по горизонтали: %s%%",
		description = string.format("По умолчанию: %d", defaultConfig.effectIconPositionX),
		min = 0,
		max = 100,
		step = 1,
		jump = 10,
		variable = mwse.mcm.createTableVariable{id = "effectIconPositionX", table = config, restartRequired = false}
	}
	
	effectIconCategory:createSlider{
		label = "Позиция по вертикали: %s%%",
		description = string.format("По умолчанию: %d", defaultConfig.effectIconPositionY),
		min = 0,
		max = 100,
		step = 1,
		jump = 10,
		variable = mwse.mcm.createTableVariable{id = "effectIconPositionY", table = config, restartRequired = false}
	}
end
event.register("modConfigReady", onModConfigReady)