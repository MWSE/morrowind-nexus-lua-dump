local mod = {
    name = "Quickkeys Hotbar",
    ver = "1.2",
    cf = {onOff2 = true, key = {keyCode = tes3.scanCode.l, isShiftDown = false, isAltDown = false, isControlDown = false}, dropDown = 0, slider = 4, sliderpercent2 = 32, blocked = {}, npcs = {}, textfield = "hello", switch = false}
            }
local cf = mwse.loadConfig(mod.name, mod.cf)
local cfq


local seph = include("seph.hudCustomizer.interop")


local menu
local state = 0
local hope = 0
local clear = {}

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

    if tes3.getItemCount({reference = tes3.player, item = item}) == 0 then
        count = 0
    end
    return count
end
local hello
local function clearclick(quickKey)
    local text = tes3.findGMST("sQuickMenu4").value.."?"
    hello = tes3ui.createMenu({id = "testmenu", dragFrame = true})
    hello.autoHeight = true
    hello.autoWidth = true
    hello.text = "Trying this"
    if cf.dropDown ~= 1 and cf.dropDown ~= 3 then
    hello.positionX = tes3.getCursorPosition().x
    hello.positionY = tes3.getCursorPosition().y
    elseif cf.dropDown == 1 then
    hello.positionX = tes3.getCursorPosition().x
    hello.positionY = tes3.getCursorPosition().y+100
    else
        hello.positionX = tes3.getCursorPosition().x-180
        hello.positionY = tes3.getCursorPosition().y
    end
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


