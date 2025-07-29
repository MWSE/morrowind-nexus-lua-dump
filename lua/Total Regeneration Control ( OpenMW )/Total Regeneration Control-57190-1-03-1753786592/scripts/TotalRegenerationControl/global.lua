local core = require('openmw.core')
local types = require('openmw.types')
local world = require('openmw.world')

local settings_import = require("scripts.TotalRegenerationControl.settings")
local settings_import_player = require("scripts.TotalRegenerationControl.settings_player")
settings_import.initSettings()
settings_import_player.initSettingsPlayer()

local data = require('scripts.TotalRegenerationControl.data')
local settingsMap = data.settingsMap
local getPercent = data.getPercent
local getAttribute = data.getAttribute
local getDynamic = data.getDynamic
local ATTRIBUTES = data.ATTRIBUTES
local trcmtimer = {}
local trcmstates = {}

-----------------------------------------------------------------------------------------------------
-- ВСЕ округлять нахрен. иначе сравнения чисел с плавающей запятой будут НЕ ВСЕГДА точные. условные 10.00000000 НЕ ВСЕГДА = 10.00000000
local function round(num, n)
    local mult = 10^(n or 0)
    return math.floor(num * mult + 0.5) / mult
end

-- создать/найти актера в таблице.
local function findOrCreateActorState(actor)
    local id = actor.id
    local state = trcmstates[id]

    -- если актер в таблице, то функция прерывается, поэтому значения не перезаписываются и не влияют на логику
    if state then
        return state
    end
    --print(" NEW ACTOR TABLE")
    -- если нет - создать
    state = {}
    trcmstates[id] = state

    -- получить динамические значения один раз
    local dynamic = data.getDynamic(actor)

    -- нужно записать эти значения, что бы для Новых актеров задержка считалась корректно с первого тика скрипта.
    -- для маны и усталости
    for _, res in ipairs({ "MAGICKA", "FATIGUE", "HEALTH" }) do
        state[res] = {}
    end

    return state
end


-- мертв ли актер. + поставить флаг, записать время последней встречи. нужно для удаления из таблицы
local function isActorDead_and_MarkToDelete(actor_state_id, actor)
        if types.Actor.isDead(actor) then
        actor_state_id.delete = true
        return true
    else
        actor_state_id.delete = false
        actor_state_id.last_seen_time = core.getGameTime()
        return false
    end
end

--? Проверки возможности регенирации + пометить актера к удалению из таблицы
local function isRegenAllowed(resource, actor, current, max)
    -- русурс актера полный
    if current >= max then
        return false
    end

    -- на актера действует эффект Замороженная магия
    if resource == "MAGICKA" then
        for _, effect in pairs(types.Actor.activeEffects(actor)) do
            if effect.id == "stuntedmagicka" then
                return false
            end
        end
    end

    return true
end

-- посчитать порог из атрибутов актера и указанных % в настройках
local function calcThreshold(resource_threshold, attrs, actor, actor_lvl, settingsCategory)
        local settingsT = settingsMap[settingsCategory][resource_threshold]

        local base = settingsT:get("threshold") or 0
        local byLvl = settingsT:get("threshold_by_lvl") or 0
        local maxLvl = settingsT:get("threshold_max_lvl") or 10000
        local cap = settingsT:get("threshold_cap") or 10000

        local threshold = base + math.min(actor_lvl, maxLvl) * byLvl

        local attr = getAttribute(actor)
        local percent = getPercent(settingsCategory, resource_threshold)
        for _, name in ipairs(attrs) do
            threshold = threshold + (attr[name] * percent[name] / 100)
        end
        threshold = math.min(threshold, cap)

        return threshold
    end

-- обновлять ли задержку регена для ресурса
local function updateDelayOrNot(current, actor_state_res, isThresholdEnabled, resource_threshold, attrs, actor, actor_lvl, settingsCategory)
    local last = actor_state_res.last_value or current
    if current < last then
        --print("current < last")
        if isThresholdEnabled then
            --print("threshold is ENABLED")
            local diff = round((last - current), 3)
            --print(string.format("DIFF = %.20f", diff))
            local threshold_amount = round(calcThreshold(resource_threshold, attrs, actor, actor_lvl, settingsCategory), 3)
            if diff > threshold_amount then
                --print("diff > threshold_amount")
                --print(string.format("YES UPDATE threshold_amount = %.20f", threshold_amount))
                return true
            else
                --print("diff < threshold_amount")
                --print(string.format("DONT UPDATE threshold_amount = %.20f", threshold_amount))
                return false
            end
        else
            --print("YES UPDATE, threshold is DISABLED ")
            return true
        end
    end
    --print("DONT UPDATE, current > last")
    return false
