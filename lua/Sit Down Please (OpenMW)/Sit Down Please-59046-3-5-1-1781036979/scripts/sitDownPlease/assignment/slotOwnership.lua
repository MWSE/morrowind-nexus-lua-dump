-- assignment/slotOwnership.lua
---@omw-context none
-- Shared runtime slot ownership guard. This keeps occupiedSlots and
-- assignedActors consistent when an actor is already seated, transitioning, or
-- being considered for a slot.

local M = {}

local function actorId(actor)
    if actor == nil then return nil end
    if type(actor) == "table" then return actor.id end
    return actor
end

function M.ownerFor(slotKey, occupiedSlots, assignedActors)
    if not slotKey then return nil, nil, nil end
    local ownerId = occupiedSlots and occupiedSlots[slotKey] or nil
    if ownerId ~= nil then
        local data = assignedActors and assignedActors[ownerId] or nil
        if data and data.slotKey == slotKey then
            return ownerId, data, "occupied_slots"
        end
        if occupiedSlots then occupiedSlots[slotKey] = nil end
    end
    if assignedActors then
        for npcId, data in pairs(assignedActors) do
            if data and data.slotKey == slotKey then
                return npcId, data, "assigned_actors"
            end
        end
    end
    return nil, nil, nil
end

function M.claimedByOther(slotKey, actor, occupiedSlots, assignedActors)
    local ownerId, data, source = M.ownerFor(slotKey, occupiedSlots, assignedActors)
    if ownerId == nil then return false, nil, nil, nil end
    local id = actorId(actor)
    if id ~= nil and tostring(ownerId) == tostring(id) then
        return false, ownerId, data, source
    end
    return true, ownerId, data, source
end

function M.claim(slotKey, actor, occupiedSlots, assignedActors)
    local id = actorId(actor)
    if not (slotKey and id and occupiedSlots) then return false, "missing_slot_or_actor" end
    local claimed, ownerId, data, source = M.claimedByOther(slotKey, id, occupiedSlots, assignedActors)
    if claimed then return false, "slot_claimed_by_other", ownerId, data, source end
    occupiedSlots[slotKey] = id
    return true, nil, id, data, source
end

return M
