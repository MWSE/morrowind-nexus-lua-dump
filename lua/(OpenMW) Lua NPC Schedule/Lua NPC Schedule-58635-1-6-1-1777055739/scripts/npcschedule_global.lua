local core  = require('openmw.core')
local types = require('openmw.types')
local world = require('openmw.world')
local async = require('openmw.async')
local util  = require('openmw.util')

local shared          = require('scripts.npcschedule_shared')
local DEFAULTS        = shared.DEFAULTS
local EXEMPT_IDS      = shared.EXEMPT_IDS
local EXEMPT_PATTERNS = shared.EXEMPT_PATTERNS
local EXEMPT_CLASSES  = shared.EXEMPT_CLASSES
local TRAVEL_CLASSES  = shared.TRAVEL_CLASSES
local ALLOWED_ANIMS   = shared.ALLOWED_ANIMS
local CITY_CELLS      = shared.CITY_CELLS
local SAFE_KEYWORDS   = shared.SAFE_KEYWORDS
local GRID_CELLS      = shared.GRID_CELLS
local BAD_WEATHER     = shared.BAD_WEATHER
local EXEMPT_MODS     = shared.EXEMPT_MODS
local SCRIPT_WHITELIST = shared.SCRIPT_WHITELIST
local QUEST_EXCEPTIONS = shared.QUEST_EXCEPTIONS
local LOCK_EXEMPT_DOORS = shared.LOCK_EXEMPT_DOORS
local MOURNHOLD_INTERIORS = shared.MOURNHOLD_INTERIORS
local EXEMPT_SHOP_IDS = shared.EXEMPT_SHOP_IDS
local TRIBUNAL_TEMPLE_CELLS = shared.TRIBUNAL_TEMPLE_CELLS
local IMPERIAL_SHRINE_CELLS = shared.IMPERIAL_SHRINE_CELLS

local NPC      = types.NPC
local Actor    = types.Actor

local LOCAL_SCRIPT = 'scripts/npcschedule_npc.lua'
local DAY_SECONDS  = 60 * 60 * 24
local SCRIPT_VERSION = 10

-- logging
local logEnabled = false
local function log(...)
    if logEnabled then print('[NPCSchedule G]', ...) end
end

local S = {}
for k, v in pairs(DEFAULTS) do S[k] = v end

local function applySettings(data)
    if not data then return end
    for k in pairs(S) do
        if data[k] ~= nil then S[k] = data[k] end
    end
    logEnabled = S.ENABLE_LOGS
end

-- weather monitoring
local badWeatherActive = false
local hasWeatherScript = core.contentFiles.has('go-home.omwaddon')

local function getCurrentWeather()
    if not hasWeatherScript then return 0 end
    local ok, scr = pcall(world.mwscript.getGlobalScript, 'momw_gh_weather_monitor')
    if not ok or not scr then return 0 end
    return scr.variables.cur or 0
end

local function isBadWeather(w)
    return BAD_WEATHER[w] == true
end

-- managed NPC registry
local managed = {}
local displaced = {}

local safePlaceCounts = {}
local doorExitCounts  = {}
local doorSoundCooldowns = {}

local morningQueue = {}
local morningActive = false

local shopReturnQueue = {}
local shopReturnActive = false
local shopDiceRolled = {}

-- temple visit return queue + once-per-day dice flag per recordId
local templeReturnQueue = {}
local templeReturnActive = false
local templeDiceRolled = {}

-- Safe place reservation system
local safePlaceReservations = {}
local SAFE_RESERVATION_TIMEOUT = 180
local reservationCleanupTimer = 0
local RESERVATION_CLEANUP_INTERVAL = 30

local function isOutdoorCell(cell)
    if not cell then return false end
    if cell.isExterior then return true end
    local name = cell.name and cell.name:lower() or ""
    return MOURNHOLD_INTERIORS[name] == true
end

local function cleanupExpiredReservations()
    local now = os.time()
    for cellName, data in pairs(safePlaceReservations) do
        for npcId, timestamp in pairs(data.reservations) do
            if now - timestamp > SAFE_RESERVATION_TIMEOUT then
                data.reservations[npcId] = nil
                data.count = data.count - 1
                log('Reservation expired for', npcId, 'in', cellName)
            end
        end
        if data.count <= 0 then
            safePlaceReservations[cellName] = nil
        end
    end
end

local function tryReserveSafePlace(npcId, cellName)
    if not cellName or cellName == '' then return false end
    
    cleanupExpiredReservations()
    
    local lo = cellName:lower()
    local data = safePlaceReservations[lo]
    local current = data and data.count or 0
    
    if current >= S.MAX_SAFE_OCCUPANTS then
        log('Safe place FULL:', cellName, '(', current, '/', S.MAX_SAFE_OCCUPANTS, ')')
        return false
    end
    
    if not data then
        safePlaceReservations[lo] = { count = 0, reservations = {} }
        data = safePlaceReservations[lo]
    end
    
    if data.reservations[npcId] then
        return true
    end
    
    data.reservations[npcId] = os.time()
    data.count = current + 1
    log('Safe place RESERVED:', cellName, 'for', npcId, '(', data.count, '/', S.MAX_SAFE_OCCUPANTS, ')')
    return true
end

local function releaseSafePlaceReservation(npcId, cellName)
    if not cellName or cellName == '' then return end
    
    local lo = cellName:lower()
    local data = safePlaceReservations[lo]
    if not data then return end
    
    if data.reservations[npcId] then
        data.reservations[npcId] = nil
        data.count = math.max(0, data.count - 1)
        log('Safe place RELEASED:', cellName, 'for', npcId, '(', data.count, '/', S.MAX_SAFE_OCCUPANTS, ')')
        if data.count <= 0 then
            safePlaceReservations[lo] = nil
        end
    end
end

-- Door planning state
local doorPlanningActive = false
local planningComplete = false

-- doors unlocked for the night
local lockedDoors = {}

local function isDoorLockExempt(door)
    if not door or not door:isValid() then return true end
    return LOCK_EXEMPT_DOORS[door.recordId:lower()] == true
end

local function unlockDoor(door, lockLevel)
    if not S.UNLOCK_HOME_DOORS then return end
    if not door or not door:isValid() then return end
    if not lockLevel or lockLevel <= 0 then return end
    if isDoorLockExempt(door) then return end
    if lockedDoors[door.id] then return end
    lockedDoors[door.id] = { door = door, lockLevel = lockLevel }
    core.sendGlobalEvent('Unlock', { target = door })
    log('Unlocked door:', door.recordId, 'level:', lockLevel)
end

