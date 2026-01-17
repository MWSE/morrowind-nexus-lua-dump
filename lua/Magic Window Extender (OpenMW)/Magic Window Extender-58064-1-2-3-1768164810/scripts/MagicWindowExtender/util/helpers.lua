local core = require('openmw.core')
local util = require('openmw.util')
local self = require('openmw.self')
local debug = require('openmw.debug')
local I = require('openmw.interfaces')

local C = require('scripts.MagicWindowExtender.util.constants')

local Helpers = {}

Helpers.shallowCopy = function(tbl)
    if type(tbl) ~= 'table' then return tbl end
    local copy = {}
    for k, v in pairs(tbl) do
        copy[k] = v
    end
    return copy
end

Helpers.deepCopy = function(tbl)
    if type(tbl) ~= 'table' then return tbl end
    local copy = {}
    for k, v in pairs(tbl) do
        if type(v) == 'table' then
            copy[k] = Helpers.deepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

Helpers.deepPrint = function(tbl, indent)
    if type(tbl) ~= 'table' then return tostring(tbl) end
    indent = indent or 0
    local toprint = string.rep(" ", indent) .. "{\n"
    indent = indent + 2 
    for k, v in pairs(tbl) do
        toprint = toprint .. string.rep(" ", indent)
        if (type(k) == "number") then
            toprint = toprint .. "[" .. k .. "] = "
        elseif (type(k) == "string") then
            toprint = toprint  .. k ..  " = "   
        end
        if (type(v) == "number") then
            toprint = toprint .. v .. ",\n"
        elseif (type(v) == "string") then
            toprint = toprint .. "\"" .. v .. "\",\n"
        elseif (type(v) == "table") then
            toprint = toprint .. Helpers.deepPrint(v, indent + 2) .. ",\n"
        else
            toprint = toprint .. "\"" .. tostring(v) .. "\",\n"
        end
    end
    toprint = toprint .. string.rep(" ", indent-2) .. "}"
    return toprint
end

Helpers.uiDeepPrint = function(layoutOrElement, lvl)
    lvl = lvl or 0
    local isElement = type(layoutOrElement) == 'userdata'
    local layout = isElement and layoutOrElement.layout or layoutOrElement
    if layout.name then
        print(string.rep('-', lvl), layoutOrElement, layout.name)
    end
    if layout.userData then
        print(string.rep(' ', lvl), 'UserData:', Helpers.deepPrint(layout.userData))
    end
    if layout.content then
        for _, child in pairs(layout.content) do
            Helpers.uiDeepPrint(child, lvl + 1)
        end
    end
end

Helpers.forEachInLayout = function(layoutOrElement, func)
    local isElement = type(layoutOrElement) == 'userdata'
    local layout = isElement and layoutOrElement.layout or layoutOrElement
    func(layout)
    if layout.content then
        for _, child in pairs(layout.content) do
            Helpers.forEachInLayout(child, func)
        end
    end
end

Helpers.findInLayout = function(layoutOrElement, predicate)
    local isElement = type(layoutOrElement) == 'userdata'
    local layout = isElement and layoutOrElement.layout or layoutOrElement
    if predicate(layout) then
        return layout
    end
    if layout.content then
        for _, child in pairs(layout.content) do
            local result = Helpers.findInLayout(child, predicate)
            if result then
                return result
            end
        end
    end
    return nil
end

-- Checks if two tables contain the same elements (ignoring order)
Helpers.tableEquals = function(t1, t2)
    if (type(t1) ~= "table" and type(t1) ~= "userdata") or (type(t2) ~= "table" and type(t2) ~= "userdata") then
        return t1 == t2
    end
    if t1.id and t2.id then
        local sameCount = true
        if t1.count and t2.count then
            sameCount = t1.count == t2.count
        end
        return t1.id == t2.id and sameCount
    end
    local t1Keys = {}
    local t2Keys = {}
    for k in pairs(t1) do table.insert(t1Keys, k) end
    for k in pairs(t2) do table.insert(t2Keys, k) end
    table.sort(t1Keys)
    table.sort(t2Keys)
    if #t1Keys ~= #t2Keys then return false end
    for i = 1, #t1Keys do
        if t1Keys[i] ~= t2Keys[i] then return false end
        if not Helpers.tableEquals(t1[t1Keys[i]], t2[t2Keys[i]]) then return false end
    end
    return true
