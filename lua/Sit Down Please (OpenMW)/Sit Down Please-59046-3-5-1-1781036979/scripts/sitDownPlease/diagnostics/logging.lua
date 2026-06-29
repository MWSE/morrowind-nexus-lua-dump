-- diagnostics/logging.lua
---@omw-context none
--
-- Shared SDP logging policy. Keep raw print decisions here so trace/verbose
-- behavior stays consistent across global, player, and local scripts.

local M = {}

M.LEVEL_OFF = "off"
M.LEVEL_TRACE = "trace"
M.LEVEL_VERBOSE = "verbose"

M.NOISY_TRACE_TAGS = {
    ["candidate scan"] = true,
    ["candidate count"] = true,
    ["candidate within radius"] = true,
    ["no candidate within radius"] = true,
    ["profile selection selected"] = true,
    ["sitting stand exit candidate selected"] = true,
    ["sitting stand exit candidate rejected"] = true,
    ["sitting focus candidate rejected blocked"] = true,
    ["sitting facing candidate rejected origin_only_bench_focus"] = true,
    ["reject"] = true,
    ["reject object occupied"] = true,
    ["reject relevant object"] = true,
    ["reject by time"] = true,
    ["reject by release safety gate"] = true,
    ["lecture assignment skipped by release safety gate"] = true,
    ["lecture object skipped by release safety gate"] = true,
    ["relevant object cache hit"] = true,
    ["relevant object cache cleared"] = true,
    ["sleep priority no available beds"] = true,
    ["sleep priority skip npc"] = true,
    ["sleep priority summary"] = true,
    ["sleep surface clutter ignored distant from final pose"] = true,
    ["sleep surface soft clutter ignored weak surface"] = true,
    ["sleep lights cache hit"] = true,
    ["skip npc"] = true,
    ["reject object physically claimed"] = true,
    ["reject sleep bed reserved"] = true,
    ["reject sleep route cooldown"] = true,
    ["sleep_before_start_hour"] = true,
    ["sleep_after_actor_wake_time"] = true,
    ["guard_or_publican_class"] = true,
    ["barter_service_npc"] = true,
    ["external_animation_npc"] = true,
    ["active_travel_package"] = true,
    ["collision_or_raycast_validation_failed"] = true,
    ["sleep lights scan"] = true,
    ["sleep lights scan detail"] = true,
    ["sleep light off"] = true,
    ["sleep light restore"] = true,
    ["teleport busy deferred"] = true,
    ["bench open-side profile received focus"] = true,
    ["bench slot positions local"] = true,
    ["bench basis comparison current_vs_legacy"] = true,
    ["bench extents raw"] = true,
    ["bench long axis selected"] = true,
    ["lectern focus candidate summary"] = true,
    ["initial placement overlay pending state cleared"] = true,
    ["initial placement overlay dynamic hold pending events"] = true,
    ["initial placement overlay visible state before cell render"] = true,
    ["initial placement overlay not settled pending local results"] = true,
    ["initial placement overlay aggregate settle ignored pending actor results"] = true,
}