local function relockDoor(doorId)
    local info = lockedDoors[doorId]
    if not info then return end
    lockedDoors[doorId] = nil
    if info.door and info.door:isValid() then
        core.sendGlobalEvent('Lock', { target = info.door, magnitude = info.lockLevel })
        log('Relocked door:', info.door.recordId, 'level:', info.lockLevel)
    end
end

local function relockAllDoors()
    for doorId in pairs(lockedDoors) do
        relockDoor(doorId)
    end
    lockedDoors = {}
end

local function vec3T(v) return { x = v.x, y = v.y, z = v.z } end
local function tVec3(t) return t and util.vector3(t.x, t.y, t.z) or nil end

local function spreadExitPos(basePos, doorRot)
    local key = string.format('%.0f_%.0f_%.0f', basePos.x, basePos.y, basePos.z)
    local count = doorExitCounts[key] or 0
    doorExitCounts[key] = count + 1
    local forward
    if doorRot then
        local fwd = doorRot:apply(util.vector3(0, 1, 0))
        forward = util.vector3(-fwd.x, -fwd.y, 0):normalize()
    end
    if not forward then forward = util.vector3(1, 0, 0) end
    return basePos + forward * ((count + 1) * S.SAFE_SPACING)
end

local function getGameHour()
    return (core.getGameTime() % DAY_SECONDS) / 3600
end

local function isNightHour(h)
    local s, e = S.NIGHT_START, S.NIGHT_END
    if s > e then return h >= s or h < e
    else return h >= s and h < e end
end

local function isInCity(actor)
    if not S.CITY_WHITELIST then return true end
    local c = actor.cell
    if not c then return false end
    local n = c.name
    if n and n ~= '' then return CITY_CELLS[n:lower()] == true end
    if c.isExterior and GRID_CELLS then
        local key = c.gridX .. "," .. c.gridY
        return GRID_CELLS[key] == true
    end
    return false
end

local function getRec(npc)
    return NPC.record(npc)
end

local questExemptCache = nil

local function buildQuestCache()
    questExemptCache = {}
    local player = world.players[1]
    if not player then return end
    local ok, quests = pcall(player.type.quests, player)
    if not ok or not quests then return end
    for id, qe in pairs(QUEST_EXCEPTIONS) do
        local quest = quests[qe.quest]
        if quest and not quest.finished
           and quest.stage >= qe.before and quest.stage < qe.after
        then
            questExemptCache[id] = true
        end
    end
end

local function clearQuestCache()
    questExemptCache = nil
end

local serviceBlacklist = {}

-- session-long cache based on EXEMPT_IDS/PATTERNS/CLASSES/MODS/ALLOWED_ANIMS/TRAVEL_CLASSES
-- questExemptCache is checked separately
local isExemptCache = {}

local function isExempt(npc)
    local id = npc.recordId
    local cached = isExemptCache[id]
    if cached == nil then
        cached = false
        if EXEMPT_IDS[id] then
            cached = true
        else
            for _, p in ipairs(EXEMPT_PATTERNS) do
                if id:find(p, 1, true) then cached = true break end
            end
        end
        if not cached and npc.contentFile and EXEMPT_MODS[npc.contentFile:lower()] then
            cached = true
        end
        if not cached then
            local rec = getRec(npc)
            if rec then
                if rec.class then
                    local cls = rec.class:lower()
                    if EXEMPT_CLASSES[cls] then
                        cached = true
                    elseif S.EXCLUDE_TRAVEL_CLASSES and TRAVEL_CLASSES[cls] then
                        cached = true
                    end
                end
                if not cached then
                    local mws = rec.mwscript
                    if mws and not SCRIPT_WHITELIST[mws:lower()] then
                        cached = true
                        log('Exempt by mwscript:', id, 'script:', mws)
                    end
                end
                if not cached then
                    local model = (rec.model or ''):lower()
                    if not ALLOWED_ANIMS[model] then cached = true end
                end
            end
        end
        isExemptCache[id] = cached
    end
    if cached then return true end
    if questExemptCache and questExemptCache[id:lower()] then return true end
    return false
end

local function hasAnyService(actor)
    local rid = actor.recordId
    if serviceBlacklist[rid] ~= nil then return serviceBlacklist[rid] end
    local rec = getRec(actor)
    if not rec then serviceBlacklist[rid] = false return false end
    local ok, services = pcall(function() return rec.servicesOffered end)
    if not ok or not services then serviceBlacklist[rid] = false return false end
    for _, offered in pairs(services) do
        if offered == true then
            serviceBlacklist[rid] = true
            return true
        end
    end
    serviceBlacklist[rid] = false
    return false
end

local function isShopHour(h)
    return h >= S.SHOP_VISIT_START and h < S.SHOP_VISIT_END
end

-- returns "tribunal" or "imperial" or nil
local function getEligibleCult(npc)
    local getRank = types.NPC.getFactionRank

    if getRank(npc, "temple")          > 0 then return "tribunal" end
    if getRank(npc, "imperial cult")   > 0 then return "imperial" end
    if getRank(npc, "imperial legion") > 0 then return "imperial" end
    if getRank(npc, "telvanni")        > 0 then return nil        end
    if getRank(npc, "redoran")         > 0 then return "tribunal" end
    if getRank(npc, "hlaalu")          > 0 then
        -- hlaalu visit both
        return (math.random() < 0.5) and "tribunal" or "imperial"
    end

    -- factionless: dunmer -> tribunal, otherwise imperial
    local rec = types.NPC.record(npc)
    if rec and rec.race == "dark elf" then
        return "tribunal"
    end
    return "imperial"
end

local function ensureScript(npc)
    if not npc:hasScript(LOCAL_SCRIPT) then
        npc:addScript(LOCAL_SCRIPT)
    end
end

local function markDisplaced(actor, startPos, startCell, startRot, savedWander)
    displaced[actor.id] = {
        recordId    = actor.recordId,
        pos         = vec3T(startPos),
        cell        = startCell,
        yaw         = startRot:getYaw(),
        savedWander = savedWander,
    }
end

local function clearDisplaced(id)
    displaced[id] = nil
end

-- goHome batch state
-- MORNING_BATCH_SIZE / MORNING_BATCH_DELAY settings as returnAllMorning
local goHomeQueue = {}
local goHomeActive = false
local goHomeMode = 'animated'