end

--? Проверка задержки для регенирации
local function isDelay(resource, resource_threshold, attrs, isThresholdEnabled, actor, actor_lvl, actor_state_res, actor_state_id, current, settingsCategory)
    local delay_resource = settingsMap[settingsCategory][resource]:get('delay_resource') or 0
    if delay_resource == 0 then
        return false
    end

    local game_time = round(core.getGameTime(), 3)
    local game_time_honest = trcmtimer.honest_game_timer
    local delay_end_time = actor_state_res.delay_end_time or 0
    local delay_end_time_honest = actor_state_res.delay_end_time_honest or 0
    -- обновить состояния
    if resource ~= "HEALTH" then
        -- MAGICKA / FATIGUE
        if delay_resource > 0 then
            --print("delay_resource > 0")
            --print("current = ", tostring(current), " actor_state.last_value = ", tostring(actor_state_res.last_value) )
            local update_delay_bool = updateDelayOrNot(current, actor_state_res, isThresholdEnabled, resource_threshold, attrs, actor, actor_lvl, settingsCategory)
            if update_delay_bool then
                local new_delay = game_time + delay_resource * core.getGameTimeScale()
                local new_delay_honest = game_time_honest + delay_resource * core.getGameTimeScale()
                -- возможно задержка от урона по хп кончится позже
                delay_end_time = math.max(delay_end_time, new_delay)
                delay_end_time_honest = math.max(delay_end_time_honest, new_delay_honest)
            end
        end
    else
        -- HEALTH
        if delay_resource > 0 then
            --print("delay_resource > 0")
            --print("current = ", tostring(current), " actor_state.last_value = ", tostring(actor_state_res.last_value) )
            local updateDelayBool = updateDelayOrNot(current, actor_state_res, isThresholdEnabled, resource_threshold, attrs, actor, actor_lvl, settingsCategory)
            if updateDelayBool then
                delay_end_time = game_time + delay_resource * core.getGameTimeScale()
                delay_end_time_honest = game_time_honest + delay_resource * core.getGameTimeScale()

                local delay_hp_for_magicka = settingsMap[settingsCategory]["MAGICKA"]:get('delay_hp_for_magicka') or 0
                local delay_hp_for_fatigue = settingsMap[settingsCategory]["FATIGUE"]:get('delay_hp_for_fatigue') or 0

            -- если задержка срабатывает для хп, то проверить нужно ли обновлять задержку для маны/выносливости 
                if delay_hp_for_magicka > 0 then
                    local delay_end_time_magicka = round((game_time + delay_hp_for_magicka * core.getGameTimeScale()), 3)
                    local delay_end_time_magicka_honest = round((game_time_honest + delay_hp_for_magicka * core.getGameTimeScale()), 3)
                    if delay_end_time_magicka > (actor_state_id["MAGICKA"].delay_end_time or 0) then
                        actor_state_id["MAGICKA"].delay_end_time = delay_end_time_magicka
                        actor_state_id["MAGICKA"].delay_end_time_honest = delay_end_time_magicka_honest
                    end
                end

                if delay_hp_for_fatigue > 0 then
                    local delay_end_time_fatigue = round((game_time + delay_hp_for_fatigue * core.getGameTimeScale()), 3)
                    local delay_end_time_fatigue_honest = round((game_time_honest + delay_hp_for_fatigue * core.getGameTimeScale()), 3)
                    if delay_end_time_fatigue > (actor_state_id["FATIGUE"].delay_end_time or 0) then
                        actor_state_id["FATIGUE"].delay_end_time = delay_end_time_fatigue
                        actor_state_id["FATIGUE"].delay_end_time_honest = delay_end_time_fatigue_honest
                    end
                end
            end
        end
    end

    actor_state_res.delay_end_time = round(delay_end_time, 3)
    actor_state_res.delay_end_time_honest = round(delay_end_time_honest, 3)
    return game_time_honest < (actor_state_res.delay_end_time_honest)
