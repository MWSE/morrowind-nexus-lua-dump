local self   = require('openmw.self')
local core   = require('openmw.core')
local types  = require('openmw.types')
local nearby = require('openmw.nearby')
local util   = require('openmw.util')
local async  = require('openmw.async')

local shared          = require('scripts.npcschedule_shared')
local SAFE_KEYWORDS   = shared.SAFE_KEYWORDS
local RECORD_ID_STRIP = shared.RECORD_ID_STRIP
local DEFAULTS        = shared.DEFAULTS
local BLACKLISTED_INTERIORS = shared.BLACKLISTED_INTERIORS

local AI       = require('openmw.interfaces').AI
local Door     = types.Door
local Lockable = types.Lockable

local logEnabled = false

local function log(...)
    if logEnabled then print('[NPCSch N]', self.object.recordId, ...) end
end

-- states: nil, 'delaying', 'walking', 'disabled', 'inside', 'walkingOut', 'returning', 'waitSnap'
local state        = nil
local savedWander  = nil
local targetDoor   = nil
local targetDoorPos = nil
local arrivalDist  = 200
local isSafe       = false
local homeCellName = nil
local scanRange    = 3000
local doorInsidePos = nil
local doorInsideRot = nil
local doorExitRot   = nil
local doorLockLevel = nil

-- walkOutAndReturn data
local walkOutStartPos  = nil
local walkOutStartCell = nil
local walkOutStartRot  = nil
local walkOutWander    = nil

-- stuck detection
local lastPos    = nil
local stuckTimer = 0
local STUCK_TIME = 5

local CHECK_RATE = 0.5
local checkTimer = 0
local lastGameTime = nil

-- safe place reservation
local pendingReservation = nil
local reservationCellName = nil
local triedSafeCells = {}
local triedDoors = {}

-- save/load helpers for vector and rotation
local function vec3T(v) return v and { x = v.x, y = v.y, z = v.z } or nil end
local function tVec3(t) return t and util.vector3(t.x, t.y, t.z) or nil end
local function rotT(r)
    if not r then return nil end
    local ok, y = pcall(function() return r:getYaw() end)
    return ok and y or 0
end
local function tRot(y) return y and util.transform.rotateZ(y) or nil end

-- save and restore for Wander
local function saveWander()
    if savedWander then return end
    local pkg = AI.getActivePackage()
    if pkg and pkg.type == 'Wander' then
        savedWander = {
            type     = 'Wander',
            distance = pkg.distance,
            duration = pkg.duration,
            idle     = pkg.idle,
            isRepeat = pkg.isRepeat,
        }
        log('Saved wander d:', pkg.distance)
    end
end



local function restoreOriginalWander()
    if savedWander then
        AI.removePackages('Wander')
        AI.removePackages('Travel')
        AI.startPackage(savedWander)
        log('Restored original wander')
    end
    savedWander = nil
end

-- safe cell check
local function isSafeCell(name)
    if not name then return false end
    local lo = name:lower()
    for _, kw in ipairs(SAFE_KEYWORDS) do
        if lo:find(kw, 1, true) then return true end
    end
    return false
end

