-- FurnitureProfiles.lua
-- Compatibility facade for legacy furniture offset helpers plus SDP-style
-- furniture profile resolution.

local FurnitureProfiles = {}

local Catalog = require("scripts.ProceduralChatter.data.FurnitureProfileCatalog")
local Blacklist = require("scripts.ProceduralChatter.Blacklist")
local types = require("openmw.types")

local function normalize(recordId)
    return recordId and string.lower(tostring(recordId)) or ""
end

local function getLegacyProfile(recordId, interactionType)
    if not recordId then return nil end
    return Catalog.getProfileForRecord(normalize(recordId), interactionType)
end

--- Return override slot definitions for a bed record, or nil if none.
-- Each slot is { x=number, y=number, z=number } offset from bed.position.
function FurnitureProfiles.getBedOverrides(recordId)
    local profile = getLegacyProfile(recordId, "sleep")
    if not profile or not profile.slots or #profile.slots == 0 then return nil end
    local slots = {}
    for _, slot in ipairs(profile.slots) do
        local off = slot.localOffset or {}
        slots[#slots + 1] = {
            x = off.x or 0,
            y = off.y or 0,
            z = off.z or 0,
        }
    end
    return slots
end

--- Return the per-record Z offset for a bed, or nil to use the default.
function FurnitureProfiles.getBedZOffset(recordId)
    local profile = getLegacyProfile(recordId, "sleep")
    if not profile or not profile.slots or not profile.slots[1] then return nil end
    return (profile.slots[1].localOffset or {}).z
end

--- Return { zOffset, forwardOffset } for a chair record, or nil if none.
function FurnitureProfiles.getChairOffsets(recordId)
    local profile = getLegacyProfile(recordId, "sit")
    if not profile then return nil end
    return {
        zOffset = profile.finalZOffset,
        forwardOffset = profile.finalForwardOffset,
    }
end

--- Return { x=number, y=number, z=number } seat offset from object origin.
function FurnitureProfiles.getChairSeatOffset(recordId)
    local profile = getLegacyProfile(recordId, "sit")
    if not profile then return nil end
    local off = profile.source == "sdp"
        and { x = profile.width, y = profile.depth, z = profile.height }
        or ((profile.slots and profile.slots[1] and profile.slots[1].localOffset) or {})
    return {
        x = off.x or 0,
        y = off.y or 0,
        z = off.z or 0,
    }
end

function FurnitureProfiles.getProfileForObject(obj, interactionType)
    return Catalog.getProfileForObject(obj, interactionType)
end

function FurnitureProfiles.getSlots(obj, interactionType)
    return Catalog.getSlots(obj, interactionType)
end

function FurnitureProfiles.getVariantForObject(profile, obj)
    return Catalog.getVariantForObject(profile, obj)
end

function FurnitureProfiles.getAnimationOffset(profile, animationId, poseContext, obj, slot)
    return Catalog.getAnimationOffset(profile, animationId, poseContext, obj, slot)
end

function FurnitureProfiles.isTableObject(obj)
    return Catalog.isTableObject(obj)
end

function FurnitureProfiles.isFurnitureObjectBlacklisted(obj)
    if not obj then return true end
    local rid, model = "", ""
    pcall(function() rid = obj.recordId or "" end)
    pcall(function()
        local rec = obj.type and obj.type.record and obj.type.record(obj)
        model = rec and rec.model or model
    end)
    if model == "" then
        pcall(function()
            if types.Static.objectIsInstance(obj) then
                local rec = types.Static.record(obj)
                model = rec and rec.model or model
            end
        end)
    end
    if model == "" then
        pcall(function()
            if types.Activator.objectIsInstance(obj) then
                local rec = types.Activator.record(obj)
                model = rec and rec.model or model
            end
        end)
    end
    return Blacklist.isObjectBlacklisted(rid, model)
end

function FurnitureProfiles.getDiagnostics()
    return Catalog.getDiagnostics()
end

return FurnitureProfiles