end

--? Вычисления регенирации и обновление показателя
local function regen(resource, attrs, actor, actor_lvl, actor_state_res, isDelayBool, max, settingsCategory)
    --print("regen()===================== ")
    local settingsR = settingsMap[settingsCategory][resource]
    local attr = getAttribute(actor)
	local perc = getPercent(settingsCategory, resource)
    --print("CHARACTER= ", actor.recordId, " settingsCategory= ", settingsCategory, " resource= ", resource)
    -- сколько регена в секунду ожидается в соответсвии от настроек и атрибутов
    local base = settingsR:get("base_regen") or 0
    local byLvl = settingsR:get("regen_by_level") or 0
    local maxLvl = settingsR:get("regen_max_level") or 10000
    local cap = settingsR:get("regen_cap") or 10000

    local regen_per_second = base + math.min(actor_lvl, maxLvl) * byLvl
    for _, name in ipairs(attrs) do
        regen_per_second = regen_per_second + (attr[name] * perc[name] / 100)
    end

    local now_game_time = round(core.getGameTime(), 3)
    local last_game_time = actor_state_res.last_regen_time or now_game_time
    local delta_game = round((now_game_time - last_game_time) / core.getGameTimeScale(), 3)

    local delay_strength = (settingsR:get('delay_strength') or 0)

    local amount = 0
    -- Если актер был не активен(в другой локации). тик скрипта с запасом, но меньше двух тиков.
    if delta_game > 0.4 then

        local now_honest_time = trcmtimer.honest_game_timer
        local last_honest_time = actor_state_res.last_regen_honest_timer or now_honest_time
        local total_honest_delta = round((now_honest_time - last_honest_time) / core.getGameTimeScale(), 3)
        local delay_end_time_honest = actor_state_res.delay_end_time_honest or 0

        --[[print(
            " +++++HONEST TIMER USED (Large delta_game) " ..
            " / last_honest_game_time= " .. tostring(last_honest_time) ..
            " / now_honest_time= " .. tostring(now_honest_time) ..
            " / delay_end_time_honest= " .. tostring(delay_end_time_honest)
        )]]

        -- Если Честное время не изменилось, ничего не делать.
        if total_honest_delta <= 0 then
            amount = 0
        else
            --время с задержкой и без нее
            local time_with_penalty = 0
            local time_without_penalty = 0

            -- 1: задержка закончилась ДО или В МОМЕНТ последнего обновления
            if delay_end_time_honest <= last_honest_time then
                -- то весь период отсутствия считать без штрафа
                time_without_penalty = total_honest_delta
                --print("1 time_without_penalty = ", time_without_penalty)
            -- 2: задержка заканчивается В ТЕЧЕНИЕ периода отсутствия
            elseif delay_end_time_honest > last_honest_time and delay_end_time_honest < now_honest_time then
                -- часть времени была с задержкой, часть - без
                time_with_penalty = (delay_end_time_honest - last_honest_time) / core.getGameTimeScale()
                time_without_penalty = (now_honest_time - delay_end_time_honest) / core.getGameTimeScale()
                --print("2 time_with_penalty= ", time_with_penalty)
                --print("2 time_without_penalty= ", time_without_penalty)
            -- 3: задержка еще НЕ закончилась к моменту возвращения
            elseif delay_end_time_honest >= now_honest_time then
                -- весь период отсутствия прошел под действием задержки
                time_with_penalty = total_honest_delta
                --print("3 time_with_penalty= ", time_with_penalty)
            end

            -- итоговое количество регена
            amount = regen_per_second * (
                time_with_penalty * (1 - delay_strength / 100) +
                time_without_penalty
            )
            cap = cap * (
                time_with_penalty * (1 - delay_strength / 100) +
                time_without_penalty
            )
            amount = round(math.max(0, math.min(amount, cap)), 3)
            --print("regen_per_second= ", regen_per_second, "amount * delay * delay_strength= ", amount)
        end
    else
        -- актер активен, обычная регенерация на основе игрового времени
        --[[print(
            " +++++REGULAR DELTA < 0.4 " ..
            " / last_regen_time " .. tostring(last_game_time) ..
            " / now " .. tostring(now_game_time) ..
            " / now_honest_time " .. tostring(trcmtimer.honest_game_timer) ..
            " / actor_state_res.delay_end_time_honest " .. tostring(actor_state_res.delay_end_time_honest) ..
            " / delta " .. tostring(delta_game)
        )]]
        amount = regen_per_second * delta_game
        cap = cap * delta_game
        --print("amount * delta= ", amount)
        -- если идет задержка, то пересчитать реген
        if isDelayBool then
            amount = amount * (1 - delay_strength / 100)
        end
        amount = round(math.max(0, math.min(amount, cap)), 3)
        --print("regen_per_second= ", regen_per_second, "amount * delta * delay_strength= ", amount)
    end
    -- определяю current прямо здесь, что бы между тем как скрипт определит current и присвоит персонажу новое значение
    -- персонаж не успел потратить ресурс. иначе персонаж как бы не потратит ресурс за действие.
    local current = round(getDynamic(actor)[resource .. "_CURRENT"], 3)
    local total = round(math.min(current + amount, max), 3)
    --[[print(
        " / regen per second " .. tostring(regen_per_second) ..
        " / isDelay " .. tostring(isDelayBool) ..
        " / amount mod" .. tostring(amount) ..
        " / total " .. tostring(total)
    )]]
    -- отправить в локальный скрипт
    if resource == "MAGICKA" then
        actor:sendEvent("totalM", total)
    elseif resource == "HEALTH" then
        actor:sendEvent("totalH", total)
    elseif resource == "FATIGUE" then
        actor:sendEvent("totalF", total)
    end

    actor_state_res.last_value = total
    actor_state_res.last_regen_honest_timer = trcmtimer.honest_game_timer
