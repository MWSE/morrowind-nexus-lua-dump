local storage = require("openmw.storage")

local dev = {}

local section = storage.globalSection("SpellforgeDev")
local KEY_ENABLE_SMOKE_TESTS = "enable_smoke_tests"
local KEY_ENABLE_DEV_HOTKEYS = "enable_dev_hotkeys"
local KEY_ENABLE_SPELLCRAFTING_UI = "enable_spellcrafting_ui"
local KEY_ENABLE_DEBUG_LAUNCH = "enable_debug_launch"
local KEY_ENABLE_DEV_LAUNCH = "enable_dev_launch"
local KEY_ENABLE_LIVE_2_2C_RUNTIME = "enable_live_2_2c_runtime"
local KEY_ENABLE_LIVE_MULTICAST = "enable_live_multicast"
local KEY_ENABLE_LIVE_SPREAD_BURST = "enable_live_spread_burst"
local KEY_ENABLE_LIVE_TRIGGER = "enable_live_trigger"
local KEY_ENABLE_LIVE_TIMER = "enable_live_timer"
local KEY_ENABLE_LIVE_SPEED_PLUS = "enable_live_speed_plus"
local KEY_ENABLE_LIVE_SIZE_PLUS = "enable_live_size_plus"
local KEY_ENABLE_LIVE_PAYLOAD_MULTICAST = "enable_live_payload_multicast_v0"
local KEY_ENABLE_LIVE_PAYLOAD_PATTERN = "enable_live_payload_pattern_v0"
local KEY_ENABLE_LIVE_NESTED_TRIGGER_TIMER = "enable_live_nested_trigger_timer_v1"
local KEY_ENABLE_LIVE_NESTED_FINAL_FANOUT = "enable_live_nested_final_fanout_v0"
local KEY_ENABLE_LIVE_CHAIN_AUDIT = "enable_live_chain_audit_v0"
local KEY_ENABLE_LIVE_CHAIN_RUNTIME = "enable_live_chain_runtime_v0"
local KEY_ENABLE_LIVE_BOUNCE = "enable_live_bounce_v0"
local KEY_ENABLE_LIVE_PIERCE = "enable_live_pierce_v0"
local KEY_ENABLE_LIVE_HOMING = "enable_live_homing_v0"
local KEY_ENABLE_LIVE_SOFT_HOMING = "enable_live_soft_homing_v0"
local KEY_ENABLE_LIVE_SOFT_HOMING_PROBE = "enable_live_soft_homing_probe"
local KEY_ENABLE_LIVE_HOMING_V2_MANAGER = "enable_live_homing_v2_manager"
local KEY_ENABLE_LIVE_CHAIN_MULTICAST = "enable_live_chain_multicast_v0"
local KEY_ENABLE_CHAOS_BUDGET = "enable_chaos_budget_v0"
local KEY_ENABLE_IR_TRIGGER_RUNTIME = "enable_ir_trigger_runtime_v0"
local KEY_ENABLE_IR_TIMER_RUNTIME = "enable_ir_timer_runtime_v0"
local KEY_ENABLE_IR_BOUNCE_RUNTIME = "enable_ir_bounce_runtime_v0"
local KEY_ENABLE_IR_CHAIN_RUNTIME = "enable_ir_chain_runtime_v0"
local KEY_ENABLE_IR_PIERCE_RUNTIME = "enable_ir_pierce_runtime_v0"
local KEY_ENABLE_IR_RUNTIME_STRICT = "enable_ir_runtime_strict_v0"
local KEY_ENABLE_LEGACY_TRIGGER_RUNTIME = "enable_legacy_trigger_runtime_v0"
local KEY_ENABLE_LEGACY_TIMER_RUNTIME = "enable_legacy_timer_runtime_v0"
local KEY_ENABLE_LEGACY_BOUNCE_RUNTIME = "enable_legacy_bounce_runtime_v0"
local KEY_ENABLE_LEGACY_CHAIN_RUNTIME = "enable_legacy_chain_runtime_v0"
local KEY_DIAG_OSSC_STYLE_CAST_REQUEST = "diag_ossc_style_cast_request"
local KEY_DIAG_OSSC_STYLE_REAL_SPELL_ID = "diag_ossc_style_real_spell_id"

