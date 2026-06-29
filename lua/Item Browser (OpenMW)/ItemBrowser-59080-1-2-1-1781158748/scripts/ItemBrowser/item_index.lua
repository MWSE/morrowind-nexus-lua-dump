local core = require('openmw.core')
local types = require('openmw.types')

local M = {}

local index
local byId

local function reverseLookup(enumTable)
    local lookup = {}
    for key, value in pairs(enumTable) do
        lookup[value] = key
    end
    return lookup
end

local subtypeNamesByTypeKey = {
    Weapon = reverseLookup(types.Weapon.TYPE),
    Armor = reverseLookup(types.Armor.TYPE),
    Clothing = reverseLookup(types.Clothing.TYPE),
}

local typeSources = {
    { typeKey = 'Weapon', setting = 'IncludeWeapons', records = types.Weapon.records },
    { typeKey = 'Armor', setting = 'IncludeArmor', records = types.Armor.records },
    { typeKey = 'Clothing', setting = 'IncludeClothing', records = types.Clothing.records },
    { typeKey = 'Potion', setting = 'IncludeAlchemy', records = types.Potion.records },
    { typeKey = 'Ingredient', setting = 'IncludeIngredients', records = types.Ingredient.records },
    { typeKey = 'Light', setting = 'IncludeLights', records = types.Light.records },
    { typeKey = 'Apparatus', setting = 'IncludeTools', records = types.Apparatus.records },
    { typeKey = 'Lockpick', setting = 'IncludeTools', records = types.Lockpick.records },
    { typeKey = 'Probe', setting = 'IncludeTools', records = types.Probe.records },
    { typeKey = 'Repair', setting = 'IncludeTools', records = types.Repair.records },
}

local function safeGet(record, key)
    local ok, value = pcall(function() return record[key] end)
    if ok and value ~= nil then
        return value
    end
    return nil
end

local function asString(value)
    if value == nil then
        return ''
    end
    return tostring(value)
end

local function maybeNumber(value)
    if type(value) == 'number' then
        return value
    end
    return nil
end

local function roundedNumber(value)
    value = maybeNumber(value)
    if value == nil then
        return nil
    end

    return math.floor(value * 100 + 0.5) / 100
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
}

local function lowerForSearch(value)
    local text = string.lower(tostring(value or ''))
    for upper, lower in pairs(cyrillicLowerMap) do
        text = string.gsub(text, upper, lower)
    end
    return text
end

local function hasSpecialSymbol(value)
    value = tostring(value or '')
    return string.find(value, '_', 1, true) ~= nil
        or string.find(value, '<', 1, true) ~= nil
        or string.find(value, '>', 1, true) ~= nil
end

local function gmst(id, fallback)
    local value = core.getGMST(id)
    if value == nil or value == '' then
        return fallback or ''
    end
    return tostring(value)
end

local function validIndex(value)
    return type(value) == 'number' and value >= 0
end

local function normalizedRefId(value)
    if value == nil then
        return ''
    end
    local text = tostring(value)
    if text == '' or text == 'nil' then
        return ''
    end
    return string.lower(text)
end

local attributeKeysByIndex = {
    [0] = 'strength',
    [1] = 'intelligence',
    [2] = 'willpower',
    [3] = 'agility',
    [4] = 'speed',
    [5] = 'endurance',
    [6] = 'personality',
    [7] = 'luck',
}

local attributeNames = {
    strength = { gmst = { 'sAttributeStrength' }, fallback = 'Strength' },
    intelligence = { gmst = { 'sAttributeIntelligence' }, fallback = 'Intelligence' },
    willpower = { gmst = { 'sAttributeWillpower' }, fallback = 'Willpower' },
    agility = { gmst = { 'sAttributeAgility' }, fallback = 'Agility' },
    speed = { gmst = { 'sAttributeSpeed' }, fallback = 'Speed' },
    endurance = { gmst = { 'sAttributeEndurance' }, fallback = 'Endurance' },
    personality = { gmst = { 'sAttributePersonality' }, fallback = 'Personality' },
    luck = { gmst = { 'sAttributeLuck' }, fallback = 'Luck' },
}

