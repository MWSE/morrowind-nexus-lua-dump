--[[
    Fair Trade - Trade Ledger UI

    Player-side popup and optional Inventory Extender barter button.
    The global script owns persistent trade data; this module requests
    a read-only snapshot and renders it in a scalable MWUI window.
]]

local async = require('openmw.async')
local core  = require('openmw.core')
local input = require('openmw.input')
local self  = require('openmw.self')
local ui    = require('openmw.ui')
local util  = require('openmw.util')
local I     = require('openmw.interfaces')

local MODNAME = 'FairTrade'
local L10N    = 'FairTrade'

local MWUI = I.MWUI
local WHITE_TEX = nil
pcall(function()
    WHITE_TEX = require('scripts.omw.mwui.constants').whiteTexture
end)

local module = {}

local ledgerElement = nil
local contextProvider = nil
local triggerRegistered = false
local ledgerModeOwned = false
local windowSize = nil
local windowPosition = nil
local layoutScale = 1.0
local lastTriggerTime = -math.huge

local TRIGGER_KEY = 'FairTrade_ToggleLedger'
local TRIGGER_COOLDOWN = 0.25

local DEFAULT_WINDOW_W = 980
local DEFAULT_WINDOW_H = 660
local MIN_WINDOW_W = 640
local MIN_WINDOW_H = 460
local OUTER_MARGIN = 18
local OUTER_PAD = 12
local PANEL_PAD = 10
local PANEL_GAP = 10
local HEADER_H = 48
local CLOSE_W = 98
local ROW_H = 29
local LABEL_W = 194

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

local function L(key)
    return core.l10n(L10N)(key) or key
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
    return clamp(math.min(windowW / DEFAULT_WINDOW_W, windowH / DEFAULT_WINDOW_H), 0.86, 1.18)
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

local function ensureGameplayPausedForLedger()
    if not I or not I.UI or not I.UI.setMode then return end
    local currentMode = safeCall(function() return I.UI.getMode() end, nil)
    if currentMode == nil then
        ledgerModeOwned = true
        local mode = safeCall(function() return I.UI.MODE.Interface end, 'Interface') or 'Interface'
        I.UI.setMode(mode, { windows = {} })
    else
        ledgerModeOwned = false
    end
end

local function releaseLedgerMode()
    if not ledgerModeOwned or not I or not I.UI or not I.UI.setMode then
        ledgerModeOwned = false
        return
    end
    ledgerModeOwned = false
    I.UI.setMode()
end

local function fmtGold(value)
    value = math.floor(tonumber(value) or 0)
    local sign = value < 0 and '-' or ''
    value = math.abs(value)
    local str = tostring(value)
    while true do
        local newStr, changed = str:gsub('^(-?%d+)(%d%d%d)', '%1,%2')
        str = newStr
        if changed == 0 then break end
    end
    return sign .. str .. 'g'
end

local function fmtPct(value)
    value = tonumber(value) or 0
    if math.abs(value - math.floor(value)) < 0.01 then
        return tostring(math.floor(value)) .. '%'
    end
    return string.format('%.1f%%', value)
end

local function fmtChance(value)
    value = tonumber(value) or 0
    return string.format('%.0f%%', value * 100)
end

local function tierLabel(section)
    if not section then return L('ledger_none') end
    if section.disabled then return L('ledger_disabled') end
    return section.tierName or L('ledger_none')
end

local function nextTierText(section, valueUnit)
    if not section then return L('ledger_no_context') end
    if section.disabled then return L('ledger_disabled') end
    if not section.nextThreshold then return L('ledger_max_tier') end
    local remaining = math.max(0, math.floor(section.nextRemaining or 0))
    if valueUnit == 'trips' then
        return string.format('%d more trip%s to %s', remaining, remaining == 1 and '' or 's', section.nextName or L('ledger_next_tier'))
    end
    return string.format('%s more to %s', fmtGold(remaining), section.nextName or L('ledger_next_tier'))
