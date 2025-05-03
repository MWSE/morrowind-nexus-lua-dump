local default = {
	thickness = 6,
	color = nil,
	showOnlyForOnStrike = true
}
local config = mwse.loadConfig("hud_weapon_charge", default)

local chargeBlockId = tes3ui.registerID("vir_hudcharge:chargeBlock")
local chargeFillbarId = tes3ui.registerID("vir_hudcharge:chargeFillbar")
local lastEquipped
local colorReady

local function updateFillBar()
	local multiMenu = tes3ui.findMenu(tes3ui.registerID("MenuMulti"))
	if not multiMenu then return end

	local chargeFillbar = multiMenu:findChild(chargeFillbarId)
	if not chargeFillbar then return end

	colorReady = { math.round((config.color.r / 255), 3), math.round((config.color.g / 255), 3), math.round((config.color.b / 255), 3) }
--	chargeFillbar.widget.fillColor = color
	chargeFillbar.children[1].color = colorReady
	chargeFillbar.height = config.thickness

	multiMenu:updateLayout()
end

local function createChargeFillbar(e)
	if not e.newlyCreated then return end

	local multiMenu = e.element
	local weaponLayout = multiMenu:findChild(tes3ui.registerID("MenuMulti_weapon_layout"))
	local chargeBlock = weaponLayout:createBlock{ id = chargeBlockId }
	chargeBlock.autoWidth = true
	chargeBlock.autoHeight = true

	colorReady = { math.round((config.color.r / 255), 3), math.round((config.color.g / 255), 3), math.round((config.color.b / 255), 3) }

	local chargeFillbar = chargeBlock:createFillBar{ id = chargeFillbarId }
	chargeFillbar.widget.fillColor = colorReady
	chargeFillbar.widget.showText = false
	chargeFillbar.width = 36
	chargeFillbar.height = config.thickness
end
event.register("uiActivated", createChargeFillbar, { filter = "MenuMulti" })

local function update()
	if not tes3.player then return end
	local multiMenu = tes3ui.findMenu(tes3ui.registerID("MenuMulti"))
	if not multiMenu then return end

	local weapon = tes3.getEquippedItem({ actor = tes3.player, objectType = tes3.objectType.weapon, enchanted = true})
	if weapon and ( config.showOnlyForOnStrike == false or weapon.object.enchantment.castType == tes3.enchantmentType.onStrike ) then
		lastEquipped = true

		local chargeFillbar = multiMenu:findChild(chargeFillbarId)
		if chargeFillbar then
			chargeFillbar.parent.visible = true
			chargeFillbar.widget.max = weapon.object.enchantment.maxCharge
			chargeFillbar.widget.current = weapon.variables and weapon.variables.charge or weapon.object.enchantment.maxCharge
		end
	elseif lastEquipped then
		lastEquipped = false

			--Hide fillbar if player doesn't have an enchanted weapon equipped
		local chargeFillbar = multiMenu:findChild(chargeFillbarId)
		if chargeFillbar then
			chargeFillbar.parent.visible = false
		end
	end
end
event.register("enterFrame", update)
event.register("loaded", function()
	--Reset when loaded
	lastEquipped = true
end)

local function initialized()
	local magic_color = tes3ui.getPalette("magic_color")
	local defaultColor = {
		r = math.round(magic_color[1] * 255),
		g = math.round(magic_color[2] * 255),
		b = math.round(magic_color[3] * 255)
	}
	default.color = defaultColor
	config.color = config.color or defaultColor

	mwse.log("[HUD Weapon Charge] Initialized")
end
event.register("initialized", initialized)


local function registerModConfig()
	local template = mwse.mcm.createTemplate("Полоса заряда оружия")
--	template:saveOnClose("hud_weapon_charge", config)
	template.onClose = function()
		mwse.saveConfig("hud_weapon_charge", config)
		updateFillBar()
	end

	local page = template:createSideBarPage{
		label = "Настройки",
		description = "Добавляет новую полосу под полосой прочности оружия, которая показывает текущий магический заряд вашего оружия."
	}

	page:createOnOffButton{
		label = "Показывать полосу заряда только для оружия с эффектом при ударе",
		description = "Если включено, то полоса будет отображаться только для оружия с эффектом при ударе. По умолчанию: Да",
		variable = mwse.mcm.createTableVariable{
			id = "showOnlyForOnStrike",
			table = config
		}
	}

	page:createSlider{
		label = "Толщина полосы магического заряда оружия",
		description = "Меняет толщину полосы. По умолчанию: 6",
		max = 12,
		min = 5,
		step = 1,
		jump = 1,
		variable = mwse.mcm:createTableVariable{
			id = "thickness",
			table = config
		},
		callback = function()
			updateFillBar()
		end
	}

	local color = page:createCategory("Цвет полосы магического заряда оружия")

	local magic_color = tes3ui.getPalette("magic_color")
	local defaultColor = {
		r = math.round(magic_color[1] * 255),
		g = math.round(magic_color[2] * 255),
		b = math.round(magic_color[3] * 255)
	}
	config.color = config.color or defaultColor
	local defaultColorS = defaultColor.r..", "..defaultColor.g..", "..defaultColor.b
	color:createSlider{
		label = "Красный",
		description = "Изменение цвета полосы. По умолчанию цвет соответствует цвету магии в Morrowind.ini: "..defaultColorS,
		max = 255,
		min = 0,
	--	variable = mwse.mcm:createTableVariable{
	--		id = "r",
	--		table = config.color
	--	},
		variable = mwse.mcm:createTableVariable{
			id = "temp_r",
			get = function()
				return config.color.r
			end,
			set = function(_, newColor)
				config.color.r = newColor
				updateFillBar()
			end
		}--,
	--	callback = function()
	--		updateFillBar()
	--	end
	}
	color:createSlider{
		label = "Зеленый",
		description = "Изменение цвета полосы. По умолчанию цвет соответствует цвету магии в Morrowind.ini: "..defaultColorS,
		max = 255,
		min = 0,
	--	variable = mwse.mcm:createTableVariable{
	--		id = "g",
	--		table = config.color
	--	},
		variable = mwse.mcm:createTableVariable{
			id = "temp_g",
			get = function()
				return config.color.g
			end,
			set = function(_, newColor)
				config.color.g = newColor
				updateFillBar()
			end
		}--,
	--	callback = function()
	--		updateFillBar()
	--	end
	}
	color:createSlider{
		label = "Синий",
		description = "Изменение цвета полосы. По умолчанию цвет соответствует цвету магии в Morrowind.ini: "..defaultColorS,
		max = 255,
		min = 0,
	--	variable = mwse.mcm:createTableVariable{
	--		id = "b",
	--		table = config.color
	--	},
		variable = mwse.mcm:createTableVariable{
			id = "temp_b",
			get = function()
				return config.color.b
			end,
			set = function(_, newColor)
				config.color.b = newColor
				updateFillBar()
			end
		}--,
	--	callback = function()
	--		updateFillBar()
	--	end
	}
	color:createButton{
		buttonText = "Восстановить базовый цвет",
		description =
			"Восстановить значение цвета полосы в соответствии с Morrowind.ini: "..defaultColorS
			.."\n\n" ..
			"Это действие потребует перезагрузки игры.",
		restartRequired = true,
		callback = function()
			config.color = defaultColor
		end
	}

	mwse.mcm.register(template)
end
event.register("modConfigReady", registerModConfig)