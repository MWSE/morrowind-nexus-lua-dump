local types = require('openmw.types')
local world = require('openmw.world')
local core = require('openmw.core')
local vfs = require('openmw.vfs')

local player = world.players[1]
local skills = types.NPC.stats.skills
local attributes = types.Actor.stats.attributes


local prefixModel = "meshes/m/"
local prefixIcon = "icons\\m\\"
local prefixIcon2 = "icons/m/"
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

local weigthByQuality = {
    ["b"] = 0.8, --"Bargain"
    ["c"] = 0.6, --"Cheap"
    ["s"] = 0.4, --"Standard"
    ["q"] = 0.2,--"Quality"
    ["e"] = 0.1,--"Exclusive"
}

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

    if not suffix or suffix == "" then
        return baseName
    else 
        return firstWord .. " " .. suffix
    end
end

local function groupEffectsByBaseName(effectNames)
    local groups = {}

    for _, name in ipairs(effectNames) do
        -- Извлекаем первое слово и остаток строки
        local effect = name:match("^%S+")
        local rest = name:match("^%S+%s+(.+)$")

        if not groups[effect] then
            groups[effect] = {}
        end
        if effect and rest then
            table.insert(groups[effect], rest)
        else
            -- Если нет пробела (одно слово) — добавляем как отдельную запись
            table.insert(groups[effect], "")
        end
    end

    -- Формируем результат
    local result = {}
    for effect, attributes in pairs(groups) do
  
        if type(attributes) == "table" and #attributes > 0 then
            table.insert(result, effect .. " " .. table.concat(attributes, ", "))
        else --if type(attributes) == "string" then
            table.insert(result, effect)
        end
    end

    return result
end

local function buildNameFromEffects(potionRecord)
    -- Список ключевых эффектов, которые ВСЕГДА должны быть в названии
    local priorityCures = {
        ["cure poison"] = true,
        ["cure paralyzation"] = true,
        ["cure common disease"] = true,
        ["cure blight disease"] = true
    }

    -- Шаг 1: Находим глобальный максимум среди magnitudeMax, duration и range
    local globalMax = 0
    for _, effect in ipairs(potionRecord.effects) do
        local mag = effect.magnitudeMax or 0
        local dur = effect.duration or 0
        local rad = effect.range or 0
        local maxForEffect = math.max(mag, dur, rad)
        if maxForEffect > globalMax then
            globalMax = maxForEffect
        end
    end

    -- Шаг 2: Собираем имена эффектов, соответствующих глобальному максимуму
    local names = {}
    for _, effect in ipairs(potionRecord.effects) do
        local mag = effect.magnitudeMax or 0
        local dur = effect.duration or 0
        local rad = effect.range or 0
        local name = getNameFromEffect(effect)

        -- Если эффект — один из приоритетных лечебных, добавляем его всегда
        if priorityCures[name:lower()] then
            table.insert(names, name)
        -- Иначе — только если хотя бы один параметр равен глобальному максимуму
        elseif mag == globalMax or dur == globalMax or rad == globalMax then
            table.insert(names, name)
        end
    end

    -- Шаг 3: Удаляем дубликаты, сохраняя порядок
    local uniqueNames = {}
    local seen = {}
    for _, name in ipairs(names) do
        local lowerName = name:lower()
        if not seen[lowerName] then
            table.insert(uniqueNames, name)
            seen[lowerName] = true
        end
    end

    -- Шаг 4: Группируем по базовому имени (если нужно)
    local groupNames = groupEffectsByBaseName(uniqueNames)

    -- Возвращаем объединённое имя
    return table.concat(groupNames, " & ")
end

local function effectsAlchemyOverhaul(effects)
    local alchemy = skills.alchemy(player).modified
    local intelligence = attributes.intelligence(player).modified
    local luck = attributes.luck(player).modified

    local effectsNew = {}
    for _, effect in ipairs(effects) do
        local school = effect.effect.school        
        local magicSchool = skills[school](player).modified 

        local basePotionStrength  = effect.magnitudeMax / (alchemy + (intelligence / 10) + (luck / 10)) 
        basePotionStrength = basePotionStrength * ((alchemy /2) + (magicSchool /2) + (intelligence / 10) + (luck / 10))
        local basePotionDuration = basePotionStrength * 2


        local effectNew = {
            affectedAttribute = effect.affectedAttribute,
            affectedSkill = effect.affectedSkill,
            area = effect.area,
            duration = basePotionDuration,
            effect = effect.effect,
            id = effect.id,
            --index = effect.index,
            magnitudeMax = basePotionStrength,
            magnitudeMin = basePotionStrength,
            range = effect.range,
            script = effect.script
        }

        -- print(effect.id, effect.magnitudeMax, effect.duration)
        -- print(effectNew.id, effectNew.magnitudeMax, effectNew.duration)
        table.insert(effectsNew, effectNew)
    end
    return effectsNew
end


