-- Compact actor identity helpers for lecture save/load recovery.
---@omw-context none

local M = {}

local function lower(value)
    return tostring(value or ""):lower()
end

function M.positionSnapshot(pos)
    if not pos then return nil end
    return {
        x = tonumber(pos.x) or 0,
        y = tonumber(pos.y) or 0,
        z = tonumber(pos.z) or 0,
    }
end

function M.copyPosition(pos)
    if not (type(pos) == "table" and pos.x ~= nil and pos.y ~= nil and pos.z ~= nil) then return nil end
    return M.positionSnapshot(pos)
end

local function distance(a, b)
    if not (a and b) then return math.huge end
    local dx = (a.x or 0) - (b.x or 0)
    local dy = (a.y or 0) - (b.y or 0)
    local dz = (a.z or 0) - (b.z or 0)
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local function valid(env, actor)
    if env and env.isValid then return env.isValid(actor) == true end
    return actor ~= nil
end

local function recordMatches(record, actor)
    return record
        and actor
        and record.actorRecordId ~= nil
        and actor.recordId ~= nil
        and lower(actor.recordId) == lower(record.actorRecordId)
end

function M.findActor(candidates, record, env)
    if not (candidates and record) then return nil, "missing_candidates" end
    if record.actorId then
        for _, actor in ipairs(candidates) do
            if valid(env, actor) and actor.id ~= nil and tostring(actor.id) == tostring(record.actorId) then
                return actor, nil
            end
        end
    end

    local matches = {}
    for _, actor in ipairs(candidates) do
        if valid(env, actor) and recordMatches(record, actor) then
            matches[#matches + 1] = actor
        end
    end
    if #matches == 0 then return nil, "actor_not_loaded" end
    if #matches == 1 then return matches[1], nil end

    local anchor = record.actorPosition
    local tolerance = tonumber(env and env.positionTolerance) or 160
    if anchor then
        local best, bestDist
        for _, actor in ipairs(matches) do
            local dist = distance(actor.position, anchor)
            if not bestDist or dist < bestDist then
                best = actor
                bestDist = dist
            end
        end
        if best and bestDist and bestDist <= tolerance then return best, nil end
    end

    return nil, "ambiguous_actor_record"
end

return M
