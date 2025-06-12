local print
local state = {
    engaged = {},
    moved = {},
    current_group = {},
    freeze = 0,
    in_combat = false,
    turn_time = 0,
    bonus_effect_instance = nil,
    priority_penalty = { until_time = 0, active = false },
    ui = { turn_time = nil, player_action_time = nil }
}

local config = {
    turn_based = true,
    group_mode = true,
    turn_duration = 4.0,
    turn_duration_minimal = 4.0 / 3,
    time_scale_nonplayer = 1.35,
    time_scale_noatime = 4.0,
    turn_end_bonus = 30,
    alchemy_cost = 2.0,
    enchantment_cost = 2.0,
    item_cost_per_weight = 0.1,
    item_cost_minimal = 0.2,
    stun_cost_mult = 0.5,
    knockdown_cost_mult = 0.7,
    key_end_turn = tes3.scanCode.c,
    key_toggle_turn_based = tes3.scanCode.b,
}

-- local serpent = require("turnbasedcombat.serpent")

-- because userdata doesn't work with plain t[key]
local function userdata_compatible_table(t)
    return setmetatable(t or {}, {
        __index = function (self, k)
            for key, value in pairs(self) do
                if key == k then
                    return value
                end
            end
        end
    })
end

local function reset_state(state)
    for key, value in pairs(state) do
        if type(value) == "table" then
            state[key] = userdata_compatible_table(value)
        end
    end
    local original_state = table.deepcopy(state)
    reset_state = function (state)
        for key, value in pairs(table.deepcopy(original_state)) do
            state[key] = value
        end
        return state
    end
    reset_state(state)
end
reset_state(state)

local function xpcall_wrap(f)
    return function (...)
        local s, result = xpcall(f, debug.traceback, ...)
        if not s then
            print(string.format('----------\n%s\n----------', result))
        else
            return result
        end
    end
end

local function unregister_event_handlers()
    for _, v in ipairs(state.eh or {}) do
        local event_type, callback, options = unpack(v)
        event.unregister(event_type, callback, options)
    end
    state.eh = {}
end

local function register_event_handler(event_type, callback, options)
    callback = xpcall_wrap(callback)
    table.insert(state.eh, { event_type, callback, options })
    event.register(event_type, callback, options)
end

local function is_turn_based()
    return config.turn_based or state.in_combat
end

local function player_and_followers()
    local result = userdata_compatible_table({ [tes3.mobilePlayer] = tes3.mobilePlayer })
    for _, friendly in ipairs(tes3.mobilePlayer.friendlyActors) do
        if friendly.aiPlanner ~= nil then
            local package_type = friendly.aiPlanner:getActivePackage() and friendly.aiPlanner:getActivePackage().type
            if package_type == tes3.aiPackage.follow or package_type == tes3.aiPackage.escort then
                result[friendly] = friendly
            end
        end
    end
    return result
end

local function calc_priority(mobile)
    return (0.5 * mobile.agility.current) + mobile.speed.current
end

local function with_priority_penalty(mobile, ...)
    if state.priority_penalty.until_time > 0 then
        if tes3.getSimulationTimestamp(false) <= state.priority_penalty.until_time then
            state.priority_penalty.active = true
        elseif state.priority_penalty.active then
            state.priority_penalty.active = false
        end
        if state.priority_penalty.active then
            if state.current_group[tes3.mobilePlayer] then
                state.priority_penalty.active = false
                state.priority_penalty.until_time = 0
            elseif player_and_followers()[mobile] then
                return -1
            end
        else
            state.priority_penalty.until_time = 0
        end
    end
    return ...
end

