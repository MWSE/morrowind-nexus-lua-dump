local core = require('openmw.core')
local ui = require('openmw.ui')
local auxUi = require('openmw_aux.ui')
local storage = require('openmw.storage')
local omwself = require('openmw.self')
local util = require('openmw.util')
local v2 = util.vector2
local I = require('openmw.interfaces')
local async = require('openmw.async')
local types = require('openmw.types')
local ambient = require('openmw.ambient')
local input = require('openmw.input')

local baseTemplates = require('scripts.InventoryExtender.ui.templates.base')
local specialTemplates = require('scripts.InventoryExtender.ui.templates.magic')
local CategoryFilter = require('scripts.InventoryExtender.ui.templates.categoryFilter')
local ItemTable = require('scripts.InventoryExtender.ui.templates.itemTable')
local InfoBar = require('scripts.InventoryExtender.ui.templates.infoBar')
local ItemStackModal = require('scripts.InventoryExtender.ui.templates.itemStackModal')
local ColumnSettingsModal = require('scripts.InventoryExtender.ui.templates.columnSettingsModal')
local Window = require('scripts.InventoryExtender.ui.windows.base')

local configPlayer = require('scripts.InventoryExtender.config.player')
local helpers = require('scripts.InventoryExtender.util.helpers')
local iconPack = require('scripts.InventoryExtender.util.iconPack')
local constants = require('scripts.InventoryExtender.util.constants')
local barterUtils = require('scripts.InventoryExtender.util.barter')
local persistentCorpses = require('scripts.InventoryExtender.util.persistentCorpses')
local Pickpocket = require('scripts.InventoryExtender.util.pickpocket')

local l10n = core.l10n('InventoryExtender')
local windowOptionsSection = storage.playerSection('InventoryExtender')
local columnVisibilityKey = 'ColumnVisibility'
local playerWindowSettings = storage.playerSection('Settings/InventoryExtender/2_WindowOptions')
local inventoryCategoryKey = 'All'

local Inventory = Window:new()

local OptionalColumns = {
    Condition = true,
    Weight_Total = true,
}

function Inventory:update(deep)
    if self.updateSize then
        self:updateSize()
    end
    self:setTitle()
    self:setPinnable()
    Window.update(self, deep)
end

