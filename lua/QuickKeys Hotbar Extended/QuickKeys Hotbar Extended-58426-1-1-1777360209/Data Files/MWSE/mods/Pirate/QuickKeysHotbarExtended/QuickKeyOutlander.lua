local i18n = mwse.loadTranslations("Pirate.QuickKeysHotbarExtended")
local config = require("Pirate.QuickKeysHotbarExtended.config")
local common = require("Pirate.QuickKeysHotbarExtended.common")
local cf = config.mcm

local mit = {
    [1] = i18n("HotBar.BindType.Item"),
    [2] = i18n("HotBar.BindType.Magic")
}

local function itemBindTooltip(e)
    if cf.HotBarExtended then return end
    if not cf.BindTooltip then return end
    
    for slot = 1, 9 do
        local quickKey = tes3.getQuickKey({slot = slot})
        if quickKey and quickKey.item and quickKey.item.id == e.object.id then
            local text
            if quickKey.type == 1 then
                text = i18n("HotBar.BindText.Item", { type = mit[quickKey.type], slot = slot })
            else
                text = i18n("HotBar.BindText.Magic", { type = mit[quickKey.type], slot = slot })
            end
            local block = e.tooltip:createBlock("spa_Quick")
            block.autoWidth = true
            block.autoHeight = true
            block.paddingAllSides = 2
            local label = block:createLabel{ text = text }
            label.wrapText = true
            if quickKey.type == 1 then
                label.color = {(8/10), (2/10), (2/10)}
            else
                label.color = tes3ui.getPalette("magic_color")
            end
            block.parent:reorderChildren(cf.BindTooltipMode, -1, 1)
            break
        end
    end
end

local function SpellBindTooltip(e)
    if cf.HotBarExtended then return end
    if not cf.BindTooltip then return end
    
    for slot = 1, 9 do
        local quickKey = tes3.getQuickKey({slot = slot})
        if quickKey and quickKey.spell and quickKey.spell.id == e.spell.id then
            local text = i18n("HotBar.BindText.Magic", { type = mit[quickKey.type], slot = slot })
            local block = e.tooltip:createBlock("spa_Quick")
            block.autoWidth = true
            block.autoHeight = true
            block.paddingAllSides = 2
            local label = block:createLabel{ text = text }
            label.wrapText = true
            label.color = tes3ui.getPalette("magic_color")
            block.parent:reorderChildren(cf.BindTooltipMode, -1, 1)
            break
        end
    end
end

-- Поиск в расширенной панели
local function findBindingInExtended(id)
    local data = tes3.player.data.quickKeys
    if not data then return nil end
    
    for p = 1, 3 do
        local panelName = config.panelNames[p]
        local panelData = data[panelName]
        if panelData then
            for slot = 1, 9 do
                local quickKey = panelData[slot]
                if quickKey and quickKey.id and quickKey.id == id then
                    local typeVal = quickKey.isMagic and 2 or 1
                    return { panel = p, slot = slot, type = typeVal }
                end
            end
        end
    end
    return nil
end

local function itemBindTooltipExtended(e)
    if not cf.HotBarExtended then return end
    if not cf.BindTooltip then return end

    local binding = findBindingInExtended(e.object.id)
    if not binding then return end
    
    local slotNumber = binding.slot
    if binding.panel == 2 then
        slotNumber = "2." .. binding.slot
    elseif binding.panel == 3 then
        slotNumber = "3." .. binding.slot
    end

    local text
    if binding.type == 1 then
        text = i18n("HotBar.BindText.Item", { type = mit[binding.type], slot = slotNumber })
    else
        text = i18n("HotBar.BindText.Magic", { type = mit[binding.type], slot = slotNumber })
    end
    
    local block = e.tooltip:createBlock("spa_Quick")
    block.autoWidth = true
    block.autoHeight = true
    block.paddingAllSides = 2
    local label = block:createLabel{ text = text }
    label.wrapText = true
    if binding.type == 1 then
        label.color = {(8/10), (2/10), (2/10)}
    else
        label.color = tes3ui.getPalette("magic_color")
    end
    block.parent:reorderChildren(cf.BindTooltipMode, -1, 1)
