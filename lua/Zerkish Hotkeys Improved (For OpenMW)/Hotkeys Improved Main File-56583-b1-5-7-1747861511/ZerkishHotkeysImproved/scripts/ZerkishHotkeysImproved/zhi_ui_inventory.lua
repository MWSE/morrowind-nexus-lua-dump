-- Zerkish Hotkeys Improved - zhi_ui_inventory.lua
-- re-implementation of the default quick key UI screen

local Actor = require('openmw.types').Actor
local async = require('openmw.async')
local types = require('openmw.types')
local ui = require('openmw.ui')
local util = require('openmw.util')
local I = require('openmw.interfaces')
local storage = require('openmw.storage')
local self = require('openmw.self')

local constants = require('scripts.omw.mwui.constants')

local ZHIUtil       = require('scripts.ZerkishHotkeysImproved.zhi_util')
local ZHIUI         = require('scripts.ZerkishHotkeysImproved.zhi_ui')
local ZHITooltip    = require('scripts.ZerkishHotkeysImproved.zhi_tooltip')

local ZHIUI_INVENTORY_CONSTANTS = {
    -- WindowWidth = 400,
    -- WindowHeight = 320,
    HeaderHeight = 38,

    HPadding = 8,
    VPadding = 8,

    --ItemsPerRow = 8,
    ItemSize = 34,
    ItemPadding = 1,

    --InventoryNumRows = 8,
    TooltipMaxHeight = 400,
}

local function createInventoryItem(item, callbacks)

    local padding = (ZHIUI_INVENTORY_CONSTANTS.ItemPadding + constants.border) * 2
    local paddedSize = util.vector2(1, 1) * (ZHIUI_INVENTORY_CONSTANTS.ItemSize + padding)

    local icon = item.type.records[item.recordId].icon

    local root = {
        --template = I.MWUI.templates.boxSolid,
        --type = ui.TYPE.Container,
        type = ui.TYPE.Widget,
        props = {
            propagateEvents = false,
            anchor = util.vector2(0.5, 0.5),
            relativePosition = util.vector2(0.5, 0.5),
            relativeSize = util.vector2(1.0, 1.0),
            size = util.vector2(ZHIUI_INVENTORY_CONSTANTS.ItemSize, ZHIUI_INVENTORY_CONSTANTS.ItemSize)
        },
        content = ui.content({}),
        userData = {
            item = item,
        },
        events = {
            mouseMove = async:callback(function(mEvent, layout)
                if callbacks.onMouseMove then
                    callbacks.onMouseMove(mEvent, layout)
                end
            end),
            mouseRelease = async:callback(function(mEvent, layout) 
                if callbacks.onSelectItem then
                    callbacks.onSelectItem(layout.userData.item)
                end
            end),
            focusGain = async:callback(function(unused, layout)
                if callbacks.onFocusItem then
                    callbacks.onFocusItem(layout)
                end
            end),
            focusLoss = async:callback(function(unused, layout)
                if callbacks.onFocusLossItem then
                    callbacks.onFocusLossItem(layout)
                end
            end),
        }
    }

    local bgPath = nil
    if Actor.hasEquipped(self, item) then
        if item.type.records[item.recordId].enchant ~= nil then
            bgPath = 'textures/menu_icon_magic_equip.dds'
        else
            bgPath = 'textures/menu_icon_equip.dds'
        end
    elseif item.type.records[item.recordId].enchant then
        bgPath = 'textures/menu_icon_magic.dds'
    end

    if bgPath then
        root.content:add({
            type = ui.TYPE.Image,
            props = {
                propagateEvents = true,
                resource = ZHIUtil.getCachedTexture({
                    path = bgPath,
                    offset = util.vector2(0, 0),
                    size = util.vector2(44, 44)
                }),
                -- resource = ui.texture({ 
                --     path = bgPath,
                --     offset = util.vector2(0, 0),
                --     size = util.vector2(44, 44)
                --  }),
                size = util.vector2(ZHIUI_INVENTORY_CONSTANTS.ItemSize + 6, ZHIUI_INVENTORY_CONSTANTS.ItemSize + 6),
                anchor = util.vector2(0.5, 0.5),
                relativePosition = util.vector2(0.5, 0.5),
            }
        })
    end

    root.content:add({
        type = ui.TYPE.Image,
        props = {
            propagateEvents = true,
            resource = ZHIUtil.getCachedTexture({path = icon }), -- ui.texture({ path = icon }),
            size = util.vector2(ZHIUI_INVENTORY_CONSTANTS.ItemSize - 2, ZHIUI_INVENTORY_CONSTANTS.ItemSize - 2),
            anchor = util.vector2(0.5, 0.5),
            relativePosition = util.vector2(0.5, 0.5),
        },
    })

    local padded = {
        type = ui.TYPE.Widget,
        props = {
            propagateEvents = false,
            size = paddedSize,
        },
        content = ui.content({root})
    }

    return padded