end
------------------------------------------------------------------
--? Основаная управляющая функция
local function main(isEnabled, isEnabledRegenPlayer, isEnabledRegenNPC, isEnabledThresholdPlayer, isEnabledThresholdNPC, resource, resource_treshold, attrs, actor, actor_state_id, actor_lvl, isPlayer, override_settings)
    if (isPlayer and not isEnabled:get(isEnabledRegenPlayer)) or
   (not isPlayer and not isEnabled:get(isEnabledRegenNPC)) then
        return
    end

    local selectedThresholdKey = isPlayer and isEnabledThresholdPlayer or isEnabledThresholdNPC
    local settingsCategory = (override_settings and isPlayer) and "player" or "common"
    --print("FOR SETTS CATEGORY ", " override_settings= ", override_settings, " isPlayer= ", isPlayer, " isThresholdEnabled= ", selectedThresholdKey, " settingsCategory= ", settingsCategory)
    local actor_state_res = actor_state_id[resource]
    local current = round(getDynamic(actor)[resource .. "_CURRENT"], 3)
    local max = round(getDynamic(actor)[resource .. "_MAX"], 3)
    --[[print(
    " / resource " .. tostring(resource) ..
    " / CURRENT " .. tostring(current)
    )]]
    if isRegenAllowed(resource, actor, current, max) then
        local isDelayBool = isDelay(resource, resource_treshold, attrs, isEnabled:get(selectedThresholdKey), actor, actor_lvl, actor_state_res, actor_state_id, current, settingsCategory)
        regen(resource, attrs, actor, actor_lvl, actor_state_res, isDelayBool, max, settingsCategory)
    end
    -- в любом случае нужно обновить, что бы дельта была всегда актуальная
    actor_state_res.last_regen_time = round(core.getGameTime(), 3)
end
------------------------------------------------------------------
-- 0.05 реальной секунды. ускорится игровое время врядли может. а если встанет на > 0.05сек, то таймер/длительность штрафа/дельты регена не идут
local EPSILON = 0.05 * core.getGameTimeScale()
local delta_time = 0

