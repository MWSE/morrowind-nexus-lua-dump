local ui = require("openmw.ui")
local I = require("openmw.interfaces")

local v2 = require("openmw.util").vector2
local util = require("openmw.util")
local cam = require("openmw.interfaces").Camera
local core = require("openmw.core")
local self = require("openmw.self")
local nearby = require("openmw.nearby")
local types = require("openmw.types")
local Camera = require("openmw.camera")
local camera = require("openmw.camera")
local input = require("openmw.input")
local async = require("openmw.async")
local storage = require("openmw.storage")
local iconsize = 40
local iconsizegrow = iconsize + 10
local windowType = { inventory = 1, magic = 2, skills = 3, stats = 4 }
local itemCheck = "ebony_dagger_mehrunes"
local keyBindings = nil
local function getEnchantment(id)
    return core.magic.enchantments[id]
end
local function mouseClick(mouseEvent, data)
    if data.props.selected then
        if mouseEvent.button == 1 then
            I.LMM.doRecall(data.props.index, data.props.iw)
            
        elseif mouseEvent.button == 3 then
            I.LMM.enterEditMode()
        end
    elseif data.props.iw.selectedPosX ~= data.props.index then
        data.props.iw.selectedPosX = data.props.index
        data.props.iw:reDraw()
    end
end
local function boxedTextEditContent(text, callback, textScale, width)
    if textScale == nil then
        textScale = 1
    end
    if width == nil then
        width = 400
    end
    return {
        type = ui.TYPE.Container,
        content = ui.content {
            {
                template = I.MWUI.templates.box,
                props = {
                    anchor = util.vector2(0, -0.5),
                    size = util.vector2(400, 10),
                },
                content = ui.content {
                    {
                        type = ui.TYPE.TextEdit,
                        template = I.MWUI.templates.textEditLine,
                        events = { textChanged = callback },
                        props = {
                            text = text,
                            size = util.vector2(width, 30),
                            textAlignH = 15,
                            textSize = 25,
                            align = ui.ALIGNMENT.Center,
                        }
                    }
                }
            }
        }
    }
end
local function padString(str, length)
    local strLength = string.len(str)

    if strLength >= length then
        return str -- No need to pad if the string is already longer or equal to the desired length
    end

    local padding = length - strLength                   -- Calculate the number of spaces needed
    local paddedString = str .. string.rep(" ", padding) -- Concatenate the string with the required number of spaces

    return paddedString
end
local function setWindowType(iw, type)
    if (type == windowType.inventory) then
        iw.catTypes = { "All", "Weapon", "Apparel", "Magic", "Misc" }
        iw.typeFilter = {
            ["All"] = {},
            ["Weapon"] = { types.Weapon },
            ["Apparel"] = { types.Clothing, types.Armor },
            ["Magic"] = { types.Ingredient, types.Potion },
            ["Misc"] = { types.Apparatus, types.Book, types.Miscellaneous, types.Probe, types.Repair }
        }
        iw.listMode = false
    elseif type == windowType.magic then
        iw.catTypes = { "All", "Alteration", "Conjuration", "Destruction", "Illusion", "Mysticism", "Restoration" }
        iw.listMode = true
    end
    iw.windowType = type
end
local function formatNumber(num)
    local threshold = 1000
    print(num)
    local millionThreshold = 1000000

    if num >= millionThreshold then
        local formattedNum = math.floor(num / millionThreshold)
        return string.format("%dm", formattedNum)
    elseif num >= threshold then
        local formattedNum = math.floor(num / threshold)
        return string.format("%dk", formattedNum)
    else
        return tostring(num)
    end
end
local function FindEnchant(item)
    if (item == nil or item.type == nil or item.type.record(item) == nil or item.type.record(item).enchant == nil or item.type.record(item).enchant == "") then
        return nil
    end
    return item.type.record(item).enchant
end

local function FindEnchantment(item)
    if (item == nil or item.type == nil or item.type.record(item) == nil or item.type.record(item).enchant == nil or item.type.record(item).enchant == "") then
        return nil
    end
    return getEnchantment(item.type.record(item).enchant)
