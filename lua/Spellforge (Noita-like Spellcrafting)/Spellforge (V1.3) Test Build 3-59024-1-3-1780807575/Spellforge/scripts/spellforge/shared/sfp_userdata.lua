---@omw-context none
local sfp_userdata = {}

local SCHEMA = "spellforge_sfp_userdata_v1"

local ALLOWED_SCALARS = {
    string = true,
    number = true,
    boolean = true,
}

local function setScalar(out, key, value)
    if ALLOWED_SCALARS[type(value)] then
        out[key] = value
    end
end

local function firstNonNil(...)
    local count = select("#", ...)
    for i = 1, count do
        local value = select(i, ...)
        if value ~= nil then
            return value
        end
    end
    return nil
end

local function mappingField(mapping, key)
    if type(mapping) == "table" then
        return mapping[key]
    end
    return nil
end

local function copyKnownScalars(source, keys)
    local out = {
        spellforge = true,
        schema = SCHEMA,
    }
    for _, key in ipairs(keys) do
        setScalar(out, key, source[key])
    end
    return out
end

function sfp_userdata.schema()
    return SCHEMA
end

function sfp_userdata.buildHelperUserData(args)
    local input = args or {}
    local mapping = input.mapping
    local out = {
        spellforge = true,
        schema = SCHEMA,
    }

    setScalar(out, "runtime", input.runtime or "2.2c_dev_helper")
    setScalar(out, "runtime_generation", input.runtime_generation)
    setScalar(out, "recipe_id", firstNonNil(input.recipe_id, mappingField(mapping, "recipe_id")))
    setScalar(out, "slot_id", firstNonNil(input.slot_id, mappingField(mapping, "slot_id")))
    setScalar(out, "helper_engine_id", firstNonNil(input.helper_engine_id, mappingField(mapping, "engine_id")))
    setScalar(out, "job_kind", input.job_kind or input.kind)
    setScalar(out, "job_id", input.job_id)
    setScalar(out, "parent_job_id", input.parent_job_id)
    setScalar(out, "source_job_id", input.source_job_id)
    setScalar(out, "depth", input.depth)
    setScalar(out, "root_source_slot_id", input.root_source_slot_id)
    setScalar(out, "current_source_slot_id", input.current_source_slot_id)
    setScalar(out, "parent_slot_id", input.parent_slot_id)
    setScalar(out, "payload_depth", input.payload_depth)
    setScalar(out, "nested_stage_kind", input.nested_stage_kind)
    setScalar(out, "nested_stage_index", input.nested_stage_index)
    setScalar(out, "nested_final_fanout", input.nested_final_fanout)
    setScalar(out, "nested_final_fanout_kind", input.nested_final_fanout_kind)
    setScalar(out, "final_fanout_count", input.final_fanout_count)
    setScalar(out, "final_fanout_index", input.final_fanout_index)
    setScalar(out, "source_slot_id", firstNonNil(input.source_slot_id, mappingField(mapping, "trigger_source_slot_id"), mappingField(mapping, "timer_source_slot_id")))
    setScalar(out, "source_prefix_opcode", firstNonNil(input.source_prefix_opcode, mappingField(mapping, "source_prefix_opcode")))
    setScalar(out, "source_postfix_opcode", firstNonNil(input.source_postfix_opcode, mappingField(mapping, "source_postfix_opcode")))
    setScalar(out, "payload_slot_id", input.payload_slot_id)
    setScalar(out, "source_helper_engine_id", input.source_helper_engine_id)
    setScalar(out, "trigger_source_slot_id", input.trigger_source_slot_id)
    setScalar(out, "trigger_payload_slot_id", input.trigger_payload_slot_id)
    setScalar(out, "has_trigger_payload", input.has_trigger_payload)
    setScalar(out, "trigger_route", input.trigger_route)
    setScalar(out, "trigger_duplicate_key", input.trigger_duplicate_key)
    setScalar(out, "timer_source_slot_id", input.timer_source_slot_id)
    setScalar(out, "timer_payload_slot_id", input.timer_payload_slot_id)
    setScalar(out, "has_timer_payload", input.has_timer_payload)
    setScalar(out, "timer_delay_ticks", input.timer_delay_ticks)
    setScalar(out, "timer_delay_seconds", input.timer_delay_seconds)
    setScalar(out, "timer_scheduled_tick", input.timer_scheduled_tick)
    setScalar(out, "timer_due_tick", input.timer_due_tick)
    setScalar(out, "timer_scheduled_seconds", input.timer_scheduled_seconds)
    setScalar(out, "timer_due_seconds", input.timer_due_seconds)
    setScalar(out, "timer_delay_semantics", input.timer_delay_semantics)
    setScalar(out, "timer_duplicate_key", input.timer_duplicate_key)
    setScalar(out, "timer_id", input.timer_id)
    setScalar(out, "cast_attempt_id", input.cast_attempt_id)
    setScalar(out, "cast_id", input.cast_id)
    setScalar(out, "emission_index", firstNonNil(input.emission_index, mappingField(mapping, "emission_index")))
    setScalar(out, "group_index", firstNonNil(input.group_index, mappingField(mapping, "group_index")))
    setScalar(out, "fanout_count", input.fanout_count)
    setScalar(out, "pattern_kind", input.pattern_kind)
    setScalar(out, "pattern_index", input.pattern_index)
    setScalar(out, "pattern_count", input.pattern_count)
    setScalar(out, "pattern_direction_key", input.pattern_direction_key)
    setScalar(out, "chain_runtime", input.chain_runtime)
    setScalar(out, "chain_role", input.chain_role)
    setScalar(out, "chain_id", input.chain_id)
    setScalar(out, "chain_hop_index", input.chain_hop_index)
    setScalar(out, "chain_max_hops", input.chain_max_hops)
    setScalar(out, "chain_targeting_mode", input.chain_targeting_mode)
    setScalar(out, "chain_target_provider", input.chain_target_provider)
    setScalar(out, "chain_side_continuation_kind", input.chain_side_continuation_kind)
    setScalar(out, "chain_side_continuation_id", input.chain_side_continuation_id)
    setScalar(out, "chain_side_payload_count", input.chain_side_payload_count)
    setScalar(out, "branch_scope", input.branch_scope)
    setScalar(out, "branch_id", input.branch_id)
    setScalar(out, "branch_parent_id", input.branch_parent_id)
    setScalar(out, "branch_kind", input.branch_kind)
    setScalar(out, "branch_index", input.branch_index)
    setScalar(out, "branch_count", input.branch_count)
    setScalar(out, "chain_continuation_group_id", input.chain_continuation_group_id)
    setScalar(out, "current_hit_target_id", input.current_hit_target_id)
    setScalar(out, "selected_target_id", input.selected_target_id)
    setScalar(out, "previous_projectile_id", input.previous_projectile_id)
    setScalar(out, "bounce_runtime", input.bounce_runtime)
    setScalar(out, "bounce_role", input.bounce_role)
    setScalar(out, "bounce_id", input.bounce_id)
    setScalar(out, "bounce_index", input.bounce_index)
    setScalar(out, "bounce_max", input.bounce_max)
    setScalar(out, "bounce_power", input.bounce_power)
    setScalar(out, "bounce_detonate_on_actor_hit", input.bounce_detonate_on_actor_hit)
    setScalar(out, "bounce_trigger_payload_slot_id", input.bounce_trigger_payload_slot_id)
    setScalar(out, "bounce_manual_detonation", input.bounce_manual_detonation)
    setScalar(out, "bounce_final", input.bounce_final)
    setScalar(out, "pierce_runtime", input.pierce_runtime)
    setScalar(out, "pierce_role", input.pierce_role)
    setScalar(out, "pierce_id", input.pierce_id)
    setScalar(out, "pierce_count", input.pierce_count)
    setScalar(out, "pierce_limit", input.pierce_limit)
    setScalar(out, "pierce_trigger_payload_slot_id", input.pierce_trigger_payload_slot_id)
    setScalar(out, "source_modifier_kind", input.source_modifier_kind)
    setScalar(out, "payload_modifier_kind", input.payload_modifier_kind)
    setScalar(out, "speed_plus", input.speed_plus)
    setScalar(out, "speed_plus_mode", input.speed_plus_mode)
    setScalar(out, "speed_plus_value", input.speed_plus_value)
    setScalar(out, "speed_plus_base_speed", input.speed_plus_base_speed)
    setScalar(out, "speed_plus_multiplier", input.speed_plus_multiplier)
    setScalar(out, "speed_plus_speed", input.speed_plus_speed)
    setScalar(out, "speed_plus_max_speed", input.speed_plus_max_speed)
    setScalar(out, "speed_plus_field", input.speed_plus_field)
    setScalar(out, "speed_plus_capped", input.speed_plus_capped)
    setScalar(out, "size_plus", input.size_plus)
    setScalar(out, "size_plus_mode", input.size_plus_mode)
    setScalar(out, "size_plus_value", input.size_plus_value)
    setScalar(out, "size_plus_multiplier", input.size_plus_multiplier)
    setScalar(out, "size_plus_field", input.size_plus_field)
    setScalar(out, "size_plus_capped", input.size_plus_capped)
    setScalar(out, "size_plus_base_area", input.size_plus_base_area)
    setScalar(out, "size_plus_area", input.size_plus_area)
    setScalar(out, "homing", input.homing)
    setScalar(out, "homing_mode", input.homing_mode)
    setScalar(out, "homing_force", input.homing_force)
    setScalar(out, "homing_field", input.homing_field)
    setScalar(out, "homing_target_id", input.homing_target_id)
    setScalar(out, "homing_target_provider", input.homing_target_provider)
    setScalar(out, "homing_target_kind", input.homing_target_kind)
    setScalar(out, "homing_targeting_mode", input.homing_targeting_mode)
    setScalar(out, "homing_initial_steer_delay_seconds", input.homing_initial_steer_delay_seconds)
    setScalar(out, "homing_candidate_count", input.homing_candidate_count)
    setScalar(out, "homing_actor_candidate_count", input.homing_actor_candidate_count)
    setScalar(out, "homing_creature_candidate_count", input.homing_creature_candidate_count)
    setScalar(out, "homing_npc_candidate_count", input.homing_npc_candidate_count)
    setScalar(out, "homing_launch_runtime_mode", input.homing_launch_runtime_mode)
    setScalar(out, "homing_launch_force_suppressed", input.homing_launch_force_suppressed)
    setScalar(out, "homing_payload_force_seeded", input.homing_payload_force_seeded)
    setScalar(out, "homing_payload_force_seed_multiplier", input.homing_payload_force_seed_multiplier)
    setScalar(out, "homing_force_key", input.homing_force_key)
    setScalar(out, "homing_direction_key", input.homing_direction_key)

    return out
