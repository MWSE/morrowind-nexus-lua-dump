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
local QUEST_EXCEPTIONS = shared.QUEST_EXCEPTIONS
local LOCK_EXEMPT_DOORS = shared.LOCK_EXEMPT_DOORS
local MOURNHOLD_INTERIORS = shared.MOURNHOLD_INTERIORS

local NPC      = types.NPC
local Actor    = types.Actor

local LOCAL_SCRIPT = 'scripts/npcschedule_npc.lua'
local DAY_SECONDS  = 60 * 60 * 24
local SCRIPT_VERSION = 8

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

-- Safe place reservation system
local safePlaceReservations = {}
local SAFE_RESERVATION_TIMEOUT = 60
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
        local ok, fwd = pcall(function() return doorRot:apply(util.vector3(0, 1, 0)) end)
        if ok and fwd then
            forward = util.vector3(-fwd.x, -fwd.y, 0):normalize()
        end
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
    local ok, r = pcall(NPC.record, npc)
    return ok and r or nil
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

local function isExempt(npc)
    local id = npc.recordId
    if EXEMPT_IDS[id] then return true end
    for _, p in ipairs(EXEMPT_PATTERNS) do
        if id:find(p, 1, true) then return true end
    end
    if npc.contentFile and EXEMPT_MODS[npc.contentFile:lower()] then return true end
    local rec = getRec(npc)
    if rec then
        if rec.class then
            local cls = rec.class:lower()
            if EXEMPT_CLASSES[cls] then return true end
            if S.EXCLUDE_TRAVEL_CLASSES and TRAVEL_CLASSES[cls] then return true end
        end
        local model = (rec.model or ''):lower()
        if not ALLOWED_ANIMS[model] then return true end
    end
    if questExemptCache and questExemptCache[id:lower()] then return true end
    return false
end

local function ensureScript(npc)
    if not npc:hasScript(LOCAL_SCRIPT) then
        local ok, err = pcall(npc.addScript, npc, LOCAL_SCRIPT)
        if not ok then log('addScript failed:', err) end
    end
end

local function markDisplaced(actor, startPos, startCell, startRot, savedWander)
    local yaw = 0
    local ok, v = pcall(function() return startRot:getYaw() end)
    if ok then yaw = v end
    displaced[actor.id] = {
        recordId    = actor.recordId,
        pos         = vec3T(startPos),
        cell        = startCell,
        yaw         = yaw,
        savedWander = savedWander,
    }
end

local function clearDisplaced(id)
    displaced[id] = nil
end

local function sendAllHome(mode)
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
    
    if #npcsToSendHome > 0 then
        for _, npc in ipairs(npcsToSendHome) do
            ensureScript(npc)
            local delay = 0
            if mode == 'animated' then
                delay = math.random(1, S.MAX_DELAY)
            end
            npc:sendEvent('NPCSch_InitGoHome', {
                scanRange      = S.DOOR_SCAN_RANGE,
                arrivalDist    = S.DOOR_ARRIVAL_DIST,
                logEnabled     = logEnabled,
                mode           = mode,
                delay          = delay,
            })
        end
    end
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

local function collectCurrentDisplacements()
    local newDisplaced = {}
    for _, actor in ipairs(world.activeActors) do
        if actor.type == NPC and not Actor.isDead(actor) and not isExempt(actor) then
            local yaw = 0
            local ok, v = pcall(function() return actor.rotation:getYaw() end)
            if ok then yaw = v end
            
            newDisplaced[actor.id] = {
                recordId    = actor.recordId,
                pos         = vec3T(actor.position),
                cell        = actor.cell and (actor.cell.name or '') or '',
                yaw         = yaw,
                savedWander = nil,
            }
        end
    end
    return newDisplaced
end

local function hardResetAll()
    log('=== HARD RESET ===')

    relockAllDoors()

    local currentDisplaced = collectCurrentDisplacements()

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
                    if actor:isValid() and actor.id == id then
                        found = actor
                        break
                    end
                end
                if not found then
                    for _, actor in ipairs(world.activeActors) do
                        if actor:isValid() and actor.recordId == d.recordId and not restored[actor.id] then
                            found = actor
                            break
                        end
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

    for id, d in pairs(currentDisplaced) do
        if not restored[id] then
            local pos = tVec3(d.pos)
            if pos then
                local found = nil
                for _, actor in ipairs(world.activeActors) do
                    if actor:isValid() and actor.id == id then
                        found = actor
                        break
                    end
                end
                if found then
                    if not found.enabled then found.enabled = true end
                    local rot = util.transform.rotateZ(d.yaw or 0)
                    ensureScript(found)
                    found:teleport(d.cell or '', pos, rot)
                    -- if no saved data found, don't reset
                    if not d.state and not d.savedWander then
                        log('No persistent data for ' .. tostring(found.recordId) .. ', skip event')
                    else
                        found:sendEvent('NPCSch_CancelAndRestore', {})
                        restored[id] = true
                        log('Reset fallback:', found.recordId)
                    end
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
    
    log('=== HARD RESET complete ===')
end

local wasNight     = nil
local wasHome      = nil
local elapsed      = 0
local wasHardReset = false
local weatherElapsed = 0

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
end

local function onSave()
    -- save managed entries keyed by actor object
    local saveable = {}
    for id, m in pairs(managed) do
        if m.actor and m.actor:isValid() then
            saveable[m.actor] = {
                startPos    = vec3T(m.startPos),
                startCell   = m.startCell,
                startRot    = m.startRot and (function()
                    local ok, y = pcall(function() return m.startRot:getYaw() end)
                    return ok and y or 0
                end)() or 0,
                savedWander = m.savedWander,
                state       = m.state,
                isSafe      = m.isSafe,
                homeCellName  = m.homeCellName,
                doorExitPos   = m.doorExitPos and vec3T(m.doorExitPos) or nil,
                doorExitRot   = m.doorExitRot and (function()
                    local ok2, y2 = pcall(function() return m.doorExitRot:getYaw() end)
                    return ok2 and y2 or 0
                end)() or nil,
                doorInsidePos = m.doorInsidePos and vec3T(m.doorInsidePos) or nil,
                doorInsideRot = m.doorInsideRot and (function()
                    local ok3, y3 = pcall(function() return m.doorInsideRot:getYaw() end)
                    return ok3 and y3 or 0
                end)() or nil,
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
                homeCellName  = data.homeCellName,
                doorExitPos   = data.doorExitPos,
                doorExitRot   = data.doorExitRot,
                doorInsidePos = data.doorInsidePos,
                doorInsideRot = data.doorInsideRot,
                doorLockLevel = data.doorLockLevel,
                doorObj       = data.doorObj,
            }
            markDisplaced(actor, data.startPos, data.startCell, data.startRot, data.savedWander)
            log('Registered:', actor.recordId, 'state:', data.state, 'home:', data.homeCellName or '?')
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
            if not isNightHour(getGameHour()) and not badWeatherActive then return end
            playerEnteredInterior(data.cellName)
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
        end,

        NPCSch_SettingsUpdated = function(data)
            applySettings(data)
            for _, m in pairs(managed) do
                if m.actor and m.actor:isValid() then
                    m.actor:sendEvent('NPCSch_SetLog', { enabled = S.ENABLE_LOGS })
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