end

Helpers.mapEquals = function(m1, m2)
    for k, v in pairs(m1) do
        if type(v) == 'table' and type(m2[k]) == 'table' then
            if not Helpers.mapEquals(v, m2[k]) then
                return false
            end
        else
            if m2[k] ~= v then
                return false
            end
        end
    end
    for k, v in pairs(m2) do
        if type(v) == 'table' and type(m1[k]) == 'table' then
            if not Helpers.mapEquals(v, m1[k]) then
                return false
            end
        else
            if m1[k] ~= v then
                return false
            end
        end
    end
    return true
end

Helpers.mergeTables = function(t1, t2)
    local merged = Helpers.shallowCopy(t1)
    for k, v in pairs(t2) do
        merged[k] = v
    end
    return merged
end

Helpers.roundToPlaces = function(num, places)
    local mult = 10^(places or 0)
    return math.floor(num * mult + 0.5) / mult
end

local magicka = self.type.stats.dynamic.magicka(self)
local willpower = self.type.stats.attributes.willpower(self)
local luck = self.type.stats.attributes.luck(self)

local FATIGUE_BASE = core.getGMST('fFatigueBase')
local FATIGUE_MULT = core.getGMST('fFatigueMult')
local FATIGUE_STAT = self.type.stats.dynamic.fatigue(self)
Helpers.getFatigueTerm = function()
    local normalizedFatigue
    if FATIGUE_STAT.base == 0 then
        normalizedFatigue = 1
    else
        normalizedFatigue = math.max(0, FATIGUE_STAT.current / FATIGUE_STAT.base)
    end

    return FATIGUE_BASE - FATIGUE_MULT * (1 - normalizedFatigue)
end

local chargeMult = {
    [core.magic.ENCHANTMENT_TYPE.CastOnStrike] = core.getGMST('iMagicItemChargeStrike'),
    [core.magic.ENCHANTMENT_TYPE.CastOnUse] = core.getGMST('iMagicItemChargeUse'),
    [core.magic.ENCHANTMENT_TYPE.CastOnce] = core.getGMST('iMagicItemChargeOnce'),
    [core.magic.ENCHANTMENT_TYPE.ConstantEffect] = core.getGMST('iMagicItemChargeConst'),
}

Helpers.getEnchantMaxCharge = function(enchantment)
    local cost = math.floor(Helpers.getBaseSpellCost(enchantment.id, true) + 0.5)
    return cost * chargeMult[enchantment.type]
end

Helpers.getBaseSpellCost = function(spellId, isEnchant)
    local cost = 0

    local spellRecord
    if isEnchant then
        spellRecord = core.magic.enchantments.records[spellId]
    else
        spellRecord = core.magic.spells.records[spellId]
    end
    if not spellRecord then return cost end

    if not spellRecord.autocalcFlag then
        return spellRecord.cost
    end

    for _, effect in ipairs(spellRecord.effects) do
        local minMagnitude, maxMagnitude = 1, 1
        local baseEffect = effect.effect

        if baseEffect.hasMagnitude then
            minMagnitude = effect.magnitudeMin
            maxMagnitude = effect.magnitudeMax
        end
        if not isEnchant then
            minMagnitude = math.max(1, minMagnitude)
            maxMagnitude = math.max(1, maxMagnitude)
        end

        local x = baseEffect.hasDuration and effect.duration or 1
        if not baseEffect.isAppliedOnce then
            x = math.max(x, 1)
        end
        x = x * 0.1 * baseEffect.baseCost
        x = x * 0.5 * (effect.magnitudeMin + effect.magnitudeMax)
        x = x + 0.05 * baseEffect.baseCost * effect.area
        if effect.range == core.magic.RANGE.Target then
            x = x * 1.5
        end
        x = x * core.getGMST('fEffectCostMult')
        x = math.max(0, x)

        cost = cost + x
    end

    return cost
