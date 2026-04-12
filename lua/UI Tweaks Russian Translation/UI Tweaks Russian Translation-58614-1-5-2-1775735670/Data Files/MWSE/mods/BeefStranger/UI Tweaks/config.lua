local bs = require("BeefStranger.UI Tweaks.common")
local configPath = "UI Tweaks"
---@class bsDEBUGUITweaksMCM
local cfg = {}

---@class bsUITweaks.cfg<K, V>: { [K]: V }
local defaults = {
    barter = {
        enable = true,
        chanceColor = true,
        hold = true,
        showChance = false,
        showDisposition = true,
        showNpcStats = false,
        showPlayerStats = false,
        enableJunk = true,
        maxSell = 30,
    },
    contents = { enable = true, totalValue = false, showOwner = false },
    dialog = { enable = true, showKey = false, showClass = false },
    effects = { enable = false, menuModeAlpha = 0.5, updateRate = 0.2, borderMode = 3, durationThreshold = 2, pinnedAlpha = 0 },
    enchant = { enable = true, showGold = true },
    enchantedGear = {enable = true, highlightNew = true, hideVanilla = true, showVanillaOnHide = true},

    ---@class bsUITweaks.cfg.embed<K, V>: { [K]: V }
    embed = { enable = false, notify = true, }, 
    ---@class bsUITweaks.cfg.embed.persuade<K, V>: { [K]: V }
    embed_persuade = { enable = true, instantFight = false, hold = true, holdBribe = false },
    ---@class bsUITweaks.cfg.embed.repair<K, V>: { [K]: V }
    embed_repair = { enable = true },
    ---@class bsUITweaks.cfg.embed.spells<K, V>: { [K]: V }
    embed_spells = { enable = true },
    ---@class bsUITweaks.cfg.embed.train<K, V>: { [K]: V }
    embed_train = { enable = true },
    ---@class bsUITweaks.cfg.embed.travel<K, V>: { [K]: V }
    embed_travel = { enable = true, keybind = true },

    escape = {
        enable = true,
        keybind = tes3.keybind.menuMode,
        blacklist = {
            MenuName = true,
            MenuRaceSex = true,
            MenuCreateClass = true,
            MenuBirthSign = true,
            MenuStatReview = true,
            MenuSetValues = true,
        },
        menus = {
            bsItemSelect = true,
            bsTransferEnchant = true, MenuAlchemy = true,
            MenuBarter = true, MenuBook = true, MenuDialog = true,
            MenuEnchantment = true, MenuInventory = true, MenuInventorySelect = true,
            MenuJournal = true, MenuLoad = true, MenuPersuasion = true, MenuPrefs = true,
            MenuRepair = true, MenuRestWait = true, MenuSave = true,
            MenuScroll = true, MenuServiceRepair = true, MenuServiceSpells = true,
            MenuServiceTraining = true, MenuServiceTravel = true, MenuSpellmaking = true,
        },
    },
    hitChance = {enable = true, updateRate = 0.25, posX = 0.35, posY = 0.65, color = bs.colorTable(bs.rgb.blackColor, 0.8)},
    inv = {enable = true, potionHighlight = true},
    -- junk = {enable = true, maxSell = 20},
    manualAdd = "",
    magic = {enable = true, highlightNew = true, highlightColor = bs.colorTable(bs.rgb.bsPrettyGreen, 1)},
    multi = { enable = true, },
    persuade = { enable = true, hold = false, holdBribe = false, delay = 0.5, showKey = false },
    repair = { enable = true, interval = 0.1, select = true, hold = true },
    spellBarter = {enable = true, showCantCast = true},
    spellmaking = { enable = true, showGold = true, serviceOnly = true },
    tooltip = { enable = true, charge = true, showDur = true, junk = false, durationDigits = 0, totalWeight = true, totalValue = true },
    travel = { enable = true, showKey = true },
    wait = { enable = true, fullRest = true, },
    keybind = { ---@class bsUITweaks.cfg.keybind
        enable = true,
        ---Dialogue---
        barter = { keyCode = tes3.scanCode.b, isShiftDown = false, isAltDown = false, isControlDown = false, configPath = configPath},
        companion = { keyCode = tes3.scanCode.c, isShiftDown = false, isAltDown = false, isControlDown = false, configPath = configPath},
        enchanting = { keyCode = tes3.scanCode.e, isShiftDown = false, isAltDown = false, isControlDown = false, configPath = configPath},
        persuasion = { keyCode = tes3.scanCode.p, isShiftDown = false, isAltDown = false, isControlDown = false, configPath = configPath},
        repair = { keyCode = tes3.scanCode.r, isShiftDown = false, isAltDown = false, isControlDown = false, configPath = configPath},
        spellmaking = { keyCode = tes3.scanCode.v, isShiftDown = false, isAltDown = false, isControlDown = false, configPath = configPath},
        spells = { keyCode = tes3.scanCode.s, isShiftDown = false, isAltDown = false, isControlDown = false, configPath = configPath},
        training = { keyCode = tes3.scanCode.y, isShiftDown = false, isAltDown = false, isControlDown = false, configPath = configPath},
        travel = { keyCode = tes3.scanCode.t, isShiftDown = false, isAltDown = false, isControlDown = false, configPath = configPath},
        ---Persuasion---
        admire = { keyCode = tes3.scanCode.a, isShiftDown = false, isAltDown = false, isControlDown = false, configPath = configPath},
        intimidate = { keyCode = tes3.scanCode.i, isShiftDown = false, isAltDown = false, isControlDown = false, configPath = configPath},
        taunt = { keyCode = tes3.scanCode.t, isShiftDown = false, isAltDown = false, isControlDown = false, configPath = configPath},
        bribe10 = { keyCode = tes3.scanCode.numpad1, isShiftDown = false, isAltDown = false, isControlDown = false, configPath = configPath},
        bribe100 = { keyCode = tes3.scanCode.numpad2, isShiftDown = false, isAltDown = false, isControlDown = false, configPath = configPath},
        bribe1000 = { keyCode = tes3.scanCode.numpad3, isShiftDown = false, isAltDown = false, isControlDown = false, configPath = configPath},
        ---Wait/Rest---
        day = { keyCode = tes3.scanCode.f, isShiftDown = false, isAltDown = false, isControlDown = false, configPath = configPath},
        heal = { keyCode = tes3.scanCode.h, isShiftDown = false, isAltDown = false, isControlDown = false, configPath = configPath},
        wait = { keyCode = tes3.scanCode.w, isShiftDown = false, isAltDown = false, isControlDown = false, configPath = configPath},
        waitDown = { keyCode = tes3.scanCode.a, isShiftDown = false, isAltDown = false, isControlDown = false, configPath = configPath},
        waitUp = { keyCode = tes3.scanCode.d, isShiftDown = false, isAltDown = false, isControlDown = false, configPath = configPath},
        ---Barter---
        barterDown = { keyCode = tes3.scanCode.keyDown, isShiftDown = false, isAltDown = false, isControlDown = false, configPath = configPath},
        barterUp = { keyCode = tes3.scanCode.keyUp, isShiftDown = false, isAltDown = false, isControlDown = false, configPath = configPath},
        barterUp100 = { keyCode = tes3.scanCode.keyRight, isShiftDown = false, isAltDown = false, isControlDown = false, configPath = configPath},
        barterDown100 = { keyCode = tes3.scanCode.keyLeft, isShiftDown = false, isAltDown = false, isControlDown = false, configPath = configPath},
        offer = { keyCode = tes3.scanCode.enter, isShiftDown = false, isAltDown = false, isControlDown = false, configPath = configPath},
        markJunk = { keyCode = tes3.scanCode.lAlt, isShiftDown = false, isAltDown = false, isControlDown = false, configPath = configPath},


        take = { keyCode = tes3.scanCode.e, isShiftDown = false, isAltDown = false, isControlDown = false, configPath = configPath},
    },
    take = { enable = true },
    DEBUG = false
}
local function updateBarter() event.trigger(bs.UpdateBarter) end

