local I = require("openmw.interfaces")
local ambient = require('openmw.ambient')
local async = require("openmw.async")
local core = require("openmw.core")
local self = require("openmw.self")
local ui = require("openmw.ui")
local util = require("openmw.util")
local types = require("openmw.types")
local input = require("openmw.input")
local storage = require('openmw.storage')
local settings = storage.playerSection("SettingsQuickSelect")

local utility = require("scripts.QuickSelect.qs_utility")
local tooltipData = require("scripts.QuickSelect.ci_tooltipgen")
local messageBoxUtil = require("scripts.QuickSelect.messagebox")
local messageBoxOpen = false
local messageBoxTextLines
local messageBoxButtons
local currentButtonSelected = 1
local function redrawMessageBox()
    messageBoxUtil.showMessageBox(nil, messageBoxTextLines, messageBoxButtons, currentButtonSelected)
end
local QuickSelectWindow
local hoveredOverId
local spellMode = false
local columnsAndRows = {}
local selectedCol = 1
local selectedRow = 1
local startOffset = 0
local endOffset = 0  -- New variable for the end of the visible range
local maxCount = 0
local selectedSpellIndex = 1
local scale = 0.9
local preventScroll = false
local tooltip
local lis = {}
local itemMode = false
local selectedItemRow = 1
local selectedItemCol = 1

local function showTooltipForSelectedSlot()
    if tooltip then
        tooltip:destroy()
        tooltip = nil
    end
    local selectedSlot = (selectedRow - 1) * 10 + selectedCol
    local data = I.QuickSelect_Storage.getFavoriteItemData(selectedSlot)
    if data.item then
        local item = types.Actor.inventory(self):find(data.item)
        if item then
            tooltip = utility.drawListMenu(tooltipData.genToolTips(item), utility.itemWindowLocs.BottomCenter, nil, "HUD")
        end
    elseif data.spell or data.enchantId or (data.spellType and data.spellType:lower() == "enchant") then
        if data.spellType and data.spellType:lower() == "spell" then
            local spell = types.Actor.spells(self)[data.spell]
            if spell then
                tooltip = utility.drawListMenu(tooltipData.genToolTips({ spell = spell }), utility.itemWindowLocs.BottomCenter, nil, "HUD")
            end
        elseif data.spellType and data.spellType:lower() == "enchant" then
            local enchant = utility.getEnchantment(data.enchantId)
            if enchant then
                local item = types.Actor.inventory(self):find(data.itemId)
                if item then
                    tooltip = utility.drawListMenu(tooltipData.genToolTips(item), utility.itemWindowLocs.BottomCenter, nil, "HUD")
                end
            end
        elseif data.itemId then
            local item = types.Actor.inventory(self):find(data.itemId)
            if item then
                tooltip = utility.drawListMenu(tooltipData.genToolTips(item), utility.itemWindowLocs.BottomCenter, nil, "HUD")
            end
        end
    end
end

local slotToSave
local savedTextures = {}
local function getTexture(path)
    if not savedTextures[path] and path then
        savedTextures[path] = ui.texture({ path = path })
    end
    return savedTextures[path]
end
    local function updateHighlight(currentSelected, newSelected)
        local content = QuickSelectWindow.layout.content[1].content[3].content[1].content[1].content
        for index, value in ipairs(content) do
            local sdata2 = value.content[1].content[1].props.spellData
            if sdata2 and sdata2.spellIndex == currentSelected then
                value.content[1].content[1].template = I.MWUI.templates.textNormal
                value.content[1].content[1]:update()
                value.template = nil
                value:update()
            elseif sdata2 and sdata2.spellIndex == newSelected then
                value.content[1].content[1].template = I.MWUI.templates.textHeader
                value.content[1].content[1]:update()
                value.template = I.MWUI.templates.boxSolid
                value:update()
            end
        end
        local spellListFlex = QuickSelectWindow.layout.content[1].content[3].content[1].content[1]
        local spellBox = QuickSelectWindow.layout.content[1].content[3]
        local outerFlex = QuickSelectWindow.layout.content[1]
        spellListFlex:update()
        spellBox:update()
        outerFlex:update()
    end

local function mouseMove(mouseEvent, data)
    if tooltip then
        tooltip:destroy()
        tooltip = nil
    end
    if data.data.item then
        tooltip = utility.drawListMenu(tooltipData.genToolTips(data.data.item),
            utility.itemWindowLocs.BottomCenter, nil, "HUD")
        -- ui.showMessage("Mouse moving over icon" .. data.item.recordId)
    elseif data.data.data.spell then
        local spellRecord = core.magic.spells.records[data.data.data.spell]
        tooltip = utility.drawListMenu(tooltipData.genToolTips({ spell = spellRecord }),
            utility.itemWindowLocs.BottomCenter, nil, "HUD")
    end
end
local function mouseClick(mouseEvent, data)
    local id = data.id
    if spellMode and data then
        if data.header then
            if data.header == "powers" then
                powersExpanded = not powersExpanded
            elseif data.header == "spells" then
                spellsExpanded = not spellsExpanded
            elseif data.header == "enchantments" then
                enchantmentsExpanded = not enchantmentsExpanded
            end
            cachedSpellsAndIds = nil
            drawSpellSelect()
            return
        end
    end
    if tooltip then
        tooltip:destroy()
        tooltip = nil
    end
    if data.data then
        if not slotToSave then
            messageBoxTextLines = { "Quick Menu Selection", "W/S or DPad for navigation", "F or X(Pad) to confirm", " " }
            messageBoxButtons = { core.getGMST("sQuickMenu2"), core.getGMST("sQuickMenu3"), core.getGMST("sQuickMenu4"), core.getGMST("sCancel") }
            currentButtonSelected = 1
            messageBoxOpen = true
            messageBoxUtil.showMessageBox(nil, messageBoxTextLines, messageBoxButtons, currentButtonSelected)
            -- ui.showMessage("Mouse moving over icon" .. data.item.recordId)
            if QuickSelectWindow then
                QuickSelectWindow:destroy()
                QuickSelectWindow = nil
            end
            if tooltip then
                tooltip:destroy()
                tooltip = nil
            end
            slotToSave = data.data.num
        else
            if data.data.item then
                I.QuickSelect_Storage.saveStoredItemData(data.data.item.recordId, slotToSave)
            elseif data.data.id then
                if data.data.enchant then
                    I.QuickSelect_Storage.saveStoredEnchantData(data.data.enchant, data.data.id, slotToSave)
                else
                    I.QuickSelect_Storage.saveStoredSpellData(data.data.id, "Spell", slotToSave)
                end
            end
            if QuickSelectWindow then
                QuickSelectWindow:destroy()
                QuickSelectWindow = nil
            end
            if tooltip then
                tooltip:destroy()
                tooltip = nil
            end
            I.UI.setMode()
            slotToSave = nil
        end
    end