end

local function SpellBindTooltipExtended(e)
    if not cf.HotBarExtended then return end
    if not cf.BindTooltip then return end

    local binding = findBindingInExtended(e.spell.id)
    if not binding then return end
    
    local slotNumber = binding.slot
    if binding.panel == 2 then
        slotNumber = "2." .. binding.slot
    elseif binding.panel == 3 then
        slotNumber = "3." .. binding.slot
    end
    
    local text = i18n("HotBar.BindText.Magic", { type = mit[binding.type], slot = slotNumber })
    
    local block = e.tooltip:createBlock("spa_Quick")
    block.autoWidth = true
    block.autoHeight = true
    block.paddingAllSides = 2
    local label = block:createLabel{ text = text }
    label.wrapText = true
    label.color = tes3ui.getPalette("magic_color")
    block.parent:reorderChildren(cf.BindTooltipMode, -1, 1)
end

local function itemTooltip(e)
    if cf.HotBarExtended then
        itemBindTooltipExtended(e)
    else
        itemBindTooltip(e)
    end
end
event.register("uiObjectTooltip", itemTooltip)

local function spellTooltip(e)
    if cf.HotBarExtended then
        SpellBindTooltipExtended(e)
    else
        SpellBindTooltip(e)
    end
end
event.register("uiSpellTooltip", spellTooltip)

-- Определение зажатой клавиши слота расширенной панели
local function getPressedSlotExtended()
    local modifierKey2 = tes3.worldController.inputController:isKeyDown(config.mcm.modifierKey2.keyCode)
    local modifierKey3 = tes3.worldController.inputController:isKeyDown(config.mcm.modifierKey3.keyCode)

    for i = 1, 9 do
        local key = "quick" .. i
        if tes3.worldController.inputController:isKeyDown(tes3.getInputBinding(tes3.keybind[key]).code) and tes3.getInputBinding(tes3.keybind[key]).device ~= 1 then
            if modifierKey2 and not modifierKey3 then
                return { panel = 2, slot = i }
            elseif modifierKey3 and not modifierKey2 then
                return { panel = 3, slot = i }
            else
                return { panel = 1, slot = i }
            end
        end
    end
    return nil
end

-- Привязка предмета в расширенной панели
local function quickItemExtended(item, name, itemData)
    local binding = getPressedSlotExtended()
    if not binding then return false end
    
    local panelName = config.panelNames[binding.panel]
    if not tes3.player.data.quickKeys[panelName] then
        tes3.player.data.quickKeys[panelName] = {}
    end
    
    local slotData = {
        id = item.id,
        name = nil,
        icon = nil,
        isMagic = false,
        isItem = false
    }
    if itemData then
        slotData.savedItemData = {
            charge = itemData.charge,
            condition = itemData.condition,
            count = itemData.count,
            timeLeft = itemData.timeLeft,
        }
    end
    
    tes3.player.data.quickKeys[panelName][binding.slot] = slotData
    
    if cf.BindMessage then
        local slotNumber = binding.slot
        if binding.panel == 2 then
            slotNumber = "2." .. binding.slot
        elseif binding.panel == 3 then
            slotNumber = "3." .. binding.slot
        end
        tes3.messageBox(i18n("HotBar.BindMessage.Item", { name = name, slot = slotNumber }))
    end
    return true
end

