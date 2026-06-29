---@omw-context none
local limits = require("scripts.spellforge.shared.limits")

local rejection_messages = {}

local function asNumber(value)
    local n = tonumber(value)
    if n ~= nil then
        return n
    end
    return nil
end

local function tableValue(source, key)
    if type(source) ~= "table" then
        return nil
    end
    return source[key]
end

local function detailsFor(issue_or_details)
    if type(issue_or_details) ~= "table" then
        return {}
    end
    if type(issue_or_details.details) == "table" then
        return issue_or_details.details
    end
    return issue_or_details
end

local function codeFor(issue_or_reason)
    if type(issue_or_reason) == "table" then
        return tostring(issue_or_reason.code or issue_or_reason.reason or issue_or_reason.message or "")
    end
    return tostring(issue_or_reason or "")
end

local function humanizeCode(code)
    local text = tostring(code or "")
    text = string.gsub(text, "_", " ")
    text = string.gsub(text, "^%s+", "")
    text = string.gsub(text, "%s+$", "")
    if text == "" then
        return "Request failed."
    end
    return string.upper(string.sub(text, 1, 1)) .. string.sub(text, 2) .. "."
end

local function firstNumber(...)
    for i = 1, select("#", ...) do
        local n = asNumber(select(i, ...))
        if n ~= nil then
            return n
        end
    end
    return nil
end

local function auditValue(details, key)
    local audit = tableValue(details, "audit")
    if type(audit) == "table" then
        return audit[key]
    end
    return nil
end

local function plannedCount(details)
    return firstNumber(
        tableValue(details, "count"),
        tableValue(details, "estimated_total_jobs"),
        auditValue(details, "estimated_total_jobs"),
        tableValue(details, "payload_count"),
        tableValue(details, "fanout_count"),
        tableValue(details, "value")
    )
end

local function plannedLimit(details)
    return firstNumber(
        tableValue(details, "limit"),
        tableValue(details, "projectile_cap"),
        tableValue(details, "job_cap"),
        tableValue(details, "max"),
        limits.MAX_PROJECTILES_PER_CAST
    )
end

local function fanoutCount(details)
    return firstNumber(
        tableValue(details, "fanout_count"),
        tableValue(details, "payload_count"),
        auditValue(details, "max_fanout"),
        tableValue(details, "count"),
        tableValue(details, "value")
    )
end

local function fanoutLimit(details)
    return firstNumber(
        tableValue(details, "fanout_cap"),
        tableValue(details, "max_fanout"),
        tableValue(details, "max"),
        limits.MAX_PAYLOAD_FANOUT
    )
end

local function withCountLimit(prefix, count, limit, suffix)
    if count ~= nil and limit ~= nil then
        return string.format("%s: %s / %s.%s", prefix, tostring(count), tostring(limit), suffix or "")
    end
    if limit ~= nil then
        return string.format("%s: limit %s.%s", prefix, tostring(limit), suffix or "")
    end
    return prefix .. "." .. (suffix or "")
end

local function multicastLimitMessage(details)
    local max = firstNumber(tableValue(details, "max"), limits.MAX_PAYLOAD_FANOUT_HARD)
    local min = firstNumber(tableValue(details, "min"), 2)
    local value = asNumber(tableValue(details, "value"))
    if value ~= nil and max ~= nil and value > max then
        return string.format("Multicast can create at most %d copies. Lower this Multicast count.", max)
    end
    if value ~= nil and min ~= nil and value < min then
        return string.format("Multicast must create at least %d copies.", min)
    end
    if max ~= nil then
        return string.format("Multicast count must be between %d and %d.", min or 2, max)
    end
    return "Multicast has an invalid count."
end