local DEFAULT_ENABLE_SMOKE_TESTS = false
local DEFAULT_ENABLE_DEV_HOTKEYS = false
local DEFAULT_ENABLE_SPELLCRAFTING_UI = true
local DEFAULT_ENABLE_DEBUG_LAUNCH = false
local DEFAULT_ENABLE_DEV_LAUNCH = false
local DEFAULT_ENABLE_LIVE_2_2C_RUNTIME = true
local DEFAULT_ENABLE_LIVE_MULTICAST = true
local DEFAULT_ENABLE_LIVE_SPREAD_BURST = true
local DEFAULT_ENABLE_LIVE_TRIGGER = true
local DEFAULT_ENABLE_LIVE_TIMER = true
local DEFAULT_ENABLE_LIVE_SPEED_PLUS = true
local DEFAULT_ENABLE_LIVE_SIZE_PLUS = true
local DEFAULT_ENABLE_LIVE_PAYLOAD_MULTICAST = true
local DEFAULT_ENABLE_LIVE_PAYLOAD_PATTERN = true
local DEFAULT_ENABLE_LIVE_NESTED_TRIGGER_TIMER = true
local DEFAULT_ENABLE_LIVE_NESTED_FINAL_FANOUT = true
local DEFAULT_ENABLE_LIVE_CHAIN_AUDIT = false
local DEFAULT_ENABLE_LIVE_CHAIN_RUNTIME = true
local DEFAULT_ENABLE_LIVE_BOUNCE = true
local DEFAULT_ENABLE_LIVE_PIERCE = true
local DEFAULT_ENABLE_LIVE_HOMING = true
local DEFAULT_ENABLE_LIVE_SOFT_HOMING = false
local DEFAULT_ENABLE_LIVE_SOFT_HOMING_PROBE = false
local DEFAULT_ENABLE_LIVE_HOMING_V2_MANAGER = true
local DEFAULT_ENABLE_LIVE_CHAIN_MULTICAST = false
local DEFAULT_ENABLE_CHAOS_BUDGET = false
local DEFAULT_ENABLE_IR_TRIGGER_RUNTIME = false
local DEFAULT_ENABLE_IR_TIMER_RUNTIME = false
local DEFAULT_ENABLE_IR_BOUNCE_RUNTIME = false
local DEFAULT_ENABLE_IR_CHAIN_RUNTIME = false
local DEFAULT_ENABLE_IR_PIERCE_RUNTIME = false
local DEFAULT_ENABLE_IR_RUNTIME_STRICT = false
local DEFAULT_ENABLE_LEGACY_TRIGGER_RUNTIME = false
local DEFAULT_ENABLE_LEGACY_TIMER_RUNTIME = false
local DEFAULT_ENABLE_LEGACY_BOUNCE_RUNTIME = false
local DEFAULT_ENABLE_LEGACY_CHAIN_RUNTIME = false
-- Diagnostic only. Sends an OSSC-style MagExp_CastRequest using a real
-- vanilla spell id and no explicit speed/maxSpeed to compare SFP behavior
-- against Spellforge generated-helper launches.
local DEFAULT_DIAG_OSSC_STYLE_CAST_REQUEST = false
local DEFAULT_DIAG_OSSC_STYLE_REAL_SPELL_ID = "fireball"

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

function dev.smokeTestsEnabled()
    return readBoolean(KEY_ENABLE_SMOKE_TESTS, DEFAULT_ENABLE_SMOKE_TESTS)
end

function dev.devHotkeysEnabled()
    return readBoolean(KEY_ENABLE_DEV_HOTKEYS, DEFAULT_ENABLE_DEV_HOTKEYS)
end

function dev.spellcraftingUiEnabled()
    return readBoolean(KEY_ENABLE_SPELLCRAFTING_UI, DEFAULT_ENABLE_SPELLCRAFTING_UI)
        or dev.devHotkeysEnabled()
        or dev.smokeTestsEnabled()
end