end

local function row(label, value, width, labelW)
    local rowW = width or scaled(360)
    local labelWidth = labelW or scaled(LABEL_W)
    local valueW = math.max(40, rowW - labelWidth - scaled(10))
    local maxChars = math.floor(valueW / math.max(7, scaled(7)))
    return hstack({
        makeText(label, {
            size = 17,
            color = SUBTLE,
            autoSize = false,
            boxSize = util.vector2(labelWidth, scaled(ROW_H)),
        }),
        makeText(clipText(value, maxChars), {
            size = 18,
            color = VALUE,
            autoSize = false,
            boxSize = util.vector2(valueW, scaled(ROW_H)),
        }),
    }, util.vector2(rowW, scaled(ROW_H)))
end

local function section(title, rows, size)
    local content = {
        makeText(title, { size = 22, color = GOLD, autoSize = false, boxSize = util.vector2(size.x - scaled(PANEL_PAD * 2), scaled(28)) }),
        spacer(scaled(4)),
    }
    for _, r in ipairs(rows) do
        content[#content + 1] = row(r[1], r[2], size.x - scaled(PANEL_PAD * 2), r[3])
    end

    return {
        type = ui.TYPE.Widget,
        props = { size = size },
        content = ui.content {
            {
                template = MWUI.templates.boxSolid,
                props = { alpha = 0.76 },
                content = ui.content {
                    solidFill(0.10, BRONZE),
                    {
                        template = MWUI.templates.padding,
                        props = { padding = scaled(PANEL_PAD) },
                        content = ui.content {
                            vstack(content, util.vector2(size.x - scaled(PANEL_PAD * 2), size.y - scaled(PANEL_PAD * 2))),
                        },
                    },
                },
            },
        },
    }
end

local function topListRows(entries, emptyLabel, maxEntries)
    local rows = {}
    if type(entries) ~= 'table' or #entries == 0 then
        rows[#rows + 1] = { emptyLabel, L('ledger_none') }
        return rows
    end
    maxEntries = maxEntries or 3
    for i = 1, math.min(maxEntries, #entries) do
        local e = entries[i]
        local left = string.format('%d. %s', i, e.name or L('ledger_unknown'))
        local right = e.trips and string.format('%d trips, %s', e.trips or 0, e.tierName or L('ledger_none'))
            or string.format('%s, %s', fmtGold(e.spent or 0), e.tierName or L('ledger_none'))
        rows[#rows + 1] = { left, right }
    end
    return rows
end

local function buildCurrentRows(snapshot)
    local merchant = snapshot.currentMerchant
    if not merchant then
        return {
            { L('ledger_context'), L('ledger_no_merchant') },
            { L('ledger_hint'), L('ledger_open_hint') },
        }
    end
    return {
        { L('ledger_merchant'), merchant.name or L('ledger_unknown') },
        { L('ledger_disposition'), tostring(merchant.disposition or 0) },
        { L('ledger_status'), tierLabel(merchant) },
        { L('ledger_spent'), fmtGold(merchant.spent or 0) },
        { L('ledger_next'), nextTierText(merchant, 'gold') },
        { L('ledger_rebate'), fmtPct(merchant.rebatePct or 0) },
        { L('ledger_daily_cap'), merchant.dailyCap and string.format('%d / %d', merchant.dailyGain or 0, merchant.dailyCap) or L('ledger_uncapped') },
    }
end

local function buildRegionRows(snapshot)
    local region = snapshot.region
    if not region then
        return {
            { L('ledger_region'), L('ledger_no_region') },
            { L('ledger_status'), L('ledger_none') },
        }
    end
    return {
        { L('ledger_region'), region.name or L('ledger_unknown') },
        { L('ledger_status'), tierLabel(region) },
        { L('ledger_spent'), fmtGold(region.spent or 0) },
        { L('ledger_next'), nextTierText(region, 'gold') },
        { L('ledger_welcome'), region.welcomeDisp and ('+' .. tostring(region.welcomeDisp)) or '+0' },
        { L('ledger_rebate'), fmtPct(region.rebatePct or 0) },
    }
end

local function buildTransportRows(snapshot)
    local transport = snapshot.transport
    if not transport then
        return {
            { L('ledger_operator'), L('ledger_no_operator') },
            { L('ledger_hint'), L('ledger_travel_hint') },
        }
    end
    return {
        { L('ledger_operator'), transport.name or L('ledger_unknown') },
        { L('ledger_service'), transport.serviceType or L('ledger_unknown') },
        { L('ledger_status'), tierLabel(transport) },
        { L('ledger_trips'), tostring(transport.trips or 0) },
        { L('ledger_next'), nextTierText(transport, 'trips') },
        { L('ledger_discount'), fmtPct(transport.discount or 0) },
        { L('ledger_vouchers'), tostring(transport.vouchers or 0) },
        { L('ledger_voucher_chance'), fmtChance(transport.voucherChance or 0) },
    }
end

local function buildSummaryRows(snapshot)
    local s = snapshot.summary or {}
    return {
        { L('ledger_known_merchants'), tostring(s.merchantCount or 0) },
        { L('ledger_known_regions'), tostring(s.regionCount or 0) },
        { L('ledger_known_operators'), tostring(s.transportCount or 0) },
        { L('ledger_total_merchant_spend'), fmtGold(s.merchantSpent or 0) },
        { L('ledger_total_region_spend'), fmtGold(s.regionSpent or 0) },
        { L('ledger_total_trips'), tostring(s.totalTrips or 0) },
        { L('ledger_total_vouchers'), tostring(s.totalVouchers or 0) },
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
    local bodyH = innerH - headerH - gap
    local wide = innerW >= scaled(800)
    local columnW = wide and math.floor((innerW - gap) / 2) or innerW
    local panelH = wide and math.floor((bodyH - gap) / 2) or math.floor((bodyH - gap * 3) / 4)
    return {
        window = size,
        position = pos,
        innerW = innerW,
        innerH = innerH,
        headerH = headerH,
        gap = gap,
        bodyH = bodyH,
        wide = wide,
        columnW = columnW,
        panelH = panelH,
    }
end

local function buildContent(snapshot, metrics)
    local headerTitle = makeText(L('ledger_title'), {
        size = 34,
        color = GOLD,
        autoSize = false,
        boxSize = util.vector2(metrics.innerW - scaled(CLOSE_W) - metrics.gap, metrics.headerH),
        alignH = ui.ALIGNMENT.Center,
        alignV = ui.ALIGNMENT.Center,
    })

    local header = hstack({
        headerTitle,
        spacer(1, metrics.gap),
        framedButton(L('ledger_close'), scaled(CLOSE_W), function() module.hide() end),
    }, util.vector2(metrics.innerW, metrics.headerH), ui.ALIGNMENT.Center)

    local panelSize = util.vector2(metrics.columnW, metrics.panelH)
    local merchantPanel = section(L('ledger_section_merchant'), buildCurrentRows(snapshot), panelSize)
    local regionPanel = section(L('ledger_section_region'), buildRegionRows(snapshot), panelSize)
    local transportPanel = section(L('ledger_section_transport'), buildTransportRows(snapshot), panelSize)
    local summaryPanel = section(L('ledger_section_summary'), buildSummaryRows(snapshot), panelSize)

    local topRows = topListRows(snapshot.topMerchants, L('ledger_top_merchants'), 3)
    for _, r in ipairs(topListRows(snapshot.topRegions, L('ledger_top_regions'), 2)) do topRows[#topRows + 1] = r end
    for _, r in ipairs(topListRows(snapshot.topTransport, L('ledger_top_transport'), 2)) do topRows[#topRows + 1] = r end
    local topPanel = section(L('ledger_section_top'), topRows, panelSize)

    local body
    if metrics.wide then
        local left = vstack({ merchantPanel, spacer(metrics.gap), regionPanel }, util.vector2(metrics.columnW, metrics.bodyH))
        local right = vstack({ transportPanel, spacer(metrics.gap), summaryPanel }, util.vector2(metrics.columnW, metrics.bodyH))
        body = hstack({ left, spacer(1, metrics.gap), right }, util.vector2(metrics.innerW, metrics.bodyH))
    else
        body = vstack({
            merchantPanel, spacer(metrics.gap), regionPanel, spacer(metrics.gap),
            transportPanel, spacer(metrics.gap), topPanel,
        }, util.vector2(metrics.innerW, metrics.bodyH))
    end

    return ui.content {
        {
            template = MWUI.templates.boxSolidThick,
            content = ui.content {
                solidFill(0.22, BRONZE),
                {
                    template = MWUI.templates.padding,
                    props = { padding = scaled(OUTER_PAD) },
                    content = ui.content {
                        vstack({ header, spacer(metrics.gap), body }, util.vector2(metrics.innerW, metrics.innerH)),
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

local function getContext()
    if type(contextProvider) ~= 'function' then return {} end
    return contextProvider() or {}
end

function module.requestSnapshot()
    local now = safeCall(function() return input.getRealTime() end, core.getRealTime()) or core.getRealTime()
    if now - lastTriggerTime < TRIGGER_COOLDOWN then return end
    lastTriggerTime = now

    local ctx = getContext()
    core.sendGlobalEvent('FairTrade_RequestLedger', {
        player   = self.object,
        merchant = ctx.merchant,
        operator = ctx.operator,
        inBarter = ctx.inBarter == true,
        inTravel = ctx.inTravel == true,
    })
end

function module.show(snapshot)
    ensureGameplayPausedForLedger()
    if ledgerElement then ledgerElement:destroy() ledgerElement = nil end
    ledgerElement = ui.create(buildLayout(snapshot or {}))
end

function module.hide()
    if ledgerElement then
        ledgerElement:destroy()
        ledgerElement = nil
    end
    releaseLedgerMode()
end

function module.toggle()
    if ledgerElement then
        module.hide()
        return
    end
    module.requestSnapshot()
end

function module.onSnapshot(data)
    module.show(data or {})
end

function module.registerTrigger()
    if triggerRegistered then return end
    triggerRegistered = true
    input.registerTrigger {
        key = TRIGGER_KEY,
        l10n = L10N,
        name = 'ledger_hotkey_name',
        description = 'ledger_hotkey_desc',
    }
    input.registerTriggerHandler(TRIGGER_KEY, async:callback(function()
        module.toggle()
    end))
end

local function findTradeWindow()
    local IE = I.InventoryExtender
    if not IE or type(IE.getWindow) ~= 'function' then return nil end
    return IE.getWindow('Trade')
end

local function findInventoryWindow()
    local IE = I.InventoryExtender
    if not IE or type(IE.getWindow) ~= 'function' then return nil end
    return IE.getWindow('Inventory')
end

local function getLayout(layoutOrElement)
    return type(layoutOrElement) == 'userdata' and layoutOrElement.layout or layoutOrElement
end

local function contentInsert(content, index, layout)
    if type(content.insert) == 'function' then
        local ok = pcall(function() content:insert(index, layout) end)
        if ok then return true end
    end
    local ok = pcall(function()
        table.insert(content, index, layout)
    end)
    if ok then return true end
    if type(content.add) == 'function' then
        content:add(layout)
        return true
    end
    return false
end

local function isGrowSpacer(layout)
    if not layout then return false end
    local external = layout.external or {}
    return external.grow ~= nil and external.stretch ~= nil
end

local function makeInventoryLedgerButton(invWindow, tradeWindow, baseTemplates, specialTemplates)
    local ctx = invWindow and invWindow.ctx or tradeWindow and tradeWindow.ctx
    return specialTemplates.interactive({
        onClick = function()
            module.requestSnapshot()
        end,
        parent = invWindow and invWindow.infoBar or tradeWindow and tradeWindow.infoBar,
    }, baseTemplates.button(L('ledger_button')), ctx)
end

local function hookInventoryInfoBarButton(invWindow, tradeWindow, baseTemplates, specialTemplates)
    if not invWindow or not invWindow.infoBar or not invWindow.infoBar.layout then return false end
    local infoLayout = invWindow.infoBar.layout
    local content = infoLayout.content
    if not content then return false end

    infoLayout.userData = infoLayout.userData or {}
    if infoLayout.userData._fairTradeLedgerAdded then return true end

    -- Place Ledger near the right edge of the player's inventory footer,
    -- rather than immediately after the flexible spacer. This keeps it in the
    -- left/player panel but moves it closer to the repair/tool icon, matching
    -- the compact spacing used by Offer and Cancel on the merchant panel.
    local insertAt = #content + 1
    local sawGrowSpacer = false
    for _, child in ipairs(content) do
        if isGrowSpacer(getLayout(child)) then
            sawGrowSpacer = true
            break
        end
    end
    if not sawGrowSpacer then
        return false
    end

    local interval = baseTemplates.intervalH(8)
    local button = makeInventoryLedgerButton(invWindow, tradeWindow, baseTemplates, specialTemplates)
    local rightPad = baseTemplates.intervalH(8)
    local inserted = contentInsert(content, insertAt, interval)
    if inserted then
        contentInsert(content, insertAt + 1, button)
        contentInsert(content, insertAt + 2, rightPad)
    else
        return false
    end

    infoLayout.userData._fairTradeLedgerAdded = true
    safeCall(function() invWindow.infoBar:update() end, nil)
    return true
end

local function hookTradeControlsFallback(tradeWindow, baseTemplates, specialTemplates)
    if not tradeWindow or not tradeWindow.infoBar or not tradeWindow.infoBar.layout then return false end
    if not tradeWindow.ctx then return false end

    local barterControls = nil
    for _, child in ipairs(tradeWindow.infoBar.layout.content or {}) do
        local layout = getLayout(child)
        if layout and layout.name == 'barterControls' then
            barterControls = layout
            break
        end
    end
    if not barterControls or not barterControls.content then return false end

    barterControls.userData = barterControls.userData or {}
    if barterControls.userData._fairTradeLedgerAdded then return true end

    barterControls.userData._fairTradeLedgerAdded = true
    barterControls.content:add(baseTemplates.intervalH(4))
    barterControls.content:add(specialTemplates.interactive({
        onClick = function()
            module.requestSnapshot()
        end,
    }, baseTemplates.button(L('ledger_button')), tradeWindow.ctx))
    return true
end

function module.hookBarterButton()
    local IE = I.InventoryExtender
    if not IE or type(IE.getWindow) ~= 'function' then return false end

    local okBase, baseTemplates = pcall(require, 'scripts.InventoryExtender.ui.templates.base')
    local okSpecial, specialTemplates = pcall(require, 'scripts.InventoryExtender.ui.templates.magic')
    if not okBase or not okSpecial or not baseTemplates or not specialTemplates then return false end

    local tradeWindow = findTradeWindow()
    local invWindow = findInventoryWindow()

    if hookInventoryInfoBarButton(invWindow, tradeWindow, baseTemplates, specialTemplates) then
        return true
    end

    -- Fallback for unusual Inventory Extender layouts where the player
    -- inventory footer is unavailable. This preserves access to the ledger
    -- rather than silently losing the button.
    return hookTradeControlsFallback(tradeWindow, baseTemplates, specialTemplates)
end

function module.init(provider)
    contextProvider = provider
    module.registerTrigger()
end

return module
