local types = require('openmw.types')
local world = require('openmw.world')
local core = require('openmw.core')
local vfs = require('openmw.vfs')

local player = world.players[1]
local skills = types.NPC.stats.skills

local prefixModel = "meshes/m/"
local prefixIcon = "icons\\m\\"
local prefixIconMod = "icons/OBaF/"
local prefixModelMod = "meshes/OBaF/"

local replacer = {}

local qualityThresholds = {{
    price = 5,
    name = "b" --"Bargain"
}, {
    price = 15,
    name = "c" --"Cheap"
}, {
    price = 35,
    name = "s" --"Standard"
}, {
    price = 80,
    name = "q" --"Quality"
}, {
    price = 175,
    name = "e" --"Exclusive"
}}

-- local function isBadEffect(effectRecord)
--     -- Набор эффектов, считающихся ядом
--     local poisonEffects = {
--         poison = true,
--         paralyze = true,
--         burden = true,
--         blind = true,
--         silence = true
--     }
    
--     return poisonEffects[effectRecord.id] or effectRecord.school == "destruction" 
-- end
local function getQualityByThreshold(threshold)
    local result = qualityThresholds[1].name 

    for _, level in ipairs(qualityThresholds) do
        if threshold >= level.price then
            result = level.name
        else
            break -- Так как таблица отсортирована, можно остановиться
        end
    end
    return result
end

local function getQuality(potionRecord, variant)
    -- 1 - Standard (качество = цена)
    -- 2 - Useless Poisons (негативные эффекты снижают качество)
    -- 3 - Useful Poisons (качество зависит от модуля разности полезных и вредных эффектов)

    --print("выбран вариант ", variant)

    if variant == 1 then
        return getQualityByThreshold(potionRecord.value), potionRecord.value
    end

    local good = 0
    local bad = 0

    -- Суммируем максимальные силы эффектов
    for _, effect in ipairs(potionRecord.effects) do
        local effectRecord = core.magic.effects.records[effect.id]
        if effectRecord.harmful then
            bad = bad + (effect.magnitudeMax or 0)
        else
            good = good + (effect.magnitudeMax or 0)
        end
        --print(string.format("Effect %s is %s", effectRecord.name, effectRecord.harmful and "bad" or "good"))

    end

    -- Защита от nil: magnitudeMax может отсутствовать
    local netEffect
    if variant == 2 then
        netEffect = math.max(1, good - bad)
    elseif variant == 3 then
        netEffect = math.max(1, math.abs(good - bad))
    else
        netEffect = potionRecord.value -- fallback на стандартное качество
    end

    --print("netEffect ", netEffect)

    local result = getQualityByThreshold(netEffect)
    if result == "e" then 
        if #potionRecord.effects < 4 then result = "q" end
    end
    return result, netEffect
end

-- Вспомогательная функция: проверка наличия элемента в таблице
local function table_contains(t, value)
    for _, v in ipairs(t) do
        if v == value then
            return true
        end
    end
    return false
end

local function buildSchoolsString(potionRecord)
    local targetOrder = { 'd', 'i', 'm', 'a', 'r' }
    local found = {}

    -- Проходим по всем школам и фиксируем, какие нужные буквы встретились

    for _, effect in ipairs(potionRecord.effects) do
        local effectRecord = core.magic.effects.records[effect.id]
        local school = effectRecord.school
        local firstChar = string.lower(string.sub(school, 1, 1))
        if table_contains(targetOrder, firstChar) then
            found[firstChar] = true
        end
    end

    -- Собираем результат в нужном порядке, без дублей
    local result = {}
    for _, char in ipairs(targetOrder) do
        if found[char] then
            table.insert(result, char)
        end
    end

    return table.concat(result)
end

local function getFirstWord(str)
    return str and string.match(str, "%S+") or ""
end

local function getNameFromEffect(effect)
    local baseName = effect.effect.name
    local firstWord = getFirstWord(baseName)
    local suffix = ""

    if effect.affectedAttribute then
        local attribute = core.stats.Attribute.record(effect.affectedAttribute)
        if attribute then
            suffix = attribute.name
        end
    elseif effect.affectedSkill then
        local skill = core.stats.Skill.record(effect.affectedSkill)
        if skill then
            suffix = skill.name
        end
    end

    return suffix ~= "" and (firstWord .. " " .. suffix) or baseName
end

local function groupEffectsByBaseName(effectNames)
    local groups = {}

    for _, name in ipairs(effectNames) do
        -- Извлекаем первое слово и остаток строки
        local effect = name:match("^%S+")
        local rest = name:match("^%S+%s+(.+)$")

        if effect and rest then
            if not groups[effect] then
                groups[effect] = {}
            end
            table.insert(groups[effect], rest)
        else
            -- Если нет пробела (одно слово) — добавляем как отдельную запись
            table.insert(groups, effect)
        end
    end

    -- Формируем результат
    local result = {}
    for effect, attributes in pairs(groups) do
        if type(attributes) == "table" and #attributes > 0 then
            table.insert(result, effect .. " " .. table.concat(attributes, ", "))
        elseif type(attributes) == "string" then
            table.insert(result, effect)
        end
    end

    return result
