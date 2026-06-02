local async = require('openmw.async')
local core = require('openmw.core')
local I = require('openmw.interfaces')
local input = require('openmw.input')
local storage = require('openmw.storage')
local ui = require('openmw.ui')
local util = require('openmw.util')

local omwConstants = require('scripts.omw.mwui.constants')

local v2 = util.vector2
local l10n = core.l10n('ItemBrowser')

local M = {}

local GENERAL_SECTION = 'Settings/ItemBrowser/1_General'
local DISPLAY_SECTION = 'Settings/ItemBrowser/2_Display'
local BROWSER_MODE = 'Journal'
local VISIBLE_ROWS = 20
local WHEEL_STEP = 2
local MAIN_PANEL_PADDING = 8
local FILTER_PANEL_CONTENT_WIDTH = 150
local FILTER_PANEL_WIDTH = FILTER_PANEL_CONTENT_WIDTH + MAIN_PANEL_PADDING * 2
local RESULT_LIST_CONTENT_WIDTH = 380
local RESULT_LIST_WIDTH = RESULT_LIST_CONTENT_WIDTH + MAIN_PANEL_PADDING * 2
local RESULT_ROWS_WIDTH = 358
local DETAIL_PANEL_CONTENT_WIDTH = 460
local DETAIL_PANEL_WIDTH = DETAIL_PANEL_CONTENT_WIDTH + MAIN_PANEL_PADDING * 2
local DETAIL_TEXT_WIDTH = 450
local RESULT_PANEL_HEIGHT = 481
local RESULT_ROWS_HEIGHT = 481 - MAIN_PANEL_PADDING * 2
local RESULT_ROW_HEIGHT = 22
local RESULT_ROW_TEXT_SIZE = omwConstants.textNormalSize
local RESULT_ROW_SPACING = 1
local LEFT_PANEL_WIDTH = FILTER_PANEL_WIDTH + RESULT_LIST_WIDTH
local RIGHT_PANEL_WIDTH = DETAIL_PANEL_WIDTH
local MAIN_CONTENT_WIDTH = LEFT_PANEL_WIDTH + RIGHT_PANEL_WIDTH
local SEARCH_PANEL_PADDING_Y = 4
local SEARCH_PANEL_HEIGHT = 24 + SEARCH_PANEL_PADDING_Y * 2
local SCROLLBAR_WIDTH = 16
local SCROLLBAR_HEIGHT = RESULT_PANEL_HEIGHT - MAIN_PANEL_PADDING
local SCROLLBAR_BUTTON_SIZE = 16
local SCROLLBAR_PADDING = 3
local SCROLLBAR_HANDLE_WIDTH = SCROLLBAR_WIDTH
local SCROLLBAR_HANDLE_X = 0
local SCROLLBAR_MIN_HANDLE_HEIGHT = 24
local SCROLLBAR_HANDLE_BOTTOM_CLEARANCE = 4
local NAV_REPEAT_DELAY = 0.35
local NAV_REPEAT_INTERVAL = 0.06
local MAX_ITEM_QUANTITY = 2147483647
local MAX_ITEM_QUANTITY_TEXT = tostring(MAX_ITEM_QUANTITY)

local callbacks = {}
local window
local openPending = false
local query = ''
local scrollOffset = 0
local scrollbarDragging = false
local scrollbarDragOffset = 0
local scrollbarDragStartY = 0
local scrollbarDragStartHandleTop = 0
local scrollbarDragAvailable = 0
local results = {}
local selectedId
local filters = {}
local activeFilter = 'All'
local activeEnchantFilter = 'All'
local typeDropdownOpen = false
local enchantDropdownOpen = false
local searchInputFocused
local addQuantityText = '1'
local pendingCloseFromOpenKey = false
local selectFirstOnNextResults = false
local heldNavigationKeys = {}
local navigationRepeatKey
local navigationRepeatDirection = 0
local navigationRepeatDelay = 0
local navigationRepeatTimer = 0
local navigationRepeatLastRealTime
local textures = {}
local expandedGroups = {}
local visibleResults = {}
local redraw
local setScrollOffset
local updateResultScroll
local resultRowsLayout
local scrollbarHandleLayout
local addQuantityInputLayout
local clampScrollOffset

local THEME = {
    colors = {
        gold = util.color.rgb(223 / 255, 201 / 255, 159 / 255),
    },
    textures = {
        headerMid = 'Textures/menu_head_block_middle.dds',
    },
}

local filterOrder = {
    { key = 'All', label = 'filter_all' },
    { key = 'IncludeWeapons', label = 'filter_weapons' },
    { key = 'IncludeArmor', label = 'filter_armor' },
    { key = 'IncludeClothing', label = 'filter_clothing' },
    { key = 'IncludeAlchemy', label = 'filter_alchemy' },
    { key = 'IncludeBooks', label = 'filter_books' },
    { key = 'IncludeScrolls', label = 'filter_scrolls' },
    { key = 'IncludeIngredients', label = 'filter_ingredients' },
    { key = 'IncludeMisc', label = 'filter_misc' },
    { key = 'IncludeLights', label = 'filter_lights' },
    { key = 'IncludeTools', label = 'filter_tools' },
    { key = 'IncludeKeys', label = 'filter_keys' },
}

local enchantFilterOrder = {
    { key = 'All', label = 'filter_enchantment_all' },
    { key = 'ConstantEffect', label = 'filter_enchantment_constant' },
    { key = 'NonConstantEffect', label = 'filter_enchantment_nonconstant' },
    { key = 'Unenchanted', label = 'filter_enchantment_unenchanted' },
}

local typeSortOrder = {
    Weapon = 1,
    Armor = 2,
    Clothing = 3,
    Potion = 4,
    Book = 5,
    Scroll = 6,
    Ingredient = 7,
    Light = 8,
    Apparatus = 9,
    Lockpick = 10,
    Probe = 11,
    Repair = 12,
    Misc = 13,
    Key = 14,
}

local function texture(path)
    if not textures[path] then
        textures[path] = ui.texture { path = path }
    end
    return textures[path]
end

local function generalSettings()
    return storage.playerSection(GENERAL_SECTION)
end

local function displaySettings()
    return storage.playerSection(DISPLAY_SECTION)
end

local function isAddAllowed()
    return generalSettings():get('AllowAddToInventory') ~= false
end

local function showDebugInfo()
    return generalSettings():get('ShowDebugInfo') == true
end

local function hideSpecialSymbolItems()
    return displaySettings():get('HideSpecialSymbolItems') ~= false
