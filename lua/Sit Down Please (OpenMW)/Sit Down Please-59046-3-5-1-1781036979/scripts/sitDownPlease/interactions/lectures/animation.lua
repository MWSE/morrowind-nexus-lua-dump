-- interactions/lectures/animation.lua
---@omw-context none
-- Lecture-specific animation timing and group selection.

local M = {}

M.bookModel = "Meshes/SDP/sermon/xsdp_preach_book.nif"
M.bookBone = "Shield Bone"
M.bookBones = { "Shield Bone", "Shield", "Bip01 L Hand", "Left Hand", "Left Wrist" }
M.bookVfxId = "sdp_lecture_book"
M.presenterSpeechSound = "Sound\\SDP\\SDP_PreachMurmur.wav"
M.presenterSpeechSoundEnabled = false
M.presenterLightBeatsEnabled = true
M.presenterExpressiveBeatsEnabled = true
M.presenterDirectionalBeatsEnabled = false
M.audienceReactionBeatsEnabled = true
M.audienceCustomAnimationsEnabled = true
M.audienceUnsafeAssetReason = nil

local PRESENTER_BASE = {
    book = "sdppreachbookidle",
    address = "sdppreachaddressidle",
}

local PRESENTER_LIGHT = {
    book = {
        center = "sdppreachbooktalk",
        left = "sdppreachbooktalkleft",
        right = "sdppreachbooktalkright",
    },
    address = {
        center = "sdppreachaddressspeak",
        left = "sdppreachaddressspeakleft",
        right = "sdppreachaddressspeakright",
    },
}

local PRESENTER_EXPRESSIVE_SAFE = {
    book = { "sdppreachattentive", "sdppreachadmonish", "sdppreachformal01", "sdppreachbeckon", "sdppreachhold", "sdppreachscan", "sdppreachcommand01", "sdppreachcommand02", "sdppreachcommand03", "sdppreachcommand04" },
    address = { "sdppreachattentive", "sdppreachadmonish", "sdppreachformal02", "sdppreachbeckon", "sdppreachhold", "sdppreachscan", "sdppreachcommand01", "sdppreachcommand02", "sdppreachcommand03", "sdppreachcommand04" },
}

local AUDIENCE_NEUTRAL = {
    "sdparmsonkneessitidle1",
}

-- Keep the 3.5 release pool deliberately conservative: these groups were
-- visually verified as seated-safe more consistently than the search/scratch
-- and attention-shift candidates. Unsafe groups should stay out of runtime
-- until their KFs are repaired in the animation workbench.
local AUDIENCE_REACTION_POOL = {
    { kind = "seated_nod", group = "sdpaudiencesitnod", weight = 58, restoreBaseAfter = 2.0, holdUntilRestore = true },
    { kind = "seated_clap", group = "sdpaudiencesitspectator4", weight = 14, restoreBaseAfter = 2.6, holdUntilRestore = true },
    { kind = "seated_listening", group = "sdparmsonkneessitidle1", weight = 28, baseRefresh = true },
}
local DISABLED_AUDIENCE_REACTION_GROUPS = {
    sdpaudiencesitidle3 = "deferred_post_3_5_seated_safety",
    sdpaudiencesitsearch2 = "deferred_post_3_5_seated_safety",
    sdpaudiencesitsearch3 = "deferred_post_3_5_seated_safety",
}

local function hash(value)
    value = tostring(value or "")
    local out = 0
    for i = 1, #value do
        out = (out * 33 + string.byte(value, i)) % 2147483647
    end
    return out
end

local function unit(seed, salt)
    return (hash(tostring(seed or "") .. "::" .. tostring(salt or "")) % 10000) / 10000
end

local function interval(seed, salt, minSeconds, maxSeconds)
    minSeconds = tonumber(minSeconds) or 0
    maxSeconds = tonumber(maxSeconds) or minSeconds
    if maxSeconds < minSeconds then maxSeconds = minSeconds end
    return minSeconds + ((maxSeconds - minSeconds) * unit(seed, salt))
end

