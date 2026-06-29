-- assignment/releaseSafetyGate.lua
---@omw-context none
--
-- Runtime gate for broad seating/sleeping/station behavior in release builds.
-- Default settings keep broad behavior inside verified scopes while preserving
-- stools/barstools everywhere.

local M = {}
local profileScope = require('scripts/sitDownPlease/profiles/scope')

-- Maintainer-owned release allowlist. Do not expose these lists as user
-- settings; the player-facing control is only the Safety Gate toggle.
local TRUSTED_CELLS = {
    ["balmora, hlaalu council manor"] = true,
    ["balmora, caius cosades' house"] = true,
}

local TRUSTED_CELL_PREFIXES = {
    ["seyda neen, census and excise "] = true,
}

-- Promote a full place only after the place-scoped profiles and safety evidence
-- are release-ready. This shares the profile PlaceKey taxonomy without making
-- profile-folder presence a runtime trust signal.
local TRUSTED_PLACE_KEYS = {
    ["seyda_neen"] = true,
    -- ["balmora"] = true,
}

local TRUSTED_REGIONS = {
    -- ["bitter coast region"] = true,
}

local TRUSTED_FURNITURE_RECORDS = {
    ["furn_com_p_bench_01"] = true,
    ["furn_com_rm_bench_02"] = true,
    ["furn_de_ex_bench_01"] = true,
}

local FURNITURE_TYPE_EXCEPTIONS = {
    stool = true,
    barstool = true,
}

local function lower(value)
    return value and string.lower(tostring(value)) or ""
end

local trustedPlacePrefixCache = nil

local function trustedPlacePrefixes()
    if trustedPlacePrefixCache then return trustedPlacePrefixCache end
    local out = {}
    for placeKey, trusted in pairs(TRUSTED_PLACE_KEYS) do
        if trusted == true then
            local normalized = profileScope.normalizePlaceKey and profileScope.normalizePlaceKey(placeKey) or lower(placeKey)
            local label = profileScope.placeLabel and profileScope.placeLabel(normalized) or tostring(placeKey)
            local prefixes = profileScope.cellPrefixesForPlaceKey and profileScope.cellPrefixesForPlaceKey(normalized) or {}
            for _, prefix in ipairs(prefixes) do
                local normalizedPrefix = lower(prefix)
                if normalizedPrefix ~= "" then
                    out[#out + 1] = {
                        prefix = normalizedPrefix,
                        placeKey = normalized,
                        label = label,
                    }
                end
            end
        end
    end
    trustedPlacePrefixCache = out
    return out
end

local function cellName(cell)
    return lower(cell and (cell.name or cell.id) or "")
end

local function regionName(cell)
    return lower(cell and cell.region or "")
end

local function furnitureRecordId(obj, profile)
    local value = lower(obj and (obj.recordId or obj.id) or "")
    if value == "" and profile then value = lower(profile.recordId or profile.profileId) end
    return value
end

local function enabled(settings)
    return not (settings and settings.verifiedLocationsOnly == false)
end

local function calibrationBypass(options)
    return options and (
        options.calibrationAction == true
        or options.manualAssign == true
        or options.calibrationFill == true
        or options.testingOverride == true
        or options.debugForce == true
        or options.targetedManual == true
        or options.externalCompatibilityAssist == true
    )
end

local function normalizedFurnitureType(interactionType, profile, options)
    local value = lower(options and options.seatCategory or nil)
    if value == "" and profile then
        if interactionType == "station" then
            value = lower(profile.stationType or profile.type)
        elseif interactionType == "sleeping" then
            value = lower(profile.bedType or profile.type)
        else
            value = lower(profile.seatCategory or profile.type)
        end
    end
    if value == "backedchair" or value == "backed_chair" or value == "chair" then return "chair" end
    if value == "single_seat_bench" or value == "singleseatbench" then return "bench" end
    if value == "" and interactionType == "station" then return "station" end
    if value == "" and interactionType == "sleeping" then return "bed" end
    return value
end

