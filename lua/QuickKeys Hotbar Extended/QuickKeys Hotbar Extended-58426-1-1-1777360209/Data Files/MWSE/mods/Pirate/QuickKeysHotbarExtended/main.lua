local i18n = mwse.loadTranslations("Pirate.QuickKeysHotbarExtended")
local config = require("Pirate.QuickKeysHotbarExtended.config")
local common = require("Pirate.QuickKeysHotbarExtended.common")
local cf = require("Pirate.QuickKeysHotbarExtended.config").mcm
local log = mwse.Logger.new{
    modName = i18n("mcm.modname"),
    level   = cf.logLevel
}
require("Pirate.QuickKeysHotbarExtended.mcm")
require("Pirate.QuickKeysHotbarExtended.QuickKeyOutlander")
if cf.HotBarExtended then
    require("Pirate.QuickKeysHotbarExtended.HotkeysExtended")
end
local seph = include("seph.hudCustomizer.interop")

local cfq
local cfTorch
local cfTorchEx
local menu
local clear = {}
local panelNames = config.panelNames
local emptySize
local barHeight
local hello
local menuInventory

local function getCount(item)
    local count = ""
    local consumableTypes = {
        [tes3.objectType.ingredient] = true,
        [tes3.objectType.alchemy] = true,
        [tes3.objectType.ammunition] = true,
      }
    local isScroll = item.objectType == tes3.objectType.book and item.type == tes3.bookType.scroll --annoying for scrolls
    local isThrowingWeapon = item.objectType == tes3.objectType.weapon and item.type == tes3.weaponType.marksmanThrown
    if consumableTypes[item.objectType] or isScroll or isThrowingWeapon then
        count = tes3.getItemCount({reference = tes3.player, item = item})
    end

    if tes3.getItemCount({reference = tes3.player, item = item}) == 0 and not (item.objectType == tes3.objectType.apparatus) then
        count = 0
    end
    return count
end

local function clearclickMenu()
    if hello then
        hello:destroy()
        hello = nil
    end
    local text = tes3.findGMST("sQuickMenu4").value.."?"
    hello = tes3ui.createMenu({id = "testmenu", dragFrame = true})
    hello.autoHeight = true
    hello.autoWidth = true

    local cursorX, cursorY = tes3.getCursorPosition().x, tes3.getCursorPosition().y
    -- по умолчанию открываем меню под курсором
    local posX = cursorX
    local posY = cursorY
    -- делаем поправку в зависимости от стороны экрана
    if cursorX > 0 then
        posX = cursorX - 120
    end
    if cursorY < 0 then
        posY = cursorY + 60
    end
    hello.positionX = posX
    hello.positionY = posY

    hello:destroyChildren()
    local hello2 = hello:createRect({id = "background", color = {0,0,0}})
    hello2.autoHeight = true
    hello2.autoWidth = true
    hello2 = hello2:createThinBorder()
    hello2.paddingAllSides = 2
    hello2.autoHeight = true
    hello2.autoWidth = true
    hello2.flowDirection = "top_to_bottom"
    hello2:createLabel({text = text})
    hello2 = hello2:createBlock()
    hello2.flowDirection = "left_to_right"
    hello2.autoHeight = true
    hello2.autoWidth = true
    local block = hello2:createBlock()
    block.width = 40
    block.height = 10

    return hello2
end

local function clearclick(quickKey)
    local hello2 = clearclickMenu()
    local yes = hello2:createButton()
    yes.text = tes3.findGMST("sYes").value
    yes:register("mouseClick", function()
        quickKey:clear()
        hello:destroy()
        hello = nil
    end)
    local no = hello2:createButton()
    no.text = tes3.findGMST("sNo").value
    no:register("mouseClick", function()
        hello:destroy()
        hello = nil end)
end

local function clearclickExtended(panelName, slot)
    local hello2 = clearclickMenu()
    local yes = hello2:createButton()
    yes.text = tes3.findGMST("sYes").value
    yes:register("mouseClick", function()
        tes3.player.data.quickKeys[panelName][slot] = {}
        hello:destroy()
        hello = nil
    end)
    
    local no = hello2:createButton()
    no.text = tes3.findGMST("sNo").value
    no:register("mouseClick", function()
        hello:destroy()
        hello = nil 
    end)
end

local function hotbarclickMenu()
    if hello then
        hello:destroy()
        hello = nil
    end
    menuInventory = tes3ui.findMenu("MenuInventory")
    local text = tes3.findGMST("sQuickMenu1").value.."?"
    hello = tes3ui.createMenu({id = "testmenu", dragFrame = true})
    hello.autoHeight = true
    hello.autoWidth = true

    local cursorX, cursorY = tes3.getCursorPosition().x, tes3.getCursorPosition().y
    -- по умолчанию открываем меню под курсором
    local posX = cursorX
    local posY = cursorY
    -- делаем поправку в зависимости от стороны экрана
    if cursorX > 0 then
        posX = cursorX - 180
    end
    if cursorY < 0 then
        posY = cursorY + 100
    end
    hello.positionX = posX
    hello.positionY = posY

    hello:destroyChildren()
    local hello2 = hello:createRect({id = "background", color = {0,0,0}})
    hello2.autoHeight = true
    hello2.autoWidth = true
    hello2 = hello2:createThinBorder()
    hello2.paddingAllSides = 2
    hello2.autoHeight = true
    hello2.autoWidth = true
    hello2.flowDirection = "top_to_bottom"
    local label = hello2:createLabel({text = text})
    label.wrapText = true
    label.justifyText = "center"
    hello2 = hello2:createBlock()
    hello2.flowDirection = "top_to_bottom"
    hello2.height = 70
    hello2.width = 200

    return hello2
end

