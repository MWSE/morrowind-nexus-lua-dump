local core  = require('openmw.core')
local types = require('openmw.types')
local world = require('openmw.world')
local async = require('openmw.async')
local util  = require('openmw.util')
local time  = require('openmw_aux.time')

local shared                = require('scripts.npcschedule_shared')
local DEFAULTS              = shared.DEFAULTS
local EXEMPT_IDS            = shared.EXEMPT_IDS
local EXEMPT_PATTERNS       = shared.EXEMPT_PATTERNS
local EXEMPT_CLASSES        = shared.EXEMPT_CLASSES
local TRAVEL_CLASSES        = shared.TRAVEL_CLASSES
local ALLOWED_ANIMS         = shared.ALLOWED_ANIMS
local CITY_CELLS            = shared.CITY_CELLS
local SAFE_KEYWORDS         = shared.SAFE_KEYWORDS
local GRID_CELLS            = shared.GRID_CELLS
local BAD_WEATHER           = shared.BAD_WEATHER
local EXEMPT_MODS           = shared.EXEMPT_MODS
local SCRIPT_WHITELIST      = shared.SCRIPT_WHITELIST
local QUEST_EXCEPTIONS      = shared.QUEST_EXCEPTIONS
local LOCK_EXEMPT_DOORS     = shared.LOCK_EXEMPT_DOORS
local MOURNHOLD_INTERIORS   = shared.MOURNHOLD_INTERIORS
local EXEMPT_SHOP_IDS       = shared.EXEMPT_SHOP_IDS
local TRIBUNAL_TEMPLE_CELLS = shared.TRIBUNAL_TEMPLE_CELLS
local IMPERIAL_SHRINE_CELLS = shared.IMPERIAL_SHRINE_CELLS

local NPC   = types.NPC
local Actor = types.Actor

-- constants
local LOCAL_SCRIPT             = 'scripts/npcschedule_npc.lua'
local DAY_SECONDS              = 60 * 60 * 24
local SCRIPT_VERSION           = 10
local SAFE_RESERVATION_TIMEOUT = 180
local RESERVATION_CLEANUP_INTERVAL = 30

local logEnabled = false
local function log(...)
    if logEnabled then print('[NPCSchedule G]', ...) end
end

-- Settings
local S = {}
for k, v in pairs(DEFAULTS) do S[k] = v end

local function applySettings(data)
    if not data then return end
    for k in pairs(S) do
        if data[k] ~= nil then S[k] = data[k] end
    end
    logEnabled = S.ENABLE_LOGS
end

-- weather
local hasWeatherScript = core.contentFiles.has('go-home.omwaddon')
local badWeatherActive = false

-- managed NPC registry
local managed   = {}
local displaced = {}

local safePlaceCounts    = {}
local doorExitCounts     = {}
local doorSoundCooldowns = {}

local morningQueue = {}
local morningActive = false

local shopReturnQueue   = {}
local shopReturnActive  = false
local shopDiceRolled    = {}

local templeReturnQueue  = {}
local templeReturnActive = false
local templeDiceRolled   = {}

local goHomeQueue  = {}
local goHomeActive = false
local goHomeMode   = 'animated'

-- NPCs that failed to find any home or safe place tonight
local noHomeFailed = {}

local safePlaceReservations = {}
local reservationCleanupTimer = 0

-- door state
local lockedDoors = {}

-- caches
local questExemptCache = nil
local serviceBlacklist = {}
local isExemptCache    = {}

-- onUpdate gating + day-rollover tracking
local elapsed         = 0
local weatherElapsed  = 0
local wasNight        = nil
local wasHome         = nil
local wasHardReset    = false
local lastShopDay     = nil
local lastTempleDay   = nil

-- save/load shape conversions
local function vec3T(v) return { x = v.x, y = v.y, z = v.z } end
local function tVec3(t) return t and util.vector3(t.x, t.y, t.z) or nil end

-- weather
local function getCurrentWeather()
    if not hasWeatherScript then return 0 end
    local ok, scr = pcall(world.mwscript.getGlobalScript, 'momw_gh_weather_monitor')
    if not ok or not scr then return 0 end
    return scr.variables.cur or 0
end

local function isBadWeather(w)
    return BAD_WEATHER[w] == true
end

-- cell classification
local function isOutdoorCell(cell)
    if not cell then return false end
    if cell.isExterior then return true end
    local name = cell.name and cell.name:lower() or ''
    return MOURNHOLD_INTERIORS[name] == true
end

local function isInCity(actor)
    if not S.CITY_WHITELIST then return true end
    local c = actor.cell
    if not c then return false end
    local n = c.name
    if n and n ~= '' then return CITY_CELLS[n:lower()] == true end
    if c.isExterior and GRID_CELLS then
        local key = c.gridX .. ',' .. c.gridY
        return GRID_CELLS[key] == true
    end
    return false
