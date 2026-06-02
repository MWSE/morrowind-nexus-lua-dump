--[[
    Smart Potion Hotkeys - Potion Belt UI

    Player-side setup/status popup and optional Inventory Extender inventory button.
    Persistent state remains in the player settings; this module requests a
    snapshot from player.lua and sends edit actions back to player.lua.
]]

local async = require('openmw.async')
local core  = require('openmw.core')
local input = require('openmw.input')
local ui    = require('openmw.ui')
local util  = require('openmw.util')
local I     = require('openmw.interfaces')

local MODNAME = 'SmartPotionHotkeys'
local L10N    = 'SmartPotionHotkeys'

local MWUI = I.MWUI
local WHITE_TEX = nil
pcall(function()
    WHITE_TEX = require('scripts.omw.mwui.constants').whiteTexture
end)

local module = {}

local beltElement = nil
local snapshotProvider = nil
local actionHandlers = nil
local triggerRegistered = false
local beltModeOwned = false
local windowSize = nil
local windowPosition = nil
local layoutScale = 1.0
local lastToggleTime = -math.huge

local TRIGGER_KEY = 'SmartPotionHotkeys_ToggleBelt'
local TRIGGER_COOLDOWN = 0.25

local DEFAULT_WINDOW_W = 1120
local DEFAULT_WINDOW_H = 660
local MIN_WINDOW_W = 800
local MIN_WINDOW_H = 500
local OUTER_MARGIN = 18
local OUTER_PAD = 12
local PANEL_PAD = 10
local PANEL_GAP = 10
local HEADER_H = 48
local CLOSE_W = 96
local REFRESH_W = 108
local ROW_H = 38

local GOLD      = util.color.rgb(0.98, 0.92, 0.78)
local PALE_GOLD = util.color.rgb(0.88, 0.80, 0.62)
local TEXT      = util.color.rgb(0.96, 0.95, 0.92)
local SUBTLE    = util.color.rgb(0.72, 0.70, 0.66)
local VALUE     = util.color.rgb(1.00, 0.99, 0.98)
local BRONZE    = util.color.rgb(0.46, 0.31, 0.16)
local BLACK     = util.color.rgb(0.0, 0.0, 0.0)

local function safeCall(fn, fallback)
    local ok, value = pcall(fn)
    if ok then return value end
    return fallback
end

local function L(key, args)
    return core.l10n(L10N)(key, args) or key
end

local function clamp(value, minValue, maxValue)
    return math.max(minValue, math.min(maxValue, value))
end

local function scaled(value, scale)
    scale = scale or layoutScale or 1.0
    return math.max(1, math.floor((value or 0) * scale + 0.5))
end

local function getLayerSize()
    local index = safeCall(function() return ui.layers.indexOf('Windows') end, nil)
    local layer = index and ui.layers[index] or nil
    return (layer and layer.size) or ui.screenSize()
end

local function getContentScale(windowW, windowH)
    return clamp(math.min(windowW / DEFAULT_WINDOW_W, windowH / DEFAULT_WINDOW_H), 0.82, 1.16)
end

local function defaultWindowSize()
    local screen = getLayerSize()
    return util.vector2(
        clamp(math.floor(screen.x - OUTER_MARGIN * 2), MIN_WINDOW_W, math.min(DEFAULT_WINDOW_W, screen.x)),
        clamp(math.floor(screen.y - OUTER_MARGIN * 2), MIN_WINDOW_H, math.min(DEFAULT_WINDOW_H, screen.y))
    )
end

local function defaultWindowPosition(size)
    local screen = getLayerSize()
    return util.vector2(
        math.floor((screen.x - size.x) * 0.5),
        math.floor((screen.y - size.y) * 0.5)
    )
end

local function getWindowSize()
    if not windowSize then windowSize = defaultWindowSize() end
    local screen = getLayerSize()
    windowSize = util.vector2(
        clamp(math.floor(windowSize.x), MIN_WINDOW_W, math.min(DEFAULT_WINDOW_W, screen.x)),
        clamp(math.floor(windowSize.y), MIN_WINDOW_H, math.min(DEFAULT_WINDOW_H, screen.y))
    )
    return windowSize