local function hotbarclick(quickKey, item, itemData)
    local hello2 = hotbarclickMenu()
    local yes = hello2:createButton()
    yes.text = tes3.findGMST("sQuickMenu2").value
    yes.absolutePosAlignX = 0.5
    yes:register("mouseClick", function()
        quickKey:setItem(item, itemData)
        menuInventory:findChild("MenuInventory_scrollpane"):getContentElement():triggerEvent(tes3.uiEvent.mouseClick)
        hello:destroy()
        hello = nil end)

        if item.enchantment and (item.enchantment.castType == 0 or item.enchantment.castType == 2) then
            hello2.height = 100
        local no = hello2:createButton()
        no.text = tes3.findGMST("sQuickMenu3").value
        no.absolutePosAlignX = 0.5
        no:register("mouseClick", function()
        local _, err = pcall(function()
            quickKey:setMagic(item, itemData)
            menuInventory:findChild("MenuInventory_scrollpane"):getContentElement():triggerEvent(tes3.uiEvent.mouseClick)
        end)
        if err then
        tes3.messageBox(i18n("HotBar.error.EnchantBinding"))
        end
        hello:destroy()
        hello = nil end)
        end
    local maybe = hello2:createButton()
    maybe.text = tes3.findGMST("sCancel").value
    maybe.absolutePosAlignX = 0.5
    maybe:register("mouseClick", function()
        hello:destroy()
        hello = nil end)
end

local function hotbarclickExtended(quickKey, panelName, slot, item, itemData)
    local hello2 = hotbarclickMenu()
    local yes = hello2:createButton()
    yes.text = tes3.findGMST("sQuickMenu2").value
    yes.absolutePosAlignX = 0.5
    yes:register("mouseClick", function()
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
                --soul = itemData.soul and itemData.soul.id,
            }
        end
        tes3.player.data.quickKeys[panelName][slot] = slotData
        menuInventory:findChild("MenuInventory_scrollpane"):getContentElement():triggerEvent(tes3.uiEvent.mouseClick)
        hello:destroy()
        hello = nil 
    end)

    if item.enchantment and (item.enchantment.castType == 0 or item.enchantment.castType == 2) then
        hello2.height = 100
        local no = hello2:createButton()
        no.text = tes3.findGMST("sQuickMenu3").value
        no.absolutePosAlignX = 0.5
        no:register("mouseClick", function()
            local _, err = pcall(function()
                local slotData = {
                    id = item.id,
                    name = item.name,
                    icon = nil,
                    isMagic = true,
                    isItem = true
                }
                if itemData then
                    slotData.savedItemData = {
                        charge = itemData.charge,
                        condition = itemData.condition,
                        count = itemData.count,
                        timeLeft = itemData.timeLeft,
                        --soul = itemData.soul and itemData.soul.id,
                    }
                end
                tes3.player.data.quickKeys[panelName][slot] = slotData
                menuInventory:findChild("MenuInventory_scrollpane"):getContentElement():triggerEvent(tes3.uiEvent.mouseClick)
            end)
            if err then
                tes3.messageBox(i18n("HotBar.error.EnchantBinding"))
            end
            hello:destroy()
            hello = nil 
        end)
    end
    
    local maybe = hello2:createButton()
    maybe.text = tes3.findGMST("sCancel").value
    maybe.absolutePosAlignX = 0.5
    maybe:register("mouseClick", function()
        hello:destroy()
        hello = nil 
    end)
end

local function createEmptySlot(borde)
    local border
    border = borde:createThinBorder({id = "icon"})
    border.autoWidth = true
    border.autoHeight = true
    border.borderAllSides = 0
    border.paddingAllSides = config.BorderSize

    local darkness = border:createRect({id = "darkness", color = {0.0, 0.0, 0.0}})
    darkness.autoWidth = true
    darkness.autoHeight = true
    darkness.minWidth = cf.SlotIconSize + cf.equipBorderSize * 2
    darkness.minHeight = cf.SlotIconSize + cf.equipBorderSize * 2
    darkness.alpha = cf.SlotBackgroundAlpha / 100

    if cf.StatusBar then
        -- невидимый заполнитель высотой в две шкалы для выравнивания панели по вертикали
        local spacer = borde:createRect({id = "spacer", color = {0,0,0,0}})
        spacer.alpha = 0
        spacer.width = emptySize
        spacer.height = barHeight * 2
    end
    return border
end

