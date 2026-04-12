local world = require("openmw.world")
local util  = require("openmw.util")

math.randomseed(os.time())

------------------------------------------------------------
-- DEBUG
------------------------------------------------------------
local DEBUG = false
local function dprint(...)
    if not DEBUG then return end
    print("[detd_birds]", ...)
end

------------------------------------------------------------
-- STATE
------------------------------------------------------------
local leadBirds   = { nil, nil, nil }
local followBirds = { nil, nil, nil }

local spawnTimer  = 0
local moveTimer   = 0
local regionTimer = 0

-- Random spawn delay between spawns
local SPAWN_DELAY_MIN = 0
local SPAWN_DELAY_MAX = 90
local spawnDelay = math.random(SPAWN_DELAY_MIN, SPAWN_DELAY_MAX)

local currentType = nil
local activeFlockType = nil
local flockDir = nil

-- Cached per-flock tuning
local cachedSpeed = 0
local cachedLiftPerSec = 0
local cachedFollowMoveThreshold = 0
local cachedMaxGap = 0

-- Orphan sweeps
local didStartupSweep = false
local orphanFarSweepTimer = 0

------------------------------------------------------------
-- FOLLOW SCALE GROW-IN
------------------------------------------------------------
local followGrowT      = { 0, 0, 0 }
local followGrowTarget = { 1.0, 1.0, 1.0 }
local followGrowStart  = 0.1
local followGrowDur    = 3.0

------------------------------------------------------------
-- GLOBAL TUNING
------------------------------------------------------------
local SPAWN_RADIUS   = 5500
local CENTER_OFFSET  = 800
local MOVE_TICK      = 0.12
local MIN_STEP       = 25

local SPAWN_HEIGHT_DEFAULT = 2000
local SPAWN_HEIGHT_RACER   = 3200

local DESPAWN_DISTANCE = 8000
local DESPAWN_DISTANCE_SQ = DESPAWN_DISTANCE * DESPAWN_DISTANCE

local CLIFFRACER_COUNT_CHANCE_3 = 0.80
local CLIFFRACER_COUNT_CHANCE_2 = 0.10

------------------------------------------------------------
-- SCALE SETTINGS
------------------------------------------------------------
local LEAD_SCALE_CLIFFRACER   = 0.2
local FOLLOW_SCALE_CLIFFRACER = 1

local LEAD_SCALE_SPARROW      = 1.0
local FOLLOW_SCALE_SPARROW    = 1.0

local LEAD_SCALE_SEAGULL      = 0.7
local FOLLOW_SCALE_SEAGULL    = 0.5

local LEAD_SCALE_GOLDFINCH    = 0.7
local FOLLOW_SCALE_GOLDFINCH  = 0.5

------------------------------------------------------------
-- MOVEMENT TUNING
------------------------------------------------------------
local LEAD_SPEED_DEFAULT_PER_SEC    = 900
local LEAD_SPEED_CLIFFRACER_PER_SEC = 1200

local LIFT_DEFAULT_PER_SEC    = 260
local LIFT_CLIFFRACER_PER_SEC = 860

local FOLLOW_MOVE_THRESHOLD_DEFAULT    = 900
local FOLLOW_MOVE_THRESHOLD_CLIFFRACER = 900

local MAX_GAP_DEFAULT    = 1200
local MAX_GAP_CLIFFRACER = 1200

------------------------------------------------------------
-- ORPHAN CLEANUP SETTINGS
------------------------------------------------------------
local ORPHAN_FAR_SWEEP_INTERVAL = 1.0

------------------------------------------------------------
-- LOCALIZED GLOBALS
------------------------------------------------------------
local random = math.random
local cos = math.cos
local sin = math.sin
local pi = math.pi
local max = math.max
local min = math.min

