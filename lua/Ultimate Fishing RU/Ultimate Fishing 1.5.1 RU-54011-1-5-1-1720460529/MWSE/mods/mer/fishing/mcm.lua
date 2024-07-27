local common = require("mer.fishing.common")
local logger = common.createLogger("MCM")
local config = require("mer.fishing.config")
local metadata = config.metadata --[[@as MWSE.Metadata]]
local LINKS_LIST = {
    {
        text = "История версий",
        url = "https://github.com/jhaakma/fishing/releases"
    },
    {
        text = "Информация",
        url = "https://github.com/jhaakma/fishing/wiki"
    },
    {
        text = "Страница мода на Nexusmods",
        url = "https://www.nexusmods.com/morrowind/mods/52872"
    },
    {
        text = "Угостить меня кофе",
        url = "https://ko-fi.com/merlord"
    },
}
local CREDITS_LIST = {
    {
        text = "Автор: Merlord",
        url = "https://www.nexusmods.com/users/3040468?tab=user+files",
    },
    {
        text = "Анимации: Greatness7",
        url = "https://github.com/Greatness7"
    },
    {
        text = "Модели легендарных рыб: Melchior Darhk",
        url = "https://www.nexusmods.com/morrowind/users/962116"
    },
    {
        text = "ИИ рыбы и другие улучшения кода: Hrnchamd",
        url = "https://www.nexusmods.com/morrowind/users/843673"
    },
    {
        text = "Модели рыбы: Cait"
    },
}

local function addSideBar(component)
    component.sidebar:createCategory(string.format("Лучшая рыбалка"))
    component.sidebar:createInfo{ text = "Лучшая рыбалка - это мод, добавляющий в Морровинд навык Рыбная ловля и мини-игру.\n- Оснастите свою удочку приманками и наживкой и поймайте более 20 различных видов рыб по всему Вварденфеллу.\n- Победите каждую рыбу в битве на смекалку и выносливость. Следите за тем, чтобы натяжение не было слишком низким или слишком высоким, и измотайте рыбу до того, как вы сами устанете.\n- Полностью анимированная механика рыбалки, включая симуляцию натяжения лески, анимацию игрока и искусственный интеллект рыбы.\n- Вам предстоит поймать пять легендарных рыб. Поймав легендарную рыбу, вы получите трофейную голову, которую можно повесить на стену.\n- Интеграция с модом Пеплопад: изготовление удочки, приготовление и поедание пойманной рыбы.\n"}

    local linksCategory = component.sidebar:createCategory("Ссылки:")
    for _, link in ipairs(LINKS_LIST) do
        linksCategory:createHyperLink{ text = link.text, url = link.url }
    end
    local creditsCategory = component.sidebar:createCategory("Создатели:")
    for _, credit in ipairs(CREDITS_LIST) do
        if credit.url then
            creditsCategory:createHyperLink{ text = credit.text, url = credit.url }
        else
            creditsCategory:createInfo{ text = credit.text }
        end
    end
end

local function registerMCM()
    local template = mwse.mcm.createTemplate{ name = "Лучшая рыбалка" }
    template.onClose = function()
        config.save()
        event.trigger("Fishing:McmUpdated")
    end
    template:register()

    local page = template:createSideBarPage{ label = "Настройки"}
    addSideBar(page)

    -- page:createYesNoButton{
        -- label = string.format("Enable %s", metadata.package.name),
        -- description = "Enable or disable the mod.",
    --     variable = mwse.mcm.createTableVariable{ id = "enabled", table = config.mcm },
    --     callback = function(self)
    --         if self.variable.value == true then
    --             logger:info("Enabling mod")
    --             event.trigger("Fishing:ModEnabled")
    --             event.trigger("Fishing:McmUpdated")
    --         else
    --             logger:info("Disabling mod")
    --             event.trigger("Fishing:ModDisabled")
    --         end
    --     end
    -- }

    page:createYesNoButton{
        label = "Включить подсказки",
        description = "Добавляет подсказки к рыбам с их описанием. Требуются мод Tooltips Complete.",
        variable = mwse.mcm.createTableVariable{ id = "enableFishTooltips", table = config.mcm },
        restartRequired = true,
    }

    --cheatMode
    page:createYesNoButton{
        label = "Включить режим легкого крючка",
        description = "Убирает влияние навыка на сложность поймать рыбу на крючок.",
        variable = mwse.mcm.createTableVariable{ id = "easyHook", table = config.mcm },
    }

    page:createYesNoButton{
        label = "Включить чит-режим",
        description = "Мгновенные поклевки, только в целях тестирования/отладки.",
        variable = mwse.mcm.createTableVariable{ id = "cheatMode", table = config.mcm },
    }

    page:createDropdown{
        label = "Уровень логирования",
        description = "Установка уровня логирования для всех логгеров.",
        options = {
            { label = "TRACE", value = "TRACE"},
            { label = "DEBUG", value = "DEBUG"},
            { label = "INFO", value = "INFO"},
            { label = "ERROR", value = "ERROR"},
            { label = "NONE", value = "NONE"},
        },
        variable =  mwse.mcm.createTableVariable{ id = "logLevel", table = config.mcm},
        callback = function(self)
            for _, logger in pairs(common.loggers) do
                logger:setLogLevel(self.variable.value)
            end
        end
    }


    template:createExclusionsPage{
        label = "Продавцы",
        description = "Выберите каким продавцам разрешено продавать рыболовные товары.",
        leftListLabel = "Разрешить",
        rightListLabel = "Исключить",
        filters = {
            {
                label = "",
                callback = function()
                    local npcs = {}
                    for obj in tes3.iterateObjects(tes3.objectType.npc) do
                        ---@cast obj tes3npc
                        if obj.class and obj.class.bartersMiscItems then
                            local id = obj.id:lower()
                            npcs[id] = true
                        end
                    end
                    local npcsList = {}
                    for npc, _ in pairs(npcs) do
                        table.insert(npcsList, npc)
                    end
                    table.sort(npcsList)
                    return npcsList
                end
            }
        },
        variable = mwse.mcm.createTableVariable{
            id = "fishingMerchants",
            table = config.mcm,
        },
    }

end
event.register("modConfigReady", registerMCM)