end

local function getWindowPosition(size)
    if not windowPosition then windowPosition = defaultWindowPosition(size) end
    local screen = getLayerSize()
    windowPosition = util.vector2(
        clamp(math.floor(windowPosition.x), 0, math.max(0, screen.x - size.x)),
        clamp(math.floor(windowPosition.y), 0, math.max(0, screen.y - size.y))
    )
    return windowPosition
end

local function clipText(text, maxChars)
    text = tostring(text or '')
    maxChars = math.max(1, math.floor(maxChars or 1))
    if #text <= maxChars then return text end
    if maxChars <= 3 then return text:sub(1, maxChars) end
    return text:sub(1, maxChars - 3) .. '...'
end

local function makeText(text, opts)
    opts = opts or {}
    return {
        type = ui.TYPE.Text,
        props = {
            text = text or '',
            textSize = scaled(opts.size or 18),
            textColor = opts.color or TEXT,
            autoSize = opts.autoSize ~= false,
            size = opts.boxSize,
            textShadow = opts.shadow ~= false,
            textShadowColor = BLACK,
            textAlignH = opts.alignH,
            textAlignV = opts.alignV,
            position = opts.position,
        },
    }
end

local function spacer(height, width)
    return {
        type = ui.TYPE.Widget,
        props = { size = util.vector2(width or 1, height or 8) },
    }
end

local function vstack(children, size, align)
    return {
        type = ui.TYPE.Flex,
        props = { autoSize = false, size = size, align = align },
        content = ui.content(children),
    }
end

local function hstack(children, size, arrange)
    return {
        type = ui.TYPE.Flex,
        props = { horizontal = true, autoSize = false, size = size, arrange = arrange },
        content = ui.content(children),
    }
end

local function solidFill(alpha, color)
    if not WHITE_TEX then return spacer(1) end
    return {
        type = ui.TYPE.Image,
        props = {
            resource = WHITE_TEX,
            relativeSize = util.vector2(1, 1),
            color = color or BLACK,
            alpha = alpha or 0.0,
        },
    }
end

local function performAction(actionName, ...)
    if type(actionHandlers) ~= 'table' then return false end
    local action = actionHandlers[actionName]
    if type(action) ~= 'function' then return false end
    local ok, changed = pcall(action, ...)
    if not ok then return false end
    if changed ~= false then module.refresh() end
    return changed ~= false
end

local function framedButton(label, width, onClick)
    return {
        type = ui.TYPE.Widget,
        props = { size = util.vector2(width, scaled(34)) },
        events = {
            mouseClick = async:callback(function()
                onClick()
            end),
        },
        content = ui.content {
            {
                template = MWUI.templates.boxSolid,
                props = { alpha = 0.92 },
                content = ui.content {
                    {
                        template = MWUI.templates.padding,
                        props = { padding = scaled(5) },
                        content = ui.content {
                            makeText(label, {
                                size = 18,
                                color = VALUE,
                                alignH = ui.ALIGNMENT.Center,
                                alignV = ui.ALIGNMENT.Center,
                                autoSize = false,
                                boxSize = util.vector2(width - scaled(10), scaled(24)),
                            }),
                        },
                    },
                },
            },
        },
    }
end

local function buttonFrame(width, height, opts)
    opts = opts or {}
    if not WHITE_TEX then
        return {
            template = MWUI.templates.box,
            props = { size = util.vector2(width, height) },
        }
    end

    local line = math.max(1, scaled(opts.line or 1))
    local frameColor = opts.frameColor or PALE_GOLD
    local background = opts.background or BLACK
    local alpha = opts.alpha or 0.15

    return {
        type = ui.TYPE.Widget,
        props = { size = util.vector2(width, height) },
        content = ui.content {
            {
                type = ui.TYPE.Image,
                props = {
                    resource = WHITE_TEX,
                    position = util.vector2(0, 0),
                    size = util.vector2(width, height),
                    color = background,
                    alpha = alpha,
                },
            },
            {
                type = ui.TYPE.Image,
                props = {
                    resource = WHITE_TEX,
                    position = util.vector2(0, 0),
                    size = util.vector2(width, line),
                    color = frameColor,
                    alpha = 0.95,
                },
            },
            {
                type = ui.TYPE.Image,
                props = {
                    resource = WHITE_TEX,
                    position = util.vector2(0, height - line),
                    size = util.vector2(width, line),
                    color = frameColor,
                    alpha = 0.95,
                },
            },
            {
                type = ui.TYPE.Image,
                props = {
                    resource = WHITE_TEX,
                    position = util.vector2(0, 0),
                    size = util.vector2(line, height),
                    color = frameColor,
                    alpha = 0.95,
                },
            },
            {
                type = ui.TYPE.Image,
                props = {
                    resource = WHITE_TEX,
                    position = util.vector2(width - line, 0),
                    size = util.vector2(line, height),
                    color = frameColor,
                    alpha = 0.95,
                },
            },
        },
    }
