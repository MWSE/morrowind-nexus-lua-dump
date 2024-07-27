local util = require("mer.realisticArchery.util")
local config = util.config
local mcmConfig = mwse.loadConfig(config.configPath, config.mcmDefault)

local LINKS_LIST = {
    {
        text = "История версий",
        url = "https://github.com/jhaakma/auto-attack/releases"
    },
    -- {
    --     text = "Wiki",
    --     url = "https://github.com/jhaakma/auto-attack/wiki"
    -- },
    {
        text = "Страница мода на Nexusmods",
        url = "https://www.nexusmods.com/morrowind/mods/51348"
    },
    {
        text = "Поддержать автора",
        url = "https://ko-fi.com/merlord"
    },
}
local CREDITS_LIST = {
    {
        text = "Автор: Merlord",
        url = "https://www.nexusmods.com/users/3040468?tab=user+files",
    },
}

local function addSideBar(component)
    local versionText = string.format(config.static.modName)
    component.sidebar:createCategory(versionText)
    component.sidebar:createInfo{ text = config.static.modDescription}

    local linksCategory = component.sidebar:createCategory("Ссылки:")
    for _, link in ipairs(LINKS_LIST) do
        linksCategory:createHyperLink{ text = link.text, url = link.url }
    end
    local creditsCategory = component.sidebar:createCategory("Создатели:")
    for _, credit in ipairs(CREDITS_LIST) do
        creditsCategory:createHyperLink{ text = credit.text, url = credit.url }
    end
end

local function registerMCM()
    local template = mwse.mcm.createTemplate{ name = config.static.modName,}
    template.onClose = function()
        config.save(mcmConfig)
    end
    template:register()

    local page = template:createSideBarPage{ label = "Настройки"}
    addSideBar(page)

    page:createYesNoButton{
        label = "Включить мод",
        description = "Включить или выключить мод",
        variable = mwse.mcm.createTableVariable{ id = "enabled", table = mcmConfig }
    }

    page:createSlider{
        label = "Максимальное отклонение: %s Градусов",
        description = "Определяет, на сколько градусов может отклониться снаряд, в зависимости от навыка \"Меткость\", стреляющего NPC/игрока."
          .. string.format(" По умолчанию: %s%%", config.mcmDefault.maxNoise),
        variable = mwse.mcm.createTableVariable{ id = "maxNoise", table = mcmConfig },
        min = 0,
        max = 100,
        jump = 5,
        step = 1
    }

    page:createSlider{
        label = "Минимальная дистанция для полного урона (при минимальном навыке Меткость): %s",
        description = "Определяет минимальное расстояние, на которое должен пролететь снаряд, чтобы нанести полный урон. При 100 навыке Меткость это расстояние уменьшается вдвое."
            .. string.format(" По умолчанию: %s", config.mcmDefault.minDistanceFullDamage),
        variable = mwse.mcm.createTableVariable{ id = "minDistanceFullDamage", table = mcmConfig },
        min = 0,
        max = 5000,
        jump = 100,
        step = 1
    }

    page:createSlider{
        label = "Максимальное снижение урона на ближней дистанции: %s%%",
        description = "Определяет максимальное снижение урона, наносимого снарядом, когда он находится близко к цели."
            .. string.format(" По умолчанию: %s%%", config.mcmDefault.maxCloseRangeDamageReduction),
        variable = mwse.mcm.createTableVariable{ id = "maxCloseRangeDamageReduction", table = mcmConfig },
        min = 0,
        max = 100,
        jump = 5,
        step = 1
    }

    page:createSlider{
        label = "Множитель подкрадывания: %s%%",
        description = "Определяет процент снижения отклонения, когда атакующий крадется."
            .. string.format(" По умолчанию: %s%%", config.mcmDefault.sneakReduction),
        variable = mwse.mcm.createTableVariable{ id = "sneakReduction", table = mcmConfig },
        min = 0,
        max = 100,
        jump = 5,
        step = 1
    }


    page:createDropdown{
        label = "Log Level",
        description = "Установите уровень ведения журнала для mwse.log. Оставьте INFO, если вы не занимаетесь отладкой.",
        options = {
            { label = "TRACE", value = "TRACE"},
            { label = "DEBUG", value = "DEBUG"},
            { label = "INFO", value = "INFO"},
            { label = "ERROR", value = "ERROR"},
            { label = "NONE", value = "NONE"},
        },
        variable =  mwse.mcm.createTableVariable{ id = "logLevel", table = mcmConfig },
        callback = function(self)
            for _, logger in pairs(util.loggers) do
                logger:setLogLevel(self.variable.value)
            end
        end
    }
end
event.register("modConfigReady", registerMCM)