local options = require("OperatorJack.SecurityEnhanced.options")
local config = require("OperatorJack.SecurityEnhanced.config")

local function createLockpickCategory(page)
    local category = page:createCategory{
        label = "Настройки отмычки"
    }

    -- Create option to capture hotkey.
    category:createKeyBinder{
        label = "Назначить горячую клавишу отмычки",
        description = "Нажмите, чтобы задать горячую клавишу для экипировки отмычки.",
        allowCombinations = true,
        variable = mwse.mcm.createTableVariable{
            id = "hotKey",
            table = config.lockpick,
            defaultSetting = {
                keyCode = tes3.scanCode.l,
                isShiftDown = false,
                isAltDown = false,
                isControlDown = false,
            },
            restartRequired = true
        }
    }

    -- Create option to capture equip order.
    category:createDropdown{
        label = "Повтороное нажатие горячей клавиши",
        description = "Этот параметр позволяет установить тип действия, которое происходит при повторном нажатии горячей клавиши.\n\nПри значении 'Взять следующую отмычку', каждое следующее нажатие будет циклически экипировать следующий тип отмычек в вашем инвентаре.\n\nПри значении 'Вернуть оружие', повторное нажатие горячей клавиши вернет оружие экипированнрое до вызова отмычки.",
        options = {
            { label = "Взять следующую отмычку", value = options.equipHotKeyCycle.Next },
            { label = "Вернуть оружие", value = options.equipHotKeyCycle.ReequipWeapon}
        },
        variable = mwse.mcm.createTableVariable{
            id = "equipHotKeyCycle",
            table = config.lockpick
        }
    }

    -- Create option to capture equip order.
    category:createDropdown{
        label = "Порядок экипировки отмычек",
        description = "Этот параметр установливает порядок экипировки отмычек, при использовании горячей клавиши или автоматической экипировки.\n\nПри значении 'Начать с лучшей отмычки' первой будет выбрана отмычка самого высокого уровня, которая у вас есть.\n\nПри значении 'Начать с худшей отмычки' первой будет выбрана отмычка самого низкого уровня, которая у вас есть.\n\nЕсли в меню «Повтороное нажатие горячей клавиши» выбрана опция «Взять следующую отмычку», переключение будет выполняться в этом же порядке.",
        options = {
            { label = "Начать с лучшей отмычки", value = options.equipOrder.BestFirst },
            { label = "Начать с худшей отмычки", value = options.equipOrder.WorstFirst}
        },
        variable = mwse.mcm.createTableVariable{
            id = "equipOrder",
            table = config.lockpick
        }
    }

    -- Create option to capture auto-equip on activation.
    category:createOnOffButton{
        label = "Автоэкипировка отмычки",
        description = "Эта опция включает функцию автоэкипировки отмычки, при активации запертого объекта.\n\n Если опция включена, то при активации запертого предмета отмычка будет автоматически экипирована в соответствии с выбранным порядком экипировки, как если бы вы нажали горячую клавишу.",
        variable = mwse.mcm.createTableVariable{
            id = "autoEquipOnActivate",
            table = config.lockpick,
            restartRequired = true
        }
    }

    return category
end

local function createProbeCategory(page)
    local category = page:createCategory{
        label = "Настройки щупа"
    }

    -- Create option to capture hotkey.
    category:createKeyBinder{
        label = "Назначить горячую клавишу щупа",
        description = "Нажмите, чтобы задать горячую клавишу для экипировки щупа.",
        allowCombinations = true,
        variable = mwse.mcm.createTableVariable{
            id = "hotKey",
            table = config.probe,
            defaultSetting = {
                keyCode = tes3.scanCode.p,
                isShiftDown = false,
                isAltDown = false,
                isControlDown = false,
            },
            restartRequired = true
        }
    }

    -- Create option to capture equip order.
    category:createDropdown{
        label = "Повтороное нажатие горячей клавиши",
        description = "Этот параметр позволяет установить тип действия, которое происходит при повторном нажатии горячей клавиши.\n\nПри значении 'Взять следующий щуп', каждое следующее нажатие будет циклически экипировать следующий тип щупов в вашем инвентаре.\n\nПри значении 'Вернуть оружие', повторное нажатие горячей клавиши вернет оружие экипированнрое до вызова щупа.",
        options = {
            { label = "Взять следующий щуп", value = options.equipHotKeyCycle.Next },
            { label = "Вернуть оружие", value = options.equipHotKeyCycle.ReequipWeapon}
        },
        variable = mwse.mcm.createTableVariable{
            id = "equipHotKeyCycle",
            table = config.probe
        }
    }

    -- Create option to capture equip order.
    category:createDropdown{
        label = "Порядок экипировки щупов",
        description = "Этот параметр установливает порядок экипировки щупов, при использовании горячей клавиши или автоматической экипировки.\n\nПри значении 'Начать с лучшего щупа' первым будет выбран щуп самого высокого уровня, который у вас есть.\n\nПри значении 'Начать с худшего щупа' первым будет выбран щуп самого низкого уровня, который у вас есть.\n\nЕсли в меню «Повтороное нажатие горячей клавиши» выбрана опция «Взять следующий щуп», переключение будет выполняться в этом же порядке.",
        options = {
            { label = "Начать с лучшего щупа", value = options.equipOrder.BestFirst },
            { label = "Начать с худшего щупа", value = options.equipOrder.WorstFirst}
        },
        variable = mwse.mcm.createTableVariable{
            id = "equipOrder",
            table = config.probe
        }
    }

    -- Create option to capture auto-equip on activation.
    category:createOnOffButton{
        label = "Автоэкипировка щупа",
        description = "Эта опция включает функцию автоэкипировки щупа.\n\n Если опция включена, то при активации запертого предмета с установленной ловушкой щуп будет автоматически экипирован в соответствии с выбранным порядком экипировки, как если бы вы нажали горячую клавишу.\n\n Внимание! Если на контейнере или двери будет только установленная ловушка, без замка, то активация приведет к срабатыванию ловушки одновременно с автоматической экипировкой щупа. В данном случае лучше воспользоваться горячей клавишей. Если же на предмете есть и ловушка и запертый замок, то при активации сначала произойдет автоматическая экипировка щупа, а после разярдки ловушки, автоматическая экипировка отмычки",
        variable = mwse.mcm.createTableVariable{
            id = "autoEquipOnActivate",
            table = config.probe,
            restartRequired = true
        }
    }

    return category
end

local function createGeneralCategory(page)
    local category = page:createCategory{
        label = "Главные настройки"
    }

    -- Create option to capture debug mode.
    category:createOnOffButton{
        label = "Включить режим отладки",
        description = "Данная опция включает режим отладки.",
        variable = mwse.mcm.createTableVariable{
            id = "debugMode",
            table = config
        }
    }

    return category
end

-- Handle mod config menu.
local template = mwse.mcm.createTemplate("Улучшенная безопасность")
template:saveOnClose("Security-Enhanced-2", config)

local page = template:createSideBarPage{
    label = "Settings Sidebar",
    description = "Наведите курсор на параметр, чтобы узнать о нем больше."
}

createGeneralCategory(page)
createLockpickCategory(page)
createProbeCategory(page)

mwse.mcm.register(template)