function dev.debugLaunchEnabled()
    return dev.devHotkeysEnabled() and readBoolean(KEY_ENABLE_DEBUG_LAUNCH, DEFAULT_ENABLE_DEBUG_LAUNCH)
end

function dev.devLaunchEnabled()
    return readBoolean(KEY_ENABLE_DEV_LAUNCH, DEFAULT_ENABLE_DEV_LAUNCH)
end

function dev.liveSimpleDispatchEnabled()
    return readBoolean(KEY_ENABLE_LIVE_2_2C_RUNTIME, DEFAULT_ENABLE_LIVE_2_2C_RUNTIME)
end

function dev.liveMulticastEnabled()
    return readBoolean(KEY_ENABLE_LIVE_MULTICAST, DEFAULT_ENABLE_LIVE_MULTICAST)
end

function dev.liveSpreadBurstEnabled()
    return readBoolean(KEY_ENABLE_LIVE_SPREAD_BURST, DEFAULT_ENABLE_LIVE_SPREAD_BURST)
end

function dev.liveTriggerEnabled()
    return readBoolean(KEY_ENABLE_LIVE_TRIGGER, DEFAULT_ENABLE_LIVE_TRIGGER)
end

function dev.liveTimerEnabled()
    return readBoolean(KEY_ENABLE_LIVE_TIMER, DEFAULT_ENABLE_LIVE_TIMER)
end

function dev.liveSpeedPlusEnabled()
    return readBoolean(KEY_ENABLE_LIVE_SPEED_PLUS, DEFAULT_ENABLE_LIVE_SPEED_PLUS)
end

function dev.liveSizePlusEnabled()
    return readBoolean(KEY_ENABLE_LIVE_SIZE_PLUS, DEFAULT_ENABLE_LIVE_SIZE_PLUS)
end

function dev.livePayloadMulticastEnabled()
    return readBoolean(KEY_ENABLE_LIVE_PAYLOAD_MULTICAST, DEFAULT_ENABLE_LIVE_PAYLOAD_MULTICAST)
end

function dev.livePayloadPatternEnabled()
    return readBoolean(KEY_ENABLE_LIVE_PAYLOAD_PATTERN, DEFAULT_ENABLE_LIVE_PAYLOAD_PATTERN)
end

function dev.liveNestedTriggerTimerEnabled()
    return readBoolean(KEY_ENABLE_LIVE_NESTED_TRIGGER_TIMER, DEFAULT_ENABLE_LIVE_NESTED_TRIGGER_TIMER)
end

function dev.liveNestedFinalFanoutEnabled()
    return readBoolean(KEY_ENABLE_LIVE_NESTED_FINAL_FANOUT, DEFAULT_ENABLE_LIVE_NESTED_FINAL_FANOUT)
end

function dev.liveChainAuditEnabled()
    return readBoolean(KEY_ENABLE_LIVE_CHAIN_AUDIT, DEFAULT_ENABLE_LIVE_CHAIN_AUDIT)
end

function dev.liveChainRuntimeEnabled()
    return readBoolean(KEY_ENABLE_LIVE_CHAIN_RUNTIME, DEFAULT_ENABLE_LIVE_CHAIN_RUNTIME)
end

function dev.liveBounceEnabled()
    return readBoolean(KEY_ENABLE_LIVE_BOUNCE, DEFAULT_ENABLE_LIVE_BOUNCE)
end

function dev.livePierceEnabled()
    return readBoolean(KEY_ENABLE_LIVE_PIERCE, DEFAULT_ENABLE_LIVE_PIERCE)
end

function dev.liveHomingEnabled()
    return readBoolean(KEY_ENABLE_LIVE_HOMING, DEFAULT_ENABLE_LIVE_HOMING)
end

function dev.liveSoftHomingEnabled()
    return readBoolean(KEY_ENABLE_LIVE_SOFT_HOMING, DEFAULT_ENABLE_LIVE_SOFT_HOMING)
end

function dev.liveSoftHomingProbeEnabled()
    return readBoolean(KEY_ENABLE_LIVE_SOFT_HOMING_PROBE, DEFAULT_ENABLE_LIVE_SOFT_HOMING_PROBE)
