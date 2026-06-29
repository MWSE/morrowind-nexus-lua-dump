---@omw-context all
local storage = require("openmw.storage")

local log = {}

local SETTINGS_SECTION = "SpellforgeSettings"
local SETTINGS_KEY_LEVEL = "log_level"
local SETTINGS_KEY_DIAGNOSTICS = "log_diagnostics"
local SETTINGS_KEY_TRACE_SPELLBOOK_SCAN = "log_trace_spellbook_scan"
local SETTINGS_KEY_TRACE_REHYDRATE = "log_trace_rehydrate"
local SETTINGS_KEY_TRACE_PROJECTILES = "log_trace_projectiles"
local SETTINGS_KEY_TRACE_SFP_CALLS = "log_trace_sfp_calls"
local SETTINGS_KEY_TRACE_UI = "log_trace_ui"
local SETTINGS_KEY_TRACE_SPEED = "log_trace_speed"

log.LOG_LEVEL = "warn"
log.LOG_DIAGNOSTICS = false
log.LOG_TRACE_SPELLBOOK_SCAN = false
log.LOG_TRACE_REHYDRATE = false
log.LOG_TRACE_PROJECTILES = false
log.LOG_TRACE_SFP_CALLS = false
log.LOG_TRACE_UI = false
log.LOG_TRACE_SPEED = false

local LEVELS = {
    trace = 0,
    debug = 1,
    info = 2,
    warn = 3,
    error = 4,
}

local LEVEL_NAMES = {
    [0] = "TRACE",
    [1] = "DEBUG",
    [2] = "INFO",
    [3] = "WARN",
    [4] = "ERROR",
}

local section = storage.globalSection(SETTINGS_SECTION)
local once_keys = {}
local rate_limited = {}
local policy_announced = false

local function sectionSetter()
    if type(section) ~= "table" then
        return nil
    end
    local setter = section["set"]
    if type(setter) == "function" then
        return setter
    end
    return nil
end

local RELEASE_INFO_MARKERS = {
    "SPELLFORGE_RELEASE_LOGGING_POLICY_OK",
    "SPELLFORGE_SAVE_LOAD_PERSISTENCE_OK phase=onSave",
    "SPELLFORGE_SAVE_LOAD_PERSISTENCE_OK phase=onLoad",
    "SPELLFORGE_RUNTIME_SAVE_CLEANUP_OK",
    "SPELLFORGE_RUNTIME_RESET_OK",
    "SPELLFORGE_REHYDRATE_COMPLETE count=",
    "SPELLFORGE_REHYDRATE_COMPLETE queued=",
    "SPELLFORGE_KNOWN_EFFECT_SCAN_DONE",
    "SPELLFORGE_UI_COMPILE_OK",
    "SPELLFORGE_SPELLCRAFT_UI_OPENED",
    "SPELLFORGE_SPELLCRAFT_UI_CLOSED",
    "SPELLFORGE_UI_SETTINGS_REGISTERED",
    "SPELLFORGE_PLAYER_RUNTIME_RESET_ON_LOAD",
    "SPELLFORGE_STALE_SELECTED_SPELL_ALIAS_REGISTERED",
    "SPELLFORGE_CAST_TRACE",
    "backend ready version=",
}

