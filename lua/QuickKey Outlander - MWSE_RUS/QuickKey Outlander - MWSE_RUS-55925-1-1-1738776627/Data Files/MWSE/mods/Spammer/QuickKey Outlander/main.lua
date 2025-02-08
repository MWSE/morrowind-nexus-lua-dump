local cf = mwse.loadConfig("QuickKey Outlander!", {onOff = true, onOff2 = true, ar_red = 8, ar_green = 2, ar_blue = 2, mg_red = 2, mg_green = 2, mg_blue = 6, mode = 1, keyEquip = {keyCode = tes3.scanCode.l, isShiftDown = false, isAltDown = false, isControlDown = false}, keyItem = {keyCode = tes3.scanCode.z, isShiftDown = false, isAltDown = false, isControlDown = false}, keyMagic = {keyCode = tes3.scanCode.x, isShiftDown = false, isAltDown = false, isControlDown = false}})

local eraseItem = {}

local function validateItem()
    local key = cf.keyItem
    local validkey = tes3.worldController.inputController:isKeyDown(key.keyCode)
        if key.isShiftDown then
            if validkey and tes3.worldController.inputController:isShiftDown() then return true end
        elseif key.isAltDown then
            if validkey and tes3.worldController.inputController:isAltDown() then return true end
        elseif key.isControlDown then
            if validkey and tes3.worldController.inputController:isControlDown() then return true end
        elseif validkey then
            return true
        end
    return false
end

local function validateMagic()
    local key = cf.keyMagic
    local validkey = tes3.worldController.inputController:isKeyDown(key.keyCode)
        if key.isShiftDown then
            if validkey and tes3.worldController.inputController:isShiftDown() then return true end
        elseif key.isAltDown then
            if validkey and tes3.worldController.inputController:isAltDown() then return true end
        elseif key.isControlDown then
            if validkey and tes3.worldController.inputController:isControlDown() then return true end
        elseif validkey then
            return true
        end
    return false
end

local function onLoad()
    eraseItem = {}
    for slot = 1, 9 do
        local quickKey = tes3.getQuickKey({slot = slot})
        if quickKey and (quickKey.item or quickKey.spell) then
            table.insert(eraseItem, slot)
        end
    end
end event.register("loaded", onLoad)

local function checkItem(item, name)
    for slot = 1, 9 do
        local quickKey = tes3.getQuickKey({slot = slot})
        if quickKey and quickKey.item == item and quickKey.type == 1 then
            if cf.onOff then
            tes3.messageBox({ message = name.." уже привязан к слоту "..slot..", удалить предмет?",
                            buttons = {"Да", "Нет"},
                            callback = function(a)
                                if (a.button == 0) then
                                    quickKey:clear()
                                    tes3.messageBox("%s успешно удален.", name)
                                    table.removevalue(eraseItem, slot)
                                end
                            end
                        })
            else quickKey:clear()
                tes3.messageBox("%s успешно удален.", name)
                table.removevalue(eraseItem, slot)
            end
            return false
        elseif quickKey and quickKey.item == item and quickKey.type == 2 then
            quickKey:setItem(item)
            tes3.messageBox("Привязка %s успешно изменена.", name)
            return false
        end
    end
     return true
end

local function setItem(item, name)
    for slot = 1, 9 do
        local quickKey = tes3.getQuickKey({slot = slot})
        if quickKey and not quickKey.item and not quickKey.spell then
            quickKey:setItem(item)
            tes3.messageBox("%s успешно привязан к слоту %d", name, slot)
            table.insert(eraseItem, slot)
        break
        elseif slot == 9 then
            local quickKey2 = tes3.getQuickKey({slot = eraseItem[1]})
            local thing
                if quickKey2.item then
                    thing = quickKey2.item.name
                elseif quickKey2.spell then
                    thing= quickKey2.spell.name
                else thing = "Item"
                end
            if cf.onOff then
            tes3.messageBox({ message = "Все слоты уже заполнены, заменить самый старый привязанный предмет?",
                    buttons = {"Да", "Нет"},
                    callback = function(a)
                        if (a.button == 0) then
                            --quickKey2:clear()
                            quickKey2:setItem(item)
                            tes3.messageBox("%s успешно заменен на %s в слоте %d.", thing, name, eraseItem[1])
                            table.insert(eraseItem, eraseItem[1])
                            table.remove(eraseItem, 1)
                        end
                    end
                })
            else
                --quickKey2:clear()
                quickKey2:setItem(item)
                tes3.messageBox("%s успешно заменен на %s в слоте %d.", thing, name, eraseItem[1])
                table.insert(eraseItem, eraseItem[1])
                table.remove(eraseItem, 1)
            end
            break
        end
    end
