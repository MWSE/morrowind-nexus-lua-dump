-- calibration/metadata.lua
--
-- Small export-only helper kept out of interactionSeeker.lua to avoid the NPC
-- local script's active-local compile limit.

local M = {}

local function degreesBucket(degrees, size)
    size = tonumber(size or 45) or 45
    degrees = tonumber(degrees or 0) or 0
    degrees = degrees % 360
    if degrees < 0 then degrees = degrees + 360 end
    return math.floor((degrees + (size / 2)) / size) * size % 360
end

local function objectYawMetadata(obj)
    local yaw = 0
    if obj and obj.rotation then
        local ok, value = pcall(function() return obj.rotation:getYaw() end)
        if ok and value then yaw = tonumber(value) or 0 end
    end
    local degrees = math.deg(yaw)
    return yaw, degrees, degreesBucket(degrees, 45), degreesBucket(degrees, 90)
end

local function actorMetadata(actor, types)
    local rec = nil
    local okRec, value = pcall(function()
        if actor and actor.recordId and types and types.NPC and types.NPC.record then
            return types.NPC.record(actor.recordId)
        end
        return nil
    end)
    if okRec then rec = value end
    return {
        race = rec and rec.race or nil,
        sex = rec and (rec.sex or rec.gender or rec.isFemale) or nil,
        class = rec and rec.class or nil,
        scale = actor and actor.scale or nil,
    }
end

function M.print(kind, object, actor, types, numberFormatter, opts)
    opts = opts or {}
    local yaw, yawDegrees, yawBucket45, yawBucket90 = objectYawMetadata(object)
    local actorMeta = actorMetadata(actor, types)
    local fmt = numberFormatter or tostring
    print("[SitDownPlease Calibration Export]",
        "METADATA",
        "kind", tostring(kind),
        "objectYawRad", fmt(yaw),
        "objectYawDeg", fmt(yawDegrees),
        "objectYawBucket45", tostring(yawBucket45),
        "objectYawBucket90", tostring(yawBucket90),
        "actorRace", tostring(actorMeta.race),
        "actorSex", tostring(actorMeta.sex),
        "actorClass", tostring(actorMeta.class),
        "actorScale", tostring(actorMeta.scale),
        "objectScale", tostring(object and object.scale),
        "profileSource", tostring(opts.profileSource),
        "yawBucket90", tostring(opts.yawBucket90 or yawBucket90),
        "slot", tostring(opts.slot),
        "surfaceMode", tostring(opts.surfaceMode),
        "basisSource", tostring(opts.basisSource),
        "promotableFlag", tostring(opts.promotableFlag),
        "safetyFlag", tostring(opts.safetyFlag),
        "manualOverride", tostring(opts.manualOverride == true),
        "manualOverrideReason", tostring(opts.manualOverrideReason)
    )
end

return M
