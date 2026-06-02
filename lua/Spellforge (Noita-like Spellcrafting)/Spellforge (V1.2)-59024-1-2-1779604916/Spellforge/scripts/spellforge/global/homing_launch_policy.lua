local limits = require("scripts.spellforge.shared.limits")
local log = require("scripts.spellforge.shared.log").new("global.homing_launch_policy")
local runtime_stats = require("scripts.spellforge.global.runtime_stats")
local live_homing = require("scripts.spellforge.global.live_homing")

local homing_launch_policy = {}

homing_launch_policy.VERSION = "spellforge-homing-launch-policy-v1"

local function hasPayloadBindings(entry)
    return type(entry and entry.payload_bindings) == "table" and #entry.payload_bindings > 0
end

local function hasPostfix(entry)
    return type(entry and entry.postfix_ops) == "table" and #entry.postfix_ops > 0
end

local function countOpcode(ops, opcode)
    local count = 0
    local first = nil
    for _, op in ipairs(ops or {}) do
        if op and op.opcode == opcode then
            count = count + 1
            first = first or op
        end
    end
    return count, first
end

local function component(value, key)
    local ok, result = pcall(function()
        return value and value[key]
    end)
    if ok then
        return tonumber(result) or 0
    end
    return 0
end

local function distanceSquared(a, b)
    if a == nil or b == nil then
        return nil
    end
    local dx = component(a, "x") - component(b, "x")
    local dy = component(a, "y") - component(b, "y")
    local dz = component(a, "z") - component(b, "z")
    return dx * dx + dy * dy + dz * dz
end

local function meaningfulHitPosition(payload)
    local hit_pos = payload and (payload.hit_pos or payload.hitPos or payload.hit_position)
    local start_pos = payload and payload.start_pos
    local distance_sq = distanceSquared(hit_pos, start_pos)
    if distance_sq ~= nil and distance_sq > 1 then
        return hit_pos
    end
    return nil
end

local function fallbackTargetPosition(payload)
    local start_pos = payload and payload.start_pos
    local direction = payload and payload.direction
    if start_pos == nil or direction == nil then
        return nil
    end
    local distance = tonumber(payload.homing_fallback_distance) or 1000
    return {
        x = component(start_pos, "x") + component(direction, "x") * distance,
        y = component(start_pos, "y") + component(direction, "y") * distance,
        z = component(start_pos, "z") + component(direction, "z") * distance,
    }
end

local function multicastFanout(op)
    local count = tonumber(op and op.params and op.params.count) or 1
    if count ~= count or count == math.huge or count == -math.huge then
        return 1
    end
    return math.max(1, math.floor(count))
end

local function cloneWarnings(warnings)
    local out = {}
    for index, warning in ipairs(warnings or {}) do
        out[index] = warning
    end
    return out
end

local function inspectPrefixOps(entry)
    local features = {
        homing = false,
        speed_plus = false,
        size_plus = false,
        multicast = false,
        pattern = false,
        pattern_kind = nil,
        bounce = false,
        pierce = false,
        chain = false,
    }
    local details = {
        homing_count = 0,
        homing_op = nil,
        multicast_count = 0,
        multicast_op = nil,
        pattern_count = 0,
        pattern_op = nil,
        pattern_ambiguous = false,
        unsupported_count = 0,
        unsupported_opcode = nil,
    }

    for _, op in ipairs(entry and entry.prefix_ops or {}) do
        local opcode = op and op.opcode
        if opcode == "Homing" then
            features.homing = true
            details.homing_count = details.homing_count + 1
            details.homing_op = details.homing_op or op
        elseif opcode == "Speed+" then
            features.speed_plus = true
        elseif opcode == "Size+" then
            features.size_plus = true
        elseif opcode == "Multicast" then
            features.multicast = true
            details.multicast_count = details.multicast_count + 1
            details.multicast_op = details.multicast_op or op
        elseif opcode == "Spread" or opcode == "Burst" then
            features.pattern = true
            details.pattern_count = details.pattern_count + 1
            if features.pattern_kind ~= nil and features.pattern_kind ~= opcode then
                details.pattern_ambiguous = true
            end
            features.pattern_kind = features.pattern_kind or opcode
            details.pattern_op = details.pattern_op or op
        elseif opcode == "Bounce" then
            features.bounce = true
        elseif opcode == "Pierce" then
            features.pierce = true
        elseif opcode == "Chain" then
            features.chain = true
        elseif opcode ~= nil then
            details.unsupported_count = details.unsupported_count + 1
            details.unsupported_opcode = details.unsupported_opcode or opcode
        end
    end

    return features, details