end

local function editButton(label, width, height, onClick, opts)
    opts = opts or {}
    local padding = scaled(opts.padding or 3)
    local textW = math.max(1, width - padding * 2)
    local textH = math.max(1, height - padding * 2)
    return {
        type = ui.TYPE.Widget,
        props = { size = util.vector2(width, height) },
        events = {
            mouseClick = async:callback(function()
                onClick()
            end),
        },
        content = ui.content {
            buttonFrame(width, height, opts),
            makeText(clipText(label, opts.maxChars or math.floor(width / 8)), {
                size = opts.size or 16,
                color = opts.color or VALUE,
                autoSize = false,
                boxSize = util.vector2(textW, textH),
                position = util.vector2(padding, padding),
                alignH = opts.alignH or ui.ALIGNMENT.Center,
                alignV = ui.ALIGNMENT.Center,
            }),
        },
    }
end

local function ensureGameplayPausedForBelt()
    if not I or not I.UI or not I.UI.setMode then return end
    local currentMode = safeCall(function() return I.UI.getMode() end, nil)
    if currentMode == nil then
        beltModeOwned = true
        local mode = safeCall(function() return I.UI.MODE.Interface end, 'Interface') or 'Interface'
        I.UI.setMode(mode, { windows = {} })
    else
        beltModeOwned = false
    end
end

local function releaseBeltMode()
    if not beltModeOwned or not I or not I.UI or not I.UI.setMode then
        beltModeOwned = false
        return
    end
    beltModeOwned = false
    I.UI.setMode()
end

local function getSnapshot()
    if type(snapshotProvider) ~= 'function' then return {} end
    return snapshotProvider() or {}
end

local function metricText(label, value, width)
    local labelW = math.floor(width * 0.46)
    local valueW = width - labelW
    return hstack({
        makeText(label, {
            size = 17,
            color = SUBTLE,
            autoSize = false,
            boxSize = util.vector2(labelW, scaled(24)),
            alignV = ui.ALIGNMENT.Center,
        }),
        makeText(value, {
            size = 18,
            color = VALUE,
            autoSize = false,
            boxSize = util.vector2(valueW, scaled(24)),
            alignV = ui.ALIGNMENT.Center,
        }),
    }, util.vector2(width, scaled(26)))
end

local function summaryPanel(snapshot, size)
    local innerW = size.x - scaled(PANEL_PAD * 2)
    local colW = math.floor((innerW - scaled(PANEL_GAP)) / 2)
    local metricsH = math.max(scaled(54), size.y - scaled(PANEL_PAD * 2 + 30))
    local left = vstack({
        metricText(L('belt_summary_total_potions'), tostring(snapshot.totalPotionCount or 0), colW),
        metricText(L('belt_summary_configured_slots'), tostring(snapshot.configuredSlots or 0) .. ' / 9', colW),
    }, util.vector2(colW, metricsH))
    local right = vstack({
        metricText(L('belt_summary_default_priority'), tostring(snapshot.defaultPriority or L('belt_unknown')), colW),
        metricText(L('belt_summary_match_mode'), tostring(snapshot.matchMode or L('belt_unknown')), colW),
    }, util.vector2(colW, metricsH))

    return {
        template = MWUI.templates.box,
        props = { size = size },
        content = ui.content {
            {
                template = MWUI.templates.padding,
                props = { padding = scaled(PANEL_PAD) },
                content = ui.content {
                    vstack({
                        makeText(L('belt_section_summary'), { size = 22, color = PALE_GOLD }),
                        spacer(4),
                        hstack({ left, spacer(1, scaled(PANEL_GAP)), right }, util.vector2(innerW, metricsH)),
                    }, util.vector2(innerW, size.y - scaled(PANEL_PAD * 2))),
                },
            },
        },
    }