function Inventory:create(windowType, ctx)
    local self = setmetatable({}, {__index = Inventory})
    self.ctx = ctx

    self.type = windowType
    if self.type == 'Inventory' then
        self.target = omwself
    end

    local content = ui.content {}
    local data = self:createData()

    local w = 60 * baseTemplates.TEXT_SIZE / 16

    local function canPickupItem(row, windowType, allowOutsideInterface)
        local mode = I.UI.getMode()
        if mode == 'Interface' then
            return true
        end

        if not allowOutsideInterface then
            return false
        end

        if mode == 'Container' or mode == 'Companion' then
            return true
        end

        if mode == 'Barter' then
            local effectiveWindowType = windowType or self.type
            if effectiveWindowType == 'Inventory' then
                return not row.isBartered
            end
            if effectiveWindowType == 'Trade' then
                return row.isBartered == true
            end
        end

        return false
    end

    local function getUseItemSource(row, windowType)
        local effectiveWindowType = windowType or self.type
        if row.item.parentContainer ~= nil then
            return row.item.parentContainer
        end
        if effectiveWindowType == 'Container' or effectiveWindowType == 'Companion' then
            return self.target
        end
        return omwself
    end

    local function getUseItemPickpocket(row, windowType)
        local effectiveWindowType = windowType or self.type
        local mode = I.UI.getMode()
        if mode == 'Container' and effectiveWindowType == 'Container' and ctx.pickpocket and ctx.pickpocket.active then
            return { target = self.target }
        end
        return nil
    end

    local onRowUse = function(row, rowWidget, fromKBMKeybind, forceBarterAction)
        return false
    end

    local function onRowPickup(row, rowWidget, windowType, allowOutsideInterface)
        if I.UI.getMode() == 'Barter' then
            return onRowUse(row, rowWidget, true, true)
        end

        for i = #ctx.handlers.onRowPickup, 1, -1 do
            local handler = ctx.handlers.onRowPickup[i]
            if handler.handler(row, ctx, self.type) == false then
                return false
            end
        end

        if not canPickupItem(row, windowType, allowOutsideInterface) then
            return false
        end

        if rowWidget and rowWidget.layout and rowWidget.layout.props then
            self.itemTable.layout.userData.getState().lastUsedRowPos = rowWidget.layout.props.position - v2(0, (ctx.focusedScrollable and ctx.focusedScrollable.layout.userData.getScrollPos() or 0))
        end

        if omwself.type.hasEquipped and omwself.type.hasEquipped(omwself, row.item) then
            local equipment = omwself.type.getEquipment(omwself)
            for slot, equippedItem in pairs(equipment) do
                if equippedItem == row.item then
                    equipment[slot] = nil
                    omwself.type.setEquipment(omwself, equipment)
                    local sound = helpers.getItemSound(row.item, 'down')
                    if sound then
                        ambient.playSound(sound)
                    end
                    omwself:sendEvent('IE_Update')
                    break
                end
            end
        else
            core.sendGlobalEvent('IE_UseItem', {
                object = row.item,
                actor = omwself,
                source = getUseItemSource(row, windowType),
                pickpocket = getUseItemPickpocket(row, windowType),
            })
        end
    end

    local function createDraggedActivationRow(item)
        local activationContext = ctx.dragAndDrop.draggingActivationContext or {}
        return {
            id = item.id,
            item = item,
            itemRecord = item.type.record(item),
            isBartered = activationContext.isBartered,
            getCount = function()
                return ctx.dragAndDrop.draggingCount or item.count
            end,
        }
    end

    local function getEnchantedIndicatorMode()
        return configPlayer.tweaks.s_EnchantedIndicatorMode or 'EnchantedIndicatorMode_Both'
    end

    local function shouldShowEnchantedSwirl(forceEnchantSwirl)
        return forceEnchantSwirl or getEnchantedIndicatorMode() ~= 'EnchantedIndicatorMode_Icon'
    end

    local function shouldShowEnchantedNameIcon()
        return getEnchantedIndicatorMode() ~= 'EnchantedIndicatorMode_Swirl'
    end

    local function isFavorited(item)
        return item ~= nil and ctx.favoriteItems[item.id] == true
    end

    local function setFavorited(item, favorited)
        if not item or not item.id then
            return false
        end

        local currentValue = ctx.favoriteItems[item.id] == true
        if currentValue == favorited then
            return currentValue
        end

        if favorited then
            ctx.favoriteItems[item.id] = true
        else
            ctx.favoriteItems[item.id] = nil
        end

        ctx.favoriteRevision = (ctx.favoriteRevision or 0) + 1
        return ctx.favoriteItems[item.id] == true
    end

    local function toggleFavorite(item)
        return setFavorited(item, not isFavorited(item))
    end

    local function hasFavorites()
        for _, isFavorite in pairs(ctx.favoriteItems or {}) do
            if isFavorite then
                return true
            end
        end
        return false
    end

    local function canToggleFavoriteRow(row)
        return self.target == omwself and row and row.item ~= nil and not row.isBartered and not ctx.dragAndDrop.draggingObject
    end

    local function isFavoriteTransferBlocked(row)
        return self.target == omwself and row and row.item ~= nil and not row.isBartered and isFavorited(row.item) and I.UI.getMode() ~= 'Interface'
    end

    local function toggleFavoriteRow(row, rowWidget)
        if not canToggleFavoriteRow(row) then
            return false
        end

        local state = self.itemTable and self.itemTable.layout and self.itemTable.layout.userData.getState and self.itemTable.layout.userData.getState()
        local scrollPos = ctx.focusedScrollable and ctx.focusedScrollable.layout and ctx.focusedScrollable.layout.userData.getScrollPos and ctx.focusedScrollable.layout.userData.getScrollPos() or 0
        if state then
            if state.lastPointerRowPos ~= nil then
                state.lastUsedRowPos = state.lastPointerRowPos
            elseif rowWidget and rowWidget.layout and rowWidget.layout.props then
                state.lastUsedRowPos = rowWidget.layout.props.position - v2(0, scrollPos)
            end
        end

        local wasFavorited = isFavorited(row.item)
        local nowFavorited = toggleFavorite(row.item)
        if wasFavorited and not nowFavorited and not hasFavorites() then
            if self.categoryFilter and self.categoryFilter.layout and self.categoryFilter.layout.userData.getCategory and self.categoryFilter.layout.userData.getCategory() == 'Favorites' then
                self.categoryFilter.layout.userData.setCategory('All')
            end
        end
        ambient.playSound('menu click')
        I.InventoryExtender.update()
        return true
    end

    local iconRenderer = function(row, width, height, options)
        options = options or {}
        local iconDim = math.min(width, height)
        local equipped = helpers.isItemEquipped(row.item, self.target, ctx.overrides.equipped)
        local showEnchantSwirl = row.showAsEnchanted() and shouldShowEnchantedSwirl(options.forceEnchantSwirl) or false
        local bgrVisible = row.isBartered or equipped or showEnchantSwirl
        local magicString = showEnchantSwirl and '_magic' or ''
        local postString = (row.isBartered and '_barter') or (equipped and '_equip') or (magicString ~= '' and '') or '_none'
        local bgrPath = 'textures/menu_icon' .. magicString .. postString .. '.dds'
        return {
            name = 'Icon',
            props = {
                size = v2(width, height),
            },
            content = ui.content {
                {
                    name = 'itemBackground',
                    type = ui.TYPE.Image,
                    props = {
                        resource = baseTemplates.createTexture(bgrPath, v2(40, 40), bgrPath == 'textures/menu_icon_barter.dds' and v2(4, 4) or v2(2, 2)),
                        anchor = v2(0.5, 0.5),
                        relativePosition = v2(0.5, 0.5),
                        size = v2(iconDim, iconDim),
                        visible = bgrVisible,
                    }
                },
                {
                    name = 'itemIcon',
                    type = ui.TYPE.Image,
                    props = {
                        resource = baseTemplates.createTexture(row.itemRecord.icon),
                        anchor = v2(0.5, 0.5),
                        relativePosition = v2(0.5, 0.5),
                        size = v2(iconDim, iconDim),
                    }
                },
            },
            userData = {
                bgrVisible = bgrVisible,
                bgrPath = bgrPath,
            }
        }
    end

    local function getNonDraggedCount(row)
        local nonDraggedCount = row.getCount()
        if self.ctx.dragAndDrop.draggingObject and self.ctx.dragAndDrop.draggingObject.id == row.item.id then
            nonDraggedCount = nonDraggedCount - self.ctx.dragAndDrop.draggingCount
        end

        if I.UI.getMode() == 'Barter' then
            if row.isBartered then
                if self.type == 'Inventory' then
                    nonDraggedCount = (self.ctx.barterState.buying[row.item.id] or {}).count or 0
                else
                    nonDraggedCount = (self.ctx.barterState.selling[row.item.id] or {}).count or 0
                end
            else
                if self.type == 'Inventory' then
                    nonDraggedCount = nonDraggedCount - ((self.ctx.barterState.selling[row.item.id] or {}).count or 0)
                elseif self.type == 'Trade' then
                    nonDraggedCount = nonDraggedCount - ((self.ctx.barterState.buying[row.item.id] or {}).count or 0)
                end
            end
        end

        return nonDraggedCount
    end

    local function getItemBadgeState(row)
        local favorite = isFavorited(row.item)
        local stolen = false

        if configPlayer.tweaks.b_StolenIndicator then
            if self.type == 'Inventory' and self.ctx.stolenItems then
                stolen = self.ctx.stolenItems[row.item.recordId] ~= nil
            elseif self.type == 'Container' and self.ctx.pickpocket and self.ctx.pickpocket.active then
                stolen = true
            end
        end

        return {
            favorite = favorite,
            stolen = stolen,
        }
    end

    local nameRenderer = function(row, width, height)
        local nonDraggedCount = getNonDraggedCount(row)

        local text = helpers.getItemName(row.item) .. (nonDraggedCount > 1 and (' (%s)'):format(helpers.addSeparators(nonDraggedCount)) or '')

        local badgeState = getItemBadgeState(row)
        local enchanted = false
        if row.showAsEnchanted() and shouldShowEnchantedNameIcon() then
            enchanted = true
        end

        local content = ui.content {
            {
                template = baseTemplates.textNormal,
                props = {
                    text = text,
                },
                userData = {
                    colorable = true,
                }
            },
        }
        local iconSize = math.min(specialTemplates.LINE_HEIGHT, 12)
        if badgeState.favorite then
            content:add(baseTemplates.intervalH(8))
            content:add({
                type = ui.TYPE.Image,
                props = {
                    resource = baseTemplates.createTexture(iconPack.getPath('item/favorited.dds')),
                    size = v2(iconSize, iconSize),
                    color = constants.Colors.GOLD,
                },
            })
        end
        if badgeState.stolen then
            content:add(baseTemplates.intervalH(8))
            content:add({
                type = ui.TYPE.Image,
                props = {
                    resource = baseTemplates.createTexture(iconPack.getPath('item/stolen.dds')),
                    size = v2(iconSize, iconSize),
                    color = constants.Colors.DAMAGED,
                },
            })
        end
        if enchanted then
            content:add(baseTemplates.intervalH(8))
            content:add({
                type = ui.TYPE.Image,
                props = {
                    resource = baseTemplates.createTexture(iconPack.getPath('item/enchanted.dds')),
                    size = v2(iconSize, iconSize),
                    color = constants.Colors.BAR_MAGIC,
                },
            })
        end

        return {
            name = 'Name',
            type = ui.TYPE.Flex,
            props = {
                horizontal = true,
                arrange = ui.ALIGNMENT.Center,
                autoSize = false,
                size = v2(width, height),
            },
            content = content,
            userData = {
                text = text,
                favorite = badgeState.favorite,
                stolen = badgeState.stolen,
                enchanted = enchanted,
            }
        }
    end

    local generalColumns = {
        {
            id = 'Icon',
            width = specialTemplates.LINE_HEIGHT * 1.5 + 8,
            renderer = iconRenderer,
            visible = true,
        },
        {
            id = 'Name',
            label = l10n('Column_Name'),
            renderer = nameRenderer,
            visible = true,
        },
        {
            id = 'Type',
            label = l10n('Column_Type'),
            width = 90 * baseTemplates.TEXT_SIZE / 16,
            textAlignH = ui.ALIGNMENT.End,
            visible = true,
        },
        {
            id = 'Weight',
            label = l10n('Column_Weight'),
            width = w,
            textAlignH = ui.ALIGNMENT.End,
            defaultOrder = 'desc',
            visible = true,
        },
        {
            id = 'Weight_Total',
            label = l10n('Column_Weight_Total'),
            width = 70 * baseTemplates.TEXT_SIZE / 16,
            textAlignH = ui.ALIGNMENT.End,
            defaultOrder = 'desc',
            visible = true,
        },
        {
            id = 'Value',
            label = l10n('Column_Value'),
            width = w,
            textAlignH = ui.ALIGNMENT.End,
            defaultOrder = 'desc',
            visible = true,
        },
        {
            id = 'V/W',
            label = l10n('Column_VW'),
            width = w,
            textAlignH = ui.ALIGNMENT.End,
            defaultOrder = 'desc',
            visible = true,
        }
    }
    local conditionColumn = {
        id = 'Condition',
        label = l10n('Column_Condition'),
        width = 55 * baseTemplates.TEXT_SIZE / 16,
        textAlignH = ui.ALIGNMENT.End,
        defaultOrder = 'desc',
        visible = true,
        comparator = function(a, b, sortDir)
            local aValue = helpers.getConditionPercent(a.item)
            local bValue = helpers.getConditionPercent(b.item)

            if aValue == bValue then
                return false
            end
            if aValue == nil then
                return false
            end
            if bValue == nil then
                return true
            end

            if sortDir == 'asc' then
                return aValue < bValue
            end
            return aValue > bValue
        end,
    }
    local noTypeColumns = {
        generalColumns[1],
        generalColumns[2],
        generalColumns[4],
        generalColumns[5],
        generalColumns[6],
        generalColumns[7],
    }
    local armorColumns = {
        generalColumns[1],
        generalColumns[2],
        generalColumns[3],
        {
            id = 'Class',
            label = l10n('Column_Class'),
            width = 60 * baseTemplates.TEXT_SIZE / 16,
            textAlignH = ui.ALIGNMENT.End,
            visible = true,
        },
        {
            id = 'AR',
            label = l10n('Column_AR'),
            width = 50 * baseTemplates.TEXT_SIZE / 16,
            textAlignH = ui.ALIGNMENT.End,
            defaultOrder = 'desc',
            visible = true,
        },
        conditionColumn,
        generalColumns[4],
        generalColumns[5],
        generalColumns[6],
        generalColumns[7],
    }
    local weaponColumns = {
        generalColumns[1],
        generalColumns[2],
        generalColumns[3],
        {
            id = 'Damage',
            label = l10n('Column_Damage'),
            width = 60 * baseTemplates.TEXT_SIZE / 16,
            textAlignH = ui.ALIGNMENT.End,
            defaultOrder = 'desc',
            visible = true,
        },
        conditionColumn,
        generalColumns[4],
        generalColumns[5],
        generalColumns[6],
        generalColumns[7],
    }
    local toolColumns = {
        generalColumns[1],
        generalColumns[2],
        generalColumns[3],
        {
            id = 'Quality',
            label = l10n('Column_Quality'),
            width = 60 * baseTemplates.TEXT_SIZE / 16,
            textAlignH = ui.ALIGNMENT.End,
            defaultOrder = 'desc',
            visible = true,
        },
        conditionColumn,
        generalColumns[4],
        generalColumns[5],
        generalColumns[6],
        generalColumns[7],
    }
    local redundantTypeCategories = {
        Potion = true,
        Ingredient = true,
        Scroll = true,
        Book = true,
        Key = true,
        Misc = true,
    }

    local editableColumns = {
        generalColumns[3],
        weaponColumns[4],
        armorColumns[4],
        armorColumns[5],
        toolColumns[4],
        conditionColumn,
        generalColumns[4],
        generalColumns[5],
        generalColumns[6],
        generalColumns[7],
    }

    local columnProfiles = {
        generalColumns,
        noTypeColumns,
        armorColumns,
        weaponColumns,
        toolColumns,
    }

    local function getColumnVisibility()
        return windowOptionsSection:get(columnVisibilityKey) or {}
    end

    local function isColumnVisible(columnId, visibility)
        visibility = visibility or getColumnVisibility()
        if OptionalColumns[columnId] then
            return visibility[columnId] == true
        end
        return visibility[columnId] ~= false
    end

    local function filterVisibleColumns(columns)
        local visibility = getColumnVisibility()
        local visibleColumns = {}

        for _, column in ipairs(columns) do
            if isColumnVisible(column.id, visibility) then
                table.insert(visibleColumns, column)
            end
        end

        if #visibleColumns == 0 and columns[1] then
            visibleColumns[1] = columns[1]
        end

        return visibleColumns
    end

    local function canHideColumn(columnId)
        local visibility = getColumnVisibility()

        for _, profile in ipairs(columnProfiles) do
            local containsColumn = false
            local visibleCount = 0

            for _, column in ipairs(profile) do
                if isColumnVisible(column.id, visibility) then
                    visibleCount = visibleCount + 1
                end
                if column.id == columnId then
                    containsColumn = true
                end
            end

            if containsColumn and visibleCount <= 1 then
                return false
            end
        end

        return true
    end

    local function getBaseColumnsForCategory(categoryKey)
        if categoryKey == 'Armor' then
            return armorColumns
        elseif categoryKey == 'Weapon' then
            return weaponColumns
        elseif categoryKey == 'Tool' then
            return toolColumns
        elseif redundantTypeCategories[categoryKey] then
            return noTypeColumns
        end

        return generalColumns
    end

    local function getColumnsForCategory(categoryKey)
        return filterVisibleColumns(getBaseColumnsForCategory(categoryKey))
    end

    local function getAvailableCategories()
        local categories = I.InventoryExtender.getCategories()
        local filteredCategories = {}
        for _, category in ipairs(categories) do
            if category.key ~= 'Favorites' or (self.target == omwself and hasFavorites()) then
                table.insert(filteredCategories, category)
            end
        end
        return filteredCategories
    end

    local function getSyncedCategoryKey(categoryKey, targetWindow)
        if categoryKey == 'Favorites' and targetWindow and targetWindow.target ~= omwself then
            return 'All'
        end
        return categoryKey
    end

    local function getCurrentCategoryKey()
        if self.categoryFilter and self.categoryFilter.layout and self.categoryFilter.layout.userData.getCategory then
            return self.categoryFilter.layout.userData.getCategory()
        end

        local categories = getAvailableCategories()
        return categories[1] and categories[1].key or nil
    end

    self.getModeDefaultCategoryKey = function()
        if I.UI.getMode() == 'Interface' then
            return inventoryCategoryKey
        end
        return 'All'
    end

    self.applyColumnVisibility = function(window)
        if not window.itemTable or not window.itemTable.layout or not window.itemTable.layout.userData then
            return
        end

        window.itemTable.layout.userData.setColumns(getColumnsForCategory(getCurrentCategoryKey()), true)
        window.itemTable.layout.userData.refresh()
    end

    local function openColumnSettings()
        local function toggleColumn(columnId, visible)
            local visibility = getColumnVisibility()
            local newVisibility = {}

            for key, value in pairs(visibility) do
                newVisibility[key] = value
            end

            if visible then
                if OptionalColumns[columnId] then
                    newVisibility[columnId] = true
                else
                    newVisibility[columnId] = nil
                end
            else
                newVisibility[columnId] = false
            end

            windowOptionsSection:set(columnVisibilityKey, newVisibility)

            for _, window in pairs(I.InventoryExtender.getWindows()) do
                if window and window.applyColumnVisibility then
                    window:applyColumnVisibility()
                end
            end

            local modal = ColumnSettingsModal.create({
                title = l10n('UI_ColumnSettingsTitle'),
                closeLabel = constants.Strings.OK,
                columns = editableColumns,
                isColumnVisible = function(id)
                    return isColumnVisible(id)
                end,
                canHideColumn = canHideColumn,
                onToggle = toggleColumn,
            }, ctx)
            ctx.modalElement = modal
        end

        local modal = ColumnSettingsModal.create({
            title = l10n('UI_ColumnSettingsTitle'),
            closeLabel = constants.Strings.OK,
            columns = editableColumns,
            isColumnVisible = function(id)
                return isColumnVisible(id)
            end,
            canHideColumn = canHideColumn,
            onToggle = toggleColumn,
        }, ctx)
        ctx.modalElement = modal
    end

    onRowUse = function(row, rowWidget, fromKBMKeybind, forceBarterAction)
        if ctx.dragAndDrop.draggingObject then
            if fromKBMKeybind then
                if rowWidget and rowWidget.layout and rowWidget.layout.props then
                    self.itemTable.layout.userData.getState().lastUsedRowPos = rowWidget.layout.props.position - v2(0, (ctx.focusedScrollable and ctx.focusedScrollable.layout.userData.getScrollPos() or 0))
                end
                ctx.dragAndDrop:stopDrag(self.target)
            end
            return true
        end

        if configPlayer.keybinds.b_SwapUsePickup and not fromKBMKeybind then
            return onRowPickup(row, rowWidget, nil, true)
        end

        for i = #ctx.handlers.onRowUse, 1, -1 do
            local handler = ctx.handlers.onRowUse[i]
            if handler.handler(row, ctx, self.type) == false then
                return false
            end
        end

        if helpers.isBoundItem(row.item) then
            return
        end

        if isFavoriteTransferBlocked(row) then
            ui.showMessage(l10n('UI_Msg_FavoriteItem'))
            return false
        end

        if not rowWidget then
            return
        end

        self.itemTable.layout.userData.getState().lastUsedRowPos = rowWidget.layout.props.position - v2(0, (ctx.focusedScrollable and ctx.focusedScrollable.layout.userData.getScrollPos() or 0))

        local transfer = input.isAltPressed() or I.UI.getMode() == 'Barter'
        local takeAll = input.isShiftPressed() or input.getAxisValue(input.CONTROLLER_AXIS.TriggerRight) > 0.5
        local takeOne = input.isCtrlPressed() or input.getAxisValue(input.CONTROLLER_AXIS.TriggerLeft) > 0.5

        if takeAll and takeOne and not forceBarterAction then
            onRowPickup(row, rowWidget)
            return
        end

        local itemCount = row.getCount()
        if I.UI.getMode() == 'Barter' then
            if row.isBartered then
                if self.type == 'Inventory' then
                    itemCount = (self.ctx.barterState.buying[row.item.id] or {}).count or 0
                else
                    itemCount = (self.ctx.barterState.selling[row.item.id] or {}).count or 0
                end
            else
                if self.type == 'Inventory' then
                    itemCount = itemCount - ((self.ctx.barterState.selling[row.item.id] or {}).count or 0)
                elseif self.type == 'Trade' then
                    itemCount = itemCount - ((self.ctx.barterState.buying[row.item.id] or {}).count or 0)
                end
            end
        end

        local function doAction(count)
            local mode = I.UI.getMode()
            local pickpocket = ctx.pickpocket
            local isPickpocketTake = mode == 'Container' and self.type == 'Container' and pickpocket and pickpocket.active

            if isPickpocketTake then
                local success = Pickpocket.rollTake(omwself, self.target, row.item, row.getCount())
                if not success then
                    pickpocket.resolved = true
                    core.sendGlobalEvent('IE_CommitPickpocket', {
                        player = omwself,
                        target = self.target,
                        victimAware = true,
                    })
                    I.UI.removeMode('Container')
                    return false
                end
            end

            if transfer then
                if mode == 'Container' or mode == 'Companion' then
                    if self.type == 'Inventory' then
                        if ctx.windowArgs[mode] then
                            ctx.dragAndDrop:transferInto(row.item, ctx.windowArgs[mode], omwself, count)
                        end
                    else
                        ctx.dragAndDrop:transferInto(row.item, omwself, self.target, count, isPickpocketTake and { target = self.target } or nil)
                    end
                elseif mode == 'Barter' then
                    if row.isBartered then
                        local table = self.type == 'Inventory' and ctx.barterState.buying or ctx.barterState.selling
                        if table[row.item.id] then
                            table[row.item.id].count = table[row.item.id].count - count
                            if table[row.item.id].count <= 0 then
                                table[row.item.id] = nil
                            end
                        end
                    else
                        local table = self.type == 'Inventory' and ctx.barterState.selling or ctx.barterState.buying
                        table[row.item.id] = table[row.item.id] or { item = row.item, stacks = row.virtualStacks, count = 0 }
                        table[row.item.id].count = math.min(table[row.item.id].count + count, row.getCount())
                    end
                    local sound = helpers.getItemSound(row.item, 'down')
                    if sound then
                        ambient.playSound(sound)
                    end
                    barterUtils.updateOffer(ctx)
                    omwself:sendEvent('IE_Update')
                elseif mode == 'Interface' then
                    if not isFavorited(row.item) then
                        ctx.dragAndDrop:dropAtViewportPosition(row.item, count, v2(0.5, 0.5), true)
                    else
                        ui.showMessage(l10n('UI_Msg_FavoriteItem'))
                    end
                end
            else
                ctx.dragAndDrop:startDrag(
                    row.item,
                    self.target,
                    count,
                    isPickpocketTake and { target = self.target } or nil,
                    {
                        windowType = self.type,
                        isBartered = row.isBartered,
                    }
                )
            end
            return true
        end

        if itemCount > 1 and not takeAll and not takeOne then
            self.itemTable.layout.userData.getState().lastUsedRowPos = nil
            local modal = ItemStackModal.create({
                itemName = row.itemRecord.name,
                maxCount = itemCount,
                onConfirm = function(count)
                    doAction(count)
                end,
            }, ctx)
            ctx.modalElement = modal
        else
            doAction(takeOne and 1 or itemCount)
        end
    end

    self.itemTable = ItemTable.create({
        columns = generalColumns,
        data = data,
        size = v2(600, 400),
        rowHeight = specialTemplates.LINE_HEIGHT * configPlayer.window.f_TableRowHeightMult,
        defaultSortId = 'Icon',
        defaultSortIcon = iconPack.getPath('default_sort.dds'),
        fallbackSort = function(a, b, sortDir)
            if not self.target then
                return false
            end

            if a.isBartered ~= b.isBartered then
                return a.isBartered
            end

            local mode = I.UI.getMode()
            local inBarterMode = mode == 'Barter'

            local aEquipped = helpers.isItemEquipped(a.item, self.target, ctx.overrides.equipped)
            local bEquipped = helpers.isItemEquipped(b.item, self.target, ctx.overrides.equipped)

            local aFavorited = isFavorited(a.item)
            local bFavorited = isFavorited(b.item)

            if inBarterMode then
                local config = helpers.getWindowSettings()
                local reverseEquipped = config:get(constants.OPT_KEYS.SortingBarterReverseEquipped)
                local reverseFavorite = config:get(constants.OPT_KEYS.SortingBarterReverseFavorite)

                if reverseFavorite and not reverseEquipped then
                    -- if only favorites are reversed, prioritize sorting by favorite status
                    if aFavorited ~= bFavorited then
                        -- favorited items come last (true > false)
                        return bFavorited
                    end

                    if aEquipped ~= bEquipped then
                        -- equipped items come first (true > false)
                        return aEquipped
                    end
                else
                    if aEquipped ~= bEquipped then
                        -- equipped items come first (true > false), unless we reverse it
                        if reverseEquipped then return bEquipped else return aEquipped end
                    end

                    if aFavorited ~= bFavorited then
                        -- favorited items come first (true > false), unless we reverse it
                        if reverseFavorite then return bFavorited else return aFavorited end
                    end
                end
            else
                if aEquipped ~= bEquipped then
                    -- equipped items come first (true > false)
                    return aEquipped
                end

                if aFavorited ~= bFavorited then
                    -- favorited items come first (true > false)
                    return aFavorited
                end
            end
            
            -- Second, sort by Category
            local categories = I.InventoryExtender.getCategories()
            local indexA, indexB = nil, nil
            for i, category in ipairs(categories) do
                if category.key ~= 'Favorites' then
                    if category.filter then
                        if category.filter(a.item) then
                            indexA = i
                        end
                        if category.filter(b.item) then
                            indexB = i
                        end
                        if indexA and indexB then
                            break
                        end
                    end
                end
            end
            if indexA ~= indexB then
                if sortDir == 'asc' then
                    return (indexA or math.huge) < (indexB or math.huge)
                else
                    return (indexA or math.huge) > (indexB or math.huge)
                end
            end

            local typeA = (type(a.Type) == 'function' and a.Type() or a.Type or ''):lower()
            local typeB = (type(b.Type) == 'function' and b.Type() or b.Type or ''):lower()
            if typeA ~= typeB then
                return typeA < typeB
            end

            local nameA = (type(a.Name) == "function" and a.Name() or a.Name):lower()
            local nameB = (type(b.Name) == "function" and b.Name() or b.Name):lower()
            if nameA == nameB then
                if a.item.recordId == b.item.recordId then
                    return a.item.id < b.item.id
                end
                return a.item.recordId < b.item.recordId
            end
            return nameA < nameB
        end,
        onRowUse = onRowUse,
        onRowPickup = onRowPickup,
        onFavoriteToggle = function(row, rowWidget)
            return toggleFavoriteRow(row, rowWidget)
        end,
        onKBMRowPickup = function(row, rowWidget)
            return onRowPickup(row, rowWidget, nil, true)
        end,
        onKBMRowUse = function(row, rowWidget)
            return onRowUse(row, rowWidget, true)
        end,
        viewMode = configPlayer.window.s_ItemViewMode,
        gridItemRenderer = function(row, itemSize)
            local base = iconRenderer(row, itemSize, itemSize, {
                forceEnchantSwirl = true,
            })
            local badgeState = getItemBadgeState(row)

            base.content.itemIcon.props.size = v2(itemSize - 8, itemSize - 8)
            base.content.itemBackground.props.visible = true

            local badgeSize = math.max(10, math.floor(itemSize * 0.18))
            local badgeContent = ui.content {}

            if badgeState.favorite then
                badgeContent:add({
                    type = ui.TYPE.Image,
                    props = {
                        resource = baseTemplates.createTexture(iconPack.getPath('item/favorited.dds')),
                        size = v2(badgeSize, badgeSize),
                        color = constants.Colors.GOLD,
                    },
                })
            end

            if badgeState.stolen then
                if #badgeContent > 0 then
                    badgeContent:add(baseTemplates.intervalH(2))
                end
                badgeContent:add({
                    type = ui.TYPE.Image,
                    props = {
                        resource = baseTemplates.createTexture(iconPack.getPath('item/stolen.dds')),
                        size = v2(badgeSize, badgeSize),
                        color = constants.Colors.DAMAGED,
                    },
                })
            end

            if #badgeContent > 0 then
                base.content:add({
                    name = 'itemBadges',
                    type = ui.TYPE.Flex,
                    props = {
                        horizontal = true,
                        position = v2(4, 4),
                        autoSize = true,
                    },
                    content = badgeContent,
                })
            end

            local count = getNonDraggedCount(row)
            if count and count > 1 then
                base.content:add({
                    type = ui.TYPE.Text,
                    template = baseTemplates.textNormal,
                    props = {
                        text = helpers.getCountString(count),
                        anchor = util.vector2(1, 1),
                        relativePosition = util.vector2(1, 1),
                        textColor = constants.Colors.DEFAULT_LIGHT,
                        textShadow = true,
                    }
                })
            end
            base.userData.count = count
            base.userData.favorite = badgeState.favorite
            base.userData.stolen = badgeState.stolen
            base.userData.bgrVisible = true
            return base
        end,
        parentWindow = self,
    }, ctx)

    local function getItemViewMode()
        if self.itemTable and self.itemTable.layout and self.itemTable.layout.userData.getState then
            return self.itemTable.layout.userData.getState().viewMode
        end

        return configPlayer.window.s_ItemViewMode or 'ItemViewMode_Table'
    end

    local function toggleItemViewMode()
        local newMode = getItemViewMode() == 'ItemViewMode_Grid' and 'ItemViewMode_Table' or 'ItemViewMode_Grid'

        playerWindowSettings:set('s_ItemViewMode', newMode)

        for _, window in pairs(I.InventoryExtender.getWindows()) do
            if window and window.itemTable and window.itemTable.layout and window.itemTable.layout.userData and window.itemTable.layout.userData.setViewMode then
                window.itemTable.layout.userData.setViewMode(newMode)
            end
            if window and window.categoryFilter and window.categoryFilter.layout and window.categoryFilter.layout.userData and window.categoryFilter.layout.userData.updateViewModeButton then
                window.categoryFilter.layout.userData.updateViewModeButton()
            end
        end
    end

    self.categoryFilter = CategoryFilter.create({
        maxHeight = 72,
        compact = configPlayer.tweaks.b_CompactCategoryFilter,
        vanillaStyle = configPlayer.tweaks.b_VanillaCategoryIcons,
        getCategories = getAvailableCategories,
        getCategoryDisabledLookup = function()
            if not self.itemTable or not self.itemTable.layout or not self.itemTable.layout.userData.getFilteredRows then
                return {}
            end

            local rows = self.itemTable.layout.userData.getFilteredRows('categoryFilter')
            local categories = getAvailableCategories()
            local disabledLookup = {}

            for _, category in ipairs(categories) do
                disabledLookup[category.key] = category.filter ~= nil
            end

            for _, row in ipairs(rows) do
                for _, category in ipairs(categories) do
                    if category.filter == nil then
                        disabledLookup[category.key] = false
                    elseif disabledLookup[category.key] and category.filter(row.item) then
                        disabledLookup[category.key] = false
                    end
                end
            end

            return disabledLookup
        end,
        onOpenSettings = openColumnSettings,
        onToggleView = toggleItemViewMode,
        getViewMode = getItemViewMode,
    }, function(selectedCategory)
        if I.UI.getMode() == 'Interface' then
            inventoryCategoryKey = selectedCategory
        end
        self.itemTable.layout.userData.setColumns(getColumnsForCategory(selectedCategory), true)
        self:setTitle()

        local categories = getAvailableCategories()
        local category = nil
        for _, cat in ipairs(categories) do
            if cat.key == selectedCategory then
                category = cat
                break
            end
        end

        self.itemTable.layout.userData.setFilter('categoryFilter', function(row)
            if not category or not category.filter then
                return true
            end
            return category.filter(row.item)
        end)

        self.itemTable.layout.userData.getState().lastUsedRowPos = nil

        self.itemTable.layout.userData.resetScroll()
        self:refresh()

        local invert = configPlayer.tweaks.b_InvertCategorySwitching
        local shouldSync = invert and input.isShiftPressed() or not invert and not input.isShiftPressed()
        if shouldSync and not ctx.syncingCategoryFilter then
            ctx.syncingCategoryFilter = true
            for _, window in pairs(I.InventoryExtender.getWindows()) do
                if window ~= self and window:isVisible() and window.categoryFilter then
                    window.categoryFilter.layout.userData.setCategory(getSyncedCategoryKey(selectedCategory, window))
                end
            end
            ctx.syncingCategoryFilter = false
        end
    end, 
    function(searchText)
        self.itemTable.layout.userData.setFilter('searchFilter', function(row)
            if not searchText or searchText == '' then
                return true
            end
            local searchLower = searchText:lower()
            local haystack = row.SearchText or helpers.getItemSearchText(row.item):lower()
            return haystack:find(searchLower, 1, true) ~= nil
        end)

        self:refresh()
    end, ctx)

    self:applyColumnVisibility()

    content:add(self.categoryFilter)

    self.categoryFilterDivider = {
        template = I.MWUI.templates.horizontalLine,
        props = {
            size = v2(0, 2),
            relativeSize = v2(1, 0),
            position = v2(0, self.categoryFilter.layout.props.size.y),
        }
    }
    content:add(self.categoryFilterDivider)

    self.updateSize = function(self)
        if self.element then
            if self.categoryFilter then
                self.categoryFilter.layout.userData.resizeImages(self.element.layout.userData.getInnerSize().x)
            end

            local categoryFilterSize = v2(0, self.categoryFilter and self.categoryFilter.layout.props.size.y or 0)
            local infoBarSize = v2(0, self.infoBar and self.infoBar.layout.props.size.y or 0)
            self.itemTable.layout.props.position = categoryFilterSize
            self.itemTable.layout.userData.resize(self.element.layout.userData.getInnerSize() - categoryFilterSize - infoBarSize)
            if self.infoBar then
                self.infoBar.layout.props.position = categoryFilterSize + v2(0, self.itemTable.layout.props.size.y + 1)
                self.infoBar:update()
            end
            if self.infoBarDivider then
                self.infoBarDivider.props.position = v2(0, self.itemTable.layout.props.size.y + self.itemTable.layout.props.position.y)
            end
            if self.categoryFilterDivider then
                self.categoryFilterDivider.props.position = v2(0, self.categoryFilter.layout.props.size.y)
            end
        end
    end

    content:add(self.itemTable)

    self.infoBar = InfoBar.create({
        maxHeight = specialTemplates.LINE_HEIGHT + 12,
    }, ctx)
    if self.type ~= 'Trade' then
        self.infoBar.layout.userData.addInfoLayout({}, function(layout)
            if not self.target then return {} end
            if self.type == 'Container' and 
                (types.Container.objectIsInstance(self.target) and types.Container.record(self.target).isOrganic)
                or (ctx.pickpocket and ctx.pickpocket.active)
            then 
                return {} 
            end
            layout = {
                name = 'encumbrance',
                type = ui.TYPE.Flex,
                props = {
                    horizontal = true,
                    arrange = ui.ALIGNMENT.Center,
                },
                content = ui.content {
                    {
                        type = ui.TYPE.Image,
                        props = {
                            resource = ui.texture { path = 'icons/weight.dds'},
                            size = v2(16, 16),
                        }
                    },
                    baseTemplates.intervalH(4),
                    specialTemplates.progressBar{
                        size = v2(100, specialTemplates.LINE_HEIGHT + 4),
                        color = constants.Colors.BAR_MAGIC,
                        value = self.target.type.getEncumbrance(self.target),
                        maxValue = self.target.type.getCapacity(self.target),
                    }
                }
            }
            return layout
        end)
    end
    if self.type == 'Inventory' or self.type == 'Trade' then
        self.infoBar.layout.userData.addInfoLayout({}, function(layout)
            if not self.target then return {} end
            local goldAmount
            if self.type == 'Inventory' then
                goldAmount = self.target.type.inventory(self.target):countOf('gold_001')
            else
                goldAmount = self.target.type.getBarterGold(self.target)
            end
            layout = {
                name = 'gold',
                type = ui.TYPE.Flex,
                props = {
                    horizontal = true,
                    arrange = ui.ALIGNMENT.Center,
                },
                content = ui.content {
                    {
                        type = ui.TYPE.Image,
                        props = {
                            resource = ui.texture { path = 'icons/gold.dds'},
                            size = v2(16, 16),
                        }
                    },
                    baseTemplates.intervalH(4),
                    {
                        template = baseTemplates.textNormal,
                        props = {
                            text = helpers.addSeparators(goldAmount),
                        }
                    }
                }
            }
            return layout
        end) 
    end
    if self.type == 'Inventory' then
        self.infoBar.layout.userData.addInfoLayout({}, function(layout)
            if not self.target then return {} end
            layout = {
                name = 'armorRating',
                type = ui.TYPE.Flex,
                props = {
                    horizontal = true,
                    arrange = ui.ALIGNMENT.Center,
                },
                content = ui.content {
                    {
                        type = ui.TYPE.Image,
                        props = {
                            resource = ui.texture { path = 'icons/a/a_cuirass_ebon.dds'},
                            size = v2(16, 16),
                        }
                    },
                    baseTemplates.intervalH(4),
                    {
                        template = baseTemplates.textNormal,
                        props = {
                            text = tostring(math.floor(I.Combat.getArmorRating(self.target))),
                        }
                    }
                }
            }
            return layout
        end)

        self.infoBar.layout.userData.addInfoLayout({ external = { grow = 1, stretch = 1 } })

        self.infoBar.layout.userData.addInfoLayout(specialTemplates.interactive({
            onClick = function()
                local draggedItem = ctx.dragAndDrop.draggingObject
                if not draggedItem then
                    return
                end

                local activationContext = ctx.dragAndDrop.draggingActivationContext or {}
                local result = onRowPickup(createDraggedActivationRow(draggedItem), nil, activationContext.windowType, true)
                if result ~= false then
                    ctx.dragAndDrop:stopDrag()
                    self.infoBar.layout.userData.updateAll()
                    self:refresh()
                end
            end,
            tooltipFn = function()
                local text
                if not configPlayer.keybinds.b_SwapUsePickup then
                    text = l10n('UI_Tooltip_UseButton', { key = input.getKeyName(configPlayer.keybinds.k_UseItem) })
                else
                    text = l10n('UI_Tooltip_UseButton_Swapped')
                end
                return specialTemplates.lineTooltip(text)
            end,
            parent = self.infoBar,
            name = 'use',
        }, baseTemplates.button(core.getGMST('sUse'), nil, 'useButton'), ctx), function(layout)
            layout.props.visible = ctx.dragAndDrop.draggingObject ~= nil
            return layout
        end)

        self.infoBar.layout.userData.addInfoLayout({})
    end

    if self.type == 'Container' or self.type == 'Companion' then
        self.infoBar.layout.userData.addInfoLayout({ external = { grow = 1, stretch = 1 }})

        if self.type == 'Container' then
            self.infoBar.layout.userData.addInfoLayout(specialTemplates.interactive({
                onClick = function()
                    if I.UI.getMode() == 'Container' and ctx.windowArgs.Container then
                        ctx.dragAndDrop:moveAll(self.target, omwself)
                        
                        if persistentCorpses[self.target.recordId] then
                            ui.showMessage(constants.Strings.DISPOSE_CORPSE_FAIL)
                        else
                            core.sendGlobalEvent('IE_DisposeOfCorpse', { target = ctx.windowArgs.Container })
                        end
                        I.UI.removeMode('Container')
                    end
                end,
                parent = self.infoBar,
                name = 'dispose',
            }, baseTemplates.button(constants.Strings.DISPOSE_OF_CORPSE, nil, 'disposeButton'), ctx), function(layout)
                local visible = false
                if ctx.windowArgs.Container then
                    visible = types.Actor.objectIsInstance(ctx.windowArgs.Container) and types.Actor.isDead(ctx.windowArgs.Container)
                end
                layout.props.visible = visible
                return layout
            end)

            self.infoBar.layout.userData.addInfoLayout(specialTemplates.interactive({
                onClick = function()
                    if I.UI.getMode() == 'Container' and ctx.windowArgs.Container then
                        local visibleOnly = input.isShiftPressed()
                        local items = nil

                        if visibleOnly and self.itemTable and self.itemTable.layout and self.itemTable.layout.userData.getFilteredRows then
                            items = {}
                            for _, row in ipairs(self.itemTable.layout.userData.getFilteredRows()) do
                                if row and row.item then
                                    table.insert(items, row.item)
                                end
                            end
                        end

                        if not items or #items > 0 then
                            ctx.dragAndDrop:moveAll(self.target, omwself, items)
                        end

                        if visibleOnly then
                            self:refresh()
                        else
                            I.UI.removeMode('Container')
                        end
                    end
                end,
                tooltipFn = function()
                    return specialTemplates.lineTooltip(l10n('UI_Tooltip_TakeAllButton_Shift'))
                end,
                parent = self.infoBar,
                name = 'takeAll',
            }, baseTemplates.button(constants.Strings.TAKE_ALL, nil, 'takeAllButton'), ctx), function(layout)
                layout.props.visible = not (ctx.pickpocket and ctx.pickpocket.active)
                return layout
            end)
        end

        if self.type == 'Companion' then
            self.infoBar.layout.userData.addInfoLayout({
                template = baseTemplates.textNormal,
                props = {},
            }, function(layout)
                if self.target == nil then return layout end
                local profit = ctx.companionProfit[self.target.id]
                layout.props.text = profit and (constants.Strings.PROFIT_VALUE .. ': ' .. helpers.addSeparators(profit)) or ''
                return layout
            end)
        end
        
        self.infoBar.layout.userData.addInfoLayout(specialTemplates.interactive({
            onClick = function()
                I.UI.removeMode(self.type)
            end,
            parent = self.infoBar,
            name = 'close',
        }, baseTemplates.button(constants.Strings.CLOSE, nil, 'closeButton'), ctx))

        self.infoBar.layout.userData.addInfoLayout({})
    end

    if self.type == 'Trade' then
        self.infoBar.layout.userData.addInfoLayout({
            name = 'barterControls',
            type = ui.TYPE.Flex,
            external = {
                grow = 1,
                stretch = 1,
            },
            props = {
                horizontal = true,
                arrange = ui.ALIGNMENT.Center,
                align = ui.ALIGNMENT.End,
                autoSize = false,
            },
            content = ui.content {
                { external = { grow = 1, stretch = 1 } },
                {
                    name = 'totalBalanceLabel',
                    template = baseTemplates.textNormal,
                    props = {
                        text = l10n('UI_Barter_Gain'),
                    },
                },
                baseTemplates.intervalH(8),
                specialTemplates.interactive({
                    onClick = function()
                        if ctx.barterState.totalBalance == 0 then
                            ctx.barterState.currentBalance = 0
                        end
                        local delta = 1
                        if input.isShiftPressed() then
                            delta = 5
                        end
                        if ctx.barterState.currentBalance < 0 then
                            ctx.barterState.currentBalance = ctx.barterState.currentBalance + delta
                        else
                            ctx.barterState.currentBalance = ctx.barterState.currentBalance - delta
                        end
                        self.infoBar.layout.userData.updateAll()
                    end,
                    --parent = self.infoBar,
                }, baseTemplates.button('-'), ctx),
                baseTemplates.intervalH(4),
                {
                    name = 'totalBalanceBox',
                    template = I.MWUI.templates.box,
                    content = ui.content {
                        {
                            template = I.MWUI.templates.padding,
                            content = ui.content {
                                {
                                    name = 'totalBalanceEdit',
                                    template = baseTemplates.textEditLine,
                                    props = {
                                        size = v2(80, specialTemplates.LINE_HEIGHT),
                                        text = tostring(ctx.barterState.currentBalance),
                                    },
                                    events = {
                                        textChanged = async:callback(function(text, layout)
                                            layout.props.text = text
                                            local num = tonumber(text)
                                            if num then
                                                local previousBalance = ctx.barterState.currentBalance

                                                ctx.barterState.currentBalance = (previousBalance >= 0 and 1 or -1) * math.floor(num)
                                                if ctx.barterState.currentBalance == 0 then
                                                    --ctx.barterState.currentBalance = previousBalance
                                                end

                                                local changed = num ~= math.abs(num)
                                                layout.props.text = tostring(math.abs(num))
                                                if changed then
                                                    self.infoBar.layout.userData.updateAll() 
                                                end
                                            end
                                        end),
                                    },
                                }
                            }
                        }
                    }
                },
                baseTemplates.intervalH(4),
                specialTemplates.interactive({
                    onClick = function()
                        if ctx.barterState.totalBalance == 0 then
                            ctx.barterState.currentBalance = 0
                        end
                        local delta = 1
                        if input.isShiftPressed() then
                            delta = 5
                        end
                        if ctx.barterState.currentBalance < 0 then
                            ctx.barterState.currentBalance = ctx.barterState.currentBalance - delta
                        else
                            ctx.barterState.currentBalance = ctx.barterState.currentBalance + delta
                        end
                        self.infoBar.layout.userData.updateAll()
                    end,
                    --parent = self.infoBar,
                }, baseTemplates.button('+'), ctx),
                baseTemplates.intervalH(4),
                specialTemplates.interactive({
                    onClick = function()
                        ctx.barterState.currentBalance = types.Actor.getBarterGold(self.target)
                        self.infoBar.layout.userData.updateAll()
                    end,
                    --parent = self.infoBar,
                }, baseTemplates.button(l10n('UI_Barter_Max')), ctx),
                { external = { grow = 1, stretch = 1 } },
                specialTemplates.interactive({
                    onClick = function()
                        if ctx.barterState.totalBalance == 0 then
                            ctx.barterState.currentBalance = 0
                        end

                        if not next(ctx.barterState.selling) and not next(ctx.barterState.buying) then
                            ui.showMessage(constants.Strings.BARTER_NO_ITEMS)
                            return
                        end

                        local playerGold = omwself.type.inventory(omwself):countOf('gold_001')
                        if ctx.barterState.currentBalance < 0 and playerGold < math.abs(ctx.barterState.currentBalance) then
                            ui.showMessage(constants.Strings.BARTER_PC_TOO_POOR)
                            return
                        end

                        if ctx.barterState.currentBalance > 0 then
                            local merchantGold = self.target.type.getBarterGold(self.target)
                            if merchantGold < ctx.barterState.currentBalance then
                                ui.showMessage(constants.Strings.BARTER_NPC_TOO_POOR)
                                return
                            end
                        end

                        for _, entry in pairs(ctx.barterState.selling) do
                            if ctx.stolenItems[entry.item.recordId] and ctx.stolenItems[entry.item.recordId][self.target.recordId] then
                                I.UI.setMode(nil)
                                ui.showMessage(string.format(constants.Strings.THATS_MINE, entry.item.type.record(entry.item).name))
                                core.sendGlobalEvent('IE_ConfiscateToOwner', {
                                    item = entry.item,
                                    count = entry.count,
                                    player = omwself,
                                    victim = self.target,
                                    stolenMap = ctx.stolenItems,
                                })
                                return
                            end
                        end

                        local offerAccepted, skillGain = barterUtils.haggle(self.target, ctx.barterState.currentBalance, ctx.barterState.currentMerchantOffer)
                        if types.NPC.objectIsInstance(self.target) then
                            local dispositionDelta = offerAccepted and core.getGMST('iBarterSuccessDisposition') or core.getGMST('iBarterFailDisposition')
                            core.sendGlobalEvent('IE_ModDisposition', {
                                target = self.target,
                                player = omwself,
                                amount = dispositionDelta,
                            })
                        end

                        if not offerAccepted then
                            ui.showMessage(constants.Strings.BARTER_REFUSED)
                            return
                        end

                        core.sendGlobalEvent('IE_FinalizeBarter', {
                            player = omwself,
                            merchant = self.target,
                            barterState = ctx.barterState,
                            skillGain = skillGain,
                        })

                        ambient.playSound('item gold up')
                        ctx.barterState.success = true
                        I.UI.removeMode('Barter')
                    end,
                    parent = self.infoBar,
                }, baseTemplates.button(constants.Strings.OFFER), ctx),
                baseTemplates.intervalH(8),
                specialTemplates.interactive({
                    onClick = function()
                        I.UI.removeMode('Barter')
                    end,
                    parent = self.infoBar,
                }, baseTemplates.button(constants.Strings.CANCEL), ctx),
            }
        }, function(layout)
            if not next(ctx.barterState.selling) and not next(ctx.barterState.buying) then
                ctx.barterState.currentBalance = 0
            end

            if ctx.barterState.currentBalance < 0 then
                layout.content.totalBalanceLabel.props.text = l10n('UI_Barter_Spend')
            else
                layout.content.totalBalanceLabel.props.text = l10n('UI_Barter_Gain')
            end

            layout.content.totalBalanceBox.content[1].content.totalBalanceEdit.props.text = tostring(math.abs(ctx.barterState.currentBalance))
            return layout
        end)
        self.infoBar.layout.userData.addInfoLayout({})
    end

    self.infoBar.layout.userData.updateAll()

    content:add(self.infoBar)
    self.infoBarDivider = {
        template = I.MWUI.templates.horizontalLine,
        props = {
            size = v2(0, 2),
            relativeSize = v2(1, 0),
        },
    }
    content:add(self.infoBarDivider)

    local pinned
    if self.type == 'Inventory' then
        pinned = playerWindowSettings:get('b_InventoryWindowPinned')
    end

    local element = baseTemplates.window(
        helpers.getEquippedName(omwself), 
        content, 
        true, 
        function(layout)
            self:updateSize()
        end,
        pinned,
        ctx)
    self.element = element
    self:loadState()
    self:updateSize()

    self.itemTable.layout.events.mouseRelease = async:callback(function(e)
        if e.button == 1 then
            if ctx.dragAndDrop.draggingObject then
                local restorePos = self.itemTable.layout.userData.getViewportSlotPosAtOffset(e.offset.x, e.offset.y)
                self.itemTable.layout.userData.getState().lastUsedRowPos = restorePos
                ctx.dragAndDrop:stopDrag(self.target)
            end
        end
    end)

    self.itemTable.layout.userData.setFilter('draggedItemFilter', function(row)
        if ctx.dragAndDrop.draggingObject then
            return row.item.id ~= ctx.dragAndDrop.draggingObject.id or row.getCount() > ctx.dragAndDrop.draggingCount
        end
        return true
    end)

    self.itemTable.layout.userData.setFilter('barterFilter', function(row)
        if I.UI.getMode() == 'Barter' then
            if helpers.isGold(row.item) then
                return false
            end
            
            if row.item.type.record(row.item).isKey then
                return false
            end

            local barterNpc = self.ctx.windowArgs.Trade
            if not barterNpc then
                return false
            end
            local services = barterNpc.type.record(barterNpc).servicesOffered

            local canTrade = true
            if services.MagicItems and row.itemRecord.enchant then
                canTrade = true
            else
                for t, serviceName in pairs(constants.TypeToService) do
                    if types[t].objectIsInstance(row.item) then
                        if not services[serviceName] then
                            return false
                        end
                        break
                    end
                end 
            end
        
            if self.type == 'Inventory' then
                if row.isBartered then
                    return self.ctx.barterState.buying[row.item.id] and self.ctx.barterState.buying[row.item.id].count > 0
                end

                local sellingCount = self.ctx.barterState.selling[row.item.id] and self.ctx.barterState.selling[row.item.id].count or 0
                return row.getCount() > sellingCount
            elseif self.type == 'Trade' then
                if self.target.type.hasEquipped(self.target, row.item) then
                    return false
                end

                if row.isBartered then
                    return self.ctx.barterState.selling[row.item.id] and self.ctx.barterState.selling[row.item.id].count > 0
                end

                local buyingCount = self.ctx.barterState.buying[row.item.id] and self.ctx.barterState.buying[row.item.id].count or 0
                return row.getCount() > buyingCount
            end
        else
            return not row.isBartered
        end
    end)

    self.itemTable.layout.userData.setFilter('pickpocketVisibilityFilter', function(row)
        if self.type ~= 'Container' or I.UI.getMode() ~= 'Container' then
            return true
        end

        return Pickpocket.isVisible(ctx.pickpocket, row.item)
    end)

    self:setPinnable()
    if self:isPinnable() and self:isPinned() then
        self:setVisible(true)
    else
        self:setVisible(false)
    end

    return self