local function updateHotbar()
    menu.visible = cf.HotBarVisible
    emptySize = cf.SlotIconSize + (config.BorderSize + cf.equipBorderSize) * 2
    barHeight = math.ceil(cf.SlotIconSize*3/16)
    local block = menu:findChild("Spa_HotQuick")
        if cf.HotBarExtended then
        block:destroyChildren()
        else
            menu:destroyChildren()
            block = menu:createRect({id = "Spa_HotQuick", color = {0.0, 0.0, 0.0}})
            block.alpha = 0
            block.autoWidth = true
            block.autoHeight = true
            block.paddingAllSides = -1
        end
    if not (seph and cf.sephIntegration) then
        menu.absolutePosAlignX = cf.HotBarPositionX / 100
        menu.absolutePosAlignY = cf.HotBarPositionY / 100
    end

    block.autoWidth = true
    block.autoHeight = true
    block.paddingAllSides = -1
    if cf.HotBarOrientation == "horizontal" then
        block.flowDirection = "left_to_right"
    else
        block.flowDirection = "top_to_bottom"
    end
    for slot = 1, 9 do
        local quickKey = tes3.getQuickKey({slot = slot})
        local currentItemData = quickKey and quickKey.item and common.getItemData(quickKey.item.id)
        if not currentItemData and quickKey and quickKey.item then
            -- Если нет актуальных данных, заполняем максимальными значениями
            currentItemData = {
                charge = quickKey.item.enchantment and quickKey.item.enchantment.maxCharge or 0,
                condition = quickKey.item.maxCondition or 0,
                count = 0,
                timeLeft = quickKey.item.time or 0,
            }
        end
        local barsCount = 0
        if quickKey and quickKey.item then
            local borde = block:createBlock({id = string.format("%s", slot)})
            borde.flowDirection = "top_to_bottom"
            borde.autoWidth = true
            borde.autoHeight = true
            borde.paddingAllSides = 0
            borde.borderAllSides = cf.SlotSpacing
            local border = borde:createThinBorder({id = "icon"})
            border.autoWidth = true
            border.autoHeight = true
            border.borderAllSides = 0
            border.paddingAllSides = config.BorderSize
            -- создаем прямоугольник - фон для слотов (рамка экипированного предмета\магии)
            local equippedBorder = border:createRect({id = "equipped", color = {0,0,0}})
            equippedBorder.autoWidth = true
            equippedBorder.autoHeight = true
            equippedBorder.paddingAllSides = cf.equipBorderSize
            -- устанавливаем прозрачность рамки по умолчанию из настроек меню.
            equippedBorder.alpha = cf.SlotBackgroundAlpha / 100
            -- меняем цвет рамки (прямоугольника) экипированного предмета
            if tes3.player.object:hasItemEquipped(quickKey.item) and quickKey:getMagic() == quickKey.item and tes3.mobilePlayer.currentEnchantedItem.itemData == quickKey.itemData then
                -- меняем цвет рамки на синий если предмет в слоте экипирован и его зачарование выбрано активным заклинанием.
                equippedBorder.color = {0,0,1}
                equippedBorder.alpha = 1
            elseif tes3.player.object:hasItemEquipped(quickKey.item) then
                -- меняем цвет рамки если предмет в слоте экипирован.
                if quickKey.item.objectType == tes3.objectType.light then
                    equippedBorder.color = {255 / 255,140 / 255,20 / 255}  -- жёлтый для светильников
                else
                    equippedBorder.color = tes3ui.getPalette("health_color") -- красный для остального
                end
                equippedBorder.alpha = 1
            end
            local darkness = equippedBorder:createRect({id = "darkness", color = {0.0, 0.0, 0.0}})
            darkness.width = cf.SlotIconSize
            darkness.height = cf.SlotIconSize
            darkness.alpha = cf.iconBackgroundAlpha / 100
            local count = getCount(quickKey.item)
            if count == 0 then
                table.insert(clear, slot)
            end
            if quickKey.item.enchantment then
                if cf.StatusBar then
                    -- шкала прочности, если у предмета есть максимальная прочность.
                    if currentItemData and quickKey.item.maxCondition and quickKey.item.maxCondition > 0 then
                        local conditionBar = borde:createFillBar({current = currentItemData.condition, max = quickKey.item.maxCondition})
                        conditionBar.widget.showText = false
                        conditionBar.width = emptySize
                        conditionBar.height = barHeight
                        barsCount = barsCount + 1
                    end
                    -- шкала заряда, если зачарование предмета выбрано активным заклинанием или предмет имеет эффект "при ударе"
                    if currentItemData and (quickKey:getMagic() or quickKey.item.enchantment.castType == 1) then
                        local chargeBar = borde:createFillBar({current = currentItemData.charge, max = quickKey.item.enchantment.maxCharge})
                        chargeBar.widget.fillColor = tes3ui.getPalette("magic_color")
                        chargeBar.widget.showText = false
                        chargeBar.width = emptySize
                        chargeBar.height = barHeight
                        barsCount = barsCount + 1
                    end
                end
                if cf.iconBackgroundTexture then
                    local texture = darkness:createImage({path = "Textures\\menu_icon_magic_mini.tga"})
                    texture.scaleMode = true
                    texture.width = cf.SlotIconSize
                    texture.height = cf.SlotIconSize
                end
                local shadowIcon = darkness:createImage({path = "Icons\\" .. quickKey.item.icon})
                shadowIcon.color = {0.0, 0.0, 0.0}
                shadowIcon.absolutePosAlignX = 0.8
                shadowIcon.absolutePosAlignY = 0.8
                shadowIcon.scaleMode = true
                shadowIcon.width = cf.SlotIconSize
                shadowIcon.height = cf.SlotIconSize
                local Icon = darkness:createImage({path = "Icons\\"..quickKey.item.icon})
                Icon.absolutePosAlignX = 0.5
                Icon.absolutePosAlignY = 0.5
                Icon.scaleMode = true
                Icon.width = cf.SlotIconSize
                Icon.height = cf.SlotIconSize
                local text = border:createLabel{text = tostring(count)}
                text.absolutePosAlignX = cf.ItemCountPositionX/100
                text.absolutePosAlignY = cf.ItemCountPositionY/100
                text.color = {1,1,1}
                -- иконка с первым эффектом (свитки)
                if cf.ScrollEffectIcons and quickKey.item.objectType == tes3.objectType.book and quickKey.item.type == tes3.bookType.scroll and quickKey.item.enchantment and quickKey.item.enchantment.effects[1] then
                    local effectIcon = darkness:createImage({path = "Icons\\"..quickKey.item.enchantment.effects[1].object[cf.effectIconStyle]})
                    effectIcon.scaleMode = true
                    effectIcon.width = cf.SlotIconSize*(cf.effectIconSize/100)
                    effectIcon.height = cf.SlotIconSize*(cf.effectIconSize/100)
                    effectIcon.absolutePosAlignX = cf.effectIconPositionX/100
                    effectIcon.absolutePosAlignY = cf.effectIconPositionY/100
                end
                -- иконка с первым эффектом (зачарованные предметы)
                if cf.EnchantEffectIcons and quickKey.item.objectType ~= tes3.objectType.book and quickKey.item.enchantment and quickKey.item.enchantment.effects[1] then
                    local effectIcon = darkness:createImage({path = "Icons\\"..quickKey.item.enchantment.effects[1].object[cf.effectIconStyle]})
                    effectIcon.scaleMode = true
                    effectIcon.width = cf.SlotIconSize*(cf.effectIconSize/100)
                    effectIcon.height = cf.SlotIconSize*(cf.effectIconSize/100)
                    effectIcon.absolutePosAlignX = cf.effectIconPositionX/100
                    effectIcon.absolutePosAlignY = cf.effectIconPositionY/100
                end
            if cf.SlotNumber then
                local slotn = border:createLabel{text = tostring(slot)}
                slotn.color = {1, 1, 1}
                slotn.absolutePosAlignX = cf.SlotNumberPositionX/100
                slotn.absolutePosAlignY = cf.SlotNumberPositionY/100
            end
            else
                if cf.StatusBar then
                    -- шкала прочности для предметов, если у предмета есть такое свойство
                    if currentItemData and quickKey.item.maxCondition and quickKey.item.maxCondition > 0 then
                        local label2 = borde:createFillBar({current = currentItemData.condition, max = quickKey.item.maxCondition})
                        label2.widget.showText = false
                        label2.width = emptySize
                        label2.height = barHeight
                        barsCount = barsCount + 1
                    end
                    -- шкала оставшегося времени для светильников
                    if currentItemData and quickKey.item.objectType == tes3.objectType.light then
                        if quickKey.item.time and quickKey.item.time > 0 then
                            local durationBar = borde:createFillBar({current = currentItemData.timeLeft, max = quickKey.item.time})
                            durationBar.widget.fillColor = {255 / 255,140 / 255,20 / 255}
                            durationBar.widget.showText = false
                            durationBar.width = emptySize
                            durationBar.height = barHeight
                            barsCount = barsCount + 1
                        end
                    end
                end
                local Icon = darkness:createImage({path = "Icons\\"..quickKey.item.icon})
                Icon.scaleMode = true
                Icon.width = cf.SlotIconSize
                Icon.height = cf.SlotIconSize
                local text = border:createLabel{text = tostring(count)}
                text.color = {1,1,1}
                text.absolutePosAlignX = cf.ItemCountPositionX/100
                text.absolutePosAlignY = cf.ItemCountPositionY/100
                -- иконка с первым эффектом (зелья)
                if cf.AlchemyEffectIcons and quickKey.item.objectType == tes3.objectType.alchemy and quickKey.item.effects and quickKey.item.effects[1] then
                    local effectIcon = darkness:createImage({path = "Icons\\"..quickKey.item.effects[1].object[cf.effectIconStyle]})
                    effectIcon.scaleMode = true
                    effectIcon.width = cf.SlotIconSize*(cf.effectIconSize/100)
                    effectIcon.height = cf.SlotIconSize*(cf.effectIconSize/100)
                    effectIcon.absolutePosAlignX = cf.effectIconPositionX/100
                    effectIcon.absolutePosAlignY = cf.effectIconPositionY/100
                end
            end
            -- невидимый заполнитель универсальной высоты для выравнивания панели по вертикали
            if cf.StatusBar and barsCount < 2 then
                local spacerHeight = (2 - barsCount) * barHeight
                if spacerHeight > 0 then
                    local spacer = borde:createRect({id = "spacer", color = {0,0,0,0}})
                    spacer.alpha = 0
                    spacer.width = emptySize
                    spacer.height = spacerHeight
                end
            end
            if cf.SlotNumber then
                local slotn = border:createLabel{text = tostring(slot)}
                slotn.color = {1, 1, 1}
                slotn.absolutePosAlignX = cf.SlotNumberPositionX/100
                slotn.absolutePosAlignY = cf.SlotNumberPositionY/100
            end
        elseif quickKey and quickKey.spell then
            local borde = block:createBlock({id = string.format("%s", slot)})
            borde.flowDirection = "top_to_bottom"
            borde.autoWidth = true
            borde.autoHeight = true
            borde.paddingAllSides = 0
            borde.borderAllSides = cf.SlotSpacing
            local border = borde:createThinBorder({id = "icon"})
            border.autoWidth = true
            border.autoHeight = true
            border.borderAllSides = 0
            border.paddingAllSides = config.BorderSize
            -- создаем прямоугольник - фон для слотов (рамка экипированного предмета\магии)
            local equippedBorder = border:createRect({id = "equipped", color = {0,0,0}})
            equippedBorder.autoWidth = true
            equippedBorder.autoHeight = true
            equippedBorder.paddingAllSides = cf.equipBorderSize
            -- устанавливаем прозрачность рамки по умолчанию из настроек меню.
            equippedBorder.alpha = cf.SlotBackgroundAlpha / 100

            if tes3.mobilePlayer.currentSpell == quickKey.spell then
                -- меняем цвет рамки на синий, если заклинание в слоте выбрано активным заклинанием.
                equippedBorder.color = {0,0,1}
                equippedBorder.alpha = 1
            end
            if cf.StatusBar then
                -- отображаем шкалу с шансом прочтения заклинания\способности
                local chance = quickKey.spell:calculateCastChance({checkMagicka = true, caster = tes3.player})
                local label2 = borde:createFillBar({current = chance, max = 100})
                label2.widget.fillColor = tes3ui.getPalette("magic_color")
                label2.widget.showText = false
                label2.width = emptySize
                label2.height = barHeight
                barsCount = barsCount + 1
            end
            -- невидимый заполнитель универсальной высоты для выравнивания панели по вертикали
            if cf.StatusBar and barsCount < 2 then
                local spacerHeight = (2 - barsCount) * barHeight
                if spacerHeight > 0 then
                    local spacer = borde:createRect({id = "spacer", color = {0,0,0,0}})
                    spacer.alpha = 0
                    spacer.width = emptySize
                    spacer.height = spacerHeight
               end
            end
            local darkness = equippedBorder:createRect({id = "darkness", color = {0.0, 0.0, 0.0}})
            darkness.width = cf.SlotIconSize
            darkness.height = cf.SlotIconSize
            darkness.alpha = cf.iconBackgroundAlpha / 100
            local spellicon = darkness:createImage({path = "Icons\\"..quickKey.spell.effects[1].object.bigIcon})
            spellicon.scaleMode = true
            spellicon.width = cf.SlotIconSize
            spellicon.height = cf.SlotIconSize
            if cf.SlotNumber then
                local slotn = border:createLabel{text = tostring(slot)}
                slotn.color = {1, 1, 1}
                slotn.absolutePosAlignX = cf.SlotNumberPositionX/100
                slotn.absolutePosAlignY = cf.SlotNumberPositionY/100
            end
        else
            local borde = block:createBlock({id = string.format("%s", slot)})
            borde.flowDirection = "top_to_bottom"
            borde.autoWidth = true
            borde.autoHeight = true
            borde.paddingAllSides = 0
            borde.borderAllSides = cf.SlotSpacing
            local border = createEmptySlot(borde)
            local slotn = border:createLabel{text = tostring(slot)}
            slotn.color = tes3ui.getPalette("normal_color")
            slotn.absolutePosAlignX = 0.5
            slotn.absolutePosAlignY = 0.4
        end
    end
    block:getTopLevelParent():updateLayout()

    -- очистка слотов когда выбранные предметы израсходованы (свитки\зелья)
    for _,v in ipairs(clear) do
        local quickKey = tes3.getQuickKey({slot = v})
        local borde = menu:findChild(string.format("%s", v))
        quickKey:clear()
        borde:destroyChildren()
        local border = createEmptySlot(borde)
        local slotn = border:createLabel{text = tostring(v)}
        slotn.color = tes3ui.getPalette("normal_color")
        slotn.absolutePosAlignX = 0.5
        slotn.absolutePosAlignY = 0.4
    end
    clear = {}