local function messageFor(code, details, fallback)
    if code == "invalid_opcode_parameter" then
        if tableValue(details, "opcode") == "Multicast" and tableValue(details, "parameter") == "count" then
            return multicastLimitMessage(details)
        end
        local opcode = tostring(tableValue(details, "opcode") or "Operator")
        local parameter = tostring(tableValue(details, "parameter") or "parameter")
        local max = asNumber(tableValue(details, "max"))
        local min = asNumber(tableValue(details, "min"))
        if max ~= nil then
            return string.format("%s %s must be %s or lower.", opcode, parameter, tostring(max))
        end
        if min ~= nil then
            return string.format("%s %s must be %s or higher.", opcode, parameter, tostring(min))
        end
        return fallback or string.format("%s has an invalid %s value.", opcode, parameter)
    end

    if code == "static_emission_cap_exceeded" then
        local count = plannedCount(details)
        local limit = plannedLimit(details)
        if count ~= nil and limit ~= nil then
            return string.format("Emitter group creates too many projectiles: %s / %s. Lower that Multicast count.", tostring(count), tostring(limit))
        end
        return "Emitter group creates too many projectiles. Lower that Multicast count."
    end

    if code == "recipe_static_emission_cap_exceeded"
        or code == "slot_cap_exceeded"
        or code == "spec_cap_exceeded"
        or code == "payload_multicast_projectile_cap_exceeded"
        or code == "payload_multicast_job_cap_exceeded"
        or code == "nested_continuation_budget_exceeded"
        or code == "nested_final_payload_budget_exceeded"
        or code == "exceeds_projectile_cap"
        or code == "exceeds_job_cap" then
        local count = plannedCount(details)
        local limit = plannedLimit(details)
        if count ~= nil and limit ~= nil then
            return string.format("Too many planned projectiles: %s / %s. Lower Multicast or remove a Trigger/Timer layer.", tostring(count), tostring(limit))
        end
        return "Too many planned projectiles. Lower Multicast or remove a Trigger/Timer layer."
    end

    if code == "payload_multicast_fanout_cap_exceeded" or code == "exceeds_fanout_cap" then
        local count = fanoutCount(details)
        local limit = fanoutLimit(details)
        if count ~= nil and limit ~= nil then
            return string.format("Payload fanout is too high: %s / %s. Lower the payload Multicast count.", tostring(count), tostring(limit))
        end
        return "Payload fanout is too high. Lower the payload Multicast count."
    end

    if code == "nested_depth_exceeded" or code == "exceeds_depth_cap" then
        local limit = firstNumber(tableValue(details, "limit"), tableValue(details, "max_depth"), limits.MAX_LIVE_NESTED_CONTINUATION_DEPTH)
        return string.format("Trigger/Timer chains can be nested up to %d layers.", limit or 3)
    end

    if code == "summon_source_cap_exceeded" then
        local limit = firstNumber(tableValue(details, "limit"), tableValue(details, "max"), limits.MAX_SUMMON_SOURCES_PER_SPELL)
        return string.format("A single spell can create at most %d summon sources.", limit or 3)
    end

    if code == "pattern_requires_multicast" or code == "payload_pattern_fanout_missing" then
        return "Spread and Burst only shape a Multicast. Add Multicast before using Spread or Burst."
    end

    if code == "fanout_requires_target_range" then
        return "Multicast with Spread/Burst needs a Target projectile. Self and Touch effects cannot use that pattern."
    end

    if code == "detonate_requires_area" then
        return "Detonate needs a Target effect with area greater than 0."
    end

    if code == "detonate_requires_target_range" then
        return "Detonate only works on Target payload effects."
    end

    if code == "detonate_requires_payload_context" then
        return "Detonate must be placed after Trigger or Timer and before an area payload."
    end

    if code == "detonate_modifier_combo_deferred" then
        return "Detonate can only combine with Multicast in this version."
    end

    if code == "detonate_sfp_capability_missing" then
        return "Detonate requires Spell Framework Plus detonation support."
    end

    if code == "homing_runtime_active_cap" or code == "soft_homing_active_cap" then
        local limit = firstNumber(tableValue(details, "limit"), tableValue(details, "max"), limits.MAX_HOMING_PROJECTILES_ACTIVE)
        return string.format("Too many active Homing projectiles. Wait for some to expire or keep Homing under %d active shots.", limit or 128)
    end

    if code == "homing_fanout_budget_exceeded" then
        local count = fanoutCount(details)
        local limit = firstNumber(tableValue(details, "fanout_cap"), tableValue(details, "max"), limits.MAX_HOMING_FANOUT_PER_CAST)
        if count ~= nil and limit ~= nil then
            return string.format("This Homing spell creates too many guided projectiles: %s / %s.", tostring(count), tostring(limit))
        end
        return "This Homing spell creates too many guided projectiles."
    end

    if code == "homing_targeting_budget_exceeded" or code == "homing_soft_high_fanout_deferred" then
        local count = fanoutCount(details)
        local limit = firstNumber(tableValue(details, "scan_cap"), tableValue(details, "max"), limits.MAX_HOMING_TARGET_SCANS_PER_CAST)
        if count ~= nil and limit ~= nil then
            return string.format("This Homing spell needs too many target scans: %s / %s.", tostring(count), tostring(limit))
        end
        return "This Homing spell needs too many target scans."
    end

    if code == "homing_runtime_state_api_missing" then
        return "Homing requires Spell Framework Plus projectile state support."
    end

    if code == "homing_runtime_redirect_api_missing" then
        return "Homing requires Spell Framework Plus redirect support."
    end

    if code == "homing_runtime_target_missing" or code == "homing_target_missing" then
        return "Homing needs a valid target or target search point."
    end

    if code == "homing_bounce_physics_unsupported" then
        return "Homing cannot combine with Bounce yet."
    end

    if code == "homing_pierce_physics_unsupported" then
        return "Homing cannot combine with Pierce yet."
    end

    if code == "homing_chain_targeting_unsupported" then
        return "Homing cannot combine with Chain because Chain already chooses the next target."
    end

    if code == "payload_multicast_disabled" then
        return "This payload Multicast is not supported in the current spell shape."
    end

    if code == "payload_pattern_disabled" or code == "payload_pattern_runtime_deferred" then
        return "Spread/Burst payload patterns are not supported in this spell shape."
    end

    if code == "missing_magic_effect_record" then
        return "A custom magic effect used by this recipe is not loaded. Check the mod/load order that provides it."
    end

    if code == "ambiguous_magic_effect_record" then
        return "A custom magic effect ID matches more than one loaded effect. Spellforge cannot safely guess which one to use."
    end

    if code == "invalid_engine_effect_id" then
        return "OpenMW rejected one of this recipe's magic effect IDs."
    end

    if code == "nested_payload_runtime_deferred" then
        return "This Trigger/Timer payload shape is not supported yet."
    end

    return nil
end

function rejection_messages.formatReason(reason, details)
    local code = codeFor(reason)
    local d = detailsFor(details or reason)
    local fallback = nil
    if type(reason) == "table" then
        fallback = reason.message
    end
    return messageFor(code, d, fallback) or fallback or humanizeCode(code)
end

function rejection_messages.formatIssue(issue, fallback)
    if type(issue) ~= "table" then
        return rejection_messages.formatReason(issue) or fallback or "Request failed."
    end
    return rejection_messages.formatReason(issue, issue.details) or issue.message or fallback or "Request failed."
end

function rejection_messages.formatFirstError(result, fallback)
    local first = result and result.errors and result.errors[1]
    if first ~= nil then
        return rejection_messages.formatIssue(first, fallback)
    end
    return fallback or "Request failed."
end

function rejection_messages.formatDeferredReasons(reasons, fallback)
    local out = {}
    local seen = {}
    for _, reason in ipairs(reasons or {}) do
        local text = rejection_messages.formatReason(reason)
        if text ~= nil and text ~= "" and not seen[text] then
            out[#out + 1] = text
            seen[text] = true
        end
    end
    if #out > 0 then
        return table.concat(out, " ")
    end
    return fallback or "Runtime combo deferred."
end

return rejection_messages