local function hotbarclick(quickKey, item, itemData)
    local menuInventory = tes3ui.findMenu("MenuInventory")
    local text = tes3.findGMST("sQuickMenu1").value.."?"
    hello = tes3ui.createMenu({id = "testmenu", dragFrame = true})
    hello.autoHeight = true
    hello.autoWidth = true
    hello.text = "Trying this"
    if cf.dropDown ~= 1 and cf.dropDown ~= 3 then
        hello.positionX = tes3.getCursorPosition().x
        hello.positionY = tes3.getCursorPosition().y
    elseif cf.dropDown == 1 then
        hello.positionX = tes3.getCursorPosition().x
        hello.positionY = tes3.getCursorPosition().y+100
    else
        hello.positionX = tes3.getCursorPosition().x-180
        hello.positionY = tes3.getCursorPosition().y
    end
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
        tes3.messageBox("Unable to bind the Item. Make sure it has a Valid Enchantment. (\"Cast When Used\" or \"Cast Once\" required)")
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
    if dont then
        return
    end
    if menu then
        menu.visible = cf.onOff2
        local block = menu:findChild("Spa_HotQuick")
            if cf.onOff then
            block:destroyChildren()
            else
                menu:destroyChildren()
                block = menu:createRect({id = "Spa_HotQuick", color = {0.0, 0.0, 0.0}})
                block.alpha = 0
                block.autoWidth = true
                block.autoHeight = true
                block.paddingAllSides = -1
            end
        if not seph then
            if cf.dropDown == 0 then
                menu.absolutePosAlignX = 0.5
                menu.absolutePosAlignY = 0.01
            elseif cf.dropDown == 1 then
                menu.absolutePosAlignX = 0.5
                menu.absolutePosAlignY = 0.985
            elseif cf.dropDown == 2 then
                menu.absolutePosAlignX = 0.01
                menu.absolutePosAlignY = 0.5
            elseif cf.dropDown == 3 then
                menu.absolutePosAlignX = 0.99
                menu.absolutePosAlignY = 0.5
            end
        end
            block.autoWidth = true
            block.autoHeight = true
            block.paddingAllSides = -1
            if cf.dropDown <= 1 then
                block.flowDirection = "left_to_right"
            else
                block.flowDirection = "top_to_bottom"
            end
            for slot = 1, 9 do
                local quickKey = tes3.getQuickKey({slot = slot})
                if quickKey and quickKey.item then
                    hope = 0
                    local borde = block:createBlock({id = string.format("%s", slot)})
                    borde.flowDirection = "top_to_bottom"
                    borde.autoWidth = true
                    borde.autoHeight = true
                    borde.paddingAllSides = 0
                    borde.borderAllSides = cf.slider
                    local border = borde:createThinBorder({id = "icon"})
                    border.autoWidth = true
                    border.autoHeight = true
                    border.borderAllSides = 0
                    border.paddingAllSides = 2
                    if tes3.player.object:hasItemEquipped(quickKey.item) and quickKey:getMagic() == quickKey.item and tes3.mobilePlayer.currentEnchantedItem.itemData == quickKey.itemData then
                        border = border:createRect({id = "equipped", color = {0,0,1}})
                        border.autoWidth = true
                        border.autoHeight = true
                        border.paddingAllSides = 1
                        hope = 2
                    elseif tes3.player.object:hasItemEquipped(quickKey.item) then
                        border.color = tes3ui.getPalette("health_color")
                        border = border:createRect({id = "equipped", color = tes3ui.getPalette("health_color")})
                        border.autoWidth = true
                        border.autoHeight = true
                        border.paddingAllSides = 1
                        hope = 2
                    end
                    local darkness = border:createRect({id = "darkness", color = {0.0, 0.0, 0.0}})
                    darkness.autoWidth = true
                    darkness.autoHeight = true
                    local count = getCount(quickKey.item)
                    if count == 0 then
                        table.insert(clear, slot)
                    end
                    if quickKey.item.enchantment then
                        if quickKey.itemData and quickKey:getMagic() then
                            local label2 = borde:createFillBar({current = quickKey.itemData.charge, max = quickKey.item.enchantment.maxCharge})
                            label2.widget.showText = false
                            label2.width = (cf.sliderpercent2+4)+hope
                            label2.height = (cf.sliderpercent2*3/16)
                        elseif quickKey.itemData then
                            local label2 = borde:createFillBar({current = quickKey.itemData.condition, max = quickKey.item.maxCondition})
                            label2.widget.showText = false
                            label2.width = (cf.sliderpercent2+4)+hope
                            label2.height = (cf.sliderpercent2*3/16)
                        end
                        local texture = darkness:createImage({path = "Textures\\menu_icon_magic_mini.tga"})
                        texture.scaleMode = true
                        texture.width = cf.sliderpercent2
                        texture.height = cf.sliderpercent2
                        local shadowIcon = darkness:createImage({path = "Icons\\" .. quickKey.item.icon})
                        shadowIcon.color = {0.0, 0.0, 0.0}
                        shadowIcon.absolutePosAlignX = 0.8
                        shadowIcon.absolutePosAlignY = 0.8
                        shadowIcon.scaleMode = true
                        shadowIcon.width = cf.sliderpercent2
                        shadowIcon.height = cf.sliderpercent2
                        local Icon = darkness:createImage({path = "Icons\\"..quickKey.item.icon})
                        Icon.absolutePosAlignX = 0.5
                        Icon.absolutePosAlignY = 0.5
                        Icon.scaleMode = true
                        Icon.width = cf.sliderpercent2
                        Icon.height = cf.sliderpercent2
                        local text = border:createLabel{text = tostring(count)}
                        text.absolutePosAlignX = 0.9
                        text.absolutePosAlignY = 0.9
                        text.color = {1,1,1}
                    else
                        if quickKey.itemData then local label2 = borde:createFillBar({current = quickKey.itemData.condition, max = quickKey.item.maxCondition})
                            label2.widget.showText = false
                            label2.width = (cf.sliderpercent2+4)+hope
                            label2.height = (cf.sliderpercent2*3/16) end
                            local Icon = darkness:createImage({path = "Icons\\"..quickKey.item.icon})
                            Icon.scaleMode = true
                            Icon.width = cf.sliderpercent2
                            Icon.height = cf.sliderpercent2
                        local text = border:createLabel{text = tostring(count)}
                        text.color = {1,1,1}
                        text.absolutePosAlignX = 0.9
                        text.absolutePosAlignY = 0.9
                    end
                elseif quickKey and quickKey.spell then
                    hope = 0
                    local borde = block:createBlock({id = string.format("%s", slot)})
                    borde.flowDirection = "top_to_bottom"
                    borde.autoWidth = true
                    borde.autoHeight = true
                    borde.paddingAllSides = 0
                    borde.borderAllSides = cf.slider
                    local border = borde:createThinBorder({id = "icon"})
                    border.autoWidth = true
                    border.autoHeight = true
                    border.borderAllSides = 0
                    border.paddingAllSides = 2
                    if tes3.mobilePlayer.currentSpell == quickKey.spell then
                        border = border:createRect({id = "equipped", color = {0,0,1}})
                        border.autoWidth = true
                        border.autoHeight = true
                        border.paddingAllSides = 1
                        hope = 2
                    end
                    local chance = quickKey.spell:calculateCastChance({checkMagicka = true, caster = tes3.player})
                    local label2 = borde:createFillBar({current = chance, max = 100})
                    --label2.widget.fillColor = tes3ui.getPalette("magic_color")
                    label2.widget.showText = false
                    label2.width = (cf.sliderpercent2+4)+hope
                    label2.height = (cf.sliderpercent2*3/16)
                    local darkness = border:createRect({id = "darkness", color = {0.0, 0.0, 0.0}})
                    darkness.autoWidth = true
                    darkness.autoHeight = true
                    local spellicon = border:createImage({path = "Icons\\"..quickKey.spell.effects[1].object.bigIcon})
                    spellicon.scaleMode = true
                    spellicon.width = cf.sliderpercent2
                    spellicon.height = cf.sliderpercent2
                else
                    local borde = block:createBlock({id = string.format("%s", slot)})
                    borde.flowDirection = "top_to_bottom"
                    borde.autoWidth = true
                    borde.autoHeight = true
                    borde.paddingAllSides = 0
                    borde.borderAllSides = cf.slider
                    local border = borde:createThinBorder():createThinBorder({id = "icon"})
                    local darkness = border:createRect({id = "darkness", color = {0.0, 0.0, 0.0}})
                    darkness.autoWidth = true
                    darkness.autoHeight = true
                    darkness.minWidth = cf.sliderpercent2
                    darkness.minHeight = cf.sliderpercent2
                    border.autoWidth = true
                    border.autoHeight = true
                    border.parent.autoWidth = true
                    border.parent.autoHeight = true
                    border.parent.borderAllSides = 0
                    border.paddingAllSides = 2
                    border.borderAllSides = 0
                    --border:createImage({path = "Icons\\Spammer\\qhicon.dds"})
                    local slotn = border:createLabel{text = tostring(slot)}
                    slotn.color = tes3ui.getPalette("normal_color")
                    slotn.absolutePosAlignX = 0.5
                    slotn.absolutePosAlignY = 0.4
                end
            end
        block:getTopLevelParent():updateLayout()
    end

    for _,v in ipairs(clear) do
        local quickKey = tes3.getQuickKey({slot = v})
        local block = menu:findChild(string.format("%s", v))
        block:destroyChildren()
        local border = block:createThinBorder({id = "icon"})
        local darkness = border:createRect({id = "darkness", color = {0.0, 0.0, 0.0}})
        darkness.autoWidth = true
        darkness.autoHeight = true
        border.autoWidth = true
        border.autoHeight = true
        border.borderAllSides = 0
        border.paddingAllSides = 2
        quickKey:clear()
        local darkness = border:createRect({id = "darkness", color = {0.0, 0.0, 0.0}})
        darkness.autoWidth = true
        darkness.autoHeight = true
        darkness.minWidth = cf.sliderpercent2
        darkness.minHeight = cf.sliderpercent2
        local slotn = border:createLabel{text = tostring(v)}
        slotn.color = tes3ui.getPalette("normal_color")
        slotn.absolutePosAlignX = 0.5
        slotn.absolutePosAlignY = 0.4
    end
    clear = {}
