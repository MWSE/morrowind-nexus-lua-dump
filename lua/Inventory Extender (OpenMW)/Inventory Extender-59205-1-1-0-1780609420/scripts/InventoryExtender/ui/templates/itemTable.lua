local ui = require('openmw.ui')
local util = require('openmw.util')
local auxUi = require('openmw_aux.ui')
local input = require('openmw.input')
local async = require('openmw.async')
local omwself = require('openmw.self')

local constants = require('scripts.InventoryExtender.util.constants')
local configPlayer = require('scripts.InventoryExtender.config.player')
local baseTemplates = require('scripts.InventoryExtender.ui.templates.base')
local specialTemplates = require('scripts.InventoryExtender.ui.templates.magic')
local helpers = require("scripts.InventoryExtender.util.helpers")
local iconPack = require('scripts.InventoryExtender.util.iconPack')

local ItemTable = {}

local scrollbarWidth = 24

local function getScrollbarWidth(scrollable)
    if not scrollable then
        return 0
    elseif scrollable.layout.userData.canScroll then
        return scrollbarWidth
    else
        return 0
    end
end

local function setColumnWidths(columns, state, scrollable)
    local contentWidth = math.floor(math.max(0, state.currentSize.x - scrollbarWidth)) -- scrollbarWidth = 16
    local widths = {}
    local fixedWidth = 0
    local flexCount = 0
    
    for i, col in ipairs(columns) do
        if col.visible ~= false then
            if col.width then
                widths[i] = col.width
                fixedWidth = fixedWidth + col.width
            else
                flexCount = flexCount + 1
            end
        end
    end
    
    local remainingWidth = math.max(0, contentWidth - fixedWidth)
    local flexWidth = flexCount > 0 and math.floor(remainingWidth / flexCount) or 0
    
    for i, col in ipairs(columns) do
        if col.visible ~= false and not col.width then
            widths[i] = flexWidth
        end
    end
    
    state.columnWidths = widths
end

local function getEquippedItemsForComparison(item, ctx)
    local mode = helpers.getWindowSettings():get(constants.OPT_KEYS.CompareItemsMode)
    if mode == constants.COMPARISON_OPTS.ALT then
        if not input.isAltPressed() then return nil end
    elseif mode == constants.COMPARISON_OPTS.Always then
        --do nothing - this always should pass
    else
        -- either Never or unknown - skip
        return nil
    end

    local actor = omwself
    local overrides = ctx.overrides.equipped

    if helpers.isItemEquipped(item, actor, overrides) then
        return nil
    end

    local slots = helpers.getEquipmentSlots(item)
    local equipped = helpers.getEquippedItems(slots, actor, overrides)

    if #equipped > 0 then
        return equipped
    else
        return nil
    end
end

-- Default sort comparator
local function compareItems(a, b, field, direction)
    local valA = a[field]
    local valB = b[field]

    if type(valA) == 'function' then valA = valA() end
    if type(valB) == 'function' then valB = valB() end

    if type(valA) == 'string' then valA = valA:lower() end
    if type(valB) == 'string' then valB = valB:lower() end
    
    if valA == nil and valB == nil then return false end
    if valA == nil then return false end
    if valB == nil then return true end
    
    if direction == 'asc' then
        return valA < valB
    else
        return valA > valB
    end