local function onUpdate(dt)
    -- обращение к основному коду 4 раза в секунду
    delta_time = delta_time + dt
    if delta_time < 0.2 then return end
    delta_time = 0

    -- изобретаю Честный таймер с игровым временем..
    -- необходимо для предсказуемой регенирации неактивных актеров. и за краткое время и за длительное.
    -- и еще, что бы выключить реген во время ожидания.
    local now_real_time = round(core.getRealTime(), 3)
    local now_game_time = round(core.getGameTime(), 3)
    local delta_real_time = now_real_time - (trcmtimer.last_real_time or now_real_time)
    local delta_game_time = now_game_time - (trcmtimer.last_game_time or now_game_time)
    local expected_delta_game_time = delta_real_time * core.getGameTimeScale()
    -- если ожидаемое и реальное совпадает, значит не было пауз или скачков(ожидание T) и таймер нужно обновить
    if math.abs(expected_delta_game_time - delta_game_time) < EPSILON then
        trcmtimer.honest_game_timer = round((trcmtimer.honest_game_timer or 0) + delta_game_time, 3)
    end
    trcmtimer.last_real_time = round(now_real_time, 3)
    trcmtimer.last_game_time = round(now_game_time, 3)

    -- основа
    local isEnabled = settingsMap["common"]["IS_ENABLED"]
    local override_settings = settingsMap["player"]["IS_ENABLED"]:get("override_settings_enabled")
    for _, actor in ipairs(world.activeActors) do
        --print("onUpdate==========================================")
        local actor_lvl = types.Actor.stats.level(actor).current
        local actor_state_id = findOrCreateActorState(actor) -- создать/найти таблицы сразу для всех.
        local isPlayer = false
        if tostring(actor.type) == "Player" then
            isPlayer = true
        end
        --print("WHO= ", actor.recordId, " lvl= ", actor_lvl, " type= ", actor.type, " isPlayer= ", isPlayer)
        if not isActorDead_and_MarkToDelete(actor_state_id, actor) then -- если мертвый, то пометить на удаление и перейти к следующему актеру
            main(isEnabled, "Magicka_Regen_Player_Is_Enabled", "Magicka_Regen_NPC_Is_Enabled", "Magicka_Treshold_Player_Is_Enabled", "Magicka_Treshold_NPC_Is_Enabled", "MAGICKA", "MAGICKA_TRESHOLD", ATTRIBUTES, actor, actor_state_id, actor_lvl, isPlayer, override_settings)
            main(isEnabled, "Fatigue_Regen_Player_Is_Enabled", "Fatigue_Regen_NPC_Is_Enabled", "Fatigue_Treshold_Player_Is_Enabled", "Fatigue_Treshold_NPC_Is_Enabled", "FATIGUE", "FATIGUE_TRESHOLD", ATTRIBUTES, actor, actor_state_id, actor_lvl, isPlayer, override_settings)
            main(isEnabled, "Health_Regen_Player_Is_Enabled", "Health_Regen_NPC_Is_Enabled", "Health_Treshold_Player_Is_Enabled", "Health_Treshold_NPC_Is_Enabled", "HEALTH", "HEALTH_TRESHOLD", ATTRIBUTES, actor, actor_state_id, actor_lvl, isPlayer, override_settings)
        end
    end
end

-- распечатать таблицу
--[[
local function dumpStates(states)
    for id, data in pairs(states) do
        print("Actor ID:", id)
        print("  delete:", tostring(data.delete))
        print("  last_seen_time:", tostring(data.last_seen_time))
        for _, res in ipairs({"HEALTH", "FATIGUE", "MAGICKA"}) do
            local resData = data[res]
            if resData then
                print("  " .. res .. ":")
                for k, v in pairs(resData) do
                    print("    " .. tostring(k) .. " = " .. tostring(v))
                end
            end
        end
        print("") -- пустая строка между акторами
    end
end]]



local function onSave()
    local now = core.getGameTime()
    local scale = core.getGameTimeScale()
    local STALE = 2700000 -- удалять через игровой месяц

    -- проверка флага сброса
    local shouldReset = settingsMap["common"]["IS_ENABLED"]
    if shouldReset:get("reset_tables") == true then
        trcmstates = {}
        trcmtimer = {}
        shouldReset:set("reset_tables", false)
        --print("[onSave] Сброшены таблицы states и timer")
        return trcmstates, trcmtimer
    end

    -- удалить мертвых
    for id, actorData in pairs(trcmstates) do
        if actorData.delete == true then
            trcmstates[id] = nil

        -- удалить, которых видел давно(остались неактивными в локации)
        elseif actorData.last_seen_time and ((now - actorData.last_seen_time) / scale) > STALE then
            trcmstates[id] = nil
        end
    end

    return trcmstates, trcmtimer
end



local function onLoad(savedStates, savedTimer)
    if savedStates then trcmstates = savedStates end
    if savedTimer then trcmstates = savedTimer end
    --dumpStates(trcmstates)
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onSave = onSave,
        onLoad = onLoad,
    }
}