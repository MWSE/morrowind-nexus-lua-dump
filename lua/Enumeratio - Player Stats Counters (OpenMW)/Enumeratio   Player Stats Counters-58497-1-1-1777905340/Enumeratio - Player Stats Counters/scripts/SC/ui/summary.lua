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

local MAX_WINDOW_W = 1340
local MAX_WINDOW_H = 790
local MIN_WINDOW_W = 1040
local MIN_WINDOW_H = 650
local OUTER_MARGIN = 18
local OUTER_PAD = 10
local PANEL_PAD = 8
local PANEL_GAP = 7
local HEADER_H = 34
local CLOSE_W = 84
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
    if #text <= maxLen then return text end
    if maxLen <= 1 then return text:sub(1, maxLen) end
    return text:sub(1, maxLen - 1) .. '…'
end

local function makeText(text, opts)
    opts = opts or {}
    return {
        type = ui.TYPE.Text,
        props = {
            text = text or '',
            textSize = opts.size or 14,
            textColor = opts.color or TEXT,
            autoSize = opts.autoSize ~= false,
            size = opts.boxSize,
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
        props = { size = util.vector2(width, 30) },
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
    rowHeight = rowHeight or ROW_H
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
                        alignV = ui.ALIGNMENT.Center,
                    }),
                    spacer(1, 6),
                    makeText(value, {
                        size = valueSize,
                        color = displayTone,
                        autoSize = false,
                        boxSize = util.vector2(valueWidth, rowHeight),
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
    local rowHeight = compact and COMPACT_ROW_H or ROW_H
    local labelSize = compact and METRIC_LABEL_SIZE or METRIC_LABEL_SIZE
    local valueSize = compact and METRIC_VALUE_SIZE_COMPACT or METRIC_VALUE_SIZE
    local inline = true
    return hstack({
        metricCell(aLabel, aValue, cellWidth, aTone, rowHeight, labelSize, valueSize, inline, valueFraction),
        spacer(1, gap),
        metricCell(bLabel or '', bValue or '', cellWidth, bTone, rowHeight, labelSize, valueSize, inline, valueFraction),
    }, util.vector2(innerWidth, rowHeight), ui.ALIGNMENT.Center)
end

local function pairRowDivider(innerWidth, aLabel, aValue, bLabel, bValue, aTone, bTone, compact, valueFraction)
    local gap = compact and 8 or 10
    local dividerW = 2
    local sideGap = math.max(2, math.floor((gap - dividerW) / 2))
    local cellWidth = math.floor((innerWidth - sideGap * 2 - dividerW) / 2)
    local rowHeight = compact and COMPACT_ROW_H or ROW_H
    local labelSize = compact and METRIC_LABEL_SIZE or METRIC_LABEL_SIZE
    local valueSize = compact and METRIC_VALUE_SIZE_COMPACT or METRIC_VALUE_SIZE
    local inline = true
    return hstack({
        metricCell(aLabel, aValue, cellWidth, aTone, rowHeight, labelSize, valueSize, inline, valueFraction),
        spacer(1, sideGap),
        ruleLine(dividerW, rowHeight, PALE_GOLD, 0.34),
        spacer(1, sideGap),
        metricCell(bLabel or '', bValue or '', cellWidth, bTone, rowHeight, labelSize, valueSize, inline, valueFraction),
    }, util.vector2(innerWidth, rowHeight), ui.ALIGNMENT.Center)
end
local function bannerInlineMetric(label, value, width, valueColor)
    local parts = {}
    if label and label ~= '' then
        parts[#parts + 1] = makeText(label, { size = 13, color = PALE_GOLD })
    end
    if value and value ~= '' then
        if #parts > 0 then parts[#parts + 1] = spacer(1, 8) end
        parts[#parts + 1] = makeText(value, { size = 14, color = valueColor or VALUE })
    end
    return {
        type = ui.TYPE.Widget,
        props = { size = util.vector2(width, 20) },
        content = ui.content {
            hstack(parts, util.vector2(width, 20), ui.ALIGNMENT.Center),
        },
    }
end

local function bannerPairRow(width, leftLabel, leftValue, rightLabel, rightValue)
    local gap = 18
    local cellWidth = math.floor((width - gap) / 2)
    return hstack({
        bannerInlineMetric(leftLabel, leftValue, cellWidth),
        spacer(1, gap),
        bannerInlineMetric(rightLabel, rightValue, cellWidth),
    }, util.vector2(width, 20), ui.ALIGNMENT.Center)
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
    for i, item in ipairs(items) do
        rows[#rows + 1] = metricCell(item.label or '', item.value or '', width, item.tone, rowHeight, labelSize, valueSize, true)
        if i < #items then
            rows[#rows + 1] = spacer(gap or 1)
        end
    end
    local totalHeight = (#items * rowHeight) + (math.max(0, #items - 1) * (gap or 1))
    return vstack(rows, util.vector2(width, totalHeight))
end


local function sectionHeaderCell(text, width)
    return {
        type = ui.TYPE.Widget,
        props = { size = util.vector2(width, 22) },
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
    local innerWidth = size.x - PANEL_PAD * 2
    local colGap = PANEL_GAP
    local colWidth = math.floor((innerWidth - colGap * (colCount - 1)) / colCount)
    local cols = {}
    for i, group in ipairs(groups) do
        local colRows = { sectionHeaderCell(group.title, colWidth), spacer(2) }
        for j, item in ipairs(group.items) do
            colRows[#colRows + 1] = metricCell(item.label or '', item.value or '', colWidth, item.tone, rowHeight, labelSize, valueSize, true, valueFraction)
            if j < #group.items then
                colRows[#colRows + 1] = spacer(gap)
            end
        end
        cols[#cols + 1] = vstack(colRows, util.vector2(colWidth, size.y - PANEL_PAD * 2 - 24))
        if i < #groups then
            cols[#cols + 1] = spacer(1, math.max(2, math.floor((colGap - 1) / 2)))
            cols[#cols + 1] = ruleLine(2, size.y - PANEL_PAD * 2 - 24, PALE_GOLD, 0.34)
            cols[#cols + 1] = spacer(1, math.max(2, math.ceil((colGap - 1) / 2)))
        end
    end
    local rows = { makeText(title, { size = PANEL_TITLE_SIZE, color = accent or GOLD }), spacer(4), hstack(cols, util.vector2(innerWidth, size.y - PANEL_PAD * 2 - 24)) }
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
        if type(rankValue) ~= 'number' then return '—' end

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

        return '—'
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

    local primaryName, primaryRank = 'None', '—'
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


local function getScreenMetrics()
    local screen = ui.screenSize()
    local windowW = clamp(math.floor(screen.x - OUTER_MARGIN * 2), MIN_WINDOW_W, MAX_WINDOW_W)
    local windowH = clamp(math.floor(screen.y - OUTER_MARGIN * 2), MIN_WINDOW_H, MAX_WINDOW_H)
    local innerW = windowW - OUTER_PAD * 2
    local innerH = windowH - OUTER_PAD * 2
    local heroH = 108
    local bodyH = innerH - HEADER_H - PANEL_GAP - heroH - PANEL_GAP
    local leftW = math.floor(innerW * 0.35)
    local middleW = math.floor(innerW * 0.35)
    local rightW = innerW - leftW - middleW - PANEL_GAP * 2
    local rightTopH = math.floor((bodyH - PANEL_GAP) * 0.57)
    local rightBottomH = bodyH - rightTopH - PANEL_GAP
    return {
        screen = screen,
        window = util.vector2(windowW, windowH),
        inner = util.vector2(innerW, innerH),
        heroH = heroH,
        bodyH = bodyH,
        leftW = leftW,
        middleW = middleW,
        rightW = rightW,
        rightTopH = rightTopH,
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
    local bannerH = metrics.heroH - PANEL_PAD * 2 - 6

    local bestSkill = getSkillExtremes()
    local topWeapon, topWeaponCount = getTopWeaponLine(state)
    local topSpell, topSpellCount = getTopSpellLine(state)

    local nameW = 340
    local centerW = 360
    local statsW = 220
    local dividerGap = 12
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
            spacer(2),
            makeText(raceName .. ' - ' .. className, {
                size = HERO_META_SIZE,
                color = TEXT,
                alignH = ui.ALIGNMENT.Center,
                autoSize = false,
                boxSize = util.vector2(nameW, 22),
            }),
            spacer(4),
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
            spacer(8),
            bannerInlineMetric('Fav. Spell', clipText(string.format('%s (%s)', topSpell, fmtNum(topSpellCount)), 30), centerW),
        }, util.vector2(centerW, bannerH), ui.ALIGNMENT.Center),
        spacer(1, dividerGap),
        ruleLine(2, bannerH, PALE_GOLD, 0.40),
        spacer(1, dividerGap),
        vstack({
            bannerPairRow(statsW, 'Level', fmtNum(getLevel()), 'Reputation', fmtNum(getReputation())),
            spacer(8),
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
            leftChildren[#leftChildren + 1] = spacer(2)
            rightChildren[#rightChildren + 1] = spacer(2)
        end
    end

    local visibleFactionEntries = {}
    for _, entry in ipairs(factionEntries or {}) do
        if entry and entry.name and entry.rankText then
            visibleFactionEntries[#visibleFactionEntries + 1] = entry
        end
    end

    local metricRowsPerColumn = math.ceil(#rows / 2)
    local metricColumnHeight = (metricRowsPerColumn * COMPACT_ROW_H) + (math.max(0, metricRowsPerColumn - 1) * 2)

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
        content[#content + 1] = spacer(8)
        content[#content + 1] = ruleLine(innerWidth, 1, PALE_GOLD, 0.22)
        content[#content + 1] = spacer(6)
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
                content[#content + 1] = spacer(2)
            end
        end
    end

    return panel('Build & Standing', util.vector2(metrics.leftW, metrics.bodyH), content, GOLD, 3)
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
    local curiosPanel = groupedMetricPanel('Curios & Misc Stats', util.vector2(metrics.rightW, metrics.rightBottomH), {miscGroup, mountGroup}, AMBER, 2, 17, 13, 14, 1, 0.36)
    return totalsPanel, journeyPanel, curiosPanel
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


function module.buildLayout(state)
    local metrics = getScreenMetrics()
    local heroBanner = buildHeroBanner(state, metrics)
    local profilePanel = buildProfilePanel(state, metrics)
    local totalsPanel, journeyPanel, curiosPanel = buildPanels(state, metrics)

    local header = hstack({
        {
            type = ui.TYPE.Widget,
            props = { size = util.vector2(metrics.inner.x - CLOSE_W - PANEL_GAP, HEADER_H) },
            content = ui.content {
                vstack({
                    makeText('Character Summary', { size = 30, color = GOLD }),
                }, util.vector2(metrics.inner.x - CLOSE_W - PANEL_GAP, HEADER_H), ui.ALIGNMENT.Center),
            },
        },
        spacer(1, PANEL_GAP),
        framedButton('[Close]', CLOSE_W, function() module.hide() end),
    }, util.vector2(metrics.inner.x, HEADER_H), ui.ALIGNMENT.Center)

    local rightColumn = vstack({
        journeyPanel,
        spacer(PANEL_GAP),
        curiosPanel,
    }, util.vector2(metrics.rightW, metrics.bodyH))

    local body = hstack({
        profilePanel,
        spacer(1, math.max(2, math.floor((PANEL_GAP - 1) / 2))),
        ruleLine(1, metrics.bodyH, PALE_GOLD, 0.18),
        spacer(1, math.max(2, math.ceil((PANEL_GAP - 1) / 2))),
        totalsPanel,
        spacer(1, math.max(2, math.floor((PANEL_GAP - 1) / 2))),
        ruleLine(1, metrics.bodyH, PALE_GOLD, 0.18),
        spacer(1, math.max(2, math.ceil((PANEL_GAP - 1) / 2))),
        rightColumn,
    }, util.vector2(metrics.inner.x, metrics.bodyH))

    return {
        layer = 'Windows',
        type = ui.TYPE.Widget,
        props = {
            anchor = util.vector2(0.5, 0.5),
            relativePosition = util.vector2(0.5, 0.462),
            size = metrics.window,
        },
        content = ui.content {
            {
                template = MWUI.templates.boxSolidThick,
                content = ui.content {
                    solidFill(0.22, BRONZE),
                    {
                        template = MWUI.templates.padding,
                        props = { padding = OUTER_PAD },
                        content = ui.content {
                            vstack({
                                header,
                                spacer(PANEL_GAP),
                                heroBanner,
                                spacer(PANEL_GAP),
                                body,
                            }, metrics.inner),
                        },
                    },
                },
            },
        },
    }
end

local function rebuildSummary()
    if not summaryElement or not currentState then return end
    summaryElement:destroy()
    summaryElement = ui.create(module.buildLayout(currentState))
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
    if summaryButton then summaryButton:destroy() summaryButton = nil end
end

function module.hide()
    if summaryElement then
        summaryElement:destroy()
        summaryElement = nil
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
    local now = safeCall(function() return input.getRealTime() end, core.getRealTime()) or core.getRealTime()
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