------------------------------------------------------------
-- BIRD RECORD IDS
------------------------------------------------------------
local BIRD_RECORD_ID = {
    detd_racer_lead1=true, detd_racer_lead2=true, detd_racer_lead3=true,
    detd_racer_follow1=true, detd_racer_follow2=true, detd_racer_follow3=true,

    detd_sparrow_lead1=true, detd_sparrow_lead2=true, detd_sparrow_lead3=true,
    detd_sparrow_follow1=true, detd_sparrow_follow2=true, detd_sparrow_follow3=true,

    detd_seagull_lead1=true, detd_seagull_lead2=true, detd_seagull_lead3=true,
    detd_seagull_follow1=true, detd_seagull_follow2=true, detd_seagull_follow3=true,

    detd_goldfinch_lead1=true, detd_goldfinch_lead2=true, detd_goldfinch_lead3=true,
    detd_goldfinch_follow1=true, detd_goldfinch_follow2=true, detd_goldfinch_follow3=true,
}

------------------------------------------------------------
-- CLEANUP QUEUE
-- Removal order:
-- follow3, lead3, follow2, lead2, follow1, lead1
------------------------------------------------------------
local cleanupActive = false
local cleanupQueue = {}
local cleanupHead = 1
local cleanupCount = 0
local cleanupTimer = 0
local CLEANUP_TICK = 0.05

------------------------------------------------------------
-- BASIC HELPERS
------------------------------------------------------------
local function isValid(obj)
    return obj and obj:isValid()
end

local function safeRemove(obj, label)
    if not isValid(obj) then return end

    local ok, err = pcall(function()
        obj:remove(1)
    end)

    if not ok then
        if type(err) == "string" and err:find("Can't remove") then return end
        if type(err) == "string" and (err:find("removed") or err:find("invalid")) then return end
        dprint("REMOVE FAILED for", label, "err=", err)
    end
end

local function safeTeleport(obj, cell, pos)
    if not isValid(obj) then return false end

    local ok, err = pcall(function()
        obj:teleport(cell, pos)
    end)

    if not ok then
        if type(err) == "string" and err:find("already in the process of teleporting") then return false end
        if type(err) == "string" and err:find("removed") then return false end
        dprint("TELEPORT FAILED err=", err)
        return false
    end

    return true
end

local function clearIndex(i)
    leadBirds[i] = nil
    followBirds[i] = nil
    followGrowT[i] = 0
    followGrowTarget[i] = 1.0
end

local function anyBirdAlive()
    for i = 1, 3 do
        if isValid(leadBirds[i]) or isValid(followBirds[i]) then
            return true
        end
    end
    return false
end

local function isTrackedBird(actor)
    for i = 1, 3 do
        if actor == leadBirds[i] or actor == followBirds[i] then
            return true
        end
    end
    return false
end

------------------------------------------------------------
-- SPAWN COUNT / SPACING
------------------------------------------------------------
local function pickSpawnCount(birdType)
    if birdType ~= "cliffracer" then
        return random(1, 3)
    end

    local r = random()
    if r < CLIFFRACER_COUNT_CHANCE_3 then
        return 3
    elseif r < (CLIFFRACER_COUNT_CHANCE_3 + CLIFFRACER_COUNT_CHANCE_2) then
        return 2
    else
        return 1
    end
end

local function getSpacing(birdType)
    if birdType == "cliffracer" then
        return 1000, 800
    elseif birdType == "sparrow" then
        return 350, 150
    else
        return 600, 300
    end
end

local function getMinSpawnDistance(birdType)
    if birdType == "cliffracer" then
        return 4000
    elseif birdType == "sparrow" then
        return 2220
    elseif birdType == "goldfinch" then
        return 2250
    else
        return 350
    end
end

local function isFarEnoughFromOthers(pos, placedPositions, minDist)
    local minDistSq = minDist * minDist

    for _, otherPos in ipairs(placedPositions) do
        local dx = pos.x - otherPos.x
        local dy = pos.y - otherPos.y
        local dz = pos.z - otherPos.z
        local distSq = dx * dx + dy * dy + dz * dz

        if distSq < minDistSq then
            return false
        end
    end

    return true
end

------------------------------------------------------------
-- SCALE LOOKUP
------------------------------------------------------------
local function getLeadScaleForType(t)
    if t == "cliffracer" then return LEAD_SCALE_CLIFFRACER end
    if t == "sparrow" then return LEAD_SCALE_SPARROW end
    if t == "seagull" then return LEAD_SCALE_SEAGULL end
    if t == "goldfinch" then return LEAD_SCALE_GOLDFINCH end
    return 1.0
