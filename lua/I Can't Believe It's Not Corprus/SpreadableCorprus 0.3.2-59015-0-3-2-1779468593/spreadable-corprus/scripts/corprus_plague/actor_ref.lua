-- Actor identity keys must be computable from the player script (no openmw.world here).
local M = {}

local function positionTuple(position)
    return math.floor(position.x + 0.5),
        math.floor(position.y + 0.5),
        math.floor(position.z + 0.5)
end

local function matchesPosition(actor, x, y, z)
    local p = actor.startingPosition
    local ax, ay, az = positionTuple(p)
    return ax == x and ay == y and az == z
end

function M.getPlagueKey(actor)
    if not actor or not actor:isValid() then
        return nil
    end

    if actor.globalVariable and actor.globalVariable ~= '' then
        return 'g:' .. actor.globalVariable
    end

    if actor.contentFile then
        local id = actor.id
        if id and id ~= '' then
            return 'f:' .. id
        end

        local x, y, z = positionTuple(actor.startingPosition)
        return string.format('r:%s:%s:%d:%d:%d', actor.contentFile, actor.recordId, x, y, z)
    end

    local cellName = actor.cell and actor.cell.name or ''
    local x, y, z = positionTuple(actor.position)
    return string.format('d:%s:%s:%d:%d:%d', actor.recordId, cellName, x, y, z)
end

-- Global script only (uses openmw.world).
function M.findActor(plagueKey)
    if not plagueKey then
        return nil
    end

    local world = require('openmw.world')
    local prefix = plagueKey:sub(1, 2)

    if prefix == 'f:' then
        local formId = plagueKey:sub(3)
        local ok, obj = pcall(function()
            return world.getObjectByFormId(formId)
        end)
        if ok and obj and obj:isValid() then
            return obj
        end
    end

    for _, actor in ipairs(world.activeActors) do
        if M.getPlagueKey(actor) == plagueKey then
            return actor
        end
    end

    if prefix == 'g:' then
        local globalName = plagueKey:sub(3)
        for _, actor in ipairs(world.activeActors) do
            if actor.globalVariable == globalName then
                return actor
            end
        end
    elseif prefix == 'r:' then
        local contentFile, recordId, xs, ys, zs = plagueKey:match('^r:([^:]+):([^:]+):(-?%d+):(-?%d+):(-?%d+)$')
        if contentFile then
            local x, y, z = tonumber(xs), tonumber(ys), tonumber(zs)
            for _, actor in ipairs(world.activeActors) do
                if actor.contentFile == contentFile
                    and actor.recordId == recordId
                    and matchesPosition(actor, x, y, z)
                then
                    return actor
                end
            end
        end
    elseif prefix == 'd:' then
        local recordId, cellName, xs, ys, zs = plagueKey:match('^d:([^:]*):([^:]*):(-?%d+):(-?%d+):(-?%d+)$')
        if recordId then
            local x, y, z = tonumber(xs), tonumber(ys), tonumber(zs)
            for _, actor in ipairs(world.activeActors) do
                local actorCell = actor.cell and actor.cell.name or ''
                if actor.recordId == recordId
                    and actorCell == cellName
                then
                    local ax, ay, az = positionTuple(actor.position)
                    if ax == x and ay == y and az == z then
                        return actor
                    end
                end
            end
        end
    end

    return nil
end

return M