end

function sfp_userdata.buildLegacyDispatchUserData(args)
    local input = args or {}
    local out = {
        spellforge = true,
        schema = SCHEMA,
        runtime = "2.2b_live_dispatch",
    }

    setScalar(out, "recipe_id", input.recipe_id)
    setScalar(out, "cast_attempt_id", input.cast_attempt_id)
    setScalar(out, "source_spell_id", input.source_spell_id)
    setScalar(out, "dispatch_spell_id", input.dispatch_spell_id)
    setScalar(out, "effect_index", input.effect_index)

    return out
end

function sfp_userdata.compactSpellforgeUserData(user_data)
    if not sfp_userdata.isSpellforgeUserData(user_data) then
        return nil
    end
    return copyKnownScalars(user_data, {
        "runtime",
        "runtime_generation",
        "recipe_id",
        "slot_id",
        "helper_engine_id",
        "job_kind",
        "job_id",
        "parent_job_id",
        "source_job_id",
        "depth",
        "root_source_slot_id",
        "current_source_slot_id",
        "parent_slot_id",
        "payload_depth",
        "nested_stage_kind",
        "nested_stage_index",
        "nested_final_fanout",
        "nested_final_fanout_kind",
        "final_fanout_count",
        "final_fanout_index",
        "source_slot_id",
        "source_prefix_opcode",
        "source_postfix_opcode",
        "payload_slot_id",
        "source_helper_engine_id",
        "trigger_source_slot_id",
        "trigger_payload_slot_id",
        "has_trigger_payload",
        "trigger_route",
        "trigger_duplicate_key",
        "timer_source_slot_id",
        "timer_payload_slot_id",
        "has_timer_payload",
        "timer_delay_ticks",
        "timer_delay_seconds",
        "timer_scheduled_tick",
        "timer_due_tick",
        "timer_scheduled_seconds",
        "timer_due_seconds",
        "timer_delay_semantics",
        "timer_duplicate_key",
        "timer_id",
        "cast_attempt_id",
        "cast_id",
        "emission_index",
        "group_index",
        "fanout_count",
        "pattern_kind",
        "pattern_index",
        "pattern_count",
        "pattern_direction_key",
        "chain_runtime",
        "chain_role",
        "chain_id",
        "chain_hop_index",
        "chain_max_hops",
        "chain_targeting_mode",
        "chain_target_provider",
        "chain_side_continuation_kind",
        "chain_side_continuation_id",
        "chain_side_payload_count",
        "branch_scope",
        "branch_id",
        "branch_parent_id",
        "branch_kind",
        "branch_index",
        "branch_count",
        "chain_continuation_group_id",
        "current_hit_target_id",
        "selected_target_id",
        "previous_projectile_id",
        "bounce_runtime",
        "bounce_role",
        "bounce_id",
        "bounce_index",
        "bounce_max",
        "bounce_power",
        "bounce_detonate_on_actor_hit",
        "bounce_trigger_payload_slot_id",
        "bounce_manual_detonation",
        "bounce_final",
        "pierce_runtime",
        "pierce_role",
        "pierce_id",
        "pierce_count",
        "pierce_limit",
        "pierce_trigger_payload_slot_id",
        "source_modifier_kind",
        "payload_modifier_kind",
        "speed_plus",
        "speed_plus_mode",
        "speed_plus_value",
        "speed_plus_base_speed",
        "speed_plus_multiplier",
        "speed_plus_speed",
        "speed_plus_max_speed",
        "speed_plus_field",
        "speed_plus_capped",
        "size_plus",
        "size_plus_mode",
        "size_plus_value",
        "size_plus_multiplier",
        "size_plus_field",
        "size_plus_capped",
        "size_plus_base_area",
        "size_plus_area",
        "homing",
        "homing_mode",
        "homing_force",
        "homing_field",
        "homing_target_id",
        "homing_target_provider",
        "homing_target_kind",
        "homing_targeting_mode",
        "homing_initial_steer_delay_seconds",
        "homing_candidate_count",
        "homing_actor_candidate_count",
        "homing_creature_candidate_count",
        "homing_npc_candidate_count",
        "homing_launch_runtime_mode",
        "homing_launch_force_suppressed",
        "homing_payload_force_seeded",
        "homing_payload_force_seed_multiplier",
        "homing_force_key",
        "homing_direction_key",
        "source_spell_id",
        "dispatch_spell_id",
        "effect_index",
    })
end

function sfp_userdata.extract(payload)
    local data = payload or {}
    local user_data = data.userData
    if type(user_data) ~= "table" then
        user_data = data.user_data
    end
    if type(user_data) == "table" then
        return user_data
    end
    return nil
end

function sfp_userdata.isSpellforgeUserData(user_data)
    return type(user_data) == "table"
        and user_data.spellforge == true
        and user_data.schema == SCHEMA
end

return sfp_userdata