---@class bsUITweaks.cfg
local config = mwse.loadConfig(configPath, defaults)

local templates = {}

local function registerModConfig()
---==========================================================Main=============================================================================
templates.main = mwse.mcm.createTemplate({ name = configPath, defaultConfig = defaults, config = config })
templates.main:saveOnClose(configPath, config)

local settings = templates.main:createPage({ label = "UI Tweaks Функции"})
-- local DEBUG = settings:createButton{buttonText = "Reload", label ="[DEBUG]Reload Files BEE"}
-- DEBUG.callback = function (self) event.trigger("UITweaksReloadFile") end
-- cfg.settings:createYesNoButton { label = "Enable HUD Tweaks", configKey = "enable", config = config.multi}
settings:createYesNoButton { label = "Включить компонент Торговля", configKey = "enable", callback = updateBarter, config = config.barter }
settings:createYesNoButton { label = "Включить компонент Содержимое", configKey = "enable", config = config.contents }
settings:createYesNoButton { label = "Включить компонент Диалоги", configKey = "enable", config = config.dialog }
settings:createYesNoButton { label = "Включить окно активных эффектов", configKey = "enable", config = config.effects }
settings:createYesNoButton { label = "Включить компонент Зачарование", configKey = "enable", config = config.enchant }
settings:createYesNoButton { label = "Включить окно зачарованного снаряжения", configKey = "enable", config = config.enchantedGear }
settings:createYesNoButton { label = "Включить встраивание меню услуг в окно диалога", configKey = "enable", config = config.embed }
settings:createYesNoButton { label = "Включить отображение шанса попадания", configKey = "enable", config = config.hitChance }
settings:createYesNoButton { label = "Включить горячие клавиши", configKey = "enable", config = config.keybind }
settings:createYesNoButton { label = "Включить компонент Убеждение", configKey = "enable", config = config.persuade }
settings:createYesNoButton { label = "Включить компонент Магия", configKey = "enable", config = config.magic }
settings:createYesNoButton { label = "Включить быстрый выход из меню", configKey = "enable", config = config.escape }
settings:createYesNoButton { label = "Включить быстрый подбор предметов", configKey = "enable", config = config.take }
settings:createYesNoButton { label = "Включить компонент Ремонт", configKey = "enable", config = config.repair }
settings:createYesNoButton { label = "Включить компонент Продажа заклинаний", configKey = "enable", config = config.spellBarter }
settings:createYesNoButton { label = "Включить компонент Создание заклинаний", configKey = "enable", config = config.spellmaking }
settings:createYesNoButton { label = "Включить Всплывающие подсказки", configKey = "enable", config = config.tooltip }
settings:createYesNoButton { label = "Включить компонент Путешествие", configKey = "enable", config = config.travel }
settings:createYesNoButton { label = "Включить компонент Ожидание/отдых", configKey = "enable", config = config.wait }

