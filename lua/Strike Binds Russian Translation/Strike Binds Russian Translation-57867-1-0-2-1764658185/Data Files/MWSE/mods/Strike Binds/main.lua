local defaultConfig = {
    enabled = true,
	bestAttackBinds = false,
    ---@type mwseKeyMouseCombo
    slash = { mouseButton = 0 },
    ---@type mwseKeyMouseCombo
    thrust = { mouseButton = 1 },
    ---@type mwseKeyMouseCombo
    chop = { mouseButton = 4 },
}
local configPath = "Strike Binds"
local config = mwse.loadConfig(configPath, defaultConfig)
local modName = "Горячие клавиши для типов атаки"
local function updateAttackBind()
    local attackBind = tes3.getInputBinding(tes3.keybind.use)
    if mge.enabled() then
        if config.attackCode and config.attackDevice then
            attackBind.device = config.attackDevice
            attackBind.code = config.attackCode
        end
        if attackBind.device ~= 0 and config.enabled then
            config.attackDevice = attackBind.device
            config.attackCode = attackBind.code
            mwse.log("Горячие клавиши для типов атаки: переназначение удара (ВКЛ)")
            attackBind.device = 0
            attackBind.code = 221
        end
    end
end

local function registerModConfig()
    -- Just a convenient time to do this on startup.
    updateAttackBind()

    local template = mwse.mcm.createTemplate{
        name = modName,
        config = config
    }

    template:register()
    template:saveOnClose(configPath, config)
    local page = template:createPage()

    page:createInfo{
        label = modName,
        text = "Версия 1.0.2\nАвтор Pete Goodfellow\n 27.12.2024"
    }

    if not mge.enabled() then
        page:createInfo{
            text = "MGE не включен - функционал отключен. Откройте графический интерфейс MGE XE и убедитесь, что опция \"Отключить MGE в игре\" отключена.",
            paddingBottom = 20,
            postCreate = function(e) e.elements.info.color = tes3ui.getPalette(tes3.palette.healthNpcColor) end
        }
    end

	page:createYesNoButton{
		label = "Включить мод?",
		configKey = "Включен",
        callback = function()
            updateAttackBind()
        end
	}

    page:createInfo{
        text = "Примечание: если вы удаляете мод, сначала отключите его в этом меню или вручную переназначьте клавишу \"Использовать\" в Morrowind, на нужную вам."
    }

	page:createYesNoButton{
		label = "Приоритет лучшим атакам?",
		configKey = "bestAttackBinds",
	}

    page:createInfo{
        text = "Если функция \"Приоритет лучшим атакам\" отключена, следующие привязки клавиш будут напрямую соответствовать каждому типу атаки.\nЕсли же эта функция включена, то клавиши будут активировать лучшую, среднюю и худшую атаки, соответственно."
    }

    page:createKeyBinder{
        label = "Режущий / Лучшая",
        configKey = "slash",
        allowCombinations = false,
        allowMouse = true,
    }
    page:createKeyBinder{
        label = "Рубящий / Средняя",
        configKey = "chop",
        allowCombinations = false,
        allowMouse = true,
    }
    page:createKeyBinder{
        label = "Колющий / Худшая",
        configKey = "thrust",
        allowCombinations = false,
        allowMouse = true,
    }
end
event.register(tes3.event.modConfigReady, registerModConfig)

if not mge.enabled() then
	mwse.log("Strike Binds disabled because MGE is disabled in-game. Please reenable it and restart.")
	return
end


local validWeapons = {
    [0] = true,
    [1] = true,
    [2] = true,
    [3] = true,
    [4] = true,
    [5] = true,
    [6] = true,
    [7] = true,
    [8] = true,
    [9] = false,
    [10] = false,
    [11] = false,
    [12] = false,
    [13] = false,
}