end
local function getAllEnchantments(actorInv, onlyCastable)
    local ret = {}
    for index, value in ipairs(actorInv:getAll()) do
        local ench = FindEnchantment(value)
        if (ench and not onlyCastable) then
            table.insert(ret, { enchantment = ench, item = value })
        elseif ench and onlyCastable and (ench.type == core.magic.ENCHANTMENT_TYPE.CastOnUse or ench.type == core.magic.ENCHANTMENT_TYPE.CastOnce) then
            table.insert(ret, { enchantment = ench, item = value })
        end
    end
    return ret
end
local function getEffectIcon(effect)
    --local strWithoutSpaces = string.gsub(effect.name, "%s", "")
    -- if( effectData[strWithoutSpaces] == nil) then
    --    print(strWithoutSpaces)
    --  end
    --strWithoutSpaces= string.sub(effectData[strWithoutSpaces], 1, -4) .. "dds"
    -- print(strWithoutSpaces)
    return effect.icon
end
local function textContent(text, template, color)
    local tsize = 15
    if not color then
        template = I.MWUI.templates.textNormal
        color = template.props.textColor
    elseif color == "red" then
        template = I.MWUI.templates.textNormal
        color = util.color.rgba(5, 0, 0, 1)
    else
        template = I.MWUI.templates.textHeader
        color = template.props.textColor
        --  tsize = 20
    end

    return {
        type = ui.TYPE.Text,
        template = template,
        props = {
            text = tostring(text),
            textSize = tsize,
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Center,
            textColor = color
        }
    }
end
local lineLength = 60
local function renderListItem(iw, selected, textx, item, diffFont, index)
    local itemIcon = nil
    local resource2

    local text = ""
    if not diffFont then diffFont = false end

    local resources = nil
    if (iw.windowType == windowType.inventory and true == false) then

    elseif iw.windowType == windowType.magic and item then
    elseif item and iw.editMode and selected then
        if iw.context == "overwrite" then
            diffFont = "red"
        elseif selected then
            diffFont = "white"
        end
        if iw.drawLine then
            resources = ui.content {
                textContent(padString(iw.editLine .. "_", lineLength), nil, diffFont)
            }
        else
            resources = ui.content {
                textContent(padString(iw.editLine, lineLength), nil, diffFont)
            }
        end
    elseif item then
        if iw.context == "overwrite" and selected then
            diffFont = "red"
        elseif selected then
            diffFont = "white"
        end
        resources = ui.content {
            textContent(padString(item, lineLength), nil, diffFont)
        }
    else
        if iw.context == "overwrite" and selected then
            diffFont = "red"
        elseif selected then
            diffFont = "white"
        end
        resources = ui.content {
            textContent(padString("", lineLength), nil, diffFont)
        }
    end
    -- resource2 = ui.texture({ path = "icons\\selected.tga" })

    local rowCountX = 1
    if (selected and item) then
        return {
            type = ui.TYPE.Container,
            props = {
                size = util.vector2(iconsize, iconsizegrow * rowCountX),
                index = index,
                autoSize = false,
                selected = true,
                iw = iw,
            },
            events = {
                mousePress = async:callback(mouseClick),
                -- mouseRelease = async:callback(clickMeStop),
                --mouseMove = async:callback(mouseMove)
            },
            content = ui.content {
                {
                    template = I.MWUI.templates.box,
                    props = {
                        size = util.vector2(iconsize, iconsizegrow * rowCountX)
                    },
                    alignment = ui.ALIGNMENT.Center,
                    content = resources
                }
            }
        }
    end
    return {
        type = ui.TYPE.Container,
        props = {
            size = util.vector2(iconsize, iconsizegrow * rowCountX),
            autoSize = false,
            selected = false,
            index = index,
            iw = iw,
        },
        events = {
            mousePress = async:callback(mouseClick),
            -- mouseRelease = async:callback(clickMeStop),
            --   mouseMove = async:callback(mouseMove)
        },
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                alignment = ui.ALIGNMENT.Center,
                content = resources
            }
        }
    }