end

function dev.liveHomingV2ManagerEnabled()
    return readBoolean(KEY_ENABLE_LIVE_HOMING_V2_MANAGER, DEFAULT_ENABLE_LIVE_HOMING_V2_MANAGER)
end

function dev.liveChainMulticastEnabled()
    return readBoolean(KEY_ENABLE_LIVE_CHAIN_MULTICAST, DEFAULT_ENABLE_LIVE_CHAIN_MULTICAST)
end

function dev.chaosBudgetEnabled()
    return readBoolean(KEY_ENABLE_CHAOS_BUDGET, DEFAULT_ENABLE_CHAOS_BUDGET)
end

function dev.irTriggerRuntimeEnabled()
    return readBoolean(KEY_ENABLE_IR_TRIGGER_RUNTIME, DEFAULT_ENABLE_IR_TRIGGER_RUNTIME)
        or dev.liveTriggerEnabled()
end

function dev.irTimerRuntimeEnabled()
    return readBoolean(KEY_ENABLE_IR_TIMER_RUNTIME, DEFAULT_ENABLE_IR_TIMER_RUNTIME)
        or dev.liveTimerEnabled()
end

function dev.irBounceRuntimeEnabled()
    return readBoolean(KEY_ENABLE_IR_BOUNCE_RUNTIME, DEFAULT_ENABLE_IR_BOUNCE_RUNTIME)
        or dev.liveBounceEnabled()
end

function dev.irChainRuntimeEnabled()
    return readBoolean(KEY_ENABLE_IR_CHAIN_RUNTIME, DEFAULT_ENABLE_IR_CHAIN_RUNTIME)
        or dev.liveChainRuntimeEnabled()
end

function dev.irPierceRuntimeEnabled()
    return readBoolean(KEY_ENABLE_IR_PIERCE_RUNTIME, DEFAULT_ENABLE_IR_PIERCE_RUNTIME)
        or dev.livePierceEnabled()
end

function dev.irRuntimeStrictEnabled()
    return readBoolean(KEY_ENABLE_IR_RUNTIME_STRICT, DEFAULT_ENABLE_IR_RUNTIME_STRICT)
end

function dev.legacyTriggerRuntimeEnabled()
    return readBoolean(KEY_ENABLE_LEGACY_TRIGGER_RUNTIME, DEFAULT_ENABLE_LEGACY_TRIGGER_RUNTIME)
end

function dev.legacyTimerRuntimeEnabled()
    return readBoolean(KEY_ENABLE_LEGACY_TIMER_RUNTIME, DEFAULT_ENABLE_LEGACY_TIMER_RUNTIME)
end

function dev.legacyBounceRuntimeEnabled()
    return readBoolean(KEY_ENABLE_LEGACY_BOUNCE_RUNTIME, DEFAULT_ENABLE_LEGACY_BOUNCE_RUNTIME)
end

function dev.legacyChainRuntimeEnabled()
    return readBoolean(KEY_ENABLE_LEGACY_CHAIN_RUNTIME, DEFAULT_ENABLE_LEGACY_CHAIN_RUNTIME)
end

function dev.diagOsscStyleCastRequestEnabled()
    return readBoolean(KEY_DIAG_OSSC_STYLE_CAST_REQUEST, DEFAULT_DIAG_OSSC_STYLE_CAST_REQUEST)
end

function dev.diagOsscStyleRealSpellId()
    return readString(KEY_DIAG_OSSC_STYLE_REAL_SPELL_ID, DEFAULT_DIAG_OSSC_STYLE_REAL_SPELL_ID)
end

function dev.smokeTestsSettingKey()
    return "SpellforgeDev.enable_smoke_tests"
end

function dev.devHotkeysSettingKey()
    return "SpellforgeDev.enable_dev_hotkeys"
end

function dev.spellcraftingUiSettingKey()
    return "SpellforgeDev.enable_spellcrafting_ui"
end

function dev.debugLaunchSettingKey()
    return "SpellforgeDev.enable_debug_launch"
end

function dev.devLaunchSettingKey()
    return "SpellforgeDev.enable_dev_launch"