local function createPotion(potionRecord, data)
    local quality, newPrice = getQuality(potionRecord, data.variant)
    local schools = buildSchoolsString(potionRecord)
    
    local model = prefixModelMod .. "misc_potion_".. quality .. "_01.nif"
    local icon = prefixIconMod .. quality .. "_" .. schools .. ".dds"

    if not vfs.fileExists(model) then
        model = potionRecord.model
    end
    if not vfs.fileExists(icon) then
        icon = potionRecord.icon
    end

    local name = potionRecord.name
    if data.replaceName and getNameFromEffect(potionRecord.effects[1]):lower() == name:lower() then
        name = buildNameFromEffects(potionRecord)
    end

    local value = potionRecord.value
    if data.changePrice then
        value = newPrice
    end

    local weight = potionRecord.weight
    if data.replaceWeight then
        weight = weigthByQuality[quality] or weight
    end

    local effects = potionRecord.effects --effectsAlchemyOverhaul(potionRecord.effects)
    local newPotion = types.Potion.createRecordDraft({
        name = name,
        effects = effects,
        weight = weight,
        value = value,
        mwscript = potionRecord.mwscript,

        model = model,
        icon = icon
    })

    local newPotionRecord = world.createRecord(newPotion)
    return newPotionRecord.id
end


local function effectsEqual(effects1, effects2)

    if effects1 == effects2 then return true end
    if #effects1 ~= #effects2 then return false end

    -- Create a copy of effects2 to track matched entries
    local unmatched = {}
    for i, eff in ipairs(effects2) do
        unmatched[i] = eff
    end

    for _, eff1 in ipairs(effects1) do
        local found = false
        for j, eff2 in ipairs(unmatched) do
            if eff1.id == eff2.id and
               eff1.magnitudeMin == eff2.magnitudeMin and
               eff1.magnitudeMax == eff2.magnitudeMax and
               eff1.duration == eff2.duration and
               eff1.area == eff2.area and
               eff1.range == eff2.range and
               eff1.affectedAttribute == eff2.affectedAttribute and
               eff1.affectedSkill == eff2.affectedSkill then
                -- Remove matched effect from unmatched list
                table.remove(unmatched, j)
                found = true
                break
            end
        end
        if not found then
            return false
        end
    end
    return true
end

local function findIdenticalPotion(potionId, findByEffects) 

    local newPotionId = replacer[potionId.id]
    if newPotionId then return newPotionId end

    if findByEffects then
        local sourceRecord = types.Potion.record(potionId)
        local sourceEffects = sourceRecord.effects
        
        for _, targetId in pairs(replacer) do
            local targetRecord = types.Potion.record(targetId)
            local targetEffects = targetRecord.effects

            if effectsEqual(sourceEffects, targetEffects) then
                return targetId
            end
        end
    end
    return nil
end

local function replacePotion(inventory, potion, potionRecord, data)


    local count = inventory:countOf(potionRecord.id)
    local newPotionId = nil
    if data.cache then
        newPotionId = findIdenticalPotion(potionRecord.id, data.replaceWeight)
    end
   if not newPotionId then
        newPotionId = createPotion(potionRecord, data)
        --print("save replace", potionRecord.id, " to ", newPotionId)
    end
    if data.cache then
        replacer[potionRecord.id] = newPotionId
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

-- local SD_Mod = {
--      'Water',
--      'Saltwater',
--      'Suspicious Water',
--      'Sujamma',
--      'Flin',
--      'Stoneflower Tea', 
--      'Heather Tea', -- name of the liquid
--      'Teapot',
--      'Flask',
--      'Bottle',
--      'Stew',
--      'Canis Root Tea',     
-- }

-- local function startsWith(str, prefix)
--     return string.sub(str, 1, #prefix) == prefix
-- end

local function checkNewPotions(data)
    --print("variant ", data.variant)
    player:sendEvent('SetUiMode', {
        mode = 'Interface'
    })
    local inventory = types.Actor.inventory(player)
    local potions = inventory:getAll(types.Potion)
    core.sendGlobalEvent('obafStartReplacePotions')
    for _, potion in ipairs(potions) do
        local potionRecord = types.Potion.record(potion)
        if isGen(potionRecord.id) then

            if potionRecord.mwscript == 'sd_loot_tracker' then goto continue end
            if potionRecord.mwscript == 'sd_liquid_tracker' then goto continue end
            if potionRecord.effects == nil or #potionRecord.effects == 0 then goto continue end
            if potionRecord.template then goto continue end

            -- for _, name in ipairs(SD_Mod) do
            --     if startsWith(potionRecord.name, name) then goto continue end
            -- end

            if string.sub(potionRecord.model, 1, #prefixModel) == prefixModel and
                ( string.sub(potionRecord.icon, 1, #prefixIcon) == prefixIcon  
                or string.sub(potionRecord.icon, 1, #prefixIcon2) == prefixIcon2 ) then
                replacePotion(inventory, potion, potionRecord, data)
            end
            ::continue::
        end
    end
    core.sendGlobalEvent('obafStopReplacePotions')
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