end

local function getFollowScaleForType(t)
    if t == "cliffracer" then return FOLLOW_SCALE_CLIFFRACER end
    if t == "sparrow" then return FOLLOW_SCALE_SPARROW end
    if t == "seagull" then return FOLLOW_SCALE_SEAGULL end
    if t == "goldfinch" then return FOLLOW_SCALE_GOLDFINCH end
    return 1.0
end

------------------------------------------------------------
-- FLOCK TUNING CACHE
------------------------------------------------------------
local function cacheFlockTuning(actualType)
    local isCliff = (actualType == "cliffracer")
    cachedSpeed = isCliff and LEAD_SPEED_CLIFFRACER_PER_SEC or LEAD_SPEED_DEFAULT_PER_SEC
    cachedLiftPerSec = isCliff and LIFT_CLIFFRACER_PER_SEC or LIFT_DEFAULT_PER_SEC
    cachedFollowMoveThreshold = isCliff and FOLLOW_MOVE_THRESHOLD_CLIFFRACER or FOLLOW_MOVE_THRESHOLD_DEFAULT
    cachedMaxGap = isCliff and MAX_GAP_CLIFFRACER or MAX_GAP_DEFAULT
end

------------------------------------------------------------
-- ORPHAN SWEEPS
------------------------------------------------------------
local function sweepOrphanBirdsInPlayerCellImmediate(player, reason)
    local cell = player.cell
    if not cell or not cell.isExterior then return end

    local removed = 0
    for _, actor in ipairs(world.activeActors) do
        if isValid(actor) and actor.cell == cell and not isTrackedBird(actor) then
            local rid = actor.recordId
            if rid and BIRD_RECORD_ID[rid] then
                safeRemove(actor, "orphanCellNow:" .. rid)
                removed = removed + 1
            end
        end
    end

    if removed > 0 then
        dprint("Immediate cell orphan sweep removed", removed, "birds. Reason:", reason or "?")
    end
end

local function sweepOrphanBirdsFarFromPlayer(player, reason)
    local cell = player.cell
    if not cell or not cell.isExterior then return end

    local p = player.position
    local px, py, pz = p.x, p.y, p.z
    local removed = 0

    for _, actor in ipairs(world.activeActors) do
        if isValid(actor) and not isTrackedBird(actor) then
            local rid = actor.recordId
            if rid and BIRD_RECORD_ID[rid] then
                local ap = actor.position
                local dx = ap.x - px
                local dy = ap.y - py
                local dz = ap.z - pz
                local d2 = dx*dx + dy*dy + dz*dz
                if d2 > DESPAWN_DISTANCE_SQ then
                    safeRemove(actor, "orphanFar:" .. rid)
                    removed = removed + 1
                end
            end
        end
    end

    if removed > 0 then
        dprint("Far orphan sweep removed", removed, "birds. Reason:", reason or "?")
    end
end

------------------------------------------------------------
-- FOLLOW GROW UPDATE
------------------------------------------------------------
local function updateFollowGrow(dt)
    for i = 1, 3 do
        local follow = followBirds[i]
        if isValid(follow) and followGrowT[i] < followGrowDur then
            followGrowT[i] = followGrowT[i] + dt
            local a = followGrowT[i] / followGrowDur
            if a > 1 then a = 1 end

            local target = followGrowTarget[i] or 1.0
            local s = followGrowStart + (target - followGrowStart) * a
            pcall(function()
                follow:setScale(s)
            end)
        end
    end
end