end

function dev.liveSimpleDispatchSettingKey()
    return "SpellforgeDev.enable_live_2_2c_runtime"
end

function dev.liveMulticastSettingKey()
    return "SpellforgeDev.enable_live_multicast"
end

function dev.liveSpreadBurstSettingKey()
    return "SpellforgeDev.enable_live_spread_burst"
end

function dev.liveTriggerSettingKey()
    return "SpellforgeDev.enable_live_trigger"
end

function dev.liveTimerSettingKey()
    return "SpellforgeDev.enable_live_timer"
end

function dev.liveSpeedPlusSettingKey()
    return "SpellforgeDev.enable_live_speed_plus"
end

function dev.liveSizePlusSettingKey()
    return "SpellforgeDev.enable_live_size_plus"
end

function dev.livePayloadMulticastSettingKey()
    return "SpellforgeDev.enable_live_payload_multicast_v0"
end

function dev.livePayloadPatternSettingKey()
    return "SpellforgeDev.enable_live_payload_pattern_v0"
end

function dev.liveNestedTriggerTimerSettingKey()
    return "SpellforgeDev.enable_live_nested_trigger_timer_v1"
end

function dev.liveNestedFinalFanoutSettingKey()
    return "SpellforgeDev.enable_live_nested_final_fanout_v0"
end

function dev.liveChainAuditSettingKey()
    return "SpellforgeDev.enable_live_chain_audit_v0"
end

function dev.liveChainRuntimeSettingKey()
    return "SpellforgeDev.enable_live_chain_runtime_v0"
end

function dev.liveBounceSettingKey()
    return "SpellforgeDev.enable_live_bounce_v0"
end

function dev.livePierceSettingKey()
    return "SpellforgeDev.enable_live_pierce_v0"
end

function dev.liveHomingSettingKey()
    return "SpellforgeDev.enable_live_homing_v0"
end

function dev.liveSoftHomingSettingKey()
    return "SpellforgeDev.enable_live_soft_homing_v0"
end

function dev.liveSoftHomingProbeSettingKey()
    return "SpellforgeDev.enable_live_soft_homing_probe"
end

function dev.liveHomingV2ManagerSettingKey()
    return "SpellforgeDev.enable_live_homing_v2_manager"
end

function dev.liveChainMulticastSettingKey()
    return "SpellforgeDev.enable_live_chain_multicast_v0"
end

function dev.chaosBudgetSettingKey()
    return "SpellforgeDev.enable_chaos_budget_v0"
end

function dev.irTriggerRuntimeSettingKey()
    return "SpellforgeDev.enable_ir_trigger_runtime_v0"
end

function dev.irTimerRuntimeSettingKey()
    return "SpellforgeDev.enable_ir_timer_runtime_v0"
end

function dev.irBounceRuntimeSettingKey()
    return "SpellforgeDev.enable_ir_bounce_runtime_v0"
end

function dev.irChainRuntimeSettingKey()
    return "SpellforgeDev.enable_ir_chain_runtime_v0"
end

function dev.irPierceRuntimeSettingKey()
    return "SpellforgeDev.enable_ir_pierce_runtime_v0"
end

function dev.irRuntimeStrictSettingKey()
    return "SpellforgeDev.enable_ir_runtime_strict_v0"
end

function dev.legacyTriggerRuntimeSettingKey()
    return "SpellforgeDev.enable_legacy_trigger_runtime_v0"
end

function dev.legacyTimerRuntimeSettingKey()
    return "SpellforgeDev.enable_legacy_timer_runtime_v0"
end

function dev.legacyBounceRuntimeSettingKey()
    return "SpellforgeDev.enable_legacy_bounce_runtime_v0"
end

function dev.legacyChainRuntimeSettingKey()
    return "SpellforgeDev.enable_legacy_chain_runtime_v0"
end

function dev.diagOsscStyleCastRequestSettingKey()
    return "SpellforgeDev.diag_ossc_style_cast_request"
end

function dev.diagOsscStyleRealSpellIdSettingKey()
    return "SpellforgeDev.diag_ossc_style_real_spell_id"
end

return dev