local function pick(list, seed, salt)
    if not list or #list == 0 then return nil end
    return list[(hash(tostring(seed) .. "::" .. tostring(salt)) % #list) + 1]
end

local function weightedPick(list, seed, salt)
    local total = 0
    for _, item in ipairs(list or {}) do
        total = total + (tonumber(item.weight) or 0)
    end
    if total <= 0 then return nil end
    local roll = unit(seed, salt) * total
    local seen = 0
    for _, item in ipairs(list) do
        seen = seen + (tonumber(item.weight) or 0)
        if roll <= seen then return item end
    end
    return list[#list]
end

local function candidateReactions(state, now, allowRepeat)
    local out = {}
    for _, item in ipairs(AUDIENCE_REACTION_POOL) do
        local rareAllowed = item.rare ~= true or now >= (tonumber(state.nextRareAt) or 0)
        local repeatAllowed = allowRepeat == true or item.group ~= state.lastReactionGroup
        if rareAllowed and repeatAllowed then out[#out + 1] = item end
    end
    return out
end

local function actorKey(actorOrId)
    if type(actorOrId) == "table" then
        return tostring(actorOrId.id or actorOrId.recordId or "actor")
    end
    return tostring(actorOrId or "actor")
end

local function positionKey(pos)
    if not pos then return "no_pos" end
    return tostring(math.floor((pos.x or 0) + 0.5))
        .. "," .. tostring(math.floor((pos.y or 0) + 0.5))
        .. "," .. tostring(math.floor((pos.z or 0) + 0.5))
end

function M.sessionId(data)
    return table.concat({
        tostring(data and data.objectId or "station"),
        tostring(data and data.slotName or data and data.slotKey or "slot"),
        positionKey(data and (data.position or data.object and data.object.position)),
        tostring(math.floor(tonumber(data and data.claimedAt or 0) or 0)),
    }, "::")
end

local function styleFor(data)
    local profileText = string.lower(table.concat({
        tostring(data and data.profileId or ""),
        tostring(data and data.objectId or ""),
        tostring(data and data.slotName or ""),
    }, " "))
    if profileText:find("address", 1, true) then return "address" end
    if profileText:find("book", 1, true) then return "book" end
    local seed = tostring(data and data.lectureSessionId or data and data.slotKey or data and data.objectId or "lecture")
        .. "::" .. actorKey(data and data.npc)
    if (hash(seed) % 100) >= 58 then return "address" end
    return "book"
end

function M.initialPresenterState(payload, actorId, now)
    local seed = tostring(actorId or "presenter") .. "::" .. tostring(payload and payload.sessionId or "lecture")
    local style = payload and payload.presenterStyle or "book"
    return {
        role = "presenter",
        active = true,
        seed = seed,
        sessionId = payload and payload.sessionId,
        style = style,
        audienceSummary = payload and payload.audienceSummary or nil,
        startedAt = now or 0,
        nextLightAt = (now or 0) + interval(seed, "first_light", 0.8, 1.8),
        nextExpressiveAt = (now or 0) + interval(seed, "first_expressive", 7, 16),
        lastExpressiveGroup = nil,
        currentGroup = nil,
        returnToBaseAt = nil,
        missingLogged = {},
    }
end

function M.refreshPresenterState(state, payload, now)
    if not state then return M.initialPresenterState(payload, nil, now) end
    state.active = true
    state.sessionId = payload and payload.sessionId or state.sessionId
    state.style = payload and payload.presenterStyle or state.style or "book"
    state.audienceSummary = payload and payload.audienceSummary or state.audienceSummary
    state.nextLightAt = state.nextLightAt or ((now or 0) + interval(state.seed, "refresh_light", 1.5, 4.0))
    state.nextExpressiveAt = state.nextExpressiveAt or ((now or 0) + interval(state.seed, "refresh_expressive", 20, 38))
    return state
end

local function preferredSector(summary, seed, salt)
    summary = summary or {}
    local left = tonumber(summary.left or 0) or 0
    local center = tonumber(summary.center or 0) or 0
    local right = tonumber(summary.right or 0) or 0
    if left <= 0 and center <= 0 and right <= 0 then
        local roll = unit(seed, salt)
        if roll < 0.33 then return "left" end
        if roll > 0.66 then return "right" end
        return "center"
    end
    if left > center and left >= right then return "left" end
    if right > center and right > left then return "right" end
    return "center"
end

function M.presenterBaseGroup(state)
    local style = state and state.style or "book"
    return PRESENTER_BASE[style] or PRESENTER_BASE.book
end

function M.selectPresenterBeat(state, now)
    if not (state and state.active) then return nil end
    now = tonumber(now) or 0
    if not state.currentGroup then
        return {
            kind = "base",
            group = M.presenterBaseGroup(state),
            loops = 999,
            forceLoop = true,
            autoDisable = false,
            attachBook = true,
        }
    end
    if state.returnToBaseAt and now >= state.returnToBaseAt then
        state.returnToBaseAt = nil
        return {
            kind = "base",
            group = M.presenterBaseGroup(state),
            loops = 999,
            forceLoop = true,
            autoDisable = false,
            attachBook = true,
        }
    end
    if M.presenterExpressiveBeatsEnabled == true and now >= (state.nextExpressiveAt or math.huge) then
        local groups = PRESENTER_EXPRESSIVE_SAFE[state.style or "book"] or PRESENTER_EXPRESSIVE_SAFE.book
        local group = pick(groups, state.seed, "expressive_group_" .. tostring(math.floor(now)))
        if group == state.lastExpressiveGroup then
            group = pick(groups, state.seed, "expressive_alt_" .. tostring(math.floor(now) + 7))
        end
        state.lastExpressiveGroup = group
        state.nextExpressiveAt = now + interval(state.seed, "expressive_" .. tostring(math.floor(now)), 35, 70)
        state.nextLightAt = math.max(state.nextLightAt or 0, now + interval(state.seed, "post_expressive_light_" .. tostring(math.floor(now)), 6, 12))
        state.returnToBaseAt = now + 4.5
        return {
            kind = "expressive",
            group = group,
            loops = 0,
            forceLoop = false,
            autoDisable = true,
            attachBook = true,
        }
    end
    if M.presenterLightBeatsEnabled == true and now >= (state.nextLightAt or math.huge) then
        local sector = M.presenterDirectionalBeatsEnabled == true
            and preferredSector(state.audienceSummary, state.seed, "light_sector_" .. tostring(now))
            or "center"
        local groups = PRESENTER_LIGHT[state.style or "book"] or PRESENTER_LIGHT.book
        state.nextLightAt = now + interval(state.seed, "light_" .. tostring(math.floor(now)), 6, 12)
        state.returnToBaseAt = now + 3.25
        return {
            kind = "light",
            group = groups[sector] or groups.center,
            loops = 0,
            forceLoop = false,
            autoDisable = true,
            attachBook = true,
        }
    end
    return nil
end

function M.initialAudienceState(payload, actorId, now)
    local sessionId = payload and payload.lectureSessionId or payload and payload.sessionId or payload and payload.slotKey or "lecture"
    local seed = tostring(actorId or "audience") .. "::" .. tostring(sessionId)
    return {
        role = "audience",
        active = true,
        seed = seed,
        sessionId = sessionId,
        baseGroup = pick(AUDIENCE_NEUTRAL, seed, "base_group"),
        headFocusPosition = payload and payload.audienceHeadFocusPosition,
        startedAt = now or 0,
        nextReactionAt = (now or 0) + interval(seed, "first_reaction", 4, 12),
        nextRareAt = (now or 0) + interval(seed, "first_rare_reaction", 85, 180),
        reactionSequence = 0,
        lastReactionGroup = nil,
        missingLogged = {},
    }
end

function M.audienceBaseGroup(state)
    return state and state.baseGroup or AUDIENCE_NEUTRAL[1]
end

function M.audienceAnimationsEnabled()
    return M.audienceCustomAnimationsEnabled == true
end

function M.rejectedAudienceAssets()
    local out = {}
    for group, reason in pairs(DISABLED_AUDIENCE_REACTION_GROUPS) do
        out[#out + 1] = group .. ":" .. reason
    end
    table.sort(out)
    return out
end

function M.selectAudienceBeat(state, now)
    if not (state and state.active) then return nil end
    now = tonumber(now) or 0
    if M.audienceCustomAnimationsEnabled ~= true then
        if now >= (state.nextReactionAt or math.huge) then
            state.nextReactionAt = now + interval(state.seed, "next_disabled_asset_reaction_" .. tostring(math.floor(now)), 24, 62)
            return nil, { reason = "audience_assets_disabled", assetReason = M.audienceUnsafeAssetReason }
        end
        return nil
    end
    if state.returnToBaseAt and now >= state.returnToBaseAt then
        state.returnToBaseAt = nil
        return {
            kind = "base_restore",
            group = M.audienceBaseGroup(state),
            loops = 999,
            forceLoop = true,
            autoDisable = false,
        }
    end
    if M.audienceReactionBeatsEnabled ~= true then
        if now >= (state.nextReactionAt or math.huge) then
            state.nextReactionAt = now + interval(state.seed, "next_disabled_reaction_" .. tostring(math.floor(now)), 24, 62)
            return nil, { reason = "reaction_beats_disabled" }
        end
        return nil
    end
    if now < (state.nextReactionAt or math.huge) then return nil end

    state.reactionSequence = (tonumber(state.reactionSequence) or 0) + 1
    local salt = "reaction_" .. tostring(state.reactionSequence) .. "_" .. tostring(math.floor(now))
    local previousGroup = state.lastReactionGroup
    local rareCooldownActive = now < (tonumber(state.nextRareAt) or 0)
    local candidates = candidateReactions(state, now, false)
    local repeatAvoided = previousGroup ~= nil
    if #candidates == 0 then
        state.nextReactionAt = now + interval(state.seed, "next_suppressed_reaction_" .. tostring(state.reactionSequence), 20, 46)
        return nil, { reason = "reaction_cooldown", lastGroup = previousGroup }
    end

    local item = weightedPick(candidates, state.seed, salt)
    if not item then
        state.nextReactionAt = now + interval(state.seed, "next_empty_reaction_" .. tostring(state.reactionSequence), 20, 46)
        return nil, { reason = "reaction_pool_empty" }
    end

    if item.rare == true then
        state.nextRareAt = now + interval(state.seed, "next_rare_reaction_" .. tostring(state.reactionSequence), 135, 260)
    end
    state.nextReactionAt = now + interval(state.seed, "next_reaction_" .. tostring(state.reactionSequence), 16, 38)
    state.lastReactionGroup = item.group
    local heldReaction = item.holdUntilRestore == true and item.baseRefresh ~= true
    return {
        kind = item.kind,
        group = item.group,
        loops = (item.baseRefresh == true or heldReaction == true) and 999 or 0,
        forceLoop = item.baseRefresh == true or heldReaction == true,
        autoDisable = item.baseRefresh ~= true and heldReaction ~= true,
        baseRefresh = item.baseRefresh == true,
        holdUntilRestore = heldReaction == true,
        restoreBaseAfter = item.restoreBaseAfter or 2.0,
        suppressedRepeat = repeatAvoided == true,
    }, (repeatAvoided or rareCooldownActive) and {
        reason = repeatAvoided and "repeat_avoided" or "rare_reaction_cooldown",
        lastGroup = previousGroup,
    } or nil
end

function M.scheduleAudienceBaseRestore(state, now, delay)
    if not (state and state.active) then return end
    state.returnToBaseAt = (tonumber(now) or 0) + (tonumber(delay) or 2.4)
end

function M.presenterPayload(data, reason)
    if not data then return nil end
    data.lectureSessionId = data.lectureSessionId or M.sessionId(data)
    return {
        sessionId = data.lectureSessionId,
        slotKey = data.slotKey,
        slotName = data.slotName,
        objectId = data.objectId,
        stationType = data.stationType,
        presenterStyle = styleFor(data),
        releaseAt = data.releaseAt,
        finalRotation = data.finalRotation,
        audienceSummary = data.audienceSummary,
        reason = reason or "lecture_animation",
    }
end

function M.audienceSector(stationData, npc)
    local facing = stationData and stationData.facingDirection
    local origin = stationData and (stationData.position or stationData.object and stationData.object.position)
    local pos = npc and npc.position
    if not (facing and origin and pos) then return "center" end
    local dx = (pos.x or 0) - (origin.x or 0)
    local dy = (pos.y or 0) - (origin.y or 0)
    local len = math.sqrt(dx * dx + dy * dy)
    if len <= 1 then return "center" end
    dx, dy = dx / len, dy / len
    local cross = (facing.x or 0) * dy - (facing.y or 0) * dx
    if cross > 0.28 then return "left" end
    if cross < -0.28 then return "right" end
    return "center"
end

function M.rebuildAudienceSummary(data)
    local summary = { left = 0, center = 0, right = 0, total = 0 }
    for _, item in pairs(data and data.audience or {}) do
        local sector = item and item.sector or "center"
        if sector ~= "left" and sector ~= "right" then sector = "center" end
        summary[sector] = (summary[sector] or 0) + 1
        summary.total = summary.total + 1
    end
    if data then data.audienceSummary = summary end
    return summary
end

return M