local engaged_queue = (function ()
    local function sort_func(a, b)
        return a[2] > b[2]
    end
    return function (engaged_table)
        local result = {}
        local es_scores = {}
        for _, e in pairs(engaged_table) do
            es_scores[#es_scores+1] = { e, with_priority_penalty(e.mobile, calc_priority(e.mobile)) }
        end
        table.sort(es_scores, sort_func)
        for _, es_score in ipairs(es_scores) do
            result[#result+1] = es_score[1]
        end
        return result
    end
end)()

local is_fighting = (function ()
    local ENGAGED_AI_STATES = table.invert({ 3, 5, 6 }) -- attacking, approaching, fleeing
    return function (mobile)
        if mobile.isDead or not mobile.inCombat then
            return false
        end
        if mobile ~= tes3.mobilePlayer then
            if not ENGAGED_AI_STATES[mobile.actionData.aiBehaviorState] then
                return false
            end
        end
        return true
    end
end)()

local function on_loaded()
    tes3.worldController.simulationTimeScalar = 1
    state.priority_penalty.until_time = tes3.getSimulationTimestamp(false) + 2
    local data = tes3.mobilePlayer.reference.data["turn_based_combat"]
    if data then
        config.turn_based = data.turn_based
    end

    local ehs = table.deepcopy(state.eh)
    reset_state(state)
    state.eh = ehs
end

-- "freeze" magic effect by setting time it was active to big negative value
-- and resistance to 100 - for over time effects it will look like actual effect is gone
-- but for others it must still be there (hopefully)
local freeze_magic_effect = (function()
    local EFFECTS_TO_CHANGE_RESIST = table.invert({
        tes3.effect["fireDamage"],
        tes3.effect["shockDamage"],
        tes3.effect["frostDamage"],
        tes3.effect["drainAttribute"],
        tes3.effect["drainHealth"],
        tes3.effect["drainMagicka"],
        tes3.effect["drainFatigue"],
        tes3.effect["drainSkill"],
        tes3.effect["damageAttribute"],
        tes3.effect["damageHealth"],
        tes3.effect["damageMagicka"],
        tes3.effect["damageFatigue"],
        tes3.effect["damageSkill"],
        tes3.effect["poison"],
        tes3.effect["disintegrateWeapon"],
        tes3.effect["disintegrateArmor"],
        tes3.effect["restoreAttribute"],
        tes3.effect["restoreHealth"],
        tes3.effect["restoreMagicka"],
        tes3.effect["restoreFatigue"],
        tes3.effect["restoreSkill"],
        tes3.effect["absorbAttribute"],
        tes3.effect["absorbHealth"],
        tes3.effect["absorbMagicka"],
        tes3.effect["absorbFatigue"],
        tes3.effect["absorbSkill"],
        tes3.effect["sunDamage"],
    })
    return function(active_magic_effect)
        active_magic_effect.effectInstance.timeActive = -3600
        if EFFECTS_TO_CHANGE_RESIST[active_magic_effect.effectId] then
            active_magic_effect.effectInstance.resistedPercent = 100
        end
    end
end)()

-- "unfreeze" magic effects for engaged by restoring time and initial resistance values
local function unfreeze_magic(engaged, time, effects)
    for _, ame in ipairs(effects or engaged.mobile.activeMagicEffectList) do
        local effect_data = engaged.magic_effects[ame.effectInstance]
        if effect_data then
            ame.effectInstance.timeActive = effect_data.time_active_actual
            ame.effectInstance.resistedPercent = effect_data.resistedPercent_initial
            effect_data.time_left_round = time or 0
        end
    end
end

local function unfreeze_magic_by_casters(engaged, time, casters_group, inverse)
    local effects_to_unfreeze = {}
    for _, ame in ipairs(engaged.mobile.activeMagicEffectList) do
        local effect_data = engaged.magic_effects[ame.effectInstance]
        if effect_data and (casters_group[effect_data.caster] and not inverse) then
            effects_to_unfreeze[#effects_to_unfreeze+1] = ame
        end
    end
    unfreeze_magic(engaged, time, effects_to_unfreeze)
end

-- look for new effects and tick active (caster's turn), freeze if no time left or just detected
local function update_magic_effects(engaged, delta)
    for _, ame in ipairs(engaged.mobile.activeMagicEffectList) do
        local effect_data = engaged.magic_effects[ame.effectInstance]

        -- look for new effect
        if not effect_data then
            local caster_mobile = (ame.instance.caster and state.engaged[ame.instance.caster.mobile] and ame.instance.caster.mobile) or engaged.mobile
            local effect_instance = ame.effectInstance
            -- for Paralyze, the caster should always be the target
            if ame.effectId == tes3.effect.paralyze then
                caster_mobile = engaged.mobile
            end
            effect_data = {
                resistedPercent_initial = effect_instance.resistedPercent,
                time_active_actual = effect_instance.timeActive,
                -- if it's the caster's turn, make it active for the caster's action time left
                time_left_round = (state.current_group[caster_mobile] and state.engaged[caster_mobile].action_time_left) or 0,
                caster = caster_mobile
            }
            engaged.magic_effects[ame.effectInstance] = effect_data
        end

        -- tick active effect
        if ame.effectInstance.timeActive >= 0 then
            effect_data.time_left_round = effect_data.time_left_round - delta
            effect_data.time_active_actual = ame.effectInstance.timeActive
            if effect_data.time_left_round <= 0 then
                freeze_magic_effect(ame)
            end
        end
    end
end

local function update_action_time(engaged, delta)
    local mobile = engaged.mobile
    local new_action_time = engaged.action_time_left

    if state.current_group[mobile] then
        if mobile.isRunning or mobile.isWalking or ((mobile.isFlying or mobile.isSwimming) and (mobile.isMovingForward or mobile.isMovingBack or mobile.isMovingLeft or mobile.isMovingRight)) then
            new_action_time = new_action_time - delta
        end
        if mobile.isAttackingOrCasting then
            if mobile.animationController:calculateAttackSwing() < 1 then
                new_action_time = new_action_time - delta
            end
        end
    end
    local mult = 0
    if mobile.isKnockedOut or mobile.isJumping or (mobile.isParalyzed and state.current_group[mobile]) then
        mult = 1
    elseif mobile.isKnockedDown then
        mult = config.knockdown_cost_mult
    elseif mobile.isHitStunned then
        mult = config.stun_cost_mult
    end
    new_action_time = new_action_time - delta * mult
    engaged.action_time_left = new_action_time
end

local function update_controls(engaged)
    local mobile = engaged.mobile
    if state.current_group[engaged.mobile] and engaged.action_time_left > 0 then
        if mobile ~= tes3.mobilePlayer and mobile.isAttackingOrCasting then
            return
        end
        return
    end
    if mobile == tes3.mobilePlayer then
        mobile.controlsDisabled = true
    else
        mobile.actionData.aiBehaviorState = 5 -- why 5? at 6 they stand still if levitating
        if not mobile.isDead then
            mobile.actionData.animationAttackState = 0 -- sometimes they stuck playing attacking animation
        end
    end
end

local function next_group(engaged_table)
    local result = userdata_compatible_table()
    local hostile_mobiles = userdata_compatible_table()
    for _, engaged in ipairs(engaged_queue(engaged_table)) do
        if not state.moved[engaged.mobile] and not hostile_mobiles[engaged.mobile] then
            -- cross check for hostiles
            local is_hostile = false
            for _, hostile in ipairs(engaged.mobile.hostileActors) do
                if result[hostile] then
                    is_hostile = true
                    break
                end
            end
            if not is_hostile then
                result[engaged.mobile] = engaged
                if not config.group_mode then
                    break
                end
                table.copymissing(hostile_mobiles, engaged.mobile.hostileActors)
            end
        end
    end
    return result
end

local function are_groups_fighting(g1, g2)
    local hostiles = {}
    for m, _ in pairs(g1) do
        for _, h in ipairs(m.hostileActors) do
            hostiles[h] = h
        end
    end
    for m, _ in pairs(g2) do
        if hostiles[m] then
            return true
        end
        for _, h in ipairs(m.hostileActors) do
            if state.current_group[h] then
                return true
            end
        end
    end
    return false
end

local function remove_engaged(engaged)
    state.engaged[engaged.mobile] = nil
    state.current_group[engaged.mobile] = nil
    state.moved[engaged.mobile] = nil
    unfreeze_magic(engaged)
end

local function try_end_combat(forced)
    if state.in_combat then
        local combat_to_end = false
        if not forced then
            if state.current_group[tes3.mobilePlayer] then
                if not are_groups_fighting(state.current_group, state.engaged) then
                    combat_to_end = true
                end
            else
                if not next(state.engaged) then
                    combat_to_end = true
                end
            end
            if not state.engaged[tes3.mobilePlayer] then
                combat_to_end = true
            end
        end
        if forced or combat_to_end then
            for _, engaged in pairs(state.engaged) do
                remove_engaged(engaged)
            end
            tes3.worldController.simulationTimeScalar = 1
            tes3.mobilePlayer.controlsDisabled = false
            state.in_combat = false
            return true
        end
    end
    return false
end

local function disengage(engaged)
    remove_engaged(engaged)
end

local function update_fatigue(engaged, delta)
    if state.current_group[engaged.mobile] and state.turn_time < config.turn_duration then
        return
    end
    local fatigue = engaged.mobile.fatigue.current
    if fatigue <= 1 and fatigue > 0 then
        return
    end
    tes3.modStatistic({
        reference = engaged.mobile,
        name = "fatigue",
        current = delta * -(2.5 + (0.02 * engaged.mobile.endurance.current)) -- 2.5 + (0.02 * Endurance) fatigue/sec (UESP)
    })
end

local function update_ui()
    if not is_turn_based() and not state.ui.player_action_time then
        return
    end
    if state.in_combat then
        local ui_player_action_time = state.ui.player_action_time
        local ui_turn_time = state.ui.turn_time
        if not ui_player_action_time then
            local bar = tes3ui.findMenu("MenuMulti"):createFillBar({current = config.turn_duration * 1000, max = config.turn_duration * 1000 })
            bar.absolutePosAlignX = 0.01
            bar.absolutePosAlignY = 0.85
            bar.width = 106
            bar.height = 20
            bar.visible = true
            bar.widget.fillColor = { 0.05, 0.7, 0.05 }
            bar:getTopLevelMenu():updateLayout()
            state.ui.player_action_time = bar
            ui_player_action_time = bar
        end
        if not ui_turn_time then
            local bar = tes3ui.findMenu("MenuMulti"):createFillBar({ current = (config.turn_duration + 1) * 1000, max = (config.turn_duration + 1) * 1000 })
            bar.absolutePosAlignX = 0.01
            bar.absolutePosAlignY = 0.827
            bar.width = 106
            bar.height = 20
            bar.visible = true
            bar.widget.fillColor = { 1, 0.6, 0.24 }
            bar:getTopLevelMenu():updateLayout()
            state.ui.turn_time = bar
            ui_turn_time = bar
        end
        ui_player_action_time.widget.current = state.engaged[tes3.mobilePlayer].action_time_left * 1000
        if state.current_group[tes3.mobilePlayer] then
            ui_player_action_time.widget.fillColor = { 0.05, 0.7, 0.05 }
            ui_player_action_time.width = 116
        else
            ui_player_action_time.widget.fillColor = { 0.7, 0.05, 0.05}
            ui_player_action_time.width = 106
        end
        if ui_turn_time then
            ui_turn_time.widget.current = math.max(0, (config.turn_duration + 1 - state.turn_time) * 1000)
        end
    else
        if state.ui.player_action_time then
            state.ui.player_action_time:destroy()
            state.ui.player_action_time = nil
            state.ui.turn_time:destroy()
            state.ui.turn_time = nil
        end
    end
end

local function do_once_simulate()
    tes3.worldController.simulationTimeScalar = 1
    state.priority_penalty.until_time = tes3.getSimulationTimestamp(false) + 2
    local data = tes3.mobilePlayer.reference.data["turn_based_combat"]
    if data then
        config.turn_based = data.turn_based
    end
    do_once_simulate = function () end
end

local simulate = (function ()
    local last_time = -1
    return function ()
        do_once_simulate()
        update_ui()

        local delta = 0
        local current_time = tes3.getSimulationTimestamp(false)
        if last_time > 0 then
            delta = current_time - last_time
        end
        last_time = current_time
        
        if not state.in_combat then
            return
        end

        -- update engaged
        for mobile, engaged in pairs(state.engaged) do
            if mobile.isDead then
                disengage(engaged)
            else
                update_action_time(engaged, delta)
                update_magic_effects(engaged, delta)
                update_fatigue(engaged, delta)
                update_controls(engaged)
            end
        end

        -- change simulation time scale for groups without player or/and with no action time left
        local simulation_time_scale = config.time_scale_noatime
        for mobile, engaged in pairs(state.current_group) do
            if not mobile.isParalyzed and (engaged.action_time_left > 0 or mobile.isAttackingOrCasting) then
                simulation_time_scale = (state.current_group[tes3.mobilePlayer] and state.engaged[tes3.mobilePlayer].action_time_left > 0) and 1 or config.time_scale_nonplayer
                break
            end
        end
        tes3.worldController.simulationTimeScalar = simulation_time_scale


        -- check for end turn, find next group or begin new round
        local turn_to_end = true
        for mobile, engaged in pairs(state.current_group) do
            if engaged.action_time_left > 0 or mobile.isAttackingOrCasting then
                turn_to_end = false
            end
        end

        -- turn lasts at least config.turn_time + 1 for non empty groups to let magic work
        -- but not more for non player group in case AI is stuck
        state.turn_time = state.turn_time + delta
        if turn_to_end then
            if state.turn_time < config.turn_duration + 1 and next(state.current_group) then
                turn_to_end = false
            end
        elseif state.turn_time >= config.turn_duration + 1 and not (state.current_group[tes3.mobilePlayer] and (state.engaged[tes3.mobilePlayer].action_time_left > 0 or tes3.mobilePlayer.isAttackingOrCasting)) then
            turn_to_end = true
        end

        -- if the group finished it's turn, look for new group or begin new round
        if turn_to_end then
            tes3.worldController.simulationTimeScalar = 1
            for _, engaged in pairs(state.current_group) do
                engaged.action_time_left = math.clamp(engaged.action_time_left + config.turn_duration, config.turn_duration_minimal, config.turn_duration)
                unfreeze_magic_by_casters(engaged, config.turn_duration, state.engaged, true)
            end
            -- remove action time bonus if player in current group
            if state.current_group[tes3.mobilePlayer] and state.bonus_effect_instance then
                local effect_instance = state.bonus_effect_instance:getEffectInstance(0, tes3.mobilePlayer.reference)
                local effect_data = state.engaged[tes3.mobilePlayer].magic_effects[effect_instance]
                if effect_data and effect_data.time_active_actual > 1 then
                    effect_instance.timeActive = config.turn_duration
                    state.bonus_effect_instance = nil
                end
            end
            for mobile, engaged in pairs(state.engaged) do
                if not is_fighting(mobile) then
                    disengage(engaged)
                end
            end
            if try_end_combat() then
                return
            end
            
            state.current_group = next_group(state.engaged)
            state.turn_time = 0
            if not next(state.current_group) then
                -- new round
                state.moved = userdata_compatible_table()
            else
                -- next turn
                for _, engaged in pairs(state.engaged) do
                    unfreeze_magic_by_casters(engaged, config.turn_duration, state.current_group)
                end
                for mobile, engaged in pairs(state.current_group) do
                    state.moved[mobile] = true
                    engaged.action_time_left = math.clamp(engaged.action_time_left, config.turn_duration_minimal, config.turn_duration)
                end
                if state.current_group[tes3.mobilePlayer] then
                    tes3.mobilePlayer.controlsDisabled = false
                end
            end
        end
    end
end)()

local function engage(mobile)
    if mobile and not state.engaged[mobile] then
        state.engaged[mobile] = {
            mobile = mobile,
            -- safe_reference = tes3.makeSafeObjectHandle(mobile.reference),
            action_time_left = config.turn_duration,
            priority = 0,
            magic_effects = userdata_compatible_table(),
        }
    end
end

-- start combat if one of the actors is player or player's follower
local function try_start_combat(attacker_mobile, target_mobile)
    if is_turn_based() and not state.in_combat and attacker_mobile and target_mobile then
        local player_and_followers = player_and_followers()
        if player_and_followers[target_mobile] or player_and_followers[attacker_mobile] then
            state.in_combat = true
        end
    end
    if is_turn_based() and state.in_combat then
        engage(attacker_mobile)
        engage(target_mobile)
        return true
    end
end

local function on_combat_started(e)
    if is_turn_based() and state.in_combat then
        engage(e.actor)
        engage(e.target)
    end
end

local function remove_action_time(mobile, amount)
    local engaged = state.engaged[mobile]
    if engaged then
        engaged.action_time_left = engaged.action_time_left - (amount or 1000)
        if tes3ui.menuMode() and engaged.action_time_left <= 0 then
            tes3ui.leaveMenuMode()
        end
    end
end

local function remove_action_time_by_item(mobile, item)
    remove_action_time(mobile, math.max(
        config.item_cost_minimal,
        item.weight and (item.weight * config.item_cost_per_weight) or 0
    ))
end

return function (print_func)
    print = print_func

    unregister_event_handlers()

    register_event_handler(tes3.event["keyDown"], function ()
        if tes3ui.menuMode() then
            return
        end
        if is_turn_based() then
            if state.in_combat then
                state.priority_penalty.until_time = tes3.getSimulationTimestamp(false) + config.turn_duration
                try_end_combat(true)
            else
                tes3.messageBox("Disabled turn based combat")
                config.turn_based = false
            end
        else
            config.turn_based = true
            tes3.messageBox("Enabled turn based combat")
        end
    end, { filter = config.key_toggle_turn_based })

    register_event_handler(tes3.event["keyDown"], function ()
        if tes3ui.menuMode() then
            return
        end
        if is_turn_based() and state.in_combat then
            if state.current_group[tes3.mobilePlayer] and state.engaged[tes3.mobilePlayer].action_time_left > 0 then
                local magnitude = config.turn_end_bonus * state.engaged[tes3.mobilePlayer].action_time_left / config.turn_duration
                if magnitude >= 1 then
                    if state.bonus_effect_instance then
                        local effect_instance = state.bonus_effect_instance:getEffectInstance(0, tes3.mobilePlayer.reference)
                        if effect_instance then
                            effect_instance.timeActive = config.turn_duration
                        end
                    end
                    state.bonus_effect_instance = tes3.applyMagicSource({
                        reference = tes3.mobilePlayer,
                        name = "Combat wait bonus",
                        target = tes3.mobilePlayer,
                        effects = {{
                            id = tes3.effect.fortifyAttribute,
                            attribute = tes3.attribute.agility,
                            duration = config.turn_duration + 1,
                            min = magnitude,
                            max = magnitude
                        }}
                    })
                end
                state.engaged[tes3.mobilePlayer].action_time_left = 0
            end
        end
    end, { filter = config.key_end_turn })

    register_event_handler(tes3.event["cellChanged"], xpcall_wrap(function (e)
        local apply_penalty = true
        if e.previousCell then
            apply_penalty = e.previousCell.isInterior or e.cell.isInterior
        end
        if apply_penalty then
            state.priority_penalty.until_time = tes3.getSimulationTimestamp(false) + 2
        end
    end))

    -- alchemy used (only player can use alchemy)
    register_event_handler(tes3.event["equip"], xpcall_wrap(function (e)
        if config.turn_based and state.in_combat then
            if e.reference.mobile == tes3.mobilePlayer then
                if e.item.objectType == tes3.objectType["alchemy"] or e.item.objectType == tes3.objectType["ingredient"] then
                    local reference = e.reference
                    local item = e.item
                    local item_count = tes3.getItemCount({ reference = reference, item = item })
                    local event = tes3ui.menuMode() and tes3.event["uiEvent"] or tes3.event["magicCasted"]
                    register_event_handler(event, xpcall_wrap(function ()
                        if tes3.getItemCount({ reference = reference, item = item }) < item_count then
                            remove_action_time(reference.mobile, config.alchemy_cost)
                        end
                    end), { doOnce = true })
                end
            end
        end
    end))

    -- enchants used
    register_event_handler(tes3.event["magicCasted"], function (e)
        if config.turn_based and state.in_combat then
            if e.source.objectType == tes3.objectType["enchantment"] then
                if e.source.castType == tes3.enchantmentType["onUse"] or e.source.castType == tes3.enchantmentType["castOnce"] then
                    remove_action_time(e.caster.mobile, config.enchantment_cost)
                end
            end
        end
    end)

    -- item equipped
    register_event_handler(tes3.event["equipped"], function (e)
        if config.turn_based and state.in_combat then
            remove_action_time_by_item(e.mobile, e.item)
        end
    end)

    register_event_handler(tes3.event["spellResist"], function (e)
        if is_turn_based() and e.effect and e.effect.object.isHarmful then
            if e.caster and e.target and e.caster.mobile and e.target.mobile then
                try_start_combat(e.caster.mobile, e.target.mobile)
            end
        end
    end)

    register_event_handler(tes3.event["attackHit"], function (e)
        if e.mobile and e.targetMobile then
            try_start_combat(e.mobile, e.targetMobile)
        end
    end)

    register_event_handler(tes3.event["mobileDeactivated"], function (e)
        if state.engaged[e.mobile] then
            disengage(state.engaged[e.mobile])
            try_end_combat()
        end
    end)

    register_event_handler(tes3.event["combatStopped"], function ()
        if is_turn_based() then
            try_end_combat()
        end
    end)

    local effects_to_preserve = {}
    register_event_handler(tes3.event["saved"], function ()
        if is_turn_based() and state.in_combat then
            for _, engaged in pairs(state.engaged) do
                for _, ame in ipairs(engaged.mobile.activeMagicEffectList) do
                    for key, value in pairs(effects_to_preserve[ame.effectInstance] or {}) do
                        ame.effectInstance[key] = value
                    end
                end
            end
            effects_to_preserve = {}
        end
    end)

    register_event_handler(tes3.event["save"], function ()
        tes3.mobilePlayer.reference.data["turn_based_combat"] = { turn_based = config.turn_based }
        if is_turn_based() and state.in_combat then
            effects_to_preserve = userdata_compatible_table()
            for _, engaged in pairs(state.engaged) do
                for _, ame in ipairs(engaged.mobile.activeMagicEffectList) do
                    local effect_data = engaged.magic_effects[ame.effectInstance]
                    if effect_data then
                        effects_to_preserve[ame.effectInstance] = {
                            timeActive = ame.effectInstance.timeActive,
                            resistedPercent = ame.effectInstance.resistedPercent
                        }
                        ame.effectInstance.timeActive = effect_data.time_active
                        ame.effectInstance.resistedPercent = effect_data.resistedPercent_initial
                    end
                end
            end
        end
    end)

    register_event_handler("loaded", on_loaded)
    register_event_handler("simulate", simulate)

    register_event_handler("combatStarted", on_combat_started)
    
    return state
end