end

local function homingEnabled(opts)
    local options = opts or {}
    if options.force_homing_disabled == true then
        return false
    end
    return options.force_homing_enabled == true
        or options.homing_enabled == true
        or options.allow_homing == true
        or options.allow_source_homing == true
        or options.allow_payload_homing == true
end

local function softHomingEnabled(opts)
    local options = opts or {}
    if options.force_soft_homing_disabled == true then
        return false
    end
    return options.force_soft_homing_enabled == true
        or options.soft_homing_enabled == true
        or options.soft_homing_probe == true
end

local function fanoutCount(features, details, opts)
    local options = opts or {}
    local explicit = tonumber(options.homing_fanout_count or options.fanout_count or options.source_fanout_count or options.payload_fanout_count)
    if explicit ~= nil then
        return math.max(1, math.floor(explicit))
    end
    if features and features.multicast == true then
        return multicastFanout(details and details.multicast_op)
    end
    return 1
end

local function emitDeferred(entry, reason, features, opts)
    local options = opts or {}
    if options.quiet == true then
        return
    end
    runtime_stats.inc("homing_policy_deferred")
    log.info(string.format(
        "SPELLFORGE_HOMING_POLICY_DEFERRED recipe_id=%s slot_id=%s reason=%s",
        tostring(entry and entry.recipe_id),
        tostring(entry and entry.slot_id),
        tostring(reason)
    ))
    local budget_reason = reason == "homing_fanout_budget_exceeded"
        or reason == "homing_targeting_budget_exceeded"
        or reason == "homing_soft_high_fanout_deferred"
    if budget_reason then
        runtime_stats.inc("homing_targeting_budget_deferred")
        log.info(string.format(
            "SPELLFORGE_HOMING_TARGETING_BUDGET_DEFERRED recipe_id=%s slot_id=%s reason=%s",
            tostring(entry and entry.recipe_id),
            tostring(entry and entry.slot_id),
            tostring(reason)
        ))
    end
end

local function emitOk(entry, features, details, opts)
    local options = opts or {}
    if options.quiet == true then
        return
    end
    runtime_stats.inc("homing_policy_ok")
    log.info(string.format(
        "SPELLFORGE_HOMING_POLICY_OK recipe_id=%s slot_id=%s policy_kind=%s fanout_count=%s pattern_kind=%s",
        tostring(entry and entry.recipe_id),
        tostring(entry and entry.slot_id),
        tostring(options.policy_kind or "launch"),
        tostring(fanoutCount(features, details, options)),
        tostring(features and features.pattern_kind)
    ))
    if options.policy_kind == "payload" then
        runtime_stats.inc("homing_payload_composition_ok")
        log.info(string.format(
            "SPELLFORGE_HOMING_PAYLOAD_COMPOSITION_OK recipe_id=%s slot_id=%s",
            tostring(entry and entry.recipe_id),
            tostring(entry and entry.slot_id)
        ))
    else
        runtime_stats.inc("homing_source_composition_ok")
        log.info(string.format(
            "SPELLFORGE_HOMING_SOURCE_COMPOSITION_OK recipe_id=%s slot_id=%s",
            tostring(entry and entry.recipe_id),
            tostring(entry and entry.slot_id)
        ))
    end
    if features and features.multicast == true then
        runtime_stats.inc("homing_fanout_policy_ok")
        log.info(string.format(
            "SPELLFORGE_HOMING_FANOUT_POLICY_OK recipe_id=%s slot_id=%s fanout_count=%s",
            tostring(entry and entry.recipe_id),
            tostring(entry and entry.slot_id),
            tostring(fanoutCount(features, details, options))
        ))
        runtime_stats.inc("homing_targeting_budget_ok")
        log.info(string.format(
            "SPELLFORGE_HOMING_TARGETING_BUDGET_OK recipe_id=%s slot_id=%s fanout_count=%s",
            tostring(entry and entry.recipe_id),
            tostring(entry and entry.slot_id),
            tostring(fanoutCount(features, details, options))
        ))
    end
    if features and features.pattern == true then
        runtime_stats.inc("homing_pattern_policy_ok")
        log.info(string.format(
            "SPELLFORGE_HOMING_PATTERN_POLICY_OK recipe_id=%s slot_id=%s pattern_kind=%s",
            tostring(entry and entry.recipe_id),
            tostring(entry and entry.slot_id),
            tostring(features.pattern_kind)
        ))
    end
