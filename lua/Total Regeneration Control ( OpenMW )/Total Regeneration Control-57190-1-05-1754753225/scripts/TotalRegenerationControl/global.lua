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
-- Дэбаг
local debugOnUpdate = false
local debugMain = false
local debugRegen = false
local debugDelayUpdateOrNot = false

local function makeDebugLogger(flagRef)
    return function(msgFunc)
        if flagRef() then
            print(msgFunc())
        end
    end
end

local onUpdateLog = makeDebugLogger(function() return debugOnUpdate end)
local mainLog = makeDebugLogger(function() return debugMain end)
local regenLog = makeDebugLogger(function() return debugRegen end)
local delayUpdateOrNotLog = makeDebugLogger(function() return debugDelayUpdateOrNot end)
-----------------------------------------------------------------------------------------------------
-- ВСЕ округлять. почему-то после 5 цифры после запятой могут быть неверные значения
local function round(num, n)
    local mult = 10^(n or 0)
    return math.floor(num * mult + 0.5) / mult
end

-- создать/найти актера в таблице.
local function findOrCreateActorState(actor)
    local id = actor.id
    local state = trcmstates[id]

    -- если актер в таблице, то функция прерывается и значения не перезаписываются
    if state then
        return state
    end

    -- если нет - создать
    state = {}
    trcmstates[id] = state

    -- создать ключи
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
local function delayUpdateOrNot(current, actor_state_res, isThresholdEnabled, resource_threshold, attrs, actor, actor_lvl, settingsCategory)
    local last = actor_state_res.last_value or current
    delayUpdateOrNotLog(function() return string.format("delay_resource > 0, HEALTH | actor_state_res.last_value= %s | current= %s", actor_state_res.last_value, current) end)
    if current < last then
        delayUpdateOrNotLog(function() return ("current < last") end)
        if isThresholdEnabled then
            delayUpdateOrNotLog(function() return ("threshold is ENABLED") end)
            local diff = round((last - current), 4)
            delayUpdateOrNotLog(function() return string.format("DIFF = %.20f", diff) end)
            local threshold_amount = round(calcThreshold(resource_threshold, attrs, actor, actor_lvl, settingsCategory), 4)
            if diff > threshold_amount then
                delayUpdateOrNotLog(function() return ("diff > threshold_amount") end)
                delayUpdateOrNotLog(function() return string.format("YES UPDATE threshold_amount = %.20f", threshold_amount) end)
                return true
            else
                delayUpdateOrNotLog(function() return ("diff < threshold_amount") end)
                delayUpdateOrNotLog(function() return string.format("DONT UPDATE threshold_amount = %.20f", threshold_amount) end)
                return false
            end
        else
            delayUpdateOrNotLog(function() return ("YES UPDATE, threshold is DISABLED ") end)
            return true
        end
    end
    delayUpdateOrNotLog(function() return ("DONT UPDATE, current >= last") end)
    return false
end

