local I = require('openmw.interfaces')
local ambient = require('openmw.ambient')
local async = require('openmw.async')
local auxUi = require('openmw_aux.ui')
local core = require('openmw.core')
local ui = require('openmw.ui')
local util = require('openmw.util')
local playerSelf = require('openmw.self')
local types = require('openmw.types')

local Pricing = require('scripts.SpellTrader.spellPricing')
local Templates = require('scripts.SpellTrader.ui.templates')

local v2 = util.vector2
local l10n = core.l10n('SpellTrader')
local Window = {}
Window.__index = Window

local LAYOUT_WINDOW_SIZE = v2(450, 290)
local LAYOUT_CONTENT_SIZE = v2(450, 290)
local LAYOUT_DEFAULT_POSITION = v2(543, 287)
local LAYOUT_PADDING = 0
local LAYOUT_HEADER_HEIGHT = 22
local LAYOUT_SUBTITLE_HEIGHT = 18
local LAYOUT_MIN_PANEL_HEIGHT = 20
local CONFIRMATION_BUTTON_SIZE = v2(140, 48)
local ROW_ICON_SIZE = v2(16, 16)
local ROW_ICON_LEFT_PADDING = 2
local ROW_HEIGHT = ROW_ICON_SIZE.y + 4
local TOOLTIP_CURSOR_OFFSET = 24
local BASE_SORT_FIELDS = { 'name', 'school', 'price', 'unknown' }
local NEW_SPELL_MARK = '* '

local function clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