local hotkeys = templates.main:createPage({label = "Горячие клавиши", showReset = true, config = config.keybind, defaultConfig = defaults.keybind})
local barterKey = cfg:newCat(hotkeys, "Торговля")
    cfg:keybind(barterKey, "Уменьшить цену", "barterDown")
    cfg:keybind(barterKey, "Увеличить цену", "barterUp")
    cfg:keybind(barterKey, "Уменьшить цену на 100", "barterDown100")
    cfg:keybind(barterKey, "Увеличить цену на 100", "barterUp100")
    cfg:keybind(barterKey, "Подтвердить предложение", "offer")
    cfg:keybind(barterKey, "Пометить как \"Хлам\"", "markJunk")

local dialogKey = cfg:newCat(hotkeys, "Диалоги")
    cfg:keybind(dialogKey, "Торговать", "barter")
    cfg:keybind(dialogKey, "Доля", "companion")
    cfg:keybind(dialogKey, "Зачарование", "enchanting")
    cfg:keybind(dialogKey, "Убеждение", "persuasion")
    cfg:keybind(dialogKey, "Ремонт", "repair")
    cfg:keybind(dialogKey, "Создание заклинаний", "spellmaking")
    cfg:keybind(dialogKey, "Заклинания", "spells")
    cfg:keybind(dialogKey, "Обучение", "training")
    cfg:keybind(dialogKey, "Путешествие", "travel")