end
local function generateListItems(iw, spellList, enchantList)
    local ret = {}
    local createListItem = function(strig, iconTable, spell)
        return { name = strig, icon = iconTable, spell = spell }
    end
    if iw.windowType == windowType.magic then
        local spells = types.Actor.spells(self)
        if (spellList ~= nil) then
            spells = spellList

            enchantList = getAllEnchantments(types.Actor.inventory(self), true)
        end
        for index, spell in ipairs(spells) do
            if spell.type == core.magic.SPELL_TYPE.Power or spell.type == core.magic.SPELL_TYPE.Spell then
                local listItem = createListItem(spell.name, getEffectIcon(spell.effects[1].effect), spell)
                table.insert(ret, listItem)
            end
        end
        enchantList = getAllEnchantments(types.Actor.inventory(self), true)
        for index, ench in ipairs(enchantList) do
            local name = ench.item.type.record(ench.item).name
            local listItem = createListItem(name, getEffectIcon(ench.enchantment.effects[1].effect), ench.item)
            table.insert(ret, listItem)
        end
    end
    return ret
end
local function renderGridIcon(item, selected, listMode)
    local itemIcon = nil
    local resource2

    resource2 = ui.texture({ path = "icons\\selected.tga" })
    local magicIcon = nil
    if (FindEnchant(item) and FindEnchant(item) ~= "") then
        magicIcon = ui.texture({ path = "textures\\menu_icon_magic_mini.dds" })
    end
    local text = ""
    if (item) then
        local record = I.ZackUtils.findItemIcon(item)
        if (item.count > 1) then
            text = formatNumber(item.count)
        end
        itemIcon = ui.texture({ path = record })
    end
    if (selected and item) then
        return {
            type = ui.TYPE.Container,
            props = {
                size = util.vector2(iconsize, iconsize)
            },
            content = ui.content {
                {
                    template = I.MWUI.templates.box,
                    alignment = ui.ALIGNMENT.Center,
                    content = ui.content {
                        I.ZackUtilsUI_ci.imageContent(magicIcon),
                        I.ZackUtilsUI_ci.imageContent(itemIcon),
                        I.ZackUtilsUI_ci.imageContent(resource2),
                        I.ZackUtilsUI_ci.textContent(tostring(text))
                    }
                }
            }
        }
    end
    return {
        type = ui.TYPE.Container,
        props = {
            size = util.vector2(iconsize, iconsize)
        },
        content = ui.content {
            {
                template = I.MWUI.templates.padding,
                alignment = ui.ALIGNMENT.Center,
                content = ui.content {
                    I.ZackUtilsUI_ci.imageContent(magicIcon),
                    I.ZackUtilsUI_ci.imageContent(itemIcon),
                    I.ZackUtilsUI_ci.textContent(tostring(text))
                }
            }
        }
    }

    --TODO:Make this not suck
end

local function itemIsEquipped(item, actor)
    --Checks if item record is equipped on the specified actor
    if (actor == nil) then actor = self end
    if (actor.type ~= types.NPC and actor.type ~= types.Creature and actor.type ~=
            types.Player) then
        print("invalid type")
        return false
    end
    for slot = 1, 17 do
        if (types.Actor.equipment(actor, slot)) then
            if (item.id == types.Actor.equipment(actor, slot).id) then
                return true
            end
        end
    end
    return false