end

local function columnWidths(width)
    local gaps = scaled(7) * 5
    local usable = width - gaps
    local slot = math.floor(usable * 0.045)
    local effect = math.floor(usable * 0.22)
    local potion = math.floor(usable * 0.26)
    local count = math.floor(usable * 0.055)
    local priority = math.floor(usable * 0.20)
    local auto = usable - slot - effect - potion - count - priority
    return {
        slot = slot,
        effect = effect,
        potion = potion,
        count = count,
        priority = priority,
        auto = auto,
    }
end

local function cell(text, width, opts)
    opts = opts or {}
    return makeText(clipText(text, opts.maxChars or math.floor(width / 8)), {
        size = opts.size or 16,
        color = opts.color or TEXT,
        autoSize = false,
        boxSize = util.vector2(width, scaled(ROW_H - 4)),
        alignH = opts.alignH,
        alignV = ui.ALIGNMENT.Center,
    })
end

local function effectCell(slot, width)
    local buttonH = scaled(ROW_H - 6)
    local arrowW = scaled(24)
    local gap = scaled(3)
    local textW = math.max(20, width - arrowW * 2 - gap * 2)
    return hstack({
        editButton('<', arrowW, buttonH, function()
            performAction('cycleEffect', slot.slot, -1)
        end, { size = 15, maxChars = 1 }),
        spacer(1, gap),
        editButton(slot.effect or '', textW, buttonH, function()
            performAction('cycleEffect', slot.slot, 1)
        end, { size = 16, maxChars = math.floor(textW / 8), color = VALUE }),
        spacer(1, gap),
        editButton('>', arrowW, buttonH, function()
            performAction('cycleEffect', slot.slot, 1)
        end, { size = 15, maxChars = 1 }),
    }, util.vector2(width, scaled(ROW_H)))
end

local function priorityCell(slot, width)
    return editButton(slot.priority or '', width, scaled(ROW_H - 6), function()
        performAction('cyclePriority', slot.slot, 1)
    end, { size = 16, maxChars = math.floor(width / 8), color = VALUE })
end

local function autoCell(slot, width)
    local buttonH = scaled(ROW_H - 6)
    local gap = scaled(3)
    if not slot.autoSupported then
        return editButton(slot.autoUse or L('belt_auto_off'), width, buttonH, function()
            performAction('toggleAutoUse', slot.slot)
        end, { size = 16, maxChars = math.floor(width / 8), color = SUBTLE })
    end

    local stepW = scaled(24)
    local textW = math.max(20, width - stepW * 2 - gap * 2)
    local autoText = slot.autoUse or L('belt_auto_off')
    return hstack({
        editButton('-', stepW, buttonH, function()
            performAction('adjustThreshold', slot.slot, -5)
        end, { size = 15, maxChars = 1 }),
        spacer(1, gap),
        editButton(autoText, textW, buttonH, function()
            performAction('toggleAutoUse', slot.slot)
        end, { size = 16, maxChars = math.floor(textW / 8), color = VALUE }),
        spacer(1, gap),
        editButton('+', stepW, buttonH, function()
            performAction('adjustThreshold', slot.slot, 5)
        end, { size = 15, maxChars = 1 }),
    }, util.vector2(width, scaled(ROW_H)))
end