local persuadeKey = cfg:newCat(hotkeys, "Убеждение")
    cfg:keybind(persuadeKey, "Вежливо", "admire")
    cfg:keybind(persuadeKey, "Угрожающе", "intimidate")
    cfg:keybind(persuadeKey, "Оскорбительно", "taunt")
    cfg:keybind(persuadeKey, "Дать 10 монет", "bribe10")
    cfg:keybind(persuadeKey, "Дать 100 монет", "bribe100")
    cfg:keybind(persuadeKey, "Дать 1000 монет", "bribe1000")

local takeKey = cfg:newCat(hotkeys, "Взять книгу/свиток")
    cfg:keybind(takeKey, "Взять", "take")

local fullRestKey = cfg:newCat(hotkeys, "Ожидание/отдых")
    cfg:keybind(fullRestKey, "Ждать/отдыхать", "wait")
    cfg:keybind(fullRestKey, "Ожидание/отдых - 1 час", "waitDown")
    cfg:keybind(fullRestKey, "Ожидание/отдых + 1 час", "waitUp")
    cfg:keybind(fullRestKey, "Выздороветь", "heal")
    cfg:keybind(fullRestKey, "Отдых/ожидание 24 часа", "day")
---==========================================================Inventory=============================================================================
-- local inventory = mwse.mcm.createTemplate({ name = configPath..": Inventory", defaultConfig = defaults, config = config })
templates.inventory = mwse.mcm.createTemplate({ name = configPath..": Инвентарь", defaultConfig = defaults, config = config })
templates.inventory:saveOnClose(configPath, config)

local active = templates.inventory:createPage({label = "Активные эффекты", config = config.effects, showReset = true, defaultConfig = defaults.effects})
    active:createDropdown({
        label = "Способ выделения закрепленных активных эффектов", configKey = "borderMode",
        options = { {label = "Тонкая рамка", value = 1}, {label = "Фон", value = 2}, {label = "Нет", value = 3}, },
        callback = function (self) event.trigger("bs_MenuEffects_Update") end,
    })

    active:createSlider{label = "Прозрачность окна в режиме меню", min = 0, max = 1, configKey = "menuModeAlpha", step = 0.05, jump = 0.1, decimalPlaces = 2}
    active:createSlider{label = "Прозрачность окна в режиме закрепления на экране", min = 0, max = 1, configKey = "pinnedAlpha", step = 0.05, jump = 0.1, decimalPlaces = 2}
    active:createSlider{label = "Порог длительности эффекта", min = 0, max = 30, configKey = "durationThreshold"}
    active:createSlider{label = "Частота обновления", min = 0.05, max = 1, configKey = "updateRate", step = 0.1, jump = 0.1, decimalPlaces = 2}

local barter = templates.inventory:createPage{ label = "Торговля", config = config.barter, showReset = true, defaultConfig = defaults.barter }
    local barter_stats = barter:createCategory({label = "Статистика"})
        barter_stats:createYesNoButton { label = "Показать шанс сделки", configKey = "showChance"}
        barter_stats:createYesNoButton { label = "Изменить цвет значения шанса в зависимости от шанса успеха", configKey = "chanceColor"}
        barter_stats:createYesNoButton { label = "Показать расположение", configKey = "showDisposition", callback = updateBarter }
        barter_stats:createYesNoButton { label = "Показать уровень навыков NPC", configKey = "showNpcStats", callback = updateBarter }
        barter_stats:createYesNoButton { label = "Показать уровень навыков игрока", configKey = "showPlayerStats", callback = updateBarter }
    local barter_junk = barter:createCategory({label = "Хлам"})
        barter_junk:createYesNoButton { label = "Включить кнопку \"Продать хлам\"", configKey = "enableJunk"}
        barter_junk:createSlider { label = "Максимальное количество хлама для продажи", configKey = "maxSell", min = 1, max = 100, step = 1, jump = 1 }