end

-- game time
local function getGameHour()
    return (core.getGameTime() % DAY_SECONDS) / 3600
end

local function getGameDay()
    return math.floor(core.getGameTime() / DAY_SECONDS)
end

local function isNightHour(h)
    local s, e = S.NIGHT_START, S.NIGHT_END
    if s > e then return h >= s or h < e
    else        return h >= s and h <  e end
end

local function isShopHour(h)
    return h >= S.SHOP_VISIT_START and h < S.SHOP_VISIT_END
end

-- safe place reservations
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

    local lo      = cellName:lower()
    local data    = safePlaceReservations[lo]
    local current = data and data.count or 0

    if current >= S.MAX_SAFE_OCCUPANTS then
        log('Safe place FULL:', cellName, '(', current, '/', S.MAX_SAFE_OCCUPANTS, ')')
        return false
    end

    if not data then
        safePlaceReservations[lo] = { count = 0, reservations = {} }
        data = safePlaceReservations[lo]
    end

    if data.reservations[npcId] then return true end

    data.reservations[npcId] = os.time()
    data.count = current + 1
    log('Safe place RESERVED:', cellName, 'for', npcId, '(', data.count, '/', S.MAX_SAFE_OCCUPANTS, ')')
    return true
end

local function releaseSafePlaceReservation(npcId, cellName)
    if not cellName or cellName == '' then return end
    local lo   = cellName:lower()
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

-- door locks
local function isDoorLockExempt(door)
    if not door or not door:isValid() then return true end
    return LOCK_EXEMPT_DOORS[door.recordId:lower()] == true
end

local function unlockDoor(door, lockLevel)
    if not S.UNLOCK_HOME_DOORS                  then return end
    if not door or not door:isValid()           then return end
    if not lockLevel or lockLevel <= 0          then return end
    if isDoorLockExempt(door)                   then return end
    if lockedDoors[door.id]                     then return end
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

-- door positioning
-- spread NPCs out from a shared exit point so they don't pile up at the door
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

-- place arriving NPC at a 4-wide grid offset from the inside-of-door anchor
local function gridSpotForCount(count, base)
    local col = count % 4
    local row = math.floor(count / 4)
    return util.vector3(
        base.x + (col - 1.5) * S.SAFE_SPACING,
        base.y + (row - 0.5) * S.SAFE_SPACING,
        base.z
    )
end

local function teleportToInsideSlot(actor, cellName, m)
    local lo    = cellName:lower()
    local count = safePlaceCounts[lo] or 0
    safePlaceCounts[lo] = count + 1
    local base = m.doorInsidePos
    local pos
    if base then
        pos = gridSpotForCount(count, base)
    else
        pos = m.doorInsidePos or util.vector3(0, 0, 0)
    end
    actor:teleport(cellName, pos, m.doorInsideRot)
end

-- quest / record / exempt checks
local function getRec(npc) return NPC.record(npc) end

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

local function computeIsExempt(npc)
    local id = npc.recordId
    if EXEMPT_IDS[id] then return true end
    for _, p in ipairs(EXEMPT_PATTERNS) do
        if id:find(p, 1, true) then return true end
    end
    if npc.contentFile and EXEMPT_MODS[npc.contentFile:lower()] then return true end

    local rec = getRec(npc)
    if not rec then return false end

    if rec.class then
        local cls = rec.class:lower()
        if EXEMPT_CLASSES[cls] then return true end
        if S.EXCLUDE_TRAVEL_CLASSES and TRAVEL_CLASSES[cls] then return true end
    end

    local mws = rec.mwscript
    if mws and not SCRIPT_WHITELIST[mws:lower()] then
        log('Exempt by mwscript:', id, 'script:', mws)
        return true
    end

    if not ALLOWED_ANIMS[(rec.model or ''):lower()] then return true end

    return false
end

local function isExempt(npc)
    local id = npc.recordId
    local cached = isExemptCache[id]
    if cached == nil then
        cached = computeIsExempt(npc)
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

-- returns 'tribunal' | 'imperial' | nil
local function getEligibleCult(npc)
    local getRank = NPC.getFactionRank
    if getRank(npc, 'temple')          > 0 then return 'tribunal' end
    if getRank(npc, 'imperial cult')   > 0 then return 'imperial' end
    if getRank(npc, 'imperial legion') > 0 then return 'imperial' end
    if getRank(npc, 'telvanni')        > 0 then return nil        end
    if getRank(npc, 'redoran')         > 0 then return 'tribunal' end
    if getRank(npc, 'hlaalu')          > 0 then
        return (math.random() < 0.5) and 'tribunal' or 'imperial'
    end
    -- factionless: dunmer -> tribunal, otherwise imperial
    local rec = NPC.record(npc)
    if rec and rec.race == 'dark elf' then return 'tribunal' end
    return 'imperial'