-- Привязка магии в расширенной панели
local function quickMagicExtended(spell, name, isItem)
    if common.isProgrammaticClick then return false end -- проверка программного клика мыши
    local binding = getPressedSlotExtended()
    if not binding then return false end
    
    local panelName = config.panelNames[binding.panel]
    if not tes3.player.data.quickKeys[panelName] then
        tes3.player.data.quickKeys[panelName] = {}
    end
    
    local slotData = {
        id = spell.id,
        name = spell.name,
        icon = isItem and spell.icon or (spell.effects and spell.effects[1].object.bigIcon),
        isMagic = true,
        isItem = isItem or false
    }
    
    tes3.player.data.quickKeys[panelName][binding.slot] = slotData
    
    if cf.BindMessage then
        local slotNumber = binding.slot
        if binding.panel == 2 then
            slotNumber = "2." .. binding.slot
        elseif binding.panel == 3 then
            slotNumber = "3." .. binding.slot
        end
        tes3.messageBox(i18n("HotBar.BindMessage.Magic", { name = name, slot = slotNumber }))
    end
    return true
end

local function quickItem(item, name)
    local keyc = {2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i,v in pairs(keyc) do
        if (tes3.worldController.inputController:isKeyDown(v)) then
            local quickKey = tes3.getQuickKey({slot = i})
            quickKey:setItem(item)
            if cf.BindMessage then
                tes3.messageBox(i18n("HotBar.BindMessage.Item", { name = name, slot = i}))
            end
            return true
        end
    end
end

local function onInventory(e)
    if not cf.BindHoldClick then return end
    e.element:registerBefore("mouseClick", function()
        if cf.HotBarExtended then
            if quickItemExtended(e.item, e.item.name, e.itemData) then
                return false
            end
        else
            if quickItem(e.item, e.item.name) then
                return false
            end
        end
    end)
end
event.register("itemTileUpdated", onInventory, {filter = "MenuInventory"})

local function quickMagic(item, name)
    local keyc = {2, 3, 4, 5, 6, 7, 8, 9, 10}
    for i,v in pairs(keyc) do
        if (tes3.worldController.inputController:isKeyDown(v)) then
            local quickKey = tes3.getQuickKey({slot = i})
            quickKey:setMagic(item)
            if cf.BindMessage then
                tes3.messageBox(i18n("HotBar.BindMessage.Magic", { name = name, slot = i}))
            end
            return true
        end
    end
end

local function spellsTooBro()
    if not cf.BindHoldClick then return end
    if common.isProgrammaticClick then return end -- проверка программного клика мыши
    if not tes3.player then return end
    local menu = tes3ui.findMenu("MenuMagic")

    if not menu or not menu.visible then return end

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

    local SpellName = menu:findChild("MagicMenu_spell_names")
    for _, child in pairs(SpellName.children) do
        if table.find(spellList, child.text) then
            child:registerBefore("mouseClick", function()
                if cf.HotBarExtended then
                    if quickMagicExtended(spells[table.find(spellList, child.text)], child.text) then
                        return false
                    end
                else
                    if quickMagic(spells[table.find(spellList, child.text)], child.text) then
                        return false
                    end
                end
            end)
        end
    end

    local PowerName = menu:findChild("MagicMenu_power_names")
    for _, child in pairs(PowerName.children) do
        if table.find(birthname, child.text) then
            child:registerBefore("mouseClick", function()
                if cf.HotBarExtended then
                    if quickMagicExtended(birth[table.find(birthname, child.text)], child.text) then
                        return false
                    end
                else
                    if quickMagic(birth[table.find(birthname, child.text)], child.text) then
                        return false
                    end
                end
            end)
        end
    end

    local ItemName = menu:findChild("MagicMenu_item_names")
    for _, child in pairs(ItemName.children) do
        if table.find(eitemname, child.text) then
            child:registerBefore("mouseClick", function()
                if cf.HotBarExtended then
                    if quickMagicExtended(eitems[table.find(eitemname, child.text)], child.text, true) then
                        return false
                    end
                else
                    if quickMagic(eitems[table.find(eitemname, child.text)], child.text) then
                        return false
                    end
                end
            end)
        end
    end

end
event.register("mouseButtonDown", spellsTooBro)