end

local function createInventoryRow(itemsPerRow, items, startIndex, callbacks)

    local row = {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            autoSize = true,
            align = ui.ALIGNMENT.Center,
            arrange = ui.ALIGNMENT.Center,
        },
        content = ui.content({})
    }

    local count = itemsPerRow
    if startIndex + count > #items then
        count = #items - startIndex
    end

    local max = math.min(#items, startIndex + itemsPerRow - 1)

    for i=startIndex, max do
        row.content:add(createInventoryItem(items[i], callbacks))
    end

    return row
end

local function isItemUseableType(item)
    -- check for carryable light sources
    if (item.type == types.Light) then
        return item.type.records[item.recordId].isCarriable
    end

    -- Anything with a script on it can be bound, it's the same as default menu as far as I can tell.
    local record = item.type.records[item.recordId]
    if record.mwscript then return true end

    return ZHIUtil.equalAnyOf(item.type,
        types.Apparatus,
        types.Armor,
        types.Book,
        types.Clothing,
        -- I've no idea what the ESM4 types are.
        --[[
        types.ESM4Ammunition,
        types.ESM4Book,
        types.ESM4Clothing,
        types.ESM4Ingredient,
        types.ESM4Light,
        types.ESM4Potion,
        types.ESM4Weapon,
        ]]--
        types.Ingredient,
        types.Lockpick,
        --types.Miscellaneous,
        types.Potion,
        types.Probe,
        types.Repair,
        types.Weapon
    )
end

local function filterUseableItems(items)
    local uItems = {}

    for i, v in ipairs(items) do
        if isItemUseableType(v) then
            table.insert(uItems, v)
        end
    end

    return uItems
end

local itemTypePriority = {
    Weapon = 1,
    Armor = 2,
    Clothing = 3,
    Potion = 4,
    Ingredient = 5,
    Apparatus = 6,
    Book = 7,
    Light = 8,
    Lockpick = 9,
    Repair = 10,
    Probe = 11,
    Miscellaneous = 12,
}

local function getItemTypePriority(item)
    local val = itemTypePriority[tostring(item.type)]
    return val and val or 999
end

local function sortCompareItems(itemA, itemB)
    -- equipped items come first
    local equippedA = Actor.hasEquipped(self, itemA)
    local equippedB = Actor.hasEquipped(self, itemB)
    if equippedA ~= equippedB then
         return equippedA
    end

    -- then sort by type
    local sortA = getItemTypePriority(itemA)
    local sortB = getItemTypePriority(itemB)
    if sortA ~= sortB then
        return sortA < sortB
    end

    -- and finally alphabetically
    return itemA.type.records[itemA.recordId].name < itemB.type.records[itemB.recordId].name
end

local function getSortedPlayerInventoryItems()
    local inventory = Actor.inventory(self)
    local items = filterUseableItems(inventory:getAll())

    table.sort(items, sortCompareItems)
    return items
end

return {
    createInventorySelectionWindow = function(callbacks)

        local section = storage.playerSection('SettingsZHIAAMain')
        local itemsPerRow = section:get('inventory_num_rows')
        local itemsPerCol = section:get('inventory_num_cols')

        local rows = {}

        local items = getSortedPlayerInventoryItems()

        local numRows = (#items / itemsPerRow) + 1

        for i=1, numRows do
            table.insert(rows, createInventoryRow(itemsPerRow, items, (i-1) * itemsPerRow + 1, callbacks))
            --inventoryPanel.content:add(createInventoryRow())
        end

        local borderPadding = constants.border * 2
        local itemActualSize = ZHIUI_INVENTORY_CONSTANTS.ItemSize + borderPadding
        local rowHeight = itemActualSize + ZHIUI_INVENTORY_CONSTANTS.ItemPadding * 2

        local panelWidth = itemsPerRow * (itemActualSize + ZHIUI_INVENTORY_CONSTANTS.ItemPadding * 2)
        local panelHeight = itemsPerCol * rowHeight

        local adjustedSize = ZHIUI.adjustScrollPaneSize(rows, util.vector2(itemActualSize, rowHeight), util.vector2(panelWidth, panelHeight))

        local inventoryPanel = ZHIUI.createVerticalScrollPane(rows, util.vector2(itemActualSize, rowHeight), adjustedSize)

        local inventoryWrapper = {
            template = I.MWUI.templates.boxSolid,
            type = ui.TYPE.Container,
            props = {},
            content = ui.content({
                inventoryPanel
            }),
        }

        local header = {
            --template = I.MWUI.templates.boxSolid,
            type = ui.TYPE.Container,
            props = { },
            content = ui.content({
                {
                    type = ui.TYPE.Flex,
                    props = {
                        size = util.vector2(adjustedSize.x, ZHIUI_INVENTORY_CONSTANTS.HeaderHeight),
                        align = ui.ALIGNMENT.Center,
                    },
                    content = ui.content({
                        {
                            type = ui.TYPE.Text,
                            props = {
                                text = 'Inventory Items to Quick key',
                                textSize = 20,
                                textColor = constants.normalColor,
                                relativePosition = util.vector2(0, 0.5),
                                anchor = util.vector2(0.0, 0.5),
                            }
                        }
                    })
                }
            })
        }

        local footer = {
            --template = I.MWUI.templates.boxSolid,
            type = ui.TYPE.Container,
            props = { },
            content = ui.content({
                 {
                    type = ui.TYPE.Flex,
                    align = ui.ALIGNMENT.End,
                    props = {
                        horizontal = true,
                        size = util.vector2(adjustedSize.x + constants.thickBorder, ZHIUI_INVENTORY_CONSTANTS.HeaderHeight),
                        align = ui.ALIGNMENT.End,
                        arrange = ui.ALIGNMENT.Center,
                    },
                    content = ui.content({
                        ZHIUI.createTextButton('Cancel', function ()
                             if callbacks.onSelectItem then
                                callbacks.onSelectItem(nil)
                             end
                        end),
                    })
                },
            })
        }

        local centerContent = {
            --template = I.MWUI.templates.boxSolid,
            type = ui.TYPE.Container,
            props = {},
            content = ui.content({
                {
                    type = ui.TYPE.Flex,
                    props = {
                        autoSize = true,
                        horizontal = false,
                    },
                    content = ui.content({
                        header,
                        inventoryWrapper,
                        footer,
                    })
                }
            })
        }

        -- Container handling the horizontal padding of the window
        local hContainer = {
            type = ui.TYPE.Flex,
            props = {
                horizontal = true,
                autoSize = true,
            },
            content = ui.content({
                {
                    type = ui.TYPE.Widget,
                    props = { size = util.vector2(ZHIUI_INVENTORY_CONSTANTS.HPadding, 1) },
                },
                centerContent,
                {
                    type = ui.TYPE.Widget,
                    props = { size = util.vector2(ZHIUI_INVENTORY_CONSTANTS.HPadding, 1) },
                },
            }),
        }

        local scrollbar = ZHIUtil.findLayoutByNameRecursive(inventoryPanel.content, 'vpane_scrollbar')
        local vpaneContent = ZHIUtil.findLayoutByNameRecursive(inventoryPanel.content, 'outerContent')

        local root = {
            template = I.MWUI.templates.boxSolidThick,
            type = ui.TYPE.Container,
            layer = I.ZHI.getPopupLayer(),
            props = {
                anchor = util.vector2(0.5, 0.5),
                relativePosition = I.ZHI.getWindowAnchor(),
            },
            userData = {
                scrollbar = scrollbar,
                content = vpaneContent,
            },
            content = ui.content({
                hContainer,
            })
        }

        return ui.create(root)
    end,

    scrollContent = function(msWindow, vWheelInput)
        if (math.abs(vWheelInput) == 0) then
            return
        end

        if not (msWindow and msWindow.layout.userData and msWindow.layout.userData.scrollbar) then
            return
        end

        local content, scrollbar = msWindow.layout.userData.content, msWindow.layout.userData.scrollbar

        local dir = vWheelInput / math.abs(vWheelInput)

        ZHIUI.vScrollPaneMoveScrollbarByItems(content, scrollbar, -dir)
        ZHIUI.vScrollpaneSetContentPositionFromScrollbarPosition(content, scrollbar)
        I.ZHI.updateUI()
    end,

    showTooltip = function(msWindow, layout)
        local tooltipPane = msWindow.layout.userData.tooltipPane

        local data = {
            item = {
                itemId = layout.userData.item.id,
                recordId = layout.userData.item.recordId,
                itemType = layout.userData.item.type,
            }
        }

        if #tooltipPane.content > 0 then
            ZHITooltip.setTooltipData(tooltipPane.content[1], data)
            tooltipPane.content[1].props.visible = true
        else
            local tooltip = ZHITooltip.createTooltip(data)
            tooltip.props.anchor = util.vector2(0.5, 0.0)
            tooltip.props.relativePosition = util.vector2(0.5, 0.0)
            tooltipPane.content = ui.content({tooltip})
        end
    end,

    hideTooltip = function(msWindow, layout)
        local tooltipPane = msWindow.layout.userData.tooltipPane
        if #tooltipPane.content > 0 then
            tooltipPane.content[1].props.visible = false
        end
    end,

}