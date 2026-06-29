---@omw-context none
-- HUDMarkers-only calibration diagnostics for seated/sleeping actors with
-- calibration-visible placement blockers.

local M = {}

local MOD_MARKER_KEY = "SitDownPleaseCalibrationBlockers"
local UPDATE_INTERVAL_SECONDS = 0.4

local ICONS = {
    surface = "textures/sitdownplease/diagnostics/surface_blocker_icon.png",
    clearance = "textures/sitdownplease/diagnostics/clearance_icon.png",
    stand_exit = "textures/sitdownplease/diagnostics/stand_exit_icon.png",
}

local function debugLog(env, ...)
    if env and env.debugLog then env.debugLog(...) end
end

local function now(env)
    if env and env.realTime then return env.realTime() end
    local core = env and env.core or nil
    if core and core.getRealTime then return core.getRealTime() end
    if core and core.getSimulationTime then return core.getSimulationTime() end
    return 0
end

local function actorId(actor)
    if not actor then return nil end
    return actor.id
end

local function actorIsValid(actor)
    if not actor then return false end
    if actor.isValid then
        local ok, valid = pcall(function() return actor:isValid() end)
        if ok then return valid == true end
    end
    return actor.id ~= nil
end

local function actorCell(actor)
    local ok, cell = pcall(function() return actor and actor.cell or nil end)
    if ok then return cell end
    return nil
end

local function actorScale(actor)
    local ok, scale = pcall(function() return actor and actor.scale or nil end)
    if ok and type(scale) == "number" and scale > 0 then return scale end
    return 1
end

local function actorHeight(env, actor)
    local types = env and env.types or nil
    if types and types.NPC and types.NPC.record and types.NPC.races and types.NPC.races.record then
        local okRecord, record = pcall(types.NPC.record, actor and actor.recordId)
        if okRecord and record and record.race then
            local okRace, race = pcall(types.NPC.races.record, record.race)
            local heights = okRace and race and race.height or nil
            local h = heights and (record.isMale and heights.male or heights.female) or nil
            if type(h) == "number" and h > 0 then
                return h * 135 * actorScale(actor)
            end
        end
    end
    return 135 * actorScale(actor)
end

local function markerWorldPosition(env, actor)
    local util = assert(env.util, "ui.blockerMarkers requires util")
    if not (actor and actor.position) then return nil end
    return actor.position + util.vector3(0, 0, actorHeight(env, actor) * 0.55)
end

local function collisionMask(nearby)
    local c = nearby and nearby.COLLISION_TYPE or nil
    if not c then return nil end
    local mask = c.World or 0
    if c.Door then mask = mask + c.Door end
    if c.VisualOnly then mask = mask + c.VisualOnly end
    if c.Camera then mask = mask + c.Camera end
    return mask
end

local function visibleFromCamera(env, actor)
    local camera = env and env.camera or nil
    local nearby = env and env.nearby or nil
    if not (camera and nearby and nearby.castRay) then return true end

    local target = markerWorldPosition(env, actor)
    if not target then return false end

    local player = env.player
    if type(player) == "function" then player = player() end
    if player and actorCell(player) and actorCell(actor) and actorCell(player) ~= actorCell(actor) then
        return false
    end

    if camera.worldToViewportVector then
        local okViewport, viewport = pcall(camera.worldToViewportVector, target)
        if okViewport and viewport and (viewport.z or 0) <= 0 then return false end
    end

    if not (camera.getPosition and nearby.COLLISION_TYPE) then return true end
    local okCamera, cameraPos = pcall(camera.getPosition)
    if not (okCamera and cameraPos) then return true end

    local options = {
        collisionType = collisionMask(nearby) or nearby.COLLISION_TYPE.World,
        radius = 0,
    }
    if player then options.ignore = player end
    local okRay, ray = pcall(nearby.castRay, cameraPos, target, options)
    if okRay and ray and ray.hit == true then return false end
    return true
end

local function normalizeKind(kind)
    kind = tostring(kind or ""):lower()
    if kind == "surface" or kind == "clearance" or kind == "stand_exit" then return kind end
    return nil
