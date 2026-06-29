-- interactions/lectures/seatReservations.lua
---@omw-context none
-- Runtime-only short reservation guard for lecture audience seat assignment.

local M = {}

local claims = {}

local function claimKey(candidate)
    if not candidate then return nil end
    return candidate.slotKey or (
        tostring(candidate.objectId or candidate.object and (candidate.object.id or candidate.object.recordId) or "")
        .. "::" .. tostring(candidate.slotName or "default")
    )
end

function M.prune(now)
    now = tonumber(now) or 0
    for key, claim in pairs(claims) do
        if type(claim) ~= "table" or (tonumber(claim.expiresAt) or 0) <= now then
            claims[key] = nil
        end
    end
end

function M.reservedForOther(candidate, npcId, now)
    local key = claimKey(candidate)
    if not key then return false end
    M.prune(now)
    local claim = claims[key]
    return claim ~= nil and tostring(claim.npcId or "") ~= tostring(npcId or "")
end

function M.reserve(candidate, npcId, now, ttl)
    local key = claimKey(candidate)
    if not key then return end
    claims[key] = {
        npcId = npcId,
        expiresAt = (tonumber(now) or 0) + (tonumber(ttl) or 7),
    }
end

function M.clear()
    claims = {}
end

return M