end
ItemTable.create = function(props, ctx)
    local columns = props.columns or {}
    local dataRows = props.data or {}
    local size = props.size or util.vector2(400, 300)
    local rowHeight = props.rowHeight or 30
    local onRowUse = props.onRowUse or props.onRowClick
    local onRowPickup = props.onRowPickup or props.onRowActivate
    local onKBMRowUse = props.onKBMRowUse or props.onKBMRowClick
    local onKBMRowPickup = props.onKBMRowPickup or props.onKBMRowActivate

    -- New props for default sort logic
    local defaultSortId = props.defaultSortId
    local defaultSortIcon = props.defaultSortIcon
    local fallbackSort = props.fallbackSort
    local gridIconSize = props.gridIconSize or 40
    
    local headerHeight = 30
    
    local state = {
        sortedRows = {},      -- List of items after sorting
        sortColIndex = nil,   -- Index of currently sorted column
        sortDir = 'asc',      -- 'asc' or 'desc'
        columns = columns,
        columnWidths = {},
        currentSize = size,   
        filters = {},
        viewMode = props.viewMode or 'ItemViewMode_Table',
        parentWindow = props.parentWindow,
        hadMouseMoveThisFrame = false,
    }

    setColumnWidths(columns, state)
    
    -- Initialize defaults
    for i, col in ipairs(columns) do
        if col.id == defaultSortId then
            state.sortColIndex = i
            break
        end 
    end
    
    for _, item in ipairs(dataRows) do
        table.insert(state.sortedRows, item)
    end
    
    local scrollable
    local updateRows
    local sortRows
    local headerRow
    
    local function resetScroll()
        if scrollable and scrollable.layout.content[1] then
            scrollable.layout.content[1].props.position = util.vector2(0, 0)
        end
    end

    local function getContentWidth()
        return math.floor(math.max(0, state.currentSize.x - getScrollbarWidth(scrollable)))
    end

    local function getViewportSlotPosAtOffset(offsetX, offsetY)
        if not scrollable then
            return nil
        end

        local viewHeight = state.currentSize.y - headerHeight
        local viewY = offsetY - headerHeight
        if viewY < 0 or viewY >= viewHeight then
            return nil
        end

        local contentWidth = getContentWidth()
        if offsetX < 0 or offsetX >= contentWidth then
            return nil
        end

        local scrollPos = scrollable.layout.userData.getScrollPos() or 0
        if state.viewMode == 'ItemViewMode_Grid' then
            local itemsPerRow = math.floor(contentWidth / gridIconSize)
            if itemsPerRow < 1 then itemsPerRow = 1 end

            local itemSize = contentWidth / itemsPerRow
            local slotX = math.floor(offsetX / itemSize) * itemSize
            local slotY = math.floor((viewY + scrollPos) / itemSize) * itemSize - scrollPos
            return util.vector2(slotX, slotY)
        end

        return util.vector2(0, math.floor((viewY + scrollPos) / rowHeight) * rowHeight - scrollPos)
    end

    local function viewportSlotEquals(a, b)
        return a ~= nil and b ~= nil
            and math.abs(a.x - b.x) <= 0.1
            and math.abs(a.y - b.y) <= 0.1
    end
    
    sortRows = function()
        if not state.sortColIndex then return end
        
        local col = columns[state.sortColIndex]
        local field = col.id
        local isDefaultCol = (col.id == defaultSortId)
        
        table.sort(state.sortedRows, function(a, b)
            if isDefaultCol and fallbackSort then
                return fallbackSort(a, b, state.sortDir)
            end

            local result
            local areEqual = false
            
            if col.comparator then
                if col.comparator(a, b, state.sortDir) then return true end
                if col.comparator(b, a, state.sortDir) then return false end
                areEqual = true
            else
                local valA = a[field]
                local valB = b[field]
                
                if type(valA) == 'function' then valA = valA() end
                if type(valB) == 'function' then valB = valB() end
                
                if valA == valB then 
                    areEqual = true 
                else
                    result = compareItems(a, b, field, state.sortDir)
                end
            end

            -- Use fallbackSort as tiebreaker
            if areEqual and fallbackSort then
                return fallbackSort(a, b, state.sortDir)
            end
            
            return result
        end)
    end

    state.rowCache = {} -- Stores generated row layouts by item ID or index

    local function applyCellContentModifiers(cellContent, row)
        if ctx and ctx.modifiers and ctx.modifiers.cellContent then
            for _, modifier in ipairs(ctx.modifiers.cellContent) do
                cellContent = modifier.modifier(cellContent, row, ctx, props.parentWindow.type) or cellContent
            end
        end
        return cellContent
    end

    local function normalizeWidgetContent(rendered, row)
        if not rendered then return ui.content {} end
        if rendered[1] then
            local content = ui.content {}
            for _, entry in ipairs(rendered) do
                content:add(applyCellContentModifiers(entry, row))
            end
            return content
        end
        return ui.content { applyCellContentModifiers(rendered, row) }
    end
    
    local function createContent(row)
        local cells = ui.content {}

        local totalW = 0
        for cIdx, col in ipairs(columns) do
            local w = state.columnWidths[cIdx] or 0
            local cellContent

            if col.renderer then
                cellContent = col.renderer(row, w, rowHeight)
            else
                local val = row[col.id]
                if type(val) == 'function' then
                    val = val()
                end
                if type(val) == 'number' then val = helpers.addSeparators(val) end
                local textStr = val ~= nil and tostring(val) or ""
                if textStr == "0" or textStr == "" then textStr = "-" end
                cellContent = {
                    name = col.id,
                    template = baseTemplates.textNormal,
                    props = {
                        text = textStr,
                        size = util.vector2(w, rowHeight),
                        textAlignH = col.textAlignH or ui.ALIGNMENT.Start,
                        textAlignV = ui.ALIGNMENT.Center,
                        autoSize = false,
                    },
                    userData = {
                        colorable = true,
                    }
                }
            end
            cellContent.props.position = util.vector2(totalW, 0)
            totalW = totalW + w

            cellContent = applyCellContentModifiers(cellContent, row)

            cells:add(cellContent)
        end

        return cells
    end

    local function renderVisibleRows(forceRedraw)
        if not scrollable then return end

        local contentLayer = scrollable.layout.content[1]
        contentLayer.type = ui.TYPE.Widget
        contentLayer.props.autoSize = nil
        local viewHeight = state.currentSize.y - headerHeight
        local contentWidth = getContentWidth()

        -- Grid calculations
        local isGrid = state.viewMode == 'ItemViewMode_Grid'
        local gridItemRenderer = props.gridItemRenderer
        local baseItemSize = gridIconSize
        local itemSize = baseItemSize
        local itemsPerRow = 1
        local effectiveRowHeight = rowHeight

        if isGrid then
            itemsPerRow = math.floor(contentWidth / baseItemSize)
            if itemsPerRow < 1 then itemsPerRow = 1 end
            -- Distribute remaining space
            itemSize = contentWidth / itemsPerRow
            effectiveRowHeight = itemSize
        end

        scrollable.layout.userData.setScrollStep(isGrid and itemSize or rowHeight * configPlayer.window.i_TableScrollStep)

        -- Virtualization mathematics
        -- contentLayer.props.position.y is negative when scrolled down
        local scrollY = -contentLayer.props.position.y
        local startRowIndex = math.floor(scrollY / effectiveRowHeight)
        local visibleRowCount = math.ceil(viewHeight / effectiveRowHeight)
        
        -- Add buffer to render slightly outside viewport for smoothness
        local buffer = 1
        -- Calculate index range
        local indexFrom, indexTo
        if isGrid then
            indexFrom = math.max(1, (startRowIndex - buffer) * itemsPerRow + 1)
            local endRowIndex = startRowIndex + visibleRowCount + buffer
            indexTo = math.min(#state.sortedRows, endRowIndex * itemsPerRow)
        else
            indexFrom = math.max(1, startRowIndex + 1 - buffer)
            indexTo = math.min(#state.sortedRows, startRowIndex + visibleRowCount + buffer)
        end

        local pendingFocusRestorePos = nil
        local restoredFocus = false
        local hoveredViewportPos = nil
        local scrollPos = scrollable.layout.userData.getScrollPos() or 0
        if state.parentWindow:isFocused() and not scrollable.layout.userData.isDraggingScrollBar then
            hoveredViewportPos = state.isPointerOverContent and state.lastPointerRowPos or nil
            if state.lastUsedRowPos then
                pendingFocusRestorePos = state.lastUsedRowPos
                hoveredViewportPos = pendingFocusRestorePos
                state.lastUsedRowPos = nil
            end
        end
        
        local newRowElements = {}

        local currentContent = contentLayer.content
        local k = 1

        for i = indexFrom, indexTo do
            local row = state.sortedRows[i]
            if row then
                local cacheKey = row.id
                
                local anyChanged = false
                local active = false
                local disabled = false
                if row.activeFn then
                    active = row.activeFn(row)
                end
                if row.disabledFn then
                    disabled = row.disabledFn(row)
                end
                if (not state.rowCache[cacheKey]) or forceRedraw then
                    local widgetContent
                    if state.rowCache[cacheKey] then
                        auxUi.deepDestroy(state.rowCache[cacheKey])
                    end
                    if isGrid then
                        if gridItemRenderer then
                            widgetContent = normalizeWidgetContent(gridItemRenderer(row, itemSize), row)
                        else
                            local iconPath = row.icon
                            if not iconPath and row.item then
                                iconPath = row.item.type.record(row.item).icon
                            end
                            if not iconPath then iconPath = 'icons/default icon.dds' end

                            local count = row.count
                            if not count and row.item then count = row.item.count end
                            
                            local iconContent = ui.content {
                                {
                                    type = ui.TYPE.Image,
                                    props = {
                                        resource = baseTemplates.createTexture(iconPath),
                                        size = util.vector2(itemSize - 8, itemSize - 8),
                                        relativePosition = util.vector2(0.5, 0.5),
                                        anchor = util.vector2(0.5, 0.5),
                                    },
                                }
                            }
                            
                            if count and count > 1 then
                                iconContent:add({
                                    type = ui.TYPE.Text,
                                    template = baseTemplates.textNormal,
                                    props = {
                                        text = tostring(count),
                                        textSize = 12,
                                        anchor = util.vector2(1, 1),
                                        relativePosition = util.vector2(0.9, 0.9), -- slightly padded
                                        textColor = constants.Colors.DEFAULT_LIGHT,
                                    }
                                })
                            end
                            widgetContent = iconContent
                        end
                    else
                        widgetContent = createContent(row)
                    end

                    local function getCurrentRow()
                        local rowWidget = state.rowCache[cacheKey]
                        if rowWidget and rowWidget.layout and rowWidget.layout.userData then
                            return rowWidget.layout.userData.row
                        end
                        return row
                    end

                    state.rowCache[cacheKey] = specialTemplates.interactive({
                        canClick = function()
                            for _, button in pairs(input.CONTROLLER_BUTTON) do
                                if input.isControllerButtonPressed(button) then
                                    return false
                                end
                            end
                            return true
                        end,
                        onClick = function()
                            local currentRow = getCurrentRow()
                            if onRowUse then 
                                return onRowUse(currentRow, state.rowCache[cacheKey]) 
                            end
                        end,
                        onMouseMove = function()
                            state.hadMouseMoveThisFrame = true
                            if not scrollable.layout.userData.isDraggingScrollBar then
                                if state.rowCache[cacheKey] then
                                    local currentScrollPos = scrollable.layout.userData.getScrollPos() or 0
                                    state.isPointerOverContent = true
                                    state.lastPointerRowPos = util.vector2(
                                        state.rowCache[cacheKey].layout.props.position.x,
                                        state.rowCache[cacheKey].layout.props.position.y - currentScrollPos
                                    )
                                end
                            end
                        end,
                        tooltipFn = function()
                            local currentRow = getCurrentRow()
                            if currentRow and currentRow.item then
                                local item = currentRow.item
                                local comparison = getEquippedItemsForComparison(item, ctx)
                                if comparison then
                                    return specialTemplates.compareItemsTooltip(item, comparison, false, ctx)
                                else
                                    return specialTemplates.itemTooltip(item, false, ctx)
                                end
                            elseif currentRow and currentRow.tooltip then
                                return specialTemplates.lineTooltip(currentRow.tooltip)
                            end
                            return nil
                        end,
                        name = row.item and row.item.id or 'item',
                    }, {
                        props = {
                            size = util.vector2(isGrid and itemSize or contentWidth, isGrid and itemSize or rowHeight),
                            position = util.vector2(0, 0),
                        },
                        content = widgetContent,
                        userData = { 
                            row = row,
                            onRowPickup = function()
                                local currentRow = getCurrentRow()
                                if onRowPickup then
                                    return onRowPickup(currentRow, state.rowCache[cacheKey])
                                end
                            end,
                            onKBMRowPickup = function()
                                local currentRow = getCurrentRow()
                                if onKBMRowPickup then
                                    return onKBMRowPickup(currentRow, state.rowCache[cacheKey])
                                elseif onRowPickup then
                                    return onRowPickup(currentRow, state.rowCache[cacheKey])
                                end
                            end,
                            onKBMRowUse = function()
                                local currentRow = getCurrentRow()
                                if onKBMRowUse then
                                    return onKBMRowUse(currentRow, state.rowCache[cacheKey])
                                elseif onRowUse then
                                    return onRowUse(currentRow, state.rowCache[cacheKey])
                                end
                            end,
                            onRowUse = function()
                                local currentRow = getCurrentRow()
                                if onRowUse then 
                                    return onRowUse(currentRow, state.rowCache[cacheKey]) 
                                end
                            end,
                            onRowActivate = function()
                                local currentRow = getCurrentRow()
                                if onRowPickup then
                                    return onRowPickup(currentRow, state.rowCache[cacheKey])
                                end
                            end,
                            onKBMRowActivate = function()
                                local currentRow = getCurrentRow()
                                if onKBMRowPickup then
                                    return onKBMRowPickup(currentRow, state.rowCache[cacheKey])
                                elseif onRowPickup then
                                    return onRowPickup(currentRow, state.rowCache[cacheKey])
                                end
                            end,
                            onKBMRowClick = function()
                                local currentRow = getCurrentRow()
                                if onKBMRowUse then
                                    return onKBMRowUse(currentRow, state.rowCache[cacheKey])
                                elseif onRowUse then
                                    return onRowUse(currentRow, state.rowCache[cacheKey])
                                end
                            end,
                            onRowClick = function()
                                local currentRow = getCurrentRow()
                                if onRowUse then
                                    return onRowUse(currentRow, state.rowCache[cacheKey])
                                end
                            end,
                            onFavoriteToggle = function()
                                if props.onFavoriteToggle and state.rowCache[cacheKey] and state.rowCache[cacheKey].layout and state.rowCache[cacheKey].layout.userData then
                                    return props.onFavoriteToggle(state.rowCache[cacheKey].layout.userData.row, state.rowCache[cacheKey])
                                end
                            end,
                            active = active,
                            disabled = disabled,
                            lastGridSize = isGrid and itemSize or nil,
                        }
                    }, ctx)
                    helpers.setInteractiveColor(state.rowCache[cacheKey].layout)
                else
                    if isGrid then
                        local rowWidget = state.rowCache[cacheKey]
                        if gridItemRenderer then
                            local lastSize = rowWidget.layout.userData.lastGridSize or 0

                            local newContent = normalizeWidgetContent(gridItemRenderer(row, itemSize), row)

                            local userDataChanged = false
                            local currentContent = rowWidget.layout.content
                            local u1 = currentContent and currentContent[1] and currentContent[1].userData
                            local u2 = newContent[1] and newContent[1].userData
                            
                            if u1 and u2 then
                                userDataChanged = not helpers.mapEquals(u1, u2)
                            elseif u1 ~= u2 then
                                userDataChanged = true
                            end

                            if math.abs(lastSize - itemSize) > 0.1 or userDataChanged then
                                rowWidget.layout.content = newContent
                                rowWidget.layout.userData.lastGridSize = itemSize
                                anyChanged = true
                            end
                        else
                            local icon = rowWidget.layout.content[1]
                            local currentIconSize = icon.props.size and icon.props.size.x or 0
                            local newIconSize = itemSize - 8
                            if math.abs(currentIconSize - newIconSize) > 0.1 then
                                icon.props.size = util.vector2(newIconSize, newIconSize)
                                anyChanged = true
                            end
                        end
                    else
                        local totalW = 0
                        for cIdx, col in ipairs(columns) do
                            local w = state.columnWidths[cIdx] or 0
                            local rowWidget = state.rowCache[cacheKey]
                            local cellContent = rowWidget.layout.content[cIdx]

                            if cellContent then
                                if col.renderer then
                                    local newCellContent = applyCellContentModifiers(col.renderer(row, w, rowHeight), row)
                                    if cellContent.userData and newCellContent.userData and not helpers.mapEquals(cellContent.userData, newCellContent.userData) then
                                        rowWidget.layout.content[cIdx] = newCellContent
                                        cellContent = newCellContent
                                        anyChanged = true
                                    end
                                end

                                cellContent.props.size = util.vector2(w, rowHeight)
                                cellContent.props.position = util.vector2(totalW, 0)
                                if cellContent.props.text then
                                    local val = row[col.id]
                                    if type(val) == 'function' then
                                        val = val()
                                    end
                                    if type(val) == 'number' then val = helpers.addSeparators(val) end
                                    local textStr = val ~= nil and tostring(val) or ""
                                    if textStr == "0" or textStr == "" then textStr = "-" end
                                    if textStr ~= cellContent.props.text then
                                        cellContent.props.text = textStr
                                        anyChanged = true
                                    end
                                end
                            end
                            totalW = totalW + w
                        end
                    end
                end

                local rowWidget = state.rowCache[cacheKey]
                rowWidget.layout.userData.row = row
                
                local targetX = 0
                local targetY = 0
                
                if isGrid then
                    local gridIndex = i - 1
                    local gridRow = math.floor(gridIndex / itemsPerRow)
                    local gridCol = gridIndex % itemsPerRow
                    targetX = gridCol * itemSize
                    targetY = gridRow * itemSize
                else
                    targetY = (i - 1) * rowHeight
                end

                local targetW = isGrid and itemSize or contentWidth
                local targetH = isGrid and itemSize or rowHeight
               
                local targetViewportPos = util.vector2(targetX, targetY - scrollPos)

                local isHoveredRow = viewportSlotEquals(hoveredViewportPos, targetViewportPos)
                if pendingFocusRestorePos ~= nil and isHoveredRow and not restoredFocus then
                    restoredFocus = true
                    ctx.focusedInteractive = rowWidget
                end

                if rowWidget.layout.userData.hovering ~= isHoveredRow then
                    rowWidget.layout.userData.hovering = isHoveredRow
                    anyChanged = true
                end

                if math.abs(rowWidget.layout.props.size.x - targetW) > 0.1
                    or math.abs(rowWidget.layout.props.position.y - targetY) > 0.1
                    or math.abs(rowWidget.layout.props.position.x - targetX) > 0.1
                    or rowWidget.layout.userData.active ~= active
                    or rowWidget.layout.userData.disabled ~= disabled
                    or anyChanged then
                    
                    rowWidget.layout.props.size = util.vector2(targetW, targetH)
                    rowWidget.layout.props.position = util.vector2(targetX, targetY)
                    rowWidget.layout.userData.active = active
                    rowWidget.layout.userData.disabled = disabled
                    
                    helpers.setInteractiveColor(rowWidget.layout)
                    
                    rowWidget:update()
                end

                if currentContent[k] ~= rowWidget then
                    currentContent[k] = rowWidget
                end
                k = k + 1
            end
        end

        while k <= #currentContent do
            currentContent[k] = nil
            k = k + 1
        end

        for i = 1, #currentContent do
            newRowElements[i] = currentContent[i]
        end

        contentLayer.content = ui.content(newRowElements)
        scrollable:update()
    end
    
    updateRows = function(forceRedraw)
        if not scrollable then return end
        
        local viewHeight = state.currentSize.y - headerHeight
        local contentWidth = getContentWidth()
        
        local totalHeight
        if state.viewMode == 'ItemViewMode_Grid' then
            local baseItemSize = gridIconSize
            local cols = math.floor(contentWidth / baseItemSize)
            if cols < 1 then cols = 1 end
            local itemSize = contentWidth / cols
            local rows = math.ceil(#state.sortedRows / cols)
            totalHeight = math.floor(math.max(rows * itemSize, viewHeight))
        else
            totalHeight = math.floor(math.max(#state.sortedRows * rowHeight, viewHeight))
        end
        
        renderVisibleRows(forceRedraw)

        scrollable.layout.userData.update(
            util.vector2(state.currentSize.x, viewHeight), 
            util.vector2(state.currentSize.x - getScrollbarWidth(scrollable), totalHeight)
        )
    end

    local function updateHeader()
        local contentWidth = getContentWidth()
        headerRow.props.size = util.vector2(contentWidth, headerHeight)

        for i, headerCell in ipairs(headerRow.content) do
            local col = columns[i]
            local isDefaultCol = (col.id == defaultSortId)
            local isSorted = (state.sortColIndex == i)
            local currentSortIcon = state.sortDir == 'asc' and iconPack.getPath('sort_asc.dds') or iconPack.getPath('sort_desc.dds')

            if isDefaultCol and defaultSortIcon then
                -- Show only sort arrow for default column
                headerCell.layout.content.icon.props.resource = baseTemplates.createTexture(isSorted and currentSortIcon or defaultSortIcon)
            else
                local icon = headerCell.layout.content.sortIcon
                icon.props.resource = baseTemplates.createTexture(currentSortIcon)
                icon.props.size = isSorted and util.vector2(16, 16) or util.vector2(0, 0)
            end

            local w = state.columnWidths[i] or 0
            headerCell.layout.props.size = util.vector2(w, headerHeight)
            headerCell:update()
        end
        if not headerRow then return end
        local contentWidth = getContentWidth()
        headerRow.props.size = util.vector2(contentWidth, headerHeight)
    end

    local function createHeader()
        local headerElements = {}
        for i, col in ipairs(columns) do
            local w = state.columnWidths[i] or 0
            local title = col.label or col.id
            local isDefaultCol = (col.id == defaultSortId)
            
            local headerWidget
            
            if isDefaultCol and defaultSortIcon then
                headerWidget = {
                    type = ui.TYPE.Flex,
                    props = {
                        size = util.vector2(w, headerHeight),
                        horizontal = true,
                        align = ui.ALIGNMENT.Center,
                        arrange = ui.ALIGNMENT.Center,
                    },
                    content = ui.content({
                        {
                            name = 'icon',
                            type = ui.TYPE.Image,
                            props = {
                                color = constants.Colors.DEFAULT,
                                resource = baseTemplates.createTexture(defaultSortIcon),
                                size = util.vector2(16, 16),
                            }
                        }
                    }),
                }
            else
                headerWidget = {
                    type = ui.TYPE.Flex,
                    --template = baseTemplates.textHeader,
                    props = {
                        horizontal = true,
                        size = util.vector2(w, headerHeight),
                        autoSize = false,
                        align = col.textAlignH or ui.ALIGNMENT.Start,
                        arrange = ui.ALIGNMENT.Center,
                    },
                    content = ui.content {
                        {
                            name = 'title',
                            template = baseTemplates.textHeader,
                            props = {
                                text = title,
                                autoSize = true,
                                textAlignV = ui.ALIGNMENT.Center,
                            },
                        },
                        {
                            name = 'sortIcon',
                            type = ui.TYPE.Image,
                            props = {
                                resource = baseTemplates.createTexture('white'),
                                color = constants.Colors.DEFAULT,
                                size = util.vector2(0, 0),
                            }
                        }
                    }
                }
            end
            
            local btn = specialTemplates.interactive({
                onClick = function()
                    local defaultDir = col.defaultOrder or 'asc'
                    if state.sortColIndex == i then
                        state.sortDir = (state.sortDir == 'asc') and 'desc' or 'asc'
                    else
                        state.sortColIndex = i
                        state.sortDir = defaultDir
                    end
                    
                    sortRows()
                    
                    resetScroll()
                    
                    updateHeader()
                    updateRows()
                end
            }, headerWidget, ctx)
            table.insert(headerElements, btn)
        end
        
        if headerRow then
            auxUi.deepDestroy(headerRow)
        end
        headerRow = {
            type = ui.TYPE.Flex,
            props = {
                horizontal = true,
                size = util.vector2(getContentWidth(), headerHeight),
            },
            content = ui.content(headerElements)
        }
    end

    local dummyContent = ui.content({}) 
    local totalY = #state.sortedRows * rowHeight
    local flexSize = util.vector2(getContentWidth(), totalY)
    
    scrollable = baseTemplates.scrollable(
        util.vector2(size.x, size.y - headerHeight),
        dummyContent,
        flexSize,
        0,
        0,
        rowHeight * 2,
        false,
        function(e)
            ctx.focusedScrollable = e
        end,
        function()
            ctx.focusedScrollable = nil
        end,
        0,
        'itemTable_Scroll'
    )
    
    local originalOnScroll = scrollable.layout.userData.onScroll
    scrollable.layout.userData.onScroll = function()
        originalOnScroll()
        renderVisibleRows()
    end
    
    createHeader()
    sortRows()
    updateRows()

    local wrapper = ui.create {
        name = 'itemTable',
        type = ui.TYPE.Flex, 
        props = {
            size = size,
        },
        content = ui.content {
            headerRow,
            scrollable
        },
        userData = {},
        events = {},
    }
    
    wrapper.layout.userData.resize = function(newSize)
        state.currentSize = newSize
        setColumnWidths(columns, state)
        wrapper.layout.props.size = newSize
        updateHeader()
        updateRows()
        wrapper:update()
    end

    wrapper.layout.userData.setFilter = function(filterId, filterFn)
        state.filters[filterId] = filterFn
    end

    wrapper.layout.userData.setViewMode = function(mode)
        if state.viewMode == mode then return end
        state.viewMode = mode
        -- Clear cache
        for k, v in pairs(state.rowCache) do
            auxUi.deepDestroy(v)
        end
        state.rowCache = {}
        
        updateRows()
        wrapper:update()
    end

    wrapper.layout.userData.resetScroll = resetScroll

    wrapper.layout.userData.getViewportSlotPosAtOffset = getViewportSlotPosAtOffset

    wrapper.layout.events.mouseMove = async:callback(function(e)
        state.hadMouseMoveThisFrame = true
        if not scrollable.layout.userData.isDraggingScrollBar then
            state.lastPointerRowPos = getViewportSlotPosAtOffset(e.offset.x, e.offset.y)
            state.isPointerOverContent = state.lastPointerRowPos ~= nil
        end
        return true
    end)

    local function getFilteredRows(excludedFilterId)
        local filteredRows = {}
        for _, row in ipairs(dataRows) do
            local include = true
            for filterId, filterFn in pairs(state.filters) do
                if filterId ~= excludedFilterId and not filterFn(row) then
                    include = false
                    break
                end
            end
            if include then
                table.insert(filteredRows, row)
            end
        end

        return filteredRows
    end

    wrapper.layout.userData.refresh = function()
        -- Re-apply filters
        state.sortedRows = getFilteredRows()

        sortRows()
        updateRows()
    end
    
    wrapper.layout.userData.updateData = function(newDataRows)
        -- Create a map of old items by ID for quick lookup
        local oldItemsMap = {}
        for _, row in ipairs(dataRows) do
            local itemId = row.item and row.item.id or row.id
            if itemId then
                oldItemsMap[itemId] = row
            end
        end
        
        -- Create a map of new items by ID
        local newItemsMap = {}
        for _, row in ipairs(newDataRows) do
            local itemId = row.item and row.item.id or row.id
            if itemId then
                newItemsMap[itemId] = row
            end
            if row.virtualStacks then
                state.rowCache[row.id] = nil
            end
        end
        
        -- Remove cache entries for items no longer present
        for itemId, row in pairs(oldItemsMap) do
            if not newItemsMap[itemId] and state.rowCache[row.id] then
                auxUi.deepDestroy(state.rowCache[row.id])
                state.rowCache[row.id] = nil
            end
        end
        
        -- Update the dataRows reference
        dataRows = newDataRows
        
        wrapper.layout.userData.refresh()
    end

    wrapper.layout.userData.getState = function()
        return state
    end

    wrapper.layout.userData.getFilteredRows = getFilteredRows

    wrapper.layout.userData.setColumns = function(newColumns, deferRedraw)
        if not newColumns or helpers.tableEquals(columns, newColumns) then
            return
        end

        local currentSortId = state.sortColIndex and columns[state.sortColIndex] and columns[state.sortColIndex].id or nil

        columns = newColumns
        state.columns = newColumns
        setColumnWidths(columns, state)

        state.sortColIndex = nil
        if currentSortId then
            for i, col in ipairs(columns) do
                if col.id == currentSortId then
                    state.sortColIndex = i
                    break
                end
            end
        end
        if not state.sortColIndex then
            for i, col in ipairs(columns) do
                if col.id == defaultSortId then
                    state.sortColIndex = i
                    state.sortDir = col.defaultOrder or 'asc'
                    break
                end
            end
        end

        for key, rowWidget in pairs(state.rowCache) do
            auxUi.deepDestroy(rowWidget)
            state.rowCache[key] = nil
        end

        createHeader()
        updateHeader()
        wrapper.layout.content[1] = headerRow

        if deferRedraw then
            wrapper:update()
            return
        end

        sortRows()
        updateRows(true)
        wrapper:update()
    end

    -- Use this after editing state.columns directly
    wrapper.layout.userData.redrawColumns = function()
        setColumnWidths(state.columns, state)
        createHeader()
        updateHeader()
        wrapper.layout.content[1] = headerRow
        updateRows(true)
        wrapper:update()
    end

    return wrapper
end

return ItemTable