end
local function mouseMoveButton(event, data)

    if not QuickSelectWindow.layout.content[1].content[3].content[1].content[1].content then
        return
    end
    local sdata = data.props.spellData

    if tooltip then
        tooltip:destroy()
        tooltip = nil
    end
    if sdata.id and sdata.enchant then
        local item = types.Actor.inventory(self):find(sdata.id)
        tooltip = utility.drawListMenu(tooltipData.genToolTips(item),
            utility.itemWindowLocs.BottomCenter, nil, "HUD")
        -- ui.showMessage("Mouse moving over icon" .. data.item.recordId)
    elseif sdata.id then
        local spellRecord = core.magic.spells.records[sdata.id]
        tooltip = utility.drawListMenu(tooltipData.genToolTips({ spell = spellRecord }),
            utility.itemWindowLocs.BottomCenter, nil, "HUD")
    end
    -- Mouse over only shows tooltip, does not change selection
end
local function renderButton(text)
    local itemTemplate
    itemTemplate = I.MWUI.templates.borders

    return {
        type = ui.TYPE.Container,
        --  events = {},
        template = itemTemplate,
        content = ui.content { utility.renderItemBold(text) },
    }
end
local function getSkillBase(skillID, actor)
    return types.NPC.stats.skills[skillID:lower()](actor).base
end
local function createItemIcon(item, spell, num, isSelected)
    local icon
    local size = utility.iconSize * 1.5
    if isSelected then
        size = size * 1.1
    end
    if item and not spell then
        icon = I.Controller_Icon_QS.getItemIcon(item, nil, isSelected, size)
    else
        return {}
    end
    local template = nil
    if isSelected then
        template = I.MWUI.templates.borders
    end
    local boxedIcon = utility.renderItemBoxed(icon, util.vector2(size, size), template,
        util.vector2(0.5, 0.5),
        { item = item, num = num } ,{
            mouseMove = async:callback(mouseMove),
            mouseClick = async:callback(mouseClick),
        })
    local padding = utility.renderItemBoxed(ui.content { boxedIcon },
        util.vector2(size, size),
        I.MWUI.templates.padding)
    return padding
end
local function getItemRow(inv, selectedIndex, row)
    local items = {}
    local start = (row - 1) * 10 + 1 + startOffset
    local endi = math.min(row * 10 + startOffset, #inv)
    for i = start, endi do
        local item = inv[i]
        table.insert(items, createItemIcon(item, nil, i, i == selectedIndex))
    end
    while #items < 10 do
        table.insert(items, {})
    end
    return items
end
local function createHotbarItem(item, xicon, num, data, isSelected)
    local icon
    local size = utility.iconSize * 1.5
    if isSelected then
        size = size * 1.1
    end
    local iconSize = size * 0.965
    if item and not xicon then
        icon = I.Controller_Icon_QS.getItemIcon(item, nil, isSelected, iconSize)
    elseif xicon then
        icon = I.Controller_Icon_QS.getSpellIcon(xicon, nil, isSelected, iconSize)
    elseif num then
        icon = ui.content {
            {
                type = ui.TYPE.Text,
                template = I.MWUI.templates.textNormal,
                props = {
                    text = tostring(num),
                    textSize = 20 * scale * (isSelected and 1.1 or 1),
                    relativePosition = util.vector2(0.5, 0.5),
                    anchor = util.vector2(0.5, 0.5),
                    arrange = ui.ALIGNMENT.Center,
                    align = ui.ALIGNMENT.Center,
                },
                item = item,
                num = num,
                events = {
                    --          mouseMove = async:callback(mouseMove),
                },
            }
        }
    end
    local template = nil
    if isSelected then
        template = I.MWUI.templates.boxSolid
    end
    local boxedIcon = utility.renderItemBoxed(icon, util.vector2(size, size), template,
        util.vector2(0.5, 0.5),
        { item = item, num = num, data = data }, {
            mouseMove = async:callback(mouseMove),
            mouseClick = async:callback(mouseClick),
        })
    local padding = utility.renderItemBoxed(ui.content { boxedIcon }, util.vector2(utility.iconSize * 2, utility.iconSize * 2),
        I.MWUI.templates.padding)
    return padding
end
local function getHotbarItems(selectedSlot)
    local items = {}
    local inv = types.Actor.inventory(self):getAll()
    local count = num + 10
    while num < count do
        local data = I.QuickSelect_Storage.getFavoriteItemData(num)
        local item
        local effect
        local icon
        if data.item then
            item = types.Actor.inventory(self):find(data.item)
        elseif data.spell or data.enchantId or (data.spellType and data.spellType:lower() == "enchant") then
            if data.spellType:lower() == "spell" then
                local spell = types.Actor.spells(self)[data.spell]
                if spell then
                    effect = spell.effects[1]
                    icon = effect.effect.icon
                end
            elseif data.spellType:lower() == "enchant" then
                local enchant = utility.getEnchantment(data.enchantId)
                if enchant then
                    effect = enchant.effects[1]
                    icon = effect.effect.icon
                end
                item = types.Actor.inventory(self):find(data.itemId)
            elseif data.itemId then
                item = types.Actor.inventory(self):find(data.itemId)
            end
        end
        table.insert(items, createHotbarItem(item, icon, num, data, num == selectedSlot))
        num = num + 1
    end
    return items
end
local function buildInv()
    local allInv = types.Actor.inventory(self):getAll()
    local inv = {}
    for _, item in ipairs(allInv) do
        if item.type ~= types.Miscellaneous and item.type ~= types.Book then
            -- Exclude onCast enchanted rings and amulets
            local exclude = false

            if item.type and types and types.Clothing and types.Clothing.objectIsInstance(item) then
                local ench = utility.FindEnchantment(item)
                if ench and ench.type == core.magic.ENCHANTMENT_TYPE.CastOnUse then
                    exclude = true
                end
            end
            if not exclude then
                table.insert(inv, item)
            end
        end
    end
    -- Sort by type order: 1) weapons 2) armors 3) clothing 4) potions 5) ingredients 6) apparatus 7) repair items 8) lockpick 9) probe 10) light
    table.sort(inv, function(a, b)
        local aOrder = 99
        local bOrder = 99
        if types then
            local aType = a.type
            local bType = b.type
                        if aType == types.Weapon then aOrder = 1
                            elseif aType == types.Armor then aOrder = 2
                            elseif aType == types.Clothing then aOrder = 3
                            elseif aType == types.Potion then aOrder = 4
                            elseif aType == types.Ingredient then aOrder = 5
                            elseif aType == types.Apparatus then aOrder = 6
                            elseif aType == types.RepairItem then aOrder = 7
                            elseif aType == types.Lockpick then aOrder = 8
                            elseif aType == types.Probe then aOrder = 9
                            elseif aType == types.Light then aOrder = 10
            
            end
            if bType == types.Weapon then bOrder = 1
                            elseif bType == types.Armor then bOrder = 2
                            elseif bType == types.Clothing then bOrder = 3
                            elseif bType == types.Potion then bOrder = 4
                            elseif bType == types.Ingredient then bOrder = 5
                            elseif bType == types.Apparatus then bOrder = 6
                            elseif bType == types.RepairItem then bOrder = 7
                            elseif bType == types.Lockpick then bOrder = 8
                            elseif bType == types.Probe then bOrder = 9
                            elseif bType == types.Light then bOrder = 10
            end
        end
        if aOrder ~= bOrder then
            return aOrder < bOrder
        else
            local aRec = nil
            pcall(function() aRec = a.type.record(a) end)
            local bRec = nil
            pcall(function() bRec = b.type.record(b) end)
            local aName = (aRec and aRec.name) or ""
            local bName = (bRec and bRec.name) or ""
            return aName < bName
        end
    end)
    return inv