end

Helpers.getModifiedSpellCost = function(spellId, isEnchant)
    local baseCost = Helpers.getBaseSpellCost(spellId, isEnchant)

    local cost = baseCost

    if isEnchant then
        local x = 0.01 * (110 - self.type.stats.skills.enchant(self).modified)
        cost = math.floor(x * cost)
        cost = math.max(cost, 1)
    end

    return cost
end

Helpers.getSpellCastChance = function(spellId)
    local spellRecord = core.magic.spells.records[spellId]
    if not spellRecord then return 0 end

    if debug.isGodMode() then
        return 100
    end

    local activeEffects = self.type.activeEffects(self)
    if activeEffects:getEffect(core.magic.EFFECT_TYPE.Silence).magnitude > 0 then 
        return 0
    end

    if not (spellRecord.type == core.magic.SPELL_TYPE.Spell or spellRecord.type == core.magic.SPELL_TYPE.Power) then
        return 100
    end

    if spellRecord.type == core.magic.SPELL_TYPE.Power then
        return self.type.spells(self):canUsePower(spellId) and 100 or 0 -- Powers can always be used if not on cooldown
    end

    if spellRecord.type == core.magic.SPELL_TYPE.Spell then
        local cost = 0

        local y = math.huge
        local lowestSkill = 0
        local effectiveSchool
        for _, effect in ipairs(spellRecord.effects) do
            local baseEffect = effect.effect
            local x = baseEffect.hasDuration and effect.duration or 1
            if not baseEffect.isAppliedOnce then
                x = math.max(x, 1)
            end
            x = x * 0.1 * baseEffect.baseCost
            x = x * 0.5 * (effect.magnitudeMin + effect.magnitudeMax)
            x = x + 0.05 * baseEffect.baseCost * effect.area
            if effect.range == core.magic.RANGE.Target then
                x = x * 1.5
            end
            x = x * core.getGMST('fEffectCostMult')

            cost = cost + x

            local s = 2 * self.type.stats.skills[baseEffect.school](self).modified
            if (s - x) < y then
                y = s - x
                effectiveSchool = baseEffect.school
                lowestSkill = s
            end
        end

        if not spellRecord.autocalcFlag then
            cost = spellRecord.cost
        end

        if spellRecord.alwaysSucceedFlag then
            return 100, effectiveSchool
        end

        if magicka.current < cost then
            return 0, effectiveSchool
        end

        local castBonus = -activeEffects:getEffect(core.magic.EFFECT_TYPE.Sound).magnitude
        local castChance = (lowestSkill - util.round(cost) + castBonus + 0.2 * willpower.modified + 0.1 * luck.modified) * Helpers.getFatigueTerm()

        return math.floor(util.clamp(castChance, 0.0, 100.0)), effectiveSchool
    end
end

local magnitudeMap = {
    [C.Magic.MagnitudeDisplayType.TIMES_INT] = {
        fortifymaximummagicka = true,
    },
    [C.Magic.MagnitudeDisplayType.FEET] = {
        telekinesis = true,
        detectanimal = true,
        detectenchantment = true,
        detectkey = true,
    },
    [C.Magic.MagnitudeDisplayType.LEVEL] = {
        commandcreature = true,
        commandhumanoid = true,
    },
    [C.Magic.MagnitudeDisplayType.PERCENTAGE] = {
        chameleon = true,
        blind = true,
        dispel = true,
        reflect = true,
    },
}

