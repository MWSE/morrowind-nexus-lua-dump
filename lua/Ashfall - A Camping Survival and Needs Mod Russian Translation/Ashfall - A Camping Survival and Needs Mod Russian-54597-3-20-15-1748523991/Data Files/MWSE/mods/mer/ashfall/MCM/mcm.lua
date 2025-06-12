local common = require("mer.ashfall.common.common")
local versionController = require("mer.ashfall.common.versionController")
local config = require("mer.ashfall.config").config

local LINKS_LIST = {
    {
        text = "История версий",
        url = "https://github.com/jhaakma/ashfall/releases"
    },
    {
        text = "Информация",
        url = "https://github.com/jhaakma/ashfall/wiki"
    },
    {
        text = "Страница мода на Nexusmods",
        url = "https://www.nexusmods.com/morrowind/mods/49057"
    },
    {
        text = "Поддержать автора",
        url = "https://ko-fi.com/merlord"
    },
}
local CREDITS_LIST = {
    {
        text = "Сделано Merlord",
        url = "https://www.nexusmods.com/users/3040468?tab=user+files",
    },
    {
        text = "Графический дизайн: XeroFoxx",
        url = "https://www.youtube.com/channel/UCcx5oYt3NtLtadZTSjI3KEw",
    },
    {
        text = "Навесы для палатки: Draconik",
        url = "https://www.nexusmods.com/morrowind/users/86600168",
    },
    {
        text = "Сетки для ловца снов: Remiros",
        url = "https://www.nexusmods.com/morrowind/users/899234",
    },
    {
        text = "Анимация сидения и сна: Vidi Aquam",
        url = "https://www.nexusmods.com/morrowind/mods/48782",
    },
    {
        text = "Стеклянное оружие (и куча других сеток): Melchior Dahrk",
        url = "https://www.nexusmods.com/morrowind/users/962116"
    },
}
local SIDE_BAR_DEFAULT =
[[Используйте меню конфигурации, чтобы включить или выключить различные механики, функции и уведомления.

Наведите курсор на отдельные параметры, чтобы увидеть дополнительную информацию.]]


local function addSideBar(component)
    local versionText = string.format("Пеплопад Версия %s", versionController.getVersion())
    component.sidebar:createCategory(versionText)
    component.sidebar:createInfo{ text = SIDE_BAR_DEFAULT}

    local linksCategory = component.sidebar:createCategory("Ссылки")
    for _, link in ipairs(LINKS_LIST) do
        linksCategory:createHyperLink{ text = link.text, url = link.url }
    end
    local creditsCategory = component.sidebar:createCategory("Авторы")
    for _, credit in ipairs(CREDITS_LIST) do
        creditsCategory:createHyperLink{ text = credit.text, url = credit.url }
    end
end


