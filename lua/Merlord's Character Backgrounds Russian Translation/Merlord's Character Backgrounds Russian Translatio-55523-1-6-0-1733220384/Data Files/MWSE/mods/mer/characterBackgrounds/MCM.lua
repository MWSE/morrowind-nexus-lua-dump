local common = require("mer.characterBackgrounds.common")
local config = common.config
local logger = common.createLogger("MCM")
local UI = require("mer.characterBackgrounds.UI")
local Background = require("mer.characterBackgrounds.Background")

local template
local function registerMCM()
    template = mwse.mcm.createTemplate("Предыстории персонажей")
    local sideBarDefault = (
        "Добро пожаловать в Предыстории персонажей от Merlord! Этот мод добавляет 27 уникальных " ..
        "предысторий, одну из которых можно выбрать после создания персонажа. "
    )
    local function addSideBar(component)
        component.sidebar:createInfo{ text = sideBarDefault}
        component.sidebar:createHyperLink{
            text = "Автор: Merlord",
            exec = "start https://www.nexusmods.com/users/3040468?tab=user+files",
            postCreate = (
                function(self)
                    self.elements.outerContainer.borderAllSides = self.indent
                    self.elements.outerContainer.alignY = 1.0
                    self.elements.outerContainer.layoutHeightFraction = 1.0
                    self.elements.info.layoutOriginFractionX = 0.5
                end
            ),
        }

    end

    template:saveOnClose(config.configPath, config.mcm)
    local page = template:createSideBarPage("Настройки")
    addSideBar(page)

    page:createOnOffButton{
        label = "Включить Предыстории персонажей",
        variable = mwse.mcm.createTableVariable{
            id = "enableBackgrounds",
            table = config.mcm
        },
        description = "Включение и отключение мода."
    }

    page:createButton {
        buttonText = "Активировать меню выбора Предыстории",
        description = "Принудительно активирует меню выбора Предыстории персонажа. Будьте осторожны, активация этого параметра для существующего персонажа может привести к непредвиденным побочным эффектам!",
        inGameOnly = true,
        callback = function()
            timer.delayOneFrame(function()
                UI.createPerkMenu()
            end)
        end
    }

    page:createDropdown{
        label = "Уровень журнала",
        description = "Установите уровень ведения журнала событий mwse.log.",
        options = {
            { label = "TRACE", value = "TRACE"},
            { label = "DEBUG", value = "DEBUG"},
            { label = "INFO", value = "INFO"},
            { label = "ERROR", value = "ERROR"},
            { label = "NONE", value = "NONE"},
        },
        variable = mwse.mcm.createTableVariable{ id = "logLevel", table = config.mcm },
        callback = function(self)
            logger:setLogLevel(self.variable.value)
        end
    }

    template:createExclusionsPage{
        label = "Зеленый пакт",
        description = "Согласно Зеленому пакту, Босмер может употреблять в пищу только мясные продукты. Используйте эту страницу, чтобы настроить, какие ингредиенты можно употреблять в пищу.",
        leftListLabel = "Мясные продукты (разрешено)",
        rightListLabel = "Немясные продукты (запрещено)",
        variable = mwse.mcm.createTableVariable{
            id = "greenPactAllowed",
            table = config.mcm
        },
        filters = {
            {
                label = "Ингредиенты",
                type = "Object",
                objectType = tes3.objectType.ingredient
            }
        }
    }

    --local ratKing = page:createCategory("Rat King")
    local ratKing = template:createSideBarPage{
        label = Background.registeredBackgrounds.ratKing.name,
        description = Background.registeredBackgrounds.ratKing:getDescription()
    }
    ratKing:createSlider{
        label = "Интервал между призывом стаи крыс: %s (часы)",
        description = "Количество часов после призыва стаи крыс, через которое они могут появиться вновь. ",
        variable = mwse.mcm.createTableVariable{ id = "ratKingInterval", table = config.mcm },
        min = 0,
        max = 20,
        step = 1,
        jump = 1
    }
    ratKing:createSlider{
        label = "Шанс призыва: %s%%",
        description = "Вероятность призвать стаю крыс, когда начинается бой. ",
        variable = mwse.mcm.createTableVariable{ id = "ratKingChance", table = config.mcm },
        min = 1,
        max = 240,
        step = 1,
        jump = 24
    }

    --local inheritance = page:createCategory("Inheritance")
    local inheritance = template:createSideBarPage{
        label =  Background.registeredBackgrounds.inheritance.name,
        description = Background.registeredBackgrounds.inheritance:getDescription()
    }
    inheritance:createSlider{
        label = "Размер наследства: %s золотых",
        description = "Сумма денег, которую вы получите, выбрав предысторию Наследника. ",
        min = 1000,
        max = 10000,
        step = 1,
        jump = 1000,
        variable = mwse.mcm.createTableVariable{
            id = "inheritanceAmount",
            table = config.mcm,
        },
    }

    template:register()
end

event.register("modConfigReady", registerMCM)

event.register("initialized", function()
    Background.registerMcmPages(template)
end, { priority = -10000 })