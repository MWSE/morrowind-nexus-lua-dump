-- FurnitureProfileCatalog.lua
-- Resolves SDP-style furniture profiles for concrete OpenMW objects.

local util = require("openmw.util")
local types = require("openmw.types")

local Loader = require("scripts.ProceduralChatter.data.FurnitureProfileLoader")
local Blacklist = require("scripts.ProceduralChatter.Blacklist")

local Catalog = {}

local loaded = false
local diagnostics = {
    chairProfilesLoaded = 0,
    bedProfilesLoaded = 0,
    chairVariantsLoaded = 0,
    bedVariantsLoaded = 0,
    animationOffsetsLoaded = 0,
    legacyRowsLoaded = 0,
    chairProfileDataRows = 0,
    bedProfileDataRows = 0,
    chairVariantDataRows = 0,
    bedVariantDataRows = 0,
    duplicateRowsDetected = 0,
    tableObjectsLoaded = 0,
}

local profilesByRecord = { sit = {}, sleep = {} }
local profilesByModel = { sit = {}, sleep = {} }
local variants = { sit = {}, sleep = {} }
local animationOffsets = {}
local tableRecords = {}
local tableModels = {}

local function normalize(s)
    return s and string.lower(tostring(s)) or ""
end

local function basename(path)
    path = normalize(path)
    return path:match("([^/\\]+)$") or path
end

local function normalizeInteractionType(s)
    s = normalize(s)
    if s == "sitting" then return "sit" end
    if s == "sleeping" then return "sleep" end
    return s
end

local function copyOffset(off)
    if not off then return nil end
    return { x = off.x or 0, y = off.y or 0, z = off.z or 0 }
end

local function cloneSlot(slot)
    return {
        slotId = slot.slotId,
        interactionType = slot.interactionType,
        profileId = slot.profileId,
        localOffset = copyOffset(slot.localOffset),
        localFacingYaw = slot.localFacingYaw,
        approachOffset = copyOffset(slot.approachOffset),
        exitOffset = copyOffset(slot.exitOffset),
        usesSharedSeatAnchor = slot.usesSharedSeatAnchor,
        flags = slot.flags or {},
    }
end

