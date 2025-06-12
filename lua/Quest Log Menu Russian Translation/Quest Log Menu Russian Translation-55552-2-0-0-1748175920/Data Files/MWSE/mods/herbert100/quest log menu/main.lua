
-- local livecoding = include("herbert100.livecoding.livecoding")
-- local register_event = livecoding and livecoding.registerEvent or event.register
local register_event = event.register
local log = Herbert_Logger()



if lfs.fileexists("data files\\mwse\\mods\\herbert100\\quest log menu\\config.lua") then
    log:info("found old config file, trying to delete it.......")
    local status = os.remove("data files\\mwse\\mods\\herbert100\\quest log menu\\config.lua")
    if status then
        log:info("old config file was deleted successfully")
    else
        log:error("old config file (\"quest log menu\\config.lua\") could not be deleted. this may cause problems")
    end
end
local hlib = require("herbert100")
local cfg = hlib.get_mod_config() --[[@as herbert.QLM.config]]

local Quest_Log = hlib.import("quest_log_menu") ---@type herbert.QLM.Quest_Log

local quest_log ---@type herbert.QLM.Quest_Log?


-- get rid of our reference to the menu whenever it gets closed
register_event("herbert.QLM:menu_destroyed", function (e)
    quest_log = nil
end)

local kc = cfg.key

---@param e mouseButtonDownEventData
local function mouse_button_clicked(e)
    if e.button == kc.mouseButton and not tes3ui.menuMode() and tes3.player then
        quest_log = Quest_Log.new()
    end
end


---@param e keyDownEventData
local function key_pressed(e)
    if e.keyCode == kc.keyCode and not tes3ui.menuMode() and tes3.player then
        quest_log = Quest_Log.new()
    end
end

local function up_arrow_pressed()
    log:trace("pressed up arrow!")
    if quest_log and tes3ui.menuMode() then
        quest_log:prev_quest()
    end
end

local function down_arrow_pressed()
    log:trace("pressed down arrow!")
    if quest_log and tes3ui.menuMode() then
        quest_log:next_quest()
    end
end



local function esc_pressed()
    Quest_Log.close(true)
end

local function initialized()
    register_event(tes3.event.mouseButtonDown, mouse_button_clicked)
    register_event(tes3.event.keyDown, key_pressed)
    register_event(tes3.event.keyDown, esc_pressed, {filter=tes3.scanCode.esc, priority=1000})
    register_event(tes3.event.keyDown, down_arrow_pressed, {filter=tes3.scanCode.keyDown})
    register_event(tes3.event.keyDown, up_arrow_pressed, {filter=tes3.scanCode.keyUp})
    log:write_init_message()
end
register_event(tes3.event.initialized, initialized)

-- if livecoding and tes3.isInitialized() then
--     log:info("livecoding installed, using livecoding")
--     initialized()
-- end

register_event("herbert:QLM:MCM_closed", function (e)
    kc = cfg.key
    log:trace("closed mcm. config = %s", json.encode, cfg)
end, {filter=hlib.get_mod_name()})