------------------------------------------------------------
-- CLEANUP
------------------------------------------------------------
local function enqueueIfValid(obj, label)
    if isValid(obj) then
        cleanupQueue[#cleanupQueue + 1] = { obj = obj, label = label }
    end
end

local function destroyAllBirds(reason)
    if cleanupActive then return end

    cleanupActive = true
    cleanupQueue = {}
    cleanupTimer = 0

    if reason then
        dprint("DestroyAllBirds:", reason)
    end

    enqueueIfValid(followBirds[3], "follow3")
    enqueueIfValid(leadBirds[3],   "lead3")
    enqueueIfValid(followBirds[2], "follow2")
    enqueueIfValid(leadBirds[2],   "lead2")
    enqueueIfValid(followBirds[1], "follow1")
    enqueueIfValid(leadBirds[1],   "lead1")

    for i = 1, 3 do
        clearIndex(i)
    end

    flockDir = nil
    activeFlockType = nil

    cleanupHead = 1
    cleanupCount = #cleanupQueue

    if cleanupCount == 0 then
        cleanupActive = false
        cleanupQueue = {}
    end
end

local function processCleanup(dt)
    if not cleanupActive then return end

    cleanupTimer = cleanupTimer + dt
    if cleanupTimer < CLEANUP_TICK then return end
    cleanupTimer = 0

    local entry = cleanupQueue[cleanupHead]
    cleanupQueue[cleanupHead] = nil
    cleanupHead = cleanupHead + 1

    if entry and entry.obj then
        safeRemove(entry.obj, entry.label or "?")
    end

    if cleanupHead > cleanupCount then
        cleanupActive = false
        cleanupQueue = {}
        cleanupHead = 1
        cleanupCount = 0
    end
end

------------------------------------------------------------
-- REGION TYPE
------------------------------------------------------------
local function getRegionType(player)
    if not player.cell.isExterior then return nil end

    local p = player.position
    local px = p.x
    local py = p.y

    local cliffracer = false
    local seagull = true

    if px >= -989.355713 and px <= 64091.140625 and py >= -23874.673828 and py <= 206294.796875 then
        cliffracer = true
        seagull = false
    elseif px >= -98444.968750 and px <= 964.699036 and py >= -238617.343750 and py <= -186779.562500 then
        cliffracer = true
        seagull = false
    elseif px >= -42184.324219 and px <= 2042.064819 and py >= 44187.960938 and py <= 152449.875000 then
        cliffracer = true
        seagull = false
    elseif px >= 61366.933594 and px <= 180772.734375 and py >= -110273.000000 and py <= 89886.296875 then
        cliffracer = true
        seagull = false
    end

    if cliffracer then return "cliffracer" end
    if seagull then return "seagull" end
    return nil
end

------------------------------------------------------------
-- SPAWN DIRECTION / LEAD POSITION
-- Cliff racers fly straight toward the player area.
-- Other birds keep the sideways offset path.
------------------------------------------------------------
local function getLeadSpawn(player, birdType)
    local center = player.position
    local angle = random() * pi * 2

    local spawnHeight = (birdType == "cliffracer") and SPAWN_HEIGHT_RACER or SPAWN_HEIGHT_DEFAULT

    local x = center.x + SPAWN_RADIUS * cos(angle)
    local y = center.y + SPAWN_RADIUS * sin(angle)
    local z = center.z + spawnHeight

    local spawnPos = util.vector3(x, y, z)

    local dir
    if birdType == "cliffracer" then
        local target = util.vector3(center.x, center.y, center.z)
        dir = (target - spawnPos):normalize()
    else
        local sideAngle = angle + pi / 2
        local ox = CENTER_OFFSET * cos(sideAngle)
        local oy = CENTER_OFFSET * sin(sideAngle)
        local target = util.vector3(center.x + ox, center.y + oy, center.z)
        dir = (target - spawnPos):normalize()
    end

    return spawnPos, dir
end

------------------------------------------------------------
-- BIRD ID LOOKUP
------------------------------------------------------------
local function getBirdIds(birdType)
    if birdType == "cliffracer" then
        return { "detd_racer_lead1","detd_racer_lead2","detd_racer_lead3" },
               { "detd_racer_follow1","detd_racer_follow2","detd_racer_follow3" }
    elseif birdType == "sparrow" then
        return { "detd_sparrow_lead1","detd_sparrow_lead2","detd_sparrow_lead3" },
               { "detd_sparrow_follow1","detd_sparrow_follow2","detd_sparrow_follow3" }
    elseif birdType == "goldfinch" then
        return { "detd_goldfinch_lead1","detd_goldfinch_lead2","detd_goldfinch_lead3" },
               { "detd_goldfinch_follow1","detd_goldfinch_follow2","detd_goldfinch_follow3" }
    else
        return { "detd_seagull_lead1","detd_seagull_lead2","detd_seagull_lead3" },
               { "detd_seagull_follow1","detd_seagull_follow2","detd_seagull_follow3" }
    end
end

------------------------------------------------------------
-- SEAGULL VARIANT PICKER
------------------------------------------------------------
local GOLDFINCH_TEST_CHANCE = 0.50

local function pickSeagullVariant()
    if random() < GOLDFINCH_TEST_CHANCE then
        return "goldfinch"
    end
    return "seagull"
end

------------------------------------------------------------
-- SPAWNING
------------------------------------------------------------
local function spawnPair(playerCell, pos, leadId, followId, index)
    local lead = world.createObject(leadId, 1)
    safeTeleport(lead, playerCell, pos)
    pcall(function()
        lead:setScale(getLeadScaleForType(activeFlockType))
    end)

    local follow = world.createObject(followId, 1)
    safeTeleport(follow, playerCell, pos)

    followGrowT[index] = 0
    followGrowTarget[index] = getFollowScaleForType(activeFlockType)
    pcall(function()
        follow:setScale(followGrowStart)
    end)

    leadBirds[index]   = lead
    followBirds[index] = follow
end

local function spawnFlock(player, birdType)
    destroyAllBirds("spawning new flock")

    if cleanupActive then
        spawnTimer = 0
        return
    end

    local actualType = (birdType == "seagull") and pickSeagullVariant() or birdType
    activeFlockType = actualType
    cacheFlockTuning(actualType)

    local cell = player.cell
    local leadIds, followIds = getBirdIds(actualType)
    local spreadXY, spreadZ  = getSpacing(actualType)
    local minSpawnDistance = getMinSpawnDistance(actualType)
    local count = pickSpawnCount(actualType)

    local leadPos, dir = getLeadSpawn(player, actualType)
    flockDir = dir

    dprint("Spawning", count, actualType)

    local placedPositions = {}
    placedPositions[1] = leadPos

    spawnPair(cell, leadPos, leadIds[1], followIds[1], 1)

    for i = 2, count do
        local newPos = nil

        for attempt = 1, 20 do
            local offset = util.vector3(
                random(-spreadXY, spreadXY),
                random(-spreadXY, spreadXY),
                random(-spreadZ, spreadZ)
            )

            local candidate = leadPos + offset

            if isFarEnoughFromOthers(candidate, placedPositions, minSpawnDistance) then
                newPos = candidate
                break
            end
        end

        if not newPos then
            local offset = util.vector3(
                random(-spreadXY, spreadXY),
                random(-spreadXY, spreadXY),
                random(-spreadZ, spreadZ)
            )
            newPos = leadPos + offset
        end

        placedPositions[#placedPositions + 1] = newPos
        spawnPair(cell, newPos, leadIds[i], followIds[i], i)
    end
end

------------------------------------------------------------
-- DISTANCE DESPAWN
------------------------------------------------------------
local function checkDistanceDespawn(player)
    local p = player.position
    local px, py, pz = p.x, p.y, p.z

    for i = 1, 3 do
        local lead = leadBirds[i]
        if isValid(lead) then
            local lp = lead.position
            local dx = lp.x - px
            local dy = lp.y - py
            local dz = lp.z - pz
            if (dx*dx + dy*dy + dz*dz) > DESPAWN_DISTANCE_SQ then
                dprint("Despawn trigger: lead", i)
                destroyAllBirds("distance > " .. DESPAWN_DISTANCE)
                return true
            end
        end

        local follow = followBirds[i]
        if isValid(follow) then
            local fp = follow.position
            local dx = fp.x - px
            local dy = fp.y - py
            local dz = fp.z - pz
            if (dx*dx + dy*dy + dz*dz) > DESPAWN_DISTANCE_SQ then
                dprint("Despawn trigger: follow", i)
                destroyAllBirds("distance > " .. DESPAWN_DISTANCE)
                return true
            end
        end
    end

    return false
end

------------------------------------------------------------
-- LEAD MOVEMENT
-- Do not change the lead/follow teleport mechanic here.
------------------------------------------------------------
local function moveLeads(player, tickDt)
    if cleanupActive then return end
    if not flockDir then return end

    local cell = player.cell
    if not cell or not cell.isExterior then return end

    local speed = cachedSpeed
    local liftPerSec = cachedLiftPerSec
    local followMoveThreshold = cachedFollowMoveThreshold
    local maxGap = cachedMaxGap

    for i = 1, 3 do
        local lead = leadBirds[i]
        local follow = followBirds[i]
        if not (isValid(lead) and isValid(follow)) then goto continue end

        local lp = lead.position
        local fp = follow.position
        local dist = (lp - fp):length()

        if dist < followMoveThreshold then
            local step = speed * tickDt
            local lift = liftPerSec * tickDt

            local desired = lp + flockDir * step
            desired = util.vector3(desired.x, desired.y, desired.z + lift)

            local newGap = (desired - fp):length()
            if newGap > maxGap then
                local allowed = max(0, maxGap - dist)
                step = max(MIN_STEP, min(step, allowed))
                desired = lp + flockDir * step
                desired = util.vector3(desired.x, desired.y, desired.z + lift)
            end

            safeTeleport(lead, cell, desired)
        end

        ::continue::
    end
end

------------------------------------------------------------
-- MAIN UPDATE LOOP
------------------------------------------------------------
return {
    engineHandlers = {
        onUpdate = function(dt)
            if cleanupActive then
                processCleanup(dt)
            end

            local players = world.players
            if not players or #players == 0 then return end

            local player = players[1]
            if not player then return end

            local cell = player.cell
            if not cell or not cell.isExterior then
                if anyBirdAlive() then
                    destroyAllBirds("entered interior")
                end
                spawnTimer = 0
                orphanFarSweepTimer = 0
                return
            end

            if not didStartupSweep then
                didStartupSweep = true
                orphanFarSweepTimer = 0
                sweepOrphanBirdsInPlayerCellImmediate(player, "startup/reloadlua immediate cell sweep")
                sweepOrphanBirdsFarFromPlayer(player, "startup/reloadlua far sweep")
            end

            orphanFarSweepTimer = orphanFarSweepTimer + dt
            if orphanFarSweepTimer >= ORPHAN_FAR_SWEEP_INTERVAL then
                orphanFarSweepTimer = 0
                sweepOrphanBirdsFarFromPlayer(player, "periodic far sweep")
            end

            updateFollowGrow(dt)

            local alive = anyBirdAlive()

            regionTimer = regionTimer + dt
            if regionTimer >= 3 then
                regionTimer = 0
                local newType = getRegionType(player)
                if newType ~= currentType then
                    currentType = newType
                    dprint("Region type now:", tostring(currentType))
                    if alive then
                        destroyAllBirds("region changed")
                        alive = false
                    end
                    spawnTimer = 0
                end
            end

            if not currentType then
                if alive then
                    destroyAllBirds("no region type")
                end
                spawnTimer = 0
                return
            end

            if cleanupActive then
                spawnTimer = 0
                return
            end

            if alive then
                if checkDistanceDespawn(player) then
                    spawnTimer = 0
                    return
                end
                spawnTimer = 0
            else
                spawnTimer = spawnTimer + dt

                if spawnTimer >= spawnDelay then
                    dprint("Spawn timer reached", spawnDelay, "seconds. Attempting spawn...")

                    spawnFlock(player, currentType)

                    spawnTimer = 0
                    spawnDelay = math.random(SPAWN_DELAY_MIN, SPAWN_DELAY_MAX)
                end
            end

            moveTimer = moveTimer + dt
            if moveTimer >= MOVE_TICK and anyBirdAlive() then
                local tickDt = moveTimer
                moveTimer = 0
                moveLeads(player, tickDt)
            end
        end
    }
}