local contents = templates.inventory:createPage({label = "Содержимое", config = config.contents, showReset = true, defaultConfig = defaults.contents})
    contents:createYesNoButton({label = "Показать общую стоимость содержимого контейнеров", configKey = "totalValue"})
    contents:createYesNoButton({label = "Показать владельца и права собственности в строке заголовка", configKey = "showOwner"})

local gear = templates.inventory:createPage{label = "Зачарованное снаряжение", config = config.enchantedGear, showReset = true, defaultConfig = defaults.enchantedGear}
    gear:createYesNoButton({label = "Подсвечивать новые зачарования/свитки", configKey = "highlightNew"})
    gear:createYesNoButton({label = "Скрывать стандартные зачарования/свитки", configKey = "hideVanilla"})
    gear:createYesNoButton({label = "Показывать стандартные зачарования/свитки, когда окно зачарованного снаряжения скрыто", configKey = "showVanillaOnHide"})

local inv = templates.inventory:createPage{label = "Инвентарь", config = config.inv, showReset = true, defaultConfig = defaults.inv}
    inv:createYesNoButton({label = "Подсвечивать зелья по типу", configKey = "potionHighlight"})

local magic = templates.inventory:createPage{label = "Магия", config = config.magic, showReset = true, defaultConfig = defaults.magic}
    magic:createYesNoButton({label = "Подсвечивать новые заклинания/зачарования", configKey = "highlightNew"})
    -- magic:createColorPicker({label = "New Spell/Enchant Hightlight Color", configKey = "highlightColor", alpha = true})
    magic:createButton({label = "Сбросить список новой магии", inGameOnly = true, buttonText = "Сброс", callback =
        function (self)
            bs.initData().lookedAt = {}
            tes3.messageBox("Список новых заклинаний/зачарований сброшен")
        end})
---==========================================================Service=============================================================================
-- local service = mwse.mcm.createTemplate({ name = configPath .. ": Services", defaultConfig = defaults, config = config })
templates.service = mwse.mcm.createTemplate({ name = configPath .. ": Услуги", defaultConfig = defaults, config = config })
templates.service:saveOnClose(configPath, config)

local enchant = templates.service:createPage{ label = "Зачарование", config = config.enchant, showReset = true, defaultConfig = defaults.enchant }
enchant:createYesNoButton({label = "Показать золото игрока", configKey = "showGold"})

local repair = templates.service:createPage{label = "Ремонт", config = config.repair, showReset = true, defaultConfig = defaults.repair}
    repair:createYesNoButton({label = "Выбор инструмента для ремонта", configKey = "select"})
    repair:createYesNoButton({label = "Удерживайте кнопку для ремонта", configKey = "hold"})
    repair:createSlider { label = "Интервал ожидания для ремонта", configKey = "interval", min = 0.01, max = 1, step = 0.01, jump = 0.1, decimalPlaces = 2 }

local spellBarter = templates.service:createPage{ label = "Заклинания", config = config.spellBarter, showReset = true, defaultConfig = defaults.spellmaking }
    spellBarter:createYesNoButton({label = "Выделить недоступные заклинания", configKey = "showCantCast"})

local spellmaking = templates.service:createPage{ label = "Создание заклинаний", config = config.spellmaking, showReset = true, defaultConfig = defaults.spellmaking }
    spellmaking:createYesNoButton({label = "Показать золото только в заклинаниях NPC", configKey = "serviceOnly"})
    spellmaking:createYesNoButton({label = "Показать золото игрока", configKey = "showGold"})

local travel = templates.service:createPage{ label = "Путешествие", config = config.travel, showReset = true, defaultConfig = defaults.travel }
    travel:createYesNoButton{label = "Показать горячие клавиши", configKey = "showKey"}
---==========================================================EmbeddedService=============================================================================
    -- local embed = mwse.mcm.createTemplate({ name = configPath .. ": Embedded", defaultConfig = defaults, config = config })
templates.embed = mwse.mcm.createTemplate({ name = configPath .. ": Встроенные меню услуг", defaultConfig = defaults, config = config })
templates.embed:saveOnClose(configPath, config)