end

local function reject(entry, reason, features, mutations, warnings, opts)
    emitDeferred(entry, reason, features, opts)
    return {
        ok = false,
        version = homing_launch_policy.VERSION,
        rejection_reason = reason,
        homing_features = features or {},
        mutations = mutations or {},
        warnings = cloneWarnings(warnings),
    }
end

local function success(entry, features, details, mutations, warnings, opts)
    emitOk(entry, features, details, opts)
    return {
        ok = true,
        version = homing_launch_policy.VERSION,
        rejection_reason = nil,
        homing_features = features or {},
        mutations = mutations or {},
        warnings = cloneWarnings(warnings),
    }
end

local function inspectEntry(plan, ir, entry, opts)
    local options = opts or {}
    local features, details = inspectPrefixOps(entry)
    local mutations = {
        homing = nil,
        homing_mode = nil,
        homing_fanout_count = nil,
    }
    local warnings = {}

    if features.homing ~= true then
        return {
            ok = true,
            version = homing_launch_policy.VERSION,
            rejection_reason = nil,
            homing_features = features,
            mutations = mutations,
            warnings = warnings,
        }
    end

    if not homingEnabled(options) then
        return reject(entry, "homing_disabled", features, mutations, warnings, options)
    end
    if details.homing_count ~= 1 then
        return reject(entry, "homing_recursion_unsupported", features, mutations, warnings, options)
    end
    if details.pattern_ambiguous == true then
        return reject(entry, "homing_fanout_budget_exceeded", features, mutations, warnings, options)
    end
    if features.pattern and not features.multicast then
        return reject(entry, "homing_fanout_budget_exceeded", features, mutations, warnings, options)
    end
    if features.bounce then
        return reject(entry, "homing_bounce_physics_unsupported", features, mutations, warnings, options)
    end
    if features.pierce then
        return reject(entry, "homing_pierce_physics_unsupported", features, mutations, warnings, options)
    end
    if features.chain then
        return reject(entry, "homing_chain_targeting_unsupported", features, mutations, warnings, options)
    end
    if options.policy_kind == "payload" then
        if (hasPostfix(entry) or hasPayloadBindings(entry))
            and options.allow_nested_payload_homing ~= true then
            return reject(entry, "homing_nested_runtime_deferred", features, mutations, warnings, options)
        end
        if tonumber(entry and entry.payload_depth)
            and tonumber(entry.payload_depth) > 1
            and options.allow_nested_payload_homing ~= true then
            return reject(entry, "homing_nested_runtime_deferred", features, mutations, warnings, options)
        end
    end

    local count = fanoutCount(features, details, options)
    mutations.homing_fanout_count = count
    local fanout_cap = tonumber(options.max_homing_fanout_per_cast)
        or tonumber(options.max_homing_fanout)
        or limits.MAX_HOMING_FANOUT_PER_CAST
        or limits.MAX_PAYLOAD_FANOUT
    if count > fanout_cap then
        return reject(entry, "homing_fanout_budget_exceeded", features, mutations, warnings, options)
    end
    local scan_cap = tonumber(options.max_homing_target_scans_per_cast)
        or limits.MAX_HOMING_TARGET_SCANS_PER_CAST
        or fanout_cap
    if count > scan_cap then
        return reject(entry, "homing_targeting_budget_exceeded", features, mutations, warnings, options)
    end
    if softHomingEnabled(options) then
        local soft_cap = tonumber(options.max_soft_homing_registrations_per_cast)
            or limits.MAX_SOFT_HOMING_REGISTRATIONS_PER_CAST
            or limits.MAX_HOMING_PROJECTILES_ACTIVE
        local soft_requested = options.force_soft_homing_enabled == true
            or options.soft_homing_probe == true
        if soft_requested and count > soft_cap then
            return reject(entry, "homing_soft_high_fanout_deferred", features, mutations, warnings, options)
        end
    end

    local mutation, err = live_homing.computeMutation(details.homing_op)
    if not mutation then
        return reject(entry, err or "homing_targeting_budget_exceeded", features, mutations, warnings, options)
    end
    mutations.homing = mutation
    mutations.homing_mode = mutation.homing_mode

    return success(entry, features, details, mutations, warnings, options)
