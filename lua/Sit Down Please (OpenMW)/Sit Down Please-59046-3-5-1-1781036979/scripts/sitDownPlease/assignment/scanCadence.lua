---@omw-context none

local M = {}

local EXTERIOR_ENTRY_DELAY_SECONDS = 8.0
local EXTERIOR_AMBIENT_SECONDS = 160
local EXTERIOR_SLEEP_SECONDS = 95
local EXTERIOR_ACTOR_RADIUS = 1250
local EXTERIOR_FURNITURE_RADIUS = 700
local EXTERIOR_FOCUS_RADIUS = 860
local EXTERIOR_MAX_NPCS = 8
local EXTERIOR_MAX_ASSIGNMENTS = 2
local EXTERIOR_INITIAL_MAX_ASSIGNMENTS = 1

function M.sleepPrioritySeconds()
    return 20
end

function M.sleepPriorityGameHours()
    return 0.10
end

local function hashText(value)
    value = tostring(value or "")
    local hash = 0
    for i = 1, #value do
        hash = (hash * 33 + string.byte(value, i)) % 2147483647
    end
    return hash
end

function M.periodicSleepPriorityMaxAssignments(source, currentHour)
    local hourBucket = math.floor((tonumber(currentHour) or 0) * 10)
    return 1 + (hashText(tostring(source or "periodic_sleep_priority") .. "|" .. tostring(hourBucket)) % 3)
end

local function cellIsExterior(cell)
    if not cell then return false end
    if cell.isExterior ~= nil then return cell.isExterior == true end
    return cell.hasSky == true
end

local function flatDistance(a, b)
    if not (a and b) then return nil end
    local dx = (a.x or 0) - (b.x or 0)
    local dy = (a.y or 0) - (b.y or 0)
    return math.sqrt(dx * dx + dy * dy)
end

local function actorNearReference(actor, references, radius, vertical)
    if not (actor and actor.position and references and #references > 0) then return true end
    radius = tonumber(radius) or EXTERIOR_ACTOR_RADIUS
    vertical = tonumber(vertical) or 420
    for _, pos in ipairs(references) do
        if pos then
            local dz = math.abs((actor.position.z or 0) - (pos.z or 0))
            local dist = flatDistance(actor.position, pos)
            if dz <= vertical and dist and dist <= radius then return true end
        end
    end
    return false
end

function M.isExteriorCell(cell)
    return cellIsExterior(cell)
end

function M.exteriorCellEntryDelaySeconds()
    return EXTERIOR_ENTRY_DELAY_SECONDS
end

function M.exteriorReferences(player, npcs)
    local refs = {}
    if player and player.position then refs[#refs + 1] = player.position end
    for _, npc in ipairs(npcs or {}) do
        if npc and npc.position and actorNearReference(npc, refs, EXTERIOR_ACTOR_RADIUS, 520) then
            refs[#refs + 1] = npc.position
            if #refs >= 12 then break end
        end
    end
    return refs
end

function M.exteriorAssignmentOptions(cell, source, player, npcs, opts)
    if not cellIsExterior(cell) then return nil end
    opts = opts or {}
    local references = opts.referencePositions or M.exteriorReferences(player, npcs)
    return {
        exteriorNearbyOnly = true,
        referencePositions = references,
        maxReferenceDistance = tonumber(opts.maxReferenceDistance) or EXTERIOR_FURNITURE_RADIUS,
        maxFocusReferenceDistance = tonumber(opts.maxFocusReferenceDistance) or EXTERIOR_FOCUS_RADIUS,
        maxActorReferenceDistance = tonumber(opts.maxActorReferenceDistance) or EXTERIOR_ACTOR_RADIUS,
        maxActorReferenceVertical = tonumber(opts.maxActorReferenceVertical) or 520,
        maxNpcs = tonumber(opts.maxNpcs) or EXTERIOR_MAX_NPCS,
        maxAssignments = tonumber(opts.maxAssignments) or EXTERIOR_MAX_ASSIGNMENTS,
        source = source,
    }
end

function M.exteriorInitialOptions(cell, source, player, npcs)
    local options = M.exteriorAssignmentOptions(cell, source, player, npcs, {
        maxNpcs = 5,
        maxAssignments = EXTERIOR_INITIAL_MAX_ASSIGNMENTS,
        maxReferenceDistance = 620,
        maxFocusReferenceDistance = 780,
    })
    if options then
        options.sleepInitialPlacementAllowed = false
        options.sittingInitialPlacementAllowed = false
        options.initialPlacement = false
        options.exteriorInitialSettle = true
    end
    return options
end

function M.exteriorPeriodicOptions(cell, source, player, npcs, kind)
    local options = M.exteriorAssignmentOptions(cell, source, player, npcs, {
        maxNpcs = kind == "sleep" and 6 or 8,
        maxAssignments = kind == "sleep" and 1 or EXTERIOR_MAX_ASSIGNMENTS,
        maxReferenceDistance = kind == "sleep" and 680 or EXTERIOR_FURNITURE_RADIUS,
        maxFocusReferenceDistance = EXTERIOR_FOCUS_RADIUS,
    })
    if options then
        options.sleepInitialPlacementAllowed = false
        options.sittingInitialPlacementAllowed = false
        options.initialPlacement = false
        options.exteriorPeriodic = true
    end
    return options
end

function M.exteriorAmbientSeconds()
    return EXTERIOR_AMBIENT_SECONDS
end

function M.exteriorSleepPrioritySeconds()
    return EXTERIOR_SLEEP_SECONDS
end

function M.actorWithinExteriorPolicy(actor, options)
    if not (options and options.exteriorNearbyOnly == true) then return true end
    return actorNearReference(actor, options.referencePositions, options.maxActorReferenceDistance, options.maxActorReferenceVertical)
end

function M.objectWithinExteriorPolicy(obj, options, padding)
    if not (options and options.exteriorNearbyOnly == true) then return true end
    if not (obj and obj.position) then return false end
    local references = options.referencePositions
    if not references or #references == 0 then return false end
    local radius = (tonumber(options.maxReferenceDistance) or EXTERIOR_FURNITURE_RADIUS) + (tonumber(padding) or 0)
    local vertical = tonumber(options.maxReferenceVertical) or 520
    for _, pos in ipairs(references) do
        if pos then
            local dz = math.abs((obj.position.z or 0) - (pos.z or 0))
            local dist = flatDistance(obj.position, pos)
            if dz <= vertical and dist and dist <= radius then return true end
        end
    end
    return false
end

function M.focusObjectWithinExteriorPolicy(obj, options)
    if not (options and options.exteriorNearbyOnly == true) then return true end
    local saved = options.maxReferenceDistance
    options.maxReferenceDistance = tonumber(options.maxFocusReferenceDistance) or EXTERIOR_FOCUS_RADIUS
    local ok = M.objectWithinExteriorPolicy(obj, options, 0)
    options.maxReferenceDistance = saved
    return ok
end

return M
