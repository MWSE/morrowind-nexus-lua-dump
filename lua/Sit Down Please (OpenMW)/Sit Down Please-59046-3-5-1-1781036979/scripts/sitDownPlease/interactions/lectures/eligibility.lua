-- interactions/lectures/eligibility.lua
---@omw-context none
-- Lecture-specific actor eligibility relaxations.

local M = {}

function M.softAudienceRoleAllowed(reason, rec, servicePolicy)
    local text = tostring(reason or "")
    if text == "barter_service_npc"
        or text == "training_service_npc"
        or text == "travel_service_npc"
        or text == "travel_destination_npc"
        or text == "faction_leader" then
        return true
    end
    if text == "guard_or_publican_class" then
        return servicePolicy and servicePolicy.isPublican and servicePolicy.isPublican(rec) == true
    end
    return false
end

function M.eligibleAudienceMember(npc, ctx)
    ctx = ctx or {}
    local baseEligible = ctx.isNpcEligibleForInteraction
    if not baseEligible then return true, nil end
    local ok, reason = baseEligible(npc, "sitting")
    if ok then return true, nil end

    local rec = ctx.servicePolicy and ctx.servicePolicy.record and ctx.servicePolicy.record(npc, ctx.types) or nil
    if not M.softAudienceRoleAllowed(reason, rec, ctx.servicePolicy) then
        return false, reason
    end
    return true, "lecture_audience_soft_role"
end

return M
