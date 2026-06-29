-- compatibility/externalAnimations.lua
---@omw-context none
--
-- Soft compatibility detection for actors whose pose/placement is owned by
-- external animation or population mods. Broad actor detection prevents SDP
-- from taking over fixed animated actors; narrower claim detection decides
-- whether those actors should reserve nearby seats or beds.

local M = {}

local function lower(value)
    if value == nil then return "" end
    return string.lower(tostring(value))
end

function M.normalizedModelPath(value)
    return lower(value):gsub("\\", "/")
end

function M.actorModelPath(actor)
    local ok, rec = pcall(function()
        if actor and actor.type and actor.type.record then
            return actor.type.record(actor)
        end
        return nil
    end)
    if ok and rec and rec.model then return rec.model end
    return nil
end

function M.actorScriptName(actor)
    local ok, rec = pcall(function()
        if actor and actor.type and actor.type.record then
            return actor.type.record(actor)
        end
        return nil
    end)
    if ok and rec and rec.script then return rec.script end
    return nil
end

local function recordId(actor)
    return lower(actor and actor.recordId)
end

local function modelPath(actor)
    return M.normalizedModelPath(M.actorModelPath(actor))
end

local function scriptName(actor)
    return lower(M.actorScriptName(actor))
end

local function hasPrefix(value, prefixes)
    if value == "" then return false end
    for _, prefix in ipairs(prefixes or {}) do
        prefix = lower(prefix)
        if prefix ~= "" and value:sub(1, #prefix) == prefix then return true end
    end
    return false
end

local function hasToken(value, tokens)
    if value == "" then return false end
    for _, token in ipairs(tokens or {}) do
        token = M.normalizedModelPath(token)
        if token ~= "" and value:find(token, 1, true) then return true end
    end
    return false
end

M.externalAnimatedNpcExactIds = {
    ["ma_questnpc1"] = true,
    ["ps_clothestestnpc"] = true,
    ["lack_qac_pianist"] = true,
    ["lack_qac_pelim"] = true,
}

M.externalAnimatedNpcPrefixes = {
    "am_",
    "ma_questnpc",
    "_mca_reader",
    "_mca_mage_reader",
    "_mca_sit",
    "aa_reader",
    "aa_mage_reader",
    "aa_drunkard_",
    "lack_qac_zbarguy",
    "lack_qac_zzbarguy",
}

M.externalAnimatedNpcModelTokens = {
    "am/",
    "gvac/",
    "angelus_anim/",
    "harpiste",
    "mca/mca_am_",
    "qq/anim_",
    "bf/dance",
    "va_sitting.nif",
    "xva_sitting.nif",
    "anim_drunk",
    "lack/anim",
    "lack/sit ",
}

M.externalAnimatedNpcScriptTokens = {
    "_bard_script",
    "bard_script",
}

M.seatedActorPrefixes = {
    "am_sitternight",
    "am_sitter",
    "am_eater",
    "am_reader",
    "am_writer",
    "am_bard",
    "am_slavesitting",
    "_mca_reader",
    "_mca_mage_reader",
    "_mca_sitbar",
    "aa_reader",
    "aa_mage_reader",
    "aa_drunkard_",
    "lack_qac_zbarguy",
    "lack_qac_zzbarguy",
}

M.seatedModelTokens = {
    "am/am_sitting.nif",
    "am/am_reader",
    "am/am_eater.nif",
    "am/am_bard",
    "mca/mca_am_sitbar",
    "gvac/barsitter.nif",
    "gvac/sitbarstl",
    "gvac/bard_sit",
    "gvac/fsit_nb.nif",
    "gvac/gv_sitflr",
    "qq/anim_",
    "bf/dance",
    "va_sitting.nif",
    "xva_sitting.nif",
    "anim_drunk",
}

M.sleepingModelTokens = {
    "/sleep",
    "sleeping",
    "/lying",
    "lying",
    "prone",
    "knockout",
    "knockdown",
}

M.sleepingActorPrefixes = {
    "am_sleep",
    "_mca_sleep",
    "aa_sleep",
    "gvrm_sleep",
    "lack_sleep",
}

function M.externalAnimationNpcReason(actor)
    local id = recordId(actor)
    if M.externalAnimatedNpcExactIds[id] then return "external_animation_npc" end
    if hasPrefix(id, M.externalAnimatedNpcPrefixes) then return "external_animation_npc" end
    if hasToken(modelPath(actor), M.externalAnimatedNpcModelTokens) then return "external_animation_npc" end
    if hasToken(scriptName(actor), M.externalAnimatedNpcScriptTokens) then return "external_animation_npc" end
    return nil
end

function M.knownSittingActorReason(actor)
    local id = recordId(actor)
    if hasPrefix(id, M.seatedActorPrefixes) then return "external_seated_actor" end
    if hasToken(modelPath(actor), M.seatedModelTokens) then return "external_seated_actor" end
    return nil
end

function M.knownSleepingActorReason(actor)
    if hasPrefix(recordId(actor), M.sleepingActorPrefixes) then return "external_sleeping_actor" end
    if hasToken(modelPath(actor), M.sleepingModelTokens) then return "external_sleeping_actor" end
    return nil
end

function M.claimReasonForCandidate(actor, candidate)
    if not candidate then return nil end
    if candidate.interactionType == "sitting" then
        return M.knownSittingActorReason(actor)
    end
    if candidate.interactionType == "sleeping" then
        return M.knownSleepingActorReason(actor)
    end
    return nil
end

local function flatDistance(a, b)
    if not (a and b) then return nil end
    local dx = (a.x or 0) - (b.x or 0)
    local dy = (a.y or 0) - (b.y or 0)
    return math.sqrt(dx * dx + dy * dy)
end

local function seatCategory(candidate)
    local category = lower(candidate and candidate.seatCategory or candidate and candidate.category or candidate and candidate.profile and (candidate.profile.seatCategory or candidate.profile.type))
    if category == "chair" or category == "backedchair" then return "backed_chair" end
    if category == "singleseatbench" then return "single_seat_bench" end
    return category
end

local function tableTaskActor(actor)
    local id = recordId(actor)
    return id:find("^am_writer") ~= nil or id:find("^am_reader") ~= nil or id:find("^am_eater") ~= nil
end

local function tableTaskSeat(candidate, category)
    category = category or seatCategory(candidate)
    if category ~= "backed_chair" and category ~= "single_seat_bench" then return false end
    local kind = lower(candidate and candidate.facingKind)
    return kind == "table" or kind == "bar" or (candidate and candidate.facingObjectPosition ~= nil)
end

local function slotClaimRadius(actor, candidate)
    local category = seatCategory(candidate)
    if tableTaskActor(actor) and tableTaskSeat(candidate, category) then return 156, 220, 175, "table_task_chair" end
    if category == "bench" then return 64, 82 end
    if category == "barstool" or category == "stool" then return 52, 76 end
    if category == "backed_chair" or category == "single_seat_bench" then return 58, 78 end
    if candidate and candidate.interactionType == "sleeping" then return 96, 130 end
    return 64, 86
end

function M.claimMatchForCandidate(actor, candidate)
    local reason = M.claimReasonForCandidate(actor, candidate)
    if not reason then return nil end
    if not (actor and actor.position and candidate) then return nil end

    local slotPos = candidate.position or candidate.finalPos or candidate.sitPosition or candidate.approachPos
    local objectPos = candidate.object and candidate.object.position or nil
    local primaryRadius, objectRadius, verticalTolerance, sourceHint = slotClaimRadius(actor, candidate)
    verticalTolerance = verticalTolerance or 96

    if slotPos then
        local dist = flatDistance(actor.position, slotPos)
        local vertical = math.abs((actor.position.z or 0) - (slotPos.z or 0))
        if dist and dist <= primaryRadius and vertical <= verticalTolerance then
            return reason, sourceHint and (sourceHint .. "_slot_geometry") or "slot_geometry", dist, vertical
        end
    end

    if objectPos then
        local dist = flatDistance(actor.position, objectPos)
        local vertical = math.abs((actor.position.z or 0) - (objectPos.z or 0))
        if dist and dist <= objectRadius and vertical <= verticalTolerance then
            return reason, sourceHint and (sourceHint .. "_object_fallback") or "object_fallback", dist, vertical
        end
    end

    return nil
end

return M
