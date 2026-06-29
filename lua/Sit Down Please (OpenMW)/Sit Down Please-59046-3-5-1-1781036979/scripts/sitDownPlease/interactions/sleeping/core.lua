-- interactions/sleeping/core.lua
---@omw-context none
-- Sleep-specific helper logic kept out of the global assignment blob.

local module = { type = "sleeping" }

function module.wakeBiasForNpc(npc, settings, profiles, types)
    local defaultBias = tonumber((profiles and profiles.SLEEP_JOB_WAKE_BIAS) or (settings and settings.sleepJobWakeBias) or 0.55) or 0.55
    if defaultBias < 0 then defaultBias = 0 end
    if defaultBias > 0.95 then defaultBias = 0.95 end
    if not (npc and npc.recordId and types and types.NPC and types.NPC.record) then return 0 end

    local okRecord, rec = pcall(types.NPC.record, npc.recordId)
    if not okRecord or not rec then return 0 end

    local cls = rec.class and string.lower(tostring(rec.class)) or ""
    if cls:find("merchant", 1, true)
        or cls:find("trader", 1, true)
        or cls:find("smith", 1, true)
        or cls:find("enchant", 1, true)
        or cls:find("publican", 1, true)
        or cls:find("pawnbroker", 1, true)
        or cls:find("healer", 1, true)
        or cls:find("apothecary", 1, true) then
        return defaultBias
    end

    local services = rec.servicesOffered
    if services and (services.Barter == true or services.Training == true or services.Travel == true or services.Spells == true) then
        return defaultBias
    end

    return 0
end

function module.isMorningWakeReason(reason)
    return reason == "scheduled_wake_time" or reason == "sleep_window_ended"
end

function module.isBunkProfile(profile)
    local text = string.lower(tostring(profile and (profile.bedType or profile.type or profile.profileId or profile.recordId) or ""))
    return text:find("bunk", 1, true) ~= nil
        or text == "top_bunk"
        or text == "bottom_bunk"
        or text == "bunk_bed"
end

local PLAYER_VISIBLE_WAKE_REASONS = {
    activated_by_player_dialogue = true,
    sleeping_disturbed_by_close_player = true,
    sleeping_disturbed_by_close_sneaking_player = true,
    sleeping_disturbed_by_invisible_close_player = true,
    sleeping_disturbed_by_player = true,
    sleeping_disturbed_by_dialogue = true,
    disturbed_by_player = true,
    disturbed_sleep = true,
    sleep_disturbed = true,
}

function module.isPlayerVisibleWakeReason(reason)
    local text = tostring(reason or "")
    if PLAYER_VISIBLE_WAKE_REASONS[text] == true then return true end
    return text:find("disturb", 1, true) ~= nil and text:find("player", 1, true) ~= nil
end

function module.shouldUseWakeExitWalk(reason, data)
    return module.isPlayerVisibleWakeReason(reason)
        and data
        and data.exitPosition ~= nil
        and not module.isBunkProfile(data.profile)
end

return module