local skillKeysByIndex = {
    [0] = 'block',
    [1] = 'armorer',
    [2] = 'mediumarmor',
    [3] = 'heavyarmor',
    [4] = 'bluntweapon',
    [5] = 'longblade',
    [6] = 'axe',
    [7] = 'spear',
    [8] = 'athletics',
    [9] = 'enchant',
    [10] = 'destruction',
    [11] = 'alteration',
    [12] = 'illusion',
    [13] = 'conjuration',
    [14] = 'mysticism',
    [15] = 'restoration',
    [16] = 'alchemy',
    [17] = 'unarmored',
    [18] = 'security',
    [19] = 'sneak',
    [20] = 'acrobatics',
    [21] = 'lightarmor',
    [22] = 'shortblade',
    [23] = 'marksman',
    [24] = 'mercantile',
    [25] = 'speechcraft',
    [26] = 'handtohand',
}

local skillNames = {
    block = { gmst = { 'sSkillBlock' }, fallback = 'Block' },
    armorer = { gmst = { 'sSkillArmorer' }, fallback = 'Armorer' },
    mediumarmor = { gmst = { 'sSkillMediumarmor', 'sSkillMediumArmor' }, fallback = 'Medium Armor' },
    heavyarmor = { gmst = { 'sSkillHeavyarmor', 'sSkillHeavyArmor' }, fallback = 'Heavy Armor' },
    bluntweapon = { gmst = { 'sSkillBluntweapon', 'sSkillBluntWeapon' }, fallback = 'Blunt Weapon' },
    longblade = { gmst = { 'sSkillLongblade', 'sSkillLongBlade' }, fallback = 'Long Blade' },
    axe = { gmst = { 'sSkillAxe' }, fallback = 'Axe' },
    spear = { gmst = { 'sSkillSpear' }, fallback = 'Spear' },
    athletics = { gmst = { 'sSkillAthletics' }, fallback = 'Athletics' },
    enchant = { gmst = { 'sSkillEnchant' }, fallback = 'Enchant' },
    destruction = { gmst = { 'sSkillDestruction' }, fallback = 'Destruction' },
    alteration = { gmst = { 'sSkillAlteration' }, fallback = 'Alteration' },
    illusion = { gmst = { 'sSkillIllusion' }, fallback = 'Illusion' },
    conjuration = { gmst = { 'sSkillConjuration' }, fallback = 'Conjuration' },
    mysticism = { gmst = { 'sSkillMysticism' }, fallback = 'Mysticism' },
    restoration = { gmst = { 'sSkillRestoration' }, fallback = 'Restoration' },
    alchemy = { gmst = { 'sSkillAlchemy' }, fallback = 'Alchemy' },
    unarmored = { gmst = { 'sSkillUnarmored' }, fallback = 'Unarmored' },
    security = { gmst = { 'sSkillSecurity' }, fallback = 'Security' },
    sneak = { gmst = { 'sSkillSneak' }, fallback = 'Sneak' },
    acrobatics = { gmst = { 'sSkillAcrobatics' }, fallback = 'Acrobatics' },
    lightarmor = { gmst = { 'sSkillLightarmor', 'sSkillLightArmor' }, fallback = 'Light Armor' },
    shortblade = { gmst = { 'sSkillShortblade', 'sSkillShortBlade' }, fallback = 'Short Blade' },
    marksman = { gmst = { 'sSkillMarksman' }, fallback = 'Marksman' },
    mercantile = { gmst = { 'sSkillMercantile' }, fallback = 'Mercantile' },
    speechcraft = { gmst = { 'sSkillSpeechcraft' }, fallback = 'Speechcraft' },
    handtohand = { gmst = { 'sSkillHandtohand', 'sSkillHandToHand' }, fallback = 'Hand-to-hand' },
}

local function localizedStatName(value, indexKeys, names)
    local key
    if validIndex(value) then
        key = indexKeys[value]
    else
        key = normalizedRefId(value)
    end

    local info = key and names[key] or nil
    if not info then
        return ''
    end

    for _, gmstId in ipairs(info.gmst) do
        local name = gmst(gmstId, '')
        if name ~= '' then
            return name
        end
    end
    return info.fallback
end

local function effectTargetName(effect)
    local skillName = localizedStatName(effect.affectedSkill, skillKeysByIndex, skillNames)
    if skillName ~= '' then
        return skillName
    end

    local attributeName = localizedStatName(effect.affectedAttribute, attributeKeysByIndex, attributeNames)
    if attributeName ~= '' then
        return attributeName
    end
    return ''
end

local function numberText(value)
    if value == math.floor(value) then
        return tostring(math.floor(value))
    end
    return tostring(value)
end

local function isFortifyMaximumMagicka(prototype)
    local name = prototype and prototype.name or ''
    return name == 'Fortify Maximum Magicka'
        or name == 'Увеличить максимум магии'
end

