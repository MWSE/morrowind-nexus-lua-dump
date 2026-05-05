--[[
ErnEnchantersRecharge for OpenMW.
Copyright (C) 2026 Erin Pentecost

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]
local MOD_NAME     = require("scripts.ErnEnchantersRecharge.ns")
local core         = require("openmw.core")
local localization = core.l10n(MOD_NAME)
local pself        = require("openmw.self")
local ui           = require("openmw.ui")
local types        = require("openmw.types")
local util         = require("openmw.util")
local async        = require("openmw.async")
local ambient      = require("openmw.ambient")
local input        = require("openmw.input")
local enchantUtil  = require('scripts.ErnEnchantersRecharge.enchantutil')
local myui         = require('scripts.ErnEnchantersRecharge.pcp.myui')
local virtualList  = require("scripts.ErnEnchantersRecharge.VirtualList.virtual_list")
local keytrack     = require("scripts.ErnEnchantersRecharge.keytrack")
local settings     = require("scripts.ErnEnchantersRecharge.settings")
local aux_util     = require('openmw_aux.util')

local interfaces   = require('openmw.interfaces')

local topic        = string.lower(localization("rechargeTopic"))

pself.type.addTopic(pself, topic)

local rechargeCostMult = core.getGMST('fMagicItemChargeRechargeMult') or 1.0

---@return integer
local function cost(charge, capacity, itemCost, enchanter)
    -- you pay the square root of the total item cost, prorated by missing charge %,
    -- plus .3 gp per missing charge.
    local base = ((1 - (charge / capacity)) * math.sqrt(itemCost)) + (capacity - charge) * .3
    -- costs are plus or minus 50% based on mercantile.
    local playerBarter = pself.type.stats.skills.mercantile(pself).modified
    local enchanterBarter = pself.type.stats.skills.mercantile(enchanter).modified
    return math.ceil(settings.main.costScale * rechargeCostMult * base *
        util.remap(util.clamp(enchanterBarter / playerBarter, 0, 2), 0, 2, 0.5, 1.5))
end

---@class RechargeEntity
---@field charge number
---@field capacity number
---@field cost number
---@field record any
---@field item any

---comment
---@param item any
---@param record any
---@return RechargeEntity?
local function missingCharge(item, record, enchanter)
    if not item:isValid() then
        return nil
    end
    if item.count > 1 then
        -- stacks are so busted
        return nil
    end
    if record.enchant == nil then
        return nil
    end
    -- enchantRecord.charge is not the same as item max charge capacity!!!
    -- this returns 105 for "steel staff of the ancestors", but that max charge is actually 75
    -- 105 is for the enchantment record, but that's not the whole story.
    -- the staff item itself has a "Enchantment Points" value of 70.
    --
    local enchantRecord = core.magic.enchantments.records[record.enchant]
    if enchantRecord.type == core.magic.ENCHANTMENT_TYPE.CastOnce or enchantRecord.type == core.magic.ENCHANTMENT_TYPE.ConstantEffect then
        return nil
    end

    local capacity = enchantUtil.getMaxEnchantmentCharge(enchantRecord)
    if capacity < 1 then
        return nil
    end
    --print("capacity: " .. tostring(record.name) .. " - " .. tostring(capacity))

    local data = types.Item.itemData(item)
    if not data or (data.enchantmentCharge == nil) then
        return nil
    end
    if data.enchantmentCharge >= capacity then
        return nil
    end

    local out = {
        charge = data.enchantmentCharge,
        capacity = capacity,
        record = record,
        item = item,
        cost = cost(data.enchantmentCharge, capacity, record.value, enchanter)
    }
    settings.debugPrint("item missing charge: " .. aux_util.deepToString(out, 4))
    return out
end

---@return RechargeEntity[]
local function getRechargableItems(enchanter)
    local out = {}
    for _, item in ipairs(pself.type.inventory(pself):getAll(types.Weapon)) do
        local recharge = missingCharge(item, types.Weapon.record(item), enchanter)
        if recharge then
            table.insert(out, recharge)
        end
    end
    for _, item in ipairs(pself.type.inventory(pself):getAll(types.Armor)) do
        local recharge = missingCharge(item, types.Armor.record(item), enchanter)
        if recharge then
            table.insert(out, recharge)
        end
    end
    for _, item in ipairs(pself.type.inventory(pself):getAll(types.Clothing)) do
        local recharge = missingCharge(item, types.Clothing.record(item), enchanter)
        if recharge then
            table.insert(out, recharge)
        end
    end
    table.sort(out, function(a, b)
        if a.record.name == b.record.name then
            return a.item.id < b.item.id
        end
        return a.record.name < b.record.name
    end)
    return out
end

local windowPosition = util.vector2(0.5, 0.5)
local windowSize = util.vector2(420, 500)
local itemSize = util.vector2(400, 32)
local viewportSize = util.vector2(420, 400)


local listHeaderLayout = {
    type = ui.TYPE.Flex,
    props = {
        arrange = ui.ALIGNMENT.Center,
        horizontal = true,
        autoSize = false,
        size = itemSize,
    },
    content = ui.content {
        myui.padWidget(4, 0),
        {
            template = interfaces.MWUI.templates.textHeader,
            type = ui.TYPE.Text,
            name = "itemName",
            props = {
                text = localization("magicalItems"),
                textColor = myui.textColors.header,
                textAlignV = ui.ALIGNMENT.Center,
            },
            external = { grow = 1 }
        },
        {
            template = interfaces.MWUI.templates.textHeader,
            type = ui.TYPE.Text,
            name = "cost",
            props = {
                text = localization("cost"),
                textColor = myui.textColors.header,
                textAlignV = ui.ALIGNMENT.Center,
                textAlignH = ui.ALIGNMENT.Start,
                anchor = util.vector2(1, 0.5)
            }
        },
        myui.padWidget(4, 0),
    },
}

local function barLayout(ratio, relativeLength)
    return {
        type = ui.TYPE.Widget,
        name = 'bar',
        template = interfaces.MWUI.templates.borders,
        props = {
            relativeSize = util.vector2(relativeLength or 1, 0),
            size = util.vector2(0, 8)
        },
        content = ui.content {
            {
                type = ui.TYPE.Image,
                name = 'barContainer',
                props = {
                    resource = ui.texture { path = 'white' },
                    relativePosition = util.vector2(0, 0),
                    relativeSize = util.vector2(1, 1),
                    alpha = 0.7,
                    color = util.color.rgb(0.1, 0.1, 0.1),
                },
                events = {},
            },
            {
                type = ui.TYPE.Image,
                name = 'barFill',
                props = {
                    resource = ui.texture { path = 'Textures/ErnEnchantersRecharge/horz_gradient.dds' },
                    anchor = util.vector2(0, 0),
                    --relativePosition = util.vector2(0, 1),
                    relativeSize = util.vector2(ratio, 1),
                    alpha = 0.7,
                    color = myui.textColors.magic_fill,
                },
            },
        }
    }
end

local function currentGold()
    return pself.type.inventory(pself):countOf("gold_001")
end

local currentGoldElement = ui.create {}
local function updateCurrentGoldElement()
    currentGoldElement.layout = {
        template = interfaces.MWUI.templates.textHeader,
        type = ui.TYPE.Text,
        name = "cost",
        props = {
            text = localization("currentGold", { gold = currentGold() }),
            textColor = myui.interactiveTextColors.normal.default,
            textAlignV = ui.ALIGNMENT.Center,
            textAlignH = ui.ALIGNMENT.End,
            relativePosition = util.vector2(1, 1),
            anchor = util.vector2(1, 1),
            position = util.vector2(-4, -4),
        }
    }
    currentGoldElement:update()
end
updateCurrentGoldElement()


---@param recharge RechargeEntity
local function doRecharge(recharge)
    local gp = currentGold()
    if gp <= recharge.cost then
        ambient.playSoundFile("sound\\ErnEnchantersRecharge\\cancel.mp3")
        return
    end
    core.sendGlobalEvent(MOD_NAME .. 'onRecharge', {
        player = pself,
        cost = recharge.cost,
        item = recharge.item,
        charge = recharge.charge,
        capacity = recharge.capacity
    })
end

local window
local enchanter
local items = {}
local itemList
---@type number?
local selectedIndex = nil
---@type number?
local focusIndex = nil


---@param recharge RechargeEntity
---@return table
local function rechargableItemLayout(recharge, idx, isSelected, isFocus, list)
    local layout = {
        type = ui.TYPE.Flex,
        name = "row_" .. recharge.record.name,
        props = {
            arrange = ui.ALIGNMENT.Center,
            horizontal = true,
            autoSize = false,
            size = itemSize,
        },
        content = ui.content {
            myui.padWidget(4, 0),
            {
                type = ui.TYPE.Image,
                name = "itemIcon",
                props = {
                    resource = ui.texture {
                        path = recharge.record.icon
                    },
                    size = util.vector2(32, 32)
                },
            },
            myui.padWidget(4, 0),
            {
                type = ui.TYPE.Flex,
                name = "row_" .. recharge.record.name,
                props = {
                    arrange = ui.ALIGNMENT.Start,
                    horizontal = false,
                    size = itemSize,
                },
                external = { grow = 1 },
                content = ui.content {
                    {
                        template = interfaces.MWUI.templates.textHeader,
                        type = ui.TYPE.Text,
                        name = "itemName",
                        props = {
                            text = recharge.record.name,
                            textColor = myui.interactiveTextColors.normal.default,
                            textAlignV = ui.ALIGNMENT.Center,
                        },
                    },
                    myui.padWidget(0, 2),
                    barLayout(recharge.charge / recharge.capacity, 0.7),
                },
            },
            myui.padWidget(4, 0),
            {
                template = interfaces.MWUI.templates.textHeader,
                type = ui.TYPE.Text,
                name = "cost",
                props = {
                    text = tostring(recharge.cost),
                    textColor = myui.interactiveTextColors.normal.default,
                    textAlignV = ui.ALIGNMENT.Center,
                    textAlignH = ui.ALIGNMENT.Start,
                    anchor = util.vector2(1, 0.5)
                }
            }
        },
    }

    local bgColor = util.color.rgb(0, 0, 0)
    if isSelected then
        bgColor = myui.interactiveTextColors.normal.default
    elseif isFocus then
        bgColor = myui.interactiveTextColors.normal.over
    end

    local rowBG = {
        type = ui.TYPE.Image,
        name = 'rowBG',
        props = {
            resource = ui.texture { path = 'white' },
            relativePosition = util.vector2(0, 0),
            relativeSize = util.vector2(1, 1),
            alpha = 0.2,
            --color = util.color.rgb(0, 0, 0),
            color = bgColor
        }
    }


    local rowContainer = {
        type = ui.TYPE.Widget,
        name = 'row',
        props = {
            relativePosition = util.vector2(0, 0),
            --relativeSize = util.vector2(1, 1),
            --alpha = 1,
            --color = util.color.rgb(0, 0, 0),
            --
        },
        events = {},
        content = ui.content {
            rowBG,
            layout
        }
    }

    rowContainer.events = {
        focusGain = async:callback(function(_, element)
            --print("focus on " .. tostring(idx))
            focusIndex = idx
            --updateRowColor(element, idx == selectedIndex, true)
            itemList:redraw()
        end),
        focusLoss = async:callback(function(_, element)
            --print("focus off " .. tostring(idx))
            --updateRowColor(element, idx == selectedIndex, false)
            if focusIndex == idx then
                focusIndex = nil
            end
            itemList:redraw()
        end),
        mousePress = async:callback(function(e)
            if e.button == 1 then
                ambient.playSound("menu click")
                --itemList:setPressedIndex(idx)
                --itemList:changeSelection(idx, rowBG)
                --itemList:updateColor(rowBG, idx)
                doRecharge(recharge)
            end
        end)
    }

    return rowContainer
end


local function closeWindow()
    if window or itemList then
        if window then window:destroy() end
        window = nil
        enchanter = nil
        items = {}
        itemList.element:destroy()
        itemList = nil
        selectedIndex = nil
        focusIndex = nil
        -- check if nothing is visible
        if interfaces.UI.getMode() == "Interface" then
            local somethingVisible = false
            for wind in pairs(interfaces.UI.getWindowsForMode("Interface")) do
                somethingVisible = somethingVisible or interfaces.UI.isWindowVisible(wind)
            end
            if not somethingVisible then
                interfaces.UI.removeMode("Interface")
            end
        end
    end
end

-- close window
local function UiModeChanged(data)
    if (data.newMode == nil) or (data.newMode ~= "Interface") then
        closeWindow()
    end
end

local cancelButtonElement = ui.create {}
local function updateCancelButtonElement()
    cancelButtonElement.layout = myui.createTextButton(
        cancelButtonElement,
        localization("cancel"),
        "normal",
        "cancelButton",
        {
            relativePosition = util.vector2(0.5, 1),
            anchor = util.vector2(0.5, 1),
            position = util.vector2(0, -4),
        },
        util.vector2(60, 20),
        closeWindow)
    cancelButtonElement:update()
end
updateCancelButtonElement()


local stretchPaddingLayout = {
    name = 'stretchPadWidget',
    props = { size = util.vector2(1, 1) },
    external = { grow = 1 }
}

local function openRechargeWindow(enchanterActor)
    enchanter = enchanterActor
    items = getRechargableItems(enchanter)
    settings.debugPrint("Found " .. #items .. " rechargeable items.")

    interfaces.UI.addMode("Interface", { windows = {} })
    -- Note the list must know the sizes involved to do its math.
    itemList = virtualList.create({
        viewportSize = viewportSize,
        itemSize = itemSize,
        itemCount = #items,
        itemLayout = function(i, list)
            return rechargableItemLayout(items[i], i, i == selectedIndex, i == focusIndex, list)
        end,
    })

    -- Put our list in a bordered window with a black background.
    window = ui.create({
        layer = "Windows",
        type = ui.TYPE.Image,
        template = interfaces.MWUI.templates.borders,
        props = {
            size = windowSize,
            anchor = windowPosition,
            relativePosition = windowPosition,
            resource = ui.texture({ path = "black" }),
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                props = {
                    arrange = ui.ALIGNMENT.Center,
                    horizontal = false,
                    autoSize = false,
                    relativeSize = util.vector2(1, 1)
                    --size = itemSize,
                },
                content = ui.content {
                    listHeaderLayout,
                    stretchPaddingLayout,
                    itemList:getElement(),
                    stretchPaddingLayout,
                    {
                        type = ui.TYPE.Widget,
                        props = {
                            size = itemSize,
                        },
                        content = ui.content {
                            cancelButtonElement,
                            currentGoldElement,
                        }
                    },
                }
            },
        }
    })
end

local function onUpdateUI()
    updateCurrentGoldElement()
    items = getRechargableItems(enchanter)
    settings.debugPrint("Found " .. #items .. " rechargeable items.")
    itemList:rebuild(#items)
    itemList.visibleRange = nil
    if #items == 0 then
        selectedIndex = nil
        itemList:redraw()
    elseif selectedIndex and selectedIndex > #items then
        selectedIndex = #items
        itemList:redraw()
    end
end

local stickDeadzone = 0.3
local keys          = {
    forward  = keytrack.NewKey("forward", function(dt)
        return input.isKeyPressed(input.KEY.UpArrow) or
            (input.getAxisValue(input.CONTROLLER_AXIS.RightY) < -1 * stickDeadzone)
    end),
    backward = keytrack.NewKey("backward", function(dt)
        return input.isKeyPressed(input.KEY.DownArrow) or
            (input.getAxisValue(input.CONTROLLER_AXIS.RightY) > stickDeadzone)
    end),
    enter    = keytrack.NewKey("enter", function(dt)
        return input.isKeyPressed(input.KEY.Enter) or
            (input.isControllerButtonPressed(input.CONTROLLER_BUTTON.A))
    end),
}

local function wrapIndex(index, length)
    return ((index - 1) % length) + 1
end

local function onFrame(dt)
    if window and itemList then
        -- Track inputs.
        for _, inp in pairs(keys) do
            inp:update(dt)
        end

        local idx = selectedIndex or 0

        if keys.backward.fall then
            selectedIndex = wrapIndex(idx + 1, #items)
            if itemList:getVisibleRange().start > selectedIndex or itemList:getVisibleRange().stop < selectedIndex then
                --print("move window backward")
                itemList:scrollToIndex(selectedIndex, "bottom")
            end
            itemList:redraw()
            --updateRowColor()
            --print("selected " .. tostring(selectedIndex))
        end
        if keys.forward.fall then
            selectedIndex = wrapIndex(idx - 1, #items)
            if itemList:getVisibleRange().start > selectedIndex or itemList:getVisibleRange().stop < selectedIndex then
                --print("move window forward")
                itemList:scrollToIndex(selectedIndex, "top")
            end
            itemList:redraw()
            --print("selected " .. tostring(selectedIndex))
        end
        if keys.enter.fall then
            if selectedIndex then
                doRecharge(items[selectedIndex])
            elseif #items > 0 then
                selectedIndex = 1
                itemList:redraw()
            elseif #items == 0 then
                closeWindow()
            end
        end
    end
end

return {
    eventHandlers = {
        [MOD_NAME .. "onUpdateUI"] = onUpdateUI,
        UiModeChanged = UiModeChanged,
        DialogueResponse = function(e)
            if e.recordId == topic then
                openRechargeWindow(e.actor)
            end
        end
    },
    engineHandlers = {
        -- Optional mouse wheel handling for scrolling.
        onMouseWheel = function(vertical, horizontal)
            if itemList then
                itemList:getMouseWheelHandler()(vertical, horizontal)
            end
        end,
        onFrame = onFrame,
    },
}