local function gmstColor(key, fallback)
    local value = core.getGMST(key)
    if type(value) == 'string' then
        local parts = {}
        for part in value:gmatch('[^,]+') do
            parts[#parts + 1] = tonumber(part:match('^%s*(.-)%s*$'))
        end
        if #parts >= 3 and parts[1] and parts[2] and parts[3] then
            local alpha = parts[4] or 255
            return util.color.rgba(
                clamp(parts[1], 0, 255) / 255,
                clamp(parts[2], 0, 255) / 255,
                clamp(parts[3], 0, 255) / 255,
                clamp(alpha, 0, 255) / 255)
        end
    end
    return fallback
end

local MAGNITUDE_DISPLAY = {
    None = 1,
    TimesInt = 2,
    Feet = 3,
    Level = 4,
    Percentage = 5,
    Points = 6,
}

local magnitudeMap = {
    [MAGNITUDE_DISPLAY.TimesInt] = {
        fortifymaximummagicka = true,
    },
    [MAGNITUDE_DISPLAY.Feet] = {
        telekinesis = true,
        detectanimal = true,
        detectenchantment = true,
        detectkey = true,
    },
    [MAGNITUDE_DISPLAY.Level] = {
        commandcreature = true,
        commandhumanoid = true,
    },
    [MAGNITUDE_DISPLAY.Percentage] = {
        chameleon = true,
        blind = true,
        dispel = true,
        reflect = true,
    },
}

local function idText(id)
    return tostring(id)
end

local function gmst(key, fallback)
    return Templates.gmst(key, fallback)
end

local function containsId(list, id)
    local wanted = idText(id)
    for _, entry in pairs(list) do
        if idText(entry) == wanted then
            return true
        end
    end
    return false
end

local function racePowersFor(actor)
    if not types.NPC.objectIsInstance(actor) then
        return nil
    end
    local record = types.NPC.record(actor)
    if not record or not record.race then
        return nil
    end
    local race = types.NPC.races.records[record.race]
    return race and race.spells or nil
end

local function playerHasSpell(spell, extraKnownSpellIds)
    local spellId = idText(spell.id)
    return types.Actor.spells(playerSelf)[spell.id] ~= nil
        or (extraKnownSpellIds and extraKnownSpellIds[spellId] == true)
end

local function effectId(params)
    if params.id ~= nil then
        return idText(params.id)
    end
    if params.effect and params.effect.id ~= nil then
        return idText(params.effect.id)
    end
    return nil
end

local function addSpellEffectIds(effectIds, spell)
    for _, params in pairs(spell.effects) do
        local id = effectId(params)
        if id then
            effectIds[id] = true
        end
    end
end

local function playerKnownSpellEffectIds(extraKnownSpellIds)
    local effectIds = {}
    for _, spell in pairs(types.Actor.spells(playerSelf)) do
        if spell.type == core.magic.SPELL_TYPE.Spell then
            addSpellEffectIds(effectIds, spell)
        end
    end
    for spellId in pairs(extraKnownSpellIds or {}) do
        local spell = core.magic.spells.records[spellId]
        if spell and spell.type == core.magic.SPELL_TYPE.Spell then
            addSpellEffectIds(effectIds, spell)
        end
    end
    return effectIds
end

local function hasEffectUnknownToPlayer(spell, knownEffectIds)
    for _, params in pairs(spell.effects) do
        local id = effectId(params)
        if id and not knownEffectIds[id] then
            return true
        end
    end
    return false
end

local function effectMagnitudeDisplayType(effect)
    if not effect or not effect.hasMagnitude then
        return MAGNITUDE_DISPLAY.None
    end
    if magnitudeMap[MAGNITUDE_DISPLAY.TimesInt][idText(effect.id)] then
        return MAGNITUDE_DISPLAY.TimesInt
    end
    if magnitudeMap[MAGNITUDE_DISPLAY.Feet][idText(effect.id)] then
        return MAGNITUDE_DISPLAY.Feet
    end
    if magnitudeMap[MAGNITUDE_DISPLAY.Level][idText(effect.id)] then
        return MAGNITUDE_DISPLAY.Level
    end
    if magnitudeMap[MAGNITUDE_DISPLAY.Percentage][idText(effect.id)]
        or idText(effect.id):find('^weakness')
        or idText(effect.id):find('^resist') then
        return MAGNITUDE_DISPLAY.Percentage
    end
    return MAGNITUDE_DISPLAY.Points
end

local function targetedEffectName(effect, params)
    local name = effect.name
    local effectType = core.magic.EFFECT_TYPE
    local hasSkill = params.affectedSkill ~= nil
    local hasAttribute = params.affectedAttribute ~= nil
    if hasSkill or hasAttribute then
        if effect.id == effectType.AbsorbAttribute or effect.id == effectType.AbsorbSkill then
            name = gmst('sAbsorb', 'Absorb')
        elseif effect.id == effectType.DamageAttribute or effect.id == effectType.DamageSkill then
            name = gmst('sDamage', 'Damage')
        elseif effect.id == effectType.DrainAttribute or effect.id == effectType.DrainSkill then
            name = gmst('sDrain', 'Drain')
        elseif effect.id == effectType.FortifyAttribute or effect.id == effectType.FortifySkill then
            name = gmst('sFortify', 'Fortify')
        elseif effect.id == effectType.RestoreAttribute or effect.id == effectType.RestoreSkill then
            name = gmst('sRestore', 'Restore')
        end
    end
    if hasSkill and core.stats.Skill.records[params.affectedSkill] then
        name = name .. ' ' .. core.stats.Skill.records[params.affectedSkill].name
    elseif hasAttribute and core.stats.Attribute.records[params.affectedAttribute] then
        name = name .. ' ' .. core.stats.Attribute.records[params.affectedAttribute].name
    end
    return name
end

local function spellEffectText(params)
    local effect = params.effect or core.magic.effects.records[params.id]
    if not effect then
        return ''
    end

    local text = targetedEffectName(effect, params)
    if effect.hasMagnitude and (params.magnitudeMin or params.magnitudeMax) then
        local minMagnitude = params.magnitudeMin or 0
        local maxMagnitude = params.magnitudeMax or minMagnitude
        local displayType = effectMagnitudeDisplayType(effect)
        if displayType == MAGNITUDE_DISPLAY.TimesInt then
            text = text .. ' ' .. tostring(math.floor(minMagnitude) / 10)
            if minMagnitude ~= maxMagnitude then
                text = text .. ' ' .. gmst('sTo', 'to') .. ' ' .. tostring(math.floor(maxMagnitude) / 10)
            end
            text = text .. gmst('sXTimesInt', 'x INT')
        elseif displayType ~= MAGNITUDE_DISPLAY.None then
            text = text .. ' ' .. tostring(minMagnitude)
            if minMagnitude ~= maxMagnitude then
                text = text .. ' ' .. gmst('sTo', 'to') .. ' ' .. tostring(maxMagnitude)
            end
            if displayType == MAGNITUDE_DISPLAY.Percentage then
                text = text .. gmst('spercent', '%')
            elseif displayType == MAGNITUDE_DISPLAY.Feet then
                text = text .. ' ' .. gmst('sfeet', 'ft')
            elseif displayType == MAGNITUDE_DISPLAY.Level then
                text = text .. ' '
                if minMagnitude == maxMagnitude and math.abs(minMagnitude) == 1 then
                    text = text .. gmst('sLevel', 'Level')
                else
                    text = text .. gmst('sLevels', 'Levels')
                end
            else
                text = text .. ' '
                if minMagnitude == maxMagnitude and math.abs(minMagnitude) == 1 then
                    text = text .. gmst('spoint', 'pt')
                else
                    text = text .. gmst('spoints', 'pts')
                end
            end
        end
    end

    local duration = params.duration or 0
    if not effect.isAppliedOnce then
        duration = math.max(1, duration)
    end
    if duration > 0 and effect.hasDuration then
        text = text .. ' ' .. gmst('sfor', 'for') .. ' ' .. tostring(duration) .. ' '
        if duration == 1 then
            text = text .. gmst('ssecond', 'second')
        else
            text = text .. gmst('sseconds', 'seconds')
        end
    end
    if (params.area or 0) > 0 then
        text = text .. ' ' .. gmst('sin', 'in') .. ' ' .. tostring(params.area) .. ' ' .. gmst('sfootarea', 'ft area')
    end
    text = text .. ' ' .. gmst('sonword', 'on') .. ' '
    if params.range == core.magic.RANGE.Self then
        text = text .. gmst('sRangeSelf', 'Self')
    elseif params.range == core.magic.RANGE.Touch then
        text = text .. gmst('sRangeTouch', 'Touch')
    else
        text = text .. gmst('sRangeTarget', 'Target')
    end
    return text
end

local function spellSchoolId(spell)
    if spell.type ~= core.magic.SPELL_TYPE.Spell or spell.alwaysSucceedFlag then
        return nil
    end

    local bestScore
    local bestSchool
    for _, params in ipairs(spell.effects) do
        local effect = params.effect or core.magic.effects.records[params.id]
        if effect and effect.school then
            local duration = effect.hasDuration and (params.duration or 0) or 1
            if not effect.isAppliedOnce then
                duration = math.max(1, duration)
            end

            local minMagnitude = params.magnitudeMin or 0
            local maxMagnitude = params.magnitudeMax or minMagnitude
            local score = duration * 0.1 * effect.baseCost * 0.5 * (minMagnitude + maxMagnitude)
            score = score + (params.area or 0) * 0.05 * effect.baseCost
            if params.range == core.magic.RANGE.Target then
                score = score * 1.5
            end
            score = score * core.getGMST('fEffectCostMult')

            local skillScore = 0
            local skill = playerSelf.type.stats.skills[effect.school]
            if skill then
                skillScore = 2 * skill(playerSelf).modified
            end
            local effectiveScore = skillScore - score
            if not bestScore or effectiveScore < bestScore then
                bestScore = effectiveScore
                bestSchool = effect.school
            end
        end
    end
    return bestSchool
end

local function spellSchoolText(spell)
    local schoolId = spellSchoolId(spell)
    local school = schoolId and core.stats.Skill.records[schoolId]
    if not school then
        return nil
    end
    return gmst('sSchool', 'School') .. ': ' .. school.name
end

local function spellSchoolName(spell)
    local schoolId = spellSchoolId(spell)
    local school = schoolId and core.stats.Skill.records[schoolId]
    return school and school.name or ''
end

local function normalizedName(spell)
    return string.lower(spell.name or '')
end

local function normalizedId(spell)
    return string.lower(idText(spell.id))
end

local cyrillicLowerMap = {
    ['А'] = 'а',
    ['Б'] = 'б',
    ['В'] = 'в',
    ['Г'] = 'г',
    ['Д'] = 'д',
    ['Е'] = 'е',
    ['Ё'] = 'ё',
    ['Ж'] = 'ж',
    ['З'] = 'з',
    ['И'] = 'и',
    ['Й'] = 'й',
    ['К'] = 'к',
    ['Л'] = 'л',
    ['М'] = 'м',
    ['Н'] = 'н',
    ['О'] = 'о',
    ['П'] = 'п',
    ['Р'] = 'р',
    ['С'] = 'с',
    ['Т'] = 'т',
    ['У'] = 'у',
    ['Ф'] = 'ф',
    ['Х'] = 'х',
    ['Ц'] = 'ц',
    ['Ч'] = 'ч',
    ['Ш'] = 'ш',
    ['Щ'] = 'щ',
    ['Ъ'] = 'ъ',
    ['Ы'] = 'ы',
    ['Ь'] = 'ь',
    ['Э'] = 'э',
    ['Ю'] = 'ю',
    ['Я'] = 'я',
    ['Ґ'] = 'ґ',
    ['Є'] = 'є',
    ['І'] = 'і',
    ['Ї'] = 'ї',
}

local function normalizeSearchText(text)
    text = string.lower(tostring(text or ''))
    for upper, lower in pairs(cyrillicLowerMap) do
        text = text:gsub(upper, lower)
    end
    return text
end

local function addSearchPart(parts, value)
    if value ~= nil and value ~= '' then
        parts[#parts + 1] = normalizeSearchText(value)
    end
end

local function rowSearchText(row)
    if row.searchText then
        return row.searchText
    end

    local parts = {}
    local spell = row.spell
    addSearchPart(parts, spell.name)
    addSearchPart(parts, idText(spell.id))
    addSearchPart(parts, row.schoolName)
    for _, params in ipairs(spell.effects or {}) do
        local effect = params.effect or core.magic.effects.records[params.id]
        addSearchPart(parts, effectId(params))
        addSearchPart(parts, effect and effect.name)
        addSearchPart(parts, effect and effect.id and idText(effect.id))
        addSearchPart(parts, effect and targetedEffectName(effect, params))
        addSearchPart(parts, spellEffectText(params))
        if params.affectedSkill and core.stats.Skill.records[params.affectedSkill] then
            addSearchPart(parts, idText(params.affectedSkill))
            addSearchPart(parts, core.stats.Skill.records[params.affectedSkill].name)
        end
        if params.affectedAttribute and core.stats.Attribute.records[params.affectedAttribute] then
            addSearchPart(parts, idText(params.affectedAttribute))
            addSearchPart(parts, core.stats.Attribute.records[params.affectedAttribute].name)
        end
    end
    row.searchText = table.concat(parts, '\n')
    return row.searchText
end

local function filterRows(rows, searchText)
    local query = normalizeSearchText(searchText):match('^%s*(.-)%s*$')
    if query == '' then
        return rows
    end

    local filtered = {}
    for _, row in ipairs(rows) do
        if rowSearchText(row):find(query, 1, true) then
            filtered[#filtered + 1] = row
        end
    end
    return filtered
end

local function sortField(settings)
    local field = settings and settings.sortField or 'name'
    if field == 'school' or field == 'price' or field == 'unknown'
        or (field == 'new' and settings and settings.markNewSpells) then
        return field
    end
    return 'name'
end

local function availableSortFields(settings)
    local fields = {}
    for _, field in ipairs(BASE_SORT_FIELDS) do
        fields[#fields + 1] = field
    end
    if settings and settings.markNewSpells then
        fields[#fields + 1] = 'new'
    end
    return fields
end

local function compareValues(a, b, ascending)
    if a == b then
        return nil
    end
    if ascending then
        return a < b
    end
    return a > b
end

local function comparePrimary(a, b, field, ascending)
    local result
    if field == 'name' then
        local aName = normalizedName(a.spell)
        local bName = normalizedName(b.spell)
        result = compareValues(aName, bName, ascending)
    elseif field == 'school' then
        local aSchool = string.lower(a.schoolName or '')
        local bSchool = string.lower(b.schoolName or '')
        result = compareValues(aSchool, bSchool, ascending)
    elseif field == 'price' then
        result = compareValues(a.price, b.price, ascending)
    elseif field == 'unknown' then
        local aValue = a.hasUnknownEffect and 1 or 0
        local bValue = b.hasUnknownEffect and 1 or 0
        result = compareValues(aValue, bValue, ascending)
    elseif field == 'new' then
        local aValue = a.isNewSpell and 0 or 1
        local bValue = b.isNewSpell and 0 or 1
        result = compareValues(aValue, bValue, ascending)
    end

    if result ~= nil then
        return result
    end

    local aName = normalizedName(a.spell)
    local bName = normalizedName(b.spell)
    if aName ~= bName then
        return aName < bName
    end

    return normalizedId(a.spell) < normalizedId(b.spell)
end

local function sortRows(rows, settings)
    local field = sortField(settings)
    local ascending = not settings or settings.sortAscending ~= false
    table.sort(rows, function(a, b)
        return comparePrimary(a, b, field, ascending)
    end)
end

local function spellTooltip(spell, price)
    local effectLayouts = {}
    local schoolText = spellSchoolText(spell)
    local costText = gmst('sCastCost', 'Cast Cost') .. ': ' .. tostring(Pricing.calcSpellCost(spell))
    local content = ui.content {
        {
            template = I.MWUI.templates.textHeader,
            props = {
                text = spell.name,
            },
        },
        {
            props = {
                size = v2(0, 4),
            },
        },
    }

    if schoolText then
        content:add(Templates.text(schoolText, nil, ui.ALIGNMENT.Center))
        content:add({
            props = {
                size = v2(0, 4),
            },
        })
    end

    for index, params in ipairs(spell.effects) do
        if index > 1 then
            effectLayouts[#effectLayouts + 1] = {
                props = {
                    size = v2(0, 4),
                },
            }
        end
        effectLayouts[#effectLayouts + 1] = {
            type = ui.TYPE.Flex,
            props = {
                horizontal = true,
                arrange = ui.ALIGNMENT.Center,
            },
            content = ui.content {
                Templates.effectIcon(effectId(params), v2(16, 16)),
                {
                    props = {
                        size = v2(4, 1),
                    },
                },
                Templates.text(spellEffectText(params)),
            },
        }
    end

    content:add(Templates.text(costText, nil, ui.ALIGNMENT.Center))
    content:add({
        props = {
            size = v2(0, 4),
        },
    })
    content:add({
        type = ui.TYPE.Flex,
        props = {
            arrange = ui.ALIGNMENT.Start,
        },
        content = ui.content(effectLayouts),
    })

    return Templates.tooltip(8, ui.content {
        {
            type = ui.TYPE.Flex,
            props = {
                align = ui.ALIGNMENT.Center,
                arrange = ui.ALIGNMENT.Center,
            },
            content = content,
        },
    }, idText(spell.id) .. '_tooltip_' .. tostring(price))
end

local function buildRows(merchant, extraKnownSpellIds, settings)
    if not merchant or not merchant:isValid() or not types.Actor.objectIsInstance(merchant) then
        return {}
    end

    local powers = racePowersFor(merchant)
    local knownEffectIds = playerKnownSpellEffectIds(extraKnownSpellIds)
    local seenSpellIds = settings and settings.seenSpellIds or {}
    local markNewSpells = settings and settings.markNewSpells == true
    local rows = {}
    for _, spell in pairs(types.Actor.spells(merchant)) do
        if spell.type == core.magic.SPELL_TYPE.Spell
            and not playerHasSpell(spell, extraKnownSpellIds)
            and not (powers and containsId(powers, spell.id)) then
            local spellId = idText(spell.id)
            rows[#rows + 1] = {
                spell = spell,
                price = Pricing.getSpellBuyingPrice(playerSelf, merchant, spell),
                hasUnknownEffect = hasEffectUnknownToPlayer(spell, knownEffectIds),
                isNewSpell = markNewSpells and seenSpellIds[spellId] ~= true,
                schoolName = spellSchoolName(spell),
            }
        end
    end

    sortRows(rows, settings)

    return rows
end

local function mixColor(a, b, weight)
    return util.color.rgba(
        a.r + (b.r - a.r) * weight,
        a.g + (b.g - a.g) * weight,
        a.b + (b.b - a.b) * weight,
        a.a + (b.a - a.a) * weight)
end

local function unknownSpellColors(baseColor)
    return {
        normal = baseColor,
        hover = mixColor(baseColor, util.color.rgb(1, 1, 1), 0.35),
        disabled = mixColor(baseColor, Templates.colors.disabled, 0.55),
    }
end

function Window:setSortPreference(sortFieldValue, sortAscending)
    local settings = self:settings()
    self.sortOverride = {
        sortField = sortField(sortFieldValue and {
            sortField = sortFieldValue,
            markNewSpells = settings.markNewSpells,
        } or nil),
        sortAscending = sortAscending ~= false,
    }
    if self.ctx and self.ctx.setSortPreference then
        self.ctx.setSortPreference(self.sortOverride.sortField, self.sortOverride.sortAscending)
    end
    self.layoutScrollPos = 0
    self:hideTooltip()
    self.pendingRefresh = true
end

function Window:clearSortOverride()
    self.sortOverride = nil
end

function Window:clearSavedPosition()
    self.position = nil
    self.layoutPosition = nil
    self.pendingWindowSize = nil
    self.suppressBoundsPersist = self.layoutElement ~= nil
    if self.layoutConfig and self.layoutConfig.window then
        self.layoutConfig.window.width = LAYOUT_WINDOW_SIZE.x
        self.layoutConfig.window.height = LAYOUT_WINDOW_SIZE.y
    end
end

local function defaultLayoutPanelConfig()
    return {
        _nextPanelIndex = 12,
        window = {
            width = LAYOUT_WINDOW_SIZE.x,
            height = LAYOUT_WINDOW_SIZE.y,
            padding = { left = 5, right = 5, top = 4, bottom = 0 },
            auto = { width = false, height = false, left = false, right = false, top = false, bottom = false },
            borderVisible = true,
            borderThick = true,
            scroll = false,
            orientation = 'vertical',
            children = { 'header', 'main' },
        },
        header = {
            width = LAYOUT_CONTENT_SIZE.x,
            height = 20,
            padding = { left = 0, right = 0, top = 0, bottom = 0 },
            auto = { width = true, height = false, left = false, right = false, top = false, bottom = false },
            borderVisible = false,
            borderThick = false,
            scroll = false,
            orientation = 'vertical',
            children = {},
        },
        main = {
            width = LAYOUT_CONTENT_SIZE.x,
            height = LAYOUT_CONTENT_SIZE.y - LAYOUT_HEADER_HEIGHT,
            padding = { left = 0, right = 0, top = 0, bottom = 0 },
            auto = { width = true, height = true, left = false, right = false, top = false, bottom = false },
            borderVisible = false,
            borderThick = false,
            scroll = false,
            orientation = 'vertical',
            children = { 'subtitle', 'list', 'p_search', 'controls' },
        },
        subtitle = {
            width = LAYOUT_CONTENT_SIZE.x,
            height = LAYOUT_SUBTITLE_HEIGHT,
            padding = { left = 0, right = 0, top = 0, bottom = 0 },
            auto = { width = true, height = false, left = false, right = false, top = false, bottom = false },
            borderVisible = false,
            borderThick = false,
            scroll = false,
            orientation = 'vertical',
            children = {},
        },
        list = {
            width = LAYOUT_CONTENT_SIZE.x,
            height = 224,
            padding = { left = 0, right = 0, top = 0, bottom = 0 },
            auto = { width = true, height = true, left = false, right = false, top = false, bottom = false },
            borderVisible = true,
            borderThick = false,
            scroll = true,
            orientation = 'vertical',
            children = {},
        },
        controls = {
            width = LAYOUT_CONTENT_SIZE.x,
            height = 34,
            padding = { left = 0, right = 0, top = 0, bottom = 0 },
            auto = { width = true, height = false, left = false, right = false, top = false, bottom = false },
            borderVisible = false,
            borderThick = false,
            scroll = false,
            orientation = 'horizontal',
            children = { 'p_money', 'p_filters', 'p_ok' },
        },
        p_money = {
            width = 180,
            height = 40,
            padding = { left = 3, right = 0, top = 0, bottom = 1 },
            auto = { width = true, height = true, left = false, right = false, top = false, bottom = false },
            borderVisible = false,
            borderThick = false,
            scroll = false,
            orientation = 'vertical',
            children = { 't_money' },
        },
        p_filters = {
            width = 190,
            height = 40,
            padding = { left = 0, right = 8, top = 4, bottom = 3 },
            auto = { width = false, height = true, left = false, right = false, top = false, bottom = false },
            borderVisible = false,
            borderThick = false,
            scroll = false,
            orientation = 'horizontal',
            children = { 't_sort', 't_sort_type', 'p_sort_spacer', 't_sort_dir' },
        },
        p_ok = {
            width = 52,
            height = 40,
            padding = { left = 0, right = 0, top = 4, bottom = 3 },
            auto = { width = false, height = true, left = false, right = false, top = false, bottom = false },
            borderVisible = false,
            borderThick = false,
            scroll = false,
            orientation = 'vertical',
            children = { 'b_ok' },
        },
        p_search = {
            width = LAYOUT_CONTENT_SIZE.x,
            height = 28,
            padding = { left = 0, right = 0, top = 0, bottom = 0 },
            auto = { width = true, height = false, left = false, right = false, top = false, bottom = false },
            borderVisible = true,
            borderThick = false,
            scroll = false,
            orientation = 'vertical',
            children = { 'i_search' },
            visible = true,
        },
        i_search = {
            kind = 'input',
            width = 120,
            height = 22,
            auto = { width = true, height = true, left = false, right = false, top = false, bottom = false },
            defaultText = 'Search...',
            children = {},
            visible = true,
        },
        t_money = {
            kind = 'text',
            width = 120,
            height = 22,
            auto = { width = true, height = true, left = false, right = false, top = false, bottom = false },
            defaultText = 'Золото: 1111111',
            children = {},
        },
        t_sort = {
            kind = 'text',
            width = 48,
            height = 22,
            auto = { width = false, height = true, left = false, right = false, top = false, bottom = false },
            defaultText = 'Сорт.',
            children = {},
        },
        t_sort_type = {
            kind = 'button',
            width = 67,
            height = 22,
            auto = { width = true, height = true, left = false, right = false, top = false, bottom = false },
            defaultText = 'Имя',
            children = {},
        },
        p_sort_spacer = {
            width = 3,
            height = 40,
            padding = { left = 0, right = 0, top = 0, bottom = 0 },
            auto = { width = false, height = false, left = false, right = false, top = false, bottom = false },
            borderVisible = false,
            borderThick = false,
            scroll = false,
            orientation = 'vertical',
            children = {},
        },
        t_sort_dir = {
            kind = 'button',
            width = 48,
            height = 22,
            auto = { width = false, height = true, left = false, right = false, top = false, bottom = false },
            defaultText = 'А-Я',
            children = {},
        },
        b_ok = {
            kind = 'button',
            width = 76,
            height = 22,
            auto = { width = true, height = true, left = false, right = false, top = false, bottom = false },
            defaultText = 'OK',
            children = {},
        },
    }
end

local isLayoutNode

local function copyLayoutPanel(panel)
    local children = {}
    for index, childName in ipairs(panel.children or {}) do
        children[index] = childName
    end
    local padding = panel.padding or { left = 0, right = 0, top = 0, bottom = 0 }
    return {
        width = panel.width,
        height = panel.height,
        padding = panel.padding and {
            left = panel.auto.left and 0 or padding.left,
            right = panel.auto.right and 0 or padding.right,
            top = panel.auto.top and 0 or padding.top,
            bottom = panel.auto.bottom and 0 or padding.bottom,
        } or nil,
        auto = panel.auto,
        borderVisible = panel.borderVisible,
        borderThick = panel.borderThick,
        scroll = panel.scroll,
        orientation = panel.orientation or 'vertical',
        children = children,
        kind = panel.kind or 'panel',
        defaultText = panel.defaultText,
        visible = panel.visible ~= false,
    }
end

local function copyLayoutConfig(raw)
    local config = {
        _nextPanelIndex = raw._nextPanelIndex,
    }
    for panelName, panel in pairs(raw) do
        if isLayoutNode(panel) then
            config[panelName] = copyLayoutPanel(panel)
        end
    end
    return config
end

function isLayoutNode(panel)
    return type(panel) == 'table'
        and type(panel.width) == 'number'
        and type(panel.height) == 'number'
        and type(panel.auto) == 'table'
end

local function isLayoutPanel(panel)
    return isLayoutNode(panel)
        and (panel.kind == nil or panel.kind == 'panel')
        and type(panel.padding) == 'table'
end

local function isLayoutElement(panel)
    return isLayoutNode(panel)
        and (panel.kind == 'button' or panel.kind == 'input' or panel.kind == 'text')
end

local function layoutPanelTreeEntries(config)
    local entries = {}
    local seen = {}
    local function visit(panelName, depth)
        local panel = config[panelName]
        if seen[panelName] or not isLayoutNode(panel) then
            return
        end
        seen[panelName] = true
        entries[#entries + 1] = {
            name = panelName,
            depth = depth,
        }
        for _, childName in ipairs(panel.children or {}) do
            visit(childName, depth + 1)
        end
    end
    visit('window', 0)
    return entries
end

local function layoutPanelNames(config)
    local names = {}
    for _, entry in ipairs(layoutPanelTreeEntries(config)) do
        names[#names + 1] = entry.name
    end
    return names
end

local function removeChild(panel, childName)
    local children = panel and panel.children
    if not children then
        return
    end
    for index = #children, 1, -1 do
        if children[index] == childName then
            table.remove(children, index)
        end
    end
end

local function visibleChildren(config, panel)
    local children = {}
    for _, childName in ipairs(panel.children or {}) do
        local child = config[childName]
        if child and child.visible ~= false then
            children[#children + 1] = childName
        end
    end
    return children
end

local function sortFieldLabel(field)
    if field == 'school' then
        return l10n('SortFieldSchool')
    elseif field == 'price' then
        return l10n('SortFieldPrice')
    elseif field == 'unknown' then
        return l10n('SortFieldUnknown')
    elseif field == 'new' then
        return l10n('SortFieldNew')
    end
    return l10n('SortFieldName')
end

local function nextSortField(field, settings)
    field = sortField(settings and {
        sortField = field,
        markNewSpells = settings.markNewSpells,
    } or nil)
    local fields = availableSortFields(settings)
    for index, value in ipairs(fields) do
        if value == field then
            return fields[index % #fields + 1]
        end
    end
    return 'name'
end

local function panelInnerSize(panel)
    local padding = panel.padding
    local borderWidth = panel.borderVisible and 4 or 0
    return v2(
        math.max(1, panel.width - borderWidth - padding.left - padding.right),
        math.max(1, panel.height - borderWidth * 2 - padding.top - padding.bottom))
end

local function panelContentOffset(panel, ignoreBorder)
    local borderOffset = panel.borderVisible and 4 or 0
    if ignoreBorder then
        borderOffset = 0
    end
    return v2(
        borderOffset + panel.padding.left,
        borderOffset + panel.padding.top)
end

local function panelLayoutSize(panel)
    return v2(math.max(1, panel.width), math.max(1, panel.height))
end

local function panelScrollbarSize(panel)
    return v2(
        math.max(1, panel.width),
        math.max(1, panel.height))
end

local function layoutBorder(panel)
    return {
        name = 'border',
        template = panel.borderThick and I.MWUI.templates.bordersThick or I.MWUI.templates.borders,
        props = {
            visible = panel.borderVisible,
            position = v2(0, 0),
            size = v2(math.max(1, panel.width), math.max(1, panel.height)),
        },
    }
end

local function layoutHighlight(panel, name)
    return {
        name = name or 'background',
        type = ui.TYPE.Image,
        props = {
            resource = ui.texture { path = 'white' },
            visible = false,
            position = v2(0, 0),
            size = v2(math.max(1, panel.width), math.max(1, panel.height)),
        },
    }
end

local function scrollbarMetrics(panel, boundsSize, scrollData)
    local rightMargin = 4
    local topMargin = 6
    local bottomMargin = 3
    local buttonSize = 14
    local scrollbarWidth = 16
    local size = boundsSize or panelLayoutSize(panel)
    local borderWidth = panel.borderVisible and 4 or 0
    local scrollbarHeight = math.max(buttonSize * 2, size.y - topMargin - bottomMargin - borderWidth)
    local trackHeight = math.max(buttonSize, scrollbarHeight - buttonSize * 2)
    local handleHeight = buttonSize
    if scrollData and scrollData.scrollLimit > 0 then
        local viewportHeight = scrollData.viewportHeight or size.y
        handleHeight = math.max(buttonSize, (viewportHeight / (scrollData.scrollLimit + viewportHeight)) * trackHeight)
    end
    return {
        buttonSize = buttonSize,
        handleHeight = handleHeight,
        position = v2(size.x - scrollbarWidth - rightMargin, topMargin),
        size = v2(scrollbarWidth, scrollbarHeight),
        trackHeight = trackHeight,
    }
end

local function layoutScrollbar(panel, boundsSize, scrollData)
    local metrics = scrollbarMetrics(panel, boundsSize, scrollData)
    local buttonSize = metrics.buttonSize
    local trackHeight = metrics.trackHeight
    local handleHeight = metrics.handleHeight
    local scrollBy = function(delta)
        if scrollData then
            scrollData.scrollBy(delta)
        end
    end
    local startDrag = function(e, layout)
        if scrollData and e.button == 1 then
            layout.userData.dragging = true
            layout.userData.dragStartAbs = e.position
            layout.userData.dragStartScroll = scrollData.getScrollPos()
            ambient.playSound('menu click')
        end
    end
    local updateDrag = function(e, layout)
        if not scrollData or not layout.userData.dragging or not layout.userData.dragStartAbs then
            return
        end
        local travel = math.max(0, trackHeight - handleHeight - 4)
        if travel > 0 then
            local delta = e.position.y - layout.userData.dragStartAbs.y
            scrollData.scrollTo(layout.userData.dragStartScroll + (delta / travel) * scrollData.scrollLimit)
        end
    end
    local stopDrag = function(layout)
        layout.userData.dragging = false
        layout.userData.dragStartAbs = nil
        layout.userData.dragStartScroll = nil
    end
    return {
        name = 'scrollbar',
        type = ui.TYPE.Flex,
        props = {
            visible = panel.scroll == true and (not scrollData or scrollData.scrollLimit > 0),
            horizontal = false,
            position = metrics.position,
            size = metrics.size,
            autoSize = false,
        },
        content = ui.content {
            {
                template = I.MWUI.templates.borders,
                props = {
                    size = v2(buttonSize, buttonSize),
                },
                content = ui.content {{
                    type = ui.TYPE.Image,
                    props = {
                        resource = ui.texture { path = 'textures/omw_menu_scroll_up.dds' },
                        size = v2(buttonSize - 4, buttonSize - 4),
                    },
                }},
                events = {
                    mousePress = async:callback(function(e)
                        if e.button == 1 then
                            scrollBy(-ROW_HEIGHT * 2)
                        end
                        return true
                    end),
                },
            },
            {
                name = 'track',
                template = I.MWUI.templates.borders,
                props = {
                    size = v2(buttonSize, trackHeight),
                },
                userData = {
                    dragging = false,
                    dragStartAbs = nil,
                    dragStartScroll = nil,
                },
                content = ui.content {{
                    name = 'handle',
                    type = ui.TYPE.Image,
                    props = {
                        resource = ui.texture { path = 'textures/omw_menu_scroll_center_v.dds' },
                        size = v2(buttonSize - 4, handleHeight),
                        position = v2(0, 0),
                        tileV = true,
                    },
                    userData = {
                        dragging = false,
                        dragStartAbs = nil,
                        dragStartScroll = nil,
                    },
                    events = {
                        mousePress = async:callback(function(e, layout)
                            startDrag(e, layout)
                            return true
                        end),
                        mouseMove = async:callback(function(e, layout)
                            updateDrag(e, layout)
                            return true
                        end),
                        mouseRelease = async:callback(function(e, layout)
                            if e.button == 1 then
                                stopDrag(layout)
                            end
                            return true
                        end),
                        focusLoss = async:callback(function(_, layout)
                            stopDrag(layout)
                            return true
                        end),
                    },
                }},
                events = {
                    mousePress = async:callback(function(e, layout)
                        if e.button == 1 then
                            startDrag(e, layout)
                        end
                        return true
                    end),
                    mouseMove = async:callback(function(e, layout)
                        updateDrag(e, layout)
                        return true
                    end),
                    mouseRelease = async:callback(function(e, layout)
                        if e.button == 1 then
                            stopDrag(layout)
                        end
                        return true
                    end),
                    focusLoss = async:callback(function(_, layout)
                        stopDrag(layout)
                        return true
                    end),
                },
            },
            {
                template = I.MWUI.templates.borders,
                props = {
                    size = v2(buttonSize, buttonSize),
                },
                content = ui.content {{
                    type = ui.TYPE.Image,
                    props = {
                        resource = ui.texture { path = 'textures/omw_menu_scroll_down.dds' },
                        size = v2(buttonSize - 4, buttonSize - 4),
                    },
                }},
                events = {
                    mousePress = async:callback(function(e)
                        if e.button == 1 then
                            scrollBy(ROW_HEIGHT * 2)
                        end
                        return true
                    end),
                },
            },
        },
    }
end

local function resolveChildPanels(config, parentPanel, panels, parentSize)
    local horizontal = parentPanel.orientation == 'horizontal'
    local fixedPrimary = 0
    local autoPrimaryCount = 0
    for _, panelName in ipairs(panels) do
        local panel = config[panelName]
        if horizontal then
            if panel.auto.height then
                panel.height = parentSize.y
            end
            if panel.auto.width then
                autoPrimaryCount = autoPrimaryCount + 1
            else
                fixedPrimary = fixedPrimary + panel.width
            end
        else
            if panel.auto.width then
                panel.width = parentSize.x
            end
            if panel.auto.height then
                autoPrimaryCount = autoPrimaryCount + 1
            else
                fixedPrimary = fixedPrimary + panel.height
            end
        end
    end

    local autoPrimary = horizontal and 1 or LAYOUT_MIN_PANEL_HEIGHT
    if autoPrimaryCount > 0 then
        local parentPrimary = horizontal and parentSize.x or parentSize.y
        autoPrimary = math.max(autoPrimary, (parentPrimary - fixedPrimary) / autoPrimaryCount)
    end
    for _, panelName in ipairs(panels) do
        local panel = config[panelName]
        if horizontal and panel.auto.width then
            panel.width = autoPrimary
        elseif not horizontal and panel.auto.height then
            panel.height = autoPrimary
        end
    end
end

local function resolvePanels(config, parentPanel, panels, parentSize)
    resolveChildPanels(config, parentPanel, panels, parentSize)
end

local function panelHorizontal(panel)
    return panel.orientation == 'horizontal'
end

local function resolveLayoutPanelConfig(raw)
    local config = {}
    for panelName, panel in pairs(raw) do
        if isLayoutNode(panel) then
            config[panelName] = copyLayoutPanel(panel)
        end
    end

    local function resolveChildren(panelName)
        local panel = config[panelName]
        if not isLayoutPanel(panel) or not panel.children or #panel.children == 0 then
            return
        end
        local children = visibleChildren(config, panel)
        if #children == 0 then
            return
        end
        local contentSize = panelInnerSize(panel)
        if panel.borderVisible then
            if panelName == 'window' then
                contentSize = v2(math.max(1, contentSize.x - 4), contentSize.y)
            else
                contentSize = v2(math.max(1, contentSize.x - 4), contentSize.y)
            end
        end
        resolvePanels(config, panel, children, contentSize)
        for _, childName in ipairs(children) do
            resolveChildren(childName)
        end
    end

    resolveChildren('window')
    return config
end

local function spellRowLabel(row, gp)
    local prefix = row.isNewSpell and NEW_SPELL_MARK or ''
    return prefix .. row.spell.name .. '  - ' .. tostring(row.price) .. gp
end

function Window:clearSeenHoverCandidate()
    self.seenHoverSpellId = nil
    self.seenHoverStartedAt = nil
    self.seenHoverRow = nil
    self.seenHoverLayout = nil
    self.seenHoverGp = nil
end

function Window:markRowSeen(row, layout, gp)
    if not row or not row.spell or not row.isNewSpell then
        return
    end
    row.isNewSpell = false
    self:clearSeenHoverCandidate()
    if self.ctx and self.ctx.markSpellSeen then
        self.ctx.markSpellSeen(idText(row.spell.id))
    end

    local settings = self:settings()
    if settings.sortField == 'new' then
        self.pendingRefresh = true
        return
    end

    if layout and layout.content and layout.content.label then
        layout.content.label.props.text = spellRowLabel(row, gp)
        if self.layoutElement then
            self.layoutElement:update()
        end
    end
end

function Window:trackSeenHover(row, layout, gp)
    local settings = self:settings()
    if not settings.markNewSpells or not row or not row.isNewSpell then
        self:clearSeenHoverCandidate()
        return
    end

    local spellId = idText(row.spell.id)
    if self.seenHoverSpellId ~= spellId then
        self.seenHoverSpellId = spellId
        self.seenHoverStartedAt = core.getRealTime()
        self.seenHoverRow = row
        self.seenHoverLayout = layout
        self.seenHoverGp = gp
    end

    if settings.newSpellSeenDelay <= 0 then
        self:markRowSeen(row, layout, gp)
    end
end

function Window:layoutRow(row, rowIndex, size, gp, settings, highlightColors, gold)
    local label = spellRowLabel(row, gp)
    local highlight = settings.highlightUnknownSpells and row.hasUnknownEffect
    local color = highlight and highlightColors.normal or nil
    local hoverColor = highlight and highlightColors.hover or nil
    local disabledColor = highlight and highlightColors.disabled or nil
    local affordable = row.price <= gold
    local firstEffect = row.spell.effects[1]
    local icon = settings.showIcons
        and firstEffect
        and Templates.effectIcon(effectId(firstEffect), ROW_ICON_SIZE)
        or nil

    return Templates.textRowButton(label, size, function()
        self.layoutScrollPos = self.layoutScrollable
            and self.layoutScrollable.userData.getScrollPos(self.layoutScrollable)
            or self.layoutScrollPos
        self:buyOrConfirm(row)
    end, {
        disabled = not affordable,
        alignH = ui.ALIGNMENT.Start,
        normalColor = color,
        hoverColor = hoverColor,
        disabledColor = disabledColor,
        icon = icon,
        iconSize = ROW_ICON_SIZE,
        iconLeftPadding = ROW_ICON_LEFT_PADDING,
        onFocusLoss = function()
            self:hideTooltip()
            self:clearSeenHoverCandidate()
        end,
        onMouseMove = function(e, layout)
            self:showTooltipForRow(rowIndex, e.position)
            self:trackSeenHover(row, layout, gp)
        end,
        update = function()
            if self.layoutElement then
                self.layoutElement:update()
            end
        end,
    })
end

function Window:layoutPanelConfig()
    if not self.layoutConfig then
        self.layoutConfig = defaultLayoutPanelConfig()
    end
    return self.layoutConfig
end

function Window:createLayoutWindow(rows, gold, gp, settings, highlightColors, position, layerSize)
    local rawConfig = self:layoutPanelConfig()
    local windowSize = self.pendingWindowSize or settings.windowSize
    if windowSize then
        rawConfig.window.width = math.max(1, windowSize.x or rawConfig.window.width)
        rawConfig.window.height = math.max(LAYOUT_MIN_PANEL_HEIGHT, windowSize.y or rawConfig.window.height)
    end
    local function effectiveRawConfig()
        local config = copyLayoutConfig(rawConfig)
        if not settings.showSortButtons then
            removeChild(config.controls, 'p_filters')
        end
        if not settings.showSearch then
            removeChild(config.main, 'p_search')
        end
        return config
    end
    local config = resolveLayoutPanelConfig(effectiveRawConfig())
    local listPanel = config.list
    local headerPanel = config.header or config.window
    local layoutSize = panelLayoutSize(config.window)
    local windowInnerSize = panelInnerSize(config.window)
    local listInnerSize = listPanel and panelInnerSize(listPanel) or v2(1, 1)
    local listSize = listInnerSize
    local listRowSize = v2(math.max(1, listSize.x - 18), ROW_HEIGHT)
    local displayRows = settings.showSearch and filterRows(rows, self.searchText) or rows
    self.filteredRows = displayRows
    local function buildRowContent(rowSize)
        local content = ui.content {}
        for rowIndex, row in ipairs(displayRows) do
            content:add(self:layoutRow(row, rowIndex, rowSize, gp, settings, highlightColors, gold))
        end
        return content
    end

    local rowContent = buildRowContent(listRowSize)
    local rowsHeight = #displayRows * ROW_HEIGHT
    local contentHeight = rowsHeight
    local listScrollLimit = math.max(0, contentHeight - listSize.y - 1)
    self.layoutScrollPos = util.clamp(self.layoutScrollPos or 0, 0, listScrollLimit)
    local listScrollData = {
        scrollLimit = listScrollLimit,
        scrollStep = ROW_HEIGHT * 2,
        viewportHeight = listSize.y,
    }
    listScrollData.scrollTo = function(scrollPos)
        self.layoutScrollPos = util.clamp(scrollPos, 0, listScrollData.scrollLimit)
        if self.layoutListRows then
            self.layoutListRows.props.position = v2(0, -self.layoutScrollPos)
        end
        if listScrollData.sync then
            listScrollData.sync()
        end
        if self.layoutElement then
            self.layoutElement:update()
        end
    end
    listScrollData.scrollBy = function(delta)
        listScrollData.scrollTo(self.layoutScrollPos + delta)
    end
    listScrollData.getScrollPos = function()
        return self.layoutScrollPos or 0
    end
    local function updateFilteredRows(searchText)
        self.searchText = searchText or ''
        displayRows = filterRows(rows, self.searchText)
        self.filteredRows = displayRows
        rowsHeight = #displayRows * ROW_HEIGHT
        contentHeight = rowsHeight
        local currentRowWidth = self.layoutListRows
            and self.layoutListRows.props
            and self.layoutListRows.props.size.x
            or listRowSize.x
        local currentListSize = listScrollData.viewportHeight
            and v2(currentRowWidth, listScrollData.viewportHeight)
            or listSize
        listScrollData.scrollLimit = math.max(0, contentHeight - currentListSize.y - 1)
        self.layoutScrollPos = util.clamp(self.layoutScrollPos or 0, 0, listScrollData.scrollLimit)
        if self.layoutListRows then
            self.layoutListRows.content = buildRowContent(v2(currentRowWidth, ROW_HEIGHT))
            self.layoutListRows.props.position = v2(0, -self.layoutScrollPos)
            self.layoutListRows.props.size = v2(
                math.max(1, listRowSize.x),
                math.max(currentListSize.y, contentHeight))
        end
        if listScrollData.sync then
            listScrollData.sync()
        end
        self:hideTooltip()
        if self.layoutElement then
            self.layoutElement:update()
        end
    end
    local minWindowWidth = 160
    local minWindowHeight = 120
    local resizeHandleSize = 6
    local function elementText(panelName, panel)
        if panelName == 't_money' then
            return l10n('Gold') .. ': ' .. tostring(gold)
        elseif panelName == 't_sort' then
            return l10n('SortLabel')
        elseif panelName == 't_sort_type' then
            return sortFieldLabel(settings.sortField)
        elseif panelName == 't_sort_dir' then
            return settings.sortAscending ~= false and l10n('SortDirectionAsc') or l10n('SortDirectionDesc')
        elseif panelName == 'i_search' then
            return l10n('SearchPlaceholder')
        elseif panelName == 'b_ok' then
            return Templates.gmst('sOK', 'OK')
        end
        return panel.defaultText or panel.kind
    end
    local function elementClick(panelName)
        if panelName == 'b_ok' then
            return function()
                I.UI.removeMode('SpellBuying')
            end
        elseif panelName == 't_sort_type' then
            return function()
                self:setSortPreference(nextSortField(settings.sortField, settings), settings.sortAscending)
            end
        elseif panelName == 't_sort_dir' then
            return function()
                self:setSortPreference(settings.sortField, settings.sortAscending == false)
            end
        end
        return nil
    end
    local function renderLayoutElement(panelName, panel)
        local size = panelLayoutSize(panel)
        local text = elementText(panelName, panel)
        local layout
        if panel.kind == 'button' then
            layout = Templates.button(text, size, elementClick(panelName))
        elseif panel.kind == 'input' then
            local placeholder = text
            local initialText = panelName == 'i_search' and (self.searchText or '') or ''
            local hasValue = initialText ~= ''
            layout = {
                name = panelName,
                template = I.MWUI.templates.textEditLine,
                props = {
                    text = hasValue and initialText or placeholder,
                    textColor = hasValue and Templates.colors.normal or Templates.colors.disabled,
                    size = size,
                    autoSize = false,
                    textAlignH = ui.ALIGNMENT.Start,
                    textAlignV = ui.ALIGNMENT.Center,
                },
                events = {
                    textChanged = async:callback(function(value, inputLayout)
                        inputLayout.props.text = value
                        if inputLayout.props.textColor == Templates.colors.disabled then
                            inputLayout.props.textColor = Templates.colors.normal
                            if self.layoutElement then
                                self.layoutElement:update()
                            end
                        end
                        if panelName == 'i_search' then
                            updateFilteredRows(value)
                        end
                        return true
                    end),
                    focusGain = async:callback(function(_, inputLayout)
                        if inputLayout.props.text == placeholder then
                            inputLayout.props.text = ''
                            if self.layoutElement then
                                self.layoutElement:update()
                            end
                        end
                        return true
                    end),
                    focusLoss = async:callback(function(_, inputLayout)
                        if inputLayout.props.text == '' then
                            inputLayout.props.text = placeholder
                            inputLayout.props.textColor = Templates.colors.disabled
                            if panelName == 'i_search' then
                                updateFilteredRows('')
                            end
                            if self.layoutElement then
                                self.layoutElement:update()
                            end
                        end
                        return true
                    end),
                },
            }
        else
            layout = {
                name = panelName,
                template = I.MWUI.templates.textNormal,
                props = {
                    text = text,
                    size = size,
                    autoSize = false,
                    textAlignH = ui.ALIGNMENT.Start,
                    textAlignV = ui.ALIGNMENT.Center,
                },
            }
        end
        layout.name = panelName
        layout.props = layout.props or {}
        layout.props.size = size
        return layout
    end
    local function renderPanel(panelName)
        local panel = config[panelName]
        if not panel then
            return { props = { size = v2(1, 1) } }
        end
        if panel.visible == false then
            return nil
        end
        if isLayoutElement(panel) then
            return renderLayoutElement(panelName, panel)
        end

        local panelContent = ui.content {
            layoutHighlight(panel),
            layoutBorder(panel),
        }
        local children = visibleChildren(config, panel)
        if #children > 0 then
            local childContent = ui.content {}
            for _, childName in ipairs(children) do
                local childLayout = renderPanel(childName)
                if childLayout then
                    childContent:add(childLayout)
                end
            end
            panelContent:add({
                name = 'inner',
                type = ui.TYPE.Flex,
                props = {
                    horizontal = panelHorizontal(panel),
                    position = panelContentOffset(panel),
                    size = panelInnerSize(panel),
                    autoSize = false,
                },
                content = childContent,
            })
        elseif panelName == 'header' then
            panelContent:add({
                name = 'headerText',
                template = I.MWUI.templates.textHeader,
                props = {
                    text = Templates.gmst('sServiceSpellsTitle', 'Spells'),
                    position = panelContentOffset(panel),
                    size = panelInnerSize(panel),
                    autoSize = false,
                    textAlignH = ui.ALIGNMENT.Center,
                    textAlignV = ui.ALIGNMENT.Center,
                },
            })
        elseif panelName == 'subtitle' then
            panelContent:add({
                name = 'subtitleText',
                template = I.MWUI.templates.textNormal,
                props = {
                    text = Templates.gmst('sSpellServiceTitle', 'Spells'),
                    position = panelContentOffset(panel),
                    size = panelInnerSize(panel),
                    autoSize = false,
                    textAlignH = ui.ALIGNMENT.Start,
                    textAlignV = ui.ALIGNMENT.Center,
                },
            })
        elseif panelName == 'list' then
            panelContent:add({
                name = 'viewport',
                type = ui.TYPE.Widget,
                props = {
                    position = panelContentOffset(panel),
                    size = listSize,
                },
                content = ui.content {{
                    name = 'rows',
                    type = ui.TYPE.Flex,
                    props = {
                        position = v2(0, -self.layoutScrollPos),
                        size = v2(listRowSize.x, math.max(listSize.y, contentHeight)),
                        autoSize = false,
                    },
                    content = rowContent,
                }},
            })
        end

        local scrollData = panelName == 'list' and listScrollData or nil
        panelContent:add(layoutScrollbar(panel, panelScrollbarSize(panel), scrollData))
        return {
            name = panelName,
            type = ui.TYPE.Widget,
            props = {
                size = panelLayoutSize(panel),
            },
            content = panelContent,
            events = panelName == 'list' and {
                focusGain = async:callback(function(_, layout)
                    self.ctx.focusedScrollable = layout
                    return true
                end),
                focusLoss = async:callback(function(_, layout)
                    if self.ctx.focusedScrollable == layout then
                        self.ctx.focusedScrollable = nil
                    end
                    return true
                end),
            } or nil,
        }
    end
    local layoutPos = self.layoutPosition
        or position
        or LAYOUT_DEFAULT_POSITION
    layoutPos = v2(
        util.clamp(layoutPos.x, 0, math.max(0, layerSize.x - layoutSize.x)),
        util.clamp(layoutPos.y, 0, math.max(0, layerSize.y - layoutSize.y)))
    self.layoutPosition = layoutPos
    local function resizeRootLayout()
        return self.layoutElement and self.layoutElement.layout or nil
    end
    local function contentByName(content, name)
        if not content then
            return nil
        end
        local ok, value = pcall(function()
            return content[name]
        end)
        if ok then
            return value
        end
        return nil
    end
    local function findNamed(layout, name, seen)
        if not layout or seen[layout] then
            return nil
        end
        seen[layout] = true
        local okName, layoutName = pcall(function()
            return layout.name
        end)
        if okName and layoutName == name then
            return layout
        end
        if layout.content then
            local named = contentByName(layout.content, name)
            if named then
                return named
            end
            for _, child in pairs(layout.content) do
                if type(child) == 'table' then
                    local found = findNamed(child, name, seen)
                    if found then
                        return found
                    end
                end
            end
        end
        return nil
    end
    local function updateScrollbarLayout(scrollbar, panel, scrollData)
        if not scrollbar or not scrollbar.props then
            return
        end

        local metrics = scrollbarMetrics(panel, panelScrollbarSize(panel), scrollData)
        local buttonSize = metrics.buttonSize
        scrollbar.props.visible = panel.scroll == true and (not scrollData or scrollData.scrollLimit > 0)
        scrollbar.props.position = metrics.position
        scrollbar.props.size = metrics.size

        if not scrollbar.content then
            return
        end

        local upButton = scrollbar.content[1]
        if upButton and upButton.props then
            upButton.props.size = v2(buttonSize, buttonSize)
        end

        local track = contentByName(scrollbar.content, 'track')
        if track and track.props then
            track.props.size = v2(buttonSize, metrics.trackHeight)
            local handle = track.content and contentByName(track.content, 'handle') or nil
            if handle and handle.props then
                handle.props.size = v2(buttonSize - 4, metrics.handleHeight)
            end
        end

        local downButton = scrollbar.content[3]
        if downButton and downButton.props then
            downButton.props.size = v2(buttonSize, buttonSize)
        end
    end
    local function updateLiveLayout(layout)
        local liveConfig = resolveLayoutPanelConfig(effectiveRawConfig())
        local windowLayoutSize = panelLayoutSize(liveConfig.window)
        local windowBackground = contentByName(layout.content, 'windowBackground')
        if windowBackground then
            windowBackground.props.size = windowLayoutSize
        end

        local windowContent = findNamed(layout, 'windowContent', {})
        if windowContent then
            windowContent.props.horizontal = panelHorizontal(liveConfig.window)
            windowContent.props.position = v2(LAYOUT_PADDING, LAYOUT_PADDING)
                + panelContentOffset(liveConfig.window, true)
            windowContent.props.size = panelInnerSize(liveConfig.window)
        end
        updateScrollbarLayout(contentByName(layout.content, 'scrollbar'), liveConfig.window, nil)

        for _, panelName in ipairs(layoutPanelNames(liveConfig)) do
            local panel = liveConfig[panelName]
            local panelLayout = findNamed(layout, panelName, {})
            if panelLayout then
                local layoutSizeForPanel = panelLayoutSize(panel)
                panelLayout.props.size = layoutSizeForPanel
                if isLayoutElement(panel) then
                    local text = elementText(panelName, panel)
                    if panel.kind ~= 'input' then
                        panelLayout.props.text = text
                    end
                    local label = panelLayout.content and contentByName(panelLayout.content, 'label') or nil
                    if label then
                        label.props.text = text
                        label.props.size = layoutSizeForPanel
                    end
                end
                local content = panelLayout.content
                local background = contentByName(content, 'background')
                if background then
                    background.props.size = layoutSizeForPanel
                end
                local border = contentByName(content, 'border')
                if border then
                    border.props.size = layoutSizeForPanel
                end
                local inner = contentByName(content, 'inner')
                if inner then
                    inner.props.horizontal = panelHorizontal(panel)
                    inner.props.position = panelContentOffset(panel)
                    inner.props.size = panelInnerSize(panel)
                end
                local headerText = contentByName(content, 'headerText')
                if headerText then
                    headerText.props.position = panelContentOffset(panel)
                    headerText.props.size = panelInnerSize(panel)
                end
                local subtitleText = contentByName(content, 'subtitleText')
                if subtitleText then
                    subtitleText.props.position = panelContentOffset(panel)
                    subtitleText.props.size = panelInnerSize(panel)
                end
                local viewport = contentByName(content, 'viewport')
                if viewport then
                    local liveListSize = panelInnerSize(panel)
                    local liveScrollLimit = math.max(0, contentHeight - liveListSize.y - 1)
                    listScrollData.scrollLimit = liveScrollLimit
                    listScrollData.viewportHeight = liveListSize.y
                    self.layoutScrollPos = util.clamp(self.layoutScrollPos or 0, 0, liveScrollLimit)
                    viewport.props.position = panelContentOffset(panel)
                    viewport.props.size = liveListSize
                    local rowsLayout = contentByName(viewport.content, 'rows')
                    if rowsLayout then
                        rowsLayout.props.position = v2(0, -self.layoutScrollPos)
                        rowsLayout.props.size = v2(
                            math.max(1, liveListSize.x - 18),
                            math.max(liveListSize.y, contentHeight))
                    end
                end
                local scrollData = panelName == 'list' and listScrollData or nil
                updateScrollbarLayout(
                    contentByName(content, 'scrollbar'),
                    panel,
                    scrollData)
                if scrollData and scrollData.sync then
                    scrollData.sync()
                end
            end
        end
    end
    local function startResize(edge)
        return function(e)
            if e.button ~= 1 then
                return true
            end
            local layout = resizeRootLayout()
            if not layout then
                return true
            end
            layout.userData.resizingEdge = edge
            layout.userData.resizeStartAbs = e.position
            layout.userData.resizeStartPos = layout.props.position
            layout.userData.resizeStartSize = layout.props.size
            self.suppressBoundsPersist = false
            ambient.playSound('menu click')
            return true
        end
    end
    local function updateResize(e, layout)
        layout = layout and layout.userData and layout.userData.resizeStartSize and layout or resizeRootLayout()
        if not layout
            or not layout.userData
            or not layout.userData.resizingEdge
            or not layout.userData.resizeStartAbs
            or not layout.userData.resizeStartPos
            or not layout.userData.resizeStartSize then
            return true
        end

        local edge = layout.userData.resizingEdge
        local startPos = layout.userData.resizeStartPos
        local startSize = layout.userData.resizeStartSize
        local delta = e.position - layout.userData.resizeStartAbs
        local x = startPos.x
        local y = startPos.y
        local width = startSize.x
        local height = startSize.y

        if edge:find('right', 1, true) then
            width = util.clamp(startSize.x + delta.x, minWindowWidth, layerSize.x - startPos.x)
        elseif edge:find('left', 1, true) then
            local right = startPos.x + startSize.x
            x = util.clamp(startPos.x + delta.x, 0, right - minWindowWidth)
            width = right - x
        end
        if edge:find('bottom', 1, true) then
            height = util.clamp(startSize.y + delta.y, minWindowHeight, layerSize.y - startPos.y)
        elseif edge:find('top', 1, true) then
            local bottom = startPos.y + startSize.y
            y = util.clamp(startPos.y + delta.y, 0, bottom - minWindowHeight)
            height = bottom - y
        end

        layout.props.position = v2(x, y)
        layout.props.size = v2(width, height)
        rawConfig.window.width = width
        rawConfig.window.height = height
        self.pendingWindowSize = v2(width, height)
        updateLiveLayout(layout)
        self.layoutPosition = layout.props.position
        self.position = self.layoutPosition
        self.layoutElement:update()
        return true
    end
    local function stopResize(layout)
        if not layout or not layout.userData then
            return true
        end
        if layout.userData.resizingEdge then
            layout.userData.resizingEdge = nil
            layout.userData.resizeStartAbs = nil
            layout.userData.resizeStartPos = nil
            layout.userData.resizeStartSize = nil
            self:persistBounds(layout.props.position, layout.props.size)
            self.pendingWindowSize = layout.props.size
            self.pendingRefresh = true
        end
        return true
    end
    local function resizeHandle(name, edge, pointer, relativePosition, handlePosition, relativeSize, size)
        return {
            name = name,
            type = ui.TYPE.Image,
            props = {
                resource = ui.texture { path = 'white' },
                alpha = 0.01,
                relativePosition = relativePosition,
                position = handlePosition,
                relativeSize = relativeSize,
                size = size,
                pointer = pointer,
            },
            events = {
                mousePress = async:callback(startResize(edge)),
                mouseMove = async:callback(updateResize),
                mouseRelease = async:callback(function(_, layout)
                    return stopResize(resizeRootLayout() or layout)
                end),
                focusLoss = async:callback(function(_, layout)
                    return stopResize(resizeRootLayout() or layout)
                end),
            },
        }
    end
    local baseWindowTemplate = config.window.borderThick and I.MWUI.templates.bordersThick or I.MWUI.templates.borders
    local windowTemplate = config.window.borderVisible and auxUi.deepLayoutCopy(baseWindowTemplate) or nil
    if windowTemplate and settings.allowWindowResize then
        windowTemplate.content:add(resizeHandle(
            'resizeTop',
            'top',
            'vresize',
            v2(0, 0),
            v2(0, 0),
            v2(1, 0),
            v2(0, resizeHandleSize)))
        windowTemplate.content:add(resizeHandle(
            'resizeBottom',
            'bottom',
            'vresize',
            v2(0, 1),
            v2(0, -resizeHandleSize),
            v2(1, 0),
            v2(0, resizeHandleSize)))
        windowTemplate.content:add(resizeHandle(
            'resizeLeft',
            'left',
            'hresize',
            v2(0, 0),
            v2(0, 0),
            v2(0, 1),
            v2(resizeHandleSize, 0)))
        windowTemplate.content:add(resizeHandle(
            'resizeRight',
            'right',
            'hresize',
            v2(1, 0),
            v2(-resizeHandleSize, 0),
            v2(0, 1),
            v2(resizeHandleSize, 0)))
        windowTemplate.content:add(resizeHandle(
            'resizeTopLeft',
            'top-left',
            'dresize',
            v2(0, 0),
            v2(0, 0),
            v2(0, 0),
            v2(resizeHandleSize, resizeHandleSize)))
        windowTemplate.content:add(resizeHandle(
            'resizeTopRight',
            'top-right',
            'dresize2',
            v2(1, 0),
            v2(-resizeHandleSize, 0),
            v2(0, 0),
            v2(resizeHandleSize, resizeHandleSize)))
        windowTemplate.content:add(resizeHandle(
            'resizeBottomLeft',
            'bottom-left',
            'dresize2',
            v2(0, 1),
            v2(0, -resizeHandleSize),
            v2(0, 0),
            v2(resizeHandleSize, resizeHandleSize)))
        windowTemplate.content:add(resizeHandle(
            'resizeBottomRight',
            'bottom-right',
            'dresize',
            v2(1, 1),
            v2(-resizeHandleSize, -resizeHandleSize),
            v2(0, 0),
            v2(resizeHandleSize, resizeHandleSize)))
    end

    self.layoutElement = ui.create {
        layer = 'Windows',
        template = windowTemplate,
        props = {
            position = layoutPos,
            size = layoutSize,
        },
        userData = {
            dragging = false,
            dragStartAbs = nil,
            dragStartPos = nil,
            resizingEdge = nil,
            resizeStartAbs = nil,
            resizeStartPos = nil,
            resizeStartSize = nil,
        },
        content = ui.content {
            {
                type = ui.TYPE.Image,
                props = {
                    resource = ui.texture { path = 'white' },
                    color = Templates.colors.background,
                    alpha = 0.65,
                    relativeSize = v2(1, 1),
                },
            },
            layoutHighlight(config.window, 'windowBackground'),
            {
                name = 'windowContent',
                type = ui.TYPE.Flex,
                props = {
                    horizontal = panelHorizontal(config.window),
                    position = v2(LAYOUT_PADDING, LAYOUT_PADDING) + panelContentOffset(config.window, true),
                    size = windowInnerSize,
                    autoSize = false,
                },
                content = (function()
                    local content = ui.content {}
                    for _, childName in ipairs(config.window.children or {}) do
                        local childLayout = renderPanel(childName)
                        if childLayout then
                            content:add(childLayout)
                        end
                    end
                    return content
                end)(),
            },
            layoutScrollbar(config.window, panelScrollbarSize(config.window)),
        },
        events = {
            mousePress = async:callback(function(e, layout)
                if not self:settings().allowWindowDrag
                    or e.button ~= 1
                    or e.offset.y > panelLayoutSize(headerPanel).y then
                    return true
                end
                layout.userData.dragging = true
                layout.userData.dragStartAbs = e.position
                layout.userData.dragStartPos = layout.props.position
                self.suppressBoundsPersist = false
                ambient.playSound('menu click')
                return true
            end),
            mouseMove = async:callback(function(e, layout)
                if layout.userData.resizingEdge then
                    return updateResize(e, layout)
                end
                if not self:settings().allowWindowDrag
                    or not layout.userData.dragging
                    or not layout.userData.dragStartAbs
                    or not layout.userData.dragStartPos then
                    return true
                end

                local dragLayerSize = ui.layers[ui.layers.indexOf('Windows')].size
                local delta = e.position - layout.userData.dragStartAbs
                layout.props.position = v2(
                    util.clamp(layout.userData.dragStartPos.x + delta.x, 0, dragLayerSize.x - layout.props.size.x),
                    util.clamp(layout.userData.dragStartPos.y + delta.y, 0, dragLayerSize.y - layout.props.size.y))
                self.layoutPosition = layout.props.position
                self.position = self.layoutPosition
                self.layoutElement:update()
                return true
            end),
            mouseRelease = async:callback(function(e, layout)
                if e.button ~= 1 then
                    return true
                end
                layout.userData.dragging = false
                layout.userData.dragStartAbs = nil
                layout.userData.dragStartPos = nil
                stopResize(layout)
                if not self.suppressBoundsPersist then
                    self.layoutPosition = layout.props.position
                    self.position = self.layoutPosition
                end
                self:persistBounds(layout.props.position, layout.props.size)
                return true
            end),
            focusLoss = async:callback(function(_, layout)
                layout.userData.dragging = false
                layout.userData.dragStartAbs = nil
                layout.userData.dragStartPos = nil
                stopResize(layout)
                if not self.suppressBoundsPersist then
                    self.layoutPosition = layout.props.position
                    self.position = self.layoutPosition
                end
                self:persistBounds(layout.props.position, layout.props.size)
                return true
            end),
        },
    }
    self.layoutScrollable = findNamed(self.layoutElement.layout, 'list', {}) or nil
    local viewport = self.layoutScrollable and contentByName(self.layoutScrollable.content, 'viewport') or nil
    if self.layoutScrollable then
        self.layoutScrollable.userData = self.layoutScrollable.userData or {}
        self.layoutScrollable.userData.scrollStep = listScrollData.scrollStep
        self.layoutScrollable.userData.scrollBy = function(_, delta)
            listScrollData.scrollBy(-delta)
        end
        self.layoutScrollable.userData.getScrollPos = function()
            return self.layoutScrollPos or 0
        end
    end
    self.layoutListRows = viewport and contentByName(viewport.content, 'rows') or nil
    self.layoutScrollbarLayout = self.layoutScrollable
        and contentByName(self.layoutScrollable.content, 'scrollbar')
        or nil
    listScrollData.sync = function()
        if not self.layoutScrollbarLayout
            or not self.layoutScrollbarLayout.content
            or not contentByName(self.layoutScrollbarLayout.content, 'track') then
            return
        end
        local track = contentByName(self.layoutScrollbarLayout.content, 'track')
        local handle = track and contentByName(track.content, 'handle') or nil
        if not handle then
            return
        end
        self.layoutScrollbarLayout.props.visible = listScrollData.scrollLimit > 0
        local travel = math.max(0, track.props.size.y - handle.props.size.y - 4)
        local progress = listScrollData.scrollLimit > 0
            and ((self.layoutScrollPos or 0) / listScrollData.scrollLimit)
            or 0
        handle.props.position = v2(0, travel * progress)
    end
    listScrollData.sync()
end

function Window:new(ctx)
    return setmetatable({
        ctx = ctx,
        layoutElement = nil,
        layoutPosition = nil,
        pendingWindowSize = nil,
        merchant = nil,
        position = nil,
        layoutScrollable = nil,
        layoutListRows = nil,
        layoutScrollbarLayout = nil,
        layoutScrollPos = 0,
        rows = {},
        filteredRows = {},
        searchText = '',
        tooltipElement = nil,
        tooltipRow = nil,
        seenHoverSpellId = nil,
        seenHoverStartedAt = nil,
        seenHoverRow = nil,
        seenHoverLayout = nil,
        seenHoverGp = nil,
        confirmationElement = nil,
        confirmationHoveredButton = nil,
        extraKnownSpellIds = {},
        sortOverride = nil,
        layoutConfig = nil,
        pendingRefresh = false,
        suppressBoundsPersist = false,
    }, self)
end

function Window:settings()
    local settings
    if self.ctx and self.ctx.getSettings then
        settings = self.ctx.getSettings()
    else
        settings = {
            enableMod = true,
            showIcons = true,
            highlightUnknownSpells = true,
            highlightUnknownSpellColor = gmstColor('FontColor_color_link', util.color.rgb(0.45, 0.55, 1)),
            markNewSpells = false,
            newSpellSeenDelay = 0.5,
            seenSpellIds = {},
            allowWindowDrag = true,
            allowWindowResize = true,
            confirmPurchase = false,
            sortField = 'name',
            sortAscending = true,
        }
    end
    if self.sortOverride then
        settings.sortField = self.sortOverride.sortField
        settings.sortAscending = self.sortOverride.sortAscending
    end
    settings.sortField = sortField(settings)
    return settings
end

function Window:persistBounds(position, size)
    if self.suppressBoundsPersist then
        return
    end
    if self.ctx and self.ctx.setWindowBounds then
        self.ctx.setWindowBounds(position, size)
    elseif self.ctx and self.ctx.setWindowPosition then
        self.ctx.setWindowPosition(position)
    end
end

function Window:destroy()
    self:hideTooltip()
    self:hidePurchaseConfirmation()
    self:clearSeenHoverCandidate()
    if self.layoutElement then
        if not self.suppressBoundsPersist
            and self.layoutElement.layout
            and self.layoutElement.layout.props then
            self.layoutPosition = self.layoutElement.layout.props.position
            self.position = self.layoutPosition
            self:persistBounds(self.layoutPosition, self.layoutElement.layout.props.size)
        end
        auxUi.deepDestroy(self.layoutElement)
        self.layoutElement = nil
        self.suppressBoundsPersist = false
    end
    self.ctx.focusedScrollable = nil
    self.layoutScrollable = nil
    self.layoutListRows = nil
    self.layoutScrollbarLayout = nil
    self.rows = {}
    self.filteredRows = {}
end

function Window:isOpen()
    return self.layoutElement ~= nil
end

function Window:show(merchant)
    self.merchant = merchant
    self.layoutScrollPos = 0
    self.searchText = ''
    self.extraKnownSpellIds = {}
    self.pendingRefresh = false
    self:refresh()
end

function Window:hide()
    self:destroy()
    self.merchant = nil
    self.pendingRefresh = false
end

function Window:refresh()
    if not self.merchant or not self.merchant:isValid() then
        self:hide()
        return
    end

    self:destroy()

    local settings = self:settings()
    local rows = buildRows(self.merchant, self.extraKnownSpellIds, settings)
    self.rows = rows
    self.rowCount = #rows
    local gold = types.Actor.inventory(playerSelf):countOf('gold_001')
    local gp = Templates.gmst('sgp', 'gp')
    local highlightColors = unknownSpellColors(settings.highlightUnknownSpellColor)

    local layerSize = ui.layers[ui.layers.indexOf('Windows')].size
    local savedPosition = settings.windowPosition
    local configuredPosition = savedPosition and v2(savedPosition.x or 0, savedPosition.y or 0) or nil
    local position = self.position or configuredPosition or v2(
        math.max(0, (layerSize.x - LAYOUT_WINDOW_SIZE.x) / 2),
        math.max(0, (layerSize.y - LAYOUT_WINDOW_SIZE.y) / 2))
    self:createLayoutWindow(rows, gold, gp, settings, highlightColors, position, layerSize)
end

function Window:buySpell(row)
    if not row or not row.spell then
        return
    end
    core.sendGlobalEvent('SpellTrader_BuySpell', {
        merchant = self.merchant,
        spellId = idText(row.spell.id),
        expectedPrice = row.price,
    })
end

function Window:buyOrConfirm(row)
    if self:settings().confirmPurchase then
        self:showPurchaseConfirmation(row)
    else
        self:buySpell(row)
    end
end

function Window:hidePurchaseConfirmation()
    if self.confirmationElement then
        auxUi.deepDestroy(self.confirmationElement)
        self.confirmationElement = nil
    end
    self.confirmationHoveredButton = nil
end

function Window:showPurchaseConfirmation(row)
    if not row or not row.spell then
        return
    end
    self:hideTooltip()
    self:hidePurchaseConfirmation()

    local effects = row.spell.effects or {}
    local effectLayouts = {}
    for index, params in ipairs(effects) do
        if index > 1 then
            effectLayouts[#effectLayouts + 1] = { props = { size = v2(0, 4) } }
        end
        effectLayouts[#effectLayouts + 1] = {
            type = ui.TYPE.Flex,
            props = {
                horizontal = true,
                arrange = ui.ALIGNMENT.Center,
            },
            content = ui.content {
                Templates.effectIcon(effectId(params), ROW_ICON_SIZE),
                { props = { size = v2(6, 1) } },
                Templates.text(spellEffectText(params)),
            },
        }
    end

    local layerSize = ui.layers[ui.layers.indexOf('Windows')].size
    local question = l10n('PurchaseConfirmationQuestion', { spellName = row.spell.name })
    local updateConfirmation = function()
        if self.confirmationElement then
            self.confirmationElement:update()
        end
    end
    local updateConfirmationHover = function(layout, hovered)
        if hovered then
            if self.confirmationHoveredButton
                and self.confirmationHoveredButton ~= layout
                and self.confirmationHoveredButton.content
                and self.confirmationHoveredButton.content.label then
                self.confirmationHoveredButton.content.label.props.textColor = Templates.colors.normal
            end
            self.confirmationHoveredButton = layout
        elseif self.confirmationHoveredButton == layout then
            self.confirmationHoveredButton = nil
        end
    end
    local buttonOptions = {
        hoverColor = Templates.colors.header,
        update = updateConfirmation,
        onHover = updateConfirmationHover,
    }
    local yesButton = Templates.button(l10n('Yes'), CONFIRMATION_BUTTON_SIZE, function()
        self:hidePurchaseConfirmation()
        self:buySpell(row)
    end, buttonOptions)
    local noButton = Templates.button(l10n('No'), CONFIRMATION_BUTTON_SIZE, function()
        self:hidePurchaseConfirmation()
    end, buttonOptions)

    local dialog = Templates.tooltip(8, ui.content {
        {
            type = ui.TYPE.Flex,
            props = {
                align = ui.ALIGNMENT.Center,
                arrange = ui.ALIGNMENT.Center,
            },
            content = ui.content {
                {
                    template = I.MWUI.templates.textHeader,
                    props = {
                        text = question,
                        textAlignH = ui.ALIGNMENT.Center,
                        textAlignV = ui.ALIGNMENT.Center,
                    },
                },
                { props = { size = v2(0, 8) } },
                {
                    type = ui.TYPE.Flex,
                    props = {
                        arrange = ui.ALIGNMENT.Start,
                    },
                    content = ui.content(effectLayouts),
                },
                { props = { size = v2(0, 12) } },
                {
                    type = ui.TYPE.Flex,
                    props = {
                        horizontal = true,
                        arrange = ui.ALIGNMENT.Center,
                    },
                    content = ui.content {
                        yesButton,
                        { props = { size = v2(14, 1) } },
                        noButton,
                    },
                },
            },
        },
    }, 'SpellTrader_purchase_confirmation')
    dialog.layer = 'Windows'
    dialog.props = {
        anchor = v2(0.5, 0.5),
        position = v2(layerSize.x / 2, layerSize.y / 2),
    }

    self.confirmationElement = ui.create(dialog)
end

function Window:onPurchaseFinished(data)
    if data and data.success and data.spellId then
        self.extraKnownSpellIds[idText(data.spellId)] = true
    end
    if self:isOpen() then
        self:refresh()
    end
end

function Window:hideTooltip()
    if self.tooltipElement then
        auxUi.deepDestroy(self.tooltipElement)
        self.tooltipElement = nil
    end
    self.tooltipRow = nil
end

function Window:moveTooltip(position)
    if not self.tooltipElement or not position then
        return
    end

    local layerSize = ui.layers[ui.layers.indexOf('Notification')].size
    self.tooltipElement.layout.props = self.tooltipElement.layout.props or {}
    local distToBottom = layerSize.y - position.y
    if distToBottom < 360 then
        self.tooltipElement.layout.props.anchor = v2(position.x / layerSize.x, 1)
        self.tooltipElement.layout.props.position = v2(position.x, position.y - TOOLTIP_CURSOR_OFFSET)
    else
        self.tooltipElement.layout.props.anchor = v2(position.x / layerSize.x, 0)
        self.tooltipElement.layout.props.position = v2(position.x, position.y + TOOLTIP_CURSOR_OFFSET)
    end
    self.tooltipElement:update()
end

function Window:showTooltipForRow(rowIndex, position)
    if not rowIndex then
        self:hideTooltip()
        return
    end

    local row = self.filteredRows and self.filteredRows[rowIndex] or nil
    if not row or not row.spell then
        self:hideTooltip()
        return
    end

    if self.tooltipRow ~= rowIndex then
        self:hideTooltip()
        self.tooltipElement = ui.create(spellTooltip(row.spell, row.price))
        self.tooltipRow = rowIndex
    end
    self:moveTooltip(position)
end

function Window:onMouseWheel(vertical)
    if not self:isOpen() then
        return
    end
    self:hideTooltip()
    self:clearSeenHoverCandidate()
    local layout = self.ctx.focusedScrollable
        or (self.layoutElement and self.layoutScrollable)
    if not layout or not layout.userData or not layout.userData.scrollBy then
        return
    end
    layout.userData.scrollBy(layout, vertical * (layout.userData.scrollStep or ROW_HEIGHT))
    if layout == self.layoutScrollable and self.layoutElement then
        self.layoutElement:update()
    end
end

function Window:onFrame()
    if self.pendingRefresh and self:isOpen() then
        self.pendingRefresh = false
        self:refresh()
    end
    if self.seenHoverSpellId and self.seenHoverStartedAt then
        local settings = self:settings()
        if settings.markNewSpells
            and core.getRealTime() - self.seenHoverStartedAt >= settings.newSpellSeenDelay then
            self:markRowSeen(self.seenHoverRow, self.seenHoverLayout, self.seenHoverGp)
        elseif not settings.markNewSpells then
            self:clearSeenHoverCandidate()
        end
    end
    if self.merchant and (not self.merchant:isValid()
        or not types.Actor.objectIsInstance(self.merchant)
        or types.Actor.isDead(self.merchant)) then
        I.UI.removeMode('SpellBuying')
    end
end

return Window