local INFO_AS_TRACE_MARKERS = {
    spellbook_scan = {
        "SPELLFORGE_KNOWN_EFFECT_SCAN_START",
        "SPELLFORGE_KNOWN_EFFECT_SCAN_ENTRY_SAMPLE",
        "SPELLFORGE_KNOWN_EFFECT_SCAN_SPELL_ID_MISSING",
        "SPELLFORGE_KNOWN_EFFECT_SCAN_SPELL_ID_OK",
        "SPELLFORGE_KNOWN_EFFECT_SCAN_SPELL_TYPE_SKIPPED",
        "SPELLFORGE_KNOWN_EFFECT_SCAN_SPELL_TYPE_OK",
        "SPELLFORGE_KNOWN_EFFECT_SCAN_RECORD_MISSING",
        "SPELLFORGE_KNOWN_EFFECT_SCAN_RECORD_OK",
        "SPELLFORGE_KNOWN_EFFECT_SCAN_EFFECT_OK",
    },
    rehydrate = {
        "SPELLFORGE_REHYDRATE_START",
        "SPELLFORGE_REHYDRATE_ENTRY",
        "SPELLFORGE_REHYDRATE_GLOBAL_INDEX_OK",
        "SPELLFORGE_REHYDRATE_FRONTEND_RECORD_OK",
        "SPELLFORGE_REHYDRATE_PLAN_OK",
        "SPELLFORGE_REHYDRATE_HELPERS_OK",
        "SPELLFORGE_SAVE_LOAD_PERSISTENCE_OK saved_recipe_id=",
        "generated_engine_spell_ids=",
    },
    projectiles = {
        "SPELLFORGE_PROJECTILE_REGISTRY_CLEARED",
        "SPELLFORGE_PROJECTILE_REGISTERED",
        "SPELLFORGE_LIVE_TRIGGER_SOURCE_OK",
        "SPELLFORGE_LIVE_TIMER_SOURCE_OK",
        "SPELLFORGE_LIVE_BOUNCE",
        "SPELLFORGE_LIVE_PIERCE",
        "SPELLFORGE_LIVE_CHAIN",
        "SPELLFORGE_LIVE_SOFT_HOMING",
        "projectile_id=",
    },
    sfp = {
        "SPELLFORGE_SFP_CALL_GUARDED",
        "SPELLFORGE_SFP_CALL_SKIPPED_STALE_GENERATION",
        "SFP",
        "MagExp",
    },
    ui = {
        "SPELLFORGE_UI_PLACEHOLDER_AUDIT_OK",
        "SPELLFORGE_SPELLCRAFT_UI_SAVE_OK",
        "SPELLFORGE_SPELLCRAFT_UI_VALIDATE_OK",
        "SPELLFORGE_SPELLCRAFT_UI_PREVIEW_OK",
        "SPELLFORGE_SPELLCRAFT_UI_COMPILE_OK",
        "SPELLFORGE_PLAYER_UI_RUNTIME_RESET",
    },
    speed = {
        "SPELLFORGE_PROJECTILE_SPEED_BASELINE",
        "SPELLFORGE_HELPER_LAUNCH_SPEED",
        "SPELLFORGE_SPEED_PLUS_LAUNCH_SPEED",
        "speed=",
        "maxSpeed=",
    },
}

local INFO_AS_DEBUG_MARKERS = {
    "SPELLFORGE_RECORDS_EXPORTED_ON_SAVE",
    "SPELLFORGE_RECORDS_IMPORTED_ON_LOAD",
    "SPELLFORGE_RECORDS_RELOADED_ON_LOAD",
    "SPELLFORGE_GLOBAL_REHYDRATE_GATE_RESET_ON_LOAD",
    "SPELLFORGE_RUNTIME_SAVE_LOAD_PROJECTILE_CRASH_GUARD_OK",
    "SPELLFORGE_RUNTIME_GENERATION_INCREMENTED",
    "SPELLFORGE_RUNTIME_GENERATION_SEEDED",
    "SPELLFORGE_ORCHESTRATOR_CLEARED",
    "SPELLFORGE_LIVE_TIMER_CLEARED",
    "SPELLFORGE_LIVE_TRIGGER_CLEARED",
    "SPELLFORGE_LIVE_CHAIN_CLEARED",
    "SPELLFORGE_LIVE_BOUNCE_CLEARED",
    "SPELLFORGE_LIVE_PIERCE_CLEARED",
    "SPELLFORGE_LIVE_SOFT_HOMING_CLEARED",
    "SPELLFORGE_COMPILED_DISPATCH_OK",
    "SPELLFORGE_LIVE_2_2C_SIMPLE_DISPATCH_OK",
    "SPELLFORGE_FRONTEND_DISPLAY_",
    "SPELLFORGE_COST_",
    "SPELLFORGE_SUPPORT_TRUTH_",
    "SPELLFORGE_PAYLOAD_PARSE_CONTEXT_OK",
    "SPELLFORGE_PLAYER_SELECTED_METADATA_REFRESH_",
    "SPELLFORGE_STALE_SELECTED_SPELL_ALIAS_USED",
    "ActorSpells:add",
    "compile success",
    "compiled recipe_id=",
}