local function registerModConfig()
    local template = mwse.mcm.createTemplate{ name = "Пеплопад", headerImagePath = "textures/ashfall/MCMHeader.tga" }
    template.onClose = function()
        config.save()
    end
    template:register()
    do --General Settings Page
        local pageGeneral = template:createSideBarPage({
            label = "Основные настройки",
        })
        addSideBar(pageGeneral)

        do --Default Settings Category
            local categoryOverrides = pageGeneral:createCategory{
                label = "Переназначить свойства",
                description = "Установите, какие значения по умолчанию будут изменены при запуске новой игры."
            }
            categoryOverrides:createYesNoButton{
                label = "Изменить свойства предметов",
                description = (
                    "Изменяет вес и стоимость некоторых изначальных ингредиентов, таких как хлеб и мясо, "..
                    "а также емкости для воды, такие как бутылки и горшки, чтобы сделать их дополнительные свойства " ..
                    "полезными в механике выживания."
                ),
                variable = mwse.mcm.createTableVariable{
                    id = "overrideFood",
                    table = config,
                    restartRequired = true,
                    --restartRequiredMessage = "Changing this setting requires a game restart to come into effect."
                }
            }

            categoryOverrides:createYesNoButton{
                label = "Изменить шкалу времени",
                description = (
                    "Изменяет шкалу времени в каждой новой игре. Чтобы настроить шкалу времени для "..
                    "текущей игры, установите значение Вкл и отрегулируйте ползунком ниже."
                ),
                variable = mwse.mcm.createTableVariable{ id = "overrideTimeScale", table = config },
                callback = function(self)
                    if tes3.player then
                        if self.variable.value == true then

                            local newTimeScale = config.manualTimeScale
                            tes3.setGlobal("TimeScale", newTimeScale)
                        end
                    end
                end
            }

            categoryOverrides:createSlider{
                label = "Шкала времени по умолчанию",
                description = ("Изменяет скорость смены дня и ночи. Значение 1 заставляет день идти со скоростью реального времени; "
                .."в реальной жизни игровой день длился бы 24 часа. Значение 10 сделает его в десять раз быстрее, чем в реальном времени. "
                .."(т.е. один игровой день продлится 2,4 часа) и т.д. "
                .."\n\nОригинальная шкала времени равна 30 (1 игровой день = 48 реальных минут), однако настоятельно рекомендуется использовать значение 15-25."),
                min = 0,
                max = 50,
                step = 1,
                jump = 5,
                variable = mwse.mcm.createTableVariable{ id = "manualTimeScale", table = config },
                callback = function(self)
                    if tes3.player then
                        if config.overrideTimeScale == true then
                            tes3.setGlobal("TimeScale", self.variable.value)
                        end
                    end
                end
            }

        end

        do --Survival Mechanics Category
            local categorySurvival = pageGeneral:createCategory{
                label = "Механика выживания",
                description = "Включить\\Выключить механики выживания Пеплопада."
            }
            categorySurvival:createYesNoButton{
                label = "Метеозависимость",
                description = (
                    "Если эта функция включена, вам нужно будет искать укрытие от экстремальных температур или других неблагоприятных погодных условий. \n\n" ..
                    "Ночью или в холодном климате хорошо питайтесь, носите много одежды, используйте факелы, костры или оставайтесь в помещении, чтобы согреться. \n\n" ..
                    "В жарком климате не допускайте обезвоживания, носите легкую одежду и избегайте источников тепла, таких как огонь, лава или пар. \n\n" ..
                    "Если промокнете, то замерзнете и станете уязвимее к ударам, но зато повысится сопртивление огню.\n\n"
                ),
                variable = mwse.mcm.createTableVariable{ id = "enableTemperatureEffects", table = config },
            }
            categorySurvival:createYesNoButton{
                label = "Голод",
                description = (
                    "При включении этой функции, вам придется регулярно есть пищу, чтобы выжить. " ..
                    "Ингредиенты обладают низкой питательной ценностью, поэтому лучше готовить еду на кострах, в кастрюлях и плитах. "
                ),
                variable = mwse.mcm.createTableVariable{ id = "enableHunger", table = config },
            }
            categorySurvival:createYesNoButton{
                label = "Жажда",
                description = (
                    "При включении этой функции, вам придется регулярно пить воду, чтобы выжить " ..
                    "Пополняйте запасы воды в любом близлежащем ручье, колодце или бочке. Вы также можете пить прямо из источников воды."
                ),
                variable = mwse.mcm.createTableVariable{ id = "enableThirst", table = config },
                callback = tes3ui.updateInventoryTiles --to clear water bottle icons
            }
            categorySurvival:createYesNoButton{
                label = "Сон",
                description = (
                    "При включении этой функции, вам придется регулярно спать, чтобы избежать усталости и снижения навыков. " ..
                    "Сон в кровати или спальнике позволит вам \"хорошо отдохнуть\", в то время как сон под открытым небом не сможет полностью восстановить вашу усталость."
                ),
                variable = mwse.mcm.createTableVariable{ id = "enableTiredness", table = config },
            }
            categorySurvival:createYesNoButton{
                label = "Мор",
                description = "При включении этой функции, вы сможете заразиться Мором во время бури. Отключите для совместимости с другими модами.",
                variable = mwse.mcm.createTableVariable{ id = "enableBlight", table = config },
            }

        end --\Survival Mechanics Category

        do --Condition Updates Category
            local categoryConditions = pageGeneral:createCategory{
                label = "Уведомления",
                description = "Выберите какие уведомления будут отображаться, при изменении состояния персонажа.",
            }

            categoryConditions:createOnOffButton{
                label = "Температура",
                description = "Показывать сообщения при изменении температурного режима персонажа.",
                variable = mwse.mcm.createTableVariable{ id = "showTemp", table = config },
            }
            categoryConditions:createOnOffButton{
                label = "Голод",
                description = "Показывать сообщения когда персонаж проголодается.",
                variable = mwse.mcm.createTableVariable{ id = "showHunger", table = config },
            }
            categoryConditions:createOnOffButton{
                label = "Жажда",
                description = "Показывать сообщения когда персонаж испытывает жажду.",
                variable = mwse.mcm.createTableVariable{ id = "showThirst", table = config },
            }
            categoryConditions:createOnOffButton{
                label = "Сон",
                description = "Показывать сообщения при изменении степени усталости персонажа.",
                variable = mwse.mcm.createTableVariable{ id = "showTiredness", table = config },
            }
            categoryConditions:createOnOffButton{
                label = "Промокание",
                description = "Показывать сообщения когда персонаж промок.",
                variable = mwse.mcm.createTableVariable{ id = "showWetness", table = config },
            }
        end --\Condition Updates Category

        do -- Enable Features
            local categoryFeatures = pageGeneral:createCategory{
                label = "Функции",
                description = "Включите\\Выключить различные функции Пеплопада."
            }

            categoryFeatures:createYesNoButton{
                label = "Ремесло ",
                description = "Что бы открыть окно ремесла, экипируйте любой предмет в свойствах которого есть пометка 'Материал для ремесла'.",
                variable = mwse.mcm.createTableVariable{ id = "bushcraftingEnabled", table = config }
            }

            categoryFeatures:createYesNoButton{
                label = "Изготовление требует времени",
                description = "Если эта функция включена, на изготовление предметов будет тратится некотрое количество времени. Отключите эту функцию, чтобы создавать предметы мгновенно.",
                variable = mwse.mcm.createTableVariable{ id = "craftingTakesTime", table = config }
            }

            categoryFeatures:createYesNoButton{
                label = "Свежевание",
                description = "Включает механику свежевания. Используйте нож, чтобы снять с туши животного шкуру, мех и мясо.",
                variable = mwse.mcm.createTableVariable{ id = "enableSkinning", table = config }
            }

            categoryFeatures:createYesNoButton{
                label = "Валежник",
                description = "Добавляет упавшие ветки рядом с деревьями, которые можно собирать на дрова. Это может привести к увеличению времени загрузки при смене ячейки на слабых системах. Выключите, если у вас возникают проблемы с производительностью.",
                variable = mwse.mcm.createTableVariable{ id = "enableBranchPlacement", table = config }
            }

            categoryFeatures:createYesNoButton{
                label = "Пар изо рта",
                description = (
                    "Добавляет эффект пара изо рта NPC и игроку при низких температурах. \n\n" ..
                    "Не требует активации механики выживания \"Метеозависимость\". "
                ),
                variable = mwse.mcm.createTableVariable{ id = "showFrostBreath", table = config },
            }

            categoryFeatures:createYesNoButton{
                label = "Анимированная рубка деревьев",
                description = "Если эта опция включена, деревья и растиния будут падать после того, как вы соберете с них слишком много материалов. Они востановятся, при следующем заходе в ячейку. Тени и отражения воды в реальном времени обновляться не будут, поскольку они основаны на статике удаленного ландшафта MGE XE, что может привести к незначительным визуальным несоответствиям.",
                variable = mwse.mcm.createTableVariable{ id = "disableHarvested", table = config}
            }

            categoryFeatures:createYesNoButton{
                label = "Разрешить зараженное мясо",
                description = (
                    "При включении этой функции, мясо, добытое от больных животных, может вызвать у вас заболевание, при употреблении в пищу."
                ),
                variable = mwse.mcm.createTableVariable{ id = "enableDiseasedMeat", table = config },
            }
        end

        do --Miscellanious Category

            local categoryMisc = pageGeneral:createCategory{
                label = "Разные",
                description = "Настройки Пеплопада не связаные с механикой выживания.",
            }

            categoryMisc:createKeyBinder{
                label = "Функциональная клавиша",
                description = "Клавиша для доступа к дополнительным функциям. Например, удерживайте эту клавишу при активации бутылки с водой, чтобы открыть меню воды (чтобы вылить или выпить воду). По умолчанию: Левый Shift.",
                allowCombinations = false,
                variable = mwse.mcm.createTableVariable{ id = "modifierHotKey", table = config },
            }

            categoryMisc:createYesNoButton{
                label = "Показывать всплывающие подсказки",
                description = "Активирует дополнительные всплывающие подсказки, объясняющие различные механики.",
                variable = mwse.mcm.createTableVariable{ id = "showHints", table = config }
            }

            categoryMisc:createYesNoButton{
                label = "Стартовый набор для выживания",
                description = "Начните новую игру с деревянным топором, спальником и котелком для приготовления пищи.",
                variable = mwse.mcm.createTableVariable{ id = "startingEquipment", table = config }
            }

            categoryMisc:createYesNoButton{
                label = "Смерть от голода\\жажды",
                description = (
                    "При включении этой функции, вы можете умереть от голода или жажды. В противном случае ваше здоровье упадет до 1."
                ),
                variable = mwse.mcm.createTableVariable{ id = "needsCanKill", table = config },
            }

            categoryMisc:createYesNoButton{
                label = "Отображать рюкзаки",
                description = "Отключите эту функцию, чтобы рюкзаки не отображались у вас на спине.",
                variable = mwse.mcm.createTableVariable{ id = "showBackpacks", table = config },
            }

            categoryMisc:createYesNoButton{
                label = "Прозрачные палатки",
                description = "При включении этой функции, внешняя часть вашей палатки будет становиться прозрачной, когда вы входите внутрь.",
                variable = mwse.mcm.createTableVariable{ id = "seeThroughTents", table = config }
            }

            categoryMisc:createYesNoButton{
                label = "Атронахи восстанавливают магию от питья",
                description = "Когда вы испытываете жажду, ваша максимальная магия (а, следовательно, и текущая магия) уменьшается. По умолчанию утоление жажды восстанавливает то же количество текущей магии, что и было потеряно из-за жажды, даже если у вас есть знак Атронаха. Отключите этот параметр, чтобы предотвратить увеличение магии. Имейте в виду, что вам, как Атронаху, нужно будет найти способы восстановить свою магию после утоления жажды.",
                variable = mwse.mcm.createTableVariable{ id = "atronachRecoverMagickaDrinking", table = config }
            }

            categoryMisc:createYesNoButton{
                label = "Зелья утоляют жажду",
                description = "При включении этой функции, употребление зелья немного утолит жажду.",
                variable = mwse.mcm.createTableVariable{ id = "potionsHydrate", table = config }
            }

            categoryMisc:createYesNoButton{
                label = "Рубка деревьев только в дикой местности",
                description = (
                    "При включении этой опции, вы не сможете рубить деревья, находясь в городе."
                ),
                variable = mwse.mcm.createTableVariable{ id = "illegalHarvest", table = config },
            }

            categoryMisc:createYesNoButton{
                label = "Установка палатки в населенных пунктах",
                description = (
                    "При включении данной функции, вы сможете разжигать костры и ставить палатки на территории поселений."
                ),
                variable = mwse.mcm.createTableVariable{ id = "canCampInSettlements", table = config },
            }

            categoryMisc:createYesNoButton{
                label = "Отдых на улице без кровати",
                description = (
                    "При включении данной функции, вы сможете отдыхать на улице на земле без спального места или палатки."
                ),
                variable = mwse.mcm.createTableVariable{ id = "canRestOnGround", table = config },
            }

        end --\Miscellanious Category

    end -- \General Settings Page

    do --Mod values page
        local pageModValues = template:createSideBarPage{
            label = "Значения свойств"
        }
        addSideBar(pageModValues)

        do -- updates
            local categoryUpdates = pageModValues:createCategory{
                label = "Интервалы обновления",
                description = "Интервалы обновления различных функций.",
            }

            categoryUpdates:createSlider{
                label = "Частота обновлений лучей (милисекунды)",
                description = "Частота обновлений зависимых от теста лучей. Увеличение этого параметра может повысить производительность, но при этом всплывающие подсказки и т. д. будут обновляться реже. Чтобы это значение вступило в силу, необходимо перезагрузить игру.",
                min = 10,
                max = 2000,
                step = 10,
                jump = 100,
                variable = mwse.mcm.createTableVariable{ id = "rayTestUpdateMilliseconds", table = config },
            }
        end

        do -- Temperature
            local categoryTemperature = pageModValues:createCategory{
                label = "Температура",
                description = "Изменения температуры.",
            }
            categoryTemperature:createSlider{
                label = "Интенсивность холода: %s%%",
                description = string.format("Изменяет интенсивность всех источников холода."
                    .. "\n\nПо умолчанию: %s.",
                    common.defaultValues.globalColdEffect
                ),
                min = -50,
                max = 50,
                step = 1,
                variable = mwse.mcm.createTableVariable{ id = "globalColdEffect", table = config },
                callback = function()
                    common.data.globalColdEffect = 1 + config.globalColdEffect * 0.01
                end
            }
            categoryTemperature:createSlider{
                label = "Интенсивность тепла: %s%%",
                description = string.format("Изменяет интенсивность всех источников тепла."
                    .. "\n\nПо умолчанию: %s.",
                    common.defaultValues.globalWarmEffect
                ),
                min = -50,
                max = 50,
                step = 1,
                variable = mwse.mcm.createTableVariable{ id = "globalWarmEffect", table = config },
                callback = function()
                    common.data.globalWarmEffect = 1 + config.globalWarmEffect * 0.01
                end
            }
        end
        do --Hunger Category
            local categoryTime = pageModValues:createCategory{
                label = "Голод",
                description = "Изменение силы голода.",
            }


            categoryTime:createSlider{
                label = "Сила голода",
                description = string.format(
                    "Определяет, на сколько усиливается голод за час. При значении 10, голод увеличивается на 1%% в час "
                    .."(без учета температурного воздействия). "
                    .."\n\nСила голода по умолчанию: %s.",
                    common.defaultValues.hungerRate
                ),
                min = 0,
                max = 100,
                step = 1,
                jump = 10,
                variable = mwse.mcm.createTableVariable{ id = "hungerRate", table = config },
            }
        end --\Hunger category

        do --Thirst Category
            local categoryThirst = pageModValues:createCategory{
                label = "Жажда",
                description = "Изменение силы жажды.",
            }

            categoryThirst:createSlider{
                label = "Сила жажды",
                description = string.format(
                    "Определяет, насколько усиливается жажда за час. При значении 10, жажда усиливается на 1%% в час "
                    .."(без учета температурного воздействия). "
                    .."\n\nСила жажды по умолчанию: %s.",
                    common.defaultValues.thirstRate
                ),
                min = 0,
                max = 100,
                step = 1,
                jump = 10,
                variable = mwse.mcm.createTableVariable{ id = "thirstRate", table = config },
            }
        end--\Thirst Category

        do --Sleep Category
            local categorySleep = pageModValues:createCategory{
                label = "Сон",
                description =  "Настройка сна.",
            }

            categorySleep:createSlider{
                label = "Скорость усталости",
                description = string.format(
                    "Определяет, насколько сильно вы устаете за час. При значении 10 вы устанете на 1%% за час. "
                    .."\n\nСкорость усталости по умолчанию: %s.",
                    common.defaultValues.loseSleepRate
                ),
                min = 0,
                max = 200,
                step = 1,
                jump = 10,
                variable = mwse.mcm.createTableVariable{ id = "loseSleepRate", table = config },
            }
            categorySleep:createSlider{
                label =  "Скорость усталости (при ожидании)",
                description = string.format(
                    "Определяет, насколько сильно вы устаете за час во время ожидания. При значении 10 вы устанете на 1%% за час. "
                    .."\n\nСкорость усталости (при ожидании) по умолчанию: %s.",
                    common.defaultValues.loseSleepWaiting
                ),
                min = 0,
                max = 200,
                step = 1,
                jump = 10,
                variable = mwse.mcm.createTableVariable{ id = "loseSleepWaiting", table = config },
            }

            categorySleep:createSlider{
                label = "Продуктивность сна (на земле)",
                description = string.format(
                    "Определяет, насколько вы восстанавливаетесь за час, отдыхая на земле. "
                    .."При значении 10, вы отдыхаете на 1%% за час. "
                    .."\n\nПродуктивность сна (на земле): %s.",
                    common.defaultValues.gainSleepRate
                ),
                min = 0,
                max = 200,
                step = 1,
                jump = 10,
                variable = mwse.mcm.createTableVariable{ id = "gainSleepRate", table = config },
            }
            categorySleep:createSlider{
                label = "Продуктивность сна (в кровати)",
                description = string.format(
                    "Определяет, насколько вывосстанавливаетесь за час, во время сна на кровати. "
                    .."При значении 10, вы отдыхаете на 1%% за час. "
                    .."\n\nПродуктивность сна (на кровати): %s.",
                    common.defaultValues.gainSleepBed
                ),
                min = 0,
                max = 200,
                step = 1,
                jump = 10,
                variable = mwse.mcm.createTableVariable{ id = "gainSleepBed", table = config },
            }
        end --\Sleep Category

        do --Natural Materials Placement
            local categoryNatualMaterials = pageModValues:createCategory{
                label = "Природные материалы",
                description = "Распространение природных материалов.",
            }

            --Determines frequence of materials such as wood, stone, flint etc that spawn in the world
            categoryNatualMaterials:createSlider{
                label = "Распространенность природных материалов",
                description = string.format(
                    "Определяет, как часто такие материалы, как дерево, камень и кремень, попадаются в природе. "
                    .."\n\nРаспространенность природных материалов по умолчанию: %s.",
                    common.defaultValues.naturalMaterialsMultiplier
                ),
                min = 0,
                max = 100,
                step = 1,
                jump = 10,
                variable = mwse.mcm.createTableVariable{ id = "naturalMaterialsMultiplier", table = config },
            }
        end
    end --\mod values page

    do --Exclusions Page
        template:createExclusionsPage{
            label = "Черный список еды\\напитков",
            description = (
                "Выберите, какая еда и напитки не будут учитываться при расчете жажды и голода в Пеплопаде. Вы также можете внести в черный список целиком плагины, чтобы все добавляемые ими элементы не учитывались."
            ),
            variable = mwse.mcm.createTableVariable{ id = "blocked", table = config },
            filters = {
                {
                    label = "Плагины",
                    type = "Plugin",
                },
                {
                    label = "Еда",
                    type = "Object",
                    objectType = tes3.objectType.ingredient,
                },
                {
                    label = "Напитки",
                    type = "Object",
                    objectType = tes3.objectType.alchemy
                }
            }
        }

    end --\Exclusions Page

    local function offersService(npcObject, service)
        if npcObject.class and npcObject.class[service] then
            return true
        end
        if npcObject.aiConfig and npcObject.aiConfig[service] then
            return true
        end
        return false
    end

    do --Camping gear merchants
        template:createExclusionsPage{
            label = "Торговцы снаряжением",
            description = "Переместите торговцев в левый список, чтобы они могли продавать походное снаряжение. Изменения вступят в силу только после того, как вы в следующий раз зайдете в ячейку, где находится торговец. Обратите внимание, что удаление торговца из списка не приведет к удалению снаряжения, если вы уже посетили ячейку, в которой он находится.",
            variable = mwse.mcm.createTableVariable{ id = "campingMerchants", table = config },
            leftListLabel = "Торговцы продающие снаряжение",
            rightListLabel = "Торговцы",
            filters = {
                {
                    label = "Merchants",
                    callback = function()
                        --Check if npc is able to sell any guar gear
                        local function canSellGear(obj)
                            local bartersFields = {
                                "bartersMiscItems",
                            }
                            for _, field in ipairs(bartersFields) do
                                if offersService(obj, field) then
                                    return true
                                end
                            end
                            return false
                        end

                        local merchants = {}
                        ---@param obj tes3npcInstance
                        for obj in tes3.iterateObjects(tes3.objectType.npc) do
                            if not (obj.baseObject and obj.baseObject.id ~= obj.id ) then
                                if canSellGear(obj) then
                                    merchants[#merchants+1] = (obj.baseObject or obj).id:lower()
                                end
                            end
                        end
                        table.sort(merchants)
                        return merchants
                    end
                }
            }
        }
    end

    do --Camping gear merchants
        template:createExclusionsPage{
            label = "Торговцы едой\\водой",
            description = "Переместите торговцев в левый список, чтобы они могли продавать еду и предлагать услуги по пополнению запасов воды. Изменения вступят в силу только после того, как вы в следующий раз зайдете в ячейку, где находится торговец. Обратите внимание, что удаление торговца из списка не приведет к удалению товаров, если вы уже посетили ячейку, в которой он находится.",
            variable = mwse.mcm.createTableVariable{ id = "foodWaterMerchants", table = config },
            leftListLabel = "Торговцы продающие еду\\воду",
            rightListLabel = "Торговцы",
            filters = {
                {
                    label = "Merchants",
                    callback = function()
                        --Check if npc is able to sell any guar gear
                        local function canSellGear(obj)
                            if obj.class then
                                local bartersFields = {
                                    "bartersAlchemy",
                                    "bartersIngredients"
                                }
                                for _, field in ipairs(bartersFields) do
                                    if offersService(obj, field) then
                                        return true
                                    end
                                end
                            end
                            return false
                        end

                        local merchants = {}
                        ---@param obj tes3npcInstance
                        for obj in tes3.iterateObjects(tes3.objectType.npc) do
                            if not (obj.baseObject and obj.baseObject.id ~= obj.id ) then
                                if canSellGear(obj) then
                                    merchants[#merchants+1] = (obj.baseObject or obj).id:lower()
                                end
                            end
                        end
                        table.sort(merchants)
                        return merchants
                    end
                }
            }
        }
    end

    do --Dev Options
        local pageDevOptions = template:createSideBarPage{
            label = "Опции для разработчиков",
            description = "Инструменты для отладки и т.д. Не трогайте, если не знаете, что делать.",
        }

        pageDevOptions:createOnOffButton{
            label = "Проверка обновлений",
            description = "Если эта функция включена, вы будете получать уведомления о появлении новых версий Пеплопада.",
            variable = mwse.mcm.createTableVariable{ id = "checkForUpdates", table = config },
            restartRequired = true,
        }

        pageDevOptions:createYesNoButton{
            label = "Показать меню конфигурации при запуске",
            description = "При следующей загрузке новой или существующей игры отобразится меню конфигурации. Предназначено для тестирования, для настройки параметров запуска используйте страницу настроек модификаций.",
            variable = mwse.mcm.createTableVariable{ id = "doIntro", table = config }
        }

        pageDevOptions:createOnOffButton{
            label = "Режим отладки",
            description = "Включить горячую перезагрузку сеток. Только для отладки.",
            variable = mwse.mcm.createTableVariable{ id = "debugMode", table = config }
        }

        pageDevOptions:createDropdown{
            label = "Уровень журнала",
            description = "Установите уровень ведения журнала mwse.log. Оставьте INFO, если вы не занимаетесь отладкой.",
            options = {
                { label = "TRACE", value = "TRACE"},
                { label = "DEBUG", value = "DEBUG"},
                { label = "INFO", value = "INFO"},
                { label = "ERROR", value = "ERROR"},
                { label = "NONE", value = "NONE"},
            },
            variable = mwse.mcm.createTableVariable{ id = "logLevel", table = config },
            callback = function(self)
                for _, log in ipairs(common.loggers) do
                    log:setLogLevel(self.variable.value)
                end
            end
        }

        pageDevOptions:createButton{
            buttonText = "Сохранить журнал в файл",
            description = "Сохраните все данные о Пеплопад в Morrowind/MWSE.log. Если у вас возникли проблемы с Пеплопадом, воссоздайте проблему в игре, нажмите эту кнопку, а затем отправьте файл MWSE.log Merlord на канал Morrowind Modding в Discord.",
            callback = function()
                if not tes3.player then
                    mwse.log("Must be in-game to print data")
                    return
                end
                mwse.log("Ashfall Data:")
                mwse.log(json.encode(tes3.player.data.Ashfall, { indent = true }))
            end,
            inGameOnly = true
        }
    end --\Dev Options
end

event.register("modConfigReady", registerModConfig)