end
local function filterItems(iw, itemList, skipItem, actor)
    local key = iw.catTypes[I.ControllerInterface.getCurrentCat()]
    print(key)
    if (key == nil) then
        I.ControllerInterface.setCurrentCat(1)
        key = iw.catTypes[I.ControllerInterface.getCurrentCat()]
    end
    local ret = {}
    if (iw.windowType == windowType.magic) then
        if (key == "All") then
            local ench = getAllEnchantments(types.Actor.inventory(self), true)
            return generateListItems(iw)
        else
            local ench = getAllEnchantments(types.Actor.inventory(self), true)
            for index, en in ipairs(ench) do

            end
            for index, spell in ipairs(types.Actor.spells(self)) do
                local effect = spell.effects[1].effect --types.Actor.spells(self)[22].effects[1].effect
                if (effect.school == core.magic.SCHOOL[key]) then
                    table.insert(ret, spell)
                end
            end
        end
        return generateListItems(iw, ret)
    end
    local filter = iw.typeFilter[key]
    if (skipItem == nil) then
        skipItem = itemCheck
    else
        skipItem = skipItem.recordId
    end
    for index, value in ipairs(itemList) do
        if (value.recordId == itemCheck) then
            core.sendGlobalEvent("clearContainerCheck", value)
        end
    end
    if (key == "All") then
        for index, value in ipairs(itemList) do
            if (value.recordId ~= skipItem and itemIsEquipped(value, actor) and value.count == 1) then
                table.insert(ret, value)
            end
        end
        for index, value in ipairs(itemList) do
            if (value.recordId ~= skipItem and itemIsEquipped(value, actor) == false) then
                table.insert(ret, value)
            end
        end
        return ret
    end
    for index, value in ipairs(itemList) do
        local valid = false
        for k, type in ipairs(filter) do
            if (value.type == type) then
                valid = true
            end
        end
        if (key == "Magic" and valid == false) then
            if (value.type == types.Weapon or value.type == types.Book or value.type == types.Armor or value.type == types.Clothing) then
                if (value.type.record(value).enchant ~= nil and value.type.record(value).enchant ~= "") then
                    valid = true
                end
            end
        end
        if (value.recordId ~= skipItem and valid and itemIsEquipped(value, actor) and value.count == 1) then
            table.insert(ret, value)
        end
    end
    for index, value in ipairs(itemList) do
        local valid = false
        for k, type in ipairs(filter) do
            if (value.type == type) then
                valid = true
            end
        end
        if (key == "Magic" and valid == false) then
            if (value.type == types.Weapon or value.type == types.Book or value.type == types.Armor or value.type == types.Clothing) then
                if (value.type.record(value).enchant ~= nil and value.type.record(value).enchant ~= "") then
                    valid = true
                end
            end
        end
        if (value.recordId ~= skipItem and valid and itemIsEquipped(value, actor) == false) then
            table.insert(ret, value)
        end
    end
    return ret
