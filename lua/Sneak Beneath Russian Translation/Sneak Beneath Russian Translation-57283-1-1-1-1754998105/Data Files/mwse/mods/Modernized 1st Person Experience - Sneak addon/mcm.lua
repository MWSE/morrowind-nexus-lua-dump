--[[
	Mod:Sneak Beneath ( Modernized 1st Person Experience - Sneak addon )
	Author: rhjelte
	Version: 1.1.1
]]--


local EasyMCM = require ("easyMCM.EasyMCM")
local config = require("Modernized 1st Person Experience - Sneak addon.config").loaded
local defaultConfig = require("Modernized 1st Person Experience - Sneak addon.config").default
configPath = "Modernized 1st Person Experience - Sneak addon"
local modName = ("Улучшенный вид от первого лица - дополнение для скрытности")
local template = EasyMCM.createTemplate(modName)
template:saveOnClose(modName, config)
template:register()

local page = template:createSideBarPage({
    label = "Настройки",
    description = "Наконец-то можно пробираться под препятствиями в режиме от первого лица интуитивно понятным способом!\n\nРекомендуется использовать вместе с модом \"Улучшенный вид от первого лица\"\n\nЭто добавит дополнительные функции: \n- Небольшую анимацию при попытке встать, когда недостаточно места; \n- Плавное изменение высоты камеры при входе/выходе из режима скрытности. \n- Настраиваемую высоту камеры. \n\nПри попытке встать мод проверяет, достаточно ли места. Это также работает при переключении в режим от третьего лица - технически я уменьшаю размер персонажа, и без этой проверки вы увидели бы уменьшенную версию своего персонажа, если не заблокировать переключение. Когда места достаточно, вы можете как переключить камеру, так и встать.",
    showReset = true
})

------------------------------------------------------------------------------------------------------------------------------- Main tweaks
local settings = page:createCategory ("Улучшенный вид от первого лица - дополнение для скрытности")

settings:createOnOffButton{
    label = "Включить мод",
    description = "Включить или выключить мод.",
    defaultSetting = defaultConfig.modEnabled,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "modEnabled",
        table = config
    }
}

settings:createSlider{
    label = "Запас по высоте",
    description ="Мод проверяет наличие свободного места выше границ персонажа на указанное значение. Простой проверки границ персонажа недостаточно для всех ситуаций, физический движок может перемещать персонажа. Чтобы избежать этого, приходится проверять с небольшим запасом, чтобы гарантировать достаточно места для подъема.\n\nЭто значение позволяет изменить размер такого запаса.",
    defaultSetting = defaultConfig.verticalPadding,
    showDefaultSetting = true,
    max = 30,
    min = 0,
    step = 1,
    jump = 5,
    variable = mwse.mcm.createTableVariable{
        id = "verticalPadding",
        table = config
    }
}

settings:createSlider{
    label = "Запас по ширине",
    description ="Определяет, насколько строго проверяется место для подъема. Меньшие значения разрешают вставать в более тесных пространствах, но могут вызывать странности при подъеме. Большие значения проверяют большую область вокруг персонажа.",
    defaultSetting = defaultConfig.horizontalPadding,
    showDefaultSetting = true,
    max = 25,
    min = -25,
    step = 1,
    jump = 5,
    variable = mwse.mcm.createTableVariable{
        id = "horizontalPadding",
        table = config
    }
}

settings:createSlider{
    label = "Интервал сообщений (в секундах)",
    description ="Время в секундах, которое должно пройти перед тем, как мод снова покажет сообщение о недостатке места для того, чтобы встать.",
    defaultSetting = defaultConfig.messageCooldown,
    showDefaultSetting = true,
    max = 2,
    min = 0.1,
    step = 0.1,
    decimalPlaces = 1,
    variable = mwse.mcm.createTableVariable{
        id = "messageCooldown",
        table = config
    }
}

settings:createDropdown{
    label = "Стиль сообщений.",
    description = [[Определяет, будут ли сообщения в игре при попытке встать отображаться от первого лица (\"Слишком тесно. Я не могу встать.\") или от третьего лица (\"Недостаточно места, чтобы встать.\").]],
    options = {
        { label = "От первого лица", value = true },
        { label = "От третьего лица", value = false}
    },
    defaultValue = defaultConfig.firstPersonMessages,
    showDefaultSetting = true,
    variable = mwse.mcm.createTableVariable{
        id = "firstPersonMessages",
        table = config
    }

}