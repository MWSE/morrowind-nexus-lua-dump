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
            tes3.messageBox({ message = name.." is already bound to slot "..slot..", remove the item?",
                            buttons = {"Yes", "No"},
                            callback = function(a)
                                if (a.button == 0) then
                                    quickKey:clear()
                                    tes3.messageBox("%s succesfully removed.", name)
                                    table.removevalue(eraseItem, slot)
                                end
                            end
                        })
            else quickKey:clear()
                tes3.messageBox("%s succesfully removed.", name)
                table.removevalue(eraseItem, slot)
            end
            return false
        elseif quickKey and quickKey.item == item and quickKey.type == 2 then
            quickKey:setItem(item)
            tes3.messageBox("Bound %s succesfully modified.", name)
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
            tes3.messageBox("%s succesfully bound to slot %d", name, slot)
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
            tes3.messageBox({ message = "All slot are already full, replace the oldest bound item?",
                    buttons = {"Yes", "No"},
                    callback = function(a)
                        if (a.button == 0) then
                            --quickKey2:clear()
                            quickKey2:setItem(item)
                            tes3.messageBox("%s succesfully replaced by %s in slot %d.", thing, name, eraseItem[1])
                            table.insert(eraseItem, eraseItem[1])
                            table.remove(eraseItem, 1)
                        end
                    end
                })
            else
                --quickKey2:clear()
                quickKey2:setItem(item)
                tes3.messageBox("%s succesfully replaced by %s in slot %d.", thing, name, eraseItem[1])
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
            tes3.messageBox({ message = name.." is already bound to slot "..slot..", remove the item?",
                            buttons = {"Yes", "No"},
                            callback = function(a)
                                if (a.button == 0) then
                                    quickKey:clear()
                                    tes3.messageBox("%s succesfully removed.", name)
                                    table.removevalue(eraseItem, slot)
                                end
                            end
                        })
            else quickKey:clear()
                tes3.messageBox("%s succesfully removed.", name)
                table.removevalue(eraseItem, slot)
            end
            return false
        elseif quickKey and (quickKey.item == item or quickKey.spell == item) and quickKey.type == 1 then
            quickKey:setMagic(item)
            tes3.messageBox("Bound %s succesfully modified.", name)
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
            tes3.messageBox("%s succesfully bound to slot %d", name, slot)
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
                tes3.messageBox({ message = "All slot are already full, replace the oldest bound item?", buttons = {"Yes", "No"},
                callback = function(a)
                    if (a.button == 0) then
                        --quickKey2:clear()
                        quickKey2:setMagic(item)
                        tes3.messageBox("%s succesfully replaced by %s in slot %d.", thing, name, eraseItem[1])
                        table.insert(eraseItem, eraseItem[1])
                        table.remove(eraseItem, 1)
                        end
                     end
                })
            else
                --quickKey2:clear()
                quickKey2:setMagic(item)
                tes3.messageBox("%s succesfully replaced by %s in slot %d.", thing, name, eraseItem[1])
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
            tes3.messageBox("%s succesfully bound to slot %d", name, i)
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
            tes3.messageBox("%s succesfully bound to slot %d", name, i)
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
                tes3.messageBox("This Item does not have a Valid Enchantment. (\"Cast on Use\" or \"Cast Once\" required)")
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
                tes3.messageBox("%s succesfully bound to slot 3!", magic.name)
            else tes3.messageBox("No Spell or Enchanted Item found!")
            end

            if tes3.mobilePlayer.readiedWeapon then
                weapon = tes3.mobilePlayer.readiedWeapon.object
                local quickWeapon = tes3.getQuickKey({slot = 2})
                quickWeapon:clear()
                quickWeapon:setItem(weapon)
                tes3.messageBox("%s succesfully bound to slot 2!", weapon.name)
            else tes3.messageBox("No Weapon found!")
            end
        end)
        if errMsg then
            tes3.messageBox("No Valid Target found.")
        end
    end
end event.register("keyDown", dynamicBinding)


