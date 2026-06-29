-- PXM Object Insight Tooltip
-- Shows source, record, item stats, and equipped-gear comparisons for the object under the crosshair.
-- OpenMW 0.51 / 0.52-dev player script.

local async = require('openmw.async')
local nearby = require('openmw.nearby')
local camera = require('openmw.camera')
local ui = require('openmw.ui')
local util = require('openmw.util')
local self = require('openmw.self')
local storage = require('openmw.storage')
local I = require('openmw.interfaces')
local types = require('openmw.types')
local core = require('openmw.core')

local v2 = util.vector2
local color = util.color

local PAGE_KEY = 'PXMObjectInsightTooltipPage'
local GROUP_KEY = 'SettingsPXMObjectInsightTooltip'
local LEGACY_GROUP_KEY = 'SettingsPXMObjectSourceTooltip'
local L10N = 'pxm_object_insight_tooltip'

local DEFAULTS = {
    Enabled = true,
    ShowSource = true,
    ShowRecord = true,
    ShowObject = false,
    ShowItemStats = true,
    ShowItemName = true,
    ShowItemType = true,
    ShowCombatStats = true,
    ShowEconomyStats = true,
    ShowEnchantStats = true,
    ShowCondition = true,
    ShowEquipmentCompare = true,
    UseInlineColors = true,
    PositionX = 2,
    PositionY = 2,
    NudgeX = 0,
    NudgeY = 0,
    TextSize = 16,
    TextColor = color.rgb(0.90, 0.80, 0.49),
    TextAlignH = 'Left',
    TextAnchorV = 'Top',
    ShowBackground = true,
    ShowBorder = true,
    BackgroundOpacity = 50,
    UpdateInterval = 0.10,
    MaxDistance = 1024,
    DebugLog = false,
}

local settings = storage.playerSection(GROUP_KEY)
local legacySettings = storage.playerSection(LEGACY_GROUP_KEY)

I.Settings.registerPage {
    key = PAGE_KEY,
    l10n = L10N,
    name = 'page_name',
    description = 'page_description',
}

I.Settings.registerGroup {
    key = GROUP_KEY,
    page = PAGE_KEY,
    l10n = L10N,
    name = 'group_name',
    description = 'group_description',
    permanentStorage = true,
    settings = {
        {
            key = 'Enabled',
            renderer = 'checkbox',
            name = 'enabled_name',
            description = 'enabled_description',
            default = DEFAULTS.Enabled,
        },
        {
            key = 'ShowSource',
            renderer = 'checkbox',
            name = 'show_source_name',
            description = 'show_source_description',
            default = DEFAULTS.ShowSource,
        },
        {
            key = 'ShowRecord',
            renderer = 'checkbox',
            name = 'show_record_name',
            description = 'show_record_description',
            default = DEFAULTS.ShowRecord,
        },
        {
            key = 'ShowObject',
            renderer = 'checkbox',
            name = 'show_object_name',
            description = 'show_object_description',
            default = DEFAULTS.ShowObject,
        },
        {
            key = 'ShowItemStats',
            renderer = 'checkbox',
            name = 'show_item_stats_name',
            description = 'show_item_stats_description',
            default = DEFAULTS.ShowItemStats,
        },
        {
            key = 'ShowItemName',
            renderer = 'checkbox',
            name = 'show_item_name_name',
            description = 'show_item_name_description',
            default = DEFAULTS.ShowItemName,
        },
        {
            key = 'ShowItemType',
            renderer = 'checkbox',
            name = 'show_item_type_name',
            description = 'show_item_type_description',
            default = DEFAULTS.ShowItemType,
        },
        {
            key = 'ShowCombatStats',
            renderer = 'checkbox',
            name = 'show_combat_stats_name',
            description = 'show_combat_stats_description',
            default = DEFAULTS.ShowCombatStats,
        },
        {
            key = 'ShowEconomyStats',
            renderer = 'checkbox',
            name = 'show_economy_stats_name',
            description = 'show_economy_stats_description',
            default = DEFAULTS.ShowEconomyStats,
        },
        {
            key = 'ShowEnchantStats',
            renderer = 'checkbox',
            name = 'show_enchant_stats_name',
            description = 'show_enchant_stats_description',
            default = DEFAULTS.ShowEnchantStats,
        },
        {
            key = 'ShowCondition',
            renderer = 'checkbox',
            name = 'show_condition_name',
            description = 'show_condition_description',
            default = DEFAULTS.ShowCondition,
        },
        {
            key = 'ShowEquipmentCompare',
            renderer = 'checkbox',
            name = 'show_equipment_compare_name',
            description = 'show_equipment_compare_description',
            default = DEFAULTS.ShowEquipmentCompare,
        },
        {
            key = 'UseInlineColors',
            renderer = 'checkbox',
            name = 'use_inline_colors_name',
            description = 'use_inline_colors_description',
            default = DEFAULTS.UseInlineColors,
        },
        {
            key = 'PositionX',
            renderer = 'number',
            name = 'position_x_name',
            description = 'position_x_description',
            default = DEFAULTS.PositionX,
            argument = { integer = true, min = 0, max = 100 },
        },
        {
            key = 'PositionY',
            renderer = 'number',
            name = 'position_y_name',
            description = 'position_y_description',
            default = DEFAULTS.PositionY,
            argument = { integer = true, min = 0, max = 100 },
        },
        {
            key = 'NudgeX',
            renderer = 'number',
            name = 'nudge_x_name',
            description = 'nudge_x_description',
            default = DEFAULTS.NudgeX,
            argument = { integer = true, min = -600, max = 600 },
        },
        {
            key = 'NudgeY',
            renderer = 'number',
            name = 'nudge_y_name',
            description = 'nudge_y_description',
            default = DEFAULTS.NudgeY,
            argument = { integer = true, min = -600, max = 600 },
        },
        {
            key = 'TextSize',
            renderer = 'number',
            name = 'text_size_name',
            description = 'text_size_description',
            default = DEFAULTS.TextSize,
            argument = { integer = true, min = 8, max = 32 },
        },
        {
            key = 'TextColor',
            renderer = 'color',
            name = 'text_color_name',
            description = 'text_color_description',
            default = DEFAULTS.TextColor,
        },
        {
            key = 'TextAlignH',
            renderer = 'select',
            name = 'text_align_h_name',
            description = 'text_align_h_description',
            default = DEFAULTS.TextAlignH,
            argument = {
                l10n = L10N,
                items = { 'Left', 'Center', 'Right' },
            },
        },
        {
            key = 'TextAnchorV',
            renderer = 'select',
            name = 'text_anchor_v_name',
            description = 'text_anchor_v_description',
            default = DEFAULTS.TextAnchorV,
            argument = {
                l10n = L10N,
                items = { 'Top', 'Center', 'Bottom' },
            },
        },
        {
            key = 'ShowBackground',
            renderer = 'checkbox',
            name = 'show_background_name',
            description = 'show_background_description',
            default = DEFAULTS.ShowBackground,
        },
        {
            key = 'ShowBorder',
            renderer = 'checkbox',
            name = 'show_border_name',
            description = 'show_border_description',
            default = DEFAULTS.ShowBorder,
        },
        {
            key = 'BackgroundOpacity',
            renderer = 'number',
            name = 'background_opacity_name',
            description = 'background_opacity_description',
            default = DEFAULTS.BackgroundOpacity,
            argument = { integer = true, min = 0, max = 100 },
        },
        {
            key = 'UpdateInterval',
            renderer = 'number',
            name = 'update_interval_name',
            description = 'update_interval_description',
            default = DEFAULTS.UpdateInterval,
            argument = { min = 0.03, max = 1.00 },
        },
        {
            key = 'MaxDistance',
            renderer = 'number',
            name = 'max_distance_name',
            description = 'max_distance_description',
            default = DEFAULTS.MaxDistance,
            argument = { integer = true, min = 256, max = 32768 },
        },
        {
            key = 'DebugLog',
            renderer = 'checkbox',
            name = 'debug_log_name',
            description = 'debug_log_description',
            default = DEFAULTS.DebugLog,
        },
    },
}

local elapsed = 0
local overlay = nil
local overlayLayer = nil
local backgroundOverlay = nil
local backgroundLayer = nil
local borderOverlay = nil
local borderLayer = nil

