local self   = require('openmw.self')
local types  = require('openmw.types')
local nearby = require('openmw.nearby')
local core   = require('openmw.core')
local util   = require('openmw.util')
local AI     = require('openmw.interfaces').AI

local Actor    = types.Actor
local Door     = types.Door
local Lockable = types.Lockable

local shared         = require('scripts.nightpatrol_shared')
local SAFE_KEYWORDS  = shared.SAFE_KEYWORDS
local EXCLUDED_CELLS = shared.EXCLUDED_CELLS

local VEC_FORWARD = util.vector3(0, 1, 0)

local target        = nil
local originPos     = nil
local originCell    = nil
local doorPos       = nil
local destCellName  = nil
local arrivalDist   = 250
local waitSeconds   = 0

-- Phases: nil (idle), 'escort', 'arrived'
local phase         = nil
local walking       = false
local waitTimer     = 0
local wasBusy       = false
local busyWasCombat = false

local savedWander   = nil

local CHECK_INTERVAL = 0.5
local checkTimer = 0

local stuckTimer    = 0
local lastPos       = nil
local scanRange     = 2000
local failedDoors   = {}

-- sheathe Your Weapons compat
local playerWeaponDrawn = false

local function isFightingPlayer()
    local ok, targets = pcall(AI.getTargets, 'Combat')
    if not ok or not targets then return false end
    for _, t in ipairs(targets) do
        if t == target then return true end
    end
    return false
end


local function saveWander()
    if savedWander then return end
    local pkg = AI.getActivePackage()
    if pkg and pkg.type == 'Wander' then
        savedWander = {
            type         = 'Wander',
            distance     = pkg.distance,
            duration     = pkg.duration,
            idle         = pkg.idle,
            isRepeat     = pkg.isRepeat,
        }
    end
end

local function restoreWander()
    if not savedWander then return end
    AI.startPackage(savedWander)
    savedWander = nil
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

-- check if guard faces player
local function isFacingPlayer()
    if not target or not target:isValid() then return false end
    local toPlayer = target.position - self.object.position
    local len = toPlayer:length()
    if len < 1 then return true end
    local forward = self.object.rotation:apply(VEC_FORWARD)
    local dot = forward:dot(toPlayer / len)
    return dot > 0.7
end

local function resetState()
    AI.removePackages('Travel')
    phase = nil
    target = nil
    doorPos = nil
    destCellName = nil
    walking = false
    waitTimer = 0
    wasBusy = false
    busyWasCombat = false
    stuckTimer = 0
    lastPos = nil
    failedDoors = {}
    restoreWander()
end

local function startEscort(data)
    target = data.target
    if not target or not target:isValid() then return end

    -- save Wander before removing it
    saveWander()

    AI.removePackages('Travel')
    AI.removePackages('Wander')

    arrivalDist = data.doorArrivalDist
    waitSeconds = 2
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
        restoreWander()
        return
    end

    doorPos = safeDoor.position
    destCellName = safeCellName
    phase = 'escort'
    walking = false
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
                AI.removePackages('Travel')
                walking = false
                target:sendEvent('NightPatrol_GuardBusy', { guard = self.object, busy = true })
            end
            return
        elseif wasBusy then
            wasBusy = false
            target:sendEvent('NightPatrol_GuardBusy', { guard = self.object, busy = false })

            if busyWasCombat then
                -- player resisted, escort over, guard has their Travel package to the initial pos, then Wander
                -- it's a fallback if Pursue isn't initiated
                busyWasCombat = false
                phase = nil
                walking = false
                target:sendEvent('NightPatrol_EscortEnded', { guard = self.object })
                restoreWander()
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

            -- arrest resolved peacefully, resume Travel to door
            busyWasCombat = false
            if doorPos then
                walking = true
                AI.startPackage({
                    type = 'Travel',
                    destPosition = doorPos,
                    cancelOther = false,
                })
            end
        end

        -- react to player weapon drawn
        if playerWeaponDrawn then
            if walking then
                AI.removePackages('Travel')
                walking = false
            end
            return
        elseif not walking and waitTimer <= 0 then
            -- weapon sheathed, resume
            walking = true
            AI.startPackage({
                type = 'Travel',
                destPosition = doorPos,
                cancelOther = false,
            })
            return
        end

        -- wait phase
        if not walking then
            waitTimer = waitTimer - CHECK_INTERVAL
            if waitTimer <= 0 then
                walking = true
                AI.startPackage({
                    type = 'Travel',
                    destPosition = doorPos,
                    cancelOther = false,
                })
            end
            return
        end

        -- stuck detection: guard hasn't moved for 3 seconds
        local curPos = self.object.position
        if lastPos and (curPos - lastPos):length() < 30 then
            -- guard facing player = engine greeting, not stuck, just wait it out
            if not isFacingPlayer() then
                stuckTimer = stuckTimer + CHECK_INTERVAL
                if stuckTimer >= 3 then
                    stuckTimer = 0
                    lastPos = nil
 
                    -- stuck on geometry, try another door silently
                    AI.removePackages('Travel')
 
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
                    end
                    -- no new door found means only one in range, retry it
                    AI.startPackage({
                        type = 'Travel',
                        destPosition = doorPos,
                        cancelOther = false,
                    })
                    return
                end
            end
        else
            stuckTimer = 0
        end
        lastPos = curPos

        -- check if arrived at door
        if doorPos then
            local distToDoor = (self.object.position - doorPos):length()
            if distToDoor <= arrivalDist then
                AI.removePackages('Travel')
                phase = 'arrived'
                -- restore Wander
                restoreWander()
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
                -- Wander already restored at 'arrived', just Travel home on top
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
            saveWander()
            AI.removePackages('Wander')
            busyWasCombat = false
            phase = 'escort'
            walking = true
            AI.startPackage({
                type = 'Travel',
                destPosition = doorPos,
                cancelOther = false,
            })
        end
    end
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onInactive = function()
            phase = nil
            target = nil
            doorPos = nil
            destCellName = nil
            walking = false
            waitTimer = 0
            wasBusy = false
            busyWasCombat = false
            stuckTimer = 0
            lastPos = nil
            failedDoors = {}
            originPos = nil
            originCell = nil
            restoreWander()
        end,
    },
    eventHandlers = {
        NightPatrol_StartEscort = startEscort,

        -- sheathe Your Weapons compat
        detd_pcWeaponState = function(value)
            playerWeaponDrawn = (value == 1)
        end,

        -- player escaped via stealth: Wander back, Travel home on top
        NightPatrol_StopAndReturn = function()
            AI.removePackages('Travel')
            phase = nil
            target = nil
            doorPos = nil
            destCellName = nil
            walking = false
            waitTimer = 0
            wasBusy = false
            busyWasCombat = false
            stuckTimer = 0
            lastPos = nil
            failedDoors = {}
            restoreWander()
            if originPos then
                AI.startPackage({
                    type = 'Travel',
                    destPosition = originPos,
                    cancelOther = false,
                })
            end
            -- originPos/originCell kept for re-escort
        end,

        -- player entered door, global teleports guard home
        NightPatrol_FullStop = function()
            AI.removePackages('Travel')
            phase = nil
            target = nil
            doorPos = nil
            destCellName = nil
            walking = false
            waitTimer = 0
            wasBusy = false
            busyWasCombat = false
            stuckTimer = 0
            lastPos = nil
            failedDoors = {}
            originPos = nil
            originCell = nil
            restoreWander()
        end,

        -- mod disabled
        NightPatrol_StopEscort = function()
            resetState()
        end,
    },
}