local function sendAllHome(mode)
    -- collect targets
    local npcsToSendHome = {}
    for _, actor in ipairs(world.activeActors) do
        if actor.type == NPC
           and not managed[actor.id]
           and not isExempt(actor)
           and actor.cell and isOutdoorCell(actor.cell)
           and isInCity(actor)
        then
            local rec = getRec(actor)
            if rec and rec.name and rec.name ~= '' then
                table.insert(npcsToSendHome, actor)
            end
        end
    end

    if #npcsToSendHome == 0 then return end

    goHomeQueue = npcsToSendHome
    goHomeMode = mode
    if goHomeActive then
        -- batch already running; it will pick up new queue on next tick
        return
    end
    goHomeActive = true

    local function processNextBatch()
        if not goHomeActive or #goHomeQueue == 0 then
            goHomeActive = false
            return
        end

        local count = 0
        while #goHomeQueue > 0 and count < S.MORNING_BATCH_SIZE do
            local npc = table.remove(goHomeQueue, 1)
            if npc and npc:isValid() and not managed[npc.id] then
                ensureScript(npc)
                local delay = 0
                if goHomeMode == 'animated' then
                    delay = math.random(1, S.MAX_DELAY)
                end
                npc:sendEvent('NPCSch_InitGoHome', {
                    scanRange      = S.DOOR_SCAN_RANGE,
                    arrivalDist    = S.DOOR_ARRIVAL_DIST,
                    logEnabled     = logEnabled,
                    mode           = goHomeMode,
                    delay          = delay,
                })
            end
            count = count + 1
        end

        if #goHomeQueue > 0 then
            async:newUnsavableSimulationTimer(S.MORNING_BATCH_DELAY, processNextBatch)
        else
            goHomeActive = false
        end
    end

    processNextBatch()
end

-- instant disable remaining outdoor NPCs (player left exterior / time skip)
local function instantDisableAll()
    for id, m in pairs(managed) do
        if m.state == 'delaying' or m.state == 'walking' then
            local actor = m.actor
            if actor and actor:isValid() and not Actor.isDead(actor)
               and actor.cell and isOutdoorCell(actor.cell)
            then
                actor:sendEvent('NPCSch_InstantDisable', {})
            end
        end
    end

    for _, actor in ipairs(world.activeActors) do
        if actor.type == NPC
           and not managed[actor.id]
           and not isExempt(actor)
           and actor.cell and isOutdoorCell(actor.cell)
           and isInCity(actor)
        then
            local rec = getRec(actor)
            if rec and rec.name and rec.name ~= '' then
                ensureScript(actor)
                actor:sendEvent('NPCSch_InitGoHome', {
                    scanRange      = S.DOOR_SCAN_RANGE,
                    arrivalDist    = S.DOOR_ARRIVAL_DIST,
                    logEnabled     = logEnabled,
                    mode           = 'instant',
                })
            end
        end
    end
end

-- player entered an interior: enable disabled NPCs whose homeCellName matches
local function playerEnteredInterior(cellName)
    if not cellName or cellName == '' then return end
    local lo = cellName:lower()

    for id, m in pairs(managed) do
        if m.state ~= 'disabled' then goto cont end
        if not m.homeCellName or m.homeCellName:lower() ~= lo then goto cont end

        local actor = m.actor
        if not actor or not actor:isValid() or Actor.isDead(actor) then goto cont end

        log('Player entered home of disabled NPC:', actor.recordId, cellName)

        actor.enabled = true
        ensureScript(actor)

        -- slot assignment for safe places
        if m.isSafe then
            local count = safePlaceCounts[lo] or 0
            safePlaceCounts[lo] = count + 1

            local base = m.doorInsidePos
            if base then
                local col = count % 4
                local row = math.floor(count / 4)
                local offset = util.vector3(
                    base.x + (col - 1.5) * S.SAFE_SPACING,
                    base.y + (row - 0.5) * S.SAFE_SPACING,
                    base.z
                )
                actor:teleport(cellName, offset, m.doorInsideRot)
            else
                actor:teleport(cellName, m.doorInsidePos or util.vector3(0,0,0), m.doorInsideRot)
            end

            actor:sendEvent('NPCSch_StartSafeWander', {})
        elseif m.isShop then
            local count = safePlaceCounts[lo] or 0
            safePlaceCounts[lo] = count + 1

            local base = m.doorInsidePos
            if base then
                local col = count % 4
                local row = math.floor(count / 4)
                local offset = util.vector3(
                    base.x + (col - 1.5) * S.SAFE_SPACING,
                    base.y + (row - 0.5) * S.SAFE_SPACING,
                    base.z
                )
                actor:teleport(cellName, offset, m.doorInsideRot)
            else
                actor:teleport(cellName, m.doorInsidePos or util.vector3(0,0,0), m.doorInsideRot)
            end

            actor:sendEvent('NPCSch_StartShopWander', {})
        elseif m.isTemple then
            -- temples: use same crowd-spacing layout as shops, but safe-wander params
            local count = safePlaceCounts[lo] or 0
            safePlaceCounts[lo] = count + 1

            local base = m.doorInsidePos
            if base then
                local col = count % 4
                local row = math.floor(count / 4)
                local offset = util.vector3(
                    base.x + (col - 1.5) * S.SAFE_SPACING,
                    base.y + (row - 0.5) * S.SAFE_SPACING,
                    base.z
                )
                actor:teleport(cellName, offset, m.doorInsideRot)
            else
                actor:teleport(cellName, m.doorInsidePos or util.vector3(0,0,0), m.doorInsideRot)
            end

            actor:sendEvent('NPCSch_StartSafeWander', {})
        else
            actor:teleport(cellName, m.doorInsidePos or util.vector3(0,0,0), m.doorInsideRot)
            actor:sendEvent('NPCSch_StartHomeStand', {})
        end

        m.state = 'inside'
        log('Enabled NPC inside:', actor.recordId)

        ::cont::
    end
end

local function playDoorSound(door)
    if not S.ENABLE_DOOR_SOUNDS then return end
    if not door or not door:isValid() then return end
    local doorId = door.id
    if doorSoundCooldowns[doorId] then return end

    local doorRec = types.Door.record(door)
    if doorRec and doorRec.openSound and doorRec.openSound ~= "" then
        core.sound.playSound3d(doorRec.openSound, door)
        doorSoundCooldowns[doorId] = true
        async:newUnsavableSimulationTimer(S.DOOR_SOUND_COOLDOWN, function()
            doorSoundCooldowns[doorId] = nil
        end)
        log('Door sound played for door:', doorId)
    end
end