end

-- managed NPC registry
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

-- door sound
local function playDoorSound(door)
    if not S.ENABLE_DOOR_SOUNDS                 then return end
    if not door or not door:isValid()           then return end
    if doorSoundCooldowns[door.id]              then return end

    local doorRec = types.Door.record(door)
    if not (doorRec and doorRec.openSound and doorRec.openSound ~= '') then return end

    core.sound.playSound3d(doorRec.openSound, door)
    doorSoundCooldowns[door.id] = true
    async:newUnsavableSimulationTimer(S.DOOR_SOUND_COOLDOWN, function()
        doorSoundCooldowns[door.id] = nil
    end)
    log('Door sound played for door:', door.id)
end

--  batch processing
local function startBatchedDrain(getQueue, isActive, batchSize, batchDelay, processFn, onDone)
    local queue = getQueue()
    if not queue or #queue == 0 then if onDone then onDone() end return end

    local function processNext()
        if not isActive() then return end       -- kill-switch: external abort
        local q = getQueue()
        if not q or #q == 0 then if onDone then onDone() end return end

        for _ = 1, batchSize do
            if not isActive() then return end   -- abort mid-batch too
            q = getQueue()
            if not q or #q == 0 then break end
            local item = table.remove(q, 1)
            if item then processFn(item) end
        end

        local q2 = getQueue()
        if isActive() and q2 and #q2 > 0 then
            async:newUnsavableSimulationTimer(batchDelay, processNext)
        elseif onDone then
            onDone()
        end
    end
    processNext()
end