local function cloneProfile(profile)
    local copy = {}
    for k, v in pairs(profile) do
        if k ~= "slots" and k ~= "flags" and k ~= "approachOffsets" then
            copy[k] = v
        end
    end
    copy.flags = profile.flags or {}
    copy.approachOffsets = profile.approachOffsets or {}
    copy.slots = {}
    for _, slot in ipairs(profile.slots or {}) do
        copy.slots[#copy.slots + 1] = cloneSlot(slot)
    end
    return copy
end

local function mergeLegacyProfile(existing, profile)
    if not existing then return profile end
    for _, slot in ipairs(profile.slots or {}) do
        existing.slots[#existing.slots + 1] = slot
    end
    return existing
end

local function addProfile(profile)
    local kind = profile.interactionType
    if kind ~= "sit" and kind ~= "sleep" then return end

    local rid = normalize(profile.recordId)
    local model = normalize(profile.model)

    if profile.source == "legacy" and rid ~= "" and profilesByRecord[kind][rid]
            and profilesByRecord[kind][rid].source == "legacy" then
        mergeLegacyProfile(profilesByRecord[kind][rid], profile)
        return
    end

    if rid ~= "" then
        if profilesByRecord[kind][rid] then
            diagnostics.duplicateRowsDetected = diagnostics.duplicateRowsDetected + 1
        end
        profilesByRecord[kind][rid] = profile
    end
    if model ~= "" then
        profilesByModel[kind][model] = profile
    end
end

local function getObjectRecordId(obj)
    local rid = ""
    pcall(function() rid = obj.recordId or "" end)
    return normalize(rid)
end

local function getObjectModel(obj)
    local model = ""
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
    return normalize(model)
end

local function yawDeg(obj)
    local yaw = 0
    pcall(function() yaw = obj.rotation:getYaw() end)
    local deg = yaw * 180 / math.pi
    while deg < 0 do deg = deg + 360 end
    while deg >= 360 do deg = deg - 360 end
    return deg
end

local function yawBucket90(deg)
    return math.floor((deg + 45) / 90) * 90 % 360
end

local function objectPositionMatches(variant, obj)
    if not variant.objectX then return true end
    local p = obj.position
    if not p then return false end
    local dx = math.abs((p.x or 0) - variant.objectX)
    local dy = math.abs((p.y or 0) - variant.objectY)
    local dz = math.abs((p.z or 0) - variant.objectZ)
    return dx <= 2 and dy <= 2 and dz <= 2
end

local function yawMatches(variant, deg)
    if variant.yawMinDeg and variant.yawMaxDeg then
        return deg >= variant.yawMinDeg and deg <= variant.yawMaxDeg
    end
    if variant.yawBucket90 then
        return yawBucket90(deg) == variant.yawBucket90
    end
    return true
end

local function variantMatches(variant, profile, obj, slot)
    local rid = getObjectRecordId(obj)
    local model = getObjectModel(obj)
    if variant.recordId ~= "" and variant.recordId ~= rid then return false end
    if variant.model ~= "" and model ~= "" and variant.model ~= model then return false end
    if variant.profileId ~= "" and variant.profileId ~= profile.profileId then return false end
    if variant.slotId ~= "" and slot and variant.slotId ~= slot.slotId then return false end
    if not objectPositionMatches(variant, obj) then return false end
    return yawMatches(variant, yawDeg(obj))
end

local function applyVariant(slot, variant)
    if not variant then return slot end
    local s = cloneSlot(slot)
    if variant.sleepRootLocalOffset then
        s.localOffset = copyOffset(variant.sleepRootLocalOffset)
        s.usesSharedSeatAnchor = false
    elseif variant.finalRightOffset or variant.finalForwardOffset or variant.finalZOffset then
        s.localOffset = {
            x = variant.finalRightOffset or s.localOffset.x,
            y = variant.finalForwardOffset or s.localOffset.y,
            z = variant.finalZOffset or s.localOffset.z,
        }
        s.usesSharedSeatAnchor = false
    end
    if variant.yawOffset then s.localFacingYaw = variant.yawOffset end
    return s
end

local function loadAll()
    if loaded then return end
    loaded = true

    local chairs, chairDiag = Loader.loadChairProfiles("data/furniture_profiles/sdp/chairProfiles.txt")
    diagnostics.chairProfileDataRows = #chairs
    diagnostics.chairProfilesLoaded = #chairs
    for _, profile in ipairs(chairs) do addProfile(profile) end

    local beds, bedDiag = Loader.loadBedProfiles("data/furniture_profiles/sdp/bedProfiles.txt")
    diagnostics.bedProfileDataRows = #beds
    diagnostics.bedProfilesLoaded = #beds
    for _, profile in ipairs(beds) do addProfile(profile) end

    local localChairs = Loader.loadLegacyProfiles("data/furniture_profiles/chair_profiles.txt", "sit")
    local localBeds = Loader.loadLegacyProfiles("data/furniture_profiles/bed_profiles.txt", "sleep")
    diagnostics.legacyRowsLoaded = #localChairs + #localBeds
    for _, profile in ipairs(localChairs) do addProfile(profile) end
    for _, profile in ipairs(localBeds) do addProfile(profile) end

    local chairVariants, chairVariantDiag = Loader.loadChairVariants("data/furniture_profiles/sdp/chairProfileVariants.txt")
    variants.sit = chairVariants
    diagnostics.chairVariantDataRows = #chairVariants
    diagnostics.chairVariantsLoaded = #chairVariants

    local bedVariants, bedVariantDiag = Loader.loadBedVariants("data/furniture_profiles/sdp/bedProfileVariants.txt")
    variants.sleep = bedVariants
    diagnostics.bedVariantDataRows = #bedVariants
    diagnostics.bedVariantsLoaded = #bedVariants

    animationOffsets = Loader.loadAnimationOffsets("data/furniture_profiles/sdp/animationNormalizationOffsets.txt")
    diagnostics.animationOffsetsLoaded = #animationOffsets

    local tableDiag
    tableRecords, tableModels, tableDiag = Loader.loadObjectList("data/furniture_profiles/table_objects.txt")
    diagnostics.tableObjectsLoaded = tableDiag and tableDiag.loaded or 0
end

function Catalog.getProfileForObject(obj, interactionType)
    loadAll()
    if not obj then return nil end
    local kind = interactionType == "sleep" and "sleep" or "sit"
    local rid = getObjectRecordId(obj)
    local model = getObjectModel(obj)
    if Blacklist.isObjectBlacklisted(rid, model) then return nil end

    local profile = profilesByRecord[kind][rid]
    if not profile and model ~= "" then
        profile = profilesByModel[kind][model]
    end
    if not profile then return nil end
    return cloneProfile(profile)
end

function Catalog.getProfileForRecord(recordId, interactionType)
    loadAll()
    local kind = interactionType == "sleep" and "sleep" or "sit"
    local profile = profilesByRecord[kind][normalize(recordId)]
    return profile and cloneProfile(profile) or nil
end

function Catalog.getVariantForObject(profile, obj, slot)
    loadAll()
    if not profile or not obj then return nil end
    local list = variants[profile.interactionType] or {}
    local best = nil
    for _, variant in ipairs(list) do
        if variantMatches(variant, profile, obj, slot) then
            if variant.objectX then
                return variant
            end
            best = best or variant
        end
    end
    return best
end

function Catalog.localOffsetToWorld(obj, offset)
    local base = obj.position
    local localVec = util.vector3(offset.x or 0, offset.y or 0, offset.z or 0)
    local ok, rotated = pcall(function() return obj.rotation * localVec end)
    if not ok or not rotated then rotated = localVec end
    return base + rotated
end

function Catalog.localYawToFacing(obj, yawOffset)
    local yaw = 0
    pcall(function() yaw = obj.rotation:getYaw() end)
    yaw = yaw + ((yawOffset or 0) * math.pi / 180)
    return util.vector3(math.sin(yaw), math.cos(yaw), 0)
end

local function actorSpaceSlotPosition(obj, offset)
    offset = offset or {}
    local base = obj.position
    return util.vector3(base.x, base.y, base.z + (offset.z or 0))
end

function Catalog.getSlots(obj, interactionType)
    local profile = Catalog.getProfileForObject(obj, interactionType)
    if not profile then return nil end
    if interactionType ~= "sleep" and profile.source == "legacy" then
        return nil, profile
    end
    local out = {}
    for _, slot in ipairs(profile.slots or {}) do
        local resolved = applyVariant(slot, Catalog.getVariantForObject(profile, obj, slot))
        local offset = resolved.localOffset or { x = 0, y = 0, z = 0 }
        local isActorSpaceSitOffset = interactionType ~= "sleep"
        local pos = isActorSpaceSitOffset and actorSpaceSlotPosition(obj, offset) or Catalog.localOffsetToWorld(obj, offset)
        local facing = Catalog.localYawToFacing(obj, resolved.localFacingYaw or profile.yawOffset)
        out[#out + 1] = {
            pos = pos,
            facing = facing,
            actorSpaceOffset = isActorSpaceSitOffset and { x = offset.x or 0, y = offset.y or 0 } or nil,
            isOverride = true,
            profileId = profile.profileId,
            slotId = resolved.slotId,
            interactionType = interactionType,
            approachPos = resolved.approachOffset and Catalog.localOffsetToWorld(obj, resolved.approachOffset) or nil,
            flags = resolved.flags or profile.flags,
            source = profile.source,
            usesSharedSeatAnchor = resolved.usesSharedSeatAnchor,
        }
    end
    return out, profile
end

local function animationOffsetMatches(row, profile, obj, slot, context)
    if row.profileId ~= "" and row.profileId ~= profile.profileId then return false end
    if row.slotId ~= "" and (not slot or row.slotId ~= slot.slotId) then return false end
    if context ~= "" and normalizeInteractionType(row.interactionType) ~= "" and normalizeInteractionType(row.interactionType) ~= context then
        return false
    end
    if obj then
        local rid = getObjectRecordId(obj)
        local model = getObjectModel(obj)
        if row.recordId ~= "" and row.recordId ~= rid then return false end
        if row.model ~= "" and row.model ~= model then return false end
        if not yawMatches(row, yawDeg(obj)) then return false end
    else
        if row.recordId ~= "" or row.model ~= "" or row.yawBucket90 or row.yawMinDeg or row.yawMaxDeg then
            return false
        end
    end
    return true
end

local function animationOffsetSpecificity(row)
    local score = 0
    if row.recordId ~= "" then score = score + 8 end
    if row.model ~= "" then score = score + 8 end
    if row.profileId ~= "" then score = score + 4 end
    if row.slotId ~= "" then score = score + 4 end
    if row.yawBucket90 or row.yawMinDeg or row.yawMaxDeg then score = score + 2 end
    if normalizeInteractionType(row.interactionType) ~= "" then score = score + 1 end
    return score
end

function Catalog.getAnimationOffset(profile, animationId, poseContext, obj, slot)
    loadAll()
    if not profile or not animationId then return nil end
    local anim = normalize(animationId)
    local context = normalizeInteractionType(poseContext)
    local best, bestScore = nil, -1
    for _, row in ipairs(animationOffsets) do
        if row.animationId == anim
                and animationOffsetMatches(row, profile, obj, slot, context) then
            local score = animationOffsetSpecificity(row)
            if score > bestScore then
                best = row
                bestScore = score
            end
        end
    end
    return best
end

function Catalog.isTableObject(obj)
    loadAll()
    if not obj then return false end
    local rid = getObjectRecordId(obj)
    local model = getObjectModel(obj)
    local modelName = basename(model)
    return tableRecords[rid] == true
        or tableModels[model] == true
        or tableModels[modelName] == true
        or rid:find("table", 1, true) ~= nil
        or modelName:find("table", 1, true) ~= nil
end

function Catalog.getDiagnostics()
    loadAll()
    local copy = {}
    for k, v in pairs(diagnostics) do copy[k] = v end
    return copy
end

return Catalog