-- morning helper: process single NPC return
local function processMorningNPC(id, m, playerInExterior, playerCellName)
    local actor = m.actor
    if not actor or not actor:isValid() or Actor.isDead(actor) then
        managed[id] = nil
        clearDisplaced(id)
        return
    end

    if m.state == 'walking' or m.state == 'delaying' then
        actor:teleport(m.startCell, m.startPos, m.startRot)
        actor:sendEvent('NPCSch_RestoreFull', { savedWander = m.savedWander })
        managed[id] = nil
        clearDisplaced(id)
        log('Morning: returned walking NPC:', actor.recordId)
        return
    end

    if m.state == 'disabled' then
        -- NPC is disabled at door outside, enable and walk to startPos
        actor.enabled = true
        ensureScript(actor)
        local exitPos = m.doorExitPos
        if exitPos and playerInExterior then
            playDoorSound(m.doorObj)
            local spreadPos = spreadExitPos(exitPos, m.doorExitRot)
            actor:teleport(m.startCell, spreadPos, m.startRot)
            actor:sendEvent('NPCSch_WalkToStart', {
                startPos = m.startPos,
                startRot = m.startRot,
                savedWander = m.savedWander,
            })
            m.state = 'returning'
        else
            actor:teleport(m.startCell, m.startPos, m.startRot)
            actor:sendEvent('NPCSch_RestoreFull', { savedWander = m.savedWander })
            managed[id] = nil
            clearDisplaced(id)
        end
        log('Morning: re-enabled disabled NPC:', actor.recordId)
        return
    end

    if m.state == 'inside' then
        ensureScript(actor)
        if playerInExterior then
            -- player is outside: teleport NPC to exit door pos, then walk to startPos
            local exitPos = m.doorExitPos
            if exitPos then
                playDoorSound(m.doorObj)
                local spreadPos = spreadExitPos(exitPos, m.doorExitRot)
                actor:teleport(m.startCell, spreadPos, m.startRot)
                actor:sendEvent('NPCSch_WalkToStart', {
                    startPos = m.startPos,
                    startRot = m.startRot,
                    savedWander = m.savedWander,
                })
                m.state = 'returning'
            else
                actor:teleport(m.startCell, m.startPos, m.startRot)
                actor:sendEvent('NPCSch_RestoreFull', { savedWander = m.savedWander })
                managed[id] = nil
                clearDisplaced(id)
            end
        elseif playerCellName and m.homeCellName
           and playerCellName:lower() == m.homeCellName:lower()
        then
            -- player is inside THIS place: NPC walks to door, then teleport to startPos
            actor:sendEvent('NPCSch_WalkOutAndReturn', {
                startPos    = m.startPos,
                startCell   = m.startCell,
                startRot    = m.startRot,
                savedWander = m.savedWander,
            })
            m.state = 'walkingOut'
        else
            -- player is in exterior or different interior: instant teleport
            actor:teleport(m.startCell, m.startPos, m.startRot)
            actor:sendEvent('NPCSch_RestoreFull', { savedWander = m.savedWander })
            managed[id] = nil
            clearDisplaced(id)
        end
    end
end

-- morning: batched return cycle
local function returnAllMorning(playerInExterior, playerCellName)
    log('Starting morning return cycle, playerExterior:', tostring(playerInExterior))

    relockAllDoors()
    safePlaceCounts = {}
    doorExitCounts  = {}
    safePlaceReservations = {}
    morningQueue = {}
    shopReturnQueue = {}
    shopReturnActive = false
    shopDiceRolled = {}
    templeReturnQueue = {}
    templeReturnActive = false
    templeDiceRolled = {}
    goHomeQueue = {}
    goHomeActive = false

    -- reset shop visit flag on all active NPCs so they can shop again today
    for _, actor in ipairs(world.activeActors) do
        if actor.type == NPC and actor:hasScript(LOCAL_SCRIPT) then
            actor:sendEvent('NPCSch_ResetShopFlag', {})
            actor:sendEvent('NPCSch_ResetTempleFlag', {})
        end
    end

    for id, m in pairs(managed) do
        table.insert(morningQueue, id)
    end

    if #morningQueue > 0 then
        morningActive = true
        
        local function processNextBatch()
            if not morningActive or #morningQueue == 0 then 
                morningActive = false
                return 
            end

            local count = 0
            while #morningQueue > 0 and count < S.MORNING_BATCH_SIZE do
                local id = table.remove(morningQueue, 1)
                local m = managed[id]
                if m then
                    processMorningNPC(id, m, playerInExterior, playerCellName)
                end
                count = count + 1
            end

            if #morningQueue > 0 then
                async:newUnsavableSimulationTimer(S.MORNING_BATCH_DELAY, processNextBatch)
            else
                morningActive = false
            end
        end
        
        processNextBatch()
    end
end

local function hardResetAll()
    log('=== HARD RESET ===')

    relockAllDoors()

    local restored = {}

    for id, m in pairs(managed) do
        local actor = m.actor
        if actor and actor:isValid() and not Actor.isDead(actor) then
            if not actor.enabled then actor.enabled = true end
            actor:teleport(m.startCell, m.startPos, m.startRot)
            ensureScript(actor)
            actor:sendEvent('NPCSch_CancelAndRestore', {})
            if m.savedWander then
                actor:sendEvent('NPCSch_RestoreFull', { savedWander = m.savedWander })
            end
            restored[id] = true
            log('Reset managed:', actor.recordId)
        end
    end

    for id, d in pairs(displaced) do
        if not restored[id] then
            local pos = tVec3(d.pos)
            if pos then
                local found = nil
                for _, actor in ipairs(world.activeActors) do
                    if actor:isValid() and actor.recordId == d.recordId and not restored[actor.id] then
                        found = actor
                        break
                    end
                end
                if found then
                    if not found.enabled then found.enabled = true end
                    local rot = util.transform.rotateZ(d.yaw or 0)
                    found:teleport(d.cell or '', pos, rot)
                    ensureScript(found)
                    found:sendEvent('NPCSch_CancelAndRestore', {})
                    if d.savedWander then
                        found:sendEvent('NPCSch_RestoreFull', { savedWander = d.savedWander })
                    end
                    restored[found.id] = true
                    log('Reset displaced:', d.recordId)
                end
            end
        end
    end

    managed = {}
    displaced = {}
    safePlaceCounts = {}
    doorExitCounts = {}
    safePlaceReservations = {}
    morningQueue = {}
    morningActive = false
    shopReturnQueue = {}
    shopReturnActive = false
    shopDiceRolled = {}
    templeReturnQueue = {}
    templeReturnActive = false
    templeDiceRolled = {}
    goHomeQueue = {}
    goHomeActive = false
    
    log('=== HARD RESET complete ===')
end

local wasNight     = nil
local wasHome      = nil
local elapsed      = 0
local wasHardReset = false
local weatherElapsed = 0
local lastShopDay  = nil
local lastTempleDay = nil