end event.register("keyUp", press)

local function register()
    if not menu then return end
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
end event.register("mouseButtonDown", register)

local function tooltips()

    local convertSchool = {
        [2] = "Destruction",
	    [0] = "Alteration",
	    [3] = "Illusion",
	    [1] = "Conjuration",
	    [5] = "Mysticism",}

    local range = {
        [0] = "Self",
        [1] = "Touch",
        [2] = "Target",}

    if not menu then return end
        for slot = 1, 9 do
            local quickKey = tes3.getQuickKey({slot = slot})
            local block = menu:findChild(string.format("%s", slot))
            block:register(tes3.uiEvent.help, function()
                if quickKey and quickKey.item then
                    tes3ui.createTooltipMenu({ item = quickKey.item, itemData = quickKey.itemData})
                elseif quickKey and quickKey.spell then
                    tes3ui.createTooltipMenu({spell = quickKey.spell})
                end
            end)
        end
end event.register("mouseAxis", tooltips)


local function simulate()
    if state == 1 then
        state = 0
        return
    end
    if menu then
        menu.visible = cf.onOff2
        timer.start({duration = 0.4, type = timer.real, callback = function()
        local block = menu:findChild("Spa_HotQuick")
            if cf.onOff then
            block:destroyChildren()
            else
                menu:destroyChildren()
                block = menu:createRect({id = "Spa_HotQuick", color = {0.0, 0.0, 0.0}})
                block.alpha = 0
                block.autoWidth = true
                block.autoHeight = true
                block.paddingAllSides = -1
            end
        if not seph then
            if cf.dropDown == 0 then
                menu.absolutePosAlignX = 0.5
                menu.absolutePosAlignY = 0.01
            elseif cf.dropDown == 1 then
                menu.absolutePosAlignX = 0.5
                menu.absolutePosAlignY = 0.985
            elseif cf.dropDown == 2 then
                menu.absolutePosAlignX = 0.01
                menu.absolutePosAlignY = 0.5
            elseif cf.dropDown == 3 then
                menu.absolutePosAlignX = 0.99
                menu.absolutePosAlignY = 0.5
            end
        end
            block.autoWidth = true
            block.autoHeight = true
            block.paddingAllSides = -1
            if cf.dropDown <= 1 then
                block.flowDirection = "left_to_right"
            else
                block.flowDirection = "top_to_bottom"
            end
            for slot = 1, 9 do
                local quickKey = tes3.getQuickKey({slot = slot})
                if quickKey and quickKey.item then
                    hope = 0
                    local borde = block:createBlock({id = string.format("%s", slot)})
                    borde.flowDirection = "top_to_bottom"
                    borde.autoWidth = true
                    borde.autoHeight = true
                    borde.paddingAllSides = 0
                    borde.borderAllSides = cf.slider
                    local border = borde:createThinBorder({id = "icon"})
                    border.autoWidth = true
                    border.autoHeight = true
                    border.borderAllSides = 0
                    border.paddingAllSides = 2
                    if tes3.player.object:hasItemEquipped(quickKey.item) and quickKey:getMagic() == quickKey.item and tes3.mobilePlayer.currentEnchantedItem.itemData == quickKey.itemData then
                        border = border:createRect({id = "equipped", color = {0,0,1}})
                        border.autoWidth = true
                        border.autoHeight = true
                        border.paddingAllSides = 1
                        hope = 2
                    elseif tes3.player.object:hasItemEquipped(quickKey.item) then
                        border = border:createRect({id = "equipped", color = tes3ui.getPalette("health_color")})
                        border.autoWidth = true
                        border.autoHeight = true
                        border.paddingAllSides = 1
                        hope = 2
                    end
                    local darkness = border:createRect({id = "darkness", color = {0.0, 0.0, 0.0}})
                    darkness.autoWidth = true
                    darkness.autoHeight = true
                    local count = getCount(quickKey.item)
                    if quickKey.item.enchantment then
                        if quickKey.itemData and quickKey:getMagic() then
                            local label2 = borde:createFillBar({current = quickKey.itemData.charge, max = quickKey.item.enchantment.maxCharge})
                            label2.widget.showText = false
                            label2.width = (cf.sliderpercent2+4)+hope
                            label2.height = (cf.sliderpercent2*3/16)
                        elseif quickKey.itemData then
                            local label2 = borde:createFillBar({current = quickKey.itemData.condition, max = quickKey.item.maxCondition})
                            label2.widget.showText = false
                            label2.width = (cf.sliderpercent2+4)+hope
                            label2.height = (cf.sliderpercent2*3/16)
                        end
                        local texture = darkness:createImage({path = "Textures\\menu_icon_magic_mini.tga"})
                        texture.scaleMode = true
                        texture.width = cf.sliderpercent2
                        texture.height = cf.sliderpercent2
                        local shadowIcon = darkness:createImage({path = "Icons\\" .. quickKey.item.icon})
                        shadowIcon.color = {0.0, 0.0, 0.0}
                        shadowIcon.absolutePosAlignX = 0.8
                        shadowIcon.absolutePosAlignY = 0.8
                        shadowIcon.scaleMode = true
                        shadowIcon.width = cf.sliderpercent2
                        shadowIcon.height = cf.sliderpercent2
                        local Icon = darkness:createImage({path = "Icons\\"..quickKey.item.icon})
                        Icon.absolutePosAlignX = 0.5
                        Icon.absolutePosAlignY = 0.5
                        Icon.scaleMode = true
                        Icon.width = cf.sliderpercent2
                        Icon.height = cf.sliderpercent2
                        local text = border:createLabel{text = tostring(count)}
                        text.absolutePosAlignX = 0.9
                        text.absolutePosAlignY = 0.9
                        text.color = {1,1,1}
                    else
                        if quickKey.itemData then local label2 = borde:createFillBar({current = quickKey.itemData.condition, max = quickKey.item.maxCondition})
                            label2.widget.showText = false
                            label2.width = (cf.sliderpercent2+4)+hope
                            label2.height = (cf.sliderpercent2*3/16) end
                            local Icon = darkness:createImage({path = "Icons\\"..quickKey.item.icon})
                            Icon.scaleMode = true
                            Icon.width = cf.sliderpercent2
                            Icon.height = cf.sliderpercent2
                        local text = border:createLabel{text = tostring(count)}
                        text.color = {1,1,1}
                        text.absolutePosAlignX = 0.9
                        text.absolutePosAlignY = 0.9
                    end
                elseif quickKey and quickKey.spell then
                    hope = 0
                    local borde = block:createBlock({id = string.format("%s", slot)})
                    borde.flowDirection = "top_to_bottom"
                    borde.autoWidth = true
                    borde.autoHeight = true
                    borde.paddingAllSides = 0
                    borde.borderAllSides = cf.slider
                    local border = borde:createThinBorder({id = "icon"})
                    border.autoWidth = true
                    border.autoHeight = true
                    border.borderAllSides = 0
                    border.paddingAllSides = 2
                    if tes3.mobilePlayer.currentSpell == quickKey.spell then
                        border = border:createRect({id = "equipped", color = {0,0,1}})
                        border.autoWidth = true
                        border.autoHeight = true
                        border.paddingAllSides = 1
                        hope = 2
                    end
                    local chance = quickKey.spell:calculateCastChance({checkMagicka = true, caster = tes3.player})
                    local label2 = borde:createFillBar({current = chance, max = 100})
                    --label2.widget.fillColor = tes3ui.getPalette("magic_color")
                    label2.widget.showText = false
                    label2.width = (cf.sliderpercent2+4)+hope
                    label2.height = (cf.sliderpercent2*3/16)
                    local darkness = border:createRect({id = "darkness", color = {0.0, 0.0, 0.0}})
                    darkness.autoWidth = true
                    darkness.autoHeight = true
                    local spellicon = border:createImage({path = "Icons\\"..quickKey.spell.effects[1].object.bigIcon})
                    spellicon.scaleMode = true
                    spellicon.width = cf.sliderpercent2
                    spellicon.height = cf.sliderpercent2
                else
                    local borde = block:createBlock({id = string.format("%s", slot)})
                    borde.flowDirection = "top_to_bottom"
                    borde.autoWidth = true
                    borde.autoHeight = true
                    borde.paddingAllSides = 0
                    borde.borderAllSides = cf.slider
                    local border = borde:createThinBorder():createThinBorder({id = "icon"})
                    local darkness = border:createRect({id = "darkness", color = {0.0, 0.0, 0.0}})
                    darkness.autoWidth = true
                    darkness.autoHeight = true
                    darkness.minWidth = cf.sliderpercent2
                    darkness.minHeight = cf.sliderpercent2
                    border.autoWidth = true
                    border.autoHeight = true
                    border.parent.autoWidth = true
                    border.parent.autoHeight = true
                    border.parent.borderAllSides = 0
                    border.paddingAllSides = 2
                    border.borderAllSides = 0
                    --border:createImage({path = "Icons\\Spammer\\qhicon.dds"})
                    local slotn = border:createLabel{text = tostring(slot)}
                    slotn.color = tes3ui.getPalette("normal_color")
                    slotn.absolutePosAlignX = 0.5
                    slotn.absolutePosAlignY = 0.4
                end
            end
        block:getTopLevelParent():updateLayout()
        end})
    end