-- population
local function findEligibleOutdoorCityNPCs()
    local result = {}
    for _, actor in ipairs(world.activeActors) do
        if actor.type == NPC
           and not managed[actor.id]
           and not noHomeFailed[actor.id]
           and not isExempt(actor)
           and actor.cell and isOutdoorCell(actor.cell)
           and isInCity(actor)
        then
            local rec = getRec(actor)
            if rec and rec.name and rec.name ~= '' then
                result[#result + 1] = actor
            end
        end
    end
    return result
end

-- go home (mass)
local function dispatchGoHome(actor, mode)
    ensureScript(actor)
    local delay = (mode == 'animated') and math.random(1, S.MAX_DELAY) or 0
    actor:sendEvent('NPCSch_InitGoHome', {
        scanRange   = S.DOOR_SCAN_RANGE,
        arrivalDist = S.DOOR_ARRIVAL_DIST,
        logEnabled  = logEnabled,
        mode        = mode,
        delay       = delay,
    })
end

local function sendAllHome(mode)
    local targets = findEligibleOutdoorCityNPCs()
    if #targets == 0 then return end

    goHomeQueue = targets
    goHomeMode  = mode
    if goHomeActive then return end  -- batch already running, will pick up new queue
    goHomeActive = true

    startBatchedDrain(
        function() return goHomeQueue end,
        function() return goHomeActive end,
        S.MORNING_BATCH_SIZE,
        S.MORNING_BATCH_DELAY,
        function(npc)
            if npc and npc:isValid() and not managed[npc.id] then
                dispatchGoHome(npc, goHomeMode)
            end
        end,
        function() goHomeActive = false end
    )
end

local function instantDisableAll()
    for _, m in pairs(managed) do
        if m.state == 'delaying' or m.state == 'walking' then
            local actor = m.actor
            if actor and actor:isValid() and not Actor.isDead(actor)
               and actor.cell and isOutdoorCell(actor.cell)
            then
                actor:sendEvent('NPCSch_InstantDisable', {})
            end
        end
    end

    for _, actor in ipairs(findEligibleOutdoorCityNPCs()) do
        ensureScript(actor)
        actor:sendEvent('NPCSch_InitGoHome', {
            scanRange   = S.DOOR_SCAN_RANGE,
            arrivalDist = S.DOOR_ARRIVAL_DIST,
            logEnabled  = logEnabled,
            mode        = 'instant',
        })
    end
end

-- player entered an interior
-- handle a single managed NPC whose home cell == the cell the player just entered
local function enableNpcInsideHome(actor, m, cellName)
    actor.enabled = true
    ensureScript(actor)

    if m.isSafe or m.isShop or m.isTemple then
        teleportToInsideSlot(actor, cellName, m)
        if m.isShop then
            actor:sendEvent('NPCSch_StartShopWander', {})
        else
            -- safe and temple use the same wander params
            actor:sendEvent('NPCSch_StartSafeWander', {})
        end
    else
        actor:teleport(cellName, m.doorInsidePos or util.vector3(0, 0, 0), m.doorInsideRot)
        actor:sendEvent('NPCSch_StartHomeStand', {})
    end

    m.state = 'inside'
    log('Enabled NPC inside:', actor.recordId)
end

local function playerEnteredInterior(cellName)
    if not cellName or cellName == '' then return end
    local lo = cellName:lower()
    for _, m in pairs(managed) do
        local actor = m.actor
        if m.state == 'disabled'
           and m.homeCellName and m.homeCellName:lower() == lo
           and actor and actor:isValid() and not Actor.isDead(actor)
        then
            log('Player entered home of disabled NPC:', actor.recordId, cellName)
            enableNpcInsideHome(actor, m, cellName)
        end
    end
end

-- morning return
-- handle a single managed NPC's morning return based on its current state
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
        actor.enabled = true
        ensureScript(actor)
        local exitPos = m.doorExitPos
        if exitPos and playerInExterior then
            playDoorSound(m.doorObj)
            local spreadPos = spreadExitPos(exitPos, m.doorExitRot)
            actor:teleport(m.startCell, spreadPos, m.startRot)
            actor:sendEvent('NPCSch_WalkToStart', {
                startPos    = m.startPos,
                startRot    = m.startRot,
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
        local sameInterior = playerCellName and m.homeCellName
                             and playerCellName:lower() == m.homeCellName:lower()
        if playerInExterior then
            -- player outside: NPC teleports to exit, walks back
            local exitPos = m.doorExitPos
            if exitPos then
                playDoorSound(m.doorObj)
                local spreadPos = spreadExitPos(exitPos, m.doorExitRot)
                actor:teleport(m.startCell, spreadPos, m.startRot)
                actor:sendEvent('NPCSch_WalkToStart', {
                    startPos    = m.startPos,
                    startRot    = m.startRot,
                    savedWander = m.savedWander,
                })
                m.state = 'returning'
            else
                actor:teleport(m.startCell, m.startPos, m.startRot)
                actor:sendEvent('NPCSch_RestoreFull', { savedWander = m.savedWander })
                managed[id] = nil
                clearDisplaced(id)
            end
        elseif sameInterior then
            -- player inside the same place: NPC walks to door, then teleports
            actor:sendEvent('NPCSch_WalkOutAndReturn', {
                startPos    = m.startPos,
                startCell   = m.startCell,
                startRot    = m.startRot,
                savedWander = m.savedWander,
            })
            m.state = 'walkingOut'
        else
            -- player elsewhere: instant teleport
            actor:teleport(m.startCell, m.startPos, m.startRot)
            actor:sendEvent('NPCSch_RestoreFull', { savedWander = m.savedWander })
            managed[id] = nil
            clearDisplaced(id)
        end
    end
end

local function clearMorningQueues()
    safePlaceCounts       = {}
    doorExitCounts        = {}
    safePlaceReservations = {}
    morningQueue       = {}
    morningActive      = false
    shopReturnQueue    = {}
    shopReturnActive   = false
    shopDiceRolled     = {}
    templeReturnQueue  = {}
    templeReturnActive = false
    templeDiceRolled   = {}
    goHomeQueue   = {}
    goHomeActive  = false
end

local function returnAllMorning(playerInExterior, playerCellName)
    log('Starting morning return cycle, playerExterior:', tostring(playerInExterior))
    relockAllDoors()
    clearMorningQueues()

    noHomeFailed = {}

    -- reset visit flags so NPCs can shop/temple again today
    for _, actor in ipairs(world.activeActors) do
        if actor.type == NPC and actor:hasScript(LOCAL_SCRIPT) then
            actor:sendEvent('NPCSch_ResetShopFlag', {})
            actor:sendEvent('NPCSch_ResetTempleFlag', {})
        end
    end

    for id in pairs(managed) do
        morningQueue[#morningQueue + 1] = id
    end

    if #morningQueue > 0 then
        morningActive = true
        startBatchedDrain(
            function() return morningQueue end,
            function() return morningActive end,
            S.MORNING_BATCH_SIZE,
            S.MORNING_BATCH_DELAY,
            function(id)
                local m = managed[id]
                if m then processMorningNPC(id, m, playerInExterior, playerCellName) end
            end,
            function() morningActive = false end
        )
    end
end

-- visit return (shop/temple)
local function isVisitActive(m, isShop)
    local flagOk
    if isShop then
        flagOk = m.isShop
    else
        flagOk = m.isTemple
    end
    if not flagOk then return false end
    return m.state == 'walking' or m.state == 'delaying'
        or m.state == 'disabled' or m.state == 'inside'
end

local function collectActiveVisitIds(isShop)
    local ids = {}
    for id, m in pairs(managed) do
        if isVisitActive(m, isShop) then ids[#ids + 1] = id end
    end
    return ids
end

-- staggered single-item-per-tick return for shop/temple visits at end of visit window
local function startVisitReturn(isShop, pExterior, pCellName)
    local function getQueue()    return isShop and shopReturnQueue   or templeReturnQueue   end
    local function getActive()   return isShop and shopReturnActive  or templeReturnActive  end
    local function setInactive()
        if isShop then shopReturnActive   = false
        else           templeReturnActive = false end
    end

    local function processNext()
        if not getActive() then return end
        local q = getQueue()
        if not q or #q == 0 then setInactive() return end

        local id = table.remove(q, 1)
        local m  = managed[id]
        if m and ((isShop and m.isShop) or (not isShop and m.isTemple)) then
            processMorningNPC(id, m, pExterior, pCellName)
        end

        local q2 = getQueue()
        if getActive() and q2 and #q2 > 0 then
            async:newUnsavableSimulationTimer(math.random(1, S.MAX_DELAY), processNext)
        else
            setInactive()
        end
    end
    processNext()
end

-- hard reset
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
                for _, actor in ipairs(world.activeActors) do
                    if actor:isValid() and actor.recordId == d.recordId and not restored[actor.id] then
                        if not actor.enabled then actor.enabled = true end
                        local rot = util.transform.rotateZ(d.yaw or 0)
                        actor:teleport(d.cell or '', pos, rot)
                        ensureScript(actor)
                        actor:sendEvent('NPCSch_CancelAndRestore', {})
                        if d.savedWander then
                            actor:sendEvent('NPCSch_RestoreFull', { savedWander = d.savedWander })
                        end
                        restored[actor.id] = true
                        log('Reset displaced:', d.recordId)
                        break
                    end
                end
            end
        end
    end

    managed   = {}
    displaced = {}
    noHomeFailed = {}
    clearMorningQueues()
    log('=== HARD RESET complete ===')
end

-- hard reset only NPCs whose visit type has just been disabled (called from settings update)
local function hardResetVisitNPCs(isShop)
    log(isShop and 'Shop visits disabled, hard reset for shop NPCs'
              or  'Temple visits disabled, hard reset for temple NPCs')
    local ids = {}
    for id, m in pairs(managed) do
        if (isShop and m.isShop) or (not isShop and m.isTemple) then
            ids[#ids + 1] = id
        end
    end
    for _, id in ipairs(ids) do
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
                log((isShop and 'Shop' or 'Temple') .. ' hard reset:', actor.recordId)
            end
            managed[id] = nil
            clearDisplaced(id)
        end
    end

    if isShop then
        shopDiceRolled    = {}
        shopReturnQueue   = {}
        shopReturnActive  = false
    else
        templeDiceRolled   = {}
        templeReturnQueue  = {}
        templeReturnActive = false
    end

    local resetEvent = isShop and 'NPCSch_ResetShopFlag' or 'NPCSch_ResetTempleFlag'
    for _, actor in ipairs(world.activeActors) do
        if actor.type == NPC and actor:hasScript(LOCAL_SCRIPT) then
            actor:sendEvent(resetEvent, {})
        end
    end
end

-- onUpdate phases
local function tickReservationCleanup()
    reservationCleanupTimer = reservationCleanupTimer + S.CHECK_INTERVAL
    if reservationCleanupTimer >= RESERVATION_CLEANUP_INTERVAL then
        reservationCleanupTimer = 0
        cleanupExpiredReservations()
    end
end

local function tickHardReset()
    if S.HARD_RESET then
        if not wasHardReset then
            hardResetAll()
            wasHardReset = true
        end
        wasHome  = false
        wasNight = false
        badWeatherActive = false
        return true
    end
    if wasHardReset and not S.HARD_RESET then
        wasHardReset = false
    end
    return false
end

local function tickWeather()
    if S.GO_HOME_BAD_WEATHER and hasWeatherScript then
        weatherElapsed = weatherElapsed + S.CHECK_INTERVAL
        if weatherElapsed >= S.WEATHER_CHECK_INTERVAL then
            weatherElapsed = 0
            badWeatherActive = isBadWeather(getCurrentWeather())
        end
    else
        badWeatherActive = false
    end
end

-- main night<->day transition handler. returns true if a transition was processed
local function tickHomeTransition(shouldBeHome, isNight)
    if wasHome == nil then
        wasHome  = shouldBeHome
        wasNight = isNight
        if shouldBeHome then
            buildQuestCache()
            sendAllHome('animated')
        end
        return true
    end

    if shouldBeHome and not wasHome then
        -- night begins
        buildQuestCache()
        -- always animated because otherwise they tend to teleport when the player's looking
        local timeSkipDetected = nil
        sendAllHome(timeSkipDetected and 'instant' or 'animated')
        wasHome  = true
        wasNight = isNight
        return true
    end

    if not shouldBeHome and wasHome then
        -- morning begins
        clearQuestCache()
        local player    = world.players[1]
        local pCell     = player and player.cell
        local pExterior = isOutdoorCell(pCell)
        local pCellName = pCell and pCell.name or ''
        returnAllMorning(pExterior, pCellName)
        wasHome  = false
        wasNight = isNight
        return true
    end

    wasNight = isNight
    return false
end

local function tickNightSweepAndReturns()
    -- 1. shops first: pull visiting NPCs back home for the night
    if S.ENABLE_SHOP_VISITS then
        local player    = world.players[1]
        local pCell     = player and player.cell
        local pExterior = isOutdoorCell(pCell)
        local pCellName = pCell and pCell.name or ''
        for _, id in ipairs(collectActiveVisitIds(true)) do
            local m = managed[id]
            if m then processMorningNPC(id, m, pExterior, pCellName) end
        end
    end

    -- 2. temples next, same pattern
    if S.ENABLE_TEMPLE_VISITS then
        local player    = world.players[1]
        local pCell     = player and player.cell
        local pExterior = isOutdoorCell(pCell)
        local pCellName = pCell and pCell.name or ''
        for _, id in ipairs(collectActiveVisitIds(false)) do
            local m = managed[id]
            if m then processMorningNPC(id, m, pExterior, pCellName) end
        end
    end

    -- 3. force any unmanaged outdoor NPCs back via LOS
    for _, m in pairs(managed) do
        local actor = m.actor
        if actor and actor:isValid() and actor.cell and isOutdoorCell(actor.cell)
           and m.state == nil
        then
            log('Night sweep: force for', actor.recordId)
            actor:sendEvent('NPCSch_ForceViaLOS', {})
        end
    end

    -- 4. catch any newly-active NPCs that haven't been managed yet
    for _, actor in ipairs(findEligibleOutdoorCityNPCs()) do
        ensureScript(actor)
        actor:sendEvent('NPCSch_InitGoHome', {
            scanRange   = S.DOOR_SCAN_RANGE,
            arrivalDist = S.DOOR_ARRIVAL_DIST,
            logEnabled  = logEnabled,
            mode        = 'animated',
            delay       = math.random(1, S.MAX_DELAY),
        })
    end
end

local function tickEndOfVisitReturn(hour)
    local player    = world.players[1]
    local pCell     = player and player.cell
    local pExterior = isOutdoorCell(pCell)
    local pCellName = pCell and pCell.name or ''

    if S.ENABLE_SHOP_VISITS and not isShopHour(hour) and not shopReturnActive then
        local ids = collectActiveVisitIds(true)
        if #ids > 0 then
            shopReturnQueue  = ids
            shopReturnActive = true
            startVisitReturn(true, pExterior, pCellName)
        end
    end

    if S.ENABLE_TEMPLE_VISITS and not isShopHour(hour) and not templeReturnActive then
        local ids = collectActiveVisitIds(false)
        if #ids > 0 then
            templeReturnQueue  = ids
            templeReturnActive = true
            startVisitReturn(false, pExterior, pCellName)
        end
    end
end

-- clears once-per-day dice flags so NPCs can shop/temple again on the new game day
local function rolloverShopDayIfDue()
    local currentDay = getGameDay()
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
end

local function rolloverTempleDayIfDue()
    local currentDay = getGameDay()
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
end

-- schedule both rollovers to run hourly on the game-time clock
time.runRepeatedly(rolloverShopDayIfDue,   time.hour, { type = time.GameTime })
time.runRepeatedly(rolloverTempleDayIfDue, time.hour, { type = time.GameTime })

local function tickShopVisitInit()
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
                    scanRange   = S.DOOR_SCAN_RANGE,
                    arrivalDist = S.DOOR_ARRIVAL_DIST,
                    logEnabled  = logEnabled,
                    shopChance  = S.SHOP_VISIT_CHANCE,
                })
            end
        end
    end
end

local function tickTempleVisitInit()
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

local function onUpdate(dt)
    elapsed = elapsed + dt
    if elapsed < S.CHECK_INTERVAL then return end
    elapsed = elapsed - S.CHECK_INTERVAL  -- preserve remainder

    tickReservationCleanup()
    if tickHardReset() then return end
    tickWeather()

    local hour         = getGameHour()
    local isNight      = isNightHour(hour)
    local shouldBeHome = isNight or badWeatherActive

    if tickHomeTransition(shouldBeHome, isNight) then return end

    if shouldBeHome then
        tickNightSweepAndReturns()
    else
        tickEndOfVisitReturn(hour)
        if S.ENABLE_SHOP_VISITS   and isShopHour(hour) then tickShopVisitInit()   end
        if S.ENABLE_TEMPLE_VISITS and isShopHour(hour) then tickTempleVisitInit() end
    end
end

-- onSave / onLoad
local function onSave()
    local saveable = {}
    for _, m in pairs(managed) do
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

    local saveableLocks = {}
    for _, info in pairs(lockedDoors) do
        if info.door and info.door:isValid() then
            saveableLocks[info.door] = info.lockLevel
        end
    end

    return {
        displaced             = displaced,
        managed               = saveable,
        wasHome               = wasHome,
        wasNight              = wasNight,
        scriptVersion         = SCRIPT_VERSION,
        morningQueue          = morningQueue,
        safePlaceReservations = safePlaceReservations,
        lockedDoors           = saveableLocks,
        shopDiceRolled        = shopDiceRolled,
        lastShopDay           = lastShopDay,
        templeDiceRolled      = templeDiceRolled,
        lastTempleDay         = lastTempleDay,
    }
end

local function rebuildManagedFromSave(savedManaged)
    if not savedManaged then return end
    for actor, m in pairs(savedManaged) do
        if actor and actor:isValid() then
            managed[actor.id] = {
                actor         = actor,
                startPos      = tVec3(m.startPos) or actor.position,
                startCell     = m.startCell or '',
                startRot      = util.transform.rotateZ(m.startRot or 0),
                savedWander   = m.savedWander,
                state         = m.state,
                isSafe        = m.isSafe,
                isShop        = m.isShop,
                isTemple      = m.isTemple,
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

local function rebuildLockedDoorsFromSave(savedLocks)
    if not savedLocks then return end
    for door, lockLevel in pairs(savedLocks) do
        if door and door:isValid() then
            lockedDoors[door.id] = { door = door, lockLevel = lockLevel }
        end
    end
end

local function onLoad(data)
    if not data then return end

    local loadedVersion = data.scriptVersion or 0
    if loadedVersion < SCRIPT_VERSION then
        log('Version upgrade detected: v' .. loadedVersion .. ' -> v' .. SCRIPT_VERSION)
        if data.displaced   then displaced = data.displaced end
        rebuildManagedFromSave(data.managed)
        rebuildLockedDoorsFromSave(data.lockedDoors)
        async:newUnsavableSimulationTimer(4.0, function()
            hardResetAll()
            log('Version upgrade hard reset completed')
        end)
        wasHome  = nil
        wasNight = nil
        morningQueue          = {}
        morningActive         = false
        safePlaceReservations = {}
        return
    end

    if data.displaced then displaced = data.displaced end
    rebuildManagedFromSave(data.managed)
    rebuildLockedDoorsFromSave(data.lockedDoors)

    if data.wasHome  ~= nil then wasHome  = data.wasHome  end
    if data.wasNight ~= nil then wasNight = data.wasNight end

    if data.safePlaceReservations then safePlaceReservations = data.safePlaceReservations end
    if data.shopDiceRolled        then shopDiceRolled        = data.shopDiceRolled        end
    if data.lastShopDay           then lastShopDay           = data.lastShopDay           end
    if data.templeDiceRolled      then templeDiceRolled      = data.templeDiceRolled      end
    if data.lastTempleDay         then lastTempleDay         = data.lastTempleDay         end

    -- resume morning spawn cycle if it was interrupted by save/load
    if data.morningQueue and #data.morningQueue > 0 then
        async:newUnsavableSimulationTimer(2.0, function()
            local player = world.players[1]
            local pCell  = player and player.cell
            local pExt   = pCell and isOutdoorCell(pCell) or false
            local pName  = pCell and pCell.name or ''
            if not isNightHour(getGameHour()) and not badWeatherActive then
                returnAllMorning(pExt, pName)
            end
        end)
    end
end

-- registry
local function onRegister(data)
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
    log('Registered:', actor.recordId, 'state:', data.state, 'home:', data.homeCellName or '?',
        'shop:', tostring(data.isShop or false), 'temple:', tostring(data.isTemple or false))
end

local function onPlayDoorSound(data)
    playDoorSound(data.door)
end

local function onUpdateState(data)
    local m = managed[data.actorId]
    if not m then return end
    m.state = data.state
    if data.homeCellName  then m.homeCellName  = data.homeCellName  end
    if data.doorInsidePos then m.doorInsidePos = data.doorInsidePos end
    if data.doorInsideRot then m.doorInsideRot = data.doorInsideRot end
    log('State update:', m.actor.recordId, '->', data.state)
end

local function onDisabledAtDoor(data)
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
end

local function onReturned(data)
    if not data or not data.actorId then return end
    managed[data.actorId] = nil
    clearDisplaced(data.actorId)
    log('Returned:', data.actorId)
end

local function onNoDoor(data)
    if not data or not data.actorId then return end
    managed[data.actorId] = nil
    -- mark as failed so we don't re-scan this NPC for the rest of tonight
    noHomeFailed[data.actorId] = true
    -- release any reservation held by this NPC
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

local function onTeleport(data)
    local actor = data.actor
    if not actor or not actor:isValid() then return end
    if data.rotation then
        actor:teleport(data.cell or '', data.pos, data.rotation)
    else
        actor:teleport(data.cell or '', data.pos)
    end
end

-- LOS
local function onRequestLOS(data)
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
end

-- player cell transitions
local function onPlayerEnteredExterior()
    if S.HARD_RESET then return end
    if not isNightHour(getGameHour()) and not badWeatherActive then return end
    log('Player entered exterior at night/bad weather')
    sendAllHome('animated')
end

local function onPlayerLeftExterior()
    if S.HARD_RESET then return end
    if not isNightHour(getGameHour()) and not badWeatherActive then return end
    log('Player left exterior at night/bad weather, instant disable remaining')
    instantDisableAll()
end

local function onPlayerEnteredInterior(data)
    if S.HARD_RESET then return end
    local nightOrWeather = isNightHour(getGameHour()) or badWeatherActive
    if nightOrWeather or S.ENABLE_SHOP_VISITS then
        playerEnteredInterior(data.cellName)
    end
end

local function onMorningExitSafe()
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
    clearMorningQueues()
    for _, actor in ipairs(world.activeActors) do
        if actor.type == NPC and actor:hasScript(LOCAL_SCRIPT) then
            actor:sendEvent('NPCSch_ResetShopFlag', {})
            actor:sendEvent('NPCSch_ResetTempleFlag', {})
        end
    end
end


-- settings
local function onSettingsUpdated(data)
    local wasShopEnabled   = S.ENABLE_SHOP_VISITS
    local wasTempleEnabled = S.ENABLE_TEMPLE_VISITS
    local wasExcludeTravel = S.EXCLUDE_TRAVEL_CLASSES

    applySettings(data)

    -- TRAVEL_CLASSES affects exempt cache; rebuild if toggled
    if wasExcludeTravel ~= S.EXCLUDE_TRAVEL_CLASSES then
        isExemptCache = {}
    end

    -- propagate log toggle to local scripts
    for _, m in pairs(managed) do
        if m.actor and m.actor:isValid() then
            m.actor:sendEvent('NPCSch_SetLog', { enabled = S.ENABLE_LOGS })
        end
    end

    if wasShopEnabled and not S.ENABLE_SHOP_VISITS then
        hardResetVisitNPCs(true)
    end
    if wasTempleEnabled and not S.ENABLE_TEMPLE_VISITS then
        hardResetVisitNPCs(false)
    end
end

-- reservations
local function onRequestSafeReservation(data)
    local npcId    = data.npcId
    local cellName = data.cellName
    local actor    = data.actor

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
            reason   = accepted and 'reserved' or 'full',
        })
    end

    if accepted then
        log('Safe place reservation ACCEPTED for', npcId, '->', cellName)
    else
        log('Safe place reservation REJECTED for', npcId, '->', cellName, '(FULL)')
    end
end

local function onReleaseReservation(data)
    releaseSafePlaceReservation(data.npcId, data.cellName)
end

local function onConfirmRegistration(data)
    releaseSafePlaceReservation(data.npcId, data.cellName)
end


return {
    engineHandlers = {
        onUpdate = onUpdate,
        onSave   = onSave,
        onLoad   = onLoad,
    },
    eventHandlers = {
        NPCSch_Register                = onRegister,
        NPCSch_PlayDoorSound           = onPlayDoorSound,
        NPCSch_UpdateState             = onUpdateState,
        NPCSch_DisabledAtDoor          = onDisabledAtDoor,
        NPCSch_Returned                = onReturned,
        NPCSch_NoDoor                  = onNoDoor,
        NPCSch_Teleport                = onTeleport,
        NPCSch_RequestLOS              = onRequestLOS,
        NPCSch_PlayerEnteredExterior   = onPlayerEnteredExterior,
        NPCSch_PlayerLeftExterior      = onPlayerLeftExterior,
        NPCSch_PlayerEnteredInterior   = onPlayerEnteredInterior,
        NPCSch_MorningExitSafe         = onMorningExitSafe,
        NPCSch_SettingsUpdated         = onSettingsUpdated,
        NPCSch_RequestSafeReservation  = onRequestSafeReservation,
        NPCSch_ReleaseReservation      = onReleaseReservation,
        NPCSch_ConfirmRegistration     = onConfirmRegistration,
    },
}