end

function Inventory:onControllerButtonPress(id)
    local function clearFocused()
        local state = self.itemTable and self.itemTable.layout and self.itemTable.layout.userData.getState and self.itemTable.layout.userData.getState()
        if state then
            state.lastUsedRowPos = nil
                state.lastPointerRowPos = nil
            if self.ctx.focusedInteractive then
                if self.ctx.focusedInteractive.layout then
                    self.ctx.focusedInteractive.layout.events.focusLoss()
                end
                self.ctx.focusedInteractive = nil 
            end
        end
    end

    if id == input.CONTROLLER_BUTTON.LeftShoulder then
        if self.categoryFilter then
            self.categoryFilter.layout.userData.cycleCategory(-1)
            clearFocused()
            return
        end
    elseif id == input.CONTROLLER_BUTTON.RightShoulder then
        if self.categoryFilter then
            self.categoryFilter.layout.userData.cycleCategory(1)
            clearFocused()
            return
        end
    elseif id == input.CONTROLLER_BUTTON.A then
        if self.ctx.focusedInteractive and self.ctx.focusedInteractive.layout then
            local userData = self.ctx.focusedInteractive.layout.userData
            if userData.onKBMRowPickup then
                userData.onKBMRowPickup()
                return
            end
            if userData.onRowPickup then
                userData.onRowPickup()
                return
            end
            return
        end
    elseif id == input.CONTROLLER_BUTTON.Y then
        if self.ctx.dragAndDrop.draggingObject then
            local state = self.itemTable and self.itemTable.layout and self.itemTable.layout.userData.getState and self.itemTable.layout.userData.getState()
            if state and state.lastPointerRowPos ~= nil then
                state.lastUsedRowPos = state.lastPointerRowPos
            end
            self.ctx.dragAndDrop:stopDrag(self.target)
            return
        end
        if self.ctx.focusedInteractive and self.ctx.focusedInteractive.layout then
            local userData = self.ctx.focusedInteractive.layout.userData
            if userData.onKBMRowUse then
                userData.onKBMRowUse()
                return
            end
            if userData.onRowUse then
                userData.onRowUse()
                return
            end
        end
    end
