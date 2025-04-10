local common = require("mer.theGuarWhisperer.common")
local guarConfig = require("mer.theGuarWhisperer.guarConfig")
local mcmConfig = common.config.mcm
local function registerMcm()

    local template = mwse.mcm.createTemplate{ name = "Дрессировщик гуаров"}
    template.onClose = function()
        common.config.save()
        event.trigger("GuarWhisperer:McmUpdated")
    end
    template:register()

    local settingsPage = template:createSideBarPage("Настройки")
    do
        local descriptionCategory = settingsPage.sidebar:createCategory("Дрессировщик гуаров")
        local sidebarText = (
            "Этот мод позволяет приручать и разводить гуаров в качестве компаньонов.\n\n" ..

            "Для начала активируйте гуара, чтобы накормить его чем-нибудь. После этого вы сможете дать ему имя, и станет доступно контекстное меню. " ..
            "Сначала вам будет доступно немного команд. Попробуйте несколько раз погладить животное или дать ему еще еды, пока " ..
            "вы не получете уведомление о том, что гуар достаточно доверяет, чтобы следовать за вами. \n\n" ..

            "Единственный способ завоевать доверие вашего гуара - проводить с ним время и радовать его. Играйте с ним в мяч " ..
            "и хорошо кормите его, и его доверие к вам мгновенно возрастет. " ..
            "Чем больше гуар доверяет вам, тем больше команд становится доступно. Со временем ваш гуар сможет собирать собирать ингредиенты или " ..
            "Брать для вас предметы, экипировать сумку (доступно у торговцев), чтобы разблокировать инвентарь компаньона, и спариваться с другими гуарами " ..
            "и приносить детенышей гуаров. \n\n" ..

            "Если ваш гуар потерялся, вы можете приобрести флейту гуара, которая, если на ней сыграть, призовет гуара обратно к вам." ..
            "Флейты, сумки и игрушки можно купить у Аррилла, Ра'вирра, а также у других торговцев. \n\n" ..

            "Если у вас установлен Пеплопад (Ashfall), походное снаряжение будет отображаться на сумке гуара при добавлении в его инвентарь. "
        )
        descriptionCategory:createInfo{
            text = sidebarText
        }

        --SETTINGS

        local settingsCategory = settingsPage:createCategory("Настройки")

        settingsCategory:createYesNoButton{
            label = "Включить мод",
            description = "Включите или выключите мод.",
            variable = mwse.mcm.createTableVariable{ id = "enabled", table = mcmConfig }
        }

        settingsCategory:createKeyBinder{
            label = "Клавиша меню команд",
            description = "Клавиша или сочетание клавиш, используемое для переключения меню команд. По умолчанию: Q",
            allowCombinations = false,
            variable = mwse.mcm.createTableVariable{ id = "commandToggleKey", table = mcmConfig }
        }

        settingsCategory:createSlider{
            label = "Установить расстояние телепортации",
            description = "Установите минимальное расстояние от игрока, на котором будет срабатывать телепорт, если гуар следует за вами.",
            variable = mwse.mcm.createTableVariable{ id = "teleportDistance", table = mcmConfig },
            min = 500,
            max = 3000,
            jump = 100,
            step = 1
        }

        --DEBUG

        local debugCategory = settingsPage:createCategory("Параметры отладки")

        debugCategory:createDropdown{
            label = "Уровень журнала",
            description = "Выберите уровень ведения журнала событий mwse.log. Оставьте INFO, если не проводите отладку.",
            options = {
                { label = "TRACE", value = "TRACE"},
                { label = "DEBUG", value = "DEBUG"},
                { label = "INFO", value = "INFO"},
                { label = "ERROR", value = "ERROR"},
                { label = "NONE", value = "NONE"},
            },
            variable = mwse.mcm.createTableVariable{ id = "logLevel", table = mcmConfig },
            callback = function(self)
                for _, logger in pairs(common.loggers) do
                    logger:setLogLevel(self.variable.value)
                end
            end
        }

        --CREDITS

        local creditsCategory = settingsPage:createCategory("\nАвторы ")

        local credits = {
            {
                name = "Сделано Merlord",
                description = "",
                link = "https://www.nexusmods.com/users/3040468?tab=user+files"
            },
            {
                name = "Alei3ter: ",
                description = "Модель сумки гуара",
                link = "https://www.nexusmods.com/morrowind/users/20765944"
            },
            {
                name = "Remiros",
                description = "Ретекстур мяча",
                link = "https://www.nexusmods.com/morrowind/users/899234"
            },
            {
                name = "R-zero: ",
                description = "Модель флейты гуара",
                link = "https://www.nexusmods.com/morrowind/users/3241081"
            },
            {
                name = "RedFurryDemon и\nOperatorJack",
                description = "Код из мода Feed the Animals",
                link = "https://www.nexusmods.com/morrowind/mods/47894"
            },
            {
                name = "Greatness7: ",
                description = "Код из мода Graphic Herbalism",
                link = "https://www.nexusmods.com/morrowind/mods/46599"
            },
            {
                name = "NullCascade: ",
                description = "Устранение неполадок в MWSE",
                link = "https://www.nexusmods.com/morrowind/users/26153919"
            },
            {
                name = "Tizzo: ",
                description = "Помощь с искусственным интеллектом компаньона",
                link = "https://www.nexusmods.com/morrowind/users/302"
            },
        }
        for _, credit in ipairs(credits) do
            local block = creditsCategory:createSideBySideBlock()
            block:createHyperlink{
                text = credit.name,
                url = credit.link,
                postCreate = (
                    function(self)
                        self.elements.outerContainer.autoWidth = true
                        self.elements.outerContainer.widthProportional = nil
                        self.elements.outerContainer:updateLayout()
                    end
                ),
            }
            block:createInfo{ text = credit.description}
        end
    end

    template:createExclusionsPage{
        label = "Торговцы экипировкой для Гуара",
        description = "Переместите торговцев в левый список, чтобы они могли продавать сумки гуара, флейты и т. д. Изменения вступят в силу только после того, как вы в следующий раз зайдете в ячейку, где находится торговец. Обратите внимание, что удаление торговца из списка не приведет к удалению экипировки, если вы уже посетили клетку, в которой он находится.",
        variable = mwse.mcm.createTableVariable{ id = "merchants", table = mcmConfig },
        leftListLabel = "Торговцы, продающие экипировку для гуара",
        rightListLabel = "Торговцы",
        filters = {
            {
                label = "Торговцы",
                callback = function()
                    --Check if npc is able to sell any guar gear
                    local function canSellGear(obj)
                        if obj.class then
                            local bartersFields = {
                                "bartersMiscItems",
                                "bartersWeapons"
                            }
                            for _, field in ipairs(bartersFields) do
                                if obj.class[field] == true then
                                    return true
                                end
                            end
                        end
                        return false
                    end

                    local merchants = {}
                    ---@param obj tes3npc|tes3npcInstance
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

    template:createExclusionsPage{
        label = "Скриптовые гуары",
        description = "По умолчанию скриптовые гуары не могут быть приручены, так как скрипт может работать некорректно. Однако если у вас есть мод, добавляющий скрипты к обычным гуарам, или вы действительно хотите приручить какого-нибудь другого заскриптованного гуара, вы можете добавить его в белый список. Будьте осторожны с guar_white_unique, после добавления его в белый список вы не сможете выполнить квест \"Мечты белого гуара\".",
        variable = mwse.mcm.createTableVariable{ id = "exclusions", table = mcmConfig },
        leftListLabel = "Белый список",
        rightListLabel = "Черный список",
        filters = {
            {
                label = "Скриптовые существа",
                callback = function()
                    local baseCreatures = {}
                    ---@param obj tes3creature|tes3creatureInstance
                    for obj in tes3.iterateObjects(tes3.objectType.creature) do
                        if not (obj.baseObject and obj.baseObject.id ~= obj.id ) then
                            if obj.script then
                                if guarConfig.meshToConvertConfig[obj.mesh:lower()] then
                                    baseCreatures[#baseCreatures+1] = (obj.baseObject or obj).id:lower()
                                end
                            end
                        end
                    end
                    table.sort(baseCreatures)
                    return baseCreatures
                end
            }
        }
    }
end

event.register("modConfigReady", registerMcm)