local function appendMaximumMagickaMultiplier(parts, effect, prototype)
    if not isFortifyMaximumMagicka(prototype) then
        return false
    end

    local min = maybeNumber(effect.magnitudeMin)
    local max = maybeNumber(effect.magnitudeMax)
    if min == nil and max == nil then
        return true
    end

    min = (min or max or 0) / 10
    max = (max or min) / 10

    local suffix = prototype.name == 'Увеличить максимум магии' and 'х ИНТ' or 'x INT'
    if min == max then
        parts[#parts + 1] = numberText(min) .. suffix
    else
        parts[#parts + 1] = string.format('%s-%s%s', numberText(min), numberText(max), suffix)
    end
    return true
end

local function appendMagnitude(parts, effect, prototype)
    if prototype and prototype.hasMagnitude == false then
        return
    end

    if appendMaximumMagickaMultiplier(parts, effect, prototype) then
        return
    end

    local min = maybeNumber(effect.magnitudeMin)
    local max = maybeNumber(effect.magnitudeMax)
    if min == nil and max == nil then
        return
    end

    min = min or max or 0
    max = max or min
    if min == max then
        parts[#parts + 1] = tostring(min)
    else
        parts[#parts + 1] = string.format('%s-%s', tostring(min), tostring(max))
    end
    parts[#parts + 1] = gmst('sPoints', 'pts')
end

local function appendDuration(parts, effect, prototype, enchantmentType)
    if enchantmentType == core.magic.ENCHANTMENT_TYPE.ConstantEffect then
        return
    end
    if prototype and prototype.hasDuration == false then
        return
    end

    local duration = maybeNumber(effect.duration)
    if duration == nil or duration <= 0 then
        return
    end

    parts[#parts + 1] = gmst('sfor', 'for')
    parts[#parts + 1] = tostring(math.max(1, duration))
    parts[#parts + 1] = duration == 1 and gmst('ssecond', 'sec') or gmst('sseconds', 'secs')
end

local function appendRange(parts, effect, enchantmentType)
    if enchantmentType == core.magic.ENCHANTMENT_TYPE.ConstantEffect then
        return
    end

    local range = effect.range
    local rangeName
    if range == core.magic.RANGE.Self then
        rangeName = gmst('sRangeSelf', 'self')
    elseif range == core.magic.RANGE.Touch then
        rangeName = gmst('sRangeTouch', 'touch')
    elseif range == core.magic.RANGE.Target then
        rangeName = gmst('sRangeTarget', 'target')
    end

    if rangeName and rangeName ~= '' then
        parts[#parts + 1] = gmst('sonword', 'on')
        parts[#parts + 1] = rangeName
    end
end

local function appendArea(parts, effect)
    local area = maybeNumber(effect.area)
    if area == nil or area <= 0 then
        return
    end
    parts[#parts + 1] = gmst('sin', 'in')
    parts[#parts + 1] = tostring(area)
    parts[#parts + 1] = gmst('sfootarea', 'ft')
end

local function effectNameWithTarget(effectName)
    if effectName == 'Восстановить характеристику' or effectName == 'Восстановить навык' then
        return 'Восстановление'
    elseif effectName == 'Увеличить характеристику' or effectName == 'Увеличить навык'
        or effectName == 'Повысить характеристику' or effectName == 'Повысить навык' then
        return 'Увеличение'
    elseif effectName == 'Уменьшить характеристику' or effectName == 'Уменьшить навык'
        or effectName == 'Понизить характеристику' or effectName == 'Понизить навык' then
        return 'Уменьшение'
    elseif effectName == 'Restore Attribute' or effectName == 'Restore Skill' then
        return 'Restore'
    elseif effectName == 'Fortify Attribute' or effectName == 'Fortify Skill' then
        return 'Fortify'
    elseif effectName == 'Drain Attribute' or effectName == 'Drain Skill' then
        return 'Drain'
    end
    return effectName
end

local function formatEnchantEffect(effect, enchantmentType, options)
    options = options or {}
    local prototype = effect.effect or core.magic.effects.records[effect.id]
    local effectName = prototype and prototype.name or tostring(effect.id)
    local parts = { effectName }
    local targetName = effectTargetName(effect)
    if targetName ~= '' then
        parts[1] = effectNameWithTarget(effectName) .. ':'
        parts[#parts + 1] = targetName
    end

    if options.namesOnly ~= true then
        appendMagnitude(parts, effect, prototype)
        appendDuration(parts, effect, prototype, enchantmentType)
        appendRange(parts, effect, enchantmentType)
        appendArea(parts, effect)
    end

    return {
        text = table.concat(parts, ' '),
        icon = prototype and prototype.icon or nil,
    }
end

local function effectInfo(record, namesOnly)
    local effectsData = safeGet(record, 'effects')
    if effectsData == nil then
        return nil
    end

    local effects = {}
    for _, effect in ipairs(effectsData) do
        effects[#effects + 1] = formatEnchantEffect(effect, nil, { namesOnly = namesOnly })
    end
    return #effects > 0 and effects or nil
end

local function damageRange(record, minKey, maxKey)
    local min = maybeNumber(safeGet(record, minKey))
    local max = maybeNumber(safeGet(record, maxKey))
    if min == nil and max == nil then
        return nil
    end

    min = min or max or 0
    max = max or min
    if min == max then
        return tostring(min)
    end
    return string.format('%s-%s', tostring(min), tostring(max))
end

local function enchantmentTypeKey(enchantmentType)
    if enchantmentType == core.magic.ENCHANTMENT_TYPE.CastOnce then
        return 'CastOnce'
    elseif enchantmentType == core.magic.ENCHANTMENT_TYPE.CastOnStrike then
        return 'CastOnStrike'
    elseif enchantmentType == core.magic.ENCHANTMENT_TYPE.CastOnUse then
        return 'CastOnUse'
    elseif enchantmentType == core.magic.ENCHANTMENT_TYPE.ConstantEffect then
        return 'ConstantEffect'
    end
    return nil
end

local function enchantmentInfo(enchantId)
    if enchantId == nil or enchantId == '' then
        return nil
    end

    local enchantment = core.magic.enchantments.records[enchantId]
    if not enchantment then
        return nil
    end

    local effects = {}
    for _, effect in ipairs(enchantment.effects or {}) do
        effects[#effects + 1] = formatEnchantEffect(effect, enchantment.type)
    end
    return {
        typeKey = enchantmentTypeKey(enchantment.type),
        effects = effects,
    }
end

local function enchantmentRecordTypeKey(enchantId)
    if enchantId == nil or enchantId == '' then
        return nil
    end

    local enchantment = core.magic.enchantments.records[enchantId]
    return enchantment and enchantmentTypeKey(enchantment.type) or nil
end

local function makeItem(record, typeKey, setting)
    local id = asString(safeGet(record, 'id'))
    if id == '' then
        return nil
    end

    local name = asString(safeGet(record, 'name'))
    local displayName = name ~= '' and name or id
    local enchant = asString(safeGet(record, 'enchant'))
    local enchantType = enchantmentRecordTypeKey(enchant)
    local subtypeName = subtypeNamesByTypeKey[typeKey]
        and subtypeNamesByTypeKey[typeKey][safeGet(record, 'type')]
        or nil
    local sortName = lowerForSearch(displayName)
    local sortId = lowerForSearch(id)

    local item = {
        id = id,
        name = name,
        displayName = displayName,
        typeKey = typeKey,
        subtypeKey = subtypeName and ('Type_' .. subtypeName) or nil,
        setting = setting,
        record = record,
        enchant = enchant ~= '' and enchant or nil,
        isEnchanted = enchant ~= '',
        enchantTypeKey = enchantType,
        sortName = sortName,
        sortId = sortId,
        hasSpecialSymbols = name == '' or hasSpecialSymbol(name),
    }

    item.searchText = lowerForSearch(table.concat({ id, name, displayName, typeKey, item.subtypeKey or '' }, '\n'))
    return item
end

local function addRecordStore(items, source)
    for _, record in ipairs(source.records) do
        local item = makeItem(record, source.typeKey, source.setting)
        if item then
            items[#items + 1] = item
        end
    end
end

local function addBookRecords(items)
    for _, record in ipairs(types.Book.records) do
        local isScroll = safeGet(record, 'isScroll') == true
        local item = makeItem(record, isScroll and 'Scroll' or 'Book', isScroll and 'IncludeScrolls' or 'IncludeBooks')
        if item then
            items[#items + 1] = item
        end
    end
end

local function addMiscRecords(items)
    for _, record in ipairs(types.Miscellaneous.records) do
        local isKey = safeGet(record, 'isKey') == true
        local item = makeItem(record, isKey and 'Key' or 'Misc', isKey and 'IncludeKeys' or 'IncludeMisc')
        if item then
            items[#items + 1] = item
        end
    end
end

local function ensureIndex()
    if index then
        return
    end

    local items = {}
    for _, source in ipairs(typeSources) do
        addRecordStore(items, source)
    end
    addBookRecords(items)
    addMiscRecords(items)

    table.sort(items, function(a, b)
        if a.sortName == b.sortName then
            return a.sortId < b.sortId
        end
        return a.sortName < b.sortName
    end)

    local ids = {}
    for _, item in ipairs(items) do
        ids[item.sortId] = item
    end

    index = items
    byId = ids
end

local function included(item, filters)
    if not filters then
        return true
    end
    return filters[item.setting] ~= false
end

local function includedByEnchant(item, enchantFilter)
    if enchantFilter == 'ConstantEffect' then
        return item.enchantTypeKey == 'ConstantEffect'
    elseif enchantFilter == 'NonConstantEffect' then
        return item.isEnchanted and item.enchantTypeKey ~= 'ConstantEffect'
    elseif enchantFilter == 'Unenchanted' then
        return not item.isEnchanted
    end
    return true
end

local function includedBySpecialSymbols(item, hideSpecialSymbolItems)
    if hideSpecialSymbolItems == false then
        return true
    end
    return not item.hasSpecialSymbols
end

local function addDetailFields(result, item)
    local record = item.record
    local icon = asString(safeGet(record, 'icon'))
    local model = asString(safeGet(record, 'model'))

    result.icon = icon ~= '' and icon or nil
    result.model = model ~= '' and model or nil
    result.weight = roundedNumber(safeGet(record, 'weight'))
    result.value = maybeNumber(safeGet(record, 'value'))
    result.health = maybeNumber(safeGet(record, 'health')) or maybeNumber(safeGet(record, 'maxCondition'))
    result.quality = roundedNumber(safeGet(record, 'quality'))
    result.enchantCapacity = roundedNumber(safeGet(record, 'enchantCapacity'))
    result.baseArmor = maybeNumber(safeGet(record, 'baseArmor'))
    result.speed = roundedNumber(safeGet(record, 'speed'))
    result.reach = roundedNumber(safeGet(record, 'reach'))
    result.chopDamage = damageRange(record, 'chopMinDamage', 'chopMaxDamage')
    result.slashDamage = damageRange(record, 'slashMinDamage', 'slashMaxDamage')
    result.thrustDamage = damageRange(record, 'thrustMinDamage', 'thrustMaxDamage')
    result.effects = effectInfo(record, item.typeKey == 'Ingredient')
    result.detailsLoaded = true
end

local function stripRuntimeFields(item, includeDetails)
    local result = {
        id = item.id,
        name = item.name,
        displayName = item.displayName,
        typeKey = item.typeKey,
        subtypeKey = item.subtypeKey,
        setting = item.setting,
        enchant = item.enchant,
        isEnchanted = item.isEnchanted,
        enchantTypeKey = item.enchantTypeKey,
    }

    if includeDetails then
        addDetailFields(result, item)
        local enchantInfo = enchantmentInfo(item.enchant)
        result.enchantTypeKey = enchantInfo and enchantInfo.typeKey or nil
        result.enchantEffects = enchantInfo and enchantInfo.effects or nil
    end

    return result
end

function M.search(options)
    ensureIndex()

    options = options or {}
    local query = lowerForSearch(options.query or '')
    local limit = tonumber(options.limit)
    local filters = options.filters
    local enchantFilter = options.enchantFilter or 'All'
    local hideSpecialSymbolItems = options.hideSpecialSymbolItems ~= false
    local favoriteOnly = options.favoriteOnly == true
    local favoriteIds = options.favoriteIds or {}
    local results = {}
    local total = 0

    for _, item in ipairs(index) do
        local favorite = favoriteIds[item.id] == true or favoriteIds[lowerForSearch(item.id)] == true
        if included(item, filters)
            and includedByEnchant(item, enchantFilter)
            and includedBySpecialSymbols(item, hideSpecialSymbolItems)
            and (not favoriteOnly or favorite)
            and (query == '' or string.find(item.searchText, query, 1, true))
        then
            total = total + 1
            if limit == nil or #results < limit then
                local result = stripRuntimeFields(item)
                result.favorite = favorite
                results[#results + 1] = result
            end
        end
    end

    return {
        query = options.query or '',
        items = results,
        total = total,
        limit = limit,
        indexed = #index,
    }
end

function M.find(recordId)
    ensureIndex()
    return byId[lowerForSearch(recordId or '')]
end

function M.details(recordId)
    ensureIndex()
    local item = byId[lowerForSearch(recordId or '')]
    if not item then
        return nil
    end
    return stripRuntimeFields(item, true)
end

return M
