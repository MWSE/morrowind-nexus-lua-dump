-- calibration/targetMetadata.lua
---@omw-context none

local M = {}
local focusMetadata = require('scripts/sitDownPlease/calibration/focusMetadata')

local function splitReasonTokens(reason)
    local text = tostring(reason or "")
    local out = {}
    for raw in text:gmatch("[^,%+]+") do
        local item = raw:gsub("^%s+", ""):gsub("%s+$", "")
        if item ~= "" and item ~= "nil" then out[#out + 1] = item end
    end
    return out
end

function M.readableReasonLabel(item)
    item = tostring(item or "")
    item = item:gsub("^soft_", "")
    item = item:gsub("^hard_", "")
    local labels = {
        active_travel_package = "Actor is using Travel",
        no_valid_slot = "No valid slot",
        invalid_transform = "Invalid target transform",
        route_rejected = "Route or claim check rejected this target",
        sleep_route_rejected = "Sleep route or bed claim was rejected",
        blocked_approach_fallback = "Approach route was blocked",
        approach_hard_timeout_fallback = "Approach route timed out",
        station_claim_mismatch = "Station claim no longer matches this actor",
        station_claim_unavailable = "Station claim system was unavailable",
        station_claim_pending = "Station is already pending another presenter",
        not_station_eligible = "Presenter does not meet station eligibility",
        station_wrong_faction_or_rank = "Presenter is not the required faction/rank",
        wrong_faction = "Presenter is in the wrong faction",
        faction_rank_too_low = "Presenter faction rank is too low",
        not_trainer_or_faction_leader = "Presenter is not a trainer or senior faction member",
        faction_leader = "Faction leader gate",
        slot_occupied = "Slot is already occupied",
        already_assigned = "Actor already has an SDP assignment",
        active_follow_or_escort_package = "Actor is following or escorting",
        escort_or_follow_package = "Actor is following or escorting",
        follower = "Followers are hard-blocked",
        disabled_actor = "Actor is disabled",
        dead_actor = "Actor is dead",
        invalid_actor = "Actor is not a valid calibration actor",
        external_animation_npc = "Actor is controlled by another animation system",
        external_furniture_claimed = "Furniture claimed by external animation",
        seat_surface_blocked_by_item = "Surface blocked by item",
        sleep_surface_blocked_by_item = "Surface blocked by item",
        sleep_surface_untrusted = "Sleep surface evidence is weak",
        sleep_body_inside_bed = "Sleep body is inside bed furniture",
        bed_surface_submerged = "Bed surface sample is submerged",
        bed_final_transform_rejected = "Bed final transform was rejected",
        debug_override_bed_inside_furniture = "Debug override forced inside-bed placement",
        sleep_missing_final_position = "Sleep transform is missing",
        sleep_service_actor_fallback_rejected = "Service NPC needs a trusted bed surface",
        sleep_final_transform_missing = "Sleep transform is missing",
        sleep_bunk_slot_untrusted = "Bunk needs a top/bottom slot",
        sleep_position_too_far_from_bed = "Sleep position is too far from bed",
        sleep_position_too_far_from_surface = "Sleep position is too far from surface",
        sleep_position_above_sampled_surface = "Sleep position is above sampled surface",
        sleep_position_below_sampled_surface = "Sleep position is below sampled surface",
        sleep_position_above_approach = "Sleep position is above safe approach",
        sleep_position_below_approach = "Sleep position is below safe approach",
        sleep_position_above_actor = "Sleep position is above actor",
        sleep_position_below_actor = "Sleep position is below actor",
        sleep_position_below_surface = "Sleep position is below sleep surface",
        sleep_position_below_floor = "Sleep position is below floor/exit",
        sleep_position_below_bed_object = "Sleep position is below bed object",
        sleep_position_above_bed_object = "Sleep position is above bed object",
        sleep_position_above_surface = "Sleep position is above sleep surface",
        sleep_surface_any_anchor_allowed = "Allowed any-surface anchor",
        sleep_surface_object_origin_fallback_allowed = "Object-origin fallback used",
        sleep_surface_low_object_unrepaired = "Sleep surface is unsafe low object hit",
        sleep_surface_any_anchor = "Any-surface anchor",
        sleep_surface_object_hits_missing = "No object-owned surface hits",
        sleep_calibration_large_offset = "Calibration offset is very large",
        sleep_calibration_large_negative_z = "Calibration Z offset is very low",
        initial_sitting_vertical_rejected = "Vertical placement would be unsafe",
        item_blocker = "Surface blocked by item",
        clutter_blocker = "Clutter blocks the seat surface",
        hard_blocker = "Hard blocker",
        soft_item_blocker = "Soft item blocker",
        paper_item = "Paper/book item",
        soft_surface = "Soft surface clutter",
        cushion_surface_blocker = "Surface blocked by cushion or pillow",
        tight_table_or_counter_rejected = "Table/counter clearance would be too tight",
        clearance_blocked_by_object = "Nearby object clearance would be too tight",
        public_bed_requires_door_assist = "Bed route needs door assist",
        manual_sleep_wrong_floor_or_room = "Sleep route crosses a wrong floor or room",
        locked_route_door = "Route blocked by a locked door",
        blocked_route_door = "Route blocked by a closed door",
        trapped_route_door = "Route blocked by a trapped door",
        teleport_door_route_required = "Route requires a teleport door",
        locked_teleport_door_route = "Route requires a locked teleport door",
        key_unknown_teleport_door_route = "Route requires a locked teleport door with unknown key",
        fill_existing_actor_unreachable = "Fill existing actor cannot reach target",
        assign_nearest_actor_unreachable = "Assigned actor cannot reach target",
        spawned_test_actor_reachability_override = "Spawned test actor reachability override",
        blocked_by_wall = "Approach route is blocked by geometry",
        wrong_floor_or_unreachable = "Approach appears on another floor or unreachable",
        sitting = "Actor is already sitting",
        sleeping = "Actor is already sleeping",
        locked = "Target is locked or route-locked",
        rented_or_private_inn_bed = "Rented / private inn bed",
        bench_slot_unavailable_short_length = "Bench slot is too short; using fallback slot",
        barter_service_npc = "Business-hours service NPC gate",
        trainer_service_npc = "Business-hours trainer gate",
        travel_service_npc = "Travel-service NPC is excluded",
        service_npc = "Business-hours service NPC gate",
        guard_or_publican_class = "Guard/publican class gate",
        publican_class = "Publican class gate",
        manual_item_override = "Item blocker",
        manual_clearance_override = "Clearance",
        manual_locked_route_override = "Locked route",
        manual_vertical_override = "Vertical placement",
        manual_override = "Manual calibration",
        testing_override = "Debug assignment",
        unverified_location_gate = "Unverified scope",
        unverified_location_calibration_override = "Unverified scope",
        unverified_location_external_compatibility = "External animation compatibility",
        verified_cell = "Cell verified",
        verified_place = "Place verified",
        verified_cell_prefix = "Cell prefix verified",
        verified_region = "Region verified",
        verified_furniture_record_exception = "Furniture verified",
        verified_furniture_type_exception = "Furniture allowed",
        modded_q_dras_hlaalu_council_manor_guard = "Modded scripted NPC guard",
    }
    local label = labels[item]
    if label then return label end
    return (item:gsub("_", " "):gsub("^%l", string.upper))
end

local function reasonDisplayTarget(item, label)
    local text = tostring(item or "")
    local visible = tostring(label or ""):lower()
    if text == "external_furniture_claimed"
        or text == "rented_or_private_inn_bed"
        or visible:find("furniture claimed by external animation", 1, true) then
        return "furniture"
    end
    if text == "external_animation_npc"
        or text == "active_travel_package"
        or text == "active_follow_or_escort_package"
        or text == "escort_or_follow_package"
        or text == "follower"
        or text == "disabled_actor"
        or text == "dead_actor"
        or text == "invalid_actor"
        or text == "already_assigned"
        or text == "barter_service_npc"
        or text == "trainer_service_npc"
        or text == "travel_service_npc"
        or text == "service_npc"
        or text == "guard_or_publican_class"
        or text == "publican_class"
        or text == "wrong_faction"
        or text == "faction_rank_too_low"
        or text == "faction_leader"
        or text == "not_trainer_or_faction_leader"
        or text == "not_station_eligible"
        or text == "station_wrong_faction_or_rank" then
        return "actor"
    end
    if visible:find("actor", 1, true)
        or visible:find("npc", 1, true)
        or visible:find("follower", 1, true)
        or visible:find("follow", 1, true)
        or visible:find("escort", 1, true)
        or visible:find("travel", 1, true)
        or visible:find("service", 1, true)
        or visible:find("trainer", 1, true)
        or visible:find("guard", 1, true)
        or visible:find("publican", 1, true)
        or visible:find("presenter", 1, true)
        or visible:find("faction", 1, true)
        or visible:find("external animation", 1, true)
        or visible:find("another animation system", 1, true) then
        return "actor"
    end
    if text:find("^sleep_position_", 1, false) then
        return "safety"
    end
    if text == "no_valid_slot"
        or text == "invalid_transform"
        or text == "seat_surface_blocked_by_item"
        or text == "sleep_surface_blocked_by_item"
        or text == "item_blocker"
        or text == "clutter_blocker"
        or text == "soft_item_blocker"
        or text == "paper_item"
        or text == "soft_surface"
        or text == "cushion_surface_blocker"
        or text == "tight_table_or_counter_rejected"
        or text == "clearance_blocked_by_object"
        or text == "slot_occupied"
        or text:find("surface", 1, true)
        or text:find("item", 1, true)
        or text:find("clutter", 1, true)
        or text:find("clearance", 1, true)
        or visible:find("surface", 1, true)
        or visible:find("clearance", 1, true)
        or visible:find("slot", 1, true) then
        return "furniture"
    end
    if text:find("fallback", 1, true)
        or text:find("profile", 1, true)
        or visible:find("fallback", 1, true)
        or visible:find("profile", 1, true) then
        return "profile"
    end
    if text:find("verified_", 1, true)
        or text:find("unverified_location", 1, true) then
        return "safety"
    end
    if text:find("sleep_", 1, true)
        or text:find("route", 1, true)
        or text:find("locked", 1, true) then
        return "furniture"
    end
    return "generic"
end

local function severityForCategory(category)
    if category == "rejections" or category == "blockers" then return "blocker" end
    if category == "overrides" then return "override" end
    return "warning"
end

local function groupedRowKey(target, severity)
    if target == "safety" then return "safetyGate" end
    local suffix = severity == "blocker" and "Blockers" or "Warnings"
    if target == "actor" then return "actor" .. suffix end
    if target == "furniture" then return "furniture" .. suffix end
    if target == "profile" then return "profile" .. suffix end
    return severity == "blocker" and "genericBlockers" or "genericWarnings"
end

local function reasonCategory(item)
    local text = tostring(item or "")
    if text == "seat_surface_blocked_by_item" or text:find("item", 1, true) or text:find("clutter", 1, true) or text:find("cushion", 1, true) then return "blockers" end
    if text == "external_furniture_claimed" then return "warnings" end
    if text:find("^hard_") or text == "no_valid_slot" or text == "invalid_transform" then return "rejections" end
    if text:find("manual_", 1, true) or text:find("override", 1, true) or text == "active_travel_package" then return "overrides" end
    if text == "sleep_surface_untrusted"
        or text == "sleep_surface_low_object_unrepaired"
        or text == "sleep_bunk_slot_untrusted"
        or text == "sleep_body_inside_bed"
        or text == "bed_surface_submerged"
        or text == "bed_final_transform_rejected"
        or text == "initial_sitting_vertical_rejected" then
        return "blockers"
    end
    if text:find("^soft_")
        or text == "tight_table_or_counter_rejected"
        or text:find("blocked", 1, true)
        or text:find("blocker", 1, true)
        or text:find("locked_route", 1, true)
        or text:find("fallback", 1, true) then
        return "blockers"
    end
    return "warnings"
end

local function reasonAppliesToInteraction(interactionType, item)
    local t = tostring(interactionType or "")
    local text = tostring(item or "")
    if t == "sleeping" then
        if text == "seat_surface_blocked_by_item"
            or text == "item_blocker"
            or text == "cushion_surface_blocker"
            or text == "soft_seat_clutter_surface"
            or text:find("^seat_") then
            return false
        end
    elseif t == "sitting" then
        if text == "sleep_surface_blocked_by_item"
            or text == "sleep_surface_untrusted"
            or text == "sleep_bunk_slot_untrusted"
            or text == "soft_bed_clutter_surface"
            or text:find("^sleep_") then
            return false
        end
    end
    return true
end

function M.compactReasonSections(reason, interactionType)
    local sections = { detected = {}, blockers = {}, overrides = {}, rejections = {}, warnings = {} }
    local seen = { detected = {}, blockers = {}, overrides = {}, rejections = {}, warnings = {} }
    for _, item in ipairs(splitReasonTokens(reason)) do
        if reasonAppliesToInteraction(interactionType, item) then
            local category = reasonCategory(item)
            local label = M.readableReasonLabel(item)
            if label ~= "" and not seen[category][label] then
                sections[category][#sections[category] + 1] = label
                seen[category][label] = true
            end
        end
    end
    local out = {}
    for _, key in ipairs({ "detected", "blockers", "overrides", "rejections", "warnings" }) do
        out[key] = table.concat(sections[key], "\n")
    end
    return out
end

local function lineLooksLikeSurfaceItemBlocker(line)
    local text = tostring(line or ""):lower()
    return text:find("surface blocked", 1, true) ~= nil
        or text:find("item on", 1, true) ~= nil
        or text:find("paper/book", 1, true) ~= nil
        or text:find("soft item", 1, true) ~= nil
        or text:find("clutter", 1, true) ~= nil
        or text:find("cushion", 1, true) ~= nil
end

local blockerWarningPairs = {
    furnitureBlockers = "furnitureWarnings",
    actorBlockers = "actorWarnings",
    profileBlockers = "profileWarnings",
    genericBlockers = "genericWarnings",
    blockers = "warnings",
}

local warningBlockerPairs = {
    furnitureWarnings = "furnitureBlockers",
    actorWarnings = "actorBlockers",
    profileWarnings = "profileBlockers",
    genericWarnings = "genericBlockers",
    warnings = "blockers",
}

local function rowHasExactLine(rows, key, line)
    for old in tostring(rows and rows[key] or ""):gmatch("[^\n]+") do
        if old == line then return true end
    end
    return false
end

local function removeExactLine(rows, key, line)
    if not (rows and key) then return end
    local kept = {}
    for old in tostring(rows[key] or ""):gmatch("[^\n]+") do
        if old ~= "" and old ~= line then kept[#kept + 1] = old end
    end
    rows[key] = table.concat(kept, "\n")
end

local function appendGroupedLine(rows, key, line)
    if not (rows and key and line and line ~= "") then return end
    line = tostring(line)
    local existing = tostring(rows[key] or "")
    if key == "furnitureBlockers" and lineLooksLikeSurfaceItemBlocker(line) then
        local kept = {}
        for old in existing:gmatch("[^\n]+") do
            if old ~= "" and not lineLooksLikeSurfaceItemBlocker(old) then
                kept[#kept + 1] = old
            end
        end
        rows[key] = table.concat(kept, "\n")
    end
    local blockerKey = warningBlockerPairs[key]
    if blockerKey and rowHasExactLine(rows, blockerKey, line) then return end
    local warningKey = blockerWarningPairs[key]
    if warningKey then removeExactLine(rows, warningKey, line) end
    rows[key] = M.appendTextLine(rows[key], line)
end

local function applyReasonLine(rows, category, rawItem, label)
    local target = reasonDisplayTarget(rawItem, label)
    local key = groupedRowKey(target, severityForCategory(category))
    appendGroupedLine(rows, key, label)
end

function M.applyReasonSections(rows, sections, interactionType)
    if not (rows and sections) then return end
    for _, category in ipairs({ "warnings", "overrides", "blockers", "rejections" }) do
        for line in tostring(sections[category] or ""):gmatch("[^\n]+") do
            if line ~= "" and M.displayReasonAppliesToInteraction(interactionType, line) then
                applyReasonLine(rows, category, line, line)
            end
        end
    end
end

function M.displayReasonAppliesToInteraction(interactionType, line)
    local t = tostring(interactionType or "")
    local text = tostring(line or ""):lower()
    local sittingOnly = text:find("seat surface", 1, true)
        or text:find("seat clutter", 1, true)
        or text:find("seat blocked", 1, true)
        or text:find("cushion", 1, true)
    local sleepingOnly = text:find("bed surface", 1, true)
        or text:find("sleep surface", 1, true)
        or text:find("sleep position", 1, true)
        or text:find("bunk", 1, true)
        or text:find("bed object", 1, true)
        or text:find("floor/exit", 1, true)
    if t == "sleeping" then
        return not sittingOnly
    elseif t == "sitting" then
        return not sleepingOnly
    end
    return true
end

function M.sanitizeRowsForInteraction(rows, interactionType)
    if not rows then return end
    for _, key in ipairs({ "detected", "blockers", "overrides", "rejections", "warnings", "actorWarnings", "actorBlockers", "furnitureWarnings", "furnitureBlockers", "focusWarnings", "profileWarnings", "profileBlockers", "genericWarnings", "genericBlockers" }) do
        local kept = {}
        for line in tostring(rows[key] or ""):gmatch("[^\n]+") do
            if line ~= "" and M.displayReasonAppliesToInteraction(interactionType, line) then
                kept[#kept + 1] = line
            end
        end
        rows[key] = table.concat(kept, "\n")
    end
end

function M.readableTargetLabel(label)
    local text = tostring(label or "")
    text = text:gsub("%s*%-%>%s*", " at ")
    text = text:gsub("%s*→%s*", " at ")
    text = text:gsub("%s+at%s+at%s+", " at ")
    if text == "" or text == "nil at nil (default)" then
        return "target selected; waiting for confirmation"
    end
    return text
end

local function clippedLabel(text, limit)
    text = tostring(text or "")
    limit = tonumber(limit) or 68
    if #text <= limit then return text end
    if limit <= 3 then return text:sub(1, limit) end
    return text:sub(1, limit - 3) .. "..."
end

local function withoutNormalPlayStatus(existing)
    local kept = {}
    for line in tostring(existing or ""):gmatch("[^\n]+") do
        if line ~= ""
            and not line:find("^Normal play ", 1, false)
            and not line:find("^Placement ", 1, false) then
            kept[#kept + 1] = line
        end
    end
    return table.concat(kept, "\n")
end

local function validReason(value)
    local text = tostring(value or "")
    if text == "" or text == "nil" then return nil end
    return text
end

local function firstApplicableNormalPlayReason(interactionType, value)
    local reasonText = validReason(value)
    if not reasonText then return nil end
    for _, reason in ipairs(splitReasonTokens(reasonText)) do
        if reasonAppliesToInteraction(interactionType, reason) then
            return reason
        end
    end
    if reasonAppliesToInteraction(interactionType, reasonText) then
        return reasonText
    end
    return nil
end

local function normalPlayStatusReason(data)
    if not data then return nil end
    local interactionType = tostring(data.interactionType or "")
    local reason = firstApplicableNormalPlayReason(interactionType, data.sleepSafetyReason)
    if reason then return reason end
    reason = firstApplicableNormalPlayReason(interactionType, data.sleepAccessOverrideReason)
    if reason then return reason end
    reason = firstApplicableNormalPlayReason(interactionType, data.hardBlockerReason)
    if reason then return reason end
    reason = firstApplicableNormalPlayReason(interactionType, data.rejectionReason)
    if reason then return reason end
    reason = firstApplicableNormalPlayReason(interactionType, data.surfaceBlockerReason)
    if reason then return reason end
    reason = firstApplicableNormalPlayReason(interactionType, data.surfaceBlockerOverrideReason)
    if reason then return reason end
    reason = firstApplicableNormalPlayReason(interactionType, data.softBlockerReason)
    if reason then return reason end
    reason = firstApplicableNormalPlayReason(interactionType, data.testingOverrideReason)
    if reason then return reason end
    reason = firstApplicableNormalPlayReason(interactionType, data.manualOverrideReason)
    if reason then return reason end
    return nil
end

local normalPlayReasonFields = {
    "sleepSafetyReason",
    "sleepAccessOverrideReason",
    "hardBlockerReason",
    "rejectionReason",
    "surfaceBlockerReason",
    "surfaceBlockerOverrideReason",
    "softBlockerReason",
    "testingOverrideReason",
    "manualOverrideReason",
}

local actorWarningNormalPlayReasons = {
    barter_service_npc = true,
    trainer_service_npc = true,
    travel_service_npc = true,
    service_npc = true,
    guard_or_publican_class = true,
    publican_class = true,
}

local function rowSetAlreadyContains(rows, label)
    local needle = tostring(label or "")
    if needle == "" then return true end
    for _, key in ipairs({
        "actorWarnings", "actorBlockers",
        "furnitureWarnings", "furnitureBlockers",
        "profileWarnings", "profileBlockers",
        "genericWarnings", "genericBlockers",
        "warnings", "blockers", "rejections", "safetyGate",
    }) do
        if tostring(rows[key] or ""):find(needle, 1, true) then
            return true
        end
    end
    return false
end

local function appendNormalPlayReasonDetails(rows, data)
    if not (rows and data) then return end
    local interactionType = tostring(data.interactionType or "")
    local seen = {}
    for _, field in ipairs(normalPlayReasonFields) do
        local reasonText = validReason(data[field])
        if reasonText then
            for _, reason in ipairs(splitReasonTokens(reasonText)) do
                if reasonAppliesToInteraction(interactionType, reason) and not seen[reason] then
                    local label = M.readableReasonLabel(reason)
                    if label ~= "" and not rowSetAlreadyContains(rows, label) then
                        local severity = actorWarningNormalPlayReasons[reason] and "warnings" or "blockers"
                        applyReasonLine(rows, severity, reason, label)
                        seen[reason] = true
                    end
                end
            end
        end
    end
end

local function rowsIndicatePlacementBlocked(rows)
    if not rows then return false end
    local text = table.concat({
        tostring(rows.blockers or ""),
        tostring(rows.rejections or ""),
        tostring(rows.actorBlockers or ""),
        tostring(rows.furnitureBlockers or ""),
        tostring(rows.profileBlockers or ""),
        tostring(rows.genericBlockers or ""),
        tostring(rows.furnitureWarnings or ""),
    }, "\n"):lower()
    if text == "" then return false end
    return text:find("surface blocked", 1, true) ~= nil
        or text:find("clearance would be too tight", 1, true) ~= nil
        or text:find("route or claim check rejected", 1, true) ~= nil
        or text:find("route was blocked", 1, true) ~= nil
        or text:find("route timed out", 1, true) ~= nil
        or text:find("no valid slot", 1, true) ~= nil
        or text:find("invalid target transform", 1, true) ~= nil
        or text:find("vertical placement would be unsafe", 1, true) ~= nil
        or text:find("sleep transform is missing", 1, true) ~= nil
        or text:find("sleep position is", 1, true) ~= nil
        or text:find("sleep surface is unsafe", 1, true) ~= nil
        or text:find("furniture claimed by external animation", 1, true) ~= nil
end

local function applyNormalPlayStatus(rows, data)
    if not (rows and data) then return end
    local interactionType = tostring(data.interactionType or "")
    if interactionType ~= "sleeping" and interactionType ~= "sitting" and interactionType ~= "station" then return end
    appendNormalPlayReasonDetails(rows, data)
    local reason = normalPlayStatusReason(data)
    local blocked = reason ~= nil or rowsIndicatePlacementBlocked(rows)
    local status = blocked and "Blocked" or "Allowed"
    rows.normalPlay = status
end

function M.compactTargetText(interactionType, label)
    local text = M.readableTargetLabel(label)
    local typeLabel = interactionType == "sitting" and "seat"
        or (interactionType == "sleeping" and "bed"
        or (interactionType == "station" and "station" or "target"))
    local prefix = "Selected " .. typeLabel .. " target: "
    local actor, object, meta = text:match("^(.-)%s+at%s+(.+)%s+%((.-)%)$")
    if actor and object then
        local slot, _, source = meta:match("^([^;]+);%s*([^;]+);%s*(.+)$")
        local line = prefix .. clippedLabel(actor, 16) .. " - " .. clippedLabel(object, 24)
        if slot and slot ~= "" then line = line .. " - " .. clippedLabel(slot, 10) end
        if source and source ~= "" then line = line .. " - " .. clippedLabel(source, 10) end
        return clippedLabel(line, 74)
    end
    object, meta = text:match("^(.+)%s+%((.-)%)$")
    if object then
        local slot, source = meta:match("^([^;]+);%s*(.+)$")
        local line = prefix .. clippedLabel(object, 28)
        if slot and slot ~= "" then line = line .. " - " .. clippedLabel(slot, 14) end
        if source and source ~= "" then line = line .. " - " .. clippedLabel(source, 12) end
        return clippedLabel(line, 74)
    end
    return clippedLabel(prefix .. text, 74)
end

function M.blankRows()
    return {
        status = "None selected",
        actor = "",
        actorScale = "",
        actorPose = "",
        actorStatus = "",
        actorDetail = "",
        actorWarnings = "",
        actorBlockers = "",
        focus = "",
        focusScale = "",
        focusDetail = "",
        focusWarnings = "",
        focusCandidates = "",
        furniture = "",
        furnitureScale = "",
        furnitureDetail = "",
        furnitureSource = "",
        furnitureModel = "",
        furnitureWarnings = "",
        furnitureBlockers = "",
        cell = "",
        slot = "",
        type = "",
        profile = "",
        profileWarnings = "",
        profileBlockers = "",
        pose = "",
        detected = "",
        blockers = "",
        overrides = "",
        rejections = "",
        normalPlay = "",
        safetyGate = "",
        warnings = "",
        genericWarnings = "",
        genericBlockers = "",
    }
end

function M.displaySlotLabel(slot)
    local text = tostring(slot or "")
    if text == "" then return "" end
    local normalized = text:lower():gsub("_", " "):gsub("%s+", " "):match("^%s*(.-)%s*$") or ""
    if normalized == "default"
        or normalized == "main seat"
        or normalized == "main bed"
        or normalized == "main bed slot"
        or normalized == "sleep main"
        or normalized == "presenter" then
        return ""
    end
    return text
end

local function displaySlotForType(slot, interactionType)
    local text = M.displaySlotLabel(slot)
    if text == "" then return "" end
    local normalized = text:lower():gsub("_", " ")
    if interactionType == "sleeping" then
        text = text:gsub("^[Bb]ed%s+", "")
        text = text:gsub("^[Mm]ain%s+[Bb]ed%s+", "")
        text = text:gsub("^[Mm]ain%s+", "")
        if normalized == "sleep a" then return "slot A" end
        if normalized == "sleep b" then return "slot B" end
        if normalized == "sleep left" then return "left slot" end
        if normalized == "sleep right" then return "right slot" end
    end
    return text
end

function M.typeDisplayValue(interactionType, typeValue, slot)
    local typeText = tostring(typeValue or "")
    if typeText == "nil" then typeText = "" end
    local slotText = displaySlotForType(slot, interactionType)
    if typeText == "" and slotText == "" then return "" end
    if typeText == "" then
        typeText = interactionType == "sleeping" and "bed"
            or (interactionType == "station" and "station" or "seat")
    end
    if slotText ~= "" then
        return typeText .. " (" .. slotText .. ")"
    end
    return typeText
end

function M.targetRows(interactionType, label, sections)
    sections = type(sections) == "table" and sections or { overrides = sections or "" }
    local text = M.readableTargetLabel(label)
    local typeLabel = interactionType == "sitting" and "seat"
        or (interactionType == "sleeping" and "bed"
        or (interactionType == "station" and "station" or "target"))
    local rows = M.blankRows()
    rows.status = typeLabel:sub(1, 1):upper() .. typeLabel:sub(2) .. " selected"
    rows.detected = sections.detected or ""
    rows.blockers = sections.blockers or ""
    rows.overrides = sections.overrides or ""
    rows.rejections = sections.rejections or ""
    rows.safetyGate = sections.safetyGate or ""
    rows.warnings = sections.warnings or ""
    M.applyReasonSections(rows, sections, interactionType)
    local actor, object, meta = text:match("^(.-)%s+at%s+(.+)%s+%((.-)%)$")
    if actor and object then
        local slot, furnitureType, source = meta:match("^([^;]+);%s*([^;]+);%s*(.+)$")
        rows.actor = actor ~= "<actor>" and (actor or "") or ""
        rows.furniture = object or ""
        rows.slot = M.displaySlotLabel(slot)
        rows.type = furnitureType or ""
        rows.profile = source or ""
        if rows.profile:lower():find("fallback", 1, true) then
            rows.profileWarnings = M.appendTextLine(rows.profileWarnings, "Generated fallback profile")
        end
        return rows
    end
    object, meta = text:match("^(.+)%s+%((.-)%)$")
    if object then
        if tostring(meta or "") == "actor selected" then
            rows.status = "Actor selected"
            rows.actor = object or ""
            return rows
        end
        local slot, furnitureType, source = meta:match("^([^;]+);%s*([^;]+);%s*(.+)$")
        if not slot then
            slot, source = meta:match("^([^;]+);%s*(.+)$")
            furnitureType = typeLabel
        end
        rows.furniture = object or ""
        rows.slot = M.displaySlotLabel(slot)
        rows.type = furnitureType or typeLabel
        rows.profile = source or ""
        if rows.profile:lower():find("fallback", 1, true) then
            rows.profileWarnings = M.appendTextLine(rows.profileWarnings, "Generated fallback profile")
        end
        return rows
    end
    rows.furniture = text
    return rows
end

function M.nonStandardScaleText(scale, label)
    local value = tonumber(scale)
    if not value or math.abs(value - 1.0) <= 0.01 then return "" end
    label = tostring(label or "scale")
    return "(" .. label .. " " .. string.format("%.2f", value) .. ")"
end

function M.appendTextLine(existing, line)
    line = tostring(line or "")
    if line == "" then return existing or "" end
    existing = tostring(existing or "")
    if existing == "" then return line end
    for old in existing:gmatch("[^\n]+") do
        if old == line then return existing end
    end
    return existing .. "\n" .. line
end

function M.applyAssignmentContext(rows, data)
    if not (rows and data) then return rows end
    local actor = tostring(rows.actor or "")
    if actor ~= "" and data.sdpOwnedAssignment == false then
        rows.profile = ""
        rows.profileWarnings = ""
        rows.profileBlockers = ""
    end
    return rows
end

local function appendTextLines(existing, lines)
    local out = existing or ""
    for line in tostring(lines or ""):gmatch("[^\n]+") do
        if line ~= "" then
            out = M.appendTextLine(out, line)
        end
    end
    return out
end

local function clippedMetadataDetail(value, limit)
    local text = tostring(value or "")
    limit = tonumber(limit) or 52
    if text == "" or text == "nil" then return "" end
    if #text <= limit then return text end
    if limit <= 3 then return text:sub(1, limit) end
    return "..." .. text:sub(-(limit - 3))
end

local function appendMetadataDetail(existing, line, limit)
    line = clippedMetadataDetail(line, limit)
    if line == "" then return existing or "" end
    return M.appendTextLine(existing, line)
end

local function contentFileLabel(value)
    local text = tostring(value or "")
    if text == "" or text == "nil" then return "" end
    return text
end

function M.applySourceDetails(rows, data)
    if not (rows and data) then return end
    if tostring(rows.actor or "") == "nil" then rows.actor = "" end
    if tostring(rows.furniture or "") == "nil" then rows.furniture = "" end
    rows.actorPose = ""
    rows.actorStatus = ""
    rows.actorDetail = ""
    rows.furnitureDetail = ""
    rows.furnitureSource = ""
    rows.furnitureModel = ""
    if tostring(rows.furniture or "") ~= "" then
        rows.furnitureSource = clippedMetadataDetail(contentFileLabel(data.objectContentFile), 52)
        rows.furnitureModel = clippedMetadataDetail(data.objectModelPath, 58)
    else
        rows.type = ""
    end
    if tostring(rows.actor or "") ~= "" then
        rows.actorPose = clippedMetadataDetail(data.animation or data.poseAnimation, 58)
        if data.externalPhysicalClaimed == true
            or data.hardBlockerReason == "external_furniture_claimed"
            or data.rejectionReason == "external_furniture_claimed" then
            rows.actorStatus = "Externally animated"
            rows.furnitureWarnings = M.appendTextLine(rows.furnitureWarnings, M.readableReasonLabel("external_furniture_claimed"))
        elseif data.rejectionReason == "external_animation_npc"
            or data.hardBlockerReason == "external_animation_npc" then
            rows.actorStatus = "Externally animated"
        end
        local actorSource = contentFileLabel(data.actorContentFile)
        local actorSourceLower = string.lower(tostring(actorSource or ""))
        if actorSourceLower == "dynamic / unknown" or actorSourceLower == "dynamic" or actorSourceLower == "unknown" then
            actorSource = ""
        end
        rows.actorDetail = appendMetadataDetail("", actorSource, 52)
    end
end

function M.applyFocusDetails(rows, data)
    if not (rows and data and data.interactionType == "sitting") then return end
    local focus, detail, warnings, candidates = focusMetadata.focusRows(data)
    rows.focus = focus
    rows.focusDetail = detail
    rows.focusWarnings = warnings
    rows.focusCandidates = candidates
end

function M.lineIsItemSurfaceBlocker(line)
    local text = tostring(line or ""):lower()
    -- Normal-play override may demote informational rejection text to yellow,
    -- but hard placement blockers must stay red from first target capture
    -- through Print/Reset refreshes.  Table/counter clearance is a hard
    -- furniture blocker even when the target was captured manually.
    return text:find("surface blocked", 1, true) ~= nil
        or text:find("item on", 1, true) ~= nil
        or text:find("paper/book", 1, true) ~= nil
        or text:find("hard blocker", 1, true) ~= nil
        or text:find("soft item", 1, true) ~= nil
        or text:find("clutter", 1, true) ~= nil
        or text:find("cushion", 1, true) ~= nil
        or text:find("clearance would be too tight", 1, true) ~= nil
        or text:find("object clearance", 1, true) ~= nil
        or text:find("table/counter clearance", 1, true) ~= nil
end

function M.normalPlayOverrideSections(sections)
    sections = sections or {}
    local warnings = tostring(sections.warnings or "")
    local retainedBlockers = ""
    for line in tostring(sections.blockers or ""):gmatch("[^\n]+") do
        if line ~= "" then
            if M.lineIsItemSurfaceBlocker(line) then
                retainedBlockers = M.appendTextLine(retainedBlockers, line)
            else
                warnings = M.appendTextLine(warnings, line)
            end
        end
    end
    sections.blockers = retainedBlockers
    for _, key in ipairs({ "rejections" }) do
        for line in tostring(sections[key] or ""):gmatch("[^\n]+") do
            if line ~= "" then
                warnings = M.appendTextLine(warnings, line)
            end
        end
        sections[key] = ""
    end
    sections.warnings = warnings
    return sections
end

local function appendExplicitBlockerReasons(rows, data)
    if not (rows and data) then return end
    local interactionType = tostring(data.interactionType or "")
    for _, field in ipairs({ "hardBlockerReason", "surfaceBlockerReason", "surfaceBlockerOverrideReason", "softBlockerReason", "rejectionReason" }) do
        for _, reason in ipairs(splitReasonTokens(data[field])) do
            if reasonAppliesToInteraction(interactionType, reason) then
                local label = M.readableReasonLabel(reason)
                if label ~= "" and not rowSetAlreadyContains(rows, label) then
                    local category = reasonCategory(reason)
                    if category == "blockers" or category == "rejections" then
                        applyReasonLine(rows, category, reason, label)
                    end
                end
            end
        end
    end
end

local function blockerDetailLabel(data)
    if not data then return nil end
    local reason = tostring(data.surfaceBlockerReason or "")
    if reason == "" or reason == "nil" then return nil end
    if data.interactionType == "sleeping" and (reason == "seat_surface_blocked_by_item" or reason == "item_blocker" or reason == "cushion_surface_blocker") then
        return nil
    end
    if data.interactionType == "sitting" and (reason == "sleep_surface_blocked_by_item" or reason:find("^sleep_", 1, false)) then
        return nil
    end
    local base = M.readableReasonLabel(reason)
    local objectId = tostring(data.surfaceBlockerObjectId or "")
    if objectId ~= "" and objectId ~= "nil" then
        base = base .. ": " .. objectId
    end
    return base
end

function M.applyBlockerDetails(rows, data)
    if not (rows and data) then return end
    appendExplicitBlockerReasons(rows, data)
    local detail = blockerDetailLabel(data)
    if tostring(data.surfaceBlockerReason or "") == "tight_table_or_counter_rejected" then
        -- The generic red clearance blocker is the useful signal now that table
        -- focus diagnostics are separated.  Do not add the older object-id detail
        -- line as a second warning/blocker row.
        return
    end
    if detail and detail ~= "" then
        local base = M.readableReasonLabel(tostring(data.surfaceBlockerReason or ""))
        local override = data.manualOverride == true or data.testingOverride == true or data.surfaceBlockerOverrideReason ~= nil
        local itemSurfaceBlocker = data.surfaceBlockerReason == "sleep_surface_blocked_by_item"
            or data.surfaceBlockerReason == "seat_surface_blocked_by_item"
            or M.lineIsItemSurfaceBlocker(detail)
        local key = (override and not itemSurfaceBlocker) and "furnitureWarnings" or "furnitureBlockers"
        local existing = tostring(rows[key] or "")
        if not itemSurfaceBlocker and base ~= "" and existing:find(base, 1, true) then
            return
        end
        if itemSurfaceBlocker then
            local objectId = tostring(data.surfaceBlockerObjectId or "")
            if objectId ~= "" and objectId ~= "nil" then
                detail = clippedLabel("Surface blocked by " .. objectId .. " item", 40)
            else
                detail = "Surface blocked by item"
            end
        end
        if override and not itemSurfaceBlocker then
            appendGroupedLine(rows, "furnitureWarnings", detail)
        else
            appendGroupedLine(rows, "furnitureBlockers", detail)
        end
    end
end

function M.applyRejectionDetails(rows, data)
    if not (rows and data and data.rejectionReason ~= nil) then return end
    local reason = tostring(data.rejectionReason or "")
    if reason == "" or reason == "nil" then return end
    local label = M.readableReasonLabel(reason)
    if label == "" then return end
    if reason == "external_furniture_claimed" then
        appendGroupedLine(rows, "furnitureWarnings", label)
        return
    end
    if (reason == "external_furniture_claimed" or reason == "external_animation_npc")
        and tostring(rows.actorStatus or "") ~= "" then
        return
    end
    applyReasonLine(rows, "rejections", reason, label)
end

function M.applySafetyDetails(rows, data)
    if not (rows and data) then return end
    rows.safetyGate = withoutNormalPlayStatus(rows.safetyGate)
    local calibrationWarning = tostring(data.sleepCalibrationWarningReason or "")
    if calibrationWarning ~= "" and calibrationWarning ~= "nil" then
        for _, item in ipairs(splitReasonTokens(calibrationWarning)) do
            local detail = M.readableReasonLabel(item)
            if detail ~= "" and not tostring(rows.furnitureWarnings or ""):find(detail, 1, true) then
                rows.furnitureWarnings = M.appendTextLine(rows.furnitureWarnings, detail)
            end
        end
    end
    applyNormalPlayStatus(rows, data)
    local reason = tostring(data.sleepSafetyReason or "")
    if reason == "" or reason == "nil" then return end
    local detail = M.readableReasonLabel(reason)
    local override = data.manualOverride == true or data.testingOverride == true or data.sleepSafetyOverrideReason ~= nil
    local rowKey = "furnitureBlockers"
    local existing = tostring(override and rows[rowKey] or rows[rowKey] or "")
    local furnitureExisting = tostring(rows.furnitureWarnings or "") .. "\n" .. tostring(rows.furnitureBlockers or "")
    if detail ~= "" and furnitureExisting:find(detail, 1, true) then
        return
    end
    if detail ~= "" and existing:find(detail, 1, true) then
        return
    end
    rows[rowKey] = M.appendTextLine(rows[rowKey], detail)
    local overrideReason = tostring(data.sleepSafetyOverrideReason or "")
    if overrideReason ~= "" and overrideReason ~= "nil" and overrideReason ~= reason then
        local overrideDetail = M.readableReasonLabel(overrideReason)
        if overrideDetail ~= "" and not tostring(rows[rowKey] or ""):find(overrideDetail, 1, true) then
            rows[rowKey] = M.appendTextLine(rows[rowKey], overrideDetail)
        end
    end
end

function M.applyAccessDetails(rows, data)
    if not (rows and data and data.interactionType == "sleeping") then return end
    local reason = tostring(data.sleepAccessOverrideReason or "")
    if reason == "" or reason == "nil" then return end
    local detail = M.readableReasonLabel(reason)
    if detail == "" then return end
    rows.furnitureWarnings = appendTextLines(rows.furnitureWarnings, detail)
    applyNormalPlayStatus(rows, data)
end

function M.applyReleaseSafetyDetails(rows, data)
    if not (rows and data) then return end
    rows.safetyGate = withoutNormalPlayStatus(rows.safetyGate)
    if data.releaseSafetyGateReason == nil and data.releaseSafetyGateLabel == nil then return end
    local detail = tostring(data.releaseSafetyGateLabel or "")
    if detail == "" or detail == "nil" then
        detail = M.readableReasonLabel(tostring(data.releaseSafetyGateReason or "unverified_location_gate"))
    end
    if detail == "" then return end
    rows.safetyGate = appendTextLines(rows.safetyGate, detail)
    applyNormalPlayStatus(rows, data)
end

function M.payloadHasSafetyOrBlockerDetails(data)
    if not data then return false end
    return data.surfaceBlockerReason ~= nil
        or data.surfaceBlockerObjectId ~= nil
        or data.surfaceBlockerOverrideReason ~= nil
        or data.sleepSafetyReason ~= nil
        or data.sleepSafetyOverrideReason ~= nil
        or data.sleepCalibrationWarningReason ~= nil
        or data.sleepAccessOverrideReason ~= nil
        or data.softBlockerReason ~= nil
        or data.hardBlockerReason ~= nil
        or data.rejectionReason ~= nil
        or data.testingOverrideReason ~= nil
        or data.manualOverrideReason ~= nil
        or data.tableClearanceFocusCleared ~= nil
        or data.tableClearanceFocusClearReason ~= nil
        or data.facingObjectId ~= nil
        or data.ignoredFacingObjectId ~= nil
end

function M.payloadHasScaleDetails(data)
    if not data then return false end
    return data.actorScale ~= nil or data.objectScale ~= nil or data.facingObjectScale ~= nil or data.ignoredFacingObjectScale ~= nil
end

function M.preserveStableRows(rows, previousRows, options)
    if not (rows and previousRows) then return end
    options = options or {}
    if options.preserveTargetDetails == true then
        for _, key in ipairs({
            "cell",
            "actor",
            "actorPose",
            "actorStatus",
            "actorDetail",
            "focus",
            "focusScale",
            "focusDetail",
            "focusWarnings",
            "focusCandidates",
            "furniture",
            "furnitureDetail",
            "furnitureSource",
            "furnitureModel",
            "slot",
            "type",
            "profile",
            "pose",
        }) do
            if tostring(rows[key] or "") == "" then rows[key] = previousRows[key] or "" end
        end
    end
    if options.preserveScales == true then
        if tostring(rows.actorScale or "") == "" then rows.actorScale = previousRows.actorScale or "" end
        if tostring(rows.furnitureScale or "") == "" then rows.furnitureScale = previousRows.furnitureScale or "" end
        if tostring(rows.focusScale or "") == "" then rows.focusScale = previousRows.focusScale or "" end
    end
    if options.preserveSafety == true then
        for _, key in ipairs({ "detected", "blockers", "overrides", "rejections", "normalPlay", "safetyGate", "warnings", "actorWarnings", "actorBlockers", "furnitureWarnings", "furnitureBlockers", "focusWarnings", "profileWarnings", "profileBlockers", "genericWarnings", "genericBlockers" }) do
            if tostring(rows[key] or "") == "" then
                rows[key] = previousRows[key] or ""
                if key == "safetyGate" then rows[key] = withoutNormalPlayStatus(rows[key]) end
            end
        end
    end
end

function M.cloneRows(rows)
    local copy = M.blankRows()
    for key, value in pairs(rows or {}) do copy[key] = value end
    return copy
end

return M