end

local function updateHotbarExtended()
    if not tes3.player or not tes3.player.data or not tes3.player.data.quickKeys then
        return
    end
    emptySize = cf.SlotIconSize + (config.BorderSize + cf.equipBorderSize) * 2
    barHeight = math.ceil(cf.SlotIconSize*3/16)
    local slotPrefix = {
        ["quick_"] = "",
        ["quick2"] = "2.",
        ["quickH"] = "3.",
    }

    local block = menu:findChild("Spa_HotQuick")
    if cf.HotBarExtended then
        block:destroyChildren()
    else
        menu:destroyChildren()
        block = menu:createRect({id = "Spa_HotQuick", color = {0.0, 0.0, 0.0}})
        block.alpha = 0
        block.autoWidth = true
        block.autoHeight = true
        block.paddingAllSides = -1
    end
    if not (seph and cf.sephIntegration) then
            menu.absolutePosAlignX = cf.HotBarPositionX / 100
            menu.absolutePosAlignY = cf.HotBarPositionY / 100
    end

    block.autoWidth = true
    block.autoHeight = true
    block.paddingAllSides = -1

if not cf.PanelsInOneLine then
    -- Направление главного контейнера (как располагаются панели)
    if cf.HotBarOrientation == "horizontal" then
        block.flowDirection = "top_to_bottom"  -- панели сверху/снизу (одна под другой)
    else
        block.flowDirection = "left_to_right"  -- панели слева/справа (одна за другой)
    end