--? Проверка задержки для регенирации
local function isDelay(resource, resource_threshold, attrs, isThresholdEnabled, actor, actor_lvl, actor_state_res, actor_state_id, current, settingsCategory, isAbuseEnabled)
    local delay_resource = settingsMap[settingsCategory][resource]:get('delay_resource') or 0
    if delay_resource == 0 then
        return false
    end

    local game_time = round(core.getGameTime(), 4)
    local game_time_honest = trcmtimer.honest_game_timer
    local delay_end_time = actor_state_res.delay_end_time or 0
    local delay_end_time_honest = actor_state_res.delay_end_time_honest or 0
    -- обновить состояния
    if resource ~= "HEALTH" then
        -- MAGICKA / FATIGUE
        if delay_resource > 0 then
            local update_delay_bool = delayUpdateOrNot(current, actor_state_res, isThresholdEnabled, resource_threshold, attrs, actor, actor_lvl, settingsCategory)
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
            local updateDelayBool = delayUpdateOrNot(current, actor_state_res, isThresholdEnabled, resource_threshold, attrs, actor, actor_lvl, settingsCategory)
            if updateDelayBool then
                delay_end_time = game_time + delay_resource * core.getGameTimeScale()
                delay_end_time_honest = game_time_honest + delay_resource * core.getGameTimeScale()

                local delay_hp_for_magicka = settingsMap[settingsCategory]["MAGICKA"]:get('delay_hp_for_magicka') or 0
                local delay_hp_for_fatigue = settingsMap[settingsCategory]["FATIGUE"]:get('delay_hp_for_fatigue') or 0

            -- если задержка срабатывает для хп, то проверить нужно ли обновлять задержку для маны/выносливости 
                if delay_hp_for_magicka > 0 then
                    local delay_end_time_magicka = round((game_time + delay_hp_for_magicka * core.getGameTimeScale()), 4)
                    local delay_end_time_magicka_honest = round((game_time_honest + delay_hp_for_magicka * core.getGameTimeScale()), 4)
                    if delay_end_time_magicka > (actor_state_id["MAGICKA"].delay_end_time or 0) then
                        actor_state_id["MAGICKA"].delay_end_time = delay_end_time_magicka
                        actor_state_id["MAGICKA"].delay_end_time_honest = delay_end_time_magicka_honest
                    end
                end

                if delay_hp_for_fatigue > 0 then
                    local delay_end_time_fatigue = round((game_time + delay_hp_for_fatigue * core.getGameTimeScale()), 4)
                    local delay_end_time_fatigue_honest = round((game_time_honest + delay_hp_for_fatigue * core.getGameTimeScale()), 4)
                    if delay_end_time_fatigue > (actor_state_id["FATIGUE"].delay_end_time or 0) then
                        actor_state_id["FATIGUE"].delay_end_time = delay_end_time_fatigue
                        actor_state_id["FATIGUE"].delay_end_time_honest = delay_end_time_fatigue_honest
                    end
                end
            end
        end
    end

    actor_state_res.delay_end_time = round(delay_end_time, 4)
    actor_state_res.delay_end_time_honest = round(delay_end_time_honest, 4)

    if isAbuseEnabled then
        return game_time < (actor_state_res.delay_end_time)
    else
        return game_time_honest < (actor_state_res.delay_end_time_honest)
    end
end