end event.register("mouseButtonUp", simulate)

local function visibility()
    local multi = tes3ui.findMenu("MenuMulti")
    if not multi then
        return
    end
    if not menu then
        return
    end
    if hello and tes3.worldController.inputController:isMouseButtonDown(1) then
        hello:destroy()
        hello = nil
    end
    local fill = multi:findChild(tes3ui.registerID("MenuMulti_fillbars_layout"))
    menu.visible = cf.onOff2 and fill.visible
end event.register("enterFrame", visibility, {priority = -1000})


local function loaded(e)
    if not e.newlyCreated then return end
    local parent = e.element:findChild(tes3ui.registerID("PartNonDragMenu_main"))
    menu = parent:createRect({id = "Spa_test", color = {0.0, 0.0, 0.0}})
    menu.alpha = 0
    menu.autoWidth = true
    menu.autoHeight = true
    menu.visible = cf.onOff2
    if cf.dropDown == 0 then
    menu.absolutePosAlignX = 0.5
    menu.absolutePosAlignY = 0.01
    elseif cf.dropDown == 1 then
        menu.absolutePosAlignX = 0.5
    menu.absolutePosAlignY = 0.985
    elseif cf.dropDown == 2 then
    menu.absolutePosAlignX = 0.01
    menu.absolutePosAlignY = 0.5
    elseif cf.dropDown == 3 then
        menu.absolutePosAlignX = 0.99
    menu.absolutePosAlignY = 0.5
    end