end

local function buildNameFromEffects(potionRecord)

    -- Находим максимальное значение magnitudeMax
    local maxMagnitude = 0
    for _, effect in ipairs(potionRecord.effects) do
        local mag = effect.magnitudeMax or 0
        if mag > maxMagnitude then
            maxMagnitude = mag
        end
    end

    -- Собираем все эффекты с максимальной силой
    local names = {}
    for _, effect in ipairs(potionRecord.effects) do
        local mag = effect.magnitudeMax or 0
        if mag == maxMagnitude then
            local name = getNameFromEffect(effect)
            table.insert(names, name)
        end
    end
    
    -- Убираем дубликаты имён, сохраняя порядок
    local uniqueNames = {}
    local seen = {}
    for _, name in ipairs(names) do
        if not seen[name] then
            table.insert(uniqueNames, name)
            seen[name] = true
        end
    end

    local groupNames = groupEffectsByBaseName(uniqueNames)
    -- Возвращаем объединённое имя
    return table.concat(groupNames, " & ")
end

local function createPotion(potionRecord, variant, changePrice, replaceName)
    local quality, newPrice = getQuality(potionRecord, variant)
    local schools = buildSchoolsString(potionRecord)


    --print("Определено качество ", quality, " и цена ", newPrice)
    
    local model = prefixModelMod .. "misc_potion_".. quality .. "_01.nif"
    local icon = prefixIconMod .. quality .. "_" .. schools .. ".dds"

    if not vfs.fileExists(model) then
        model = potionRecord.model
    end
    if not vfs.fileExists(icon) then
        icon = potionRecord.icon
    end

    local name = potionRecord.name
    if replaceName and getNameFromEffect(potionRecord.effects[1]):lower() == name:lower() then
        name = buildNameFromEffects(potionRecord)
    end

    local value = potionRecord.value
    if changePrice then
        value = newPrice
    end

    local newPotion = types.Potion.createRecordDraft({
        name = name,
        effects = potionRecord.effects,
        weight = potionRecord.weight,
        value = value,
        mwscript = potionRecord.mwscript,

        model = model,
        icon = icon
    })

    local newPotionRecord = world.createRecord(newPotion)
    return newPotionRecord.id
end

local function replacePotion(inventory, potion, potionRecord, variant, changePrice, replaceName, cache)


    local count = inventory:countOf(potionRecord.id)
    local newPotionId = nil
    if cache then
        newPotionId = replacer[potionRecord.id]
    end

    if not newPotionId then
        newPotionId = createPotion(potionRecord, variant, changePrice, replaceName)
        if cache then
            replacer[potionRecord.id] = newPotionId
        end
        --print("save replace", potionRecord.id, " to ", newPotionId)
    end
    local item = world.createObject(newPotionId, count)

    potion:remove(count)
    item:moveInto(inventory)
end


local function restorePotion()
    local inventory = types.Actor.inventory(player)

    for oldPotion, newPotion in pairs(replacer) do
        local potion = inventory:find(newPotion)
        if potion then
            local count = inventory:countOf(newPotion)
            local item = world.createObject(oldPotion, count)

            potion:remove(count)
            item:moveInto(inventory)

        end
    end
end

local function isGen(itemid)
    return string.sub(itemid, 1, 9) == "Generated"
end

local function checkNewPotions(data)
    --print("variant ", data.variant)
    player:sendEvent('SetUiMode', {
        mode = 'Interface'
    })
    local inventory = types.Actor.inventory(player)
    local potions = inventory:getAll(types.Potion)
    for _, potion in ipairs(potions) do
        local potionRecord = types.Potion.record(potion)
        if isGen(potionRecord.id) then
            if string.sub(potionRecord.model, 1, #prefixModel) == prefixModel and
                string.sub(potionRecord.icon, 1, #prefixIcon) == prefixIcon and 
                #potionRecord.effects > 0 then
                replacePotion(inventory, potion, potionRecord, data.variant, data.changePrice, data.replace, data.cache)
            end
        end
    end
    player:sendEvent('AddUiMode', {
        mode = 'Interface'
    })
end

return {
    engineHandlers = {
        -- onUpdate = onUpdate
        onLoad = function(savedData, initData)
            replacer = savedData and savedData.replacer or {}
        end,
        onSave = function()
            return {
                replacer = replacer
            }
        end
    },


    eventHandlers = {
        checkNewPotions = checkNewPotions,
    }

}
