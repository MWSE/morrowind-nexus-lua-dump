-- assignment/publicInterface.lua
---@omw-context none

local M = {}

local function actorId(actorOrId)
    if actorOrId == nil then return nil end
    if type(actorOrId) == "string" then return actorOrId end
    if type(actorOrId) == "number" then return tostring(actorOrId) end
    return actorOrId.id
end

local function yawOf(rotationOrYaw)
    if type(rotationOrYaw) == "number" then return rotationOrYaw end
    if rotationOrYaw and rotationOrYaw.getYaw then
        local ok, yaw = pcall(function() return rotationOrYaw:getYaw() end)
        if ok then return yaw end
    end
    return nil
end

local function interactingLike(state)
    return state == "interacting" or state == "transitioning"
end

local function staticForConversation(data)
    if not data then return false end
    if data.interactionType == "sitting" then return interactingLike(data.state) end
    if data.interactionType == "station" then return interactingLike(data.state) end
    return false
end

function M.actorInteractionState(assignedActors, actorOrId)
    local id = actorId(actorOrId)
    if not id then return nil end
    local data = assignedActors and assignedActors[id] or nil
    if not data then return nil end
    local npc = data.npc
    local finalRotationYaw = yawOf(data.finalRotation)
    local actorRotationYaw = yawOf(npc and npc.rotation)
    return {
        managed = true,
        actorId = id,
        actorRecordId = npc and npc.recordId or nil,
        interactionType = data.interactionType,
        state = data.state,
        objectId = data.objectId,
        slotName = data.slotName,
        profileId = data.profileId,
        finalPosition = data.finalPosition or data.position,
        finalRotationYaw = finalRotationYaw,
        seatRotationYaw = finalRotationYaw,
        actorPosition = npc and npc.position or nil,
        actorRotationYaw = actorRotationYaw,
        facingDirection = data.facingDirection,
        facingKind = data.facingKind,
        facingReason = data.facingReason,
        facingObjectId = data.facingObjectId,
        facingObjectScale = data.facingObjectScale,
        staticForConversation = staticForConversation(data),
        avoidMovement = true,
        allowUpperBodyConversation = staticForConversation(data) and data.interactionType == "sitting",
        calibrationAction = data.calibrationAction == true,
    }
end

function M.isActorManaged(assignedActors, actorOrId)
    return M.actorInteractionState(assignedActors, actorOrId) ~= nil
end

return M