end

local function readFilters()
    filters = {}
    activeFilter = activeFilter or 'All'
    for _, filter in ipairs(filterOrder) do
        if filter.key ~= 'All' then
            filters[filter.key] = activeFilter == 'All' or activeFilter == filter.key
        end
    end
end

local function selectedItem()
    if selectedId then
        for _, item in ipairs(results) do
            if item.id == selectedId then
                return item
            end
        end
    end
    return nil
end

local function resultGroupLabel(item)
    if item.subtypeKey then
        return l10n(item.subtypeKey)
    end
    return l10n('type_' .. item.typeKey)
end

local function resultGroupKey(item, label)
    return string.format('%s:%s', tostring(item.typeKey or ''), tostring(label or resultGroupLabel(item)))
end

local function itemGroupKey(item)
    return resultGroupKey(item, resultGroupLabel(item))
end

local function rebuildVisibleResults()
    local groupsByKey = {}
    local groups = {}

    for _, item in ipairs(results) do
        local label = resultGroupLabel(item)
        local groupKey = resultGroupKey(item, label)
        local group = groupsByKey[groupKey]
        if not group then
            group = {
                key = groupKey,
                label = label,
                typeKey = item.typeKey,
                items = {},
            }
            groupsByKey[groupKey] = group
            groups[#groups + 1] = group
        end
        group.items[#group.items + 1] = item
    end

    table.sort(groups, function(a, b)
        local orderA = typeSortOrder[a.typeKey] or 100
        local orderB = typeSortOrder[b.typeKey] or 100
        if orderA ~= orderB then
            return orderA < orderB
        end
        return a.label < b.label
    end)

    visibleResults = {}
    for _, group in ipairs(groups) do
        local collapsed = expandedGroups[group.key] ~= true
        visibleResults[#visibleResults + 1] = {
            kind = 'group',
            key = group.key,
            label = group.label,
            count = #group.items,
            collapsed = collapsed,
        }
        if not collapsed then
            for _, item in ipairs(group.items) do
                visibleResults[#visibleResults + 1] = {
                    kind = 'item',
                    item = item,
                }
            end
        end
    end
end

local function selectedVisibleIndex()
    if selectedId then
        for index, row in ipairs(visibleResults) do
            if row.kind == 'item' and row.item.id == selectedId then
                return index
            end
        end
    end
    return nil
end

local function collapseAllGroups()
    expandedGroups = {}
    rebuildVisibleResults()
    clampScrollOffset()
    updateResultScroll()
end

local function hasSearchQuery()
    return query ~= ''
end

local function requestSearch(selectFirst)
    selectFirstOnNextResults = selectFirst == true and hasSearchQuery()
    if callbacks.search then
        callbacks.search({
            query = query,
            filters = filters,
            enchantFilter = activeEnchantFilter,
            hideSpecialSymbolItems = hideSpecialSymbolItems(),
        })
    end
end

local function requestSelectedDetails()
    local item = selectedItem()
    if not item or item.detailsLoaded then
        return
    end
    if callbacks.details then
        callbacks.details({ recordId = item.id })
    end
end

local function maxScrollOffset()
    return math.max(0, #visibleResults - VISIBLE_ROWS)
end

local selectResultByOffset

clampScrollOffset = function()
    scrollOffset = util.clamp(math.floor(scrollOffset), 0, maxScrollOffset())
end

selectResultByOffset = function(offset)
    if #visibleResults == 0 then
        return false
    end

    local index = selectedVisibleIndex()
    if not index then
        index = offset >= 0 and 0 or #visibleResults + 1
    end

    local step = offset >= 0 and 1 or -1
    local nextIndex = util.clamp(index + step, 1, #visibleResults)
    local item
    while nextIndex >= 1 and nextIndex <= #visibleResults do
        local row = visibleResults[nextIndex]
        if row.kind == 'item' then
            item = row.item
            break
        end
        nextIndex = nextIndex + step
    end

    if not item or item.id == selectedId then
        return true
    end

    selectedId = item.id
    if nextIndex < scrollOffset + 1 then
        setScrollOffset(nextIndex - 1)
    elseif nextIndex > scrollOffset + VISIBLE_ROWS then
        setScrollOffset(nextIndex - VISIBLE_ROWS)
    end
    requestSelectedDetails()
    redraw()
    return true
end

local function stopNavigationRepeat()
    heldNavigationKeys = {}
    navigationRepeatKey = nil
    navigationRepeatDirection = 0
    navigationRepeatDelay = 0
    navigationRepeatTimer = 0
    navigationRepeatLastRealTime = nil
end

local function startNavigationRepeat(key, direction)
    heldNavigationKeys[key] = true
    navigationRepeatKey = key
    navigationRepeatDirection = direction
    navigationRepeatDelay = NAV_REPEAT_DELAY
    navigationRepeatTimer = NAV_REPEAT_INTERVAL
    navigationRepeatLastRealTime = core.getRealTime and core.getRealTime() or nil
end

local function navigationRepeatDt(dt)
    dt = tonumber(dt) or 0
    if dt > 0 then
        navigationRepeatLastRealTime = core.getRealTime and core.getRealTime() or navigationRepeatLastRealTime
        return dt
    end

    if core.getRealFrameDuration then
        local realFrameDuration = tonumber(core.getRealFrameDuration()) or 0
        if realFrameDuration > 0 then
            navigationRepeatLastRealTime = core.getRealTime and core.getRealTime() or navigationRepeatLastRealTime
            return realFrameDuration
        end
    end

    if core.getRealTime then
        local now = core.getRealTime()
        local realDt = navigationRepeatLastRealTime and now - navigationRepeatLastRealTime or 0
        navigationRepeatLastRealTime = now
        return math.max(0, realDt)
    end

    return 0
end

local function navigationKeyStillPressed(key)
    if not input.isKeyPressed then
        return true
    end
    local ok, pressed = pcall(input.isKeyPressed, key)
    return not ok or pressed == true
end

local function updateNavigationRepeat(dt)
    if not window or not navigationRepeatKey or navigationRepeatDirection == 0 then
        return
    end
    if not heldNavigationKeys[navigationRepeatKey] or not navigationKeyStillPressed(navigationRepeatKey) then
        stopNavigationRepeat()
        return
    end

    dt = navigationRepeatDt(dt)
    if dt <= 0 then
        return
    end

    if navigationRepeatDelay > 0 then
        navigationRepeatDelay = navigationRepeatDelay - dt
        return
    end

    navigationRepeatTimer = navigationRepeatTimer - dt
    if navigationRepeatTimer > 0 then
        return
    end

    selectResultByOffset(navigationRepeatDirection)
    navigationRepeatTimer = NAV_REPEAT_INTERVAL
end

local function destroyWindow()
    if window then
        window:destroy()
        window = nil
    end
    resultRowsLayout = nil
    scrollbarHandleLayout = nil
    addQuantityInputLayout = nil
end

local function close()
    openPending = false
    scrollbarDragging = false
    pendingCloseFromOpenKey = false
    searchInputFocused = nil
    stopNavigationRepeat()
    destroyWindow()
    if I.UI.getMode() == BROWSER_MODE then
        I.UI.removeMode(BROWSER_MODE)
    end
end

local function makeText(text, size, opts)
    opts = opts or {}
    local autoSize = size == nil
    if opts.autoSize ~= nil then
        autoSize = opts.autoSize
    end
    return {
        template = opts.header and I.MWUI.templates.textHeader or I.MWUI.templates.textNormal,
        type = ui.TYPE.Text,
        props = {
            text = text,
            textSize = opts.textSize or 14,
            size = size,
            autoSize = autoSize,
            multiline = opts.multiline,
            wordWrap = opts.wordWrap,
            textColor = opts.textColor,
        },
    }
end

local function makeSpacer(width, height)
    return {
        type = ui.TYPE.Widget,
        props = { size = v2(width or 8, height or 8) },
    }
end

local function makeRightButtonFrame(state)
    local prefix = state == 'down' and 'textures/menu_rightbuttondown_' or 'textures/menu_rightbuttonup_'

    return ui.content {
        {
            type = ui.TYPE.Image,
            props = { position = v2(0, 0), size = v2(2, 2), resource = texture(prefix .. 'top_left.dds') },
        },
        {
            type = ui.TYPE.Image,
            props = { position = v2(2, 0), size = v2(15, 2), resource = texture(prefix .. 'top.dds') },
        },
        {
            type = ui.TYPE.Image,
            props = { position = v2(17, 0), size = v2(2, 2), resource = texture(prefix .. 'top_right.dds') },
        },
        {
            type = ui.TYPE.Image,
            props = { position = v2(0, 2), size = v2(2, 15), resource = texture(prefix .. 'left.dds') },
        },
        {
            type = ui.TYPE.Image,
            props = { position = v2(2, 2), size = v2(15, 15), resource = texture(prefix .. 'center.dds') },
        },
        {
            type = ui.TYPE.Image,
            props = { position = v2(17, 2), size = v2(2, 15), resource = texture(prefix .. 'right.dds') },
        },
        {
            type = ui.TYPE.Image,
            props = { position = v2(0, 17), size = v2(2, 2), resource = texture(prefix .. 'bottom_left.dds') },
        },
        {
            type = ui.TYPE.Image,
            props = { position = v2(2, 17), size = v2(15, 2), resource = texture(prefix .. 'bottom.dds') },
        },
        {
            type = ui.TYPE.Image,
            props = { position = v2(17, 17), size = v2(2, 2), resource = texture(prefix .. 'bottom_right.dds') },
        },
    }
end

local function makeHeaderCloseButton()
    local button
    button = {
        type = ui.TYPE.Widget,
        props = {
            size = v2(20, 20),
            anchor = v2(1, 0),
            relativePosition = v2(1, 0),
            propagateEvents = false,
        },
        content = makeRightButtonFrame('up'),
        events = {
            mousePress = async:callback(function(e, layout)
                if e.button and e.button ~= 1 then
                    return
                end
                layout.content = makeRightButtonFrame('down')
                if window then
                    window:update()
                end
            end),
            mouseRelease = async:callback(function(e, layout)
                layout.content = makeRightButtonFrame('up')
                if window then
                    window:update()
                end
                if not e.button or e.button == 1 then
                    close()
                end
            end),
        },
    }
    return button
end

local function makeHeader(width)
    local headerHeight = 20

    return {
        type = ui.TYPE.Widget,
        props = {
            size = v2(width, headerHeight),
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                props = {
                    horizontal = true,
                    size = v2(width, headerHeight),
                    arrange = ui.ALIGNMENT.Center,
                },
                content = ui.content {
                    {
                        type = ui.TYPE.Image,
                        external = { grow = 1 },
                        props = {
                            size = v2(0, headerHeight),
                            resource = texture(THEME.textures.headerMid),
                            tileH = true,
                            tileV = false,
                        },
                    },
                    makeSpacer(10, 1),
                    {
                        type = ui.TYPE.Text,
                        template = I.MWUI.templates.textNormal,
                        props = {
                            text = l10n('window_title'),
                            textSize = omwConstants.textNormalSize,
                            textAlignH = ui.ALIGNMENT.Center,
                            textAlignV = ui.ALIGNMENT.Center,
                            autoSize = true,
                            size = v2(0, headerHeight),
                        },
                    },
                    makeSpacer(10, 1),
                    {
                        type = ui.TYPE.Image,
                        external = { grow = 1 },
                        props = {
                            size = v2(0, headerHeight),
                            resource = texture(THEME.textures.headerMid),
                            tileH = true,
                            tileV = false,
                        },
                    },
                },
            },
            makeHeaderCloseButton(),
        },
    }
end

local function makeFramedPanel(width, height, content, horizontal)
    return {
        type = ui.TYPE.Widget,
        template = I.MWUI.templates.bordersThick,
        props = {
            size = v2(width, height),
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                props = {
                    position = v2(0, 0),
                    horizontal = horizontal == true,
                    size = v2(width, height),
                    autoSize = false,
                    align = ui.ALIGNMENT.Start,
                    arrange = ui.ALIGNMENT.Start,
                },
                content = content,
            },
        },
    }
end

local function makeButton(text, width, height, onClick, highlighted, disabled, opts)
    opts = opts or {}
    local color = disabled and util.color.rgb(0.45, 0.45, 0.45) or highlighted and util.color.rgb(1, 1, 1) or nil
    local buttonHeight = height or 24
    local buttonWidth = width or 90
    local autoWidth = opts.autoWidth == true
    local textWidth = opts.textWidth or (autoWidth and nil or math.max(1, buttonWidth - 8))
    local content = {
        {
            template = I.MWUI.templates.textNormal,
            type = ui.TYPE.Text,
            props = {
                anchor = v2(0.5, 0.5),
                relativePosition = v2(0.5, 0.5),
                text = text,
                textSize = opts.textSize or 13,
                textColor = color,
                size = textWidth and v2(textWidth, buttonHeight) or nil,
                autoSize = autoWidth,
                multiline = true,
                wordWrap = true,
                textAlignH = opts.alignStart and ui.ALIGNMENT.Start or ui.ALIGNMENT.Center,
                textAlignV = ui.ALIGNMENT.Center,
            },
        },
    }

    local template = I.MWUI.templates.bordersThick
    if opts.noBorder then
        template = nil
    end

    local button = {
        type = ui.TYPE.Widget,
        template = template,
        props = {
            size = opts.stretch and v2(1, buttonHeight) or autoWidth and nil or v2(buttonWidth, buttonHeight),
            autoSize = autoWidth,
            propagateEvents = false,
        },
        content = ui.content(content),
    }
    if opts.stretch then
        button.external = { stretch = 1 }
    end

    if not disabled then
        button.events = {
            mouseClick = async:callback(onClick),
        }
    end

    return button
end

local function normalizeQuantityText(text)
    local digits = tostring(text or ''):gsub('%D', ''):gsub('^0+', '')
    if #digits > #MAX_ITEM_QUANTITY_TEXT
        or (#digits == #MAX_ITEM_QUANTITY_TEXT and digits > MAX_ITEM_QUANTITY_TEXT)
    then
        return MAX_ITEM_QUANTITY_TEXT
    end
    return digits
end

local function updateAddQuantityText(text)
    local sanitized = normalizeQuantityText(text)
    local changed = sanitized ~= tostring(text or '')
    addQuantityText = sanitized
    if addQuantityInputLayout then
        addQuantityInputLayout.props.text = addQuantityText
    end
    if changed and window then
        window:update()
    end
end

local function addQuantity()
    return util.clamp(math.floor(tonumber(addQuantityText) or 1), 1, MAX_ITEM_QUANTITY)
end

local function handleAddQuantityKeyPress(e)
    if e.code == input.KEY.Escape then
        close()
        return false
    end
end

local function makeAddToInventoryPanel()
    local item = selectedItem()
    local addAllowed = isAddAllowed()
    local addDisabled = not item or not addAllowed

    local addButton = makeButton(l10n('button_add'), 150, 24, function()
        if callbacks.add and selectedItem() then
            callbacks.add({ recordId = selectedItem().id, quantity = addQuantity(), allowAdd = isAddAllowed() })
        end
    end, false, addDisabled)
    addButton.props.position = v2(0, 50)

    local toggleGroupsButton = makeButton(
        l10n('button_collapse_all'),
        150,
        24,
        collapseAllGroups,
        false,
        false
    )
    toggleGroupsButton.props.position = addAllowed and v2(0, 80) or v2(0, 0)

    local content = {}
    if addAllowed then
        addQuantityInputLayout = {
            template = I.MWUI.templates.textEditLine,
            props = {
                text = addQuantityText,
                size = v2(142, 24),
            },
            events = {
                keyPress = async:callback(handleAddQuantityKeyPress),
                textChanged = async:callback(updateAddQuantityText),
            },
        }
        content[#content + 1] = {
            type = ui.TYPE.Text,
            template = I.MWUI.templates.textNormal,
            props = {
                position = v2(6, 0),
                text = l10n('label_quantity'),
                textSize = 14,
                size = v2(144, 18),
            },
        }
        content[#content + 1] = {
            template = I.MWUI.templates.box,
            props = {
                position = v2(0, 20),
                size = v2(150, 24),
            },
            content = ui.content {
                {
                    template = I.MWUI.templates.padding,
                    content = ui.content { addQuantityInputLayout },
                },
            },
        }
        content[#content + 1] = addButton
    end
    content[#content + 1] = toggleGroupsButton

    return {
        type = ui.TYPE.Widget,
        props = {
            size = v2(150, 126),
        },
        content = ui.content(content),
    }
end

local function makeSearchRow(width)
    local contentWidth = width
    local innerWidth = contentWidth - MAIN_PANEL_PADDING * 2
    local innerHeight = SEARCH_PANEL_HEIGHT - SEARCH_PANEL_PADDING_Y * 2
    local searchLabelWidth = 68
    local searchButtonWidth = 68
    local clearButtonWidth = 104
    local searchRightPadding = 8
    local searchInputWidth = innerWidth
        - searchLabelWidth
        - searchButtonWidth
        - clearButtonWidth
        - searchRightPadding
        - 18

    local searchInput = {
        template = I.MWUI.templates.textEditLine,
        props = {
            text = query,
            size = v2(searchInputWidth, 24),
        },
        events = {
            textChanged = async:callback(function(text)
                searchInputFocused = true
                pendingCloseFromOpenKey = false
                query = text
            end),
            keyPress = async:callback(function(e)
                searchInputFocused = true
                pendingCloseFromOpenKey = false
                if e.code == input.KEY.Enter then
                    scrollOffset = 0
                    requestSearch(true)
                elseif e.code == input.KEY.Escape then
                    close()
                end
            end),
            focusGain = async:callback(function()
                searchInputFocused = true
                pendingCloseFromOpenKey = false
            end),
            focusLoss = async:callback(function()
                searchInputFocused = false
                scrollOffset = 0
                requestSearch(true)
            end),
        },
    }

    return makeFramedPanel(contentWidth, SEARCH_PANEL_HEIGHT, ui.content {
        {
            type = ui.TYPE.Flex,
            props = {
                horizontal = true,
                position = v2(MAIN_PANEL_PADDING, SEARCH_PANEL_PADDING_Y),
                size = v2(innerWidth, innerHeight),
                autoSize = false,
                arrange = ui.ALIGNMENT.Center,
            },
            content = ui.content {
                {
                    type = ui.TYPE.Widget,
                    props = { size = v2(searchLabelWidth, 24) },
                    content = ui.content {
                        {
                            type = ui.TYPE.Text,
                            template = I.MWUI.templates.textNormal,
                            props = {
                                position = v2(6, 4),
                                text = l10n('label_search'),
                                textSize = 14,
                                size = v2(searchLabelWidth - 6, 22),
                            },
                        },
                    },
                },
                {
                    template = I.MWUI.templates.box,
                    content = ui.content {
                        {
                            template = I.MWUI.templates.padding,
                            content = ui.content { searchInput },
                        },
                    },
                },
                makeSpacer(8, 1),
                makeButton(l10n('button_search'), searchButtonWidth, 24, function()
                    scrollOffset = 0
                    requestSearch(true)
                end, false, false),
                makeSpacer(6, 1),
                makeButton(l10n('button_clear'), clearButtonWidth, 24, function()
                    query = ''
                    scrollOffset = 0
                    requestSearch(true)
                    redraw()
                end, false, false),
                makeSpacer(searchRightPadding, 1),
            },
        },
    }, false)
end

local function makeDropdown(title, options, activeKey, isOpen, onToggle, onChoose, opts)
    opts = opts or {}
    local dropdownWidth = 150
    local dropdownPaddingLeft = 0
    local dropdownPaddingRight = 0
    local dropdownPaddingTop = 0
    local dropdownPaddingBottom = 0
    local dropdownInnerWidth = dropdownWidth - dropdownPaddingLeft - dropdownPaddingRight
    local dropdownHeaderHeight = opts.headerHeight or 24
    local dropdownRowHeight = 22
    local activeLabel = options[1].label

    for _, option in ipairs(options) do
        if option.key == activeKey then
            activeLabel = option.label
            break
        end
    end

    local headerText = title .. ': ' .. l10n(activeLabel)
    if opts.headerLineBreak then
        headerText = title .. ':\n' .. l10n(activeLabel)
    end

    local dropdownContent = {
        makeButton(headerText, dropdownInnerWidth, dropdownHeaderHeight, onToggle, isOpen, false, { noBorder = true }),
    }

    if isOpen then
        for _, option in ipairs(options) do
            local key = option.key
            local label = option.label
            dropdownContent[#dropdownContent + 1] = makeButton(
                l10n(label),
                dropdownInnerWidth,
                dropdownRowHeight,
                function()
                    onChoose(key)
                end,
                activeKey == key,
                false,
                { noBorder = true }
            )
        end
    end

    local dropdownHeight = dropdownPaddingTop + dropdownPaddingBottom + dropdownHeaderHeight
    if isOpen then
        dropdownHeight = dropdownHeight + #options * dropdownRowHeight
    end

    return {
        type = ui.TYPE.Widget,
        props = {
            size = v2(dropdownWidth, dropdownHeight),
            propagateEvents = false,
        },
        content = ui.content {
            {
                type = ui.TYPE.Widget,
                template = I.MWUI.templates.bordersThick,
                props = {
                    size = v2(dropdownWidth, dropdownHeight),
                    propagateEvents = true,
                },
            },
            {
                type = ui.TYPE.Flex,
                props = {
                    horizontal = false,
                    position = v2(dropdownPaddingLeft, dropdownPaddingTop),
                    size = v2(dropdownInnerWidth, dropdownHeight - dropdownPaddingTop - dropdownPaddingBottom),
                    autoSize = false,
                },
                content = ui.content(dropdownContent),
            },
        },
    }
end

local function makeFilterPanel()
    local content = {}
    local actionPanelHeight = 126
    local filterControlsHeight = 481 - MAIN_PANEL_PADDING * 2 - actionPanelHeight - 8

    content[#content + 1] = makeDropdown(l10n('filter_type'), filterOrder, activeFilter, typeDropdownOpen, function()
        typeDropdownOpen = not typeDropdownOpen
        if typeDropdownOpen then
            enchantDropdownOpen = false
        end
        redraw()
    end, function(key)
        activeFilter = key
        typeDropdownOpen = false
        readFilters()
        scrollOffset = 0
        requestSearch(true)
        redraw()
    end)
    content[#content + 1] = makeSpacer(1, 4)

    content[#content + 1] = makeDropdown(
        l10n('filter_enchantment'),
        enchantFilterOrder,
        activeEnchantFilter,
        enchantDropdownOpen,
        function()
            enchantDropdownOpen = not enchantDropdownOpen
            if enchantDropdownOpen then
                typeDropdownOpen = false
            end
            redraw()
        end,
        function(key)
            activeEnchantFilter = key
            enchantDropdownOpen = false
            scrollOffset = 0
            requestSearch(true)
            redraw()
        end,
        { headerHeight = 40, headerLineBreak = true }
    )

    return {
        type = ui.TYPE.Widget,
        props = {
            size = v2(FILTER_PANEL_WIDTH, 481),
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                props = {
                    horizontal = false,
                    position = v2(MAIN_PANEL_PADDING, MAIN_PANEL_PADDING),
                    size = v2(FILTER_PANEL_CONTENT_WIDTH, filterControlsHeight),
                    autoSize = false,
                },
                content = ui.content(content),
            },
            {
                type = ui.TYPE.Widget,
                props = {
                    position = v2(MAIN_PANEL_PADDING, 481 - MAIN_PANEL_PADDING - actionPanelHeight),
                    size = v2(FILTER_PANEL_CONTENT_WIDTH, actionPanelHeight),
                    autoSize = false,
                },
                content = ui.content {
                    makeAddToInventoryPanel(),
                },
            },
        },
    }
end

local function makeResultRow(item)
    local isSelected = item.id == (selectedId or (results[1] and results[1].id))
    local label = item.displayName

    return makeButton(label, nil, RESULT_ROW_HEIGHT, function()
        selectedId = item.id
        requestSelectedDetails()
        redraw()
    end, isSelected, false, {
        stretch = true,
        textWidth = RESULT_ROWS_WIDTH - 2,
        alignStart = true,
        noBorder = true,
        textSize = RESULT_ROW_TEXT_SIZE,
    })
end

local function makeResultGroupRow(group)
    local prefix = group.collapsed and '[+] ' or '[-] '
    local label = string.format('%s%s (%s)', prefix, group.label, tostring(group.count))

    return makeButton(label, nil, RESULT_ROW_HEIGHT, function()
        expandedGroups[group.key] = group.collapsed or nil
        rebuildVisibleResults()
        clampScrollOffset()
        updateResultScroll()
    end, false, false, {
        stretch = true,
        textWidth = RESULT_ROWS_WIDTH - 2,
        alignStart = true,
        noBorder = true,
        textSize = RESULT_ROW_TEXT_SIZE,
    })
end

setScrollOffset = function(newOffset)
    local previous = scrollOffset
    scrollOffset = util.clamp(math.floor(newOffset + 0.5), 0, maxScrollOffset())
    if scrollOffset ~= previous then
        if updateResultScroll then
            updateResultScroll()
        else
            redraw()
        end
    end
end

local function scrollbarMetrics()
    local maxOffset = maxScrollOffset()
    local canScroll = maxOffset > 0
    local trackHeight = SCROLLBAR_HEIGHT - (SCROLLBAR_BUTTON_SIZE + SCROLLBAR_PADDING) * 2
    local handleHeight = trackHeight
    local handleTop = 0

    if canScroll and #visibleResults > 0 then
        local maxHandleHeight = math.max(
            SCROLLBAR_MIN_HANDLE_HEIGHT,
            trackHeight - SCROLLBAR_HANDLE_BOTTOM_CLEARANCE
        )
        handleHeight = math.min(
            maxHandleHeight,
            math.max(SCROLLBAR_MIN_HANDLE_HEIGHT, math.floor(trackHeight * VISIBLE_ROWS / #visibleResults))
        )
        handleTop = math.floor(
            (trackHeight - handleHeight - SCROLLBAR_HANDLE_BOTTOM_CLEARANCE) * scrollOffset / maxOffset
        )
    end

    return {
        maxOffset = maxOffset,
        canScroll = canScroll,
        trackHeight = trackHeight,
        handleHeight = handleHeight,
        handleTop = handleTop,
        available = math.max(0, trackHeight - handleHeight - SCROLLBAR_HANDLE_BOTTOM_CLEARANCE),
    }
end

local function makeVisibleResultRows()
    clampScrollOffset()
    local rows = {}
    local first = scrollOffset + 1
    local last = math.min(first + VISIBLE_ROWS - 1, #visibleResults)

    if #results == 0 then
        rows[#rows + 1] = makeText(
            l10n('message_no_results'),
            v2(RESULT_ROWS_WIDTH, 80),
            { multiline = true, wordWrap = true }
        )
    else
        for i = first, last do
            local row = visibleResults[i]
            if row.kind == 'group' then
                rows[#rows + 1] = makeResultGroupRow(row)
            else
                rows[#rows + 1] = makeResultRow(row.item)
            end
            rows[#rows + 1] = makeSpacer(1, RESULT_ROW_SPACING)
        end
    end

    return ui.content(rows)
end

updateResultScroll = function()
    if resultRowsLayout then
        resultRowsLayout.content = makeVisibleResultRows()
    end

    if scrollbarHandleLayout then
        local metrics = scrollbarMetrics()
        scrollbarHandleLayout.props.size = v2(SCROLLBAR_HANDLE_WIDTH, metrics.handleHeight)
        scrollbarHandleLayout.props.position = v2(SCROLLBAR_HANDLE_X, metrics.handleTop)
    end

    if window then
        window:update()
    end
end

local function beginScrollbarDrag(e, handleTop, available)
    scrollbarDragging = true
    scrollbarDragOffset = 0
    scrollbarDragStartY = e.position and e.position.y or 0
    scrollbarDragStartHandleTop = handleTop
    scrollbarDragAvailable = available
end

local function updateScrollbarDrag(e)
    if not scrollbarDragging or scrollbarDragAvailable <= 0 then
        return
    end
    if e.button and e.button ~= 1 then
        scrollbarDragging = false
        return
    end

    local metrics = scrollbarMetrics()
    local y = e.position and e.position.y or scrollbarDragStartY
    local handleTop = util.clamp(scrollbarDragStartHandleTop + y - scrollbarDragStartY, 0, scrollbarDragAvailable)
    setScrollOffset(metrics.maxOffset * handleTop / scrollbarDragAvailable)
end

local function makeScrollButton(iconPath, direction, canScroll)
    local events
    if canScroll then
        events = {
            mousePress = async:callback(function(e)
                if e.button and e.button ~= 1 then
                    return
                end
                setScrollOffset(scrollOffset + direction * WHEEL_STEP)
            end),
        }
    end

    return {
        template = I.MWUI.templates.borders,
        props = {
            size = v2(SCROLLBAR_BUTTON_SIZE, SCROLLBAR_BUTTON_SIZE),
            propagateEvents = false,
        },
        content = ui.content {
            {
                type = ui.TYPE.Image,
                props = {
                    resource = texture(iconPath),
                    size = v2(SCROLLBAR_BUTTON_SIZE - 4, SCROLLBAR_BUTTON_SIZE - 4),
                    relativePosition = v2(0.5, 0.5),
                    anchor = v2(0.5, 0.5),
                },
            },
        },
        events = events,
    }
end

local function makeScrollbar()
    local metrics = scrollbarMetrics()

    local function scrollToTrackY(y)
        if not metrics.canScroll then
            return
        end

        if metrics.available <= 0 then
            setScrollOffset(0)
            return
        end

        local newHandleTop = util.clamp(y - scrollbarDragOffset, 0, metrics.available)
        setScrollOffset(metrics.maxOffset * newHandleTop / metrics.available)
    end

    scrollbarHandleLayout = {
        name = 'handle',
        type = ui.TYPE.Image,
        props = {
            resource = texture('textures/omw_menu_scroll_center_v.dds'),
            size = v2(SCROLLBAR_HANDLE_WIDTH, metrics.handleHeight),
            position = v2(SCROLLBAR_HANDLE_X, metrics.handleTop),
            tileV = true,
            propagateEvents = true,
        },
        events = metrics.canScroll and {
            mousePress = async:callback(function(e)
                if e.button and e.button ~= 1 then
                    return
                end
                local current = scrollbarMetrics()
                beginScrollbarDrag(e, current.handleTop, current.available)
                return false
            end),
            mouseRelease = async:callback(function()
                scrollbarDragging = false
                return false
            end),
        } or nil,
    }

    local track = {
        template = I.MWUI.templates.borders,
        props = {
            size = v2(SCROLLBAR_WIDTH, metrics.trackHeight),
            propagateEvents = false,
        },
        content = ui.content { scrollbarHandleLayout },
        events = {
            mousePress = metrics.canScroll and async:callback(function(e)
                if e.button and e.button ~= 1 then
                    return
                end
                scrollbarDragOffset = metrics.handleHeight / 2
                scrollToTrackY(e.offset and e.offset.y or 0)
                beginScrollbarDrag(e, scrollbarMetrics().handleTop, metrics.available)
            end) or nil,
            mouseMove = metrics.canScroll and async:callback(function(e)
                if scrollbarDragging then
                    updateScrollbarDrag(e)
                end
            end) or nil,
            mouseRelease = metrics.canScroll and async:callback(function()
                scrollbarDragging = false
            end) or nil,
        },
    }

    return {
        type = ui.TYPE.Flex,
        props = {
            horizontal = false,
            position = v2(0, MAIN_PANEL_PADDING),
            size = v2(SCROLLBAR_WIDTH, SCROLLBAR_HEIGHT),
            autoSize = false,
        },
        content = ui.content {
            makeScrollButton('textures/omw_menu_scroll_up.dds', -1, metrics.canScroll),
            makeSpacer(1, SCROLLBAR_PADDING),
            track,
            makeSpacer(1, SCROLLBAR_PADDING),
            makeScrollButton('textures/omw_menu_scroll_down.dds', 1, metrics.canScroll),
        },
    }
end

local function makeResultList()
    local content = {}

    resultRowsLayout = {
        type = ui.TYPE.Flex,
        props = {
            horizontal = false,
            size = v2(RESULT_ROWS_WIDTH, RESULT_ROWS_HEIGHT),
            autoSize = false,
        },
        content = makeVisibleResultRows(),
    }

    content[#content + 1] = {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            size = v2(RESULT_LIST_WIDTH, 481),
            autoSize = false,
        },
        content = ui.content {
            {
                type = ui.TYPE.Widget,
                props = {
                    size = v2(RESULT_ROWS_WIDTH + MAIN_PANEL_PADDING * 2, 481),
                },
                content = ui.content {
                    {
                        type = ui.TYPE.Flex,
                        props = {
                            position = v2(MAIN_PANEL_PADDING, MAIN_PANEL_PADDING),
                            horizontal = false,
                            size = v2(RESULT_ROWS_WIDTH, RESULT_ROWS_HEIGHT),
                            autoSize = false,
                        },
                        content = ui.content { resultRowsLayout },
                    },
                },
            },
            makeScrollbar(),
        },
    }

    return {
        type = ui.TYPE.Widget,
        props = {
            size = v2(RESULT_LIST_WIDTH, 481),
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                props = {
                    horizontal = false,
                    position = v2(0, 0),
                    size = v2(RESULT_LIST_WIDTH, 481),
                    autoSize = false,
                },
                content = ui.content(content),
            },
        },
    }
end

local function statLine(key, value)
    if value == nil or value == '' then
        return nil
    end
    return makeText(string.format('%s: %s', l10n(key), tostring(value)), v2(280, 20))
end

local function addLine(content, key, value)
    local line = statLine(key, value)
    if line then
        content[#content + 1] = line
    end
end

local function isAmmoOrThrown(item)
    return item.subtypeKey == 'Type_Arrow'
        or item.subtypeKey == 'Type_Bolt'
        or item.subtypeKey == 'Type_MarksmanThrown'
end

local function isBowOrCrossbow(item)
    return item.subtypeKey == 'Type_MarksmanBow'
        or item.subtypeKey == 'Type_MarksmanCrossbow'
end

local function itemTypeLabel(item)
    local typeLabel = l10n('type_' .. item.typeKey)
    if item.subtypeKey then
        return string.format('%s: %s', typeLabel, l10n(item.subtypeKey))
    end
    return typeLabel
end

local function addIconPreview(content, iconPath)
    local iconContent = {}
    if iconPath ~= nil and iconPath ~= '' then
        iconContent[#iconContent + 1] = {
            type = ui.TYPE.Image,
            props = {
                resource = texture(iconPath),
                size = v2(32, 32),
            },
        }
    end

    content[#content + 1] = {
        type = ui.TYPE.Flex,
        props = {
            horizontal = true,
            size = v2(DETAIL_TEXT_WIDTH, 40),
            autoSize = false,
            align = ui.ALIGNMENT.Center,
            arrange = ui.ALIGNMENT.Center,
        },
        content = ui.content(iconContent),
    }
end

local function addEnchantEffects(content, typeKey, effects)
    if effects == nil or #effects == 0 then
        return
    end

    local labelKey = typeKey and ('enchant_type_' .. typeKey) or 'field_enchant_effects'
    local label = l10n(labelKey)
    local effectIconSize = 16
    local blockContent = {
        makeText(label, nil, { header = true }),
    }
    for _, effect in ipairs(effects) do
        local effectText = type(effect) == 'table' and effect.text or tostring(effect)
        local effectIcon = type(effect) == 'table' and effect.icon or nil
        local rowContent = {}
        if effectIcon and effectIcon ~= '' then
            rowContent[#rowContent + 1] = {
                type = ui.TYPE.Image,
                props = {
                    resource = texture(effectIcon),
                    size = v2(effectIconSize, effectIconSize),
                },
            }
        else
            rowContent[#rowContent + 1] = makeSpacer(effectIconSize, effectIconSize)
        end
        rowContent[#rowContent + 1] = makeSpacer(4, 1)
        rowContent[#rowContent + 1] = makeText(effectText, nil, { textSize = 13 })
        blockContent[#blockContent + 1] = {
            type = ui.TYPE.Flex,
            props = {
                horizontal = true,
                autoSize = true,
                align = ui.ALIGNMENT.Center,
            },
            content = ui.content(rowContent),
        }
    end

    content[#content + 1] = makeSpacer(1, 4)
    content[#content + 1] = {
        type = ui.TYPE.Flex,
        props = {
            horizontal = false,
            autoSize = true,
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                props = {
                    horizontal = false,
                    autoSize = true,
                },
                content = ui.content(blockContent),
            },
        },
    }
end

local function makeDetailPanel()
    local item = selectedItem()
    local content = {}

    if not item then
        content[#content + 1] = makeText(
            l10n('message_select_item'),
            v2(DETAIL_TEXT_WIDTH, 90),
            { multiline = true, wordWrap = true }
        )
    else
        content[#content + 1] = makeText(
            item.displayName,
            v2(DETAIL_TEXT_WIDTH, 42),
            { header = true, multiline = true, wordWrap = true }
        )
        addIconPreview(content, item.icon)
        content[#content + 1] = makeText(itemTypeLabel(item), v2(280, 20))
        if showDebugInfo() then
            addLine(content, 'field_id', item.id)
        end
        addLine(content, 'field_weight', item.weight)
        addLine(content, 'field_value', item.value)
        if not isAmmoOrThrown(item) then
            addLine(content, 'field_health', item.health)
        end
        addLine(content, 'field_armor', item.baseArmor)
        addLine(content, 'field_damage_chop', item.chopDamage)
        addLine(content, 'field_damage_slash', item.slashDamage)
        addLine(content, 'field_damage_thrust', item.thrustDamage)
        addLine(content, 'field_quality', item.quality)
        addLine(content, 'field_enchant', item.enchantCapacity)
        if not isAmmoOrThrown(item) then
            addLine(content, 'field_speed', item.speed)
        end
        if not isAmmoOrThrown(item) and not isBowOrCrossbow(item) then
            addLine(content, 'field_reach', item.reach)
        end
        if showDebugInfo() then
            addLine(content, 'field_icon', item.icon)
            addLine(content, 'field_model', item.model)
        end
        addEnchantEffects(content, nil, item.effects)
        addEnchantEffects(content, item.enchantTypeKey, item.enchantEffects)
    end

    return {
        type = ui.TYPE.Widget,
        props = {
            size = v2(DETAIL_PANEL_WIDTH, 481),
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                props = {
                    horizontal = false,
                    position = v2(MAIN_PANEL_PADDING, MAIN_PANEL_PADDING),
                    size = v2(DETAIL_PANEL_CONTENT_WIDTH, 481 - MAIN_PANEL_PADDING * 2),
                    autoSize = false,
                },
                content = ui.content(content),
            },
        },
    }
end

redraw = function()
    if not window then
        return
    end
    destroyWindow()
    M.createWindow()
end

function M.createWindow()
    local screen = ui.screenSize()
    local width = math.min(MAIN_CONTENT_WIDTH, screen.x - 80)
    local height = math.min(545, screen.y - 80)

    window = ui.create {
        type = ui.TYPE.Container,
        layer = 'Windows',
        template = I.MWUI.templates.boxTransparentThick,
        props = {
            relativePosition = v2(0.5, 0.5),
            anchor = v2(0.5, 0.5),
            size = v2(width, height),
            propagateEvents = false,
        },
        events = {
            mouseMove = async:callback(function(e)
                updateScrollbarDrag(e)
            end),
            mouseRelease = async:callback(function()
                scrollbarDragging = false
            end),
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                props = {
                    horizontal = false,
                    align = ui.ALIGNMENT.Center,
                    arrange = ui.ALIGNMENT.Start,
                },
                content = ui.content {
                    makeHeader(width),
                    makeSearchRow(width),
                    {
                        type = ui.TYPE.Flex,
                        props = { horizontal = true, arrange = ui.ALIGNMENT.Start },
                        content = ui.content {
                            makeFramedPanel(LEFT_PANEL_WIDTH, 481, ui.content {
                                makeFilterPanel(),
                                makeResultList(),
                            }, true),
                            makeFramedPanel(RIGHT_PANEL_WIDTH, 481, ui.content {
                                makeDetailPanel(),
                            }, false),
                        },
                    },
                },
            },
        },
    }
end

function M.setCallbacks(newCallbacks)
    callbacks = newCallbacks or {}
end

function M.open()
    if window or openPending then
        close()
        return
    end

    readFilters()
    scrollbarDragging = false
    scrollbarDragOffset = 0
    if I.UI.setPauseOnMode then
        I.UI.setPauseOnMode(BROWSER_MODE, true)
    end
    openPending = true
    I.UI.setMode(BROWSER_MODE, { windows = {} })
    M.createWindow()
    if #results == 0 then
        requestSearch(false)
    else
        requestSelectedDetails()
    end
end

function M.onFrame(dt)
    if openPending and I.UI.getMode() == BROWSER_MODE then
        openPending = false
        return
    end
    if window and not openPending and I.UI.getMode() ~= BROWSER_MODE then
        destroyWindow()
        return
    end
    if pendingCloseFromOpenKey then
        pendingCloseFromOpenKey = false
        if searchInputFocused ~= true then
            close()
            return
        end
    end
    updateNavigationRepeat(tonumber(dt) or 0)
end

function M.close()
    close()
end

function M.isOpen()
    return window ~= nil or openPending
end

function M.requestCloseFromOpenKey()
    if not M.isOpen() then
        return false
    end
    if searchInputFocused == true then
        return false
    end

    pendingCloseFromOpenKey = true
    return true
end

function M.handleKeyPress(e)
    if e.code == input.KEY.Escape and M.isOpen() then
        close()
        return true
    end
    if M.isOpen() and e.code == input.KEY.UpArrow then
        if heldNavigationKeys[e.code] then
            return true
        end
        startNavigationRepeat(e.code, -1)
        return selectResultByOffset(-1)
    elseif M.isOpen() and e.code == input.KEY.DownArrow then
        if heldNavigationKeys[e.code] then
            return true
        end
        startNavigationRepeat(e.code, 1)
        return selectResultByOffset(1)
    end
    return false
end

function M.handleKeyRelease(e)
    if e.code == input.KEY.UpArrow or e.code == input.KEY.DownArrow then
        heldNavigationKeys[e.code] = nil
        if navigationRepeatKey == e.code then
            stopNavigationRepeat()
        end
    end
end

function M.setResults(data)
    results = data.items or {}
    selectedId = nil
    scrollOffset = 0

    local firstItem = selectFirstOnNextResults and results[1] or nil
    if firstItem then
        selectedId = firstItem.id
        expandedGroups[itemGroupKey(firstItem)] = true
    end
    selectFirstOnNextResults = false

    rebuildVisibleResults()
    local visibleIndex = selectedVisibleIndex()
    if visibleIndex and visibleIndex > VISIBLE_ROWS then
        scrollOffset = visibleIndex - VISIBLE_ROWS
    end
    clampScrollOffset()
    requestSelectedDetails()
    redraw()
end

function M.setItemDetails(data)
    data = data or {}
    if not data.id then
        return
    end

    for _, item in ipairs(results) do
        if item.id == data.id then
            for key, value in pairs(data) do
                item[key] = value
            end
            if selectedId == data.id then
                redraw()
            end
            return
        end
    end
end

function M.onMouseWheel(vertical)
    if not window or vertical == 0 or maxScrollOffset() == 0 then
        return
    end

    setScrollOffset(scrollOffset - vertical * WHEEL_STEP)
end

function M.showSearchError(data)
    ui.showMessage(string.format('%s: %s', l10n('message_search_failed'), tostring(data and data.message or '')))
end

function M.showAddResult(data)
    data = data or {}
    if data.ok then
        ui.showMessage(string.format(
            l10n(data.key or 'message_added'),
            tostring(data.quantity or 1),
            tostring(data.name or data.recordId or '')
        ))
    elseif data.key == 'message_add_failed' then
        ui.showMessage(string.format(
            l10n('message_add_failed'),
            tostring(data.recordId or ''),
            tostring(data.message or '')
        ))
    elseif data.key == 'message_not_found' then
        ui.showMessage(string.format(l10n('message_not_found'), tostring(data.recordId or '')))
    else
        ui.showMessage(l10n(data.key or 'message_add_disabled'))
    end
end

return M