local embedMain = templates.embed:createPage { label = "Встроенные меню услуг", config = config.embed, showReset = true, defaultConfig = defaults.embed }
    embedMain:createYesNoButton({ label = "Показать подсказки клавиш", configKey = "notify" })
    embedMain:createYesNoButton({ label = "Включить встроенное меню для убеждения", config = config.embed_persuade, configKey = "enable" })
    embedMain:createYesNoButton({ label = "Включить встроенное меню для ремонта", config = config.embed_repair, configKey = "enable" })
    embedMain:createYesNoButton({ label = "Включить встроенное меню для заклинаний", config = config.embed_spells, configKey = "enable" })
    embedMain:createYesNoButton({ label = "Включить встроенное меню для обучения", config = config.embed_train, configKey = "enable" })
    embedMain:createYesNoButton({ label = "Включить встроенное меню для путешествий", config = config.embed_travel, configKey = "enable" })

local embedPersuade = templates.embed:createPage{label = "Убеждение", config = config.embed_persuade, showReset = true, defaultConfig = defaults.embed_persuade}
    -- embedPersuade:createYesNoButton({label = "Enable Embedded Persuadion", configKey = "enable"})
    embedPersuade:createYesNoButton({label = "Мгновенное начало боя при успешной насмешке", configKey = "instantFight"})
    embedPersuade:createYesNoButton({label = "Удерживать, чтобы убеждать", configKey = "hold"})
    embedPersuade:createYesNoButton({label = "Удерживать, чтобы подкупить", configKey = "holdBribe"})

    -- local embedRepair = embed:createPage{label = "Repair", config = config.embed_repair, showReset = true, defaultConfig = defaults.embed_repair}

    -- local embedSpells = embed:createPage{label = "Spells", config = config.embed_spells, showReset = true, defaultConfig = defaults.embed_spells}

    -- local embedTrain = embed:createPage{label = "Training", config = config.embed_train, showReset = true, defaultConfig = defaults.embed_train}

    -- local embedTravel = embed:createPage{label = "Travel", config = config.embed_travel, showReset = true, defaultConfig = defaults.embed_travel}
---==========================================================Tooltips=============================================================================
    -- local tooltips = mwse.mcm.createTemplate({ name = configPath .. ": Tooltips", defaultConfig = defaults, config = config })
templates.tooltips = mwse.mcm.createTemplate({ name = configPath .. ": Подсказки", defaultConfig = defaults, config = config })
templates.tooltips:saveOnClose(configPath, config)

local hitChance = templates.tooltips:createPage { label = "Шанс попадания", config = config.hitChance, showReset = true, defaultConfig = defaults.hitChance }
hitChance:createYesNoButton({label = "Показать шанс попадания", configKey = "enable"})
    hitChance:createSlider({ label = "Частота обновления", min = 0.01, max = 5, configKey = "updateRate", decimalPlaces = 2, step = 0.01, jump = 0.1 })
    hitChance:createCategory({ label = "Позиция: X: 0 от левого края, Y: 0 от верхнего края" })
    hitChance:createSlider({ label = "Позиция X", configKey = "posX", min = 0, max = 1, decimalPlaces = 2, step = 0.01, jump = 0.1 })
    hitChance:createSlider({ label = "Позиция Y", configKey = "posY", min = 0, max = 1, decimalPlaces = 2, step = 0.01, jump = 0.1 })

-- local color = hitChance:createColorPicker({ label = "Background Color", configKey = "color", alpha = true })
--     color.indent = 0

local tooltip = templates.tooltips:createPage { label = "Всплывающие подсказки", config = config.tooltip, showReset = true, defaultConfig = defaults.tooltip }
    tooltip:createYesNoButton({ label = "Показать стоимость заряда зачарования", configKey = "charge" })
    tooltip:createYesNoButton({ label = "Показать длительность на значках активных эффектов", configKey = "showDur" })
    tooltip:createYesNoButton { label = "Показать всплывающую подсказку \"Хлам\"", configKey = "junk" }
    tooltip:createYesNoButton { label = "Показать общий вес \"наложенных\" предметов", configKey = "totalWeight" }
    tooltip:createSlider { label = "Отображать оставшееся время в секундах", configKey = "durationDigits", min = 0, max = 5, step = 1, jump = 1 }