local function beltRow(slot, widths, header)
    local rowColor = header and PALE_GOLD or TEXT
    local size = header and 17 or 16
    local gap = scaled(7)
    local rowH = header and scaled(34) or scaled(ROW_H)

    local children
    if header then
        children = {
            cell(L('belt_col_slot'), widths.slot, { color = rowColor, size = size, maxChars = 6 }),
            spacer(1, gap),
            cell(L('belt_col_effect'), widths.effect, { color = rowColor, size = size, maxChars = 22 }),
            spacer(1, gap),
            cell(L('belt_col_potion'), widths.potion, { color = rowColor, size = size, maxChars = 42 }),
            spacer(1, gap),
            cell(L('belt_col_qty'), widths.count, { color = rowColor, size = size, alignH = ui.ALIGNMENT.Center, maxChars = 8 }),
            spacer(1, gap),
            cell(L('belt_col_priority'), widths.priority, { color = rowColor, size = size, maxChars = 22 }),
            spacer(1, gap),
            cell(L('belt_col_auto'), widths.auto, { color = rowColor, size = size, maxChars = 24 }),
        }
    else
        children = {
            cell(tostring(slot.slot or ''), widths.slot, { color = rowColor, size = size, maxChars = 6 }),
            spacer(1, gap),
            effectCell(slot, widths.effect),
            spacer(1, gap),
            cell(tostring(slot.bestPotion or ''), widths.potion, { color = VALUE, size = size, maxChars = math.floor(widths.potion / 8) }),
            spacer(1, gap),
            cell(tostring(slot.count or ''), widths.count, { color = rowColor, size = size, alignH = ui.ALIGNMENT.Center, maxChars = 8 }),
            spacer(1, gap),
            priorityCell(slot, widths.priority),
            spacer(1, gap),
            autoCell(slot, widths.auto),
        }
    end

    return hstack(children, util.vector2(widths.slot + widths.effect + widths.potion + widths.count + widths.priority + widths.auto + gap * 5, rowH))
end

