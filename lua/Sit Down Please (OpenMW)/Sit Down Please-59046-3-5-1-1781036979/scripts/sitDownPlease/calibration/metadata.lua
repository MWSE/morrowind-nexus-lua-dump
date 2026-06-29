-- calibration/metadata.lua
---@omw-context none
--
-- Small export-only helper kept out of interactionSeeker.lua to avoid the NPC
-- local script's active-local compile limit.

local M = {}
local scaleContext = require('scripts/sitDownPlease/world/scaleContext')

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


local function objectCellName(object, actor)
    local ok, value = pcall(function()
        local cell = object and object.cell or actor and actor.cell
        return cell and (cell.name or cell.id)
    end)
    if ok then return value end
    return nil
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
    local scaleWarning, scalePromoteHint = scaleContext.exportWarning(actorMeta.scale, object and object.scale)
    local fmt = numberFormatter or tostring
    print("[SitDownPlease Calibration Export]",
        "METADATA",
        "kind", tostring(kind),
        "cell", tostring(opts.cell or objectCellName(object, actor)),
        "objectYawRad", fmt(yaw),
        "objectYawDeg", fmt(yawDegrees),
        "objectYawBucket45", tostring(yawBucket45),
        "objectYawBucket90", tostring(yawBucket90),
        "actorRace", tostring(actorMeta.race),
        "actorLabel", tostring(opts.actorLabel or (actor and (actor.recordId or actor.id))),
        "fillRole", tostring(opts.fillRole),
        "fillSource", tostring(opts.fillSource),
        "fillIndex", tostring(opts.fillIndex),
        "runtimeObjectId", tostring(opts.runtimeObjectId),
        "actorSex", tostring(actorMeta.sex),
        "actorClass", tostring(actorMeta.class),
        "actorScale", tostring(actorMeta.scale),
        "objectScale", tostring(object and object.scale),
        "scaleContext", tostring(scaleWarning or "standard_scale"),
        "scalePromoteHint", tostring(scalePromoteHint or "ok_for_broad_profile_if_other_layers_agree"),
        "profileSource", tostring(opts.profileSource),
        "yawBucket90", tostring(opts.yawBucket90 or yawBucket90),
        "slot", tostring(opts.slot),
        "surfaceMode", tostring(opts.surfaceMode),
        "basisSource", tostring(opts.basisSource),
        "promotableFlag", tostring(opts.promotableFlag),
        "safetyFlag", tostring(opts.safetyFlag),
        "manualOverride", tostring(opts.manualOverride == true),
        "manualOverrideReason", tostring(opts.manualOverrideReason),
        "surfaceBlockerReason", tostring(opts.surfaceBlockerReason),
        "surfaceBlockerOverrideReason", tostring(opts.surfaceBlockerOverrideReason),
        "surfaceBlockerKind", tostring(opts.surfaceBlockerKind),
        "surfaceBlockerObjectId", tostring(opts.surfaceBlockerObjectId),
        "surfaceBlockerDistance", tostring(opts.surfaceBlockerDistance),
        "surfaceBlockerVertical", tostring(opts.surfaceBlockerVertical),
        "surfaceBlockerLocalReason", tostring(opts.surfaceBlockerLocalReason),
        "softBlockerReason", tostring(opts.softBlockerReason),
        "hardBlockerReason", tostring(opts.hardBlockerReason),
        "sleepSafetyReason", tostring(opts.sleepSafetyReason),
        "sleepSafetyDelta", tostring(opts.sleepSafetyDelta),
        "sleepSafetyLimit", tostring(opts.sleepSafetyLimit),
        "sleepSafetyOverrideReason", tostring(opts.sleepSafetyOverrideReason),
        "sleepCalibrationWarningReason", tostring(opts.sleepCalibrationWarningReason),
        "sleepCalibrationEvidenceReason", tostring(opts.sleepCalibrationEvidenceReason)
    )
end

return M