local block = menu:createRect({id = "Spa_HotQuick", color = {0.0, 0.0, 0.0}})
    block:destroyChildren()
    block.autoWidth = true
    block.autoHeight = true
    block.alpha = 0
    block.paddingAllSides = -1
    if cf.dropDown <= 1 then
        block.flowDirection = "left_to_right"
    else
        block.flowDirection = "top_to_bottom"
    end
    for slot = 1, 9 do
        local quickKey = tes3.getQuickKey({slot = slot})
        if quickKey and quickKey.item then
            hope = 0
            local borde = block:createBlock({id = string.format("%s", slot)})
            borde.flowDirection = "top_to_bottom"
            borde.autoWidth = true
            borde.autoHeight = true
            borde.paddingAllSides = 0
            borde.borderAllSides = cf.slider
            local border = borde:createThinBorder({id = "icon"})
            border.autoWidth = true
            border.autoHeight = true
            border.paddingAllSides = 2
            border.borderAllSides = 0
            if tes3.player.object:hasItemEquipped(quickKey.item) and quickKey:getMagic() == quickKey.item  and tes3.mobilePlayer.currentEnchantedItem.itemData == quickKey.itemData then
                border = border:createRect({id = "equipped", color = {0,0,1}})
                border.autoWidth = true
                border.autoHeight = true
                border.paddingAllSides = 1
                hope = 2
            elseif tes3.player.object:hasItemEquipped(quickKey.item) then
                border = border:createRect({id = "equipped", color = tes3ui.getPalette("health_color")})
                border.autoWidth = true
                border.autoHeight = true
                border.paddingAllSides = 1
                hope = 2
            end
            local darkness = border:createRect({id = "darkness", color = {0.0, 0.0, 0.0}})
            darkness.autoWidth = true
            darkness.autoHeight = true
            local count = getCount(quickKey.item)
            if quickKey.item.enchantment then
                if quickKey.itemData and quickKey:getMagic() then
                    local label2 = borde:createFillBar({current = quickKey.itemData.charge, max = quickKey.item.enchantment.maxCharge})
                    label2.widget.showText = false
                    label2.width = (cf.sliderpercent2+4)+hope
                    label2.height = (cf.sliderpercent2*3/16)
                elseif quickKey.itemData then local label2 = borde:createFillBar({current = quickKey.itemData.condition, max = quickKey.item.maxCondition})
                    label2.widget.showText = false
                    label2.width = (cf.sliderpercent2+4)+hope
                    label2.height = (cf.sliderpercent2*3/16)
                end
                local texture = darkness:createImage({path = "Textures\\menu_icon_magic_mini.tga"})
                    texture.scaleMode = true
                    texture.width = cf.sliderpercent2
                    texture.height = cf.sliderpercent2
                    local shadowIcon = darkness:createImage({path = "Icons\\" .. quickKey.item.icon})
                    shadowIcon.color = {0.0, 0.0, 0.0}
                    shadowIcon.absolutePosAlignX = 0.8
                    shadowIcon.absolutePosAlignY = 0.8
                    shadowIcon.scaleMode = true
                    shadowIcon.width = cf.sliderpercent2
                    shadowIcon.height = cf.sliderpercent2
                    local Icon = darkness:createImage({path = "Icons\\"..quickKey.item.icon})
                    Icon.absolutePosAlignX = 0.5
                    Icon.absolutePosAlignY = 0.5
                    Icon.scaleMode = true
                    Icon.width = cf.sliderpercent2
                    Icon.height = cf.sliderpercent2
                local text = border:createLabel{text = tostring(count)}
                text.absolutePosAlignX = 0.9
                text.absolutePosAlignY = 0.9
                text.color = {1,1,1}
            else
                if quickKey.itemData then
                    local label2 = borde:createFillBar({current = quickKey.itemData.condition, max = quickKey.item.maxCondition})
                    label2.widget.showText = false
                    label2.width = (cf.sliderpercent2+4)+hope
                    label2.height = (cf.sliderpercent2*3/16) end
                local Icon = darkness:createImage({path = "Icons\\"..quickKey.item.icon})
                Icon.scaleMode = true
                Icon.width = cf.sliderpercent2
                Icon.height = cf.sliderpercent2
                local text = border:createLabel{text = tostring(count)}
                text.color = {1,1,1}
                text.absolutePosAlignX = 0.9
                text.absolutePosAlignY = 0.9
            end
        elseif quickKey and quickKey.spell then
            hope = 0
            local borde = block:createBlock({id = string.format("%s", slot)})
            borde.flowDirection = "top_to_bottom"
            borde.autoWidth = true
            borde.autoHeight = true
            borde.paddingAllSides = 0
            borde.borderAllSides = cf.slider
            local border = borde:createThinBorder({id = "icon"})
            border.autoWidth = true
            border.autoHeight = true
            border.borderAllSides = 0
            border.paddingAllSides = 2
            if tes3.mobilePlayer.currentSpell == quickKey.spell then
                border = border:createRect({id = "equipped", color = {0,0,1}})
                border.autoWidth = true
                border.autoHeight = true
                border.paddingAllSides = 1
                hope = 2
            end
            local chance = quickKey.spell:calculateCastChance({checkMagicka = true, caster = tes3.player})
            local label2 = borde:createFillBar({current = chance, max = 100})
            --label2.widget.fillColor = tes3ui.getPalette("magic_color")
            label2.widget.showText = false
            label2.width = (cf.sliderpercent2+4)+hope
            label2.height = (cf.sliderpercent2*3/16)
            local darkness = border:createRect({id = "darkness", color = {0.0, 0.0, 0.0}})
            darkness.autoWidth = true
            darkness.autoHeight = true
            local spellicon = border:createImage({path = "Icons\\"..quickKey.spell.effects[1].object.bigIcon})
                spellicon.scaleMode = true
                spellicon.width = cf.sliderpercent2
                spellicon.height = cf.sliderpercent2
        else
            local borde = block:createBlock({id = string.format("%s", slot)})
            borde.flowDirection = "top_to_bottom"
            borde.autoWidth = true
            borde.autoHeight = true
            borde.paddingAllSides = 0
            borde.borderAllSides = cf.slider
            local border = borde:createThinBorder():createThinBorder({id = "icon"})
            local darkness = border:createRect({id = "darkness", color = {0.0, 0.0, 0.0}})
            darkness.autoWidth = true
            darkness.autoHeight = true
            darkness.minWidth = cf.sliderpercent2
            darkness.minHeight = cf.sliderpercent2
            border.autoWidth = true
            border.autoHeight = true
            border.parent.autoWidth = true
            border.parent.autoHeight = true
            border.parent.borderAllSides = 0
            border.paddingAllSides = 2
            border.borderAllSides = 0
            --border:createImage({path = "Icons\\Spammer\\qhicon.dds"})
            local slotn = border:createLabel{text = tostring(slot)}
            slotn.color = tes3ui.getPalette("normal_color")
            slotn.absolutePosAlignX = 0.5
            slotn.absolutePosAlignY = 0.4
        end
    end