local function readBoolean(key, default_value)
    local value = section:get(key)
    if value == nil then
        return default_value
    end
    return value == true
end

local function readString(key, default_value)
    local value = section:get(key)
    if type(value) == "string" and value ~= "" then
        return value
    end
    return default_value
end

local function normalizeLevel(level)
    if type(level) ~= "string" then
        return string.lower(log.LOG_LEVEL)
    end
    local normalized = string.lower(level)
    if LEVELS[normalized] ~= nil then
        return normalized
    end
    return string.lower(log.LOG_LEVEL)
end

local function currentLevel()
    return normalizeLevel(readString(SETTINGS_KEY_LEVEL, log.LOG_LEVEL))
end

local function diagnosticsEnabled()
    return readBoolean(SETTINGS_KEY_DIAGNOSTICS, log.LOG_DIAGNOSTICS)
end

local function traceFlagEnabled(category)
    if category == "spellbook_scan" then
        return readBoolean(SETTINGS_KEY_TRACE_SPELLBOOK_SCAN, log.LOG_TRACE_SPELLBOOK_SCAN)
    elseif category == "rehydrate" then
        return readBoolean(SETTINGS_KEY_TRACE_REHYDRATE, log.LOG_TRACE_REHYDRATE)
    elseif category == "projectiles" then
        return readBoolean(SETTINGS_KEY_TRACE_PROJECTILES, log.LOG_TRACE_PROJECTILES)
    elseif category == "sfp" then
        return readBoolean(SETTINGS_KEY_TRACE_SFP_CALLS, log.LOG_TRACE_SFP_CALLS)
    elseif category == "ui" then
        return readBoolean(SETTINGS_KEY_TRACE_UI, log.LOG_TRACE_UI)
    elseif category == "speed" then
        return readBoolean(SETTINGS_KEY_TRACE_SPEED, log.LOG_TRACE_SPEED)
    end
    return false
end

local function containsAny(message, markers)
    for _, marker in ipairs(markers or {}) do
        if string.find(message, marker, 1, true) then
            return true
        end
    end
    return false
end

local function traceCategory(message)
    for category, markers in pairs(INFO_AS_TRACE_MARKERS) do
        if containsAny(message, markers) then
            return category
        end
    end
    return nil
end

local function messageFrom(...)
    local count = select("#", ...)
    if count == 0 then
        return ""
    end
    if count == 1 then
        return tostring(select(1, ...))
    end
    local parts = {}
    for i = 1, count do
        parts[i] = tostring(select(i, ...))
    end
    return table.concat(parts, " ")
end

local function releaseInfoAllowed(message)
    return containsAny(message, RELEASE_INFO_MARKERS)
end

local function classifiedLevel(level, message)
    if level ~= "info" then
        return level
    end
    local category = traceCategory(message)
    if category ~= nil then
        return "trace", category
    end
    if containsAny(message, INFO_AS_DEBUG_MARKERS) then
        return "debug", nil
    end
    if releaseInfoAllowed(message) then
        return "info", nil
    end
    return "debug", nil
end

local function shouldEmit(level, message)
    local effective_level, category = classifiedLevel(level, message)
    if effective_level == "error" or effective_level == "warn" then
        return true, effective_level
    end
    if diagnosticsEnabled() then
        return true, effective_level
    end
    if category ~= nil and traceFlagEnabled(category) then
        return true, effective_level
    end
    local configured = currentLevel()
    if effective_level == "trace" then
        return configured == "trace", effective_level
    end
    if LEVELS[effective_level] < LEVELS[configured] then
        return false, effective_level
    end
    if level == "info" and effective_level ~= "info" and configured == "info" then
        return false, effective_level
    end
    return true, effective_level