end

function Inventory:refresh()
    if not self.itemTable then return end
    self.itemTable.layout.userData.refresh()
    if self.categoryFilter and self.categoryFilter.layout and self.categoryFilter.layout.userData.updateCategories then
        self.categoryFilter.layout.userData.updateCategories()
    end
end

function Inventory:createData()
    if not self.target then
        return {}
    end
    
    local function createRowData(item, isBartered, isVirtual)
        local itemStack = isVirtual and item.stacks[1] or item

        if not types.Item.isCarriable(itemStack) then return nil end

        local record = itemStack.type.record(itemStack)
        local value = helpers.getItemValue(itemStack)
        local vw = record.weight > 0 and (value / record.weight) or 0
        local vwPrecision = vw > 10 and 0 or 1
        local getItemCount = function()
            if isVirtual then
                return item.totalCount
            else
                return itemStack.count
            end
        end
        
        local rowData = {
            id = itemStack.id,
            Name = helpers.getItemName(itemStack),
            SearchText = helpers.getItemSearchText(itemStack):lower(),
            Type = function()
                return helpers.getItemTypeLabel(itemStack)
            end,
            Damage = function()
                return helpers.getWeaponDamage(itemStack)
            end,
            Class = function()
                return helpers.getArmorClassLabel(itemStack)
            end,
            AR = function()
                return helpers.getArmorRating(itemStack, omwself)
            end,
            Condition = function()
                return helpers.getConditionPercentLabel(itemStack)
            end,
            Quality = record.quality and helpers.roundToPlaces(record.quality, 3),
            Value = helpers.roundToPlaces(value, 1),
            Weight = helpers.roundToPlaces(record.weight, 2),
            Weight_Total = helpers.roundToPlaces(record.weight * getItemCount(), 2),
            ['V/W'] = helpers.roundToPlaces(vw, vwPrecision),
            item = itemStack,
            itemRecord = record,
            isBartered = isBartered,
            virtualStacks = isVirtual and item.stacks or nil,
            getCount = getItemCount,
            showAsEnchanted = function()
                if record.enchant then
                    return true
                end
                if configPlayer.tweaks.b_FilledGemsAppearEnchanted and types.Item.itemData(itemStack).soul then
                    return true
                end
                return false
            end,
            disabledFn = function()
                if not isBartered and I.UI.getMode() == 'Container' and self.type == 'Inventory' then
                    if self.ctx.windowArgs.Container and types.Container.objectIsInstance(self.ctx.windowArgs.Container) and types.Container.record(self.ctx.windowArgs.Container).isOrganic then
                        return true
                    end
                    return not helpers.doesItemFit(itemStack, self.ctx.windowArgs.Container, 1)
                end
            end,
        }
        
        -- if isBartered then
        --     rowData.activeFn = function() return true end
        -- end
        
        return rowData
    end
    
    local data = {}
    
    -- Add primary inventory
    if self.type ~= 'Trade' then
        for _, item in ipairs(self.target.type.inventory(self.target):getAll()) do
            table.insert(data, createRowData(item, false, false))
        end
    else
        for _, recordId in pairs(helpers.getMerchantItems(self.target)) do
            for _, virtualItem in ipairs(recordId) do
                table.insert(data, createRowData(virtualItem, false, true))
            end
        end 
    end
    
    -- Add bartered items from other inventory
    if I.UI.getMode() == 'Barter' then
        if self.type == 'Trade' then
            for _, item in ipairs(omwself.type.inventory(omwself):getAll()) do
                table.insert(data, createRowData(item, true, false))
            end
        else
            local barterNpc = self.ctx.windowArgs.Trade
            if barterNpc then
                for _, recordId in pairs(helpers.getMerchantItems(barterNpc)) do
                    for _, virtualItem in ipairs(recordId) do
                        table.insert(data, createRowData(virtualItem, true, true))
                    end
                end 
            end
        end
    end
    
    return data