--? Вычисления регенирации и обновление показателя
local function regen(resource, attrs, actor, actor_lvl, actor_state_res, isDelayBool, max, settingsCategory, isAbuseEnabled)
    local settingsR = settingsMap[settingsCategory][resource]
    local attr = getAttribute(actor)
	local perc = getPercent(settingsCategory, resource)
    -- сколько регена в секунду ожидается в соответсвии от настроек и атрибутов
    local base = settingsR:get("base_regen") or 0
    local byLvl = settingsR:get("regen_by_level") or 0
    local maxLvl = settingsR:get("regen_max_level") or 10000
    local cap = settingsR:get("regen_cap") or 10000

    local regen_per_second = base + math.min(actor_lvl, maxLvl) * byLvl
    for _, name in ipairs(attrs) do
        regen_per_second = regen_per_second + (attr[name] * perc[name] / 100)
    end

    local now_game_time = round(core.getGameTime(), 4)
    local last_game_time = actor_state_res.last_regen_time or now_game_time
    local delta_game = round((now_game_time - last_game_time) / core.getGameTimeScale(), 4)

    local delay_strength = (settingsR:get('delay_strength') or 0)

    local amount = 0
    -- Если актер был не активен(в другой локации). тик скрипта с запасом, но меньше двух тиков.
    if delta_game > 0.4 and not isAbuseEnabled then

        local now_honest_time = trcmtimer.honest_game_timer
        local last_honest_time = actor_state_res.last_regen_honest_timer or now_honest_time
        local total_honest_delta = round((now_honest_time - last_honest_time) / core.getGameTimeScale(), 4)
        local delay_end_time_honest = actor_state_res.delay_end_time_honest or 0

        regenLog(function() return string.format(
        "+++++HONEST TIMER \nlast_honest_game_time= %s | now_honest_time= %s | delay_end_time_honest= %s delta_game= %s",
        last_honest_time, now_honest_time, delay_end_time_honest, delta_game)
        end)

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
                regenLog(function() return string.format("1 - time_without_penalty= %s", time_without_penalty) end)
            -- 2: задержка заканчивается В ТЕЧЕНИЕ периода отсутствия
            elseif delay_end_time_honest > last_honest_time and delay_end_time_honest < now_honest_time then
                -- часть времени была с задержкой, часть - без
                time_with_penalty = (delay_end_time_honest - last_honest_time) / core.getGameTimeScale()
                time_without_penalty = (now_honest_time - delay_end_time_honest) / core.getGameTimeScale()
                regenLog(function() return string.format("2 - time_with_penalty= %s", time_with_penalty) end)
                regenLog(function() return string.format("2 - time_without_penalty= %s", time_without_penalty) end)
            -- 3: задержка еще НЕ закончилась к моменту возвращения
            elseif delay_end_time_honest >= now_honest_time then
                -- весь период отсутствия прошел под действием задержки
                time_with_penalty = total_honest_delta
                regenLog(function() return string.format("3 - time_with_penalty= %s", time_with_penalty) end)
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
            amount = round(math.max(0, math.min(amount, cap)), 4)
            regenLog(function() return string.format("regen_per_second= %s | amount * delay * delay_strength= %s", regen_per_second, amount) end)
        end
    else
        regenLog(function() return string.format(
        "+++++REGULAR DELTA \nlast_regen_time= %s | now_game_time= %s \nnow_honest_time= %s | actor_state_res.delay_end_time_honest= %s \ndelta_game= %s",
        last_game_time, now_game_time, trcmtimer.honest_game_timer, actor_state_res.delay_end_time_honest, delta_game)
        end)

        amount = regen_per_second * delta_game
        cap = cap * delta_game
        regenLog(function() return string.format("amount * delta= %s", amount) end)
        -- если идет задержка, то пересчитать реген
        if isDelayBool then
            amount = amount * (1 - delay_strength / 100)
        end
        amount = round(math.max(0, math.min(amount, cap)), 4)
        regenLog(function() return string.format("regen_per_second= %s | amount * delta * delay_strength= %s", regen_per_second, amount) end)
    end
    -- определяю current прямо здесь, что бы между тем как скрипт определит current и присвоит персонажу новое значение
    -- персонаж не успел потратить ресурс. иначе персонаж как бы не потратит ресурс за действие.
    local current = round(getDynamic(actor)[resource .. "_CURRENT"], 4)
    local total = round(math.min(current + amount, max), 4)
    regenLog(function() return string.format("isDelay %s | total %s", isDelayBool, total) end)

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
local function main(isEnabled, isEnabledRegenPlayer, isEnabledRegenNPC, isEnabledThresholdPlayer, isEnabledThresholdNPC, abuseResourceEnabled, resource, resource_treshold, attrs, actor, actor_state_id, actor_lvl, isPlayer, override_settings)
    if (isPlayer and not isEnabled:get(isEnabledRegenPlayer)) or
   (not isPlayer and not isEnabled:get(isEnabledRegenNPC)) then
        return
    end

    local selectedThresholdKey = isPlayer and isEnabledThresholdPlayer or isEnabledThresholdNPC
    local settingsCategory = (override_settings and isPlayer) and "player" or "common"
    local isAbuseEnabled = isEnabled:get(abuseResourceEnabled)

    mainLog(function() return string.format("RESOURCE= %s | isThresholdEnabled= %s | settingsCategory= %s | override_settings= %s", resource, selectedThresholdKey, settingsCategory, override_settings) end)

    local actor_state_res = actor_state_id[resource]
    local current = round(getDynamic(actor)[resource .. "_CURRENT"], 4)
    local max = round(getDynamic(actor)[resource .. "_MAX"], 4)

    if isRegenAllowed(resource, actor, current, max) then
        local isDelayBool = isDelay(resource, resource_treshold, attrs, isEnabled:get(selectedThresholdKey), actor, actor_lvl, actor_state_res, actor_state_id, current, settingsCategory, isAbuseEnabled)
        regen(resource, attrs, actor, actor_lvl, actor_state_res, isDelayBool, max, settingsCategory, isAbuseEnabled)
    end
    -- в любом случае нужно обновить, что бы дельта была всегда актуальная
    actor_state_res.last_regen_time = round(core.getGameTime(), 4)
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
    local now_real_time = round(core.getRealTime(), 4)
    local now_game_time = round(core.getGameTime(), 4)
    local delta_real_time = now_real_time - (trcmtimer.last_real_time or now_real_time)
    local delta_game_time = now_game_time - (trcmtimer.last_game_time or now_game_time)
    local expected_delta_game_time = delta_real_time * core.getGameTimeScale() * world.getSimulationTimeScale()
    -- если ожидаемое и реальное совпадает, значит не было пауз или скачков(ожидание T) и таймер нужно обновить
    if math.abs(expected_delta_game_time - delta_game_time) < EPSILON then
        trcmtimer.honest_game_timer = round((trcmtimer.honest_game_timer or 0) + delta_game_time, 4)
    end
    trcmtimer.last_real_time = round(now_real_time, 4)
    trcmtimer.last_game_time = round(now_game_time, 4)

    -- основа
    local isEnabled = settingsMap["common"]["IS_ENABLED"]
    local override_settings = settingsMap["player"]["IS_ENABLED"]:get("override_settings_enabled")
    for _, actor in ipairs(world.activeActors) do
        onUpdateLog(function() return string.format("onUpdate==========================================") end)
        local actor_lvl = types.Actor.stats.level(actor).current
        local actor_state_id = findOrCreateActorState(actor) -- создать/найти таблицы сразу для всех.
        local isPlayer = false
        if tostring(actor.type) == "Player" then
            isPlayer = true
        end
        onUpdateLog(function() return string.format("WHO= %s | lvl= %s | type= %s | isPlayer= %s", actor.recordId, actor_lvl, actor.type, isPlayer) end)
        if not isActorDead_and_MarkToDelete(actor_state_id, actor) then -- если мертвый, то пометить на удаление и перейти к следующему актеру
            main(isEnabled, "Magicka_Regen_Player_Is_Enabled", "Magicka_Regen_NPC_Is_Enabled", "Magicka_Treshold_Player_Is_Enabled", "Magicka_Treshold_NPC_Is_Enabled", "Magicka_Abuse_T_Is_Enabled", "MAGICKA", "MAGICKA_TRESHOLD", ATTRIBUTES, actor, actor_state_id, actor_lvl, isPlayer, override_settings)
            main(isEnabled, "Fatigue_Regen_Player_Is_Enabled", "Fatigue_Regen_NPC_Is_Enabled", "Fatigue_Treshold_Player_Is_Enabled", "Fatigue_Treshold_NPC_Is_Enabled", "Fatigue_Abuse_T_Is_Enabled", "FATIGUE", "FATIGUE_TRESHOLD", ATTRIBUTES, actor, actor_state_id, actor_lvl, isPlayer, override_settings)
            main(isEnabled, "Health_Regen_Player_Is_Enabled", "Health_Regen_NPC_Is_Enabled", "Health_Treshold_Player_Is_Enabled", "Health_Treshold_NPC_Is_Enabled", "Health_Abuse_T_Is_Enabled", "HEALTH", "HEALTH_TRESHOLD", ATTRIBUTES, actor, actor_state_id, actor_lvl, isPlayer, override_settings)
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
    local STALE = 15600000 -- удалять через 6 игровых месев

    -- проверка флага сброса
    local shouldReset = settingsMap["common"]["IS_ENABLED"]
    if shouldReset:get("reset_tables") == true then
        trcmtimer = {}
        trcmstates = {}
        shouldReset:set("reset_tables", false)

        return {
        timer = trcmtimer,
        states = trcmstates
        }
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

    return {
        timer = trcmtimer,
        states = trcmstates
    }
end



local function onLoad(savedData)
    if savedData then
        if savedData.timer then
            trcmtimer = savedData.timer
        end
        if savedData.states then
            trcmstates = savedData.states
        end
    end
    --dumpStates(trcmstates)
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onSave = onSave,
        onLoad = onLoad,
    }
}