Helpers.getEffectMagnitudeDisplayType = function(effect)
    if (not effect.maxMagnitude or not effect.minMagnitude) and not effect.hasMagnitude then
        return C.Magic.MagnitudeDisplayType.NONE
    end
    if magnitudeMap[C.Magic.MagnitudeDisplayType.TIMES_INT][effect.id] then
        return C.Magic.MagnitudeDisplayType.TIMES_INT
    end
    if magnitudeMap[C.Magic.MagnitudeDisplayType.FEET][effect.id] then
        return C.Magic.MagnitudeDisplayType.FEET
    end
    if magnitudeMap[C.Magic.MagnitudeDisplayType.LEVEL][effect.id] then
        return C.Magic.MagnitudeDisplayType.LEVEL
    end
    if magnitudeMap[C.Magic.MagnitudeDisplayType.PERCENTAGE][effect.id] or
        effect.id:find('^weakness') or 
        effect.id:find('^resist') then
        return C.Magic.MagnitudeDisplayType.PERCENTAGE
    end
    return C.Magic.MagnitudeDisplayType.POINTS
end

Helpers.createDurationString = function(duration)
    local l10n = core.l10n('Interface')

    local string = ''

    if duration < 1.0 then
        string = string .. l10n('DurationSecond', { seconds = 0 })
        return string
    end

    local secondsPerMinute = 60
    local secondsPerHour = secondsPerMinute * 60
    local secondsPerDay = secondsPerHour * 24
    local secondsPerMonth = secondsPerDay * 30
    local secondsPerYear = secondsPerDay * 365

    local fullDuration = math.floor(duration)
    local units = 0
    local years = math.floor(fullDuration / secondsPerYear)
    local months = math.floor((fullDuration % secondsPerYear) / secondsPerMonth)
    local days = math.floor((fullDuration % secondsPerYear % secondsPerMonth) / secondsPerDay)
    local hours = math.floor((fullDuration % secondsPerDay) / secondsPerHour)
    local minutes = math.floor((fullDuration % secondsPerHour) / secondsPerMinute)
    local seconds = fullDuration % secondsPerMinute

    if years > 0 then
        units = units + 1
        string = string .. l10n('DurationYear', { years = years })
    end
    if months > 0 then
        units = units + 1
        string = string .. l10n('DurationMonth', { months = months })
    end
    if units < 2 and days > 0 then
        units = units + 1
        string = string .. l10n('DurationDay', { days = days })
    end
    if units < 2 and hours > 0 then
        units = units + 1
        string = string .. l10n('DurationHour', { hours = hours })
    end
    if units >= 2 then
        return string
    end
    if minutes > 0 then
        string = string .. l10n('DurationMinute', { minutes = minutes })
    end
    if seconds > 0 then
        string = string .. l10n('DurationSecond', { seconds = seconds })
    end

    return string
end

Helpers.createActiveEffectString = function(activeSpellEffect, spellName)
    local string = spellName or ''
    if activeSpellEffect.affectedSkill then
        string = string .. ' (' .. core.stats.Skill.records[activeSpellEffect.affectedSkill].name .. ')' 
    end
    if activeSpellEffect.affectedAttribute then
        string = string .. ' (' .. core.stats.Attribute.records[activeSpellEffect.affectedAttribute].name .. ')' 
    end

    local magnitudeType = Helpers.getEffectMagnitudeDisplayType(activeSpellEffect)
    if magnitudeType == C.Magic.MagnitudeDisplayType.TIMES_INT then
        string = string .. ' ' .. Helpers.roundToPlaces(activeSpellEffect.magnitudeThisFrame / 10.0, 1) .. C.Strings.X_TIMES_INT
    elseif magnitudeType ~= C.Magic.MagnitudeDisplayType.NONE then
        string = string .. ': ' .. tostring(math.floor(activeSpellEffect.magnitudeThisFrame))
        if magnitudeType == C.Magic.MagnitudeDisplayType.PERCENTAGE then
            string = string .. C.Strings.PERCENT
        elseif magnitudeType == C.Magic.MagnitudeDisplayType.FEET then
            string = string .. ' ' .. C.Strings.FEET
        elseif magnitudeType == C.Magic.MagnitudeDisplayType.LEVEL then
            string = string .. ' '
            if activeSpellEffect.magnitudeThisFrame > 1 then
                string = string .. C.Strings.LEVELS
            else
                string = string .. C.Strings.LEVEL
            end
        else
            string = string .. ' '
            if activeSpellEffect.magnitudeThisFrame > 1 then
                string = string .. C.Strings.POINTS
            else
                string = string .. C.Strings.POINT
            end
        end
    end

    if activeSpellEffect.durationLeft and activeSpellEffect.durationLeft > 0 then
        string = string .. ' ' .. C.Strings.DURATION .. ': ' .. Helpers.createDurationString(activeSpellEffect.durationLeft)
    end

    return string