end

local function checkMagic(item, name)
    for slot = 1, 9 do
        local quickKey = tes3.getQuickKey({slot = slot})
        if quickKey and (quickKey.item == item or quickKey.spell == item) and quickKey.type == 2 then
            if cf.onOff then
            tes3.messageBox({ message = name.." уже привязан к слоту "..slot..", удалить предмет?",
                            buttons = {"Да", "Нет"},
                            callback = function(a)
                                if (a.button == 0) then
                                    quickKey:clear()
                                    tes3.messageBox("%s успешно удален.", name)
                                    table.removevalue(eraseItem, slot)
                                end
                            end
                        })
            else quickKey:clear()
                tes3.messageBox("%s успешно удален.", name)
                table.removevalue(eraseItem, slot)
            end
            return false
        elseif quickKey and (quickKey.item == item or quickKey.spell == item) and quickKey.type == 1 then
            quickKey:setMagic(item)
            tes3.messageBox("Привязка %s успешно изменена.", name)
            return false
        end
    end
    return true
end

local function setMagic(item, name)
    for slot = 1, 9 do
        local quickKey = tes3.getQuickKey({slot = slot})
        if quickKey and not quickKey.item and not quickKey.spell then
            quickKey:setMagic(item)
            tes3.messageBox("%s успешно привязан к слоту %d", name, slot)
            table.insert(eraseItem, slot)
            break
        elseif slot == 9 then
            local quickKey2 = tes3.getQuickKey({slot = eraseItem[1]})
            local thing
                if quickKey2.item then
                    thing = quickKey2.item.name
                elseif quickKey2.spell then
                    thing= quickKey2.spell.name
                else thing = "Item"
                end
            if cf.onOff then
                tes3.messageBox({ message = "Все слоты уже заполнены, заменить самый старый привязанный предмет?", buttons = {"Да", "Нет"},
                callback = function(a)
                    if (a.button == 0) then
                        --quickKey2:clear()
                        quickKey2:setMagic(item)
                        tes3.messageBox("%s успешно заменен на %s в слоте %d.", thing, name, eraseItem[1])
                        table.insert(eraseItem, eraseItem[1])
                        table.remove(eraseItem, 1)
                        end
                     end
                })
            else
                --quickKey2:clear()
                quickKey2:setMagic(item)
                tes3.messageBox("%s успешно заменен на %s в слоте %d.", thing, name, eraseItem[1])
                table.insert(eraseItem, eraseItem[1])
                table.remove(eraseItem, 1)
            end
            break
        end
    end
end