end

function homing_launch_policy.inspectSourceEntry(plan, ir, source_entry, opts)
    local options = {}
    for key, value in pairs(opts or {}) do
        options[key] = value
    end
    options.policy_kind = "source"
    return inspectEntry(plan, ir, source_entry, options)
end

function homing_launch_policy.inspectPayloadEntry(plan, ir, payload_entry, opts)
    local options = {}
    for key, value in pairs(opts or {}) do
        options[key] = value
    end
    options.policy_kind = "payload"
    return inspectEntry(plan, ir, payload_entry, options)
end

local function applyInfo(target, info)
    if type(target) ~= "table" or type(info) ~= "table" then
        return
    end
    target.forceVec = info.forceVec
    target.homing = true
    target.homing_mode = info.homing_mode
    target.homing_force = info.homing_force
    target.homing_field = info.homing_field
    target.homing_target_id = info.homing_target_id
    target.homing_target_object = info.homing_target_object
    target.homing_target_position = info.homing_target_position
    target.homing_target_provider = info.homing_target_provider
    target.homing_target_kind = info.homing_target_kind
    target.homing_targeting_mode = info.homing_targeting_mode
    target.homing_payload_targeting = info.homing_payload_targeting
    target.homing_initial_steer_delay_seconds = info.homing_initial_steer_delay_seconds
    target.homing_initial_retarget_delay_seconds = info.homing_initial_retarget_delay_seconds
    target.homing_payload_search_origin = info.homing_payload_search_origin
    target.homing_payload_search_radius = info.homing_payload_search_radius
    target.homing_candidate_count = info.homing_candidate_count
    target.homing_actor_candidate_count = info.homing_actor_candidate_count
    target.homing_creature_candidate_count = info.homing_creature_candidate_count
    target.homing_npc_candidate_count = info.homing_npc_candidate_count
    target.homing_force_key = info.homing_force_key
    target.homing_direction_key = info.homing_direction_key
end

local function launchPayloadForSpec(launch_spec, event_context, opts)
    local payload = {}
    local source = type(launch_spec and launch_spec.payload) == "table" and launch_spec.payload or launch_spec or {}
    for key, value in pairs(source) do
        payload[key] = value
    end
    for key, value in pairs(event_context or {}) do
        if payload[key] == nil then
            payload[key] = value
        end
    end
    payload.actor = payload.actor or payload.caster or payload.sender
    payload.sender = payload.sender or payload.actor
    payload.start_pos = payload.start_pos
        or payload.origin
        or payload.hit_pos
        or payload.position
    payload.direction = payload.direction or payload.launch_direction
    if opts and opts.homing_actor_scan ~= nil then
        payload.homing_actor_scan = opts.homing_actor_scan
    end
    if opts and opts.policy_kind == "payload" then
        payload.homing_targeting_mode = payload.homing_targeting_mode or "payload_local_sphere"
        payload.homing_payload_targeting = payload.homing_payload_targeting or "local_sphere"
        payload.homing_initial_steer_delay_seconds = payload.homing_initial_steer_delay_seconds
            or limits.HOMING_PAYLOAD_INITIAL_STEER_DELAY_SECONDS
            or 0
        payload.homing_initial_retarget_delay_seconds = payload.homing_initial_retarget_delay_seconds
            or payload.homing_initial_steer_delay_seconds
        payload.homing_payload_scan_radius = payload.homing_payload_scan_radius
            or opts.homing_payload_scan_radius
            or limits.HOMING_PAYLOAD_SCAN_RADIUS
        payload.homing_payload_scan_candidates = payload.homing_payload_scan_candidates
            or opts.homing_payload_scan_candidates
            or limits.HOMING_PAYLOAD_SCAN_CANDIDATES
    end
    local payload_local_scan = payload.homing_targeting_mode == "payload_local_sphere"
        and payload.homing_actor_scan ~= false
    if payload.homing_target_position == nil
        and payload.hit_object == nil
        and payload.homing_target_object == nil
        and not payload_local_scan then
        local hit_position = meaningfulHitPosition(payload)
        payload.homing_target_position = (opts and opts.homing_target_position) or hit_position or fallbackTargetPosition(payload)
        payload.homing_target_id = payload.homing_target_id
            or (opts and opts.homing_target_id)
            or (hit_position ~= nil and "homing_policy_hit_position" or "homing_policy_fallback_target")
        payload.homing_target_provider = payload.homing_target_provider
            or (hit_position ~= nil and "hit_position" or "fallback_position")
    end
    return payload
