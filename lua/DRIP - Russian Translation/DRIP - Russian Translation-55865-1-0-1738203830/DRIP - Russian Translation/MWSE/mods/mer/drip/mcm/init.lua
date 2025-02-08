local common = require("mer.drip.common")
local mcmConfig = mwse.loadConfig(common.config.configPath, common.config.mcmDefault)

local LINKS_LIST = {
    {
        text = "История релизов",
        url = "https://github.com/jhaakma/drip/releases"
    },
    -- {
    --     text = "Wiki",
    --     url = "https://github.com/jhaakma/crafting-framework/wiki"
    -- },
    {
        text = "Страничка оригинального мода на Нексусе",
        url = "https://www.nexusmods.com/morrowind/mods/51242"
    },
	{
        text = "Страничка русской версии мода на Нексусе",
        url = "https://www.nexusmods.com/morrowind/mods/55865"
    },
    {
        text = "Купить кофе автору",
        url = "https://ko-fi.com/merlord"
    },
}
local CREDITS_LIST = {
    {
        text = "Автор мода - Merlord",
        url = "https://www.nexusmods.com/users/3040468?tab=user+files",
    },
}

local function addSideBar(component)
    local versionText = string.format(common.config.modName)
    component.sidebar:createCategory(versionText)
    component.sidebar:createInfo{ text = common.config.modDescription}

    local linksCategory = component.sidebar:createCategory("Ссылки")
    for _, link in ipairs(LINKS_LIST) do
        linksCategory:createHyperLink{ text = link.text, url = link.url }
    end
    local creditsCategory = component.sidebar:createCategory("Авторство")
    for _, credit in ipairs(CREDITS_LIST) do
        creditsCategory:createHyperLink{ text = credit.text, url = credit.url }
    end
end

local function registerMCM()
    local template = mwse.mcm.createTemplate{ name = common.config.modName, headerImagePath = "textures/drip/MCMHeader.dds" }
    template.onClose = function()
        common.config.save(mcmConfig)
    end
    template:register()

    local page = template:createSideBarPage{ label = "Настройки"}
    addSideBar(page)

    page:createYesNoButton{
        label = "Мод включен",
        description = "Включение и выключение мода",
        variable = mwse.mcm.createTableVariable{ id = "enabled", table = mcmConfig }
    }

    page:createSlider{
        label = "Шанс генерации первого модификатора: %s%%",
        description = "Определяет процентный шанс генерации первого модификатора для доступных предметов. ВНИМАНИЕ: слишком высокое значение может вызывать подтормаживания при первых посещениях локаций. Не рекомендуется устанавливать значение выше 10%."
            .. string.format(" Значение по умолчанию - %s", common.config.mcmDefault.modifierChance),
        min = 0,
        max = 100,
        step = 1,
        jump = 10,
        variable = mwse.mcm.createTableVariable{ id = "modifierChance", table = mcmConfig }
    }

    page:createSlider{
        label = "Шанс генерации второго модификатора: %s%%",
        description = "Определяет процент вероятности добавления второго модификатора к подходящему предмету. Фактическая вероятность может быть немного ниже установленной, так как некоторые модификаторы не применяются из-за превышения максимальной длины имени (31 символ)."
        .. string.format(" Значение по умолчанию - %s", common.config.mcmDefault.secondaryModifierChance),
        min = 0,
        max = 100,
        step = 1,
        jump = 10,
        variable = mwse.mcm.createTableVariable{ id = "secondaryModifierChance", table = mcmConfig }
    }

    page:createSlider{
        label = "Шанс дикого заклинания: %s%%",
        description = "Определяет процент вероятности добавления дополнительного модификатора дикого заклинания к подходящему предмету. Расширяет диапазон минимальных и максимальных значений всех эффектов предмета."
        .. string.format(" Значение по умолчанию - %s", common.config.mcmDefault.wildChance),
        min = 0,
        max = 100,
        step = 1,
        jump = 10,
        variable = mwse.mcm.createTableVariable{ id = "wildChance", table = mcmConfig }
    }

    page:createDropdown{
        label = "Логирование",
        description = "Установите уровень логирования для файла mwse.log. Оставьте значение INFO, если не занимаетесь отладкой.",
        options = {
            { label = "TRACE", value = "TRACE"},
            { label = "DEBUG", value = "DEBUG"},
            { label = "INFO", value = "INFO"},
            { label = "ERROR", value = "ERROR"},
            { label = "NONE", value = "NONE"},
        },
        variable =  mwse.mcm.createTableVariable{ id = "logLevel", table = mcmConfig },
        callback = function(self)
            common.updateLoggers(self.variable.value)
        end
    }
end
event.register("modConfigReady", registerMCM)