---@return tes3.physicalAttackType
---@param w tes3weapon
local function orderAttacks(w)
	if not config.bestAttackBinds then
		return { tes3.physicalAttackType.slash, tes3.physicalAttackType.chop, tes3.physicalAttackType.thrust }
	end

    local com = {
        slash = w.slashMin + w.slashMax,
        chop = w.chopMin + w.chopMax,
        thrust = w.thrustMin + w.thrustMax,
    }

	if com.chop >= com.thrust and com.chop >= com.slash and com.slash <= com.thrust then
		return { tes3.physicalAttackType.chop, tes3.physicalAttackType.slash, tes3.physicalAttackType.thrust }
	end

	if com.chop >= com.thrust and com.chop >= com.slash and com.slash <= com.thrust then
		return { tes3.physicalAttackType.chop, tes3.physicalAttackType.thrust, tes3.physicalAttackType.slash }
	end

	if com.thrust >= com.chop and com.thrust >= com.slash and com.slash > com.chop then
		return { tes3.physicalAttackType.thrust, tes3.physicalAttackType.slash, tes3.physicalAttackType.chop }
	end

	if com.thrust >= com.chop and com.thrust >= com.slash and com.slash <= com.chop then
		return { tes3.physicalAttackType.thrust, tes3.physicalAttackType.chop, tes3.physicalAttackType.slash }
	end

	if com.slash >= com.chop and com.slash >= com.thrust and com.thrust > com.chop then
		return { tes3.physicalAttackType.slash, tes3.physicalAttackType.thrust, tes3.physicalAttackType.chop }
	end

	if com.slash >= com.chop and com.slash >= com.thrust and com.thrust <= com.chop then
		return { tes3.physicalAttackType.slash, tes3.physicalAttackType.chop, tes3.physicalAttackType.thrust }
	end

	-- this is fine
	return { tes3.physicalAttackType.slash, tes3.physicalAttackType.chop, tes3.physicalAttackType.thrust }
end

local slash = false
local chop = false
local thrust = false

---@param e attackStartEventData
local function onAttackStart(e)
    if not config.enabled then return end
    if e.reference ~= tes3.player then return end
    if not e.mobile.readiedWeapon then return end

    if slash then
		e.attackType = orderAttacks(e.mobile.readiedWeapon.object)[1]
	elseif chop then
		e.attackType = orderAttacks(e.mobile.readiedWeapon.object)[2]
	elseif thrust then
		e.attackType = orderAttacks(e.mobile.readiedWeapon.object)[3]
	end
end
event.register(tes3.event.attackStart, onAttackStart)

local function isKeyEqualIgnoringModifiers(params)
	local actual = params.actual
	local expected = params.expected
	-- Handle mouseDownEventData
	local actualMouseButton = actual.mouseButton or actual.button
	local expectedMouseButton = expected.mouseButton or expected.button

	if ((actual.keyCode or false)  ~= (expected.keyCode or false)
		or (actualMouseButton or false) ~= (expectedMouseButton or false)) then
		return false
	end

	return true
end

--- @param e keyDownEventData|mouseButtonDownEventData
local function onButtonDown(e)
    if not config.enabled then return end
	if tes3.menuMode() then return end
	if slash or chop or thrust then return end

    if isKeyEqualIgnoringModifiers{ expected = config.slash, actual = e} then slash = true end
    if isKeyEqualIgnoringModifiers{ expected = config.thrust, actual = e} then thrust = true end
    if isKeyEqualIgnoringModifiers{ expected = config.chop, actual = e} then chop = true end

	if slash or chop or thrust then
		tes3.pushKey(tes3.getInputBinding(tes3.keybind.use).code)
	end
end
event.register(tes3.event.keyDown, onButtonDown)
event.register(tes3.event.mouseButtonDown, onButtonDown)

--- @param e keyUpEventData|mouseButtonUpEventData
local function onButtonUp(e)
    if not config.enabled then return end
	if tes3.menuMode() then return end
	if not slash and not chop and not thrust then return end

    if isKeyEqualIgnoringModifiers{ expected = config.slash, actual = e} then slash = false end
    if isKeyEqualIgnoringModifiers{ expected = config.thrust, actual = e} then thrust = false end
    if isKeyEqualIgnoringModifiers{ expected = config.chop, actual = e} then chop = false end

	if not slash and not chop and not thrust then
		tes3.releaseKey(tes3.getInputBinding(tes3.keybind.use).code)
	end
end
event.register(tes3.event.keyUp, onButtonUp)
event.register(tes3.event.mouseButtonUp, onButtonUp)

--- @param e menuEnterEventData
local function menuEnterCallback(e)
    if not config.enabled then return end
    tes3.releaseKey(tes3.getInputBinding(tes3.keybind.use).code)
    slash = false
    thrust = false
    chop = false
end
event.register(tes3.event.menuEnter, menuEnterCallback)