end
local function drawItemSelect()
    itemMode = true
    spellMode = false
    if QuickSelectWindow then
        QuickSelectWindow:destroy()
    end
    local xContent = {}
    local content  = {}
    -- Build inv
    local inv = buildInv()
    maxCount = #inv
    local numRows = math.min(6, math.ceil(maxCount / 10))
    selectedItemRow = math.min(selectedItemRow, numRows)
    selectedItemCol = math.min(selectedItemCol, 10)
    local selectedIndex = (selectedItemRow - 1) * 10 + selectedItemCol + startOffset
    --Draw search menu

    table.insert(content, utility.renderItemBold("Quick Select Item Menu", nil, nil, true))
    table.insert(content, utility.renderItemBold("W/S/A/D or DPad for navigation || Q/E or L1/R1 to scroll", nil, nil, true))
    table.insert(content, utility.renderItemBold("F or X(Pad) to select || You can also scroll with mouse", nil, nil, true))


    for i = 1, numRows do
        table.insert(content,
            utility.renderItemBoxed(utility.flexedItems(getItemRow(inv, selectedIndex, i), true), utility.scaledVector2(620, 100),
                I.MWUI.templates.padding,
                util.vector2(0.5, 0.5)))
    end

    --rcontent = flexedItems(content,false)
    --   table.insert(content,flexedItems(lis, true))
    -- table.insert(content, imageContent(resource, size))
    content = ui.content(content)
    QuickSelectWindow = ui.create {
        layer = "Windows",
        template = I.MWUI.templates.boxTransparentThick
        ,
        props = {
            anchor = util.vector2(0.5, 0.5),
            relativePosition = util.vector2(0.5, 0.35),
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Center,
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                content = content,
                props = {
                    horizontal = false,
                    align = ui.ALIGNMENT.Center,
                    arrange = ui.ALIGNMENT.Center,
                    --    size = util.vector2(0, 0),
                }
            }
        }
    }
end
local function getAllEnchantments(actorInv, onlyCastable)
    local ret = {}
    for index, value in ipairs(actorInv:getAll()) do
        local ench = utility.FindEnchantment(value)
        if (ench and not onlyCastable) then
            table.insert(ret, { enchantment = ench, item = value })
        elseif ench and onlyCastable and (ench.type == core.magic.ENCHANTMENT_TYPE.CastOnUse or ench.type == core.magic.ENCHANTMENT_TYPE.CastOnce) then
            table.insert(ret, { enchantment = ench, item = value })
        end
    end
    return ret
end
local function compareNames(a, b)
    return a.name < b.name
end

-- Caches for spell/enchant list and rendered content (added for FPS optimization)
local cachedSpellsAndIds = nil
local cachedXContent = nil
local lastSpellHash = 0  -- Simple change detection (count of spells/enchants)

local function drawSpellSelect()
    itemMode = false
    spellMode = true
    if QuickSelectWindow then
        QuickSelectWindow:destroy()  -- Still destroy, but internal rebuilding is lighter
    end
    local xContent = {}
    local content  = {}
    num = 1

    -- Lightweight change detection (compute a simple hash/count)
    local currentSpellHash = #types.Actor.spells(self) + #types.Actor.inventory(self):getAll()  -- Quick API calls, no full iteration

    if cachedSpellsAndIds == nil or currentSpellHash ~= lastSpellHash then
        -- Rebuild spellsAndIds only if data changed (e.g., new spell learned)
        cachedSpellsAndIds = {}
        local spellList = {}
        local powerList = {}

        -- Powers section
        table.insert(cachedSpellsAndIds, {name = "Powers", type = "" ,bold = true, header = "powers"})
        if powersExpanded then
            for index, spell in ipairs(types.Actor.spells(self)) do
                if spell.type == core.magic.SPELL_TYPE.Power then
                    table.insert(powerList, { id = spell.id, name = spell.name, type = "Power" })
                end
            end
            table.sort(powerList, compareNames)
            for index, value in ipairs(powerList) do
                table.insert(cachedSpellsAndIds, value)
            end
        end

        -- Spells section
        table.insert(cachedSpellsAndIds, {name = "Spells", type = "" ,bold = true, header = "spells"})
        if spellsExpanded then
            for index, spell in ipairs(types.Actor.spells(self)) do
                if spell.type == core.magic.SPELL_TYPE.Spell then
                    table.insert(spellList, { id = spell.id, name = spell.name, type = "Spell" })
                end
            end
            table.sort(spellList, compareNames)
            for index, value in ipairs(spellList) do
                table.insert(cachedSpellsAndIds, value)
            end
        end

        -- Enchantments section
        local enchL = getAllEnchantments(types.Actor.inventory(self), true)
        table.insert(cachedSpellsAndIds, {name = "Enchantments", type = "" ,bold = true, header = "enchantments"})
        if enchantmentsExpanded then
            local enchantList = {}
            for index, ench in ipairs(enchL) do
                table.insert(enchantList, { id = ench.item.recordId, name = ench.item.type.record(ench.item).name, type = "Enchant", enchant = ench.item.type.record(ench.item).enchant })
            end
            table.sort(enchantList, compareNames)
            for index, value in ipairs(enchantList) do
                table.insert(cachedSpellsAndIds, value)
            end
        end

        -- Add spellIndex to each spellData
        for i, spellData in ipairs(cachedSpellsAndIds) do
            spellData.spellIndex = i
        end

        maxCount = #cachedSpellsAndIds
        selectedSpellIndex = math.min(selectedSpellIndex, maxCount)
        lastSpellHash = currentSpellHash  -- Update hash
    end

    -- Calculate endOffset and clamp startOffset to prevent overscrolling
    local visibleCount = 21  -- Max items visible at once
    endOffset = startOffset + 20  -- End offset for the last visible item (20 ahead for 21 total)
    startOffset = math.max(0, math.min(startOffset, math.max(0, maxCount - visibleCount)))  -- Clamp to prevent empty space
    endOffset = startOffset + 20  -- Recalculate after clamping

    -- Ensure startOffset keeps selectedSpellIndex visible (unless prevented)
    if not preventScroll then
        if selectedSpellIndex < startOffset + 1 then
            startOffset = selectedSpellIndex - 1
        elseif selectedSpellIndex > startOffset + visibleCount then
            startOffset = selectedSpellIndex - visibleCount
        end
    end

        -- Render only visible items based on startOffset and endOffset
        cachedXContent = {}  -- Rebuild visible portion only
        for i = startOffset + 1, math.min(endOffset + 1, maxCount) do  -- Covers startOffset+1 to startOffset+21
            local spellData = cachedSpellsAndIds[i]
            if spellData then
                local isSelected = (i == selectedSpellIndex)
                table.insert(cachedXContent, utility.renderItemBold(spellData.name, nil, nil, nil, true, spellData, {
                    mouseMove = async:callback(mouseMoveButton),
                    mouseClick = async:callback(mouseClick),
                    horizontalAlignment = ui.ALIGNMENT.Center
                }, isSelected))
            end
        end

    -- Rest of your code (headers, UI creation) remains the same, but use cachedXContent
    table.insert(content, utility.renderItemBold("Quick Select Spell Menu", nil, nil, true))
    table.insert(content, utility.renderItemBold("W/S or DPad Up/Down to choose spell", nil, nil, true))
    table.insert(content, utility.renderItemBold("A/D or L1/R1 to scroll the list", nil, nil, true))
    table.insert(content, utility.renderItemBold("F or X(Pad) to add the spell", nil, nil, true))
    table.insert(content,
        utility.renderItemBoxed(utility.flexedItems(cachedXContent, false), utility.scaledVector2(350, 630), I.MWUI.templates.boxTransparent,
            util.vector2(0.5, 0.5)))
    content = ui.content(content)
    QuickSelectWindow = ui.create {
        layer = "Windows",
        template = I.MWUI.templates.boxTransparentThick
        ,
        props = {
            anchor = util.vector2(0.5, 0.5),
            relativePosition = util.vector2(0.5, 0.39),
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Center,
        },
        content = ui.content {
                        {
                type = ui.TYPE.Flex,
                content = content,
                props = {
                    horizontal = false,
                    align = ui.ALIGNMENT.Center,
                    arrange = ui.ALIGNMENT.Center,
                    --    size = util.vector2(0, 0),
                }
            }
        }
    }
