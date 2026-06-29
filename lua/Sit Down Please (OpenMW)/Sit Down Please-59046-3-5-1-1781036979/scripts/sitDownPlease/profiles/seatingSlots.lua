-- profiles/seatingSlots.lua
---@omw-context none
--
-- Pure sitting-slot/category helper. Keep broad seat classification here instead
-- of growing interactionAssignment.lua.

local M = {}

local function lower(value)
    if value == nil then return "" end
    return string.lower(tostring(value))
end

local function shallowCopy(t)
    local copy = {}
    for k, v in pairs(t or {}) do copy[k] = v end
    return copy
end
M.shallowCopy = shallowCopy

function M.categoryFromKeys(keys, explicit)
    local category = lower(explicit)
    if category == "chair" or category == "backedchair" then return "backed_chair" end
    if category == "directionalstool" or category == "directional_stool" or category == "directional stool" or category == "directional-stool" then return "single_seat_bench" end
    if category == "single_seat_bench" or category == "singleseatbench" or category == "single seat bench" or category == "single-seat-bench" then return "single_seat_bench" end
    if category ~= "" and category ~= "fallback" then return category end

    local hasStool, hasBench, hasChair = false, false, false
    for _, key in ipairs(keys or {}) do
        local id = lower(key)
        if id:find("prayer_stool", 1, true) or id:find("prayer stool", 1, true) or id:find("kneel", 1, true) then
            return "prayer_stool"
        end
        if id:find("barstool", 1, true) then return "barstool" end
        if id:find("stool", 1, true) then hasStool = true end
        if id:find("bench", 1, true) then hasBench = true end
        if id:find("chair", 1, true) then hasChair = true end
    end
    if hasStool then return "stool" end
    if hasBench then return "bench" end
    if hasChair then return "backed_chair" end
    return category ~= "" and category or "stool"
end

function M.defaultSlotsForCategory(category)
    category = lower(category)
    if category == "bench" then
        -- Fallback benches expose three candidate seats. Short/single benches
        -- should use explicit profile rows with fewer slots.
        return { { name = "seat_a" }, { name = "seat_b" }, { name = "seat_c" } }
    end
    return { { name = "default" } }
end

function M.defaultApproachOffsetsForCategory(category)
    category = lower(category)
    if category == "bench" then
        return {
            { name = "front", x = 0, y = -80, z = 0 },
            { name = "back", x = 0, y = 80, z = 0 },
        }
    end
    if category == "backed_chair" then
        return { { name = "front", x = 0, y = -80, z = 0 } }
    end
    if category == "barstool" then
        return {
            { name = "front", x = 0, y = -80, z = 0 },
            { name = "left", x = -70, y = 0, z = 0 },
            { name = "right", x = 70, y = 0, z = 0 },
        }
    end
    return {
        { name = "front", x = 0, y = -70, z = 0 },
        { name = "left", x = -60, y = 0, z = 0 },
        { name = "right", x = 60, y = 0, z = 0 },
    }
end

function M.rotationModeForCategory(category)
    category = lower(category)
    if category == "backed_chair" or category == "single_seat_bench" then return "respectFurnitureForward" end
    if category == "bench" then return "faceOpenSide" end
    return "faceNearestTableOrCounter"
end

function M.fallbackProfileForKeys(baseProfile, keys, settings)
    local category = M.categoryFromKeys(keys, baseProfile and baseProfile.type)
    if not (settings and settings.allowFallbackSitting == true) then return nil, category end
    if category == "backed_chair" and settings.allowFallbackBackedChairs ~= true then return nil, category end
    if category == "prayer_stool" then return nil, category end
    if category ~= "stool" and category ~= "bench" and category ~= "barstool" and category ~= "backed_chair" then return nil, category end

    local profile = shallowCopy(baseProfile or {})
    profile.profileId = "fallback_" .. category
    profile.type = category
    profile.seatCategory = category
    profile.slots = M.defaultSlotsForCategory(category)
    profile.approachOffsets = M.defaultApproachOffsetsForCategory(category)
    profile.rotationMode = M.rotationModeForCategory(category)
    profile.finalForwardOffset = profile.finalForwardOffset or -7
    profile.finalZOffset = profile.finalZOffset or -36
    profile.unsafeIfBlocked = true
    profile.allowFallbackPositioning = true
    profile.isFallback = true
    return profile, category
end

return M