end

local function getMagicEffectString(effectParams, attributeId, skillId)
    local effect = core.magic.effects.records[effectParams.id]
    if not effect then
        effect = I.MagicWindow.Spells.getCustomEffect(effectParams.id)
        if not effect then
            return ''
        end
    end

    local targetsSkill = effectParams.affectedSkill and skillId
    local targetsAttribute = effectParams.affectedAttribute and attributeId

    local string

    local TYPE = core.magic.EFFECT_TYPE
    if (targetsSkill or targetsAttribute) then
        if effect.id == TYPE.AbsorbAttribute or effect.id == TYPE.AbsorbSkill then
            string = C.Strings.ABSORB
        elseif effect.id == TYPE.DamageAttribute or effect.id == TYPE.DamageSkill then
            string = C.Strings.DAMAGE
        elseif effect.id == TYPE.DrainAttribute or effect.id == TYPE.DrainSkill then
            string = C.Strings.DRAIN
        elseif effect.id == TYPE.FortifyAttribute or effect.id == TYPE.FortifySkill then
            string = C.Strings.FORTIFY
        elseif effect.id == TYPE.RestoreAttribute or effect.id == TYPE.RestoreSkill then
            string = C.Strings.RESTORE
        end
    end

    if not string then
        string = effect.name
    end

    if targetsSkill then
        local skill = core.stats.Skill.records[skillId]
        string = string .. ' ' .. skill.name
    elseif targetsAttribute then
        local attribute = core.stats.Attribute.records[attributeId]
        string = string .. ' ' .. attribute.name
    end

    return string
end

Helpers.effectListContainsString = function(effectsWithParams, searchString)
    for _, effectParams in ipairs(effectsWithParams) do
        local string = getMagicEffectString(effectParams, effectParams.affectedAttribute, effectParams.affectedSkill)
        if string:lower():find(searchString:lower(), 1, true) then
            return true
        end
    end
    return false
end

Helpers.effectListContainsSchool = function(effectsWithParams, schoolFilter)
    for _, effectParams in ipairs(effectsWithParams) do
        local effect = effectParams.effect
        if effect and effect.school and effect.school:lower() == schoolFilter:lower() then
            return true
        end
    end
    return false
end