local BACKGROUND_TEXTURE = 'textures/pxm/object_insight_tooltip/pxm_object_insight_tooltip_background.dds'
local BACKGROUND_RESOURCE = ui.texture { path = BACKGROUND_TEXTURE }
local BORDER_COLOR = color.rgb(0.78, 0.67, 0.38)
local BORDER_ALPHA = 0.95
local BORDER_THICKNESS = 2
local lastText = nil
local lastVisible = false
local printedLoaded = false
local printedFirstHit = false
local printedFirstMiss = false

local dragging = false
local dragTopLeftOffset = nil
local dragCenterOffset = nil
local dragPreviewCenter = nil
local dragUiDirty = false
local dragHoldTimer = 0
local dragPreviewOverlay = nil

local function getSetting(key)
    local value = settings:get(key)
    if value ~= nil then
        return value
    end

    -- Read old Object Source Tooltip settings as a fallback so the rename does
    -- not discard the user's previous position/appearance choices. New writes
    -- go to the renamed Object Insight Tooltip section.
    local legacyValue = legacySettings:get(key)
    if legacyValue ~= nil then
        return legacyValue
    end

    return DEFAULTS[key]
end

local function clamp(value, minValue, maxValue)
    value = tonumber(value) or minValue
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

local function round(value)
    if value >= 0 then
        return math.floor(value + 0.5)
    end
    return math.ceil(value - 0.5)
end

local function pxmLog(msg)
    if getSetting('DebugLog') then
        print('[PXM Object Insight Tooltip] ' .. tostring(msg))
    end
end

local function parseHexColor(value)
    if type(value) == 'userdata' or type(value) == 'table' then
        return value
    end

    if type(value) ~= 'string' then
        return color.rgb(0.90, 0.80, 0.49)
    end

    local hex = value:gsub('#', '')
    if #hex ~= 6 then
        return color.rgb(0.90, 0.80, 0.49)
    end

    local r = tonumber(hex:sub(1, 2), 16)
    local g = tonumber(hex:sub(3, 4), 16)
    local b = tonumber(hex:sub(5, 6), 16)
    if not r or not g or not b then
        return color.rgb(0.90, 0.80, 0.49)
    end

    return color.rgb(r / 255, g / 255, b / 255)
end

local function screenSizeSafe()
    local size = ui.screenSize()
    if not size or size.x <= 0 or size.y <= 0 then
        return v2(1920, 1080)
    end
    return size
end

local function getStoredCenterPixels()
    local screen = screenSizeSafe()
    local x = clamp(getSetting('PositionX'), 0, 100) / 100 * screen.x + clamp(getSetting('NudgeX'), -600, 600)
    local y = clamp(getSetting('PositionY'), 0, 100) / 100 * screen.y + clamp(getSetting('NudgeY'), -600, 600)
    return v2(clamp(x, 0, screen.x), clamp(y, 0, screen.y))
end

local function saveCenterPixels(center)
    local screen = screenSizeSafe()
    local x = clamp(center.x, 0, screen.x)
    local y = clamp(center.y, 0, screen.y)

    -- Store the nearest percentage plus a pixel nudge. This preserves the old
    -- settings UI while still allowing precise mouse placement.
    local positionX = round((x / screen.x) * 100)
    local positionY = round((y / screen.y) * 100)
    local nudgeX = round(x - (positionX / 100) * screen.x)
    local nudgeY = round(y - (positionY / 100) * screen.y)

    settings:set('PositionX', clamp(positionX, 0, 100))
    settings:set('PositionY', clamp(positionY, 0, 100))
    settings:set('NudgeX', clamp(nudgeX, -600, 600))
    settings:set('NudgeY', clamp(nudgeY, -600, 600))
end

local GLYPH_WIDTH = {
    [' '] = 0.32, ['.'] = 0.26, [','] = 0.26, [':'] = 0.26, [';'] = 0.26,
    ['!'] = 0.28, ['?'] = 0.45, ['|'] = 0.24, ['/'] = 0.34, ['\\'] = 0.34,
    ['('] = 0.32, [')'] = 0.32, ['['] = 0.32, [']'] = 0.32,
    ['+'] = 0.50, ['-'] = 0.34, ['='] = 0.50,
    ['0'] = 0.50, ['1'] = 0.42, ['2'] = 0.50, ['3'] = 0.50, ['4'] = 0.50,
    ['5'] = 0.50, ['6'] = 0.50, ['7'] = 0.50, ['8'] = 0.50, ['9'] = 0.50,
    ['i'] = 0.24, ['l'] = 0.25, ['I'] = 0.26, ['j'] = 0.28, ['t'] = 0.34,
    ['f'] = 0.34, ['r'] = 0.34, ['m'] = 0.78, ['w'] = 0.74, ['W'] = 0.82,
    ['M'] = 0.82,
}

local function estimateLineWidth(line, textSize)
    line = tostring(line or ''):gsub('#%x%x%x%x%x%x', '')
    local width = 0
    for char in line:gmatch('.') do
        width = width + (GLYPH_WIDTH[char] or 0.52)
    end
    return width * textSize
end

local function estimateTextBox(text)
    local textSize = clamp(getSetting('TextSize'), 8, 32)
    local body = tostring(text or lastText or '')

    local maxLineWidth = 1
    local lineCount = 0
    for line in (body .. '\n'):gmatch('(.-)\n') do
        lineCount = lineCount + 1
        local lineWidth = estimateLineWidth(line, textSize)
        if lineWidth > maxLineWidth then
            maxLineWidth = lineWidth
        end
    end
    if lineCount < 1 then
        lineCount = 1
    end

    -- One explicit padding value is used for every side. The box size is based
    -- on estimated rendered glyph widths instead of raw character count, so a
    -- row with many narrow letters no longer leaves a huge right-side gap.
    local padding = 8
    local paddingX = padding
    local paddingY = padding
    -- This size is for the invisible event-capturing wrapper, not for the
    -- visible MWUI box itself. It must be at least as tall as the auto-sized
    -- MWUI box; otherwise tall tooltips get clipped at the bottom.
    local estimatedLineHeight = textSize * 1.28
    local wrapperExtraY = 12

    local width = math.ceil(maxLineWidth + paddingX * 2)
    local height = math.ceil(lineCount * estimatedLineHeight + paddingY * 2 + wrapperExtraY)

    -- Keep the panel useful for long plugin names, but never allow it to run
    -- off-screen or become huge.
    local screen = screenSizeSafe()
    width = clamp(width, 80, math.max(80, screen.x - 24))
    height = clamp(height, 28, math.max(28, screen.y - 24))

    return v2(width, height), paddingX, paddingY
end

local function getVerticalAnchorY()
    local value = tostring(getSetting('TextAnchorV') or 'Center')
    if value == 'Top' then
        return 0
    elseif value == 'Bottom' then
        return 1
    end
    return 0.5
end

local function getHorizontalAnchorX()
    -- Match the panel anchor to the chosen text alignment. This keeps the
    -- left edge stable for left-aligned text and the right edge stable for
    -- right-aligned text even when the tooltip width changes.
    local value = tostring(getSetting('TextAlignH') or 'Center')
    if value == 'Left' then
        return 0
    elseif value == 'Right' then
        return 1
    end
    return 0.5
end

local function anchorPointToTopLeft(anchorPoint, boxSize)
    local anchorX = getHorizontalAnchorX()
    local anchorY = getVerticalAnchorY()
    boxSize = boxSize or v2(0, 0)
    anchorPoint = anchorPoint or getStoredCenterPixels()

    return v2(
        anchorPoint.x - boxSize.x * anchorX,
        anchorPoint.y - boxSize.y * anchorY
    )
end

local function topLeftToAnchorPoint(topLeft, boxSize)
    local anchorX = getHorizontalAnchorX()
    local anchorY = getVerticalAnchorY()
    boxSize = boxSize or v2(0, 0)
    topLeft = topLeft or v2(0, 0)

    return v2(
        topLeft.x + boxSize.x * anchorX,
        topLeft.y + boxSize.y * anchorY
    )
end

