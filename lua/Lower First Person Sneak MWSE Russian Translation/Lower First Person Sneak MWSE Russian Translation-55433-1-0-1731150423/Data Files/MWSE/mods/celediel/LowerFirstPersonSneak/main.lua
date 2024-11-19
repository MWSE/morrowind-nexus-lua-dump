local modName = "Настройки камеры при скрытности"
local modConfig = "LowerFirstPersonSneak"
local modInfo = [[Настройка высоты камеры от первого лица, во время скрытности.
Чем больше значение на ползунке, тем ниже будет камера от положения стоя.

Стандартное значение: 10, Значение мода: 25

Нажмите кнопку Применить или перезапустите игру, чтобы изменения вступили в силу.]]

local defaultConfig = {i1stPersonSneakDelta = 25}

local config = mwse.loadConfig(modConfig, defaultConfig)

local function applyChanges()
    tes3.findGMST("i1stPersonSneakDelta").value = config.i1stPersonSneakDelta
    mwse.log("[%s] First Person Sneak Delta set to %s", modName, config.i1stPersonSneakDelta)
end

local function onInitialized() applyChanges() end

local function configMenu()
    local template = mwse.mcm.createTemplate(modName)
    template:saveOnClose(modConfig, config)

    local page = template:createSideBarPage({
        label = "Sidebar Page???",
        description = string.format("%s\n\n%s", modName, modInfo)
    })

    local category = page:createCategory(modName)

    category:createSlider({
        label = "Уровень высоты камеры",
        min = 0,
        max = 100,
        step = 1,
        jump = 5,
        variable = mwse.mcm.createTableVariable({id = "i1stPersonSneakDelta", table = config})
    })

    category:createButton({buttonText = "Применить", callback = applyChanges})

    return template
end

event.register("modConfigReady", function() mwse.mcm.register(configMenu()) end)
event.register("initialized", onInitialized)