else
    -- Режим "одна линия"
    if cf.HotBarOrientation == "horizontal" then
        block.flowDirection = "left_to_right"  -- все слоты горизонтально
    else
        block.flowDirection = "top_to_bottom"  -- все слоты вертикально
    end
end
    for p = 1, cf.numberVisiblePanels do
    local panelRow
    if not cf.PanelsInOneLine then
        -- Контейнер для одной панели
        panelRow = block:createBlock()
        panelRow.autoWidth = true
        panelRow.autoHeight = true
        panelRow.paddingAllSides = 0
        
        -- Направление слотов внутри панели
        if cf.HotBarOrientation == "horizontal" then
            panelRow.flowDirection = "left_to_right"
        else
            panelRow.flowDirection = "top_to_bottom"
        end
    end
        local panelData = tes3.player.data.quickKeys[panelNames[p]]
        if not panelData then
            panelData = {}
            tes3.player.data.quickKeys[panelNames[p]] = panelData
        end
        
        for slot = 1, cf.numberVisibleSlot do
            local quickKey = panelData[slot]
            local barsCount = 0
            if quickKey and quickKey.id and (quickKey.id ~= 0) then
                local item = tes3.getObject(quickKey.id)
                local count = item.objectType ~= tes3.objectType.spell and getCount(item)
                if count == 0 and item.objectType ~= tes3.objectType.spell then
                    table.insert(clear, {panelName = panelNames[p], slot = slot})
                end
                if not count then count = "" end
                local borde
                if not cf.PanelsInOneLine then
                    borde = panelRow:createBlock({id = string.format("%s_%s", panelNames[p], slot)})
                else
                    borde = block:createBlock({id = string.format("%s_%s", panelNames[p], slot)})
                end
                borde.flowDirection = "top_to_bottom"
                borde.autoWidth = true
                borde.autoHeight = true
                borde.paddingAllSides = 0
                borde.borderAllSides = cf.SlotSpacing
                local border = borde:createThinBorder({id = "icon"})
                border.autoWidth = true
                border.autoHeight = true
                border.borderAllSides = 0
                border.paddingAllSides = config.BorderSize
                -- создаем прямоугольник - фон для слотов (рамка экипированного предмета\магии)
                local equippedBorder = border:createRect({id = "equipped", color = {0,0,0}})
                equippedBorder.autoWidth = true
                equippedBorder.autoHeight = true
                equippedBorder.paddingAllSides = cf.equipBorderSize
                -- устанавливаем прозрачность рамки по умолчанию из настроек меню.
                equippedBorder.alpha = cf.SlotBackgroundAlpha / 100
                -- меняем цвет рамки (прямоугольника) экипированного предмета
                if tes3.player.object:hasItemEquipped(item) and tes3.mobilePlayer.currentEnchantedItem.object == item then
                    -- меняем цвет рамки на синий если предмет в слоте экипирован и его зачарование выбрано активным заклинанием.
                    equippedBorder.color = {0,0,1}
                    equippedBorder.alpha = 1
                elseif tes3.player.object:hasItemEquipped(item) then
                    -- меняем цвет рамки на синий если предмет в слоте экипирован
                    if item.objectType == tes3.objectType.light then
                        equippedBorder.color = {255 / 255,140 / 255,20 / 255}  -- жёлтый для светильников
                    else
                        equippedBorder.color = tes3ui.getPalette("health_color")  -- красный для остальной экипировки
                    end
                    equippedBorder.alpha = 1
                end
                if quickKey.isMagic and not quickKey.isItem then
                    if tes3.mobilePlayer.currentSpell and tes3.mobilePlayer.currentSpell.id == quickKey.id then
                        -- меняем цвет рамки на синий, если заклинание в слоте выбрано активным заклинанием.
                        equippedBorder.color = {0,0,1}
                        equippedBorder.alpha = 1
                    end
                end
                if quickKey.isMagic and quickKey.isItem and item.objectType == tes3.objectType.book and item.type == tes3.bookType.scroll then
                    if tes3.mobilePlayer.currentEnchantedItem and 
                       tes3.mobilePlayer.currentEnchantedItem.object and 
                       tes3.mobilePlayer.currentEnchantedItem.object.id == quickKey.id then
                        -- меняем цвет рамки на синий, если свиток в слоте выбран активным заклинанием.
                        equippedBorder.color = {0,0,1}
                        equippedBorder.alpha = 1
                    end
                end

                if cf.StatusBar then
                    local itemData = nil
                    local liveData = common.getItemData(quickKey.id)
                    if liveData then
                        -- если предмет экипирован, обновляем savedItemData
                        if not quickKey.savedItemData then
                            quickKey.savedItemData = {}
                        end
                        quickKey.savedItemData.charge = liveData.charge
                        quickKey.savedItemData.condition = liveData.condition
                        quickKey.savedItemData.count = liveData.count
                        quickKey.savedItemData.timeLeft = liveData.timeLeft

                        itemData = quickKey.savedItemData  -- используем обновлённые данные
                    else
                        local item = tes3.getObject(quickKey.id)
                        if item then
                            quickKey.savedItemData = {
                                charge = item.enchantment and item.enchantment.maxCharge or 0,
                                condition = item.maxCondition or 0,
                                count = 0,
                                timeLeft = item.time or 0,
                            }
                            itemData = quickKey.savedItemData
                        else
                            quickKey.savedItemData = nil
                            itemData = nil
                        end
                    end
                    -- шкала прочности для оружия и брони (у которых есть прочность)
                    if itemData and (item.objectType == tes3.objectType.weapon or item.objectType == tes3.objectType.armor) then
                        if item.maxCondition and item.maxCondition > 0 then
                            local conditionBar = borde:createFillBar({current = itemData.condition, max = item.maxCondition})
                            conditionBar.widget.showText = false
                            conditionBar.width = emptySize
                            conditionBar.height = barHeight
                            barsCount = barsCount + 1
                        end
                    end
                    -- шкала заряда для зачарованных предметов эффект "при ударе"
                    if itemData and item.enchantment and item.enchantment.maxCharge and item.enchantment.maxCharge > 0 then
                        if item.enchantment.castType == 1 then
                            if itemData.charge then
                                local chargeBar = borde:createFillBar({current = itemData.charge, max = item.enchantment.maxCharge})
                                chargeBar.widget.fillColor = tes3ui.getPalette("magic_color")
                                chargeBar.widget.showText = false
                                chargeBar.width = emptySize
                                chargeBar.height = barHeight
                                barsCount = barsCount + 1
                            end
                        end
                    end
                    -- шкала шанса для заклинаний и способностей
                    if quickKey.isMagic and not quickKey.isItem and item and item.calculateCastChance then
                        local chance = item:calculateCastChance({checkMagicka = true, caster = tes3.player})
                        local chanceBar = borde:createFillBar({current = chance, max = 100})
                        chanceBar.widget.fillColor = tes3ui.getPalette("magic_color")
                        chanceBar.widget.showText = false
                        chanceBar.width = emptySize
                        chanceBar.height = barHeight
                        barsCount = barsCount + 1
                    end
                    -- шкала заряда для эффекта "при использовании" зачарованных предметов
                    if quickKey.isMagic and quickKey.isItem and item and item.enchantment and itemData and item.enchantment.maxCharge and item.enchantment.maxCharge > 0 then
                        if item.enchantment.castType == 2 then
                            local chargeBar = borde:createFillBar({current = itemData.charge, max = item.enchantment.maxCharge})
                            chargeBar.widget.fillColor = tes3ui.getPalette("magic_color")
                            chargeBar.widget.showText = false
                            chargeBar.width = emptySize
                            chargeBar.height = barHeight
                            barsCount = barsCount + 1
                        end
                    end
                    -- шкала оставшегося времени для светильников
                    if itemData and item.objectType == tes3.objectType.light then
                        if item.time and item.time > 0 then
                            local durationBar = borde:createFillBar({current = itemData.timeLeft, max = item.time})
                            durationBar.widget.fillColor = {255 / 255,140 / 255,20 / 255}
                            durationBar.widget.showText = false
                            durationBar.width = emptySize
                            durationBar.height = barHeight
                            barsCount = barsCount + 1
                        end
                    end
                end
                -- невидимый заполнитель универсальной высоты для выравнивания панели по вертикали
                if cf.StatusBar and barsCount < 2 then
                    local spacerHeight = (2 - barsCount) * barHeight
                    if spacerHeight > 0 then
                        local spacer = borde:createRect({id = "spacer", color = {0,0,0,0}})
                        spacer.alpha = 0
                        spacer.width = emptySize
                        spacer.height = spacerHeight
                    end
                end

                local darkness = equippedBorder:createRect({id = "darkness", color = {0.0, 0.0, 0.0}})
                darkness.width = cf.SlotIconSize
                darkness.height = cf.SlotIconSize
                darkness.alpha = cf.iconBackgroundAlpha / 100
                local path = item.icon or item.effects[1].object.bigIcon
                if item.enchantment then
                    if cf.iconBackgroundTexture then
                        local texture = darkness:createImage({path = "Textures\\menu_icon_magic_mini.tga"})
                        texture.scaleMode = true
                        texture.width = cf.SlotIconSize
                        texture.height = cf.SlotIconSize
                    end
                    local shadowIcon = darkness:createImage({path = "Icons\\" .. path})
                    shadowIcon.color = {0.0, 0.0, 0.0}
                    shadowIcon.absolutePosAlignX = 0.8
                    shadowIcon.absolutePosAlignY = 0.8
                    shadowIcon.scaleMode = true
                    shadowIcon.width = cf.SlotIconSize
                    shadowIcon.height = cf.SlotIconSize
                    local Icon = darkness:createImage({path = "Icons\\"..path})
                    Icon.absolutePosAlignX = 0.5
                    Icon.absolutePosAlignY = 0.5
                    Icon.scaleMode = true
                    Icon.width = cf.SlotIconSize
                    Icon.height = cf.SlotIconSize
                    local text = border:createLabel{text = tostring(count)}
                    text.absolutePosAlignX = cf.ItemCountPositionX/100
                    text.absolutePosAlignY = cf.ItemCountPositionY/100
                    text.color = {1,1,1}
                    -- иконка с первым эффектом (свитки)
                    if cf.ScrollEffectIcons and item.objectType == tes3.objectType.book and item.type == tes3.bookType.scroll and item.enchantment and item.enchantment.effects[1] then
                        local effectIcon = darkness:createImage({path = "Icons\\"..item.enchantment.effects[1].object[cf.effectIconStyle]})
                        effectIcon.scaleMode = true
                        effectIcon.width = cf.SlotIconSize*(cf.effectIconSize/100)
                        effectIcon.height = cf.SlotIconSize*(cf.effectIconSize/100)
                        effectIcon.absolutePosAlignX = cf.effectIconPositionX/100
                        effectIcon.absolutePosAlignY = cf.effectIconPositionY/100
                    end
                    -- иконка с первым эффектом (зачарованные предметы)
                    if cf.EnchantEffectIcons and item.objectType ~= tes3.objectType.book and item.enchantment and item.enchantment.effects[1] then
                        local effectIcon = darkness:createImage({path = "Icons\\"..item.enchantment.effects[1].object[cf.effectIconStyle]})
                        effectIcon.scaleMode = true
                        effectIcon.width = cf.SlotIconSize*(cf.effectIconSize/100)
                        effectIcon.height = cf.SlotIconSize*(cf.effectIconSize/100)
                        effectIcon.absolutePosAlignX = cf.effectIconPositionX/100
                        effectIcon.absolutePosAlignY = cf.effectIconPositionY/100
                    end
                else
                    local Icon = darkness:createImage({path = "Icons\\"..path})
                    Icon.scaleMode = true
                    Icon.width = cf.SlotIconSize
                    Icon.height = cf.SlotIconSize
                    local text = border:createLabel{text = tostring(count)}
                    text.color = {1,1,1}
                    text.absolutePosAlignX = cf.ItemCountPositionX/100
                    text.absolutePosAlignY = cf.ItemCountPositionY/100
                    -- иконка с первым эффектом (зелья)
                    if cf.AlchemyEffectIcons and item.objectType == tes3.objectType.alchemy and item.effects and item.effects[1] then
                        local effectIcon = darkness:createImage({path = "Icons\\"..item.effects[1].object[cf.effectIconStyle]})
                        effectIcon.scaleMode = true
                        effectIcon.width = cf.SlotIconSize*(cf.effectIconSize/100)
                        effectIcon.height = cf.SlotIconSize*(cf.effectIconSize/100)
                        effectIcon.absolutePosAlignX = cf.effectIconPositionX/100
                        effectIcon.absolutePosAlignY = cf.effectIconPositionY/100
                    end
                end
                if cf.SlotNumber then
                    local slotNumber = border:createLabel{text = slotPrefix[panelNames[p]] .. tostring(slot)}
                    slotNumber.color = {1, 1, 1}
                    slotNumber.absolutePosAlignX = cf.SlotNumberPositionX/100
                    slotNumber.absolutePosAlignY = cf.SlotNumberPositionY/100
                end
            else
                local borde
                if not cf.PanelsInOneLine then
                    borde = panelRow:createBlock({id = string.format("%s_%s", panelNames[p], slot)})
                else
                    borde = block:createBlock({id = string.format("%s_%s", panelNames[p], slot)})
                end
                borde.flowDirection = "top_to_bottom"
                borde.autoWidth = true
                borde.autoHeight = true
                borde.paddingAllSides = 0
                borde.borderAllSides = cf.SlotSpacing
                local border = createEmptySlot(borde)
                local slotn = border:createLabel{text = slotPrefix[panelNames[p]] .. tostring(slot)}
                slotn.color = tes3ui.getPalette("normal_color")
                slotn.absolutePosAlignX = 0.5
                slotn.absolutePosAlignY = 0.4
            end
        end
    end
    menu:updateLayout()

    -- очистка слотов когда выбранные предметы израсходованы (свитки\зелья)
    for _, item in ipairs(clear) do
        local panelData = tes3.player.data.quickKeys[item.panelName]
        if panelData and panelData[item.slot] then
            panelData[item.slot].id = nil
            panelData[item.slot].savedItemData = nil
            panelData[item.slot].name = nil
            panelData[item.slot].icon = nil
            panelData[item.slot].isMagic = false
            panelData[item.slot].isItem = false
        end

        local borde = menu:findChild(string.format("%s_%s", item.panelName, item.slot))
        if borde then
            borde:destroyChildren()
            local border = createEmptySlot(borde)
            local slotn = border:createLabel{text = slotPrefix[item.panelName] .. tostring(item.slot)}
            slotn.color = tes3ui.getPalette("normal_color")
            slotn.absolutePosAlignX = 0.5
            slotn.absolutePosAlignY = 0.4
        end
    end
    clear = {}