register_event("modConfigReady", function (e)

    local template = mwse.mcm.createTemplate{label="Меню заданий", config=cfg, defaultConfig=hlib.import("config.default")}
    local page = template:createSideBarPage{label="Настройки", 
        description='Этот мод облегчает отслеживание активных заданий. Он включает в себя несколько эффективных функций поиска.\n\n\z
            \z
            При поиске заданий мод будет проверять название задания, а также имена и местоположение квестодателей. \z
                При желании вы можете включить поиск по темам заданий и ходу их выполнения \z
                (эти опции сделают первый поиск немного медленнее, так как потребуется загрузить больше файлов.).\n\n\z
            \z
            Этот мод использует нечеткий поиск для нахождения заданий. \z
                Это означает, что вам разрешено делать небольшие опечатки при поиске, а также использовать аббревиатуры. \z
                Например, "НТБ" будет соответствовать "Нападениям Темного Братства".\n\n\z
            \z
            Поиск чувствителен к регистру только в том случае, если вы набираете буквы в верхнем регистре. (Таким образом, запрос "темное братство" будет находить "Нападение Темного Братства", а "тЕмное" не будет.) \z
                Это сделано для облегчения распознавания аббревиатур с учетом регистра. (Например, "НТБ" будет распознаваться как аббревиатура, а "нтб" - нет.)\n\n\z
                \z
            Также есть возможность поиска по ключевым словам. Более подробно об этом говорится в описании настроек.\n\n\z
            Все изменения вступают в силу немедленно.\z
            \z
        '
    }

    page:createKeyBinder{label="Клавиша окна заданий", configKey="key", description="Эта клавиша открывает окно заданий."}
    

    do -- make ui settings
        local ui_cat = page:createCategory{label="Настройки пользовательского интерфейса", configKey="ui",
            description="Эти настройки управляют внешним видом пользовательского интерфейса. Они не влияют на функциональность.\n\n\z
                \z
                Эти настройки нельзя изменить в окне заданий. \z
                (Но изменения, внесенные в меню настройки мода, вступают в силу немедленно.)\z
            "
        }

        ui_cat:createPercentageSlider{label="Горизонтальный размер меню:", configKey="x_size",
            description="Какой ширины должно быть меню? 100% означает, что меню будет использовать все доступное горизонтальное пространство.",
            min = .3
        }

        ui_cat:createPercentageSlider{label="Вертикальный размер меню:", configKey="y_size",
            description="Какой высоты должно быть меню? 100% означает, что меню будет использовать все доступное вертикальное пространство.",
            min = .3
        }

        ui_cat:createYesNoButton{label="Показывать иконки заданий?", configKey="show_icons",
            description="Если установлен мод \"Оповещения о квестах в стиле Skyrim\", эта опция отобразит иконки заданий в окне заданий.\n\n\z
            \z
            Примечание: для использования этой настройки требуется только файл iconlist.lua. Вам не нужно устанавливать полный мод."
        }
        ui_cat:createYesNoButton{label="Светлый режим?", configKey="light_mode",
            description="Если эта опция включена, будет использоваться цветовая палитра, более похожая на стандартный журнал заданий."
        }

        ui_cat:createYesNoButton{label="Показывать регион в заголовке задания?", configKey="region_names",
            description="Если эта опция включена, то в заголовке задания, при указании местоположения квестодателя/исполнителей, будет отображаться регион.\n\n\z
                Примечание: Этот параметр не влияет на работу поиска."
        }


        page:createYesNoButton{label="Показать техническую информацию о задании?", configKey="show_technical_info",
            description='Если эта функция включена, в меню будет отображаться различная техническая информация:\n\z
                Какие ESP модифицировали это задание,\n\z
                С какой фракцией связано задание (если есть)\n\z
                Соответствующие идентификаторы диалогов\n\z
                Каков ваш текущий индекс журнала.\n\n\z
                \z
                Эту опцию также можно изменить в окне заданий в любое время.'
        }
    end

    do -- add search settings
        local search_cat = page:createCategory{label="Настройки поиска", configKey="search",
            description="Эти настройки определяют, как работает функция поиска. \z
                Большинство этих настроек можно изменить в окне заданий."
        }


        search_cat:createYesNoButton{label="Использовать поиск по ключевым словам?", configKey="keywords",
            description='Если эта опция включена, порядок вводимых слов не будет иметь значения, за исключением проверки названий заданий. \z
                    (Т.е. в названиях заданий никогда не используется поиск по ключевым словам.) \z
                    Включение этой настройки может сделать поиск прогресса задания немного более точным, поскольку в противном случае вам придется \z
                    точно соответствовать порядку слов. \n\n\z
                \z
                Эта опция также делает поиск по соответствующим актерам/ячейкам более точным, так как в противном случае вам придется искать \z
                    в соответствии с порядком появления этих актеров/ячеек.\n\n\z
                    Например, если этот параметр отключен, вы можете обнаружить, что «mournhold ebonheart» ничему не соответствует, а \z
                    "ebonheart mournhold" соответствует.\z
            '
        }

        search_cat:createPercentageSlider{label="Точность нечеткого поиска", configKey="fzy_confidence",
            description='Насколько "хорошим" должно быть совпадение, чтобы отображаться в результатах?\n\n\z
                Грубо говоря, чем ближе этот показатель к 100 %, тем точнее текст поиска должен совпадать с целевым текстом.\n\z
                Например, поиск по аббревиатурам с меньшей вероятностью будет успешным, если этот параметр близок к 100 %.',
            min = 0.1,
            max = .8
        }
        do -- add search weight settings
            local weights_cat = search_cat:createCategory{label="Прироритеты поиска", configKey="weights",
                description="Эти настройки управляют приоритетом различных элементов запроса при нечетком поиске. \z
                    Большее значение означает, что соответствующее поле является более приоритетным при нечетком поиске.\n\n\z
                    \z
                    Вы можете игнорировать эти настройки, но они могут оказаться полезными, если вы хотите чтобы определенная информация ассоциируемая с заданием \z
                        имела больший приоритет при его поиске. По умолчанию название задания, имя квестодателя и \z
                        название локации имеют наивысший приоритет.\n\n\z
                    \z
                    Установка значения на 0 означает, что соответсвтвующая информация связанная с заданием не будет учитываться при нечетком поиске.\z"
            }

            weights_cat:createPercentageSlider{label="Название задания", configKey="quest_name", max=2,
                description="Насколько важно название задания при нечетком поиске?\n\nУстановите значение 0%, чтобы игнорировать названия заданий при поиске."
            }
            weights_cat:createPercentageSlider{label="Имя квестодателя", configKey="actor_names", max=2,
                description="Насколько важно имя квестодателя при нечетком поиске?\n\n\z
                    Это позволит выполнять такое действие, как поиск по запросу \"Кай\" чтобы увидеть все задания, в которых участвует \"Кай Косадес\".\n\n\z
                    Установите значение 0%, чтобы игнорировать имена квестодателей при поиске."
            }
            weights_cat:createPercentageSlider{label="Местонахождение квестодателя", configKey="location_data", max=2,
                description="Насколько важно местоположение квестодателя при нечетком поиске?\n\n\z
                    Это позволит выполнить такое действие, как поиск по запросу \"Квартал Чужеземцев\" чтобы увидеть все задания, связанные с кантоном Квартал Чужеземцев в Вивеке.\n\n\z
                    Установите значение 0%, чтобы игнорировать местоположение квестодателей при поиске."
            }
            weights_cat:createPercentageSlider{label="Регионы", configKey="region_names", max=2,
                description="Насколько важен регион при нечетком поиске?\n\n\z
                    Это позволяет по запросу «Западное Нагорье» отобразить все задания, связанные с регионом Западное Нагорье.\n\n\z
                    Установите значение 0%, чтобы игнорировать регион при поиске."
            }
            weights_cat:createPercentageSlider{label="Темы заданий", configKey="topics", max=2,
                description="Насколько важны темы заданий при нечетком поиске?\n\n\z
                    Темы заданий - это выделенные слова, отображаемые в разделе \"Прогресс задания\".\n\n\z
                    Это позволит выполнить такое действие, как поиск по слову \"двемер\" чтобы увидеть все задания, в которых задействованы артефакты и технологии двемеров.\n\n\z
                    Установите значение 0%, чтобы игнорировать местоположение квестодателей при поиске.\n\n\z
                    Примечание: Если эта настройка или настройка \"Прогресс задания\" установлена на значение выше 0%, \z
                        то самый первый поиск, который происходит (за одну игровую сессию) \z
                        может быть заметно медленнее. (Примерно на 2 секунды медленнее, при наличии SSD и 50 активных заданий.) \z
                        Это связано с тем, что поиск с активным заданием подразумевает загрузку большого количества файлов.\z
                "
            }
            weights_cat:createPercentageSlider{label="Прогресс задания", configKey="quest_progress", max=2,
                description="Насколько важны журнальные записи о ходе выполнения задания при нечетком поиске?\n\n\z
                    \z
                    Эта настройка позволяет выполнять поиск по любому тексту, который отображается в пронумерованных записях в разделе \"Прогресс задания\".\n\n\z
                    \z
                    Это позволит выполнить такое действие, как поиск \"пакет\" чтобы найти задание \"Прибыть к Каю Косадесу\" \z
                        (потому что первая запись содержит фразу \"мне надо отдать ему пакет с документами\").\n\n\z
                    \z
                    Установите значение 0%, чтобы игнорировать записи о ходе выполнения задания при поиске.\n\n\z
                    Примечание: Если эта настройка или настройка \"Темы\" установлена на значение выше 0%, \z
                        то самый первый поиск, который происходит (за одну игровую сессию) \z
                        может быть заметно медленнее. (Примерно на 2 секунды медленнее, при наличии SSD и 50 активных заданий.) \z
                        Это связано с тем, что поиск с активным заданием подразумевает загрузку большого количества файлов.\z
                "
            }
        end 
    end
    do -- make quest list settings
        local quest_list_cat = page:createCategory{label="Настройки списка заданий", configKey="quest_list",
            description="Эти настройки определяют, какие задания будут отображаться в списке заданий, расположенном в левой части окна.\n\n\z
                \z
                Эти настройки также можно изменить непосредственно в окне заданий.\z
            "
        }
        quest_list_cat:createYesNoButton{label="Показать завершенные задания", configKey="show_completed", 
            description="При включении этой функции, выполненные задания будут отображаться в списке заданий под активными заданиями. \n\n\z
            Эта настройка немного увеличивает время, необходимое для первого открытия окна заданий. \z
            (Не влияет на дальнейшую производительность)\z
            ",
        }

        quest_list_cat:createYesNoButton{label="Показать скрытые задания?", configKey="show_hidden", 
            description="При включении этой функции, \"скрытые\" задания будут отображаться в списке заданий под активными заданиями. \n\n\z
                Вы можете скрыть/показать задания, нажав на соответствующую кнопку в нижней части окна заданий. \z
            ",
        }
    end
    
    do -- advanced settings
        local adv_settings = page:createCategory{label="Дополнительные настройки", description="Позволяет вам изменять больше настроек в окне заданий."}

        adv_settings:createYesNoButton{label="Отложенная загрузка", configKey="lazy_loading", 
            description='Если отключено, все данные будут загружаться при открытии окна заданий. Если отключено, данные будут загружаться только тогда, когда они понадобятся.\n\n\z
                \z
                Включение этой опции означает, что этот мод будет ждать до последней возможной секунды, чтобы загрузить файлы. Плюс этого в том, что меню будет открываться намного быстрее. \z
                    Но загрузка все равно должна произойти в какой-то момент, поэтому другие функции могут работать немного медленнее.\n\n\z
                    Отключение этой функции обычно приводит к тому, что открытие меню занимает дополнительно 2–5 секунд, но только в самый первый раз после запуске игры. \z
                    При каждом последующем открытии меню его ожидание будет занимать всего лишь (максимум) на 0,05 секунды больше времени, если эта опция отключена.\n\n\z
                \z
                Эта настройка имеет смысл только в том случае, если у вас большой список заданий или если игра установлена на жесткий дис, а не на твердотелый накопитель.\n\n\z
                \z
                Примечание: эта настройка по-настоящему влияет только на то, что происходит при первом открытии меню (после запуска игры).\n\n\z
                \z
                Если поиск по темам и ходу выполнения заданий отключен, рекомендуется оставить отложенную загрузку включенной. \z
                    Это связано с тем, что загрузка тем и хода выполнения заданий требует выполнения нескольких медленных дисковых операций и они могут значительно накапливаться, если заданий много. \z
                    Таким образом, процессы отложенной загрузки работают только тогда, когда задание фактически отображается в меню.\n\n\z
                \z
            '
        }
        log:add_to_MCM(adv_settings)

    end
    

    template.onClose = function()
        -- the "modConfigClosed" event is the only part of my MCM wrapper that hasn't gotten merged 
        -- into MWSE proper (except for the i18n stuff i guess)
        -- so, i'll just fire a custom event here.
        -- if the `modConfigClosed` PR gets merged, then i'll happily start using that event
        -- and remove this custom one
        -- (so don't count on future versions of this mod triggering this event)
        event.trigger("herbert:QLM:MCM_closed", {mod_name = hlib.get_mod_name()}, {filter=hlib.get_mod_name()})
        mwse.saveConfig(hlib.get_mod_name(), cfg)
    end


    ---@param comp mwseMCMComponent|mwseMCMCategory|mwseMCMTemplate|mwseMCMSetting
    local function add_defaults_to_descriptions(comp)
        local sub_comps = comp.pages or comp.components
        if sub_comps then
            for _, sub_comp in ipairs(sub_comps) do
                add_defaults_to_descriptions(sub_comp)
            end
        end
        if not comp.variable then return end
        local default_val = comp.variable.defaultSetting
        local default_str = comp:convertToLabelValue(default_val)
        if comp.description == nil then
            comp.description = "По умолчанию: " .. default_str
        else
            comp.description = string.format("%s\n\nПо умолчанию: %s", comp.description, default_str)
        end
    end

    add_defaults_to_descriptions(template)
    template:register()

end, {doOnce=true})