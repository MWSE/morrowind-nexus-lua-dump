-- calibration/poseState.lua
---@omw-context none
-- Small runtime calibration helpers kept out of interactionSeeker.lua to avoid
-- adding local pressure to the NPC script.

local M = {}

function M.emptyOffset()
    return { x = nil, y = nil, z = nil, yaw = nil }
end

function M.targetKey(object, interactionType, slotKey, profileId)
    return table.concat({
        tostring(interactionType or ""),
        tostring(object and (object.id or object.recordId) or ""),
        tostring(object and object.recordId or ""),
        tostring(slotKey or ""),
        tostring(profileId or ""),
    }, "|")
end

function M.shouldReset(previousKey, object, interactionType, slotKey, profileId)
    local key = M.targetKey(object, interactionType, slotKey, profileId)
    if previousKey ~= key then return true, key end
    return false, key
end

function M.offsetText(offset)
    offset = offset or {}
    return tostring(tonumber(offset.x) or 0)
        .. "," .. tostring(tonumber(offset.y) or 0)
        .. "," .. tostring(tonumber(offset.z) or 0)
        .. ",yaw=" .. tostring(tonumber(offset.yaw) or 0)
end

function M.objectYaw(object)
    if not (object and object.rotation) then return nil end
    local ok, yaw = pcall(function() return object.rotation:getYaw() end)
    if ok then return yaw end
    return nil
end

function M.debugBaseline(debugLog, label, data)
    if type(debugLog) ~= "function" then return end
    data = data or {}
    local object = data.object
    local actor = data.actor
    local yaw = M.objectYaw(object)
    debugLog(
        label or "calibration baseline",
        "actor", tostring(actor and (actor.recordId or actor.id)),
        "actorId", tostring(actor and actor.id),
        "object", tostring(object and object.recordId),
        "model", tostring(data.model),
        "slot", tostring(data.slotName or data.slotKey),
        "profile", tostring(data.profileId),
        "objectPos", tostring(object and object.position),
        "objectYaw", tostring(yaw),
        "objectScale", tostring(object and object.scale),
        "actorScale", tostring(actor and actor.scale),
        "profileOffset", M.offsetText(data.profileOffset),
        "currentDelta", M.offsetText(data.currentDelta),
        "finalWorld", tostring(data.finalPosition),
        "finalYaw", tostring(data.finalRotation),
        "surface", tostring(data.surfaceMode),
        "basis", tostring(data.basisSource)
    )
end

return M