end

local function press(e)
    local dont = true
    for i = 22, 30 do
        if tes3.getInputBinding(i).code == e.keyCode then
            dont = false
        end
        if cfq and cfq.keyEquip.keyCode == e.keyCode then
            dont = false
        end
    end
    -- проверка нажатия клавиши факела из моей версии мода Torch Hotkey
    if cfTorch and cfTorch.torchKey.keyCode and cfTorch.torchKey.keyCode == e.keyCode then
        dont = false
    end
    -- проверка нажатия клавиши факела из Torch Hotkey Expanded
    if cfTorchEx and cfTorchEx.hotkey.keyCode and cfTorchEx.hotkey.keyCode == e.keyCode then
        dont = false
    end

    if dont then
        return
    end
    if menu then
        menu.visible = cf.HotBarVisible
        if cf.HotBarExtended then
            updateHotbarExtended()
        else
            updateHotbar()
        end
    end
end event.register("keyUp", press)

local function menuExit()
    if cfTorch then
        cfTorch = mwse.loadConfig("TorchHotkey")
    end
    if cfTorchEx then
        cfTorchEx = mwse.loadConfig("Torch Hotkey Expanded")
    end

    if cf.HotBarExtended then
        updateHotbarExtended()
    end
end event.register("menuExit", menuExit)

