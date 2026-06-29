-- assignment/initialPlacementGuards.lua
---@omw-context none
-- Small predicates for initial-placement handoff/retry suppression.

local M = {}

function M.hasPendingSleepHandoff(pendingInitialHandoffs, npc, candidate)
    if not (pendingInitialHandoffs and npc and npc.id and candidate) then return false end
    return candidate.initialPlacement == true
        and candidate.interactionType == "sleeping"
        and pendingInitialHandoffs[npc.id] ~= nil
end

function M.count(stats, key)
    return tonumber(stats and stats[key] or 0) or 0
end

function M.shouldSkipDelayedSleepRetry(stats)
    if not stats then return false end
    return M.count(stats, "total") > 0
        and M.count(stats, "sleepCandidateCount") <= 0
        and M.count(stats, "initialSleepSentConsider") <= 0
end

function M.shouldSkipReadyRetry(lastCandidateCount)
    return (tonumber(lastCandidateCount or 0) or 0) <= 0
end

return M