---==========================================================Dialogue=============================================================================
-- local dialogue = mwse.mcm.createTemplate({ name = configPath .. ": Dialogue", defaultConfig = defaults, config = config })
templates.dialogue = mwse.mcm.createTemplate({ name = configPath .. ": Диалоги", defaultConfig = defaults, config = config })
templates.dialogue:saveOnClose(configPath, config)

local dialog = templates.dialogue:createPage{ label = "Диалоги", config = config.dialog, showReset = true, defaultConfig = defaults.dialog }
    dialog:createYesNoButton({label = "Показать класс NPC", configKey = "showClass"})
    dialog:createYesNoButton({label = "Показать подсказки клавиш", configKey = "showKey"})

local persuade = templates.dialogue:createPage{ label = "Убеждение", config = config.persuade, showReset = true, defaultConfig = defaults.persuade }
    persuade:createYesNoButton({label = "Показать подсказки клавиш", configKey = "showKey"})
    persuade:createYesNoButton({label = "Удерживайте клавишу, для быстрого убеждения", configKey = "hold"})
    persuade:createYesNoButton({label = "Удерживайте клавишу, для быстрого подкупа", configKey = "holdBribe"})
    persuade:createSlider { label = "Задержка при удержании клавиши убеждения", configKey = "delay",
    min = 0.01, max = 1, step = 0.01, jump = 0.01, decimalPlaces = 2 }
---==========================================================Misc=============================================================================
templates.misc = mwse.mcm.createTemplate({ name = configPath .. ": Разное", defaultConfig = defaults, config = config })
templates.misc:saveOnClose(configPath, config)

local waitRest = templates.misc:createPage{ label = "Ожидание/отдых", config = config.wait }
    waitRest:createYesNoButton({ label = "Отдых/ожидание 24 часа", configKey = "fullRest", })


local escape = templates.misc:createPage{label = "Быстрый выход", config = config.escape}
    escape:createDropdown({
        label = "Клавиша быстрого выхода",
        configKey = "keybind",
        options = {
            {label = "Режим меню: Правая кнопка мыши", value = tes3.keybind.menuMode},
            {label = "Escape: Escape", value = tes3.keybind.escape}
        }
    })

    templates.misc:createExclusionsPage({
        label = "Черный список для быстрого выхода",
        leftListLabel = "Отключенные меню",
        rightListLabel = "Включенные меню",
        config = config.escape,
        defaultConfig = defaults.escape,
        showReset = true,
        configKey = "blacklist",
        filters = { {
            label = "Ингредиенты",
            callback = function()
                local menu = {}
                for index, value in pairs(bs.menus) do
                    if type(value) == "string" then
                        table.insert(menu, value)
                    end
                end
                table.sort(menu)
                return menu
            end
        }, },
    })

---==========================================================Multi=============================================================================
    -- templates.multi = mwse.mcm.createTemplate({ name = configPath .. ": HUD", defaultConfig = defaults, config = config })
    -- templates.multi:saveOnClose(configPath, config)
---========================================================== =============================================================================

    for k, v in pairs(templates) do
        v:register()
    end


    -- templates.dialogue:register()
    -- templates.inventory:register()
    -- templates.main:register()
    -- templates.misc:register()
    -- templates.embed:register()
    -- templates.service:register()
    -- templates.tooltips:register()
end
event.register(tes3.event.modConfigReady, registerModConfig)

---@param page mwseMCMExclusionsPage|mwseMCMFilterPage|mwseMCMMouseOverPage|mwseMCMPage|mwseMCMSideBarPage
---@param label string
function cfg:newCat(page, label)
    return page:createCategory({label = label})
end

---comments
---@param page mwseMCMExclusionsPage|mwseMCMFilterPage|mwseMCMMouseOverPage|mwseMCMPage|mwseMCMSideBarPage
---@param label string
---@param key string
---@return mwseMCMKeyBinder
function cfg:keybind(page, label, key)
    return page:createKeyBinder({ label = label, configKey = key })
end

return config