end
local function renderItemList(iw)
    local itemList = iw.list

    local name = "ItemGrid"

    local counter = 0
    local contents = {}

    for x = 1, iw.rowCountY - 1 do
        local content = {} -- Create a new table for each value of x
        --  for y = 1, iw.rowCountY do
        local index = (x) + iw.scrollOffset

        --print(tostring(getScrollOffset(isPlayer)))
        --print(index)
        if index <= #itemList then
            local item = itemList[index]
            -- if (item.recordId == itemCheck) then
            --     core.sendGlobalEvent("clearContainerCheck", item)
            ----    item = nil
            ---end
            local linetext
            local icon
            if (item == nil) then
                print(index)
                print(#itemList)
                return
            end
            item = item.label
            local itemLayout = nil
            if iw.context == "override" then

            end
            if iw.selectedPosX == x then
                iw.selectedInvItem = item
                itemLayout = renderListItem(iw, true, nil, item, nil, index)
            else
                itemLayout = renderListItem(iw, false, nil, item, nil, index)
            end

            --itemLayout.template = I.MWUI.templates.padding
            table.insert(content, itemLayout)
        else
            if iw.selectedPosX == x and iw.selected then
                iw.selectedInvItem = nil
                local itemLayout = renderListItem(iw, true, "")
                itemLayout.template = I.MWUI.templates.padding
                table.insert(content, itemLayout)
            else
                local itemLayout = renderListItem(iw, false, "")
                itemLayout.template = I.MWUI.templates.padding
                table.insert(content, itemLayout)
            end
        end

        --    end
        table.insert(contents, content)
    end
    local contentinfo = {} -- Create a new table for each value of x
    if iw.editMode then
        local infoitemLayout = renderListItem(iw, false, nil,
            "Type to change the mark name.", true)
        table.insert(contentinfo, infoitemLayout)
        table.insert(contents, contentinfo)
    else
        local selected = iw:getItemAt(iw.selectedPosX, iw.selectedPosY)
        local sindex = 1
        local str = "Available Marks: " ..
            tostring(I.LMM.getMaxSlots() - I.LMM.getMarkDataLength()) ..
            "      " ..
            "Selected Mark: " .. tostring(I.LMM.getSelectedMarkIndex()) .. "/" .. tostring(I.LMM.getMarkDataLength())

        local kb = I.LMM.getKeyBindings()

        local infoitemLayout = renderListItem(iw, false, nil,
            str, true)
        table.insert(contentinfo, infoitemLayout)
        table.insert(contents, contentinfo)
    end

    for _, item in ipairs(itemList) do
        counter = counter + 1
    end
    local table_contents = {} -- Table to hold the generated items
    if (#contents == 0) then
        error("No content items")
    end

    for index, contentx in ipairs(contents) do
        local item = {
            type = ui.TYPE.Flex,
            content = ui.content(contentx),
            props = {
                size = util.vector2(450, iconsize),
                position = v2(0.8, 25 * (index - 1)),
                vertical = true,
                arrange = ui.ALIGNMENT.Start,
                autoSize = false
            },
            external = {
                -- grow = iconsize + 10
            }
        }
        table.insert(table_contents, item)
    end
    return ui.create {
        layer = "Windows",
        template = I.MWUI.templates.boxTransparent,
        events = {
            -- mousePress = async:callback(clickMe),
            -- mouseRelease = async:callback(clickMeStop),
            -- mouseMove = async:callback(clickMeMove)
        },
        props = {
            -- relativePosition = v2(0.65, 0.8),
            anchor = util.vector2(0.5, 0.5),
            size = v2(1, 1),
            relativePosition = v2(iw.posX, iw.posY),
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Center,
            autoSize = false,
            vertical = true,
            name = name,
        },
        content = ui.content(table_contents)
    }
end
local function renderItemGrid(iw)
    local posX = iw.posX
    local posY = iw.posY
    local itemList = iw:filterItems(iw.inventory:getAll(), nil, iw.parentObject)
    local vertical = 80
    local myData = nil
    local name = "ItemGrid"

    local counter = 0
    local contents = {}

    for x = 1, iw.rowCountX do
        local content = {} -- Create a new table for each value of x
        for y = 1, iw.rowCountY do
            local index = (x - 1) * iw.rowCountY + y + iw.scrollOffset

            --print(tostring(getScrollOffset(isPlayer)))
            --print(index)
            if index <= #itemList then
                local item = itemList[index]
                -- if (item.recordId == itemCheck) then
                --     core.sendGlobalEvent("clearContainerCheck", item)
                ----    item = nil
                ---end
                local itemLayout = nil
                if iw.selectedPosX == x and iw.selectedPosY == y and iw.selected then
                    iw.selectedInvItem = item
                    itemLayout = renderGridIcon(item, true)
                else
                    itemLayout = renderGridIcon(item, false)
                end

                if itemIsEquipped(item, iw.parentObject) then
                    itemLayout.template = I.MWUI.templates.box
                    print("equipped")
                else
                    itemLayout.template = I.MWUI.templates.padding
                end
                table.insert(content, itemLayout)
            else
                if iw.selectedPosX == x and iw.selectedPosY == y and iw.selected then
                    iw.selectedInvItem = nil
                    local itemLayout = renderGridIcon(nil, true)
                    itemLayout.template = I.MWUI.templates.padding
                    table.insert(content, itemLayout)
                else
                    local itemLayout = renderGridIcon(nil, false)
                    itemLayout.template = I.MWUI.templates.padding
                    table.insert(content, itemLayout)
                end
            end
        end
        table.insert(contents, content)
    end

    for _, item in ipairs(itemList) do
        counter = counter + 1
    end
    local table_contents = {} -- Table to hold the generated items

    for index, contentx in ipairs(contents) do
        local item = {
            type = ui.TYPE.Flex,
            content = ui.content(contentx),
            props = {
                size = util.vector2(iconsize, iconsize),
                position = v2(50 * (index - 1), 0.8),
                vertical = false,
                arrange = ui.ALIGNMENT.Center,
            },
            external = {
                grow = iconsize + 15
            }
        }
        table.insert(table_contents, item)
    end
    return ui.create {
        layer = "Windows",
        template = I.MWUI.templates.boxTransparent,
        events = {
            -- mousePress = async:callback(clickMe),
            -- mouseRelease = async:callback(clickMeStop),
            -- mouseMove = async:callback(clickMeMove)
        },
        props = {
            -- relativePosition = v2(0.65, 0.8),
            anchor = util.vector2(0.5, 0.5),
            size = v2(iconsizegrow * iw.rowCountX, iconsizegrow * iw.rowCountY),
            relativePosition = v2(iw.posX, iw.posY),
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Center,
            name = name,
        },
        content = ui.content(table_contents)
    }
end
local function getInventory(object)
    --Quick way to get the inventory of an object, regardless of type
    if (object.type == types.NPC or object.type == types.Creature or object.type == types.Player) then
        return types.Actor.inventory(object)
    elseif (object.type == types.Container) then
        return types.Container.content(object)
    end
    return nil --Not any of the above types, so no inv
end
local function createParentUi(content, horizontal, vertical, name, isHorizontal, iw)
    if (isHorizontal == nil) then
        isHorizontal = false
    end
    local ret = {
        layer = "Windows",
        template = I.MWUI.templates.boxTransparent,
        --    type = ui.TYPE.Flex,
        events = {
            --    mousePress = async:callback(clickMe),
            --   mouseRelease = async:callback(clickMeStop),
            --     mouseMove = async:callback(clickMeMove)
        },
        props = {
            -- relativePosition = v2(0.65, 0.8),
            anchor = v2(0.5, 0.5),
            relativePosition = v2(0.5, iw.posY + vertical),
            -- position = v2(horizontal, vertical),
            vertical = not isHorizontal,
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Center,
            name = name
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                content = ui.content(content),
                props = {
                    size = v2(iconsizegrow * iw.rowCountX, 40),
                    horizontal = isHorizontal,
                    align = ui.ALIGNMENT.Center,
                    arrange = ui.ALIGNMENT.Center
                }
            }
        }
    }
    local myData = nil
    --  if (invMode) then
    --     myData = locDataInvMode[name]
    --  else
    --      myData = locData[name]
    --  end


    if (myData ~= nil) then
        ret.props = {
            -- relativePosition = v2(0.65, 0.8),
            position = v2(myData.xpos, myData.ypos),
            vertical = not isHorizontal,
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Center,
            name = name
        }
    end
    return ui.create(ret)
end
local function renderCatWindow(iw)
    local topContent = {}



    local horizontal = 600
    local vertical = 100

    for index, cat in ipairs(iw.catTypes) do
        table.insert(topContent,
            I.ZackUtilsUI_ci.boxedTextContent(cat, iw.catTypes[I.ControllerInterface.getCurrentCat()]))
    end
    return createParentUi(topContent, horizontal, -0.25, "CatChooser", true, iw)
end

local function renderInfoWindow(iw)
    local topContent = {}



    local horizontal = 600
    local vertical = 100

    if (iw.selectedInvItem == nil) then
        return
    end
    if (iw.windowType == windowType.inventory) then
        local record = iw.selectedInvItem.type.record(iw.selectedInvItem)

        table.insert(topContent,
            I.ZackUtilsUI_ci.boxedTextContent(padString(record.name, 15), nil))
        table.insert(topContent,
            I.ZackUtilsUI_ci.boxedTextContent(padString("Value: " .. tostring(record.value), 15), nil))
    elseif iw.windowType == windowType.magic then

    end
    return createParentUi(topContent, horizontal, 0.25, "CatChooser", true, iw)
end
local function createItemWindow(list, posX, posY, keyBindingsx, context)
    keyBindings = keyBindingsx
    local itemWindow = {}
    itemWindow.parentObject = nil
    itemWindow.selected = true
    itemWindow.inventory = nil
    itemWindow.ui = nil
    itemWindow.headerUi = nil
    itemWindow.infoUi = nil
    itemWindow.list = list
    itemWindow.windowType = 0
    itemWindow.context = "normal"
    if context then
        itemWindow.context = context
    end
    itemWindow.listMode = true
    itemWindow.posX = posX
    itemWindow.posY = posY
    itemWindow.rowCountX = 10
    itemWindow.rowCountY = 25
    itemWindow.editMode = false
    itemWindow.drawLine = false
    itemWindow.selectedText = list[1]
    itemWindow.selectedPosX = 1
    itemWindow.filterItems = filterItems
    itemWindow.selectedPosY = 1
    itemWindow.scrollOffset = 0
    itemWindow.drawWindow = function(iw)
        if (iw.listMode) then
            iw.ui = renderItemList(iw)
        else
            iw.ui = renderItemGrid(iw)
        end

        -- iw.headerUi = renderCatWindow(iw)
        --  iw.infoUi = renderInfoWindow(iw)
    end
    itemWindow.fixCursorPos = function(iw)
        local currentItem = iw:getItemAt(iw.selectedPosX, iw.selectedPosY)
        if (currentItem ~= nil) then
            return
        end
        local itemList = iw:filterItems(iw.inventory:getAll(), nil, iw.parentObject)
        if (#itemList == 0) then
            return
        end

        local index = (iw.selectedPosX - 1) * iw.rowCountY + iw.selectedPosY + iw.scrollOffset
        local lastItem = nil
        if (index > #itemList) then
            iw.selectedPosX = 1
            iw.selectedPosY = 1
        end
    end
    itemWindow.setGridSize = function(iw, x, y)
        iw.rowCountX = x
        iw.rowCountY = y
        iw:reDraw()
    end

    itemWindow.reDraw = function(iw)
        iw.ui:destroy()
        if (iw.headerUi) then
            iw.headerUi:destroy()
        end
        if (iw.infoUi) then
            iw.infoUi:destroy()
        end
        if (iw.listMode) then
            iw.ui = renderItemList(iw)
        else
            iw.ui = renderItemGrid(iw)
        end
        if (iw.selected) then
        end
    end
    itemWindow.getItemAt = function(iw, x, y)
        local itemList = iw.list
        if (iw.listMode) then
            local index = (x) + iw.scrollOffset
            if index <= #itemList then
                local item = itemList[index]
                if not item then
                    print("Item is nil")
                end
                return item
            end
            return nil
        end
        local index = (x - 1) * iw.rowCountY + y + iw.scrollOffset
        if index <= #itemList then
            local item = itemList[index]

            return item
        end
        return nil
    end
    itemWindow.setSelectedItem = function(iw, item)
        local itemList = iw:filterItems(iw.inventory:getAll(), nil, iw.parentObject)
        local index = (x - 1) * iw.rowCountY + y + iw.scrollOffset
        if index <= #itemList then
            local item = itemList[index]

            return item
        end
        return nil
    end
    itemWindow.updateSelection = function(iw, x, y)
        --validate the specified position is valid, return if it is or not
    end
    itemWindow.setSelected = function(iw, select)
        iw.selected = select
    end
    itemWindow.destroy = function(iw)
        iw.ui:destroy()
        if (iw.headerUi) then
            iw.headerUi:destroy()
        end
        if (iw.infoUi) then
            iw.infoUi:destroy()
        end
    end
    itemWindow:drawWindow()
    return itemWindow
end
return {
    interfaceName = "LMM_Window",
    interface = {
        version = 1,
        createItemWindow = createItemWindow,

    },
    eventHandlers = {
        sendMessage = sendMessage,
        returnActivators = returnActivators,
        ClickedContainer = ClickedContainer,
        upDateinvWins = upDateinvWins,
        ClickedActor = ClickedActor,
    },
    engineHandlers = {
        onConsoleCommand = onConsoleCommand,
        onFrame = onFrame,
        onActive = onActive,
        onControllerButtonPress = onControllerButtonPress,
        onInputAction = onInputAction,
        onSave = onSave,
        onKeyPress = onKeyPress,
        onLoad = onLoad,
        onControllerButtonRelease = onControllerButtonRelease,
    }
}