end

local function emit(level, module_name, ...)
    local message = messageFrom(...)
    local allowed, effective_level = shouldEmit(level, message)
    if not allowed then
        return false
    end
    local output_message = message
    if effective_level == "error" and not string.find(message, "SPELLFORGE_RUNTIME_ERROR", 1, true) then
        output_message = "SPELLFORGE_RUNTIME_ERROR " .. message
    end
    print(string.format("[spellforge][%s][%s] %s", module_name, LEVEL_NAMES[LEVELS[effective_level]], output_message))
    return true
end

local function announcePolicy()
    if policy_announced then
        return
    end
    policy_announced = true
    emit(
        "info",
        "shared.log",
        string.format(
            "SPELLFORGE_RELEASE_LOGGING_POLICY_OK log_level=%s diagnostics=%s trace_spellbook_scan=%s trace_rehydrate=%s trace_projectiles=%s trace_sfp_calls=%s trace_ui=%s trace_speed=%s",
            tostring(currentLevel()),
            tostring(diagnosticsEnabled()),
            tostring(traceFlagEnabled("spellbook_scan")),
            tostring(traceFlagEnabled("rehydrate")),
            tostring(traceFlagEnabled("projectiles")),
            tostring(traceFlagEnabled("sfp")),
            tostring(traceFlagEnabled("ui")),
            tostring(traceFlagEnabled("speed"))
        )
    )
end

function log.setLevel(level)
    local setter = sectionSetter()
    if not setter then
        return false
    end
    setter(section, SETTINGS_KEY_LEVEL, normalizeLevel(level))
    return true
end

function log.setDiagnostics(enabled)
    local setter = sectionSetter()
    if not setter then
        return false
    end
    setter(section, SETTINGS_KEY_DIAGNOSTICS, enabled == true)
    return true
end

function log.setTraceFlag(category, enabled)
    local key_by_category = {
        spellbook_scan = SETTINGS_KEY_TRACE_SPELLBOOK_SCAN,
        rehydrate = SETTINGS_KEY_TRACE_REHYDRATE,
        projectiles = SETTINGS_KEY_TRACE_PROJECTILES,
        sfp = SETTINGS_KEY_TRACE_SFP_CALLS,
        ui = SETTINGS_KEY_TRACE_UI,
        speed = SETTINGS_KEY_TRACE_SPEED,
    }
    local key = key_by_category[category]
    local setter = sectionSetter()
    if not key or not setter then
        return false
    end
    setter(section, key, enabled == true)
    return true
end

function log.new(module_name)
    local name = module_name or "unknown"
    announcePolicy()
    local logger = {}
    logger.trace = function(...) return emit("trace", name, ...) end
    logger.debug = function(...) return emit("debug", name, ...) end
    logger.info = function(...) return emit("info", name, ...) end
    logger.warn = function(...) return emit("warn", name, ...) end
    logger.error = function(...) return emit("error", name, ...) end
    logger.once = function(key, level, ...)
        local once_key = tostring(name) .. ":" .. tostring(key)
        if once_keys[once_key] then
            return false
        end
        once_keys[once_key] = true
        return emit(normalizeLevel(level), name, ...)
    end
    logger.rateLimited = function(key, seconds, level, ...)
        local rate_key = tostring(name) .. ":" .. tostring(key)
        local now = os.time()
        local interval = tonumber(seconds) or 1
        local previous = rate_limited[rate_key]
        if previous and (now - previous) < interval then
            return false
        end
        rate_limited[rate_key] = now
        return emit(normalizeLevel(level), name, ...)
    end
    logger.summary = function(key, ...)
        return logger.once("summary:" .. tostring(key), "info", ...)
    end
    return logger
end

return log
