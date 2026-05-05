local self   = require('openmw.self')
local types  = require('openmw.types')
local nearby = require('openmw.nearby')
local core   = require('openmw.core')
local util   = require('openmw.util')
local AI     = require('openmw.interfaces').AI
local time   = require('openmw_aux.time')

local Actor    = types.Actor
local Door     = types.Door
local Lockable = types.Lockable

local shared         = require('scripts.nightpatrol_shared')
local SAFE_KEYWORDS  = shared.SAFE_KEYWORDS
local EXCLUDED_CELLS = shared.EXCLUDED_CELLS

local hasBCOM = core.contentFiles.has('Beautiful cities of Morrowind.ESP')
local DOOR_OVERRIDES = hasBCOM and shared.DOOR_OVERRIDES_BCOM or shared.DOOR_OVERRIDES

local target        = nil
local originPos     = nil
local originCell    = nil
local doorPos       = nil
local destCellName  = nil
local arrivalDist   = 250
local waitSeconds   = 0

-- Phases: nil (idle), 'escort', 'arrived'
local phase         = nil
local escorting     = false
local waitTimer     = 0
local wasBusy       = false
local busyWasCombat = false

-- sheathe Your Weapons compat
local playerWeaponDrawn = false

local CHECK_INTERVAL = 0.5 * time.second
local checkTimer = 0

local stuckTimer    = 0
local lastPos       = nil
local scanRange     = 2000
local failedDoors   = {}

local function isFightingPlayer()
    local ok, targets = pcall(AI.getTargets, 'Combat')
    if not ok or not targets then return false end
    for _, t in ipairs(targets) do
        if t == target then return true end
    end
    return false
end


local function isSafeCell(cellName)
    if not cellName then return false end
    local lower = string.lower(cellName)
    if EXCLUDED_CELLS[lower] then return false end
    for _, keyword in ipairs(SAFE_KEYWORDS) do
        if lower:find(keyword, 1, true) then return true end
    end
    return false
end

local function findSafeDoor(range)
    local bestDist = range + 1
    local bestDoor = nil
    local bestCellName = nil
    for _, door in ipairs(nearby.doors) do
        if door:isValid()
           and not failedDoors[door.id]
           and Door.isTeleport(door)
           and not Lockable.isLocked(door)
        then
            local ok, destCell = pcall(Door.destCell, door)
            if ok and destCell and not destCell.isExterior then
                local dist = (door.position - self.object.position):length()
                if dist < bestDist and isSafeCell(destCell.name or '') then
                    bestDist = dist
                    bestDoor = door
                    bestCellName = destCell.name or ''
                end
            end
        end
    end
    return bestDoor, bestCellName
end

-- returns overridden exterior approach position for given cell, or nil
local function getDoorOverride(cellName)
    if not cellName then return nil end
    local entries = DOOR_OVERRIDES[cellName:lower()]
    if not entries or #entries == 0 then return nil end
    if #entries == 1 then
        local e = entries[1]
        return util.vector3(e.x, e.y, e.z)
    end
    -- nearest entry to guard
    local myPos = self.object.position
    local best, bestD = nil, math.huge
    for _, e in ipairs(entries) do
        local v = util.vector3(e.x, e.y, e.z)
        local d = (v - myPos):length()
        if d < bestD then best, bestD = v, d end
    end
    return best
end

local function removeEscortPackages()
    AI.removePackages('Escort')
    AI.removePackages('Travel')
end

local function resetState()
    removeEscortPackages()
    phase = nil
    target = nil
    doorPos = nil
    destCellName = nil
    escorting = false
    waitTimer = 0
    wasBusy = false
    busyWasCombat = false
    stuckTimer = 0
    lastPos = nil
    failedDoors = {}
end

local function startEscortPackage()
    if not target or not target:isValid() or not doorPos then return end
    escorting = true
    AI.startPackage({
        type         = 'Escort',
        target       = target,
        destPosition = doorPos,
        destCell     = self.cell,
        duration     = 3 * time.hour,
        isRepeat     = false,
        cancelOther  = false,
    })
end

local function startEscort(data)
    target = data.target
    if not target or not target:isValid() then return end

    removeEscortPackages()

    arrivalDist = data.doorArrivalDist
    waitSeconds = 2 * time.second
    scanRange = data.doorScanRange
    failedDoors = {}
    stuckTimer = 0
    lastPos = nil

    -- preserve original patrol point if already set (re-escort after stealth escape)
    if not originPos then
        originPos   = self.object.position
        local cell  = self.cell
        originCell  = cell and (cell.name or '') or ''
    end

    local safeDoor, safeCellName = findSafeDoor(scanRange)
    if not safeDoor then
        if target:isValid() then
            target:sendEvent('NightPatrol_NoShelter', { guard = self.object })
        end
        originPos = nil
        originCell = nil
        return
    end

    doorPos = safeDoor.position
    destCellName = safeCellName
    local ovr = getDoorOverride(destCellName)
    if ovr then doorPos = ovr end
    phase = 'escort'
    escorting = false
    waitTimer = waitSeconds

    target:sendEvent('NightPatrol_EscortConfirmed', {
        guard = self.object,
        destCellName = destCellName,
    })
end