end

function Inventory:updateData()
    if not self.target then return end
    self:setTitle()
    self:setPinnable()
    if self.infoBar then
        self.infoBar.layout.userData.updateAll()
    end

    local function updateCategoryAvailability()
        if self.categoryFilter and self.categoryFilter.layout and self.categoryFilter.layout.userData.updateCategories then
            self.categoryFilter.layout.userData.updateCategories()
        end
    end

    local anyChanges = false
    if I.UI.getMode() == 'Barter' or self.ctx.lastUiMode == 'Barter' then
        anyChanges = true
    end

    local currentAlchemy = omwself.type.stats.skills.alchemy(omwself).base
    if self.trackedAlchemy ~= currentAlchemy then
        anyChanges = true
        self.trackedAlchemy = currentAlchemy
    end

    local currentFavoritesRevision = self.ctx.favoriteRevision or 0
    if self.trackedFavoritesRevision ~= currentFavoritesRevision then
        anyChanges = true
        self.trackedFavoritesRevision = currentFavoritesRevision
    end

    if not self.trackedCounts then
        self.trackedCounts = {}
        anyChanges = true
    end
    local currentItems = self.target.type.inventory(self.target):getAll()

    if not self.itemTable then return end

    local currentItemIds = {}
    for _, item in ipairs(currentItems) do
        currentItemIds[item.id] = true
        if self.trackedCounts[item.id] ~= item.count then
            anyChanges = true
        end
        self.trackedCounts[item.id] = item.count
    end
    
    if not anyChanges then
        for id, _ in pairs(self.trackedCounts) do
            if not currentItemIds[id] then
                anyChanges = true
                self.trackedCounts[id] = nil
            end
        end
    end

    if not anyChanges then
        self.itemTable.layout.userData.refresh()
        updateCategoryAvailability()
        return
    end

    local data = self:createData()
    self.itemTable.layout.userData.updateData(data)
    updateCategoryAvailability()