local function furnitureAllowed(interactionType, profile, options)
    local furnitureType = normalizedFurnitureType(interactionType, profile, options)
    return FURNITURE_TYPE_EXCEPTIONS[furnitureType] == true, furnitureType
end

local function cellPrefixTrusted(name)
    if name == "" then return false, nil end
    for prefix in pairs(TRUSTED_CELL_PREFIXES) do
        if name:sub(1, #prefix) == prefix then return true, prefix, "cell_prefix" end
    end
    for _, place in ipairs(trustedPlacePrefixes()) do
        local prefix = place.prefix
        if prefix ~= "" and name:sub(1, #prefix) == prefix then
            return true, prefix, "place", place.placeKey, place.label
        end
    end
    return false, nil
end

function M.enabled(settings)
    return enabled(settings)
end

function M.cellTrusted(settings, cell)
    if not enabled(settings) then return true end
    local name = cellName(cell)
    return TRUSTED_CELLS[name] == true or cellPrefixTrusted(name) == true
end

function M.regionTrusted(settings, cell)
    if not enabled(settings) then return true end
    local region = regionName(cell)
    return region ~= "" and TRUSTED_REGIONS[region] == true
end

function M.trustedCells()
    return TRUSTED_CELLS
end

function M.trustedCellPrefixes()
    return TRUSTED_CELL_PREFIXES
end

function M.trustedPlaceKeys()
    return TRUSTED_PLACE_KEYS
end

function M.trustedPlaceCellPrefixes()
    return trustedPlacePrefixes()
end

function M.trustedRegions()
    return TRUSTED_REGIONS
end

function M.furnitureRecordExceptions()
    return TRUSTED_FURNITURE_RECORDS
end

function M.furnitureTypeExceptions()
    return FURNITURE_TYPE_EXCEPTIONS
end

function M.calibrationBypass(options)
    return calibrationBypass(options)
end

function M.policy(settings, cell, interactionType, profile, obj, options)
    local policy = {
        enabled = enabled(settings),
        cellName = cellName(cell),
        regionName = regionName(cell),
        interactionType = interactionType,
    }
    local furnitureException, furnitureType = furnitureAllowed(interactionType, profile, options)
    local recordId = furnitureRecordId(obj, profile)
    local prefixTrusted, prefix, prefixKind, placeKey, placeLabel = cellPrefixTrusted(policy.cellName)
    policy.furnitureType = furnitureType
    policy.furnitureRecordId = recordId
    policy.cellTrusted = TRUSTED_CELLS[policy.cellName] == true
    policy.cellPrefixTrusted = prefixTrusted == true and prefixKind ~= "place"
    policy.placeTrusted = prefixTrusted == true and prefixKind == "place"
    policy.cellPrefix = prefix
    policy.cellPrefixKind = prefixKind
    policy.placeKey = placeKey
    policy.placeLabel = placeLabel
    policy.regionTrusted = policy.regionName ~= "" and TRUSTED_REGIONS[policy.regionName] == true
    policy.furnitureRecordException = recordId ~= "" and TRUSTED_FURNITURE_RECORDS[recordId] == true
    policy.furnitureException = furnitureException == true
    if not policy.enabled then
        policy.allowed = true
        policy.reason = "gate_disabled"
        policy.status = "disabled"
        return policy
    end
    if policy.cellTrusted == true then
        policy.allowed = true
        policy.reason = "verified_cell"
        policy.status = "verified_cell"
        return policy
    end
    if policy.placeTrusted == true then
        policy.allowed = true
        policy.reason = "verified_place"
        policy.status = "verified_place"
        return policy
    end
    if policy.cellPrefixTrusted == true then
        policy.allowed = true
        policy.reason = "verified_cell_prefix"
        policy.status = "verified_cell_prefix"
        return policy
    end
    if policy.regionTrusted == true then
        policy.allowed = true
        policy.reason = "verified_region"
        policy.status = "verified_region"
        return policy
    end
    if policy.furnitureRecordException == true then
        policy.allowed = true
        policy.reason = "verified_furniture_record_exception"
        policy.status = "furniture_record_exception"
        return policy
    end
    if policy.furnitureException == true then
        policy.allowed = true
        policy.reason = "verified_furniture_type_exception"
        policy.status = "furniture_exception"
        return policy
    end
    if calibrationBypass(options) then
        policy.allowed = true
        if options and options.externalCompatibilityAssist == true then
            policy.reason = "unverified_location_external_compatibility"
            policy.status = "external_compatibility"
        else
            policy.reason = "unverified_location_calibration_override"
            policy.status = "calibration_override"
        end
        return policy
    end
    policy.allowed = false
    policy.reason = "unverified_location_gate"
    policy.status = "blocked"
    return policy
end

function M.candidatePolicy(settings, cell, interactionType, profile, obj, options)
    return M.policy(settings, cell, interactionType, profile, obj, options)
end

function M.stationPolicy(settings, cell, options)
    return M.policy(settings, cell, "station", options and options.profile or nil, options and options.object or nil, options)
end

function M.candidateAllowed(settings, cell, interactionType, profile, obj, options)
    local policy = M.candidatePolicy(settings, cell, interactionType, profile, obj, options)
    return policy.allowed == true, policy.reason, policy
end

function M.stationAllowed(settings, cell, options)
    local policy = M.stationPolicy(settings, cell, options)
    return policy.allowed == true, policy.reason, policy
end

function M.visibleLabel(policy)
    if not policy then return nil end
    local status = tostring(policy.status or "")
    if status == "disabled" then
        if policy.cellTrusted == true then
            status = "verified_cell"
        elseif policy.placeTrusted == true then
            status = "verified_place"
        elseif policy.cellPrefixTrusted == true then
            status = "verified_cell_prefix"
        elseif policy.regionTrusted == true then
            status = "verified_region"
        elseif policy.furnitureRecordException == true then
            status = "furniture_record_exception"
        elseif policy.furnitureException == true then
            status = "furniture_exception"
        else
            status = "blocked"
        end
    end
    local lines = {}
    if status == "verified_cell" then
        lines[#lines + 1] = "Cell verified"
    elseif status == "verified_place" then
        local label = tostring(policy.placeLabel or "")
        lines[#lines + 1] = label ~= "" and ("Place verified (" .. label .. ")") or "Place verified"
    elseif status == "verified_cell_prefix" then
        lines[#lines + 1] = "Cell prefix verified"
    elseif policy.cellName and policy.cellName ~= "" and status ~= "furniture_record_exception" and status ~= "furniture_exception" then
        lines[#lines + 1] = "Unverified cell"
    end
    if status == "verified_region" then
        lines[#lines + 1] = "Region verified"
    elseif policy.regionName and policy.regionName ~= "" and status ~= "verified_cell" and status ~= "verified_place" and status ~= "verified_cell_prefix" and status ~= "furniture_record_exception" and status ~= "furniture_exception" then
        lines[#lines + 1] = "Unverified region"
    end
    if status == "furniture_record_exception" then
        lines[#lines + 1] = "Furniture verified"
    elseif status == "furniture_exception" then
        local furnitureType = tostring(policy.furnitureType or "furniture")
        lines[#lines + 1] = "Furniture type allowed (" .. furnitureType .. ")"
    elseif status ~= "verified_cell" and status ~= "verified_place" and status ~= "verified_cell_prefix" and status ~= "verified_region" then
        lines[#lines + 1] = "Unverified furniture"
    end
    if policy.furnitureRecordException == true and status ~= "furniture_record_exception" then
        lines[#lines + 1] = "Furniture verified"
    end
    if status == "external_compatibility" then
        lines[#lines + 1] = "External animation compatibility"
    end
    if status ~= "blocked"
        and status ~= "calibration_override"
        and status ~= "external_compatibility"
        and status ~= "verified_cell"
        and status ~= "verified_place"
        and status ~= "verified_cell_prefix"
        and status ~= "verified_region"
        and status ~= "furniture_record_exception"
        and status ~= "furniture_exception" then
        return nil
    end
    return table.concat(lines, "\n")
end

return M
