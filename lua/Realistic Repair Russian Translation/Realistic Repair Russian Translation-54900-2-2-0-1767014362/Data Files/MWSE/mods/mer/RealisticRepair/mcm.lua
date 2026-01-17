local config = require("mer.RealisticRepair.config")

local  sideBarDefault = [[
Этот мод добавляет следующие механики:

Деградация:

При неудачной попытке ремонта предмет будет "деградировать", что снизит максимальное состояние, до которого его можно отремонтировать. Вы можете уменьшить степень деградации, используя наковальню или кузницу. Если бонус от наковальни/кузницы превышает степень деградации, вы можете даже полностью устранить деградацию ваших предметов. Вы также можете полностью устранить деградацию, отремонтировав предметы у кузнеца.

Усиление:

На ремонтной станции полностью отремонтированные предметы могут быть усилены сверх их базового максимального состояния. Усиление добавляет временные очки состояния (10-50% от базового), которые изнашиваются прежде, чем базовое состояние. Усиленные предметы не могут деградировать, пока усиление не износится. Предметы, максимальное состояние которых деградировало, должны быть полностью восстановлены, прежде чем можно будет применить усиление.

Повреждение добычи:

Когда NPC умирает, его снаряжение получает случайное количество повреждений.
]]

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


local function doGeneralSettings(page)
    ---General
    local generalSettings = page:createCategory("Общие настройки")

    generalSettings:createOnOffButton{
        label = "Включить реалистичный ремонт",
        variable = mwse.mcm.createTableVariable{
            id = "enableRealisticRepair",
            table = config.mcm
        },
        description = "Включить или выключить мод."
    }

    generalSettings:createOnOffButton{
        label = "Включить отображение текущего урона/защиты во всплывающих подсказках",
        variable = mwse.mcm.createTableVariable{
            id = "enableDynamicTooltips",
            table = config.mcm
        },
        description = "При включении этой функции, значения урона и защиты, во всплывающих подсказках к предметам, будут изменятся, в зависимости от текущего состояния предмета."
    }

    generalSettings:createOnOffButton{
        label = "Включить ремонтные станции",
        variable = mwse.mcm.createTableVariable{
            id = "enableStations",
            table = config.mcm
        },
        description = "При включении этой функции, для ремонта предметов необходимо использовать наковальни и кузницы."
    }

    generalSettings:createLogLevelOptions{
        configKey = "logLevel",
    }
end

---@param page mwseMCMSideBarPage
local function doCostSettings(page)
    ---Cost Settings
    local costSettings = page:createCategory("Настройки затрат")
    --Time cost
    costSettings:createOnOffButton{
        label = "Включить затраты времени на ремонт",
        variable = mwse.mcm.createTableVariable{
            id = "enableTimeCost",
            table = config.mcm
        },
        description = "При включении этой функции, ремонт предметов будет занимать игровое время, зависящее от объема ремонта.",
    }

    --repairTimeMin
    costSettings:createSlider{
        label = "Время ремонта в часах при низком уровне навыка",
        decimalPlaces = 2,
        min = 0.1,
        max = 5.0,
        step = 0.1,
        variable = mwse.mcm.createTableVariable{
            id = "repairTimeMin",
            table = config.mcm
        }
    }

    --repairTimeMax
    costSettings:createSlider{
        label = "Время ремонта в часах при высоком уровне навыка",
        decimalPlaces = 2,
        min = 0.1,
        max = 5.0,
        step = 0.1,
        variable = mwse.mcm.createTableVariable{
            id = "repairTimeMax",
            table = config.mcm
        }
    }

    --Fatigue cost
    costSettings:createOnOffButton{
        label = "Включить затраты запаса сил на ремонт",
        variable = mwse.mcm.createTableVariable{
            id = "enableFatigueCost",
            table = config.mcm
        },
        description = "При включении этой функции, ремонт предметов будет расходовать определенное количество запаса сил, зависящее от объема ремонта.",
    }

    --repairFatigueMin
    costSettings:createSlider{
        label = "Количество запаса сил, затрачиваемое при низком уровне навыка",
        min = 1,
        max = 50,
        step = 1,
        variable = mwse.mcm.createTableVariable{
            id = "repairFatigueMin",
            table = config.mcm
        }
    }

    --repairFatigueMax
    costSettings:createSlider{
        label = "Количество запаса сил, затрачиваемое при высоком уровне навыка",
        min = 1,
        max = 50,
        step = 1,
        variable = mwse.mcm.createTableVariable{
            id = "repairFatigueMax",
            table = config.mcm
        }
    }

end


