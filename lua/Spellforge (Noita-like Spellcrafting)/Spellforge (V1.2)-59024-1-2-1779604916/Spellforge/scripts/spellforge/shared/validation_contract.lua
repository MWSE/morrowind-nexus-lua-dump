local validation_contract = {}

local DEFAULT_ERROR_CODE = "validation_error"
local DEFAULT_WARNING_CODE = "validation_warning"

local CODE_PATTERNS = {
    { pattern = "effects must be an array", code = "effects_not_array" },
    { pattern = "effect must be a table", code = "effect_not_table" },
    { pattern = "unknown spellforge operator", code = "unknown_spellforge_operator" },
    { pattern = "unknown opcode", code = "unknown_opcode" },
    { pattern = "missing parameter", code = "missing_opcode_parameter" },
    { pattern = "must be an integer", code = "invalid_opcode_parameter" },
    { pattern = "must be a number", code = "invalid_opcode_parameter" },
    { pattern = "burst/spread requires multicast", code = "pattern_requires_multicast" },
    { pattern = "fanout requires target range", code = "fanout_requires_target_range" },
    { pattern = "static emissions exceed", code = "static_emission_cap_exceeded" },
    { pattern = "static emission estimate exceeds", code = "recipe_static_emission_cap_exceeded" },
    { pattern = "has no preceding emitter group", code = "postfix_missing_source" },
    { pattern = "must be followed by an emitter group", code = "prefix_missing_emitter" },
    { pattern = "recipe has no emitter groups", code = "recipe_has_no_emitter_groups" },
    { pattern = "slot count exceeds", code = "slot_cap_exceeded" },
    { pattern = "spec count exceeds", code = "spec_cap_exceeded" },
    { pattern = "summon source", code = "summon_source_cap_exceeded" },
    { pattern = "detonate payload requires target range", code = "detonate_requires_target_range" },
    { pattern = "detonate payload requires area", code = "detonate_requires_area" },
    { pattern = "detonate requires payload context", code = "detonate_requires_payload_context" },
    { pattern = "nested continuation budget", code = "nested_continuation_budget_exceeded" },
    { pattern = "nested final payload budget", code = "nested_final_payload_budget_exceeded" },
    { pattern = "no cached plan", code = "plan_not_cached" },
}

local function cloneValue(value, depth)
    if type(value) ~= "table" then
        return value
    end
    if (depth or 0) >= 4 then
        return tostring(value)
    end

    local out = {}
    for k, v in pairs(value) do
        out[k] = cloneValue(v, (depth or 0) + 1)
    end
    return out
end

local function normalizeCode(value, fallback)
    local text = tostring(value or "")
    text = string.lower(text)
    text = string.gsub(text, "[^%w]+", "_")
    text = string.gsub(text, "^_+", "")
    text = string.gsub(text, "_+$", "")
    if text ~= "" and #text <= 80 then
        return text
    end
    return fallback
end

function validation_contract.deriveCode(message, fallback)
    local text = string.lower(tostring(message or ""))
    for _, entry in ipairs(CODE_PATTERNS) do
        if string.find(text, entry.pattern, 1, true) then
            return entry.code
        end
    end
    return normalizeCode(text, fallback or DEFAULT_ERROR_CODE)
end

function validation_contract.makeIssue(path, message, code, severity, details)
    local normalized_severity = severity or "error"
    local fallback = normalized_severity == "warning" and DEFAULT_WARNING_CODE or DEFAULT_ERROR_CODE
    return {
        code = normalizeCode(code or validation_contract.deriveCode(message, fallback), fallback),
        path = path or "",
        message = tostring(message or ""),
        severity = normalized_severity,
        details = details ~= nil and cloneValue(details, 0) or nil,
    }
end

function validation_contract.error(path, message, code, details)
    return validation_contract.makeIssue(path, message, code, "error", details)
end

function validation_contract.warning(path, message, code, details)
    return validation_contract.makeIssue(path, message, code, "warning", details)
end

function validation_contract.cloneIssue(issue, fallback_severity)
    if type(issue) ~= "table" then
        return validation_contract.makeIssue("", tostring(issue), nil, fallback_severity or "error")
    end

    local severity = issue.severity or fallback_severity or "error"
    return validation_contract.makeIssue(
        issue.path,
        issue.message,
        issue.code,
        severity,
        issue.details
    )
end

function validation_contract.cloneIssues(issues, fallback_severity)
    local out = {}
    for i, issue in ipairs(issues or {}) do
        out[i] = validation_contract.cloneIssue(issue, fallback_severity)
    end
    return out
end

return validation_contract