end
local function drawQuickSelect()
    itemMode = false
    spellMode = false
    if QuickSelectWindow then
        QuickSelectWindow:destroy()
    end
    local xContent = {}
    local content  = {}
    num            = 1
    --local trainerRow = utility.renderItemBoxed({}, util.vector2((160 * scale) * 7, 400 * scale),
    ---    I.MWUI.templates.padding)

    local selectedSlot = (selectedRow - 1) * 10 + selectedCol
    table.insert(content, utility.renderItemBold("Quick Select Ultimate", nil, nil, true))
    table.insert(content, utility.renderItemBold("W/S/A/D or DPad for navigation || F or X(Pad) or Mouse1 to select" , nil, nil, true))

    table.insert(content,
        utility.renderItemBoxed(utility.flexedItems(getHotbarItems(selectedSlot), true), utility.scaledVector2(800, 100),
            I.MWUI.templates.padding,
            util.vector2(0.5, 0.5)))
    table.insert(content,
        utility.renderItemBoxed(utility.flexedItems(getHotbarItems(selectedSlot), true), utility.scaledVector2(800, 100),
            I.MWUI.templates.padding,
            util.vector2(0.5, 0.5)))
    table.insert(content,
        utility.renderItemBoxed(utility.flexedItems(getHotbarItems(selectedSlot), true), utility.scaledVector2(800, 100),
            I.MWUI.templates.padding,
            util.vector2(0.5, 0.5)))

    content = ui.content(content)
    QuickSelectWindow = ui.create {
        layer = "Windows",
        template = I.MWUI.templates.boxTransparentThick
        ,
        props = {
            anchor = util.vector2(0.5, 0.5),
            relativePosition = util.vector2(0.5, 0.5),
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Center,
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                content = content,
                props = {
                    horizontal = false,
                    align = ui.ALIGNMENT.Center,
                    arrange = ui.ALIGNMENT.Center,
                    --    size = util.vector2(0, 0),
                }
            }
        }
    }
end
local function openQuickSelect()
    I.UI.setMode("LevelUp", { windows = { I.UI.WINDOW.QuickKeys } })
    drawQuickSelect()
end

local function UiModeChanged(data)
    if not data.newMode then
        if QuickSelectWindow then
            QuickSelectWindow:destroy()
            QuickSelectWindow = nil
        end
        if tooltip then
            tooltip:destroy()
            tooltip = nil
        end
        -- Reset spell section states
        powersExpanded = false
        spellsExpanded = false
        enchantmentsExpanded = false
        spellMode = false
        itemMode = false
        I.QuickSelect_Hotbar.drawHotbar()
        slotToSave = nil
    end
end