local function doDegradationSettings(page)
    local degradationSettings = page:createCategory("Настройки деградации")

    degradationSettings:createOnOffButton{
        label = "Включить деградацию предметов при неудачном ремонте",
        variable = mwse.mcm.createTableVariable{
            id = "enableDegradation",
            table = config.mcm
        },
        description = "При включении этой функции, максимальный уровень состояния предметов будет снижаться при неудачной попытке ремонта."
    }

    degradationSettings:createSlider{
        label = "Минимальная деградация (Высокий навык)",
        description = "Уровень деградации при 100 уровне навыка Кузнец",
        min = 0,
        max = 20,
        step = 1,
        variable = mwse.mcm.createTableVariable{
            id = "minDegradation",
            table = config.mcm
        }
    }
    degradationSettings:createSlider{
        label = "Максимальная деградация (Низкий навык)",
        description = "Уровень деградации при 0 уровне навыка Кузнец",
        min = 1,
        max = 50,
        step = 1,
        variable = mwse.mcm.createTableVariable{
            id = "maxDegradation",
            table = config.mcm
        }
    }

    degradationSettings:createSlider{
        label = "Модификатор шанса успеха на станции",
        description = "Множитель, добавленный к шансу успешного ремонта при использовании станции (наковальни/кузницы)",
        min = 0,
        max = 50,
        step = 1,
        variable = mwse.mcm.createTableVariable{
            id = "stationChanceModifier",
            table = config.mcm
        }
    }
end

local function doEnhancementSettings(page)
       ---Enhancement Settings
    local enhancementSettings = page:createCategory("Настройки усиления")

    --enable Enhancement
    enhancementSettings:createOnOffButton{
        label = "Включить усиление предметов при успешном ремонте",
        variable = mwse.mcm.createTableVariable{
            id = "enableEnhancement",
            table = config.mcm
        },
        description = "При включении этой функции, предметы могут быть усилены сверх их базового максимального состояния при ремонте на станции."
    }

    enhancementSettings:createSlider{
        label = "Минимальная величина усиления",
        description = "Величина усиления за успешный ремонт при 0 уровне навыка Кузнец",
        min = 1,
        max = 1000,
        step = 1,
        jump = 100,
        variable = mwse.mcm.createTableVariable{
            id = "minEnhancement",
            table = config.mcm
        }
    }

    enhancementSettings:createSlider{
        label = "Максимальная величина усиления",
        description = "Величина усиления за успешный ремонт при 100 уровне навыка Кузнец",
        min = 1,
        max = 1000,
        step = 1,
        jump = 100,
        variable = mwse.mcm.createTableVariable{
            id = "maxEnhancement",
            table = config.mcm
        }
    }

    enhancementSettings:createSlider{
        label = "Минимальный предел усиления (Низкий навык)",
        description = "Максимальный процент усиления при 0 уровне навыка Кузнец",
        min = 0,
        max = 100,
        step = 1,
        variable = mwse.mcm.createTableVariable{
            id = "minEnhancementCap",
            table = config.mcm
        }
    }

    enhancementSettings:createSlider{
        label = "Максимальный предел усиления (Высокий навык)",
        description = "Максимальный процент усиления при 100 уровне навыка Кузнец",
        min = 0,
        max = 100,
        step = 1,
        variable = mwse.mcm.createTableVariable{
            id = "maxEnhancementCap",
            table = config.mcm
        }
    }

    enhancementSettings:createSlider{
        label = "Минимальный шанс усиления",
        description = "Шанс усиления при успешном ремонте при 0 уровне навыка Кузнец",
        min = 0,
        max = 100,
        step = 1,
        variable = mwse.mcm.createTableVariable{
            id = "minEnhancementChance",
            table = config.mcm
        }
    }

    enhancementSettings:createSlider{
        label = "Максимальный шанс усиления",
        description = "Шанс усиления при успешном ремонте при 100 уровне навыка Кузнец",
        min = 0,
        max = 100,
        step = 1,
        variable = mwse.mcm.createTableVariable{
            id = "maxEnhancementChance",
            table = config.mcm
        }
    }
end

local function doLootDamageSettings(page)
    ---Loot Damage
    local lootCategory = page:createCategory("Настройки повреждения добычи")

    lootCategory:createOnOffButton{
        label = "Включить повреждение добычи",
        variable = mwse.mcm.createTableVariable{
            id = "enableLootDamage",
            table = config.mcm
        },
        description = (
            "Когда эта функция включена, снаряжение NPC будет сильно повреждено после смерти. " ..
            "Это сделано для того, чтобы сбалансировать экономику, усложнив возможность зарабатывать " ..
            "деньги, грабя врагов ради снаряжения."
        )
    }
    lootCategory:createSlider{
        label = "Минимальный процент состояния добычи",
        min = 0,
        max = 100,
        step = 1,
        variable = mwse.mcm.createTableVariable{
            id = "minCondition",
            table = config.mcm
        }
    }
    lootCategory:createSlider{
        label = "Максимальный процент состояния добычи",
        min = 0,
        max = 100,
        step = 1,
        variable = mwse.mcm.createTableVariable{
            id = "maxCondition",
            table = config.mcm
        }
    }
end

event.register("modConfigReady", function()
    local template = mwse.mcm.createTemplate{
        name = "Реалистичный ремонт",
        config = config.mcm,
        defaultConfig = config.mcmDefault,
        showDefaultSetting = true
    }
    template:saveOnClose(config.configPath, config.mcm)
    template:register()

    local page = template:createSideBarPage{ showReset = true}
    addSideBar(page)
    doGeneralSettings(page)
    doCostSettings(page)
    doDegradationSettings(page)
    doEnhancementSettings(page)
    doLootDamageSettings(page)
end)