M.NOISY_VERBOSE_TAGS = {
    ["candidate scan"] = true,
    ["candidate count"] = true,
    ["candidate within radius"] = true,
    ["no candidate within radius"] = true,
    ["consider"] = true,
    ["skip npc"] = true,
    ["accepted"] = true,
    ["accepted assignment"] = true,
    ["accepted local"] = true,
    ["global sitting accepted result received"] = true,
    ["profile selection selected"] = true,
    ["sitting stand exit candidate selected"] = true,
    ["sitting stand exit candidate rejected"] = true,
    ["sitting focus candidate rejected blocked"] = true,
    ["sitting facing candidate rejected origin_only_bench_focus"] = true,
    ["reject object occupied"] = true,
    ["reject relevant object"] = true,
    ["reject by time"] = true,
    ["reject object physically claimed"] = true,
    ["reject sleep bed reserved"] = true,
    ["reject sleep route cooldown"] = true,
    ["reject stationed behind counter"] = true,
    ["wake cleanup probe sent"] = true,
    ["relevant object cache hit"] = true,
    ["relevant object cache cleared"] = true,
    ["sleep candidate rejected non_sleep_object"] = true,
    ["sleep candidate rejected clothing"] = true,
    ["sleep surface clutter ignored distant from final pose"] = true,
    ["sleep surface clutter ignored outside slot grid"] = true,
    ["sleep surface soft clutter ignored weak surface"] = true,
    ["sleep lights cache hit"] = true,
    ["sleep lights batch pending sleepers count"] = true,
    ["sleep lights off request"] = true,
    ["sleep lights deferred until batch complete"] = true,
    ["sleep lights pending sleeper ignored as awake"] = true,
    ["sleep priority no available beds"] = true,
    ["sleep priority skip npc"] = true,
    ["sleep priority summary"] = true,
    ["sleep_entry_rejected"] = true,
    ["sleep reservation created"] = true,
    ["sleep reservation reused"] = true,
    ["sleep reservation state"] = true,
    ["sleep animation groups force-cancelled"] = true,
    ["sleep animation queue force-cleared"] = true,
    ["sleep animation queue cleared"] = true,
    ["stale sleep animation cleared before sitting validation"] = true,
    ["sitting animation groups force-cancelled"] = true,
    ["seeker ready initial assignment scan"] = true,
    ["npc seeker ready"] = true,
    ["resolved sitting transform"] = true,
    ["sitting local acceptance begin"] = true,
    ["sitting solver basis"] = true,
    ["sitting calibration baseline"] = true,
    ["sitting local acceptance sending result"] = true,
    ["sitting local acceptance sent"] = true,
    ["bench open-side profile received focus"] = true,
    ["bench slot positions local"] = true,
    ["bench slot count computed"] = true,
    ["bench multi slot allowed"] = true,
    ["bench explicit slots widened from tight sampled spacing"] = true,
    ["bench basis comparison current_vs_legacy"] = true,
    ["bench extents raw"] = true,
    ["bench long axis selected"] = true,
    ["lectern focus candidate summary"] = true,
    ["initial placement overlay reused existing cover"] = true,
    ["initial placement overlay duplicate show suppressed"] = true,
    ["initial placement overlay prevented show_settle_show"] = true,
    ["initial placement overlay post animation settle hold"] = true,
    ["initial placement overlay final settle after all initial candidates resolved"] = true,
}

local function normalizedLevelName(value)
    if value == nil then return nil end
    local level = string.lower(tostring(value))
    if level == "verbose" then return M.LEVEL_VERBOSE end
    if level == "trace" or level == "debug" then return M.LEVEL_TRACE end
    if level == "off" or level == "normal" or level == "" then return M.LEVEL_OFF end
    return nil
end

function M.level(settings)
    local level = normalizedLevelName(settings and settings.logLevel)
    if level then return level end
    if settings and (settings.verboseDebug == true or settings.debugVerbose == true) then return M.LEVEL_VERBOSE end
    if settings and settings.debug == true then return M.LEVEL_TRACE end
    return M.LEVEL_OFF
end

function M.applyDerivedFlags(settings)
    if not settings then return settings end
    local level = M.level(settings)
    settings.logLevel = level
    settings.debug = level == M.LEVEL_TRACE or level == M.LEVEL_VERBOSE
    settings.verboseDebug = level == M.LEVEL_VERBOSE
    settings.debugVerbose = settings.verboseDebug
    return settings
end

function M.isNoisyTraceTag(tag)
    local text = tostring(tag)
    return M.NOISY_TRACE_TAGS[text] == true
        or M.NOISY_VERBOSE_TAGS[text] == true
end

function M.isNoisyTraceArgs(...)
    -- Local NPC scripts prefix diagnostics with the actor id before the message
    -- tag, so trace-level flood filtering must inspect both leading fields.
    return M.isNoisyTraceTag(select(1, ...))
        or M.isNoisyTraceTag(select(2, ...))
end

function M.isNoisyVerboseTag(tag)
    return M.NOISY_VERBOSE_TAGS[tostring(tag)] == true
end

function M.isNoisyVerboseArgs(...)
    return M.isNoisyVerboseTag(select(1, ...))
        or M.isNoisyVerboseTag(select(2, ...))
end

function M.verboseEnabled(settings)
    return M.level(settings) == M.LEVEL_VERBOSE
end

function M.debugLog(settings, ...)
    local level = M.level(settings)
    if level == M.LEVEL_OFF then return end
    if level == M.LEVEL_TRACE and M.isNoisyTraceArgs(...) then return end
    if level == M.LEVEL_VERBOSE and M.isNoisyVerboseArgs(...) then return end
    print("[SitDownPlease]", ...)
end

function M.verboseLog(settings, ...)
    if M.verboseEnabled(settings) then
        print("[SitDownPlease]", ...)
    end
end

return M
