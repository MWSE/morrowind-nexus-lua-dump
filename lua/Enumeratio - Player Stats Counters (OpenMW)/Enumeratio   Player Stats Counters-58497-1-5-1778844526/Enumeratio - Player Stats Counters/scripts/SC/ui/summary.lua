local async = require('openmw.async')
local core = require('openmw.core')
local input = require('openmw.input')
local self = require('openmw.self')
local storage = require('openmw.storage')
local ui = require('openmw.ui')
local util = require('openmw.util')
local T = require('openmw.types')
local I = require('openmw.interfaces')

local mDef = require('scripts.SC.config.definition')
local mS = require('scripts.SC.config.settings')
local derived = require('scripts.SC.util.derived')
local log = require('scripts.SC.util.log')

local MWUI = I.MWUI
local MWUIConstants = require('scripts.omw.mwui.constants')
local WHITE_TEX = MWUIConstants.whiteTexture

local module = {}

local summaryElement = nil
local summaryButton = nil
local triggerRegistered = false
local currentState = nil
local updateAccumulator = 0
local lastTriggerTime = -math.huge
local TRIGGER_COOLDOWN = 0.25
local summaryModeOwned = false
local summaryWindowSize = nil
local summaryWindowPosition = nil
local summaryScrollY = 0
local hoveredDragType = nil
local summaryLayoutScale = 1.0
local summaryResizeRefreshPending = false
local summaryLastContentRefreshTime = -math.huge
local summaryIsDragging = false

local DEFAULT_WINDOW_W = 1340
local DEFAULT_WINDOW_H = 790
local MAX_WINDOW_W = 4096
local MAX_WINDOW_H = 2160
local MAX_CONTENT_SCALE = 1.35
local MIN_WINDOW_W = 840
local MIN_WINDOW_H = 420
local WIDE_LAYOUT_W = 1040
local DESIGN_WINDOW_H = 650
local OUTER_MARGIN = 18
local OUTER_PAD = 10
local PANEL_PAD = 8
local PANEL_GAP = 7
local HEADER_H = 34
local CLOSE_W = 84
local SCROLLBAR_W = 16
local SCROLLBAR_BUTTON_H = 16
local SCROLL_STEP = 54
local RESIZE_EDGE = 10
local RESIZE_REFRESH_INTERVAL = 0.045
local LINE_GAP = 2
local ROW_H = 22
local COMPACT_ROW_H = 18
local PORTRAIT_H = 82

local HERO_NAME_SIZE = 30
local HERO_META_SIZE = 18
local HERO_SIGN_SIZE = 17
local PANEL_TITLE_SIZE = 22
local METRIC_LABEL_SIZE = 13
local METRIC_VALUE_SIZE = 16
local METRIC_VALUE_SIZE_COMPACT = 14

local GOLD = util.color.rgb(0.98, 0.92, 0.78)
local PALE_GOLD = util.color.rgb(0.90, 0.83, 0.68)
local TEXT = util.color.rgb(0.96, 0.95, 0.92)
local SUBTLE = util.color.rgb(0.72, 0.70, 0.66)
local VALUE = util.color.rgb(1.00, 0.99, 0.98)
local SKY = VALUE
local MINT = VALUE
local ROSE = VALUE
local AMBER = VALUE
local BRONZE = util.color.rgb(0.46, 0.31, 0.16)
local VANILLA_BLUE = util.color.rgb(0.03, 0.06, 0.10)
local BLACK = util.color.rgb(0.0, 0.0, 0.0)

local SKILL_IDS = {
    'block', 'armorer', 'mediumarmor', 'heavyarmor', 'bluntweapon',
    'longblade', 'axe', 'spear', 'athletics', 'enchant',
    'destruction', 'alteration', 'illusion', 'conjuration', 'mysticism',
    'restoration', 'alchemy', 'unarmored', 'security', 'sneak',
    'acrobatics', 'lightarmor', 'shortblade', 'marksman', 'mercantile',
    'speechcraft', 'handtohand',
}

local ATTRIBUTE_IDS = {
    'strength', 'intelligence', 'willpower', 'agility',
    'speed', 'endurance', 'personality', 'luck',
}

local textureCache = {}

local function isSummaryEnabled()
    if not mS.summaryStorage then return true end
    local value = mS.summaryStorage:get('enableSummaryPage')
    if value == nil then return true end
    return value == true
end

local function isOppAfflictionLedgerEnabled()
    if not mS.summaryStorage then return true end
    local value = mS.summaryStorage:get('showOppAfflictionLedger')
    if value == nil then return true end
    return value == true
end

local function getOppAfflictionLedger()
    if not isOppAfflictionLedgerEnabled() then return nil end
    local opp = I and I.OfPestilenceAndPurification
    if not opp or type(opp.getAfflictionLedger) ~= 'function' then return nil end
    local ok, entries = pcall(function() return opp.getAfflictionLedger() end)
    if not ok or type(entries) ~= 'table' then return nil end
    return entries
end

local function getOppAfflictionEntryCount()
    local entries = getOppAfflictionLedger()
    if not entries then return 0 end
    return math.max(1, #entries)
end

local function safeCall(fn, fallback)
    local ok, value = pcall(fn)
    if ok then return value end
    return fallback
end

local function getTexture(path)
    if not path or path == '' then return nil end
    if textureCache[path] == nil then
        local ok, resource = pcall(ui.texture, { path = path })
        textureCache[path] = ok and resource or false
    end
    return textureCache[path] or nil
end

local function clamp(value, minValue, maxValue)
    return math.max(minValue, math.min(maxValue, value))
end

local function getRealTime()
    return safeCall(function() return input.getRealTime() end, core.getRealTime()) or core.getRealTime()
end

local function scaled(value, scale)
    scale = scale or summaryLayoutScale or 1.0
    return math.max(1, math.floor((value or 0) * scale + 0.5))
end

local function getContentScale(windowW, windowH)
    return clamp(math.min(windowW / DEFAULT_WINDOW_W, windowH / DEFAULT_WINDOW_H), 1.0, MAX_CONTENT_SCALE)
end

local function getLayerSize()
    local index = safeCall(function() return ui.layers.indexOf('Windows') end, nil)
    local layer = index and ui.layers[index] or nil
    return (layer and layer.size) or ui.screenSize()
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
        math.floor(screen.y * 0.462 - size.y * 0.5)
    )
end

local function clampWindowPosition(position, size)
    local screen = getLayerSize()
    return util.vector2(
        clamp(math.floor(position.x), 0, math.max(0, screen.x - size.x)),
        clamp(math.floor(position.y), 0, math.max(0, screen.y - size.y))
    )
end

local function getWindowSize()
    if not summaryWindowSize then
        summaryWindowSize = defaultWindowSize()
    end
    local screen = getLayerSize()
    summaryWindowSize = util.vector2(
        clamp(math.floor(summaryWindowSize.x), MIN_WINDOW_W, math.min(MAX_WINDOW_W, math.max(MIN_WINDOW_W, screen.x))),
        clamp(math.floor(summaryWindowSize.y), MIN_WINDOW_H, math.min(MAX_WINDOW_H, math.max(MIN_WINDOW_H, screen.y)))
    )
    return summaryWindowSize
end

local function getWindowPosition(size)
    if not summaryWindowPosition then
        summaryWindowPosition = defaultWindowPosition(size)
    end
    summaryWindowPosition = clampWindowPosition(summaryWindowPosition, size)
    return summaryWindowPosition
end

local function fmtNum(n)
    if n == math.huge then return 'Inf.' end
    if type(n) ~= 'number' then return tostring(n or 0) end
    if math.abs(n - math.floor(n)) < 0.01 then
        return tostring(math.floor(n + 0.0001))
    end
    return string.format('%.1f', n)
end

local function fmtRate(value)
    if not value then return 'N/A' end
    return string.format('%.1f', value)
end

local function fmtPercent(value)
    if value == nil then return 'N/A' end
    return string.format('%.1f%%', value)
end

local function fmtKdRatio(profileId)
    local kills = derived.get(profileId, 'killCount') or 0
    local deaths = derived.get(profileId, 'deathCount') or 0
    return string.format('%d:%d', math.floor(kills), math.floor(deaths))
end

local function combatAccuracy(profileId)
    local swings = derived.get(profileId, 'swingCount')
    local hits = derived.get(profileId, 'hitCount')
    if not swings or swings <= 0 then return nil end
    return (hits / swings) * 100
end

local function countSerializedEntries(profileId, key)
    local raw = safeCall(function() return storage.playerSection(profileId):get(key) end, '') or ''
    if raw == '' then return 0 end
    local count = 0
    for _ in raw:gmatch('[^\n]+') do
        count = count + 1
    end
    return count
end

local WORLD_UNITS_PER_FOOT = 73.0
local METERS_PER_FOOT = 0.3048

local function worldUnitsToFeet(units)
    return (units or 0) / WORLD_UNITS_PER_FOOT
end

local function worldUnitsToMeters(units)
    return worldUnitsToFeet(units) * METERS_PER_FOOT
end

local function fmtWorldDistance(units)
    local meters = worldUnitsToMeters(units)
    local absMeters = math.abs(meters)
    if absMeters >= 1000 then
        return string.format('%.2f km', meters / 1000)
    end
    return string.format('%.1f m', meters)
end

local function fmtDistPerDay(profileId)
    local rate = derived.safePerDay(derived.totalDistance(profileId))
    if not rate then return 'N/A' end
    return fmtWorldDistance(rate)
end

local function fmtPlaytime(seconds)
    seconds = math.max(0, math.floor(seconds or 0))
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local days = math.floor(hours / 24)
    local remHours = hours % 24
    if days > 0 then
        return string.format('%dd %02dh %02dm', days, remHours, minutes)
    end
    return string.format('%dh %02dm', hours, minutes)
end


local function clipText(text, maxLen)
    text = tostring(text or '')
    maxLen = math.max(1, math.floor((maxLen or 1) * (summaryLayoutScale or 1.0)))
    if #text <= maxLen then return text end
    if maxLen <= 3 then return text:sub(1, maxLen) end
    return text:sub(1, maxLen - 3) .. '...'