end

function Inventory:setTitle()
    local title
    if I.UI.getMode() == 'Interface' then
        title = helpers.getEquippedName(omwself)
    else
        local target = self.target or omwself
        title = target.type.record(target).name
    end

    if configPlayer.tweaks.b_CompactCategoryFilter and self.categoryFilter and self.categoryFilter.layout and self.categoryFilter.layout.userData.getCategory then
        local categoryKey = self.categoryFilter.layout.userData.getCategory()
        local category = categoryKey and I.InventoryExtender.getCategory(categoryKey)
        if category and category.name then
            title = title and (title .. ' - ' .. category.name) or category.name
        end
    end

    if title then
        self.element.layout.userData.setTitle(title)
    end
end

function Inventory:setPinnable()
    if not self.element then return end

    local mode = I.UI.getMode()
    if self.type == 'Inventory' and (not mode or mode == 'Interface') then
        self.element.layout.userData.setPinnable(true)
    else
        self.element.layout.userData.setPinnable(false)
    end
end

function Inventory:setVisible(visible)
    if self.categoryFilter then
        self.categoryFilter.layout.userData.clearSearch()
        self.categoryFilter.layout.userData.updateCategories()
    end
    Window.setVisible(self, visible)
end

function Inventory:updateTarget()
    local oldTarget = self.target
    if self.type == 'Inventory' then
        self.target = omwself
    else
        local windowArgs = self.ctx.windowArgs
        if windowArgs and windowArgs[self.type] then
            self.target = windowArgs[self.type]
        else
            self.target = nil
        end
    end

    if oldTarget ~= self.target then
        self.trackedCounts = nil
        self.trackedAlchemy = nil
    end

    if self.itemTable then
        self.itemTable.layout.userData.getState().lastUsedRowPos = nil
    end

    self:updateData()