local function quickMagic(item, name)
    local keyc = {2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i,v in pairs(keyc) do
        if (tes3.worldController.inputController:isKeyDown(v)) then
            local quickKey = tes3.getQuickKey({slot = i})
            --quickKey:clear()
            quickKey:setMagic(item)
            tes3.messageBox("%s успешно привязан к слоту %d", name, i)
            table.insert(eraseItem, i)
        return true
        end
    end
end

local function quickItem(item, name)
    local keyc = {2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i,v in pairs(keyc) do
        if (tes3.worldController.inputController:isKeyDown(v)) then
            local quickKey = tes3.getQuickKey({slot = i})
            --quickKey:clear()
            quickKey:setItem(item)
            tes3.messageBox("%s успешно привязан к слоту %d", name, i)
            table.insert(eraseItem, i)
        return true
        end
    end
end

local function onInventory(e)
    e.element:registerBefore("mouseClick", function()
        if quickItem(e.item, e.item.name) then
            return false
        end
    end)
    e.element:registerBefore("mouseClick", function()
        if validateItem() then
            if checkItem(e.item, e.item.name) == true then
                do setItem(e.item, e.item.name)
                end
            end
            return false
        end
    end)
    e.element:registerBefore("mouseClick", function()
        if validateMagic() then
            local _, errMsg = pcall(function()
                if checkMagic(e.item, e.item.name) == true then
                    do setMagic(e.item, e.item.name)
                    end
                end
            end)
            if errMsg then
                tes3.messageBox("У этого предмета отсутствует зачарование. (Требуется \"Применение при использование\" или \"Единоразовое применение\")")
            end
            return false
        end
    end)
end event.register("itemTileUpdated", onInventory, {filter = "MenuInventory"})

local function spellsTooBro()
    if not tes3.player then return end
    local menu = tes3ui.findMenu("MenuMagic")
    if menu then
    if menu.visible == false then return
    else
    local spellList = {}
    local spells = {}
    local eitems = {}
    local eitemname = {}
    local birthname = {}
    local birth = {}
    local race = tes3.player.object.race
    local pcInventory = tes3.player.object.inventory
    for i,spell in pairs(tes3.mobilePlayer.object.spells) do
        table.insert(spellList, i, spell.name)
        table.insert(spells, i, spell)
	    table.insert(birthname, i, spell.name)
        table.insert(birth, i, spell)
    end
    for i,spell in pairs(tes3.mobilePlayer.birthsign.spells.iterator) do
        table.insert(birthname, i, spell.name)
        table.insert(birth, i, spell)
    end
    for i,ability in pairs(race.abilities.iterator) do
        table.insert(birthname, i, ability.name)
        table.insert(birth, i, ability)
    end
    for i,stack in pairs(pcInventory) do
        table.insert(eitems, i, stack.object)
        table.insert(eitemname, i, stack.object.name)
    end
----------------------------------------------------------------------------------------------------
    local SpellName = menu:findChild("MagicMenu_spell_names")
        for _, child in pairs(SpellName.children) do
            if table.find(spellList, child.text) then
                child:registerBefore("mouseClick", function()

                    if quickMagic(spells[table.find(spellList, child.text)], child.text) then
                        return false
                    end

                    if validateMagic() then
                        if checkMagic(spells[table.find(spellList, child.text)], child.text) then
                            do setMagic(spells[table.find(spellList, child.text)], child.text)
                            end
                        end
                        return false
                    end
                end)
            end
        end
----------------------------------------------------------------------------------------------------
    local PowerName = menu:findChild("MagicMenu_power_names")
    for _, child in pairs(PowerName.children) do
        if table.find(birthname, child.text) then
            child:registerBefore("mouseClick", function()

                if quickMagic(birth[table.find(birthname, child.text)], child.text) then
                    return false
                end

                if validateMagic() then
                    if checkMagic(birth[table.find(birthname, child.text)], child.text) then
                        do setMagic(birth[table.find(birthname, child.text)], child.text)
                        end
                    end
                    return false
                end
            end)
        end
    end
------------------------------------------------------------------------------------------------------------
    local ItemName = menu:findChild("MagicMenu_item_names")
        for _, child in pairs(ItemName.children) do
            if table.find(eitemname, child.text) then
                child:registerBefore("mouseClick", function()

                    if quickMagic(eitems[table.find(eitemname, child.text)], child.text) then
                        return false
                    end


                if validateMagic() then
                    if checkMagic(eitems[table.find(eitemname, child.text)], child.text) then
                        do setMagic(eitems[table.find(eitemname, child.text)], child.text)
                        end
                    end
                    return false
------------------------------------------------------------------------------------------------------------
                elseif validateItem() then
                    if checkItem(eitems[table.find(eitemname, child.text)], child.text) then
                        do setItem(eitems[table.find(eitemname, child.text)], child.text)
                        end
                    end
                return false
                end
            end)
        end
    end
-------------------------------------------------------------------------------------------------------------
    end
end
end event.register("mouseButtonDown", spellsTooBro)

local function dynamicBinding(e)
    if not tes3.mobilePlayer then return end
    if tes3ui.menuMode() then return end
    if e.keyCode == tes3.scanCode.esc then return
    elseif e.keyCode == cf.keyEquip.keyCode then
        local weapon
        local magic
        local _, errMsg = pcall(function()
            magic = tes3.mobilePlayer.currentEnchantedItem.object or tes3.mobilePlayer.currentSpell
            if magic then
                local quickSpell = tes3.getQuickKey({slot = 3})
                quickSpell:clear()
                quickSpell:setMagic(magic)
                tes3.messageBox("%s успешно привязан к слоту 3!", magic.name)
            else tes3.messageBox("На предмете не найдено зачарование!")
            end

            if tes3.mobilePlayer.readiedWeapon then
                weapon = tes3.mobilePlayer.readiedWeapon.object
                local quickWeapon = tes3.getQuickKey({slot = 2})
                quickWeapon:clear()
                quickWeapon:setItem(weapon)
                tes3.messageBox("%s успешно привязан к слоту 2!", weapon.name)
            else tes3.messageBox("Не найдено оружие!")
            end
        end)
        if errMsg then
            tes3.messageBox("Цель не найдена!")
        end
    end
end event.register("keyDown", dynamicBinding)


local function readTooltip(e)
    if not cf.onOff2 then return end
    local mit = {
        [1] = "Предмет",
        [2] = "Магия"
    }
    for slot = 9, 1, -1 do pcall(function()
        local quickKey = tes3.getQuickKey({slot = slot})
        if quickKey.item.id == e.object.id then
        local text = "["..mit[quickKey.type].." привязан к слоту "..slot.."]"
        local block = e.tooltip:createBlock("spa_Quick")
        block.minWidth = 1
        block.maxWidth = 230
        block.autoWidth = true
        block.autoHeight = true
        block.paddingAllSides = -1
        local label = block:createLabel{text = text}
        label.wrapText = true
        if quickKey.type == 1 then
            label.color = {(cf.ar_red/10), (cf.ar_green/10), (cf.ar_blue/10)}
        else
            label.color = {(cf.mg_red/10), (cf.mg_green/10), (cf.mg_blue/10)}
        end
        block.parent:reorderChildren(cf.mode, -1, 1)
        end
    end)
    end
end event.register("uiObjectTooltip", readTooltip)

local function readTooltip2(e)
    if not cf.onOff2 then return end
    local mit = {
        [1] = "Предмет",
        [2] = "Магия"
    }
    for slot = 9, 1, -1 do pcall(function()
        local quickKey = tes3.getQuickKey({slot = slot})
        if quickKey.spell.id == e.spell.id then
        local text = "["..mit[quickKey.type].." привязан к слоту "..slot.."]"
        local block = e.tooltip:createBlock("spa_Quick")
        block.minWidth = 1
        block.maxWidth = 230
        block.autoWidth = true
        block.autoHeight = true
        block.paddingAllSides = -1
        local label = block:createLabel{text = text}
        label.wrapText = true
        label.color = {(cf.mg_red/10), (cf.mg_green/10), (cf.mg_blue/10)}
        block.parent:reorderChildren(cf.mode, -1, 1)
        end
    end)
    end
end event.register("uiSpellTooltip", readTooltip2)

local function registerModConfig()
    local template = mwse.mcm.createTemplate("Быстрая привязка к слотам!")
    template:saveOnClose("QuickKey Outlander!", cf) template:register()
    local page = template:createSideBarPage({label="Добро пожаловать в \"Быструю привязку к слотам!\""})
    page.sidebar:createInfo{ text = "Добро пожаловать в меню настроек мода \"Быстрая привязка к слотам!\" \n \n \n Разработчик мода - Spammer."}
    page.sidebar:createHyperLink{ text = "Страница профиля Spammer на сайте Nexus", url = "https://www.nexusmods.com/users/140139148?tab=user+files" }
    local category = page:createCategory("Главные настройки:")
    category:createOnOffButton{label = "Подтверждение при изменении", description = "Перед удалением/заменой привязки для определенного слота будет запрашиваться подтверждение [По умолчанию: ВКЛ]", variable = mwse.mcm.createTableVariable{id = "onOff", table = cf}}
    category:createKeyBinder{label = "Привязка активных элементов", description = "Здесь необходимо указать клавишу, нажав на которую, экипированный предмет и активное заклинание будут автоматически привязаны к слоту 2 и 3. Нажмите кнопку \"Esc\" что бы отменить кнопку.", allowCombinations = false, variable = mwse.mcm.createTableVariable{id = "keyEquip", table = cf, restartRequired = false, defaultSetting = {keyCode = tes3.scanCode.l, isShiftDown = false, isAltDown = false, isControlDown = false}}}
    local category1 = page:createCategory("Настройка кнопок:")
    category1:createKeyBinder{label = "Назначить кнопку для привязки предметов", description = "Новая кнопка для привязки предметов. Она же снимает привязку. Это может быть и комбинация (Alt-B, Ctrl-U, Shift-X, и т.д.).", allowCombinations = true, variable = mwse.mcm.createTableVariable{id = "keyItem", table = cf, restartRequired = false, defaultSetting = {keyCode = tes3.scanCode.z, isShiftDown = false, isAltDown = false, isControlDown = false}}}
    category1:createKeyBinder{label = "Назначить кнопку для привязки магических предметов/заклинаний", description = "Новая кнопка для привязки магических предметов/заклинаний. Она же снимает привязку. Это может быть и комбинация (Alt-B, Ctrl-U, Shift-X, и т.д.).", allowCombinations = true, variable = mwse.mcm.createTableVariable{id = "keyMagic", table = cf, restartRequired = false, defaultSetting = {keyCode = tes3.scanCode.x, isShiftDown = false, isAltDown = false, isControlDown = false}}}
    local category2 = page:createCategory("Всплывающая подсказка:")
    category2:createOnOffButton{label = "ВКЛ/ВЫКЛ", description = "Указывает, будет ли пользовательская всплывающая подсказка отображаться на предметах/заклинаниях, привязанных к слотам. [По умолчанию = ВКЛ]", variable = mwse.mcm.createTableVariable{id = "onOff2", table = cf}}
    local elementGroup = category2:createCategory("Порядок отображения")
    elementGroup:createDropdown { description = "Здесь вы можете изменить положение строки информации о \"привязанном предмете/заклинании\" среди остальной информации.",
        options  = {
            { label = "В самом верху", value = 0 },
            { label = "Первая строка после названия", value = 1 },
            { label = "Вторая строка после названия", value = 2 },
            { label = "Третья строка после названи", value = 3 },
            { label = "Четвертая строка после названия", value = 4 },
            { label = "В самом низу", value = -1 }
        },
        variable = mwse.mcm:createTableVariable {
            id    = "mode",
            table = cf
        }
    }
    local subcat = category2:createCategory("Цвет текста привязанных предметов во всплывающей подсказке")
    subcat:createSlider{label = "Красный", description = "Здесь вы можете изменить цвет текста во всплывающей подсказке для предметов, привязанных к слотам.", min = 0, max = 10, step = 1, jump = 1, variable = mwse.mcm.createTableVariable{id = "ar_red", table = cf}}
    subcat:createSlider{label = "Зеленый", description = "Здесь вы можете изменить цвет текста во всплывающей подсказке для предметов, привязанных к слотам.", min = 0, max = 10, step = 1, jump = 1, variable = mwse.mcm.createTableVariable{id = "ar_green", table = cf}}
    subcat:createSlider{label = "Синий", description = "Здесь вы можете изменить цвет текста во всплывающей подсказке для предметов, привязанных к слотам.", min = 0, max = 10, step = 1, jump = 1, variable = mwse.mcm.createTableVariable{id = "ar_blue", table = cf}}
    local subcat2 = category2:createCategory("Цвет текста привязанных магических предметов/заклинаний во всплывающей подсказке")
    subcat2:createSlider{label = "Красный", description = "Здесь вы можете изменить цвет текста во всплывающей подсказке для магических предметов/заклинаний, привязанных к слотам.", min = 0, max = 10, step = 1, jump = 1, variable = mwse.mcm.createTableVariable{id = "mg_red", table = cf}}
    subcat2:createSlider{label = "Зеленый", description = "Здесь вы можете изменить цвет текста во всплывающей подсказке для магических предметов/заклинаний, привязанных к слотам.", min = 0, max = 10, step = 1, jump = 1, variable = mwse.mcm.createTableVariable{id = "mg_green", table = cf}}
    subcat2:createSlider{label = "Синий", description = "Здесь вы можете изменить цвет текста во всплывающей подсказке для магических предметов/заклинаний, привязанных к слотам.", min = 0, max = 10, step = 1, jump = 1, variable = mwse.mcm.createTableVariable{id = "mg_blue", table = cf}}

end event.register("modConfigReady", registerModConfig)

local function initialized()
     print("[\"QuickKey Outlander!\", by Spammer] 2.0 Initialized!")
end event.register("initialized", initialized)