Helpers.createSpellEffectString = function(effectParams, isConstant)
    local effect = core.magic.effects.records[effectParams.id]
    local isCustom = false
    if not effect then
        effect = I.MagicWindow.Spells.getCustomEffect(effectParams.id)
        if not effect then
            return ''
        end
        isCustom = true
    end
    
    local string = getMagicEffectString(effectParams, effectParams.affectedAttribute, effectParams.affectedSkill)

    if (effectParams.magnitudeMin or effectParams.magnitudeMax) and effect.hasMagnitude then
        local magnitudeType
        if isCustom then
            magnitudeType = effect.magnitudeType
        else
            magnitudeType = Helpers.getEffectMagnitudeDisplayType(effect)
        end

        if magnitudeType == C.Magic.MagnitudeDisplayType.TIMES_INT then
            string = string .. ' ' .. Helpers.roundToPlaces(effectParams.magnitudeMin / 10.0, 1)
            if effectParams.magnitudeMin ~= effectParams.magnitudeMax then
                string = string .. ' ' .. C.Strings.TO .. ' ' .. Helpers.roundToPlaces(effectParams.magnitudeMax / 10.0, 1)
            end
            string = string .. C.Strings.X_TIMES_INT
        elseif magnitudeType ~= C.Magic.MagnitudeDisplayType.NONE then
            string = string .. ' ' .. tostring(effectParams.magnitudeMin)
            if effectParams.magnitudeMin ~= effectParams.magnitudeMax then
                string = string .. ' ' .. C.Strings.TO .. ' ' .. tostring(effectParams.magnitudeMax)
            end

            if magnitudeType == C.Magic.MagnitudeDisplayType.PERCENTAGE then
                string = string .. C.Strings.PERCENT
            elseif magnitudeType == C.Magic.MagnitudeDisplayType.FEET then
                string = string .. ' ' .. C.Strings.FEET
            elseif magnitudeType == C.Magic.MagnitudeDisplayType.LEVEL then
                string = string .. ' '
                if effectParams.magnitudeMin == effectParams.magnitudeMax and math.abs(effectParams.magnitudeMin) == 1 then
                    string = string .. C.Strings.LEVEL
                else
                    string = string .. C.Strings.LEVELS
                end
            else -- POINTS
                string = string .. ' '
                if effectParams.magnitudeMin == effectParams.magnitudeMax and math.abs(effectParams.magnitudeMin) == 1 then
                    string = string .. C.Strings.POINT
                else
                    string = string .. C.Strings.POINTS
                end
            end
        end
    end

    if not isConstant then
        local duration = effectParams.duration or 0

        if not effect.isAppliedOnce then
            duration = math.max(1, duration)
        end

        if duration > 0 and effect.hasDuration then
            string = string .. ' ' .. C.Strings.FOR .. ' ' .. tostring(duration) .. ' '
            if duration == 1 then
                string = string .. C.Strings.SECOND
            else
                string = string .. C.Strings.SECONDS
            end
        end

        if effectParams.area > 0 then
            string = string .. ' ' .. C.Strings.IN .. ' ' .. tostring(effectParams.area) .. ' ' .. C.Strings.FOOT_AREA
        end

        string = string .. ' ' .. C.Strings.ON .. ' '
        if effectParams.range == core.magic.RANGE.Self then
            string = string .. C.Strings.RANGE_SELF
        elseif effectParams.range == core.magic.RANGE.Touch then
            string = string .. C.Strings.RANGE_TOUCH
        else
            string = string .. C.Strings.RANGE_TARGET
        end
    end

    return string
end

Helpers.getSpellListOrder = function()
    local powersSection = I.MagicWindow.getSection(C.DefaultSections.POWERS)
    local spellsSection = I.MagicWindow.getSection(C.DefaultSections.SPELLS)
    local magicItemsSection = I.MagicWindow.getSection(C.DefaultSections.MAGIC_ITEMS)
    local sections = {
        powersSection,
        spellsSection,
        magicItemsSection,
    }
    local pinned = I.MagicWindow.getStat(C.TrackedStats.PINNED) or {}
    local hidden = I.MagicWindow.getStat(C.TrackedStats.HIDDEN) or {}

    local list = {}
    local lookup = {}
    local i = 0
    -- For each section, sort by its sort type, with pinned items first and hidden items excluded
    for _, section in ipairs(sections) do
        local pinnedLines = {}
        local unpinnedLines = {}
        for _, line in ipairs(section.lines) do
            if not line.editInfo or not (hidden[line.editInfo.type] and hidden[line.editInfo.type][line.editInfo.id]) then
                if line.editInfo and pinned[line.editInfo.type] and pinned[line.editInfo.type][line.editInfo.id] then
                    table.insert(pinnedLines, line)
                else
                    table.insert(unpinnedLines, line)
                end
            end
        end

        local sortFn
        if section.sort == C.Sort.LABEL_ASC then
            sortFn = function(a, b) return a.label < b.label end
        elseif section.sort == C.Sort.LABEL_DESC then
            sortFn = function(a, b) return a.label > b.label end
        end

        if sortFn then
            table.sort(pinnedLines, sortFn)
            table.sort(unpinnedLines, sortFn)
        end

        for _, line in ipairs(pinnedLines) do
            i = i + 1
            lookup[line.id] = i
            table.insert(list, line.id)
        end
        for _, line in ipairs(unpinnedLines) do
            i = i + 1
            lookup[line.id] = i
            table.insert(list, line.id)
        end
    end

    return list, lookup
end

return Helpers