local function mouseButtonDown()
    if hello and tes3.worldController.inputController:isMouseButtonDown(1) then
        hello:destroy()
        hello = nil
    end
    if not menu then return end
    if cf.HotBarExtended then
        for p = 1, cf.numberVisiblePanels do
            local panelName = panelNames[p]
            for slot = 1, 9 do
                local block = menu:findChild(string.format("%s_%s", panelName, slot))
                if block then
                    block:register(tes3.uiEvent.mouseClick, function()
                        -- Проверяем, есть ли предмет под курсором
                        local cursor = tes3ui.findHelpLayerMenu("CursorIcon")
                        local c
                        if cursor then
                            c = cursor:getPropertyObject("MenuInventory_Thing", "tes3inventoryTile")
                        end
                        
                        local quickKey = tes3.player.data.quickKeys[panelName][slot]
                        local menuInventory = tes3ui.findMenu("MenuInventory")
                        local pcInventory = tes3.player.object.inventory
                        
                        -- Если есть предмет под курсором (перетаскивание)
                        if c and pcInventory:contains(c.item, c.itemData) and menuInventory then
                            hotbarclickExtended(quickKey, panelName, slot, c.item, c.itemData)
                        else
                            -- Если просто клик по слоту
                            if quickKey and quickKey.id then
                                clearclickExtended(panelName, slot)
                            end
                        end
                    end)
                end
            end
        end
    else
        for slot = 1, 9 do
            local quickKey = tes3.getQuickKey({slot = slot})
            local block = menu:findChild(string.format("%s", slot))
            local cursor = tes3ui.findHelpLayerMenu("CursorIcon")
            local c
            if cursor then
             c = cursor:getPropertyObject("MenuInventory_Thing", "tes3inventoryTile")
            end
            local menuInventory = tes3ui.findMenu("MenuInventory")
            local pcInventory = tes3.player.object.inventory
            block:register(tes3.uiEvent.mouseClick, function()
                if c and pcInventory:contains(c.item, c.itemData) and menuInventory then
                     hotbarclick(quickKey, c.item, c.itemData)
                else
                    if quickKey.item or quickKey.spell then
                        clearclick(quickKey)
                    else
                        return
                    end
                end
            end)
        end
    end