local function readTooltip(e)
    if not cf.onOff2 then return end
    local mit = {
        [1] = "Item",
        [2] = "Magic"
    }
    for slot = 9, 1, -1 do pcall(function()
        local quickKey = tes3.getQuickKey({slot = slot})
        if quickKey.item.id == e.object.id then
        local text = "[Bound to "..mit[quickKey.type].." Slot "..slot.."]"
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
        [1] = "Item",
        [2] = "Magic"
    }
    for slot = 9, 1, -1 do pcall(function()
        local quickKey = tes3.getQuickKey({slot = slot})
        if quickKey.spell.id == e.spell.id then
        local text = "[Bound to "..mit[quickKey.type].." Slot "..slot.."]"
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
    local template = mwse.mcm.createTemplate("QuickKey Outlander!")
    template:saveOnClose("QuickKey Outlander!", cf) template:register()
    local page = template:createSideBarPage({label="Welcome to \"QuickKey Outlander!\""})
    page.sidebar:createInfo{ text = "Welcome to \"QuickKey Outlander!\" Configuration Menu. \n \n \n A mod by Spammer."}
    page.sidebar:createHyperLink{ text = "Spammer's Nexus Profile", url = "https://www.nexusmods.com/users/140139148?tab=user+files" }
    local category = page:createCategory("General Configurations:")
    category:createOnOffButton{label = "Confirmation Prompts", description = "Toggles the confirmation popups before removing/replacing a Quick Key Bind. [Default: On]", variable = mwse.mcm.createTableVariable{id = "onOff", table = cf}}
    category:createKeyBinder{label = "On Equip QuickKey", description = "The Key to press for your current equipped weapon and spell/enchant to be automatically bound to QuickKeys 2 and 3. Set it to \"Esc\" to disable it.", allowCombinations = false, variable = mwse.mcm.createTableVariable{id = "keyEquip", table = cf, restartRequired = false, defaultSetting = {keyCode = tes3.scanCode.l, isShiftDown = false, isAltDown = false, isControlDown = false}}}
    local category1 = page:createCategory("Configure Key:")
    category1:createKeyBinder{label = "Remap Item Key", description = "New Item Binding Key. Can be a combination (Alt-B, Ctrl-U, Shift-X, etc).", allowCombinations = true, variable = mwse.mcm.createTableVariable{id = "keyItem", table = cf, restartRequired = false, defaultSetting = {keyCode = tes3.scanCode.z, isShiftDown = false, isAltDown = false, isControlDown = false}}}
    category1:createKeyBinder{label = "Remap Magic Key", description = "New Enchanted Item / Spell Binding Key. Can be a combination (Alt-B, Ctrl-U, Shift-X, etc).", allowCombinations = true, variable = mwse.mcm.createTableVariable{id = "keyMagic", table = cf, restartRequired = false, defaultSetting = {keyCode = tes3.scanCode.x, isShiftDown = false, isAltDown = false, isControlDown = false}}}
    local category2 = page:createCategory("Tooltip:")
    category2:createOnOffButton{label = "On/Off", description = "Toggles whether the custom tooltip will show up on key bound items. [Default = On]", variable = mwse.mcm.createTableVariable{id = "onOff2", table = cf}}
    local elementGroup = category2:createCategory("Order")
    elementGroup:createDropdown { description = "Here you can change the place of the \"bound item\" info besides the other ones.",
        options  = {
            { label = "Top most", value = 0 },
            { label = "First after the Item name", value = 1 },
            { label = "Second after the Item name", value = 2 },
            { label = "Third after the Item name", value = 3 },
            { label = "Fourth after the Item name", value = 4 },
            { label = "Last", value = -1 }
        },
        variable = mwse.mcm:createTableVariable {
            id    = "mode",
            table = cf
        }
    }
    local subcat = category2:createCategory("Item Toolbar Color")
    subcat:createSlider{label = "Red", description = "Here you can change the color of the key bound items tooltip.", min = 0, max = 10, step = 1, jump = 1, variable = mwse.mcm.createTableVariable{id = "ar_red", table = cf}}
    subcat:createSlider{label = "Green", description = "Here you can change the color of the key bound items tooltip.", min = 0, max = 10, step = 1, jump = 1, variable = mwse.mcm.createTableVariable{id = "ar_green", table = cf}}
    subcat:createSlider{label = "Blue", description = "Here you can change the color of the of the key bound items tooltip.", min = 0, max = 10, step = 1, jump = 1, variable = mwse.mcm.createTableVariable{id = "ar_blue", table = cf}}
    local subcat2 = category2:createCategory("Magic Item Toolbar Color")
    subcat2:createSlider{label = "Red", description = "Here you can change the color of the key bound magic items tooltip.", min = 0, max = 10, step = 1, jump = 1, variable = mwse.mcm.createTableVariable{id = "mg_red", table = cf}}
    subcat2:createSlider{label = "Green", description = "Here you can change the color of the key bound magic items tooltip.", min = 0, max = 10, step = 1, jump = 1, variable = mwse.mcm.createTableVariable{id = "mg_green", table = cf}}
    subcat2:createSlider{label = "Blue", description = "Here you can change the color of the of the key bound magic items tooltip.", min = 0, max = 10, step = 1, jump = 1, variable = mwse.mcm.createTableVariable{id = "mg_blue", table = cf}}

end event.register("modConfigReady", registerModConfig)

local function initialized()
     print("[\"QuickKey Outlander!\", by Spammer] 2.0 Initialized!")
end event.register("initialized", initialized)