end

function Inventory:getDimensionsKey()
    if self.type == 'Trade' then
        return 'd_BarterWindowDimensions'
    elseif self.type == 'Container' then
        return 'd_ContainerWindowDimensions'
    elseif self.type == 'Companion' then
        return 'd_CompanionWindowDimensions'
    else
        if I.UI.getMode() == 'Barter' then
            return 'd_InventoryBarterWindowDimensions'
        elseif I.UI.getMode() == 'Container' then
            return 'd_InventoryContainerWindowDimensions'
        elseif I.UI.getMode() == 'Companion' then
            return 'd_InventoryCompanionWindowDimensions'
        else
            return 'd_InventoryWindowDimensions'
        end
    end
end

function Inventory:saveState()
    if not self.element then return end

    local dims = self:getDimensions()
    if not dims then return end

    local storedDims = playerWindowSettings:get(self.stateKey)
    if not storedDims or dims.x ~= storedDims.x or dims.y ~= storedDims.y or dims.w ~= storedDims.w or dims.h ~= storedDims.h then
        playerWindowSettings:set(self.stateKey, dims)
    end
    if self.type == 'Inventory' and self:isPinnable() and playerWindowSettings:get('b_InventoryWindowPinned') ~= self.element.layout.userData.pinned then
        playerWindowSettings:set('b_InventoryWindowPinned', self.element.layout.userData.pinned)
    end
end

function Inventory:loadState()
    if not self.element then return end

    if self.itemTable then
        self.itemTable.layout.userData.setViewMode(configPlayer.window.s_ItemViewMode)
    end
    if self.categoryFilter and self.categoryFilter.layout then
        self.categoryFilter.layout.userData.updateViewModeButton()
        self.categoryFilter.layout.userData.setCategory(self:getModeDefaultCategoryKey())
    end

    self.stateKey = self:getDimensionsKey()
    local dims = playerWindowSettings:get(self.stateKey)
    if not dims then return end

    local currentDims = self:getDimensions()
    if not currentDims or dims.x ~= currentDims.x or dims.y ~= currentDims.y or dims.w ~= currentDims.w or dims.h ~= currentDims.h then
        self:setDimensions(dims)
    end
end

return Inventory