local function onUpdate(dt)
    if not phase then return end

    checkTimer = checkTimer + dt
    if checkTimer < CHECK_INTERVAL then return end
    checkTimer = 0

    if not target or not target:isValid() then
        resetState()
        return
    end

    if phase == 'escort' then
        local activePkg = AI.getActivePackage()
        local isBusy = activePkg and (activePkg.type == 'Combat' or activePkg.type == 'Pursue')

        if isBusy then
            if not wasBusy then
                wasBusy = true
                busyWasCombat = activePkg.type == 'Combat' and isFightingPlayer()
                removeEscortPackages()
                escorting = false
                target:sendEvent('NightPatrol_GuardBusy', { guard = self.object, busy = true })
            end
            return
        elseif wasBusy then
            wasBusy = false
            target:sendEvent('NightPatrol_GuardBusy', { guard = self.object, busy = false })

            if busyWasCombat then
                -- player resisted, escort over
                busyWasCombat = false
                phase = nil
                escorting = false
                target:sendEvent('NightPatrol_EscortEnded', { guard = self.object })
                if originPos then
                    AI.startPackage({
                        type = 'Travel',
                        destPosition = originPos,
                        cancelOther = false,
                    })
                end
                originPos = nil
                originCell = nil
                return
            end

            -- arrest resolved peacefully, resume Escort to door
            busyWasCombat = false
            startEscortPackage()
        end

        -- react to player weapon drawn
        if playerWeaponDrawn then
            if escorting then
                removeEscortPackages()
                escorting = false
            end
            return
        elseif not escorting and waitTimer <= 0 then
            -- weapon sheathed, resume
            startEscortPackage()
            return
        end

        -- wait phase
        if not escorting then
            waitTimer = waitTimer - CHECK_INTERVAL
            if waitTimer <= 0 then
                startEscortPackage()
            end
            return
        end

        -- stuck detection: guard hasn't moved for 3 seconds
        local curPos = self.object.position
        if lastPos and (curPos - lastPos):length() < 30 then
            stuckTimer = stuckTimer + CHECK_INTERVAL
            if stuckTimer >= 3 * time.second then
                stuckTimer = 0
                lastPos = nil

                -- stuck on geometry, try another door silently
                removeEscortPackages()

                for _, door in ipairs(nearby.doors) do
                    if door:isValid() and doorPos
                       and (door.position - doorPos):length() < 50
                    then
                        failedDoors[door.id] = true
                        break
                    end
                end

                local safeDoor, safeCellName = findSafeDoor(scanRange)
                if safeDoor then
                    doorPos = safeDoor.position
                    destCellName = safeCellName
                    local ovr = getDoorOverride(destCellName)
                    if ovr then doorPos = ovr end
                end
                -- no new door found means only one in range, retry it
                startEscortPackage()
                return
            end
        else
            stuckTimer = 0
        end
        lastPos = curPos

        -- check if arrived at door
        if doorPos then
            local distToDoor = (self.object.position - doorPos):length()
            if distToDoor <= arrivalDist then
                removeEscortPackages()
                phase = 'arrived'
                target:sendEvent('NightPatrol_GuardAtDoor', {
                    guard = self.object,
                    doorPos = doorPos,
                })
            end
        end
        return
    end

    -- arrived phase
    if phase == 'arrived' then
        -- sheathe Your Weapons compat: guard reacting to weapon, skip
        if playerWeaponDrawn then
            return
        end

        local activePkg = AI.getActivePackage()
        local isBusy = activePkg and (activePkg.type == 'Combat' or activePkg.type == 'Pursue')

        if isBusy then
            if not wasBusy then
                wasBusy = true
                busyWasCombat = activePkg.type == 'Combat' and isFightingPlayer()
                target:sendEvent('NightPatrol_GuardBusy', { guard = self.object, busy = true })
            end
            return
        elseif wasBusy then
            wasBusy = false
            target:sendEvent('NightPatrol_GuardBusy', { guard = self.object, busy = false })

            if busyWasCombat then
                busyWasCombat = false
                phase = nil
                target:sendEvent('NightPatrol_EscortEnded', { guard = self.object })
                if originPos then
                    AI.startPackage({
                        type = 'Travel',
                        destPosition = originPos,
                        cancelOther = false,
                    })
                end
                originPos = nil
                originCell = nil
                return
            end

            -- arrest resolved peacefully, resume escort to door
            busyWasCombat = false
            phase = 'escort'
            startEscortPackage()
        end
    end
end

local function onInactive()
    phase = nil
    target = nil
    doorPos = nil
    destCellName = nil
    escorting = false
    waitTimer = 0
    wasBusy = false
    busyWasCombat = false
    stuckTimer = 0
    lastPos = nil
    failedDoors = {}
    originPos = nil
    originCell = nil
end

-- sheathe Your Weapons compat
local function onPcWeaponState(value)
    playerWeaponDrawn = (value == 1)
end

-- player escaped via stealth: Travel home on top of Wander
local function onStopAndReturn()
    removeEscortPackages()
    phase = nil
    target = nil
    doorPos = nil
    destCellName = nil
    escorting = false
    waitTimer = 0
    wasBusy = false
    busyWasCombat = false
    stuckTimer = 0
    lastPos = nil
    failedDoors = {}
    if originPos then
        AI.startPackage({
            type = 'Travel',
            destPosition = originPos,
            cancelOther = false,
        })
    end
    -- originPos/originCell kept for re-escort
end

-- player entered door, global teleports guard home
local function onFullStop()
    removeEscortPackages()
    phase = nil
    target = nil
    doorPos = nil
    destCellName = nil
    escorting = false
    waitTimer = 0
    wasBusy = false
    busyWasCombat = false
    stuckTimer = 0
    lastPos = nil
    failedDoors = {}
    originPos = nil
    originCell = nil
end

-- mod disabled
local function onStopEscort()
    resetState()
end

return {
    engineHandlers = {
        onUpdate   = onUpdate,
        onInactive = onInactive,
    },
    eventHandlers = {
        NightPatrol_StartEscort   = startEscort,
        detd_pcWeaponState        = onPcWeaponState,
        NightPatrol_StopAndReturn = onStopAndReturn,
        NightPatrol_FullStop      = onFullStop,
        NightPatrol_StopEscort    = onStopEscort,
    },
}