end event.register("mouseButtonDown", mouseButtonDown)

local function tooltipHotbarExtended(panelName, slot)
    local quickKey = tes3.player.data.quickKeys[panelName][slot]
    if not quickKey or not quickKey.id then return end
    
    if quickKey.isMagic and not quickKey.isItem then
        local spell = tes3.getObject(tostring(quickKey.id))
        if spell then
            tes3ui.createTooltipMenu({ spell = spell })
        end
    else
        local item = tes3.getObject(quickKey.id)
        if item then
            local itemData = common.getItemData(quickKey.id)
            tes3ui.createTooltipMenu({ item = item, itemData = itemData })
        end
    end
end

local function tooltips()
    if not menu then return end
    if cf.HotBarExtended then
        for p = 1, cf.numberVisiblePanels do
            local panelName = panelNames[p]
            for slot = 1, 9 do
                local block = menu:findChild(string.format("%s_%s", panelName, slot))
                if block then
                    block:register(tes3.uiEvent.help, function()
                        tooltipHotbarExtended(panelName, slot)
                    end)
                end
            end
        end
    else
        for slot = 1, 9 do
            local quickKey = tes3.getQuickKey({slot = slot})
            local block = menu:findChild(string.format("%s", slot))
            block:register(tes3.uiEvent.help, function()
                if quickKey and quickKey.item then
                    local itemData = common.getItemData(quickKey.item.id)
                    tes3ui.createTooltipMenu({ item = quickKey.item, itemData = itemData})
                elseif quickKey and quickKey.spell then
                    tes3ui.createTooltipMenu({spell = quickKey.spell})
                end
            end)
        end
    end
end
event.register("mouseAxis", tooltips)

local function mouseClickUpdateHotbar()
    if menu then
        menu.visible = cf.HotBarVisible
        if cf.HotBarExtended then
            timer.start({duration = 0.4, type = timer.real, callback = updateHotbarExtended })
        else
        timer.start({duration = 0.4, type = timer.real, callback = updateHotbar })
        end
    end
end event.register("mouseButtonUp", mouseClickUpdateHotbar)

local function realTimeUpdateHotbar()
    if not cf.HotBarBgUpdate then return end
    if tes3.menuMode() and not tes3ui.findMenu(tes3ui.registerID("MWSE:ModConfigMenu")) then return end
    if not menu or not menu.visible then return end
    if cf.HotBarExtended then
        updateHotbarExtended()
    else
        updateHotbar()
    end
end

local function startTimer()
    if not cf.HotBarBgUpdate then return end
    timer.start({
        duration = cf.BgUpdateInterval/1000,
        type = timer.real,
        callback = realTimeUpdateHotbar,
        iterations = -1
    })
end

local function loaded(e)
    if not e.newlyCreated then return end

    local parent = e.element:findChild(tes3ui.registerID("PartNonDragMenu_main"))
    menu = parent:createRect({id = "ExtendedHotkeyBar", color = {0.0, 0.0, 0.0}})
    menu.alpha = 0
    menu.autoWidth = true
    menu.autoHeight = true
    menu.visible = cf.HotBarVisible

    local block = menu:createRect({id = "Spa_HotQuick", color = {0.0, 0.0, 0.0}})
    block.alpha = 0
    block.autoWidth = true
    block.autoHeight = true
    block.paddingAllSides = -1

    if cf.HotBarExtended then
        updateHotbarExtended()
    else
        updateHotbar()
    end

end event.register(tes3.event.uiActivated, loaded, { filter = "MenuMulti" })

local function initialized()
    if seph and cf.sephIntegration then
        seph:registerElement(
        "ExtendedHotkeyBar",
        i18n("mcm.modname"),
        {
        positionX = 0.5,    -- центр по горизонтали
        positionY = 1.0,   -- самый низ экрана
        visible = true
        }, 
        {
        position = true,
        --visibility = true,
        })
    end
    if cf.HotBarBgUpdate then
        event.register("loaded", startTimer)
    end
    -- загрузка конфигурации - моя версия мода Torch Hotkey
    if tes3.isLuaModActive("Torch Hotkey") then
        cfTorch = mwse.loadConfig("TorchHotkey")
    end
    -- загрузка конфигурации - Torch Hotkey Expanded
    if tes3.isLuaModActive("Torch Hotkey Expanded") then
        cfTorchEx = mwse.loadConfig("Torch Hotkey Expanded")
    end

    if tes3.isLuaModActive([[Spammer/QuickKey Outlander]]) then
        cfq = mwse.loadConfig("QuickKey Outlander!")
    end
    log:info("Version: "..config.modVersion.." Initialized!")
end event.register("initialized", initialized)