local function clampTopLeftToScreen(topLeft, boxSize)
    local screen = screenSizeSafe()
    local margin = 8
    boxSize = boxSize or v2(0, 0)
    topLeft = topLeft or v2(0, 0)

    local minX = margin
    local minY = margin
    local maxX = screen.x - boxSize.x - margin
    local maxY = screen.y - boxSize.y - margin

    -- Very large tooltips should still remain draggable instead of inverting
    -- the clamp range.
    if maxX < minX then
        maxX = minX
    end
    if maxY < minY then
        maxY = minY
    end

    return v2(
        clamp(topLeft.x, minX, maxX),
        clamp(topLeft.y, minY, maxY)
    )
end

local function clampAnchorPointToScreen(anchorPoint, boxSize)
    local topLeft = anchorPointToTopLeft(anchorPoint, boxSize)
    topLeft = clampTopLeftToScreen(topLeft, boxSize)
    return topLeftToAnchorPoint(topLeft, boxSize)
end

local function overlayPositionProps(boxSize)
    local screen = screenSizeSafe()
    local anchorPoint = clampAnchorPointToScreen(getStoredCenterPixels(), boxSize)
    local topLeft = anchorPointToTopLeft(anchorPoint, boxSize)

    -- Use a top-left anchored root widget regardless of text alignment. Alignment
    -- only decides which point is saved/dragged inside the box. This avoids the
    -- old problem where right/bottom anchored roots were clamped using one size
    -- while OpenMW laid out the MWUI box with another size.
    return v2(topLeft.x / screen.x, topLeft.y / screen.y), v2(0, 0)
end

local function forceOverlayUpdate()
    -- Do not assign nil to overlay.layout. OpenMW expects a layout table there,
    -- and setting it to nil breaks the widget permanently after dragging.
    -- Destroy and recreate the widget instead.
    if overlay then
        overlay:destroy()
        overlay = nil
        overlayLayer = nil
    end
    if backgroundOverlay then
        backgroundOverlay:destroy()
        backgroundOverlay = nil
        backgroundLayer = nil
    end
    if borderOverlay then
        borderOverlay:destroy()
        borderOverlay = nil
        borderLayer = nil
    end
    lastVisible = nil
end


local function stripInlineColors(text)
    if not text then
        return ''
    end
    return tostring(text):gsub('#%x%x%x%x%x%x', '')
end

local function destroyDragPreview()
    if dragPreviewOverlay then
        dragPreviewOverlay:destroy()
        dragPreviewOverlay = nil
    end
end

local getTextAlignment