end

function homing_launch_policy.applyToLaunchSpec(plan, ir, entry, launch_spec, event_context, opts)
    local options = opts or {}
    local inspected = options.inspection
    if type(inspected) ~= "table" then
        inspected = inspectEntry(plan, ir, entry, options)
    end
    if inspected.ok ~= true then
        if type(launch_spec) == "table" then
            launch_spec.homing_rejection_reason = inspected.rejection_reason
            if type(launch_spec.payload) == "table" then
                launch_spec.payload.homing_rejection_reason = inspected.rejection_reason
            end
        end
        return inspected
    end
    if inspected.homing_features and inspected.homing_features.homing ~= true then
        return inspected
    end

    local mutations = inspected.mutations or {}
    local launch_payload = launchPayloadForSpec(launch_spec, event_context, options)
    local info, err = live_homing.computeLaunchAssist(launch_payload, mutations.homing)
    if not info then
        return reject(entry, err or "homing_target_missing", inspected.homing_features, mutations, inspected.warnings, options)
    end
    if options.apply_homing_direction == true and info.direction ~= nil then
        launch_spec.direction = info.direction
        if type(launch_spec.payload) == "table" then
            launch_spec.payload.direction = info.direction
        end
    end
    applyInfo(launch_spec, info)
    if type(launch_spec.payload) == "table" then
        applyInfo(launch_spec.payload, info)
    end
    runtime_stats.inc("homing_policy_applied")
    log.info(string.format(
        "SPELLFORGE_HOMING_POLICY_APPLIED recipe_id=%s event_kind=%s slot_id=%s homing_mode=%s homing_field=%s target_provider=%s targeting_mode=%s initial_steer_delay=%s",
        tostring(launch_spec and launch_spec.recipe_id),
        tostring(event_context and event_context.event_kind),
        tostring(launch_spec and launch_spec.slot_id),
        tostring(info.homing_mode),
        tostring(info.homing_field),
        tostring(info.homing_target_provider),
        tostring(info.homing_targeting_mode),
        tostring(info.homing_initial_steer_delay_seconds)
    ))
    if info.homing_targeting_mode == "payload_local_sphere" then
        runtime_stats.inc("homing_payload_local_policy_applied")
        log.info(string.format(
            "SPELLFORGE_HOMING_PAYLOAD_LOCAL_POLICY_APPLIED recipe_id=%s event_kind=%s slot_id=%s target_provider=%s initial_steer_delay=%s",
            tostring(launch_spec and launch_spec.recipe_id),
            tostring(event_context and event_context.event_kind),
            tostring(launch_spec and launch_spec.slot_id),
            tostring(info.homing_target_provider),
            tostring(info.homing_initial_steer_delay_seconds)
        ))
    end
    return inspected
end

function homing_launch_policy.applyToJob(plan, ir, payload_entry, job, event_context, opts)
    local options = {}
    for key, value in pairs(opts or {}) do
        options[key] = value
    end
    options.policy_kind = "payload"
    return homing_launch_policy.applyToLaunchSpec(plan, ir, payload_entry, job, event_context, options)
end

return homing_launch_policy
