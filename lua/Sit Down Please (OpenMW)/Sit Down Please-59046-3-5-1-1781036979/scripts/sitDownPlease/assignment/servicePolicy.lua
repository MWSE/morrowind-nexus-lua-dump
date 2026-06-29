-- assignment/servicePolicy.lua
---@omw-context none
-- Conservative service-NPC policy shared by global assignment and local validation.

local M = {}

local function lower(value)
    return value and string.lower(tostring(value)) or ""
end

local function hourInWindow(profiles, hour, startHour, endHour)
    if profiles and type(profiles.isHourInWindow) == "function" then
        return profiles.isHourInWindow(hour, startHour, endHour)
    end
    hour = tonumber(hour)
    startHour = tonumber(startHour)
    endHour = tonumber(endHour)
    if hour == nil or startHour == nil or endHour == nil then return false end
    if startHour == endHour then return true end
    if startHour < endHour then return hour >= startHour and hour < endHour end
    return hour >= startHour or hour < endHour
end

function M.record(npc, typesApi)
    if not (npc and npc.recordId and typesApi and typesApi.NPC and typesApi.NPC.record) then return nil end
    local ok, rec = pcall(typesApi.NPC.record, npc.recordId)
    if ok then return rec end
    return nil
end

function M.hasTravelService(rec)
    local services = rec and rec.servicesOffered or nil
    if services and services.Travel == true then return true end
    if rec and rec.travelDestinations and #rec.travelDestinations > 0 then return true end
    return false
end

function M.isGuard(rec)
    return lower(rec and rec.class) == "guard"
end

function M.isPublican(rec)
    return lower(rec and rec.class) == "publican"
end

local function settingEnabled(settings, key, default)
    if settings and settings[key] ~= nil then return settings[key] == true end
    return default == true
end

function M.isOffHoursService(rec, isFactionLeader, settings)
    if not rec then return false end
    if M.isGuard(rec) or M.hasTravelService(rec) then return false end
    if isFactionLeader == true then
        return settingEnabled(settings, "serviceNpcOffHoursIncludeFactionLeaders", true)
    end
    if M.isPublican(rec) then
        return settingEnabled(settings, "serviceNpcOffHoursIncludePublicans", true)
    end
    local services = rec.servicesOffered
    if services and services.Barter == true and settingEnabled(settings, "serviceNpcOffHoursIncludeTraders", true) then return true end
    if services and services.Training == true and settingEnabled(settings, "serviceNpcOffHoursIncludeTrainers", true) then return true end
    return false
end

function M.offHoursEnabled(settings, profiles, currentHour)
    if settings and settings.serviceNpcOffHoursEnabled ~= true then return false end
    return hourInWindow(
        profiles,
        currentHour,
        settings and settings.serviceNpcOffHoursStartHour or 20,
        settings and settings.serviceNpcOffHoursEndHour or 8
    )
end

function M.offHoursServiceReason(npc, settings, profiles, typesApi, currentHour, isFactionLeader)
    local rec = M.record(npc, typesApi)
    return M.offHoursServiceRecordReason(rec, settings, profiles, currentHour, isFactionLeader)
end

function M.offHoursServiceRecordReason(rec, settings, profiles, currentHour, isFactionLeader)
    if not M.isOffHoursService(rec, isFactionLeader, settings) then return nil end
    if not M.offHoursEnabled(settings, profiles, currentHour) then return nil end
    return "off_hours_service_npc"
end

function M.offHoursSittingAllowed(npc, rec, settings, profiles, currentHour, isFactionLeader)
    local reason = M.offHoursServiceRecordReason(rec, settings, profiles, currentHour, isFactionLeader)
    if not reason then return false, nil end
    local chance = M.isPublican(rec)
        and (settings and settings.serviceNpcOffHoursPublicanSittingChance)
        or (settings and settings.serviceNpcOffHoursSittingChance)
    chance = tonumber(chance)
    if chance == nil then chance = M.isPublican(rec) and 0.20 or 0.45 end
    if chance <= 0 then return false, "off_hours_service_sitting_chance" end
    if chance >= 1 then return true, reason end
    local actorKey = npc and (npc.recordId or npc.id) or rec and rec.id or "<service>"
    local classKey = lower(rec and rec.class)
    local key = tostring(actorKey) .. "::" .. tostring(classKey) .. "::off_hours_service_sitting"
    local unit = profiles and profiles.stableUnitInterval and profiles.stableUnitInterval(key) or 0
    if unit <= chance then return true, reason end
    return false, "off_hours_service_sitting_chance"
end

function M.classBlockReason(rec, offHoursReason)
    if M.isGuard(rec) then return "guard_or_publican_class" end
    if M.isPublican(rec) and not offHoursReason then return "guard_or_publican_class" end
    return nil
end

function M.sittingBlockReason(rec, settings, offHoursReason, isFactionLeader)
    if not rec then return nil end
    local services = rec.servicesOffered
    if services and services.Barter == true and not offHoursReason then
        return "barter_service_npc"
    end

    if isFactionLeader == true and not offHoursReason then
        return "faction_leader"
    end

    if settings and settings.sittingAllowServiceNpcs == true then
        return nil
    end

    if services then
        if services.Travel == true then return "travel_service_npc" end
        if services.Training == true and not offHoursReason then return "training_service_npc" end
    end
    if rec.travelDestinations and #rec.travelDestinations > 0 then
        return "travel_destination_npc"
    end
    return nil
end

function M.usesNearPostSittingRule(rec)
    if not rec then return false end
    local services = rec.servicesOffered
    if services and (services.Travel == true or services.Training == true) then return true end
    if rec.travelDestinations and #rec.travelDestinations > 0 then return true end
    return false
end

function M.offHoursReleaseReason(npc, data, settings, profiles, typesApi, currentHour, isFactionLeader)
    if not (data and data.offHoursServiceNpc == true) then return nil end
    if M.offHoursServiceReason(npc, settings, profiles, typesApi, currentHour, isFactionLeader) then return nil end
    return "off_hours_service_window_ended"
end

function M.nonSittingServiceBlockReason(rec)
    if not rec then return nil end
    local services = rec.servicesOffered
    if not services then return nil end
    if services.Travel == true then return "travel_service_npc" end
    if services.Barter == true then return "barter_service_npc" end
    if services.Training == true then return "training_service_npc" end
    return nil
end

function M.isServiceOrFixedPost(rec)
    if not rec then return true end
    if M.isGuard(rec) or M.isPublican(rec) then return true end
    local services = rec.servicesOffered
    if services and (services.Barter == true or services.Travel == true or services.Training == true) then return true end
    if rec.travelDestinations and #rec.travelDestinations > 0 then return true end
    return false
end

return M