local function tablePanel(snapshot, size)
    local innerW = size.x - scaled(PANEL_PAD * 2)
    local innerH = size.y - scaled(PANEL_PAD * 2)
    local widths = columnWidths(innerW)
    local rows = {}
    rows[#rows + 1] = hstack({
        makeText(L('belt_section_slots'), {
            size = 22,
            color = PALE_GOLD,
            autoSize = false,
            boxSize = util.vector2(math.floor(innerW * 0.45), scaled(26)),
            alignV = ui.ALIGNMENT.Center,
        }),
        makeText(L('belt_edit_hint'), {
            size = 14,
            color = SUBTLE,
            autoSize = false,
            boxSize = util.vector2(math.floor(innerW * 0.55), scaled(26)),
            alignH = ui.ALIGNMENT.End,
            alignV = ui.ALIGNMENT.Center,
        }),
    }, util.vector2(innerW, scaled(28)))
    rows[#rows + 1] = spacer(4)
    rows[#rows + 1] = beltRow({}, widths, true)

    for _, slot in ipairs(snapshot.slots or {}) do
        rows[#rows + 1] = beltRow(slot, widths, false)
    end

    return {
        template = MWUI.templates.box,
        props = { size = size },
        content = ui.content {
            {
                template = MWUI.templates.padding,
                props = { padding = scaled(PANEL_PAD) },
                content = ui.content {
                    vstack(rows, util.vector2(innerW, innerH)),
                },
            },
        },
    }
end

local function getMetrics()
    local size = getWindowSize()
    local scale = getContentScale(size.x, size.y)
    layoutScale = scale
    local pos = getWindowPosition(size)
    local innerW = size.x - scaled(OUTER_PAD * 2)
    local innerH = size.y - scaled(OUTER_PAD * 2)
    local headerH = scaled(HEADER_H)
    local gap = scaled(PANEL_GAP)
    local summaryH = scaled(108)
    local tableH = innerH - headerH - gap * 2 - summaryH
    return {
        window = size,
        position = pos,
        innerW = innerW,
        innerH = innerH,
        headerH = headerH,
        gap = gap,
        summaryH = summaryH,
        tableH = tableH,
    }
end

local function buildContent(snapshot, metrics)
    local buttonsW = scaled(REFRESH_W + CLOSE_W) + metrics.gap
    local headerTitle = makeText(L('belt_title'), {
        size = 34,
        color = GOLD,
        autoSize = false,
        boxSize = util.vector2(metrics.innerW - buttonsW - metrics.gap, metrics.headerH),
        alignH = ui.ALIGNMENT.Center,
        alignV = ui.ALIGNMENT.Center,
    })

    local header = hstack({
        headerTitle,
        spacer(1, metrics.gap),
        framedButton(L('belt_refresh'), scaled(REFRESH_W), function() module.refresh() end),
        spacer(1, metrics.gap),
        framedButton(L('belt_close'), scaled(CLOSE_W), function() module.hide() end),
    }, util.vector2(metrics.innerW, metrics.headerH), ui.ALIGNMENT.Center)

    local summary = summaryPanel(snapshot, util.vector2(metrics.innerW, metrics.summaryH))
    local table = tablePanel(snapshot, util.vector2(metrics.innerW, metrics.tableH))

    return ui.content {
        {
            template = MWUI.templates.boxSolidThick,
            content = ui.content {
                solidFill(0.22, BRONZE),
                {
                    template = MWUI.templates.padding,
                    props = { padding = scaled(OUTER_PAD) },
                    content = ui.content {
                        vstack({ header, spacer(metrics.gap), summary, spacer(metrics.gap), table }, util.vector2(metrics.innerW, metrics.innerH)),
                    },
                },
            },
        },
    }
end

local function buildLayout(snapshot)
    local metrics = getMetrics()
    return {
        layer = 'Windows',
        type = ui.TYPE.Widget,
        props = {
            position = metrics.position,
            size = metrics.window,
        },
        content = buildContent(snapshot or {}, metrics),
    }
end

function module.show()
    ensureGameplayPausedForBelt()
    if beltElement then beltElement:destroy() beltElement = nil end
    beltElement = ui.create(buildLayout(getSnapshot()))
end

function module.hide()
    if beltElement then
        beltElement:destroy()
        beltElement = nil
    end
    releaseBeltMode()
end

function module.refresh()
    if not beltElement then return end
    beltElement:destroy()
    beltElement = ui.create(buildLayout(getSnapshot()))
end

function module.toggle()
    local now = safeCall(function() return input.getRealTime() end, core.getRealTime()) or core.getRealTime()
    if now - lastToggleTime < TRIGGER_COOLDOWN then return end
    lastToggleTime = now

    if beltElement then
        module.hide()
    else
        module.show()
    end
end

function module.registerTrigger()
    if triggerRegistered then return end
    triggerRegistered = true
    input.registerTrigger {
        key = TRIGGER_KEY,
        l10n = L10N,
        name = 'belt_hotkey_name',
        description = 'belt_hotkey_desc',
    }
    input.registerTriggerHandler(TRIGGER_KEY, async:callback(function()
        module.toggle()
    end))
end

function module.init(provider, actions)
    snapshotProvider = provider
    actionHandlers = actions
    module.registerTrigger()
end

function module.hookInventoryButton()
    local IE = I.InventoryExtender
    if not IE or type(IE.getWindow) ~= 'function' then return false end

    local invWindow = IE.getWindow('Inventory')
    if not invWindow or not invWindow.infoBar or not invWindow.infoBar.layout then return false end
    if not invWindow.ctx then return false end

    local infoLayout = invWindow.infoBar.layout
    infoLayout.userData = infoLayout.userData or {}
    if infoLayout.userData._smartPotionBeltAdded then return true end

    local okBase, baseTemplates = pcall(require, 'scripts.InventoryExtender.ui.templates.base')
    local okSpecial, specialTemplates = pcall(require, 'scripts.InventoryExtender.ui.templates.magic')
    if not okBase or not okSpecial or not baseTemplates or not specialTemplates then return false end

    local button = specialTemplates.interactive({
        onClick = function()
            module.toggle()
        end,
        parent = invWindow.infoBar,
    }, baseTemplates.button(L('belt_button')), invWindow.ctx)

    if infoLayout.userData and type(infoLayout.userData.addInfoLayout) == 'function' then
        infoLayout.userData.addInfoLayout(button)
    elseif infoLayout.content and type(infoLayout.content.add) == 'function' then
        infoLayout.content:add(baseTemplates.intervalH(8))
        infoLayout.content:add(button)
    else
        return false
    end

    infoLayout.userData._smartPotionBeltAdded = true
    safeCall(function() invWindow.infoBar:update() end, nil)
    return true
end

return module