local function onUpdate(dt)
    elapsed = elapsed + dt
    if elapsed < S.CHECK_INTERVAL then return end
    elapsed = 0

    reservationCleanupTimer = reservationCleanupTimer + S.CHECK_INTERVAL
    if reservationCleanupTimer >= RESERVATION_CLEANUP_INTERVAL then
        reservationCleanupTimer = 0
        cleanupExpiredReservations()
    end

    if S.HARD_RESET then
        if not wasHardReset then
            hardResetAll()
            wasHardReset = true
        end
        wasHome = false
        wasNight = false
        badWeatherActive = false
        return
    end
    if wasHardReset and not S.HARD_RESET then
        wasHardReset = false
    end

    -- weather check
    if S.GO_HOME_BAD_WEATHER and hasWeatherScript then
        weatherElapsed = weatherElapsed + S.CHECK_INTERVAL
        if weatherElapsed >= S.WEATHER_CHECK_INTERVAL then
            weatherElapsed = 0
            badWeatherActive = isBadWeather(getCurrentWeather())
        end
    else
        badWeatherActive = false
    end

    local hour = getGameHour()
    local isNight = isNightHour(hour)
    local shouldBeHome = isNight or badWeatherActive

    if wasHome == nil then
        wasHome = shouldBeHome
        wasNight = isNight
        if shouldBeHome then
            buildQuestCache()
            sendAllHome('animated')
        end
        return
    end

    if shouldBeHome and not wasHome then
        buildQuestCache()
        sendAllHome(timeSkipDetected and 'instant' or 'animated')
        wasHome = true
        wasNight = isNight
        return
    end

    if not shouldBeHome and wasHome then
        clearQuestCache()
        local player = world.players[1]
        local pCell = player and player.cell
        local pExterior = isOutdoorCell(pCell)
        local pCellName = pCell and pCell.name or ''
        returnAllMorning(pExterior, pCellName)
        wasHome = false
        wasNight = isNight
        return
    end

    wasNight = isNight

    if shouldBeHome then
        -- night: return shop-visiting NPCs first
        if S.ENABLE_SHOP_VISITS then
            local player = world.players[1]
            local pCell = player and player.cell
            local pExterior = isOutdoorCell(pCell)
            local pCellName = pCell and pCell.name or ''
            local shopIds = {}
            for id, m in pairs(managed) do
                if m.isShop and (m.state == 'walking' or m.state == 'delaying'
                    or m.state == 'disabled' or m.state == 'inside') then
                    shopIds[#shopIds + 1] = id
                end
            end
            for _, id in ipairs(shopIds) do
                local m = managed[id]
                if m then processMorningNPC(id, m, pExterior, pCellName) end
            end
        end

        -- night: return temple-visiting NPCs first (mirrors shop block above)
        if S.ENABLE_TEMPLE_VISITS then
            local player = world.players[1]
            local pCell = player and player.cell
            local pExterior = isOutdoorCell(pCell)
            local pCellName = pCell and pCell.name or ''
            local templeIds = {}
            for id, m in pairs(managed) do
                if m.isTemple and (m.state == 'walking' or m.state == 'delaying'
                    or m.state == 'disabled' or m.state == 'inside') then
                    templeIds[#templeIds + 1] = id
                end
            end
            for _, id in ipairs(templeIds) do
                local m = managed[id]
                if m then processMorningNPC(id, m, pExterior, pCellName) end
            end
        end

        for id, m in pairs(managed) do
            local actor = m.actor
            if actor and actor:isValid() and actor.cell and isOutdoorCell(actor.cell) then
                if m.state == nil then
                    log('Night sweep: force for', actor.recordId)
                    actor:sendEvent('NPCSch_ForceViaLOS', {})
                end
            end
        end

        for _, actor in ipairs(world.activeActors) do
            if actor.type == NPC
               and not managed[actor.id]
               and not isExempt(actor)
               and actor.cell and isOutdoorCell(actor.cell)
               and isInCity(actor)
            then
                local rec = getRec(actor)
                if rec and rec.name and rec.name ~= '' then
                    ensureScript(actor)
                    actor:sendEvent('NPCSch_InitGoHome', {
                        scanRange      = S.DOOR_SCAN_RANGE,
                        arrivalDist    = S.DOOR_ARRIVAL_DIST,
                        logEnabled     = logEnabled,
                        mode           = 'animated',
                        delay          = math.random(1, S.MAX_DELAY),
                    })
                end
            end
        end
    end

    -- SHOP_VISIT_END: return shop NPCs
    if not shouldBeHome and S.ENABLE_SHOP_VISITS and not isShopHour(hour) and not shopReturnActive then
        local shopIds = {}
        for id, m in pairs(managed) do
            if m.isShop and (m.state == 'walking' or m.state == 'delaying'
                or m.state == 'disabled' or m.state == 'inside') then
                shopIds[#shopIds + 1] = id
            end
        end
        if #shopIds > 0 then
            shopReturnQueue = shopIds
            shopReturnActive = true
            local player = world.players[1]
            local pCell = player and player.cell
            local pExterior = isOutdoorCell(pCell)
            local pCellName = pCell and pCell.name or ''

            local function processNextShopBatch()
                if not shopReturnActive or #shopReturnQueue == 0 then
                    shopReturnActive = false
                    return
                end
                local id = table.remove(shopReturnQueue, 1)
                local m = managed[id]
                if m and m.isShop then
                    processMorningNPC(id, m, pExterior, pCellName)
                end
                if #shopReturnQueue > 0 then
                    local delay = math.random(1, S.MAX_DELAY)
                    async:newUnsavableSimulationTimer(delay, processNextShopBatch)
                else
                    shopReturnActive = false
                end
            end

            processNextShopBatch()
        end
    end

    -- Temple visit end: return temple NPCs at same hour as shops (reuses SHOP_VISIT_END)
    if not shouldBeHome and S.ENABLE_TEMPLE_VISITS and not isShopHour(hour) and not templeReturnActive then
        local templeIds = {}
        for id, m in pairs(managed) do
            if m.isTemple and (m.state == 'walking' or m.state == 'delaying'
                or m.state == 'disabled' or m.state == 'inside') then
                templeIds[#templeIds + 1] = id
            end
        end
        if #templeIds > 0 then
            templeReturnQueue = templeIds
            templeReturnActive = true
            local player = world.players[1]
            local pCell = player and player.cell
            local pExterior = isOutdoorCell(pCell)
            local pCellName = pCell and pCell.name or ''

            local function processNextTempleBatch()
                if not templeReturnActive or #templeReturnQueue == 0 then
                    templeReturnActive = false
                    return
                end
                local id = table.remove(templeReturnQueue, 1)
                local m = managed[id]
                if m and m.isTemple then
                    processMorningNPC(id, m, pExterior, pCellName)
                end
                if #templeReturnQueue > 0 then
                    local delay = math.random(1, S.MAX_DELAY)
                    async:newUnsavableSimulationTimer(delay, processNextTempleBatch)
                else
                    templeReturnActive = false
                end
            end

            processNextTempleBatch()
        end
    end

    -- shop visits during daytime
    if not shouldBeHome and S.ENABLE_SHOP_VISITS and isShopHour(hour) then
        -- reset dice on new game day
        local currentDay = math.floor(core.getGameTime() / DAY_SECONDS)
        if lastShopDay ~= currentDay then
            lastShopDay = currentDay
            shopDiceRolled = {}
            for _, actor in ipairs(world.activeActors) do
                if actor.type == NPC and actor:hasScript(LOCAL_SCRIPT) then
                    actor:sendEvent('NPCSch_ResetShopFlag', {})
                end
            end
            log('New shop day:', currentDay)
        end

        for _, actor in ipairs(world.activeActors) do
            if actor.type == NPC
               and not managed[actor.id]
               and not shopDiceRolled[actor.recordId]
               and not isExempt(actor)
               and not hasAnyService(actor)
               and not EXEMPT_SHOP_IDS[actor.recordId]
               and actor.cell and isOutdoorCell(actor.cell)
               and isInCity(actor)
            then
                local rec = getRec(actor)
                if rec and rec.name and rec.name ~= '' then
                    shopDiceRolled[actor.recordId] = true
                    ensureScript(actor)
                    actor:sendEvent('NPCSch_InitShopVisit', {
                        scanRange  = S.DOOR_SCAN_RANGE,
                        arrivalDist = S.DOOR_ARRIVAL_DIST,
                        logEnabled = logEnabled,
                        shopChance = S.SHOP_VISIT_CHANCE,
                    })
                end
            end
        end
    end

    -- Temple visit roll
    if not shouldBeHome and S.ENABLE_TEMPLE_VISITS and isShopHour(hour) then
        local currentDay = math.floor(core.getGameTime() / DAY_SECONDS)
        if lastTempleDay ~= currentDay then
            lastTempleDay = currentDay
            templeDiceRolled = {}
            for _, actor in ipairs(world.activeActors) do
                if actor.type == NPC and actor:hasScript(LOCAL_SCRIPT) then
                    actor:sendEvent('NPCSch_ResetTempleFlag', {})
                end
            end
            log('New temple day:', currentDay)
        end

        for _, actor in ipairs(world.activeActors) do
            if actor.type == NPC
               and not managed[actor.id]
               and not templeDiceRolled[actor.recordId]
               and not isExempt(actor)
               and not hasAnyService(actor)
               and not EXEMPT_SHOP_IDS[actor.recordId]
               and actor.cell and isOutdoorCell(actor.cell)
               and isInCity(actor)
            then
                local rec = getRec(actor)
                if rec and rec.name and rec.name ~= '' then
                    templeDiceRolled[actor.recordId] = true

                    local cult = getEligibleCult(actor)
                    if cult then
                        ensureScript(actor)
                        actor:sendEvent('NPCSch_InitTempleVisit', {
                            cult         = cult,
                            scanRange    = S.DOOR_SCAN_RANGE,
                            arrivalDist  = S.DOOR_ARRIVAL_DIST,
                            logEnabled   = logEnabled,
                            templeChance = S.TEMPLE_VISIT_CHANCE,
                        })
                    end
                end
            end
        end
    end
end

local function onSave()
    -- save managed entries keyed by actor object
    local saveable = {}
    for id, m in pairs(managed) do
        if m.actor and m.actor:isValid() then
            saveable[m.actor] = {
                startPos      = vec3T(m.startPos),
                startCell     = m.startCell,
                startRot      = m.startRot and m.startRot:getYaw() or 0,
                savedWander   = m.savedWander,
                state         = m.state,
                isSafe        = m.isSafe,
                isShop        = m.isShop,
                isTemple      = m.isTemple,
                homeCellName  = m.homeCellName,
                doorExitPos   = m.doorExitPos and vec3T(m.doorExitPos) or nil,
                doorExitRot   = m.doorExitRot and m.doorExitRot:getYaw() or nil,
                doorInsidePos = m.doorInsidePos and vec3T(m.doorInsidePos) or nil,
                doorInsideRot = m.doorInsideRot and m.doorInsideRot:getYaw() or nil,
                doorLockLevel = m.doorLockLevel,
                doorObj       = m.doorObj,
            }
        end
    end
    -- save lockedDoors: map doorObj -> lockLevel
    local saveableLocks = {}
    for doorId, info in pairs(lockedDoors) do
        if info.door and info.door:isValid() then
            saveableLocks[info.door] = info.lockLevel
        end
    end
    return {
        displaced      = displaced,
        managed        = saveable,
        wasHome        = wasHome,
        wasNight       = wasNight,
        scriptVersion  = SCRIPT_VERSION,
        morningQueue   = morningQueue,
        safePlaceReservations = safePlaceReservations,
        lockedDoors    = saveableLocks,
        shopDiceRolled = shopDiceRolled,
        lastShopDay   = lastShopDay,
        templeDiceRolled = templeDiceRolled,
        lastTempleDay = lastTempleDay,
    }
end

local function onLoad(data)
    if not data then return end
    
    local loadedVersion = data.scriptVersion or 0
    if loadedVersion < SCRIPT_VERSION then
        log('Version upgrade detected: v' .. loadedVersion .. ' -> v' .. SCRIPT_VERSION)
        
        if data.displaced then
            displaced = data.displaced
        end
        
        -- restore managed so hardResetAll() can find disabled NPCs
        if data.managed then
            for actor, m in pairs(data.managed) do
                if actor and actor:isValid() then
                    managed[actor.id] = {
                        actor       = actor,
                        startPos    = tVec3(m.startPos) or actor.position,
                        startCell   = m.startCell or '',
                        startRot    = util.transform.rotateZ(m.startRot or 0),
                        savedWander = m.savedWander,
                        state       = m.state,
                        isSafe      = m.isSafe,
                        isShop      = m.isShop,
                        isTemple    = m.isTemple,
                        homeCellName  = m.homeCellName,
                        doorExitPos   = tVec3(m.doorExitPos),
                        doorExitRot   = m.doorExitRot and util.transform.rotateZ(m.doorExitRot) or nil,
                        doorInsidePos = tVec3(m.doorInsidePos),
                        doorInsideRot = m.doorInsideRot and util.transform.rotateZ(m.doorInsideRot) or nil,
                        doorLockLevel = m.doorLockLevel,
                        doorObj       = m.doorObj,
                    }
                end
            end
        end
        
        -- restore lockedDoors so hardResetAll can relock them
        if data.lockedDoors then
            for door, lockLevel in pairs(data.lockedDoors) do
                if door and door:isValid() then
                    lockedDoors[door.id] = { door = door, lockLevel = lockLevel }
                end
            end
        end
        
        async:newUnsavableSimulationTimer(4.0, function()
            hardResetAll()
            log('Version upgrade hard reset completed')
        end)
        
        wasHome = nil
        wasNight = nil
        morningQueue = {}
        morningActive = false
        safePlaceReservations = {}
        
        return
    end
    
    if data.displaced then displaced = data.displaced end

    -- restore managed from saved actor-keyed table
    if data.managed then
        for actor, m in pairs(data.managed) do
            if actor and actor:isValid() then
                managed[actor.id] = {
                    actor       = actor,
                    startPos    = tVec3(m.startPos) or actor.position,
                    startCell   = m.startCell or '',
                    startRot    = util.transform.rotateZ(m.startRot or 0),
                    savedWander = m.savedWander,
                    state       = m.state,
                    isSafe      = m.isSafe,
                    isShop      = m.isShop,
                    isTemple    = m.isTemple,
                    homeCellName  = m.homeCellName,
                    doorExitPos   = tVec3(m.doorExitPos),
                    doorExitRot   = m.doorExitRot and util.transform.rotateZ(m.doorExitRot) or nil,
                    doorInsidePos = tVec3(m.doorInsidePos),
                    doorInsideRot = m.doorInsideRot and util.transform.rotateZ(m.doorInsideRot) or nil,
                    doorLockLevel = m.doorLockLevel,
                    doorObj       = m.doorObj,
                }
            end
        end
    end

    -- restore time-of-day tracking so onUpdate continues seamlessly
    if data.wasHome ~= nil then wasHome = data.wasHome end
    if data.wasNight ~= nil then wasNight = data.wasNight end
    
    if data.safePlaceReservations then
        safePlaceReservations = data.safePlaceReservations
    end

    if data.shopDiceRolled then
        shopDiceRolled = data.shopDiceRolled
    end

    if data.lastShopDay then
        lastShopDay = data.lastShopDay
    end

    if data.templeDiceRolled then
        templeDiceRolled = data.templeDiceRolled
    end

    if data.lastTempleDay then
        lastTempleDay = data.lastTempleDay
    end

    if data.lockedDoors then
        for door, lockLevel in pairs(data.lockedDoors) do
            if door and door:isValid() then
                lockedDoors[door.id] = { door = door, lockLevel = lockLevel }
            end
        end
    end

    -- resume morning spawn cycle if it was interrupted by save/load    
    if data.morningQueue and #data.morningQueue > 0 then
        async:newUnsavableSimulationTimer(2.0, function()
            local player = world.players[1]
            local pCell = player and player.cell
            local pExt = pCell and isOutdoorCell(pCell) or false
            local pName = pCell and pCell.name or ''
            
            -- re-run the batch logic if it's still morning
            if not isNightHour(getGameHour()) and not badWeatherActive then
                returnAllMorning(pExt, pName)
            end
        end)
    end
end


return {
    engineHandlers = {
        onUpdate = onUpdate,
        onSave   = onSave,
        onLoad   = onLoad,
    },
    eventHandlers = {
        NPCSch_Register = function(data)
            local actor = data.actor
            if not actor or not actor:isValid() then return end
            managed[actor.id] = {
                actor         = actor,
                startPos      = data.startPos,
                startCell     = data.startCell,
                startRot      = data.startRot,
                savedWander   = data.savedWander,
                state         = data.state,
                isSafe        = data.isSafe,
                isShop        = data.isShop,
                isTemple      = data.isTemple,
                homeCellName  = data.homeCellName,
                doorExitPos   = data.doorExitPos,
                doorExitRot   = data.doorExitRot,
                doorInsidePos = data.doorInsidePos,
                doorInsideRot = data.doorInsideRot,
                doorLockLevel = data.doorLockLevel,
                doorObj       = data.doorObj,
            }
            markDisplaced(actor, data.startPos, data.startCell, data.startRot, data.savedWander)
            log('Registered:', actor.recordId, 'state:', data.state, 'home:', data.homeCellName or '?', 'shop:', tostring(data.isShop or false), 'temple:', tostring(data.isTemple or false))
        end,

       -- for npc script
       NPCSch_PlayDoorSound = function(data)
            playDoorSound(data.door)
        end,

        NPCSch_UpdateState = function(data)
            local m = managed[data.actorId]
            if m then
                m.state = data.state
                if data.homeCellName then m.homeCellName = data.homeCellName end
                if data.doorInsidePos then m.doorInsidePos = data.doorInsidePos end
                if data.doorInsideRot then m.doorInsideRot = data.doorInsideRot end
                log('State update:', m.actor.recordId, '->', data.state)
            end
        end,

        NPCSch_DisabledAtDoor = function(data)
            local actor = data.actor
            if not actor or not actor:isValid() then return end
            local m = managed[actor.id]
            if not m then return end
            actor.enabled = false
            m.state = 'disabled'

            playDoorSound(m.doorObj)

            if not m.isSafe and m.doorLockLevel and m.doorObj then
                unlockDoor(m.doorObj, m.doorLockLevel)
            end
            log('Disabled at door:', actor.recordId)
        end,

        NPCSch_Returned = function(data)
            if not data or not data.actorId then return end
            managed[data.actorId] = nil
            clearDisplaced(data.actorId)
            log('Returned:', data.actorId)
        end,

        NPCSch_NoDoor = function(data)
            if data and data.actorId then
                managed[data.actorId] = nil
                for cellName, cellData in pairs(safePlaceReservations) do
                    if cellData.reservations[data.actorId] then
                        cellData.reservations[data.actorId] = nil
                        cellData.count = math.max(0, cellData.count - 1)
                        log('Released reservation for failed NPC:', data.actorId)
                        if cellData.count <= 0 then
                            safePlaceReservations[cellName] = nil
                        end
                        break
                    end
                end
            end
        end,

        NPCSch_Teleport = function(data)
            local actor = data.actor
            if not actor or not actor:isValid() then return end
            if data.rotation then
                actor:teleport(data.cell or '', data.pos, data.rotation)
            else
                actor:teleport(data.cell or '', data.pos)
            end
        end,

        NPCSch_RequestLOS = function(data)
            local player = world.players[1]
            if not player then return end
            if data.actor and data.actor:isValid() then
                local dist = (data.actor.position - player.position):length()
                if dist > S.FAR_TELEPORT_DIST then
                    data.actor:sendEvent('NPCSch_LOSDone', { canTeleport = true })
                    return
                end
            end
            player:sendEvent('NPCSch_CheckLOS', data)
        end,

        NPCSch_PlayerEnteredExterior = function(data)
            if S.HARD_RESET then return end
            if not isNightHour(getGameHour()) and not badWeatherActive then return end
            log('Player entered exterior at night/bad weather')
            sendAllHome('animated')
        end,

        NPCSch_PlayerLeftExterior = function(data)
            if S.HARD_RESET then return end
            if not isNightHour(getGameHour()) and not badWeatherActive then return end
            log('Player left exterior at night/bad weather, instant disable remaining')
            instantDisableAll()
        end,

        NPCSch_PlayerEnteredInterior = function(data)
            if S.HARD_RESET then return end
            local isNight = isNightHour(getGameHour()) or badWeatherActive
            if isNight or S.ENABLE_SHOP_VISITS then
                playerEnteredInterior(data.cellName)
            end
        end,

        NPCSch_MorningExitSafe = function(data)
            if S.HARD_RESET then return end
            if isNightHour(getGameHour()) or badWeatherActive then return end
            relockAllDoors()
            log('Morning: player exited safe place, returning all')
            for id, m in pairs(managed) do
                local actor = m.actor
                if actor and actor:isValid() and not Actor.isDead(actor) then
                    if not actor.enabled then actor.enabled = true end
                    actor:teleport(m.startCell, m.startPos, m.startRot)
                    ensureScript(actor)
                    actor:sendEvent('NPCSch_RestoreFull', { savedWander = m.savedWander })
                end
                clearDisplaced(id)
            end
            managed = {}
            safePlaceCounts = {}
            doorExitCounts  = {}
            safePlaceReservations = {}
            morningQueue = {}
            morningActive = false
            shopReturnQueue = {}
            shopReturnActive = false
            shopDiceRolled = {}
            templeReturnQueue = {}
            templeReturnActive = false
            templeDiceRolled = {}
            goHomeQueue = {}
            goHomeActive = false
            for _, actor in ipairs(world.activeActors) do
                if actor.type == NPC and actor:hasScript(LOCAL_SCRIPT) then
                    actor:sendEvent('NPCSch_ResetShopFlag', {})
                    actor:sendEvent('NPCSch_ResetTempleFlag', {})
                end
            end
        end,

        NPCSch_SettingsUpdated = function(data)
            local wasShopEnabled = S.ENABLE_SHOP_VISITS
            local wasTempleEnabled = S.ENABLE_TEMPLE_VISITS
            local wasExcludeTravel = S.EXCLUDE_TRAVEL_CLASSES
            applySettings(data)
            if wasExcludeTravel ~= S.EXCLUDE_TRAVEL_CLASSES then
                isExemptCache = {}
            end
            for _, m in pairs(managed) do
                if m.actor and m.actor:isValid() then
                    m.actor:sendEvent('NPCSch_SetLog', { enabled = S.ENABLE_LOGS })
                end
            end
            -- shop visits toggled off: hard reset all shop NPCs
            if wasShopEnabled and not S.ENABLE_SHOP_VISITS then
                log('Shop visits disabled, hard reset for shop NPCs')
                local shopIds = {}
                for id, m in pairs(managed) do
                    if m.isShop then shopIds[#shopIds + 1] = id end
                end
                for _, id in ipairs(shopIds) do
                    local m = managed[id]
                    if m then
                        local actor = m.actor
                        if actor and actor:isValid() and not Actor.isDead(actor) then
                            if not actor.enabled then actor.enabled = true end
                            actor:teleport(m.startCell, m.startPos, m.startRot)
                            ensureScript(actor)
                            actor:sendEvent('NPCSch_CancelAndRestore', {})
                            if m.savedWander then
                                actor:sendEvent('NPCSch_RestoreFull', { savedWander = m.savedWander })
                            end
                            log('Shop hard reset:', actor.recordId)
                        end
                        managed[id] = nil
                        clearDisplaced(id)
                    end
                end
                shopDiceRolled = {}
                shopReturnQueue = {}
                shopReturnActive = false
                for _, actor in ipairs(world.activeActors) do
                    if actor.type == NPC and actor:hasScript(LOCAL_SCRIPT) then
                        actor:sendEvent('NPCSch_ResetShopFlag', {})
                    end
                end
            end
            -- temple visits toggled off: hard reset all temple NPCs
            if wasTempleEnabled and not S.ENABLE_TEMPLE_VISITS then
                log('Temple visits disabled, hard reset for temple NPCs')
                local templeIds = {}
                for id, m in pairs(managed) do
                    if m.isTemple then templeIds[#templeIds + 1] = id end
                end
                for _, id in ipairs(templeIds) do
                    local m = managed[id]
                    if m then
                        local actor = m.actor
                        if actor and actor:isValid() and not Actor.isDead(actor) then
                            if not actor.enabled then actor.enabled = true end
                            actor:teleport(m.startCell, m.startPos, m.startRot)
                            ensureScript(actor)
                            actor:sendEvent('NPCSch_CancelAndRestore', {})
                            if m.savedWander then
                                actor:sendEvent('NPCSch_RestoreFull', { savedWander = m.savedWander })
                            end
                            log('Temple hard reset:', actor.recordId)
                        end
                        managed[id] = nil
                        clearDisplaced(id)
                    end
                end
                templeDiceRolled = {}
                templeReturnQueue = {}
                templeReturnActive = false
                for _, actor in ipairs(world.activeActors) do
                    if actor.type == NPC and actor:hasScript(LOCAL_SCRIPT) then
                        actor:sendEvent('NPCSch_ResetTempleFlag', {})
                    end
                end
            end
        end,

        NPCSch_RequestSafeReservation = function(data)
            local npcId = data.npcId
            local cellName = data.cellName
            local actor = data.actor
            
            if not npcId or not cellName then
                if actor and actor:isValid() then
                    actor:sendEvent('NPCSch_SafeReservationResponse', { accepted = false, reason = 'invalid' })
                end
                return
            end
            
            local accepted = tryReserveSafePlace(npcId, cellName)
            
            if actor and actor:isValid() then
                actor:sendEvent('NPCSch_SafeReservationResponse', { 
                    accepted = accepted, 
                    cellName = cellName,
                    reason = accepted and 'reserved' or 'full'
                })
            end
            
            if accepted then
                log('Safe place reservation ACCEPTED for', npcId, '->', cellName)
            else
                log('Safe place reservation REJECTED for', npcId, '->', cellName, '(FULL)')
            end
        end,

        NPCSch_ReleaseReservation = function(data)
            releaseSafePlaceReservation(data.npcId, data.cellName)
        end,

        NPCSch_ConfirmRegistration = function(data)
            releaseSafePlaceReservation(data.npcId, data.cellName)
        end,
    },
}