-- door search
local function getNameTokens(recordId)
    local tokens = {}
    for s in recordId:gmatch('([^_]+)') do
        if not RECORD_ID_STRIP[s:lower()] then
            tokens[#tokens + 1] = s:lower()
        end
    end
    return tokens
end

local function cellMatchesNpc(cellName, npcName, recordId)
    local lo = cellName:lower()
    if lo:find(npcName:lower(), 1, true) then return true end
    if lo:find(recordId:lower(), 1, true) then return true end
    for _, t in ipairs(getNameTokens(recordId)) do
        if #t >= 3 and lo:find(t, 1, true) then return true end
    end
    return false
end

-- find personal home door
local function findHomeDoor(range)
    local rec = types.NPC.record(self.object)
    local npcName  = rec and rec.name or ''
    local recordId = self.object.recordId
    if npcName == '' then return nil end

    local best, bestD = nil, range + 1
    for _, d in ipairs(nearby.doors) do
        if d:isValid() and Door.isTeleport(d) then
            local ok, dc = pcall(Door.destCell, d)
            if ok and dc and not dc.isExterior then
                local cn = dc.name or ''
                if not BLACKLISTED_INTERIORS[cn:lower()] then
                    if cellMatchesNpc(cn, npcName, recordId) then
                        local dist = (d.position - self.object.position):length()
                        if dist < bestD then best, bestD = d, dist end
                    end
                end
            end
        end
    end
    return best
end

-- find safe place door candidates
-- the problem is sometimes places have doors that are unavailable (like doors on the roof)
-- instance id changes, so no way to filter them
-- bcom eight plates is an example
local function findAvailableSafeDoors(range, excludeTried)
    local candidates = {}
    
    for _, d in ipairs(nearby.doors) do
        if d:isValid() and Door.isTeleport(d) and not Lockable.isLocked(d) then
            local ok, dc = pcall(Door.destCell, d)
            if ok and dc and not dc.isExterior then
                local cn = dc.name or ''
                local lo = cn:lower()
                
                if not BLACKLISTED_INTERIORS[lo] and isSafeCell(cn) then
                    if excludeTried and triedSafeCells[lo] then
                        goto continue
                    end
                    
                    local dist = (d.position - self.object.position):length()
                    if dist <= range then
                        table.insert(candidates, { door = d, dist = dist, cellName = cn })
                    end
                end
            end
        end
        ::continue::
    end
    
    table.sort(candidates, function(a, b) return a.dist < b.dist end)
    return candidates
end

-- resolve door inside position/rotation from the door object (while NPC is still outside)
local function resolveDoorInside(door)
    if not door or not door:isValid() then return end
    local pos = Door.destPosition(door)
    local rot = Door.destRotation(door)
    if pos then doorInsidePos = pos end
    if rot then doorInsideRot = rot end
    doorExitRot = door.rotation
    if Lockable.isLocked(door) then
        doorLockLevel = Lockable.getLockLevel(door)
    else
        doorLockLevel = nil
    end
end

local function registerWith(st)
    core.sendGlobalEvent('NPCSch_Register', {
        actor         = self.object,
        startPos      = self.startingPosition,
        startCell     = self.cell and (self.cell.name or '') or '',
        startRot      = self.startingRotation,
        savedWander   = savedWander,
        state         = st,
        isSafe        = isSafe,
        homeCellName  = homeCellName,
        doorExitPos   = targetDoorPos,
        doorExitRot   = doorExitRot,
        doorInsidePos = doorInsidePos,
        doorInsideRot = doorInsideRot,
        doorLockLevel = doorLockLevel,
        doorObj       = targetDoor,
    })
end

-- NPC arrived at door: request disable from global (no teleport into interior)
local function disableAtDoor()
    AI.removePackages('Travel')
    AI.removePackages('Wander')
    state = 'disabled'
    core.sendGlobalEvent('NPCSch_DisabledAtDoor', {
        actor = self.object,
    })
    if isSafe and reservationCellName then
        core.sendGlobalEvent('NPCSch_ConfirmRegistration', {
            npcId = self.object.id,
            cellName = reservationCellName,
        })
        reservationCellName = nil
    end
    log('Requesting disable at door')
end

local function resetStuck()
    lastPos = self.object.position
    stuckTimer = 0
end

local function isStuck(dt)
    if not lastPos then resetStuck() return false end
    if (self.object.position - lastPos):length() > 30 then
        resetStuck()
        return false
    end
    stuckTimer = stuckTimer + dt
    return stuckTimer >= STUCK_TIME
end

local function findEscape()
    local pos = self.object.position
    local fwd = self.object.rotation:apply(util.vector3(0, 1, 0))
    local rgt = self.object.rotation:apply(util.vector3(1, 0, 0))
    for _, dir in ipairs({ fwd, (fwd+rgt):normalize(), (fwd-rgt):normalize(), rgt, -rgt, -fwd }) do
        local cand = pos + dir * 300
        local wall = nearby.castRay(
            pos + util.vector3(0,0,60), cand + util.vector3(0,0,60),
            { collisionType = nearby.COLLISION_TYPE.World, ignore = { self.object } }
        )
        if not wall.hit then
            local ground = nearby.castRay(
                cand + util.vector3(0,0,50), cand - util.vector3(0,0,200),
                { collisionType = nearby.COLLISION_TYPE.World }
            )
            if ground.hit and math.abs(ground.hitPos.z - pos.z) < 120 then
                local ox = (math.random() - 0.5) * 240
                local oy = (math.random() - 0.5) * 240
                return ground.hitPos + util.vector3(ox, oy, 10)
            end
        end
    end
    return nil
end

local function startWalkToDoor()
    if not targetDoorPos then return end
    AI.removePackages('Wander')
    AI.startPackage({
        type = 'Travel', destPosition = targetDoorPos,
        isRepeat = false, cancelOther = false,
    })
    state = 'walking'
    core.sendGlobalEvent('NPCSch_UpdateState', {
        actorId = self.object.id, state = 'walking',
    })
    resetStuck()
end

local escapeAttempted = false


local function tryNextSafePlace(mode, delay, allCandidates, startIndex)
    local index = startIndex or 1
    
    while index <= #allCandidates do
        local candidate = allCandidates[index]
        local cellNameLower = candidate.cellName:lower()
        
        if not triedSafeCells[cellNameLower] then
            log(string.format('Trying safe place: %s. Delay: %.2f sec. (%d of %d)', candidate.cellName, delay, index, #allCandidates))
            
            pendingReservation = {
                door = candidate.door,
                cellName = candidate.cellName,
                mode = mode,
                delay = delay,
                candidates = allCandidates,
                nextIndex = index + 1,
            }
            
            core.sendGlobalEvent('NPCSch_RequestSafeReservation', {
                npcId = self.object.id,
                cellName = candidate.cellName,
                actor = self.object,
            })
            return true
        end
        
        index = index + 1
    end
    
    log('All safe doors exhausted, giving up')
    core.sendGlobalEvent('NPCSch_NoDoor', { actorId = self.object.id })
    state = nil
    return false
end

local function handleStuck()
    if not escapeAttempted and targetDoor and targetDoor:isValid() then
        local esc = findEscape()
        if esc then
            log('Stuck, escape path found')
            escapeAttempted = true
            AI.removePackages('Travel')
            AI.startPackage({ type = 'Travel', destPosition = esc, isRepeat = false, cancelOther = false })
            resetStuck()
            async:newUnsavableSimulationTimer(3, function()
                if state ~= 'walking' or not escapeAttempted then return end
                if state ~= 'walking' then return end
                AI.removePackages('Travel')
                if targetDoorPos then
                    local angle = math.random() * math.pi * 2
                    local distance = math.random(100, 200)
                    
                    local deltaX = math.cos(angle) * distance
                    local deltaY = math.sin(angle) * distance

                    local newDestPos = util.vector3(
                        targetDoorPos.x + deltaX,
                        targetDoorPos.y + deltaY,
                        targetDoorPos.z
                    )
                    AI.startPackage({ type = 'Travel', destPosition = newDestPos, isRepeat = false, cancelOther = false })
                    resetStuck()
                    log('Resumed walking to door after escape')
                end
            end)
            return
        end
    end

    -- try another door of the same safe place
    if targetDoor and targetDoor:isValid() then
        triedDoors[targetDoor.id] = true -- mark this specific door instance as failed
    end

    if reservationCellName then
        log('Stuck again, searching for another door to the same safe place:', reservationCellName)
        
        for _, d in ipairs(nearby.doors) do
            if d:isValid() and Door.isTeleport(d) and not triedDoors[d.id] then
                local ok, dc = pcall(Door.destCell, d)
                if ok and dc and dc.name:lower() == reservationCellName:lower() then
                    log('Found alternative door to same safe place, switching target')
                    
                    targetDoor = d
                    targetDoorPos = d.position
                    escapeAttempted = false
                    
                    AI.removePackages('Travel')
                    AI.startPackage({ type = 'Travel', destPosition = targetDoorPos, isRepeat = false, cancelOther = false })
                    resetStuck()
                    return
                end
            end
        end
    end

    -- request a teleportation
    log('Stuck, no more doors for this safe place. Requesting LOS for disable')
    escapeAttempted = false
    triedDoors = {} -- clear for next time
    
    if isSafe and reservationCellName then
        core.sendGlobalEvent('NPCSch_ReleaseReservation', {
            npcId = self.object.id,
            cellName = reservationCellName,
        })
        reservationCellName = nil
    end

    core.sendGlobalEvent('NPCSch_RequestLOS', {
        actor = self.object, door = targetDoor, safe = isSafe,
    })
    resetStuck()
end


local function onUpdate(dt)
    if not state then return end
    checkTimer = checkTimer + dt
    if checkTimer < CHECK_RATE then return end
    local acc = checkTimer
    checkTimer = 0


    if state == 'walking' then
        if not targetDoorPos then
            state = nil
            return
        end
        if isStuck(acc) then handleStuck() return end

        local dist = (self.object.position - targetDoorPos):length()
        if dist <= arrivalDist then
            -- arrived at door: disable instead of teleporting inside
            disableAtDoor()
        end
        return
    end

    if state == 'disabled' or state == 'inside' then
        return
    end

    if state == 'returning' then
        if isStuck(acc) then
            AI.removePackages('Travel')
            state = 'waitSnap'
            core.sendGlobalEvent('NPCSch_RequestLOS', {
                actor = self.object, door = nil, safe = false,
            })
            return
        end

        local dist = (self.object.position - self.startingPosition):length()
        if dist <= 40 then
            AI.removePackages('Travel')
            state = 'waitSnap'
            restoreOriginalWander()
            core.sendGlobalEvent('NPCSch_RequestLOS', {
                actor = self.object, door = nil, safe = false,
            })
        end
        return
    end

    if state == 'waitSnap' then
        return
    end

    if state == 'walkingOut' then
        if not targetDoorPos then state = nil return end
        if isStuck(acc) then
            -- stuck walking to door inside, just teleport out
            AI.removePackages('Travel')
            core.sendGlobalEvent('NPCSch_PlayDoorSound', { door = targetDoor })
            core.sendGlobalEvent('NPCSch_Teleport', {
                actor = self.object,
                cell = walkOutStartCell or '',
                pos = walkOutStartPos,
                rotation = walkOutStartRot,
            })
            savedWander = walkOutWander
            restoreOriginalWander()
            core.sendGlobalEvent('NPCSch_Returned', { actorId = self.object.id })
            state = nil
            return
        end
        local dist = (self.object.position - targetDoorPos):length()
        if dist <= arrivalDist then
            core.sendGlobalEvent('NPCSch_PlayDoorSound', { door = targetDoor })
            AI.removePackages('Travel')
            core.sendGlobalEvent('NPCSch_Teleport', {
                actor = self.object,
                cell = walkOutStartCell or '',
                pos = walkOutStartPos,
                rotation = walkOutStartRot,
            })
            savedWander = walkOutWander
            restoreOriginalWander()
            core.sendGlobalEvent('NPCSch_Returned', { actorId = self.object.id })
            state = nil
            targetDoor = nil
            targetDoorPos = nil
            log('Reached interior door, teleported to startPos')
        end
        return
    end

    -- if the player skips time, end delay
    local currentGameTime = core.getGameTime()
    if lastGameTime then
        local delta = currentGameTime - lastGameTime
        if delta > 3599 then
            if state == 'delaying' then
                log('Time skip detected during delay. Ending delay phase.')
                state = 'walking' 
            end
        end
    end
    lastGameTime = currentGameTime

end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onSave = function()
            if not savedWander and not state then return end
            return { 
                savedWander = savedWander, 
                state = state,
                targetDoorPos = vec3T(targetDoorPos),
                arrivalDist = arrivalDist,
                isSafe = isSafe,
                homeCellName = homeCellName,
                doorInsidePos = vec3T(doorInsidePos),
                doorInsideRot = rotT(doorInsideRot),
                doorExitRot = rotT(doorExitRot),
                doorLockLevel = doorLockLevel,
                walkOutStartPos = vec3T(walkOutStartPos),
                walkOutStartCell = walkOutStartCell,
                walkOutStartRot = rotT(walkOutStartRot),
                walkOutWander = walkOutWander,
                scanRange = scanRange,
                reservationCellName = reservationCellName,
                triedSafeCells = triedSafeCells,
            }
        end,
        onLoad = function(data)
            if not data then return end
            savedWander = data.savedWander
            state = data.state
            targetDoorPos = tVec3(data.targetDoorPos)
            arrivalDist = data.arrivalDist or 200
            isSafe = data.isSafe or false
            homeCellName = data.homeCellName
            doorInsidePos = tVec3(data.doorInsidePos)
            doorInsideRot = tRot(data.doorInsideRot)
            doorExitRot = tRot(data.doorExitRot)
            doorLockLevel = data.doorLockLevel
            walkOutStartPos = tVec3(data.walkOutStartPos)
            walkOutStartCell = data.walkOutStartCell
            walkOutStartRot = tRot(data.walkOutStartRot)
            walkOutWander = data.walkOutWander
            scanRange = data.scanRange or 3000
            reservationCellName = data.reservationCellName
            triedSafeCells = data.triedSafeCells or {}

            -- restart lost AI packages
            if state == 'walking' and targetDoorPos then
                async:newUnsavableSimulationTimer(0.5, function()
                    if state ~= 'walking' then return end
                    AI.removePackages('Wander')
                    AI.startPackage({
                        type = 'Travel', destPosition = targetDoorPos,
                        isRepeat = false, cancelOther = false,
                    })
                    resetStuck()
                end)
            elseif state == 'delaying' and targetDoorPos then
                -- delay timer lost, start walking immediately
                async:newUnsavableSimulationTimer(0.5, function()
                    if state ~= 'delaying' then return end
                    startWalkToDoor()
                end)
            elseif state == 'returning' then
                async:newUnsavableSimulationTimer(0.5, function()
                    if state ~= 'returning' then return end
                    AI.removePackages('Wander')
                    AI.startPackage({
                        type = 'Travel', destPosition = self.startingPosition,
                        isRepeat = false, cancelOther = false,
                    })
                    resetStuck()
                end)
            elseif state == 'walkingOut' and targetDoorPos then
                async:newUnsavableSimulationTimer(0.5, function()
                    if state ~= 'walkingOut' then return end
                    AI.removePackages('Wander')
                    AI.startPackage({
                        type = 'Travel', destPosition = targetDoorPos,
                        isRepeat = false, cancelOther = false,
                    })
                    resetStuck()
                end)
            end
        end,
    },
    eventHandlers = {
        -- Global tells NPC to go home
        NPCSch_InitGoHome = function(data)
            if state then return end
            scanRange    = data.scanRange or 3000
            arrivalDist  = data.arrivalDist or 200
            logEnabled   = data.logEnabled or false
            local mode   = data.mode or 'animated'
            local delay  = data.delay or 0
            triedSafeCells = {}
            pendingReservation = nil
            reservationCellName = nil


            local pkg = AI.getActivePackage()
            if pkg and pkg.type ~= 'Wander' then
               return 
             end


            saveWander()

            -- tier 1: personal home
            local door = findHomeDoor(scanRange)
            if door then
                isSafe = false
                targetDoor = door
                targetDoorPos = door.position
                
                local ok2, dc2 = pcall(Door.destCell, door)
                if ok2 and dc2 then
                    homeCellName = dc2.name or ''
                end
                resolveDoorInside(door)
                
                if mode == 'instant' then
                    state = 'walking'
                    registerWith('walking')
                    core.sendGlobalEvent('NPCSch_RequestLOS', {
                        actor = self.object, door = door, safe = false,
                    })
                    return
                end
                
                if delay > 0 then
                    state = 'delaying'
                    registerWith('delaying')
                    async:newUnsavableSimulationTimer(delay, function()
                        if state ~= 'delaying' then return end
                        startWalkToDoor()
                        log('Started walking after delay')
                    end)
                else
                    startWalkToDoor()
                    registerWith('walking')
                end
                log('GoHome mode:', mode, 'personal home found')
                return
            end
            
            -- tier 2: safe place with reservation
            log('No personal home, searching safe places')
            local candidates = findAvailableSafeDoors(scanRange, true)
            
            if #candidates == 0 then
                core.sendGlobalEvent('NPCSch_NoDoor', { actorId = self.object.id })
                return
            end
            
            tryNextSafePlace(mode, delay, candidates, 1)
        end,

        NPCSch_SafeReservationResponse = function(data)
            if not pendingReservation then
                log('WARNING: Received reservation response but no pending reservation')
                return
            end
            
            local p = pendingReservation
            pendingReservation = nil
            
            if data.accepted then
                log('Reservation ACCEPTED for', data.cellName)
                
                isSafe = true
                targetDoor = p.door
                targetDoorPos = p.door.position
                reservationCellName = data.cellName
                
                local ok, dc = pcall(Door.destCell, p.door)
                if ok and dc then
                    homeCellName = dc.name or ''
                end
                resolveDoorInside(p.door)
                
                if p.mode == 'instant' then
                    -- request LOS check: if player not looking, disable immediately
                    state = 'walking'
                    registerWith('walking')
                    core.sendGlobalEvent('NPCSch_RequestLOS', {
                        actor = self.object, door = p.door, safe = true,
                    })
                    return
                end
                
                -- animated: walk with optional delay
                if p.delay > 0 then
                    state = 'delaying'
                    registerWith('delaying')
                    async:newUnsavableSimulationTimer(p.delay, function()
                        if state ~= 'delaying' then return end
                        startWalkToDoor()
                    end)
                else
                    startWalkToDoor()
                    registerWith('walking')
                end
                log('GoHome mode:', p.mode, 'safe:', tostring(isSafe))
            else
                log('Reservation REJECTED for', p.cellName, 'trying next')
                triedSafeCells[p.cellName:lower()] = true
                tryNextSafePlace(p.mode, p.delay, p.candidates, p.nextIndex)
            end
        end,

        -- Instant disable: player left exterior, can't see NPCs
        NPCSch_InstantDisable = function()
            if state ~= 'walking' and state ~= 'delaying' then return end
            disableAtDoor()
            log('Instant disable')
        end,

        -- Night sweep: NPC still delaying, cancel delay and start walking
        NPCSch_ForceViaLOS = function()
            if state ~= 'delaying' then return end
            startWalkToDoor()
            log('ForceViaLOS: started walking')
        end,

        -- LOS check result
        NPCSch_LOSDone = function(data)
            if state == 'waitSnap' then
                if data.canTeleport then
                    core.sendGlobalEvent('NPCSch_Teleport', {
                        actor = self.object,
                        cell = self.cell and (self.cell.name or '') or '',
                        pos = self.startingPosition,
                        rotation = self.startingRotation,
                    })
                    restoreOriginalWander()
                    core.sendGlobalEvent('NPCSch_Returned', { actorId = self.object.id })
                    state = nil
                else
                    async:newUnsavableSimulationTimer(1, function()
                        if state ~= 'waitSnap' then return end
                        core.sendGlobalEvent('NPCSch_RequestLOS', {
                            actor = self.object, door = nil, safe = false,
                        })
                    end)
                end
                return
            end

            if not data.canTeleport then
                -- player is looking, switch to animated walk to door
                log('LOS: player sees me, walking to door instead')
                startWalkToDoor()
                return
            end
            -- player not looking: disable at door immediately
            disableAtDoor()
        end,

        -- global enables NPC inside safe place: start wander
        NPCSch_StartSafeWander = function()
            state = 'inside'
            AI.removePackages('Wander')
            AI.removePackages('Travel')
            AI.startPackage({
                type = 'Wander',
                distance = DEFAULTS.SAFE_WANDER_DIST,
                duration = DEFAULTS.SAFE_WANDER_DURATION,
                idle = DEFAULTS.SAFE_WANDER_IDLE,
                isRepeat = true,
            })
            log('Started safe wander inside')
        end,

        -- global enables NPC inside personal home: stand still
        NPCSch_StartHomeStand = function()
            state = 'inside'
            AI.removePackages('Wander')
            AI.removePackages('Travel')
            AI.startPackage({ type = 'Wander', distance = 0, duration = 0, isRepeat = true })
            log('Standing in personal home')
        end,

        -- cancel everything and restore
        NPCSch_CancelAndRestore = function()

            AI.removePackages('Travel')
            AI.removePackages('Wander')
            if isSafe and reservationCellName then
                core.sendGlobalEvent('NPCSch_ReleaseReservation', {
                    npcId = self.object.id,
                    cellName = reservationCellName,
                })
                reservationCellName = nil
            end
            restoreOriginalWander()
            state = nil
            targetDoor = nil
            targetDoorPos = nil
            doorInsidePos = nil
            doorInsideRot = nil
            doorExitRot = nil
            doorLockLevel = nil
            walkOutStartPos = nil
            walkOutStartCell = nil
            walkOutStartRot = nil
            walkOutWander = nil
            triedSafeCells = {}
            pendingReservation = nil
            log('Cancelled and restored')
        end,

        -- hard reset / full restore
        NPCSch_RestoreFull = function(data)
            AI.removePackages('Travel')
            AI.removePackages('Wander')
            if isSafe and reservationCellName then
                core.sendGlobalEvent('NPCSch_ReleaseReservation', {
                    npcId = self.object.id,
                    cellName = reservationCellName,
                })
                reservationCellName = nil
            end
            if data and data.savedWander then
                savedWander = data.savedWander
            end
            restoreOriginalWander()
            state = nil
            targetDoor = nil
            targetDoorPos = nil
            doorInsidePos = nil
            doorInsideRot = nil
            doorExitRot = nil
            doorLockLevel = nil
            walkOutStartPos = nil
            walkOutStartCell = nil
            walkOutStartRot = nil
            walkOutWander = nil
            triedSafeCells = {}
            pendingReservation = nil
            log('Full restore')
        end,

        -- morning: walk to starting position
        NPCSch_WalkToStart = function(data)
            AI.removePackages('Wander')
            AI.removePackages('Travel')
            savedWander = data.savedWander
            AI.startPackage({
                type = 'Travel', destPosition = data.startPos,
                isRepeat = false, cancelOther = false,
            })
            state = 'returning'
            resetStuck()
            log('Walking to start pos')
        end,

        -- morning: NPC inside, player inside same cell: walk to door, then teleport to startPos
        NPCSch_WalkOutAndReturn = function(data)
            local best, bestD = nil, math.huge
            for _, d in ipairs(nearby.doors) do
                if d:isValid() and Door.isTeleport(d) then
                    local dist = (d.position - self.object.position):length()
                    if dist < bestD then best = d; bestD = dist end
                end
            end
            if best then
                AI.removePackages('Wander')
                AI.removePackages('Travel')
                targetDoor = best
                targetDoorPos = best.position
                AI.startPackage({
                    type = 'Travel', destPosition = best.position,
                    isRepeat = false, cancelOther = false,
                })
                state = 'walkingOut'
                walkOutStartPos  = data.startPos
                walkOutStartCell = data.startCell
                walkOutStartRot  = data.startRot
                walkOutWander    = data.savedWander
                resetStuck()
                log('Walking to interior door for morning exit')
            else
                -- no door found, teleport directly
                core.sendGlobalEvent('NPCSch_Teleport', {
                    actor = self.object,
                    cell = data.startCell or '',
                    pos = data.startPos,
                    rotation = data.startRot,
                })
                savedWander = data.savedWander
                restoreOriginalWander()
                core.sendGlobalEvent('NPCSch_Returned', { actorId = self.object.id })
                state = nil
            end
        end,

        NPCSch_SetLog = function(data)
            logEnabled = data.enabled or false
        end,
    },
}