local function onKeyPress(key)
    if messageBoxOpen then
        if key.code == input.KEY.W then
            currentButtonSelected = math.max(1, currentButtonSelected - 1)
            redrawMessageBox()
            return
        elseif key.code == input.KEY.S then
            currentButtonSelected = math.min(#messageBoxButtons, currentButtonSelected + 1)
            redrawMessageBox()
            return
        elseif key.code == input.KEY.F then
            self:sendEvent("ButtonClicked", {text = messageBoxButtons[currentButtonSelected]})
            messageBoxUtil.destroyMessageBox()
            messageBoxOpen = false
            return
        elseif key.code == input.KEY.Escape then
            self:sendEvent("ButtonClicked", {text = core.getGMST("sCancel")})
            messageBoxUtil.destroyMessageBox()
            messageBoxOpen = false
            return
        end
        return true  -- Consume unhandled keys when messageBox is open
    end
    if not QuickSelectWindow then return end

    if spellMode and QuickSelectWindow then
        if  key.code == input.KEY.W then
            selectedSpellIndex = math.max(1, selectedSpellIndex - 1)
            startOffset = math.max(0, math.min(startOffset, selectedSpellIndex - 1))
            endOffset = startOffset + 20
            drawSpellSelect()
            -- Show tooltip for selected spell
            local spellData = cachedSpellsAndIds[selectedSpellIndex]
            if tooltip then
                tooltip:destroy()
                tooltip = nil
            end
            if spellData and spellData.id then
                if spellData.enchant then
                    local item = types.Actor.inventory(self):find(spellData.id)
                    tooltip = utility.drawListMenu(tooltipData.genToolTips(item), utility.itemWindowLocs.BottomCenter, nil, "HUD")
                else
                    local spellRecord = core.magic.spells.records[spellData.id]
                    tooltip = utility.drawListMenu(tooltipData.genToolTips({ spell = spellRecord }), utility.itemWindowLocs.BottomCenter, nil, "HUD")
                end
            end
            return
        elseif key.code == input.KEY.S then
            selectedSpellIndex = math.min(maxCount, selectedSpellIndex + 1)
            startOffset = math.max(0, math.max(startOffset, selectedSpellIndex - 20))
            endOffset = startOffset + 20
            drawSpellSelect()
            -- Show tooltip for selected spell
            local spellData = cachedSpellsAndIds[selectedSpellIndex]
            if tooltip then
                tooltip:destroy()
                tooltip = nil
            end
            if spellData and spellData.id then
                if spellData.enchant then
                    local item = types.Actor.inventory(self):find(spellData.id)
                    tooltip = utility.drawListMenu(tooltipData.genToolTips(item), utility.itemWindowLocs.BottomCenter, nil, "HUD")
                else
                    local spellRecord = core.magic.spells.records[spellData.id]
                    tooltip = utility.drawListMenu(tooltipData.genToolTips({ spell = spellRecord }), utility.itemWindowLocs.BottomCenter, nil, "HUD")
                end
            end
            return
        elseif key.code == input.KEY.A then
            -- Scroll list up by 21
            startOffset = startOffset - 21
            local visibleCount = 21
            startOffset = math.max(0, math.min(startOffset, math.max(0, maxCount - visibleCount)))
            endOffset = startOffset + 20
            selectedSpellIndex = startOffset + 1
            selectedSpellIndex = math.min(selectedSpellIndex, maxCount)
            drawSpellSelect()
            return
        elseif key.code == input.KEY.D then
            -- Scroll list down by 21
            startOffset = startOffset + 21
            local visibleCount = 21
            startOffset = math.max(0, math.min(startOffset, math.max(0, maxCount - visibleCount)))
            endOffset = startOffset + 20
            selectedSpellIndex = startOffset + 1
            selectedSpellIndex = math.min(selectedSpellIndex, maxCount)
            drawSpellSelect()
            return
        elseif key.code == input.KEY.F then
            local spellData = cachedSpellsAndIds[selectedSpellIndex]
            if spellData and spellData.header then
                if spellData.header == "powers" then
                    powersExpanded = not powersExpanded
                elseif spellData.header == "spells" then
                    spellsExpanded = not spellsExpanded
                elseif spellData.header == "enchantments" then
                    enchantmentsExpanded = not enchantmentsExpanded
                end
                cachedSpellsAndIds = nil
                drawSpellSelect()
                return
            else
                -- Save selected spell
                if spellData and spellData.id then
                    if spellData.enchant then
                        I.QuickSelect_Storage.saveStoredEnchantData(spellData.enchant, spellData.id, slotToSave)
                    else
                        I.QuickSelect_Storage.saveStoredSpellData(spellData.id, "Spell", slotToSave)
                    end
                    I.UI.setMode()
                    if QuickSelectWindow then
                        QuickSelectWindow:destroy()
                        QuickSelectWindow = nil
                    end
                    if tooltip then
                        tooltip:destroy()
                        tooltip = nil
                    end
                    slotToSave = nil
                end
                return
            end
        end
    end

    if itemMode then
        if key.code == input.KEY.W then
            if selectedItemRow > 1 then
                selectedItemRow = selectedItemRow - 1
            else
                if startOffset > 0 then
                    startOffset = startOffset - 10
                end
            end
            drawItemSelect()
            -- Update tooltip for selected item
            if tooltip then
                tooltip:destroy()
                tooltip = nil
            end
            local inv = buildInv()
            local index = (selectedItemRow - 1) * 10 + selectedItemCol + startOffset
            if inv[index] then
                tooltip = utility.drawListMenu(tooltipData.genToolTips(inv[index]), utility.itemWindowLocs.BottomCenter, nil, "HUD")
            end
            return
        elseif key.code == input.KEY.S then
            local visibleRows = math.min(6, math.ceil((maxCount - startOffset) / 10))
            if selectedItemRow < visibleRows then
                selectedItemRow = selectedItemRow + 1
            else
                if startOffset + 60 < maxCount then
                    startOffset = startOffset + 10
                end
            end
            drawItemSelect()
            -- Update tooltip for selected item
            if tooltip then
                tooltip:destroy()
                tooltip = nil
            end
            local inv = buildInv()
            local index = (selectedItemRow - 1) * 10 + selectedItemCol + startOffset
            if inv[index] then
                tooltip = utility.drawListMenu(tooltipData.genToolTips(inv[index]), utility.itemWindowLocs.BottomCenter, nil, "HUD")
            end
            return
        elseif key.code == input.KEY.A then
            selectedItemCol = math.max(1, selectedItemCol - 1)
            drawItemSelect()
            -- Update tooltip for selected item
            if tooltip then
                tooltip:destroy()
                tooltip = nil
            end
            local inv = buildInv()
            local index = (selectedItemRow - 1) * 10 + selectedItemCol + startOffset
            if inv[index] then
                tooltip = utility.drawListMenu(tooltipData.genToolTips(inv[index]), utility.itemWindowLocs.BottomCenter, nil, "HUD")
            end
            return
        elseif key.code == input.KEY.D then
            selectedItemCol = math.min(10, selectedItemCol + 1)
            drawItemSelect()
            -- Update tooltip for selected item
            if tooltip then
                tooltip:destroy()
                tooltip = nil
            end
            local inv = buildInv()
            local index = (selectedItemRow - 1) * 10 + selectedItemCol + startOffset
            if inv[index] then
                tooltip = utility.drawListMenu(tooltipData.genToolTips(inv[index]), utility.itemWindowLocs.BottomCenter, nil, "HUD")
            end
            return
        elseif key.code == input.KEY.Q then
            local targetRow = selectedItemRow - 6
            if targetRow < 1 then
                local scrollRows = 1 - targetRow
                startOffset = math.max(0, startOffset - scrollRows * 10)
                startOffset = math.max(0, math.min(startOffset, math.max(0, maxCount - 60)))
                selectedItemRow = 1
            else
                selectedItemRow = targetRow
            end
            startOffset = math.max(0, math.min(startOffset, math.max(0, maxCount - 60)))
            selectedItemRow = math.max(1, math.min(selectedItemRow, math.min(6, math.ceil((maxCount - startOffset) / 10))))
            drawItemSelect()
            -- Update tooltip for selected item
            if tooltip then
                tooltip:destroy()
                tooltip = nil
            end
            local inv = buildInv()
            local index = (selectedItemRow - 1) * 10 + selectedItemCol + startOffset
            if inv[index] then
                tooltip = utility.drawListMenu(tooltipData.genToolTips(inv[index]), utility.itemWindowLocs.BottomCenter, nil, "HUD")
            end
            return
        elseif key.code == input.KEY.E then
            local targetRow = selectedItemRow + 6
            local visibleRows = math.min(6, math.ceil((maxCount - startOffset) / 10))
            if targetRow > visibleRows then
                local scrollRows = targetRow - visibleRows
                startOffset = startOffset + scrollRows * 10
                startOffset = math.max(0, math.min(startOffset, math.max(0, maxCount - 60)))
                selectedItemRow = math.min(6, math.ceil((maxCount - startOffset) / 10))
            else
                selectedItemRow = targetRow
            end
            startOffset = math.max(0, math.min(startOffset, math.max(0, maxCount - 60)))
            selectedItemRow = math.max(1, math.min(selectedItemRow, math.min(6, math.ceil((maxCount - startOffset) / 10))))
            drawItemSelect()
            -- Update tooltip for selected item
            if tooltip then
                tooltip:destroy()
                tooltip = nil
            end
            local inv = buildInv()
            local index = (selectedItemRow - 1) * 10 + selectedItemCol + startOffset
            if inv[index] then
                tooltip = utility.drawListMenu(tooltipData.genToolTips(inv[index]), utility.itemWindowLocs.BottomCenter, nil, "HUD")
            end
            return
        elseif key.code == input.KEY.F then
            local index = (selectedItemRow - 1) * 10 + selectedItemCol + startOffset
            local inv = buildInv()
            if inv[index] then
                I.QuickSelect_Storage.saveStoredItemData(inv[index].recordId, slotToSave)
                I.UI.setMode()
                if QuickSelectWindow then
                    QuickSelectWindow:destroy()
                    QuickSelectWindow = nil
                end
                if tooltip then
                    tooltip:destroy()
                    tooltip = nil
                end
                slotToSave = nil
            end
            return
        end
    end

    if not spellMode and not itemMode then
        -- Keyboard navigation in hotbar mode
        if key.code == input.KEY.W then
            selectedRow = math.max(1, selectedRow - 1)
            drawQuickSelect()
            showTooltipForSelectedSlot()
            return
        elseif key.code == input.KEY.S then
            selectedRow = math.min(3, selectedRow + 1)
            drawQuickSelect()
            showTooltipForSelectedSlot()
            return
        elseif key.code == input.KEY.A then
            selectedCol = math.max(1, selectedCol - 1)
            drawQuickSelect()
            showTooltipForSelectedSlot()
            return
        elseif key.code == input.KEY.D then
            selectedCol = math.min(10, selectedCol + 1)
            drawQuickSelect()
            showTooltipForSelectedSlot()
            return
        elseif key.code == input.KEY.F then
            local slot = (selectedRow - 1) * 10 + selectedCol
            slotToSave = slot
            messageBoxTextLines = { "Quick Menu Selection", "W/S or DPad for navigation", "F or X(Pad) to confirm", " " }
            messageBoxButtons = { core.getGMST("sQuickMenu2"), core.getGMST("sQuickMenu3"), core.getGMST("sQuickMenu4"), core.getGMST("sCancel") }
            currentButtonSelected = 1
            messageBoxOpen = true
            messageBoxUtil.showMessageBox(nil, messageBoxTextLines, messageBoxButtons, currentButtonSelected)
            if QuickSelectWindow then
                QuickSelectWindow:destroy()
                QuickSelectWindow = nil
            end
            if tooltip then
                tooltip:destroy()
                tooltip = nil
            end
            return
        end
        return true  -- Consume unhandled keys in hotbar mode
    end
    if spellMode or itemMode then return true end
end
local function onControllerButtonPress(id)
    if messageBoxOpen then
        if id == input.CONTROLLER_BUTTON.DPadUp then
            if not settings:get("enableGamepadControls") then return end
            currentButtonSelected = math.max(1, currentButtonSelected - 1)
            redrawMessageBox()
            return
        elseif id == input.CONTROLLER_BUTTON.DPadDown then
            if not settings:get("enableGamepadControls") then return end
            currentButtonSelected = math.min(#messageBoxButtons, currentButtonSelected + 1)
            redrawMessageBox()
            return
        elseif id == input.CONTROLLER_BUTTON.A then
            if not settings:get("enableGamepadControls") then return end
            self:sendEvent("ButtonClicked", {text = messageBoxButtons[currentButtonSelected]})
            messageBoxUtil.destroyMessageBox()
            messageBoxOpen = false
            return
        end
        return true  -- Consume unhandled controller buttons when messageBox is open
    end
    if not QuickSelectWindow then return end

    if spellMode and QuickSelectWindow then
        if id == input.CONTROLLER_BUTTON.DPadUp then
            if not settings:get("enableGamepadControls") then return end
            selectedSpellIndex = math.max(1, selectedSpellIndex - 1)
            startOffset = math.max(0, math.min(startOffset, selectedSpellIndex - 1))
            endOffset = startOffset + 20
            drawSpellSelect()
            -- Show tooltip for selected spell
            local spellData = cachedSpellsAndIds[selectedSpellIndex]
            if tooltip then
                tooltip:destroy()
                tooltip = nil
            end
            if spellData and spellData.id then
                if spellData.enchant then
                    local item = types.Actor.inventory(self):find(spellData.id)
                    tooltip = utility.drawListMenu(tooltipData.genToolTips(item), utility.itemWindowLocs.BottomCenter, nil, "HUD")
                else
                    local spellRecord = core.magic.spells.records[spellData.id]
                    tooltip = utility.drawListMenu(tooltipData.genToolTips({ spell = spellRecord }), utility.itemWindowLocs.BottomCenter, nil, "HUD")
                end
            end
            return
        elseif id == input.CONTROLLER_BUTTON.DPadDown then
            if not settings:get("enableGamepadControls") then return end
            selectedSpellIndex = math.min(maxCount, selectedSpellIndex + 1)
            startOffset = math.max(0, math.max(startOffset, selectedSpellIndex - 20))
            endOffset = startOffset + 20
            drawSpellSelect()
            -- Show tooltip for selected spell
            local spellData = cachedSpellsAndIds[selectedSpellIndex]
            if tooltip then
                tooltip:destroy()
                tooltip = nil
            end
            if spellData and spellData.id then
                if spellData.enchant then
                    local item = types.Actor.inventory(self):find(spellData.id)
                    tooltip = utility.drawListMenu(tooltipData.genToolTips(item), utility.itemWindowLocs.BottomCenter, nil, "HUD")
                else
                    local spellRecord = core.magic.spells.records[spellData.id]
                    tooltip = utility.drawListMenu(tooltipData.genToolTips({ spell = spellRecord }), utility.itemWindowLocs.BottomCenter, nil, "HUD")
                end
            end
            return
        elseif id == input.CONTROLLER_BUTTON.LeftShoulder then
            if not settings:get("enableGamepadControls") then return end
            -- Scroll list up by 21
            startOffset = startOffset - 21
            local visibleCount = 21
            startOffset = math.max(0, math.min(startOffset, math.max(0, maxCount - visibleCount)))
            endOffset = startOffset + 20
            selectedSpellIndex = startOffset + 1
            selectedSpellIndex = math.min(selectedSpellIndex, maxCount)
            drawSpellSelect()
            -- Show tooltip for selected spell
            local spellData = cachedSpellsAndIds[selectedSpellIndex]
            if tooltip then
                tooltip:destroy()
                tooltip = nil
            end
            if spellData and spellData.id then
                if spellData.enchant then
                    local item = types.Actor.inventory(self):find(spellData.id)
                    tooltip = utility.drawListMenu(tooltipData.genToolTips(item), utility.itemWindowLocs.BottomCenter, nil, "HUD")
                else
                    local spellRecord = core.magic.spells.records[spellData.id]
                    tooltip = utility.drawListMenu(tooltipData.genToolTips({ spell = spellRecord }), utility.itemWindowLocs.BottomCenter, nil, "HUD")
                end
            end
            return
        elseif id == input.CONTROLLER_BUTTON.RightShoulder then
            if not settings:get("enableGamepadControls") then return end
            -- Scroll list down by 21
            startOffset = startOffset + 21
            local visibleCount = 21
            startOffset = math.max(0, math.min(startOffset, math.max(0, maxCount - visibleCount)))
            endOffset = startOffset + 20
            selectedSpellIndex = startOffset + 1
            selectedSpellIndex = math.min(selectedSpellIndex, maxCount)
            drawSpellSelect()
            -- Show tooltip for selected spell
            local spellData = cachedSpellsAndIds[selectedSpellIndex]
            if tooltip then
                tooltip:destroy()
                tooltip = nil
            end
            if spellData and spellData.id then
                if spellData.enchant then
                    local item = types.Actor.inventory(self):find(spellData.id)
                    tooltip = utility.drawListMenu(tooltipData.genToolTips(item), utility.itemWindowLocs.BottomCenter, nil, "HUD")
                else
                    local spellRecord = core.magic.spells.records[spellData.id]
                    tooltip = utility.drawListMenu(tooltipData.genToolTips({ spell = spellRecord }), utility.itemWindowLocs.BottomCenter, nil, "HUD")
                end
            end
            return
        elseif id == input.CONTROLLER_BUTTON.A then
            if not settings:get("enableGamepadControls") then return end
            local spellData = cachedSpellsAndIds[selectedSpellIndex]
            if spellData and spellData.header then
                if spellData.header == "powers" then
                    powersExpanded = not powersExpanded
                elseif spellData.header == "spells" then
                    spellsExpanded = not spellsExpanded
                elseif spellData.header == "enchantments" then
                    enchantmentsExpanded = not enchantmentsExpanded
                end
                cachedSpellsAndIds = nil
                drawSpellSelect()
                return
            else
                -- Save selected spell
                if spellData and spellData.id then
                    if spellData.enchant then
                        I.QuickSelect_Storage.saveStoredEnchantData(spellData.enchant, spellData.id, slotToSave)
                    else
                        I.QuickSelect_Storage.saveStoredSpellData(spellData.id, "Spell", slotToSave)
                    end
                    I.UI.setMode()
                    if QuickSelectWindow then
                        QuickSelectWindow:destroy()
                        QuickSelectWindow = nil
                    end
                    if tooltip then
                        tooltip:destroy()
                        tooltip = nil
                    end
                    slotToSave = nil
                end
                return
            end
        end
    end

    if itemMode then
        if id == input.CONTROLLER_BUTTON.DPadUp then
            if not settings:get("enableGamepadControls") then return end
            if selectedItemRow > 1 then
                selectedItemRow = selectedItemRow - 1
            else
                if startOffset > 0 then
                    startOffset = startOffset - 10
                end
            end
            drawItemSelect()
            -- Update tooltip for selected item
            if tooltip then
                tooltip:destroy()
                tooltip = nil
            end
            local inv = buildInv()
            local index = (selectedItemRow - 1) * 10 + selectedItemCol + startOffset
            if inv[index] then
                tooltip = utility.drawListMenu(tooltipData.genToolTips(inv[index]), utility.itemWindowLocs.BottomCenter, nil, "HUD")
            end
            return
        elseif id == input.CONTROLLER_BUTTON.DPadDown then
            if not settings:get("enableGamepadControls") then return end
            local visibleRows = math.min(6, math.ceil((maxCount - startOffset) / 10))
            if selectedItemRow < visibleRows then
                selectedItemRow = selectedItemRow + 1
            else
                if startOffset + 60 < maxCount then
                    startOffset = startOffset + 10
                end
            end
            drawItemSelect()
            -- Update tooltip for selected item
            if tooltip then
                tooltip:destroy()
                tooltip = nil
            end
            local inv = buildInv()
            local index = (selectedItemRow - 1) * 10 + selectedItemCol + startOffset
            if inv[index] then
                tooltip = utility.drawListMenu(tooltipData.genToolTips(inv[index]), utility.itemWindowLocs.BottomCenter, nil, "HUD")
            end
            return
        elseif id == input.CONTROLLER_BUTTON.DPadLeft then
            if not settings:get("enableGamepadControls") then return end
            selectedItemCol = math.max(1, selectedItemCol - 1)
            drawItemSelect()
            -- Update tooltip for selected item
            if tooltip then
                tooltip:destroy()
                tooltip = nil
            end
            local inv = buildInv()
            local index = (selectedItemRow - 1) * 10 + selectedItemCol + startOffset
            if inv[index] then
                tooltip = utility.drawListMenu(tooltipData.genToolTips(inv[index]), utility.itemWindowLocs.BottomCenter, nil, "HUD")
            end
            return
        elseif id == input.CONTROLLER_BUTTON.DPadRight then
            if not settings:get("enableGamepadControls") then return end
            selectedItemCol = math.min(10, selectedItemCol + 1)
            drawItemSelect()
            -- Update tooltip for selected item
            if tooltip then
                tooltip:destroy()
                tooltip = nil
            end
            local inv = buildInv()
            local index = (selectedItemRow - 1) * 10 + selectedItemCol + startOffset
            if inv[index] then
                tooltip = utility.drawListMenu(tooltipData.genToolTips(inv[index]), utility.itemWindowLocs.BottomCenter, nil, "HUD")
            end
            return
        elseif id == input.CONTROLLER_BUTTON.A then
            if not settings:get("enableGamepadControls") then return end
            local index = (selectedItemRow - 1) * 10 + selectedItemCol + startOffset
            local inv = buildInv()
            if inv[index] then
                I.QuickSelect_Storage.saveStoredItemData(inv[index].recordId, slotToSave)
                I.UI.setMode()
                if QuickSelectWindow then
                    QuickSelectWindow:destroy()
                    QuickSelectWindow = nil
                end
                if tooltip then
                    tooltip:destroy()
                    tooltip = nil
                end
                slotToSave = nil
            end
            return
        elseif id == input.CONTROLLER_BUTTON.LeftShoulder then
            if not settings:get("enableGamepadControls") then return end
            startOffset = startOffset - 50
            local visibleCount = 60
            startOffset = math.max(0, math.min(startOffset, math.max(0, maxCount - visibleCount)))
            endOffset = startOffset + (visibleCount - 1)
            drawItemSelect()
            return
        elseif id == input.CONTROLLER_BUTTON.RightShoulder then
            if not settings:get("enableGamepadControls") then return end
            startOffset = startOffset + 50
            local visibleCount = 60
            startOffset = math.max(0, math.min(startOffset, math.max(0, maxCount - visibleCount)))
            endOffset = startOffset + (visibleCount - 1)
            drawItemSelect()
            return
        end
    end

    if not spellMode and not itemMode then
        if id == input.CONTROLLER_BUTTON.DPadUp then
            if not settings:get("enableGamepadControls") then return end
            selectedRow = math.max(1, selectedRow - 1)
            drawQuickSelect()
            showTooltipForSelectedSlot()
            return
        elseif id == input.CONTROLLER_BUTTON.DPadDown then
            if not settings:get("enableGamepadControls") then return end
            selectedRow = math.min(3, selectedRow + 1)
            drawQuickSelect()
            showTooltipForSelectedSlot()
            return
        elseif id == input.CONTROLLER_BUTTON.DPadLeft then
            if not settings:get("enableGamepadControls") then return end
            selectedCol = math.max(1, selectedCol - 1)
            drawQuickSelect()
            showTooltipForSelectedSlot()
            return
        elseif id == input.CONTROLLER_BUTTON.DPadRight then
            if not settings:get("enableGamepadControls") then return end
            selectedCol = math.min(10, selectedCol + 1)
            drawQuickSelect()
            showTooltipForSelectedSlot()
            return
        elseif id == input.CONTROLLER_BUTTON.A then
            if not settings:get("enableGamepadControls") then return end
            local slot = (selectedRow - 1) * 10 + selectedCol
            slotToSave = slot
            messageBoxTextLines = { "Quick Menu Selection", "W/S or DPad for navigation", "F or X(Pad) to confirm", " " }
            messageBoxButtons = { core.getGMST("sQuickMenu2"), core.getGMST("sQuickMenu3"), core.getGMST("sQuickMenu4"), core.getGMST("sCancel") }
            currentButtonSelected = 1
            messageBoxOpen = true
            messageBoxUtil.showMessageBox(nil, messageBoxTextLines, messageBoxButtons, currentButtonSelected)
            if QuickSelectWindow then
                QuickSelectWindow:destroy()
                QuickSelectWindow = nil
            end
            if tooltip then
                tooltip:destroy()
                tooltip = nil
            end
            return
        end
        return true  -- Consume unhandled controller buttons in hotbar mode
    end

    if spellMode or itemMode then return true end
end
I.UI.registerWindow(I.UI.WINDOW.QuickKeys, drawQuickSelect, function() --
    if QuickSelectWindow then
        QuickSelectWindow:destroy()
        QuickSelectWindow = nil
    end
    if tooltip then
        tooltip:destroy()
        tooltip = nil
    end
end)
local function ButtonClicked(data)
    local text = data.text
    num = 1
    messageBoxOpen = false
    if text == core.getGMST("sQuickMenu2") then
        spellMode = false
        -- Reset spell section states
        powersExpanded = false
        spellsExpanded = false
        enchantmentsExpanded = false
        messageBoxUtil.destroyMessageBox()
        messageBoxOpen = false
        selectedItemRow = 1
        selectedItemCol = 1
        startOffset = 0
        drawItemSelect()
    elseif text == core.getGMST("sQuickMenu3") then
        spellMode = true
        messageBoxUtil.destroyMessageBox()
        messageBoxOpen = false
        powersExpanded = false
        spellsExpanded = false
        enchantmentsExpanded = false
        cachedSpellsAndIds = nil
        selectedSpellIndex = 1
        startOffset = 0
        drawSpellSelect()
    elseif text == core.getGMST("sQuickMenu4") then
--delete
        I.QuickSelect_Storage.deleteStoredItemData(slotToSave)
        I.QuickSelect_Hotbar.drawHotbar()
        if QuickSelectWindow then
            QuickSelectWindow:destroy()
            QuickSelectWindow = nil
        end
        messageBoxUtil.destroyMessageBox()
        messageBoxOpen = false
        I.UI.setMode()
    elseif text == core.getGMST(
        "sCancel") then
        if QuickSelectWindow then
            QuickSelectWindow:destroy()
            QuickSelectWindow = nil
        end
        messageBoxUtil.destroyMessageBox()
        messageBoxOpen = false
        I.UI.setMode()
    end
end
return {

    interfaceName = "QuickSelect_Win1",
    interface = {
        drawQuickSelect = drawQuickSelect,
        openQuickSelect = openQuickSelect,
        getQuickSelectWindow = function()
            return QuickSelectWindow
        end,
        isQuickSelectOpen = function()
            return QuickSelectWindow ~= nil
        end,
        isMessageBoxOpen = function()
            return messageBoxOpen
        end,
    },
    eventHandlers = {
        UiModeChanged = UiModeChanged,
        drawQuickSelect = drawQuickSelect,
        openQuickSelect = openQuickSelect,
        ButtonClicked = ButtonClicked,
        MessageBoxMouseOver = function(data)
            currentButtonSelected = data.index
            redrawMessageBox()
        end,
        MessageBoxNavigate = function(data)
            if data.direction == "up" then
                currentButtonSelected = math.max(1, currentButtonSelected - 1)
            elseif data.direction == "down" then
                currentButtonSelected = math.min(#messageBoxButtons, currentButtonSelected + 1)
            end
            redrawMessageBox()
        end,
        MessageBoxConfirm = function()
            self:sendEvent("ButtonClicked", {text = messageBoxButtons[currentButtonSelected]})
            messageBoxUtil.destroyMessageBox()
            messageBoxOpen = false
        end,
    },
    engineHandlers = {
        onKeyPress = onKeyPress,
        onControllerButtonPress = onControllerButtonPress,
    onMouseWheel = function (vert)
        if not settings:get("enableMouseControls") and not itemMode then return end
        if not QuickSelectWindow then return end
        if not spellMode and not itemMode then return end
            local modifer = 10

            if spellMode then
                modifer = 3
            end
            if vert > 0 then
                startOffset = startOffset - modifer
            elseif vert < 0 then
                startOffset = startOffset + modifer
            end
            -- Clamp startOffset and recalculate endOffset
            local visibleCount = spellMode and 21 or 60  -- 21 for spells, 60 for items
            startOffset = math.max(0, math.min(startOffset, math.max(0, maxCount - visibleCount)))
            endOffset = startOffset + (visibleCount - 1)  -- Recalculate endOffset after clamping
            if spellMode then
                -- Adjust selectedSpellIndex to stay in view
                if selectedSpellIndex < startOffset + 1 then
                    selectedSpellIndex = startOffset + 1
                elseif selectedSpellIndex > startOffset + visibleCount then
                    selectedSpellIndex = startOffset + visibleCount
                end
                selectedSpellIndex = math.min(selectedSpellIndex, maxCount)
                -- Update tooltip
                local spellData = cachedSpellsAndIds[selectedSpellIndex]
                if tooltip then
                    tooltip:destroy()
                    tooltip = nil
                end
                if spellData and spellData.id then
                    if spellData.enchant then
                        local item = types.Actor.inventory(self):find(spellData.id)
                        tooltip = utility.drawListMenu(tooltipData.genToolTips(item), utility.itemWindowLocs.BottomCenter, nil, "HUD")
                    else
                        local spellRecord = core.magic.spells.records[spellData.id]
                        tooltip = utility.drawListMenu(tooltipData.genToolTips({ spell = spellRecord }), utility.itemWindowLocs.BottomCenter, nil, "HUD")
                    end
                end
                drawSpellSelect()
            else
                drawItemSelect()
            end
        end
    },
    onControllerAxisMove = function(axis, value)
        -- Scrolling now handled by shoulder buttons in onControllerButtonPress
    end
}