end

local function entryKey(actorKey, kind)
    if not (actorKey and kind) then return nil end
    return tostring(actorKey) .. "::" .. tostring(kind)
end

local function hudMarkers(env)
    local interfaces = env and (env.interfaces or env.I) or nil
    local hud = interfaces and interfaces.HUDMarkers or nil
    if hud and hud.setMarkers then return hud end
    return nil
end

local function markerParams(env, entry)
    local util = assert(env.util, "ui.blockerMarkers requires util")
    local kind = entry.kind
    local xOffsets = {
        surface = -12,
        stand_exit = 0,
        clearance = 12,
    }
    local xOffset = xOffsets[kind] or 0
    return {
        object = entry.actor,
        icon = ICONS[kind],
        scale = 0.78,
        raytracing = true,
        range = 60,
        opacity = 0.92,
        offsetMult = 0.55,
        offset = util.vector3(0, 0, 0),
        screenOffset = util.vector2(xOffset, 6),
        bonusSize = 6,
        color = { 1, 1, 1 },
    }
end

function M.create(env)
    env = env or {}
    assert(env.util, "ui.blockerMarkers requires util")

    local state = {
        active = false,
        entries = {},
        nextUpdateAt = 0,
        loggedUnavailable = false,
    }

    local controller = {}

    local function apply()
        local hud = hudMarkers(env)
        if not hud then
            if state.active == true and state.loggedUnavailable ~= true then
                state.loggedUnavailable = true
                debugLog(env, "calibration blocker markers unavailable", "HUDMarkers interface missing")
            end
            return false
        end

        state.loggedUnavailable = false
        local t = now(env)
        local markers = {}
        for key, entry in pairs(state.entries) do
            if not actorIsValid(entry.actor) then
                state.entries[key] = nil
            elseif state.active == true and visibleFromCamera(env, entry.actor) then
                markers[#markers + 1] = markerParams(env, entry)
            end
        end

        local ok, err = pcall(function()
            hud.setMarkers(MOD_MARKER_KEY, markers)
        end)
        if not ok then
            debugLog(env, "calibration blocker marker sync failed", tostring(err))
            return false
        end
        return true
    end

    function controller.clearAll(reason)
        state.entries = {}
        state.nextUpdateAt = 0
        local hud = hudMarkers(env)
        if hud then
            local ok, err = pcall(function()
                hud.setMarkers(MOD_MARKER_KEY, {})
            end)
            if not ok then
                debugLog(env, "calibration blocker marker clear failed", tostring(reason or "clear"), tostring(err))
            end
        end
    end

    function controller.setActive(value, reason)
        local active = value == true
        if state.active == active then return end
        state.active = active
        if active then
            apply()
        else
            controller.clearAll(reason or "inactive")
        end
    end

    function controller.show(data)
        if state.active ~= true then return false end
        local actor = data and (data.actor or data.npc) or nil
        local key = data and data.actorId or actorId(actor)
        local kind = normalizeKind(data and data.kind)
        if not (key and kind and actorIsValid(actor)) then return false end
        state.entries[entryKey(key, kind)] = {
            actor = actor,
            actorId = tostring(key),
            recordId = data.recordId,
            kind = kind,
            reason = data.reason or data.rejectionReason,
            lastSeenAt = now(env),
        }
        return apply()
    end

    function controller.clearActor(data)
        local actor = data and (data.actor or data.npc) or nil
        local key = data and data.actorId or actorId(actor)
        if not key then return false end
        local prefix = tostring(key) .. "::"
        local cleared = false
        for entryId in pairs(state.entries) do
            if tostring(entryId):sub(1, #prefix) == prefix then
                state.entries[entryId] = nil
                cleared = true
            end
        end
        if not cleared then return false end
        return apply()
    end

    function controller.update()
        if state.active ~= true then return end
        local t = now(env)
        if t < state.nextUpdateAt then return end
        state.nextUpdateAt = t + UPDATE_INTERVAL_SECONDS
        apply()
    end

    return controller
end

return M