end

local function makeText(text, opts)
    opts = opts or {}
    local scale = opts.noScale and 1.0 or (summaryLayoutScale or 1.0)
    local boxSize = opts.boxSize
    if boxSize and opts.scaleBox ~= false and scale ~= 1.0 then
        boxSize = util.vector2(boxSize.x, scaled(boxSize.y, scale))
    end
    return {
        type = ui.TYPE.Text,
        props = {
            text = text or '',
            textSize = scaled(opts.size or 14, scale),
            textColor = opts.color or TEXT,
            autoSize = opts.autoSize ~= false,
            size = boxSize,
            textShadow = opts.shadow ~= false,
            textShadowColor = util.color.rgb(0, 0, 0),
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

local function ruleLine(width, height, color, alpha)
    return {
        type = ui.TYPE.Image,
        props = {
            resource = WHITE_TEX,
            size = util.vector2(width or 1, height or 1),
            color = color or PALE_GOLD,
            alpha = alpha or 0.35,
        },
    }
end

local function framedButton(label, width, onClick)
    return {
        type = ui.TYPE.Widget,
        props = { size = util.vector2(width, scaled(30)) },
        events = {
            mouseClick = async:callback(onClick),
        },
        content = ui.content {
            {
                template = MWUI.templates.boxSolid,
                props = { alpha = 0.92 },
                content = ui.content {
                    {
                        template = MWUI.templates.padding,
                        props = { padding = 6 },
                        content = ui.content {
                            makeText(label, {
                                size = 14,
                                color = VALUE,
                                alignH = ui.ALIGNMENT.Center,
                                autoSize = false,
                                boxSize = util.vector2(width - 12, 18),
                            }),
                        },
                    },
                },
            },
        },
    }
end

local function metricCell(label, value, width, tone, rowHeight, labelSize, valueSize, inline, valueFraction)
    rowHeight = scaled(rowHeight or ROW_H)
    labelSize = labelSize or 12
    valueSize = valueSize or 15
    local displayTone = tone or VALUE
    if value == '0' or value == '0.0' or value == '0.0 m' or value == '0.00 km' or value == '0h 00m' then
        displayTone = SUBTLE
    end
    if inline then
        local valueWidth = math.floor(width * (valueFraction or 0.46))
        local labelWidth = width - valueWidth - 6
        return {
            type = ui.TYPE.Widget,
            props = { size = util.vector2(width, rowHeight) },
            content = ui.content {
                hstack({
                    makeText(label, {
                        size = labelSize,
                        color = PALE_GOLD,
                        autoSize = false,
                        boxSize = util.vector2(labelWidth, rowHeight),
                        scaleBox = false,
                        alignV = ui.ALIGNMENT.Center,
                    }),
                    spacer(1, 6),
                    makeText(value, {
                        size = valueSize,
                        color = displayTone,
                        autoSize = false,
                        boxSize = util.vector2(valueWidth, rowHeight),
                        scaleBox = false,
                        alignH = ui.ALIGNMENT.End,
                        alignV = ui.ALIGNMENT.Center,
                    }),
                }, util.vector2(width, rowHeight), ui.ALIGNMENT.Center),
            },
        }
    end
    return {
        type = ui.TYPE.Widget,
        props = { size = util.vector2(width, rowHeight) },
        content = ui.content {
            vstack({
                makeText(label, { size = labelSize, color = PALE_GOLD }),
                spacer(0),
                makeText(value, { size = valueSize, color = displayTone }),
            }, util.vector2(width, rowHeight)),
        },
    }
end

local function pairRow(innerWidth, aLabel, aValue, bLabel, bValue, aTone, bTone, compact, valueFraction)
    local gap = compact and 8 or 10
    local cellWidth = math.floor((innerWidth - gap) / 2)
    local rowHeightRaw = compact and COMPACT_ROW_H or ROW_H
    local rowHeight = scaled(rowHeightRaw)
    local labelSize = compact and METRIC_LABEL_SIZE or METRIC_LABEL_SIZE
    local valueSize = compact and METRIC_VALUE_SIZE_COMPACT or METRIC_VALUE_SIZE
    local inline = true
    return hstack({
        metricCell(aLabel, aValue, cellWidth, aTone, rowHeightRaw, labelSize, valueSize, inline, valueFraction),
        spacer(1, gap),
        metricCell(bLabel or '', bValue or '', cellWidth, bTone, rowHeightRaw, labelSize, valueSize, inline, valueFraction),
    }, util.vector2(innerWidth, rowHeight), ui.ALIGNMENT.Center)
end

local function pairRowDivider(innerWidth, aLabel, aValue, bLabel, bValue, aTone, bTone, compact, valueFraction)
    local gap = compact and 8 or 10
    local dividerW = 2
    local sideGap = math.max(2, math.floor((gap - dividerW) / 2))
    local cellWidth = math.floor((innerWidth - sideGap * 2 - dividerW) / 2)
    local rowHeightRaw = compact and COMPACT_ROW_H or ROW_H
    local rowHeight = scaled(rowHeightRaw)
    local labelSize = compact and METRIC_LABEL_SIZE or METRIC_LABEL_SIZE
    local valueSize = compact and METRIC_VALUE_SIZE_COMPACT or METRIC_VALUE_SIZE
    local inline = true
    return hstack({
        metricCell(aLabel, aValue, cellWidth, aTone, rowHeightRaw, labelSize, valueSize, inline, valueFraction),
        spacer(1, sideGap),
        ruleLine(dividerW, rowHeight, PALE_GOLD, 0.34),
        spacer(1, sideGap),
        metricCell(bLabel or '', bValue or '', cellWidth, bTone, rowHeightRaw, labelSize, valueSize, inline, valueFraction),
    }, util.vector2(innerWidth, rowHeight), ui.ALIGNMENT.Center)
end
local function bannerInlineMetric(label, value, width, valueColor)
    local h = scaled(20)
    local gap = scaled(8)
    local parts = {}
    if label and label ~= '' then
        parts[#parts + 1] = makeText(label, { size = 13, color = PALE_GOLD })
    end
    if value and value ~= '' then
        if #parts > 0 then parts[#parts + 1] = spacer(1, gap) end
        parts[#parts + 1] = makeText(value, { size = 14, color = valueColor or VALUE })
    end
    return {
        type = ui.TYPE.Widget,
        props = { size = util.vector2(width, h) },
        content = ui.content {
            hstack(parts, util.vector2(width, h), ui.ALIGNMENT.Center),
        },
    }
end

local function bannerPairRow(width, leftLabel, leftValue, rightLabel, rightValue)
    local gap = scaled(18)
    local h = scaled(20)
    local cellWidth = math.floor((width - gap) / 2)
    return hstack({
        bannerInlineMetric(leftLabel, leftValue, cellWidth),
        spacer(1, gap),
        bannerInlineMetric(rightLabel, rightValue, cellWidth),
    }, util.vector2(width, h), ui.ALIGNMENT.Center)
end


local function sectionFrame(size, children, alpha)
    return {
        type = ui.TYPE.Widget,
        props = { size = size },
        content = ui.content {
            {
                template = MWUI.templates.boxTransparent,
                props = { alpha = alpha or 0.98 },
                content = ui.content {
                    solidFill(0.72, VANILLA_BLUE),
                    solidFill(0.08, BRONZE),
                    {
                        template = MWUI.templates.padding,
                        props = { padding = PANEL_PAD },
                        content = ui.content {
                            vstack({
                                spacer(3),
                                ruleLine(size.x - PANEL_PAD * 2, 1, PALE_GOLD, 0.18),
                                spacer(5),
                                unpack(children),
                            }, util.vector2(size.x - PANEL_PAD * 2, size.y - PANEL_PAD * 2)),
                        },
                    },
                },
            },
        },
    }
end

local function panel(title, size, rows, accent, rowGap)
    local innerWidth = size.x - PANEL_PAD * 2
    rowGap = rowGap or 6
    local content = {
        makeText(title, { size = PANEL_TITLE_SIZE, color = accent or GOLD }),
        spacer(4),
    }
    for i, row in ipairs(rows) do
        content[#content + 1] = row
        if i < #rows then
            content[#content + 1] = spacer(rowGap)
        end
    end
    return sectionFrame(size, {
        vstack(content, util.vector2(innerWidth, size.y - PANEL_PAD * 2)),
    })
end


local function metricSpec(label, value, tone)
    return { label = label, value = value, tone = tone }
end

local function metricColumn(items, width, rowHeight, labelSize, valueSize, gap)
    local rows = {}
    local rowHeightRaw = rowHeight or COMPACT_ROW_H
    local gapH = scaled(gap or 1)
    for i, item in ipairs(items) do
        rows[#rows + 1] = metricCell(item.label or '', item.value or '', width, item.tone, rowHeightRaw, labelSize, valueSize, true)
        if i < #items then
            rows[#rows + 1] = spacer(gapH)
        end
    end
    local totalHeight = (#items * scaled(rowHeightRaw)) + (math.max(0, #items - 1) * gapH)
    return vstack(rows, util.vector2(width, totalHeight))
end


local function sectionHeaderCell(text, width)
    local h = scaled(22)
    return {
        type = ui.TYPE.Widget,
        props = { size = util.vector2(width, h) },
        content = ui.content {
            makeText(text, {
                size = 15,
                color = GOLD,
                autoSize = false,
                boxSize = util.vector2(width, 22),
            }),
        },
    }
end

local function groupedMetricPanel(title, size, groups, accent, colCount, rowHeight, labelSize, valueSize, gap, valueFraction)
    colCount = colCount or #groups
    rowHeight = rowHeight or COMPACT_ROW_H
    labelSize = labelSize or 12
    valueSize = valueSize or 14
    gap = gap or 1
    local gapH = scaled(gap)
    local headerH = scaled(22)
    local titleBlockH = scaled(24)
    local innerWidth = size.x - PANEL_PAD * 2
    local colGap = PANEL_GAP
    local colWidth = math.floor((innerWidth - colGap * (colCount - 1)) / colCount)
    local cols = {}
    for i, group in ipairs(groups) do
        local colRows = { sectionHeaderCell(group.title, colWidth), spacer(scaled(2)) }
        for j, item in ipairs(group.items) do
            colRows[#colRows + 1] = metricCell(item.label or '', item.value or '', colWidth, item.tone, rowHeight, labelSize, valueSize, true, valueFraction)
            if j < #group.items then
                colRows[#colRows + 1] = spacer(gapH)
            end
        end
        cols[#cols + 1] = vstack(colRows, util.vector2(colWidth, size.y - PANEL_PAD * 2 - titleBlockH))
        if i < #groups then
            cols[#cols + 1] = spacer(1, math.max(2, math.floor((colGap - 1) / 2)))
            cols[#cols + 1] = ruleLine(2, size.y - PANEL_PAD * 2 - titleBlockH, PALE_GOLD, 0.34)
            cols[#cols + 1] = spacer(1, math.max(2, math.ceil((colGap - 1) / 2)))
        end
    end
    local rows = { makeText(title, { size = PANEL_TITLE_SIZE, color = accent or GOLD }), spacer(scaled(4)), hstack(cols, util.vector2(innerWidth, size.y - PANEL_PAD * 2 - titleBlockH)) }
    return sectionFrame(size, { vstack(rows, util.vector2(innerWidth, size.y - PANEL_PAD * 2)) })
end

local function metricListPanel(title, size, items, accent, colCount, rowHeight, labelSize, valueSize, gap)
    colCount = colCount or 2
    rowHeight = rowHeight or COMPACT_ROW_H
    labelSize = labelSize or 12
    valueSize = valueSize or 14
    gap = gap or 1
    local innerWidth = size.x - PANEL_PAD * 2
    local colGap = PANEL_GAP
    local colWidth = math.floor((innerWidth - colGap * (colCount - 1)) / colCount)
    local columns = {}
    local perCol = math.ceil(#items / colCount)
    for col = 1, colCount do
        local startIndex = (col - 1) * perCol + 1
        local endIndex = math.min(#items, startIndex + perCol - 1)
        local slice = {}
        for i = startIndex, endIndex do
            slice[#slice + 1] = items[i]
        end
        columns[#columns + 1] = metricColumn(slice, colWidth, rowHeight, labelSize, valueSize, gap)
        if col < colCount then
            columns[#columns + 1] = spacer(1, colGap)
        end
    end
    local rows = {
        makeText(title, { size = PANEL_TITLE_SIZE, color = accent or GOLD }),
        spacer(4),
        hstack(columns, util.vector2(innerWidth, size.y - PANEL_PAD * 2 - 24)),
    }
    return sectionFrame(size, {
        vstack(rows, util.vector2(innerWidth, size.y - PANEL_PAD * 2)),
    })
end


local function afflictionEffectText(entry)
    local parts = {}
    if type(entry) ~= 'table' then return '' end
    if type(entry.effects) == 'table' then
        for _, effect in ipairs(entry.effects) do
            if type(effect) == 'table' and type(effect.text) == 'string' and effect.text ~= '' then
                parts[#parts + 1] = effect.text
            end
        end
    end
    local text = table.concat(parts, ', ')
    if text == '' then text = '-' end
    if entry.active == false then
        text = 'Locked: ' .. text
    end
    return text
end

local function afflictionLedgerPanel(size)
    local entries = getOppAfflictionLedger() or {}
    local items = {}
    if #entries == 0 then
        items[#items + 1] = metricSpec('Active diseases', 'None', SUBTLE)
    else
        for _, entry in ipairs(entries) do
            local label = tostring(entry.title or entry.diseaseId or 'Unknown')
            local value = afflictionEffectText(entry)
            items[#items + 1] = metricSpec(label, value, entry.active and MINT or SUBTLE)
        end
    end
    return metricListPanel('Afflictions & Adaptations', size, items, MINT, 1, 20, 13, 12, 2)
end

local function getNpcRecord()
    return safeCall(function() return T.NPC.record(self) end, nil)
end

local function getBirthSignRecord()
    local signId = safeCall(function() return T.Player.getBirthSign(self) end, nil)
    if not signId or signId == '' then return nil end
    return safeCall(function() return T.Player.birthSigns.records[signId] end, nil)
end

local function getBirthSignName()
    local record = getBirthSignRecord()
    return (record and record.name) or 'Unknown'
end

local function getBirthSignTexture()
    local record = getBirthSignRecord()
    return record and getTexture(record.texture) or nil
end

local function getRaceName(record)
    if not record or not record.race then return 'Unknown' end
    local raceRecord = safeCall(function() return T.NPC.races.records[record.race] end, nil)
    return (raceRecord and raceRecord.name) or record.race
end

local function normalizeRaceToken(value)
    if type(value) ~= 'string' then return '' end
    return value:lower():gsub('^%s+', ''):gsub('%s+$', ''):gsub('[%s%-%_]+', '')
end

local function getRacePortraitTexture(record)
    return nil
end

local function getClassName(record)
    if not record or not record.class then return 'Unknown' end
    local classRecord = safeCall(function() return T.NPC.classes.records[record.class] end, nil)
    return (classRecord and classRecord.name) or record.class
end

local function getPlayerName(record)
    return (record and record.name) or 'Player'
end

local function getFactionStanding(record)
    local function getFactionRecord(factionId)
        if type(factionId) ~= 'string' or factionId == '' then return nil end
        return safeCall(function() return core.factions.record(factionId) end, nil)
            or safeCall(function() return core.factions.records[factionId] end, nil)
            or safeCall(function() return T.Faction.records[factionId] end, nil)
            or safeCall(function() return T.Faction.records[string.lower(factionId)] end, nil)
    end

    local function getFactionIds()
        local ids = {}
        local seen = {}
        local direct = safeCall(function() return self.type.getFactions(self) end, nil)
        if type(direct) == 'table' then
            local okLen, len = pcall(function() return #direct end)
            if okLen and type(len) == 'number' then
                for i = 1, len do
                    local id = direct[i]
                    if type(id) == 'string' and id ~= '' and not seen[id] then
                        seen[id] = true
                        ids[#ids + 1] = id
                    end
                end
            else
                for k, v in pairs(direct) do
                    local id = type(v) == 'string' and v or k
                    if type(id) == 'string' and id ~= '' and not seen[id] then
                        seen[id] = true
                        ids[#ids + 1] = id
                    end
                end
            end
        end
        if record and type(record.faction) == 'string' and record.faction ~= '' and not seen[record.faction] then
            seen[record.faction] = true
            ids[#ids + 1] = record.faction
        end
        return ids
    end

    local function rankNameFromEntry(rank)
        if not rank then return nil end
        local directName = safeCall(function() return rank.name end, nil)
        if type(directName) == 'string' and directName ~= '' then
            return directName
        end
        if type(rank) == 'table' then
            local tableName = rank.name or rank.title or rank.rankName or rank[1]
            if type(tableName) == 'string' and tableName ~= '' then
                return tableName
            end
        end
        if type(rank) == 'string' and rank ~= '' then
            return rank
        end
        return nil
    end

    local function resolveRankText(factionRecord, factionId, rankValue)
        if safeCall(function() return self.type.isExpelled(self, factionId) end, false) then
            return 'Expelled'
        end
        if type(rankValue) ~= 'number' then return '-' end

        local candidates = { rankValue, rankValue + 1, math.max(1, rankValue - 1) }
        for _, index in ipairs(candidates) do
            local rankName = safeCall(function()
                local rank = factionRecord and factionRecord.ranks and factionRecord.ranks[index]
                return rankNameFromEntry(rank)
            end, nil)
            if type(rankName) == 'string' and rankName ~= '' then
                return rankName
            end
        end

        return '-'
    end

    local entries = {}
    for _, factionId in ipairs(getFactionIds()) do
        local factionRecord = getFactionRecord(factionId)
        if factionRecord and not factionRecord.hidden then
            local rankValue = safeCall(function() return self.type.getFactionRank(self, factionId) end, 0)
            local repValue = safeCall(function() return self.type.getFactionReputation(self, factionId) end, 0) or 0
            entries[#entries + 1] = {
                id = factionId,
                name = factionRecord.name or factionId,
                rank = type(rankValue) == 'number' and rankValue or 0,
                rep = repValue,
                rankText = resolveRankText(factionRecord, factionId, rankValue),
            }
        end
    end

    local primaryName, primaryRank = 'None', '-'
    if #entries > 0 then
        local best = entries[1]
        for i = 2, #entries do
            local candidate = entries[i]
            if (candidate.rank or 0) > (best.rank or 0)
                or ((candidate.rank or 0) == (best.rank or 0) and (candidate.rep or 0) > (best.rep or 0)) then
                best = candidate
            end
        end
        primaryName = best.name or primaryName
        primaryRank = best.rankText or primaryRank
    end

    return primaryName, primaryRank, #entries, entries
end

local function getReputation()
    return safeCall(function() return T.NPC.stats.reputation(self).current end, 0)
end

local function getLevel()
    return safeCall(function() return T.Actor.stats.level(self).current end, 1)
end

local function getAttributeExtremes()
    local bestName, bestValue = 'N/A', -math.huge
    local worstName, worstValue = 'N/A', math.huge
    for _, attrId in ipairs(ATTRIBUTE_IDS) do
        local stat = safeCall(function() return T.Actor.stats.attributes[attrId](self) end, nil)
        local value = stat and stat.modified or nil
        if value then
            local name = safeCall(function() return core.stats.Attribute.record(attrId).name end, attrId)
            if value > bestValue then bestValue, bestName = value, name end
            if value < worstValue then worstValue, worstName = value, name end
        end
    end
    if bestValue == -math.huge then bestValue = 0 end
    if worstValue == math.huge then worstValue = 0 end
    return string.format('%s (%s)', bestName, fmtNum(bestValue)), string.format('%s (%s)', worstName, fmtNum(worstValue))
end

local function getSkillExtremes()

    local bestName, bestValue = 'N/A', -math.huge
    local worstName, worstValue = 'N/A', math.huge
    for _, skillId in ipairs(SKILL_IDS) do
        local stat = safeCall(function() return T.NPC.stats.skills[skillId](self) end, nil)
        local value = stat and stat.modified or nil
        if value then
            local name = safeCall(function() return core.stats.Skill.record(skillId).name end, skillId)
            if value > bestValue then bestValue, bestName = value, name end
            if value < worstValue then worstValue, worstName = value, name end
        end
    end
    if bestValue == -math.huge then bestValue = 0 end
    if worstValue == math.huge then worstValue = 0 end
    return string.format('%s (%s)', bestName, fmtNum(bestValue)), string.format('%s (%s)', worstName, fmtNum(worstValue))
end

local function getTopWeaponLine(state)
    local top = safeCall(function() return state.getTopWeapons() end, nil)
    if not top or not top[1] then return 'None', 0 end
    return top[1].name or 'None', top[1].count or 0
end

local function getTopSpellLine(state)
    local top = safeCall(function() return state.getTopSpells() end, nil)
    if not top or not top[1] then return 'None', 0 end
    return top[1].name or 'None', top[1].count or 0
end


local function getScreenMetrics(windowSize)
    local size = windowSize or getWindowSize()
    local windowW = math.floor(size.x)
    local windowH = math.floor(size.y)
    local scale = getContentScale(windowW, windowH)
    summaryLayoutScale = scale
    local headerH = scaled(HEADER_H, scale)
    local panelGap = scaled(PANEL_GAP, scale)
    local scrollbarW = scaled(SCROLLBAR_W, scale)
    local innerW = windowW - OUTER_PAD * 2
    local innerH = windowH - OUTER_PAD * 2
    local heroH = scaled(108, scale)
    local viewportH = math.max(80, innerH - headerH - panelGap)
    local stacked = windowW < WIDE_LAYOUT_W
    local designInnerH = DESIGN_WINDOW_H - OUTER_PAD * 2
    local designScrollContentH = designInnerH - HEADER_H - PANEL_GAP

    local contentWNoScroll = innerW
    local scrollContentH
    local profileH
    local bodyH
    local rightTopH
    local rightBottomH
    local rightAfflictionH = 0
    local hasOppAfflictionLedger = getOppAfflictionLedger() ~= nil
    if hasOppAfflictionLedger then
        local rows = getOppAfflictionEntryCount()
        rightAfflictionH = clamp(scaled(54 + rows * 22, scale), scaled(92, scale), scaled(380, scale))
    end

    if stacked then
        profileH = scaled(420, scale)
        bodyH = scaled(500, scale)
        rightTopH = scaled(430, scale)
        rightBottomH = scaled(260, scale)
        local afflictionStackH = hasOppAfflictionLedger and (panelGap + rightAfflictionH) or 0
        scrollContentH = heroH + panelGap + profileH + panelGap + bodyH + panelGap + rightTopH + afflictionStackH + panelGap + rightBottomH
    else
        scrollContentH = math.max(viewportH, designScrollContentH)
        bodyH = scrollContentH - heroH - panelGap
        local rightGapTotal = panelGap + (hasOppAfflictionLedger and panelGap or 0)
        local availableRightH = math.max(scaled(300, scale), bodyH - rightAfflictionH - rightGapTotal)
        rightTopH = math.floor(availableRightH * 0.57)
        rightBottomH = availableRightH - rightTopH - panelGap
        local requiredBodyH = rightTopH + panelGap + (hasOppAfflictionLedger and (rightAfflictionH + panelGap) or 0) + rightBottomH
        bodyH = math.max(bodyH, requiredBodyH)
        scrollContentH = heroH + panelGap + bodyH
        profileH = bodyH
    end

    local canScroll = scrollContentH > viewportH + 1
    local scrollBarReserve = canScroll and (scrollbarW + panelGap) or 0
    local contentW = contentWNoScroll - scrollBarReserve

    local leftW
    local middleW
    local rightW
    if stacked then
        leftW = contentW
        middleW = contentW
        rightW = contentW
    else
        leftW = math.floor(contentW * 0.35)
        middleW = math.floor(contentW * 0.35)
        rightW = contentW - leftW - middleW - panelGap * 2
    end

    local maxScroll = math.max(0, scrollContentH - viewportH)
    summaryScrollY = clamp(summaryScrollY or 0, -maxScroll, 0)
    return {
        screen = getLayerSize(),
        window = util.vector2(windowW, windowH),
        position = getWindowPosition(util.vector2(windowW, windowH)),
        scale = scale,
        headerH = headerH,
        panelGap = panelGap,
        scrollbarW = scrollbarW,
        scrollButtonH = scaled(SCROLLBAR_BUTTON_H, scale),
        headerW = innerW,
        inner = util.vector2(contentW, scrollContentH),
        viewport = util.vector2(innerW, viewportH),
        scrollContent = util.vector2(contentW, scrollContentH),
        stacked = stacked,
        canScroll = canScroll,
        maxScroll = maxScroll,
        heroH = heroH,
        profileH = profileH,
        bodyH = bodyH,
        leftW = leftW,
        middleW = middleW,
        rightW = rightW,
        rightTopH = rightTopH,
        rightAfflictionH = rightAfflictionH,
        hasOppAfflictionLedger = hasOppAfflictionLedger,
        rightBottomH = rightBottomH,
    }
end

local function portraitBlock(size, portraitTexture, signName)
    local innerW = size.x - 16
    local innerH = size.y - 16
    local imageW = 116
    local imageH = innerH - 16
    local portraitResource = portraitTexture

    local portraitContent = portraitResource and {
        type = ui.TYPE.Image,
        props = {
            resource = portraitResource,
            size = util.vector2(imageW, imageH),
            color = VALUE,
        },
    } or spacer(imageH, imageW)

    local captionWidth = innerW - imageW - 26

    return {
        type = ui.TYPE.Widget,
        props = { size = size },
        content = ui.content {
            {
                template = MWUI.templates.boxSolid,
                props = { alpha = 0.92 },
                content = ui.content {
                    solidFill(0.10, BRONZE),
                    {
                        template = MWUI.templates.padding,
                        props = { padding = 8 },
                        content = ui.content {
                            hstack({
                                portraitContent,
                                spacer(1, 10),
                                vstack({
                                    makeText('Portrait', {
                                        size = 14,
                                        color = PALE_GOLD,
                                        alignH = ui.ALIGNMENT.Center,
                                        autoSize = false,
                                        boxSize = util.vector2(captionWidth, 18),
                                    }),
                                    spacer(2),
                                    makeText('Adventurer showcase', {
                                        size = 12,
                                        color = SUBTLE,
                                        alignH = ui.ALIGNMENT.Center,
                                        autoSize = false,
                                        boxSize = util.vector2(captionWidth, 16),
                                    }),
                                }, util.vector2(captionWidth, imageH), ui.ALIGNMENT.Center),
                            }, util.vector2(innerW, innerH)),
                        },
                    },
                },
            },
        },
    }
end


local function buildHeroBanner(state, metrics)
    local record = getNpcRecord()
    local signName = getBirthSignName()
    local name = getPlayerName(record)
    local raceName = getRaceName(record)
    local className = getClassName(record)
    local innerWidth = metrics.inner.x - PANEL_PAD * 2
    local bannerH = metrics.heroH - PANEL_PAD * 2 - scaled(6)

    local bestSkill = getSkillExtremes()
    local topWeapon, topWeaponCount = getTopWeaponLine(state)
    local topSpell, topSpellCount = getTopSpellLine(state)

    local nameW = 340
    local centerW = 360
    local statsW = 220
    local dividerGap = scaled(12)
    local totalW = nameW + centerW + statsW + dividerGap * 4 + 4
    if totalW > innerWidth then
        local overflow = totalW - innerWidth
        centerW = centerW - math.ceil(overflow / 2)
        nameW = nameW - math.floor(overflow / 4)
        statsW = statsW - math.floor(overflow / 4)
        totalW = nameW + centerW + statsW + dividerGap * 4 + 4
    end

    local contentRow = hstack({
        vstack({
            makeText(name, {
                size = HERO_NAME_SIZE,
                color = GOLD,
                alignH = ui.ALIGNMENT.Center,
                autoSize = false,
                boxSize = util.vector2(nameW, 34),
            }),
            spacer(scaled(2)),
            makeText(raceName .. ' - ' .. className, {
                size = HERO_META_SIZE,
                color = TEXT,
                alignH = ui.ALIGNMENT.Center,
                autoSize = false,
                boxSize = util.vector2(nameW, 22),
            }),
            spacer(scaled(4)),
            makeText(signName, {
                size = HERO_SIGN_SIZE,
                color = VALUE,
                alignH = ui.ALIGNMENT.Center,
                autoSize = false,
                boxSize = util.vector2(nameW, 20),
            }),
        }, util.vector2(nameW, bannerH), ui.ALIGNMENT.Center),
        spacer(1, dividerGap),
        ruleLine(2, bannerH, PALE_GOLD, 0.40),
        spacer(1, dividerGap),
        vstack({
            bannerPairRow(centerW,
                'Top Skill', clipText(bestSkill, 28),
                'Fav. Weapon', clipText(string.format('%s (%s)', topWeapon, fmtNum(topWeaponCount)), 26)
            ),
            spacer(scaled(8)),
            bannerInlineMetric('Fav. Spell', clipText(string.format('%s (%s)', topSpell, fmtNum(topSpellCount)), 30), centerW),
        }, util.vector2(centerW, bannerH), ui.ALIGNMENT.Center),
        spacer(1, dividerGap),
        ruleLine(2, bannerH, PALE_GOLD, 0.40),
        spacer(1, dividerGap),
        vstack({
            bannerPairRow(statsW, 'Level', fmtNum(getLevel()), 'Reputation', fmtNum(getReputation())),
            spacer(scaled(8)),
            bannerPairRow(statsW, 'Playtime', fmtPlaytime(derived.get(state.profileId, 'playSeconds')), 'Days Passed', fmtNum(derived.displayDaysPassed())),
        }, util.vector2(statsW, bannerH), ui.ALIGNMENT.Center),
    }, util.vector2(totalW, bannerH), ui.ALIGNMENT.Center)

    return sectionFrame(util.vector2(metrics.inner.x, metrics.heroH), {
        {
            type = ui.TYPE.Flex,
            props = { horizontal = true, autoSize = false, size = util.vector2(innerWidth, metrics.heroH - PANEL_PAD * 2), arrange = ui.ALIGNMENT.Center },
            content = ui.content { contentRow },
        },
    })
end

local function buildProfilePanel(state, metrics)
    local bestSkill, worstSkill = getSkillExtremes()
    local bestAttr, worstAttr = getAttributeExtremes()
    local topWeapon, topWeaponCount = getTopWeaponLine(state)
    local topSpell, topSpellCount = getTopSpellLine(state)
    local factionName, factionRank, factionCount, factionEntries = getFactionStanding(getNpcRecord())
    local innerWidth = metrics.leftW - PANEL_PAD * 2
    local dividerW = 2
    local dividerGap = 8
    local colWidth = math.floor((innerWidth - dividerGap * 2 - dividerW) / 2)
    local valueFractionWide = 0.64
    local valueFractionShort = 0.38
    local rows = {
        metricCell('Top Skill', clipText(bestSkill, 26), colWidth, VALUE, COMPACT_ROW_H, METRIC_LABEL_SIZE, METRIC_VALUE_SIZE_COMPACT, true, valueFractionWide),
        metricCell('Low Skill', clipText(worstSkill, 26), colWidth, VALUE, COMPACT_ROW_H, METRIC_LABEL_SIZE, METRIC_VALUE_SIZE_COMPACT, true, valueFractionWide),
        metricCell('Top Attr.', clipText(bestAttr, 24), colWidth, VALUE, COMPACT_ROW_H, METRIC_LABEL_SIZE, METRIC_VALUE_SIZE_COMPACT, true, valueFractionWide),
        metricCell('Low Attr.', clipText(worstAttr, 24), colWidth, VALUE, COMPACT_ROW_H, METRIC_LABEL_SIZE, METRIC_VALUE_SIZE_COMPACT, true, valueFractionWide),
        metricCell('Fav. Weapon', clipText(string.format('%s (%s)', topWeapon, fmtNum(topWeaponCount)), 32), colWidth, VALUE, COMPACT_ROW_H, METRIC_LABEL_SIZE, METRIC_VALUE_SIZE_COMPACT, true, 0.70),
        metricCell('Fav. Spell', clipText(string.format('%s (%s)', topSpell, fmtNum(topSpellCount)), 32), colWidth, VALUE, COMPACT_ROW_H, METRIC_LABEL_SIZE, METRIC_VALUE_SIZE_COMPACT, true, 0.70),
        metricCell('Effects', fmtNum(derived.get(state.profileId, 'spellEffectsLearned')), colWidth, VALUE, COMPACT_ROW_H, METRIC_LABEL_SIZE, METRIC_VALUE_SIZE_COMPACT, true, valueFractionShort),
        metricCell('Training', fmtNum(derived.get(state.profileId, 'trainCount')), colWidth, VALUE, COMPACT_ROW_H, METRIC_LABEL_SIZE, METRIC_VALUE_SIZE_COMPACT, true, valueFractionShort),
        metricCell('Artifacts', fmtNum(derived.get(state.profileId, 'artifactsFound')), colWidth, VALUE, COMPACT_ROW_H, METRIC_LABEL_SIZE, METRIC_VALUE_SIZE_COMPACT, true, valueFractionShort),
        metricCell('Ingredients Foraged', fmtNum(derived.get(state.profileId, 'plantsForaged')), colWidth, VALUE, COMPACT_ROW_H, METRIC_LABEL_SIZE, METRIC_VALUE_SIZE_COMPACT, true, valueFractionShort),
        metricCell('Most Gold Carried', fmtNum(derived.get(state.profileId, 'mostGold')), colWidth, VALUE, COMPACT_ROW_H, METRIC_LABEL_SIZE, METRIC_VALUE_SIZE_COMPACT, true, valueFractionShort),
        metricCell('Highest Point', fmtWorldDistance(derived.get(state.profileId, 'highestPoint')), colWidth, VALUE, COMPACT_ROW_H, METRIC_LABEL_SIZE, METRIC_VALUE_SIZE_COMPACT, true, valueFractionShort),
        metricCell('High Bounty', fmtNum(derived.get(state.profileId, 'highestBounty')), colWidth, VALUE, COMPACT_ROW_H, METRIC_LABEL_SIZE, METRIC_VALUE_SIZE_COMPACT, true, valueFractionShort),
        metricCell('Bounties Paid', fmtNum(derived.get(state.profileId, 'bountiesPaid')), colWidth, VALUE, COMPACT_ROW_H, METRIC_LABEL_SIZE, METRIC_VALUE_SIZE_COMPACT, true, valueFractionShort),
        metricCell('Stolen Items', fmtNum(derived.get(state.profileId, 'stolenItemCount')), colWidth, VALUE, COMPACT_ROW_H, METRIC_LABEL_SIZE, METRIC_VALUE_SIZE_COMPACT, true, valueFractionShort),
        metricCell('Stolen Value', fmtNum(derived.get(state.profileId, 'stolenItemValue')), colWidth, VALUE, COMPACT_ROW_H, METRIC_LABEL_SIZE, METRIC_VALUE_SIZE_COMPACT, true, valueFractionShort),
        metricCell('Unique Weap.', fmtNum(countSerializedEntries(state.profileId, 'weaponTallyStr')), colWidth, VALUE, COMPACT_ROW_H, METRIC_LABEL_SIZE, METRIC_VALUE_SIZE_COMPACT, true, valueFractionShort),
        metricCell('Unique Spls.', fmtNum(countSerializedEntries(state.profileId, 'spellTallyStr')), colWidth, VALUE, COMPACT_ROW_H, METRIC_LABEL_SIZE, METRIC_VALUE_SIZE_COMPACT, true, valueFractionShort),
    }

    local leftChildren = {}
    local rightChildren = {}
    for i = 1, #rows, 2 do
        leftChildren[#leftChildren + 1] = rows[i]
        if i < #rows then
            rightChildren[#rightChildren + 1] = rows[i + 1]
        end
        if i + 1 < #rows then
            leftChildren[#leftChildren + 1] = spacer(scaled(2))
            rightChildren[#rightChildren + 1] = spacer(scaled(2))
        end
    end

    local visibleFactionEntries = {}
    for _, entry in ipairs(factionEntries or {}) do
        if entry and entry.name and entry.rankText then
            visibleFactionEntries[#visibleFactionEntries + 1] = entry
        end
    end

    local metricRowsPerColumn = math.ceil(#rows / 2)
    local metricColumnHeight = (metricRowsPerColumn * scaled(COMPACT_ROW_H)) + (math.max(0, metricRowsPerColumn - 1) * scaled(2))

    local content = {
        hstack({
            vstack(leftChildren, util.vector2(colWidth, metricColumnHeight)),
            spacer(1, dividerGap),
            ruleLine(dividerW, metricColumnHeight, PALE_GOLD, 0.40),
            spacer(1, dividerGap),
            vstack(rightChildren, util.vector2(colWidth, metricColumnHeight)),
        }, util.vector2(innerWidth, metricColumnHeight)),
    }

    if #visibleFactionEntries > 0 then
        content[#content + 1] = spacer(scaled(8))
        content[#content + 1] = ruleLine(innerWidth, 1, PALE_GOLD, 0.22)
        content[#content + 1] = spacer(scaled(6))
        for index, entry in ipairs(visibleFactionEntries) do
            content[#content + 1] = pairRowDivider(
                innerWidth,
                '',
                clipText(entry.name, 34),
                '',
                clipText(entry.rankText, 24),
                VALUE,
                VALUE,
                true,
                0.64
            )
            if index < #visibleFactionEntries then
                content[#content + 1] = spacer(scaled(2))
            end
        end
    end

    return panel('Build & Standing', util.vector2(metrics.leftW, metrics.profileH or metrics.bodyH), content, GOLD, 3)
end

local function buildPanels(state, metrics)
    local profileId = state.profileId

    local statsGroup = {
        title = 'Stats',
        items = {
            metricSpec('Quests', fmtNum(derived.get(profileId, 'questCount')), AMBER),
            metricSpec('Days', fmtNum(derived.displayDaysPassed()), AMBER),
            metricSpec('Deaths', fmtNum(derived.get(profileId, 'deathCount')), ROSE),
            metricSpec('K/D Ratio', fmtKdRatio(profileId), SKY),
            metricSpec('Kills / Day', fmtRate(derived.safePerDay(derived.get(profileId, 'killCount'))), ROSE),
            metricSpec('Gold / Day', fmtRate(derived.safePerDay(derived.get(profileId, 'totalGoldFound'))), AMBER),
            metricSpec('Distance / Day', fmtDistPerDay(profileId), SKY),
            metricSpec('Potions / Day', fmtRate(derived.safePerDay(derived.get(profileId, 'potionCount'))), MINT),
            metricSpec('Most Gold', fmtNum(derived.get(profileId, 'mostGold')), AMBER),
            metricSpec('Gold Found', fmtNum(derived.get(profileId, 'totalGoldFound')), AMBER),
            metricSpec('Books Read', fmtNum(derived.get(profileId, 'bookCount')), AMBER),
            metricSpec('Artifacts Collected', fmtNum(derived.get(profileId, 'artifactsFound')), GOLD),
            metricSpec('Diseases', fmtNum(derived.get(profileId, 'diseaseCaught')), ROSE),
            metricSpec('Blights', fmtNum(derived.get(profileId, 'blightCaught')), ROSE),
        },
    }

    local crimeGroup = {
        title = 'Crime',
        items = {
            metricSpec('High Bounty', fmtNum(derived.get(profileId, 'highestBounty')), ROSE),
            metricSpec('Murders', fmtNum(derived.get(profileId, 'murderCount')), ROSE),
            metricSpec('Assaults', fmtNum(derived.get(profileId, 'assaultCount')), TEXT),
            metricSpec('Jail Visits', fmtNum(derived.get(profileId, 'jailCount')), TEXT),
            metricSpec('Bounties Paid', fmtNum(derived.get(profileId, 'bountiesPaid')), AMBER),
            metricSpec('Stolen Items', fmtNum(derived.get(profileId, 'stolenItemCount')), TEXT),
            metricSpec('Stolen Value', fmtNum(derived.get(profileId, 'stolenItemValue')), AMBER),
            metricSpec('Broken Picks', fmtNum(derived.get(profileId, 'lockpicksBroken')), ROSE),
            metricSpec('Broken Probes', fmtNum(derived.get(profileId, 'probesBroken')), ROSE),
            metricSpec('Brute Forced', fmtNum(derived.get(profileId, 'bruteForceCount')), AMBER),
        },
    }

    local combatGroup = {
        title = 'Combat',
        items = {
            metricSpec('Total Kills', fmtNum(derived.get(profileId, 'killCount')), ROSE),
            metricSpec('People Slain', fmtNum(derived.get(profileId, 'npcKillCount')), ROSE),
            metricSpec('Humanoid', fmtNum(derived.get(profileId, 'humanoidKillCount')), TEXT),
            metricSpec('Creatures', fmtNum(derived.get(profileId, 'creatureKillCount')), TEXT),
            metricSpec('Undead', fmtNum(derived.get(profileId, 'undeadKillCount')), ROSE),
            metricSpec('Daedra', fmtNum(derived.get(profileId, 'daedraKillCount')), ROSE),
            metricSpec('Gods', fmtNum(derived.get(profileId, 'godsKilled')), ROSE),
            metricSpec('Regicides', fmtNum(derived.get(profileId, 'regicides')), ROSE),
            metricSpec('Hits Landed', fmtNum(derived.get(profileId, 'hitCount')), MINT),
            metricSpec('Swings', fmtNum(derived.get(profileId, 'swingCount')), TEXT),
            metricSpec('Misses', fmtNum(derived.get(profileId, 'missCount')), TEXT),
            metricSpec('Accuracy', fmtPercent(combatAccuracy(profileId)), MINT),
            metricSpec('Damage Taken', fmtNum(derived.get(profileId, 'damageTaken')), ROSE),
            metricSpec('Combat Damage', fmtNum(derived.get(profileId, 'combatDamageTaken')), ROSE),
            metricSpec('Sneak Attacks', fmtNum(derived.get(profileId, 'sneakAttackCount')), MINT),
            metricSpec('Headshots', fmtNum(derived.get(profileId, 'headshotCount')), SKY),
            metricSpec('Knockdowns', fmtNum(derived.get(profileId, 'knockdownCount')), TEXT),
            metricSpec('Witches', fmtNum(derived.get(profileId, 'witchesHunted')), ROSE),
            metricSpec('Necromancers', fmtNum(derived.get(profileId, 'necromancersSlain')), ROSE),
            metricSpec('Warlocks', fmtNum(derived.get(profileId, 'warlocksSlain')), ROSE),
            metricSpec('Worshippers', fmtNum(derived.get(profileId, 'worshippersSlain')), ROSE),
            metricSpec('Weapons Used', fmtNum(countSerializedEntries(profileId, 'weaponTallyStr')), TEXT),
        },
    }

    local needsInteractGroup = {
        title = 'Needs & Interaction',
        items = {
            metricSpec('Meals Cooked', fmtNum(derived.get(profileId, 'sdCookCount')), MINT),
            metricSpec('Meals Eaten', fmtNum(derived.get(profileId, 'sdMealCount')), MINT),
            metricSpec('Drinks', fmtNum(derived.get(profileId, 'sdDrinkCount')), AMBER),
            metricSpec('Baths', fmtNum(derived.get(profileId, 'sdBathCount')), SKY),
            metricSpec('Days Slept / Waited', fmtNum(derived.get(profileId, 'sleepHours')), TEXT),
            metricSpec('Times Travelled', fmtNum(derived.get(profileId, 'travelCount')), TEXT),
            metricSpec('Interventions', fmtNum(derived.get(profileId, 'interventionCount')), AMBER),
            metricSpec('Recalls', fmtNum(derived.get(profileId, 'recallCount')), SKY),
            metricSpec('People Met', fmtNum(derived.get(profileId, 'peopleMet')), MINT),
            metricSpec('Slaves Freed', fmtNum(derived.get(profileId, 'slavesFreed')), MINT),
            metricSpec('Training Sessions', fmtNum(derived.get(profileId, 'trainCount')), TEXT),
            metricSpec('Repairs', fmtNum(derived.get(profileId, 'repairCount')), AMBER),
            metricSpec('Ingredients Eaten', fmtNum(derived.get(profileId, 'ingredientsEaten')), MINT),
            metricSpec('Locks Opened', fmtNum(derived.get(profileId, 'unlockCount')), TEXT),
            metricSpec('Disarms', fmtNum(derived.get(profileId, 'disarmCount')), TEXT),
            metricSpec('Traps Disarmed', fmtNum(derived.get(profileId, 'trapCount')), TEXT),
        },
    }

    local journeyMagicGroup = {
        title = 'Journey & Magic',
        items = {
            metricSpec('Distance', fmtWorldDistance(derived.totalDistance(profileId)), SKY),
            metricSpec('Distance on Foot', fmtWorldDistance(derived.get(profileId, 'distOnFoot')), TEXT),
            metricSpec('Distance Swam', fmtWorldDistance(derived.get(profileId, 'distSwum')), SKY),
            metricSpec('Distance Levitated', fmtWorldDistance(derived.get(profileId, 'distLevitated')), SKY),
            metricSpec('Distance Mounted', fmtWorldDistance(derived.get(profileId, 'distMounted')), AMBER),
            metricSpec('Distance Jumped', fmtWorldDistance(derived.get(profileId, 'distJumped')), MINT),
            metricSpec('Fastest Speed', fmtWorldDistance(derived.get(profileId, 'fastestSpeed')) .. '/s', MINT),
            metricSpec('Highest Point', fmtWorldDistance(derived.get(profileId, 'highestPoint')), SKY),
            metricSpec('Deepest Dive', fmtWorldDistance(derived.get(profileId, 'deepestDive')), SKY),
            metricSpec('Longest Fall', fmtWorldDistance(derived.get(profileId, 'longestFallSurvived')), ROSE),
            metricSpec('Furthest from Seyda Neen', fmtWorldDistance(derived.get(profileId, 'furthestFromStart')), SKY),
            metricSpec('Potions Consumed', fmtNum(derived.get(profileId, 'potionCount')), AMBER),
            metricSpec('Potions Crafted', fmtNum(derived.get(profileId, 'alchemyCount')), MINT),
            metricSpec('Spells Made', fmtNum(derived.get(profileId, 'spellsMade')), SKY),
            metricSpec('Items Enchanted', fmtNum(derived.get(profileId, 'itemsEnchanted')), SKY),
            metricSpec('Souls Trapped', fmtNum(derived.get(profileId, 'trapCount')), SKY),
            metricSpec('Black Souls', fmtNum(derived.get(profileId, 'blackSoulsTrapped')), SKY),
            metricSpec('Effects', fmtNum(derived.get(profileId, 'spellEffectsLearned')), SKY),
            metricSpec('Diseased Cured', fmtNum(derived.get(profileId, 'cmcDiseasedCreaturesCured')), MINT),
            metricSpec('Blighted Cured', fmtNum(derived.get(profileId, 'cmcBlightedCreaturesCured')), MINT),
            metricSpec('Diseases Spread', fmtNum(derived.get(profileId, 'cmcDiseasesSpread')), ROSE),
            metricSpec('Blights Spread', fmtNum(derived.get(profileId, 'cmcBlightsSpread')), ROSE),
            metricSpec('Spells Cast', fmtNum(countSerializedEntries(profileId, 'spellTallyStr')), SKY),
        },
    }

    local miscGroup = {
        title = 'Misc',
        items = {
            metricSpec('Scribs Petted', fmtNum(derived.get(profileId, 'scribCount')), VALUE),
            metricSpec('Quickloads', fmtNum(derived.get(profileId, 'quickloadCount')), VALUE),
            metricSpec('Worlds Doomed', fmtNum(derived.get(profileId, 'worldsDoomed')), VALUE),
            metricSpec('Skooma', fmtNum(derived.get(profileId, 'skoomaCount')), VALUE),
            metricSpec("Called n'wah", fmtNum(derived.get(profileId, 'nwahCount')), VALUE),
            metricSpec("Called S'wit", fmtNum(derived.get(profileId, 'switCount')), VALUE),
            metricSpec('Called Fetcher', fmtNum(derived.get(profileId, 'fetcherCount')), VALUE),
            metricSpec('Called Scum', fmtNum(derived.get(profileId, 'scumCount')), VALUE),
        },
    }

    local mountGroup = {
        title = 'Mount Ledger',
        items = {
            metricSpec('Horse', fmtWorldDistance(derived.get(profileId, 'distMount_horse')), AMBER),
            metricSpec('Guar', fmtWorldDistance(derived.get(profileId, 'distMount_guar')), AMBER),
            metricSpec('Donkey', fmtWorldDistance(derived.get(profileId, 'distMount_donkey')), AMBER),
            metricSpec('Strident', fmtWorldDistance(derived.get(profileId, 'distMount_strident')), AMBER),
            metricSpec('Skylamp', fmtWorldDistance(derived.get(profileId, 'distMount_skylamp')), AMBER),
            metricSpec('Skyrender', fmtWorldDistance(derived.get(profileId, 'distMount_skyrender')), AMBER),
            metricSpec('Nix', fmtWorldDistance(derived.get(profileId, 'distMount_nix')), AMBER),
            metricSpec('Cliff Racer', fmtWorldDistance(derived.get(profileId, 'distMount_cliffracer')), AMBER),
            metricSpec('Boar', fmtWorldDistance(derived.get(profileId, 'distMount_boar')), AMBER),
        },
    }

    local totalsPanel = groupedMetricPanel('Totals', util.vector2(metrics.middleW, metrics.bodyH), {statsGroup, crimeGroup, combatGroup}, SKY, 3, 18, 13, 14, 1, 0.36)
    local journeyPanel = groupedMetricPanel('Journey & Tempo', util.vector2(metrics.rightW, metrics.rightTopH), {needsInteractGroup, journeyMagicGroup}, MINT, 2, 17, 13, 14, 1, 0.36)
    local afflictionPanel = nil
    if metrics.hasOppAfflictionLedger and metrics.rightAfflictionH and metrics.rightAfflictionH > 0 then
        afflictionPanel = afflictionLedgerPanel(util.vector2(metrics.rightW, metrics.rightAfflictionH))
    end
    local curiosPanel = groupedMetricPanel('Curios & Misc Stats', util.vector2(metrics.rightW, metrics.rightBottomH), {miscGroup, mountGroup}, AMBER, 2, 17, 13, 14, 1, 0.36)
    return totalsPanel, journeyPanel, curiosPanel, afflictionPanel
end

local function ensureGameplayPausedForSummary()
    if not I or not I.UI or not I.UI.setMode then return end
    local currentMode = safeCall(function() return I.UI.getMode() end, nil)
    if currentMode == nil then
        summaryModeOwned = true
        local mode = safeCall(function() return I.UI.MODE.Interface end, 'Interface') or 'Interface'
        I.UI.setMode(mode, { windows = {} })
    else
        summaryModeOwned = false
    end
end

local function releaseSummaryMode()
    if not summaryModeOwned or not I or not I.UI or not I.UI.setMode then
        summaryModeOwned = false
        return
    end
    summaryModeOwned = false
    I.UI.setMode()
end

local function buildHudButton()
    return nil
end

local function ensureHudButton()
    if summaryButton then
        summaryButton:destroy()
        summaryButton = nil
    end
end



local function refreshSummaryContent()
    if not summaryElement or not currentState then return end
    local metrics = getScreenMetrics(summaryWindowSize)
    summaryElement.layout.props.size = metrics.window
    summaryElement.layout.props.position = metrics.position
    summaryElement.layout.content = module.buildContent(currentState, metrics)
    summaryElement:update()
    summaryResizeRefreshPending = false
    summaryLastContentRefreshTime = getRealTime()
end

local function refreshSummaryContentThrottled(force)
    if force then
        refreshSummaryContent()
        return
    end

    if not summaryElement or not currentState then return end
    local now = getRealTime()
    if now - summaryLastContentRefreshTime >= RESIZE_REFRESH_INTERVAL then
        refreshSummaryContent()
    else
        summaryResizeRefreshPending = true
    end
end

local function refreshSummaryPositionOnly()
    if not summaryElement then return end
    local metrics = getScreenMetrics(summaryWindowSize)
    summaryElement.layout.props.size = metrics.window
    summaryElement.layout.props.position = metrics.position
    summaryElement:update()
end

local function scrollSummary(delta)
    if not summaryElement then return end
    local metrics = getScreenMetrics(summaryWindowSize)
    local oldScrollY = summaryScrollY or 0
    if metrics.maxScroll <= 0 then
        summaryScrollY = 0
    else
        summaryScrollY = clamp(oldScrollY + delta, -metrics.maxScroll, 0)
    end
    if summaryScrollY ~= oldScrollY then
        refreshSummaryContentThrottled(false)
    end
end

local function setScrollFromTrack(offsetY, metrics)
    if metrics.maxScroll <= 0 then return end
    local trackH = math.max(1, metrics.viewport.y - metrics.scrollButtonH * 2)
    local handleH = clamp(math.floor(trackH * metrics.viewport.y / metrics.scrollContent.y), 18, trackH)
    local travel = math.max(1, trackH - handleH)
    local y = clamp(offsetY - metrics.scrollButtonH - math.floor(handleH / 2), 0, travel)
    local progress = y / travel
    local oldScrollY = summaryScrollY or 0
    summaryScrollY = -metrics.maxScroll * progress
    if summaryScrollY ~= oldScrollY then
        refreshSummaryContentThrottled(false)
    end
end

local function makeScrollButton(label, onClick)
    return {
        type = ui.TYPE.Widget,
        props = { size = util.vector2(scaled(SCROLLBAR_W), scaled(SCROLLBAR_BUTTON_H)) },
        events = { mousePress = async:callback(function(e)
            if e.button ~= 1 then return end
            onClick()
        end) },
        content = ui.content {
            {
                template = MWUI.templates.boxSolid,
                props = { alpha = 0.80 },
                content = ui.content {
                    makeText(label, {
                        size = 12,
                        color = VALUE,
                        autoSize = false,
                        boxSize = util.vector2(scaled(SCROLLBAR_W), SCROLLBAR_BUTTON_H),
                        alignH = ui.ALIGNMENT.Center,
                        alignV = ui.ALIGNMENT.Center,
                    }),
                },
            },
        },
    }
end

local function buildScrollBar(metrics)
    if not metrics.canScroll then
        return spacer(metrics.viewport.y, metrics.scrollbarW)
    end
    local trackH = math.max(1, metrics.viewport.y - metrics.scrollButtonH * 2)
    local handleH = clamp(math.floor(trackH * metrics.viewport.y / metrics.scrollContent.y), 18, trackH)
    local travel = math.max(1, trackH - handleH)
    local progress = metrics.maxScroll > 0 and (-summaryScrollY / metrics.maxScroll) or 0
    local handleY = math.floor(progress * travel)
    local track = {
        type = ui.TYPE.Widget,
        props = { size = util.vector2(metrics.scrollbarW, trackH) },
        events = {
            mousePress = async:callback(function(e)
                if e.button == 1 then setScrollFromTrack(e.offset.y + metrics.scrollButtonH, metrics) end
            end),
            mouseMove = async:callback(function(e)
                if e.button == 1 then setScrollFromTrack(e.offset.y + metrics.scrollButtonH, metrics) end
            end),
        },
        content = ui.content {
            solidFill(0.35, BLACK),
            {
                type = ui.TYPE.Image,
                props = {
                    resource = WHITE_TEX,
                    position = util.vector2(2, handleY),
                    size = util.vector2(metrics.scrollbarW - 4, handleH),
                    color = PALE_GOLD,
                    alpha = 0.85,
                },
            },
        },
    }
    return vstack({
        makeScrollButton('^', function() scrollSummary(scaled(SCROLL_STEP)) end),
        track,
        makeScrollButton('v', function() scrollSummary(-scaled(SCROLL_STEP)) end),
    }, util.vector2(metrics.scrollbarW, metrics.viewport.y))
end

local function dragHandle(name, position, relativePosition, size, pointer)
    return {
        type = ui.TYPE.Widget,
        props = {
            position = position,
            relativePosition = relativePosition,
            size = size,
            pointer = pointer or 'arrow',
        },
        events = {
            focusGain = async:callback(function() hoveredDragType = name end),
            focusLoss = async:callback(function()
                if hoveredDragType == name then hoveredDragType = nil end
            end),
        },
    }
end

local function buildResizeHandles(metrics)
    local w = metrics.window.x
    local h = metrics.window.y
    local e = RESIZE_EDGE
    return {
        dragHandle('left', util.vector2(0, e), util.vector2(0, 0), util.vector2(e, h - e * 2), 'hresize'),
        dragHandle('right', util.vector2(-e, e), util.vector2(1, 0), util.vector2(e, h - e * 2), 'hresize'),
        dragHandle('top', util.vector2(e, 0), util.vector2(0, 0), util.vector2(w - e * 2, e), 'vresize'),
        dragHandle('bottom', util.vector2(e, -e), util.vector2(0, 1), util.vector2(w - e * 2, e), 'vresize'),
        dragHandle('topLeft', util.vector2(0, 0), util.vector2(0, 0), util.vector2(e, e), 'dresize'),
        dragHandle('topRight', util.vector2(-e, 0), util.vector2(1, 0), util.vector2(e, e), 'dresize2'),
        dragHandle('bottomLeft', util.vector2(0, -e), util.vector2(0, 1), util.vector2(e, e), 'dresize2'),
        dragHandle('bottomRight', util.vector2(-e, -e), util.vector2(1, 1), util.vector2(e, e), 'dresize'),
    }
end

local function applySummaryDrag(layout, dragType, delta)
    local screen = getLayerSize()
    local startSize = layout.userData.dragStartSize
    local startPos = layout.userData.dragStartPos
    local newSize = startSize
    local newPos = startPos

    if dragType == 'left' or dragType == 'topLeft' or dragType == 'bottomLeft' then
        local rightEdge = startPos.x + startSize.x
        local maxW = math.min(MAX_WINDOW_W, rightEdge)
        local dX = clamp(delta.x, startSize.x - maxW, startSize.x - MIN_WINDOW_W)
        newSize = util.vector2(startSize.x - dX, newSize.y)
        newPos = util.vector2(startPos.x + dX, newPos.y)
    elseif dragType == 'right' or dragType == 'topRight' or dragType == 'bottomRight' then
        local maxW = math.min(MAX_WINDOW_W, screen.x - startPos.x)
        newSize = util.vector2(clamp(startSize.x + delta.x, MIN_WINDOW_W, maxW), newSize.y)
    end

    if dragType == 'top' or dragType == 'topLeft' or dragType == 'topRight' then
        local bottomEdge = startPos.y + startSize.y
        local maxH = math.min(MAX_WINDOW_H, bottomEdge)
        local dY = clamp(delta.y, startSize.y - maxH, startSize.y - MIN_WINDOW_H)
        newSize = util.vector2(newSize.x, startSize.y - dY)
        newPos = util.vector2(newPos.x, startPos.y + dY)
    elseif dragType == 'bottom' or dragType == 'bottomLeft' or dragType == 'bottomRight' then
        local maxH = math.min(MAX_WINDOW_H, screen.y - startPos.y)
        newSize = util.vector2(newSize.x, clamp(startSize.y + delta.y, MIN_WINDOW_H, maxH))
    elseif dragType == 'move' then
        newPos = clampWindowPosition(startPos + delta, newSize)
    end

    summaryWindowSize = newSize
    summaryWindowPosition = clampWindowPosition(newPos, newSize)

    if dragType == 'move' then
        refreshSummaryPositionOnly()
    else
        refreshSummaryContentThrottled(false)
    end
end

function module.buildContent(state, metrics)
    summaryLayoutScale = metrics.scale or 1.0
    local heroBanner = buildHeroBanner(state, metrics)
    local profilePanel = buildProfilePanel(state, metrics)
    local totalsPanel, journeyPanel, curiosPanel, afflictionPanel = buildPanels(state, metrics)

    local headerTitle = {
        type = ui.TYPE.Widget,
        props = {
            size = util.vector2(metrics.headerW - scaled(CLOSE_W) - metrics.panelGap, metrics.headerH),
            pointer = 'arrow',
        },
        events = {
            focusGain = async:callback(function() hoveredDragType = 'move' end),
            focusLoss = async:callback(function()
                if hoveredDragType == 'move' then hoveredDragType = nil end
            end),
        },
        content = ui.content {
            vstack({
                makeText('Character Summary', { size = 30, color = GOLD }),
            }, util.vector2(metrics.headerW - scaled(CLOSE_W) - metrics.panelGap, metrics.headerH), ui.ALIGNMENT.Center),
        },
    }

    local header = hstack({
        headerTitle,
        spacer(1, metrics.panelGap),
        framedButton('[Close]', scaled(CLOSE_W), function() module.hide() end),
    }, util.vector2(metrics.headerW, metrics.headerH), ui.ALIGNMENT.Center)

    local body
    if metrics.stacked then
        body = vstack({
            profilePanel,
            spacer(metrics.panelGap),
            totalsPanel,
            spacer(metrics.panelGap),
            journeyPanel,
            spacer(metrics.panelGap),
            afflictionPanel or spacer(0),
            afflictionPanel and spacer(metrics.panelGap) or spacer(0),
            curiosPanel,
        }, util.vector2(metrics.inner.x, metrics.profileH + metrics.bodyH + metrics.rightTopH + metrics.rightAfflictionH + metrics.rightBottomH + metrics.panelGap * (afflictionPanel and 5 or 3)))
    else
        local rightColumnRows = {
            journeyPanel,
            spacer(metrics.panelGap),
        }
        if afflictionPanel then
            rightColumnRows[#rightColumnRows + 1] = afflictionPanel
            rightColumnRows[#rightColumnRows + 1] = spacer(metrics.panelGap)
        end
        rightColumnRows[#rightColumnRows + 1] = curiosPanel
        local rightColumn = vstack(rightColumnRows, util.vector2(metrics.rightW, metrics.bodyH))

        body = hstack({
            profilePanel,
            spacer(1, math.max(2, math.floor((metrics.panelGap - 1) / 2))),
            ruleLine(1, metrics.bodyH, PALE_GOLD, 0.18),
            spacer(1, math.max(2, math.ceil((metrics.panelGap - 1) / 2))),
            totalsPanel,
            spacer(1, math.max(2, math.floor((metrics.panelGap - 1) / 2))),
            ruleLine(1, metrics.bodyH, PALE_GOLD, 0.18),
            spacer(1, math.max(2, math.ceil((metrics.panelGap - 1) / 2))),
            rightColumn,
        }, util.vector2(metrics.inner.x, metrics.bodyH))
    end

    local scrollContent = vstack({
        heroBanner,
        spacer(metrics.panelGap),
        body,
    }, metrics.scrollContent)

    local scrollViewport = {
        type = ui.TYPE.Widget,
        props = { size = metrics.viewport },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                props = {
                    autoSize = false,
                    size = metrics.scrollContent,
                    position = util.vector2(0, summaryScrollY or 0),
                },
                content = ui.content { scrollContent },
            },
            {
                type = ui.TYPE.Widget,
                props = {
                    position = util.vector2(-metrics.scrollbarW, 0),
                    relativePosition = util.vector2(1, 0),
                    size = util.vector2(metrics.scrollbarW, metrics.viewport.y),
                    visible = metrics.canScroll,
                },
                content = ui.content { buildScrollBar(metrics) },
            },
        },
    }

    local outerFrame = {
        template = MWUI.templates.boxSolidThick,
        content = ui.content {
            solidFill(0.22, BRONZE),
            {
                template = MWUI.templates.padding,
                props = { padding = OUTER_PAD },
                content = ui.content {
                    vstack({
                        header,
                        spacer(metrics.panelGap),
                        scrollViewport,
                    }, util.vector2(metrics.headerW, metrics.window.y - OUTER_PAD * 2)),
                },
            },
        },
    }

    local content = ui.content { outerFrame }
    for _, handle in ipairs(buildResizeHandles(metrics)) do
        content:add(handle)
    end
    return content
end

function module.buildLayout(state)
    local metrics = getScreenMetrics(getWindowSize())
    return {
        layer = 'Windows',
        type = ui.TYPE.Widget,
        props = {
            position = metrics.position,
            size = metrics.window,
        },
        content = module.buildContent(state, metrics),
        events = {
            mousePress = async:callback(function(e, layout)
                if e.button ~= 1 then return end
                local dragType = hoveredDragType
                if dragType == nil then return end
                layout.userData.dragging = true
                layout.userData.dragType = dragType
                layout.userData.dragStartAbs = e.position
                layout.userData.dragStartSize = layout.props.size
                layout.userData.dragStartPos = layout.props.position
                summaryIsDragging = true
                summaryResizeRefreshPending = false
                summaryLastContentRefreshTime = -math.huge
            end),
            mouseMove = async:callback(function(e, layout)
                if not layout.userData.dragging then return end
                if not layout.userData.dragStartAbs or not layout.userData.dragStartSize or not layout.userData.dragStartPos then return end
                applySummaryDrag(layout, layout.userData.dragType, e.position - layout.userData.dragStartAbs)
            end),
            mouseRelease = async:callback(function(e, layout)
                if e.button ~= 1 then return end
                local dragType = layout.userData.dragType
                layout.userData.dragging = false
                layout.userData.dragType = nil
                layout.userData.dragStartAbs = nil
                layout.userData.dragStartSize = nil
                layout.userData.dragStartPos = nil
                summaryIsDragging = false
                if dragType and dragType ~= 'move' then
                    refreshSummaryContentThrottled(true)
                end
            end),
        },
        userData = {
            dragging = false,
        },
    }
end

local function rebuildSummary()
    if not summaryElement or not currentState then return end
    refreshSummaryContent()
end

function module.show(state)
    if not isSummaryEnabled() then
        log('[SC] Summary hotkey pressed but summary page is disabled in settings')
        return
    end
    if not state or not state.profileId then
        log('[SC] Summary hotkey pressed but no summary state/profile is available yet')
        return
    end
    currentState = state
    ensureGameplayPausedForSummary()
    log('[SC] Opening career summary window')
    if summaryElement then summaryElement:destroy() summaryElement = nil end
    summaryElement = ui.create(module.buildLayout(state))
    summaryResizeRefreshPending = false
    summaryLastContentRefreshTime = getRealTime()
    summaryIsDragging = false
    if summaryButton then summaryButton:destroy() summaryButton = nil end
end

function module.hide()
    if summaryElement then
        summaryElement:destroy()
        summaryElement = nil
        summaryResizeRefreshPending = false
        summaryIsDragging = false
        log('[SC] Closed career summary window')
    end
    releaseSummaryMode()
    ensureHudButton()
end

function module.toggle(state)
    local activeState = state or currentState
    if not activeState or not activeState.profileId then
        log('[SC] Summary toggle ignored because state is not ready')
        return
    end
    local now = getRealTime()
    if now - lastTriggerTime < TRIGGER_COOLDOWN then
        log('[SC] Summary trigger ignored due to cooldown')
        return
    end
    lastTriggerTime = now
    if summaryElement then
        module.hide()
        return
    end
    module.show(activeState)
end

function module.onMouseWheel(vertical, horizontal)
    if not summaryElement then return end
    local metrics = getScreenMetrics(summaryWindowSize)
    if metrics.maxScroll <= 0 then return end
    scrollSummary((vertical or 0) * scaled(SCROLL_STEP))
end

function module.setState(state)
    currentState = state or currentState
    ensureHudButton()
end

function module.attachState(state)
    module.setState(state)
end

function module.update(state, deltaTime)
    currentState = state or currentState
    if summaryElement and not isSummaryEnabled() then
        module.hide()
        return
    end
    ensureHudButton()
    if not summaryElement or not currentState then return end

    if summaryResizeRefreshPending then
        local now = getRealTime()
        if not summaryIsDragging or now - summaryLastContentRefreshTime >= RESIZE_REFRESH_INTERVAL then
            refreshSummaryContentThrottled(true)
        end
    end

    if summaryIsDragging then return end

    updateAccumulator = updateAccumulator + (deltaTime or 0)
    if updateAccumulator < 1.0 then return end
    updateAccumulator = 0
    rebuildSummary()
end

function module.onUpdate(deltaTime)
    module.update(currentState, deltaTime)
end

function module.registerTrigger()
    if triggerRegistered then return end
    triggerRegistered = true
    input.registerTrigger {
        key = 'SC_ToggleSummaryPage',
        l10n = mDef.MOD_NAME,
        name = 'toggleSummaryPage_name',
        description = 'toggleSummaryPage_desc',
    }
    input.registerTriggerHandler('SC_ToggleSummaryPage', async:callback(function()
        log('[SC] Summary trigger activated')
        module.toggle(currentState)
    end))
    log('[SC] Summary trigger registered')
end

function module.init(state)
    currentState = state or currentState
    module.registerTrigger()
    ensureHudButton()
end

return module