end event.register(tes3.event.uiActivated, loaded, { filter = "MenuMulti" })


local function registerModConfig()
    local template = mwse.mcm.createTemplate(mod.name)
    template:saveOnClose(mod.name, cf)
    template:register()

    local page = template:createSideBarPage({label="\""..mod.name.."\" Settings"})
    page.sidebar:createInfo{ text = "Welcome to \""..mod.name.."\" Configuration Menu. \n \n \n A mod by Spammer."}
    page.sidebar:createHyperLink{ text = "Spammer's Nexus Profile", url = "https://www.nexusmods.com/users/1cf.slider01391cf.slider8?tab=user+files" }

    local category0 = page:createCategory("Show the Hotbar?")
    category0:createYesNoButton{label = "Yes/No", description = " ", variable = mwse.mcm.createTableVariable{id = "onOff2", table = cf, restartRequired = false, restartRequiredMessage = "You will need to reload a Saved Game to get back the Border."}}

    local category1 = page:createCategory("")
    local elementGroup = category1:createCategory("Select where on the screen will the Hotbar be shown:")

    elementGroup:createDropdown { description = " ",
        options  = {
            { label = "Top", value = 0 },
            { label = "Bottom", value = 1 },
            { label = "Left", value = 2 },
            { label = "Right", value = 3 },
        },
        variable = mwse.mcm:createTableVariable {
            id    = "dropDown",
            table = cf
        }
    }

    local category2 = page:createCategory("Size of the Hotbar:")
    local subcat = category2:createCategory(" ")

    subcat:createSlider{label = "Spacing", description = "[Default: 4]", min = -1, max = 10, step = 1, jump = 1, variable = mwse.mcm.createTableVariable{id = "slider", table = cf}}

    subcat:createSlider{label = "Size", description = "[Default: 32]", min = 0, max = 128, step = 1, jump = 10, variable = mwse.mcm.createTableVariable{id = "sliderpercent2", table = cf}}

end event.register("modConfigReady", registerModConfig)

local function initialized()
    if seph then
        seph:registerElement("Spa_test", "QuickKey Hotbar", nil, nil)
    end
    if tes3.isLuaModActive([[Spammer/QuickKey Outlander]]) then
        cfq = mwse.loadConfig("QuickKey Outlander!")
    end
    print("["..mod.name..", by Spammer] "..mod.ver.." Initialized!")
end event.register("initialized", initialized)