local function makeTooltipRows(text, stripColors)
    local textSize = clamp(getSetting('TextSize'), 8, 32)
    local body = tostring(text or lastText or '')
    local rows = {}
    local padV = math.max(2, math.floor(textSize * 0.20))
    local textColor = getSetting('UseInlineColors') and not stripColors and color.rgb(1, 1, 1) or parseHexColor(getSetting('TextColor'))

    -- Let OpenMW/MWUI size the box from the actual text widgets. The leading
    -- and trailing spaces are intentional horizontal padding, matching the
    -- approach used by other OpenMW tooltip mods that rely on boxTransparent.
    rows[#rows + 1] = { props = { size = v2(0, padV) } }

    for line in (body .. '\n'):gmatch('(.-)\n') do
        if line == '' then
            rows[#rows + 1] = { props = { size = v2(0, math.max(4, math.floor(textSize * 0.45))) } }
        else
            if stripColors then
                line = stripInlineColors(line)
            end
            rows[#rows + 1] = {
                type = ui.TYPE.Text,
                template = I.MWUI.templates.textNormal,
                props = {
                    text = ' ' .. line .. ' ',
                    textSize = textSize,
                    textColor = textColor,
                    textAlignH = getTextAlignment(),
                    textShadow = true,
                    textShadowColor = color.rgb(0, 0, 0),
                    visible = true,
                    propagateEvents = false,
                },
            }
        end
    end

    rows[#rows + 1] = { props = { size = v2(0, padV) } }
    return rows
end

local onMousePress
local onMouseMove
local onMouseRelease


local function makeTooltipBox(text, visible, props, includeEvents, stripColors)
    local boxSize = props and props.size or estimateTextBox(text)

    local rowsFlex = {
        type = ui.TYPE.Flex,
        props = {
            arrange = getTextAlignment(),
            visible = visible,
            propagateEvents = true,
        },
        content = ui.content(makeTooltipRows(text, stripColors)),
    }

    local contentRoot
    if getSetting('ShowBorder') then
        -- boxTransparent is kept as an inner auto-sized visual box. Mouse events
        -- are captured by a transparent top hitbox below, because text/box
        -- template children can eat clicks before the root receives them.
        contentRoot = {
            template = I.MWUI.templates.boxTransparent,
            props = {
                name = 'PXMObjectInsightTooltipBox',
                visible = visible,
                propagateEvents = false,
            },
            content = ui.content({ rowsFlex }),
        }
    else
        contentRoot = rowsFlex
    end

    local content = { contentRoot }

    if includeEvents then
        -- Full-size invisible mouse target placed ABOVE the text/box. This makes
        -- dragging work from any part of the tooltip, including text rows, while
        -- keeping the MWUI auto-sized visual box.
        content[#content + 1] = {
            name = 'PXMObjectInsightTooltipDragHitbox',
            type = ui.TYPE.Image,
            props = {
                relativePosition = v2(0, 0),
                position = v2(0, 0),
                anchor = v2(0, 0),
                size = boxSize,
                resource = BACKGROUND_RESOURCE,
                color = color.rgb(0, 0, 0),
                alpha = 0.001,
                visible = visible,
                propagateEvents = true,
            },
            events = {
                mousePress = onMousePress,
                mouseMove = onMouseMove,
                mouseRelease = onMouseRelease,
            },
        }
    end

    local root = {
        layer = 'Windows',
        type = ui.TYPE.Widget,
        props = props,
        content = ui.content(content),
    }

    if includeEvents then
        root.events = {
            mousePress = onMousePress,
            mouseMove = onMouseMove,
            mouseRelease = onMouseRelease,
        }
    end

    return root
end

local function makeDragPreview(text)
    local anchorPoint = dragPreviewCenter or getStoredCenterPixels()
    local body = text or lastText or ''
    return makeTooltipBox(body, true, {
        name = 'PXMObjectInsightTooltipDragPreview',
        position = anchorPoint,
        anchor = v2(0, 0),
        size = estimateTextBox(body),
        visible = true,
        propagateEvents = false,
    }, false, true)
end

local function updateDragPreview(force)
    if not dragging then
        destroyDragPreview()
        return
    end

    if not force and not dragUiDirty then
        return
    end

    if not dragPreviewOverlay then
        dragPreviewOverlay = ui.create(makeDragPreview(lastText or ''))
    else
        dragPreviewOverlay.layout = makeDragPreview(lastText or '')
        dragPreviewOverlay:update()
    end
    dragUiDirty = false
end

function getTextAlignment()
    -- OpenMW's alignment enum is Start / Center / End, not Left / Right.
    -- The settings values stay user-friendly, but we map them to the real enum.
    local value = tostring(getSetting('TextAlignH') or 'Center')
    if value == 'Left' then
        return ui.ALIGNMENT.Start
    elseif value == 'Right' then
        return ui.ALIGNMENT.End
    end
    return ui.ALIGNMENT.Center
end

local function getBackgroundOpacity()
    return clamp(getSetting('BackgroundOpacity'), 0, 100) / 100
end

local function makeBorderOverlay(text, visible)
    local boxSize = estimateTextBox(text)
    local relativePosition, position = overlayPositionProps(boxSize)
    local shouldShow = visible and getSetting('ShowBorder')
    local t = BORDER_THICKNESS
    local w = boxSize.x
    local h = boxSize.y

    local function line(name, pos, size)
        return {
            name = name,
            type = ui.TYPE.Image,
            props = {
                relativePosition = v2(0, 0),
                position = pos,
                anchor = v2(0, 0),
                size = size,
                resource = BACKGROUND_RESOURCE,
                color = BORDER_COLOR,
                alpha = BORDER_ALPHA,
                visible = shouldShow,
                propagateEvents = false,
            },
        }
    end

    return {
        layer = 'Windows',
        type = ui.TYPE.Widget,
        props = {
            name = 'PXMObjectInsightTooltipBorder',
            relativePosition = relativePosition,
            position = position,
            anchor = v2(getHorizontalAnchorX(), getVerticalAnchorY()),
            size = boxSize,
            visible = shouldShow,
            propagateEvents = false,
        },
        content = ui.content({
            line('borderTop', v2(0, 0), v2(w, t)),
            line('borderBottom', v2(0, math.max(0, h - t)), v2(w, t)),
            line('borderLeft', v2(0, 0), v2(t, h)),
            line('borderRight', v2(math.max(0, w - t), 0), v2(t, h)),
        }),
    }
end

local function destroyBorderOverlay()
    if borderOverlay then
        borderOverlay:destroy()
        borderOverlay = nil
        borderLayer = nil
    end
end

local function makeBackgroundOverlay(text, visible)
    local boxSize = estimateTextBox(text)
    local relativePosition, position = overlayPositionProps(boxSize)
    local shouldShow = visible and getSetting('ShowBackground')

    return {
        layer = 'Windows',
        type = ui.TYPE.Image,
        props = {
            name = 'PXMObjectInsightTooltipBackground',
            relativePosition = relativePosition,
            position = position,
            anchor = v2(getHorizontalAnchorX(), getVerticalAnchorY()),
            size = boxSize,
            resource = BACKGROUND_RESOURCE,
            color = color.rgb(0, 0, 0),
            alpha = getBackgroundOpacity(),
            visible = shouldShow,
            propagateEvents = false,
        },
    }
end

local function destroyBackgroundOverlay()
    if backgroundOverlay then
        backgroundOverlay:destroy()
        backgroundOverlay = nil
        backgroundLayer = nil
    end
    if borderOverlay then
        borderOverlay:destroy()
        borderOverlay = nil
        borderLayer = nil
    end
end

local function makeOverlay(text, visible)
    local body = text or lastText or ''
    local shouldShow = visible or dragging
    local boxSize = estimateTextBox(body)
    local relativePosition, position = overlayPositionProps(boxSize)

    -- Use OpenMW's MWUI box template and individual text rows. This lets the UI
    -- size the visible box from the rendered text instead of relying on manual
    -- width/height guesses for the background and border.
    return makeTooltipBox(body, shouldShow, {
        name = 'PXMObjectInsightTooltipRoot',
        relativePosition = relativePosition,
        position = position,
        anchor = v2(0, 0),
        size = boxSize,
        visible = shouldShow,
        propagateEvents = true,
    }, true, false)
end

local function setOverlay(text, force)
    local visible = text ~= nil and text ~= ''

    -- Keep the previous visible text while dragging. Menus can temporarily break
    -- the crosshair hit, and without this the widget disappears under the mouse.
    if dragging and not visible and lastText and lastText ~= '' then
        text = lastText
        visible = true
    end

    local desiredLayer = 'Windows'
    if overlay and overlayLayer ~= desiredLayer then
        overlay:destroy()
        overlay = nil
        overlayLayer = nil
        lastText = nil
        lastVisible = nil
    end

    -- The old implementation used separate root widgets for background/border.
    -- Destroy any leftovers when upgrading/reloading into the MWUI box layout.
    destroyBackgroundOverlay()
    destroyBorderOverlay()

    if not force and text == lastText and visible == lastVisible then
        return
    end

    if text and text ~= '' then
        lastText = text
    end
    lastVisible = visible

    if force and overlay then
        overlay:destroy()
        overlay = nil
        overlayLayer = nil
    end

    if not overlay then
        overlay = ui.create(makeOverlay(text, visible))
        overlayLayer = desiredLayer
        return
    end

    overlay.layout = makeOverlay(text, visible)
    overlay:update()
end

local function moveMainOverlayTopLeftTo(topLeft)
    local boxSize = estimateTextBox(lastText or '')
    topLeft = clampTopLeftToScreen(topLeft, boxSize)
    local anchorPoint = topLeftToAnchorPoint(topLeft, boxSize)

    saveCenterPixels(anchorPoint)
    dragPreviewCenter = anchorPoint

    if overlay then
        overlay.layout = makeOverlay(lastText, true)
        overlay:update()
    else
        setOverlay(lastText, true)
    end
end

onMousePress = async:callback(function(event)
    if not event or not event.position then
        return true
    end

    dragging = true
    local boxSize = estimateTextBox(lastText or '')
    local anchorPoint = clampAnchorPointToScreen(getStoredCenterPixels(), boxSize)
    local topLeft = anchorPointToTopLeft(anchorPoint, boxSize)

    dragTopLeftOffset = topLeft - event.position
    dragCenterOffset = nil
    dragPreviewCenter = anchorPoint
    dragUiDirty = false

    -- Move the real tooltip itself instead of creating a second preview widget.
    -- This avoids duplicate boxes, release-position mismatch, and stuck preview
    -- overlays if the mouse release event is swallowed by another UI layer.
    destroyDragPreview()
    moveMainOverlayTopLeftTo(topLeft)
    return true
end)

onMouseMove = async:callback(function(event)
    if not dragging or not event or not event.position then
        return true
    end

    local topLeft = event.position + dragTopLeftOffset
    moveMainOverlayTopLeftTo(topLeft)
    return true
end)

onMouseRelease = async:callback(function(event)
    if not dragging then
        return true
    end

    if dragPreviewCenter then
        saveCenterPixels(clampAnchorPointToScreen(dragPreviewCenter, estimateTextBox(lastText or '')))
    end

    local savedText = lastText
    dragging = false
    dragTopLeftOffset = nil
    dragCenterOffset = nil
    dragPreviewCenter = nil
    dragUiDirty = false
    destroyDragPreview()

    -- Menus can make the crosshair/raycast temporarily miss immediately after
    -- releasing the mouse. Keep the last tooltip alive briefly so the widget
    -- does not vanish right after being placed.
    dragHoldTimer = 1.5

    setOverlay(savedText, true)
    return true
end)

local WEAPON_TYPE_TO_TEXT = {
    [0] = 'Short Blade, One Handed',
    [1] = 'Long Blade, One Handed',
    [2] = 'Long Blade, Two Handed',
    [3] = 'Blunt Weapon, One Handed',
    [4] = 'Blunt Weapon, Two Handed',
    [5] = 'Blunt Weapon, Two Handed',
    [6] = 'Spear, Two Handed',
    [7] = 'Axe, One Handed',
    [8] = 'Axe, Two Handed',
    [9] = 'Marksman Bow',
    [10] = 'Marksman Crossbow',
    [11] = 'Marksman Thrown',
    [12] = 'Arrow',
    [13] = 'Bolt',
}

local RANGED_WEAPON = { [9] = true, [10] = true, [11] = true }
local RANGED_AMMO = { [12] = true, [13] = true }

local ARMOR_TYPE_TO_TEXT = {
    [0] = 'Helmet',
    [1] = 'Cuirass',
    [2] = 'Left Pauldron',
    [3] = 'Right Pauldron',
    [4] = 'Greaves',
    [5] = 'Boots',
    [6] = 'Left Gauntlet',
    [7] = 'Right Gauntlet',
    [8] = 'Shield',
    [9] = 'Left Bracer',
    [10] = 'Right Bracer',
}

local CLOTHING_TYPE_TO_TEXT = {
    [0] = 'Pants',
    [1] = 'Shoes',
    [2] = 'Shirt',
    [3] = 'Belt',
    [4] = 'Robe',
    [5] = 'Right Glove',
    [6] = 'Left Glove',
    [7] = 'Skirt',
    [8] = 'Ring',
    [9] = 'Amulet',
}

local APPARATUS_TYPE_TO_TEXT = {
    [0] = 'Mortar and Pestle',
    [1] = 'Alembic',
    [2] = 'Calcinator',
    [3] = 'Retort',
}

local function colorTag(hex, text)
    if not getSetting('UseInlineColors') then
        return tostring(text)
    end
    return tostring(hex) .. tostring(text)
end

local function addLine(lines, label, value, valueColor)
    if value == nil or value == '' then
        return
    end

    if getSetting('UseInlineColors') then
        lines[#lines + 1] = '#caa560' .. label .. ' ' .. tostring(valueColor or '#f5f0d0') .. tostring(value)
    else
        lines[#lines + 1] = label .. ' ' .. tostring(value)
    end
end

local function addBlank(lines)
    lines[#lines + 1] = ''
end

local fmtNumber
local safeGetEquipment

local function cmpColor(delta, higherIsBetter)
    local d = tonumber(delta) or 0
    if math.abs(d) < 0.05 then
        return '#d4c46f'
    end
    if higherIsBetter then
        return d > 0 and '#73bd80' or '#FF7373'
    end
    return d < 0 and '#73bd80' or '#FF7373'
end

local function cmpSign(delta, decimals)
    local d = tonumber(delta) or 0
    decimals = decimals or 0
    if math.abs(d) < 0.0001 then
        return '+0'
    end
    local fmt = '%.' .. tostring(decimals) .. 'f'
    local v = string.format(fmt, d)

    -- Only trim decimal padding when decimals were requested.
    -- With decimals=0, values like +70 must stay +70, not become +7.
    if decimals > 0 then
        v = v:gsub('0+$', ''):gsub('%.$', '')
    end

    if d > 0 then
        return '+' .. v
    end
    return v
end

local function compareDelta(value, equippedValue, decimals, higherIsBetter)
    local v = tonumber(value)
    local e = tonumber(equippedValue)
    if not v or not e then return nil, nil end
    local delta = v - e
    return delta, cmpColor(delta, higherIsBetter)
end

local function addDeltaToText(text, delta, decimals)
    if delta == nil then
        return text
    end
    return tostring(text) .. ' (' .. cmpSign(delta, decimals) .. ')'
end

function fmtNumber(value, decimals)
    local n = tonumber(value)
    if not n then return nil end
    decimals = decimals or 0
    if decimals <= 0 then
        return tostring(round(n))
    end
    local s = string.format('%.' .. tostring(decimals) .. 'f', n)
    s = s:gsub('0+$', ''):gsub('%.$', '')
    return s
end

local function fmtRange(minValue, maxValue)
    local mn = tonumber(minValue)
    local mx = tonumber(maxValue)
    if not mn or not mx then return nil end
    return string.format('%d - %d', mn, mx)
end

local function safeRecord(obj)
    if not obj or not obj.type or not obj.type.record then
        return nil
    end
    local ok, record = pcall(obj.type.record, obj)
    if ok then
        return record
    end
    return nil
end

local function safeItemData(obj)
    if not obj or not obj.type or not obj.type.itemData then
        return nil
    end
    local ok, data = pcall(obj.type.itemData, obj)
    if ok then
        return data
    end
    return nil
end

local function safeEnchantCost(enchantId)
    if not enchantId then return nil end
    local ok, ench = pcall(function()
        return core.magic.enchantments.records[enchantId]
    end)
    if ok and ench then
        return tonumber(ench.cost) or 0
    end
    return nil
end

local function getDpsRange(obj, record)
    if not obj or obj.type ~= types.Weapon or not record then
        return nil, nil
    end

    local speed = tonumber(record.speed) or 0
    if speed <= 0 then
        return nil, nil
    end

    if RANGED_WEAPON[record.type] or RANGED_AMMO[record.type] then
        local minDmg = tonumber(record.chopMinDamage) or 0
        local maxDmg = tonumber(record.chopMaxDamage) or 0
        if maxDmg <= 0 then return nil, nil end
        return minDmg * speed, maxDmg * speed
    end

    local chopMin = tonumber(record.chopMinDamage) or 0
    local chopMax = tonumber(record.chopMaxDamage) or 0
    local slashMin = tonumber(record.slashMinDamage) or 0
    local slashMax = tonumber(record.slashMaxDamage) or 0
    local thrustMin = tonumber(record.thrustMinDamage) or 0
    local thrustMax = tonumber(record.thrustMaxDamage) or 0

    local chopAvg = chopMin + chopMax
    local slashAvg = slashMin + slashMax
    local thrustAvg = thrustMin + thrustMax

    local bestMin, bestMax = chopMin, chopMax
    if slashAvg >= thrustAvg and slashAvg >= chopAvg then
        bestMin, bestMax = slashMin, slashMax
    elseif thrustAvg >= slashAvg and thrustAvg >= chopAvg then
        bestMin, bestMax = thrustMin, thrustMax
    end

    if bestMax <= 0 then return nil, nil end
    return bestMin * speed, bestMax * speed
end

local function getBestDamageAverage(record)
    if not record then return nil end

    local chopMin = tonumber(record.chopMinDamage) or 0
    local chopMax = tonumber(record.chopMaxDamage) or 0
    local slashMin = tonumber(record.slashMinDamage) or 0
    local slashMax = tonumber(record.slashMaxDamage) or 0
    local thrustMin = tonumber(record.thrustMinDamage) or 0
    local thrustMax = tonumber(record.thrustMaxDamage) or 0

    if RANGED_WEAPON[record.type] or RANGED_AMMO[record.type] then
        if chopMax <= 0 then return nil end
        return (chopMin + chopMax) * 0.5
    end

    local chopAvg = (chopMin + chopMax) * 0.5
    local slashAvg = (slashMin + slashMax) * 0.5
    local thrustAvg = (thrustMin + thrustMax) * 0.5
    local best = math.max(chopAvg, slashAvg, thrustAvg)
    if best <= 0 then return nil end
    return best
end

local function getAverageDps(obj, record)
    local minDps, maxDps = getDpsRange(obj, record)
    if not minDps or not maxDps then return nil end
    return (minDps + maxDps) * 0.5
end

local WEAPON_TYPE_TO_SKILL = {
    [0] = 'shortblade',
    [1] = 'longblade',
    [2] = 'longblade',
    [3] = 'bluntweapon',
    [4] = 'bluntweapon',
    [5] = 'bluntweapon',
    [6] = 'spear',
    [7] = 'axe',
    [8] = 'axe',
    [9] = 'marksman',
    [10] = 'marksman',
    [11] = 'marksman',
    [12] = 'marksman',
    [13] = 'marksman',
}

local function safeSkillValue(skillKey)
    local fn = skillKey and types.NPC.stats.skills[skillKey]
    if not fn then return nil end
    local ok, stat = pcall(fn, self)
    if ok and stat then
        return tonumber(stat.modified or stat.base)
    end
    return nil
end

local function safeAttributeValue(attributeKey)
    local fn = attributeKey and types.Actor.stats.attributes[attributeKey]
    if not fn then return nil end
    local ok, stat = pcall(fn, self)
    if ok and stat then
        return tonumber(stat.modified or stat.base)
    end
    return nil
end

local function getFatigueTerm()
    local ok, stat = pcall(types.Actor.stats.dynamic.fatigue, self)
    if not ok or not stat then
        return 1
    end

    local current = tonumber(stat.current)
    local base = tonumber(stat.base)
    local modifier = tonumber(stat.modifier) or 0
    local maxFatigue = (base or 0) + modifier
    if not current or maxFatigue <= 0 then
        return 1
    end

    -- Vanilla-style fatigue influence: low fatigue penalizes performance and
    -- high/full fatigue gives a small bonus. This is an estimate for display;
    -- exact combat also depends on target stats and attack state.
    return clamp(0.75 + 0.5 * (current / maxFatigue), 0.25, 1.25)
end

local function getConditionRatio(obj, record)
    local maxCondition = record and tonumber(record.health or record.maxCondition or record.duration)
    if not maxCondition or maxCondition <= 0 then
        return 1
    end

    local data = safeItemData(obj)
    local condition = data and tonumber(data.condition)
    if not condition then
        return 1
    end

    return clamp(condition / maxCondition, 0, 1)
end

local function getBestDamageRange(record)
    if not record then return nil, nil end

    local chopMin = tonumber(record.chopMinDamage) or 0
    local chopMax = tonumber(record.chopMaxDamage) or 0
    local slashMin = tonumber(record.slashMinDamage) or 0
    local slashMax = tonumber(record.slashMaxDamage) or 0
    local thrustMin = tonumber(record.thrustMinDamage) or 0
    local thrustMax = tonumber(record.thrustMaxDamage) or 0

    if RANGED_WEAPON[record.type] or RANGED_AMMO[record.type] then
        if chopMax <= 0 then return nil, nil end
        return chopMin, chopMax
    end

    local chopAvg = chopMin + chopMax
    local slashAvg = slashMin + slashMax
    local thrustAvg = thrustMin + thrustMax

    local bestMin, bestMax = chopMin, chopMax
    if slashAvg >= thrustAvg and slashAvg >= chopAvg then
        bestMin, bestMax = slashMin, slashMax
    elseif thrustAvg >= slashAvg and thrustAvg >= chopAvg then
        bestMin, bestMax = thrustMin, thrustMax
    end

    if bestMax <= 0 then return nil, nil end
    return bestMin, bestMax
end

local function isCompatibleAmmoForLauncher(ammoRecord, launcherRecord)
    if not ammoRecord or not launcherRecord then return false end
    if launcherRecord.type == 9 then
        return ammoRecord.type == 12
    elseif launcherRecord.type == 10 then
        return ammoRecord.type == 13
    end
    return false
end

local function getLauncherAndAmmoFor(record)
    local slot = types.Actor.EQUIPMENT_SLOT
    local right = safeGetEquipment(slot.CarriedRight)
    local rightRecord = right and right.type == types.Weapon and safeRecord(right) or nil
    local ammo = safeGetEquipment(slot.Ammunition)
    local ammoRecord = ammo and ammo.type == types.Weapon and safeRecord(ammo) or nil

    if record and RANGED_AMMO[record.type] then
        if rightRecord and isCompatibleAmmoForLauncher(record, rightRecord) then
            return right, rightRecord, nil, record
        end
        return nil, nil, nil, record
    end

    if record and (record.type == 9 or record.type == 10) then
        if ammoRecord and isCompatibleAmmoForLauncher(ammoRecord, record) then
            return nil, record, ammo, ammoRecord
        end
        return nil, record, nil, nil
    end

    return nil, record, nil, nil
end

local function getPlayerAdjustedDps(obj, record)
    if not obj or obj.type ~= types.Weapon or not record then
        return nil
    end

    local launcherObj, launcherRecord, ammoObj, ammoRecord = getLauncherAndAmmoFor(record)
    local speedRecord = launcherRecord or record
    local speed = tonumber(speedRecord.speed) or 0
    if speed <= 0 then
        return nil
    end

    local minDamage, maxDamage = getBestDamageRange(record)
    if not minDamage or not maxDamage then
        return nil
    end

    if launcherRecord and launcherRecord ~= record then
        local launcherMin, launcherMax = getBestDamageRange(launcherRecord)
        if not launcherMin or not launcherMax then
            return nil
        end
        minDamage = minDamage + launcherMin
        maxDamage = maxDamage + launcherMax
    elseif ammoRecord then
        local ammoMin, ammoMax = getBestDamageRange(ammoRecord)
        if ammoMin and ammoMax then
            minDamage = minDamage + ammoMin
            maxDamage = maxDamage + ammoMax
        end
    elseif RANGED_AMMO[record.type] then
        -- Arrows/bolts cannot produce a meaningful launcher-based DPS without
        -- a compatible equipped bow/crossbow.
        return nil
    end

    local averageDamage = (minDamage + maxDamage) * 0.5
    local strength = safeAttributeValue('strength') or 50
    local skill = safeSkillValue(WEAPON_TYPE_TO_SKILL[speedRecord.type] or WEAPON_TYPE_TO_SKILL[record.type]) or 30
    local agility = safeAttributeValue('agility') or 50
    local luck = safeAttributeValue('luck') or 50
    local fatigueTerm = getFatigueTerm()
    local conditionTerm = getConditionRatio(obj, record)

    if launcherObj and launcherRecord and launcherRecord ~= record then
        conditionTerm = conditionTerm * getConditionRatio(launcherObj, launcherRecord)
    end
    if ammoObj and ammoRecord then
        -- Ammo stacks normally do not degrade, but keep this future-proof.
        conditionTerm = conditionTerm * getConditionRatio(ammoObj, ammoRecord)
    end

    local strengthTerm = 0.5 + strength / 100

    -- Target evasion is unknown when looking at an item. Use the player's
    -- offensive score as an expected-hit multiplier against a neutral target.
    local hitTerm = clamp((skill + agility / 5 + luck / 10) * fatigueTerm / 100, 0.05, 1.00)

    return averageDamage * speed * strengthTerm * conditionTerm * hitTerm
end

function safeGetEquipment(slot)
    if not slot then return nil end
    local ok, item = pcall(types.Actor.getEquipment, self, slot)
    if ok and item and item.isValid and item:isValid() then
        return item
    elseif ok and item then
        return item
    end
    return nil
end

local function getWeaponCompareSlot(record)
    if not record then return nil end
    local slot = types.Actor.EQUIPMENT_SLOT
    if RANGED_AMMO[record.type] then
        return slot.Ammunition, 'ammunition'
    end
    return slot.CarriedRight, 'weapon'
end

local ARMOR_TYPE_TO_SLOT = {
    [0] = function(slot) return slot.Helmet end,
    [1] = function(slot) return slot.Cuirass end,
    [2] = function(slot) return slot.LeftPauldron end,
    [3] = function(slot) return slot.RightPauldron end,
    [4] = function(slot) return slot.Greaves end,
    [5] = function(slot) return slot.Boots end,
    [6] = function(slot) return slot.LeftGauntlet end,
    [7] = function(slot) return slot.RightGauntlet end,
    [8] = function(slot) return slot.CarriedLeft end,
    [9] = function(slot) return slot.LeftGauntlet end,
    [10] = function(slot) return slot.RightGauntlet end,
}

local function getArmorCompareSlot(record)
    if not record then return nil end
    local slot = types.Actor.EQUIPMENT_SLOT
    local resolver = ARMOR_TYPE_TO_SLOT[record.type]
    if not resolver then return nil end
    return resolver(slot)
end

local function getEquippedName(item, record)
    local rec = record or safeRecord(item)
    if rec and rec.name and rec.name ~= '' then
        return rec.name
    end
    if item and item.recordId then
        return item.recordId
    end
    return '<unknown>'
end

local function getWeaponComparisonInfo(obj, record)
    if not getSetting('ShowEquipmentCompare') or not record then return nil end

    local slot = getWeaponCompareSlot(record)
    local equipped = safeGetEquipment(slot)
    if not equipped or equipped == obj or equipped.recordId == obj.recordId then
        return nil
    end

    if equipped.type ~= types.Weapon then
        return nil
    end

    local equippedRecord = safeRecord(equipped)
    if not equippedRecord then return nil end

    local rawDps = getAverageDps(obj, record)
    local equippedRawDps = getAverageDps(equipped, equippedRecord)
    local rawDpsDelta, rawDpsColor = compareDelta(rawDps, equippedRawDps, 1, true)

    local effectiveDps = getPlayerAdjustedDps(obj, record)
    local equippedEffectiveDps = getPlayerAdjustedDps(equipped, equippedRecord)
    local effectiveDpsDelta, effectiveDpsColor = compareDelta(effectiveDps, equippedEffectiveDps, 1, true)

    return {
        equippedName = getEquippedName(equipped, equippedRecord),
        rawDpsDelta = rawDpsDelta,
        rawDpsColor = rawDpsColor,
        effectiveDpsDelta = effectiveDpsDelta,
        effectiveDpsColor = effectiveDpsColor,
    }
end

local ARMOR_SLOT_BASE_WEIGHT = {
    [0] = 5,   -- helmet
    [1] = 30,  -- cuirass
    [2] = 10,  -- left pauldron
    [3] = 10,  -- right pauldron
    [4] = 15,  -- greaves
    [5] = 20,  -- boots
    [6] = 5,   -- left gauntlet
    [7] = 5,   -- right gauntlet
    [8] = 15,  -- shield
    [9] = 5,   -- left bracer
    [10] = 5,  -- right bracer
}

local function getArmorSkillKey(record)
    if not record then return nil end
    local weight = tonumber(record.weight) or 0
    local baseWeight = ARMOR_SLOT_BASE_WEIGHT[record.type]
    if not baseWeight or baseWeight <= 0 then
        return nil
    end

    -- TES3 armor class is derived from item weight relative to the slot's
    -- base weight: <=50% light, <=90% medium, otherwise heavy.
    if weight <= baseWeight * 0.5 then
        return 'lightarmor'
    elseif weight <= baseWeight * 0.9 then
        return 'mediumarmor'
    end
    return 'heavyarmor'
end

local function getArmorRatingValue(record)
    if not record then return nil end
    local ar = tonumber(record.baseArmor)
    if not ar then return nil end

    -- OpenMW exposes the armor record's base armor rating in the same units
    -- used by the item data. Do not scale small values up: low-tier armor can
    -- legitimately have values such as 1 or 5. Scaling here made items like the
    -- Nordic Fur Helm show 50 instead of the expected low armor value.
    return ar
end

local function getPlayerAdjustedArmorRating(obj, record)
    local base = getArmorRatingValue(record)
    if not base then return nil end

    local skillKey = getArmorSkillKey(record)
    local skill = safeSkillValue(skillKey) or 30
    local conditionTerm = getConditionRatio(obj, record)

    return base * (skill / 30) * conditionTerm
end

local function getArmorComparisonInfo(obj, record)
    if not getSetting('ShowEquipmentCompare') or not record then return nil end

    local slot = getArmorCompareSlot(record)
    local equipped = safeGetEquipment(slot)
    if not equipped or equipped == obj or equipped.recordId == obj.recordId then
        return nil
    end

    if equipped.type ~= types.Armor then
        return nil
    end

    local equippedRecord = safeRecord(equipped)
    if not equippedRecord then return nil end

    local rawArValue = getArmorRatingValue(record)
    local equippedRawArValue = getArmorRatingValue(equippedRecord)
    local rawArDelta, rawArColor = compareDelta(rawArValue, equippedRawArValue, 0, true)

    local effectiveArValue = getPlayerAdjustedArmorRating(obj, record)
    local equippedEffectiveArValue = getPlayerAdjustedArmorRating(equipped, equippedRecord)
    local effectiveArDelta, effectiveArColor = compareDelta(effectiveArValue, equippedEffectiveArValue, 1, true)

    return {
        equippedName = getEquippedName(equipped, equippedRecord),
        rawArDelta = rawArDelta,
        rawArColor = rawArColor,
        effectiveArDelta = effectiveArDelta,
        effectiveArColor = effectiveArColor,
    }
end

local function addRawDpsLine(lines, obj, record, comparisonInfo)
    local minDps, maxDps = getDpsRange(obj, record)
    if not minDps or not maxDps then return end
    local avgDps = (minDps + maxDps) * 0.5
    local lineColor = comparisonInfo and comparisonInfo.rawDpsColor or '#73bd80'
    local dpsDelta = comparisonInfo and comparisonInfo.rawDpsDelta or nil
    if math.abs(minDps - maxDps) < 0.05 then
        local text = addDeltaToText(string.format('%.1f', maxDps), dpsDelta, 1)
        addLine(lines, 'Base DPS:', text, lineColor)
    else
        local text = string.format('%.1f avg  (%0.1f - %0.1f)', avgDps, minDps, maxDps)
        text = addDeltaToText(text, dpsDelta, 1)
        addLine(lines, 'Base DPS:', text, lineColor)
    end
end

local function addEffectiveDpsLine(lines, obj, record, comparisonInfo)
    local effectiveDps = getPlayerAdjustedDps(obj, record)
    if not effectiveDps then
        return
    end

    local lineColor = comparisonInfo and comparisonInfo.effectiveDpsColor or '#73bd80'
    local dpsDelta = comparisonInfo and comparisonInfo.effectiveDpsDelta or nil
    local text = addDeltaToText(fmtNumber(effectiveDps, 1), dpsDelta, 1)
    addLine(lines, 'Effective DPS:', text, lineColor)
end

local function addEnchantStats(lines, record)
    if not getSetting('ShowEnchantStats') or not record then
        return
    end

    if record.enchant then
        addLine(lines, 'Enchant:', tostring(record.enchant), '#d19cff')
    end

    local maxCap = tonumber(record.enchantCapacity) or 0
    if maxCap <= 0 then
        return
    end

    local used = safeEnchantCost(record.enchant) or 0
    local free = maxCap - used
    local ratio = maxCap > 0 and (free / maxCap) or 0
    local freeColor = '#FF7373'
    if ratio > 0.6 then
        freeColor = '#73bd80'
    elseif ratio > 0.3 then
        freeColor = '#d4c46f'
    end

    addLine(lines, 'Enchant Cap:', fmtNumber(maxCap, 1), '#d19cff')
    if used > 0 then
        addLine(lines, 'Enchant Used:', fmtNumber(used, 1), freeColor)
        addLine(lines, 'Enchant Free:', fmtNumber(free, 1), freeColor)
    end
end

local function addCondition(lines, obj, record)
    if not getSetting('ShowCondition') then
        return
    end

    local data = safeItemData(obj)
    if not data or not data.condition then
        return
    end

    local max = record and (record.maxCondition or record.health or record.duration) or nil
    if max then
        addLine(lines, 'Condition:', string.format('%d / %d', data.condition, max), '#f5f0d0')
    else
        addLine(lines, 'Condition:', tostring(data.condition), '#f5f0d0')
    end
end

local function addEconomyStats(lines, record)
    if not getSetting('ShowEconomyStats') or not record then
        return
    end

    if record.weight ~= nil then
        addLine(lines, 'Weight:', fmtNumber(record.weight, 2), '#f5f0d0')
    end
    if record.value ~= nil then
        addLine(lines, 'Value:', fmtNumber(record.value, 0), '#f5f0d0')
    end
    local weight = tonumber(record.weight) or 0
    local value = tonumber(record.value) or 0
    if weight > 0 and value > 0 then
        addLine(lines, 'Value / Weight:', fmtNumber(value / weight, 2), '#73bd80')
    end
end

local function addWeaponStats(lines, obj, record)
    if not record then return end

    if getSetting('ShowItemType') then
        addLine(lines, 'Type:', WEAPON_TYPE_TO_TEXT[record.type] or 'Weapon', '#9fd3ff')
    end

    if not getSetting('ShowCombatStats') then
        return
    end

    local comparisonInfo = getWeaponComparisonInfo(obj, record)
    if comparisonInfo and comparisonInfo.equippedName then
        addLine(lines, 'Equipped:', comparisonInfo.equippedName, '#d4c46f')
    end
    addRawDpsLine(lines, obj, record, comparisonInfo)
    addEffectiveDpsLine(lines, obj, record, comparisonInfo)

    if record.chopMaxDamage then
        if RANGED_WEAPON[record.type] then
            addLine(lines, 'Attack:', fmtRange(record.chopMinDamage, record.chopMaxDamage), '#f5f0d0')
            addLine(lines, 'Speed:', fmtNumber(record.speed, 2), '#f5f0d0')
        elseif RANGED_AMMO[record.type] then
            addLine(lines, 'Attack:', fmtRange(record.chopMinDamage, record.chopMaxDamage), '#f5f0d0')
        else
            addLine(lines, 'Chop:', fmtRange(record.chopMinDamage, record.chopMaxDamage), '#f5f0d0')
            addLine(lines, 'Slash:', fmtRange(record.slashMinDamage, record.slashMaxDamage), '#f5f0d0')
            addLine(lines, 'Thrust:', fmtRange(record.thrustMinDamage, record.thrustMaxDamage), '#f5f0d0')
            addLine(lines, 'Range:', fmtNumber(record.reach, 2), '#f5f0d0')
            addLine(lines, 'Speed:', fmtNumber(record.speed, 2), '#f5f0d0')
        end
    end
end

local function addArmorStats(lines, obj, record)
    if not record then return end

    if getSetting('ShowItemType') then
        addLine(lines, 'Type:', ARMOR_TYPE_TO_TEXT[record.type] or 'Armor', '#9fd3ff')
    end

    local rawArmorRating = getArmorRatingValue(record)
    if getSetting('ShowCombatStats') and rawArmorRating then
        local comparisonInfo = getArmorComparisonInfo(obj, record)
        if comparisonInfo and comparisonInfo.equippedName then
            addLine(lines, 'Equipped:', comparisonInfo.equippedName, '#d4c46f')
        end

        local rawLineColor = comparisonInfo and comparisonInfo.rawArColor or '#73bd80'
        local rawText = addDeltaToText(fmtNumber(rawArmorRating, 0), comparisonInfo and comparisonInfo.rawArDelta or nil, 0)
        addLine(lines, 'Base Armor Rating:', rawText, rawLineColor)

        local effectiveArmorRating = getPlayerAdjustedArmorRating(obj, record)
        if effectiveArmorRating then
            local effectiveLineColor = comparisonInfo and comparisonInfo.effectiveArColor or '#73bd80'
            local effectiveText = addDeltaToText(fmtNumber(effectiveArmorRating, 1), comparisonInfo and comparisonInfo.effectiveArDelta or nil, 1)
            addLine(lines, 'Effective Armor Rating:', effectiveText, effectiveLineColor)
        end
    end
end

local function addOtherItemStats(lines, obj, record)
    if not record then return end

    if not getSetting('ShowItemType') then
        return
    end

    if obj.type == types.Clothing then
        addLine(lines, 'Type:', CLOTHING_TYPE_TO_TEXT[record.type] or 'Clothing', '#9fd3ff')
    elseif obj.type == types.Book then
        addLine(lines, 'Type:', record.isScroll and 'Scroll' or 'Book', '#9fd3ff')
        if record.skill then
            addLine(lines, 'Teaches:', tostring(record.skill), '#d19cff')
        end
    elseif obj.type == types.Potion then
        addLine(lines, 'Type:', 'Potion', '#9fd3ff')
    elseif obj.type == types.Ingredient then
        addLine(lines, 'Type:', 'Ingredient', '#9fd3ff')
    elseif obj.type == types.Light then
        addLine(lines, 'Type:', 'Light', '#9fd3ff')
        if record.time then
            addLine(lines, 'Duration:', tostring(record.time), '#f5f0d0')
        end
    elseif obj.type == types.Apparatus then
        addLine(lines, 'Type:', APPARATUS_TYPE_TO_TEXT[record.type] or 'Apparatus', '#9fd3ff')
        if record.quality then
            addLine(lines, 'Quality:', fmtNumber(record.quality, 2), '#73bd80')
        end
    elseif obj.type == types.Lockpick then
        addLine(lines, 'Type:', 'Lockpick', '#9fd3ff')
        if record.quality then
            addLine(lines, 'Quality:', fmtNumber(record.quality, 2), '#73bd80')
        end
        if record.uses then
            addLine(lines, 'Uses:', tostring(record.uses), '#f5f0d0')
        end
    elseif obj.type == types.Probe then
        addLine(lines, 'Type:', 'Probe', '#9fd3ff')
        if record.quality then
            addLine(lines, 'Quality:', fmtNumber(record.quality, 2), '#73bd80')
        end
        if record.uses then
            addLine(lines, 'Uses:', tostring(record.uses), '#f5f0d0')
        end
    elseif obj.type == types.Repair then
        addLine(lines, 'Type:', 'Repair Tool', '#9fd3ff')
        if record.quality then
            addLine(lines, 'Quality:', fmtNumber(record.quality, 2), '#73bd80')
        end
        if record.uses then
            addLine(lines, 'Uses:', tostring(record.uses), '#f5f0d0')
        end
    elseif obj.type == types.Miscellaneous then
        addLine(lines, 'Type:', 'Miscellaneous', '#9fd3ff')
    end
end

local function isSupportedItemType(obj)
    if not obj then return false end
    return obj.type == types.Weapon
        or obj.type == types.Armor
        or obj.type == types.Clothing
        or obj.type == types.Book
        or obj.type == types.Potion
        or obj.type == types.Ingredient
        or obj.type == types.Miscellaneous
        or obj.type == types.Light
        or obj.type == types.Apparatus
        or obj.type == types.Lockpick
        or obj.type == types.Probe
        or obj.type == types.Repair
end

local function addItemStats(lines, obj)
    if not getSetting('ShowItemStats') or not isSupportedItemType(obj) then
        return
    end

    local record = safeRecord(obj)
    if not record then
        return
    end

    if #lines > 0 then
        addBlank(lines)
    end

    if getSetting('ShowItemName') then
        addLine(lines, 'Item:', record.name or obj.recordId or '<unnamed>', '#ffffff')
    end

    if obj.type == types.Weapon then
        addWeaponStats(lines, obj, record)
    elseif obj.type == types.Armor then
        addArmorStats(lines, obj, record)
    else
        addOtherItemStats(lines, obj, record)
    end

    addCondition(lines, obj, record)
    addEnchantStats(lines, record)
    addEconomyStats(lines, record)
end

local function safeObjectText(obj)
    if not obj or not obj:isValid() then
        return nil
    end

    local lines = {}

    if getSetting('ShowSource') then
        addLine(lines, 'Source:', tostring(obj.contentFile or '<dynamic / no content file>'), '#ffdf80')
    end

    if getSetting('ShowRecord') then
        addLine(lines, 'Record:', tostring(obj.recordId or '<no record id>'), '#f5f0d0')
    end

    if getSetting('ShowObject') then
        addLine(lines, 'Object:', tostring(obj.id or '<no object id>'), '#d0d0d0')
    end

    addItemStats(lines, obj)

    if #lines == 0 then
        return nil
    end

    return table.concat(lines, '\n')
end

local function getCrosshairHit()
    local from = camera.getPosition()
    local dir = camera.viewportToWorldVector(v2(0.5, 0.5))
    if not dir then
        return nil, 'none'
    end

    dir = dir:normalize()
    local to = from + dir * clamp(getSetting('MaxDistance'), 256, 32768)

    -- Rendering ray is best for visible meshes, including no-collision visuals.
    -- Do not pass options here: some builds expose options in docs, but the common
    -- stable signature is exactly castRenderingRay(from, to).
    local res = nearby.castRenderingRay(from, to)
    if res and res.hitObject and res.hitObject:isValid() then
        return res.hitObject, 'rendering'
    end

    -- Always run the physics fallback raycast after the rendering ray misses.
    -- The vanilla activation tooltip is usually based on physical/collision
    -- target checks, so this catches doors, containers, and actors that the
    -- rendering ray may miss.
    local physical = nearby.COLLISION_TYPE.World + nearby.COLLISION_TYPE.Door + nearby.COLLISION_TYPE.Actor
    res = nearby.castRay(from, to, {
        ignore = self,
        collisionType = physical,
    })
    if res and res.hitObject and res.hitObject:isValid() then
        return res.hitObject, 'physics'
    end

    return nil, 'none'
end

local function updateHoveredObject()
    if not getSetting('Enabled') then
        setOverlay(nil)
        return
    end

    local ok, obj, mode = pcall(getCrosshairHit)
    if not ok then
        pxmLog('ERROR: ' .. tostring(obj))
        if getSetting('DebugLog') then
            setOverlay('PXM object insight tooltip error:\n' .. tostring(obj), true)
        else
            setOverlay(nil, true)
        end
        return
    end

    if obj then
        if not printedFirstHit then
            printedFirstHit = true
            pxmLog('first hit via ' .. tostring(mode) .. ': id=' .. tostring(obj.id) .. ', record=' .. tostring(obj.recordId) .. ', contentFile=' .. tostring(obj.contentFile))
        end
        setOverlay(safeObjectText(obj), false)
    else
        if not printedFirstMiss then
            printedFirstMiss = true
            pxmLog('no object hit yet')
        end
        setOverlay(nil, false)
    end
end

return {
    engineHandlers = {
        onFrame = function(dt)
            if not printedLoaded then
                printedLoaded = true
                pxmLog('loaded')
            end

            -- While dragging, update the widget from onFrame instead of from the
            -- mouse event callbacks. Updating layout from inside mousePress/mouseMove
            -- can blank the text until mouseRelease on some OpenMW builds.
            if dragging then
                updateDragPreview(false)
                return
            end

            if dragHoldTimer > 0 then
                dragHoldTimer = math.max(0, dragHoldTimer - dt)
                if lastText and lastText ~= '' then
                    setOverlay(lastText, false)
                end
                return
            end

            elapsed = elapsed + dt
            local interval = clamp(getSetting('UpdateInterval'), 0.03, 1.00)
            if elapsed < interval then
                return
            end
            elapsed = 0

            updateHoveredObject()
        end,
    },
}
